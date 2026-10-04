--!strict
-- Dresses the checked-in arena at start with neon strips, portals, and a boss gate.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ArenaLayout = require(ReplicatedStorage.Shared.ArenaLayout)
local Fit = require(ReplicatedStorage.Shared.Fit)
local LightingPresets = require(ReplicatedStorage.Shared.LightingPresets)
local Maps = require(ReplicatedStorage.Shared.Maps)
local ModelKey = require(ReplicatedStorage.Shared.ModelKey)
local Theme = require(ReplicatedStorage.Shared.Theme)
local GameState = require(ServerStorage.GameState)
local ModelLibrary = require(ServerStorage.ModelLibrary)

local arena = workspace:WaitForChild("Arena")
local selectedMap = Maps.get(GameState.get("MapName"))

local function c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function normalizedColor(t: { number }): Color3
	return Color3.new(t[1], t[2], t[3])
end

local function applyLightingPreset(preset: any)
	local properties = preset.Lighting
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
	-- Exported pivots sit at the mesh origin (often the base), so centre the bounding box on cf;
	-- pivoting alone left the boss gate floating about 10 studs up.
	local boxCFrame = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + (cf.Position - boxCFrame.Position))
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = true
		end
	end
	model.Parent = arena
	return true
end

local function neonStrip(size: Vector3, cf: CFrame, color: Color3, range: number?, name: string?)
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
		local p = part(
			name or "Neon",
			segmentSize,
			cf * CFrame.new(axis * offset),
			color,
			if color == c3(Theme.Goo) then Enum.Material.Neon else Enum.Material.SmoothPlastic
		)
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

local function configureMap()
	arena:SetAttribute("MapName", selectedMap.Name)
	arena:SetAttribute("MapBoss", selectedMap.Boss)

	local floor = arena:FindFirstChild("Floor") :: BasePart?
	if floor then
		floor.Material = Enum.Material.SmoothPlastic
		floor.Color = c3(selectedMap.FloorColor)
	end

	local spawnFolder = arena:FindFirstChild("EnemySpawns")
	if spawnFolder then
		local spawnParts = {}
		for _, child in spawnFolder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(spawnParts, child)
			end
		end
		table.sort(spawnParts, function(a, b)
			return a.Name < b.Name
		end)
		for index, spawn in selectedMap.Spawns do
			local spawnPart = spawnParts[index]
			if spawnPart then
				spawnPart.Position = Vector3.new(spawn.x, spawnPart.Position.Y, spawn.z)
			end
		end
	end

	for _, name in { "WallN", "WallS", "WallE", "WallW" } do
		local w = arena:FindFirstChild(name) :: BasePart?
		if w then
			w.Material = Enum.Material.SmoothPlastic
			w.Color = c3(Theme.Wall)
		end
	end
	-- These legacy platforms occupied the new open fight space.
	for _, name in { "TowerA", "TowerB", "TowerA_Step", "TowerB_Step", "Ledge" } do
		local legacy = arena:FindFirstChild(name)
		if legacy then
			legacy:Destroy()
		end
	end
	for _, name in { "GapPillar" } do
		local p = arena:FindFirstChild(name) :: BasePart?
		if p then
			p.Material = Enum.Material.SmoothPlastic
			p.Color = c3(Theme.Metal)
		end
	end
end

local function cloudSea()
	local clouds = part(
		"CloudSea",
		Vector3.new(600, 2, 600),
		CFrame.new(0, -35, 0),
		c3(Theme.OutpostCream),
		Enum.Material.SmoothPlastic
	)
	clouds.Transparency = 0.35
	clouds.CanCollide = false
	clouds.CanQuery = false
end

local function outerCover()
	local layout = arena:FindFirstChild("ArenaLayout")
	if layout then
		for _, child in layout:GetChildren() do
			if
				child.Name == "Bunker"
				or child.Name:match("^Bunker%d+$")
				or child.Name == "Ring"
				or child.Name == "Crate"
				or child.Name == "LowWall"
				or child.Name == "Pillar"
			then
				child:Destroy()
			end
		end
	end

	for _, spec in ArenaLayout.Props do
		local cover = part(
			spec.Kind,
			Vector3.new(spec.Width, spec.Height, spec.Depth),
			CFrame.new(spec.x, 1 + spec.Height / 2, spec.z),
			c3(if spec.Kind == "Pillar" then Theme.Metal else Theme.PropPastel),
			Enum.Material.SmoothPlastic
		)
		cover.CanCollide = true
	end
