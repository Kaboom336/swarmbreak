--!strict
-- Pure, frame-rate-independent combat-camera targets and rate-limited easing.
export type Framing = {
	Distance: number,
	Height: number,
	Fov: number,
	DistanceVelocity: number?,
	HeightVelocity: number?,
	FovVelocity: number?,
}

local CombatCameraMath = {}

CombatCameraMath.InputFreezeSeconds = 0.2
CombatCameraMath.CrowdCount = 12
CombatCameraMath.Response = 5
CombatCameraMath.MaxDistanceRate = 7
CombatCameraMath.MaxHeightRate = 3
CombatCameraMath.MaxFovRate = 16

local BASE: Framing = { Distance = 12, Height = 2.2, Fov = 70 }
local CROWD: Framing = { Distance = 17, Height = 3.2, Fov = 80 }

local function spring(
	current: number,
	velocity: number,
	target: number,
	deltaTime: number,
	maximumRate: number
): (number, number)
	local acceleration = (target - current) * CombatCameraMath.Response ^ 2
		- 2 * CombatCameraMath.Response * velocity
	local nextVelocity = math.clamp(velocity + acceleration * deltaTime, -maximumRate, maximumRate)
	local nextValue = current + nextVelocity * deltaTime
	if (target - current) * (target - nextValue) < 0 then
		return target, 0
	end
	return nextValue, nextVelocity
end

function CombatCameraMath.target(enemyCount: number, hasElite: boolean, hasBoss: boolean): Framing
	local crowd = math.clamp(enemyCount / CombatCameraMath.CrowdCount, 0, 1)
	local threat = if hasBoss then 1 else if hasElite then 0.6 else 0
	return {
		Distance = BASE.Distance + (CROWD.Distance - BASE.Distance) * crowd - 3 * threat,
		Height = BASE.Height + (CROWD.Height - BASE.Height) * crowd - 0.9 * threat,
		Fov = BASE.Fov + (CROWD.Fov - BASE.Fov) * crowd - 2 * threat,
		DistanceVelocity = 0,
		HeightVelocity = 0,
		FovVelocity = 0,
	}
end

function CombatCameraMath.step(
	current: Framing,
	target: Framing,
	deltaTime: number,
	inputAge: number
): Framing
	if deltaTime <= 0 or inputAge <= CombatCameraMath.InputFreezeSeconds then
		return {
			Distance = current.Distance,
			Height = current.Height,
			Fov = current.Fov,
			DistanceVelocity = 0,
			HeightVelocity = 0,
			FovVelocity = 0,
		}
	end
	local dt = math.min(deltaTime, 0.1)
	local distance, distanceVelocity = spring(
		current.Distance,
		current.DistanceVelocity or 0,
		target.Distance,
		dt,
		CombatCameraMath.MaxDistanceRate
	)
	local height, heightVelocity = spring(
		current.Height,
		current.HeightVelocity or 0,
		target.Height,
		dt,
		CombatCameraMath.MaxHeightRate
	)
	local fov, fovVelocity =
		spring(current.Fov, current.FovVelocity or 0, target.Fov, dt, CombatCameraMath.MaxFovRate)
	return {
		Distance = distance,
		Height = height,
		Fov = fov,
		DistanceVelocity = distanceVelocity,
		HeightVelocity = heightVelocity,
		FovVelocity = fovVelocity,
	}
end

return CombatCameraMath
