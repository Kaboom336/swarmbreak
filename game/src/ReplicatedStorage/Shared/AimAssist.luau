--!strict
export type Position = {
	x: number,
	z: number,
}

local AimAssist = {}
AimAssist.PcConeDegrees = 6

local function distanceSquared(a: Position, b: Position): number
	local x = a.x - b.x
	local z = a.z - b.z
	return x * x + z * z
end

local function pick(
	origin: Position,
	facing: Position,
	enemies: { Position },
	maxRange: number,
	maxAngleDeg: number,
	fallbackToNearest: boolean
): number?
	if maxRange < 0 then
		return nil
	end

	local rangeSquared = maxRange * maxRange
	local facingLengthSquared = facing.x * facing.x + facing.z * facing.z
	local coneDotMinimum = math.cos(math.rad(math.clamp(maxAngleDeg, 0, 180)))
	local nearestIndex: number? = nil
	local nearestDistanceSquared = math.huge
	local coneIndex: number? = nil
	local coneDistanceSquared = math.huge

	for index, enemy in enemies do
		local enemyDistanceSquared = distanceSquared(origin, enemy)
		if enemyDistanceSquared <= rangeSquared then
			if enemyDistanceSquared < nearestDistanceSquared then
				nearestIndex = index
				nearestDistanceSquared = enemyDistanceSquared
			end

			local insideCone = enemyDistanceSquared == 0
			if not insideCone and facingLengthSquared > 0 then
				local toEnemyX = enemy.x - origin.x
				local toEnemyZ = enemy.z - origin.z
				local dot = facing.x * toEnemyX + facing.z * toEnemyZ
				insideCone = dot / math.sqrt(facingLengthSquared * enemyDistanceSquared)
					>= coneDotMinimum
			end
			if insideCone and enemyDistanceSquared < coneDistanceSquared then
				coneIndex = index
				coneDistanceSquared = enemyDistanceSquared
			end
		end
	end

	return coneIndex or if fallbackToNearest then nearestIndex else nil
end

-- Soft aim assist never drags aim to a target outside the configured cone.
function AimAssist.pickTargetInCone(
	origin: Position,
	facing: Position,
	enemies: { Position },
	maxRange: number,
	maxAngleDeg: number
): number?
	return pick(origin, facing, enemies, maxRange, maxAngleDeg, false)
end

-- Touch auto-aim keeps its wider-cone nearest-target fallback.
function AimAssist.pickTarget(
	origin: Position,
	facing: Position,
	enemies: { Position },
	maxRange: number,
	maxAngleDeg: number
): number?
	return pick(origin, facing, enemies, maxRange, maxAngleDeg, true)
end

return AimAssist