end

-- Wide, bright lanes point outward without adding cover to the open fight space.
local function laneStripes()
	for _, stripe in Theme.LaneStripes do
		local angle = math.rad(stripe.Angle)
		local direction = Vector3.new(math.sin(angle), 0, -math.cos(angle))
		local centre = direction * (stripe.Length / 2)
		local cf = CFrame.new(centre + Vector3.new(0, 1 + stripe.Thickness / 2, 0))
			* CFrame.Angles(0, angle, 0)
		neonStrip(
			Vector3.new(stripe.Width, stripe.Thickness, stripe.Length),
			cf,
			c3(stripe.Color),
			nil,
			"LaneStripe"
		)
	end
	-- center emblem
	local emblem = part(
		"Emblem",
		Vector3.new(0.1, 8, 8),
		CFrame.new(0, 1.06, 0) * CFrame.Angles(0, 0, math.rad(90)),
		c3(Theme.FloorTrim),
		Enum.Material.SmoothPlastic,
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

local function gooPatches()
	local teal = c3(Theme.NeonTeal)
	for index, spec in
		{
			{ x = -30, z = -20, radius = 6 },
			{ x = 24, z = -28, radius = 4 },
			{ x = 30, z = 22, radius = 7 },
			{ x = -22, z = 30, radius = 5 },
		}
	do
		local cf = CFrame.new(spec.x, 1.04, spec.z) * CFrame.Angles(0, 0, math.rad(90))
		local goo = part(
			"HiveGoo" .. index,
			Vector3.new(0.06, spec.radius * 2, spec.radius * 2),
			cf,
			teal:Lerp(Color3.new(0, 0.2, 0.18), 0.45),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder
		)
		goo.CanCollide = false
		goo.CanQuery = false
		local edge = part(
			"HiveGooEdge" .. index,
			Vector3.new(0.04, spec.radius * 2 + 0.7, spec.radius * 2 + 0.7),
			cf * CFrame.new(-0.05, 0, 0),
			teal,
			Enum.Material.Neon,
			Enum.PartType.Cylinder
		)
		edge.CanCollide = false
		edge.CanQuery = false
		edge.Transparency = 0.35
	end
end

local function crystalClusters()
	local colors = { c3(Theme.NeonPurple), c3(Theme.NeonTeal) }
	for _, spec in ArenaLayout.CrystalClusters do
		local cluster = Instance.new("Model")
		cluster.Name = "CrystalCluster" .. spec.Name
		cluster.Parent = arena
		for index, offset in { -1.5, 0, 1.5 } do
			local color = colors[(index - 1) % #colors + 1]
			local crystal = part(
				"Crystal" .. index,
				Vector3.new(1.1, 3 + index, 1.1),
				CFrame.new(spec.x + offset, 2.5 + index / 2, spec.z)
					* CFrame.Angles(math.rad(offset * 5), 0, math.rad(offset * 8)),
				color,
				Enum.Material.Neon
			)
			crystal.CanCollide = false
			crystal.Parent = cluster
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 14
			light.Brightness = 1.4
			light.Parent = crystal
		end
	end
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
				c3(Theme.PropPastel),
				Enum.Material.SmoothPlastic
			)
			post.CanCollide = true
			neonStrip(Vector3.new(1.4, 1.4, 1.4), CFrame.new(x, 19.5, z), amber, 26)
		end
	end
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
				boss.CFrame * CFrame.new(0, 10.5, 0) -- box centre: the gate's base rests on the floor
			)
		then
			for _, sign in { -1, 1 } do
				local pillar = part(
					"GatePillar",
					Vector3.new(3, 22, 3),
					boss.CFrame * CFrame.new(sign * 9, 10, 0),
					c3(Theme.PropPastel),
					Enum.Material.SmoothPlastic
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
				c3(Theme.PropPastel),
				Enum.Material.SmoothPlastic
			)
			top.CanCollide = true
			neonStrip(Vector3.new(19, 0.4, 0.4), boss.CFrame * CFrame.new(0, 19.6, -1.7), amber, 30)
		end
	end
