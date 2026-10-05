--!strict
local Tutorial = load("Tutorial")

test("tutorial banner depends only on size and completion", function()
	eq(Tutorial.banner(0, false), "Grow to 10 then roll!", "grow prompt")
	eq(Tutorial.banner(10, false), "FOLLOW THE ARROW - STEP ON THE START PAD!", "roll prompt")
	eq(Tutorial.banner(0, true), nil, "completed at zero size")
	eq(Tutorial.banner(1_000_000, true), nil, "completed at large size")
end)
