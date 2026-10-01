--!strict
-- Orbital weapons: orbs circle the player on the server and damage enemies they pass through.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerData = require(ServerStorage.PlayerData)
local CombatEffects = require(ServerStorage.CombatEffects)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Theme = require(ReplicatedStorage.Shared.Theme)

local enemiesFolder = workspace:WaitForChild("Enemies")

type Orbit = {
	Player: Player,
	Weapon: Weapons.WeaponDef,
	Orbs: { BasePart },
	Angle: number,
	LastHit: { [Model]: number },
}
local orbits: { [Player]: Orbit } = {}

local function c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function clear(plr: Player)
	local o = orbits[plr]
	if o then
		for _, orb in o.Orbs do
			orb:Destroy()
		end
		orbits[plr] = nil
	end
end

local function makeOrb(color: Color3, size: number, legendary: boolean): BasePart
	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(size, size, size)
	orb.Color = color
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 8
	light.Brightness = 1.5
	light.Parent = orb
	local att = Instance.new("Attachment")
	att.Parent = orb
	local trail = Instance.new("ParticleEmitter")
	trail.Color = ColorSequence.new(color)
	trail.Size = NumberSequence.new(size * 0.8, 0)
	trail.Transparency = NumberSequence.new(0.3, 1)
	trail.Lifetime = NumberRange.new(0.25, 0.4)
	trail.Rate = if legendary then 40 else 20
	trail.Speed = NumberRange.new(0, 0)
	trail.LightEmission = 1
	trail.Parent = att
	if not legendary then
		-- blade look: a thin neon wedge welded through the orb
		local blade = Instance.new("Part")
		blade.Shape = Enum.PartType.Wedge
		blade.Size = Vector3.new(0.2, size * 1.6, size * 0.8)
		blade.Color = color
		blade.Material = Enum.Material.Neon
		blade.Anchored = true
		blade.CanCollide = false
		blade.CanQuery = false
		blade.Parent = orb
	end
	orb.Parent = workspace
	return orb
end

local function refresh(plr: Player)
	clear(plr)
	local weapon = PlayerData.equippedWeapon(plr)
	if weapon.Kind ~= "Orbital" or not plr.Character then
		return
	end
	local color = c3(Theme.Rarity[weapon.Rarity])
	local orbs = {}
	for _ = 1, weapon.Pellets do
		table.insert(
			orbs,
			makeOrb(
				color,
				if weapon.Rarity == "Legendary" then 1.8 else 1.1,
				weapon.Rarity == "Legendary"
			)
		)
	end
	orbits[plr] = { Player = plr, Weapon = weapon, Orbs = orbs, Angle = 0, LastHit = {} }
end

RunService.Heartbeat:Connect(function(dt)
	for plr, o in orbits do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not hum or hum.Health <= 0 then
			continue
		end
		local w = o.Weapon
		for m in o.LastHit do
			if not m.Parent then
				o.LastHit[m] = nil
			end
		end
		o.Angle += dt * 2.6 -- radians per second
		local n = #o.Orbs
		local damage = w.Damage * PlayerData.damageMultiplier(plr)
		local hitGap = 1 / (w.FireRate * PlayerData.fireRateMultiplier(plr))
		local now = os.clock()
		for i, orb in o.Orbs do
			local a = o.Angle + (i - 1) * (2 * math.pi / n)
			local pos = root.Position
				+ Vector3.new(
					math.cos(a) * w.Range,
					0.5 + math.sin(now * 3 + i) * 0.4,
					math.sin(a) * w.Range
				)
			orb.CFrame = CFrame.lookAt(pos, root.Position) * CFrame.Angles(0, 0, a)
			local blade = orb:FindFirstChild("Part") :: BasePart?
			if blade then
				blade.CFrame = orb.CFrame * CFrame.Angles(0, 0, now * 12)
			end
			for _, model in enemiesFolder:GetChildren() do
				local eroot = model:IsA("Model") and model.PrimaryPart
				if
					eroot
					and (eroot.Position - pos).Magnitude
						<= orb.Size.X / 2 + eroot.Size.Magnitude / 2
				then
					local m = model :: Model
					if now - (o.LastHit[m] or 0) >= hitGap then
						o.LastHit[m] = now
						CombatEffects.hit(plr, m, damage, eroot.Position)
					end
				end
			end
		end
	end
end)

-- Refresh when the equipped weapon or character changes.
local function watch(plr: Player)
	plr.CharacterAdded:Connect(function()
		task.wait(0.2)
		refresh(plr)
	end)
	plr.CharacterRemoving:Connect(function()
		clear(plr)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, plr in Players:GetPlayers() do
	watch(plr)
end
Players.PlayerRemoving:Connect(clear)

-- PlayerData calls this on every equip so the orbit matches the weapon.
PlayerData.OnEquipChanged = function(plr: Player)
	refresh(plr)
end
