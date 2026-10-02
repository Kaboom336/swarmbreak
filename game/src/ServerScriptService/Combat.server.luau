--!strict
-- Server-authoritative combat for every weapon kind. Client only sends aim + intent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerData = require(ServerStorage.PlayerData)
local CombatEffects = require(ServerStorage.CombatEffects)
local Barrels = require(ReplicatedStorage.Shared.Barrels)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent
local FX = Remotes.FX :: RemoteEvent

local lastAction: { [Player]: number } = {}
local rng = Random.new()
local enemiesFolder = workspace:WaitForChild("Enemies")
local barrelsFolder = workspace:WaitForChild("Barrels")
local enemiesNear: (Vector3, number) -> { Model }

type Cascade = { FXCount: number }

local function barrelFromHit(hit: Instance): Model?
	local model = hit:FindFirstAncestorOfClass("Model")
	if model and model.Parent == barrelsFolder and model:GetAttribute("IsEnergyBarrel") == true then
		return model
	end
	return nil
end

local function showBarrel(model: Model, visible: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if visible then 0 else 1
			descendant.CanCollide = visible and descendant.Name == "Core"
			descendant.CanQuery = visible
		end
	end
end

local function resetBarrels()
	barrelsFolder:SetAttribute("Generation", (barrelsFolder:GetAttribute("Generation") or 0) + 1)
	for _, child in barrelsFolder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("IsEnergyBarrel") == true then
			child:SetAttribute("Health", Barrels.Health)
			child:SetAttribute("Spent", false)
			child:SetAttribute("Queued", false)
			showBarrel(child, true)
		end
	end
end

local explodeBarrel: (Player, Model, Cascade, boolean) -> ()

local function queueBarrel(plr: Player, model: Model, delaySeconds: number, cascade: Cascade)
	if model:GetAttribute("Spent") == true or model:GetAttribute("Queued") == true then
		return
	end
	model:SetAttribute("Queued", true)
	cascade.FXCount += 1
	local showFX = cascade.FXCount <= Barrels.MaxChainFX
	if showFX then
		FX:FireAllClients("barrelWarning", {
			Position = (model.PrimaryPart :: BasePart).Position,
			Delay = delaySeconds,
			Color = Barrels.Color,
		})
	end
	local generation = barrelsFolder:GetAttribute("Generation") or 0
	task.delay(delaySeconds, function()
		if barrelsFolder:GetAttribute("Generation") == generation then
			explodeBarrel(plr, model, cascade, showFX)
		end
	end)
end

explodeBarrel = function(plr: Player, model: Model, cascade: Cascade, showFX: boolean)
	if model:GetAttribute("Spent") == true or model.Parent ~= barrelsFolder then
		return
	end
	model:SetAttribute("Spent", true)
	model:SetAttribute("Queued", false)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local center = root.Position
	showBarrel(model, false)
	if showFX then
		FX:FireAllClients("barrelBlast", {
			Position = center,
			Radius = Barrels.BlastRadius,
			Color = Barrels.Color,
		})
	end
	for _, enemy in enemiesNear(center, Barrels.BlastRadius) do
		local enemyRoot = enemy.PrimaryPart :: BasePart
		local offset = enemyRoot.Position - center
		local distance = offset.Magnitude
		local damage = Barrels.damageAtDistance(distance)
		if damage > 0 then
			CombatEffects.rawHit(plr, enemy, damage, enemyRoot.Position, false)
			local horizontal = offset * Vector3.new(1, 0, 1)
			if horizontal.Magnitude > 0.01 then
				local velocity = horizontal.Unit * Barrels.knockbackAtDistance(distance)
					+ Vector3.new(0, 16, 0)
				if enemyRoot.Anchored then
					enemyRoot.CFrame += horizontal.Unit * math.min(6, velocity.Magnitude * 0.08)
				else
					enemyRoot:ApplyImpulse(velocity * enemyRoot.AssemblyMass)
				end
			end
		end
	end
	for _, other in barrelsFolder:GetChildren() do
		if other:IsA("Model") and other ~= model and other.PrimaryPart then
			local distance = (other.PrimaryPart.Position - center).Magnitude
			if Barrels.shouldChain(distance) then
				queueBarrel(plr, other, Barrels.ChainDelay, cascade)
			end
		end
	end
end

local function damageBarrel(plr: Player, model: Model, damage: number): boolean
	if model:GetAttribute("Spent") == true or model:GetAttribute("Queued") == true then
		return false
	end
	local health = math.max(0, (model:GetAttribute("Health") :: number? or Barrels.Health) - damage)
	model:SetAttribute("Health", health)
	if health <= 0 then
		queueBarrel(plr, model, Barrels.FuseDelay, { FXCount = 0 })
	end
	return true
end

local resetEvent = barrelsFolder:WaitForChild("Reset") :: BindableEvent
resetEvent.Event:Connect(resetBarrels)

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

enemiesNear = function(pos: Vector3, radius: number): { Model }
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
			local barrel = barrelFromHit(hit.Instance)
			local model = hit.Instance:FindFirstAncestorOfClass("Model")
			local landed = if barrel
				then damageBarrel(plr, barrel, damage)
				else model ~= nil and damageEnemy(plr, model, damage, hit.Position)
			if landed then
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
		local barrel = barrelFromHit(hit.Instance)
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		local landed = if barrel
			then damageBarrel(plr, barrel, damage)
			else model ~= nil and damageEnemy(plr, model, damage, hit.Position)
		if landed then
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
end)
