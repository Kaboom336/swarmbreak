-- Arena round 8 map: a crowd-size garden (~260 studs) around a big 4-tier Pumpkin Pyramid.
-- Ramps on every face, slam sockets on each tier ledge, four corner pumpkin fields,
-- a cauldron gate at every ramp foot, a raised spawn plaza and the shop. Run in Edit mode.
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local kit = ServerStorage.KitSource
local rng = Random.new(8)

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

local function place(name, cf, scale, parent)
	local m = kit[name]:Clone()
	m:ScaleTo(2.5 * (scale or 1))
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
local function at(x, z, yaw, y)
	return CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
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
local function signpost(name, text, color, position)
	local anchor = part({
		Name = name,
		CanCollide = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.one,
		Position = position,
		Parent = garden,
	})
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(230, 58)
	bb.LightInfluence = 0
	bb.MaxDistance = 260
	bb.Parent = anchor
	local label = Instance.new("TextLabel")
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
end

local DIRS = {
	{ name = "S", v = Vector3.new(0, 0, 1) },
	{ name = "E", v = Vector3.new(1, 0, 0) },
	{ name = "N", v = Vector3.new(0, 0, -1) },
	{ name = "W", v = Vector3.new(-1, 0, 0) },
}

-- 1. Terrain: grass everywhere, gentle hills outside, dirt around the pyramid and on the paths.
Terrain:Clear()
Terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(420, 8, 420), Enum.Material.LeafyGrass)
Terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(84, 116, 56))
Terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(74, 48, 32))
Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(96, 70, 48))
for _ = 1, 40 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(150, 200)
	Terrain:FillBall(Vector3.new(math.cos(a) * r, -8, math.sin(a) * r), rng:NextNumber(14, 26), Enum.Material.LeafyGrass)
end
Terrain:FillCylinder(CFrame.new(0, -6, 0), 4, 72, Enum.Material.Ground)
for _, d in DIRS do
	local mid = d.v * 92
	local size = d.v.X ~= 0 and Vector3.new(60, 4, 18) or Vector3.new(18, 4, 60)
	Terrain:FillBlock(CFrame.new(mid + Vector3.new(0, -6, 0)), size, Enum.Material.Ground)
end

-- 2. Pyramid: four stone tiers, a trim on each ledge, a plinth for the giant.
local pyramid = Instance.new("Model")
pyramid.Name = "Pyramid"
pyramid.Parent = garden
local TIERS = {
	{ width = 96, top = 8, color = Color3.fromRGB(84, 76, 98) },
	{ width = 72, top = 16, color = Color3.fromRGB(96, 88, 112) },
	{ width = 48, top = 24, color = Color3.fromRGB(108, 98, 124) },
	{ width = 24, top = 32, color = Color3.fromRGB(120, 110, 138) },
}
for i, tier in TIERS do
	local h = tier.top + 2
	part({
		Name = "Tier" .. i,
		Material = Enum.Material.Slate,
		Color = tier.color,
		Size = Vector3.new(tier.width, h, tier.width),
		CFrame = CFrame.new(0, tier.top - h / 2, 0),
		Parent = pyramid,
	})
	part({
		Name = "Trim" .. i,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(52, 44, 62),
		Size = Vector3.new(tier.width + 0.6, 0.6, tier.width + 0.6),
		CFrame = CFrame.new(0, tier.top - 0.3, 0),
		Parent = pyramid,
	})
	local half = tier.width / 2 - 1.5
	for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		local candle = place("candle_triple", at(c[1] * half, c[2] * half, 45, tier.top), 1.4, pyramid)
		candle.Name = "TierCandle" .. i
		local _, size = candle:GetBoundingBox()
		local flame = part({
			Name = "Flame",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 170, 60),
			Size = Vector3.new(0.6, 0.9, 0.6),
			CanCollide = false,
			CastShadow = false,
			Transparency = 1,
			CFrame = CFrame.new(candle:GetPivot().Position + Vector3.new(0, size.Y + 0.3, 0)),
			Parent = candle,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 70)
		light.Range = 12
		light.Brightness = 1.2
		light.Enabled = false
		light.Parent = flame
	end
