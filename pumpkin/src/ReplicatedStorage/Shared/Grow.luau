--!strict
local Config = require(script.Parent.Config)

export type Modifiers = {
	rebirths: number?,
	petMultipliers: { number }?,
	doubleSize: boolean?,
	vip: boolean?,
	friendBoost: number?,
}

export type RateLimiter = {
	allow: (self: RateLimiter, key: any, now: number) -> boolean,
	clear: (self: RateLimiter, key: any) -> (),
}

local Grow = {}

function Grow.stackMultipliers(additive: { number }?, multiplicative: { number }?): number
	local total = 1
	if additive then
		for _, bonus in additive do
			total += bonus
		end
	end
	if multiplicative then
		for _, multiplier in multiplicative do
			total *= multiplier
		end
	end
	return total
end

function Grow.multiplier(modifiers: Modifiers?): number
	local values = modifiers or {}
	local additive = {
		math.max(0, values.rebirths or 0) * Config.RebirthSizeBonus,
		math.clamp(values.friendBoost or 0, 0, 0.5),
	}
	local petTotal = 0
	for _, petMultiplier in values.petMultipliers or {} do
		petTotal += math.max(0, petMultiplier)
	end
	if petTotal > 0 then
		table.insert(additive, petTotal - 1)
	end

	local multiplicative = {}
	if values.doubleSize then
		table.insert(multiplicative, 2)
	end
	if values.vip then
		table.insert(multiplicative, 1.5)
	end
	return Grow.stackMultipliers(additive, multiplicative)
end

function Grow.amount(modifiers: Modifiers?): number
	return Config.SizePerClick * Grow.multiplier(modifiers)
end

function Grow.pumpkinScale(size: number): number
	local safeSize = math.max(0, size)
	local logarithm = math.log(safeSize + 1) / math.log(10)
	return math.min(
		Config.PumpkinMaxScale,
		Config.PumpkinBaseScale + logarithm * Config.PumpkinLogScale
	)
end

function Grow.newRateLimiter(limit: number?, windowSeconds: number?): RateLimiter
	local maximum = limit or Config.ClicksPerSecond
	local window = windowSeconds or Config.ClickWindowSeconds
	assert(maximum > 0, "rate limit must be positive")
	assert(window > 0, "rate window must be positive")

	local timestamps: { [any]: { number } } = {}
	local limiter = {} :: any

	function limiter:allow(key: any, now: number): boolean
		local history = timestamps[key]
		if not history then
			history = {}
			timestamps[key] = history
		end

		local firstValid = 1
		while firstValid <= #history and now - history[firstValid] >= window do
			firstValid += 1
		end
		if firstValid > 1 then
			local kept = {}
			for index = firstValid, #history do
				table.insert(kept, history[index])
			end
			history = kept
			timestamps[key] = history
		end

		if #history >= maximum then
			return false
		end
		table.insert(history, now)
		return true
	end

	function limiter:clear(key: any)
		timestamps[key] = nil
	end

	return limiter
end

return Grow
