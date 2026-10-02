--!strict
-- Server-authoritative combat for every weapon kind. Client only sends aim + intent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local PlayerData = require(ServerStorage.PlayerData)
local CombatEffects = require(ServerStorage.CombatEffects)
local Difficulty = require(ReplicatedStorage.Shared.Difficulty)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Pickups = require(ReplicatedStorage.Shared.Pickups)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent
local FX = Remotes.FX :: RemoteEvent

local lastAction: { [Player]: number } = {}
local rng = Random.new()
local enemiesFolder = workspace:WaitForChild("Enemies")

type LivePickup = {
	Id: number,
	Kind: string,
	Amount: number,
	Position: Vector3,
	ExpiresAt: number,
	TargetId: number?,
	Collected: boolean?,
}

local livePickups: { [number]: LivePickup } = {}
local vacuumUntil: { [Player]: number } = {}
local nextPickupId = 0

local function eligible(plr: Player): (boolean, BasePart?)
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return PlayerData.isWaiting(plr) == false and root ~= nil and hum ~= nil and hum.Health > 0,
		root
end

local function point(position: Vector3): { [string]: number }
	return { x = position.X, y = position.Y, z = position.Z }
end

local function spawnPickup(kind: string, amount: number, position: Vector3)
	nextPickupId += 1
	local id = nextPickupId
	livePickups[id] = {
		Id = id,
		Kind = kind,
		Amount = amount,
		Position = position,
		ExpiresAt = os.clock() + Pickups.Lifetime,
	}
	FX:FireAllClients("pickupSpawn", {
		Id = id,
		Kind = kind,
		Position = position,
		Lifetime = Pickups.Lifetime,
	})
end

CombatEffects.OnEnemyKilled = function(killer: Player, model: Model, hitPosition: Vector3)
	local baseCoins = model:GetAttribute("DropBaseCoins")
	local wave = model:GetAttribute("DropWave")
	local difficultyId = model:GetAttribute("DropDifficulty")
	local xp = model:GetAttribute("DropXP")
	if
		type(baseCoins) ~= "number"
		or type(wave) ~= "number"
		or type(difficultyId) ~= "string"
		or type(xp) ~= "number"
	then
		return
	end
	local coinAmount =
		Economy.coinsForKill(baseCoins, PlayerData.hasPass(killer, "DoubleCoins"), wave)
	coinAmount = Difficulty.scaleReward(coinAmount, difficultyId :: Difficulty.TierName)
	if Pickups.shouldDrop("Coin", rng:NextNumber()) then
		spawnPickup("Coin", coinAmount, hitPosition + Vector3.new(-0.8, 1, 0))
	end
	if Pickups.shouldDrop("XP", rng:NextNumber()) then
		spawnPickup("XP", xp, hitPosition + Vector3.new(0.8, 1, 0))
	end
	if Pickups.shouldDrop("Vacuum", rng:NextNumber()) then
		spawnPickup("Vacuum", 1, hitPosition + Vector3.new(0, 2, 0))
	end
end

local function pickupCandidates(): { any }
	local candidates = {}
	for _, plr in Players:GetPlayers() do
		local isEligible, root = eligible(plr)
		if root then
			table.insert(candidates, {
				Id = plr.UserId,
				Position = point(root.Position),
				Eligible = isEligible,
				VacuumUntil = vacuumUntil[plr],
			})
		end
	end
	return candidates
end

local pickupClock = 0
RunService.Heartbeat:Connect(function(dt: number)
	pickupClock += dt
	if pickupClock < 0.05 then
		return
	end
	local stepTime = pickupClock
	pickupClock = 0
	local now = os.clock()
	local candidates = pickupCandidates()
	for id, drop in livePickups do
		if now >= drop.ExpiresAt then
			livePickups[id] = nil
			FX:FireAllClients("pickupRemove", { Id = id })
			continue
		end
		local target = Pickups.chooseTarget(point(drop.Position), candidates, now)
		local targetId = if target then target.Id else nil
		if targetId ~= drop.TargetId then
			drop.TargetId = targetId
			FX:FireAllClients("pickupTarget", {
				Id = id,
				Target = if targetId then Players:GetPlayerByUserId(targetId) else nil,
				Position = drop.Position,
			})
		end
		if not target then
			continue
		end
		local targetPlayer = Players:GetPlayerByUserId(target.Id)
		local isEligible = false
		local root: BasePart? = nil
		if targetPlayer then
			isEligible, root = eligible(targetPlayer)
		end
		if not targetPlayer or not isEligible or not root then
			continue
		end
		local offset = root.Position - drop.Position
		local distance = offset.Magnitude
		if distance > 0 then
			drop.Position += offset.Unit * math.min(distance, Pickups.FlySpeed * stepTime)
		end
		local claim = {
			Id = targetPlayer.UserId,
			Position = point(root.Position),
			Eligible = true,
			VacuumUntil = vacuumUntil[targetPlayer],
		}
		local collected = Pickups.tryCollect(drop :: any, claim, now)
		if collected then
			livePickups[id] = nil
			if drop.Kind == "Coin" then
				PlayerData.addCoins(targetPlayer, drop.Amount)
			elseif drop.Kind == "XP" then
				PlayerData.addXP(targetPlayer, drop.Amount)
			elseif drop.Kind == "Vacuum" then
				vacuumUntil[targetPlayer] = Pickups.vacuumExpiry(now)
			end
			FX:FireAllClients("pickupCollect", {
				Id = id,
				Kind = drop.Kind,
				Player = targetPlayer,
				Position = root.Position,
			})
		end
	end
end)

