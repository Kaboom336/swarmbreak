--!strict
-- Pure validation for client fire requests. Roblox vectors are converted at the call site.
export type Point3 = {
	x: number,
	y: number,
	z: number,
}

local FireGuard = {}

FireGuard.MaximumOriginDistance = 8
FireGuard.FireRateTolerance = 0.1

local function isFinite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

local function isFinitePoint(point: Point3): boolean
	return isFinite(point.x) and isFinite(point.y) and isFinite(point.z)
end

function FireGuard.validate(
	now: number,
	lastAcceptedAt: number?,
	fireRate: number,
	origin: Point3,
	characterPosition: Point3,
	direction: Point3
): boolean
	if not isFinitePoint(direction) then
		return false
	end

	local directionLengthSquared = direction.x ^ 2 + direction.y ^ 2 + direction.z ^ 2
	if directionLengthSquared < 0.0001 then
		return false
	end

	if not isFinitePoint(origin) or not isFinitePoint(characterPosition) then
		return false
	end
	local dx = origin.x - characterPosition.x
	local dy = origin.y - characterPosition.y
	local dz = origin.z - characterPosition.z
	local distanceSquared = dx ^ 2 + dy ^ 2 + dz ^ 2
	if distanceSquared > FireGuard.MaximumOriginDistance ^ 2 then
		return false
	end

	if not isFinite(now) or not isFinite(fireRate) or fireRate <= 0 then
		return false
	end
	if lastAcceptedAt ~= nil then
		local minimumInterval = (1 / fireRate) * (1 - FireGuard.FireRateTolerance)
		if now - lastAcceptedAt < minimumInterval then
			return false
		end
	end

	return true
end

return FireGuard
