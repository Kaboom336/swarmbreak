-- Studio EDIT command bar, after LaunchLook1-4. SECTION-PALETTE.md is the source of truth.
-- Reuses inspected local scene roles; no imports, scripts, deletion, or geometry changes.
assert(not game:GetService("RunService"):IsRunning(), "LaunchLook5 requires Edit mode")
local lighting = game:GetService("Lighting")
local garden = assert(workspace:FindFirstChild("Garden"), "Missing Garden")
local art = assert(garden:FindFirstChild("Art"), "Missing Garden.Art")
for _, name in { "LaunchLook", "LaunchLook2", "LaunchLook3", "LaunchLook4" } do
	assert(art:FindFirstChild(name), "Run " .. name .. " first")
end
local hex = Color3.fromHex
local base = {
	orange = "FF8A1F",
	gold = "FFC83D",
	grape = "7A4FD0",
	plum = "3B2766",
	cream = "F6E8CC",
	bone = "FFF8EC",
	leaf = "9ED66A",
	wood = "B07A4A",
}
-- floor A/B, wall low/high, accent 1/2, GateWall, HUD colour.
local palette = {
	{ "9ED66A", "96CE62", "E8B87A", "F0C88E", "FF8A1F", "FFF8EC", "7A4A2A", "FF9A2E" },
	{ "D7CDEB", "CFC4E4", "8E7FC4", "9F92D2", "FFC83D", "FFF8EC", "4E4380", "C9B4F0" },
	{ "8FC87A", "86BF72", "A06A3C", "B07A4A", "FFC83D", "7A4FD0", "5E3F24", "A8DC6A" },
	{ "A8D8C0", "9ED0B8", "6A42BC", "7A4FD0", "9EF0C8", "FF8A1F", "3B2766", "9A6BE8" },
	{ "EAB8C8", "E2AEBF", "A8406A", "B8507A", "FFC83D", "FFF8EC", "6A2444", "FF6B8E" },
	{ "FAD0E6", "F4C4DE", "C79BEA", "D8B0F2", "FF5FA8", "9EF0C8", "7E55A8", "FF7EC0" },
	{ "FFD98A", "F8CE78", "4A2D7A", "5A3A8E", "FFC83D", "FF8A1F", "2D1F43", "FFD23D" },
}
local hub = { "8CC765", "84BD5E", "7A4FD0", "8A63DE", "FF8A1F", "FFF8EC" }
local totals, painted = {}, {}
local function chunk(i)
	if i % 80 == 0 then
		task.wait()
	end
end
local function visit(root, callback)
	if not root then
		return
	end
	if root:IsA("BasePart") then
		callback(root)
	end
	for i, d in root:GetDescendants() do
		callback(d)
		chunk(i)
	end
end
local function paint(p, color, group, material, floor)
	p.Color, p.Material = hex(color), material or Enum.Material.Plastic
	if floor then
		p.TopSurface = Enum.SurfaceType.Studs
		-- Rotated cylindrical steps/discs: also retain studs on the world-facing top.
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
	end
	-- Report distinct parts per final surface group, including on reruns.
	local old = painted[p]
	if old then
		totals[old] -= 1
	end
	painted[p] = group
	totals[group] = (totals[group] or 0) + 1
end
local function preset(target, values, prefix)
	for key, value in values do
		target[key] = value
		target:SetAttribute("Base" .. key, value)
		lighting:SetAttribute("Base" .. (prefix or "") .. key, value)
	end
end
local function effect(name, class)
	local obj = lighting:FindFirstChild(name) or lighting:FindFirstChildOfClass(class)
	if not obj then
		obj = Instance.new(class)
		obj.Name, obj.Parent = name, lighting
	end
	return obj
end
preset(lighting, {
	Ambient = hex("9A8DA8"),
	OutdoorAmbient = hex("C2B2C8"),
	ColorShift_Top = hex("FFE9C8"),
	Brightness = 3.0,
	ClockTime = 16.5,
})
local grade = effect("PhaseTint", "ColorCorrectionEffect")
preset(
	grade,
	{ TintColor = hex("FFF3E6"), Brightness = 0.02, Saturation = 0.14, Contrast = 0.08 },
	"Grade"
)
for _, key in { "TintColor", "Saturation", "Contrast" } do
	lighting:SetAttribute("Base" .. key, grade[key])
