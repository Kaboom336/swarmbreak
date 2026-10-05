--!strict
local Config = require(script.Parent.Config)

export type BonusKind = "Candy" | "GoldPumpkin" | "SpeedPad"

export type BonusTarget = {
	id: number,
	kind: BonusKind,
	lane: number,
	time: number,
}

export type ObstacleKind = "RollingLog" | "Tombstone" | "LowFence"

export type ObstacleWave = {
	id: number,
	kind: ObstacleKind,
	time: number,
	lanes: { number },
	freeLane: number,
}

export type PathSample = {
	forward: number,
	height: number,
	lateral: number,
	forwardTangent: number,
	heightTangent: number,
	lateralTangent: number,
	bank: number,
}

local MODULUS = 2_147_483_647
local MULTIPLIER = 48_271
local QUOTIENT = 44_488
local REMAINDER = 3_399

local Ride = {}

function Ride.axleRotation(distance: number, radius: number): number
	if radius <= 0 then
		return 0
	end
	return -distance / radius
end

local function makeRandom(seed: number): () -> number
	local state = math.floor(math.abs(seed)) % (MODULUS - 1) + 1
	return function()
		local high = math.floor(state / QUOTIENT)
		local low = state % QUOTIENT
		state = MULTIPLIER * low - REMAINDER * high
		if state <= 0 then
			state += MODULUS
		end
		return state / MODULUS
	end
end

function Ride.physicalDuration(size: number): number
	local sizeEase = math.clamp(math.log10(math.max(0, size) + 1) / 6, 0, 1)
	return Config.RidePhysicalSeconds + sizeEase * 0.5
end

function Ride.bonusDuration(bonusWalls: number): number
	local count = math.clamp(math.floor(bonusWalls), 0, Config.MaxBonusWalls)
	-- A steady pace per bonus wall (not a fixed squeeze), so 15 bonus walls take about 2.3 s, not 1 s
	return math.min(Config.BonusZoneMaxSeconds, count * Config.BonusSecondsPerWall)
end

function Ride.duration(size: number, bonusWalls: number): number
	return math.min(14, Ride.physicalDuration(size) + Ride.bonusDuration(bonusWalls))
end

function Ride.speedAtTime(
	elapsed: number,
	duration: number,
	speedScale: number?,
	boostScale: number?
): number
	local alpha = math.clamp(elapsed / math.max(duration, 0.001), 0, 1)
	local eased = alpha * alpha * (3 - 2 * alpha)
	local base = Config.RideStartSpeed + (Config.RideTopSpeed - Config.RideStartSpeed) * eased
	return base * math.max(0, speedScale or 1) * math.max(0, boostScale or 1)
end

function Ride.speedScaleAfterHit(elapsedSinceHit: number): number
	local recovery = math.clamp(elapsedSinceHit / Config.RideHitRecoverySeconds, 0, 1)
	return Config.RideHitSpeedScale + (1 - Config.RideHitSpeedScale) * recovery
end

function Ride.baseDistanceAtTime(elapsed: number, duration: number): number
	local clamped = math.clamp(elapsed, 0, math.max(0, duration))
	if duration <= 0 then
		return 0
	end
	local delta = Config.RideTopSpeed - Config.RideStartSpeed
	local normalized = clamped / duration
	-- Integral of smoothstep (3a^2 - 2a^3).
	return Config.RideStartSpeed * clamped
		+ delta * duration * (normalized ^ 3 - 0.5 * normalized ^ 4)
end

function Ride.timeAtBaseDistance(distance: number, duration: number): number
	local low = 0
	local high = math.max(0, duration)
	for _ = 1, 24 do
		local midpoint = (low + high) * 0.5
		if Ride.baseDistanceAtTime(midpoint, duration) < math.max(0, distance) then
			low = midpoint
		else
			high = midpoint
		end
	end
	return (low + high) * 0.5
end

