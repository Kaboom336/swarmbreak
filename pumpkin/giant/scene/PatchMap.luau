-- Pumpkin Patch Panic map (arena round 9). A center market with the Giant Jack, four diagonal
-- roads with a cauldron on each, four corner fields of 6 player patches (24 total), ghost
-- spawns on the edges, a fence ring and woods. Every prop is snapped to the terrain surface.
-- Run in Edit mode.
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local Terrain = workspace.Terrain

local kit = ServerStorage.KitSource
local rng = Random.new(9)

local old = workspace:FindFirstChild("Garden")
if old then
	old:Destroy()
end
local garden = Instance.new("Model")
garden.Name = "Garden"
garden.Parent = workspace
local art = Instance.new("Folder")
art.Name = "Art"
art.Parent = garden

local R = 136 -- fence ring half-size

-- 1. Terrain first, so everything after it can be snapped to the surface.
Terrain:Clear()
Terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(460, 8, 460), Enum.Material.LeafyGrass)
Terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(78, 108, 52))
Terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(70, 46, 30))
Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(96, 70, 48))
for _ = 1, 44 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(R + 24, R + 70)
	Terrain:FillBall(
		Vector3.new(math.cos(a) * r, -8, math.sin(a) * r),
		rng:NextNumber(14, 26),
		Enum.Material.LeafyGrass
	)
end
Terrain:FillCylinder(CFrame.new(0, -6, 0), 4, 44, Enum.Material.Ground)
local DIAG = {
	{ name = "SE", v = Vector3.new(1, 0, 1).Unit },
	{ name = "NE", v = Vector3.new(1, 0, -1).Unit },
	{ name = "NW", v = Vector3.new(-1, 0, -1).Unit },
	{ name = "SW", v = Vector3.new(-1, 0, 1).Unit },
}
for _, d in DIAG do
	local mid = d.v * 72
	Terrain:FillBlock(
		CFrame.lookAt(mid + Vector3.new(0, -6, 0), mid + Vector3.new(0, -6, 0) + d.v),
		Vector3.new(16, 4, 90),
		Enum.Material.Ground
	)
end
local FIELD = 88
for _, d in DIAG do
	local c = Vector3.new(math.sign(d.v.X) * FIELD, 0, math.sign(d.v.Z) * FIELD)
	Terrain:FillBlock(
		CFrame.new(c + Vector3.new(0, -6, 0)),
		Vector3.new(88, 4, 60),
		Enum.Material.Ground
	)
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { Terrain }
local function ground(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), groundParams)
	return hit and hit.Position.Y or 0
end

local function place(name, cf, scale, parent, keepY)
	local m = kit[name]:Clone()
	m:ScaleTo(2.5 * (scale or 1))
	local bcf, bsize = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bcf.X, bcf.Y - bsize.Y / 2, bcf.Z)
	local p = cf.Position
	if keepY then
		m:PivotTo(cf)
		for _, part in m:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		m.Parent = parent or art
		return m
	end
	-- Sink slightly below the lowest of five samples so nothing hovers on a slope.
	local half = math.min(bsize.X, bsize.Z) * 0.35
	local y = ground(p.X, p.Z)
	for _, o in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		y = math.min(y, ground(p.X + o[1] * half, p.Z + o[2] * half))
	end
	m:PivotTo(cf - p + Vector3.new(p.X, y - 0.15, p.Z))
	for _, part in m:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	m.Parent = parent or art
	return m
end
local function at(x, z, yaw)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end
local function part(props)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	-- Shape first (it can reset Size) and Parent last.
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in props do
		if k ~= "Class" and k ~= "Shape" and k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end
local function lamp(x, z, scale)
	local m = place("post_lantern", at(x, z, rng:NextNumber(0, 360)), scale or 1.1)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 80)
	light.Range = 18
	light.Brightness = 1.5
	light.Parent = m:FindFirstChildWhichIsA("BasePart", true)
	return m
end
local function billboard(
	parent: Instance,
	text: string,
	color: Color3,
	size: Vector2,
	offset: Vector3,
	maxDistance: number?
)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign"
	bb.Size = UDim2.fromOffset(size.X, size.Y)
	bb.StudsOffsetWorldSpace = offset
	bb.LightInfluence = 0
	bb.MaxDistance = maxDistance or 260
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(30, 12, 40)
	stroke.Parent = label
	return bb
