-- Pure presentation policy. Allowed speed is observed, never assigned.
local Move = {}
function Move.step(age, dt, input)
	local allowed = not input.carry and not input.reduced and not input.blocked
		and input.walkSpeed >= 16 and input.grounded and input.alive
	local running = allowed and input.intent >= .85 and input.speed >= input.walkSpeed * .8
	if not allowed then return 0, 0, false end
	age = math.clamp(age + (running and dt or -dt * 3), 0, .75)
	local t = age / .75
	return age, t * t * (3 - 2 * t), running
end
return Move
