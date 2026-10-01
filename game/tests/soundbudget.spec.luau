--!strict
local SoundBudget = load("SoundBudget")

local function fillGlobalCap()
	local state = SoundBudget.new()
	for index = 1, SoundBudget.GlobalCap do
		local allowed
		state, allowed = SoundBudget.allow(state, "sound " .. index, SoundBudget.P2, index)
		eq(allowed, true, "sound inside global cap")
	end
	return state
end

test("global cap drops lower priorities but never P0", function()
	local state = fillGlobalCap()
	local nextState, allowed = SoundBudget.allow(state, "another hit", SoundBudget.P2, 100)
	eq(allowed, false, "P2 refused at global cap")
	eq(nextState, state, "refused P2 keeps state")

	nextState, allowed = SoundBudget.allow(state, "ambience", SoundBudget.P3, 100)
	eq(allowed, false, "P3 refused at global cap")

	nextState, allowed = SoundBudget.allow(state, "player hurt", SoundBudget.P0, 100)
	eq(allowed, true, "P0 allowed at global cap")
	eq(nextState.Active, SoundBudget.GlobalCap + 1, "P0 is counted")
end)

test("per-name cap refuses another copy", function()
	local state = SoundBudget.new()
	for index = 1, SoundBudget.PerNameCap do
		local allowed
		state, allowed = SoundBudget.allow(state, "Hit", SoundBudget.P2, index)
		eq(allowed, true, "copy inside per-name cap")
	end

	local nextState, allowed = SoundBudget.allow(state, "Hit", SoundBudget.P2, 100)
	eq(allowed, false, "copy above per-name cap")
	eq(nextState.ActiveByName.Hit, SoundBudget.PerNameCap, "active copies unchanged")
end)

test("same name waits for the minimum interval", function()
	local state, allowed = SoundBudget.allow(SoundBudget.new(), "Hit", SoundBudget.P2, 10)
	eq(allowed, true, "first sound")

	local refused
	state, refused =
		SoundBudget.allow(state, "Hit", SoundBudget.P2, 10 + SoundBudget.MinIntervalSec - 0.001)
	eq(refused, false, "inside interval")

	state, allowed =
		SoundBudget.allow(state, "Hit", SoundBudget.P2, 10 + SoundBudget.MinIntervalSec)
	eq(allowed, true, "at interval boundary")
end)

test("release frees global and per-name slots", function()
	local state = fillGlobalCap()
	local released = SoundBudget.release(state, "sound 1", 100)
	eq(released.Active, SoundBudget.GlobalCap - 1, "global slot released")
	eq(released.ActiveByName["sound 1"], nil, "name slot released")

	local allowed
	released, allowed = SoundBudget.allow(released, "replacement", SoundBudget.P3, 101)
	eq(allowed, true, "released slot can be reused")
	eq(released.Active, SoundBudget.GlobalCap, "global count restored")
end)

test("allow and release do not mutate prior states", function()
	local original = SoundBudget.new()
	local allowedState, allowed = SoundBudget.allow(original, "Hit", SoundBudget.P2, 1)
	eq(allowed, true, "sound allowed")
	eq(original.Active, 0, "original active count")
	eq(original.ActiveByName.Hit, nil, "original name count")
	eq(original.LastPlayedAt.Hit, nil, "original timestamp")
	assert(allowedState ~= original, "allow returns a new state")

	local released = SoundBudget.release(allowedState, "Hit", 2)
	eq(allowedState.Active, 1, "allowed state remains active")
	eq(allowedState.ActiveByName.Hit, 1, "allowed name count remains")
	eq(released.Active, 0, "released state count")
	assert(released ~= allowedState, "release returns a new state")
end)
