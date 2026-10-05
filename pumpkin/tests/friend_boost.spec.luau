--!strict
local FriendBoost = load("FriendBoost")
local Grow = load("Grow")

test("friend boost gives ten percent per friend and caps at fifty percent", function()
	eq(FriendBoost.boost(0), 0)
	eq(math.floor(FriendBoost.boost(3) * 100 + 0.5), 30)
	eq(FriendBoost.boost(99), 0.5)
	eq(FriendBoost.boost(-2), 0)
end)

test("friend boost participates in the additive grow multiplier", function()
	eq(Grow.multiplier({ friendBoost = FriendBoost.boost(2) }), 1.2)
	eq(Grow.multiplier({ friendBoost = 0.5, doubleSize = true }), 3)
end)
