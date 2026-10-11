-- Studio command bar, EDIT only, after LaunchLook 1-3. Proposal B: Stud Patch.
-- Reuses inspected local scene code; no imported assets, network, or new scripts.
-- Reference: Steal an Egg h_0018 for daylight/studs; our King/beds/gate retain identity.
-- Visual acceptance (stud visibility, phone moire, bloom) requires a Studio capture.
assert(not game:GetService("RunService"):IsRunning(), "LaunchLook4 requires Edit mode")
local lighting = game:GetService("Lighting")
local garden = assert(workspace:FindFirstChild("Garden"), "Missing Garden")
local art = assert(garden:FindFirstChild("Art"), "Missing Garden.Art")
local v1 = assert(art:FindFirstChild("LaunchLook"), "Run LaunchLook first")
local v2 = assert(art:FindFirstChild("LaunchLook2"), "Run LaunchLook2 first")
local v3 = assert(art:FindFirstChild("LaunchLook3"), "Run LaunchLook3 first")
local hex = Color3.fromHex
local function chunk(i)
	if i % 80 == 0 then
		task.wait()
	end
end
local function counts()
	local result = { parts = 0, visible = 0, lights = 0, enabled = 0 }
	for i, d in garden:GetDescendants() do
		if d:IsA("BasePart") then
			result.parts += 1
			if d.Transparency < 1 then
				result.visible += 1
			end
		elseif d:IsA("PointLight") then
			result.lights += 1
			if d.Enabled then
				result.enabled += 1
			end
		end
		chunk(i)
	end
	return result
end
local before = counts()
print(
	"LaunchLook4 before:",
	before.parts,
	"parts;",
	before.visible,
	"visible;",
	before.lights,
	"PointLights;",
	before.enabled,
	"enabled"
)
local previous = art:FindFirstChild("LaunchLook4")
if previous then
	for i, d in previous:GetDescendants() do
		-- This root owns only new cap geometry, never gameplay anchors.
		if d:IsA("BasePart") then
			d:Destroy()
		end
		chunk(i)
	end
	previous:Destroy()
end
local look = Instance.new("Folder")
look.Name, look.Parent = "LaunchLook4", art
look:SetAttribute("StudsRendered", "UNKNOWN: inspect top faces in Studio")
local function remember(p)
	for key, value in
		{
			Color = p.Color,
			Material = p.Material.Name,
			Transparency = p.Transparency,
			CanCollide = p.CanCollide,
			CanQuery = p.CanQuery,
			CanTouch = p.CanTouch,
			CastShadow = p.CastShadow,
		}
	do
		if p:GetAttribute("L4Orig" .. key) == nil then
			p:SetAttribute("L4Orig" .. key, value)
		end
	end
	for _, face in { "Top", "Bottom", "Front", "Back", "Left", "Right" } do
		local key = face .. "Surface"
		if p:GetAttribute("L4Orig" .. key) == nil then
			p:SetAttribute("L4Orig" .. key, p[key].Name)
		end
	end
end
local function paint(p, color, material)
	remember(p)
	p.Color, p.Material = hex(color), material or Enum.Material.Plastic
end
local function hide(p)
	remember(p)
	p.Transparency, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow =
		1, false, false, false, false
end
local function visit(root, callback)
	for i, d in root and root:GetDescendants() or {} do
		callback(d)
		chunk(i)
	end
end
local studded, sideways = 0, 0
local function studs(p, color)
	paint(p, color)
	-- Cylindrical rings/steps were rotated by v2: local Top is a SIDE in world space.
	-- Keep geometry intact and stud the upward face as well as local Top.
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth
	local best, dot = "Top", p.CFrame.UpVector.Y
	for face, vector in
		{
			Right = p.CFrame.RightVector,
			Left = -p.CFrame.RightVector,
			Front = p.CFrame.LookVector,
			Back = -p.CFrame.LookVector,
			Bottom = -p.CFrame.UpVector,
		}
	do
		if vector.Y > dot then
			best, dot = face, vector.Y
		end
	end
	p[best .. "Surface"] = Enum.SurfaceType.Studs
	if best ~= "Top" then
		sideways += 1
	end
	for _, d in p:GetChildren() do
		if d:IsA("Texture") or d:IsA("Decal") then
			d:Destroy()
		end
	end
	studded += 1
