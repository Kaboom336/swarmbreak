--!strict
-- Pure wave math: counts and infinite-mode scaling.
local Config = require(script.Parent.Config)

export type Composition = { [string]: number }

local WaveTable = {
	Compositions = {
		{ Walker = 8 },
		{ Walker = 7, Runner = 2 },
		{ Walker = 8, Runner = 3, Spitter = 1 },
		{ Walker = 8, Runner = 4, Spitter = 2, Flyer = 1 },
		{ Walker = 10, Runner = 4, Spitter = 2, Flyer = 1, Brute = 1 },
		{ Walker = 9, Runner = 4, Spitter = 3, Flyer = 2, Tank = 1 },
		{ Walker = 9, Runner = 5, Spitter = 4, Flyer = 3, Tank = 3 },
		{ Walker = 10, Runner = 6, Spitter = 4, Flyer = 4, Tank = 3 },
		{ Walker = 11, Runner = 6, Spitter = 5, Flyer = 4, Tank = 4 },
		{ Walker = 10, Runner = 7, Spitter = 5, Flyer = 5, Tank = 5, Queen = 1 },
		{ Walker = 12, Runner = 8, Spitter = 6, Flyer = 5, Tank = 5 },
		{ Walker = 12, Runner = 8, Spitter = 7, Flyer = 6, Tank = 6 },
		{ Walker = 13, Runner = 9, Spitter = 7, Flyer = 6, Tank = 7 },
		{ Walker = 14, Runner = 9, Spitter = 8, Flyer = 7, Tank = 7 },
		{ Walker = 14, Runner = 10, Spitter = 8, Flyer = 7, Tank = 8, Warden = 1 },
		{ Walker = 16, Runner = 11, Spitter = 9, Flyer = 8, Tank = 9 },
		{ Walker = 17, Runner = 12, Spitter = 10, Flyer = 9, Tank = 10 },
		{ Walker = 18, Runner = 13, Spitter = 11, Flyer = 10, Tank = 11 },
		{ Walker = 19, Runner = 14, Spitter = 12, Flyer = 11, Tank = 12 },
		{ Walker = 20, Runner = 14, Spitter = 12, Flyer = 12, Tank = 14, Brute = 1 },
		{ Walker = 21, Runner = 15, Spitter = 13, Flyer = 13, Tank = 16 },
		{ Walker = 20, Runner = 15, Spitter = 14, Flyer = 14, Tank = 17 },
		{ Walker = 19, Runner = 15, Spitter = 14, Flyer = 14, Tank = 18 },
		{ Walker = 18, Runner = 15, Spitter = 14, Flyer = 14, Tank = 19 },
		{ Walker = 17, Runner = 15, Spitter = 14, Flyer = 14, Tank = 19, Queen = 1 },
	} :: { Composition },
}

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
