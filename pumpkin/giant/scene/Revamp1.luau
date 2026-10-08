-- Arena round 4, batch 1 scene fixes. Run in Edit mode after BuildScene.luau.
-- Giant becomes the hero on a stepped altar, sockets become stone dishes, the patch
-- becomes soil, white blob props go, dressing is grouped, and the arch moves over the route.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local KIT_SCALE = 2.5
local kit = ServerStorage.KitSource
local garden = workspace.Garden
local art = garden.Art
local ALTAR = Vector3.new(0, 0, -18)
local rng = Random.new(7)

local function place(name, cf, scale)
	local m = kit[name]:Clone()
	m:ScaleTo(KIT_SCALE * (scale or 1))
	local bcf, bsize = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bcf.X, bcf.Y - bsize.Y / 2, bcf.Z)
	m:PivotTo(cf)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	m.Parent = art
	return m
end
local function at(x, z, yaw, y)
	return CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end
local function flame(model)
	local _, size = model:GetBoundingBox()
	local top = model:GetPivot().Position + Vector3.new(0, size.Y + 0.2, 0)
	local f = Instance.new("Part")
	f.Name = "Flame"
	f.Shape = Enum.PartType.Ball
	f.Material = Enum.Material.Neon
	f.Color = Color3.fromRGB(255, 170, 60)
	f.Size = Vector3.new(0.35, 0.6, 0.35)
	f.Anchored = true
	f.CanCollide = false
	f.CastShadow = false
	f.CFrame = CFrame.new(top)
	f.Parent = model
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 160, 70)
	l.Range = 6
	l.Brightness = 0.5
	l.Parent = f
end

-- 1. Remove white blob props and the old altar/patch pieces.
local pale = { candle_melted = true, candle = true, bone_A = true, skull = true, pumpkin_orange_small = true, pumpkin_yellow_small = true, skull_candle = true, candle_triple = true, floor_dirt = true, pillar = true, arch = true }
for _, m in art:GetChildren() do
	if pale[m.Name] then
		m:Destroy()
	end
end
for _, name in { "Altar", "AltarStep", "Ground" } do
	local p = garden:FindFirstChild(name)
	if p then
		p:Destroy()
	end
end

-- 2. Terrain ground. Voxels are 4 studs: a block whose top is at -4 renders its surface near 0.
-- LeafyGrass has no tall grass blades, so fences and paths stay visible.
Terrain:Clear()
Terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(320, 8, 320), Enum.Material.LeafyGrass)
Terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(84, 116, 56))
Terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(74, 48, 32))
Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(96, 70, 48))
for i = 1, 26 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(70, 120)
	Terrain:FillBall(Vector3.new(math.cos(a) * r, -8, math.sin(a) * r), rng:NextNumber(12, 22), Enum.Material.LeafyGrass)
end
-- Dirt under the main path, the patch branch, the altar and the patch.
Terrain:FillBlock(CFrame.new(0, -6, 28), Vector3.new(8, 4, 48), Enum.Material.Ground)
Terrain:FillBlock(CFrame.new(-10, -6, 20), Vector3.new(16, 4, 8), Enum.Material.Ground)
Terrain:FillCylinder(CFrame.new(0, -6, -18), 4, 26, Enum.Material.Ground)

local patch = garden.Patch
local PATCH = Vector3.new(-27, 0, 20)
Terrain:FillBlock(CFrame.new(PATCH + Vector3.new(0, -6, 0)), Vector3.new(34, 4, 23), Enum.Material.Ground)
for _, plot in patch:GetChildren() do
	if plot.Name == "Plot" then
		local p = plot.Position
		Terrain:FillBall(Vector3.new(p.X, -3.4, p.Z), 3.4, Enum.Material.Mud)
		plot.CFrame = CFrame.new(p.X, 1.0, p.Z) * (plot.CFrame - plot.CFrame.Position)
		-- Sprout leaves so an empty plot still says "something grows here".
		for k = 1, 3 do
			local leaf = Instance.new("Part")
			leaf.Name = "Sprout"
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.Material = Enum.Material.SmoothPlastic
			leaf.Color = Color3.fromRGB(96, 168, 70)
			leaf.Size = Vector3.new(0.3, 1.2, 1.6)
			leaf.CFrame = CFrame.new(p.X, 1.2, p.Z) * CFrame.Angles(0, math.rad(k * 120), math.rad(40)) * CFrame.new(0, 0, 1.6)
			leaf.Parent = plot
		end
	end
end
-- First three plots start ripe.
local n = 0
for _, plot in patch:GetChildren() do
	if plot.Name == "Plot" and n < 3 then
		plot:SetAttribute("StartRipe", true)
		n += 1
	end
end
-- A pumpkin pile vignette at the patch corner.
for k, spec in { { "pumpkin_orange", -45, 31, 1.5 }, { "pumpkin_yellow", -42, 33, 1.3 }, { "pumpkin_orange", -44, 35, 1.1 }, { "pumpkin_yellow", -47, 34, 1.6 } } do
	place(spec[1], at(spec[2], spec[3], k * 50), spec[4])
end

