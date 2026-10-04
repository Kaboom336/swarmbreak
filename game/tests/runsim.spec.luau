local Config = load("Config")
local RunSim = load("RunSim")

local result = RunSim.simulate({ Seed = 475, Waves = 15 })

local function metrics(): string
	local rows = {}
	for _, wave in result.Waves do
		table.insert(
			rows,
			string.format(
				"w%d clear=%.1fs damage=%.2f/s attackers=%d boss=%s",
				wave.Wave,
				wave.TimeToClear,
				wave.DamagePerSecond,
				wave.PeakAttackers,
				if wave.BossKillSeconds then string.format("%.1fs", wave.BossKillSeconds) else "-"
			)
		)
	end
	return table.concat(rows, "; ")
end

print("RunSim seed 475: " .. metrics())
do
	local values = {}
	for index, timestamp in result.LevelUpTimestamps do
		local gap = if index == 1
			then timestamp
			else timestamp - result.LevelUpTimestamps[index - 1]
		table.insert(values, string.format("%.1f(+%.1f)", timestamp, gap))
	end
	print("RunSim levels: " .. table.concat(values, ", "))
end

test("RunSim is deterministic for a seed", function()
	local repeated = RunSim.simulate({ Seed = 475, Waves = 15 })
	for wave, stats in result.Waves do
		eq(repeated.Waves[wave].TimeToClear, stats.TimeToClear, "clear time wave " .. wave)
		eq(repeated.Waves[wave].DamagePerSecond, stats.DamagePerSecond, "damage wave " .. wave)
	end
end)

test("first level-up lands 8 to 15 seconds after the first pack", function()
	local first = result.LevelUpTimestamps[1]
	assert(first and first >= 8 and first <= 15, "first level-up was " .. tostring(first))
end)

test("level-up gaps widen without a pre-wave-15 drought", function()
	local timestamps = result.LevelUpTimestamps
	for index = 2, #timestamps do
		local gap = timestamps[index] - timestamps[index - 1]
		local at = timestamps[index]
		if at <= 120 then
			assert(gap >= 12 and gap <= 20, string.format("early gap %.1fs at %.1fs", gap, at))
		end
		assert(gap < 60, string.format("level drought %.1fs at %.1fs", gap, at))
	end

	local previous = timestamps[1]
	local foundLateGap = false
	for _, timestamp in timestamps do
		if timestamp >= result.Waves[10].LevelUpTimestamps[1] then
			local gap = timestamp - previous
			if gap >= 25 and gap <= 40 then
				foundLateGap = true
			end
		end
		previous = timestamp
		if timestamp > result.Waves[10].LevelUpTimestamps[#result.Waves[10].LevelUpTimestamps] then
			break
		end
	end
	assert(foundLateGap, "no 25-40 second level gap by wave 10")
end)

test("early standing-still damage stays survivable", function()
	for wave = 1, 3 do
		local stats = result.Waves[wave]
		assert(
			stats.DamagePerSecond <= Config.StartHealth * 0.06,
			string.format("wave %d damage %.2f/s", wave, stats.DamagePerSecond)
		)
	end
	for wave = 1, 5 do
		local deathAt = result.Waves[wave].TimeToDeath
		assert(not deathAt or deathAt >= 12, string.format("wave %d death at %.1fs", wave, deathAt))
	end
end)

test("only four melee enemies can attack at once", function()
	eq(RunSim.AttackSlots, 4, "attack-slot cap")
	for _, stats in result.Waves do
		assert(stats.PeakAttackers <= 4, "too many attackers on wave " .. stats.Wave)
	end
end)

test("contact hits use a half-second i-frame", function()
	eq(RunSim.IFrameSeconds, 0.5, "i-frame seconds")
end)

test("waves one through ten clear in 35 to 70 seconds", function()
	for wave = 1, 10 do
		local seconds = result.Waves[wave].TimeToClear
		assert(seconds >= 35 and seconds <= 70, string.format("wave %d clear %.1fs", wave, seconds))
	end
end)

test("Brute and Queen kills take 20 to 40 seconds", function()
	for _, wave in { 5, 10 } do
		local seconds = result.Waves[wave].BossKillSeconds
		assert(
			seconds and seconds >= 20 and seconds <= 40,
			string.format("wave %d boss %s", wave, tostring(seconds))
		)
	end
end)

test("Outpost 9 clears in twelve to fifteen minutes on Normal", function()
	local seconds = 0
	for _, wave in result.Waves do
		seconds += wave.TimeToClear
	end
	assert(seconds >= 12 * 60 and seconds <= 15 * 60, string.format("run took %.1fs", seconds))
end)

test("Mars Core stage fifteen clears in five to eight minutes on Normal", function()
	local stageResult = RunSim.simulate({
		Seed = 475,
		CoreId = "Outpost9",
		Stage = 15,
		Difficulty = "Normal",
	})
	local seconds = 0
	for _, wave in stageResult.Waves do
		seconds += wave.TimeToClear
	end
	eq(#stageResult.Waves, 8, "stage wave count")
	assert(seconds >= 5 * 60 and seconds <= 8 * 60, string.format("stage took %.1fs", seconds))
end)