end
local GIANT_BASE_Y = 38
part({
	Name = "Plinth",
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Slate,
	Color = Color3.fromRGB(70, 60, 84),
	Size = Vector3.new(GIANT_BASE_Y - 32, 10, 10),
	CFrame = CFrame.new(0, (32 + GIANT_BASE_Y) / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Parent = pyramid,
})

-- 3. Ramps: one per face, ground -> tier 1, then ledge -> next tier, all 16 wide.
local ramps = Instance.new("Folder")
ramps.Name = "Ramps"
ramps.Parent = pyramid
for _, d in DIRS do
	local flights = {
		{ outer = TIERS[1].width / 2 + 16, inner = TIERS[1].width / 2, bottom = 0, top = TIERS[1].top },
	}
	for t = 1, #TIERS - 1 do
		table.insert(flights, {
			outer = TIERS[t].width / 2,
			inner = TIERS[t + 1].width / 2,
			bottom = TIERS[t].top,
			top = TIERS[t + 1].top,
		})
	end
	for i, f in flights do
		local run = f.outer - f.inner
		local rise = f.top - f.bottom
		local center = d.v * ((f.outer + f.inner) / 2) + Vector3.new(0, f.bottom + rise / 2, 0)
		part({
			Class = "WedgePart",
			Name = "Ramp" .. d.name .. i,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(128, 116, 142),
			Size = Vector3.new(16, rise, run),
			CFrame = CFrame.lookAt(center, center + d.v),
			Parent = ramps,
		})
	end
end

-- 4. Slam sockets on every tier ledge, skipping the ramp lanes.
local sockets = Instance.new("Folder")
sockets.Name = "Sockets"
sockets.Parent = pyramid
local jackMesh = kit.pumpkin_orange_jackolantern:FindFirstChildWhichIsA("MeshPart", true)
local SOCKET = 5
local index = 0
for t, tier in TIERS do
	local ring, offsets
	if t < #TIERS then
		ring = (tier.width / 2 + TIERS[t + 1].width / 2) / 2
		offsets = {}
		local span = ring - 6
		local o = -span
		while o <= span + 0.01 do
			if math.abs(o) >= 11 then
				table.insert(offsets, o)
			end
			o += 10
		end
	else
		ring = 8
		offsets = { -7, 7 }
	end
	for _, d in DIRS do
		local along = Vector3.new(d.v.Z, 0, -d.v.X)
		for _, o in offsets do
			index += 1
			local pos = d.v * ring + along * o + Vector3.new(0, tier.top, 0)
			local socket = part({
				Name = string.format("Socket%02d", index),
				CanCollide = false,
				Transparency = 1,
				Size = Vector3.new(SOCKET, 0.2, SOCKET),
				CFrame = CFrame.lookAt(pos, pos + d.v),
				Parent = sockets,
			})
			socket:SetAttribute("Tier", t)
			socket:SetAttribute("Index", index)
			part({
				Class = "Part",
				Name = "Ring",
				Shape = Enum.PartType.Cylinder,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 140, 40),
				CanCollide = false,
				CanQuery = false,
				CastShadow = false,
				Transparency = 1,
				Size = Vector3.new(0.12, SOCKET + 1, SOCKET + 1),
				CFrame = CFrame.new(pos + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Parent = socket,
			})
			local ghost = jackMesh:Clone()
			ghost.Name = "Ghost"
			ghost.Anchored = true
			ghost.CanCollide = false
			ghost.CanQuery = false
			ghost.CastShadow = false
			ghost.Material = Enum.Material.ForceField
			ghost.Color = Color3.fromRGB(255, 160, 60)
			ghost.Transparency = 1
			ghost.Size = jackMesh.Size * (SOCKET * 0.8 / jackMesh.Size.X)
			ghost.CFrame = socket.CFrame * CFrame.new(0, ghost.Size.Y / 2, 0)
			ghost.Parent = socket
		end
	end
end

-- 5. The giant on the plinth: a plain pumpkin that becomes a carved jack.
local giant = jackMesh:Clone()
giant.Name = "Giant"
giant.Anchored = true
giant.CanCollide = false
giant.Size = jackMesh.Size * (16 / jackMesh.Size.X)
giant.CFrame = CFrame.new(0, GIANT_BASE_Y + giant.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0)
giant.Transparency = 1
giant.Parent = garden
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(255, 150, 50)
glow.Range = 26
glow.Brightness = 1.6
glow.Parent = giant
local outline = Instance.new("Highlight")
outline.FillTransparency = 1
outline.OutlineColor = Color3.fromRGB(255, 150, 40)
outline.OutlineTransparency = 0.35
outline.DepthMode = Enum.HighlightDepthMode.Occluded
outline.Enabled = false
outline.Parent = giant
local embers = Instance.new("ParticleEmitter")
embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60))
embers.LightEmission = 1
embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
embers.Lifetime = NumberRange.new(1.5, 2.5)
embers.Rate = 14
embers.Speed = NumberRange.new(2, 4)
embers.SpreadAngle = Vector2.new(30, 30)
embers.Parent = giant
local plainMesh = kit.pumpkin_orange:FindFirstChildWhichIsA("MeshPart", true)
local plain = plainMesh:Clone()
plain.Name = "GiantPlain"
plain.Anchored = true
plain.CanCollide = false
plain.Size = plainMesh.Size * (16 / plainMesh.Size.X)
plain.CFrame = CFrame.new(0, GIANT_BASE_Y + plain.Size.Y / 2, 0)
plain.Parent = garden
local goldForm = ReplicatedStorage:FindFirstChild("GiantGold")
if goldForm then
	goldForm.Size = giant.Size
