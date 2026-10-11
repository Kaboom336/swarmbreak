-- Studio EDIT command bar, after LaunchLook1-5. No builders/imports/network.
-- SECTION-WORLD / SECTION-PALETTE; reference: Steal an Egg's clear lanes and
-- Tongue Evolution's escalating silhouettes. All geometry is local block art.
-- Runtime Patch.server recreates gate GUIs/prompts: their runtime distance/content
-- cannot be guaranteed by an Edit-only pass. GateSign's physical position persists.
assert(not game:GetService("RunService"):IsRunning(), "WorldPlan requires Edit mode")
local garden = assert(workspace:FindFirstChild("Garden"), "Missing Garden")
local art = assert(garden:FindFirstChild("Art"), "Missing Art")
local zones = assert(garden:FindFirstChild("Zones"), "Missing Zones")
local market = assert(garden:FindFirstChild("Market"), "Missing Market")
local patches = assert(garden:FindFirstChild("Patches"), "Missing Patches")
for _, name in { "LaunchLook", "LaunchLook2", "LaunchLook3", "LaunchLook4" } do
	assert(art:FindFirstChild(name), "Run " .. name .. " and LaunchLook5 first")
end
local lighting = game:GetService("Lighting")
local V, hex = Vector3.new, Color3.fromHex
local report, removed, added = {}, {}, {}
local function log(s)
	table.insert(report, s)
	print("[WorldPlan] " .. s)
end
local function chunk(i)
	if i % 60 == 0 then
		task.wait()
	end
end
-- Rotation-aware world AABB, including single parts and nested models/folders.
local function bounds(root, skipPrompt)
	local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	local function include(p)
		if not p:IsA("BasePart") then
			return
		end
		if skipPrompt and p.Name == "PromptPart" then
			return
		end
		local cf, s = p.CFrame, p.Size / 2
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					local q = cf:PointToWorldSpace(V(s.X * x, s.Y * y, s.Z * z))
					lo, hi = lo:Min(q), hi:Max(q)
				end
			end
		end
	end
	include(root)
	for _, p in root:GetDescendants() do
		include(p)
	end
	if lo.X == math.huge then
		return nil
	end
	return (lo + hi) / 2, hi - lo, lo, hi
