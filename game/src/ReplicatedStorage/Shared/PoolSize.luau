--!strict
-- Quality-scaled effect budgets and pure capped-pool bookkeeping.

export type Sizes = {
	Tracers: number,
	HitSparks: number,
	DamageNumbers: number,
	GooDecals: number,
}

export type Pool<T> = {
	Capacity: number,
	Entries: { T },
	InUse: { [number]: boolean },
	LastAcquired: { [number]: number },
	Sequence: number,
}

local PoolSize = {}

local LOW: Sizes = {
	Tracers = 16,
	HitSparks = 12,
	DamageNumbers = 10,
	GooDecals = 6,
}
local MEDIUM: Sizes = {
	Tracers = 32,
	HitSparks = 24,
	DamageNumbers = 20,
	GooDecals = 12,
}
local HIGH: Sizes = {
	Tracers = 48,
	HitSparks = 36,
	DamageNumbers = 30,
	GooDecals = 18,
}

local function copySizes(sizes: Sizes): Sizes
	return {
		Tracers = sizes.Tracers,
		HitSparks = sizes.HitSparks,
		DamageNumbers = sizes.DamageNumbers,
		GooDecals = sizes.GooDecals,
	}
end

function PoolSize.forQuality(level: number): Sizes
	if level <= 3 then
		return copySizes(LOW)
	elseif level <= 7 then
		return copySizes(MEDIUM)
	end
	return copySizes(HIGH)
end

function PoolSize.new<T>(capacity: number, create: (number) -> T): Pool<T>
	assert(capacity >= 1 and capacity % 1 == 0, "capacity must be a positive integer")
	local entries = table.create(capacity)
	for index = 1, capacity do
		entries[index] = create(index)
	end
	return {
		Capacity = capacity,
		Entries = entries,
		InUse = {},
		LastAcquired = {},
		Sequence = 0,
	}
end

function PoolSize.acquire<T>(pool: Pool<T>): T
	local selected = 0
	for index = 1, pool.Capacity do
		if not pool.InUse[index] then
			selected = index
			break
		end
	end

	if selected == 0 then
		selected = 1
		local oldest = pool.LastAcquired[selected] or 0
		for index = 2, pool.Capacity do
			local acquiredAt = pool.LastAcquired[index] or 0
			if acquiredAt < oldest then
				selected = index
				oldest = acquiredAt
			end
		end
	end

	pool.Sequence += 1
	pool.InUse[selected] = true
	pool.LastAcquired[selected] = pool.Sequence
	return pool.Entries[selected]
end

function PoolSize.release<T>(pool: Pool<T>, entry: T): boolean
	for index, candidate in pool.Entries do
		if candidate == entry then
			pool.InUse[index] = nil
			return true
		end
	end
	return false
end

function PoolSize.count<T>(pool: Pool<T>): number
	return #pool.Entries
end

return PoolSize
