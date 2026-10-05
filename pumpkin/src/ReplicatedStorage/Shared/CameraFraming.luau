--!strict
local Config = require(script.Parent.Config)

export type Frame = {
	distance: number,
	height: number,
}

local CameraFraming = {}

export type Heading = {
	x: number,
	z: number,
}

function CameraFraming.horizontalHeading(
	deltaX: number,
	deltaZ: number,
	fallbackX: number,
	fallbackZ: number
): Heading
	local magnitude = math.sqrt(deltaX * deltaX + deltaZ * deltaZ)
	if magnitude < 1e-5 then
		magnitude = math.sqrt(fallbackX * fallbackX + fallbackZ * fallbackZ)
		if magnitude < 1e-5 then
			return { x = 0, z = -1 }
		end
		return { x = fallbackX / magnitude, z = fallbackZ / magnitude }
	end
	return { x = deltaX / magnitude, z = deltaZ / magnitude }
end

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

function CameraFraming.springStep(
	current: number,
	velocity: number,
	target: number,
	deltaTime: number,
	frequency: number?
): (number, number)
	if deltaTime <= 0 then
		return current, velocity
	end
	local angular = 2 * math.pi * (frequency or 4)
	local offset = current - target
	local decay = math.exp(-angular * deltaTime)
	local nextValue = target + (offset + (velocity + angular * offset) * deltaTime) * decay
	local nextVelocity = (velocity - angular * (velocity + angular * offset) * deltaTime) * decay
	local maximumChange = math.max(0.01, math.abs(current) * 0.1)
	local change = math.clamp(nextValue - current, -maximumChange, maximumChange)
	if change ~= nextValue - current then
		nextVelocity = change / deltaTime
	end
	return current + change, nextVelocity
end

return CameraFraming
