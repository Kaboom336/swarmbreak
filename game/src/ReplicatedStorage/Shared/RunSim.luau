--!strict
-- Pure, seeded solo-run simulator. It deliberately models player decisions simply:
-- shoot the nearest spawned enemy, take every level-up, and never move.
local BalanceMath = require(script.Parent.BalanceMath)
local Campaign = require(script.Parent.Campaign)
local Config = require(script.Parent.Config)
local Difficulty = require(script.Parent.Difficulty)
local Enemies = require(script.Parent.Enemies)
local LevelUp = require(script.Parent.LevelUp)
local WaveTable = require(script.Parent.WaveTable)
local Weapons = require(script.Parent.Weapons)

export type Options = {
	Seed: number?,
	Waves: number?,
	Difficulty: Difficulty.TierName?,
	Weapon: string?,
}

export type WaveResult = {
	Wave: number,
	TimeToClear: number,
	LevelUpTimestamps: { number },
	PeakAttackers: number,
	DamagePerSecond: number,
	TimeToDeath: number?,
	BossKillSeconds: number?,
}

export type Result = {
	Waves: { WaveResult },
	LevelUpTimestamps: { number },
}

type SimEnemy = {
	Name: string,
	Health: number,
	Distance: number,
	Speed: number,
	Damage: number,
	SpawnAt: number,
	NextAttackAt: number,
	Ranged: boolean,
	Range: number,
	AttackCooldown: number,
	Boss: boolean,
	FirstDamagedAt: number?,
}

local RunSim = {}

RunSim.StepSeconds = 0.05
RunSim.SpawnDistanceMin = 38
RunSim.SpawnDistanceMax = 46
RunSim.ContactRange = 6
RunSim.AttackSlots = 4
RunSim.IFrameSeconds = 0.5
RunSim.AutoFireEfficiency = 0.16
RunSim.BossFireEfficiency = 0.35
RunSim.DpsPerPick = 0.08

local function seededRandom(seed: number): () -> number
	local state = math.max(1, math.floor(math.abs(seed))) % 2147483647
	return function(): number
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
end

local function sortedNames(composition: WaveTable.Composition): { string }
	local names = {}
	for name in composition do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

local function aliveCount(enemies: { SimEnemy }): number
	local count = 0
	for _, enemy in enemies do
		if enemy.Health > 0 then
			count += 1
		end
	end
	return count
end

local function nearestEnemy(enemies: { SimEnemy }, now: number): SimEnemy?
	local nearest: SimEnemy? = nil
	for _, enemy in enemies do
		if enemy.Health > 0 and enemy.SpawnAt <= now then
			if
				not nearest
				or enemy.Distance < nearest.Distance
				or (enemy.Distance == nearest.Distance and enemy.SpawnAt < nearest.SpawnAt)
			then
				nearest = enemy
			end
		end
	end
	return nearest
end

local function makeEnemy(
	name: string,
	wave: number,
	spawnAt: number,
	healthScale: number,
	damageScale: number,
	random: () -> number
): SimEnemy
	local def = Enemies.Defs[name]
	return {
		Name = name,
		Health = def.Health * healthScale * if name == "Brute"
			then if wave >= 10 then 1.35 else 1.08
			else 1,
		Distance = RunSim.SpawnDistanceMin
			+ (RunSim.SpawnDistanceMax - RunSim.SpawnDistanceMin) * random(),
		Speed = def.Speed,
		Damage = math.floor(def.Damage * damageScale + 0.5),
		SpawnAt = spawnAt,
		NextAttackAt = spawnAt + random(),
		Ranged = def.Ranged == true,
		Range = def.Range or RunSim.ContactRange,
		AttackCooldown = def.AttackCooldown or 1,
		Boss = def.Boss == true,
		FirstDamagedAt = nil,
	}
end

