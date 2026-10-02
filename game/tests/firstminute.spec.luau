local Config = load("Config")
local Enemies = load("Enemies")
local LevelUp = load("LevelUp")
local SpawnPicker = load("SpawnPicker")
local WaveTable = load("WaveTable")
local Weapons = load("Weapons")

test("wave 1 starts with eight Walkers", function()
	eq(Config.WaveStartDelay, 3, "opening countdown")
	eq(WaveTable.enemyCount(1), 8, "Walker count")
	local weights = Enemies.weightsForWave(1)
	eq(weights.Walker, 5, "Walkers are enabled")
	for enemyType in weights do
		eq(enemyType, "Walker", "only Walkers spawn")
	end
end)

test("starter pistol kills a wave 1 Walker within one second", function()
	local walker = Enemies.Defs.Walker
	local starter = Weapons.Defs.Starter
	local hitsToKill = math.ceil(walker.Health / (starter.Damage * starter.Pellets))
	local timeToKill = hitsToKill / starter.FireRate
	assert(hitsToKill <= 2, "Walker takes more than two starter hits")
	assert(timeToKill <= 1, "Walker time-to-kill exceeds one second")
end)

test("Walker cannot reach a protected spawn before four seconds", function()
	local earliestArrival = SpawnPicker.ExcludeRadius / Enemies.Defs.Walker.Speed
	assert(earliestArrival >= 4, "Walker reaches the player too quickly")
	eq(Config.SpawnProtectionSeconds, 2, "spawn protection")
end)

test("first level-up arrives within three Walker kills", function()
	local walkerXp = LevelUp.xpForKill("Walker")
	local killsToLevel = math.ceil(LevelUp.requiredXp(1) / walkerXp)
	assert(killsToLevel <= 3, "first level takes more than three Walker kills")
	local seconds = LevelUp.secondsAtWaveOneRate(1)
	assert(seconds >= 12 and seconds <= 18, "first level is not about 15 seconds")
end)

test("player starts with 150 health", function()
	eq(Config.StartHealth, 150, "starting health")
	eq(Config.Upgrades.MaxHealth.Base, Config.StartHealth, "live max health")
end)
