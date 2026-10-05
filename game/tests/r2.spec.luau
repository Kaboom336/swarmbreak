--!strict
local fs = require("@lune/fs")

local ArenaLayout = load("ArenaLayout")
local CoreStages = load("CoreStages")
local Difficulty = load("Difficulty")
local EnemyFamilies = load("EnemyFamilies")
local EnemyWatchdog = load("EnemyWatchdog")
local Feel = load("Feel")
local PoolSize = load("PoolSize")
local RunSim = load("RunSim")
local VfxDefs = load("VfxDefs")
local WaveTable = load("WaveTable")

test("R2 every campaign boss spawns on its active stage floor on every difficulty", function()
	for _, stage in CoreStages.forCore("Outpost9") do
		if not stage.Boss then
			continue
		end
		for difficulty in Difficulty.Defs do
			local layoutWave = ArenaLayout.layoutWave(stage.Zone, stage.Waves)
			local zone = ArenaLayout.zoneForWave(layoutWave)
			local spawn = ArenaLayout.bossSpawnForWave(layoutWave)
			eq(zone.Id, stage.Zone, difficulty .. " stage zone")
			assert(ArenaLayout.zoneContains(zone, spawn), difficulty .. " boss escaped stage zone")
			assert(ArenaLayout.onFloor(spawn), difficulty .. " boss spawn has no floor")
		end
	end
end)

test("R2 every campaign boss rig is twelve to eighteen studs tall", function()
	for _, stage in CoreStages.forCore("Outpost9") do
		if stage.Boss then
			local height = EnemyFamilies.rigHeight(stage.Family, stage.Boss)
			assert(height and height >= 12 and height <= 18, stage.Boss .. " rig height")
			eq(
				ArenaLayout.bossSpawnY(height) - height / 2,
				ArenaLayout.FloorTopY,
				stage.Boss .. " feet"
			)
		end
	end
	local rigBuilder = fs.readFile("src/ServerStorage/EnemyRigBuilder.luau")
	assert(not rigBuilder:find("or size.Y", 1, true), "rigs must not fall back to primitive height")
end)

test("R2 boss watchdog pure rule replaces off-floor and undamageable bosses", function()
	local offFloor = 0
	offFloor = EnemyWatchdog.nextBossOffFloor(offFloor, false, 0)
	eq(EnemyWatchdog.shouldRepositionBoss(offFloor, 0, false), false, "one second grace")
	offFloor = EnemyWatchdog.nextBossOffFloor(offFloor, false, 0)
	eq(EnemyWatchdog.shouldRepositionBoss(offFloor, 0, false), true, "off-floor timeout")
	eq(EnemyWatchdog.nextBossOffFloor(offFloor, true, 10), 0, "floor resets timer")

	local noDamage = 0
	for _ = 1, EnemyWatchdog.BossNoDamageSeconds do
		noDamage = EnemyWatchdog.nextBossNoDamage(noDamage, false, true)
	end
	eq(EnemyWatchdog.shouldRepositionBoss(0, noDamage, true), true, "no-damage timeout")
	eq(EnemyWatchdog.nextBossNoDamage(noDamage, true, true), 0, "damage resets timer")
	eq(EnemyWatchdog.nextBossNoDamage(noDamage, false, false), 0, "distant players reset timer")
end)

test("R2 death and hit effects meet impact sizes, timings, and budgets", function()
	assert(VfxDefs.deathRingRadius("Walker", 4) >= 8, "normal death ring")
	assert(VfxDefs.deathRingRadius("Tank", 10) >= 16, "Tank death ring")
	assert(VfxDefs.DeathShardCount >= 16 and VfxDefs.DeathShardCount <= 24, "death sparks")
	assert(VfxDefs.HitStreakCount >= 6 and VfxDefs.HitStreakCount <= 8, "radial hit streaks")
	eq(
		VfxDefs.particleCount(VfxDefs.DeathShardCount, true),
		VfxDefs.DeathShardCount / 2,
		"low death sparks"
	)
	eq(
		VfxDefs.particleCount(VfxDefs.HitStreakCount, true),
		VfxDefs.HitStreakCount / 2,
		"low hit streaks"
	)
	assert(VfxDefs.HitSpark.Size[1].Value >= 0.7, "hit sparks are not doubled")
	assert(VfxDefs.DeathFlashDiscSeconds <= 0.08, "filled flash disc timing")
	assert(VfxDefs.KillImpactFrameSeconds <= 0.05, "kill impact frame timing")
	assert(VfxDefs.KillImpactFrameSeconds <= 0.3, "screen centre coverage")
	eq(PoolSize.MaxLiveVfxParts, 60, "live VFX budget")
	for _, quality in { 2, 5, 9 } do
		assert(PoolSize.total(PoolSize.forQuality(quality)) <= 60, "quality pool budget")
	end
end)

test("R2 Reaper hits use the wide two-tone arc, hit-stop, and larger numbers", function()
	eq(VfxDefs.ScytheArcStuds, 10, "scythe arc")
	eq(VfxDefs.ScytheSlashSeconds, 0.12, "scythe arc timing")
	eq(Feel.ScytheHitStopSeconds, 0.04, "scythe hit-stop")
	eq(Feel.ScytheDamageNumberScale, 1.5, "scythe number scale")
	local effects = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Effects.client.luau")
	assert(effects:find("Theme.Loot", 1, true), "scythe arc has no gold layer")
	assert(effects:find("Theme.Chitin", 1, true), "scythe arc has no purple layer")
	local combat = fs.readFile("src/ServerScriptService/Combat.server.luau")
	assert(combat:find('Scythe = weapon.Id == "Reaper"', 1, true), "Reaper swing is not tagged")
end)

test("R2 waves use two to four timed pulses", function()
	for wave, composition in WaveTable.Compositions do
		local packs = WaveTable.packs(composition)
		assert(#packs >= 2 and #packs <= 4, string.format("wave %d has %d pulses", wave, #packs))
		for _, pack in packs do
			assert(pack.PortalCount >= 2, "pulse does not use different gates")
		end
	end
	assert(WaveTable.PulseGapSeconds > 0, "pulses need timing")
	assert(WaveTable.FinalePulseGapSeconds > WaveTable.PulseGapSeconds, "finale timing")
end)

test("R2 Reaper starter clears paced Normal stages within six minutes", function()
	for _, stage in CoreStages.forCore("Outpost9") do
		local result = RunSim.simulate({
			Seed = 475,
			CoreId = "Outpost9",
			Stage = stage.Id,
			Difficulty = "Normal",
			Profile = "ReaperStarter",
		})
		local total = 0
		for _, wave in result.Waves do
			total += wave.TimeToClear
			assert(
				wave.TimeToClear >= 12,
				string.format("stage %d wave %d %.1fs", stage.Id, wave.Wave, wave.TimeToClear)
			)
			assert(
				wave.AverageFps >= 55,
				string.format("stage %d wave %d %.1f fps", stage.Id, wave.Wave, wave.AverageFps)
			)
		end
		assert(result.Waves[#result.Waves].TimeToClear >= 20, "finale under twenty seconds")
		assert(total <= 6 * 60, string.format("stage %d took %.1fs", stage.Id, total))
	end
end)
