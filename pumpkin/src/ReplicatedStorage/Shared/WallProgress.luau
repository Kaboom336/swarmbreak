--!strict
local Roll = require(script.Parent.Roll)
local Ride = require(script.Parent.Ride)

export type Progress = {
	wallsBroken: number,
	totalWallsBroken: number,
	wins: number,
	nextWall: number?,
	nextHealth: number?,
	progress: number,
}

local WallProgress = {}

function WallProgress.compute(size: number, zone: string | Roll.Zone, wallCount: number?): Progress
	local count = wallCount or 10
	local result = Roll.simulate(size, zone, count)
	local baseWins = Ride.finalWins(result.wins, {}, {})
	local nextWall = if result.physicalWallsBroken < count
		then result.physicalWallsBroken + 1
		else nil
	if not nextWall then
		return {
			wallsBroken = result.physicalWallsBroken,
			totalWallsBroken = result.wallsBroken,
			wins = baseWins,
			nextWall = nil,
			nextHealth = nil,
			progress = 1,
		}
	end
	local previousHealth = if nextWall == 1 then 0 else Roll.wallHealth(nextWall - 1)
	local nextHealth = Roll.wallHealth(nextWall)
	local progress =
		math.clamp((math.max(0, size) - previousHealth) / (nextHealth - previousHealth), 0, 1)
	return {
		wallsBroken = result.physicalWallsBroken,
		totalWallsBroken = result.wallsBroken,
		wins = baseWins,
		nextWall = nextWall,
		nextHealth = nextHealth,
		progress = progress,
	}
end

return WallProgress
