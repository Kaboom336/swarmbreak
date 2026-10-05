--!strict
local Tutorial = load("Tutorial")

test("tutorial banner uses short contextual beats", function()
	eq(Tutorial.banner(0, false), "GROW TO 10", "grow prompt")
	eq(Tutorial.banner(10, false), "ROLL — SIZE BECOMES WINS", "roll prompt")
	eq(Tutorial.banner(0, true), nil, "completed at zero size")
	eq(Tutorial.banner(1_000_000, true), nil, "completed at large size")
end)

test("tutorial launch requirement preserves Size on dead attempts", function()
	eq(Tutorial.canLaunch(9), false, "too small")
	eq(Tutorial.canLaunch(10), true, "ready")
end)
