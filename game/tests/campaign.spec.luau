local Campaign = load("Campaign")
local ProfileSchema = load("ProfileSchema")

test("campaign maps unlock in order after a Normal clear", function()
	local profile = ProfileSchema.default()
	local unlocked = Campaign.unlockedMaps(profile)
	eq(#unlocked, 1, "only Outpost 9 starts unlocked")
	eq(unlocked[1].Id, "Outpost9", "first map")

	profile.Flags.MapClear_Outpost9_Normal = true
	unlocked = Campaign.unlockedMaps(profile)
	eq(#unlocked, 2, "Normal clear unlocks Frost Relay")
	eq(unlocked[2].Id, "FrostRelay", "second map")
	eq(Campaign.nextMap("FrostRelay").Id, "MagmaRefinery", "next map")
	eq(Campaign.nextMap("HiveHeart"), nil, "last map has no successor")
end)

test("map clear flags survive profile sanitizing", function()
	local profile = ProfileSchema.sanitize({
		Flags = {
			MapClear_Outpost9_Normal = true,
			MapClear_Outpost9_Bogus = true,
			MapClear_NotAMap_Normal = true,
		},
	})
	eq(profile.Flags.MapClear_Outpost9_Normal, true, "known clear kept")
	eq(profile.Flags.MapClear_Outpost9_Bogus, nil, "unknown tier dropped")
	eq(profile.Flags.MapClear_NotAMap_Normal, nil, "unknown map dropped")
end)
