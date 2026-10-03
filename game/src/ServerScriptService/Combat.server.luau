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
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent

local lastAction: { [Player]: number } = {}
local rejectedFireCounts: { [Player]: number } = {}
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
local function damageEnemy(plr: Player, model: Model, damage: number, hitPos: Vector3): boolean
	local landed = CombatEffects.hit(plr, model, damage, hitPos)
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
		if ok and damageEnemy(plr, model, damage, eroot.Position) then
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
	}, plr)
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
	rejectedFireCounts[plr] = nil
end)
