local LevelUp = load("LevelUp")
local Evolutions = load("Evolutions")
local WaveRewards = load("WaveRewards")
local Weapons = load("Weapons")

test("wave 1 level-ups take 10 to 20 seconds at the baseline kill rate", function()
	for level = 1, 2 do
		local seconds = LevelUp.secondsAtWaveOneRate(level)
		assert(seconds >= 10, "level " .. level .. " is not an instant pick")
		assert(seconds <= 20, "level " .. level .. " takes at most 20 seconds")
	end
end)

test("wave 4 level-ups take 30 to 60 seconds at the baseline kill rate", function()
	local seconds = LevelUp.secondsAtWaveOneRate(4)
	assert(seconds >= 30, "wave 4 cadence is at least 30 seconds")
	assert(seconds <= 60, "wave 4 cadence is at most 60 seconds")
	eq(LevelUp.requiredXp(5), LevelUp.requiredXp(4), "late cadence stays bounded")
end)

test("xp carries across levels", function()
	local level, xp, gained = LevelUp.advance(0, 0, LevelUp.requiredXp(1) + 5)
	eq(level, 1, "one level gained")
	eq(xp, 5, "extra xp carried")
	eq(gained, 1, "one pick owed")

	local level2, xp2, gained2 =
		LevelUp.advance(level, xp, LevelUp.requiredXp(2) + LevelUp.requiredXp(3))
	eq(level2, 3, "two more levels gained")
	eq(xp2, 5, "carry survives multiple levels")
	eq(gained2, 2, "two picks owed")
end)

test("level-up offers contain three different cards", function()
	local offer = LevelUp.offer(1, {}, "Hitscan", { 0.1, 0.5, 0.9 }, { 0.05, 0.65, 0.95 })
	eq(#offer, WaveRewards.OfferSize, "three cards")
	local seen = {}
	for _, card in offer do
		assert(WaveRewards.Defs[card.Id], "real card " .. card.Id)
		assert(not seen[card.Id], "duplicate card " .. card.Id)
		assert(LevelUp.RarityOdds[card.Rarity], "known rarity " .. card.Rarity)
		seen[card.Id] = true
	end
end)

test("card rarity odds sum to one", function()
	local total = 0
	for _, rarity in LevelUp.RarityOrder do
		total += LevelUp.RarityOdds[rarity]
	end
	assert(math.abs(total - 1) < 1e-9, "rarity odds must sum to 1")
	eq(LevelUp.rollRarity(0), "Common", "low roll")
	eq(LevelUp.rollRarity(0.999), "Legendary", "high roll")
end)

test("the level 2 offer contains exactly one element card", function()
	for _, rolls in
		{
			{ 0, 0.2, 0.8 },
			{ 0.26, 0.4, 0.9 },
			{ 0.51, 0.6, 0.1 },
			{ 0.99, 0.8, 0.3 },
		}
	do
		local offer = LevelUp.offer(2, {}, "Hitscan", rolls, { 0.05, 0.65, 0.95 })
		local elementCards = 0
		for _, card in offer do
			assert(LevelUp.RarityOdds[card.Rarity], "element offers retain valid rarities")
			if card.Element then
				elementCards += 1
				local element = Evolutions.Elements[card.Element]
				assert(element, "known element " .. card.Element)
				eq(card.Color, element.Color, "weapon recolor comes from the element")
				eq(
					card.OnHitEffect,
					element.Tiers[2].Effect,
					"card grants the element on-hit effect"
				)
			end
		end
		eq(elementCards, 1, "one element card")
	end
end)

test("the level 4 offer shows one first evolution preview", function()
	local offer = LevelUp.offer(4, {}, "Hitscan", { 0.7, 0.2, 0.8 }, { 0.1, 0.7, 0.99 })
	local previews = 0
	for _, card in offer do
		assert(LevelUp.RarityOdds[card.Rarity], "preview offers retain valid rarities")
		if card.EvolutionPreview then
			previews += 1
			eq(card.EvolutionPreview.Tier, 1, "first evolution tier")
			local element = Evolutions.Elements[card.EvolutionPreview.Element]
			assert(element, "preview uses a known element")
			eq(card.EvolutionPreview.Label, element.Tiers[1].Label, "preview label")
		end
	end
	eq(previews, 1, "one evolution preview")
end)

test("the run chest uses the existing crate pity", function()
	eq(LevelUp.ChestCrate, "Gem", "existing Gem crate")
	eq(LevelUp.chestRarity(0, Weapons.PityAt - 1), "Legendary", "pity overrides the rolled rarity")
end)

test("rerolls grant one free use plus one every five levels", function()
	local actions = LevelUp.newActionState()
	eq(LevelUp.rerollsLeft(actions, 0), 1, "one free reroll")
	eq(LevelUp.useReroll(actions, 0), true, "free reroll works")
	eq(LevelUp.useReroll(actions, 4), false, "free reroll cannot repeat")
	eq(LevelUp.rerollsLeft(actions, 5), 1, "level five grants another")
	eq(LevelUp.useReroll(actions, 5), true, "level five reroll works")
	eq(LevelUp.useReroll(actions, 9), false, "second reroll cannot repeat")
	eq(LevelUp.rerollsLeft(actions, 10), 1, "level ten grants another")
end)

test("banish is limited to two unique cards per run", function()
	local actions = LevelUp.newActionState()
	eq(LevelUp.banishesLeft(actions), 2, "two banishes")
	eq(LevelUp.banish(actions, "Sharp"), true, "first banish")
	eq(LevelUp.banish(actions, "Sharp"), false, "same id cannot be spent twice")
	eq(LevelUp.banish(actions, "Trigger"), true, "second banish")
	eq(LevelUp.banish(actions, "Greed"), false, "third banish denied")
	eq(LevelUp.banishesLeft(actions), 0, "none left")
	assert(actions.Banished.Sharp and actions.Banished.Trigger, "banished ids are remembered")
end)

test("skip refunds ten percent of the next level", function()
	eq(LevelUp.skipXp(0), 3, "ten percent of level one")
	eq(LevelUp.skipXp(3), 8, "ten percent of level four")
end)
