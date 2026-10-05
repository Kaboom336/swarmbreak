--!strict
local Config = require(script.Parent.Config)
local Ride = require(script.Parent.Ride)

export type Zone = {
	Name: string,
	DisplayName: string,
	RequiredWins: number,
	WinMultiplier: number,
}

export type Result = {
	wallsBroken: number,
	physicalWallsBroken: number,
	bonusWalls: number,
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

function Roll.sizeFactor(size: number): number
	return math.max(1, math.max(0, size) ^ Config.WinSizeExponent)
end

function Roll.winsFor(wallsBroken: number, zone: string | Zone, size: number?): number
	local resolved = Roll.getZone(zone)
	assert(resolved, "unknown zone")
	return math.floor(
		math.max(0, math.floor(wallsBroken)) * resolved.WinMultiplier * Roll.sizeFactor(size or 0)
	)
end

function Roll.simulate(size: number, zone: string | Zone, physicalCount: number?): Result
	local resolved = Roll.getZone(zone)
	assert(resolved, "unknown zone")
	local count = physicalCount or Config.FallbackWallCount
	assert(count >= 0 and count % 1 == 0, "physical count must be a non-negative integer")
	local maximumCount = count + Config.MaxBonusWalls

	local power = math.max(0, size)
	local broken = 0
	for wallIndex = 1, maximumCount do
		if power < Roll.wallHealth(wallIndex) then
			break
		end
		broken = wallIndex
	end

	local stoppedAtWall = if broken < maximumCount then broken + 1 else nil
	-- Bonus walls are virtual, so a roll past the physical track ends at its last bonus wall
	local wallsReached = if stoppedAtWall and broken < count then stoppedAtWall else broken
	local physicalWallsBroken = math.min(broken, count)
	local bonusWalls = math.max(0, broken - count)
	return {
		wallsBroken = broken,
		physicalWallsBroken = physicalWallsBroken,
		bonusWalls = bonusWalls,
		distance = wallsReached * Config.WallSpacing,
		wins = Roll.winsFor(broken, resolved, size),
		stoppedAtWall = stoppedAtWall,
	}
end

function Roll.duration(_distance: number, size: number, bonusWalls: number?): number
	return Ride.duration(size, bonusWalls or 0)
end

return Roll
