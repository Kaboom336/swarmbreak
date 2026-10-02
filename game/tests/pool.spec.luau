--!strict
local PoolSize = load("PoolSize")

test("acquire and release reuse pre-created objects", function()
	local created = 0
	local pool = PoolSize.new(2, function()
		created += 1
		return { Id = created }
	end)

	local first = PoolSize.acquire(pool)
	local second = PoolSize.acquire(pool)
	eq(created, 2, "pool is pre-created")
	assert(first ~= second, "available objects are acquired before reuse")

	eq(PoolSize.release(pool, first), true, "acquired object releases")
	eq(PoolSize.acquire(pool), first, "released object is reused")
	eq(created, 2, "reuse creates no object")
end)

test("pool never exceeds its cap", function()
	local created = 0
	local pool = PoolSize.new(2, function()
		created += 1
		return { Id = created }
	end)

	PoolSize.acquire(pool)
	PoolSize.acquire(pool)
	PoolSize.acquire(pool)
	PoolSize.acquire(pool)
	eq(PoolSize.count(pool), 2, "entry count stays capped")
	eq(created, 2, "factory only runs during pre-creation")
end)

test("oldest object is recycled when every object is busy", function()
	local pool = PoolSize.new(3, function(index)
		return { Id = index }
	end)

	local oldest = PoolSize.acquire(pool)
	local second = PoolSize.acquire(pool)
	local third = PoolSize.acquire(pool)
	eq(PoolSize.acquire(pool), oldest, "oldest busy object recycled first")
	eq(PoolSize.acquire(pool), second, "recycling order advances")
	assert(oldest ~= second and second ~= third, "pool began with distinct objects")
end)

test("quality levels select increasing effect budgets", function()
	local low = PoolSize.forQuality(2)
	local medium = PoolSize.forQuality(5)
	local high = PoolSize.forQuality(9)

	for _, name in { "Tracers", "HitSparks", "DamageNumbers", "GooDecals" } do
		assert(low[name] > 0, name .. " low budget is positive")
		assert(low[name] < medium[name], name .. " medium budget increases")
		assert(medium[name] < high[name], name .. " high budget increases")
	end
end)
