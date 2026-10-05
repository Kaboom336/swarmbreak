--!strict
local Challenges = load("Challenges")

test("daily and weekly challenges rotate deterministically", function()
	local first = Challenges.daily(0)
	local same = Challenges.daily(86_399)
	local next = Challenges.daily(86_400)
	eq(first.id, same.id, "same UTC day")
	eq(first.id ~= next.id, true, "next UTC day")
	eq(Challenges.weekly(0).id, Challenges.weekly(6 * 86_400).id, "same UTC week")
	eq(Challenges.weekly(0).id ~= Challenges.weekly(7 * 86_400).id, true, "next week")
end)

test("challenge progress caps and only matching events advance", function()
	local challenge = { id = "test", label = "TEST", kind = "Dodge", target = 3, rewardWins = 10 }
	local progress, complete = Challenges.advance(challenge, 0, "Pickup", 1)
	eq(progress, 0, "other event ignored")
	eq(complete, false, "not complete")
	progress, complete = Challenges.advance(challenge, 2, "Dodge", 4)
	eq(progress, 3, "progress capped")
	eq(complete, true, "complete")
end)
