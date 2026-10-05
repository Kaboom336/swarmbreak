--!strict
-- Server-authoritative combat for every weapon kind. Client only sends aim + intent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerData = require(ServerStorage.PlayerData)
local CombatEffects = require(ServerStorage.CombatEffects)
local EnemyIndex = require(ServerStorage.EnemyIndex)
local FxRouter = require(ServerStorage.FxRouter)
local FireGuard = require(ReplicatedStorage.Shared.FireGuard)
local Kits = require(ReplicatedStorage.Shared.Kits)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Theme = require(ReplicatedStorage.Shared.Theme)
local AbilityPool = require(ReplicatedStorage.Shared.AbilityPool)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent
local Signature = Remotes.Signature :: RemoteEvent
local WeaponAbility = Remotes.WeaponAbility :: RemoteEvent

local lastAction: { [Player]: number } = {}
local rejectedFireCounts: { [Player]: number } = {}
local abilityReadyAt: { [Player]: { [string]: number } } = {}
local rng = Random.new()

local function point3(vector: Vector3): FireGuard.Point3
	return { x = vector.X, y = vector.Y, z = vector.Z }
end

local function recordRejectedFire(plr: Player)
	rejectedFireCounts[plr] = (rejectedFireCounts[plr] or 0) + 1
end

