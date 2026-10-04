local Feel = load("Feel")
local Enemies = load("Enemies")

test("hit feedback timings stay readable and immediate", function()
	assert(Feel.HitFlashSeconds >= 0.04, "hit flash is too short")
	assert(Feel.HitFlashSeconds <= 0.08, "hit flash is too long")
	assert(Feel.DamageNumberSeconds >= 0.4, "damage number is too brief")
	assert(Feel.DamageNumberSeconds <= 1, "damage number lingers too long")
end)

test("critical hits are bigger than normal hits", function()
	assert(
		Feel.Events.Crit.NumberScale > Feel.Events.Hit.NumberScale,
		"critical number scale should exceed normal hit scale"
	)
	assert(Feel.CritSparkScale > Feel.HitSparkScale, "critical spark should exceed normal spark")
end)

test("every enemy type has a death burst colour", function()
	for enemyType in Enemies.Defs do
		local color = Feel.DeathBurstColors[enemyType]
		assert(color ~= nil, enemyType .. " is missing a death burst colour")
		eq(#color, 3, enemyType .. " death burst colour channel count")
		for _, channel in color do
			assert(channel >= 0 and channel <= 255, enemyType .. " death burst colour channel")
		end
	end
end)

test("freeze times stay inside the feel budget", function()
	for name, event in Feel.Events do
		assert(event.FreezeMs >= 0, name .. " freeze is below zero")
		assert(event.FreezeMs <= 80, name .. " freeze is above 80 ms")
	end
	eq(Feel.Events.Hit.FreezeMs, 0, "ordinary hits do not freeze")
	eq(Feel.Events.Kill.FreezeMs, 50, "ordinary kill freeze")
	eq(Feel.Events.EliteKill.FreezeMs, 80, "elite kill freeze")
end)

test("shake settings respect accessibility levels", function()
	for name in Feel.Events do
		eq(Feel.shakeFor(name, "Off"), 0, name .. " off shake")
		local full = Feel.shakeFor(name, "Full")
		if full > 0 then
			assert(Feel.shakeFor(name, "Low") < full, name .. " low shake should be below full")
		else
			eq(Feel.shakeFor(name, "Low"), 0, name .. " no shake stays none on Low")
		end
	end
end)

test("damage number cap allows exactly N inside one second", function()
	local state = {}
	for _ = 1, Feel.NumberCapPerSecond do
		local allowed
		state, allowed = Feel.allowNumber(state, 10)
		eq(allowed, true, "number inside cap")
	end

	local allowed
	state, allowed = Feel.allowNumber(state, 10.999)
	eq(allowed, false, "number above cap")
	eq(#state, Feel.NumberCapPerSecond, "denied number is not recorded")

	state, allowed = Feel.allowNumber(state, 11)
	eq(allowed, true, "cap resumes after the window")
	eq(#state, 1, "expired timestamps are removed")
end)

test("damage number state is not mutated in place", function()
	local original = { 4, 4.5 }
	local nextState, allowed = Feel.allowNumber(original, 5)
	eq(allowed, true, "new number allowed")
	eq(#original, 2, "original length unchanged")
	eq(original[1], 4, "original timestamp unchanged")
	assert(nextState ~= original, "returns a new state table")
	eq(#nextState, 2, "expired entry replaced by current timestamp")
end)
