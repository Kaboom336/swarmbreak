--!strict
local CameraFraming = load("CameraFraming")

local function near(actual: number, expected: number, message: string)
	if math.abs(actual - expected) > 1e-9 then
		error(string.format("%s: expected %.8f, got %.8f", message, expected, actual), 2)
	end
end

test("camera framing scales with pumpkin diameter", function()
	local smallRoll = CameraFraming.compute(2.5, true)
	eq(smallRoll.distance, 20, "roll minimum distance")
	near(smallRoll.height, 7.375, "roll height")

	local largeRoll = CameraFraming.compute(25, true)
	near(largeRoll.distance, 63, "scaled roll distance")
	near(largeRoll.height, 19.75, "scaled roll height")
	eq(25 / largeRoll.distance < 0.4, true, "large pumpkin framing ratio")

	local rest = CameraFraming.compute(2.5, false)
	eq(rest.distance, 14, "rest minimum distance")
	eq(rest.height, 5, "rest minimum height")
end)
