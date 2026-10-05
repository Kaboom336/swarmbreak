--!strict
local fs = require("@lune/fs")
local CoreStages = load("CoreStages")
local PoolSize = load("PoolSize")
local RewardTimeout = load("RewardTimeout")
local RunSim = load("RunSim")
local VfxDefs = load("VfxDefs")
local WaveTable = load("WaveTable")

local function count(composition: { [string]: number }): number
	local total = 0
	for _, amount in composition do
		total += amount
	end
	return total
end

test("FX1 death burst is saturated, sharp, and brief", function()
	local burst = VfxDefs.DeathBurst
	assert(burst.Lifetime[2] <= 0.4, "death particles outlive the burst budget")
	for _, color in burst.Colors do
		local high = math.max(color[1], color[2], color[3])
		local low = math.min(color[1], color[2], color[3])
		assert((high - low) / 255 >= 0.35, "death color is white-dominant")
	end
	eq(VfxDefs.DeathRing.StartRadius, 0.5, "shockwave start")
	eq(VfxDefs.DeathRing.EndRadius, 8, "shockwave end")
	assert(VfxDefs.DeathRing.Seconds <= 0.18, "shockwave is too slow")
	assert(VfxDefs.DeathShardCount >= 16 and VfxDefs.DeathShardCount <= 24, "shard count")
	eq(burst.LightEmission, 1, "shards are emissive")
end)

test("FX1 hit, muzzle, trail, and ultimate timings fit the brief", function()
	assert(VfxDefs.HitStreakCount >= 6 and VfxDefs.HitStreakCount <= 8, "hit streak count")
	assert(VfxDefs.HitSeconds <= 0.1, "hit spark duration")
	assert(VfxDefs.MuzzleFlashSeconds <= 0.06, "muzzle star duration")
	eq(VfxDefs.TrailSeconds, 0.15, "weapon trail duration")
	assert(VfxDefs.UltimateBurstSeconds <= 0.3, "ultimate radial duration")
end)

test("FX1 mobile particles halve and live pool sizes stay capped", function()
	eq(VfxDefs.particleCount(10, true), 5, "mobile particle count")
	eq(VfxDefs.particleCount(10, false), 10, "desktop particle count")
	for _, quality in { 2, 5, 9 } do
		assert(PoolSize.total(PoolSize.forQuality(quality)) <= 60, "live VFX cap")
	end
	eq(VfxDefs.MaxLiveParts, 60, "documented VFX cap")
end)

test("FX1 every bossless stage ends in a larger Tank finale", function()
	for _, stage in CoreStages.forCore("Outpost9") do
		if not stage.Boss then
			local previous = WaveTable.resolveStageComposition(
				WaveTable.Compositions[stage.Waves - 1],
				stage.Family,
				stage.Boss,
				false
			)
			local finale = WaveTable.resolveStageComposition(
				WaveTable.Compositions[stage.Waves],
				stage.Family,
				stage.Boss,
				true
			)
			assert(count(finale) >= math.ceil(count(previous) * 1.6), "finale enemy count")
			assert((finale.Tank or 0) >= 1, "finale Tank")
			local simulation =
				RunSim.simulate({ CoreId = "Outpost9", Stage = stage.Id, Seed = 475 })
			local finalWave = simulation.Waves[#simulation.Waves]
			assert(finalWave.TimeToClear >= 20, "final wave clear time")
			assert(finalWave.TimeToClear > simulation.Waves[1].TimeToClear, "finale beats wave one")
		end
	end
end)

test("FX1 reward picks time out server-side without gating waves or auto-fire", function()
	local playerData = fs.readFile("src/ServerStorage/PlayerData.luau")
	local waves = fs.readFile("src/ServerScriptService/WaveManager.server.luau")
	local shooting = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Shooting.client.luau")
	eq(RewardTimeout.Seconds, 8, "eight-second timeout")
	eq(RewardTimeout.shouldAutoPick(10, 17.999, 3), false, "not before timeout")
	eq(RewardTimeout.shouldAutoPick(10, 18, 3), true, "fires at timeout")
	eq(RewardTimeout.shouldAutoPick(10, 99, 0), false, "closed offer")
	eq(RewardTimeout.first({ "Sharp", "Lucky" }), "Sharp", "first-card pick")
	assert(playerData:find("task.delay(RewardTimeout.Seconds", 1, true), "server timer")
	assert(not waves:find("PlayerData.autoPick(plr)", 1, true), "wave advance waits on a pick")
	assert(shooting:find("elseif autoFireEnabled() then", 1, true), "auto-fire continues")
end)

test(
	"FX1 review: tracer pool fits both layers, particle ring keeps colour and expansion",
	function()
		local source =
			require("@lune/fs").readFile("src/StarterPlayer/StarterPlayerScripts/ClientFX.luau")
		assert(
			source:find("effectPoolSizes.Tracers * PoolSize.TracerLayers", 1, true),
			"tracer pool must hold both layers"
		)
		assert(
			source:find("entry.Emitter.Color = ColorSequence.new(color)", 1, true),
			"particle ring ignores colour"
		)
		assert(
			source:find("NumberSequenceKeypoint.new(1, math.max(radius * 2", 1, true),
			"particle ring must expand"
		)
	end
)
