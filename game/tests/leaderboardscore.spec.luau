local LeaderboardScore = load("LeaderboardScore")

test("campaign leaderboard score is monotonic by difficulty, stage, then waves", function()
	local normal = LeaderboardScore.score("Normal", 15, 8)
	local hard = LeaderboardScore.score("Hard", 1, 0)
	local nightmare = LeaderboardScore.score("Nightmare", 1, 0)
	assert(hard > normal, "Hard must beat every Normal stage")
	assert(nightmare > LeaderboardScore.score("Hard", 15, 8), "Nightmare must beat Hard")
	assert(
		LeaderboardScore.score("Normal", 2, 0) > LeaderboardScore.score("Normal", 1, 8),
		"a later stage must beat waves on an earlier stage"
	)
	assert(
		LeaderboardScore.score("Normal", 2, 4) > LeaderboardScore.score("Normal", 2, 3),
		"more cleared waves must win within a stage"
	)
end)

test("campaign leaderboard score decodes for display", function()
	local score = LeaderboardScore.score("Nightmare", 15, 8)
	local difficulty, stage, waves = LeaderboardScore.decode(score)
	eq(difficulty, "Nightmare", "difficulty")
	eq(stage, 15, "stage")
	eq(waves, 8, "cleared waves")
end)
