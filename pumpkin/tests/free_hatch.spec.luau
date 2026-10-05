--!strict
local HatchEntitlements = load("HatchEntitlements")

test("first Candy Egg hatch is free only once", function()
	local state = { freeCandyUsed = false, freeSpookyHatches = 0 }
	local firstCost, afterFirst = HatchEntitlements.cost("CandyEgg", 1, 100, state)
	eq(firstCost, 0, "first cost")
	eq(afterFirst.freeCandyUsed, true, "entitlement consumed")
	local secondCost = HatchEntitlements.cost("CandyEgg", 1, 100, afterFirst)
	eq(secondCost, 100, "second cost")
	eq(state.freeCandyUsed, false, "pure input")
end)

test("free Spooky hatch token pays for one egg", function()
	local cost, state = HatchEntitlements.cost(
		"SpookyEgg",
		3,
		1_500,
		{ freeCandyUsed = true, freeSpookyHatches = 1 }
	)
	eq(cost, 3_000, "two paid eggs")
	eq(state.freeSpookyHatches, 0, "token consumed")
end)