local function spreadDir(dir: Vector3, degrees: number): Vector3
	if degrees <= 0 then
		return dir
	end
	local yaw = math.rad(rng:NextNumber(-degrees, degrees))
	local pitch = math.rad(rng:NextNumber(-degrees, degrees))
	return (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- Damage an enemy model (plus Evolution effects); returns true if it counted.
local function damageEnemy(plr: Player, model: Model, damage: number, hitPos: Vector3): boolean
	local landed = CombatEffects.hit(plr, model, damage, hitPos)
	return landed
end

local function enemiesNear(pos: Vector3, radius: number): { Model }
	local out = {}
	for _, model in enemiesFolder:GetChildren() do
		local root = model:IsA("Model") and model.PrimaryPart
		if root and (root.Position - pos).Magnitude <= radius + root.Size.Magnitude / 2 then
			table.insert(out, model :: Model)
		end
	end
	return out
end

local function doHitscan(
	plr: Player,
	char: Model,
	weapon,
	origin: Vector3,
	dir: Vector3,
	damage: number
)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char :: Instance }
	local ends, hits = {}, {}
	for _ = 1, weapon.Pellets do
		local d = spreadDir(dir, weapon.Spread)
		local hit = workspace:Raycast(origin, d * weapon.Range, params)
		table.insert(ends, if hit then hit.Position else origin + d * weapon.Range)
		if hit then
			local model = hit.Instance:FindFirstAncestorOfClass("Model")
			if model and damageEnemy(plr, model, damage, hit.Position) then
				table.insert(hits, hit.Position)
			end
		end
	end
	FX:FireAllClients("shot", {
		Shooter = plr,
		Origin = origin,
		Ends = ends,
		Hits = hits,
		Color = Theme.Rarity[weapon.Rarity],
		Sound = Sounds.ForWeapon[weapon.Id] or "ShotPistol",
	})
end

local function doMelee(
	plr: Player,
	char: Model,
	weapon,
	_origin: Vector3,
	dir: Vector3,
	damage: number
)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	flatDir = if flatDir.Magnitude > 0.01 then flatDir.Unit else root.CFrame.LookVector
	if weapon.Lunge and weapon.Lunge > 0 then
		local att = Instance.new("Attachment")
		att.Parent = root
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = att
		lv.MaxForce = math.huge
		lv.VectorVelocity = flatDir * (weapon.Lunge * 5)
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.Parent = root
		task.delay(0.2, function()
			lv:Destroy()
			att:Destroy()
		end)
	end
	local center = root.Position + flatDir * (if weapon.Slam then 0 else weapon.Range * 0.4)
	local hits = {}
	local damageDealt = 0
	local cosLimit = math.cos(math.rad(weapon.Spread))
	for _, model in enemiesNear(center, weapon.Range) do
		local eroot = model.PrimaryPart :: BasePart
		local to = eroot.Position - root.Position
		local ok = weapon.Slam
			or to.Magnitude < 3
			or (Vector3.new(to.X, 0, to.Z).Unit:Dot(flatDir) >= cosLimit)
		if ok and damageEnemy(plr, model, damage, eroot.Position) then
			table.insert(hits, eroot.Position)
			damageDealt += damage
		end
	end
	if damageDealt > 0 then
		PlayerData.addMeleeDamage(plr, damageDealt)
	end
	FX:FireAllClients("swing", {
		Shooter = plr,
		Origin = root.Position,
		Dir = flatDir,
		Range = weapon.Range,
		Slam = weapon.Slam == true,
		Hits = hits,
		Color = Theme.Rarity[weapon.Rarity],
		Sound = Sounds.ForWeapon[weapon.Id] or "Swing",
	})
end

local function doBeam(
	plr: Player,
	char: Model,
	weapon,
	origin: Vector3,
	dir: Vector3,
	damage: number
)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char :: Instance }
	local hit = workspace:Raycast(origin, dir * weapon.Range, params)
	local endPos = if hit then hit.Position else origin + dir * weapon.Range
	local hitPos: Vector3? = nil
	if hit then
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		if model and damageEnemy(plr, model, damage, hit.Position) then
			hitPos = hit.Position
		end
	end
	FX:FireAllClients("beam", {
		Shooter = plr,
		Origin = origin,
		EndPos = endPos,
		Hit = hitPos,
		Color = Theme.Rarity[weapon.Rarity],
		Sound = Sounds.ForWeapon[weapon.Id] or "Beam",
	})
end

Shoot.OnServerEvent:Connect(function(plr, origin: Vector3, dir: Vector3)
	if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" or dir.Magnitude < 0.01 then
		return
	end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not root or not hum or hum.Health <= 0 then
		return
	end
	if (root.Position - origin).Magnitude > 12 then
		return -- origin must be near the player
	end
	local weapon = PlayerData.equippedWeapon(plr)
	if weapon.Kind == "Orbital" then
		return -- passive: handled by OrbitalRunner
	end
	local rate = weapon.FireRate * PlayerData.fireRateMultiplier(plr)
	local now = os.clock()
	if now - (lastAction[plr] or 0) < (1 / rate) * 0.85 then
		return -- rate guard (small tolerance for latency)
	end
	lastAction[plr] = now
	PlayerData.completeTutorial(plr, "Shoot")
	local damage = weapon.Damage * PlayerData.damageMultiplier(plr)
	dir = dir.Unit
	if weapon.Kind == "Hitscan" then
		doHitscan(plr, char, weapon, origin, dir, damage)
	elseif weapon.Kind == "Melee" then
		doMelee(plr, char, weapon, origin, dir, damage)
	elseif weapon.Kind == "Beam" then
		doBeam(plr, char, weapon, origin, dir, damage)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	lastAction[plr] = nil
	vacuumUntil[plr] = nil
end)
