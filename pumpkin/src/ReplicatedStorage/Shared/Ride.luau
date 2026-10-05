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

function Ride.layout(seed: number, count: number?): { BonusTarget }
	local targetCount = count or Config.RideBonusTargetCount
	assert(targetCount >= 0 and targetCount % 1 == 0, "target count must be a non-negative integer")
	local random = makeRandom(seed)
	local targets = {}
	for index = 1, targetCount do
		local lane = math.floor(random() * 3) - 1
		local kindRoll = random()
		local kind: BonusKind
		if kindRoll < 0.5 then
			kind = "Candy"
		elseif kindRoll < 0.72 then
			kind = "GoldPumpkin"
		else
			kind = "SpeedPad"
		end
		local spacing = 0.68 / math.max(1, targetCount)
		local time = 0.16 + (index - 0.5) * spacing + (random() - 0.5) * spacing * 0.35
		table.insert(targets, {
			id = index,
			kind = kind,
			lane = lane,
			time = math.clamp(time, 0.12, 0.88),
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

function Ride.validatePickup(
	target: BonusTarget?,
	elapsed: number,
	duration: number,
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
	local expected = Ride.elapsedForProgress(target.time, duration)
	if math.abs(elapsed - expected) > Config.RidePickupTimeTolerance then
		return false, "time"
	end
	return true, nil
end

function Ride.winsWithBonuses(baseWins: number, kinds: { BonusKind }): number
	local candy = 0
	local gold = 0
	for _, kind in kinds do
		if kind == "Candy" then
			candy += 1
		elseif kind == "GoldPumpkin" then
			gold += 1
		end
	end
	local candyMultiplier = 1 + candy * Config.RideCandyWinBonus
	local goldMultiplier = Config.RideGoldWinMultiplier ^ gold
	return math.floor(math.max(0, baseWins) * candyMultiplier * goldMultiplier)
end

function Ride.comboText(wallsBroken: number): string?
	local count = math.max(0, math.floor(wallsBroken))
	return if count > 0 then "WALL x" .. count .. "!" else nil
end

return Ride
