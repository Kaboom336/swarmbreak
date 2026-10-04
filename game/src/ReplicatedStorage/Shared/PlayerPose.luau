--!strict
-- Pure curves for additive player movement poses.
local PlayerPose = {
	RunLeanDegrees = 8,
	RunLeanResponse = 12,
	DashLeanDegrees = 15,
	DashStretch = 0.35,
	DashDuration = 0.28,
	DashTrailLifetime = 0.12,
	HitDuration = 0.1,
	HitFlinchDegrees = 6,
	LevelUpDuration = 0.45,
	LevelUpPop = 0.6,
}

export type MovementPose = {
	LeanDegrees: number,
	TuckStuds: number,
	SpinDegrees: number,
	ArmSweepDegrees: number,
}

local poseProfiles = {
	Dash = {
		{ LeanDegrees = 18, TuckStuds = 0.05, SpinDegrees = 0, ArmSweepDegrees = 20 },
		{ LeanDegrees = 11, TuckStuds = 0.45, SpinDegrees = 0, ArmSweepDegrees = -35 },
		{ LeanDegrees = 8, TuckStuds = 0.1, SpinDegrees = 180, ArmSweepDegrees = 80 },
	},
	DoubleJump = {
		{ LeanDegrees = -10, TuckStuds = 0.35, SpinDegrees = 0, ArmSweepDegrees = 45 },
		{ LeanDegrees = 0, TuckStuds = 0.5, SpinDegrees = 360, ArmSweepDegrees = 15 },
		{ LeanDegrees = 8, TuckStuds = 0.15, SpinDegrees = 0, ArmSweepDegrees = 110 },
	},
	Slide = {
		{ LeanDegrees = 22, TuckStuds = -0.25, SpinDegrees = 0, ArmSweepDegrees = -25 },
		{ LeanDegrees = 14, TuckStuds = -0.4, SpinDegrees = 0, ArmSweepDegrees = 65 },
		{ LeanDegrees = 18, TuckStuds = -0.2, SpinDegrees = 120, ArmSweepDegrees = 95 },
	},
}

local function clamp01(value: number): number
	return math.max(0, math.min(1, value))
end

function PlayerPose.spinAngle(progress: number): number
	local remaining = 1 - clamp01(progress)
	return (1 - remaining * remaining) * 2 * math.pi
end

function PlayerPose.targetRunLean(moveRight: number, moveForward: number): (number, number)
	local magnitude = math.sqrt(moveRight * moveRight + moveForward * moveForward)
	if magnitude <= 1e-4 then
		return 0, 0
	end
	local scale = PlayerPose.RunLeanDegrees / math.max(1, magnitude)
	return moveForward * scale, -moveRight * scale
end

function PlayerPose.stepRunLean(
	currentPitch: number,
	currentRoll: number,
	moveRight: number,
	moveForward: number,
	deltaTime: number
): (number, number)
	local targetPitch, targetRoll = PlayerPose.targetRunLean(moveRight, moveForward)
	local alpha = 1 - math.exp(-PlayerPose.RunLeanResponse * math.max(0, deltaTime))
	return currentPitch + (targetPitch - currentPitch) * alpha,
		currentRoll + (targetRoll - currentRoll) * alpha
end

function PlayerPose.dashPose(elapsed: number): { LeanDegrees: number, Stretch: number }
	if elapsed < 0 or elapsed >= PlayerPose.DashDuration then
		return { LeanDegrees = 0, Stretch = 0 }
	end
	local progress = clamp01(elapsed / PlayerPose.DashDuration)
	local curve = math.sin(progress * math.pi)
	return {
		LeanDegrees = PlayerPose.DashLeanDegrees * curve,
		Stretch = PlayerPose.DashStretch * curve,
	}
end

function PlayerPose.movementPose(
	action: string,
	variant: number,
	envelope: number,
	progress: number
): MovementPose
	local profiles = (poseProfiles :: any)[action]
	local profile = if profiles then profiles[math.clamp(math.floor(variant), 1, 3)] else nil
	if not profile then
		return { LeanDegrees = 0, TuckStuds = 0, SpinDegrees = 0, ArmSweepDegrees = 0 }
	end
	local weight = clamp01(envelope)
	return {
		LeanDegrees = profile.LeanDegrees * weight,
		TuckStuds = profile.TuckStuds * weight,
		SpinDegrees = profile.SpinDegrees * PlayerPose.spinAngle(progress) / (2 * math.pi),
		ArmSweepDegrees = profile.ArmSweepDegrees * weight,
	}
end

function PlayerPose.hitFlinch(elapsed: number): number
	if elapsed < 0 or elapsed >= PlayerPose.HitDuration then
		return 0
	end
	local progress = clamp01(elapsed / PlayerPose.HitDuration)
	return PlayerPose.HitFlinchDegrees * math.sin(progress * math.pi)
end

function PlayerPose.levelUpPop(elapsed: number): number
	if elapsed < 0 or elapsed >= PlayerPose.LevelUpDuration then
		return 0
	end
	local progress = clamp01(elapsed / PlayerPose.LevelUpDuration)
	return PlayerPose.LevelUpPop * math.sin(progress * math.pi)
end

function PlayerPose.scytheIdleAt(elapsed: number): MovementPose
	local breath = math.sin(elapsed * math.pi * 2 / 2.4)
	return {
		LeanDegrees = 2 + breath * 1.5,
		TuckStuds = breath * 0.03,
		SpinDegrees = 0,
		ArmSweepDegrees = 12 + breath * 3,
	}
end

function PlayerPose.scytheAbilityAt(kind: string, progress: number): MovementPose
	local t = clamp01(progress)
	local envelope = math.sin(t * math.pi)
	if kind == "DashSpin" or kind == "ReaperArc" then
		return {
			LeanDegrees = 12 * envelope,
			TuckStuds = 0.25 * envelope,
			SpinDegrees = 360 * (1 - (1 - t) * (1 - t)),
			ArmSweepDegrees = 100 * envelope,
		}
	end
	return {
		LeanDegrees = -10 * envelope,
		TuckStuds = 0.12 * envelope,
		SpinDegrees = 0,
		ArmSweepDegrees = 145 * envelope,
	}
end

return PlayerPose
