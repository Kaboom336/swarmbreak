-- Run in Studio EDIT after LaunchLook v1. Only owned decoration is rebuilt.
-- References: LOOK-CRITIC-1 ten fixes; AUDIT-LOBBY-MAP section 4 (TE / SAE / PS99).
-- Hard caps override conflicting critic requests: 40 PointLights, <1500 new parts.
-- Existing client snapshots Lighting, but does NOT consume Base* attributes and
-- neutralises PhaseTint on Day. Existing server also restores legacy King visuals.
assert(not game:GetService("RunService"):IsRunning(), "LaunchLook2 requires Edit mode")
local lighting = game:GetService("Lighting")
local storage = game:GetService("ServerStorage")
local garden = assert(workspace:FindFirstChild("Garden"), "Missing Garden")
local art = assert(garden:FindFirstChild("Art"), "Missing Garden.Art")
local market = assert(garden:FindFirstChild("Market"), "Missing Garden.Market")
local pens = assert(garden:FindFirstChild("Patches"), "Missing Garden.Patches")
local v1 = assert(art:FindFirstChild("LaunchLook"), "Run LaunchLook v1 first")
local king = assert(v1:FindFirstChild("ThroneKing"), "Missing v1 ThroneKing")
assert(king:IsA("Model"), "ThroneKing must be a Model")
local spawn = assert(garden:FindFirstChild("SpawnLocation"), "Missing SpawnLocation")
local KC = Vector3.new(1500, 0, 40)
local hex = Color3.fromHex
local function yieldChunk(i)
	if i % 80 == 0 then
		task.wait()
	end
end
local function counts()
	local parts, lights = 0, 0
	for i, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
		if d:IsA("PointLight") then
			lights += 1
		end
		yieldChunk(i)
	end
	return parts, lights
end
local before, lightsBefore = counts()
local function teardown(root)
	for i, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d:Destroy()
		end
		yieldChunk(i)
	end
	root:Destroy()
end
local old = art:FindFirstChild("LaunchLook2")
if old then
	teardown(old)
end
-- Names created solely by v1; never touch Market / Patches / Zones contracts.
for _, name in { "WallLanterns", "StringLights", "WallProps" } do
	local f = v1:FindFirstChild(name)
	if f then
		teardown(f)
	end
end
-- LobbyDecor is decoration authored by Lobby, never a game-script contract.
local decor = art:FindFirstChild("LobbyDecor")
if decor then
	for i, d in decor:GetChildren() do
		if
			d:IsA("Model")
			or (d:IsA("BasePart") and (d.Name == "Pennant" or d.Name == "PennantPole"))
		then
			teardown(d)
		end
		yieldChunk(i)
	end
end
local look = Instance.new("Folder")
look.Name, look.Parent = "LaunchLook2", art
look:SetAttribute(
	"Reference",
	"Pumpkin Patch at Golden Hour; TE t_0494 / SAE h_0018 critic criteria"
)
local function folder(name)
	local f = Instance.new("Folder")
	f.Name, f.Parent = name, look
	return f
