--!strict
-- Pure selection for procedural movement poses. The supplied roll is normalized so
-- callers can use either math.random() or a deterministic value in tests.
local MoveVariants = {
	Count = 3,
}

local validActions = {
	Dash = true,
	DoubleJump = true,
	Slide = true,
}

function MoveVariants.pick(action: string, lastIndex: number?, roll: number): number
	assert(validActions[action], "unknown movement action: " .. action)
	local count = MoveVariants.Count
	local normalizedRoll = math.clamp(roll, 0, 1 - 1e-9)
	local previous = if type(lastIndex) == "number" then math.floor(lastIndex) else 0
	if previous < 1 or previous > count then
		return math.floor(normalizedRoll * count) + 1
	end

	local picked = math.floor(normalizedRoll * (count - 1)) + 1
	return if picked >= previous then picked + 1 else picked
end

return MoveVariants
