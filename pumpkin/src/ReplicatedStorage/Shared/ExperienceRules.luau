--!strict
local Config = require(script.Parent.Config)

export type EffectTier = {
	maxPopups: number,
	maxParticles: number,
	maxDebris: number,
	maxSounds: number,
	maxLights: number,
}

local ExperienceRules = {}

ExperienceRules.HOLD_SECONDS = 1 / Config.ClicksPerSecond
ExperienceRules.FIRST_ACTION_MIN_SECONDS = 8
ExperienceRules.FIRST_ACTION_MAX_SECONDS = 15
ExperienceRules.FIRST_LOOP_MAX_SECONDS = 45
ExperienceRules.REMOTE_RIDE_DISTANCE = 650
ExperienceRules.FREE_DOUBLE_WINS_SECONDS = 10 * 60
ExperienceRules.VFX_TIMING = {
	anticipationSeconds = 0.15,
	contactSeconds = 1 / 60,
	resultSeconds = 0.55,
}

ExperienceRules.EffectTiers = {
	reduced = {
		maxPopups = 7,
		maxParticles = 36,
		maxDebris = 12,
		maxSounds = 8,
		maxLights = 6,
	},
	high = {
		maxPopups = 10,
		maxParticles = 90,
		maxDebris = 28,
		maxSounds = 16,
		maxLights = 12,
	},
}

ExperienceRules.ParticleVocabulary = {
	Ground = { motif = "dust-leaf", lifetime = 0.42, direction = "up" },
	Grow = { motif = "pumpkin-seed", lifetime = 0.65, direction = "hud" },
	Candy = { motif = "candy-star", lifetime = 0.5, direction = "hud" },
	Gold = { motif = "gold-spark", lifetime = 0.55, direction = "hud" },
	Impact = { motif = "impact-chip", lifetime = 0.6, direction = "against-travel" },
	Speed = { motif = "speed-wisp", lifetime = 0.45, direction = "against-travel" },
	Hatch = { motif = "hatch-confetti", lifetime = 0.7, direction = "up" },
	Rare = { motif = "rarity-aura", lifetime = 0.8, direction = "out" },
}

ExperienceRules.ActionFeedback = {
	Grow = { channels = { "motion", "vfx", "sound" }, result = "size" },
	Launch = { channels = { "motion", "sound" }, result = "ride" },
	Steer = { channels = { "motion", "ui" }, result = "lane" },
	LaneSettle = { channels = { "motion", "sound" }, result = "lane" },
	Pickup = { channels = { "vfx", "sound", "ui" }, result = "pending-wins" },
	Dodge = { channels = { "vfx", "sound", "ui" }, result = "combo" },
	Hit = { channels = { "motion", "vfx", "sound" }, result = "combo-reset" },
	Finish = { channels = { "motion", "sound", "ui" }, result = "banked-wins" },
	Hatch = { channels = { "motion", "vfx", "sound" }, result = "pet" },
	Equip = { channels = { "motion", "ui" }, result = "equipped" },
	Unlock = { channels = { "vfx", "ui" }, result = "destination" },
	Rebirth = { channels = { "vfx", "sound", "ui" }, result = "multiplier" },
	ShopDelivery = { channels = { "vfx", "sound", "ui" }, result = "delivered" },
}

function ExperienceRules.canLaunch(size: number): (boolean, number)
	local current = math.max(0, size)
	return current >= Config.TutorialRollSize, math.max(0, Config.TutorialRollSize - current)
end

function ExperienceRules.tutorialStep(
	size: number,
	tutorialDone: boolean,
	rolling: boolean,
	firstEggEngaged: boolean
): string?
	if tutorialDone then
		return if firstEggEngaged then nil else "FIRST HATCH FREE"
	end
	if rolling then
		return "ROLL — SIZE BECOMES WINS"
	end
	return if size >= Config.TutorialRollSize then "ROLL — SIZE BECOMES WINS" else "GROW TO 10"
end

function ExperienceRules.actionableMilestone(before: number, after: number): string?
	if before < Config.TutorialRollSize and after >= Config.TutorialRollSize then
		return "FIRST WALL READY!"
	end
	for index = 2, Config.FallbackWallCount do
		local threshold = Config.WallBaseHealth * Config.WallHealthGrowth ^ (index - 1)
		if before < threshold and after >= threshold then
			return string.format("WALL %d READY!", index)
		end
	end
	return nil
end

function ExperienceRules.feedbackComplete(): boolean
	for _, feedback in ExperienceRules.ActionFeedback do
		if #feedback.channels < 2 or type(feedback.result) ~= "string" or feedback.result == "" then
			return false
		end
	end
	return true
end

function ExperienceRules.effectTier(reduced: boolean): EffectTier
	return if reduced then ExperienceRules.EffectTiers.reduced else ExperienceRules.EffectTiers.high
end

function ExperienceRules.remoteRideRelevant(distance: number, isLocal: boolean): boolean
	return isLocal or math.max(0, distance) <= ExperienceRules.REMOTE_RIDE_DISTANCE
end

function ExperienceRules.runsToGoal(wins: number, goal: number, expectedPerRun: number): number
	local remaining = math.max(0, goal - math.max(0, wins))
	if remaining == 0 then
		return 0
	end
	return math.ceil(remaining / math.max(1, expectedPerRun))
end

return ExperienceRules