end

-- 6. Cauldron gates at every ramp foot: carry a pumpkin under the arch to dunk it.
local gates = Instance.new("Folder")
gates.Name = "Gates"
gates.Parent = garden
for _, d in DIRS do
	local center = d.v * 80
	local gate = Instance.new("Model")
	gate.Name = "Gate" .. d.name
	gate.Parent = gates
	local arch = place("arch", CFrame.lookAt(center, center + d.v), 1.7, gate)
	arch.Name = "Arch"
	local side = Vector3.new(d.v.Z, 0, -d.v.X)
	local potPos = center + side * 12
	part({
		Name = "Pot",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(34, 30, 40),
		Size = Vector3.new(6, 9, 9),
		CFrame = CFrame.new(potPos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = gate,
	})
	part({
		Name = "Rim",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(44, 38, 52),
		Size = Vector3.new(1, 10, 10),
		CFrame = CFrame.new(potPos + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = gate,
	})
	local brew = part({
		Name = "Brew",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(120, 230, 80),
		CanCollide = false,
		Size = Vector3.new(0.3, 8, 8),
		CFrame = CFrame.new(potPos + Vector3.new(0, 5.9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = gate,
	})
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color = ColorSequence.new(Color3.fromRGB(150, 255, 110))
	bubbles.LightEmission = 1
	bubbles.Size = NumberSequence.new(0.8, 0)
	bubbles.Lifetime = NumberRange.new(1, 1.8)
	bubbles.Rate = 12
	bubbles.Speed = NumberRange.new(3, 6)
	bubbles.EmissionDirection = Enum.NormalId.Right
	bubbles.Parent = brew
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(110, 220, 90))
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8) })
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Rate = 4
	smoke.Speed = NumberRange.new(4, 7)
	smoke.EmissionDirection = Enum.NormalId.Right
	smoke.Parent = brew
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(120, 255, 90)
	light.Range = 20
	light.Brightness = 2
	light.Parent = brew
	part({
		Name = "Zone",
		CanCollide = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.new(20, 10, 8),
		CFrame = CFrame.lookAt(center + Vector3.new(0, 5, 0), center + Vector3.new(0, 5, 0) + d.v),
		Parent = gate,
	})
	signpost("SignGate" .. d.name, "MAGIC CAULDRON", Color3.fromRGB(150, 255, 110), center + Vector3.new(0, 22, 0))
end

