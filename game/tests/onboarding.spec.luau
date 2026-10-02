local Onboarding = load("Onboarding")

test("opening objective is complete and lasts three seconds", function()
	eq(Onboarding.ObjectiveText, "Survive 5 waves. Kill the Queen.", "objective text")
	eq(Onboarding.ObjectiveSeconds, 3, "objective duration")
	eq(Onboarding.CountdownSeconds, 3, "countdown duration")
end)

test("first pack spawns between 25 and 35 studs away", function()
	eq(Onboarding.firstSpawnDistance(0), 25, "minimum distance")
	eq(Onboarding.firstSpawnDistance(1), 35, "maximum distance")
	local distance = Onboarding.firstSpawnDistance(0.42)
	assert(distance >= 25 and distance <= 35, "spawn distance is outside the window")
end)

test("enemy arrow hides after the first kill", function()
	assert(Onboarding.shouldShowArrow(0), "arrow should show before a kill")
	assert(not Onboarding.shouldShowArrow(1), "arrow should hide after the first kill")
end)
