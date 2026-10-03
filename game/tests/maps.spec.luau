local Enemies = load("Enemies")
local LightingPresets = load("LightingPresets")
local Maps = load("Maps")
local Theme = load("Theme")

test("maps have unique plain English names and valid references", function()
	local names = {}
	for _, map in Maps.All do
		assert(not names[map.Name], map.Name .. " is duplicated")
		names[map.Name] = true
		assert(LightingPresets[map.LightingPreset], map.Name .. " has an invalid lighting preset")
		assert(Enemies.Defs[map.Boss], map.Name .. " has an invalid boss")
		assert(#map.Props > 0, map.Name .. " needs props")
	end

	eq(#Maps.All, 3, "map count")
	assert(names["Station Deck"], "Station Deck is missing")
	assert(names["Hive Caves"], "Hive Caves is missing")
	assert(names["Overgrown Hangar"], "Overgrown Hangar is missing")
end)

test("each map has at least six spawns inside its bounds", function()
	for _, map in Maps.All do
		assert(#map.Spawns >= 6, map.Name .. " needs at least six spawns")
		for index, spawn in map.Spawns do
			assert(math.abs(spawn.x) < map.Bounds.Width / 2, map.Name .. " spawn " .. index .. " x")
			assert(math.abs(spawn.z) < map.Bounds.Depth / 2, map.Name .. " spawn " .. index .. " z")
		end
	end
end)

test("every map floor keeps enemy silhouettes readable", function()
	for _, map in Maps.All do
		for enemyName in Enemies.Defs do
			local body = Theme.Enemy[enemyName].Body
			assert(
				Theme.luminanceContrast(map.FloorColor, body) >= 0.35,
				map.Name .. " hides " .. enemyName
			)
		end
	end
end)

test("map selection defaults to Station Deck", function()
	eq(Maps.DefaultName, "Station Deck", "default map name")
	eq(Maps.get(nil).Name, "Station Deck", "missing map fallback")
	eq(Maps.get("Not A Map").Name, "Station Deck", "invalid map fallback")
	eq(Maps.get("Hive Caves").Name, "Hive Caves", "selected map")
end)
