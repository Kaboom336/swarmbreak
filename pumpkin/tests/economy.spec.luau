--!strict
local Economy = load("Economy")

test("five clicks per second reaches the target progression windows", function()
	local result = Economy.simulate(40, 5)
	local forest = result.forestUnlockMinutes
	local rebirth = result.firstRebirthMinutes
	local graveyard = result.graveyardUnlockMinutes
	eq(forest ~= nil and forest >= 2 and forest <= 4, true, "Forest unlocks in 2-4 minutes")
	eq(rebirth ~= nil and rebirth >= 8 and rebirth <= 15, true, "first rebirth is in 8-15 minutes")
	eq(
		graveyard ~= nil and graveyard >= 20 and graveyard <= 40,
		true,
		"Graveyard unlocks in 20-40 minutes"
	)
end)

test("economy simulation validates its inputs", function()
	eq(pcall(Economy.simulate, -1, 5), false, "negative minutes")
	eq(pcall(Economy.simulate, 1, 0), false, "zero click rate")
end)