end
preset(effect("Atmosphere", "Atmosphere"), {
	Color = hex("F3D9F0"),
	Decay = hex("FFC8A0"),
	Density = 0.22,
	Haze = 0.4,
	Offset = 0,
	Glare = 0,
}, "Atmosphere")
preset(
	effect("HarvestBloom", "BloomEffect"),
	{ Intensity = 0.25, Size = 12, Threshold = 1.6 },
	"Bloom"
)
task.wait()
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
		end
	end)
	ranges[n] = lo == math.huge and { 150 + (n - 1) * 160, 150 + n * 160 } or { lo, hi }
end
local function zoneAt(p)
	local ancestor = p.Parent
	while ancestor and ancestor ~= garden do
		if ancestor.Name:match("^LaunchWall") then
			return nil
		end
		local n = tonumber(ancestor.Name:match("^Zone(%d)$"))
		if n and palette[n] then
			return n
		end
		ancestor = ancestor.Parent
	end
	for n, r in ranges do
		if p.Position.Z >= r[1] and p.Position.Z < r[2] then
			return n
		end
	end
	if p.Position.Z >= 150 and p.Position.Z < 1270 then
		return math.clamp(math.floor((p.Position.Z - 150) / 160) + 1, 1, 7)
	end
	return nil
end
local function colorsAt(p)
	local n = zoneAt(p)
	return n and palette[n] or hub, n and "Z" .. n or "Hub"
end
local ground = garden:FindFirstChild("Ground")
local tileSize = 8
visit(ground, function(p)
	if p:IsA("BasePart") and p.Size.X <= 32 and p.Size.Z <= 32 then
		tileSize = math.max(tileSize, math.min(p.Size.X, p.Size.Z))
	end
end)
local function floor(p)
	local colors, group = colorsAt(p)
	local parity = (
		math.floor((p.Position.X - 1330) / tileSize) + math.floor((p.Position.Z + 80) / tileSize)
	) % 2
	paint(p, colors[parity + 1], group .. " floors", nil, true)
end
visit(ground, function(p)
	if p:IsA("BasePart") then
		floor(p)
	end
end)
visit(zones, function(p)
	if p:IsA("BasePart") then
		local colors, group = colorsAt(p)
		if p.Name == "Spawn" then
			floor(p)
		elseif p.Name == "GateWall" then
			paint(p, colors[7], group .. " gates")
		elseif p.Name == "Trim" or p.Name == "Accent" then
			paint(p, colors[5], group .. " accents")
		elseif p.Name == "Banner" or p.Name == "Accent2" then
			paint(p, colors[6], group .. " accents")
		end
	end
end)
local capColors = {}
visit(art:FindFirstChild("Walls"), function(p)
	if not p:IsA("BasePart") then
		return
	end
	local colors, group = colorsAt(p)
	if p.Name == "Slab" then
		-- L4's added caps live outside LaunchWall; recover ownership by footprint.
		local key = string.format("%.3f/%.3f", p.Position.X, p.Position.Z)
		capColors[key] = { colors, group }
	end
	if p.Name == "Cap" then
		paint(p, colors[5], group .. " caps", Enum.Material.Neon)
	else
		paint(p, colors[p.Position.Y < 15 and 3 or 4], group .. " walls")
		for _, face in { "Top", "Front", "Back", "Left", "Right" } do
			p[face .. "Surface"] = Enum.SurfaceType.Studs
		end
	end
end)
visit(art:FindFirstChild("LaunchLook4"), function(p)
	if p:IsA("BasePart") and p.Name == "WallCap" then
		local colors, group = colorsAt(p)
		local source = capColors[string.format("%.3f/%.3f", p.Position.X, p.Position.Z)]
		if source then
			colors, group = source[1], source[2]
		end
		paint(p, colors[5], group .. " caps", Enum.Material.Neon)
	end
end)
local v2 = art:FindFirstChild("LaunchLook2")
visit(v2:FindFirstChild("CleanPaths"), function(p)
	if not p:IsA("BasePart") then
		return
	end
	local color = p.Name == "InnerLawn" and base.leaf
		or (p.Name == "Curb" or p.Name == "RingEdge") and base.bone
		or "FBF1DC"
	paint(p, color, "Paths and lawn", nil, true)
end)
local market = garden:FindFirstChild("Market")
local plaza = market and market:FindFirstChild("Plaza")
if plaza and plaza:IsA("BasePart") then
	paint(plaza, "FBF1DC", "Paths and lawn", nil, true)
