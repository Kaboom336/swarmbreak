local LevelUp = load("LevelUp")
local WaveRewards = load("WaveRewards")
local Weapons = load("Weapons")

test("the first two levels arrive inside the target cadence", function()
	for level = 1, 2 do
		local seconds = LevelUp.secondsAtWaveOneRate(level)
		assert(seconds > 10, "level " .. level .. " is not an instant pick")
		assert(seconds < 20, "level " .. level .. " takes under 20 seconds")
	end
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

test("the run chest uses the existing crate pity", function()
	eq(LevelUp.ChestCrate, "Gem", "existing Gem crate")
	eq(LevelUp.chestRarity(0, Weapons.PityAt - 1), "Legendary", "pity overrides the rolled rarity")
end)
