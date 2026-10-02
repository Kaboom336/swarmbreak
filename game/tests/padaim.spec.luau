local PadAim = load("PadAim")

local function near(actual, expected, message)
	if math.abs(actual - expected) > 0.000001 then
		error(string.format("%s: expected %.6f, got %.6f", message, expected, actual), 2)
	end
end

test("deadzone includes its inner edge", function()
	local inside = PadAim.applyDeadzone({ x = PadAim.Deadzone, y = 0 })
	eq(inside.x, 0, "edge x")
	eq(inside.y, 0, "edge y")

	local outside = PadAim.applyDeadzone({ x = PadAim.Deadzone + 0.001, y = 0 })
	eq(outside.x, 1, "outside x")
	eq(outside.y, 0, "outside y")
end)

test("active stick output is normalized", function()
	local direction = PadAim.applyDeadzone({ x = 0.3, y = 0.4 })
	near(direction.x, 0.6, "normalized x")
	near(direction.y, 0.8, "normalized y")
end)

test("neutral stick holds the last direction", function()
	local direction = PadAim.resolveDirection(
		{ x = 0.01, y = 0 },
		{ x = -3, y = 4 },
		{ x = 1, y = 0 }
	)
	near(direction.x, -0.6, "held x")
	near(direction.y, 0.8, "held y")
end)

test("zero last direction uses a safe fallback", function()
	local direction = PadAim.resolveDirection({ x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = -8 })
	eq(direction.x, 0, "fallback x")
	eq(direction.y, -1, "fallback y")

	local zero = PadAim.resolveDirection({ x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 })
	eq(zero.x, 0, "zero fallback x")
	eq(zero.y, 0, "zero fallback y")
end)
