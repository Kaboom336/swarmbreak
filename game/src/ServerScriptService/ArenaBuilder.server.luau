--!strict
-- Dresses the arena at start: lighting, materials, neon strips, props, spawn portals, boss gate.
-- Static geometry lives in src/Workspace/Arena (model JSON); this adds everything decorative.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Fit = require(ReplicatedStorage.Shared.Fit)
local ModelKey = require(ReplicatedStorage.Shared.ModelKey)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ModelLibrary = require(ServerStorage.ModelLibrary)
local arenaLayoutModule = ReplicatedStorage.Shared:FindFirstChild("ArenaLayout")
local ArenaLayout = if arenaLayoutModule and arenaLayoutModule:IsA("ModuleScript")
	then require(arenaLayoutModule)
	else nil

local arena = workspace:WaitForChild("Arena")
local rng = Random.new(7)

local function c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- ---------- lighting ----------
local function setupLighting()
	Lighting.ClockTime = 18.6
	Lighting.Brightness = 2
	Lighting.Ambient = c3({ 40, 40, 56 })
	Lighting.OutdoorAmbient = c3({ 70, 66, 92 })
	Lighting.FogColor = c3({ 14, 14, 26 })
	Lighting.FogStart = 90
	Lighting.FogEnd = 420

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.42
	atmo.Offset = 0.3
	atmo.Color = c3({ 120, 110, 150 })
	atmo.Decay = c3({ 40, 30, 70 })
	atmo.Glare = 0.3
	atmo.Haze = 2.2
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 32
	bloom.Threshold = 1.2
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Contrast = 0.15
	cc.Saturation = 0.1
	cc.TintColor = c3({ 235, 235, 255 })
	cc.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.08
	rays.Spread = 0.6
	rays.Parent = Lighting

	local sky = Instance.new("Sky")
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting
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
	local p = part("Neon", size, cf, color, Enum.Material.Neon)
	p.CanCollide = false
	p.CanQuery = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range or 14
	light.Brightness = 1.2
	light.Parent = p
	return p
end

local function retexture()
	local floor = arena:FindFirstChild("Floor") :: BasePart?
	if floor then
		floor.Material = Enum.Material.Slate
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

