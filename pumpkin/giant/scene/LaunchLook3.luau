-- Studio EDIT, after LaunchLook and LaunchLook2. No network / external assets.
-- LOOK-CRITIC-2 exact corrections; AUDIT-LOBBY-MAP section 4 harvest palette.
-- Reuses the project's VoxelModels PumpkinKing and v2 props; no new dependencies.
-- TE t_0494 is the readability bar; SAE h_0018 is the harvest-hub comparison.
-- Only scene-owned decoration is removed. All Market/Patches/Zones contracts survive.
-- Patch.client currently snapshots properties, reads NO Base* attributes, and clears
-- PhaseTint on Day. Attributes below prepare restoration; they cannot fix that code.
-- Patch.server's GiantJack reset is explicitly outside this batch. No reset override.
assert(not game:GetService("RunService"):IsRunning(), "LaunchLook3 requires Edit mode")
local lighting = game:GetService("Lighting")
local garden = assert(workspace:FindFirstChild("Garden"), "Missing Garden")
local art = assert(garden:FindFirstChild("Art"), "Missing Garden.Art")
local market = assert(garden:FindFirstChild("Market"), "Missing Garden.Market")
local v1 = assert(art:FindFirstChild("LaunchLook"), "Run LaunchLook first")
local v2 = assert(art:FindFirstChild("LaunchLook2"), "Run LaunchLook2 first")
local king = assert(v1:FindFirstChild("ThroneKing"), "Missing ThroneKing")
assert(king:IsA("Model"), "ThroneKing must be a Model")
local details = assert(v2:FindFirstChild("ThroneDetails"), "Missing ThroneDetails")
local throne = assert(v2:FindFirstChild("Throne"), "Missing Throne")
local lanterns = assert(v2:FindFirstChild("PathLanterns"), "Missing PathLanterns")
local strings = assert(v2:FindFirstChild("StringLights"), "Missing StringLights")
local KC = Vector3.new(1500, 0, 40)
local hex = Color3.fromHex
local function chunk(i)
	if i % 80 == 0 then
		task.wait()
	end
end
local function counts()
	local parts, lights = 0, 0
	for i, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("PointLight") then
			lights += 1
		end
		chunk(i)
	end
	return parts, lights
end
local before, lightsBefore = counts()
-- This root contains only this file's additions, never game anchors or prompts.
local previous = art:FindFirstChild("LaunchLook3")
if previous then
	for i, d in previous:GetDescendants() do
		if d:IsA("BasePart") then
			d:Destroy()
		end
		chunk(i)
	end
	previous:Destroy()