end
local added = 0
local function part(parent, name, size, cf, color, material, class)
	assert(added < 1499, "LaunchLook2 decoration budget exceeded")
	local p = Instance.new(class or "Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = hex(color), material or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	added += 1
	yieldChunk(added)
	return p
end
local function cylinder(parent, name, diameter, height, at, color, material)
	local p = part(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function label(gui, text, color)
	local l = Instance.new("TextLabel")
	l.Size, l.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	l.Text, l.TextColor3, l.Font, l.TextScaled = text, hex(color), Enum.Font.FredokaOne, true
	l.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Parent = hex("2D1F43"), 3, l
end
local function title(parent, text, width, height, offset, color, distance)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size = "LaunchTitle", UDim2.fromScale(width, height)
	gui.StudsOffsetWorldSpace, gui.MaxDistance = offset, distance
	gui.LightInfluence, gui.AlwaysOnTop, gui.Parent = 0, false, parent
	label(gui, text, color)
end
-- All PointLights count, including disabled lights. Retain existing instances
-- outside rebuilt decoration, including any game-referenced LookGlow lights.
local external = 0
for i, d in workspace:GetDescendants() do
	if d:IsA("PointLight") then
		external += 1
	end
	yieldChunk(i)
end
assert(external <= 12, "Too many retained PointLights to reserve 28 hero/path/bed lights")
local lightCount = external
local function light(parent, color, brightness, range)
	if lightCount >= 40 then
		return
	end
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = hex(color), brightness, range, false
	l.Parent = parent
	lightCount += 1
end

-- 4. Golden hour, a single PhaseTint; preserve cartoon Sky asset IDs.
for i, d in lighting:GetDescendants() do
	if
		d:IsA("ColorCorrectionEffect")
		or d:IsA("Atmosphere")
		or d:IsA("BloomEffect")
		or d:IsA("SunRaysEffect")
	then
		d:Destroy()
	end
	yieldChunk(i)
end
for key, value in
	{
		ClockTime = 15.6,
		Brightness = 2.4,
		GeographicLatitude = 30,
		ExposureCompensation = 0,
		GlobalShadows = true,
		ShadowSoftness = 0.2,
		Ambient = hex("8C7AA8"),
		OutdoorAmbient = hex("9D8DBF"),
		ColorShift_Top = hex("FFD9A8"),
		ColorShift_Bottom = hex("6B4E8C"),
		EnvironmentDiffuseScale = 0.4,
		EnvironmentSpecularScale = 0.3,
	}
do
	lighting[key] = value
	lighting:SetAttribute("Base" .. key, value)
end
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "PhaseTint"
for key, value in
	{ Brightness = 0.02, Contrast = 0.12, Saturation = 0.08, TintColor = hex("FFF1E6") }
do
	cc[key] = value
	cc:SetAttribute("Base" .. key, value)
	lighting:SetAttribute("BaseGrade" .. key, value)
	if key ~= "Brightness" then
		lighting:SetAttribute("Base" .. key, value)
	end
end
cc.Parent = lighting
local atmosphere = Instance.new("Atmosphere")
for key, value in
	{
		Density = 0.28,
		Offset = 0.12,
		Color = hex("E7C8E8"),
		Decay = hex("B07ACF"),
		Glare = 0.15,
		Haze = 1.2,
	}
do
	atmosphere[key] = value
	atmosphere:SetAttribute("Base" .. key, value)
	lighting:SetAttribute("BaseAtmosphere" .. key, value)
end
atmosphere.Parent = lighting
local bloom = Instance.new("BloomEffect")
bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold, bloom.Parent =
	"HarvestBloom", 0.8, 28, 0.95, lighting
lighting:SetAttribute("BaseBloomIntensity", 0.8)
lighting:SetAttribute("BaseBloomSize", 28)
lighting:SetAttribute("BaseBloomThreshold", 0.95)
local rays = Instance.new("SunRaysEffect")
rays.Name, rays.Intensity, rays.Spread, rays.Parent = "HarvestSun", 0.06, 0.6, lighting
lighting:SetAttribute("BaseSunRaysIntensity", 0.06)
lighting:SetAttribute("BaseSunRaysSpread", 0.6)
for _, sky in lighting:GetChildren() do
	if sky:IsA("Sky") then
		sky.SunAngularSize = 14
		lighting:SetAttribute("BaseSunAngularSize", 14)
	end
end
local moon = cylinder(
	look,
	"DaytimeMoon",
	160,
	0.3,
	Vector3.new(1500, 120, 460),
	"E9DDF5",
	Enum.Material.Neon
)
moon.CFrame = CFrame.lookAt(
	moon.Position,
	Vector3.new(spawn.Position.X, moon.Position.Y, spawn.Position.Z)
) * CFrame.Angles(0, math.pi / 2, 0)
moon.Transparency = 0.2
task.wait()

-- 3. Repaint the existing collision floor, not Terrain (raycast contracts preserved).
local floorCount = 0
local ground = assert(garden:FindFirstChild("Ground"), "Missing Ground")
for i, p in ground:GetDescendants() do
	if
		p:IsA("BasePart")
		and math.abs(p.Position.X - 1500) <= 180
		and p.Position.Z >= -80
		and p.Position.Z <= 150
	then
		local parity = (
			math.floor((p.Position.X - 1330) / 16) + math.floor((p.Position.Z + 70) / 16)
		) % 2
		local corner = math.abs(p.Position.X - KC.X) > 120 and math.abs(p.Position.Z - KC.Z) > 70
		p.Color = hex(corner and "9CC544" or (parity == 0 and "6BAA3E" or "639F39"))
		p.Material, p.TopSurface, p.BottomSurface =
			Enum.Material.Grass, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for _, d in p:GetDescendants() do
			if d:IsA("Texture") or d:IsA("Decal") then
				d:Destroy()
			end
		end
		floorCount += 1
	end
	yieldChunk(i)
end
task.wait()

-- 10. Scale stations once from saved v1 pivots; prompts move with their models.
local stations = {}
for _, spec in
	{
		{ "Sell", "SELL", "39D8F0" },
		{ "Seeds", "SHOP", "FFC83D" },
		{ "Upgrades", "UPGRADES", "7A52BF" },
	}
do
	local m = market:FindFirstChild(spec[1])
	assert(m and m:IsA("Model"), "Missing Market." .. spec[1])
	local baseScale = m:GetAttribute("Launch2BaseScale") or m:GetScale()
	local basePivot = m:GetAttribute("Launch2BasePivot") or m:GetPivot()
	m:SetAttribute("Launch2BaseScale", baseScale)
	m:SetAttribute("Launch2BasePivot", basePivot)
	m:ScaleTo(baseScale * 1.5)
	-- Inward from the nearest hub boundary, exactly 25 studs; never compound.
	local v = basePivot.Position - KC
	local delta = if math.abs(v.X) / 170 > math.abs(v.Z) / 110
		then Vector3.new(-math.sign(v.X) * 25, 0, 0)
		else Vector3.new(0, 0, -math.sign(v.Z) * 25)
	m:PivotTo(basePivot + delta)
	local box, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, -(box.Position.Y - size.Y / 2), 0))
	local at = m:GetPivot().Position
	local pad = cylinder(
		look,
		spec[2] .. "Pad",
		18,
		0.2,
		Vector3.new(at.X, 0.2, at.Z),
		spec[3],
		Enum.Material.Neon
	)
	pad.Transparency = 0.4
	local anchor = part(look, "StationTitle", Vector3.one, CFrame.new(at.X, 24, at.Z), "2D1F43")
	anchor.Transparency = 1
	title(anchor, spec[2], 32, 6, Vector3.zero, spec[3], 350)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
		if d:IsA("BillboardGui") then
			d.Enabled = false
		end
	end
	table.insert(stations, { model = m, at = Vector3.new(at.X, 0, at.Z), name = spec[1] })
	task.wait()
