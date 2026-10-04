local Campaign = load("Campaign")
local CoreStages = load("CoreStages")
local ProfileSchema = load("ProfileSchema")
local WaveTable = load("WaveTable")

test("Mars Core has fifteen ordered stages with rising scales and three bosses", function()
	local core = Campaign.get("Outpost9")
	eq(core.Name, "Mars Core", "core name")
	eq(
		core.StoryLine,
		"A withered Martian factory outpost, overrun by a Nest feeding on its reactor.",
		"story line"
	)

	local stages = CoreStages.forCore(core.Id)
	eq(#stages, 15, "stage count")
	for index, stage in stages do
		eq(stage.Id, index, "stage id")
		eq(stage.Family, "Nest", "stage family")
		eq(
			stage.Zone,
			if index <= 5 then "LandingPad" else if index <= 10 then "Refinery" else "HiveCore",
			"stage zone"
		)
		assert(stage.Waves >= 3 and stage.Waves <= 8, "stage wave count")
		assert(stage.StoryBeat ~= "" and not stage.StoryBeat:find("\n"), "one-line story beat")
		if index > 1 then
			local previous = stages[index - 1]
			assert(stage.Waves >= previous.Waves, "waves must not fall")
			assert(stage.HealthScale > previous.HealthScale, "health scale must rise")
			assert(stage.DamageScale > previous.DamageScale, "damage scale must rise")
		end
		eq(
			stage.Boss,
			if index == 5 or index == 10 then "Brute" else if index == 15 then "Queen" else nil,
			"stage boss"
		)
	end
	eq(stages[1].Waves, 3, "first waves")
	eq(stages[15].Waves, 8, "last waves")
	eq(stages[1].HealthScale, 1, "first health")
	assert(math.abs(stages[15].HealthScale - 3) < 0.001, "last health is about three")
	assert(math.abs(stages[15].DamageScale - 3) < 0.001, "last damage is about three")
end)

test("stage wave composition uses only the selected stage boss on its final wave", function()
	local oldBossWave = WaveTable.Compositions[5]
	local noBoss = WaveTable.resolveStageComposition(oldBossWave, "Nest", nil, true)
	eq(noBoss.Brute, nil, "old fixed-wave Brute removed")
	eq(noBoss.Queen, nil, "no unselected Queen")
	local queen = WaveTable.resolveStageComposition(oldBossWave, "Nest", "Queen", true)
	eq(queen.Brute, nil, "old boss still removed")
	eq(queen.Queen, 1, "selected final boss")
	local early = WaveTable.resolveStageComposition(oldBossWave, "Nest", "Queen", false)
	eq(early.Queen, nil, "selected boss waits for final wave")
end)

test("stage unlocks chain within and across difficulties", function()
	local profile = ProfileSchema.default()
	eq(CoreStages.isUnlocked(profile, "Outpost9", "Normal", 1), true, "Normal 1")
	eq(CoreStages.isUnlocked(profile, "Outpost9", "Normal", 2), false, "Normal 2")
	eq(CoreStages.isUnlocked(profile, "Outpost9", "Hard", 1), false, "Hard 1")

	for stage = 1, 15 do
		profile.Flags[CoreStages.clearFlag("Outpost9", "Normal", stage)] = true
	end
	eq(CoreStages.isUnlocked(profile, "Outpost9", "Hard", 1), true, "Hard after Normal 15")
	eq(CoreStages.isUnlocked(profile, "Outpost9", "Hard", 2), false, "Hard 2")
	for stage = 1, 15 do
		profile.Flags[CoreStages.clearFlag("Outpost9", "Hard", stage)] = true
	end
	eq(CoreStages.isUnlocked(profile, "Outpost9", "Nightmare", 1), true, "Nightmare after Hard 15")
end)

test("old map clears migrate to all fifteen matching stage flags", function()
	local profile = ProfileSchema.sanitize({
		Flags = {
			MapClear_Outpost9_Hard = true,
		},
	})
	for stage = 1, 15 do
		eq(
			profile.Flags[CoreStages.clearFlag("Outpost9", "Hard", stage)],
			true,
			"migrated stage " .. stage
		)
	end
	eq(profile.Flags.StageClear_Outpost9_Normal_1, nil, "other difficulty stays locked")
end)

test("first-clear rewards scale and repeats pay twenty-five percent", function()
	local early = CoreStages.reward(1, "Normal", true)
	local late = CoreStages.reward(15, "Normal", true)
	local hard = CoreStages.reward(15, "Hard", true)
	local repeatReward = CoreStages.reward(15, "Hard", false)
	assert(late.Gold > early.Gold and late.Gems > early.Gems, "stage rewards rise")
	assert(hard.Gold > late.Gold and hard.Gems > late.Gems, "difficulty rewards rise")
	eq(repeatReward.Gold, hard.Gold * 0.25, "repeat Gold")
	eq(repeatReward.Gems, hard.Gems * 0.25, "repeat Gems")
end)

test("only Nightmare stage fifteen grants the Mars base theme", function()
	for _, difficulty in { "Normal", "Hard", "Nightmare" } do
		for stage = 1, 15 do
			local profile = ProfileSchema.default()
			CoreStages.complete(profile, "Outpost9", difficulty, stage)
			eq(
				profile.BaseThemes.Mars,
				if difficulty == "Nightmare" and stage == 15 then true else nil,
				string.format("%s %d", difficulty, stage)
			)
		end
	end
	local kept = ProfileSchema.sanitize({ BaseThemes = { Mars = true, Bogus = true } })
	eq(kept.BaseThemes.Mars, true, "Mars theme kept")
	eq(kept.BaseThemes.Bogus, nil, "unknown theme dropped")
end)
