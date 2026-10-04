--!strict
-- Pure additive FOV kicks. Each offset owns its easing lifetime so overlapping effects
-- cannot cancel or overwrite one another.
export type Kick = {
	Amount: number,
	StartedAt: number,
	Duration: number,
}

export type Stack = {
	Base: number,
	Kicks: { Kick },
}

local FovStack = {}

function FovStack.new(baseFov: number): Stack
	return {
		Base = baseFov,
		Kicks = {},
	}
end

function FovStack.add(stack: Stack, amount: number, duration: number, now: number)
	table.insert(stack.Kicks, {
		Amount = amount,
		StartedAt = now,
		Duration = math.max(duration, 0.001),
	})
end

local function remaining(kick: Kick, now: number): number
	local progress = math.clamp((now - kick.StartedAt) / kick.Duration, 0, 1)
	local inverse = 1 - progress
	return inverse * inverse
end

function FovStack.valueAt(stack: Stack, now: number): number
	local value = stack.Base
	for _, kick in stack.Kicks do
		value += kick.Amount * remaining(kick, now)
	end
	return value
end

function FovStack.prune(stack: Stack, now: number): boolean
	for index = #stack.Kicks, 1, -1 do
		local kick = stack.Kicks[index]
		if now - kick.StartedAt >= kick.Duration then
			table.remove(stack.Kicks, index)
		end
	end
	return #stack.Kicks > 0
end

return FovStack
