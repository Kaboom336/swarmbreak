local Feel = load("Feel")

test("freeze times stay inside the feel budget", function()
	for name, event in Feel.Events do
		assert(event.FreezeMs >= 0, name .. " freeze is below zero")
		assert(event.FreezeMs <= 80, name .. " freeze is above 80 ms")
	end
	eq(Feel.Events.Hit.FreezeMs, 0, "ordinary hits do not freeze")
	eq(Feel.Events.Kill.FreezeMs, 0, "ordinary kills do not freeze")
end)

test("shake settings respect accessibility levels", function()
	for name in Feel.Events do
		eq(Feel.shakeFor(name, "Off"), 0, name .. " off shake")
		assert(
			Feel.shakeFor(name, "Low") < Feel.shakeFor(name, "Full"),
			name .. " low shake should be below full"
		)
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