-- Grid of floor panels + glowing seams so the ground has scale and reads in motion.
local function floorGrid()
	local teal = c3(Theme.NeonTeal)
	for i = -3, 3 do
		neonStrip(
			Vector3.new(0.3, 0.08, 156),
			CFrame.new(i * 22, 1.05, 0),
			teal:Lerp(Color3.new(0, 0, 0), 0.55),
			0
		)
		neonStrip(
			Vector3.new(156, 0.08, 0.3),
			CFrame.new(0, 1.05, i * 22),
			teal:Lerp(Color3.new(0, 0, 0), 0.55),
			0
		)
	end
	-- center emblem
	local emblem = part(
		"Emblem",
		Vector3.new(0.1, 18, 18),
		CFrame.new(0, 1.06, 0) * CFrame.Angles(0, 0, math.rad(90)),
		c3(Theme.FloorTrim),
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	emblem.CanCollide = false
	emblem.CanQuery = false
	local ring = part(
		"EmblemRing",
		Vector3.new(0.12, 20, 20),
		CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		teal,
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
		local r = part("Rail", Vector3.new(len, 0.2, 0.2), cf, teal, Enum.Material.Neon)
		r.CanCollide = false
		r.CanQuery = false
	end
	rail(CFrame.new(45, 17.2, -22), 14)
	rail(CFrame.new(45, 17.2, -8), 14)
	rail(CFrame.new(-40, 21.2, 27), 16)
	rail(CFrame.new(-40, 21.2, 43), 16)
	rail(CFrame.new(0, 14.2, 55), 30)
end

-- Cover: crates, barrels, broken pillars, scattered around but off the spawn lines.
local function props()
	local metal = c3(Theme.Metal)
	local dark = c3(Theme.MetalDark)
	local amber = c3(Theme.NeonAmber)
	if ArenaLayout then
		for _, spec in ArenaLayout.Props do
			local size = Vector3.new(spec.Width, spec.Height, spec.Depth)
			local cf = CFrame.new(spec.x, 1 + spec.Height / 2, spec.z)
			if not placeArenaAsset(spec.Kind, size, cf) then
				part(
					spec.Kind,
					size,
					cf,
					if spec.Kind == "Crate" then metal else dark,
					if spec.Kind == "Crate" then Enum.Material.DiamondPlate else Enum.Material.Metal
				).CanCollide =
					true
			end
		end
		return
	end
	local spots = {
		{ 20, 20 },
		{ -22, -18 },
		{ 50, 40 },
		{ -55, -40 },
		{ 25, -52 },
		{ -30, 55 },
		{ 60, -35 },
		{ -60, 15 },
		{ 5, 35 },
		{ -8, -35 },
	}
	for i, s in spots do
		local x, z = s[1], s[2]
		local ang = rng:NextNumber(0, math.pi * 2)
		if i % 3 == 0 then
			-- barrel cluster
			for j = 0, 2 do
				local size = Vector3.new(3.2, 2.4, 2.4)
				local cf = CFrame.new(x + j * 2.6, 2.6, z + (j % 2) * 2.2)
					* CFrame.Angles(0, 0, math.rad(90))
				if not placeArenaAsset("Barrel", size, cf) then
					local b = part(
						"Barrel",
						size,
						cf,
						if j == 1 then amber:Lerp(dark, 0.5) else dark,
						Enum.Material.Metal,
						Enum.PartType.Cylinder
					)
					b.CanCollide = true
				end
			end
		elseif i % 3 == 1 then
			-- crate stack
			local lowerCf = CFrame.new(x, 3, z) * CFrame.Angles(0, ang, 0)
			if not placeArenaAsset("Crate", Vector3.new(4, 4, 4), lowerCf) then
				part("Crate", Vector3.new(4, 4, 4), lowerCf, metal, Enum.Material.DiamondPlate).CanCollide =
					true
			end
			local upperCf = CFrame.new(x + 1, 6.5, z - 0.5) * CFrame.Angles(0, ang + 0.4, 0)
			if not placeArenaAsset("Crate", Vector3.new(3, 3, 3), upperCf) then
				part("Crate", Vector3.new(3, 3, 3), upperCf, dark, Enum.Material.DiamondPlate).CanCollide =
					true
			end
			neonStrip(
				Vector3.new(4.1, 0.15, 0.15),
				CFrame.new(x, 5.05, z + 2) * CFrame.Angles(0, ang, 0),
				amber,
				8
			)
		else
			-- broken pillar
			local height = rng:NextNumber(5, 9)
			local pillarCf = CFrame.new(x, 4.5, z) * CFrame.Angles(0, ang, 0)
			if not placeArenaAsset("Pillar", Vector3.new(3, height, 3), pillarCf) then
				part("Pillar", Vector3.new(3, height, 3), pillarCf, metal, Enum.Material.Concrete).CanCollide =
					true
				part(
					"PillarTop",
					Vector3.new(3.4, 0.6, 3.4),
					CFrame.new(x, 8.2, z) * CFrame.Angles(math.rad(8), ang, 0),
					dark,
					Enum.Material.Concrete
				).CanCollide =
					true
			end
		end
	end
end

-- Build the v2 pieces from data when it is available. The checked-in model JSON remains
-- the fallback, so an older place without ArenaLayout still starts with its existing arena.
local function applyArenaLayout()
	if not ArenaLayout then
		return
	end

	local floor = arena:FindFirstChild("Floor") :: BasePart?
	if floor then
		floor.Size = Vector3.new(ArenaLayout.Floor, floor.Size.Y, ArenaLayout.Floor)
	end

	local spawnFolder = arena:FindFirstChild("EnemySpawns")
	if spawnFolder then
		for i, position in ArenaLayout.Spawns do
			local spawn = spawnFolder:FindFirstChild("Spawn" .. i)
			if spawn and spawn:IsA("BasePart") then
				spawn.Position = Vector3.new(position.x, spawn.Position.Y, position.z)
			end
		end
	end

	for i, spec in ArenaLayout.Bunkers do
		part(
			"Bunker" .. i,
			Vector3.new(spec.Width, spec.Height, spec.Depth),
			CFrame.new(spec.x, 1 + spec.Height / 2, spec.z),
			c3(Theme.MetalDark),
			Enum.Material.DiamondPlate
		).CanCollide =
			true
	end

	local ring = ArenaLayout.Ring
	local ringRadius = (ring.OuterDiameter - ring.Thickness) / 2
	local segmentCount = 12
	local arcStride = 2 * math.pi * ringRadius / segmentCount
	local segmentLength = 2 * arcStride - ring.Gap
	for i = 0, segmentCount - 1 do
		-- Four omitted segments make the compass-point gaps.
		if i % 3 ~= 0 then
			local angle = i * 2 * math.pi / segmentCount
			local ringPart = part(
				"Ring",
				Vector3.new(segmentLength, ring.Height, ring.Thickness),
				CFrame.new(
					ringRadius * math.cos(angle),
					1 + ring.Height / 2,
					ringRadius * math.sin(angle)
				) * CFrame.Angles(0, -angle - math.pi / 2, 0),
				c3(Theme.Metal),
				Enum.Material.Metal
			)
			ringPart.CanCollide = true
		end
	end

	for _, spec in ArenaLayout.Beacons do
		local beacon = part(
			"Beacon" .. spec.Name,
			Vector3.new(spec.Width, spec.Height, spec.Width),
			CFrame.new(spec.x, 1 + spec.Height / 2, spec.z),
			c3(spec.Color),
			Enum.Material.Neon
		)
		beacon.CanCollide = false
		beacon.CanQuery = false
	end
end

-- Portals at each enemy spawn and a big gate at the boss spawn.
local function portals()
	local swarm = c3(Theme.Swarm)
	local red = c3(Theme.NeonRed)
	local spawns = arena:FindFirstChild("EnemySpawns")
	if spawns then
		for _, sp in spawns:GetChildren() do
			if sp:IsA("BasePart") then
				local ring = part(
					"Portal",
					Vector3.new(0.4, 9, 9),
					sp.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(0, math.rad(90), 0),
					swarm,
					Enum.Material.Neon,
					Enum.PartType.Cylinder
				)
				ring.CanCollide = false
				ring.CanQuery = false
				ring.Transparency = 0.35
				local light = Instance.new("PointLight")
				light.Color = swarm
				light.Range = 18
				light.Parent = ring
				local att = Instance.new("Attachment")
				att.Parent = ring
				local pe = Instance.new("ParticleEmitter")
				pe.Color = ColorSequence.new(swarm)
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
					red,
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
			neonStrip(Vector3.new(19, 0.4, 0.4), boss.CFrame * CFrame.new(0, 19.6, -1.7), red, 30)
		end
	end
	local wall = arena:FindFirstChild("LeaderboardWall") :: BasePart?
	if wall then
		neonStrip(
			Vector3.new(25, 0.3, 0.3),
			wall.CFrame * CFrame.new(0, 7.3, -0.6),
			c3(Theme.NeonAmber),
			20
		)
		neonStrip(
			Vector3.new(25, 0.3, 0.3),
			wall.CFrame * CFrame.new(0, -7.3, -0.6),
			c3(Theme.NeonAmber),
			20
		)
	end
end

setupLighting()
retexture()
applyArenaLayout()
floorGrid()
wallsAndRails()
props()
portals()
