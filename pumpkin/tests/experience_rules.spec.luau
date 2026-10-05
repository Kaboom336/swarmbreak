--!strict
local fs = require("@lune/fs")
local ExperienceRules = load("ExperienceRules")

test("onboarding blocks dead runs and teaches the reward conversion", function()
	local allowed, missing = ExperienceRules.canLaunch(0)
	eq(allowed, false, "zero size blocked")
	eq(missing, 10, "specific requirement")
	eq(ExperienceRules.canLaunch(9), false, "too-small run blocked")
	eq(ExperienceRules.canLaunch(10), true, "first valid launch")
	eq(ExperienceRules.tutorialStep(0, false, false, false), "GROW TO 10", "grow beat")
	eq(
		ExperienceRules.tutorialStep(10, false, false, false),
		"ROLL — SIZE BECOMES WINS",
		"roll beat"
	)
	eq(ExperienceRules.tutorialStep(0, true, false, false), "FIRST HATCH FREE", "post-payout goal")
	eq(ExperienceRules.tutorialStep(0, true, false, true), nil, "tutorial dismissed")
end)

test("action feedback and themed effects are bounded", function()
	eq(ExperienceRules.feedbackComplete(), true, "all verbs have two channels and a result")
	local reduced = ExperienceRules.effectTier(true)
	local high = ExperienceRules.effectTier(false)
	eq(reduced.maxParticles < high.maxParticles, true, "reduced particle tier")
	eq(high.maxParticles <= 100, true, "mobile particle ceiling")
	eq(high.maxDebris <= 28, true, "debris ceiling")
	eq(high.maxSounds <= 16, true, "sound ceiling")
	eq(high.maxLights <= 12, true, "light ceiling")
	eq(ExperienceRules.VFX_TIMING.anticipationSeconds >= 0.1, true, "anticipation")
	eq(ExperienceRules.VFX_TIMING.contactSeconds <= 1 / 60, true, "one-frame contact")
	eq(ExperienceRules.VFX_TIMING.resultSeconds <= 0.7, true, "bounded result")
	local vocabularyCount = 0
	for _, effect in ExperienceRules.ParticleVocabulary do
		vocabularyCount += 1
		eq(effect.lifetime >= 0.3 and effect.lifetime <= 0.8, true, effect.motif)
	end
	eq(vocabularyCount, 8, "complete themed vocabulary")
end)

test("profile schema persists Q4-E settings, funnel, and return goals", function()
	local ProfileSchema = load("ProfileSchema")
	local profile = ProfileSchema.fromStored({
		SFXVolume = 0.5,
		MusicVolume = 0.25,
		ReducedEffects = true,
		TutorialFirstFinishAt = 123,
		DailyChallengeProgress = 4,
		FreeDoubleWinsUntil = 999,
	})
	eq(profile.SFXVolume, 0.5, "SFX")
	eq(profile.MusicVolume, 0.25, "music")
	eq(profile.ReducedEffects, true, "effects tier")
	eq(profile.TutorialFirstFinishAt, 123, "funnel timestamp")
	eq(profile.DailyChallengeProgress, 4, "daily progress")
	eq(profile.FreeDoubleWinsUntil, 999, "earned sample")
end)

test("remote riders use distance relevance and local riders always render", function()
	eq(ExperienceRules.remoteRideRelevant(10_000, true), true, "local rider")
	eq(ExperienceRules.remoteRideRelevant(649, false), true, "near rider")
	eq(ExperienceRules.remoteRideRelevant(651, false), false, "distant rider")
end)

test("runs-to-goal is explicit and stable", function()
	eq(ExperienceRules.runsToGoal(0, 100, 25), 4, "four runs")
	eq(ExperienceRules.runsToGoal(99, 100, 25), 1, "one run")
	eq(ExperienceRules.runsToGoal(100, 100, 25), 0, "already affordable")
end)

test("Q4-E runtime wiring keeps critical protections", function()
	local gameSource = fs.readFile("src/ServerScriptService/Game.server.luau")
	local hudSource = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Hud.client.luau")
	local rollSource = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Roll.client.luau")
	local petsSource = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Pets.client.luau")
	eq(gameSource:find("FireAllClients", 1, true), nil, "ride playback is relevance filtered")
	eq(gameSource:find('"Rejected"', 1, true) ~= nil, true, "dead-run rejection")
	eq(gameSource:find("TutorialFirstFinishAt", 1, true) ~= nil, true, "finish-timed tutorial")
	eq(hudSource:find("GetGuiObjectsAtPosition", 1, true) ~= nil, true, "UI taps do not grow")
	eq(
		hudSource:find("ExperienceRules.HOLD_SECONDS", 1, true) ~= nil,
		true,
		"accepted hold cadence"
	)
	eq(hudSource:find("CONFIRM REBIRTH", 1, true) ~= nil, true, "destructive confirmation")
	eq(hudSource:find("GetProductInfo", 1, true) ~= nil, true, "localized live price")
	eq(rollSource:find("RollingBed", 1, true) ~= nil, true, "rolling sound bed")
	eq(rollSource:find("PendingUpdate", 1, true) ~= nil, true, "pending rewards")
	eq(petsSource:find("ViewportFrame", 1, true) ~= nil, true, "model pet cards and reveal")
	eq(petsSource:find("CONFIRM DELETE", 1, true) ~= nil, true, "delete confirmation")
end)
