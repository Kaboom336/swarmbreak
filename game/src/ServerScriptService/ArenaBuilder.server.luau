--!strict
-- Dresses the checked-in arena at start with neon strips, portals, and a boss gate.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Fit = require(ReplicatedStorage.Shared.Fit)
local ModelKey = require(ReplicatedStorage.Shared.ModelKey)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ModelLibrary = require(ServerStorage.ModelLibrary)

local arena = workspace:WaitForChild("Arena")

local function c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
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

retexture()
floorGrid()
wallsAndRails()
portals()