end
local sell = stations[1].at
local cauldron = part(
	look,
	"SellCauldron",
	Vector3.new(10, 7, 10),
	CFrame.new(sell + Vector3.new(0, 3.5, 0)),
	"2D1F43"
)
cauldron.Shape = Enum.PartType.Ball
local goo = cylinder(
	look,
	"CauldronGoo",
	8.5,
	0.2,
	sell + Vector3.new(0, 6, 0),
	"78E580",
	Enum.Material.Neon
)
light(goo, "78E580", 1.5, 14)
local bubbles = Instance.new("ParticleEmitter")
bubbles.Name, bubbles.Rate = "Bubbles", 6
bubbles.Texture = "rbxasset://textures/particles/bubble_main.dds"
bubbles.Color, bubbles.Lifetime, bubbles.Speed =
	ColorSequence.new(hex("78E580")), NumberRange.new(1, 2), NumberRange.new(2, 4)
bubbles.Size, bubbles.SpreadAngle, bubbles.Parent =
	NumberSequence.new(0.5), Vector2.new(12, 12), goo
-- Preserve SELL prompt/counter, hide only its plain presentation.
for _, d in stations[1].model:GetDescendants() do
	if d:IsA("BasePart") and d.Name ~= "PromptPart" then
		d.Transparency = 1
	end
	if d:IsA("SurfaceGui") then
		d.Enabled = false
	end
end

-- 1. Reuse v1 king's voxel body, 2.2x once. Its authored face is +Z;
-- turn voxel geometry 180 locally, so the requested lookAt pivot faces spawn.
if not king:GetAttribute("Launch2ForwardFixed") then
	local pivot = king:GetPivot()
	for i, d in king:GetDescendants() do
		if d:IsA("BasePart") and d ~= king.PrimaryPart then
			d.CFrame = pivot * CFrame.Angles(0, math.pi, 0) * pivot:ToObjectSpace(d.CFrame)
		end
		yieldChunk(i)
	end
	king:SetAttribute("Launch2ForwardFixed", true)
end
local kingBaseScale = king:GetAttribute("Launch2BaseScale") or king:GetScale()
king:SetAttribute("Launch2BaseScale", kingBaseScale)
king:ScaleTo(kingBaseScale * 2.2)
local kingPos = KC + Vector3.new(0, 4.5, 0)
local facing = CFrame.lookAt(kingPos, Vector3.new(spawn.Position.X, kingPos.Y, spawn.Position.Z))
king:PivotTo(facing)
for i, d in king:GetDescendants() do
	if d:IsA("BasePart") then
		d.CanCollide, d.CanTouch, d.CanQuery, d.Anchored = false, false, false, true
		d.TopSurface = Enum.SurfaceType.Smooth
		if d.Name == "p" then
			d.Color, d.Material = hex("7A52BF"), Enum.Material.Plastic
		end
		if d.Name == "c" then
			d.Color = hex("D35208")
		end
		-- Replace old small head, face, collar and crown with exact critic silhouettes.
		if
			d.Name == "o"
			or d.Name == "d"
			or d.Name == "f"
			or d.Name == "y"
			or d.Name == "j"
			or d.Name == "w"
			or d.Name == "k"
		then
			d.Transparency = 1
		end
	end
	yieldChunk(i)
end
local hero = folder("ThroneDetails")
local headCF = CFrame.new(KC + Vector3.new(0, 30, 0)) * (facing - facing.Position)
-- Flat front at local Z=-10 allows genuinely recessed luminous carvings.
local head = part(hero, "RoyalPumpkinHead", Vector3.new(26, 22, 20), headCF, "F28C1A")
for _, x in { -10, -5, 0, 5, 10 } do
	part(hero, "PumpkinRib", Vector3.new(0.5, 21, 0.3), headCF * CFrame.new(x, 0, 10.1), "D35208")
end
-- Carvings are inset 0.5 into the head. A front made of panels leaves real
-- openings, avoiding buried/occluded Neon; the inner aubergine panel adds depth.
head.Transparency = 1
local roundedBack =
	part(hero, "HeadBack", Vector3.new(26, 22, 17), headCF * CFrame.new(0, 0, 1.5), "F28C1A")
roundedBack.Shape = Enum.PartType.Ball
part(hero, "HeadTop", Vector3.new(26, 4, 3), headCF * CFrame.new(0, 9, -8.5), "F28C1A")
part(hero, "HeadBottom", Vector3.new(26, 4, 3), headCF * CFrame.new(0, -9, -8.5), "D35208")
for _, x in { -11.25, 11.25 } do
	part(hero, "HeadSide", Vector3.new(3.5, 14, 3), headCF * CFrame.new(x, 0, -8.5), "F28C1A")
end
part(hero, "HeadNose", Vector3.new(3, 7, 3), headCF * CFrame.new(0, 3.5, -8.5), "F28C1A")
part(hero, "FaceInterior", Vector3.new(19, 14, 0.2), headCF * CFrame.new(0, 0, -9.2), "2D1F43")
for _, x in { -5, 5 } do
	part(
		hero,
		"TriangleEye",
		Vector3.new(0.4, 5, 5),
		headCF * CFrame.new(x, 3.5, -9.3) * CFrame.Angles(0, math.pi / 2, 0),
		"FFB347",
		Enum.Material.Neon,
		"WedgePart"
	)
