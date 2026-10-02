--!strict
-- Pure wave math: counts and infinite-mode scaling.
local Config = require(script.Parent.Config)

local WaveTable = {}

function WaveTable.enemyCount(wave: number): number
	if wave == 1 then
		return 8
	end
	local base = 6 + 3 * (wave - 1)
	if wave > Config.NormalWaves then
		base += Config.InfiniteCountPerWave * (wave - Config.NormalWaves)
	end
	return math.min(base, 80)
end

-- Multipliers applied to enemy Health / Damage for a wave.
function WaveTable.scaling(wave: number): (number, number)
	if wave <= Config.NormalWaves then
		return 1, 1
	end
	local n = wave - Config.NormalWaves
	return Config.InfiniteHealthScale ^ n, Config.InfiniteDamageScale ^ n
end

function WaveTable.isBossWave(wave: number): boolean
	return wave % Config.BossEvery == 0
end

function WaveTable.wavesUntilBoss(wave: number): number
	return (Config.BossEvery - wave % Config.BossEvery) % Config.BossEvery
end

function WaveTable.bossChipText(wave: number): string
	local waves = WaveTable.wavesUntilBoss(wave)
	if waves == 0 then
		return "BOSS WAVE"
	elseif waves == 1 then
		return "Boss next wave"
	end
	return string.format("Boss in %d waves", waves)
end

function WaveTable.isFinalNormalWave(wave: number): boolean
	return wave == Config.NormalWaves
end

return WaveTable
