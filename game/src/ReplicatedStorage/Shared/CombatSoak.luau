--!strict
-- Pure, fixed-step combat lifecycle simulation for offline leak and budget checks.

export type Budgets = {
	enemies: number,
	playerStates: number,
	contributors: number,
	effects: number,
	orbitals: number,
	queue: number,
}

export type Config = {
	seed: number?,
	durationSeconds: number?,
	initialPlayers: number?,
	maxPlayers: number?,
	joinChance: number?,
	leaveChance: number?,
	budgets: { [string]: number }?,
}

export type Counts = { [string]: number }
export type Result = {
	ok: boolean,
	seed: number,
	durationSeconds: number,
	steps: number,
	peaks: Counts,
	retained: Counts,
	counters: Counts,
	failures: { string },
}

local CombatSoak = {}

CombatSoak.DEFAULT_DURATION_SECONDS = 30 * 60
CombatSoak.DEFAULT_SEEDS = { 1337, 8675309, 202405 }
CombatSoak.DEFAULT_BUDGETS = {
	enemies = 96,
	playerStates = 8,
	contributors = 256,
	effects = 64,
	orbitals = 24,
	queue = 64,
} :: Budgets

local RESOURCE_NAMES = { "enemies", "playerStates", "contributors", "effects", "orbitals", "queue" }

-- Park-Miller using Schrage's method, which stays inside exact integer arithmetic.
local function makeRng(seedValue: number): (number) -> number
	local seed = math.floor(math.abs(seedValue)) % 2147483647
	if seed == 0 then
		seed = 1
	end
	return function(limit: number): number
		local high = math.floor(seed / 44488)
		local low = seed % 44488
		seed = 48271 * low - 3399 * high
		if seed <= 0 then
			seed += 2147483647
		end
		return (seed % limit) + 1
	end
end

local function copyBudgets(overrides: { [string]: number }?): Budgets
	local budgets = table.clone(CombatSoak.DEFAULT_BUDGETS) :: any
	if overrides then
		for name, value in overrides do
			assert(budgets[name] ~= nil, "unknown combat soak budget: " .. name)
			assert(value >= 0 and value % 1 == 0, "budgets must be non-negative integers")
			budgets[name] = value
		end
	end
	return budgets
end

local function countKeys(values: { [any]: any }): number
	local count = 0
	for _ in values do
		count += 1
	end
	return count
end

