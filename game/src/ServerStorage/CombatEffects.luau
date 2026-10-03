--!strict
-- Applies a hit to an enemy and the equipped weapon's Evolution effects. Used by Combat and OrbitalRunner.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent.PlayerData)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local Feel = require(ReplicatedStorage.Shared.Feel)
local EnemyIndex = require(script.Parent.EnemyIndex)
local FxRouter = require(script.Parent.FxRouter)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HitMarker = Remotes.HitMarker :: RemoteEvent
local enemiesFolder = workspace:WaitForChild("Enemies")

local CombatEffects = {}

local function enemiesNear(pos: Vector3, radius: number, except: Model?): { Model }
	local out = {}
	for _, model in EnemyIndex.queryRadius(pos, radius) do
		local root = model.PrimaryPart
		if root and model ~= except and (root.Position - pos).Magnitude <= radius then
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(out, model :: Model)
			end
		end
	end
	table.sort(out, function(a, b)
		return ((a.PrimaryPart :: BasePart).Position - pos).Magnitude
			< ((b.PrimaryPart :: BasePart).Position - pos).Magnitude
	end)
	return out
end
CombatEffects.enemiesNear = enemiesNear

local function heal(plr: Player, amount: number)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and amount > 0 then
		hum.Health = math.min(hum.MaxHealth, hum.Health + amount)
	end
end

-- Raw damage with attribution and a hit marker. Returns true if it landed, and whether it killed.
local function rawHit(
	plr: Player,
	model: Model,
	damage: number,
	hitPos: Vector3
): (boolean, boolean)
	local ehum = model:FindFirstChildOfClass("Humanoid")
	if not ehum or ehum.Health <= 0 or model.Parent ~= enemiesFolder then
		return false, false
	end
	if damage <= 0 or damage ~= damage then
		return false, false
	end
	local creditedDamage = math.min(damage, ehum.Health)
	PlayerData.recordDamage(model, plr, creditedDamage)
	model:SetAttribute("LastHitBy", plr.UserId)
	ehum:TakeDamage(damage)
	local killed = ehum.Health <= 0
	local root = model.PrimaryPart
	local playerRoot = plr.Character
		and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and playerRoot and model:GetAttribute("Boss") ~= true then
		local away = (root.Position - playerRoot.Position) * Vector3.new(1, 0, 1)
		if away.Magnitude > 0.01 then
			root.CFrame += away.Unit * Feel.KnockbackStuds
		end
	end
	HitMarker:FireClient(plr, hitPos, math.floor(damage + 0.5), killed, model)
	return true, killed
end

-- A full hit: damage plus every active evolution effect. Returns landed, killed.
function CombatEffects.hit(
	plr: Player,
	model: Model,
	damage: number,
	hitPos: Vector3
): (boolean, boolean)
	local landed, killed = rawHit(plr, model, damage, hitPos)
	if not landed then
		return false, false
	end
	local effects = PlayerData.activeEffects(plr)
	if #effects == 0 then
		return true, killed
	end
	local evo = PlayerData.equippedEvo(plr)
	local color = if evo then Evolutions.Elements[evo.Element].Color else { 255, 255, 255 }
	local root = model.PrimaryPart :: BasePart
	local E = Evolutions.Effects

	for _, key in effects do
		if key == "Lifesteal" then
			heal(plr, damage * E.Lifesteal.Value)
		elseif key == "Slow" then
			model:SetAttribute("SlowUntil", os.clock() + 2)
		elseif key == "Arc" then
			local others = enemiesNear(root.Position, 12, model)
			if others[1] then
				local o = others[1]
				local opos = (o.PrimaryPart :: BasePart).Position
				rawHit(plr, o, damage * E.Arc.Value, opos)
				FxRouter.emit(
					"chain",
					root.Position,
					{ Points = { root.Position, opos }, Color = color },
					plr
				)
			end
		elseif key == "Chain" then
			local points = { root.Position }
			local last = root.Position
			local hitSet = { [model] = true }
			for _ = 1, 3 do
				local others = enemiesNear(last, 12, nil)
				local nextModel: Model? = nil
				for _, o in others do
					if not hitSet[o] then
						nextModel = o
						break
					end
				end
				if not nextModel then
					break
				end
				hitSet[nextModel] = true
				local opos = (nextModel.PrimaryPart :: BasePart).Position
				rawHit(plr, nextModel, damage * E.Chain.Value, opos)
				table.insert(points, opos)
				last = opos
			end
			if #points > 1 then
				FxRouter.emit("chain", root.Position, { Points = points, Color = color }, plr)
			end
		elseif key == "HealOnKill" and killed then
			local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				heal(plr, hum.MaxHealth * E.HealOnKill.Value)
			end
		elseif key == "Pull" and killed then
			local radius = E.Pull.Value
			for _, o in enemiesNear(root.Position, radius, model) do
				local oroot = o.PrimaryPart :: BasePart
				if not oroot.Anchored then
					local dir = root.Position - oroot.Position
					if dir.Magnitude > 1 then
						oroot.AssemblyLinearVelocity = dir.Unit * 40 + Vector3.new(0, 12, 0)
					end
				end
			end
			FxRouter.emit(
				"pull",
				root.Position,
				{ Position = root.Position, Radius = radius, Color = color },
				plr
			)
		end
	end
	return true, killed
