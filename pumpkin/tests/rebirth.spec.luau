--!strict
local Rebirth = load("Rebirth")

test("rebirth cost doubles and multiplier grows by half", function()
	eq(Rebirth.cost(0), 1_000, "first cost")
	eq(Rebirth.cost(1), 2_000, "second cost")
	eq(Rebirth.cost(5), 32_000, "sixth cost")
	eq(Rebirth.multiplier(0), 1, "base multiplier")
	eq(Rebirth.multiplier(4), 3, "four rebirth multiplier")
	eq(Rebirth.canAfford(1_999, 1), false, "below cost")
	eq(Rebirth.canAfford(2_000, 1), true, "exact cost")
end)
