-- Scalar collision recipe shared by live construction and offline checks.
local Layout = {}
local function point(x, y, z, kind)
	return { x = x, y = y, z = z, kind = kind or "Walk" }
end
function Layout.protected(x, z, radius)
	radius = radius or 0
	return math.abs(x) <= 24 + radius and z <= -38 + radius and z >= -78 - radius
end
function Layout.assemble(config, seed, fixed)
	assert(type(seed) == "number" and seed % 1 == 0 and seed > 0, "positive integer seed")
	local random = (seed + config.RecipeVersion * 31 + 1009) % 2147483647
	local function nextInt(n)
		random = random * 48271 % 2147483647
		return random % n + 1
	end
	local swap = not fixed and nextInt(2) == 2
	local l = {
		seed = seed,
		pieces = {},
		solids = {},
		ramps = {},
		hides = {},
		sockets = {},
		routes = {},
		crossLinks = {},
		jumps = {},
		gullies = {},
	}
	local function chunk(id, x, z)
		local d = config.Pieces[id]
		table.insert(l.pieces, { id = id, x = x, z = z, width = d.width, depth = d.depth })
	end
	chunk("I01", 0, -58)
	chunk("I02", 0, 32)
	chunk(swap and "I03" or "I04", -48, 12)
	chunk(swap and "I04" or "I03", 48, 12)
	chunk("I06", -40, -30)
	chunk("I08", 0, -22)
	chunk("I09", 40, -30)
	chunk("I10", -40, 52)
	chunk("I11", 40, 64)
	local function box(name, x, y, z, w, h, d, role)
		table.insert(l.solids, { name = name, x = x, y = y, z = z, w = w, h = h, d = d, role = role or "Floor" })
	end
	local function ramp(name, a, b, width)
		table.insert(l.ramps, { name = name, a = a, b = b, width = width })
	end
	for _, p in l.pieces do
		if p.id == "I03" or p.id == "I04" then
			local h = config.Pieces[p.id].height
			ramp(p.id .. "SouthRamp", point(p.x - 20, 0, 0), point(p.x + 8, h, 0), 12)
			ramp(p.id .. "NorthRamp", point(p.x + 20, 0, 24), point(p.x - 8, h, 24), 12)
			box("HillLandingS", p.x + 14, h / 2, 6, 12, h, 24)
			box("HillLandingN", p.x - 14, h / 2, 18, 12, h, 24)
			box("HillSummit", p.x, h / 2, 12, 16, h, 12)
			l.routes[p.x < 0 and "Ridge" or "Grove"] = {
				point(p.x - 26, 0, -44),
				point(p.x - 26, 0, -12),
				point(p.x - 20, 0, 0),
				point(p.x + 8, h, 0, "ClimbRamp"),
				point(p.x + 14, h, 0),
				point(p.x + 14, h, 12),
				point(p.x - 14, h, 12),
				point(p.x - 14, h, 24),
				point(p.x - 8, h, 24),
				point(p.x + 20, 0, 24, "ClimbRamp"),
				point(p.x + 24, 0, 24),
				point(p.x + 24, 0, 34),
				point(p.x < 0 and -24 or 24, 0, 34),
				point(p.x < 0 and -24 or 24, 0, 32),
				point(p.x < 0 and -10 or 10, 4, 32, "ClimbRamp"),
				point(0, 4, 32),
			}
			if p.x < 0 then
				local route = l.routes.Ridge
				while #route > 11 do
					table.remove(route)
				end
				table.insert(route, point(-16, 0, 24))
				table.insert(route, point(-10, 4, 32, "ClimbRamp"))
				table.insert(route, point(0, 4, 32))
			end
		end
	end
	box("CampTerrace", 0, 2, 32, 20, 4, 16)
	ramp("CampSouthRamp", point(0, 0, 12), point(0, 4, 24), 16)
	ramp("CampEastRamp", point(24, 0, 32), point(10, 4, 32), 12)
	ramp("CampWestRamp", point(-16, 0, 24), point(-10, 4, 32), 12)
	local offset = fixed and 0 or (nextInt(3) - 1) * 2
	box("CoverWest", -12, 4, -24 - offset, 8, 8, 12, "Cover")
	box("CoverEast", 12, 3, -26, 8, 6, 12, "Cover")
	box("Landmark", 0, 11, 39, 2, 14, 2, "Cover")
	l.routes.Quick = {
		point(0, 0, -38),
		point(0, 0, -20),
		point(0, 0, 0),
		point(0, 0, 12),
		point(0, 4, 24, "ClimbRamp"),
		point(0, 4, 32),
	}
	l.crossLinks = {
		{
			point(-64, 0, -12),
			point(-18, 0, -12),
			point(-18, 0, 8),
			point(18, 0, 8),
			point(18, 0, -12),
			point(64, 0, -12),
		},
		{
			point(-20, 0, 24),
			point(-16, 0, 24),
			point(-10, 4, 32, "ClimbRamp"),
			point(10, 4, 32),
			point(24, 0, 32, "ClimbRamp"),
			point(64, 0, 34),
		},
	}
	l.gullies = { { x = -40, z = -30, w = 32, d = 24 }, { x = 40, z = 64, w = 36, d = 32 } }
	for i, g in l.gullies do
		box("RecoveryFloor", g.x, -5, g.z, g.w, 4, g.d)
		if i == 1 then
			ramp("RecoverySouth1", point(-32, -3, -40), point(-24, 0, -40), 12)
			ramp("RecoveryNorth1", point(-48, -3, -20), point(-56, 0, -20), 12)
		else
			ramp("RecoverySouth" .. i, point(g.x, -3, g.z - g.d / 2 + 8), point(g.x, 0, g.z - g.d / 2), 12)
			ramp("RecoveryNorth" .. i, point(g.x, -3, g.z + g.d / 2 - 8), point(g.x, 0, g.z + g.d / 2), 12)
		end
	end
	box("JumpStart", -52, -1, -42, 12, 2, 12)
	box("Stone1", -52, -1, -28, 8, 4, 8)
	box("Stone2", -38, -0.5, -28, 8, 5, 8)
	box("JumpLanding", -24, 1, -28, 12, 2, 12)
	l.jumps = {
		{ from = point(-52, 0, -36), to = point(-52, 1, -28, "Jump"), gap = 4 },
		{ from = point(-50, 1, -28), to = point(-38, 2, -28, "Jump"), gap = 6 },
	}
	for _, x in { 29, 51 } do
		box("BridgeDeck", x, 1, 64, 12, 2, 20)
		ramp("BridgeSouthRamp" .. x, point(x, 0, 46), point(x, 2, 54), 12)
		ramp("BridgeNorthRamp" .. x, point(x, 0, 80), point(x, 2, 74), 12)
	end
	box("LogSide", 35.5, 4.5, -30, 1, 9, 16, "Cover")
	box("LogSide", 44.5, 4.5, -30, 1, 9, 16, "Cover")
	box("LogRoof", 40, 8.5, -30, 8, 1, 16, "Cover")
	table.insert(l.hides, { x = 40, z = -37.5, w = 4, d = 1, log = true, opening = point(40, 0, -40) })
	for _, x in { -49, -31 } do
		box("BushBack", x, 4, 61, 12, 8, 2, "Cover")
		table.insert(l.hides, { x = x, z = 51, w = 12, d = 12, opening = point(x, 0, 44) })
	end
	for x = -76, 76, 4 do
		for z = -76, 76, 4 do
			if not Layout.protected(x, z) then
				table.insert(l.sockets, point(x, 0, z))
			end
		end
	end
	return l