end

local function areaHit(plr: Player, position: Vector3, radius: number, damage: number)
	for _, model in enemiesNear(position, radius, nil) do
		local root = model.PrimaryPart
		if root then
			CombatEffects.hit(plr, model, damage, root.Position)
		end
	end
end

local function fragBurst(plr: Player, root: BasePart, damage: number)
	local position = root.Position + root.CFrame.LookVector * 8
	areaHit(plr, position, 12, damage)
	FxRouter.emit(
		"pull",
		position,
		{ Position = position, Radius = 12, Color = { 40, 220, 200 } },
		plr
	)
end

local function groundSlam(plr: Player, root: BasePart, damage: number)
	areaHit(plr, root.Position, 14, damage)
	FxRouter.emit(
		"pull",
		root.Position,
		{ Position = root.Position, Radius = 14, Color = { 45, 210, 155 } },
		plr
	)
end

local function turretDrop(plr: Player, root: BasePart, damage: number)
	local turret = Instance.new("Part")
	turret.Name = "EngineerTurret"
	turret.Anchored = true
	turret.CanCollide = false
	turret.CanQuery = false
	turret.Material = Enum.Material.Neon
	turret.Color = Color3.fromRGB(40, 220, 200)
	turret.Size = Vector3.new(2, 3, 2)
	turret.CFrame = CFrame.new(root.Position - Vector3.new(0, 2, 0))
	turret.Parent = workspace
	task.spawn(function()
		for _ = 1, 8 do
			if not turret.Parent then
				return
			end
			local targets = enemiesNear(turret.Position, 35, nil)
			local target = targets[1]
			local targetRoot = target and target.PrimaryPart
			if target and targetRoot then
				CombatEffects.hit(plr, target, damage, targetRoot.Position)
				FxRouter.emit(
					"chain",
					turret.Position,
					{ Points = { turret.Position, targetRoot.Position }, Color = { 40, 220, 200 } },
					plr
				)
			end
			task.wait(1)
		end
		turret:Destroy()
	end)
end

local function healPulse(plr: Player, root: BasePart)
	for _, other in Players:GetPlayers() do
		local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		local hum = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
		if
			otherRoot
			and otherRoot:IsA("BasePart")
			and hum
			and hum.Health > 0
			and (otherRoot.Position - root.Position).Magnitude <= 30
		then
			heal(other, math.max(25, hum.MaxHealth * 0.25))
		end
	end
	FxRouter.emit(
		"pull",
		root.Position,
		{ Position = root.Position, Radius = 30, Color = { 45, 220, 160 } },
		plr
	)
end

-- Kit signatures reuse the same indexed targeting, damage attribution, hit effects and FX path.
function CombatEffects.castSignature(plr: Player, effect: string): boolean
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not hum or hum.Health <= 0 then
		return false
	end
	local damage = 45 * PlayerData.damageMultiplier(plr)
	if effect == "FragBurst" then
		fragBurst(plr, root, damage)
	elseif effect == "GroundSlam" then
		groundSlam(plr, root, damage * 1.4)
	elseif effect == "TurretDrop" then
		turretDrop(plr, root, damage * 0.45)
	elseif effect == "HealPulse" then
		healPulse(plr, root)
	else
		return false
	end
	return true
end

enemiesFolder.ChildRemoved:Connect(function(enemy)
	if enemy:IsA("Model") then
		PlayerData.clearDamageCredit(enemy)
	end
end)

return CombatEffects
