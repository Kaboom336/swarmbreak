local ArenaLayout = load("ArenaLayout")

local function distance(a, b)
	local dx = a.x - b.x
	local dz = a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

local function onFourStudGrid(value)
	return value % 4 == 0
end

test("Outpost 9 has the specified floor, spawns, bunkers, and ring", function()
	eq(ArenaLayout.Floor, 160, "floor size")
	eq(#ArenaLayout.Spawns, 8, "spawn count")
	eq(#ArenaLayout.Bunkers, 4, "bunker count")
	eq(ArenaLayout.Spawns[1].x, -58, "northwest spawn x")
	eq(ArenaLayout.Spawns[1].z, -58, "northwest spawn z")
	eq(ArenaLayout.Spawns[5].x, 0, "north edge spawn x")
	eq(ArenaLayout.Spawns[5].z, -72, "north edge spawn z")
	eq(ArenaLayout.Bunkers[3].x, 66, "southeast bunker x")
	eq(ArenaLayout.Bunkers[3].z, 66, "southeast bunker z")
	eq(ArenaLayout.Bunkers[3].Width, 20, "bunker width")
	eq(ArenaLayout.Bunkers[3].Height, 6, "bunker height")
	eq(ArenaLayout.Bunkers[3].Depth, 20, "bunker depth")
	eq(ArenaLayout.Ring.OuterDiameter, 44, "ring diameter")
	eq(ArenaLayout.Ring.Height, 5, "ring height")
	eq(ArenaLayout.Ring.Thickness, 3, "ring thickness")
	eq(ArenaLayout.Ring.Gap, 10, "ring gap")
end)

test("free placement positions use the four stud grid", function()
	for i, prop in ArenaLayout.Props do
		assert(onFourStudGrid(prop.x), "prop " .. i .. " x is off grid")
		assert(onFourStudGrid(prop.z), "prop " .. i .. " z is off grid")
	end
	for i, beacon in ArenaLayout.Beacons do
		assert(onFourStudGrid(beacon.x), "beacon " .. i .. " x is off grid")
		assert(onFourStudGrid(beacon.z), "beacon " .. i .. " z is off grid")
	end
end)

test("props are low and leave room around each other and the ring", function()
	eq(#ArenaLayout.Props, 24, "prop cluster count")
	local ringRadius = ArenaLayout.Ring.OuterDiameter / 2
	for i, prop in ArenaLayout.Props do
		assert(prop.Height <= 5, "prop " .. i .. " is too tall")
		local fromCenter = math.sqrt(prop.x * prop.x + prop.z * prop.z)
		assert(fromCenter - ringRadius >= 25, "prop " .. i .. " is too close to the ring")
		for j = i + 1, #ArenaLayout.Props do
			assert(
				distance(prop, ArenaLayout.Props[j]) >= 18,
				"props " .. i .. " and " .. j .. " are too close"
			)
		end
	end
end)

test("spawns clear bunkers and stay inside the walls", function()
	local wall = ArenaLayout.Floor / 2
	for i, spawn in ArenaLayout.Spawns do
		assert(math.abs(spawn.x) < wall, "spawn " .. i .. " x is outside")
		assert(math.abs(spawn.z) < wall, "spawn " .. i .. " z is outside")
		for j, bunker in ArenaLayout.Bunkers do
			assert(distance(spawn, bunker) >= 10, "spawn " .. i .. " is too close to bunker " .. j)
		end
	end
end)

test("solo play area keeps some spawns active", function()
	local half = ArenaLayout.playArea(1) / 2
	local inside = 0
	for _, spawn in ArenaLayout.Spawns do
		if math.abs(spawn.x) <= half and math.abs(spawn.z) <= half then
			inside += 1
		end
	end
	assert(inside > 0, "solo play area needs at least one spawn")
end)

test("play area grows at four players", function()
	eq(ArenaLayout.playArea(1), 120, "solo area")
	eq(ArenaLayout.playArea(3), 120, "three-player area")
	eq(ArenaLayout.playArea(4), 160, "four-player area")
end)
