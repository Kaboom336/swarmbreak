--!strict
-- Pure all-time campaign leaderboard scoring and display decoding.
local Difficulty = require(script.Parent.Difficulty)

local LeaderboardScore = {}

LeaderboardScore.DifficultyBase = 10000
LeaderboardScore.StageBase = 100

local difficultyIndex: { [Difficulty.TierName]: number } = {
	Normal = 1,
	Hard = 2,
	Nightmare = 3,
}

function LeaderboardScore.score(
	difficulty: Difficulty.TierName,
	stage: number,
	clearedWaves: number
): number
	return difficultyIndex[difficulty] * LeaderboardScore.DifficultyBase
		+ math.floor(stage) * LeaderboardScore.StageBase
		+ math.floor(clearedWaves)
end

function LeaderboardScore.decode(score: number): (Difficulty.TierName, number, number)
	local wholeScore = math.max(0, math.floor(score))
	local index = math.floor(wholeScore / LeaderboardScore.DifficultyBase)
	local difficulty = Difficulty.Order[math.clamp(index, 1, #Difficulty.Order)]
	local stageScore = wholeScore % LeaderboardScore.DifficultyBase
	local stage = math.floor(stageScore / LeaderboardScore.StageBase)
	local clearedWaves = stageScore % LeaderboardScore.StageBase
	return difficulty, stage, clearedWaves
end

return LeaderboardScore