-- 7. Four corner pumpkin fields, 30 vines each.
local fields = Instance.new("Folder")
fields.Name = "Fields"
fields.Parent = garden
for fi, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
	local fc = Vector3.new(c[1] * 92, 0, c[2] * 92)
	local field = Instance.new("Folder")
	field.Name = "Field" .. fi
	field.Parent = fields
	Terrain:FillBlock(CFrame.new(fc + Vector3.new(0, -6, 0)), Vector3.new(62, 4, 52), Enum.Material.Ground)
	for gx = 0, 5 do
		for gz = 0, 4 do
			local p = fc + Vector3.new((gx - 2.5) * 10, 0, (gz - 2) * 10)
			Terrain:FillBall(Vector3.new(p.X, -3.4, p.Z), 3.2, Enum.Material.Mud)
			local plot = part({
				Name = "Plot",
				CanCollide = false,
				Transparency = 1,
				Size = Vector3.new(2, 0.2, 2),
				CFrame = CFrame.new(p.X, 1, p.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
				Parent = field,
			})
			for k = 1, 3 do
				part({
					Name = "Sprout",
					CanCollide = false,
					Material = Enum.Material.SmoothPlastic,
					Color = Color3.fromRGB(96, 168, 70),
					Size = Vector3.new(0.3, 1.2, 1.6),
					CFrame = CFrame.new(p.X, 1.1, p.Z) * CFrame.Angles(0, math.rad(k * 120), math.rad(40)) * CFrame.new(0, 0, 1.6),
					Parent = plot,
				})
			end
		end
	end
	-- Low fence on the two outer sides, lamps on the inner corner.
	for k = -2, 2 do
		place("fence_seperate", at(fc.X + k * 11, fc.Z + c[2] * 29, 0), 1)
		place("fence_seperate", at(fc.X + c[1] * 34, fc.Z + k * 10, 90), 1)
	end
	lamp(fc.X - c[1] * 34, fc.Z - c[2] * 29, 1.2)
	signpost("SignField" .. fi, "PUMPKINS", Color3.fromRGB(255, 160, 50), fc + Vector3.new(0, 16, 0))
end

-- 8. Raised spawn plaza on the south edge, shop beside it.
part({
	Name = "Plaza",
	Material = Enum.Material.Slate,
	Color = Color3.fromRGB(92, 84, 104),
	Size = Vector3.new(52, 2, 30),
	CFrame = CFrame.new(0, 1, 104),
	Parent = garden,
})
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.CFrame = CFrame.lookAt(Vector3.new(0, 2.5, 104), Vector3.new(0, 2.5, 0))
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = garden
for _, d in spawn:GetChildren() do
	if d:IsA("Decal") then
		d:Destroy()
	end
end
local shop = part({
	Name = "UpgradeBoard",
	Material = Enum.Material.Wood,
	Color = Color3.fromRGB(88, 58, 38),
	Size = Vector3.new(14, 10, 0.8),
	CFrame = CFrame.new(-20, 8, 100) * CFrame.Angles(0, math.rad(-150), 0),
	Parent = garden,
})
for _, x in { -6, 6 } do
	part({
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(70, 46, 30),
		Size = Vector3.new(0.8, 11, 0.8),
		CFrame = shop.CFrame * CFrame.new(x, -1.5, 0.8),
		Parent = shop,
	})
end
for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = shop
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.6)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 214, 80)
	title.Text = "SHOP"
	title.Parent = gui
	local sub = title:Clone()
	sub.Position = UDim2.fromScale(0, 0.6)
	sub.Size = UDim2.fromScale(1, 0.3)
	sub.TextColor3 = Color3.fromRGB(255, 240, 220)
	sub.Text = "Upgrades inside"
	sub.Parent = gui
end
signpost("SignShop", "SHOP", Color3.fromRGB(110, 210, 255), Vector3.new(-20, 18, 100))
signpost("SignPyramid", "GIANT PYRAMID", Color3.fromRGB(255, 214, 80), Vector3.new(0, 70, 0))

-- 9. Dressing: lamps along the four roads, a graveyard and crypt between fields, fence ring, trees.
for _, d in DIRS do
	for k = 0, 2 do
		local p = d.v * (58 + k * 16)
		local side = Vector3.new(d.v.Z, 0, -d.v.X)
		lamp(p.X + side.X * 11, p.Z + side.Z * 11)
		lamp(p.X - side.X * 11, p.Z - side.Z * 11)
	end
end
local graves = { "grave_A", "grave_B", "gravestone", "gravemarker_A", "gravemarker_B", "grave_A_destroyed" }
for _ = 1, 18 do
	local x = rng:NextNumber(-30, 30)
	local z = rng:NextNumber(-125, -100)
	place(graves[rng:NextInteger(1, #graves)], at(x, z, rng:NextNumber(-20, 20)), rng:NextNumber(1, 1.3))
end
place("crypt", at(0, -112, 0), 1.6)
place("shrine_candles", at(112, 0, 270), 1.8)
place("tree_dead_large_decorated", at(-112, 0, 90), 2.2)
local R = 130
for i = -R + 5, R - 5, 10 do
	place("fence", at(i, R, 0), 1)
	place("fence", at(i, -R, 0), 1)
	place("fence", at(R, i, 90), 1)
	place("fence", at(-R, i, 90), 1)
end
local trees = { "tree_pine_orange_large", "tree_pine_orange_medium", "tree_pine_yellow_large", "tree_dead_large", "tree_dead_medium" }
for _ = 1, 110 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(R + 8, R + 50)
	local x, z = math.cos(a) * r, math.sin(a) * r
	if math.abs(x) < 40 and z > 120 then
		continue -- keep the view behind the spawn clear
	end
	place(trees[rng:NextInteger(1, #trees)], at(math.cos(a) * r, math.sin(a) * r, rng:NextNumber(0, 360)), rng:NextNumber(1.6, 2.6))
end

-- 10. Lighting stays dusk; fog pulled out for the bigger map.
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then
	atmosphere.Density = 0.32
end
workspace.StreamingEnabled = false

return string.format("big map built: %d sockets", index)
