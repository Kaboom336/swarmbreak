--!strict
-- Run from game/: lune run ../tools/balance_sim.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local SHARED = "src/ReplicatedStorage/Shared/"
local cache: { [string]: any } = {}

local function loadShared(name: string): any
	if cache[name] ~= nil then
		return cache[name]
	end

	local parent = setmetatable({}, {
		__index = function(_, key: string): string
			return "MODULE:" .. key
		end,
	})
	local environment = setmetatable({
		script = { Parent = parent, Name = name },
		require = function(target: any): any
			if type(target) == "string" and string.sub(target, 1, 7) == "MODULE:" then
				return loadShared(string.sub(target, 8))
			end
			return require(target)
		end,
	}, { __index = _G })
	local chunk = luau.load(fs.readFile(SHARED .. name .. ".luau"), {
		debugName = name,
		environment = environment,
	})
	local result = chunk()
	cache[name] = result
	return result
end

local BalanceMath = loadShared("BalanceMath")
local Config = loadShared("Config")
local Enemies = loadShared("Enemies")
local Evolutions = loadShared("Evolutions")
local WaveTable = loadShared("WaveTable")
local Weapons = loadShared("Weapons")

local FIRST_WAVE = 1
local LAST_WAVE = 25
local EXPECTED_CLEAR_SECONDS = 60

local function sortedKeys(values: { [string]: any }): { string }
	local keys = {}
	for key in values do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local enemyNames = sortedKeys(Enemies.Defs)
local weaponNames = sortedKeys(Weapons.Defs)

local function upgradeValue(name: string, level: number): number
	local def = Config.Upgrades[name]
	return def.Base + def.PerLevel * math.min(level, def.MaxLevel)
end

local function averageWaveSeconds(
	wave: number,
	weapon: any,
	healthMultiplier: number,
	damageMultiplier: number,
	fireRateMultiplier: number
): number
	local weights = Enemies.weightsForWave(wave)
	local weightedSeconds = 0
	local totalWeight = 0
	for enemyName, weight in weights do
		weightedSeconds += BalanceMath.timeToKill(
			Enemies.Defs[enemyName].Health,
			weapon,
			healthMultiplier,
			damageMultiplier,
			fireRateMultiplier
		) * weight
		totalWeight += weight
	end
	local seconds = weightedSeconds / totalWeight * WaveTable.enemyCount(wave)
	local bossName = Enemies.bossForWave(wave)
	if bossName ~= nil then
		seconds += BalanceMath.timeToKill(
			Enemies.Defs[bossName].Health,
			weapon,
			healthMultiplier,
			damageMultiplier,
			fireRateMultiplier
		)
	end
	return seconds
end

print("# Balance simulation")
print("")
print(
	string.format(
		"Expected wave means the last consecutive wave with an estimated clear time at or below %d seconds.",
		EXPECTED_CLEAR_SECONDS
	)
)
print("Upgrade level applies to both Damage and Fire rate, each capped by its Config maximum.")
print("Evolution rows use the selected path at tier 3; None is the unevolved weapon.")
print("")

local header = { "Weapon", "Evolution", "Upgrade level", "Wave", "DPS" }
for _, enemyName in enemyNames do
	table.insert(header, enemyName .. " TTK")
end
table.insert(header, "Expected wave")
print("| " .. table.concat(header, " | ") .. " |")
local divider = {}
for _ in header do
	table.insert(divider, "---")
end
print("| " .. table.concat(divider, " | ") .. " |")

local evolutionNames = { "None" }
for _, element in Evolutions.Order do
	table.insert(evolutionNames, element)
end
local maximumUpgradeLevel = math.max(Config.Upgrades.Damage.MaxLevel, Config.Upgrades.FireRate.MaxLevel)

for _, weaponName in weaponNames do
	local weapon = Weapons.Defs[weaponName]
	for _, evolutionName in evolutionNames do
		local evolutionDamage, evolutionRate = 1, 1
		if evolutionName ~= "None" then
			evolutionDamage, evolutionRate = Evolutions.multipliers({
				Element = evolutionName,
				Tier = 3,
			})
		end
		for upgradeLevel = 0, maximumUpgradeLevel do
			local damageMultiplier = upgradeValue("Damage", upgradeLevel) * evolutionDamage
			local fireRateMultiplier = upgradeValue("FireRate", upgradeLevel) * evolutionRate
			local clearSecondsByWave = {}
			for wave = FIRST_WAVE, LAST_WAVE do
				local healthMultiplier = WaveTable.scaling(wave)
				table.insert(
					clearSecondsByWave,
					averageWaveSeconds(wave, weapon, healthMultiplier, damageMultiplier, fireRateMultiplier)
				)
			end
			local expectedWave = BalanceMath.expectedWaveReached(clearSecondsByWave, EXPECTED_CLEAR_SECONDS)

			for wave = FIRST_WAVE, LAST_WAVE do
				local healthMultiplier = WaveTable.scaling(wave)
				local row = {
					weapon.Name,
					evolutionName,
					tostring(upgradeLevel),
					tostring(wave),
					string.format("%.1f", BalanceMath.damagePerSecond(weapon, damageMultiplier, fireRateMultiplier)),
				}
				for _, enemyName in enemyNames do
					table.insert(
						row,
						string.format(
							"%.2f",
							BalanceMath.timeToKill(
								Enemies.Defs[enemyName].Health,
								weapon,
								healthMultiplier,
								damageMultiplier,
								fireRateMultiplier
							)
						)
					)
				end
				table.insert(row, tostring(expectedWave))
				print("| " .. table.concat(row, " | ") .. " |")
			end
		end
	end
end
