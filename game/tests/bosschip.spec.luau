local Config = load("Config")
local WaveTable = load("WaveTable")

test("waves 1 through 15 count down to each boss", function()
	local expected = { 4, 3, 2, 1, 0 }
	for wave = 1, 15 do
		eq(WaveTable.wavesUntilBoss(wave), expected[(wave - 1) % 5 + 1], "wave " .. wave)
	end
end)

test("boss chip text covers boss, next wave, and later waves", function()
	eq(WaveTable.bossChipText(5), "BOSS WAVE", "boss wave")
	eq(WaveTable.bossChipText(4), "Boss next wave", "one wave")
	eq(WaveTable.bossChipText(2), "Boss in 3 waves", "several waves")
end)

test("infinite waves keep the boss countdown pattern", function()
	for wave = Config.NormalWaves + 1, Config.NormalWaves + 10 do
		eq(
			WaveTable.wavesUntilBoss(wave),
			(Config.BossEvery - wave % Config.BossEvery) % Config.BossEvery,
			"wave " .. wave
		)
	end
end)

test("boss countdown reads BossEvery from Config", function()
	local originalBossEvery = Config.BossEvery
	Config.BossEvery = 3
	eq(WaveTable.wavesUntilBoss(1), 2, "changed interval")
	eq(WaveTable.wavesUntilBoss(3), 0, "changed boss wave")
	Config.BossEvery = originalBossEvery
end)
