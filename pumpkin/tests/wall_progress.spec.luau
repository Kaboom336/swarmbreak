--!strict
local WallProgress = load("WallProgress")

test("wall progress reports broken walls and progress to the next wall", function()
	local zero = WallProgress.compute(0, "PumpkinPatch", 10)
	eq(zero.wallsBroken, 0)
	eq(zero.nextWall, 1)
	eq(zero.progress, 0)

	local between = WallProgress.compute(13, "PumpkinPatch", 10)
	eq(between.wallsBroken, 1)
	eq(between.nextWall, 2)
	eq(math.floor(between.progress * 100 + 0.5), 50)
end)

test("wall progress is complete after every configured wall", function()
	local complete = WallProgress.compute(1e9, "PumpkinPatch", 3)
	eq(complete.wallsBroken, 3)
	eq(complete.nextWall, nil)
	eq(complete.progress, 1)
end)