function Ride.pathSample(distance: number): PathSample
	local traveled = math.clamp(distance, 0, Config.RideTrackLength)
	local slope = math.rad(Config.RideSlopeDegrees)
	local curveAngle = traveled / Config.RidePathCurveLength * math.pi * 2
	local lateral = Config.RidePathCurveStuds * (1 - math.cos(curveAngle)) * 0.5
	local lateralDerivative = Config.RidePathCurveStuds
		* math.pi
		/ Config.RidePathCurveLength
		* math.sin(curveAngle)
	local forwardDerivative = math.cos(slope)
	local heightDerivative = -math.sin(slope)
	local magnitude =
		math.sqrt(forwardDerivative ^ 2 + heightDerivative ^ 2 + lateralDerivative ^ 2)
	local turn = math.sin(curveAngle)
	return {
		forward = traveled * forwardDerivative,
		height = traveled * heightDerivative,
		lateral = lateral,
		forwardTangent = forwardDerivative / magnitude,
		heightTangent = heightDerivative / magnitude,
		lateralTangent = lateralDerivative / magnitude,
		bank = math.rad(Config.RideBankDegrees) * turn,
	}
end

function Ride.layout(seed: number, duration: number?, count: number?): { BonusTarget }
	local targetCount = count or Config.RideBonusTargetCount
	assert(targetCount >= 0 and targetCount % 1 == 0, "target count must be a non-negative integer")
	local rideDuration = duration or 8
	assert(rideDuration > 0, "duration must be positive")
	local random = makeRandom(seed)
	local kinds: { BonusKind } = { "SpeedPad" }
	local goldCount = 0
	for _ = 2, targetCount do
		local roll = random()
		local kind: BonusKind
		if roll < 0.22 and goldCount < 2 then
			kind = "GoldPumpkin"
			goldCount += 1
		else
			kind = "Candy"
		end
		table.insert(kinds, kind)
	end
	for index = #kinds, 2, -1 do
		local swapIndex = math.floor(random() * index) + 1
		kinds[index], kinds[swapIndex] = kinds[swapIndex], kinds[index]
	end

	local targets = {}
	for index = 1, targetCount do
		local lane = math.floor(random() * 3) - 1
		local startTime = rideDuration * 0.15
		local endTime = rideDuration * 0.85
		local spacing = if targetCount > 1 then (endTime - startTime) / (targetCount - 1) else 0
		local jitter = if index == 1 or index == targetCount then 0 else (random() - 0.5) * 0.1
		local time = startTime + (index - 1) * spacing + jitter
		table.insert(targets, {
			id = index,
			kind = kinds[index],
			lane = lane,
			time = time,
		})
	end
	return targets
end

