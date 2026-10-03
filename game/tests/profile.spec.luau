local ProfileSchema = load("ProfileSchema")

test("default profile is valid and minimal", function()
	local p = ProfileSchema.default()
	eq(p.Gems, 0, "gems")
	eq(#p.Weapons, 1, "starter only")
	eq(p.Equipped, "Starter", "equipped")
	eq(p.Shards.Dark, 0, "shards")
end)

test("sanitize drops junk and keeps good data", function()
	local p = ProfileSchema.sanitize({
		Gems = 512.7,
		Shards = { Dark = 3, Bogus = 9, Lightning = -2 },
		Weapons = { "Starter", "Nova", "NotAWeapon", "Nova", 42 },
		Equipped = "Nova",
		Evolutions = {
			Nova = { Element = "Dark", Tier = 2 },
			Blade = { Element = "Fire", Tier = 3 },
			Starter = { Element = "Lightning", Tier = 9 },
		},
		Perks = { StartCoins = 99, Fake = 2 },
		BestWave = 12,
	})
	eq(p.Gems, 512, "gems floored")
	eq(p.Shards.Dark, 3, "void kept")
	eq(p.Shards.Lightning, 0, "negative dropped")
	eq(p.Shards.Bogus, nil, "unknown element dropped")
	eq(#p.Weapons, 2, "dupes and junk dropped")
	eq(p.Equipped, "Nova", "equipped kept")
	eq(p.Evolutions.Nova.Tier, 2, "evo kept")
	eq(p.Evolutions.Blade, nil, "bad element dropped")
	eq(p.Evolutions.Starter.Tier, 3, "tier clamped")
	eq(p.Perks.StartCoins, 5, "perk clamped to max")
	eq(p.Perks.Fake, nil, "unknown perk dropped")
	eq(p.BestWave, 12, "best wave")
end)

test("sanitize of garbage returns default; equipped must be owned", function()
	local p = ProfileSchema.sanitize("nope")
	eq(p.Equipped, "Starter", "default")
	local q = ProfileSchema.sanitize({ Equipped = "Nova" })
	eq(q.Equipped, "Starter", "not owned -> starter")
end)

test("perks cost more per level and stop at max", function()
	local p = ProfileSchema.default()
	p.Gems = 10000
	local ok = ProfileSchema.canBuyPerk(p, "StartCoins")
	eq(ok, true, "affordable")
	eq(ProfileSchema.perkCost(p, "StartCoins"), 80, "lvl 1 cost")
	p.Perks.StartCoins = 5
	eq(ProfileSchema.perkCost(p, "StartCoins"), nil, "maxed")
	eq(ProfileSchema.perkValue(p, "StartCoins"), 500, "value")
	p.Gems = 0
	p.Perks.MaxHealth = 1
	local ok2, why = ProfileSchema.canBuyPerk(p, "MaxHealth")
	eq(ok2, false, "poor")
	assert(why:find("400"), why)
end)

test("the first perk is in reach at exactly 80 Gems", function()
	local p = ProfileSchema.default()
	p.Gems = 80
	eq(ProfileSchema.canBuyPerk(p, "StartCoins"), true, "80 buys it")
	p.Gems = 79
	local ok, why = ProfileSchema.canBuyPerk(p, "StartCoins")
	eq(ok, false, "79 does not")
	assert(why:find("80"), why)
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

test("crate duplicate streak is sanitized", function()
	eq(ProfileSchema.default().CrateDuplicateStreak, 0, "default streak")
	eq(ProfileSchema.sanitize({ CrateDuplicateStreak = -3 }).CrateDuplicateStreak, 0, "negative")
	eq(ProfileSchema.sanitize({ CrateDuplicateStreak = 12.9 }).CrateDuplicateStreak, 12, "floored")
	eq(
		ProfileSchema.sanitize({ CrateDuplicateStreak = 10001 }).CrateDuplicateStreak,
		9999,
		"clamped"
	)
	eq(
		ProfileSchema.sanitize({ CrateDuplicateStreak = "3" }).CrateDuplicateStreak,
		0,
		"strings dropped"
	)
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
