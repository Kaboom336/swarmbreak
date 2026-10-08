-- Edit-mode scene builder for Feed the Giant. Run from the Studio MCP in the place that
-- holds the imported KayKit "Scene" model. Rebuilds workspace.Garden from scratch.
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KIT_SCALE = 2.5
local kit = workspace:FindFirstChild("Scene") or ServerStorage:FindFirstChild("KitSource")
assert(kit, "imported KayKit Scene model not found")
kit.Name = "KitSource"
kit.Parent = ServerStorage

local old = workspace:FindFirstChild("Garden")
if old then
	old:Destroy()
end
for _, name in { "Baseplate" } do
	local p = workspace:FindFirstChild(name)
	if p then
		p:Destroy()
	end
end

local garden = Instance.new("Model")
garden.Name = "Garden"
garden.Parent = workspace
local art = Instance.new("Folder")
art.Name = "Art"
art.Parent = garden

local rng = Random.new(31)

local function place(name: string, cf: CFrame, scale: number?, parent: Instance?): Model
	local m = kit[name]:Clone()
	m:ScaleTo(KIT_SCALE * (scale or 1))
	-- Imported pivots sit at the import grid, so re-pivot to the bottom centre first.
	local bcf, bsize = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bcf.X, bcf.Y - bsize.Y / 2, bcf.Z)
	m:PivotTo(cf)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	m.Parent = parent or art
	return m
end

local function at(x: number, z: number, yaw: number?): CFrame
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function light(model: Model, range: number, brightness: number)
	local part = model:FindFirstChildWhichIsA("BasePart", true)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 160, 70)
	l.Range = range
	l.Brightness = brightness
	l.Shadows = true
	l.Parent = part
end

-- Ground
local ground = Instance.new("Part")
ground.Name = "Ground"
ground.Anchored = true
ground.Size = Vector3.new(260, 2, 260)
ground.CFrame = CFrame.new(0, -1, 0)
ground.Material = Enum.Material.Grass
ground.Color = Color3.fromRGB(96, 128, 68)
ground.Parent = garden

-- Altar and giant at the centre-north.
local ALTAR = Vector3.new(0, 0, -18)
local plinth = Instance.new("Part")
plinth.Name = "Altar"
plinth.Shape = Enum.PartType.Cylinder
plinth.Anchored = true
plinth.Size = Vector3.new(2.4, 26, 26)
plinth.CFrame = CFrame.new(ALTAR + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
plinth.Material = Enum.Material.Slate
plinth.Color = Color3.fromRGB(92, 86, 104)
plinth.Parent = garden
local rim = plinth:Clone()
rim.Name = "AltarStep"
rim.Size = Vector3.new(1.2, 32, 32)
rim.CFrame = CFrame.new(ALTAR + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
rim.Color = Color3.fromRGB(70, 64, 82)
rim.Parent = garden

local giantModel = kit.pumpkin_orange_jackolantern:Clone()
local giant = giantModel:FindFirstChildWhichIsA("MeshPart", true):Clone()
giantModel:Destroy()
giant.Name = "Giant"
giant.Anchored = true
giant.CanCollide = false
giant.Size *= 8
giant.CFrame = CFrame.new(ALTAR + Vector3.new(0, 2.4 + giant.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(180), 0)
giant.Parent = garden
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(255, 150, 50)
glow.Range = 18
glow.Brightness = 1.6
glow.Parent = giant
local embers = Instance.new("ParticleEmitter")
embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60))
embers.LightEmission = 1
embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
embers.Lifetime = NumberRange.new(1.5, 2.5)
embers.Rate = 6
embers.Speed = NumberRange.new(2, 4)
embers.SpreadAngle = Vector2.new(30, 30)
embers.EmissionDirection = Enum.NormalId.Top
embers.Parent = giant

local collider = Instance.new("Part")
collider.Name = "GiantCollider"
collider.Shape = Enum.PartType.Ball
collider.Anchored = true
collider.Transparency = 1
collider.Size = Vector3.one * (giant.Size.X * 0.9)
collider.CFrame = giant.CFrame
collider.Parent = garden

-- Eight sockets on the altar where carried pumpkins are smashed in.
local sockets = Instance.new("Folder")
sockets.Name = "Sockets"
sockets.Parent = garden
for i = 0, 7 do
	local a = (i + 0.5) / 8 * math.pi * 2
	local pos = ALTAR + Vector3.new(math.cos(a) * 12, 2.4, math.sin(a) * 12)
	local socket = Instance.new("Part")
	socket.Name = "Socket" .. (i + 1)
	socket.Anchored = true
	socket.CanCollide = false
	socket.Transparency = 1
	socket.Size = Vector3.new(5, 0.2, 5)
	socket.CFrame = CFrame.new(pos)
	socket.Parent = sockets
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 150, 50)
	ring.Transparency = 0.55
	ring.Size = Vector3.new(0.15, 5.5, 5.5)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = socket
