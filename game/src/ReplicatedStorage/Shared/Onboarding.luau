--!strict
-- Pure first-run presentation and spawn rules shared by the server, HUD, and tests.
local Onboarding = {
	ObjectiveText = "Survive 5 waves. Beat the Big Brute.",
	ObjectiveSeconds = 3,
	CountdownSeconds = 3,
	SpawnDistanceMin = 25,
	SpawnDistanceMax = 35,
}

function Onboarding.firstSpawnDistance(alpha: number): number
	local amount = math.clamp(alpha, 0, 1)
	return Onboarding.SpawnDistanceMin
		+ (Onboarding.SpawnDistanceMax - Onboarding.SpawnDistanceMin) * amount
end

function Onboarding.shouldShowArrow(kills: number): boolean
	return kills < 1
end

return Onboarding