end
local function preset(target, values, prefix)
	for key, value in values do
		target[key] = value
		target:SetAttribute("Base" .. key, value)
		lighting:SetAttribute("Base" .. (prefix or "") .. key, value)
	end
end
-- 1. Absolute daylight. Never overwrite sun BaseBrightness with grade brightness.
preset(lighting, {
	ClockTime = 14,
	GeographicLatitude = 25,
	Brightness = 2.8,
	ExposureCompensation = 0.15,
	Ambient = hex("7E8494"),
	OutdoorAmbient = hex("A4AAB8"),
	ColorShift_Top = hex("FFF4E2"),
	ColorShift_Bottom = hex("000000"),
	GlobalShadows = true,
	ShadowSoftness = 0.4,
	EnvironmentDiffuseScale = 0.55,
	EnvironmentSpecularScale = 0.15,
})
pcall(function()
	lighting.Technology = Enum.Technology.ShadowMap
	lighting:SetAttribute("BaseTechnology", lighting.Technology.Name)
end)
local function effect(name, class)
	local obj = lighting:FindFirstChild(name) or lighting:FindFirstChildOfClass(class)
	if not obj then
		obj = Instance.new(class)
		obj.Name, obj.Parent = name, lighting
	end
	return obj
end
local cc = effect("PhaseTint", "ColorCorrectionEffect")
preset(
	cc,
	{ TintColor = hex("FFFFFF"), Brightness = 0.02, Contrast = 0.06, Saturation = 0.10 },
	"Grade"
)
for _, key in { "TintColor", "Contrast", "Saturation" } do
	lighting:SetAttribute("Base" .. key, cc[key])
end
preset(effect("Atmosphere", "Atmosphere"), {
	Density = 0.22,
	Offset = 0,
	Color = hex("CFE6FF"),
	Decay = hex("9CC2EE"),
	Glare = 0,
	Haze = 0.4,
}, "Atmosphere")
preset(
	effect("HarvestBloom", "BloomEffect"),
	{ Intensity = 0.25, Size = 12, Threshold = 1.6 },
	"Bloom"
)
for _, d in lighting:GetChildren() do
	if d:IsA("SunRaysEffect") then
		d:Destroy()
	elseif d:IsA("Sky") then
		preset(
			d,
			{ SunAngularSize = 11, MoonAngularSize = 6, CelestialBodiesShown = true, StarCount = 0 }
		)
	end
end
lighting:SetAttribute("BaseSunRaysIntensity", nil)
lighting:SetAttribute("BaseSunRaysSpread", nil)
task.wait()
-- 2. Preserve every slab and every contract's geometry/collision/prompts.
local palette = {
	{ "A8E04A", "9DD443", "C9783E", "D4864A", "9BFF4A", "8E4312" },
	{ "BFC3DE", "B3B7D4", "6B6F94", "777BA0", "E8E4FF", "4E5278" },
	{ "5FC24A", "56B443", "6E4A32", "7A5538", "9BFF4A", "4A3022" },
	{ "6FBFA0", "64B294", "5E3F94", "6A4AA0", "9BFF4A", "3F2A66" },
	{ "C9CBE6", "BCBEDC", "4F5D96", "5B69A2", "FFFFFF", "3A4578" },
	{ "F7C8E8", "EDBADC", "B57BD6", "C08AE0", "FFFFFF", "8E52B8" },
	{ "F7A63C", "EC9832", "3E2C5C", "4A3668", "FFB347", "2D1F43" },
}
local hub = { "8EE03C", "82D236", "8A6CC8", "9579D2", "FF9A2E" }
local ranges = {}
local zones = garden:FindFirstChild("Zones")
for n = 1, 7 do
	local zone = zones and zones:FindFirstChild("Zone" .. n)
	local lo, hi = math.huge, -math.huge
	visit(zone, function(p)
		if p:IsA("BasePart") and p.Name == "Spawn" then
			local half = (
				math.abs(p.CFrame.RightVector.Z) * p.Size.X
				+ math.abs(p.CFrame.UpVector.Z) * p.Size.Y
				+ math.abs(p.CFrame.LookVector.Z) * p.Size.Z
			) / 2
			lo, hi = math.min(lo, p.Position.Z - half), math.max(hi, p.Position.Z + half)
			studs(p, palette[n][1])
		elseif p:IsA("BasePart") and p.Name == "GateWall" then
			paint(p, palette[n][6])
		end
	end)
	ranges[n] = lo == math.huge and { 150 + (n - 1) * 160, 150 + n * 160 } or { lo, hi }
