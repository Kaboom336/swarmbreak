local CoPlay = load("CoPlay")
local Economy = load("Economy")

test("coin multiplier starts at one and ignores negative counts", function()
	eq(CoPlay.coinMult(0), 1.0, "no friends")
	eq(CoPlay.coinMult(-2), 1.0, "negative friends")
end)

test("coin multiplier adds ten percent per friend and caps at thirty percent", function()
	eq(CoPlay.coinMult(1), 1.1, "one friend")
	eq(CoPlay.coinMult(3), 1.3, "three friends")
	eq(CoPlay.coinMult(5), 1.3, "five friends")
end)

test("kill coins include the co-play multiplier", function()
	eq(Economy.coinsForKill(100, false, 1, 0), 100, "solo")
	eq(Economy.coinsForKill(100, false, 1, 2), 120, "two friends")
	eq(Economy.coinsForKill(100, true, 1, 5), 260, "double coins and capped friends")
end)