end

-- Candles around the altar edge.
for i = 0, 7 do
	local a = i / 8 * math.pi * 2
	local c = place(i % 2 == 0 and "candle_triple" or "skull_candle", at(math.cos(a) * 14.5, ALTAR.Z + math.sin(a) * 14.5, math.deg(-a)), 1)
	c:PivotTo(c:GetPivot() + Vector3.new(0, 1.2, 0))
	light(c, 7, 0.8)
end

-- Patch of dirt plots west of the spawn path.
local patch = Instance.new("Folder")
patch.Name = "Patch"
patch.Parent = garden
local PATCH = Vector3.new(-27, 0, 20)
for gx = 0, 2 do
	for gz = 0, 1 do
		local pos = PATCH + Vector3.new((gx - 1) * 11, 0, (gz - 0.5) * 11)
		place("floor_dirt", at(pos.X, pos.Z), 1.05)
		local plot = Instance.new("Part")
		plot.Name = "Plot"
		plot.Anchored = true
		plot.CanCollide = false
		plot.Transparency = 1
		plot.Size = Vector3.new(2, 0.2, 2)
		plot.CFrame = CFrame.new(pos + Vector3.new(0, 1.35, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		plot.Parent = patch
	end
end
-- Low fence around the patch with a gap facing the altar.
for i = -1, 1 do
	place("fence_seperate", at(PATCH.X + i * 11, PATCH.Z + 17, 0), 1)
end
place("fence_seperate", at(PATCH.X - 19, PATCH.Z + 6, 90), 1)
place("fence_seperate", at(PATCH.X - 19, PATCH.Z - 5, 90), 1)
place("fence_seperate", at(PATCH.X - 11, PATCH.Z - 16, 0), 1)
place("fence_seperate", at(PATCH.X + 0, PATCH.Z - 16, 0), 1)
light(place("post_lantern", at(PATCH.X + 19, PATCH.Z - 14, -90), 1), 16, 1.2)
place("pumpkin_yellow", at(PATCH.X - 21, PATCH.Z + 15, 30), 1.6)
place("pumpkin_orange_small", at(PATCH.X - 18, PATCH.Z + 17, 10), 1.4)

-- Cobble path: spawn -> altar, with a branch to the patch.
local function pathLine(from: Vector3, to: Vector3)
	local d = to - from
	local steps = math.floor(d.Magnitude / 4.6)
	local tiles = { "path_A", "path_B", "path_C", "path_D" }
	for s = 0, steps do
		local p = from + d * (s / math.max(steps, 1))
		local t = place(tiles[rng:NextInteger(1, 4)], at(p.X + rng:NextNumber(-0.4, 0.4), p.Z, rng:NextInteger(0, 3) * 90), 1)
		t:PivotTo(t:GetPivot() + Vector3.new(0, 0.06, 0))
	end
end
pathLine(Vector3.new(0, 0, 48), Vector3.new(0, 0, 0))
pathLine(Vector3.new(-12, 0, 18), Vector3.new(-3, 0, 4))

-- Lantern posts along the main path.
for z = 42, 6, -12 do
	for _, side in { -1, 1 } do
		local p = place("post_lantern", at(side * 6.5, z, side == 1 and 180 or 0), 1)
		light(p, 16, 1.4)
	end
end

-- Graveyard corner east of the altar.
local graves = { "grave_A", "grave_B", "gravestone", "gravemarker_A", "gravemarker_B", "grave_A_destroyed" }
for i = 1, 16 do
	local x = rng:NextNumber(18, 40)
	local z = rng:NextNumber(-26, 24)
	place(graves[rng:NextInteger(1, #graves)], at(x, z, rng:NextNumber(-20, 20) + 270), rng:NextNumber(0.9, 1.15))
end
place("crypt", at(30, -36, 200), 1.2)
place("coffin_decorated", at(24, 10, 80), 1)
place("bench_decorated", at(12, 26, 270), 1)
light(place("lantern_standing", at(16, -6, 0), 1.2), 14, 1.2)
light(place("lantern_standing", at(22, 22, 0), 1.2), 14, 1.2)

-- Shrine landmark behind the giant and the arch gate at the entrance.
place("shrine_candles", at(-14, -38, 20), 1.6)
place("arch", at(0, 36, 0), 1.6)

-- Fence ring.
local R = 52
for i = -R + 5, R - 5, 10 do
	if math.abs(i) > 9 then
		place(rng:NextNumber() < 0.15 and "fence_broken" or "fence", at(i, R, 0), 1)
	end
	place(rng:NextNumber() < 0.15 and "fence_broken" or "fence", at(i, -R, 0), 1)
	place("fence", at(R, i, 90), 1)
	place("fence", at(-R, i, 90), 1)
end
for _, c in { { R, R }, { -R, R }, { R, -R }, { -R, -R } } do
	place("fence_pillar", at(c[1], c[2]), 1.2)
end

-- Trees: dense outside the fence, a few inside for framing.
local trees = { "tree_pine_orange_large", "tree_pine_orange_medium", "tree_pine_yellow_large", "tree_dead_large", "tree_dead_medium", "tree_pine_orange_small" }
for i = 1, 70 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(R + 5, R + 34)
	place(trees[rng:NextInteger(1, #trees)], at(math.cos(a) * r, math.sin(a) * r, rng:NextNumber(0, 360)), rng:NextNumber(1.3, 2.2))
end
place("tree_dead_large_decorated", at(-22, -20, 40), 1.8)
place("tree_dead_large", at(18, 38, 120), 1.6)
place("tree_pine_orange_large", at(-42, -26, 0), 2)
place("tree_pine_yellow_medium", at(-42, 42, 0), 1.8)
light(place("lantern_hanging", at(-22, -20, 40), 1.2), 12, 1)

-- Small dressing along the path and around the altar.
local smalls = { "pumpkin_orange_small", "pumpkin_yellow_small", "candle_melted", "bone_A", "skull", "candle" }
for i = 1, 26 do
	local side = rng:NextNumber() < 0.5 and -1 or 1
	local z = rng:NextNumber(0, 44)
	place(smalls[rng:NextInteger(1, #smalls)], at(side * rng:NextNumber(8.5, 13), z, rng:NextNumber(0, 360)), rng:NextNumber(1, 1.6))
end
for i = 1, 5 do
	local a = math.rad(200 + i * 28)
	place("pillar", at(math.cos(a) * 19, ALTAR.Z + math.sin(a) * 19, math.deg(a)), 1.4)
end

-- Spawn facing the giant.
local spawn = workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(0, 0.5, 47)
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = garden
for _, d in spawn:GetChildren() do
	if d:IsA("Decal") then
		d:Destroy()
	end
end

-- Templates used by the gameplay scripts.
local templates = ServerStorage:FindFirstChild("KitTemplates") or Instance.new("Folder")
templates.Name = "KitTemplates"
templates:ClearAllChildren()
templates.Parent = ServerStorage
local pumpkinPart = kit.pumpkin_orange:FindFirstChildWhichIsA("MeshPart", true):Clone()
pumpkinPart.Name = "pumpkin_orange"
pumpkinPart.Size *= KIT_SCALE
pumpkinPart.Parent = templates
local jack = kit.pumpkin_orange_jackolantern:FindFirstChildWhichIsA("MeshPart", true):Clone()
jack.Name = "Jack"
jack.Size *= KIT_SCALE
jack.Parent = templates
local oldGold = ReplicatedStorage:FindFirstChild("GiantGold")
if oldGold then
	oldGold:Destroy()
end
local goldForm = kit.pumpkin_yellow_jackolantern:FindFirstChildWhichIsA("MeshPart", true):Clone()
goldForm.Name = "GiantGold"
goldForm.Size = giant.Size
goldForm.Parent = ReplicatedStorage

-- Dusk lighting.
Lighting.ClockTime = 17.75
Lighting.GeographicLatitude = 20
Lighting.Brightness = 2.4
Lighting.Ambient = Color3.fromRGB(78, 62, 98)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 118, 170)
Lighting.EnvironmentDiffuseScale = 0.5
Lighting.EnvironmentSpecularScale = 0.3
for _, c in Lighting:GetChildren() do
	if c:IsA("Atmosphere") or c:IsA("ColorCorrectionEffect") or c:IsA("BloomEffect") then
		c:Destroy()
	end
end
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(196, 140, 190)
atmosphere.Decay = Color3.fromRGB(92, 60, 130)
atmosphere.Glare = 0.4
atmosphere.Haze = 1.6
atmosphere.Parent = Lighting
local grade = Instance.new("ColorCorrectionEffect")
grade.Saturation = 0.12
grade.Contrast = 0.08
grade.TintColor = Color3.fromRGB(255, 240, 248)
grade.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.6
bloom.Size = 28
bloom.Threshold = 1.6
bloom.Parent = Lighting

return "built"