function Ride.obstacleLayout(seed: number, duration: number?, count: number?): { ObstacleWave }
	local waveCount = count or Config.RideObstacleCount
	assert(waveCount >= 0 and waveCount % 1 == 0, "obstacle count must be a non-negative integer")
	local rideDuration = duration or Config.RidePhysicalSeconds
	local random = makeRandom(seed + 91_337)
	local kinds: { ObstacleKind } = { "RollingLog", "Tombstone", "LowFence" }
	local waves = {}
	local firstTime = math.max(Config.RideGentleStartSeconds + 0.8, rideDuration * 0.24)
	local lastTime = rideDuration * 0.88
	for index = 1, waveCount do
		local alpha = if waveCount > 1 then (index - 1) / (waveCount - 1) else 0
		local freeLane = math.floor(random() * 3) - 1
		local occupied = {}
		for lane = -1, 1 do
			if lane ~= freeLane and (index > 1 or #occupied == 0) then
				table.insert(occupied, lane)
			end
		end
		table.insert(waves, {
			id = index,
			kind = kinds[(index - 1) % #kinds + 1],
			time = firstTime + (lastTime - firstTime) * alpha,
			lanes = occupied,
			freeLane = freeLane,
		})
	end
	return waves
end

function Ride.waveHitsLane(wave: ObstacleWave, lane: number): boolean
	for _, obstacleLane in wave.lanes do
		if math.abs(lane - obstacleLane) <= Config.RideObstacleLaneTolerance then
			return true
		end
	end
	return false
end

function Ride.snapLane(lane: number, direction: number): number
	local current = math.clamp(math.floor(lane + 0.5), -1, 1)
	return math.clamp(current + (if direction < 0 then -1 else 1), -1, 1)
end

function Ride.progress(elapsed: number, duration: number): number
	if duration <= 0 then
		return 1
	end
	local alpha = math.clamp(elapsed / duration, 0, 1)
	return alpha ^ Config.RideSlopeAcceleration
end

function Ride.elapsedForProgress(progress: number, duration: number): number
	return math.clamp(progress, 0, 1) ^ (1 / Config.RideSlopeAcceleration) * math.max(0, duration)
end

function Ride.distanceAtTime(
	elapsed: number,
	physicalDuration: number,
	physicalDistance: number,
	bonusDuration: number,
	bonusDistance: number
): number
	if elapsed <= physicalDuration then
		return physicalDistance * Ride.progress(elapsed, physicalDuration)
	end
	if bonusDuration <= 0 then
		return physicalDistance
	end
	local bonusAlpha = math.clamp((elapsed - physicalDuration) / bonusDuration, 0, 1)
	return physicalDistance + bonusDistance * bonusAlpha
end

function Ride.validatePickup(
	target: BonusTarget?,
	elapsed: number,
	_duration: number,
	lane: number,
	claimed: { [number]: boolean },
	claimedCount: number
): (boolean, string?)
	if claimedCount >= Config.RideMaxPickups then
		return false, "cap"
	end
	if not target then
		return false, "unknown"
	end
	if claimed[target.id] then
		return false, "claimed"
	end
	if math.abs(lane - target.lane) > Config.RidePickupLaneTolerance then
		return false, "lane"
	end
	local expected = target.time
	if math.abs(elapsed - expected) > Config.RidePickupTimeTolerance then
		return false, "time"
	end
	return true, nil
end

function Ride.validatePickupSpatial(
	target: BonusTarget?,
	elapsed: number,
	duration: number,
	lane: number,
	longitudinalError: number,
	claimed: { [number]: boolean },
	claimedCount: number
): (boolean, string?)
	local accepted, reason =
		Ride.validatePickup(target, elapsed, duration, lane, claimed, claimedCount)
	if not accepted then
		return false, reason
	end
	if math.abs(longitudinalError) > Config.RideStartSpeed * Config.RidePickupTimeTolerance then
		return false, "position"
	end
	return true, nil
end

local function bonusMultiplier(kinds: { BonusKind }): number
	local candy = 0
	local gold = 0
	for _, kind in kinds do
		if kind == "Candy" then
			candy += 1
		elseif kind == "GoldPumpkin" then
			gold += 1
		end
	end
	-- Bonuses add up instead of compounding, so 6 golds give x7, not x64
	return 1 + candy * Config.RideCandyWinBonus + gold * (Config.RideGoldWinMultiplier - 1)
end

function Ride.winsWithBonuses(baseWins: number, kinds: { BonusKind }): number
	return math.floor(math.max(0, baseWins) * bonusMultiplier(kinds))
end

function Ride.comboMultiplier(combo: number): number
	return math.min(Config.RideComboCap, 1 + math.max(0, math.floor(combo)) * Config.RideComboStep)
end

function Ride.finalWins(
	baseWins: number,
	kinds: { BonusKind },
	multipliers: { number },
	combo: number?
): number
	local wins = math.max(0, baseWins) * bonusMultiplier(kinds)
	for _, multiplier in multipliers do
		wins *= math.max(0, multiplier)
	end
	wins *= Ride.comboMultiplier(combo or 0)
	return math.floor(wins)
end

function Ride.comboText(combo: number): string?
	local count = math.max(0, math.floor(combo))
	return if count > 0
		then string.format("COMBO %d  x%.1f", count, Ride.comboMultiplier(count))
		else nil
end

return Ride