end
for k = 0, 6 do
	part(
		hero,
		"ZigzagMouth",
		Vector3.new(0.4, 4, 2),
		headCF
			* CFrame.new(-6 + k * 2, -4, -9.3)
			* CFrame.Angles(0, math.pi / 2, 0)
			* CFrame.Angles(k % 2 * math.pi, 0, 0),
		"FFB347",
		Enum.Material.Neon,
		"WedgePart"
	)
end
light(head, "FF9A3C", 3, 40)
part(
	hero,
	"CrownBand",
	Vector3.new(20, 2, 20),
	headCF * CFrame.new(0, 12, 0),
	"FFC83D",
	Enum.Material.Metal
)
for k = 0, 4 do
	local a = k * math.pi * 2 / 5
	local cf = headCF * CFrame.new(math.cos(a) * 9, 15, math.sin(a) * 9)
	part(hero, "CrownPoint", Vector3.new(2, 4, 2), cf, "FFC83D", Enum.Material.Metal)
	local tip = part(
		hero,
		"CrownTip",
		Vector3.new(2, 1, 2),
		cf * CFrame.new(0, 2.5, 0),
		"FFE58A",
		Enum.Material.Neon
	)
	tip.Transparency = 0.3
end
part(hero, "Belt", Vector3.new(15, 1, 11), facing * CFrame.new(0, 8, 0), "2D1F43")
for _, x in { -4, 4 } do
	part(
		hero,
		"Cape",
		Vector3.new(8, 17, 0.4),
		facing * CFrame.new(x, 9, 7),
		"D35208",
		Enum.Material.Plastic,
		"WedgePart"
	)
end
local kingTitle =
	part(hero, "KingTitle", Vector3.one, CFrame.new(KC + Vector3.new(0, 48, 0)), "2D1F43")
kingTitle.Transparency = 1
title(kingTitle, "PUMPKIN KING", 40, 10, Vector3.zero, "FFC83D", 400)
local sign = market:FindFirstChild("SignJack")
if sign then
	for _, d in sign:GetDescendants() do
		if d:IsA("BillboardGui") then
			d.Enabled = false
		end
	end
end
task.wait()

-- 2. Three exact Y-axis steps. Keep the game's Plinth instance, hide its art.
local plinth = market:FindFirstChild("Plinth")
if plinth and plinth:IsA("BasePart") then
	plinth.Transparency, plinth.CanCollide = 1, false
end
local throne = folder("Throne")
for k, diameter in { 44, 36, 28 } do
	cylinder(
		throne,
		"Step" .. k,
		diameter,
		1.5,
		KC + Vector3.new(0, k * 1.5 - 0.75, 0),
		k == 1 and "A9ABD3" or "B8BADD"
	)
	cylinder(
		throne,
		"Trim" .. k,
		diameter + 0.5,
		0.3,
		KC + Vector3.new(0, k * 1.5 - 1.35, 0),
		"E8E4D0"
	)
end
local pool = cylinder(
	throne,
	"GlowPool",
	26,
	0.1,
	KC + Vector3.new(0, 4.55, 0),
	"FFB347",
	Enum.Material.Neon
)
pool.Transparency = 0.35
local meter = market:FindFirstChild("MeterRing")
if meter and meter:IsA("BasePart") then
	meter.Transparency, meter.CanCollide = 1, false
end
local function hay(parent, at, yaw)
	local cf = CFrame.new(at + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, yaw, 0)
	part(parent, "HayBale", Vector3.new(5, 3, 3), cf, "E3B04B", Enum.Material.Fabric)
	for _, x in { -1.5, 1.5 } do
		part(parent, "HayBand", Vector3.new(0.4, 3.05, 3.05), cf * CFrame.new(x, 0, 0), "B5832E")
	end
end
local function pumpkin(parent, at, diameter, lit)
	local p = part(
		parent,
		"Pumpkin",
		Vector3.new(diameter, diameter * 0.8, diameter),
		CFrame.new(at + Vector3.new(0, diameter * 0.4, 0)),
		"F28C1A"
	)
	p.Shape = Enum.PartType.Ball
	for _, x in { -0.28, 0.28 } do
		local rib = part(
			parent,
			"Shade",
			Vector3.new(diameter * 0.25, diameter * 0.75, diameter * 0.9),
			p.CFrame * CFrame.new(diameter * x, 0, 0),
			"D35208"
		)
		rib.Shape = Enum.PartType.Ball
	end
	part(
		parent,
		"Stem",
		Vector3.new(0.5, diameter * 0.2, 0.5),
		p.CFrame * CFrame.new(0, diameter * 0.47, 0),
		"4E7A2A"
	)
	part(
		parent,
		"Leaf",
		Vector3.new(diameter * 0.5, 0.2, diameter * 0.35),
		p.CFrame * CFrame.new(diameter * 0.3, diameter * 0.5, 0),
		"4E8F34",
		Enum.Material.Plastic,
		"WedgePart"
	)
	if lit then
		-- Surface face remains visible on curved pumpkins from the spawn side.
		local face = part(
			parent,
			"JackFace",
			Vector3.new(diameter * 0.55, diameter * 0.3, 0.1),
			CFrame.lookAt(p.Position + Vector3.new(0, 0, -diameter * 0.46), spawn.Position),
			"FFB347",
			Enum.Material.Neon
		)
		light(face, "FFB347", 1, 10)
	end
