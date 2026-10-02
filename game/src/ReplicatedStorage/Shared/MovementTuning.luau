--!strict
-- Pure movement tuning and curves. Values are placeholders until a device playtest pass.
local MovementTuning = {
	WalkSpeed = 20,
	Sprint = {
		SpeedMultiplier = 1.35,
		MobileDefaultOn = true,
	},
	Slide = {
		StartSpeed = 38,
		Duration = 0.8,
		CameraTiltDegrees = 6,
	},
	Dash = {
		Speed = 90,
		Duration = 0.18,
		Cooldown = 1.2,
	},
	Jump = {
		CoyoteTime = 0.12,
		BufferTime = 0.12,
	},
	Fov = {
		Base = 70,
		SprintKick = 5,
		DashKick = 10,
		ReturnTime = 0.35,
	},
}

local function clamp01(value: number): number
	return math.max(0, math.min(1, value))
end

function MovementTuning.slideSpeed(elapsed: number): number
	local progress = clamp01(elapsed / MovementTuning.Slide.Duration)
	local remaining = 1 - progress
	return MovementTuning.WalkSpeed
		+ (MovementTuning.Slide.StartSpeed - MovementTuning.WalkSpeed) * remaining * remaining
end

function MovementTuning.dashReady(
	lastDashAt: number,
	now: number,
	cooldownMultiplier: number?
): boolean
	local multiplier = math.max(0, cooldownMultiplier or 1)
	local cooldown = MovementTuning.Dash.Cooldown * multiplier
	return now - lastDashAt + 1e-9 >= cooldown
end

function MovementTuning.fovAt(elapsed: number, kick: number): number
	local progress = clamp01(elapsed / MovementTuning.Fov.ReturnTime)
	local remaining = 1 - progress
	return MovementTuning.Fov.Base + kick * remaining * remaining
end

function MovementTuning.defaultSprint(touchEnabled: boolean): boolean
	return touchEnabled and MovementTuning.Sprint.MobileDefaultOn
end

return MovementTuning
