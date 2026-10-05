--!strict
local Config = load("Config")

test("each click grows the pumpkin by one", function()
	eq(Config.SizePerClick, 1, "size per click")
end)