end
for k = 0, 11 do
	local a = math.rad(k * 30)
	local at = KC + Vector3.new(math.sin(a) * 25, 0, math.cos(a) * 25)
	hay(throne, at, a + math.pi / 2)
	if k == 1 or k == 5 or k == 9 then
		hay(throne, at + Vector3.new(0, 3, 0), a + math.pi / 2)
	end
end
for k = 0, 7 do
	local a = (k + 0.5) * math.pi / 4
	pumpkin(throne, KC + Vector3.new(math.sin(a) * 25, 0, math.cos(a) * 25), 3 + k % 3, false)
end
task.wait()

-- 5. Remove only the old Paths art; Plaza remains a contract under Market.
local paths = art:FindFirstChild("Paths")
if paths then
	for i, p in paths:GetDescendants() do
		if p:IsA("BasePart") then
			p:Destroy()
		end
		yieldChunk(i)
	end
end
paths = folder("CleanPaths")
cylinder(paths, "RingEdge", 86, 0.35, KC + Vector3.new(0, -0.025, 0), "E8E4D0")
cylinder(paths, "Ring", 84, 0.4, KC + Vector3.new(0, 0.05, 0), "B8BADD")
cylinder(paths, "InnerLawn", 52, 0.45, KC + Vector3.new(0, 0.075, 0), "6BAA3E", Enum.Material.Grass)
local plaza = market:FindFirstChild("Plaza")
if plaza and plaza:IsA("BasePart") then
	plaza.Color, plaza.Material = hex("A9ABD3"), Enum.Material.SmoothPlastic
end
local spokes = {}
local endpoints = {
	{ Vector3.new(1500, 0, -60), 16 },
	{ Vector3.new(1500, 0, 150), 16 },
	{ Vector3.new(1377, 0, 40), 12 },
	{ Vector3.new(1623, 0, 40), 12 },
}
for _, direction in { -1, 1 } do
	local a = math.rad(40) * direction
	table.insert(endpoints, { KC + Vector3.new(math.sin(a) * 115, 0, math.cos(a) * 115), 12 })
end
for _, spec in endpoints do
	local b, width = spec[1], spec[2]
	local dir = (b - KC).Unit
	local a = KC + dir * 38
	local mid, length = (a + b) / 2, (b - a).Magnitude
	local cf = CFrame.lookAt(mid + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0))
	part(paths, "Spoke", Vector3.new(width, 0.4, length), cf, "A9ABD3")
	for _, side in { -1, 1 } do
		part(
			paths,
			"Curb",
			Vector3.new(1, 0.5, length),
			cf * CFrame.new(side * (width / 2 + 0.5), 0.05, 0),
			"E8E4D0"
		)
	end
	cylinder(paths, "DestinationPad", width + 8, 0.4, b + Vector3.new(0, 0.05, 0), "B8BADD")
	table.insert(spokes, { a = a, b = b, width = width, cf = cf, length = length })
	task.wait()
end
-- Diagonal pads link to live stall pads with one broad, flat apron each;
-- the remaining station also connects to its nearest existing pad.
for _, station in stations do
	local nearest, distance = nil, math.huge
	if station.name == "Seeds" or station.name == "Upgrades" then
		nearest = spokes[station.name == "Seeds" and 6 or 5].b
		distance = (nearest - station.at).Magnitude
	else
		for _, s in spokes do
			local d = (s.b - station.at).Magnitude
			if d < distance then
				nearest, distance = s.b, d
			end
		end
	end
	if distance > 1 then
		local cf = CFrame.lookAt(
			(nearest + station.at) / 2 + Vector3.new(0, 0.05, 0),
			station.at + Vector3.new(0, 0.05, 0)
		)
		part(paths, "StationApron", Vector3.new(12, 0.4, distance), cf, "A9ABD3")
		table.insert(
			spokes,
			{ a = nearest, b = station.at, width = 12, cf = cf, length = distance, apron = true }
		)
	end
end

-- 8. Nominal bed envelopes are exact; clip planting to 10-stud path/fence
-- clearance where critic coordinates overlap existing protected pens.
local function clear(at, radius)
	for _, s in spokes do
		local delta = s.b - s.a
		local t = math.clamp((at - s.a):Dot(delta) / delta:Dot(delta), 0, 1)
		if (at - (s.a + delta * t)).Magnitude < s.width / 2 + 11 + radius then
			return false
		end
	end
	for _, pen in pens:GetChildren() do
		local soil = pen:FindFirstChild("Soil")
		if soil and soil:IsA("BasePart") then
			local p = soil.CFrame:PointToObjectSpace(Vector3.new(at.X, soil.Position.Y, at.Z))
			if
				math.abs(p.X) < soil.Size.X / 2 + 10 + radius
				and math.abs(p.Z) < soil.Size.Z / 2 + 10 + radius
			then
				return false
			end
		end
	end
	return true
end
local beds = folder("PumpkinBeds")
local rng = Random.new(1042)
local clipped, planted = 0, 0
local occupied = {}
local soilParts = 0
local function plantingClear(at, diameter)
	if not clear(at, diameter / 2) then
		return false
	end
	for _, other in occupied do
		if (at - other.at).Magnitude < (diameter + other.diameter) * 0.35 then
			return false
		end
	end
	return true
