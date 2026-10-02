--!strict
-- Builds a held weapon model from parts, colored by rarity, and welds it to the right hand.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local ModelKey = require(ReplicatedStorage.Shared.ModelKey)
local ModelLibrary = require(ServerStorage.ModelLibrary)

local WeaponModels = {}

local function c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function part(
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Shape = shape or Enum.PartType.Block
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function weldTo(base: BasePart, p: BasePart, offset: CFrame)
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = base
end

-- Shape per weapon. Origin = grip; barrel points -Z.
local shapes: { [string]: (Model, BasePart, Color3, Color3) -> () } = {}

local function basicGun(
	model: Model,
	grip: BasePart,
	dark: Color3,
	accent: Color3,
	bodyLen: number,
	barrelLen: number,
	barrelR: number
)
	local body = part(Vector3.new(0.35, 0.45, bodyLen), dark)
	body.Parent = model
	weldTo(grip, body, CFrame.new(0, 0.45, -bodyLen / 2 + 0.2))
	local barrel = part(
		Vector3.new(barrelLen, barrelR, barrelR),
		dark:Lerp(Color3.new(0, 0, 0), 0.3),
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	barrel.Parent = model
	weldTo(
		body,
		barrel,
		CFrame.new(0, 0.05, -bodyLen / 2 - barrelLen / 2) * CFrame.Angles(0, math.rad(90), 0)
	)
	local strip = part(Vector3.new(0.12, 0.12, bodyLen * 0.7), accent, Enum.Material.Neon)
	strip.Parent = model
	weldTo(body, strip, CFrame.new(0, 0.28, 0))
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(barrelLen / 2, 0, 0)
	muzzle.Parent = barrel
end

shapes.Starter = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 1.0, 0.6, 0.18)
end
shapes.Burst = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 1.4, 0.8, 0.16)
	local mag = part(Vector3.new(0.25, 0.7, 0.35), dark)
	mag.Parent = model
	weldTo(grip, mag, CFrame.new(0, 0.1, -0.7))
end
shapes.Scatter = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 1.6, 1.2, 0.22)
	local barrel2 =
		part(Vector3.new(1.2, 0.22, 0.22), dark, Enum.Material.Metal, Enum.PartType.Cylinder)
	barrel2.Parent = model
	weldTo(grip, barrel2, CFrame.new(0.22, 0.5, -2.0) * CFrame.Angles(0, math.rad(90), 0))
end
shapes.Marksman = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 2.0, 1.8, 0.14)
	local scope =
		part(Vector3.new(0.7, 0.2, 0.2), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	scope.Parent = model
	weldTo(grip, scope, CFrame.new(0, 0.85, -0.5) * CFrame.Angles(0, math.rad(90), 0))
end
shapes.Arc = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 1.5, 0.9, 0.2)
	for i = 1, 3 do
		local fin =
			part(Vector3.new(0.08, 0.5, 0.6), accent, Enum.Material.Neon, Enum.PartType.Wedge)
		fin.Parent = model
		weldTo(
			grip,
			fin,
			CFrame.new(0, 0.5, -1.4)
				* CFrame.Angles(0, 0, math.rad(120 * i))
				* CFrame.new(0, 0.35, 0)
		)
	end
