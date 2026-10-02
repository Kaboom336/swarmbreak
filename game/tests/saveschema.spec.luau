--!strict
local SaveSchema = load("SaveSchema")

test("migrating version 1 keeps currencies", function()
	local profile = SaveSchema.migrate({
		Version = 1,
		Gems = 47,
		Shards = { Dark = 3, Tech = 5 },
	})

	eq(profile.Version, SaveSchema.Version, "latest version")
	eq(profile.Gems, 47, "gems kept")
	eq(profile.Shards.Dark, 3, "dark shards kept")
	eq(profile.Shards.Tech, 5, "tech shards kept")
end)

test("migration drops unknown fields safely", function()
	local profile = SaveSchema.migrate({
		Version = 1,
		Gems = 12,
		UnknownCurrency = 999,
		Shards = { Dark = 2, UnknownShard = 100 },
	})

	eq(profile.UnknownCurrency, nil, "unknown top-level field")
	eq(profile.Shards.UnknownShard, nil, "unknown nested field")
end)

test("default save profile is valid", function()
	local profile = SaveSchema.default()

	eq(profile.Version, SaveSchema.Version, "version")
	eq(profile.Gems, 0, "gems")
	eq(profile.Shards.Dark, 0, "shards")
	eq(profile.Equipped, "Starter", "equipped weapon")
	eq(profile.Weapons[1], "Starter", "owned starter weapon")
end)
