local WeeklyBoard = load("WeeklyBoard")

local DAY = 86400

test("weeks change at Monday 00:00 UTC", function()
	-- Unix time began on a Thursday, so the first Monday starts at day 4.
	eq(WeeklyBoard.weekIndex(4 * DAY - 1), 0, "Sunday's week")
	eq(WeeklyBoard.weekIndex(4 * DAY), 1, "Monday's week")
	eq(WeeklyBoard.weekIndex(11 * DAY - 1), 1, "next Sunday")
	eq(WeeklyBoard.weekIndex(11 * DAY), 2, "next Monday")
	eq(WeeklyBoard.key(11 * DAY), "Week_2", "store key")
end)

test("scores decode back to wave and whole seconds", function()
	local encoded = WeeklyBoard.score(14, 327)
	local wave, timeSeconds = WeeklyBoard.decode(encoded)
	eq(wave, 14, "wave")
	eq(timeSeconds, 327, "time")
end)

test("a higher wave ranks first", function()
	assert(WeeklyBoard.score(12, 900) > WeeklyBoard.score(11, 20), "wave matters before time")
end)

test("a faster run ranks first on the same wave", function()
	assert(WeeklyBoard.score(12, 300) > WeeklyBoard.score(12, 301), "faster time wins")
end)

test("top sorts by score, breaks ties by name, and leaves input alone", function()
	local tied = WeeklyBoard.score(8, 240)
	local entries = {
		{ Name = "Zoe", Score = tied },
		{ Name = "Avery", Score = tied },
		{ Name = "Kai", Score = WeeklyBoard.score(9, 500) },
	}
	local leaders = WeeklyBoard.top(entries, 2)
	eq(leaders[1].Name, "Kai", "highest score")
	eq(leaders[2].Name, "Avery", "name breaks the tie")
	eq(entries[1].Name, "Zoe", "input order unchanged")
end)
