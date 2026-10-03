local CombatSoak = load("CombatSoak")

local function encoded(result)
	return CombatSoak.formatSummary(result)
		.. string.format(
			" created=%d died=%d hits=%d",
			result.counters.enemiesSpawned,
			result.counters.enemiesDied,
			result.counters.hits
		)
end

test("combat soak repeats exactly for a seed", function()
	local config = { seed = 71237, durationSeconds = 120 }
	eq(encoded(CombatSoak.run(config)), encoded(CombatSoak.run(config)), "same seed summary")
end)

test("combat soak cleans every lifecycle collection", function()
	local result = CombatSoak.run({ seed = 41, durationSeconds = 180 })
	assert(result.ok, table.concat(result.failures, "; "))
	for name, count in result.retained do
		eq(count, 0, "retained " .. name)
	end
	eq(result.counters.enemiesSpawned, result.counters.enemiesDied, "enemy cleanup")
	eq(
		result.counters.playerStatesCreated,
		result.counters.playerStatesCleaned,
		"player state cleanup"
	)
	eq(
		result.counters.contributorsCreated,
		result.counters.contributorsCleaned,
		"contributor cleanup"
	)
	eq(result.counters.effectsCreated, result.counters.effectsCleaned, "effect cleanup")
	eq(result.counters.orbitalsCreated, result.counters.orbitalsCleaned, "orbital cleanup")
	eq(result.counters.queueAdded, result.counters.queueCleaned, "queue cleanup")
end)

test("default combat peaks stay inside budgets", function()
	local result = CombatSoak.run({ seed = 9001, durationSeconds = 300 })
	assert(result.ok, table.concat(result.failures, "; "))
	for name, peak in result.peaks do
		assert(peak <= CombatSoak.DEFAULT_BUDGETS[name], name .. " exceeded its budget")
	end
end)

test("combat soak reports budget failures with the resource and values", function()
	local result = CombatSoak.run({
		seed = 5,
		durationSeconds = 2,
		initialPlayers = 1,
		maxPlayers = 1,
		joinChance = 0,
		leaveChance = 0,
		budgets = { enemies = 0 },
	})
	eq(result.ok, false, "budget violation fails")
	assert(result.failures[1]:match("enemies peak %d+ exceeds budget 0"), result.failures[1])
	assert(CombatSoak.formatSummary(result):match("combat%-soak FAIL"), "summary reports failure")
end)

test("zero-player soak creates and retains no combat state", function()
	local result = CombatSoak.run({
		seed = 99,
		durationSeconds = 60,
		initialPlayers = 0,
		maxPlayers = 0,
	})
	assert(result.ok, table.concat(result.failures, "; "))
	eq(result.counters.enemiesSpawned, 0, "no enemies")
	eq(result.peaks.playerStates, 0, "no player state")
	eq(result.peaks.queue, 0, "no queued combat work")
end)
