--!strict
-- Pure movement tuning and curves. Values are placeholders until a device playtest pass.
local MovementTuning = {
	WalkSpeed = 20,
	RunSpeedMultiplier = 1.35,
	Slide = {
		StartSpeed = 38,
		Duration = 0.6,
		JumpCarry = 0.9,
		HeightScale = 0.55,
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
		DashKick = 6,
		SlideKick = 4,
		ReturnTime = 0.35,
	},
	Cooldowns = {
		Dash = 1.2,
	},
	CooldownBounds = {
		Min = 0.1,
		Max = 5,
	},
	MaxGearExtraJumps = 3,
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

function MovementTuning.runSpeed(baseSpeed: number, moveSpeedPercent: number?): number
	local perkMultiplier = 1 + math.max(0, moveSpeedPercent or 0) / 100
	return math.max(0, baseSpeed) * perkMultiplier * MovementTuning.RunSpeedMultiplier
end

function MovementTuning.slideJumpMomentum(currentSpeed: number, elapsed: number): number
	local carriedSlideSpeed = MovementTuning.slideSpeed(elapsed) * MovementTuning.Slide.JumpCarry
	return math.max(0, currentSpeed, carriedSlideSpeed)
end

function MovementTuning.extraJumps(perks: { [string]: any }?): number
	local value = if perks then perks.ExtraJumps else nil
	if type(value) ~= "number" then
		return 0
	end
	return math.clamp(math.floor(value), 0, MovementTuning.MaxGearExtraJumps)
end

function MovementTuning.airJumps(perks: { [string]: any }?): number
	return 1 + MovementTuning.extraJumps(perks)
end

function MovementTuning.dashReady(
	lastDashAt: number,
	now: number,
	cooldownMultiplier: number?
): boolean
	local cooldown = MovementTuning.cooldown("Dash", cooldownMultiplier)
	return now - lastDashAt + 1e-9 >= cooldown
end

function MovementTuning.cooldown(action: string, cooldownMultiplier: number?): number
	local base = (MovementTuning.Cooldowns :: any)[action]
	assert(type(base) == "number", "unknown movement cooldown: " .. action)
	local cooldown = base * math.max(0, cooldownMultiplier or 1)
	return math.clamp(
		cooldown,
		MovementTuning.CooldownBounds.Min,
		MovementTuning.CooldownBounds.Max
	)
end

function MovementTuning.fovAt(elapsed: number, kick: number): number
	local progress = clamp01(elapsed / MovementTuning.Fov.ReturnTime)
	local remaining = 1 - progress
	return MovementTuning.Fov.Base + kick * remaining * remaining
end

return MovementTuning
