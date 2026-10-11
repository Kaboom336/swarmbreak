-- Paste/run once in Studio's command bar in EDIT mode. Safe to repeat.
-- Scope: launch-plan C1/C2/C3/B11/A7 cheap lobby; no gameplay or asset uploads.
-- References: AUDIT-LOBBY-MAP sections 3/4 (SAE castle / PS99 harvest warmth).
-- IMPORTANT: current Patch.client resets PhaseTint to neutral on Day, and the
-- server restores GiantJack on King reset. This Edit script cannot change those
-- runtime behaviours without changing game scripts. Base attributes document the
-- intended preset; the current client snapshots actual Lighting properties.
assert(not game:GetService("RunService"):IsRunning(), "LaunchLook must run in Edit mode")
local lighting = game:GetService("Lighting")
local storage = game:GetService("ServerStorage")
local garden = assert(workspace:FindFirstChild("Garden"), "Missing workspace.Garden")
local art = assert(garden:FindFirstChild("Art"), "Missing Garden.Art")
local ground = assert(garden:FindFirstChild("Ground"), "Missing Garden.Ground")
local walls = assert(art:FindFirstChild("Walls"), "Missing Garden.Art.Walls")
local market = assert(garden:FindFirstChild("Market"), "Missing Garden.Market")
local patches = assert(garden:FindFirstChild("Patches"), "Missing Garden.Patches")
local zones = assert(garden:FindFirstChild("Zones"), "Missing Garden.Zones")
local hex = Color3.fromHex
local KC = Vector3.new(1500, 0, 40)
local function pause(i)
	if i % 150 == 0 then
		task.wait()
	end
end
local function countParts(root)
	local n = 0
	for i, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
		pause(i)
	end
	return n
end
local before = countParts(garden)
local wallBefore = countParts(walls)
local removed = { effects = 0, bricks = 0, centre = 0, lights = 0 }
local old = art:FindFirstChild("LaunchLook")
if old then
	-- Yield during teardown too: the King and kit may contain hundreds of voxels.
	for i, d in old:GetDescendants() do
		if d:IsA("BasePart") then
			d:Destroy()
		end
		pause(i)
	end
	old:Destroy()
end
local look = Instance.new("Folder")
look.Name = "LaunchLook"
look.Parent = art
local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or look
	return f
end
local function part(parent, name, size, cf, color, material, solid)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = hex(color), material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = solid == true
	p.CanTouch = false
	p.CanQuery = solid == true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function paint(p, color, material)
	p.Color = hex(color)
	p.Material = material or Enum.Material.SmoothPlastic
end

-- ONE grade, named PhaseTint so the client reuses it rather than stacking another.
for i, d in lighting:GetDescendants() do
	if
		d:IsA("ColorCorrectionEffect")
		or d:IsA("BloomEffect")
		or d:IsA("SunRaysEffect")
		or d:IsA("Atmosphere")
	then
		d:Destroy()
		removed.effects += 1
	end
	pause(i)
end
local baseLighting = {
	ClockTime = 15.6,
	Brightness = 2.4,
	ExposureCompensation = 0,
	GlobalShadows = true,
	ShadowSoftness = 0.2,
	Ambient = hex("8C7AA8"),
	OutdoorAmbient = hex("9D8DBF"),
	ColorShift_Top = hex("FFD9A8"),
	ColorShift_Bottom = Color3.new(),
	EnvironmentDiffuseScale = 0.4,
	EnvironmentSpecularScale = 0.3,
}
for key, value in baseLighting do
	lighting[key] = value
	lighting:SetAttribute("Base" .. key, value)
end
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "PhaseTint"
for key, value in
	{ Brightness = 0.02, Contrast = 0.12, Saturation = 0.15, TintColor = hex("FFF1E6") }
do
	cc[key] = value
	cc:SetAttribute("Base" .. key, value)
	lighting:SetAttribute("Base" .. key, value)
end
-- BaseBrightness on Lighting means sun brightness, not the grade's brightness.
lighting:SetAttribute("BaseBrightness", baseLighting.Brightness)
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
bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "HarvestBloom", 0.8, 28, 0.95
bloom.Parent = lighting
local rays = Instance.new("SunRaysEffect")
rays.Name, rays.Intensity, rays.Spread = "HarvestSun", 0.06, 0.6
rays.Parent = lighting
task.wait()