end
local look = Instance.new("Folder")
look.Name, look.Parent = "LaunchLook3", art
look:SetAttribute("Reference", "LOOK-CRITIC-2; Pumpkin Patch at Golden Hour; TE / SAE")
local created = 0
local function part(name, size, cf, color, material, parent, class)
	assert(created < 1499, "LaunchLook3 creation budget exceeded")
	local p = Instance.new(class or "Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = hex(color), material or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent or look
	created += 1
	chunk(created)
	return p
end
local function hide(p)
	p.Transparency, p.CanCollide, p.CastShadow = 1, false, false
end
-- 1 / 4. One King: keep only the title from the entire replacement head kit.
for i, d in details:GetDescendants() do
	if d:IsA("BasePart") and d.Name ~= "KingTitle" then
		hide(d)
	elseif d:IsA("Light") then
		-- Owned v2 decoration, not Market.GiantJack's game-referenced light.
		d:Destroy()
	end
	chunk(i)
end
-- V2 already rotated voxel geometry once (Launch2ForwardFixed). Do not repeat it.
-- If that flag is absent, authored +Z geometry needs one local half-turn so a
-- lookAt pivot's -Z forward points the face toward world +Z / the spawn at +90Z.
if not king:GetAttribute("Launch2ForwardFixed") then
	local pivot = king:GetPivot()
	for i, d in king:GetDescendants() do
		if d:IsA("BasePart") and d ~= king.PrimaryPart then
			d.CFrame = pivot * CFrame.Angles(0, math.pi, 0) * pivot:ToObjectSpace(d.CFrame)
		end
		chunk(i)
	end
	king:SetAttribute("Launch2ForwardFixed", true)
end
king:ScaleTo(1.4) -- Absolute model scale, exactly as critic requests; never compounded.
local pos = KC + Vector3.new(0, 4.65, 0)
king:PivotTo(CFrame.lookAt(pos, Vector3.new(1500, pos.Y, 130)))
local box, size = king:GetBoundingBox()
king:PivotTo(king:GetPivot() + (KC + Vector3.new(0, 4.65 + size.Y / 2, 0) - box.Position))
local palette = {
	o = "F28C1A",
	d = "D35208",
	f = "FFB347",
	k = "2D1F43",
	y = "FFC83D",
	j = "7A52BF",
	p = "7A52BF",
	c = "D35208",
	w = "E8E4D0",
	v = "4E7A2A",
	g = "4E7A2A",
	n = "2D1F43",
}
local faceCount, darkCount = 0, 0
local headParts = {}
for i, d in king:GetDescendants() do
	if d:IsA("BasePart") then
		d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery = true, false, false, false
		d.TopSurface, d.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if palette[d.Name] then
			d.Transparency, d.CastShadow = 0, true
			d.Color = hex(palette[d.Name])
			d.Material = d.Name == "f" and Enum.Material.Neon or Enum.Material.Plastic
			if d.Name == "y" then
				d.Material = Enum.Material.Metal
			elseif d.Name == "f" then
				faceCount += 1
			elseif d.Name == "k" then
				darkCount += 1
			end
			if d.Name == "o" or d.Name == "d" then
				table.insert(headParts, d)
			end
		elseif d == king.PrimaryPart or d.Name == "Root" then
			hide(d)
		end
	end
	chunk(i)
end
assert(#headParts > 0, "Missing orange King head voxels")
-- Flush against the actual voxel back, rather than floating behind the old sphere.
local headLow, headHigh = math.huge, -math.huge
for _, p in headParts do
	headLow = math.min(headLow, p.Position.Y - p.Size.Y / 2)
	headHigh = math.max(headHigh, p.Position.Y + p.Size.Y / 2)
end
local headY = (headLow + headHigh) / 2
for _, dx in { -9, -3, 3, 9 } do
	local x, back = KC.X + dx, math.huge
	for _, p in headParts do
		if math.abs(p.Position.X - x) <= p.Size.X / 2 + 0.5 then
			back = math.min(back, p.Position.Z - p.Size.Z / 2)
		end
	end
	assert(back < math.huge, "No head surface under back rib")
	part("KingBackRib", Vector3.new(1, 18, 0.6), CFrame.new(x, headY, back - 0.3), "D35208")
end
local glow = part("KingHeadGlow", Vector3.one, CFrame.new(KC + Vector3.new(0, 38, 4)), "FF9A3C")
hide(glow)
local title = assert(details:FindFirstChild("KingTitle"), "Missing KingTitle")
local kingBox, kingSize = king:GetBoundingBox()
local kingTop = kingBox.Position.Y + kingSize.Y / 2
title.Position = KC + Vector3.new(0, kingTop + 9, 0)
hide(title)
local titleGui = assert(title:FindFirstChildWhichIsA("BillboardGui"), "Missing King title GUI")
titleGui.Size, titleGui.LightInfluence, titleGui.MaxDistance = UDim2.fromScale(34, 8), 0, 400
titleGui.StudsOffsetWorldSpace, titleGui.Enabled = Vector3.zero, true
assert(title.Position.Y - 4 - kingTop >= 4, "Crown must clear title by four studs")
task.wait()

-- 2. Preserve legacy anchors; hidden initial art, never change endBloodMoon.
for _, name in { "GiantJack", "KingFace", "KingGlow", "Plinth", "MeterRing" } do
	local p = market:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		hide(p)
		for _, d in p:GetDescendants() do
			if d:IsA("Light") or d:IsA("ParticleEmitter") then
				d.Enabled = false
			end
		end
	end
end
local sign = market:FindFirstChild("SignJack")
if sign then
	if sign:IsA("BillboardGui") then
		sign.Enabled = false
	end
	for _, d in sign:GetDescendants() do
		if d:IsA("BillboardGui") then
			d.Enabled = false
		end
	end
end
-- A scene-owned visual adapter lets the live boss replace the statue. It does
-- not alter event logic, GiantJack, combat anchors, or any existing script.
local visualSwitch = Instance.new("Script")
visualSwitch.Name = "KingStatueVisibility"
visualSwitch.Source = [=[
local garden = workspace:WaitForChild("Garden")
local art = garden:WaitForChild("Art")
local king = art:WaitForChild("LaunchLook"):WaitForChild("ThroneKing")
local face = garden:WaitForChild("Market"):WaitForChild("KingFace")
local look = script.Parent
local title = art:WaitForChild("LaunchLook2"):WaitForChild("ThroneDetails"):WaitForChild("KingTitle")
local originals = {}
for _, root in { king, look, title } do
    for _, d in root:GetDescendants() do
        if d:IsA("BasePart") or d:IsA("Light") or d:IsA("BillboardGui") then
            if root ~= look or d.Name == "KingBackRib" or d.Name == "KingHeadGlow"
                or (d:IsA("Light") and d.Parent.Name == "KingHeadGlow") then
                originals[d] = d:IsA("BasePart") and d.Transparency or d.Enabled
            end
        end
    end
end
local function refresh()
    local visible = face.Transparency >= 1
    for d, original in originals do
        if d.Parent then
            if d:IsA("BasePart") then
                d.Transparency = visible and original or 1
                d.CastShadow = visible and original < 1
            else
                d.Enabled = visible and original
            end
        end
    end
end
face:GetPropertyChangedSignal("Transparency"):Connect(refresh)
refresh()
]=]
visualSwitch.Parent = look
task.wait()

-- 3. Lilac moon off-axis, facing spawn, no white halo behind the King.
local moon = assert(v2:FindFirstChild("DaytimeMoon"), "Missing DaytimeMoon")
local moonPos = Vector3.new(1330, 150, -390)
moon.Size, moon.Shape = Vector3.new(0.2, 130, 130), Enum.PartType.Cylinder
moon.CFrame = CFrame.lookAt(moonPos, Vector3.new(1500, 10, 130)) * CFrame.Angles(0, math.rad(90), 0)
moon.Color, moon.Material, moon.Transparency = hex("D9C8F0"), Enum.Material.Neon, 0.45
moon.CanCollide, moon.CastShadow = false, false

-- 5. Exact critic overrides plus the retained section-4 lighting settings.
for key, value in
	{
		ClockTime = 17.2,
		GeographicLatitude = 35,
		ColorShift_Top = hex("FFB86B"),
		Brightness = 2.4,
		Ambient = hex("8C7AA8"),
		OutdoorAmbient = hex("9D8DBF"),
		ColorShift_Bottom = hex("6B4E8C"),
		ExposureCompensation = 0,
		GlobalShadows = true,
		ShadowSoftness = 0.2,
		EnvironmentDiffuseScale = 0.4,
		EnvironmentSpecularScale = 0.3,
	}
do
	lighting[key] = value
	lighting:SetAttribute("Base" .. key, value)
end
local cc = assert(lighting:FindFirstChild("PhaseTint"), "Missing v2 PhaseTint")
for key, value in
	{ TintColor = hex("FFE6CC"), Saturation = 0.12, Brightness = 0.02, Contrast = 0.12 }
do
	cc[key] = value
	cc:SetAttribute("Base" .. key, value)
	lighting:SetAttribute("BaseGrade" .. key, value)
	if key ~= "Brightness" then
		lighting:SetAttribute("Base" .. key, value)
	end
end
local atmosphere = assert(lighting:FindFirstChildOfClass("Atmosphere"), "Missing v2 Atmosphere")
for key, value in
	{
		Density = 0.34,
		Offset = 0.1,
		Color = hex("F4C9A8"),
		Decay = hex("9A6FC4"),
		Glare = 0.4,
		Haze = 2.0,
	}
do
	atmosphere[key] = value
	atmosphere:SetAttribute("Base" .. key, value)
	lighting:SetAttribute("BaseAtmosphere" .. key, value)
end
for _, sky in lighting:GetChildren() do
	if sky:IsA("Sky") then
		sky.SunAngularSize, sky.CelestialBodiesShown = 18, true
		sky:SetAttribute("BaseSunAngularSize", 18)
		sky:SetAttribute("BaseCelestialBodiesShown", true)
		lighting:SetAttribute("BaseSunAngularSize", 18)
		lighting:SetAttribute("BaseCelestialBodiesShown", true)
	end
end
task.wait()

-- 6. Translate whole fixtures together, using each core's stable v2 position.
local movedLanterns = 0
local lanternParts = lanterns:GetChildren()
for i, core in lanternParts do
	if core:IsA("BasePart") and core.Name == "Core" then
		local at = core:GetAttribute("Launch3OriginalPosition") or core.Position
		core:SetAttribute("Launch3OriginalPosition", at)
		local flat = Vector3.new(at.X - KC.X, 0, at.Z - KC.Z)
		local target = at
		-- Include the fixture's half-width; all its pieces remain beyond radius 46.
		if flat.Magnitude < 48 then
			target = KC + flat.Unit * 48 + Vector3.new(0, at.Y, 0)
			movedLanterns += 1
		end
		local delta = target - core.Position
		for _, p in lanternParts do
			if p:IsA("BasePart") and (p == core or (p.Position - core.Position).Magnitude < 5) then
				-- Save membership before moving the core last.
				if p ~= core then
					p.CFrame += delta
				end
			end
		end
		core.CFrame += delta
		core.Size, core.Color, core.Material =
			Vector3.new(1.8, 2.4, 1.8), hex("FFB347"), Enum.Material.Neon
		for _, l in core:GetChildren() do
			if l:IsA("PointLight") then
				l.Color, l.Shadows = hex("FFB347"), false
			end
		end
		for _, dy in { -1.4, 1.4 } do
			part(
				"LanternCapBase",
				Vector3.new(2.8, 0.4, 2.8),
				core.CFrame * CFrame.new(0, dy, 0),
				"2D1F43"
			)
		end
	end
	chunk(i)
end
-- V2 strings are decoration only. Rebuild each span to keep wires attached and
-- preserve exact 3-stud spacing / 3-stud sag, not just shrink detached bulbs.
for i, d in strings:GetChildren() do
	d:Destroy()
	chunk(i)
end
for _, z in { -90, -60, -48, 50, 80 } do
	for _, x in { -11, 11 } do
		part(
			"Post",
			Vector3.new(0.8, 16, 0.8),
			CFrame.new(KC + Vector3.new(x, 8, z)),
			"2D1F43",
			nil,
			strings
		)
	end
	for _, dz in { -0.5, 0.5 } do
		local last
		-- 22-wide wire between the posts; bulbs at -9..9 have pitch exactly 3.
		local points = { -11, -9, -6, -3, 0, 3, 6, 9, 11 }
		for k, x in points do
			local t = (x + 11) / 22
			local at = KC + Vector3.new(x, 16 - 12 * t * (1 - t), z + dz)
			if k > 1 and k < #points then
				local bulb = part(
					"Bulb",
					Vector3.new(0.7, 0.7, 0.7),
					CFrame.new(at),
					({ "FFB347", "FF8A3D", "C79BFF" })[(k - 2) % 3 + 1],
					Enum.Material.Neon,
					strings
				)
				bulb.Shape = Enum.PartType.Ball
			end
			if last then
				part(
					"Wire",
					Vector3.new(0.08, 0.08, (at - last).Magnitude),
					CFrame.lookAt((at + last) / 2, at),
					"2D1F43",
					nil,
					strings
				)
			end
			last = at
		end
	end
	task.wait()
end

-- 7. Reuse v2 positions and bodies; primitive option avoids uninspected kit imports.
-- Store original size/centre on the surviving body, so reruns never shrink/float it.
local pumpkins, bales = {}, {}
for i, p in v2:GetDescendants() do
	if p:IsA("BasePart") then
		if p.Name == "Pumpkin" then
			table.insert(pumpkins, p)
		elseif p.Name == "HayBale" then
			table.insert(bales, p)
		elseif p.Name == "Shade" or p.Name == "Leaf" or p.Name == "Stem" or p.Name == "HayBand" then
			hide(p)
		end
	end
	chunk(i)
end
for i, p in pumpkins do
	local diameter = p:GetAttribute("Launch3Diameter") or p.Size.X
	local original = p:GetAttribute("Launch3PumpkinPosition") or p.Position
	p:SetAttribute("Launch3Diameter", diameter)
	p:SetAttribute("Launch3PumpkinPosition", original)
	local groundY = original.Y - diameter * 0.4
	p.Position = Vector3.new(original.X, groundY + 0.36 * diameter, original.Z)
	p.Shape, p.Size = Enum.PartType.Block, Vector3.one
	p.Color, p.Material, p.Transparency = hex("F28C1A"), Enum.Material.SmoothPlastic, 0
	local mesh = p:FindFirstChild("Launch3PumpkinMesh")
	if not mesh then
		mesh = Instance.new("SpecialMesh")
		mesh.Name, mesh.Parent = "Launch3PumpkinMesh", p
	end
	mesh.MeshType, mesh.Scale = Enum.MeshType.Sphere, Vector3.new(1, 0.72, 1) * diameter
	-- Thin spherical meridian strips follow the whole surface, including the poles;
	-- unlike rectangular ribs, there is no detached strip hovering at the shoulder.
	for k = 0, 5 do
		local rib = part(
			"PumpkinRib",
			Vector3.one,
			p.CFrame * CFrame.Angles(0, k * math.pi / 6, 0),
			"D35208"
		)
		local ribMesh = Instance.new("SpecialMesh")
		ribMesh.MeshType = Enum.MeshType.Sphere
		ribMesh.Scale, ribMesh.Parent =
			Vector3.new(0.4, diameter * 0.72 + 0.02, diameter + 0.02), rib
	end
	local stem = part(
		"PumpkinStem",
		Vector3.new(1.6, 0.8, 0.8),
		CFrame.new(p.Position + Vector3.new(0, diameter * 0.36 + 0.8, 0))
			* CFrame.Angles(0, 0, math.pi / 2),
		"4E7A2A"
	)
	stem.Shape = Enum.PartType.Cylinder
	chunk(i)
end
for i, p in bales do
	local original = p:GetAttribute("Launch3BaleCFrame") or p.CFrame
	p:SetAttribute("Launch3BaleCFrame", original)
	local cf = original
	if p.Parent == throne then
		local v = Vector3.new(original.X - KC.X, 0, original.Z - KC.Z)
		-- Critic's radius 30, ground/bottom Y 1.5; preserve the three stacked bales.
		local at = KC + v.Unit * 30 + Vector3.new(0, original.Y + 1.5, 0)
		cf = CFrame.new(at) * (original - original.Position)
	end
	p.CFrame, p.Size, p.Color, p.Material =
		cf, Vector3.new(5, 3, 3), hex("E3B04B"), Enum.Material.Fabric
	-- Eight narrow pieces form two closed bands, not solid boxes or crate lids.
	for _, x in { -1.5, 1.5 } do
		for _, y in { -1.52, 1.52 } do
			part("HayBand", Vector3.new(0.4, 0.04, 3.08), cf * CFrame.new(x, y, 0), "9C6B22")
		end
		for _, z in { -1.52, 1.52 } do
			part("HayBand", Vector3.new(0.4, 3, 0.04), cf * CFrame.new(x, 0, z), "9C6B22")
		end
	end
	for _, x in { -2, 2 } do
		part(
			"StrawTuft",
			Vector3.new(1, 0.6, 0.6),
			cf * CFrame.new(x, 1.8, 0),
			"E8C36A",
			nil,
			nil,
			"WedgePart"
		)
	end
	chunk(i)
end
task.wait()

-- 8. Bigger lavender dais: preserve Step/Trim instances and their flat walkability.
for k, diameter in { 52, 44, 36 } do
	local step = assert(throne:FindFirstChild("Step" .. k), "Missing Step" .. k)
	step.Size, step.Color =
		Vector3.new(1.5, diameter, diameter), hex(({ "8F8DC0", "A3A3D1", "B8BADD" })[k])
	step.Shape = Enum.PartType.Cylinder
	step.CFrame = CFrame.new(KC + Vector3.new(0, k * 1.5 - 0.75, 0))
		* CFrame.Angles(0, 0, math.pi / 2)
	local trim = assert(throne:FindFirstChild("Trim" .. k), "Missing Trim" .. k)
	trim.Size, trim.Color = Vector3.new(0.3, diameter + 0.5, diameter + 0.5), hex("E8E4D0")
	trim.Shape = Enum.PartType.Cylinder
	trim.CFrame = CFrame.new(KC + Vector3.new(0, k * 1.5 - 1.35, 0))
		* CFrame.Angles(0, 0, math.pi / 2)
end
local pool = assert(throne:FindFirstChild("GlowPool"), "Missing GlowPool")
pool.Size, pool.Transparency, pool.Color = Vector3.new(0.1, 34, 34), 0.6, hex("FFB347")
pool.Material = Enum.Material.Neon
-- Warm all remaining owned Neon yellows, including gate windows and old gold tips.
for _, root in { v1, v2, look } do
	for i, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide, d.CanTouch, d.CanQuery = false, false, false
			if
				d.Material == Enum.Material.Neon
				and d.Color.R > 0.9
				and d.Color.G > 0.75
				and d.Color.B < 0.35
			then
				d.Color = hex("FFB347")
			end
		end
		chunk(i)
	end
end
-- Retain all contract PointLights. Only v2 decorative surplus may be removed.
local _, lightCount = counts()
for _, root in { v2:FindFirstChild("WallDetails"), strings, lanterns } do
	if root then
		for i, d in root:GetDescendants() do
			if d:IsA("PointLight") and lightCount > 39 then
				d:Destroy()
				lightCount -= 1
			end
			chunk(i)
		end
	end
end
assert(lightCount < 40, "No room for King's light without deleting protected lights")
local light = Instance.new("PointLight")
light.Name, light.Color, light.Brightness, light.Range, light.Shadows =
	"KingWarmLight", hex("FF9A3C"), 2.5, 34, false
light.Parent = glow
task.wait()
local after, lightsAfter = counts()
assert(after - before < 1500, "Part growth must remain below +1500")
assert(lightsAfter <= 40, "PointLight instance cap exceeded")
look:SetAttribute("PartsBefore", before)
look:SetAttribute("PartsAfter", after)
look:SetAttribute("PointLightsBefore", lightsBefore)
look:SetAttribute("PointLightsAfter", lightsAfter)
local report = string.format(
	"LaunchLook3: Workspace parts %d -> %d (%+d); PointLights %d -> %d/40; created %d parts; one King (scale 1.4, bottom 4.65, +Z face), %d face / %d dark voxels; %d pumpkins, %d bales, %d lantern relocations. Base* saved. Play visuals/counts unverified until run; client Day clears PhaseTint, server GiantJack reset remains separate.",
	before,
	after,
	after - before,
	lightsBefore,
	lightsAfter,
	created,
	faceCount,
	darkCount,
	#pumpkins,
	#bales,
	movedLanterns
)
print(report)
return report