end
shapes.Hornet = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 1.6, 1.0, 0.34)
	local drum =
		part(Vector3.new(0.7, 0.7, 0.7), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	drum.Parent = model
	weldTo(grip, drum, CFrame.new(0, 0.2, -1.0) * CFrame.Angles(0, 0, math.rad(90)))
end
shapes.Nova = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 2.2, 1.4, 0.45)
	for i = 0, 3 do
		local ring =
			part(Vector3.new(0.1, 0.8, 0.8), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
		ring.Parent = model
		weldTo(grip, ring, CFrame.new(0, 0.5, -1.2 - i * 0.5) * CFrame.Angles(0, math.rad(90), 0))
	end
end

-- ----- melee -----
local function blade(
	model: Model,
	grip: BasePart,
	dark: Color3,
	accent: Color3,
	length: number,
	width: number,
	glow: boolean
)
	local guard = part(Vector3.new(0.9, 0.15, 0.4), dark)
	guard.Parent = model
	weldTo(grip, guard, CFrame.new(0, 0.45, 0))
	local edge = part(
		Vector3.new(width, length, 0.12),
		if glow then accent else dark:Lerp(Color3.new(1, 1, 1), 0.5),
		if glow then Enum.Material.Neon else Enum.Material.Metal
	)
	edge.Parent = model
	weldTo(grip, edge, CFrame.new(0, 0.5 + length / 2, 0))
	local tip =
		part(Vector3.new(width, width, 0.12), edge.Color, edge.Material, Enum.PartType.Wedge)
	tip.Parent = model
	weldTo(edge, tip, CFrame.new(0, length / 2 + width / 2, 0) * CFrame.Angles(0, math.rad(90), 0))
	local line = part(Vector3.new(0.06, length * 0.9, 0.14), accent, Enum.Material.Neon)
	line.Parent = model
	weldTo(edge, line, CFrame.new(0, 0, 0))
end

shapes.Blade = function(model, grip, dark, accent)
	blade(model, grip, dark, accent, 2.6, 0.45, false)
end
shapes.Saber = function(model, grip, dark, accent)
	blade(model, grip, dark, accent, 3.2, 0.3, true)
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 10
	light.Parent = grip
end
shapes.Hammer = function(model, grip, dark, accent)
	local handle =
		part(Vector3.new(0.25, 3.0, 0.25), dark, Enum.Material.Metal, Enum.PartType.Cylinder)
	handle.Size = Vector3.new(3.0, 0.25, 0.25)
	handle.Parent = model
	weldTo(grip, handle, CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)))
	local head = part(Vector3.new(1.4, 0.9, 0.9), dark)
	head.Parent = model
	weldTo(grip, head, CFrame.new(0, 3.2, 0))
	for _, sign in { -1, 1 } do
		local cap = part(Vector3.new(0.2, 1.0, 1.0), accent, Enum.Material.Neon)
		cap.Parent = model
		weldTo(head, cap, CFrame.new(sign * 0.8, 0, 0))
	end
end
shapes.Reaper = function(model, grip, dark, accent)
	local shaft =
		part(Vector3.new(4.2, 0.22, 0.22), dark, Enum.Material.Metal, Enum.PartType.Cylinder)
	shaft.Parent = model
	weldTo(grip, shaft, CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
	local curve = part(Vector3.new(0.3, 0.3, 2.8), dark)
	curve.Parent = model
	weldTo(grip, curve, CFrame.new(0, 4.3, -1.2))
	local edge = part(Vector3.new(0.12, 1.0, 2.8), accent, Enum.Material.Neon, Enum.PartType.Wedge)
	edge.Parent = model
	weldTo(curve, edge, CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(180)))
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 12
	light.Brightness = 2
	light.Parent = curve
	local att = Instance.new("Attachment")
	att.Parent = edge
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(accent)
	pe.Size = NumberSequence.new(0.5, 0)
	pe.Transparency = NumberSequence.new(0.3, 1)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Rate = 25
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.LightEmission = 1
	pe.Parent = att
end

-- ----- orbital: a small emitter held in hand; the orbs themselves come from OrbitalRunner -----
local function emitter(model: Model, grip: BasePart, dark: Color3, accent: Color3, rings: number)
	local core = part(Vector3.new(0.6, 0.6, 0.6), accent, Enum.Material.Neon, Enum.PartType.Ball)
	core.Parent = model
	weldTo(grip, core, CFrame.new(0, 0.9, 0))
	for i = 1, rings do
		local ring = part(
			Vector3.new(0.08, 1.0 + i * 0.25, 1.0 + i * 0.25),
			dark:Lerp(accent, 0.4),
			Enum.Material.Metal,
			Enum.PartType.Cylinder
		)
		ring.Parent = model
		weldTo(core, ring, CFrame.Angles(math.rad(35 * i), math.rad(60 * i), 0))
	end
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 8
	light.Parent = core
end
shapes.Guardian = function(model, grip, dark, accent)
	emitter(model, grip, dark, accent, 1)
end
shapes.Storm = function(model, grip, dark, accent)
	emitter(model, grip, dark, accent, 2)
end
shapes.Halo = function(model, grip, dark, accent)
	emitter(model, grip, dark, accent, 3)
end

