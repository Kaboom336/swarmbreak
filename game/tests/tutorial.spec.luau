local Tutorial = load("Tutorial")
local ProfileSchema = load("ProfileSchema")

test("steps are in first-run order with plain English hints", function()
	local expected = { "Move", "Shoot", "Dash", "Pick", "Upgrade", "Crate" }
	eq(#Tutorial.Steps, #expected, "step count")
	for i, id in expected do
		eq(Tutorial.Steps[i].Id, id, "step " .. i)
		assert(Tutorial.Steps[i].Hint ~= "", "step " .. i .. " has a hint")
	end
	eq(Tutorial.Steps[3].Hint, "Press Shift to dash", "dash hint")
end)

test("next returns the first unfinished step", function()
	eq(Tutorial.next({}).Id, "Move", "fresh profile")
	eq(Tutorial.next({ Tut_Move = true }).Id, "Shoot", "after moving")
	eq(
		Tutorial.next({ Tut_Move = true, Tut_Shoot = true, Tut_Dash = true }).Id,
		"Pick",
		"after controls"
	)
end)

test("next returns nil when every step is done", function()
	local flags = {}
	for _, step in Tutorial.Steps do
		flags = Tutorial.complete(flags, step.Id)
	end
	eq(Tutorial.next(flags), nil, "tutorial complete")
end)

test("complete returns new flags and keeps the input unchanged", function()
	local flags = { FirstBossCrate = true }
	local completed = Tutorial.complete(flags, "Move")
	eq(flags.Tut_Move, nil, "input unchanged")
	eq(completed.Tut_Move, true, "prefixed completion")
	eq(completed.FirstBossCrate, true, "other flags kept")
	assert(completed ~= flags, "a new flags table is returned")
end)

test("complete ignores unknown step ids", function()
	local completed = Tutorial.complete({ Tut_Move = true }, "Bogus")
	eq(completed.Tut_Move, true, "known flag kept")
	eq(completed.Tut_Bogus, nil, "unknown flag not added")
end)

test("tutorial completion flags survive profile sanitizing", function()
	local profile = ProfileSchema.sanitize({
		Flags = { Tut_Move = true, Tut_Dash = true, Tut_Bogus = true },
	})
	eq(profile.Flags.Tut_Move, true, "move kept")
	eq(profile.Flags.Tut_Dash, true, "dash kept")
	eq(profile.Flags.Tut_Bogus, nil, "unknown tutorial flag dropped")
end)
