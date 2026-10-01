local SpawnPicker = load("SpawnPicker")

local portals = {
	{ x = 0, z = 0 },
	{ x = 40, z = 0 },
	{ x = 80, z = 0 },
}

test("no players allows any portal by roll", function()
	eq(SpawnPicker.pick(portals, {}, 0), 1, "first portal")
	eq(SpawnPicker.pick(portals, {}, 0.34), 2, "middle portal")
	eq(SpawnPicker.pick(portals, {}, 0.8), 3, "last portal")
end)

test("a player on a portal excludes it", function()
	local players = { { x = 0, z = 0 } }
	eq(SpawnPicker.pick(portals, players, 0), 2, "first eligible portal")
	eq(SpawnPicker.pick(portals, players, 0.999), 3, "last eligible portal")
end)

test("all blocked portals fall back to the farthest", function()
	local blockedPortals = {
		{ x = 0, z = 0 },
		{ x = 10, z = 0 },
		{ x = 20, z = 0 },
	}
	eq(SpawnPicker.pick(blockedPortals, { { x = 0, z = 0 } }, 0.5), 3, "farthest portal")
end)

test("edge rolls stay in range", function()
	eq(SpawnPicker.pick(portals, {}, 0), 1, "zero roll")
	eq(SpawnPicker.pick(portals, {}, 0.999), #portals, "high roll")
end)

test("an empty portal list errors clearly", function()
	local ok, message = pcall(function()
		SpawnPicker.pick({}, {}, 0)
	end)
	eq(ok, false, "empty list refused")
	assert(tostring(message):find("at least one portal"), tostring(message))
end)
