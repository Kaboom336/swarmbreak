--!strict
local Config = load("Config")
local Roll = load("Roll")

local function near(actual: number, expected: number, tolerance: number, message: string)
	if math.abs(actual - expected) > tolerance then
		error(string.format("%s: expected %.8f, got %.8f", message, expected, actual), 2)
	end
end

test("simulate is deterministic and stops at the first wall above its power", function()
	local first = Roll.simulate(25, "PumpkinPatch", 8)
	local second = Roll.simulate(25, "PumpkinPatch", 8)
	eq(first.wallsBroken, 2, "broken walls")
	eq(first.physicalWallsBroken, 2, "physical walls")
	eq(first.bonusWalls, 0, "bonus walls")
	eq(first.distance, 3 * Config.WallSpacing, "distance to stopping wall")
	eq(first.stoppedAtWall, 3, "stopping wall")
	eq(first.wallsBroken, second.wallsBroken, "repeat walls")
	eq(first.distance, second.distance, "repeat distance")
	eq(first.wins, second.wins, "repeat wins")
end)

test("simulate keeps counting on the health curve past the physical track", function()
	local expected = {
		{ size = 10, walls = 1 },
		{ size = 100, walls = 5 },
		{ size = 1_000, walls = 10 },
		{ size = 1_200_000, walls = 25 },
	}
	for _, sample in expected do
		local result = Roll.simulate(sample.size, "PumpkinPatch", 10)
		eq(result.wallsBroken, sample.walls, "walls at size " .. sample.size)
		eq(result.bonusWalls, math.max(0, sample.walls - 10), "bonus walls")
	end
end)

test("bonus walls are capped in addition to the physical track", function()
	local result = Roll.simulate(math.huge, "PumpkinPatch", 10)
	eq(result.physicalWallsBroken, 10, "physical walls")
	eq(result.bonusWalls, Config.MaxBonusWalls, "bonus cap")
	eq(result.wallsBroken, 10 + Config.MaxBonusWalls, "total walls")
end)

test("simulated wins include physical and bonus walls for every zone", function()
	for _, zone in Config.Zones do
		local result = Roll.simulate(1_200_000, zone, 10)
		eq(result.wins, 25 * zone.WinMultiplier, zone.Name .. " wins")
	end
end)

test("wall health follows the configured exponential curve", function()
	near(Roll.wallHealth(1), Config.WallBaseHealth, 1e-9, "first wall")
	near(
		Roll.wallHealth(4),
		Config.WallBaseHealth * Config.WallHealthGrowth ^ 3,
		1e-9,
		"fourth wall"
	)
end)

test("wins use walls broken times the zone multiplier", function()
	eq(Roll.winsFor(4, "PumpkinPatch"), 4, "patch wins")
	eq(Roll.winsFor(4, "HauntedForest"), 12, "forest wins")
	eq(Roll.winsFor(4, "Graveyard"), 40, "graveyard wins")
	eq(Roll.winsFor(4, "WitchCastle"), 120, "castle wins")
end)

test("zone unlocks use the exact configured total-wins thresholds", function()
	for _, zone in Config.Zones do
		eq(Roll.isZoneUnlocked(zone.RequiredWins, zone), true, zone.Name .. " at threshold")
		if zone.RequiredWins > 0 then
			eq(
				Roll.isZoneUnlocked(zone.RequiredWins - 1, zone),
				false,
				zone.Name .. " below threshold"
			)
		end
	end
end)

test("roll duration uses size-based speed within playback bounds", function()
	local slow = Roll.duration(500, 10, 0)
	local fast = Roll.duration(1_250, 1_200_000, 15)
	eq(slow <= Config.RollMaxDuration, true, "maximum duration")
	eq(fast >= Config.RollMinDuration, true, "minimum duration")
	eq(fast < slow, true, "larger pumpkin rolls faster")
	eq(fast <= Config.RollMaxDuration + Config.BonusZoneMaxSeconds, true, "bonus duration bound")
end)