function RunSim.simulate(options: Options?): Result
	local settings = options or {}
	local random = seededRandom(settings.Seed or 475)
	local waveLimit = math.clamp(settings.Waves or 15, 1, #WaveTable.Compositions)
	local difficultyId = settings.Difficulty or Difficulty.Default
	local weapon = Weapons.Defs[settings.Weapon or "Starter"]
	assert(weapon, "unknown simulation weapon")

	local level = 0
	local xp = 0
	local runTime = 0
	local allLevelUps = {}
	local results = {}

	for wave = 1, waveLimit do
		local healthScale, damageScale = WaveTable.scaling(wave)
		local scaled =
			Difficulty.apply({ Health = healthScale, Damage = damageScale }, difficultyId)
		local enemies = {} :: { SimEnemy }
		local spawnAt = 0
		local map = Campaign.get(Campaign.DefaultId)
		local composition =
			WaveTable.resolveComposition(WaveTable.Compositions[wave], map.Family, map.BossKey)
		for packIndex, pack in WaveTable.packs(composition) do
			if packIndex > 1 then
				spawnAt += Config.SpawnGapMin + (Config.SpawnGapMax - Config.SpawnGapMin) * random()
			end
			for _, name in sortedNames(pack.Composition) do
				for _ = 1, pack.Composition[name] do
					table.insert(
						enemies,
						makeEnemy(
							name,
							wave,
							spawnAt,
							scaled.Health :: number,
							scaled.Damage :: number,
							random
						)
					)
				end
			end
		end

		local now = 0
		local nextDamageAt = 0
		local damageTaken = 0
		local health = Config.StartHealth
		local timeToDeath: number? = nil
		local peakAttackers = 0
		local waveLevelUps = {}
		local bossKillSeconds: number? = nil

		while aliveCount(enemies) > 0 and now < 600 do
			local contact = 0
			for _, enemy in enemies do
				if enemy.Health <= 0 or enemy.SpawnAt > now then
					continue
				end
				local stopDistance = if enemy.Ranged then enemy.Range * 0.8 else RunSim.ContactRange
				enemy.Distance =
					math.max(stopDistance, enemy.Distance - enemy.Speed * RunSim.StepSeconds)
				if not enemy.Ranged and enemy.Distance <= RunSim.ContactRange then
					contact += 1
				end
			end
			local attackers = math.min(contact, RunSim.AttackSlots)
			peakAttackers = math.max(peakAttackers, attackers)

			local target = nearestEnemy(enemies, now)
			if target then
				local efficiency = if target.Boss
					then RunSim.BossFireEfficiency
					else RunSim.AutoFireEfficiency
				local dps = BalanceMath.damagePerSecond(weapon)
					* efficiency
					* (1 + level * RunSim.DpsPerPick)
				if target.Boss and not target.FirstDamagedAt then
					target.FirstDamagedAt = now
				end
				target.Health -= dps * RunSim.StepSeconds
				if target.Health <= 0 then
					if target.Boss and target.FirstDamagedAt then
						bossKillSeconds = now - target.FirstDamagedAt + RunSim.StepSeconds
					end
					local nextLevel, nextXp, gained =
						LevelUp.advance(level, xp, LevelUp.xpForKill(target.Name))
					level = nextLevel
					xp = nextXp
					for _ = 1, gained do
						local timestamp = runTime + now
						table.insert(allLevelUps, timestamp)
						table.insert(waveLevelUps, timestamp)
					end
				end
			end

			if now >= nextDamageAt then
				local availableSlots = attackers
				for _, enemy in enemies do
					if enemy.Health <= 0 or enemy.SpawnAt > now or enemy.NextAttackAt > now then
						continue
					end
					local canAttack = enemy.Ranged and enemy.Distance <= enemy.Range
						or (
							not enemy.Ranged
							and enemy.Distance <= RunSim.ContactRange
							and availableSlots > 0
						)
					if canAttack then
						damageTaken += enemy.Damage
						health -= enemy.Damage
						nextDamageAt = now + RunSim.IFrameSeconds
						enemy.NextAttackAt = now + enemy.AttackCooldown
						if not enemy.Ranged then
							availableSlots -= 1
						end
						if health <= 0 and not timeToDeath then
							timeToDeath = now
						end
						break
					end
				end
			end

			now += RunSim.StepSeconds
		end

		table.insert(results, {
			Wave = wave,
			TimeToClear = now,
			LevelUpTimestamps = waveLevelUps,
			PeakAttackers = peakAttackers,
			DamagePerSecond = damageTaken / math.max(now, RunSim.StepSeconds),
			TimeToDeath = timeToDeath,
			BossKillSeconds = bossKillSeconds,
		})
		runTime += now
	end

	return {
		Waves = results,
		LevelUpTimestamps = allLevelUps,
	}
end

return RunSim