end
for index, spec in
	{
		{ -48, -62, 30, 18 },
		{ 48, -62, 30, 18 },
		{ -100, -40, 28, 16 },
		{ 100, -40, 28, 16 },
		{ -70, 60, 24, 14 },
		{ 70, 60, 24, 14 },
	}
do
	local at = KC + Vector3.new(spec[1], 0, spec[2])
	local bed = Instance.new("Folder")
	bed.Name, bed.Parent = "Bed" .. index, beds
	bed:SetAttribute("RequestedCenter", at)
	bed:SetAttribute("RequestedSize", Vector3.new(spec[3], 0.6, spec[4]))
	for x = -spec[3] / 2 + 2, spec[3] / 2 - 2, 4 do
		for z = -spec[4] / 2 + 2, spec[4] / 2 - 2, 4 do
			local p = at + Vector3.new(x, 0, z)
			if clear(p, 2.9) and soilParts < 100 then
				part(
					bed,
					"Soil",
					Vector3.new(4, 0.6, 4),
					CFrame.new(p + Vector3.new(0, 0.3, 0)),
					"7A4E33",
					Enum.Material.Ground
				)
				part(
					bed,
					"Furrow",
					Vector3.new(1, 0.2, 4),
					CFrame.new(p + Vector3.new(0, 0.7, 0)),
					"5E3A26"
				)
				soilParts += 2
			else
				clipped += 1
			end
		end
	end
	local candidates = {}
	for k = 1, 10 do
		local diameter = rng:NextNumber(2.5, 7)
		local chosen
		for attempt = 1, 300 do
			local p = at
				+ Vector3.new(
					rng:NextNumber(-spec[3] / 2 + diameter / 2, spec[3] / 2 - diameter / 2),
					0,
					rng:NextNumber(-spec[4] / 2 + diameter / 2, spec[4] / 2 - diameter / 2)
				)
			if plantingClear(p, diameter) then
				chosen = p
				break
			end
		end
		-- If the fixed envelope has no room, keep the exact pumpkin count on a
		-- nearby safe island; report every such relocation, never move a pen.
		if not chosen then
			local best = math.huge
			for x = -120, 120, 4 do
				for z = -85, 85, 4 do
					local p = KC + Vector3.new(x, 0, z)
					local d = (p - at).Magnitude
					if d < best and plantingClear(p, diameter) and (p - KC).Magnitude > 46 then
						chosen, best = p, d
					end
				end
			end
			clipped += 1
		end
		assert(chosen, "No safe planting space; protected pens kept intact")
		table.insert(occupied, { at = chosen, diameter = diameter })
		pumpkin(bed, chosen + Vector3.new(0, 0.6, 0), diameter, k == 1)
		table.insert(candidates, chosen)
		planted += 1
	end
	local stack = candidates[#candidates]
	if not clear(stack, 4.5) then
		for _, p in candidates do
			if clear(p, 4.5) then
				stack = p
				break
			end
		end
	end
	if not clear(stack, 4.5) then
		local best = math.huge
		for x = -120, 120, 4 do
			for z = -85, 85, 4 do
				local p = KC + Vector3.new(x, 0, z)
				local distance = (p - at).Magnitude
				if distance < best and clear(p, 4.5) and (p - KC).Magnitude > 46 then
					stack, best = p, distance
				end
			end
			task.wait()
		end
		assert(best < math.huge, "No clear hay-stack footprint")
		clipped += 1
	end
	hay(bed, stack, 0)
	hay(bed, stack + Vector3.new(0, 0, 3), 0)
	hay(bed, stack + Vector3.new(0, 3, 1.5), 0)
	task.wait()
end

-- 6. Twenty full-sized path lanterns; pairs 18 studs apart along spokes.
local lanterns = folder("PathLanterns")
local lanternIndex = 0
for index = 1, 6 do
	local s = spokes[index]
	local pairs = index <= 4 and 2 or 1
	for row = 1, pairs do
		local distance = math.min(10 + (row - 1) * 18, s.length - 4)
		local center = s.a + (s.b - s.a).Unit * distance
		for _, side in { -1, 1 } do
			local at = center + s.cf.RightVector * side * (s.width / 2 + 3)
			part(
				lanterns,
				"Post",
				Vector3.new(0.8, 12, 0.8),
				CFrame.new(at + Vector3.new(0, 6, 0)),
				"2D1F43"
			)
			part(
				lanterns,
				"Arm",
				Vector3.new(3, 0.6, 0.6),
				CFrame.new(at + Vector3.new(0, 11.7, 0)),
				"2D1F43"
			)
			local box = CFrame.new(at + Vector3.new(0, 10.1, 0))
			for _, y in { -1.5, 1.5 } do
				part(
					lanterns,
					"Frame",
					Vector3.new(2.4, 0.2, 2.4),
					box * CFrame.new(0, y, 0),
					"2D1F43"
				)
			end
			for _, x in { -1.1, 1.1 } do
				for _, z in { -1.1, 1.1 } do
					part(
						lanterns,
						"Frame",
						Vector3.new(0.2, 3, 0.2),
						box * CFrame.new(x, 0, z),
						"2D1F43"
					)
				end
			end
			local core = part(
				lanterns,
				"Core",
				Vector3.new(1.8, 2.4, 1.8),
				box,
				"FFB347",
				Enum.Material.Neon
			)
			light(core, "FFB347", 1.5, 16)
			lanternIndex += 1
		end
	end
	task.wait()
end

-- 7. Five cross-street spans, two parallel sagging rows each, 3-stud bulbs.
local strings = folder("StringLights")
local extraLights = math.max(0, 40 - lightCount)
local stringBudget = math.min(6, math.floor(extraLights / 2))
local stringUsed = 0
for index, z in { -90, -60, -30, 50, 80 } do
	for _, x in { -11, 11 } do
		part(
			strings,
			"Post",
			Vector3.new(0.8, 16, 0.8),
			CFrame.new(KC + Vector3.new(x, 8, z)),
			"2D1F43"
		)
	end
	for _, dz in { -0.5, 0.5 } do
		local last
		for k = 0, 8 do
			local x = math.min(k * 3, 22) - 11
			local t = (x + 11) / 22
			local at = KC + Vector3.new(x, 16 - 12 * t * (1 - t), z + dz)
			local bulb = part(
				strings,
				"Bulb",
				Vector3.one,
				CFrame.new(at),
				k % 2 == 0 and "FFB347" or "FFC83D",
				Enum.Material.Neon
			)
			bulb.Shape = Enum.PartType.Ball
			if (k == 2 or k == 6) and stringUsed < stringBudget then
				light(bulb, "FFB347", 0.8, 10)
				stringUsed += 1
			end
			if last then
				part(
					strings,
					"Wire",
					Vector3.new(0.08, 0.08, (at - last).Magnitude),
					CFrame.lookAt((at + last) / 2, at),
					"2D1F43"
				)
			end
			last = at
		end
	end
	task.wait()
end

-- Wall-cap fixture count: 14 per long / 9 per short, at 24-stud pitch.
-- At the north mouth omit cubes inside the 120-stud gap, never fill it with walls.
local wallDecor = folder("WallDetails")
local walls = art:FindFirstChild("Walls")
for i, p in walls and walls:GetDescendants() or {} do
	if p:IsA("BasePart") and p.Name == "Slab" and string.match(p.Parent.Name, "^LaunchWall") then
		p.Material = Enum.Material.Plastic
		p.Color = hex(p.Position.Y < 15 and "453E69" or "4E4775")
	end
	yieldChunk(i)
end
local wallIndex = 0
local function wallLamp(at)
	part(
		wallDecor,
		"Bracket",
		Vector3.new(1, 3, 1),
		CFrame.new(at + Vector3.new(0, 1.5, 0)),
		"2D1F43"
	)
	local core = part(
		wallDecor,
		"WallGlow",
		Vector3.new(3, 3, 3),
		CFrame.new(at + Vector3.new(0, 4.5, 0)),
		"FFB347",
		Enum.Material.Neon
	)
	wallIndex += 1
	if wallIndex % 2 == 0 then
		light(core, "FFB347", 1, 14)
	end
end
for k = 0, 13 do
	local x = 1344 + k * 24
	wallLamp(Vector3.new(x, 31.5, -73))
	if math.abs(x - 1500) >= 60 then
		wallLamp(Vector3.new(x, 31.5, 153))
	end
end
for _, x in { 1327, 1673 } do
	for k = 0, 8 do
		wallLamp(Vector3.new(x, 31.5, -56 + k * 24))
	end
end
local function buttress(at, side)
	part(
		wallDecor,
		"Buttress",
		Vector3.new(6, 34, 4),
		CFrame.new(at + Vector3.new(0, 17, 0)) * CFrame.Angles(0, side, 0),
		"453E69"
	)
	part(
		wallDecor,
		"CapTrim",
		Vector3.new(6, 1.5, 2),
		CFrame.new(at + Vector3.new(0, 34.75, 0)) * CFrame.Angles(0, side, 0),
		"E8E4D0"
	)
	pumpkin(wallDecor, at + Vector3.new(0, 35.5, 0), 4, false)
end
for x = 1340, 1660, 40 do
	buttress(Vector3.new(x, 0, -73), 0)
	if math.abs(x - 1500) >= 60 then
		buttress(Vector3.new(x, 0, 153), 0)
	end
end
for _, x in { 1327, 1673 } do
	for z = -60, 140, 40 do
		buttress(Vector3.new(x, 0, z), math.pi / 2)
	end
end
task.wait()

-- 9. Gate towers are decoration, allowing the full existing lane footprint.
local gate = folder("HauntedGate")
for _, x in { -40, 40 } do
	local at = KC + Vector3.new(x, 0, 110)
	part(
		gate,
		"Tower",
		Vector3.new(12, 42, 12),
		CFrame.new(at + Vector3.new(0, 21, 0)),
		"4E4775",
		Enum.Material.Plastic
	)
	for index, size in { 8, 6, 4 } do
		local y = ({ 46, 53, 56 })[index]
		part(
			gate,
			"Spire",
			Vector3.new(size, size, size),
			CFrame.new(at + Vector3.new(0, y, 0)),
			"7A52BF",
			Enum.Material.Plastic
		)
	end
	for _, y in { 16, 28 } do
		part(
			gate,
			"Window",
			Vector3.new(3, 4, 0.2),
			CFrame.new(at + Vector3.new(0, y, -6.1)),
			"FDF301",
			Enum.Material.Neon
		)
	end
end
part(gate, "ArchBeam", Vector3.new(80, 4, 4), CFrame.new(KC + Vector3.new(0, 34, 110)), "2D1F43")
local banner = part(
	gate,
	"Banner",
	Vector3.new(40, 8, 0.3),
	CFrame.new(KC + Vector3.new(0, 28, 107.8)),
	"F28C1A"
)
local gui = Instance.new("SurfaceGui")
gui.Face, gui.PixelsPerStud, gui.LightInfluence, gui.Parent = Enum.NormalId.Front, 32, 0, banner
label(gui, "PUMPKIN PATCH →", "FFFFFF")
task.wait()

-- 8/10. Reuse local KitSource art, stripped of executable code and lights.
local kit = storage:FindFirstChild("KitSource")
local function kitProp(source, name, at, scale, color)
	if not source or not source:IsA("Model") then
		return false
	end
	local n = 0
	for _, d in source:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	if n == 0 or added + n >= 1450 then
		return false
	end
	local m = source:Clone()
	m.Name = name
	m:ScaleTo(m:GetScale() * scale)
	local cf, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (at + Vector3.new(0, size.Y / 2, 0) - cf.Position))
	for i, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery = true, false, false, false
			d.TopSurface = Enum.SurfaceType.Smooth
			if color then
				d.Color = hex(color)
			end
		elseif d:IsA("LuaSourceContainer") or d:IsA("Light") then
			d:Destroy()
		end
		yieldChunk(i)
	end
	m.Parent = look
	added += n
	return true