-- Zone pairs intentionally drawn from the audit palette; only Meadow uses gold grass.
local palette = {
	{ "A6CF4A", "8E5B3A" }, -- Meadow / barn wood
	{ "A9ABD3", "453E69" }, -- Graveyard / bone cap
	{ "64B53A", "2D1F43" }, -- Haunted Woods / aubergine
	{ "8A86B8", "7A52BF" }, -- Witch Swamp / magic purple
	{ "B8BADD", "4E4775" }, -- Castle / slate
	{ "E7C8E8", "B07ACF" }, -- Candy / peach lilac
	{ "F28C1A", "D35208" }, -- King / harvest orange
}
-- Prefer live Spawn footprints for lane extents; config's 160-stud strips are fallback.
local ranges = {}
for n = 1, 7 do
	local zone = zones:FindFirstChild("Zone" .. n)
	local lo, hi = math.huge, -math.huge
	for i, d in zone and zone:GetDescendants() or {} do
		if d:IsA("BasePart") and d.Name == "Spawn" then
			local half = (
				math.abs(d.CFrame.RightVector.Z) * d.Size.X
				+ math.abs(d.CFrame.UpVector.Z) * d.Size.Y
				+ math.abs(d.CFrame.LookVector.Z) * d.Size.Z
			) / 2
			lo, hi = math.min(lo, d.Position.Z - half), math.max(hi, d.Position.Z + half)
			paint(d, palette[n][1], Enum.Material.Plastic)
		end
		pause(i)
	end
	if lo == math.huge then
		lo, hi = 150 + (n - 1) * 160, 150 + n * 160
	end
	ranges[n] = { lo, hi }
	-- Gate geometry and names remain intact.
	local gate = zone and zone:FindFirstChild("GateWall")
	if gate and gate:IsA("BasePart") then
		paint(gate, palette[n][2])
	end
end
local function zoneAt(z)
	for n, r in ranges do
		if z >= r[1] and z < r[2] then
			return n
		end
	end
	-- Spawn grids can be inset from their zone boundaries.
	if z >= 150 and z < 1270 then
		return math.clamp(math.floor((z - 150) / 160) + 1, 1, 7)
	end
	return nil
end
for i, d in ground:GetDescendants() do
	if d:IsA("BasePart") then
		local n = zoneAt(d.Position.Z)
		if n then
			paint(d, palette[n][1], Enum.Material.Plastic)
		elseif
			d.Position.X >= 1320
			and d.Position.X <= 1680
			and d.Position.Z >= -80
			and d.Position.Z < 150
		then
			local parity = (math.floor(d.Position.X / 8) + math.floor(d.Position.Z / 8)) % 2
			paint(d, parity == 0 and "6BBF3F" or "64B53A", Enum.Material.Plastic)
			d.TopSurface = Enum.SurfaceType.Studs
		end
	end
	pause(i)
end
local paths = art:FindFirstChild("Paths")
for i, d in paths and paths:GetDescendants() or {} do
	if d:IsA("BasePart") then
		paint(d, d.Name == "PathEdge" and "E8E4D0" or "B8BADD")
	end
	pause(i)
end
for i, d in patches:GetDescendants() do
	if d:IsA("BasePart") then
		if d.Name == "Soil" then
			paint(d, "7A4E33", Enum.Material.Ground)
			d.TopSurface = Enum.SurfaceType.Smooth
		elseif d.Name == "Rail" or d.Name == "Brace" then
			paint(d, "9A5B2E", Enum.Material.Wood)
		elseif d.Name == "Post" or d.Name == "Pole" or d.Name == "Board" then
			paint(d, "2D1F43")
		elseif d.Name == "Bar" then
			paint(d, "F28C1A")
		end
	end
	pause(i)
end
local furrows = folder("PenFurrows")
for _, pen in patches:GetChildren() do
	local soil = pen:FindFirstChild("Soil")
	if soil and soil:IsA("BasePart") then
		for _, x in { -0.3, 0, 0.3 } do
			part(
				furrows,
				"Furrow",
				Vector3.new(0.3, 0.05, soil.Size.Z - 2),
				soil.CFrame * CFrame.new(soil.Size.X * x, soil.Size.Y / 2 + 0.025, 0),
				"5E3A26"
			)
		end
	end
	task.wait()
end

-- Merge only named hub bricks, computing EXACT bounds per side from live parts.
-- Five sides preserves the 120-stud lane mouth; existing caps retain their footprint.
local groups = {}
local function side(p)
	local v = p.Position
	if v.Z < -65 then
		return "South"
	end
	if v.X < 1333 then
		return "West"
	end
	if v.X > 1667 then
		return "East"
	end
	if v.Z > 148 then
		return v.X < 1500 and "NorthWest" or "NorthEast"
	end
	return nil