end
visit(garden:FindFirstChild("Patches"), function(p)
	if p:IsA("TextLabel") and p:FindFirstAncestor("OwnerSign") then
		p.TextColor3 = hex(base.bone)
		return
	end
	if not p:IsA("BasePart") then
		return
	end
	local pen = p:FindFirstAncestorWhichIsA("Model")
	while pen and not pen.Name:match("^Pen%d+$") do
		pen = pen:FindFirstAncestorWhichIsA("Model")
	end
	local name = p.Name
	if name == "Soil" then
		paint(p, pen and "F2DC9A" or "A06A40", "Pens and patches", nil, true)
	elseif name == "Rail" or name == "Brace" then
		paint(p, pen and base.cream or base.wood, "Pens and patches")
	elseif name == "Post" then
		paint(p, pen and base.grape or "6B4430", "Pens and patches")
	elseif name == "Pole" or name == "Board" then
		paint(p, "6B4430", "Pens and patches")
	elseif name == "Plot" then
		paint(p, "A06A40", "Pens and patches", nil, true)
	elseif name == "DiscRim" then
		paint(p, base.wood, "Pens and patches", nil, true)
	elseif name == "Bar" then
		paint(p, base.orange, "Pens and patches")
	end
end)
for _, name in { "Sell", "Seeds", "Upgrades" } do
	visit(market and market:FindFirstChild(name), function(p)
		if p:IsA("BasePart") then
			local stripe = tonumber(p.Name:match("^Roof(%d+)$") or p.Name:match("^Awning(%d+)$"))
			if stripe then
				paint(p, stripe % 2 == 1 and base.orange or base.bone, "Stalls")
			elseif p.Name == "Board" then
				paint(p, base.plum, "Stalls")
			elseif p.Name == "Pole" or p.Name == "Post" then
				paint(p, "6B4430", "Stalls")
			elseif p.Name == "Counter" or p.Name == "Top" or p.Name == "Body" then
				paint(p, base.wood, "Stalls")
			end
		elseif p:IsA("TextLabel") then
			p.TextColor3 = hex(base.gold)
		elseif p:IsA("PointLight") then
			p.Color = hex(base.gold)
		end
	end)