end
local state = {}
for n = 1, 7 do
	local zone = assert(zones:FindFirstChild("Zone" .. n), "Missing Zone" .. n)
	local hoard = assert(zone:FindFirstChild("Hoard"), "Missing Hoard in " .. zone.Name)
	local hc = assert(bounds(hoard), "Hoard has no geometry")
	local gate = zone:FindFirstChild("GateWall")
	local z0 = zone:GetAttribute("ZMin") or (gate and gate.Position.Z) or (hc.Z - 104)
	local spawns, floor = {}, math.huge
	for _, d in zone:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Spawn" then
			table.insert(spawns, d)
			floor = math.min(floor, d.Position.Y - d.Size.Y / 2)
		end
	end
	assert(#spawns > 0, "No live Spawn parts in " .. zone.Name)
	-- Contract lane width, translated by the actual gate / spawn centre.
	local x = gate and gate.Position.X or 0
	if not gate then
		for _, p in spawns do
			x += p.Position.X / #spawns
		end
	end
	state[n] = { zone = zone, hoard = hoard, hc = hc, x = x, z = z0, y = floor, spawns = spawns }
	log(
		string.format(
			"%s actual gate/start Z %.2f, lane X %.2f, floor %.2f, Hoard %s, Spawns %d",
			zone.Name,
			z0,
			x,
			floor,
			tostring(hc),
			#spawns
		)
	)
end
local spawn = assert(garden:FindFirstChildOfClass("SpawnLocation"), "Missing hub spawn")
local king = garden:FindFirstChild("ThroneKing", true) or market:FindFirstChild("GiantJack")
assert(king and bounds(king), "Missing King geometry")
local kc = bounds(king)
local hubX, hubZ, hubY = spawn.Position.X, kc.Z, spawn.Position.Y - spawn.Size.Y / 2
log("Hub actual spawn " .. tostring(spawn.Position) .. ", King " .. tostring(kc))
-- Snapshot gameplay contracts before cuts. Entire functional branches are immutable
-- for deletion. Zone structural pieces and their descendants are also protected.
local protected = {}
local function protect(root)
	if not root then
		return
	end
	protected[root] = true
	for _, d in root:GetDescendants() do
		protected[d] = true
	end
end
for _, name in
	{
		"Market",
		"Patches",
		"Cauldrons",
		"GhostSpawns",
		"Ground",
		"SpawnLocation",
		"WildPumpkins",
		"Loose",
		"Ghosts",
		"LoosePumpkins",
		"Ghosts",
		"PlayAreaSafety",
	}
do
	protect(garden:FindFirstChild(name))
end
protect(king)
for _, s in state do
	protected[s.zone] = true
	for _, d in s.zone:GetDescendants() do
		local name = d.Name:lower()
		if
			name == "spawn"
			or name:find("hoard")
			or name:find("guard")
			or name:find("nest")
			or name:find("kingseed")
			or name:find("gate")
			or name:find("floor")
			or name:find("wall")
			or name:find("ground")
			or d:IsA("ProximityPrompt")
			or d:IsA("LuaSourceContainer")
		then
			protect(d)
		end
	end
end
local existingPlan = art:FindFirstChild("WorldPlan")
for _, d in garden:GetDescendants() do
	local name = d.Name:lower()
	if
		(not existingPlan or not d:IsDescendantOf(existingPlan))
		and (name:find("hoard") or name:find("guard") or name:find("nest") or name:find("kingseed"))
	then
		protect(d)
	end
	if d:IsA("ProximityPrompt") or d:IsA("LuaSourceContainer") or d:IsA("ObjectValue") then
		protect(d.Parent)
		if d:IsA("ObjectValue") and d.Value then
			protect(d.Value)
		end
	end
end
local function safe(root)
	if protected[root] then
		return false
	end
	for _, d in root:GetDescendants() do
		if protected[d] then
			return false
		end
	end
	return true
end
local function area(c)
	if c and c.Z >= state[1].z then
		for n = 7, 1, -1 do
			if c.Z >= state[n].z then
				return "Zone" .. n
			end
		end
	end
	return "Hub"
end
local function cut(d)
	if not d.Parent or not safe(d) then
		return
	end
	local c = bounds(d)
	local key = area(c)
	removed[key] = (removed[key] or 0) + 1
	log("Cut " .. d:GetFullName() .. " at " .. tostring(c))
	d:Destroy()
end
local previous = art:FindFirstChild("WorldPlan")
if previous then
	assert(
		previous:GetAttribute("WorldPlanOwned") == true and safe(previous),
		"Unowned/functional WorldPlan: refusing teardown"
	)
	for _, folder in previous:GetChildren() do
		for i, d in folder:GetChildren() do
			cut(d)
			chunk(i)
		end
		folder:Destroy()
	end
	previous:Destroy()
end
local hidden = {
	DaytimeMoon = true,
	StringLights = true,
	PenFurrows = true,
	WallGlow = true,
	Bracket = true,
	GlowPool = true,
	JumpPads = true,
	RoadLanterns = true,
}
-- Explicit presentation-only cut names are not Patch gameplay references.
-- Permit deleting these children even inside an otherwise protected King.
for _, d in garden:GetDescendants() do
	if hidden[d.Name] then
		protected[d] = nil
		for _, child in d:GetDescendants() do
			protected[child] = nil
		end
	end
end
local propWords = {
	"pumpkin",
	"grave",
	"mushroom",
	"tree",
	"pine",
	"fence",
	"haybale",
	"crop",
	"rock",
	"prop",
	"mini",
	"scatter",
	"bush",
}
local function isProp(name)
	for _, word in propWords do
		if name:lower():find(word) then
			return true
		end
	end
	return false
end
-- Models are removed whole only when no protected descendants exist. Never
-- destroy structural containers based on their aggregate centre.
for i, d in garden:GetDescendants() do
	if d.Parent and safe(d) then
		local c, size = bounds(d)
		local inDecor = d:IsDescendantOf(art) or d:IsDescendantOf(zones)
		local individual = d:IsA("Model") or d:IsA("BasePart")
		local delete = hidden[d.Name] == true
		if c and individual and inDecor then
			local lane = c.Z >= state[1].z and isProp(d.Name)
			local ring = math.abs((V(c.X, 0, c.Z) - V(hubX, 0, hubZ)).Magnitude - 39) < 4
				and size.Y < 5
				and isProp(d.Name)
			local wp = d.Parent.Name == "WallProps"
			local middle = wp and math.abs(c.Z - 65) < 12
			local corner = wp
				and (d.Name:lower():find("grave") or d.Name:lower():find("post_lantern"))
			local outside = (c.Z < state[1].z and (c.X < hubX - 170 or c.X > hubX + 170))
				or (c.Z >= state[1].z and (c.X < state[1].x - 60 or c.X > state[1].x + 60))
			delete = delete or lane or ring or middle or corner or (outside and isProp(d.Name))
			if
				(d.Name == "Glass" or d.Name == "WarmGlass") and d:FindFirstAncestor("WallLanterns")
			then
				delete = true
			end
		end
		if delete then
			cut(d)
		end
	end
	chunk(i)
end
local root = Instance.new("Folder")
root.Name, root.Parent = "WorldPlan", art
root:SetAttribute("WorldPlanOwned", true)
local function group(parent, name)
	local m = Instance.new("Model")
	m.Name, m.Parent = name, parent
	return m
end
local function block(m, name, size, at, color, neon)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, CFrame.new(at)
	p.Color, p.Material = hex(color), neon and Enum.Material.Neon or Enum.Material.Plastic
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface = neon and Enum.SurfaceType.Smooth or Enum.SurfaceType.Studs
	p.Parent = m
	return p
end
local function light(p, color, range)
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Parent = hex(color), 1, range or 12, p
end
local function pumpkin(m, at, h, jack)
	block(m, "Pumpkin", V(h, h * 0.8, h * 0.85), at + V(0, h * 0.4, 0), "FF8A1F")
	block(m, "Stem", V(h * 0.18, h * 0.2, h * 0.18), at + V(0, h * 0.9, 0), "6FAE60")
	if jack then
		for _, x in { -0.22, 0.22 } do
			block(
				m,
				"Eye",
				V(h * 0.15, h * 0.14, 0.15),
				at + V(x * h, h * 0.5, -h * 0.43),
				"FFC83D",
				true
			)
		end
		block(m, "Smile", V(h * 0.5, h * 0.1, 0.15), at + V(0, h * 0.25, -h * 0.43), "FFC83D", true)
	end
end
local function lamp(m, at, h, color, lit)
	block(m, "Post", V(0.7, h - 2, 0.7), at + V(0, (h - 2) / 2, 0), "6B4430")
	local p = block(m, "Lantern", V(2, 2, 2), at + V(0, h - 1, 0), color or "FFC83D", true)
	if lit then
		light(p, color or "FFC83D")
	end
end
local function bale(m, at)
	block(m, "Hay", V(5, 3, 3), at + V(0, 1.5, 0), "E8D27A")
	for _, x in { -1.5, 1.5 } do
		block(m, "Tie", V(0.3, 3.1, 3.1), at + V(x, 1.5, 0), "6B4430")
	end
end
local function tree(m, at, h, pine)
	block(m, "Trunk", V(2, h, 2), at + V(0, h / 2, 0), "8A5A34")
	for j = 1, 3 do
		local p = block(
			m,
			"Branch",
			V(7 - j, h * 0.08, 1.4),
			at + V((j % 2 == 0 and -1 or 1) * 2, h * (0.35 + j * 0.15), 0),
			"8A5A34"
		)
		p.CFrame *= CFrame.Angles(0, 0, math.rad(j % 2 == 0 and -25 or 25))
	end
	if pine then
		for j = 1, 3 do
			block(m, "Crown", V(9 - j * 2, 3, 9 - j * 2), at + V(0, h - 8 + j * 2, 0), "6FAE60")
		end
	end
end
local function mushrooms(m, at, color)
	for j = 1, 3 do
		local q = at + V((j - 2) * 2, 0, j % 2 * 2)
		block(m, "Stem", V(1, 2 + j * 0.5, 1), q + V(0, 1 + j * 0.25, 0), "FFF8EC")
		block(m, "Cap", V(2.5, 1, 2.5), q + V(0, 2.5 + j * 0.5, 0), color)
		block(m, "Dot", V(0.6, 0.2, 0.6), q + V(0.5, 3.1 + j * 0.5, 0), "FFF8EC")
	end
end
local function candle(m, at, h)
	block(m, "Stand", V(0.8, h - 1, 0.8), at + V(0, (h - 1) / 2, 0), "3B2766")
	block(m, "Arms", V(4, 0.6, 1), at + V(0, h - 2, 0), "B07A4A")
	for _, x in { -1.5, 0, 1.5 } do
		block(m, "Flame", V(0.6, 1, 0.6), at + V(x, h - 0.5, 0), "FFC83D", true)
	end
end
local function banner(m, at, h, color)
	block(m, "Pole", V(0.6, h, 0.6), at + V(0, h / 2, 0), "B07A4A")
	block(m, "Cloth", V(5, h * 0.4, 0.4), at + V(2, h * 0.75, 0), color)
end
local palette = { "FF8A1F", "FFC83D", "FFC83D", "9EF0C8", "FFC83D", "FF5FA8", "FFC83D" }
local heights = { 28, 30, 34, 34, 38, 38, 44 }
local heroNames =
	{ "HayTower", "Crypt", "ElderTree", "GiantCauldron", "GateTower", "CakeTower", "Throne" }
local function buildHero(m, n)
	local h = heights[n]
	if n == 1 then
		for j, w in { 20, 14, 8 } do
			block(m, "HayTier", V(w, 6, w), V(0, (j - 1) * 6 + 3, 0), "E8D27A")
			for _, x in { -w * 0.3, w * 0.3 } do
				block(m, "Tie", V(0.5, 6.1, w + 0.1), V(x, (j - 1) * 6 + 3, 0), "6B4430")
			end
		end
		pumpkin(m, V(0, 18, 0), 6, true)
		block(m, "CrowPole", V(0.5, 6, 0.5), V(0, 25, 0), "6B4430")
		block(m, "Crow", V(3, 1, 2), V(0, 27.5, 0), "3B2766")
	elseif n == 2 then
		block(m, "CryptBody", V(18, 24, 18), V(0, 12, 0), "8E7FC4")
		block(m, "Roof", V(20, 6, 20), V(0, 27, 0), "D7CDEB")
		block(m, "Door", V(7, 12, 0.5), V(0, 6, -9.3), "3B2766")
		block(m, "Window", V(4, 4, 0.5), V(0, 19, -9.4), "FFC83D", true)
	elseif n == 3 then
		tree(m, V(0, 0, 0), h, false)
		for _, x in { -2, 2 } do
			block(m, "CarvedEye", V(2, 3, 0.4), V(x, 22, -1.2), "FFC83D", true)
		end
		for j = 1, 3 do
			block(m, "Root", V(10, 1, 2), V(0, 0.5, (j - 2) * 3), "8A5A34")
		end
	elseif n == 4 then
		block(m, "Pot", V(20, 23, 20), V(0, 15, 0), "3B2766")
		for _, x in { -7, 7 } do
			block(m, "Leg", V(3, 5, 3), V(x, 2.5, 0), "B07A4A")
		end
		block(m, "Rim", V(22, 3, 22), V(0, 27, 0), "7A4FD0")
		light(block(m, "Brew", V(18, 0.3, 18), V(0, 28.6, 0), "78E580", true), "78E580", 24)
		for j = 1, 7 do
			block(m, "LadderRung", V(5, 0.5, 1), V(0, j * 4, -11), "B07A4A")
		end
		for _, x in { -2.5, 2.5 } do
			block(m, "LadderRail", V(0.6, 34, 0.6), V(x, 17, -11), "B07A4A")
		end
	elseif n == 5 then
		for _, x in { -5.5, 5.5 } do
			block(m, "Tower", V(9, 34, 14), V(x, 17, 0), "A8406A")
			for _, dx in { -3, 0, 3 } do
				block(m, "Crenel", V(2, 4, 14), V(x + dx, 36, 0), "B8507A")
			end
			block(m, "Window", V(3, 7, 0.4), V(x, 24, -7.3), "FFE08A")
		end
		block(m, "Bridge", V(20, 4, 8), V(0, 16, 0), "3B2766")
		banner(m, V(0, 17, -7.5), 14, "FF8A1F")
		block(m, "BatWings", V(4, 0.7, 0.5), V(2, 28, -8), "3B2766")
	elseif n == 6 then
		for j, w in { 16, 12, 8 } do
			block(
				m,
				"Cake",
				V(w, 8, w),
				V(0, 4 + (j - 1) * 10, 0),
				({ "F4C4DE", "FFF8EC", "C79BEA" })[j]
			)
			block(m, "Icing", V(w + 0.5, 2, w + 0.5), V(0, 9 + (j - 1) * 10, 0), "FFF8EC")
		end
		block(m, "Cherry", V(6, 6, 6), V(0, 33, 0), "FF5FA8")
		block(m, "CherryStem", V(0.7, 2, 0.7), V(0, 37, 0), "9EF0C8")
	else
		for j, w in { 24, 18, 12 } do
			block(
				m,
				"Dais",
				V(w, 3, w),
				V(0, (j - 1) * 3 + 1.5, 0),
				({ "3B2766", "4A2D7A", "5A3A8E" })[j]
			)
		end
		block(m, "ThroneBack", V(18, 32, 5), V(0, 25, 5), "FF8A1F")
		block(m, "Seat", V(14, 4, 10), V(0, 12, -1), "7A4FD0")
		for _, x in { -8, 8 } do
			block(m, "Arm", V(3, 8, 12), V(x, 15, -1), "FFC83D")
		end
		for _, x in { -4, 4 } do
			block(m, "CarvedEye", V(3, 4, 0.4), V(x, 32, 2.3), "FFC83D", true)
		end
		block(m, "Crown", V(12, 3, 4), V(0, 42.5, 5), "FFC83D")
	end
end
-- Place whole AABBs inside bands. Spawn footprints +4 always win. Planned
-- coordinates are offsets from measured gates, not assumed world locations.
local occupied = {}
local function place(m, s, x, z, role)
	local c, size = bounds(m)
	local base = block(m, "AnchorPlate", V(size.X + 2, 2, size.Z + 2), V(c.X, -1, c.Z), "B07A4A")
	if role == "Hero" then
		base.Size *= V(0.7, 1, 0.7)
		base.CanCollide, base.CanQuery = true, true
	end
	c, size = bounds(m)
	local side = x < s.x and -1 or 1
	-- Tall nest pieces live on the wall-facing half. Low framing may reach the
	-- nest edge, but candy canes must never obstruct the central run corridor.
	if role == "Cluster" and size.Y > 5 then
		local nestSide = s.hc.X < s.x and -1 or 1
		x = s.x + nestSide * math.max(math.abs(x - s.x), 33 + size.X / 2)
	end
	if role ~= "FinalHero" and role ~= "Cluster" and role ~= "Ground" then
		local low, high = side == -1 and s.x - 58 or s.x + 33, side == -1 and s.x - 33 or s.x + 58
		x = math.clamp(x, low + size.X / 2, high - size.X / 2)
	end
	local originalZ = z
	for attempt = 1, 60 do
		local clash = false
		for _, p in s.spawns do
			local pc, ps = bounds(p)
			if
				math.abs(x - pc.X) < (size.X + ps.X) / 2 + 4
				and math.abs(z - pc.Z) < (size.Z + ps.Z) / 2 + 4
			then
				clash = true
			end
		end
		for _, o in occupied[s.zone] or {} do
			local gap = role == "Cluster" and 1 or 6
			if
				math.abs(x - o.x) < (size.X + o.size.X) / 2 + gap
				and math.abs(z - o.z) < (size.Z + o.size.Z) / 2 + gap
			then
				clash = true
			end
		end
		if not clash then
			break
		end
		z = originalZ + math.ceil(attempt / 2) * 2 * (attempt % 2 == 1 and 1 or -1)
		if attempt == 60 or z < s.z + 16 or z + size.Z / 2 > s.z + 151 then
			log("SKIPPED blocked " .. m.Name .. "; protected Spawns/spacing win")
			m:Destroy()
			return false
		end
	end
	m:PivotTo(m:GetPivot() + V(x - c.X, s.y + size.Y / 2 - c.Y, z - c.Z))
	m:SetAttribute("Role", role)
	occupied[s.zone] = occupied[s.zone] or {}
	table.insert(occupied[s.zone], { x = x, z = z, size = size })
	added[s.zone.Name] = (added[s.zone.Name] or 0) + 1
	log(s.zone.Name .. " " .. role .. " " .. m.Name .. " actual " .. tostring(bounds(m)))
	return true
end
for n, s in state do
	local folder = Instance.new("Folder", root)
	folder.Name = s.zone.Name
	local heroX = n == 7 and s.x or s.x + (n % 2 == 1 and 56 or -56)
	local heroZ = s.z + (n == 7 and 140 or 136)
	local heroOk = false
	for _, dz in { 0, -24, -48, -72, -96, 12 } do
		local hero = group(folder, heroNames[n])
		buildHero(hero, n)
		-- Local fronts face inward. Z7 faces the arriving player (-Z).
		if n < 7 then
			hero:PivotTo(CFrame.Angles(0, (n % 2 == 1 and -1 or 1) * math.pi / 2, 0) * hero:GetPivot())
		end
		if place(hero, s, heroX, heroZ + dz, n == 7 and "FinalHero" or "Hero") then
			heroOk = true
			break
		end
	end
	if not heroOk then
		warn("[WorldPlan] Hero could not be placed, skipped: " .. heroNames[n])
	end
	local function support(name, x, z, draw)
		local m = group(folder, name)
		draw(m)
		place(m, s, s.x + x, s.z + z, "Support")
	end
	if n > 1 then
		for j, x in { -48, 48 } do
			local m = group(folder, "GatePillar" .. j)
			block(m, "Pillar", V(4, 14, 4), V(0, 7, 0), n == 5 and "A8406A" or "7A4FD0")
			local cap = block(m, "Lantern", V(3, 2, 3), V(0, 15, 0), palette[n], n ~= 6)
			if n == 4 then
				light(cap, "9EF0C8", 12)
			end
			if n == 5 then
				banner(m, V(0, 0, 2), 14, "A8406A")
			end
			place(m, s, s.x + x, s.z + 2, "Apron")
		end
	end
	if n == 1 then
		for j, v in { { -50, 32 }, { 50, 72 } } do
			support("Scarecrow" .. j, v[1], v[2], function(m)
				block(m, "Pole", V(1, 10, 1), V(0, 5, 0), "6B4430")
				block(m, "Arms", V(8, 1, 1), V(0, 7, 0), "B07A4A")
				pumpkin(m, V(0, 8, 0), 3, true)
				block(m, "StrawHat", V(5, 1, 4), V(0, 11.5, 0), "E8D27A")
			end)
		end
		support("BaleStack", -48, 106, function(m)
			bale(m, V(-1, 0, 0))
			bale(m, V(1, 3, 0))
			bale(m, V(0, 6, 0))
		end)
		support("ArrowPost", -44, 50, function(m)
			block(m, "Post", V(0.7, 7, 0.7), V(0, 3.5, 0), "6B4430")
			block(m, "Arrow", V(4, 1, 1), V(0, 6, 0), "FFC83D")
		end)
	elseif n == 2 then
		for j, v in { { -48, 32 }, { 48, 42 } } do
			support("DeadTree" .. j, v[1], v[2], function(m)
				tree(m, V(0, 0, 0), 16, false)
			end)
		end
		for j = 1, 6 do
			support(
				"Headstone" .. j,
				39 + (j % 2) * 10,
				60 + math.floor((j - 1) / 2) * 15,
				function(m)
					local p = block(m, "Stone", V(4, 6, 1.5), V(0, 3, 0), "D7CDEB")
					p.CFrame *= CFrame.Angles(0, 0, math.rad(4))
					block(m, "Inset", V(2, 3, 0.2), V(0, 3, -0.9), "8E7FC4")
				end
			)
		end
		support("NestFence", 45, 112, function(m)
			for j = -4, 4 do
				block(m, "Picket", V(0.5, 4, 0.5), V(0, 2, j * 2), "3B2766")
			end
			block(m, "Rail", V(0.6, 0.6, 20), V(0, 3, 0), "B07A4A")
		end)
	elseif n == 3 then
		for j = 1, 5 do
			support("TreeLine" .. j, j % 2 == 1 and -48 or 48, 24 + j * 20, function(m)
				tree(m, V(0, 0, 0), 14 + j % 3 * 2, j > 3)
			end)
		end
		for j, v in { { 48, 60 }, { -48, 85 } } do
			support("Mushrooms" .. j, v[1], v[2], function(m)
				mushrooms(m, V(0, 0, 0), "D8433E")
			end)
		end
		support("FallenLog", -48, 28, function(m)
			block(m, "Log", V(3, 3, 10), V(0, 1.5, 0), "8A5A34")
		end)
	elseif n == 4 then
		for j, v in { { -48, 55 }, { 48, 75 }, { 48, 30 } } do
			support("PurpleMushrooms" .. j, v[1], v[2], function(m)
				mushrooms(m, V(0, 0, 0), "7A4FD0")
			end)
		end
	elseif n == 5 then
		for j, z in { 40, 70, 95, 125 } do
			support("Candelabra" .. j, j % 2 == 1 and -48 or 48, z, function(m)
				candle(m, V(0, 0, 0), 6)
			end)
		end
		for j = 1, 3 do
			support("Coffin" .. j, -40, 85 + j * 12, function(m)
				local p = block(m, "Coffin", V(4, 9, 3), V(0, 4.5, 0), "A8406A")
				p.CFrame *= CFrame.Angles(0, 0, math.rad(8))
				block(m, "Lid", V(4, 9, 0.4), V(2, 4.5, -2), "3B2766")
			end)
		end
	elseif n == 6 then
		for j = 1, 3 do
			support("Lollipop" .. j, j % 2 == 1 and 48 or -48, 25 + j * 24, function(m)
				block(m, "Stick", V(1, 10, 1), V(0, 5, 0), "FFF8EC")
				block(m, "Candy", V(8, 8, 2), V(0, 14, 0), "FF5FA8")
				for k = -2, 2 do
					block(m, "Swirl", V(1, 6, 0.3), V(k, 14, -1.2), "FFF8EC")
				end
			end)
		end
		for j = 1, 5 do
			support("Gumdrop" .. j, j % 2 == 1 and -48 or 48, 35 + j * 19, function(m)
				block(
					m,
					"Candy",
					V(4, 3, 4),
					V(0, 1.5, 0),
					({ "9EF0C8", "FF5FA8", "FFC83D" })[j % 3 + 1]
				)
			end)
		end
	else
		for j, v in { { -48, 60 }, { 48, 75 }, { -48, 95 }, { 48, 110 } } do
			support("Brazier" .. j, v[1], v[2], function(m)
				lamp(m, V(0, 0, 0), 7, "FFC83D", j < 3)
			end)
		end
		for _, x in { -48, 48 } do
			support("BannerWall" .. x, x, 120, function(m)
				banner(m, V(0, 0, 0), 18, "7A4FD0")
			end)
		end
		for _, x in { -30, 30 } do
			support("Obelisk" .. x, x, 140, function(m)
				block(m, "Obelisk", V(5, 24, 5), V(0, 12, 0), "5A3A8E")
				block(m, "GoldCap", V(5, 2, 5), V(0, 23, 0), "FFC83D")
			end)
		end
	end
	-- Nest frames follow the actual Hoard. Gate-facing arc is deliberately open.
	local count = n == 3 and 6 or (n == 6 or n == 7) and 8 or n == 4 and 5 or 3
	for j = 1, count do
		local theta = math.rad(-120 + (j - 1) * 240 / math.max(count - 1, 1))
		local x, z = s.hc.X + math.sin(theta) * 11, s.hc.Z + math.cos(theta) * 11
		local m = group(folder, "NestFrame" .. j)
		if n == 1 then
			bale(m, V(0, 0, 0))
		elseif n == 2 then
			candle(m, V(0, 0, 0), 3)
			block(m, "Skull", V(2, 2, 2), V(0, 1, 0), "FFF8EC")
		elseif n == 3 then
			block(m, "Stump", V(2, 2, 2), V(0, 1, 0), "8A5A34")
		elseif n == 4 then
			block(m, "LilyPad", V(6, 0.2, 6), V(0, 0.1, 0), "3A8F4E")
		elseif n == 5 then
			candle(m, V(0, 0, 0), 4)
		elseif n == 6 then
			block(m, "Cane", V(1, 8, 1), V(0, 4, 0), "FFF8EC")
			for k = 1, 4 do
				block(m, "Stripe", V(1.1, 0.8, 1.1), V(0, k * 1.5, 0), "FF5FA8")
			end
			block(m, "Hook", V(3, 1, 1), V(1, 7.5, 0), "FFF8EC")
		else
			pumpkin(m, V(0, 1, 0), 3, true)
			block(m, "Post", V(1, 1, 1), V(0, 0.5, 0), "F6E8CC")
		end
		place(m, s, x, z, "Cluster")
	end
	local detail = group(folder, "NestDetail")
	if n == 1 then
		block(detail, "Crate", V(3, 3, 3), V(0, 1.5, 0), "B07A4A")
		for _, y in { 0.5, 2.5 } do
			block(detail, "Brace", V(3.1, 0.3, 3.1), V(0, y, 0), "6B4430")
		end
	elseif n == 2 or n == 7 then
		for j = 1, 3 do
			block(
				detail,
				n == 7 and "Skull" or "Bone",
				n == 7 and V(2, 2, 2) or V(3, 0.6, 0.6),
				V((j - 2) * 1.5, 1, j % 2),
				"FFF8EC"
			)
			if n == 7 then
				block(
					detail,
					"Socket",
					V(0.4, 0.4, 0.2),
					V((j - 2) * 1.5, 1, -0.1 + j % 2),
					"3B2766"
				)
			end
		end
	elseif n == 3 then
		mushrooms(detail, V(0, 0, 0), "D8433E")
	else
		detail:Destroy()
		detail = nil
	end
	if detail then
		place(detail, s, s.hc.X, s.hc.Z + 12, "Cluster")
	end
	if n == 1 or n == 4 or n == 5 then
		local m = group(folder, "NestGround")
		if n == 1 then
			for j = 1, 12 do
				local a = j * math.pi / 6
				block(
					m,
					"StrawRim",
					V(2, 0.2, 1),
					V(math.sin(a) * 4, 0.1, math.cos(a) * 4),
					"E2C066"
				)
			end
		elseif n == 4 then
			block(m, "Pond", V(26, 0.1, 26), V(0, 0.05, 0), "A8D8C0")
		else
			block(m, "Carpet", V(6, 0.1, 24), V(0, 0.05, 0), "A8406A")
		end
		-- Ground plates are under the existing nest and never move it.
		m:PivotTo(m:GetPivot() + V(s.hc.X, s.y, s.hc.Z))
	end
	for _, z in { 22, 148 } do
		local m = group(folder, "Chevron" .. z)
		for _, dx in { -1, 1 } do
			local p = block(m, "Arrow", V(3, 0.05, 1), V(s.x + dx, s.y + 0.05, s.z + z), palette[n])
			p.CFrame *= CFrame.Angles(0, dx * math.pi / 4, 0)
		end
	end
	task.wait()
end
local hub = Instance.new("Folder", root)
hub.Name = "Hub"
local function hubModel(name, at, draw)
	local m = group(hub, name)
	draw(m)
	local c, size = bounds(m)
	block(m, "AnchorPlate", V(size.X + 2, 0.2, size.Z + 2), V(c.X, -0.1, c.Z), "B07A4A")
	m:PivotTo(m:GetPivot() + at)
	added.Hub = (added.Hub or 0) + 1
	return m
end
for _, v in { { 0, -40 }, { 40, 0 }, { 0, 40 }, { -40, 0 } } do
	hubModel("CardinalJack", V(hubX + v[1], hubY, hubZ + v[2]), function(m)
		block(m, "Post", V(3, 3, 3), V(0, 1.5, 0), "F6E8CC")
		pumpkin(m, V(0, 3, 0), 6, true)
	end)
end
for _, dx in { -50, 50 } do
	hubModel("LaneBanner", V(state[1].x + dx, hubY, state[1].z - 6), function(m)
		banner(m, V(0, 0, 0), 16, "FF8A1F")
	end)
end
for _, v in { { -160, -63 }, { 160, -63 }, { -160, 135 }, { 160, 135 } } do
	hubModel("HarvestCorner", V(hubX + v[1], hubY, v[2] + (spawn.Position.Z - 130)), function(m)
		bale(m, V(0, 0, -4))
		pumpkin(m, V(-4, 0, 0), 2.5, false)
		pumpkin(m, V(4, 0, 0), 3.5, false)
		lamp(m, V(0, 0, 5), 7, "FFC83D", false)
	end)
end
local moon = block(hub, "PumpkinMoon", V(44, 44, 2), V(hubX, hubY + 40, hubZ - 113), "FFE9B0")
moon.Shape = Enum.PartType.Cylinder
moon.Size = V(2, 44, 44)
moon.CFrame = CFrame.new(moon.Position) * CFrame.Angles(0, math.pi / 2, 0)
local up = block(hub, "KingUplight", V(1, 0.2, 1), V(hubX, hubY + 0.1, hubZ), "FFB060")
up.Transparency = 1
light(up, "FFB060", 40)
-- Pen gate lamps follow the existing Soil orientation (its -Z axis is the
-- authored front); board faces its spur, never a guessed world direction.
for i, pen in patches:GetChildren() do
	local soil = pen:FindFirstChild("Soil")
	if soil and soil:IsA("BasePart") then
		local front = soil.CFrame.LookVector
		local centre = soil.Position + front * (soil.Size.Z / 2 + 1)
		local right = soil.CFrame.RightVector
		for _, dx in { -6, 6 } do
			hubModel(
				pen.Name .. "GateJack" .. dx,
				V(centre.X + right.X * dx, hubY, centre.Z + right.Z * dx),
				function(m)
					block(m, "Post", V(0.6, 3, 0.6), V(0, 1.5, 0), "B07A4A")
					pumpkin(m, V(0, 3, 0), 1.2, true)
				end
			)
		end
		local sign = pen:FindFirstChild("SignPost")
		local boardPart = sign and sign:FindFirstChild("Board")
		if boardPart and boardPart:IsA("BasePart") then
			boardPart.CFrame = CFrame.lookAt(
				V(boardPart.Position.X, hubY + 7.5, boardPart.Position.Z),
				V(boardPart.Position.X, hubY + 7.5, boardPart.Position.Z) + front
			)
		end
	end
	chunk(i)
end
-- Move original lanterns using their read positions; don't duplicate them.
for _, d in art:GetDescendants() do
	if d:IsA("Model") and not d:IsDescendantOf(root) and d.Name:lower():find("post_lantern") then
		local c, size = bounds(d)
		if
			c
			and math.abs(math.abs(c.X - hubX) - 10) < 2
			and c.Z > spawn.Position.Z - 25
			and c.Z < spawn.Position.Z + 15
		then
			local target = V(hubX + math.sign(c.X - hubX) * 15, c.Y, c.Z)
			d:PivotTo(d:GetPivot() + target - c)
			log("Spawn lantern " .. tostring(c) .. " -> " .. tostring(target))
		end
	end
end
local signsMoved = 0
local function movePart(p, target)
	log(p:GetFullName() .. " " .. tostring(p.Position) .. " -> " .. tostring(target))
	p.Position = target
end
for _, spec in { { "Seeds", -88, 118 }, { "Upgrades", -88, 84 }, { "Sell", 88, 118 } } do
	local stall = market:FindFirstChild(spec[1])
	if stall and stall:IsA("Model") then
		local c, size = bounds(stall, true)
		local target = V(hubX + spec[2], hubY + size.Y / 2, spawn.Position.Z + spec[3] - 130)
		local delta = target - c
		if math.abs(c.X - target.X) > 2 or math.abs(c.Z - target.Z) > 2 then
			stall:PivotTo(stall:GetPivot() + delta)
			-- LaunchLook2's pad/title/SELL cauldron live outside the stall.
			for _, d in art:GetDescendants() do
				if
					d:IsA("BasePart")
					and not d:IsDescendantOf(root)
					and not d:IsDescendantOf(stall)
					and (d.Name == "StationTitle" or d.Name == "SellCauldron" or d.Name == "CauldronGoo" or d.Name:match(
						"Pad$"
					))
					and (V(d.Position.X, 0, d.Position.Z) - V(c.X, 0, c.Z)).Magnitude < 20
				then
					d.CFrame += delta
				end
			end
		end
		local prompt = stall:FindFirstChild("PromptPart", true)
		if prompt and prompt:IsA("BasePart") then
			movePart(
				prompt,
				V(target.X - math.sign(spec[2]) * (size.X / 2 + 2), hubY + 3, target.Z)
			)
		end
		hubModel(
			spec[1] .. "Backdrop",
			V(target.X + math.sign(spec[2]) * 8, hubY, target.Z + 6),
			function(m)
				bale(m, V(0, 0, 0))
				pumpkin(m, V(0, 3, 0), 3, false)
			end
		)
	end
end
local board = market:FindFirstChild("LifetimeBoard")
if board and board:IsA("BasePart") then
	movePart(board, V(hubX + 88, hubY + board.Size.Y / 2, spawn.Position.Z - 46))
end
for _, s in state do
	local wall = s.zone:FindFirstChild("GateWall")
	if wall and wall:IsA("BasePart") and wall.Size.Y > 20 then
		wall.Size = V(wall.Size.X, 14, wall.Size.Z)
		wall.Position = V(wall.Position.X, s.y + 7, wall.Position.Z)
	end
	local sign = s.zone:FindFirstChild("GateSign")
	if sign and sign:IsA("BasePart") then
		movePart(sign, V(s.x, s.y + 22, s.z - 3))
		signsMoved += 1
	end
end
-- Billboard bottom, not just centre, clears intersecting geometry. Offsets are
-- world-space; never reuse camera-relative StudsOffset to measure clearance.
local accepted = {}
local geometry = {}
for _, p in garden:GetDescendants() do
	if p:IsA("BasePart") and p.Transparency < 1 then
		table.insert(geometry, p)
	end
end
for i, bb in garden:GetDescendants() do
	if bb:IsA("BillboardGui") and bb.Enabled then
		local anchor = bb.Adornee or bb.Parent
		local pos = anchor:IsA("Attachment") and anchor.WorldPosition
			or anchor:IsA("BasePart") and anchor.Position
		if pos then
			local text = ""
			for _, t in bb:GetDescendants() do
				if t:IsA("TextLabel") then
					text ..= " " .. t.Text
				end
			end
			local gate = bb.Name == "GateGui" or anchor.Name == "GateSign"
			local station = anchor.Name == "StationTitle"
				or text:find("SHOP")
				or text:find("SELL")
				or text:find("UPGRADES")
			local kingTitle = text:find("PUMPKIN KING") ~= nil
			local pen = bb.Name == "OwnerSign" or anchor.Name == "SignPost"
			local wild = anchor:FindFirstAncestor("WildPumpkins")
				or anchor:FindFirstAncestor("Wild")
			local referencedTag = bb.Name == "HpBar"
				or bb.Name == "CarveTag"
				or bb.Name == "MysteryTag"
			if
				wild
				and not referencedTag
				and not text:find("Golden")
				and not text:find("Big")
				and safe(bb)
			then
				bb:Destroy()
			else
				local model = anchor:FindFirstAncestorOfClass("Model") or anchor
				local _, _, _, top = bounds(model)
				local y = (top and top.Y or pos.Y) + (kingTitle and 6 or 2)
				local half = kingTitle and 1.5 or station and 3 or gate and 5 or 1.5
				if kingTitle then
					local _, _, _, kt = bounds(king)
					y = kt.Y + 6 + half
				elseif gate then
					y = math.max(pos.Y, y)
				elseif station then
					y = math.max(hubY + 24, y)
				elseif pen then
					y = math.max(hubY + 10.7, y)
				end
				for _, p in geometry do
					local pc, ps, _, pt = bounds(p)
					if
						math.abs(pos.X - pc.X) <= ps.X / 2 + 1
						and math.abs(pos.Z - pc.Z) <= ps.Z / 2 + 1
					then
						y = math.max(y, pt.Y + 2 + half)
					end
				end
				for _, other in accepted do
					if
						(V(pos.X, 0, pos.Z) - V(other.x, 0, other.z)).Magnitude < 8
						and math.abs(y - other.y) < half + other.half + 2
					then
						y = other.y + half + other.half + 2
					end
				end
				bb.StudsOffset, bb.StudsOffsetWorldSpace = Vector3.zero, V(0, y - pos.Y, 0)
				bb.ExtentsOffset, bb.ExtentsOffsetWorldSpace = Vector3.zero, Vector3.zero
				bb.AlwaysOnTop = false
				bb.MaxDistance = kingTitle and 200
					or station and 120
					or gate and 90
					or pen and 90
					or 60
				if kingTitle then
					bb.Size = UDim2.fromScale(16, 3)
				elseif station then
					bb.Size = UDim2.fromScale(32, 6)
				end
				if gate then
					for _, t in bb:GetDescendants() do
						if
							t:IsA("TextLabel")
							and (t.Name == "Benefit" or t.Text:lower():find("new pets"))
						then
							t.Text = ""
						end
					end
				end
				signsMoved += 1
				table.insert(accepted, { x = pos.X, z = pos.Z, y = y, half = half })
				log("Billboard " .. bb:GetFullName() .. " centre " .. tostring(V(pos.X, y, pos.Z)))
			end
		end
	end
	if bb:IsA("ProximityPrompt") then
		bb.MaxActivationDistance = bb.Name == "UnlockPrompt" and 12 or 8
		bb.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
		if bb.Name == "UnlockPrompt" then
			bb.ActionText = "Unlock"
		end
	end
	chunk(i)
end
-- Absolute preset: reruns never compound the darkening. -0.27 EV is ~17%
-- less linear exposure (2^-0.27), not a measured screenshot luminance claim.
local function preset(target, values, prefix)
	for key, value in values do
		log(
			"Lighting "
				.. target.Name
				.. "."
				.. key
				.. " "
				.. tostring(target[key])
				.. " -> "
				.. tostring(value)
		)
		target[key] = value
		target:SetAttribute("Base" .. key, value)
		lighting:SetAttribute("Base" .. (prefix or "") .. key, value)
	end
end
preset(lighting, { Brightness = 2.5, ExposureCompensation = -0.27, ClockTime = 16.5 })
for _, d in lighting:GetChildren() do
	if d:IsA("BloomEffect") then
		preset(d, { Intensity = 0.12, Size = 12, Threshold = 1.8 }, "Bloom")
	elseif d:IsA("ColorCorrectionEffect") and d.Name == "PhaseTint" then
		preset(
			d,
			{ Brightness = -0.01, TintColor = hex("FFF3E6"), Saturation = 0.1, Contrast = 0.06 },
			"Grade"
		)
	end
end
for key in protected do
	assert(key.Parent ~= nil, "Contract instance removed: " .. key.Name)
end
local promptPositions = {}
for i, d in garden:GetDescendants() do
	if d:IsA("ProximityPrompt") and d.Enabled then
		local holder = d.Parent
		local pos = holder:IsA("Attachment") and holder.WorldPosition
			or holder:IsA("BasePart") and holder.Position
		if pos then
			for _, old in promptPositions do
				if (old.pos - pos).Magnitude < 14 then
					log("AUDIT prompts <14 studs: " .. old.name .. " / " .. d:GetFullName())
				end
			end
			table.insert(promptPositions, { pos = pos, name = d:GetFullName() })
		end
	end
	chunk(i)
end
for n, s in state do
	local parts, lights = 0, 0
	for _, d in root:FindFirstChild("Zone" .. n):GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			if
				math.abs(d.Position.X - s.x) < 33
				and d.Size.Y > 5
				and not (n == 7 and d.Position.Z > s.z + 125)
			then
				log("AUDIT centre obstruction " .. d:GetFullName())
			end
		elseif d:IsA("PointLight") then
			lights += 1
		end
	end
	local live = 0
	for _, d in s.zone:GetDescendants() do
		if d:IsA("BasePart") then
			live += 1
		end
	end
	log(
		string.format(
			"Zone%d removed %d props; added %d groups / %d parts; live total %d; lights %d",
			n,
			removed["Zone" .. n] or 0,
			added["Zone" .. n] or 0,
			parts,
			live + parts,
			lights
		)
	)
	if live + parts > 250 then
		log("AUDIT Zone" .. n .. " exceeds 250 incl protected gameplay; preserved contracts")
	end
	assert(parts <= 250 and lights <= 6, "Authored zone budget exceeded")
	task.wait()
end
log(
	string.format(
		"Hub removed %d; added %d groups; signs moved %d",
		removed.Hub or 0,
		added.Hub or 0,
		signsMoved
	)
)
local hubParts = 0
for _, d in hub:GetDescendants() do
	if d:IsA("BasePart") then
		hubParts += 1
	end
end
log("Hub authored decor parts " .. hubParts .. " / 600; existing King/retained decor excluded")
assert(hubParts <= 600, "Authored hub budget exceeded")
log(
	"Runtime/1080p visual checks UNKNOWN. Server recreates GateGui / UnlockPrompt; runtime content and distance remain server-owned."
)
return table.concat(report, "\n")
