local PartyConfig = load("PartyConfig")

local function validConfig(overrides)
	local config = {
		Map = "Outpost 9",
		Difficulty = "Normal",
		Mode = "Survival",
		PartySize = 4,
		FriendsOnly = false,
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return config
end

test("party size clamps from one to eight", function()
	local tooSmall = PartyConfig.validate(validConfig({ PartySize = -2 }))
	local tooLarge = PartyConfig.validate(validConfig({ PartySize = 12 }))

	assert(tooSmall ~= nil, "otherwise valid small party config accepted")
	assert(tooLarge ~= nil, "otherwise valid large party config accepted")
	eq(tooSmall.PartySize, 1, "small party size")
	eq(tooLarge.PartySize, 8, "large party size")
end)

test("friends-only flag is respected", function()
	local friendsOnly = PartyConfig.validate(validConfig({ FriendsOnly = true }))
	local openParty = PartyConfig.validate(validConfig({ FriendsOnly = false }))

	assert(friendsOnly ~= nil, "friends-only config accepted")
	assert(openParty ~= nil, "open config accepted")
	eq(friendsOnly.FriendsOnly, true, "friends-only party")
	eq(openParty.FriendsOnly, false, "open party")
end)

test("invalid maps and difficulties are rejected", function()
	local badMap, mapError = PartyConfig.validate(validConfig({ Map = "Unknown Map" }))
	local badDifficulty, difficultyError =
		PartyConfig.validate(validConfig({ Difficulty = "Impossible" }))

	eq(badMap, nil, "invalid map")
	eq(mapError, "invalid map", "map error")
	eq(badDifficulty, nil, "invalid difficulty")
	eq(difficultyError, "invalid difficulty", "difficulty error")
end)
