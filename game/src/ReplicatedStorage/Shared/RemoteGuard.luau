--!strict
-- Per-player, per-action request validation and token-bucket throttling.
local RemoteGuard = {}

RemoteGuard.Actions = {
	Shop = "shop",
	Settings = "settings",
	Equip = "equip",
	Evolution = "evolution",
	Code = "code",
	Reward = "reward",
	Tutorial = "tutorial",
}

RemoteGuard.Policies = {
	shop = { Capacity = 4, RefillPerSecond = 1 },
	settings = { Capacity = 4, RefillPerSecond = 2 },
	equip = { Capacity = 4, RefillPerSecond = 2 },
	evolution = { Capacity = 2, RefillPerSecond = 0.5 },
	code = { Capacity = 1, RefillPerSecond = 0.5 },
	reward = { Capacity = 2, RefillPerSecond = 1 },
	tutorial = { Capacity = 4, RefillPerSecond = 2 },
}

RemoteGuard.Limits = {
	MaxStringBytes = 128,
	MaxTableEntries = 32,
	MaxTableDepth = 4,
}

type Bucket = {
	Tokens: number,
	UpdatedAt: number,
}

type Policy = {
	Capacity: number,
	RefillPerSecond: number,
}

local Guard = {}
Guard.__index = Guard

local function isFinite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

local function validateValue(
	value: any,
	depth: number,
	entryCount: { Value: number },
	activeTables: { [any]: boolean }
): boolean
	local kind = typeof(value)
	if kind == "nil" or kind == "boolean" then
		return true
	elseif kind == "number" then
		return isFinite(value)
	elseif kind == "string" then
		return #value <= RemoteGuard.Limits.MaxStringBytes
	elseif kind ~= "table" or depth >= RemoteGuard.Limits.MaxTableDepth then
		return false
	end

	if activeTables[value] then
		return false
	end
	activeTables[value] = true
	for key, child in value do
		entryCount.Value += 1
		if entryCount.Value > RemoteGuard.Limits.MaxTableEntries then
			activeTables[value] = nil
			return false
		end
		if
			not validateValue(key, depth + 1, entryCount, activeTables)
			or not validateValue(child, depth + 1, entryCount, activeTables)
		then
			activeTables[value] = nil
			return false
		end
	end
	activeTables[value] = nil
	return true
end

function RemoteGuard.validatePayload(payload: any): boolean
	return validateValue(payload, 0, { Value = 0 }, {})
end

function RemoteGuard.new(clock: (() -> number)?)
	return setmetatable({
		_clock = clock or os.clock,
		_buckets = {} :: { [any]: { [string]: Bucket } },
	}, Guard)
end

-- Returns whether the request is accepted and, when throttled, the exact seconds
-- until one token is available. Invalid payloads return false, 0.
function Guard:allow(subject: any, action: string, payload: any): (boolean, number)
	local policy = RemoteGuard.Policies[action] :: Policy?
	if subject == nil or policy == nil or not RemoteGuard.validatePayload(payload) then
		return false, 0
	end

	local now = self._clock()
	if not isFinite(now) then
		return false, 0
	end

	local subjectBuckets = self._buckets[subject]
	if subjectBuckets == nil then
		subjectBuckets = {}
		self._buckets[subject] = subjectBuckets
	end

	local bucket = subjectBuckets[action]
	if bucket == nil then
		bucket = { Tokens = policy.Capacity, UpdatedAt = now }
		subjectBuckets[action] = bucket
	else
		local elapsed = math.max(0, now - bucket.UpdatedAt)
		bucket.Tokens = math.min(policy.Capacity, bucket.Tokens + elapsed * policy.RefillPerSecond)
		bucket.UpdatedAt = math.max(bucket.UpdatedAt, now)
	end

	if bucket.Tokens >= 1 then
		bucket.Tokens -= 1
		return true, 0
	end

	return false, (1 - bucket.Tokens) / policy.RefillPerSecond
end

function Guard:clear(subject: any)
	self._buckets[subject] = nil
end

return RemoteGuard
