--!strict
-- Pure wave math: counts and infinite-mode scaling.
local Config = require(script.Parent.Config)

export type Composition = { [string]: number }
export type Pack = {
	Composition: Composition,
	Size: number,
	PortalCount: number,
}

local WaveTable = {
	Compositions = {
		{ Walker = 16 },
		{ Walker = 16, Runner = 2 },
		{ Walker = 17, Runner = 5, Spitter = 2 },
		{ Walker = 20, Runner = 7, Spitter = 3, Flyer = 2 },
		{ Walker = 25, Runner = 8, Spitter = 4, Flyer = 2, Brute = 1 },
		{ Walker = 14, Runner = 6, Spitter = 4, Flyer = 3, Tank = 2 },
		{ Walker = 14, Runner = 8, Spitter = 6, Flyer = 4, Tank = 4 },
		{ Walker = 15, Runner = 9, Spitter = 6, Flyer = 6, Tank = 4 },
		{ Walker = 16, Runner = 9, Spitter = 8, Flyer = 6, Tank = 6 },
		{ Walker = 15, Runner = 10, Spitter = 8, Flyer = 8, Tank = 8, Queen = 1 },
		{ Walker = 18, Runner = 12, Spitter = 9, Flyer = 8, Tank = 8 },
		{ Walker = 18, Runner = 12, Spitter = 10, Flyer = 9, Tank = 9 },
		{ Walker = 20, Runner = 14, Spitter = 10, Flyer = 9, Tank = 10 },
		{ Walker = 21, Runner = 14, Spitter = 12, Flyer = 10, Tank = 10 },
		{ Walker = 21, Runner = 15, Spitter = 12, Flyer = 10, Tank = 12, Warden = 1 },
		{ Walker = 24, Runner = 16, Spitter = 14, Flyer = 12, Tank = 14 },
		{ Walker = 26, Runner = 18, Spitter = 15, Flyer = 14, Tank = 15 },
		{ Walker = 27, Runner = 20, Spitter = 16, Flyer = 15, Tank = 16 },
		{ Walker = 28, Runner = 21, Spitter = 18, Flyer = 16, Tank = 18 },
		{ Walker = 30, Runner = 21, Spitter = 18, Flyer = 18, Tank = 21, Brute = 1 },
		{ Walker = 32, Runner = 22, Spitter = 20, Flyer = 20, Tank = 24 },
		{ Walker = 30, Runner = 22, Spitter = 21, Flyer = 21, Tank = 26 },
		{ Walker = 28, Runner = 22, Spitter = 21, Flyer = 21, Tank = 27 },
		{ Walker = 27, Runner = 22, Spitter = 21, Flyer = 21, Tank = 28 },
		{ Walker = 26, Runner = 22, Spitter = 21, Flyer = 21, Tank = 28, Queen = 1 },
	} :: { Composition },
}

-- Split a composition into balanced bursts. A target size of four gives wave 1
-- exactly four packs while the bounds keep every burst between three and six.
WaveTable.BossNames = { Brute = true, Queen = true, Warden = true }

function WaveTable.packs(composition: Composition): { Pack }
	-- Mix types across packs (round-robin in name order) and send bosses last, so a pack is
	-- never all one type and the boss arrives after its escort. Deterministic for specs.
	local names = {}
	for enemyName in composition do
		table.insert(names, enemyName)
	end
	table.sort(names)
	local enemies = {}
	local remaining = table.clone(composition)
	local placed = true
	while placed do
		placed = false
		for _, enemyName in names do
			if not WaveTable.BossNames[enemyName] and remaining[enemyName] > 0 then
				table.insert(enemies, enemyName)
				remaining[enemyName] -= 1
				placed = true
			end
		end
	end
	for _, enemyName in names do
		if WaveTable.BossNames[enemyName] then
			for _ = 1, remaining[enemyName] do
				table.insert(enemies, enemyName)
			end
		end
	end

	local total = #enemies
	if total == 0 then
		return {}
	end
	local minimumPacks = math.ceil(total / 6)
	local maximumPacks = math.max(1, math.floor(total / 3))
	local targetPacks = math.floor(total / 4 + 0.5)
	local packCount = math.clamp(targetPacks, minimumPacks, maximumPacks)
	local baseSize = math.floor(total / packCount)
	local largerPacks = total % packCount
	local packs: { Pack } = {}
	local enemyIndex = 1

	for packIndex = 1, packCount do
		local size = baseSize + if packIndex <= largerPacks then 1 else 0
		local packedComposition: Composition = {}
		for _ = 1, size do
			local enemyName = enemies[enemyIndex]
			packedComposition[enemyName] = (packedComposition[enemyName] or 0) + 1
			enemyIndex += 1
		end
		table.insert(packs, {
			Composition = packedComposition,
			Size = size,
			PortalCount = math.min(2, size),
		})
	end

	return packs
end

function WaveTable.packFits(alive: number, packSize: number, maxAlive: number): boolean
	return alive + packSize <= maxAlive
end

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
