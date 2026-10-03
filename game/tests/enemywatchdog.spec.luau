local EnemyWatchdog = load("EnemyWatchdog")

test("destroyed enemies are forgotten so the wave can end", function()
	eq(EnemyWatchdog.verdict(false, true, 0, 5, 0, 0), "Forget", "no model")
	eq(EnemyWatchdog.verdict(true, false, 0, 5, 0, 0), "Forget", "no root")
end)

test("fallen or escaped enemies are killed", function()
	eq(EnemyWatchdog.verdict(true, true, 0, -40, 0, 0), "Kill", "fell")
	eq(EnemyWatchdog.verdict(true, true, 300, 5, 0, 0), "Kill", "outside the map")
	eq(EnemyWatchdog.verdict(true, true, 60, 5, 60, 0), "Ok", "inside the arena")
end)

test("wedged enemies respawn after being stuck long enough", function()
	local stuck = 0
	for _ = 1, EnemyWatchdog.StuckSeconds do
		stuck = EnemyWatchdog.nextStuck(stuck, 0.2, true)
	end
	eq(EnemyWatchdog.verdict(true, true, 0, 5, 0, stuck), "Respawn", "stuck")
	eq(EnemyWatchdog.nextStuck(stuck, 3, true), 0, "moving resets")
	eq(EnemyWatchdog.nextStuck(stuck, 0, false), 0, "holding position on purpose resets")
end)
