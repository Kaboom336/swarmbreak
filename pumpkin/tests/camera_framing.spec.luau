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

test("camera spring is damped and caps per-frame distance changes", function()
	local current = 20
	local velocity = 0
	local previousError = math.huge
	for _ = 1, 30 do
		local nextValue, nextVelocity = CameraFraming.springStep(current, velocity, 60, 1 / 60)
		eq(nextValue - current <= current * 0.1 + 1e-9, true, "ten percent cap")
		current = nextValue
		velocity = nextVelocity
		local error = math.abs(60 - current)
		eq(error <= previousError + 1e-9, true, "converges without oscillation")
		previousError = error
	end
	eq(current > 59, true, "approaches target")
end)

test("camera heading follows motion while keeping a roll-independent horizon", function()
	local heading = CameraFraming.horizontalHeading(3, 4, 0, -1)
	near(heading.x, 0.6, "motion x")
	near(heading.z, 0.8, "motion z")

	local fallback = CameraFraming.horizontalHeading(0, 0, -2, 0)
	near(fallback.x, -1, "fallback x")
	near(fallback.z, 0, "fallback z")
end)
