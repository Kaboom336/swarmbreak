--!strict
local Daily = load("Daily")

test("daily streak rolls over through seven days", function()
	local result = Daily.nextStreak(100, 6, 101 * 86_400)
	eq(result.claimable, true, "next day is claimable")
	eq(result.streak, 7, "seventh day")
	result = Daily.nextStreak(101, 7, 102 * 86_400)
	eq(result.streak, 1, "calendar rolls over")
end)

test("daily streak blocks same UTC day and resets after a missed day", function()
	local result = Daily.nextStreak(200, 3, 200 * 86_400 + 86_399)
	eq(result.claimable, false, "same UTC day")
	eq(result.streak, 3, "same streak")
	result = Daily.nextStreak(200, 3, 202 * 86_400)
	eq(result.claimable, true, "later day is claimable")
	eq(result.streak, 1, "missed day resets streak")
end)
