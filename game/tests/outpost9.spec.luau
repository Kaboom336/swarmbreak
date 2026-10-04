local ArenaLayout = load("ArenaLayout")

local function overlap(a, b)
	return math.abs(a.x - b.x) * 2 < a.Width + b.Width
		and math.abs(a.z - b.z) * 2 < a.Depth + b.Depth
end

test("Outpost 9 zone bounds do not overlap", function()
	for first = 1, #ArenaLayout.Zones do
		for second = first + 1, #ArenaLayout.Zones do
			assert(
				not overlap(ArenaLayout.Zones[first], ArenaLayout.Zones[second]),
				"zones overlap"
			)
		end
	end
end)

test("every spawn is inside an open zone for its wave", function()
	for wave = 1, 15 do
		local available = ArenaLayout.spawnsForWave(wave)
		assert(#available > 0, "wave " .. wave .. " has no spawns")
		for _, spawn in available do
			assert(
				ArenaLayout.zoneContains(ArenaLayout.zoneForWave(wave), spawn),
				"closed-zone spawn"
			)
		end
	end
end)

test("bridges open at waves 6 and 11", function()
	eq(ArenaLayout.bridgeOpenWave("LandingToRefinery"), 6, "first bridge")
	eq(ArenaLayout.bridgeOpenWave("RefineryToHive"), 11, "second bridge")
	eq(#ArenaLayout.openBridges(5), 0, "wave 5")
	eq(#ArenaLayout.openBridges(6), 1, "wave 6")
	eq(#ArenaLayout.openBridges(11), 2, "wave 11")
end)

test("walkable grid is exposed", function()
	assert(ArenaLayout.WalkableGrid.CellSize > 0, "cell size")
	assert(#ArenaLayout.WalkableGrid.Cells > 0, "grid cells")
end)
