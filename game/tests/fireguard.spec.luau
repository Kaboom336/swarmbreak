--!strict
local FireGuard = load("FireGuard")

local characterPosition = { x = 0, y = 0, z = 0 }
local nearbyOrigin = { x = 0, y = 1, z = 0 }
local direction = { x = 1, y = 0, z = 0 }

test("legitimate fire cadence is accepted", function()
	local accepted = FireGuard.validate(10.25, 10, 4, nearbyOrigin, characterPosition, direction)
	eq(accepted, true, "shot at the weapon cadence")
end)

test("a player running at 24 studs per second with 250 ms latency is accepted", function()
	local latencySeconds = 0.25
	local runningSpeed = 24
	local latencyAdjustedOrigin = { x = runningSpeed * latencySeconds, y = 0, z = 0 }
	local accepted =
		FireGuard.validate(10.25, 10, 4, latencyAdjustedOrigin, characterPosition, direction)
	eq(accepted, true, "running player origin")
end)

test("double-rate fire is rejected", function()
	local accepted = FireGuard.validate(10.125, 10, 4, nearbyOrigin, characterPosition, direction)
	eq(accepted, false, "shot at twice the weapon rate")
end)

test("an origin farther than fourteen studs from the character is rejected", function()
	local farOrigin = { x = 14.01, y = 0, z = 0 }
	local accepted = FireGuard.validate(10.25, 10, 4, farOrigin, characterPosition, direction)
	eq(accepted, false, "far origin")
end)

test("a NaN direction is rejected", function()
	local nan = 0 / 0
	local invalidDirection = { x = nan, y = 0, z = 0 }
	local accepted =
		FireGuard.validate(10.25, 10, 4, nearbyOrigin, characterPosition, invalidDirection)
	eq(accepted, false, "NaN direction")
end)