end
local function colorsAt(p)
	if p.Parent and p.Parent.Name:match("^LaunchWall") then
		return hub
	end
	for n, r in ranges do
		if p.Position.Z >= r[1] and p.Position.Z < r[2] then
			return palette[n]
		end
	end
	if p.Position.Z >= 150 and p.Position.Z < 1270 then
		return palette[math.clamp(math.floor((p.Position.Z - 150) / 160) + 1, 1, 7)]
	end
	return hub
end
local tileSize = 8
local ground = garden:FindFirstChild("Ground")
visit(ground, function(p)
	if p:IsA("BasePart") and p.Size.X <= 32 and p.Size.Z <= 32 then
		tileSize = math.max(tileSize, math.min(p.Size.X, p.Size.Z))
	end
end)
print("LaunchLook4 checker pitch:", tileSize, "studs; slabs retained")
visit(ground, function(p)
	if p:IsA("BasePart") then
		local colors = colorsAt(p)
		local parity = (
			math.floor((p.Position.X - 1330) / tileSize)
			+ math.floor((p.Position.Z + 80) / tileSize)
		) % 2
		studs(p, colors[parity + 1])
	end
end)
visit(garden:FindFirstChild("Patches"), function(p)
	if p:IsA("BasePart") then
		if p.Name == "Soil" then
			studs(p, "9A6A44")
		elseif p.Name == "Rail" or p.Name == "Brace" then
			paint(p, "8E4312")
		elseif p.Name == "Post" or p.Name == "Pole" or p.Name == "Board" then
			paint(p, "40303A")
		end
	end
end)
local market = garden:FindFirstChild("Market")
local plaza = market and market:FindFirstChild("Plaza")
if plaza and plaza:IsA("BasePart") then
	studs(plaza, "E9DCC4")
end
visit(v2:FindFirstChild("CleanPaths"), function(p)
	if p:IsA("BasePart") then
		studs(
			p,
			p.Name == "InnerLawn" and "8EE03C"
				or (p.Name == "Curb" or p.Name == "RingEdge") and "FFFFFF"
				or "E9DCC4"
		)
	end
end)
-- 3. Stud walls and reuse the existing cap lines, without changing footprints.
local walls = art:FindFirstChild("Walls")
local caps, slabs = {}, {}
visit(walls, function(p)
	if p:IsA("BasePart") then
		local colors = colorsAt(p)
		if p.Name == "Cap" then
			paint(p, colors[5], Enum.Material.Neon)
			table.insert(caps, p)
		else
			paint(p, colors[p.Position.Y < 15 and 3 or 4])
			for _, face in { "Top", "Front", "Back", "Left", "Right" } do
				p[face .. "Surface"] = Enum.SurfaceType.Studs
			end
			if p.Name == "Slab" then
				table.insert(slabs, p)
			end
		end
	end
end)
local addedCaps = 0
for i, slab in slabs do
	local covered, higher = false, false
	local top = slab.Position.Y + slab.Size.Y / 2
	for _, cap in caps do
		local localPos = cap.CFrame:PointToObjectSpace(slab.Position)
		if
			math.abs(localPos.X) <= cap.Size.X / 2 + 1
			and math.abs(localPos.Z) <= cap.Size.Z / 2 + 1
		then
			covered = true
			break
		end
	end
	for _, other in slabs do
		if
			other ~= slab
			and math.abs(other.Position.X - slab.Position.X) < 0.1
			and math.abs(other.Position.Z - slab.Position.Z) < 0.1
			and other.Position.Y > slab.Position.Y
		then
			higher = true
			break
		end
	end
	if not covered and not higher then
		local cap = Instance.new("Part")
		cap.Name, cap.Size = "WallCap", Vector3.new(slab.Size.X, 1, slab.Size.Z)
		cap.CFrame = CFrame.new(slab.Position.X, top + 0.5, slab.Position.Z)
			* (slab.CFrame - slab.Position)
		cap.Anchored, cap.CanCollide, cap.CanQuery, cap.CanTouch = true, false, false, false
		cap.Color, cap.Material = hex(colorsAt(slab)[5]), Enum.Material.Neon
		cap.Parent = look
		addedCaps += 1
	end
	chunk(i)