end
function Layout.length(route)
	local length = 0
	for i = 2, #route do
		local a, b = route[i - 1], route[i]
		length += math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
	end
	return length
end
function Layout.loopCarrySteps(l)
	local steps = {}
	local function add(name, x, y, z, kind)
		local p = point(x, y, z, kind)
		p.name = name
		table.insert(steps, p)
		return p
	end
	-- One escape: camp descent, one stone set, one hill, one dodge, cyan.
	add("camp south terrace", 0, 4, 24)
	add("camp south descent", 0, 0, 12)
	add("central cross-link", 0, 0, 8)
	add("jump set approach", 0, 0, -14)
	add("east takeoff approach", -22, 0, -14)
	add("jump landing entry", -24, 2, -28, "Jump").takeoff = point(-22, 0, -18.5)
	add("4 gap / stepping stone", -38, 2, -28, "Jump").takeoff = point(-28.5, 2, -28)
	add("6 gap / low ledge", -52, 1, -28, "Jump").takeoff = point(-40.8, 2, -28)
	add("stone set west exit", -60, 0, -28, "Jump").takeoff = point(-54.8, 1, -28)
	add("hill lane", -60, 0, -12)
	add("hill approach", -68, 0, -12)
	add("hill foot", -68, 0, 0)
	for i = 4, 10 do
		local p = l.routes.Ridge[i]
		add("carrying ridge " .. i, p.x, p.y, p.z, "ClimbRamp")
	end
	add("hill exit", -24, 0, 24)
	add("west return lane", -22, 0, 8)
	add("throw lane", 0, 0, 8, "Dodge")
	add("dodge destination", 0, 0, -4)
	add("automatic secure return", 0, 0, -40, "Return")
	return steps
