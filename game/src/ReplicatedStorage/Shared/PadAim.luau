--!strict
-- Pure right-stick helpers. Directions are plain tables so this can be tested outside Roblox.
export type Direction = {
	x: number,
	y: number,
}

local PadAim = {}

PadAim.Deadzone = 0.2

function PadAim.normalize(direction: Direction): Direction
	local magnitude = math.sqrt(direction.x * direction.x + direction.y * direction.y)
	if magnitude == 0 then
		return { x = 0, y = 0 }
	end
	return { x = direction.x / magnitude, y = direction.y / magnitude }
end

function PadAim.applyDeadzone(stick: Direction, deadzone: number?): Direction
	local threshold = math.clamp(deadzone or PadAim.Deadzone, 0, 1)
	local magnitude = math.sqrt(stick.x * stick.x + stick.y * stick.y)
	if magnitude <= threshold then
		return { x = 0, y = 0 }
	end
	return PadAim.normalize(stick)
end

-- An active stick wins. At rest, retain the last aim; before the first input, use fallback.
function PadAim.resolveDirection(
	stick: Direction,
	lastDirection: Direction,
	fallbackDirection: Direction,
	deadzone: number?
): Direction
	local active = PadAim.applyDeadzone(stick, deadzone)
	if active.x ~= 0 or active.y ~= 0 then
		return active
	end

	local held = PadAim.normalize(lastDirection)
	if held.x ~= 0 or held.y ~= 0 then
		return held
	end
	return PadAim.normalize(fallbackDirection)
end

return PadAim
