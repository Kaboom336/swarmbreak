-- v2 numeric contract. +Z is north; all heights are local surface Y.
local Layout = {}
local function point(x, y, z, kind)
	return { x = x, y = y, z = z, kind = kind or "Walk" }
end
function Layout.protected(x, z, radius)
	radius = radius or 0
	-- Pad plus independent eight-stud apron; west extension includes the arch.
	return (math.abs(x) <= 24 + radius and math.abs(z + 58) <= 20 + radius)
		or (x >= -38 - radius and x <= -16 + radius and math.abs(z + 58) <= 16 + radius)
end
function Layout.assemble(config, seed, _fixed)
	assert(type(seed) == "number" and seed % 1 == 0 and seed > 0, "positive integer seed")
	local l = {
		seed = seed,
		pieces = {},
		solids = {},
		ramps = {},
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
	chunk("I04", -40, 12)
	chunk("I03", 40, 12)
	chunk("I06", -32, -28)
	local function box(name, x, y, z, w, h, d, role)
		table.insert(l.solids, { name = name, x = x, y = y, z = z, w = w, h = h, d = d, role = role or "Floor" })
	end
	local function ramp(name, a, b, width)
		table.insert(l.ramps, { name = name, a = a, b = b, width = width })
	end
	-- Opposing switchback runs stay within the 40x40 hill envelopes.
	for _, hill in { { -40, 10, "Mountain" }, { 40, 8, "GroveHill" } } do
		local x, h, name = hill[1], hill[2], hill[3]
		local direction = x < 0 and 1 or -1
		ramp(name .. "SouthRamp", point(x - direction * 20, 0, 0), point(x + direction * 8, h, 0), 12)
		ramp(name .. "NorthRamp", point(x + direction * 20, 4, 24), point(x - direction * 8, h, 24), 12)
		-- Clip the inner south corner so cover and hillside leave a body-clear bypass.
		box(name .. "LandingS", x + direction * 12, h / 2, 0, 8, h, 12)
		box(name .. "LandingSCorner", x + direction * 14, h / 2, 12, 12, h, 12)
		box(name .. "LandingN", x - direction * 14, h / 2, 18, 12, h, 24)
		box(name .. "Summit", x, h / 2, 12, 16, h, 12)
	end
	box("CampTerrace", 0, 2, 32, 40, 4, 40)
	ramp("CampSouthRamp", point(-4, 0, 0), point(-4, 4, 12), 16)
	ramp("CampNorthRamp", point(0, 0, 64), point(0, 4, 52), 16)
	box("CoverWest", -10, 4, -10, 8, 8, 12, "Cover")
	box("CoverEast", 10, 3, 8, 8, 6, 12, "Cover")
	l.routes.Quick = {
		point(0, 0, -58),
		point(0, 0, -22),
		point(0, 0, -2),
		point(-4, 0, 0),
		point(-4, 4, 12, "ClimbRamp"),
		point(0, 4, 32),
	}
	for _, side in { -1, 1 } do
		l.routes[side < 0 and "Ridge" or "Grove"] = {
			point(side * 16, 0, -58),
			point(side * 24, 0, -44),
			point(side * 24, 0, -24),
			point(side * 24, 0, -18),
			point(side * 16.5, 0, -2),
			point(-4, 0, 0),
			point(-4, 4, 12, "ClimbRamp"),
			point(-4, 4, 18),
			point(side * 8, 4, 18),
			point(0, 4, 32),
		}
	end
	table.insert(l.routes.Grove, 5, point(16, 0, -12))
	table.insert(l.routes.Grove, 7, point(0, 0, -2))
	-- Ridge uses the ground bypass east of the recovery cutout.
	l.routes.Ridge = {
		point(-16, 0, -58),
		point(-10, 0, -44),
		point(-10, 0, -24),
		point(0, 0, -24),
		point(0, 0, -2),
		point(-4, 0, 0),
		point(-4, 4, 12, "ClimbRamp"),
		point(-4, 4, 18),
		point(-8, 4, 18),
		point(0, 4, 32),
	}
	-- Lower link detours six studs south of the cover so its full width is clear.
	l.crossLinks = {
		{ point(-10, 0, -24), point(0, 0, -24), point(0, 0, -18), point(24, 0, -18) },
		{ point(-8, 4, 18), point(0, 4, 18), point(8, 4, 18) },
	}
	l.gullies = { { x = -32, z = -28, w = 32, d = 24 } }
	box("RecoveryFloor", -32, -5, -28, 32, 4, 24)
	-- Bent stone chain fits the stated 32x24 footprint: edge gaps 4 then 6.
	box("JumpStart", -55, -1, -34, 12, 2, 12)
	box("Stone1", -43, -1, -34, 8, 4, 8)
	box("Stone2", -31, -0.5, -34, 8, 5, 8)
	box("Stone3", -25, 0, -20, 8, 6, 8)
	box("JumpLanding", -25, -1, -10, 12, 2, 12)
	ramp("RecoveryWest", point(-40, -3, -24), point(-48, 0, -24), 12)
	ramp("RecoveryEast", point(-23.5, -3, -32), point(-16, 0, -32), 12)
	l.jumps = {
		{ from = point(-43, 1, -34), to = point(-31, 2, -34, "Jump"), gap = 4 },
		{ from = point(-31, 2, -34), to = point(-25, 3, -20, "Jump"), gap = 6 },
	}
	-- Open rock cutbacks: twelve-stud through passages, no interior.
	box("CutbackRockA", 38, 4, -18, 8, 8, 8, "Cover")
	box("CutbackRockB", 38, 3, -38, 8, 6, 8, "Cover")
	box("CutbackRockC", 62, 4, -26, 8, 8, 8, "Cover")
	box("CutbackRockD", 62, 3, -46, 8, 6, 8, "Cover")
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
function Layout.loopCarrySteps(_l)
	local steps = {}
	local function add(name, x, y, z, kind)
		local p = point(x, y, z, kind)
		p.name = name
		table.insert(steps, p)
		return p
	end
	add("south terrace", -4, 4, 16)
	add("camp ramp lip", -4, 4, 12)
	add("camp descent", -4, 0, 0, "Dodge")
	add("west approach", -16.5, 0, 0)
	add("west corner clearance", -18, 0, -6)
	add("hill bypass south", -18, 0, -10)
	add("hill bypass west", -64, 0, -10)
	add("hill west turn", -64, 0, 0)
	add("hill foot", -60, 0, 0)
	add("hill south ramp", -32, 10, 0, "ClimbRamp")
	add("hill south landing", -28, 10, 0)
	add("hill summit east", -28, 10, 12)
	add("hill south landing back", -28, 10, 0)
	add("hill ramp back", -32, 10, 0)
	add("hill foot back", -60, 0, 0, "ClimbRamp")
	add("stone west bypass", -64, 0, 0)
	add("stone bypass north", -64, 0, -10)
	add("stone bypass approach", -56, 0, -10)
	add("stone takeoff landing", -55, 0, -34)
	add("first stone", -43, 1, -34, "Jump").takeoff = point(-50.5, 0, -34)
	add("four-stud gap", -31, 2, -34, "Jump").takeoff = point(-39.8, 1, -34)
	add("six-stud gap", -25, 3, -20, "Jump").takeoff = point(-29, 2, -30.5)
	add("stone north landing", -25, 0, -10, "Jump").takeoff = point(-25, 3, -16.8)
	add("east stone clearance", -18, 0, -10)
	add("inner return corner", -18, 0, -6)
	add("inner return turn", -16.5, 0, 0)
	add("centre return lane", 0, 0, 0)
	add("dodge destination", 0, 0, -24)
	add("automatic secure return", 0, 0, -40, "Return")
	return steps
end
function Layout.pvpRoutes()
	return {
		Tester = { point(0, 0, -58), point(-42, 0, -58), point(-62, 0, -56) },
		Dummy = {
			point(0, 4, 32),
			point(-4, 4, 16),
			point(-4, 4, 12),
			point(-4, 0, 0),
			point(-16.5, 0, 0),
			point(-18, 0, -6),
			point(-18, 0, -10),
			point(-64, 0, -10),
			point(-64, 0, -56),
		},
		Pacing = { point(-64, 0, -56), point(-64, 0, -54), point(-64, 0, -56) },
		Mercy = { point(-64, 0, -56), point(-72, 0, -48), point(-64, 0, -56) },
		Leave = { point(-64, 0, -56), point(-68, 0, -52) },
		Winner = { point(-64, 0, -56), point(-42, 0, -56), point(-34, 0, -56) },
	}
end
function Layout.validate(config, l)
	assert(#l.pieces == 5 and #l.crossLinks == 2 and #l.jumps == 2, "required v2 topology")
	local contract = {
		{ "I01", 0, -58 },
		{ "I02", 0, 32 },
		{ "I04", -40, 12 },
		{ "I03", 40, 12 },
		{ "I06", -32, -28 },
	}
	for i, p in l.pieces do
		local c = contract[i]
		local d = assert(config.Pieces[p.id], "unknown chunk")
		assert(p.id == c[1] and p.x == c[2] and p.z == c[3], "v2 fixed landmark")
		assert(p.width == d.width and p.depth == d.depth, "unstretched footprint")
		assert(math.abs(p.x) + p.width / 2 <= 80 and math.abs(p.z) + p.depth / 2 <= 80, "160 envelope")
	end
	for _, r in l.ramps do
		local run = math.sqrt((r.a.x - r.b.x) ^ 2 + (r.a.z - r.b.z) ^ 2)
		assert(r.width >= 12 and math.deg(math.atan(math.abs(r.a.y - r.b.y) / run)) <= 25, "ramp carrying contract")
	end
	for name, route in l.routes do
		local length = Layout.length(route)
		assert(
			length >= (name == "Quick" and 90 or 110) and length <= (name == "Quick" and 105 or 130),
			"route length " .. name .. " " .. length
		)
		for _, p in route do
			assert(p.kind ~= "Jump", "mandatory jump")
		end
	end
	assert(not Layout.protected(0, 12, config.ThrowRadius), "camp protected overlap")
	return true
end
function Layout.signature(l)
	local v = {}
	for _, p in l.pieces do
		table.insert(v, p.id .. ":" .. p.x .. ":" .. p.z)
	end
	return table.concat(v, "|")
end
function Layout.selfTest(config, log)
	for seed = 1, 50 do
		local l = Layout.assemble(config, seed, false)
		Layout.validate(config, l)
		assert(
			Layout.signature(l) == Layout.signature(Layout.assemble(config, seed, true)),
			"v2 landmarks vary by seed"
		)
	end
	log("PASS 50 seeds; fixed v2 contract; measured 3 walking routes; slopes/gaps")
end
return Layout
