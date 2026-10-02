--!strict
-- Dresses the checked-in arena at start with neon strips, portals, and a boss gate.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local Fit = require(ReplicatedStorage.Shared.Fit)
local ArenaLayout = require(ReplicatedStorage.Shared.ArenaLayout)
local Barrels = require(ReplicatedStorage.Shared.Barrels)
local LightingPresets = require(ReplicatedStorage.Shared.LightingPresets)
local ModelKey = require(ReplicatedStorage.Shared.ModelKey)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ModelLibrary = require(ServerStorage.ModelLibrary)

local arena = workspace:WaitForChild("Arena")

local function c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function normalizedColor(t: { number }): Color3
	return Color3.new(t[1], t[2], t[3])
end

local function applyLightingPreset(preset: any)
	local properties = preset.Lighting
	Lighting.Technology = Enum.Technology.Future
	Lighting.ClockTime = properties.ClockTime
	Lighting.Brightness = properties.Brightness
	Lighting.ExposureCompensation = properties.ExposureCompensation
	Lighting.GlobalShadows = properties.GlobalShadows
	Lighting.EnvironmentDiffuseScale = properties.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = properties.EnvironmentSpecularScale
	Lighting.ShadowSoftness = properties.ShadowSoftness
	Lighting.Ambient = normalizedColor(properties.Ambient)
	Lighting.OutdoorAmbient = normalizedColor(properties.OutdoorAmbient)
	Lighting.FogColor = normalizedColor(properties.FogColor)
	Lighting.FogStart = properties.FogStart
	Lighting.FogEnd = properties.FogEnd

	local atmosphere = Lighting:FindFirstChild("Atmosphere") :: Atmosphere
	atmosphere.Density = preset.Atmosphere.Density
	atmosphere.Offset = preset.Atmosphere.Offset
	atmosphere.Color = normalizedColor(preset.Atmosphere.Color)
	atmosphere.Decay = normalizedColor(preset.Atmosphere.Decay)
	atmosphere.Glare = preset.Atmosphere.Glare
	atmosphere.Haze = preset.Atmosphere.Haze

	local bloom = Lighting:FindFirstChild("Bloom") :: BloomEffect
	bloom.Intensity = preset.Bloom.Intensity
	bloom.Size = preset.Bloom.Size
	bloom.Threshold = preset.Bloom.Threshold

	local correction = Lighting:FindFirstChild("ColorCorrection") :: ColorCorrectionEffect
	correction.Contrast = preset.ColorCorrection.Contrast
	correction.Saturation = preset.ColorCorrection.Saturation
	correction.TintColor = normalizedColor(preset.ColorCorrection.TintColor)

	local sky = Lighting:FindFirstChild("Sky") :: Sky
	sky.StarCount = preset.Sky.StarCount
	sky.CelestialBodiesShown = preset.Sky.CelestialBodiesShown
	sky.SunAngularSize = preset.Sky.SunAngularSize
end