end
for i, d in walls:GetDescendants() do
	if d:IsA("BasePart") then
		local v = d.Position
		local hub = v.X >= 1320 and v.X <= 1680 and v.Z >= -80 and v.Z <= 156
		local s = hub and side(d)
		if s and d.Name == "Brick" then
			local g = groups[s]
			if not g then
				g = {
					lo = Vector3.new(math.huge, math.huge, math.huge),
					hi = Vector3.new(-math.huge, -math.huge, -math.huge),
					parts = {},
				}
				groups[s] = g
			end
			local a, b = v - d.Size / 2, v + d.Size / 2
			g.lo = Vector3.new(math.min(g.lo.X, a.X), math.min(g.lo.Y, a.Y), math.min(g.lo.Z, a.Z))
			g.hi = Vector3.new(math.max(g.hi.X, b.X), math.max(g.hi.Y, b.Y), math.max(g.hi.Z, b.Z))
			table.insert(g.parts, d)
		elseif s and d.Name == "Cap" then
			paint(d, "E8E4D0")
		elseif s and d.Name == "Slab" and string.match(d.Parent.Name, "^LaunchWall") then
			-- Already merged on a prior run: north slabs must stay hub purple,
			-- even though their centres sit just beyond the safe-line Z=150.
			paint(d, d.Position.Y < 15 and "453E69" or "4E4775", Enum.Material.Brick)
		else
			local n = zoneAt(v.Z)
			if n then
				paint(
					d,
					d.Name == "Cap" and "E8E4D0" or palette[n][2],
					d.Name == "Cap" and Enum.Material.SmoothPlastic or Enum.Material.Brick
				)
			end
		end
	end
	pause(i)
end
-- Replacement slabs live in Walls (not the rebuildable decoration folder).
for _, s in { "South", "West", "East", "NorthWest", "NorthEast" } do
	local g = groups[s]
	if g then
		local previous = walls:FindFirstChild("LaunchWall" .. s)
		if previous then
			previous:Destroy()
		end
		local f = folder("LaunchWall" .. s, walls)
		local size, mid = g.hi - g.lo, (g.lo + g.hi) / 2
		for band = 0, 1 do
			part(
				f,
				"Slab",
				Vector3.new(size.X, size.Y / 2, size.Z),
				CFrame.new(mid + Vector3.new(0, (band - 0.5) * size.Y / 2, 0)),
				band == 0 and "453E69" or "4E4775",
				Enum.Material.Brick,
				true
			)
		end
		for i, p in g.parts do
			p:Destroy()
			removed.bricks += 1
			pause(i)
		end
	end
	task.wait()
end

-- Thirty wall lanterns, ~24-30 studs apart. All lights have no shadow cost.
local lanterns = folder("WallLanterns")
local lampPositions = {}
for _, x in { 1327, 1673 } do
	for k = 0, 7 do
		table.insert(lampPositions, Vector3.new(x, 31.5, -55 + k * 27))
	end
end
for k = 0, 9 do
	table.insert(lampPositions, Vector3.new(1365 + k * 30, 31.5, -73))
end
for _, x in { 1380, 1420, 1580, 1620 } do
	table.insert(lampPositions, Vector3.new(x, 31.5, 153))
end
for i, at in lampPositions do
	part(
		lanterns,
		"Post",
		Vector3.new(0.65, 2, 0.65),
		CFrame.new(at + Vector3.new(0, 1, 0)),
		"2D1F43"
	)
	local glass = part(
		lanterns,
		"WarmGlass",
		Vector3.new(1.5, 1.5, 1.5),
		CFrame.new(at + Vector3.new(0, 2.5, 0)),
		"FFB347",
		Enum.Material.Neon
	)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = hex("FFB347"), 12, 1, false
	light.Parent = glass
	if i % 5 == 0 then
		task.wait()
	end