task.spawn(function()
	while true do
		task.wait(60)
		for plr, count in rejectedFireCounts do
			warn(string.format("Rejected %d fire requests from %s", count, plr.Name))
			rejectedFireCounts[plr] = nil
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
local function damageEnemy(
	plr: Player,
	model: Model,
	damage: number,
	hitPos: Vector3,
	scytheHit: boolean?
): boolean
	local landed = CombatEffects.hit(plr, model, damage, hitPos, scytheHit)
	if landed then
		PlayerData.recordHit(plr)
	end
	return landed
end

local function enemiesNear(pos: Vector3, radius: number): { Model }
	local out = {}
	local searchRadius = radius + EnemyIndex.maximumRootRadius()
	for _, model in EnemyIndex.queryRadius(pos, searchRadius) do
		local root = model.PrimaryPart
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
	FxRouter.emit("shot", origin, {
		Shooter = plr,
		Origin = origin,
		Ends = ends,
		Hits = hits,
		Color = Theme.Rarity[weapon.Rarity],
		Sound = Sounds.ForWeapon[weapon.Id] or "ShotPistol",
	}, plr)
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
		if ok and damageEnemy(plr, model, damage, eroot.Position, weapon.Id == "Reaper") then
			table.insert(hits, eroot.Position)
			damageDealt += damage
		end
	end
	if damageDealt > 0 then
		PlayerData.addMeleeDamage(plr, damageDealt)
	end
	FxRouter.emit("swing", root.Position, {
		Shooter = plr,
		Origin = root.Position,
		Dir = flatDir,
		Range = weapon.Range,
		Slam = weapon.Slam == true,
		Hits = hits,
		Color = Theme.Rarity[weapon.Rarity],
		Sound = Sounds.ForWeapon[weapon.Id] or "Swing",
		Scythe = weapon.Id == "Reaper",
	}, plr)
end

local function doScytheAbility(plr: Player, abilityId: string, root: BasePart, damage: number)
	local radius = if abilityId == "HeavySweep"
		then 18
		elseif abilityId == "DashSpin" then 16
		elseif abilityId == "CrescentPull" then 22
		else 24
	local multiplier = if abilityId == "HeavySweep"
		then 1.8
		elseif abilityId == "DashSpin" then 1.35
		elseif abilityId == "CrescentPull" then 1.1
		else 2.4
	local hits = {}
	for _, model in enemiesNear(root.Position, radius) do
		local enemyRoot = model.PrimaryPart
		if enemyRoot and damageEnemy(plr, model, damage * multiplier, enemyRoot.Position, true) then
			table.insert(hits, enemyRoot.Position)
			if abilityId == "CrescentPull" and not enemyRoot.Anchored then
				local toward = root.Position - enemyRoot.Position
				if toward.Magnitude > 1 then
					enemyRoot.AssemblyLinearVelocity = toward.Unit * 32
				end
			end
		end
	end
	FxRouter.emit("swing", root.Position, {
		Shooter = plr,
		Origin = root.Position,
		Dir = root.CFrame.LookVector,
		Range = radius,
		Slam = true,
		Ultimate = abilityId == "ReaperArc",
		Hits = hits,
		Color = Theme.Rarity.Legendary,
		Sound = Sounds.ForWeapon.Reaper or "Swing",
		Scythe = true,
	}, plr)
end

WeaponAbility.OnServerEvent:Connect(function(plr, abilityId: any)
	if typeof(abilityId) ~= "string" then
		return
	end
	local weapon = PlayerData.equippedWeapon(plr)
	if weapon.Id ~= "Reaper" then
		return
	end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end
	local loadout = AbilityPool.defaultLoadout("Reaper")
	local isUltimate = abilityId == loadout.Ultimate
	if not isUltimate and not table.find(loadout.Abilities, abilityId) then
		return -- only the equipped loadout may fire (K1 review)
	end
	local ability = AbilityPool.find("Reaper", abilityId)
	if (not ability or not ability.Implemented) and not isUltimate then
		return
	end
	local cooldown = if isUltimate then 30 else (ability :: AbilityPool.Ability).Cooldown
	local readyById = abilityReadyAt[plr] or {}
	abilityReadyAt[plr] = readyById
	local now = os.clock()
	if now < (readyById[abilityId] or 0) then
		return
	end
	readyById[abilityId] = now + cooldown
	WeaponAbility:FireClient(plr, abilityId)
	doScytheAbility(plr, abilityId, root, weapon.Damage * PlayerData.damageMultiplier(plr))
end)

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
	FxRouter.emit("beam", origin, {
		Shooter = plr,
		Origin = origin,
		EndPos = endPos,
		Hit = hitPos,
		Color = Theme.Rarity[weapon.Rarity],
		Sound = Sounds.ForWeapon[weapon.Id] or "Beam",
	}, plr)
end

Shoot.OnServerEvent:Connect(function(plr, origin: Vector3, dir: Vector3)
	if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" then
		recordRejectedFire(plr)
		return
	end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not root or not hum or hum.Health <= 0 then
		return
	end
	local weapon = PlayerData.equippedWeapon(plr)
	if weapon.Kind == "Orbital" then
		return -- passive: handled by OrbitalRunner
	end
	local rate = weapon.FireRate * PlayerData.fireRateMultiplier(plr)
	local now = os.clock()
	if
		not FireGuard.validate(
			now,
			lastAction[plr],
			rate,
			point3(origin),
			point3(root.Position),
			point3(dir)
		)
	then
		recordRejectedFire(plr)
		return
	end
	-- Advance by one fire interval instead of jumping to now, so two shots that the network
	-- bunched together still pass; clamp to now - interval so idle time never banks a burst.
	local interval = 1 / math.max(rate, 0.01)
	local last = lastAction[plr]
	lastAction[plr] = if last then math.max(now - interval, math.min(now, last + interval)) else now
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

Signature.OnServerEvent:Connect(function(plr)
	if not PlayerData.get(plr).Active then
		return
	end
	local signature = PlayerData.signature(plr)
	local now = os.clock()
	local oldReadyAt = (plr:GetAttribute("SignatureReadyAt") :: number?) or 0
	local ready, nextReadyAt = Kits.trySignature(signature.Id, now, oldReadyAt)
	if not ready then
		return
	end
	if CombatEffects.castSignature(plr, signature.Effect) then
		plr:SetAttribute("SignatureReadyAt", nextReadyAt)
		Signature:FireClient(plr, signature.Cooldown)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	lastAction[plr] = nil
	rejectedFireCounts[plr] = nil
	abilityReadyAt[plr] = nil
end)