end
local function anchor(name: string, position: Vector3, parent: Instance?)
	return part({
		Name = name,
		CanCollide = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.one,
		Position = position,
		Parent = parent or garden,
	})
end

-- 2. Center market: stone plaza, the Giant Jack on a plinth, sell / seeds / upgrades stalls.
local HUB_Y = ground(0, 0)
local market = Instance.new("Model")
market.Name = "Market"
market.Parent = garden
part({
	Name = "Plaza",
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Slate,
	Color = Color3.fromRGB(88, 80, 100),
	Size = Vector3.new(2, 76, 76),
	CFrame = CFrame.new(0, HUB_Y - 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Parent = market,
})
part({
	Name = "PlazaRim",
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Slate,
	Color = Color3.fromRGB(60, 52, 72),
	Size = Vector3.new(1.6, 78, 78),
	CFrame = CFrame.new(0, HUB_Y - 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Parent = market,
})
local TOP = HUB_Y + 0.4
local PLINTH = 9
part({
	Name = "Plinth",
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Slate,
	Color = Color3.fromRGB(70, 60, 84),
	Size = Vector3.new(PLINTH, 16, 16),
	CFrame = CFrame.new(0, TOP + PLINTH / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Parent = market,
})
part({
	Name = "MeterRing",
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Neon,
	Color = Color3.fromRGB(255, 140, 40),
	CanCollide = false,
	Size = Vector3.new(0.4, 17, 17),
	CFrame = CFrame.new(0, TOP + 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Transparency = 0.4,
	Parent = market,
})
local jackMesh = kit.pumpkin_orange_jackolantern:FindFirstChildWhichIsA("MeshPart", true)
local plainMesh = kit.pumpkin_orange:FindFirstChildWhichIsA("MeshPart", true)
local JACK_W = 20
local jack = plainMesh:Clone()
jack.Name = "GiantJack"
jack.Anchored = true
jack.CanCollide = true
jack.Size = plainMesh.Size * (JACK_W / plainMesh.Size.X)
jack.CFrame = CFrame.new(0, TOP + PLINTH + jack.Size.Y / 2, 0)
jack.Parent = market
local king = jackMesh:Clone()
king.Name = "KingFace"
king.Anchored = true
king.CanCollide = false
king.Transparency = 1
king.Size = jackMesh.Size * (JACK_W / jackMesh.Size.X)
king.CFrame = CFrame.new(0, TOP + PLINTH + king.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0)
king.Parent = market
local jackLight = Instance.new("PointLight")
jackLight.Color = Color3.fromRGB(255, 150, 50)
jackLight.Range = 30
jackLight.Brightness = 1
jackLight.Parent = jack
billboard(
	anchor("SignJack", Vector3.new(0, TOP + PLINTH + jack.Size.Y + 6, 0), market),
	"GIANT JACK",
	Color3.fromRGB(255, 160, 50),
	Vector2.new(260, 60),
	Vector3.zero
)

local function stall(
	name: string,
	title: string,
	sub: string,
	color: Color3,
	position: Vector3,
	roofColor: Color3
)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = market
	local face = CFrame.lookAt(position, Vector3.new(0, position.Y, 0)) -- counter faces the jack
	local base = face * CFrame.new(0, 0, 0)
	local counter = part({
		Name = "Counter",
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(110, 70, 44),
		Size = Vector3.new(14, 3.6, 4),
		CFrame = base * CFrame.new(0, 1.8, 0),
		Parent = model,
	})
	part({
		Name = "Top",
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(80, 50, 32),
		Size = Vector3.new(15, 0.5, 5),
		CFrame = base * CFrame.new(0, 3.85, 0),
		Parent = model,
	})
	for _, x in { -6.8, 6.8 } do
		part({
			Name = "Pole",
			Material = Enum.Material.Wood,
			Color = Color3.fromRGB(70, 44, 28),
			Size = Vector3.new(0.7, 10, 0.7),
			CFrame = base * CFrame.new(x, 5, 1.6),
			Parent = model,
		})
	end
	for i, c in { roofColor, Color3.fromRGB(40, 30, 50) } do
		part({
			Name = "Roof" .. i,
			Material = Enum.Material.Fabric,
			Color = c,
			Size = Vector3.new(16, 0.4, 3.4),
			CFrame = base
				* CFrame.new(0, 10.4 - (i - 1) * 0.6, 3.2 - (i - 1) * 3.2)
				* CFrame.Angles(math.rad(i == 1 and -18 or 18), 0, 0),
			Parent = model,
		})
	end
	local board = part({
		Name = "Board",
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(60, 38, 26),
		Size = Vector3.new(11, 3, 0.4),
		CFrame = base * CFrame.new(0, 8, 1.4) * CFrame.Angles(0, math.rad(180), 0),
		Parent = model,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = title
	label.Parent = gui
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = board
	billboard(
		anchor("Sign" .. name, position + Vector3.new(0, 15, 0), model),
		title,
		color,
		Vector2.new(230, 56),
		Vector3.zero
	)
	billboard(
		anchor("Sub" .. name, position + Vector3.new(0, 12.4, 0), model),
		sub,
		Color3.fromRGB(255, 240, 220),
		Vector2.new(230, 30),
		Vector3.zero,
		90
	)
	-- The prompt anchor sits in front of the counter, on the jack side.
	local promptPart = part({
		Name = "PromptPart",
		CanCollide = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.new(2, 2, 2),
		CFrame = base * CFrame.new(0, 2.5, -3.5),
		Parent = model,
	})
	model:SetAttribute("Kind", name)
	return model, counter, promptPart
end
local _, sellCounter = stall(
	"Sell",
	"WITCH BUYS PUMPKINS",
	"Sell for candy",
	Color3.fromRGB(190, 120, 255),
	Vector3.new(0, TOP, -27),
	Color3.fromRGB(110, 50, 150)
)
stall(
	"Seeds",
	"SEEDS",
	"Buy pumpkin seeds",
	Color3.fromRGB(140, 255, 110),
	Vector3.new(27, TOP, 0),
	Color3.fromRGB(60, 130, 50)
)
stall(
	"Upgrades",
	"UPGRADES",
	"Spend candy",
	Color3.fromRGB(110, 210, 255),
	Vector3.new(-27, TOP, 0),
	Color3.fromRGB(40, 90, 150)
)
place(
	"pumpkin_orange_jackolantern",
	sellCounter.CFrame * CFrame.new(-4.5, 1.8, 0),
	0.9,
	market,
	true
)
place("candle_triple", sellCounter.CFrame * CFrame.new(4.5, 1.8, 0), 0.8, market, true)
place("skull_candle", sellCounter.CFrame * CFrame.new(1.5, 1.8, 0), 0.8, market, true)

local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.CFrame = CFrame.lookAt(Vector3.new(0, TOP + 0.1, 26), Vector3.new(0, TOP + 0.1, 0))
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = garden
for _, d in spawn:GetChildren() do
	if d:IsA("Decal") then
		d:Destroy()
	end
end
for i = 1, 12 do
	local a = (i + 0.5) / 12 * math.pi * 2
	if math.abs(math.cos(a)) > 0.25 and math.abs(math.sin(a)) > 0.25 then
		lamp(math.cos(a) * 35, math.sin(a) * 35, 1.15)
	end
end

-- 3. Cauldrons: one beside each diagonal road, halfway between market and fields.
local cauldrons = Instance.new("Folder")
cauldrons.Name = "Cauldrons"
cauldrons.Parent = garden
for _, d in DIAG do
	local side = Vector3.new(d.v.Z, 0, -d.v.X)
	local c = d.v * 64 + side * 12
	local y = ground(c.X, c.Z)
	local model = Instance.new("Model")
	model.Name = "Cauldron" .. d.name
	model.Parent = cauldrons
	local pos = Vector3.new(c.X, y, c.Z)
	part({
		Name = "Pot",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(34, 30, 40),
		Size = Vector3.new(11, 11, 11),
		CFrame = CFrame.new(pos + Vector3.new(0, 4.6, 0)),
		Parent = model,
	})
	part({
		Name = "Rim",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(48, 42, 56),
		Size = Vector3.new(1.2, 10.4, 10.4),
		CFrame = CFrame.new(pos + Vector3.new(0, 8.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = model,
	})
	local brew = part({
		Name = "Brew",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(150, 90, 255),
		CanCollide = false,
		Size = Vector3.new(0.3, 9.2, 9.2),
		CFrame = CFrame.new(pos + Vector3.new(0, 8.7, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = model,
	})
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		part({
			Name = "Leg",
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(30, 26, 34),
			Size = Vector3.new(1, 3, 1),
			CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 3.6, 0.6, math.sin(a) * 3.6)),
			Parent = model,
		})
	end
	local fire = part({
		Name = "Fire",
		CanCollide = false,
		Transparency = 1,
		Size = Vector3.new(5, 1, 5),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)),
		Parent = model,
	})
	local flames = Instance.new("Fire")
	flames.Color = Color3.fromRGB(255, 120, 40)
	flames.SecondaryColor = Color3.fromRGB(255, 200, 60)
	flames.Size = 6
	flames.Heat = 4
	flames.Parent = fire
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255))
	bubbles.LightEmission = 1
	bubbles.Size = NumberSequence.new(0.9, 0)
	bubbles.Lifetime = NumberRange.new(1, 1.8)
	bubbles.Rate = 14
	bubbles.Speed = NumberRange.new(3, 6)
	bubbles.EmissionDirection = Enum.NormalId.Right
	bubbles.Parent = brew
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(170, 120, 255))
	smoke.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Rate = 5
	smoke.Speed = NumberRange.new(4, 7)
	smoke.EmissionDirection = Enum.NormalId.Right
	smoke.Parent = brew
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 110, 255)
	light.Range = 24
	light.Brightness = 2.2
	light.Parent = brew
	place("skull_candle", at(pos.X + side.X * 7, pos.Z + side.Z * 7, 0), 1, model)
	place("bone_A", at(pos.X - d.v.X * 6, pos.Z - d.v.Z * 6, rng:NextNumber(0, 360)), 1, model)
	billboard(
		anchor("SignCauldron" .. d.name, pos + Vector3.new(0, 17, 0), model),
		"MAGIC CAULDRON",
		Color3.fromRGB(200, 150, 255),
		Vector2.new(240, 56),
		Vector3.zero
	)
	billboard(
		anchor("SubCauldron" .. d.name, pos + Vector3.new(0, 14.4, 0), model),
		"Brew pumpkins = worth more",
		Color3.fromRGB(255, 240, 220),
		Vector2.new(250, 30),
		Vector3.zero,
		110
	)
end

-- 4. Fields: four corners, each with 6 patches of 3x3 plots. Patches face the market.
local patches = Instance.new("Folder")
patches.Name = "Patches"
patches.Parent = garden
local PLOT_GAP = 7
local PATCH = 24
local patchId = 0
for _, d in DIAG do
	local sx, sz = math.sign(d.v.X), math.sign(d.v.Z)
	local fc = Vector3.new(sx * FIELD, 0, sz * FIELD)
	for col = -1, 1 do
		for row = 0, 1 do
			patchId += 1
			local pc = fc + Vector3.new(col * (PATCH + 3), 0, (row - 0.5) * (PATCH + 5))
			local y = ground(pc.X, pc.Z)
			local patch = Instance.new("Model")
			patch.Name = string.format("Patch%02d", patchId)
			patch:SetAttribute("Id", patchId)
			patch:SetAttribute("Owner", 0)
			patch.Parent = patches
			local soil = part({
				Name = "Soil",
				Material = Enum.Material.Ground,
				Color = Color3.fromRGB(66, 44, 30),
				Size = Vector3.new(PATCH - 2, 0.6, PATCH - 2),
				CFrame = CFrame.new(pc.X, y + 0.1, pc.Z),
				Parent = patch,
			})
			for _, e in { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } } do
				local long = e[1] == 0
				part({
					Name = "Border",
					Material = Enum.Material.Wood,
					Color = Color3.fromRGB(96, 62, 40),
					Size = long and Vector3.new(PATCH, 1.2, 1) or Vector3.new(1, 1.2, PATCH),
					CFrame = CFrame.new(
						pc.X + e[1] * (PATCH / 2 - 0.5),
						y + 0.6,
						pc.Z + e[2] * (PATCH / 2 - 0.5)
					),
					Parent = patch,
				})
			end
			local index = 0
			for gx = -1, 1 do
				for gz = -1, 1 do
					index += 1
					local p = Vector3.new(pc.X + gx * PLOT_GAP, y + 0.45, pc.Z + gz * PLOT_GAP)
					local plot = part({
						Name = "Plot",
						Shape = Enum.PartType.Cylinder,
						Material = Enum.Material.Mud,
						Color = Color3.fromRGB(52, 34, 24),
						CanCollide = false,
						Size = Vector3.new(0.3, 5, 5),
						CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
						Parent = patch,
					})
					plot:SetAttribute("Index", index)
				end
			end
			-- Name sign at the corner nearest the market.
			local corner = Vector3.new(pc.X - sx * (PATCH / 2 - 1), y, pc.Z - sz * (PATCH / 2 - 1))
			local post = part({
				Name = "SignPost",
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(80, 52, 34),
				Size = Vector3.new(0.6, 6, 0.6),
				CFrame = CFrame.new(corner + Vector3.new(0, 3, 0)),
				Parent = patch,
			})
			local nameSign = billboard(
				post,
				"Free patch",
				Color3.fromRGB(255, 230, 200),
				Vector2.new(190, 40),
				Vector3.new(0, 4.5, 0),
				45
			)
			nameSign.Name = "OwnerSign"
			soil:SetAttribute("Center", true)
		end
	end
	-- A fence on the two outer edges.
	for k = -3, 3 do
		place("fence_seperate", at(fc.X + k * 12, fc.Z + sz * 34, 0), 1)
		place("fence_seperate", at(fc.X + sx * 44, fc.Z + k * 9.5, 90), 1)
	end
end

-- 5. Ghost spawns on the four edges, each with a spooky landmark.
local spawns = Instance.new("Folder")
spawns.Name = "GhostSpawns"
spawns.Parent = garden
local EDGE = {
	{ name = "N", p = Vector3.new(0, 0, -112), prop = "crypt", yaw = 0, scale = 1.6 },
	{ name = "E", p = Vector3.new(112, 0, 0), prop = "shrine_candles", yaw = 270, scale = 1.8 },
	{ name = "S", p = Vector3.new(0, 0, 112), prop = "crypt", yaw = 180, scale = 1.4 },
	{
		name = "W",
		p = Vector3.new(-112, 0, 0),
		prop = "tree_dead_large_decorated",
		yaw = 90,
		scale = 2.2,
	},
}
local graves =
	{ "grave_A", "grave_B", "gravestone", "gravemarker_A", "gravemarker_B", "grave_A_destroyed" }
for _, e in EDGE do
	place(e.prop, at(e.p.X, e.p.Z, e.yaw), e.scale)
	for _ = 1, 7 do
		local off = Vector3.new(rng:NextNumber(-18, 18), 0, rng:NextNumber(-18, 18))
		if off.Magnitude > 9 then
			local g = e.p + off
			place(
				graves[rng:NextInteger(1, #graves)],
				at(g.X, g.Z, rng:NextNumber(-25, 25)),
				rng:NextNumber(1, 1.3)
			)
		end
	end
	local s = anchor("Spawn" .. e.name, Vector3.new(e.p.X, ground(e.p.X, e.p.Z) + 6, e.p.Z), spawns)
	s.Size = Vector3.new(4, 4, 4)
end

-- 6. Dressing: lamps along the roads, fence ring, woods outside.
for _, d in DIAG do
	local side = Vector3.new(d.v.Z, 0, -d.v.X)
	for k = 0, 1 do
		local p = d.v * (46 + k * 36)
		lamp(p.X - side.X * 10, p.Z - side.Z * 10)
	end
end
for i = -R + 5, R - 5, 10 do
	place("fence", at(i, R, 0), 1)
	place("fence", at(i, -R, 0), 1)
	place("fence", at(R, i, 90), 1)
	place("fence", at(-R, i, 90), 1)
end
local trees = {
	"tree_pine_orange_large",
	"tree_pine_orange_medium",
	"tree_pine_yellow_large",
	"tree_dead_large",
	"tree_dead_medium",
}
for _ = 1, 120 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(R + 10, R + 56)
	place(
		trees[rng:NextInteger(1, #trees)],
		at(math.cos(a) * r, math.sin(a) * r, rng:NextNumber(0, 360)),
		rng:NextNumber(1.6, 2.6)
	)
end

-- 7. Lighting: dusk; the game script darkens it at midnight.
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then
	atmosphere.Density = 0.3
end
workspace.StreamingEnabled = false

return string.format("patch map built: %d patches, hub y=%.1f", patchId, HUB_Y)