end
local graveSource = kit and kit:FindFirstChild("gravestone")
for _, x in { -140, 140 } do
	for k = 0, 4 do
		local at = KC + Vector3.new(x + (k - 2) * 4, 0, -98)
		if not kitProp(graveSource, "Gravestone", at, 1.6, "8E8AA8") then
			part(
				look,
				"Gravestone",
				Vector3.new(3, 4, 1),
				CFrame.new(at + Vector3.new(0, 2, 0)),
				"8E8AA8"
			)
		end
	end
end
local treeSource
if kit then
	for _, name in { "tree_orange", "tree_autumn", "tree_red", "tree_dead_large" } do
		treeSource = kit:FindFirstChild(name)
		if treeSource then
			break
		end
	end
end
local reusedTrees = 0
for index, spec in
	{ { -150, -90 }, { -150, 90 }, { 150, -90 }, { 150, 90 }, { -142, 85 }, { 142, 85 } }
do
	local at = KC + Vector3.new(spec[1], 0, spec[2])
	if kitProp(treeSource, "HarvestTree" .. index, at, 1.8, nil) then
		reusedTrees += 1
		local m = look:FindFirstChild("HarvestTree" .. index)
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.Position.Y > 8 then
				d.Color = hex(index % 2 == 0 and "D35208" or "F28C1A")
			end
		end
	else
		part(
			look,
			"TreeTrunk",
			Vector3.new(3.6, 21.6, 3.6),
			CFrame.new(at + Vector3.new(0, 10.8, 0)),
			"8E5B3A",
			Enum.Material.Wood
		)
		for k = 1, 3 do
			part(
				look,
				"TreeCrown",
				Vector3.new(12, 8, 12),
				CFrame.new(at + Vector3.new((k - 2) * 4, 19 + k * 2, 0)),
				index % 2 == 0 and "D35208" or "F28C1A"
			)
		end
	end
	task.wait()
