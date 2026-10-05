--!strict
local Roll = require(script.Parent.Roll)

export type Progress = {
	wallsBroken: number,
	nextWall: number?,
	nextHealth: number?,
	progress: number,
}

local WallProgress = {}

function WallProgress.compute(size: number, zone: string | Roll.Zone, wallCount: number?): Progress
	local count = wallCount or 10
	local result = Roll.simulate(size, zone, count)
	local nextWall = result.stoppedAtWall
	if not nextWall then
		return { wallsBroken = result.wallsBroken, nextWall = nil, nextHealth = nil, progress = 1 }
	end
	local previousHealth = if nextWall == 1 then 0 else Roll.wallHealth(nextWall - 1)
	local nextHealth = Roll.wallHealth(nextWall)
	local progress =
		math.clamp((math.max(0, size) - previousHealth) / (nextHealth - previousHealth), 0, 1)
	return {
		wallsBroken = result.wallsBroken,
		nextWall = nextWall,
		nextHealth = nextHealth,
		progress = progress,
	}
end

return WallProgress