end
function Layout.pvpRoutes()
	return {
		Tester = { point(0, 0, -58), point(-30, 0, -58), point(-62, 0, -56) },
		Dummy = {
			point(0, 4, 32),
			point(0, 4, 24),
			point(0, 0, 12),
			point(0, 0, 8),
			point(-20, 0, 8),
			point(-20, 0, -12),
			point(-64, 0, -12),
			point(-64, 0, -56),
		},
		Pacing = { point(-64, 0, -56), point(-64, 0, -54), point(-64, 0, -56) },
		Mercy = { point(-64, 0, -56), point(-72, 0, -48), point(-64, 0, -56) },
		Leave = { point(-64, 0, -56), point(-68, 0, -52) },
		Winner = { point(-64, 0, -56), point(-26, 0, -56), point(-22, 0, -56) },
	}
end
function Layout.validate(config, l)
	assert(#l.pieces == 9 and #l.crossLinks == 2 and #l.jumps == 2, "required recipe topology")
	assert(
		l.pieces[1].id == "I01" and l.pieces[1].z == -58 and l.pieces[2].id == "I02" and l.pieces[2].z == 32,
		"fixed terminals"
	)
	local hills = 0
	for i, p in l.pieces do
		local d = assert(config.Pieces[p.id], "unknown chunk")
		assert(p.width == d.width and p.depth == d.depth, "unstretched chunk")
		assert(
			math.abs(p.x) + p.width / 2 <= config.IslandSize / 2
				and math.abs(p.z) + p.depth / 2 <= config.IslandSize / 2,
			"accepted 160 envelope"
		)
		if p.id == "I03" or p.id == "I04" then
			hills += 1
		end
		for j = 1, i - 1 do
			local q = l.pieces[j]
			assert(
				math.abs(p.x - q.x) >= (p.width + q.width) / 2 or math.abs(p.z - q.z) >= (p.depth + q.depth) / 2,
				"overlapping chunks"
			)
		end
	end
	assert(hills == 2 and #l.hides == 3, "hill/hide requirement")
	for _, r in l.ramps do
		local run = math.sqrt((r.a.x - r.b.x) ^ 2 + (r.a.z - r.b.z) ^ 2)
		assert(r.width >= 12 and math.deg(math.atan(math.abs(r.a.y - r.b.y) / run)) <= 25, "ramp carrying contract")
	end
	for _, route in l.routes do
		assert(#route >= 6 and Layout.length(route) > 70, "connected measured route")
		for _, p in route do
			assert(p.kind ~= "Jump", "mandatory jump")
		end
	end
	for _, j in l.jumps do
		assert(j.gap >= 4 and j.gap <= 6 and j.to.y - j.from.y <= 3, "easy jump contract")
	end
	assert(not Layout.protected(0, 12, config.ThrowRadius), "camp protected overlap")
	return true
end
function Layout.signature(l)
	local v = {}
	for _, p in l.pieces do
		table.insert(v, p.id .. ":" .. p.x .. ":" .. p.z)
	end
	for _, b in l.solids do
		table.insert(v, b.name .. ":" .. b.x .. ":" .. b.z)
	end
	return table.concat(v, "|")
end
function Layout.selfTest(config, log)
	local seen = {}
	for seed = 1, 50 do
		local l = Layout.assemble(config, seed, false)
		Layout.validate(config, l)
		local key = Layout.signature(l)
		assert(key == Layout.signature(Layout.assemble(config, seed, false)), "seed replay")
		seen[key] = true
	end
	local count = 0
	for _ in seen do
		count += 1
	end
	assert(count >= 4, "shuffle variation")
	log(
		"PASS 50 seeds; replay; "
			.. count
			.. " bounded recipes; fixed terminals, chunk nonoverlap, 3 walking routes, slopes/gaps"
	)
end
return Layout
