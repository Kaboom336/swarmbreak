local ProfileSchema = load("ProfileSchema")

test("default profile is valid and minimal", function()
	local p = ProfileSchema.default()
	eq(p.Gems, 0, "gems")
	eq(p.Gold, 0, "gold")
	eq(#p.Weapons, 1, "starter only")
	eq(p.Equipped, "Starter", "equipped")
	eq(p.Shards.Dark, 0, "shards")
end)

test("sanitize drops junk and keeps good data", function()
	local p = ProfileSchema.sanitize({
		Gold = 321.9,
		Gems = 512.7,
		Shards = { Dark = 3, Bogus = 9, Lightning = -2 },
		Weapons = { "Starter", "Nova", "NotAWeapon", "Nova", 42 },
		Equipped = "Nova",
		Evolutions = {
			Nova = { Element = "Dark", Tier = 2 },
			Blade = { Element = "Fire", Tier = 3 },
			Starter = { Element = "Lightning", Tier = 9 },
		},
		Perks = { MaxHealth = 99, Fake = 2 },
		BestWave = 12,
	})
	eq(p.Gems, 512, "gems floored")
	eq(p.Gold, 321, "gold floored")
	eq(p.Shards.Dark, 3, "void kept")
	eq(p.Shards.Lightning, 0, "negative dropped")
	eq(p.Shards.Bogus, nil, "unknown element dropped")
	eq(#p.Weapons, 2, "dupes and junk dropped")
	eq(p.Equipped, "Nova", "equipped kept")
	eq(p.Evolutions.Nova.Tier, 2, "evo kept")
	eq(p.Evolutions.Blade, nil, "bad element dropped")
	eq(p.Evolutions.Starter.Tier, 3, "tier clamped")
	eq(p.Perks.MaxHealth, 10, "perk clamped to max")
	eq(p.Perks.Fake, nil, "unknown perk dropped")
	eq(p.BestWave, 12, "best wave")
end)

test("sanitize rejects negative and NaN Gold", function()
	eq(ProfileSchema.sanitize({ Gold = -1 }).Gold, 0, "negative")
	eq(ProfileSchema.sanitize({ Gold = 0 / 0 }).Gold, 0, "NaN")
end)

test("sanitize of garbage returns default; equipped must be owned", function()
	local p = ProfileSchema.sanitize("nope")
	eq(p.Equipped, "Starter", "default")
	local q = ProfileSchema.sanitize({ Equipped = "Nova" })
	eq(q.Equipped, "Starter", "not owned -> starter")
end)

test("permanent perk costs rise and stop at level ten", function()
	local p = ProfileSchema.default()
	p.Gold = 100000
	p.Gems = 10000
	local ok = ProfileSchema.canBuyPerk(p, "MaxHealth")
	eq(ok, true, "affordable")
	for key, def in ProfileSchema.PerkDefs do
		eq(def.MaxLevel, 10, key .. " max level")
		local previousGold = -1
		local previousGems = -1
		for level = 0, def.MaxLevel - 1 do
			p.Perks[key] = level
			local cost = ProfileSchema.perkCost(p, key)
			assert(cost.Gold > previousGold, key .. " Gold cost must rise")
			assert(cost.Gems > previousGems, key .. " Gems cost must rise")
			previousGold = cost.Gold
			previousGems = cost.Gems
		end
		p.Perks[key] = def.MaxLevel
		eq(ProfileSchema.perkCost(p, key), nil, key .. " caps")
	end
end)

test("perk purchase needs both Gold and Gems", function()
	local p = ProfileSchema.default()
	local cost = ProfileSchema.perkCost(p, "DamagePercent")
	p.Gold = cost.Gold - 1
	p.Gems = cost.Gems
	local goldOk, goldWhy = ProfileSchema.canBuyPerk(p, "DamagePercent")
	eq(goldOk, false, "short Gold")
	assert(goldWhy:find("Gold"), goldWhy)
	p.Gold = cost.Gold
	p.Gems = cost.Gems - 1
	local gemsOk, gemsWhy = ProfileSchema.buyPerk(p, "DamagePercent")
	eq(gemsOk, false, "short Gems")
	assert(gemsWhy:find("Gems"), gemsWhy)
	eq(p.Gold, cost.Gold, "failed purchase keeps Gold")
	eq(p.Gems, cost.Gems - 1, "failed purchase keeps Gems")
	p.Gems = cost.Gems
	eq(ProfileSchema.buyPerk(p, "DamagePercent"), true, "both currencies")
	eq(p.Gold, 0, "Gold deducted")
	eq(p.Gems, 0, "Gems deducted")
	eq(p.Perks.DamagePercent, 1, "level granted")
end)

test("pity counter and flags are sanitized", function()
	eq(ProfileSchema.sanitize({ CratesSinceLegendary = -3 }).CratesSinceLegendary, 0, "negative")
	eq(ProfileSchema.sanitize({ CratesSinceLegendary = 12.9 }).CratesSinceLegendary, 12, "floored")
	local p =
		ProfileSchema.sanitize({ Flags = { FirstBossCrate = true, Bogus = true, Other = "yes" } })
	eq(p.Flags.FirstBossCrate, true, "known flag kept")
	eq(p.Flags.Bogus, nil, "unknown flag dropped")
	eq(p.Flags.Other, nil, "non-boolean dropped")
	local q = ProfileSchema.sanitize({ Flags = { FirstBossCrate = "true" } })
	eq(q.Flags.FirstBossCrate, nil, "only exactly true is kept")
	eq(next(ProfileSchema.default().Flags), nil, "default flags empty")
	eq(ProfileSchema.default().CratesSinceLegendary, 0, "default counter")
end)

test("daily reward day and streak are sanitized", function()
	local p = ProfileSchema.sanitize({ LastClaimDay = 19999.7, Streak = -4 })
	eq(p.LastClaimDay, 19999, "day floored")
	eq(p.Streak, 0, "negative streak dropped")
	eq(
		ProfileSchema.sanitize({ LastClaimDay = "20000", Streak = "3" }).Streak,
		0,
		"strings dropped"
	)
	eq(ProfileSchema.default().Streak, 0, "default streak")
	eq(ProfileSchema.default().LastClaimDay, 0, "default day")
end)

test("processed purchase ids persist through profile sanitizing", function()
	local p = ProfileSchema.sanitize({
		ProcessedPurchaseIds = { "purchase-1", false, "", "purchase-2", "purchase-1" },
	})
	eq(#p.ProcessedPurchaseIds, 2, "valid unique ids")
	eq(p.ProcessedPurchaseIds[1], "purchase-2", "newest order")
	eq(p.ProcessedPurchaseIds[2], "purchase-1", "newest duplicate")
	eq(#ProfileSchema.default().ProcessedPurchaseIds, 0, "default ledger")
	eq(
		#ProfileSchema.sanitize({ ProcessedPurchaseIds = "corrupt" }).ProcessedPurchaseIds,
		0,
		"junk"
	)
end)

test("sanitize keeps in-run recipe discoveries", function()
	local Evolutions = load("Evolutions")
	local recipe = Evolutions.Recipes[1]
	local key = Evolutions.RecipeFlagPrefix .. recipe.Id
	local raw = ProfileSchema.default()
	raw.Flags[key] = true
	raw.Flags.Recipe_Bogus = true
	local p = ProfileSchema.sanitize(raw)
	eq(p.Flags[key], true, "discovered recipe kept")
	eq(p.Flags.Recipe_Bogus, nil, "unknown recipe dropped")
end)
