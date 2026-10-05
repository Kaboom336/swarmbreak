--!strict
local Config = require(script.Parent.Config)

export type BonusKind = "Candy" | "GoldPumpkin" | "SpeedPad"

export type BonusTarget = {
	id: number,
	kind: BonusKind,
	lane: number,
	time: number,
}

local MODULUS = 2_147_483_647
local MULTIPLIER = 48_271
local QUOTIENT = 44_488
local REMAINDER = 3_399

local Ride = {}

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
	return math.clamp(7 + 0.5 * math.log10(math.max(0, size) + 1), 7, 10)
end

function Ride.bonusDuration(bonusWalls: number): number
	local count = math.clamp(math.floor(bonusWalls), 0, Config.MaxBonusWalls)
	-- A steady pace per bonus wall (not a fixed squeeze), so 15 bonus walls take about 2.3 s, not 1 s
	return math.min(Config.BonusZoneMaxSeconds, count * Config.BonusSecondsPerWall)
end

function Ride.duration(size: number, bonusWalls: number): number
	return Ride.physicalDuration(size) + Ride.bonusDuration(bonusWalls)
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

function Ride.finalWins(baseWins: number, kinds: { BonusKind }, multipliers: { number }): number
	local wins = math.max(0, baseWins) * bonusMultiplier(kinds)
	for _, multiplier in multipliers do
		wins *= math.max(0, multiplier)
	end
	return math.floor(wins)
end

function Ride.comboText(wallsBroken: number): string?
	local count = math.max(0, math.floor(wallsBroken))
	return if count > 0 then "WALL x" .. count .. "!" else nil
end

return Ride
