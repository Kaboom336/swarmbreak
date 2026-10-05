--!strict
local Config = require(script.Parent.Config)
local Rebirth = require(script.Parent.Rebirth)
local Roll = require(script.Parent.Roll)

export type Simulation = {
	elapsedMinutes: number,
	forestUnlockMinutes: number?,
	firstRebirthMinutes: number?,
	graveyardUnlockMinutes: number?,
	rebirths: number,
	wins: number,
	totalWins: number,
	zone: string,
}

local Economy = {}

local function bestZone(totalWins: number): Roll.Zone
	local selected = Config.Zones[1]
	for _, zone in Config.Zones do
		if totalWins >= zone.RequiredWins then
			selected = zone
		else
			break
		end
	end
	return selected
end

local function bestRoll(zone: Roll.Zone, growthPerSecond: number): (number, Roll.Result, number)
	local bestSize = Config.WallBaseHealth
	local bestResult = Roll.simulate(bestSize, zone, Config.FallbackWallCount)
	local bestDuration = bestSize / growthPerSecond
		+ Roll.duration(bestResult.distance, bestSize, bestResult.bonusWalls)
	local bestRate = bestResult.wins / bestDuration

	for wallIndex = 2, Config.FallbackWallCount + Config.MaxBonusWalls do
		local size = Roll.wallHealth(wallIndex)
		local result = Roll.simulate(size, zone, Config.FallbackWallCount)
		local duration = size / growthPerSecond
			+ Roll.duration(result.distance, size, result.bonusWalls)
		local rate = result.wins / duration
		if rate > bestRate then
			bestSize = size
			bestResult = result
			bestDuration = duration
			bestRate = rate
		end
	end

	return bestSize, bestResult, bestDuration
end

function Economy.simulate(minutes: number, clicksPerSecond: number): Simulation
	assert(minutes >= 0, "minutes must be non-negative")
	assert(clicksPerSecond > 0, "clicks per second must be positive")
	local limitSeconds = minutes * 60
	local elapsedSeconds = 0
	local wins = 0
	local totalWins = 0
	local rebirths = 0
	local forestUnlockMinutes: number? = nil
	local firstRebirthMinutes: number? = nil
	local graveyardUnlockMinutes: number? = nil

	while elapsedSeconds < limitSeconds do
		local zone = bestZone(totalWins)
		local growthPerSecond = clicksPerSecond * Rebirth.multiplier(rebirths) * Config.SizePerClick
		local _, result, cycleSeconds = bestRoll(zone, growthPerSecond)
		if elapsedSeconds + cycleSeconds > limitSeconds then
			break
		end

		elapsedSeconds += cycleSeconds
		wins += result.wins
		totalWins += result.wins
		local elapsedMinutes = elapsedSeconds / 60
		if not forestUnlockMinutes and totalWins >= Config.Zones[2].RequiredWins then
			forestUnlockMinutes = elapsedMinutes
		end
		if not graveyardUnlockMinutes and totalWins >= Config.Zones[3].RequiredWins then
			graveyardUnlockMinutes = elapsedMinutes
		end

		if Rebirth.canAfford(wins, rebirths) then
			if not firstRebirthMinutes then
				firstRebirthMinutes = elapsedMinutes
			end
			wins = 0
			totalWins = 0
			rebirths += 1
		end
	end

	return {
		elapsedMinutes = elapsedSeconds / 60,
		forestUnlockMinutes = forestUnlockMinutes,
		firstRebirthMinutes = firstRebirthMinutes,
		graveyardUnlockMinutes = graveyardUnlockMinutes,
		rebirths = rebirths,
		wins = wins,
		totalWins = totalWins,
		zone = bestZone(totalWins).Name,
	}
end

return Economy
