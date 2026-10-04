local Lobby = load("Lobby")
local ProfileSchema = load("ProfileSchema")

test("start pad requires three full seconds", function()
	eq(Lobby.StartPadSeconds, 3, "pad duration")
	assert(not Lobby.isPadReady(10, 12.99), "pad should still be charging")
	assert(Lobby.isPadReady(10, 13), "pad should start at three seconds")
end)

test("map and difficulty pickers explain locked choices", function()
	local profile = ProfileSchema.default()
	local maps = Lobby.mapOptions(profile)
	eq(maps[1].Locked, false, "Mars Core available")
	eq(maps[2].LockText, "Clear Mars Core on Normal", "next-map requirement")
	local ok, reason = Lobby.canSelectDifficulty(profile, "Outpost9", "Hard")
	eq(ok, false, "Hard locked")
	assert(reason:find("Normal"), reason)
	profile.Flags.MapClear_Outpost9_Normal = true
	eq(Lobby.canSelectDifficulty(profile, "Outpost9", "Hard"), true, "Hard unlocked")
end)

test("stage picker exposes only stages unlocked on the selected difficulty", function()
	local profile = ProfileSchema.default()
	local options = Lobby.stageOptions(profile, "Outpost9", "Normal")
	eq(#options, 15, "stage options")
	eq(options[1].Locked, false, "stage one")
	eq(options[2].Locked, true, "stage two")
	profile.Flags.StageClear_Outpost9_Normal_1 = true
	eq(Lobby.canSelectStage(profile, "Outpost9", "Normal", 2), true, "stage two unlocked")
end)

test("players are grouped into parties without exceeding the party size", function()
	local groups = Lobby.groupParties({ 8, 3, 5, 1, 2 })
	eq(#groups, 2, "party count")
	eq(#groups[1], Lobby.PartySize, "first party is full")
	eq(#groups[2], 1, "last party contains the remainder")

	local seen = {}
	for _, group in groups do
		assert(#group <= Lobby.PartySize, "party exceeds the configured size")
		for _, userId in group do
			assert(not seen[userId], "player grouped more than once")
			seen[userId] = true
		end
	end
	for _, userId in { 8, 3, 5, 1, 2 } do
		assert(seen[userId], "player missing from parties")
	end
end)

test("every lobby shop price is zero", function()
	assert(#Lobby.ShopItems > 0, "shop board needs at least one item")
	for _, item in Lobby.ShopItems do
		eq(item.Price, 0, item.Name .. " price")
	end
end)
