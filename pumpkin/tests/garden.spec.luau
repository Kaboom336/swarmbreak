local Rules = load("GardenRules")
test("garden ready small instantly only when mature, big requires upgrade and time", function()
	local size, ready = Rules.crop(0, 0)
	eq(ready, false)
	eq(size, 0.7)
	eq(select(2, Rules.crop(8, 0)), true)
	eq(Rules.harvestDiameter(100, 0), Rules.SmallDiameter)
	eq(Rules.harvestDiameter(8, 1), Rules.SmallDiameter)
	eq(Rules.harvestDiameter(28, 1), Rules.BigDiameter)
	eq(Rules.charges(Rules.SmallDiameter), 3)
	eq(Rules.charges(Rules.BigDiameter), 5)
end)
test("garden one permanent growth unlock cannot double spend", function()
	local p = { Gold = 59, PumpkinRank = 0 }
	eq(Rules.upgrade(p), false)
	eq(p.Gold, 59)
	p.Gold = 60
	eq(Rules.upgrade(p), true)
	eq(p.Gold, 0)
	eq(p.PumpkinRank, 1)
	p.Gold = 100
	eq(Rules.upgrade(p), false)
	eq(p.Gold, 100)
end)
test("garden chain rejects own old distant or already spent burst", function()
	local a = { owner = 1, time = 10, used = false }
	eq(Rules.chain(a, { owner = 2, time = 12, distance = 10 }), true)
	eq(Rules.chain(a, { owner = 1, time = 12, distance = 10 }), false)
	eq(Rules.chain(a, { owner = 2, time = 9, distance = 10 }), false)
	eq(Rules.chain(a, { owner = 2, time = 13, distance = 10 }), false)
	eq(Rules.chain(a, { owner = 2, time = 12, distance = 19 }), false)
	a.used = true
	eq(Rules.chain(a, { owner = 2, time = 12, distance = 10 }), false)
end)
test("garden swept collision excludes ghosts behind segment", function()
	eq(Rules.segmentDistance(5, 2, 0, 0, 10, 0), 2)
	eq(Rules.segmentDistance(-3, 0, 0, 0, 10, 0), 3)
	eq(Rules.segmentDistance(3, 4, 0, 0, 0, 0), 5)
end)
test(
	"garden movement blocks nonfinite teleport and outside world without rejecting walking",
	function()
		local bounds = { minX = -100, maxX = 100, minZ = -100, maxZ = 100, floorY = 50 }
		local origin = { x = 0, y = 53, z = 0 }
		eq(Rules.movement(origin, { x = 1, y = 53, z = 0 }, 0.05, bounds), true)
		eq(Rules.movement(origin, { x = 12, y = 53, z = 0 }, 0.5, bounds), true)
		eq(Rules.movement(origin, { x = 40, y = 53, z = 0 }, 5, bounds), false)
		eq(Rules.movement(origin, { x = 101, y = 53, z = 0 }, 5, bounds), false)
		eq(Rules.movement(origin, { x = 0 / 0, y = 53, z = 0 }, 0.1, bounds), false)
		eq(Rules.movement(origin, { x = math.huge, y = 53, z = 0 }, 0.1, bounds), false)
		eq(Rules.movement(origin, { x = 0, y = 53, z = 0 }, -1, bounds), false)
	end
)
test("garden harvest matches visible intermediate growth", function()
	local visible = Rules.crop(18, 1)
	eq(Rules.harvestDiameter(18, 1), visible)
	eq(Rules.charges(visible), 3)
end)
test("garden movement allowance cannot be reused for repeated short teleports", function()
	local bounds = { minX = -100, maxX = 100, minZ = -100, maxZ = 100, floorY = 50 }
	local valid, budget = Rules.movement(
		{ x = 0, y = 53, z = 0, budget = 2 },
		{ x = 2, y = 53, z = 0 },
		0.01,
		bounds
	)
	eq(valid, true)
	eq(
		Rules.movement(
			{ x = 2, y = 53, z = 0, budget = budget },
			{ x = 4, y = 53, z = 0 },
			0.01,
			bounds
		),
		false
	)
	eq(Rules.movement({ x = 0, y = 53, z = 0 }, { x = 0.4, y = 54.5, z = 0 }, 0.03, bounds), true)
end)