function CombatSoak.run(configValue: Config?): Result
	local config = configValue or {}
	local seed = config.seed or 1337
	local durationSeconds = config.durationSeconds or CombatSoak.DEFAULT_DURATION_SECONDS
	local initialPlayers = config.initialPlayers
	if initialPlayers == nil then
		initialPlayers = 3
	end
	local maxPlayers = config.maxPlayers
	if maxPlayers == nil then
		maxPlayers = 6
	end
	local joinChance = config.joinChance
	if joinChance == nil then
		joinChance = 2
	end
	local leaveChance = config.leaveChance
	if leaveChance == nil then
		leaveChance = 1
	end

	assert(
		durationSeconds >= 0 and durationSeconds % 1 == 0,
		"durationSeconds must be a non-negative integer"
	)
	assert(maxPlayers >= 0 and maxPlayers % 1 == 0, "maxPlayers must be a non-negative integer")
	assert(
		initialPlayers >= 0 and initialPlayers <= maxPlayers,
		"initialPlayers must fit maxPlayers"
	)
	assert(joinChance >= 0 and joinChance <= 100, "joinChance must be from 0 to 100")
	assert(leaveChance >= 0 and leaveChance <= 100, "leaveChance must be from 0 to 100")

	local budgets = copyBudgets(config.budgets)
	local rng = makeRng(seed)
	local players: { [number]: { orbitals: number } } = {}
	local enemies: { { id: number, health: number, age: number, contributors: { [number]: boolean } } } =
		{}
	local effects: { { expires: number } } = {}
	local queue: { number } = {}
	local nextPlayerId = 0
	local nextEnemyId = 0
	local contributorCount = 0
	local orbitalCount = 0
	local counters: Counts = {
		playersJoined = 0,
		playersLeft = 0,
		playerStatesCreated = 0,
		playerStatesCleaned = 0,
		enemiesSpawned = 0,
		enemiesDied = 0,
		enemiesCleaned = 0,
		hits = 0,
		contributorsCreated = 0,
		effectsCreated = 0,
		orbitalsCreated = 0,
		queueAdded = 0,
		contributorsCleaned = 0,
		effectsCleaned = 0,
		orbitalsCleaned = 0,
		queueCleaned = 0,
	}
	local peaks: Counts = {
		enemies = 0,
		playerStates = 0,
		contributors = 0,
		effects = 0,
		orbitals = 0,
		queue = 0,
	}
	local failures = {}
	local reported: { [string]: boolean } = {}

	local function addPlayer()
		nextPlayerId += 1
		local orbitals = rng(3)
		players[nextPlayerId] = { orbitals = orbitals }
		orbitalCount += orbitals
		counters.playersJoined += 1
		counters.playerStatesCreated += 1
		counters.orbitalsCreated += orbitals
	end

	local function removePlayer(playerId: number)
		local state = players[playerId]
		if not state then
			return
		end
		for _, enemy in enemies do
			if enemy.contributors[playerId] then
				enemy.contributors[playerId] = nil
				contributorCount -= 1
				counters.contributorsCleaned += 1
			end
		end
		orbitalCount -= state.orbitals
		counters.orbitalsCleaned += state.orbitals
		players[playerId] = nil
		counters.playersLeft += 1
		counters.playerStatesCleaned += 1
	end

	local function removeEnemy(index: number)
		local enemy = enemies[index]
		local contributors = countKeys(enemy.contributors)
		contributorCount -= contributors
		counters.contributorsCleaned += contributors
		table.remove(enemies, index)
		counters.enemiesDied += 1
		counters.enemiesCleaned += 1
	end

	local function observe()
		local current: Counts = {
			enemies = #enemies,
			playerStates = countKeys(players),
			contributors = contributorCount,
			effects = #effects,
			orbitals = orbitalCount,
			queue = #queue,
		}
		for _, name in RESOURCE_NAMES do
			peaks[name] = math.max(peaks[name], current[name])
			if current[name] > (budgets :: any)[name] and not reported[name] then
				reported[name] = true
				table.insert(
					failures,
					string.format(
						"%s peak %d exceeds budget %d",
						name,
						current[name],
						(budgets :: any)[name]
					)
				)
			end
		end
	end

	for _ = 1, initialPlayers do
		addPlayer()
	end
	observe()

	for step = 1, durationSeconds do
		local playerCount = countKeys(players)
		if playerCount < maxPlayers and rng(100) <= joinChance then
			addPlayer()
		end
		if playerCount > 0 and rng(100) <= leaveChance then
			local ids = {}
			for playerId in players do
				table.insert(ids, playerId)
			end
			table.sort(ids)
			removePlayer(ids[rng(#ids)])
		end

		playerCount = countKeys(players)
		if playerCount > 0 then
			local spawnCount = 1 + math.floor(playerCount / 2) + (if rng(4) == 1 then 1 else 0)
			for _ = 1, spawnCount do
				nextEnemyId += 1
				table.insert(enemies, {
					id = nextEnemyId,
					health = 2 + rng(4),
					age = 0,
					contributors = {},
				})
				counters.enemiesSpawned += 1
			end
		end

		for _, enemy in enemies do
			enemy.age += 1
		end
		for playerId in players do
			if #enemies > 0 then
				local enemy = enemies[rng(#enemies)]
				if not enemy.contributors[playerId] then
					enemy.contributors[playerId] = true
					contributorCount += 1
					counters.contributorsCreated += 1
				end
				enemy.health -= 2
				table.insert(effects, { expires = step + 2 })
				table.insert(queue, enemy.id)
				counters.hits += 1
				counters.effectsCreated += 1
				counters.queueAdded += 1
			end
		end
		-- Observe produced work before bounded consumers remove it. Otherwise queue
		-- and short-lived effect spikes would be invisible to their budgets.
		observe()

		for index = #effects, 1, -1 do
			if effects[index].expires <= step then
				table.remove(effects, index)
				counters.effectsCleaned += 1
			end
		end
		local drainCount = math.min(#queue, 8 + playerCount * 2)
		for _ = 1, drainCount do
			table.remove(queue, 1)
			counters.queueCleaned += 1
		end
		for index = #enemies, 1, -1 do
			local enemy = enemies[index]
			if enemy.health <= 0 or enemy.age >= 8 then
				removeEnemy(index)
			end
		end
		observe()
	end

	local playerIds = {}
	for playerId in players do
		table.insert(playerIds, playerId)
	end
	for _, playerId in playerIds do
		removePlayer(playerId)
	end
	for index = #enemies, 1, -1 do
		removeEnemy(index)
	end
	counters.effectsCleaned += #effects
	counters.queueCleaned += #queue
	table.clear(effects)
	table.clear(queue)

	local retained: Counts = {
		enemies = #enemies,
		playerStates = countKeys(players),
		contributors = contributorCount,
		effects = #effects,
		orbitals = orbitalCount,
		queue = #queue,
	}
	for _, name in RESOURCE_NAMES do
		if retained[name] ~= 0 then
			table.insert(failures, string.format("retained %s: %d", name, retained[name]))
		end
	end

	return {
		ok = #failures == 0,
		seed = seed,
		durationSeconds = durationSeconds,
		steps = durationSeconds,
		peaks = peaks,
		retained = retained,
		counters = counters,
		failures = failures,
	}
end

CombatSoak.simulate = CombatSoak.run

function CombatSoak.formatSummary(result: Result): string
	local status = if result.ok then "PASS" else "FAIL"
	local summary = string.format(
		"combat-soak %s seed=%d duration=%ds peak[e=%d p=%d c=%d fx=%d o=%d q=%d] retained[e=%d p=%d c=%d fx=%d o=%d q=%d]",
		status,
		result.seed,
		result.durationSeconds,
		result.peaks.enemies,
		result.peaks.playerStates,
		result.peaks.contributors,
		result.peaks.effects,
		result.peaks.orbitals,
		result.peaks.queue,
		result.retained.enemies,
		result.retained.playerStates,
		result.retained.contributors,
		result.retained.effects,
		result.retained.orbitals,
		result.retained.queue
	)
	if #result.failures > 0 then
		return summary .. " errors=" .. table.concat(result.failures, "; ")
	end
	return summary
end

return CombatSoak