end
task.wait()
-- 4. Keepers. Classify row-1 lantern pairs using stable v2 positions, not child order.
local lanterns = v2:FindFirstChild("PathLanterns")
local groups = { {}, {}, {}, {} }
local cores, kept = {}, {}
visit(lanterns, function(p)
	if p:IsA("BasePart") and p.Name == "Core" then
		table.insert(cores, p)
		local at = p:GetAttribute("Launch3OriginalPosition") or p.Position
		local dx, dz = at.X - 1500, at.Z - 40
		local axis = math.abs(dx) > math.abs(dz) and (dx < 0 and 3 or 4) or (dz < 0 and 1 or 2)
		-- Diagonal station lanterns are outside the four cardinal spoke corridors.
		if math.min(math.abs(dx), math.abs(dz)) <= 12 then
			table.insert(groups[axis], p)
		end
	end
end)
local function distance(p)
	local at = p:GetAttribute("Launch3OriginalPosition") or p.Position
	return Vector3.new(at.X - 1500, 0, at.Z - 40).Magnitude
end
local keptCount = 0
for _, group in groups do
	table.sort(group, function(a, b)
		return distance(a) < distance(b)
	end)
	for i = 1, math.min(2, #group) do
		kept[group[i]] = true
		keptCount += 1
	end
end
local function fixture(p)
	if not p:IsA("BasePart") then
		return
	end
	local nearest, delta = nil, math.huge
	for _, core in cores do
		local flat =
			Vector3.new(p.Position.X - core.Position.X, 0, p.Position.Z - core.Position.Z).Magnitude
		if flat < delta then
			nearest, delta = core, flat
		end
	end
	if nearest and delta < 5 then
		if kept[nearest] then
			paint(
				p,
				p == nearest and "FFB347" or "2D1F43",
				p == nearest and Enum.Material.Neon or Enum.Material.Plastic
			)
		else
			hide(p)
		end
	end
end
visit(lanterns, fixture)
visit(v3, function(p)
	if p:IsA("BasePart") and p.Name == "LanternCapBase" then
		fixture(p)
	end
end)
visit(lanterns, function(d)
	if d:IsA("PointLight") then
		if kept[d.Parent] then
			d.Enabled, d.Brightness, d.Range, d.Shadows, d.Color = true, 1, 12, false, hex("FFB347")
		else
			d:Destroy()
		end
	end
end)
-- V3's light-budget pass may have removed a row-1 light. Restore only kept cores.
for core in kept do
	if not core:FindFirstChildWhichIsA("PointLight") then
		local light = Instance.new("PointLight")
		light.Name, light.Color, light.Brightness, light.Range, light.Shadows =
			"StudLanternLight", hex("FFB347"), 1, 12, false
		light.Parent = core
	end
end
if keptCount ~= 8 then
	warn("LaunchLook4: expected eight lantern cores; found " .. keptCount)
end
visit(v2:FindFirstChild("Throne"), function(p)
	if p:IsA("BasePart") then
		local step = tonumber(p.Name:match("^Step(%d)$"))
		if step and step <= 3 then
			studs(p, ({ "B8A6E6", "C6B6EE", "D4C8F4" })[step])
		elseif p.Name:match("^Trim") then
			paint(p, "FFFFFF")
		elseif p.Name == "GlowPool" then
			hide(p)
		end
	end
end)
visit(v2:FindFirstChild("PumpkinBeds"), function(p)
	if p:IsA("BasePart") then
		if p.Name == "Soil" then
			studs(p, "9A6A44")
		elseif p.Name == "Furrow" then
			hide(p)
		end
	end
end)
visit(v2:FindFirstChild("HauntedGate"), function(p)
	if p:IsA("BasePart") then
		local colors = {
			Tower = "8A6CC8",
			Spire = "FF9A2E",
			ArchBeam = "2D1F43",
			Banner = "F28C1A",
			Window = "FFD36B",
		}
		if colors[p.Name] then
			paint(
				p,
				colors[p.Name],
				p.Name == "Window" and Enum.Material.SmoothPlastic or Enum.Material.Plastic
			)
		end
		if p.Name == "Tower" then
			for _, face in { "Top", "Front", "Back", "Left", "Right" } do
				p[face .. "Surface"] = Enum.SurfaceType.Studs
			end
		end
	end
end)
-- 5. Cuts hide decoration, never delete contracts or the visibility adapter.
local function cut(root)
	if root and root:IsA("BasePart") then
		hide(root)
	end
	visit(root, function(d)
		if d:IsA("BasePart") then
			hide(d)
		elseif d:IsA("Light") then
			d:Destroy()
		end
	end)
end
for _, name in { "StringLights", "DaytimeMoon" } do
	cut(v2:FindFirstChild(name))
end
for _, name in { "WallLanterns", "StringLights", "PenFurrows" } do
	cut(v1:FindFirstChild(name))
end
-- B's four landmarks carry the hub; hide remaining v2 skyline filler.
for i, d in v2:GetChildren() do
	if
		d.Name == "Gravestone"
		or d.Name:match("^HarvestTree")
		or d.Name == "TreeTrunk"
		or d.Name == "TreeCrown"
	then
		cut(d)
	end
	chunk(i)
end
visit(v2:FindFirstChild("WallDetails"), function(p)
	if p:IsA("BasePart") then
		if p.Name == "WallGlow" or p.Name == "Bracket" then
			hide(p)
		elseif p.Name == "Buttress" then
			paint(p, "8A6CC8")
		elseif p.Name == "CapTrim" then
			paint(p, "FFFFFF")
		elseif p.Name == "Pumpkin" then
			paint(p, "F28C1A")
		end
	elseif p:IsA("Light") then
		p:Destroy()
	end
end)
visit(v3, function(p)
	if p:IsA("BasePart") and p.Name == "KingHeadGlow" then
		cut(p)
	elseif p:IsA("PointLight") and p.Name == "KingWarmLight" then
		p:Destroy()
	end
end)
local king = v1:FindFirstChild("ThroneKing")
for _, root in { v1, v2, v3 } do
	visit(root, function(p)
		if p:IsA("BasePart") then
			local allowed = (king and p:IsDescendantOf(king) and p.Name == "f") or kept[p]
			if p.Material == Enum.Material.Neon and not allowed then
				paint(p, p.Color:ToHex(), Enum.Material.SmoothPlastic)
			end
			if
				p.Material == Enum.Material.Wood
				or p.Material == Enum.Material.WoodPlanks
				or p.Material == Enum.Material.Grass
				or p.Material == Enum.Material.Ground
				or p.Material == Enum.Material.Brick
				or p.Material == Enum.Material.Slate
				or p.Material == Enum.Material.Cobblestone
			then
				paint(p, p.Color:ToHex())
			end
		elseif p:IsA("Light") and not kept[p.Parent] then
			-- Only owned art. Market and gameplay markers are outside these roots.
			p.Enabled = false
		end
	end)
end
-- 6. Audit actual counts (hidden parts remain deliberately present).
local after = counts()
assert(after.parts - before.parts < 300, "LaunchLook4 part growth exceeds budget")
if after.lights > 40 then
	warn("PointLight cap exceeded; protected game lights were retained")
end
local report = string.format(
	"LaunchLook4: Garden parts %d -> %d; visible %d -> %d; PointLights %d -> %d (enabled %d -> %d); stud floors %d (%d rotated top faces); lanterns %d/8; new caps %d; Studs rendered UNKNOWN (Studio check).",
	before.parts,
	after.parts,
	before.visible,
	after.visible,
	before.lights,
	after.lights,
	before.enabled,
	after.enabled,
	studded,
	sideways,
	keptCount,
	addedCaps
)
print(report)
return report
