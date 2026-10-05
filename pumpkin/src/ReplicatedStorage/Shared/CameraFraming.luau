--!strict
local Config = require(script.Parent.Config)

export type Frame = {
	distance: number,
	height: number,
}

local CameraFraming = {}

function CameraFraming.compute(visualDiameter: number, rolling: boolean?): Frame
	local diameter = math.max(0, visualDiameter)
	local isRolling = rolling == true
	local minimumDistance = if isRolling
		then Config.PumpkinRollCameraMinDistance
		else Config.PumpkinCameraMinDistance
	local baseHeight = if isRolling then Config.PumpkinRollCameraBaseHeight else 0
	return {
		distance = math.max(
			minimumDistance,
			diameter * Config.PumpkinCameraDistancePerDiameter + Config.PumpkinCameraBaseDistance
		),
		height = math.max(5, diameter * Config.PumpkinCameraHeightPerDiameter + baseHeight),
	}
end

return CameraFraming