-- ---------- helpers ----------
local function part(
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = arena
	return p
end

local function placeArenaAsset(name: string, size: Vector3, cf: CFrame): boolean
	local model = ModelLibrary.get(ModelKey.make("arena", name))
	if not model then
		return false
	end
	local bounds = model:GetExtentsSize()
	model:ScaleTo(Fit.scaleFor({ bounds.X, bounds.Y, bounds.Z }, { size.X, size.Y, size.Z }))
	model.Name = name
	model:PivotTo(cf)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = true
		end
	end
	model.Parent = arena
	return true
end

local function neonStrip(size: Vector3, cf: CFrame, color: Color3, range: number?)
	local longest = math.max(size.X, size.Y, size.Z)
	local segmentCount = math.ceil(longest / 12)
	local segmentSize = size
	local axis = Vector3.new(1, 0, 0)
	if size.Y == longest then
		segmentSize = Vector3.new(size.X, size.Y / segmentCount, size.Z)
		axis = Vector3.new(0, 1, 0)
	elseif size.Z == longest then
		segmentSize = Vector3.new(size.X, size.Y, size.Z / segmentCount)
		axis = Vector3.new(0, 0, 1)
	else
		segmentSize = Vector3.new(size.X / segmentCount, size.Y, size.Z)
	end

	for index = 1, segmentCount do
		local offset = (index - (segmentCount + 1) / 2) * longest / segmentCount
		local p =
			part("Neon", segmentSize, cf * CFrame.new(axis * offset), color, Enum.Material.Neon)
		p.CanCollide = false
		p.CanQuery = false
		if range and range > 0 and index == math.ceil(segmentCount / 2) then
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = range
			light.Brightness = 1.2
			light.Parent = p
		end
	end
end

local function retexture()
	local floor = arena:FindFirstChild("Floor") :: BasePart?
	if floor then
		floor.Material = Enum.Material.Concrete
		floor.Color = c3(Theme.Floor)
	end
	for _, name in { "WallN", "WallS", "WallE", "WallW" } do
		local w = arena:FindFirstChild(name) :: BasePart?
		if w then
			w.Material = Enum.Material.Metal
			w.Color = c3(Theme.Wall)
		end
	end
	for _, name in { "TowerA", "TowerB", "TowerA_Step", "TowerB_Step", "Ledge", "GapPillar" } do
		local p = arena:FindFirstChild(name) :: BasePart?
		if p then
			p.Material = Enum.Material.DiamondPlate
			p.Color = c3(Theme.Metal)
		end
	end
end

-- Dark, non-glowing seams give the bright floor scale without overpowering combat.
local function floorGrid()
	local trim = c3(Theme.FloorTrim)
	for i = -3, 3 do
		local northSouth = part(
			"GridLine",
			Vector3.new(0.3, 0.08, 156),
			CFrame.new(i * 22, 1.05, 0),
			trim,
			Enum.Material.SmoothPlastic
		)
		northSouth.CanCollide = false
		northSouth.CanQuery = false
		local eastWest = part(
			"GridLine",
			Vector3.new(156, 0.08, 0.3),
			CFrame.new(0, 1.05, i * 22),
			trim,
			Enum.Material.SmoothPlastic
		)
		eastWest.CanCollide = false
		eastWest.CanQuery = false
	end
	-- center emblem
	local emblem = part(
		"Emblem",
		Vector3.new(0.1, 8, 8),
		CFrame.new(0, 1.06, 0) * CFrame.Angles(0, 0, math.rad(90)),
		c3(Theme.FloorTrim),
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	emblem.CanCollide = false
	emblem.CanQuery = false
	local ring = part(
		"EmblemRing",
		Vector3.new(0.12, 10, 10),
		CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		c3(Theme.NeonTeal),
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Transparency = 0.4
end

-- Wall trims, hazard lights and catwalk railings.
local function wallsAndRails()
	local amber = c3(Theme.NeonAmber)
	local teal = c3(Theme.NeonTeal)
	for _, spec in
		{
			{ CFrame.new(0, 19, -79), Vector3.new(158, 0.4, 0.4) },
			{ CFrame.new(0, 19, 79), Vector3.new(158, 0.4, 0.4) },
			{ CFrame.new(79, 19, 0), Vector3.new(0.4, 0.4, 158) },
			{ CFrame.new(-79, 19, 0), Vector3.new(0.4, 0.4, 158) },
		}
	do
		neonStrip(spec[2] :: Vector3, spec[1] :: CFrame, teal, 18)
	end
	-- hazard lights at the corners
	for _, x in { -76, 76 } do
		for _, z in { -76, 76 } do
			local post = part(
				"Post",
				Vector3.new(1, 18, 1),
				CFrame.new(x, 10, z),
				c3(Theme.MetalDark),
				Enum.Material.Metal
			)
			post.CanCollide = true
			neonStrip(Vector3.new(1.4, 1.4, 1.4), CFrame.new(x, 19.5, z), amber, 26)
		end
	end
	-- railings on the towers and ledge
	local function rail(cf: CFrame, len: number)
		neonStrip(Vector3.new(len, 0.2, 0.2), cf, teal, 0)
	end
	rail(CFrame.new(45, 17.2, -22), 14)
	rail(CFrame.new(45, 17.2, -8), 14)
	rail(CFrame.new(-40, 21.2, 27), 16)
	rail(CFrame.new(-40, 21.2, 43), 16)
	rail(CFrame.new(0, 14.2, 55), 30)
end

local function spawnRing(cf: CFrame, color: Color3)
	local radius = 3
	for index = 0, 7 do
		local angle = index * math.pi / 4
		local marker = part(
			"SpawnRing",
			Vector3.new(2.2, 0.12, 0.35),
			cf
				* CFrame.new(radius * math.cos(angle), 0.1, radius * math.sin(angle))
				* CFrame.Angles(0, -angle, 0),
			color,
			Enum.Material.Neon
		)
		marker.CanCollide = false
		marker.CanQuery = false
	end
end

-- Compact floor rings mark enemy spawns without obscuring enemies or sightlines.
local function portals()
	local teal = c3(Theme.NeonTeal)
	local amber = c3(Theme.NeonAmber)
	local spawns = arena:FindFirstChild("EnemySpawns")
	if spawns then
		for index, sp in spawns:GetChildren() do
			if sp:IsA("BasePart") then
				local markerColor = if index % 2 == 0 then amber else teal
				spawnRing(sp.CFrame, markerColor)
				local light = Instance.new("PointLight")
				light.Color = markerColor
				light.Range = 10
				light.Brightness = 0.8
				light.Parent = sp
				local att = Instance.new("Attachment")
				att.Parent = sp
				local pe = Instance.new("ParticleEmitter")
				pe.Color = ColorSequence.new(markerColor)
				pe.Size = NumberSequence.new(0.6, 0)
				pe.Transparency = NumberSequence.new(0.5, 1)
				pe.Lifetime = NumberRange.new(0.8, 1.4)
				pe.Rate = 10
				pe.Speed = NumberRange.new(2, 4)
				pe.SpreadAngle = Vector2.new(60, 60)
				pe.LightEmission = 1
				pe.Parent = att
			end
		end
	end
	local boss = arena:FindFirstChild("BossSpawn") :: BasePart?
	if boss then
		boss.Transparency = 1
		if
			not placeArenaAsset(
				"BossGate",
				Vector3.new(21, 22, 4),
				boss.CFrame * CFrame.new(0, 10, 0)
			)
		then
			for _, sign in { -1, 1 } do
				local pillar = part(
					"GatePillar",
					Vector3.new(3, 22, 3),
					boss.CFrame * CFrame.new(sign * 9, 10, 0),
					c3(Theme.MetalDark),
					Enum.Material.Metal
				)
				pillar.CanCollide = true
				neonStrip(
					Vector3.new(0.4, 20, 0.4),
					boss.CFrame * CFrame.new(sign * 9, 10, -1.7),
					amber,
					24
				)
			end
			local top = part(
				"GateTop",
				Vector3.new(21, 2.5, 3),
				boss.CFrame * CFrame.new(0, 21, 0),
				c3(Theme.MetalDark),
				Enum.Material.Metal
			)
			top.CanCollide = true
			neonStrip(Vector3.new(19, 0.4, 0.4), boss.CFrame * CFrame.new(0, 19.6, -1.7), amber, 30)
		end
	end
end

local function energyBarrels()
	local existing = workspace:FindFirstChild("Barrels")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Barrels"
	folder.Parent = workspace
	local reset = Instance.new("BindableEvent")
	reset.Name = "Reset"
	reset.Parent = folder
	local teal = c3(Barrels.Color)
	for rowIndex, row in ArenaLayout.BarrelRows do
		for index = 1, row.Count do
			local offset = (index - (row.Count + 1) / 2) * row.Spacing
			local x = row.x + (if row.Axis == "X" then offset else 0)
			local z = row.z + (if row.Axis == "Z" then offset else 0)
			local model = Instance.new("Model")
			model.Name = string.format("EnergyBarrel_%d_%d", rowIndex, index)
			model:SetAttribute("IsEnergyBarrel", true)
			model:SetAttribute("Health", Barrels.Health)
			model:SetAttribute("Spent", false)
			model:SetAttribute("Queued", false)
			local cf = CFrame.new(x, 3.5, z) * CFrame.Angles(0, 0, math.rad(90))
			local core = part(
				"Core",
				Vector3.new(5, 3.5, 3.5),
				cf,
				c3(Theme.MetalDark),
				Enum.Material.Metal,
				Enum.PartType.Cylinder
			)
			core.Parent = model
			local energy = part(
				"Energy",
				Vector3.new(3.8, 3.65, 3.65),
				cf,
				teal,
				Enum.Material.Neon,
				Enum.PartType.Cylinder
			)
			energy.CanCollide = false
			energy.Parent = model
			model.PrimaryPart = core
			model.Parent = folder
		end
	end
end

applyLightingPreset(LightingPresets.Station)
retexture()
floorGrid()
wallsAndRails()
portals()
energyBarrels()
