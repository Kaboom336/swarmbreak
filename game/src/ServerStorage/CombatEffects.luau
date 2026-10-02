--!strict
-- Applies a hit to an enemy and the equipped weapon's Evolution effects. Used by Combat and OrbitalRunner.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent.PlayerData)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local Feel = require(ReplicatedStorage.Shared.Feel)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HitMarker = Remotes.HitMarker :: RemoteEvent
local FX = Remotes.FX :: RemoteEvent
local enemiesFolder = workspace:WaitForChild("Enemies")

local CombatEffects = {}

local function enemiesNear(pos: Vector3, radius: number, except: Model?): { Model }
	local out = {}
	for _, model in enemiesFolder:GetChildren() do
		local root = model:IsA("Model") and model.PrimaryPart
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
	hitPos: Vector3,
	applyWeaponKnockback: boolean?
): (boolean, boolean)
	local ehum = model:FindFirstChildOfClass("Humanoid")
	if not ehum or ehum.Health <= 0 or model.Parent ~= enemiesFolder then
		return false, false
	end
	model:SetAttribute("LastHitBy", plr.UserId)
	ehum:TakeDamage(damage)
	local killed = ehum.Health <= 0
	local root = model.PrimaryPart
	local playerRoot = plr.Character
		and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and playerRoot and applyWeaponKnockback ~= false then
		local away = (root.Position - playerRoot.Position) * Vector3.new(1, 0, 1)
		if away.Magnitude > 0.01 then
			if root.Anchored then
				root.CFrame += away.Unit * Feel.KnockbackStuds
			else
				root:ApplyImpulse(away.Unit * Feel.KnockbackSpeed * root.AssemblyMass)
			end
		end
	end
	HitMarker:FireClient(plr, hitPos, math.floor(damage + 0.5), killed, model)
	return true, killed
end
CombatEffects.rawHit = rawHit

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
				FX:FireAllClients("chain", { Points = { root.Position, opos }, Color = color })
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
				FX:FireAllClients("chain", { Points = points, Color = color })
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
			FX:FireAllClients("pull", { Position = root.Position, Radius = radius, Color = color })
		end
	end
	return true, killed
end

-- Keep Players referenced for type checkers that flag unused services in strict mode.
local _ = Players

return CombatEffects
