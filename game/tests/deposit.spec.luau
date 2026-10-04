local Deposit = load("Deposit")

test("raid deposits use the outcome rate for both currencies", function()
	local clear = Deposit.calculate(101, 9, "Clear")
	eq(clear.Gold, 101, "clear gold")
	eq(clear.Gems, 9, "clear gems")

	local death = Deposit.calculate(101, 9, "Death")
	eq(death.Gold, 50, "death gold rounds down")
	eq(death.Gems, 4, "death gems round down")

	local early = Deposit.calculate(101, 9, "EarlyLeave")
	eq(early.Gold, 0, "early leave gold")
	eq(early.Gems, 0, "early leave gems")
end)

test("raid deposits sanitize invalid run currency", function()
	local result = Deposit.calculate(-10, 0 / 0, "Clear")
	eq(result.Gold, 0, "negative gold")
	eq(result.Gems, 0, "NaN gems")
end)