end

local function buildOutpost9()
	local world = Instance.new("Folder")
	world.Name = "Outpost9"
	world.Parent = arena

	local zones = Instance.new("Folder")
	zones.Name = "Zones"
	zones.Parent = world
	for _, zone in ArenaLayout.Zones do
		local model = Instance.new("Model")
		model.Name = zone.Id
		model:SetAttribute("FirstWave", zone.FirstWave)
		model:SetAttribute("LastWave", zone.LastWave)
		model.Parent = zones
		if zone.Id == "Refinery" then
			for side in { -1, 1 } do
				local width = (zone.Width - 16) / 2
				local floor = part(
					"Floor",
					Vector3.new(width, 2, zone.Depth),
					CFrame.new(zone.x + side * (width + 16) / 2, 0, zone.z),
					c3(Theme.OutpostCream),
					Enum.Material.SmoothPlastic
				)
				floor.Parent = model
			end
		else
			local floor = part(
				"Floor",
				Vector3.new(zone.Width, 2, zone.Depth),
				CFrame.new(zone.x, 0, zone.z),
				c3(Theme.OutpostCream),
				Enum.Material.SmoothPlastic
			)
			floor.Parent = model
		end
	end

	local spawnFolder = arena:FindFirstChild("EnemySpawns")
	if spawnFolder then
		spawnFolder:ClearAllChildren()
	else
		spawnFolder = Instance.new("Folder")
		spawnFolder.Name = "EnemySpawns"
		spawnFolder.Parent = arena
	end
	for _, spawn in ArenaLayout.ZoneSpawns do
		local zone
		for _, candidate in ArenaLayout.Zones do
			if candidate.Id == spawn.ZoneId then
				zone = candidate
				break
			end
		end
		if zone then
			local gate = Instance.new("Part")
			gate.Name = spawn.Name
			gate.Anchored = true
			gate.CanCollide = false
			gate.CanQuery = false
			gate.Transparency = 1
			gate.Size = Vector3.new(6, 1, 6)
			gate.Position = Vector3.new(spawn.x, 2, spawn.z)
			gate:SetAttribute("FirstWave", zone.FirstWave)
			gate:SetAttribute("LastWave", zone.LastWave)
			gate.Parent = spawnFolder
		end
	end

	local bridges = Instance.new("Folder")
	bridges.Name = "Bridges"
	bridges.Parent = world
	local bridgeDecks: { [string]: BasePart } = {}
	for _, bridge in ArenaLayout.Bridges do
		local deck = Instance.new("Part")
		deck.Name = bridge.Id
		deck.Anchored = true
		deck.CanCollide = false
		deck.Size = Vector3.new(0.6, 2, bridge.Depth)
		deck.Position = Vector3.new(bridge.x - bridge.Width / 2, 0, bridge.z)
		deck.Color = c3(Theme.SignalOrange)
		deck.Material = Enum.Material.SmoothPlastic
		deck:SetAttribute("OpenWave", bridge.OpenWave)
		deck.Parent = bridges
		bridgeDecks[bridge.Id] = deck
	end

	local opened: { [string]: boolean } = {}
	local bossSpawn = arena:FindFirstChild("BossSpawn") :: BasePart?
	local function openBridges(wave: number)
		if bossSpawn then
			local spot = ArenaLayout.bossSpawnForWave(wave)
			bossSpawn.Position = Vector3.new(spot.x, 2, spot.z)
		end
		if wave <= 0 then
			-- New run: fold the bridges back so zones open again during play.
			for _, bridge in ArenaLayout.Bridges do
				opened[bridge.Id] = nil
				local deck = bridgeDecks[bridge.Id]
				deck.CanCollide = false
				deck.Size = Vector3.new(0.6, 2, bridge.Depth)
				deck.Position = Vector3.new(bridge.x - bridge.Width / 2, 0, bridge.z)
			end
			return
		end
		for _, bridge in ArenaLayout.Bridges do
			if wave >= bridge.OpenWave and not opened[bridge.Id] then
				opened[bridge.Id] = true
				local deck = bridgeDecks[bridge.Id]
				deck.CanCollide = true
				TweenService
					:Create(
						deck,
						TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{
							Size = Vector3.new(bridge.Width, 2, bridge.Depth),
							Position = Vector3.new(bridge.x, 0, bridge.z),
						}
					)
					:Play()
				local state = ReplicatedStorage:WaitForChild("State")
				local banner = state:WaitForChild("ZoneBanner") :: StringValue
				banner.Value = "NEW ZONE"
				task.delay(0.5, function()
					if banner.Value == "NEW ZONE" then
						banner.Value = ""
					end
				end)
			end
		end
	end
	local state = ReplicatedStorage:WaitForChild("State")
	local waveValue = state:WaitForChild("Wave") :: IntValue
	waveValue.Changed:Connect(openBridges)
	openBridges(waveValue.Value)

	local traversal = Instance.new("Folder")
	traversal.Name = "Traversal"
	traversal.Parent = world
	for _, padSpec in ArenaLayout.JumpPads do
		local pad = part(
			padSpec.Name,
			Vector3.new(10, 1, 10),
			CFrame.new(padSpec.x, 1.5, padSpec.z),
			c3(Theme.SignalOrange),
			Enum.Material.SmoothPlastic
		)
		pad.Parent = traversal
		pad.Touched:Connect(function(hit)
			local root = hit.Parent and hit.Parent:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				root.AssemblyLinearVelocity =
					Vector3.new(padSpec.Velocity[1], padSpec.Velocity[2], padSpec.Velocity[3])
			end
		end)
	end

	local refineryProps = {
		{ "Pipe", Vector3.new(52, 5, 5), Vector3.new(200, 5, -52) },
		{ "Catwalk", Vector3.new(70, 3, 14), Vector3.new(205, 13, 36) },
		{ "HighLoop", Vector3.new(52, 3, 12), Vector3.new(230, 25, -22) },
		{ "RefineryTower", Vector3.new(18, 52, 18), Vector3.new(232, 27, -42) },
	}
	for _, spec in refineryProps do
		part(
			spec[1] :: string,
			spec[2] :: Vector3,
			CFrame.new(spec[3] :: Vector3),
			c3(Theme.OutpostShade),
			Enum.Material.SmoothPlastic
		).Parent =
			world
	end

	part(
		"RadioMast",
		Vector3.new(8, 58, 8),
		CFrame.new(-48, 30, -42),
		c3(Theme.OutpostShade),
		Enum.Material.SmoothPlastic
	).Parent =
		world
	part(
		"Beacon",
		Vector3.new(10, 5, 10),
		CFrame.new(-48, 61.5, -42),
		c3(Theme.SignalOrange),
		Enum.Material.SmoothPlastic
	).Parent =
		world
	part(
		"NestWall",
		Vector3.new(12, 32, 120),
		CFrame.new(438, 17, 0),
		c3(Theme.ChitinDark),
		Enum.Material.SmoothPlastic
	).Parent =
		world
	part(
		"NestCore",
		Vector3.new(18, 24, 18),
		CFrame.new(448, 13, 0),
		c3(Theme.Goo),
		Enum.Material.Neon,
		Enum.PartType.Ball
	).Parent =
		world
	for index, z in { -34, 34 } do
		local pool = part(
			"GooPool" .. index,
			Vector3.new(32, 0.6, 18),
			CFrame.new(390, 1.3, z),
			c3(Theme.Goo),
			Enum.Material.Neon
		)
		pool.CanCollide = false
		pool.Parent = world
	end

	world:SetAttribute("WalkableCellSize", ArenaLayout.WalkableGrid.CellSize)
	world:SetAttribute("WalkableCellCount", #ArenaLayout.WalkableGrid.Cells)
end

applyLightingPreset(LightingPresets[selectedMap.LightingPreset])
configureMap()
cloudSea()
outerCover()
laneStripes()
gooPatches()
crystalClusters()
wallsAndRails()
portals()
buildOutpost9()