end
-- Populate the existing right-wall slab without inventing live leaderboard numbers.
for _, board in garden:GetDescendants() do
	local namedBoard = board.Name == "LifetimeBoard"
		or board.Name == "Leaderboard"
		or board.Name == "LeaderboardBoard"
	local blankRightSlab = board:IsA("BasePart")
		and board.Position.X > 1650
		and board.Position.Z < 150
		and board.Position.Z > -70
		and board.Size.X > 10
		and board.Size.Y > 6
		and board.Size.Z < 2
		and not board:IsDescendantOf(pens)
		and not (walls and board:IsDescendantOf(walls))
	if board:IsA("BasePart") and (namedBoard or blankRightSlab) then
		local previous = board:FindFirstChild("Launch2Board")
		if previous then
			previous:Destroy()
		end
		local boardGui = Instance.new("SurfaceGui")
		boardGui.Name, boardGui.Face, boardGui.PixelsPerStud, boardGui.LightInfluence =
			"Launch2Board", Enum.NormalId.Front, 32, 0
		boardGui.Parent = board
		label(
			boardGui,
			"HARVEST LEADERS\nMost pumpkins sold\nLive rankings appear in game",
			"FFC83D"
		)
	end
end
local after, lightsAfter = counts()
assert(after - before < 1500, "Part growth must stay below +1500")
assert(lightsAfter <= 40, "PointLight cap exceeded")
local report = string.format(
	"LaunchLook2: Workspace parts %d -> %d (%+d); PointLights %d -> %d/40; created %d parts; grass %d; 6 spokes, 20 path lanterns, %d wall fixtures, 5 double strings (%d string lights), 6 beds / %d pumpkins, 10 gravestones, 6 trees (%d kit). Clearance clips/relocations %d. Base* saved; Studio spawn-camera/runtime review still required.",
	before,
	after,
	after - before,
	lightsBefore,
	lightsAfter,
	added,
	floorCount,
	wallIndex,
	stringUsed,
	planted,
	reusedTrees,
	clipped
)
print(report)
return report