-- ----- beam -----
shapes.Ion = function(model, grip, dark, accent)
	basicGun(model, grip, dark, accent, 1.8, 0.4, 0.3)
	local coil =
		part(Vector3.new(1.2, 0.5, 0.5), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	coil.Transparency = 0.3
	coil.Parent = model
	weldTo(grip, coil, CFrame.new(0, 0.5, -1.6) * CFrame.Angles(0, math.rad(90), 0))
	local tank =
		part(Vector3.new(0.4, 0.4, 0.9), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	tank.Parent = model
	weldTo(grip, tank, CFrame.new(0, 0.85, -0.3) * CFrame.Angles(0, math.rad(90), 0))
end

function WeaponModels.build(id: string): Model
	local imported = ModelLibrary.get(ModelKey.make("weapons", id))
	if imported then
		local body = imported:FindFirstChild("Body", true)
		if body and body:IsA("BasePart") then
			imported.Name = "Weapon"
			imported.PrimaryPart = body
			for _, descendant in imported:GetDescendants() do
				if descendant:IsA("BasePart") and descendant ~= body then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = body
					weld.Part1 = descendant
					weld.Parent = body
				end
			end
			return imported
		end
		imported:Destroy()
	end
	local def = Weapons.Defs[id] or Weapons.Defs.Starter
	local accent = c3(Theme.Rarity[def.Rarity])
	local dark = c3(Theme.MetalDark)
	local model = Instance.new("Model")
	model.Name = "Weapon"
	local grip = part(Vector3.new(0.3, 0.7, 0.35), dark)
	grip.Name = "Grip"
	grip.Parent = model
	model.PrimaryPart = grip
	local shape = shapes[id] or shapes.Starter
	shape(model, grip, dark, accent)
	return model
end

-- Attach to the character's right hand (R15) or right arm (R6).
-- Hand offset per kind: guns point forward (-Z of the grip already faces forward),
-- melee/orbital tools stand up along the hand's forward axis.
local function gripOffset(id: string): CFrame
	local def = Weapons.Defs[id] or Weapons.Defs.Starter
	if def.Kind == "Hitscan" or def.Kind == "Beam" then
		return CFrame.new(0, -0.3, 0) * CFrame.Angles(0, 0, 0)
	end
	return CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

-- Evolution dressing: the weapon's neon accents take the element's color; tier 2 adds particles,
-- tier 3 adds a light. Keeps the weapon recognisable while showing its path at a glance.
function WeaponModels.applyEvolution(model: Model, evo: Evolutions.WeaponEvo?)
	if not evo or evo.Tier <= 0 then
		return
	end
	local el = Evolutions.Elements[evo.Element]
	if not el then
		return
	end
	local color = c3(el.Color)
	for _, d in model:GetDescendants() do
		if (d:IsA("BasePart") and d.Material == Enum.Material.Neon) or d:IsA("PointLight") then
			d.Color = color
		elseif d:IsA("ParticleEmitter") then
			d.Color = ColorSequence.new(color)
		end
	end
	local grip = model.PrimaryPart
	if not grip then
		return
	end
	if evo.Tier >= 2 then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "EvoParticles"
		pe.Color = ColorSequence.new(color)
		pe.Size = NumberSequence.new(0.18, 0)
		pe.Transparency = NumberSequence.new(0.3, 1)
		pe.Lifetime = NumberRange.new(0.4, 0.8)
		pe.Rate = 8 + evo.Tier * 4
		pe.Speed = NumberRange.new(0.5, 1.5)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LightEmission = 1
		pe.Parent = grip
	end
	if evo.Tier >= 3 then
		local light = Instance.new("PointLight")
		light.Name = "EvoLight"
		light.Color = color
		light.Brightness = 1.5
		light.Range = 8
		light.Parent = grip
	end
	model:SetAttribute("Element", evo.Element)
	model:SetAttribute("Tier", evo.Tier)
end

-- Attach to the character's right hand (R15) or right arm (R6).
function WeaponModels.attach(char: Model, id: string, evo: Evolutions.WeaponEvo?)
	local old = char:FindFirstChild("Weapon")
	if old then
		old:Destroy()
	end
	local hand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not hand then
		return
	end
	local model = WeaponModels.build(id)
	WeaponModels.applyEvolution(model, evo)
	local grip = model.PrimaryPart :: BasePart
	local offset = gripOffset(id)
	model:PivotTo(hand.CFrame * offset)
	local w = Instance.new("Motor6D")
	w.Name = "GripMotor"
	w.Part0 = hand
	w.Part1 = grip
	w.C0 = offset
	w.Parent = hand
	model.Parent = char
end

return WeaponModels