end
local strings = folder("StringLights")
for _, x in { 1492, 1508 } do
	for _, z in { 78, 112, 146 } do
		part(strings, "Post", Vector3.new(0.5, 15, 0.5), CFrame.new(x, 7.5, z), "2D1F43")
	end
	for span = 0, 1 do
		local last
		for k = 0, 12 do
			local t = k / 12
			local at = Vector3.new(x, 15 - 2 * math.sin(t * math.pi), 78 + span * 34 + t * 34)
			local bulb = part(
				strings,
				"Bulb",
				Vector3.new(0.8, 0.8, 0.8),
				CFrame.new(at),
				({ "FFB347", "7A52BF", "E8E4D0" })[k % 3 + 1],
				Enum.Material.Neon
			)
			bulb.Shape = Enum.PartType.Ball
			if last then
				part(
					strings,
					"Rope",
					Vector3.new(0.09, 0.09, (at - last).Magnitude),
					CFrame.lookAt((at + last) / 2, at),
					"2D1F43"
				)
			end
			last = at
		end
		task.wait()
	end
end

-- Reuse existing kit only; no new dependencies. Fallbacks keep all 30 placements.
local props = folder("WallProps")
local kit = storage:FindFirstChild("KitSource")
local propCount = 0
local function prop(name, at, height, yaw)
	local source = kit and kit:FindFirstChild(name)
	local m
	if source and source:IsA("Model") and source:FindFirstChildWhichIsA("BasePart", true) then
		m = source:Clone()
		local _, size = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * height / math.max(size.Y, 0.01))
		m:PivotTo(CFrame.new(at) * CFrame.Angles(0, yaw, 0))
		local cf, sz = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + (at + Vector3.new(0, sz.Y / 2, 0) - cf.Position))
	else
		m = Instance.new("Model")
		local hay = name == "haybale"
		local p = part(
			m,
			"Prop",
			hay and Vector3.new(5, height, 3) or Vector3.new(height, height, height),
			CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, yaw, 0),
			hay and "E3B04B" or (name == "gravestone" and "A9ABD3" or "F28C1A"),
			hay and Enum.Material.Fabric or Enum.Material.SmoothPlastic
		)
		if string.find(name, "pumpkin") then
			p.Shape = Enum.PartType.Ball
		elseif name == "post_lantern" then
			p.Size = Vector3.new(0.6, height - 1.5, 0.6)
			p.Position = at + Vector3.new(0, (height - 1.5) / 2, 0)
			paint(p, "2D1F43")
			part(
				m,
				"Glass",
				Vector3.new(1.5, 1.5, 1.5),
				CFrame.new(at + Vector3.new(0, height - 0.75, 0)),
				"FFB347",
				Enum.Material.Neon
			)
		end
	end
	m.Name = string.format("Prop%02d_%s", propCount + 1, name)
	for i, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			if name == "haybale" then
				paint(d, "E3B04B", Enum.Material.Fabric)
			end
		elseif d:IsA("LuaSourceContainer") or d:IsA("Light") then
			d:Destroy()
		end
		pause(i)
	end
	m.Parent = props
	propCount += 1
end
for index, v in
	{ { 1340, -63 }, { 1660, -63 }, { 1340, 135 }, { 1660, 135 }, { 1340, 65 }, { 1660, 65 } }
do
	local at = Vector3.new(v[1], 0, v[2])
	for k = 0, 2 do
		prop(
			k == 1 and "pumpkin_yellow" or "pumpkin_orange",
			at + Vector3.new((k - 1) * 3, 0, k % 2 * 2),
			2.5 + k * 0.6,
			index * 0.4
		)
	end
	prop("haybale", at + Vector3.new(0, 0, -4), 3, 0)
	prop(
		index % 2 == 0 and "gravestone" or "post_lantern",
		at + Vector3.new(0, 0, 5),
		index % 2 == 0 and 4 or 7,
		0
	)
	task.wait()
end

-- Keep every contract instance. Remove only explicitly named, unreferenced decor.
local centre = art:FindFirstChild("Centre")
for i, d in centre and centre:GetChildren() or {} do
	if
		d:IsA("BasePart")
		and (d.Position - KC).Magnitude < 50
		and (d.Name == "SwirlPool" or string.match(d.Name, "^Tier%d+$"))
	then
		d:Destroy()
		removed.centre += 1
	end
	pause(i)
