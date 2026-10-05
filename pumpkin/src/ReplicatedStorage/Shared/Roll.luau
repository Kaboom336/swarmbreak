--!strict
local Config = require(script.Parent.Config)

export type Zone = {
	Name: string,
	DisplayName: string,
	RequiredWins: number,
	WinMultiplier: number,
}

export type Result = {
	wallsBroken: number,
	distance: number,
	wins: number,
	stoppedAtWall: number?,
}

local Roll = {}

function Roll.getZone(zone: string | Zone): Zone?
	if type(zone) == "table" then
		return zone
	end
	for _, candidate in Config.Zones do
		if candidate.Name == zone then
			return candidate
		end
	end
	return nil
end

function Roll.wallHealth(wallIndex: number): number
	assert(wallIndex >= 1 and wallIndex % 1 == 0, "wall index must be a positive integer")
	return Config.WallBaseHealth * Config.WallHealthGrowth ^ (wallIndex - 1)
end

function Roll.isZoneUnlocked(totalWins: number, zone: string | Zone): boolean
	local resolved = Roll.getZone(zone)
	return resolved ~= nil and math.max(0, totalWins) >= resolved.RequiredWins
end

function Roll.winsFor(wallsBroken: number, zone: string | Zone): number
	local resolved = Roll.getZone(zone)
	assert(resolved, "unknown zone")
	return math.max(0, math.floor(wallsBroken)) * resolved.WinMultiplier
end

function Roll.simulate(size: number, zone: string | Zone, wallCount: number?): Result
	local resolved = Roll.getZone(zone)
	assert(resolved, "unknown zone")
	local count = wallCount or Config.FallbackWallCount
	assert(count >= 0 and count % 1 == 0, "wall count must be a non-negative integer")

	local power = math.max(0, size)
	local broken = 0
	for wallIndex = 1, count do
		if power < Roll.wallHealth(wallIndex) then
			break
		end
		broken = wallIndex
	end

	local stoppedAtWall = if broken < count then broken + 1 else nil
	local wallsReached = if stoppedAtWall then stoppedAtWall else broken
	return {
		wallsBroken = broken,
		distance = wallsReached * Config.WallSpacing,
		wins = Roll.winsFor(broken, resolved),
		stoppedAtWall = stoppedAtWall,
	}
end

function Roll.duration(distance: number, size: number): number
	local speed = Config.RollBaseSpeed + math.sqrt(math.max(0, size)) * Config.RollSizeSpeedFactor
	return math.clamp(math.max(0, distance) / speed, Config.RollMinDuration, Config.RollMaxDuration)
end

return Roll
