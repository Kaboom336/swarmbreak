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
	HitFlinchDegrees = 10,
	LevelUpDuration = 0.45,
	LevelUpPop = 0.6,
}

local function clamp01(value: number): number
	return math.max(0, math.min(1, value))
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

return PlayerPose