end
local plinth = market:FindFirstChild("Plinth")
if plinth and plinth:IsA("BasePart") then
	-- Cylinder's local X is its height; force a stable four-stud lavender dais.
	if plinth:IsA("Part") and plinth.Shape == Enum.PartType.Cylinder then
		plinth.Size = Vector3.new(4, 24, 24)
		plinth.CFrame = CFrame.new(KC + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	else
		plinth.Size = Vector3.new(24, 4, 24)
		plinth.CFrame = CFrame.new(KC + Vector3.new(0, 2, 0))
	end
	paint(plinth, "B8BADD")
end
local plaza = market:FindFirstChild("Plaza")
if plaza and plaza:IsA("BasePart") then
	paint(plaza, "A9ABD3")
end
local guards = storage:FindFirstChild("GuardModels")
local kingSource = guards and guards:FindFirstChild("PumpkinKing")
local kingStatus = "PumpkinKing missing; kept legacy silhouette"
if
	kingSource
	and kingSource:IsA("Model")
	and kingSource:FindFirstChildWhichIsA("BasePart", true)
then
	local king = kingSource:Clone()
	king.Name = "ThroneKing"
	local _, size = king:GetBoundingBox()
	king:ScaleTo(king:GetScale() * 15 / math.max(size.Y, 0.01)) -- ~3 x 5-stud avatar
	local spawn = garden:FindFirstChild("SpawnLocation")
	local target = spawn and spawn.Position or Vector3.new(1500, 0, 130)
	local facing = CFrame.lookAt(KC, Vector3.new(target.X, 0, target.Z))
	-- VoxelModels authors the FACE toward local +Z, unlike CFrame's -Z forward.
	king:PivotTo(facing * CFrame.Angles(0, math.pi, 0))
	local cf, sz = king:GetBoundingBox()
	king:PivotTo(king:GetPivot() + (KC + Vector3.new(0, 4 + sz.Y / 2, 0) - cf.Position))
	for i, d in king:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
		elseif d:IsA("LuaSourceContainer") or d:IsA("Light") then
			d:Destroy()
		end
		pause(i)
	end
	king.Parent = look
	for _, name in { "GiantJack", "KingFace", "KingGlow" } do
		local p = market:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Transparency = 1
			p.CanCollide = false
			p.CFrame = CFrame.new(KC + Vector3.new(0, 4 + p.Size.Y / 2, 0))
				* (p.CFrame - p.Position)
			for _, d in p:GetDescendants() do
				if d:IsA("Light") or d:IsA("ParticleEmitter") then
					d.Enabled = false
				end
			end
		end
	end
	kingStatus = "ThroneKing 15 studs, plinth top 4; legacy King parts hidden (preserved)"
end
local meter = market:FindFirstChild("MeterRing")
if meter and meter:IsA("BasePart") then
	paint(meter, "FFB347", Enum.Material.Neon)
	meter.CFrame = CFrame.new(KC + Vector3.new(0, 4.05, 0)) * (meter.CFrame - meter.Position)
end
local sign = market:FindFirstChild("SignJack")
if sign and sign:IsA("BasePart") then
	sign.Position = KC + Vector3.new(0, 22, 0)
	for _, d in sign:GetDescendants() do
		if d:IsA("TextLabel") then
			d.Text = "PUMPKIN KING"
			d.TextColor3 = hex("F28C1A")
		end
	end
end
task.wait()

-- Cap actual PointLight INSTANCE count across Garden at 40, reserving all 30 wall lights.
-- Preserve up to ten old lights deterministically; strings rely on Neon + Bloom.
local existing = {}
local billboards = 0
for i, d in garden:GetDescendants() do
	if d:IsA("PointLight") and not d:IsDescendantOf(lanterns) then
		table.insert(existing, d)
	elseif d:IsA("BillboardGui") then
		if d.Name == "OwnerSign" and d:IsDescendantOf(patches) then
			d.MaxDistance = 100
		elseif d.MaxDistance > 150 then
			d.MaxDistance = 60
			billboards += 1
		end
	end
	pause(i)
end
table.sort(existing, function(a, b)
	return a:GetFullName() < b:GetFullName()
end)
for i, d in existing do
	if i > 10 then
		d:Destroy()
		removed.lights += 1
	else
		d.Shadows = false
	end
	pause(i)
end
local after, wallAfter = countParts(garden), countParts(walls)
local report = string.format(
	"LaunchLook: Garden parts %d -> %d; wall parts %d -> %d; removed %d bricks, %d centre decor, %d effects, %d excess PointLights; 30 wall lanterns, 2 strings, %d props; PointLights %d/40; billboards shortened %d. %s. Client Day neutralises grade; server King reset restores GiantJack.",
	before,
	after,
	wallBefore,
	wallAfter,
	removed.bricks,
	removed.centre,
	removed.effects,
	removed.lights,
	propCount,
	30 + math.min(#existing, 10),
	billboards,
	kingStatus
)
print(report)
return report
