--!strict
-- Pure wave math: counts and infinite-mode scaling.
local Config = require(script.Parent.Config)
local EnemyFamilies = require(script.Parent.EnemyFamilies)

export type Composition = { [string]: number }
export type Pack = {
	Composition: Composition,
	Size: number,
	PortalCount: number,
}

local WaveTable = {
	Compositions = {
		{ Swarmer = 16 },
		{ Swarmer = 16, Runner = 2 },
		{ Swarmer = 17, Runner = 5, Shooter = 2 },
		{ Swarmer = 20, Runner = 7, Shooter = 3, Flyer = 2 },
		{ Swarmer = 15, Runner = 8, Shooter = 3, Flyer = 2, Elite = 1 },
		{ Swarmer = 14, Runner = 6, Shooter = 4, Flyer = 3, Tank = 2 },
		{ Swarmer = 14, Runner = 8, Shooter = 6, Flyer = 4, Tank = 2 },
		{ Swarmer = 15, Runner = 9, Shooter = 6, Flyer = 6, Tank = 2 },
		{ Swarmer = 16, Runner = 9, Shooter = 8, Flyer = 6, Tank = 2 },
		{ Swarmer = 12, Runner = 8, Shooter = 4, Flyer = 4, Tank = 1, Elite = 1 },
		{ Swarmer = 14, Runner = 8, Shooter = 6, Flyer = 5, Tank = 2 },
		{ Swarmer = 14, Runner = 9, Shooter = 6, Flyer = 5, Tank = 3 },
		{ Swarmer = 15, Runner = 9, Shooter = 6, Flyer = 6, Tank = 3 },
		{ Swarmer = 15, Runner = 10, Shooter = 7, Flyer = 6, Tank = 3 },
		{ Swarmer = 10, Runner = 7, Shooter = 4, Flyer = 4, Tank = 2, Boss = 1 },
		{ Swarmer = 24, Runner = 16, Shooter = 14, Flyer = 12, Tank = 14 },
		{ Swarmer = 26, Runner = 18, Shooter = 15, Flyer = 14, Tank = 15 },
		{ Swarmer = 27, Runner = 20, Shooter = 16, Flyer = 15, Tank = 16 },
		{ Swarmer = 28, Runner = 21, Shooter = 18, Flyer = 16, Tank = 18 },
		{ Swarmer = 30, Runner = 21, Shooter = 18, Flyer = 18, Tank = 21, Elite = 1 },
		{ Swarmer = 32, Runner = 22, Shooter = 20, Flyer = 20, Tank = 24 },
		{ Swarmer = 30, Runner = 22, Shooter = 21, Flyer = 21, Tank = 26 },
		{ Swarmer = 28, Runner = 22, Shooter = 21, Flyer = 21, Tank = 27 },
		{ Swarmer = 27, Runner = 22, Shooter = 21, Flyer = 21, Tank = 28 },
		{ Swarmer = 26, Runner = 22, Shooter = 21, Flyer = 21, Tank = 28, Boss = 1 },
	} :: { Composition },
}

function WaveTable.resolveComposition(
	composition: Composition,
	familyId: string,
	bossKey: string
): Composition
	local resolved = {}
	for role, count in composition do
		local enemyKey = if role == "Boss" then bossKey else EnemyFamilies.resolve(familyId, role)
		assert(enemyKey, string.format("%s has no enemy for role %s", familyId, role))
		resolved[enemyKey] = (resolved[enemyKey] or 0) + count
	end
	return resolved
end

-- Campaign stages own their boss beat. Strip bosses inherited from the old fixed wave table,
-- then add the selected stage's boss to its last wave.
function WaveTable.resolveStageComposition(
	composition: Composition,
	familyId: string,
	bossKey: string?,
	finalWave: boolean
): Composition
	local resolved = WaveTable.resolveComposition(composition, familyId, bossKey or "Queen")
	for enemyName in resolved do
		if WaveTable.BossNames[enemyName] then
			resolved[enemyName] = nil
		end
	end
	if finalWave and bossKey then
		resolved[bossKey] = 1
	end
	return resolved
end

-- Split a composition into balanced bursts. A target size of four gives wave 1
-- exactly four packs while the bounds keep every burst between three and six.
WaveTable.BossNames = { Brute = true, Queen = true, Warden = true, Elite = true, Boss = true }

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

-- Mini-boss Brutes get tougher at wave 10 so the fight lasts 20-40 s (RunSim spec).
function WaveTable.bossHealthBonus(name: string, wave: number): number
	if name ~= "Brute" then
		return 1
	end
	return if wave >= 10 then 1.35 else 1.08
end

return WaveTable
