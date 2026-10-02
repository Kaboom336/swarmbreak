--!strict
-- Pure target scoring and shot cadence for automatic combat.
export type Position = {
	x: number,
	y: number?,
	z: number,
}

export type Target = {
	position: Position,
	velocity: Position?,
	boss: boolean?,
	visible: boolean?,
}

local AutoAim = {}

AutoAim.BossWeight = 1.3
AutoAim.Hysteresis = 0.15
AutoAim.ClosingSpeedForMaximumWeight = 20
AutoAim.MaximumClosingWeight = 1.2

local function distanceAndScore(
	origin: Position,
	target: Target,
	maxRange: number
): (number?, number?)
	if maxRange < 0 or target.visible == false then
		return nil, nil
	end

	local dx = target.position.x - origin.x
	local dy = (target.position.y or 0) - (origin.y or 0)
	local dz = target.position.z - origin.z
	local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
	if distance > maxRange then
		return nil, nil
	end

	local closingSpeed = 0
	if target.velocity and distance > 0 then
		closingSpeed = math.max(
			0,
			-(target.velocity.x * dx + (target.velocity.y or 0) * dy + target.velocity.z * dz)
				/ distance
		)
	end
	local closingAlpha = math.clamp(closingSpeed / AutoAim.ClosingSpeedForMaximumWeight, 0, 1)
	local closingWeight = 1 + closingAlpha * (AutoAim.MaximumClosingWeight - 1)
	local bossWeight = if target.boss == true then AutoAim.BossWeight else 1

	return distance, distance / (closingWeight * bossWeight)
end

function AutoAim.pickTarget(
	origin: Position,
	targets: { Target },
	maxRange: number,
	currentIndex: number?
): number?
	local bestIndex: number? = nil
	local bestScore = math.huge
	local bestIsBoss = false
	for index, target in targets do
		local _, score = distanceAndScore(origin, target, maxRange)
		local isBoss = target.boss == true
		if score and (score < bestScore or (score == bestScore and isBoss and not bestIsBoss)) then
			bestIndex = index
			bestScore = score
			bestIsBoss = isBoss
		end
	end

	if currentIndex then
		local current = targets[currentIndex]
		local currentScore: number? = nil
		if current then
			local _, score = distanceAndScore(origin, current, maxRange)
			currentScore = score
		end
		if currentScore then
			if bestIndex == currentIndex or bestScore > currentScore * (1 - AutoAim.Hysteresis) then
				return currentIndex
			end
		end
	end

	return bestIndex
end

function AutoAim.canFire(now: number, lastFiredAt: number?, fireRate: number): boolean
	if fireRate <= 0 or fireRate ~= fireRate then
		return false
	end
	return lastFiredAt == nil or now - lastFiredAt >= 1 / fireRate
end

return AutoAim
