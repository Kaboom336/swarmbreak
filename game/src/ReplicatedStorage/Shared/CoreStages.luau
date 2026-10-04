--!strict
-- Pure Mars Core stage data, progression, and clear rewards.
local Difficulty = require(script.Parent.Difficulty)

export type Stage = {
	Id: number,
	Name: string,
	Zone: "LandingPad" | "Refinery" | "HiveCore",
	Waves: number,
	Family: string,
	Boss: string?,
	HealthScale: number,
	DamageScale: number,
	StoryBeat: string,
}

export type Reward = {
	Gold: number,
	Gems: number,
	FirstClear: boolean,
}

type ProgressProfile = {
	Gold: number,
	Gems: number,
	Flags: { [string]: boolean },
	BaseThemes: { [string]: boolean },
}

local CoreStages = {}

CoreStages.Count = 15
CoreStages.DefaultStage = 1

local names = {
	"Dustfall",
	"Silent Gantry",
	"Broken Convoy",
	"Reactor Road",
	"Landing Breach",
	"Cold Pipes",
	"Fuel Lines",
	"Pressure Hall",
	"Smelter Wake",
	"Refinery Siege",
	"Buried Signal",
	"Brood Tunnels",
	"Reactor Roots",
	"Queen's Door",
	"Heart of Mars",
}

local storyBeats = {
	"The crew lands beside a factory that should have gone dark years ago.",
	"Empty cranes turn toward the Nest's heat below the dust.",
	"A lost supply convoy points toward the reactor road.",
	"Fresh tracks reveal the Nest hauling power cells underground.",
	"A Brute guards the breach into the factory proper.",
	"Frozen pipes still pulse with stolen reactor energy.",
	"The team reopens a fuel line and follows the flow inward.",
	"Pressure doors buckle as the Nest defends its feeding route.",
	"The old smelter wakes, lighting a path through the refinery.",
	"A second Brute falls beside the refinery control room.",
	"A buried distress signal names the creature below: the Queen.",
	"The tunnels reveal eggs clustered around reactor conduits.",
	"Nest roots have grown through the reactor's shielding.",
	"The last blast door opens onto the Queen's chamber.",
	"The Queen falls and the Mars reactor belongs to its people again.",
}

local marsStages: { Stage } = {}
for stageNumber = 1, CoreStages.Count do
	local progress = (stageNumber - 1) / (CoreStages.Count - 1)
	local boss = if stageNumber == 5 or stageNumber == 10
		then "Brute"
		else if stageNumber == 15 then "Queen" else nil
	table.insert(marsStages, {
		Id = stageNumber,
		Name = names[stageNumber],
		Zone = if stageNumber <= 5
			then "LandingPad"
			else if stageNumber <= 10 then "Refinery" else "HiveCore",
		Waves = 3 + math.floor(progress * 5 + 0.5),
		Family = "Nest",
		Boss = boss,
		HealthScale = 1 + progress * 2,
		DamageScale = 1 + progress * 2,
		StoryBeat = storyBeats[stageNumber],
	})
end

CoreStages.ByCore = {
	Outpost9 = marsStages,
} :: { [string]: { Stage } }

function CoreStages.forCore(coreId: string): { Stage }
	return CoreStages.ByCore[coreId] or {}
end

function CoreStages.get(coreId: string, stageNumber: number?): Stage?
	local stages = CoreStages.ByCore[coreId]
	return if stages then stages[stageNumber or CoreStages.DefaultStage] else nil
end

function CoreStages.clearFlag(coreId: string, difficulty: string, stageNumber: number): string
	return string.format("StageClear_%s_%s_%d", coreId, difficulty, stageNumber)
end

function CoreStages.isUnlocked(
	profile: { Flags: { [string]: boolean } },
	coreId: string,
	difficulty: string,
	stageNumber: number
): boolean
	if
		not Difficulty.Defs[difficulty :: Difficulty.TierName]
		or not CoreStages.get(coreId, stageNumber)
	then
		return false
	end
	if stageNumber > 1 then
		return profile.Flags[CoreStages.clearFlag(coreId, difficulty, stageNumber - 1)] == true
	end
	if difficulty == "Normal" then
		return true
	end
	local previousDifficulty = if difficulty == "Hard" then "Normal" else "Hard"
	return profile.Flags[CoreStages.clearFlag(coreId, previousDifficulty, CoreStages.Count)] == true
end

function CoreStages.lockReason(
	profile: { Flags: { [string]: boolean } },
	coreId: string,
	difficulty: string,
	stageNumber: number
): string?
	if CoreStages.isUnlocked(profile, coreId, difficulty, stageNumber) then
		return nil
	end
	if stageNumber > 1 then
		return string.format("Clear stage %d on %s", stageNumber - 1, difficulty)
	end
	if difficulty == "Hard" then
		return "Clear stage 15 on Normal"
	elseif difficulty == "Nightmare" then
		return "Clear stage 15 on Hard"
	end
	return "Locked"
end

function CoreStages.reward(
	stageNumber: number,
	difficulty: Difficulty.TierName,
	firstClear: boolean
): Reward
	assert(stageNumber >= 1 and stageNumber <= CoreStages.Count, "invalid stage")
	local gold = Difficulty.scaleReward(40 + stageNumber * 8, difficulty)
	local gems = Difficulty.scaleReward(4 + stageNumber * 4, difficulty)
	if not firstClear then
		gold *= 0.25
		gems *= 0.25
	end
	return { Gold = gold, Gems = gems, FirstClear = firstClear }
end

function CoreStages.complete(
	profile: ProgressProfile,
	coreId: string,
	difficulty: Difficulty.TierName,
	stageNumber: number
): Reward
	assert(CoreStages.get(coreId, stageNumber), "invalid core stage")
	local flag = CoreStages.clearFlag(coreId, difficulty, stageNumber)
	local clearReward = CoreStages.reward(stageNumber, difficulty, profile.Flags[flag] ~= true)
	profile.Flags[flag] = true
	profile.Gold += clearReward.Gold
	profile.Gems += clearReward.Gems
	if stageNumber == CoreStages.Count then
		profile.Flags[string.format("MapClear_%s_%s", coreId, difficulty)] = true
	end
	if coreId == "Outpost9" and difficulty == "Nightmare" and stageNumber == CoreStages.Count then
		profile.BaseThemes.Mars = true
	end
	return clearReward
end

return CoreStages