-- 3. Stepped altar with the giant as hero.
local function tier(name, radius, top, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.Material = Enum.Material.Slate
	p.Color = color
	p.Size = Vector3.new(top + 2, radius * 2, radius * 2)
	p.CFrame = CFrame.new(ALTAR + Vector3.new(0, top - (top + 2) / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = garden
	return p
end
tier("AltarStep", 22, 0.8, Color3.fromRGB(78, 72, 92))
tier("Altar", 18.5, 1.8, Color3.fromRGB(96, 90, 112))
tier("AltarTop", 11, 3.2, Color3.fromRGB(110, 102, 126))

local giant = garden.Giant
local mesh = kit.pumpkin_orange_jackolantern:FindFirstChildWhichIsA("MeshPart", true)
giant.Size = mesh.Size * 11
giant.CFrame = CFrame.new(ALTAR + Vector3.new(0, 3.2 + giant.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(180), 0)
local glow = giant:FindFirstChildOfClass("PointLight")
glow.Range = 24
local embers = giant:FindFirstChildOfClass("ParticleEmitter")
embers.Rate = 14
local outline = giant:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
outline.FillTransparency = 1
outline.OutlineColor = Color3.fromRGB(255, 150, 40)
outline.OutlineTransparency = 0.35
outline.DepthMode = Enum.HighlightDepthMode.Occluded
outline.Parent = giant
local uplight = garden.AltarTop:FindFirstChild("Uplight") or Instance.new("SpotLight")
uplight.Name = "Uplight"
uplight.Face = Enum.NormalId.Right -- the cylinder's local +X points up after the 90° roll
uplight.Angle = 70
uplight.Range = 30
uplight.Brightness = 3
uplight.Color = Color3.fromRGB(255, 140, 60)
uplight.Parent = garden.AltarTop
local collider = garden.GiantCollider
collider.Size = Vector3.one * (giant.Size.X * 0.9)
collider.CFrame = giant.CFrame
local gold = ReplicatedStorage:FindFirstChild("GiantGold")
if gold then
	gold.Size = giant.Size
end

-- 4. Sockets become stone dishes on the middle tier.
for i, socket in garden.Sockets:GetChildren() do
	local index = tonumber(string.match(socket.Name, "%d+")) or i
	local a = (index - 0.5) / 8 * math.pi * 2
	local pos = ALTAR + Vector3.new(math.cos(a) * 15, 1.8, math.sin(a) * 15)
	socket.CFrame = CFrame.new(pos + Vector3.new(0, 0.35, 0))
	for _, c in socket:GetChildren() do
		if c:IsA("BasePart") then
			c:Destroy()
		end
	end
	local dish = Instance.new("Part")
	dish.Name = "Dish"
	dish.Shape = Enum.PartType.Cylinder
	dish.Anchored = true
	dish.Material = Enum.Material.Slate
	dish.Color = Color3.fromRGB(70, 64, 80)
	dish.Size = Vector3.new(0.6, 6.4, 6.4)
	dish.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	dish.Parent = socket
	local inner = dish:Clone()
	inner.Name = "Inner"
	inner.Material = Enum.Material.Slate
	inner.Color = Color3.fromRGB(36, 30, 44)
	inner.Size = Vector3.new(0.62, 5, 5)
	inner.Parent = socket
	local ring = dish:Clone()
	ring.Name = "Ring"
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 140, 40)
	ring.CastShadow = false
	ring.CanCollide = false
	ring.Transparency = 1
	ring.Size = Vector3.new(0.64, 4.2, 4.2)
	ring.Parent = socket
end
local ghost = ReplicatedStorage:FindFirstChild("GhostJack")
if ghost then
	ghost:Destroy()
end
ghost = ServerStorage.KitTemplates.Jack:Clone()
ghost.Name = "GhostJack"
ghost.Size *= 1.6
ghost.Parent = ReplicatedStorage

-- Candles with flames around the bottom step, lantern pair at the front.
for i = 0, 11 do
	local a = (i + 0.25) / 12 * math.pi * 2
	local c = place(i % 3 == 0 and "skull_candle" or "candle_triple", at(math.cos(a) * 20.3, ALTAR.Z + math.sin(a) * 20.3, math.deg(-a), 0.8), 1)
	flame(c)
end
for _, x in { -12, 12 } do
	local l = place("lantern_standing", at(x, 3, 0), 1.4)
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 160, 70)
	pl.Range = 16
	pl.Brightness = 1.4
	pl.Parent = l:FindFirstChildWhichIsA("BasePart", true)
end
-- Pillars ring behind the giant, further out.
for i = 1, 5 do
	local a = math.rad(200 + i * 28)
	place("pillar", at(math.cos(a) * 26, ALTAR.Z + math.sin(a) * 26, math.deg(a)), 1.5)
end
-- Skulls and candles grouped by the graves.
for k = 1, 4 do
	local c = place(k % 2 == 0 and "skull_candle" or "candle_triple", at(24 + k * 2.5, -2 + (k % 2) * 3, k * 40), 1)
	flame(c)
end

-- Crypt further back so it doesn't compete with the giant.
for _, m in art:GetChildren() do
	if m.Name == "crypt" then
		m:PivotTo(at(40, -44, 210))
	end
end

-- 5. Patch path joins the main path at z=20; the arch spans the route after the join.
for _, m in art:GetChildren() do
	if string.match(m.Name, "^path_") then
		local p = m:GetPivot().Position
		if p.X < -2 then
			m:Destroy()
		end
	end
end
local tiles = { "path_A", "path_B", "path_C", "path_D" }
for s = 0, 3 do
	local x = -14 + s * 3.6
	local t = place(tiles[rng:NextInteger(1, 4)], at(x, 20 + rng:NextNumber(-0.4, 0.4), rng:NextInteger(0, 3) * 90), 1)
	t:PivotTo(t:GetPivot() + Vector3.new(0, 0.06, 0))
end
place("arch", at(0, 12, 0), 1.6)

return "revamp1 done"