end
visit(v2:FindFirstChild("Throne"), function(p)
	if not p:IsA("BasePart") then
		return
	end
	local step = tonumber(p.Name:match("^Step(%d)$"))
	if step and step <= 3 then
		paint(p, ({ "C9B4F0", "D8C8F5", "E8DEFA" })[step], "Throne", nil, true)
	elseif p.Name:match("^Trim") then
		paint(p, base.bone, "Throne")
	end
end)
visit(v2:FindFirstChild("WallDetails"), function(p)
	if not p:IsA("BasePart") then
		return
	end
	local colors = { Buttress = "6A42BC", CapTrim = base.bone, Pumpkin = base.orange }
	if colors[p.Name] then
		paint(p, colors[p.Name], "Wall details")
	end
end)
visit(v2:FindFirstChild("HauntedGate"), function(p)
	if p:IsA("TextLabel") then
		p.TextColor3 = hex(base.bone)
		return
	end
	if not p:IsA("BasePart") then
		return
	end
	local colors = {
		Tower = base.grape,
		Spire = base.orange,
		ArchBeam = base.plum,
		Banner = base.orange,
		Window = "FFE08A",
	}
	if colors[p.Name] then
		paint(
			p,
			colors[p.Name],
			"Hub gate",
			p.Name == "Window" and Enum.Material.SmoothPlastic or nil
		)
	end
end)
visit(v2:FindFirstChild("PathLanterns"), function(p)
	if p:IsA("BasePart") then
		paint(
			p,
			p.Name == "Core" and base.gold or base.plum,
			"Lanterns",
			p.Name == "Core" and Enum.Material.Neon or nil
		)
	elseif p:IsA("PointLight") then
		p.Color, p.Brightness, p.Range = hex(base.gold), 1, 12
	end
end)
visit(art:FindFirstChild("LaunchLook3"), function(p)
	if p:IsA("BasePart") and p.Name == "LanternCapBase" then
		paint(p, base.plum, "Lanterns")
	end
end)
local stationColors = {
	SELLPad = base.orange,
	SHOPPad = base.gold,
	UPGRADESPad = base.grape,
	SellCauldron = base.plum,
	CauldronGoo = base.grape,
}
visit(v2, function(p)
	if p:IsA("BasePart") and stationColors[p.Name] then
		paint(p, stationColors[p.Name], "Station props", nil, p.Name:match("Pad$") ~= nil)
	elseif p:IsA("ParticleEmitter") and p.Name == "Bubbles" and p.Parent.Name == "CauldronGoo" then
		p.Color = ColorSequence.new(hex(base.grape))
	elseif p:IsA("TextLabel") and p:FindFirstAncestor("StationTitle") then
		p.TextColor3 = hex(base.gold)
	end
end)
-- Recognized scenery roles only: pets, guardians, scythes, scripts and UI layout stay intact.
visit(art, function(p)
	if
		not p:IsA("BasePart")
		or painted[p]
		or p:FindFirstAncestor("ThroneKing")
		or p:FindFirstAncestor("ThroneDetails")
	then
		return
	end
	local name = p.Name:lower()
	local owner = p.Parent
	local role = name
	while owner and owner ~= art do
		role ..= "/" .. owner.Name:lower()
		owner = owner.Parent
	end
	if name == "soil" then
		paint(p, "A06A40", "Bed soil", nil, true)
	elseif name == "pumpkinstem" or name == "stem" then
		paint(p, "6FAE60", "Props")
	elseif
		name == "pumpkin"
		or name == "pumpkinrib"
		or role:find("prop%d+_pumpkin")
		or (
			name == "shade"
			and (p:FindFirstAncestor("PumpkinBeds") or p:FindFirstAncestor("Throne"))
		)
	then
		paint(p, base.orange, "Props")
	elseif role:find("gravestone") then
		paint(p, name:find("shade") and "8E7FC4" or "D7CDEB", "Props")
	elseif name:find("trunk") then
		paint(p, "8A5A34", "Props")
	elseif name == "treecrown" or name == "leaf" or name:find("bush") or name:find("vine") then
		paint(p, zoneAt(p) == 3 and "6FAE60" or base.leaf, "Props")
	elseif role:find("prop%d+_post_lantern") then
		paint(p, (name == "glass" or name == "core") and base.gold or "6B4430", "Props")
	elseif name == "haybale" or role:find("prop%d+_haybale") then
		paint(p, "F2DC9A", "Props")
	elseif name == "post" or name == "pole" or name == "board" or name == "pennantpole" then
		paint(p, "6B4430", "Props")
	elseif name == "rail" or name == "brace" then
		paint(p, base.wood, "Props")
	elseif name == "path" then
		paint(p, "FBF1DC", "Paths and lawn", nil, true)
	elseif name == "pathedge" then
		paint(p, base.bone, "Paths and lawn", nil, true)
	end
end)
-- Repaint existing gate GUI colours in Edit mode; server uses the same zone definitions.
visit(zones, function(d)
	local gui = d:FindFirstAncestor("GateGui")
	if not gui then
		return
	end
	local sign = gui.Parent
	if not sign or not sign:IsA("BasePart") then
		return
	end
	local colors = colorsAt(sign)
	if d:IsA("TextLabel") then
		d.TextColor3 = hex(d.Name == "Title" and colors[8] or base.bone)
	elseif d:IsA("Frame") and d.Name == "Pill" then
		d.BackgroundColor3 = hex(base.gold)
	elseif d:IsA("UIStroke") then
		d.Color = hex(base.plum)
	end
end)
local groups, total = {}, 0
for group, count in totals do
	table.insert(groups, group .. "=" .. count)
	total += count
end
table.sort(groups)
local report = "LaunchLook5: "
	.. total
	.. " parts recoloured; "
	.. table.concat(groups, "; ")
	.. "; Base*/BaseGrade* warm daylight saved; Studio visuals UNKNOWN."
print(report)
return report
