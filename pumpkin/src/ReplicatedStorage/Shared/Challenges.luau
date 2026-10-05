--!strict

export type Challenge = {
	id: string,
	label: string,
	kind: string,
	target: number,
	rewardWins: number,
}

local Challenges = {}

local DAILY = {
	{ label = "DODGE 6 OBSTACLES", kind = "Dodge", target = 6, rewardWins = 150 },
	{ label = "COLLECT 5 TREATS", kind = "Pickup", target = 5, rewardWins = 150 },
	{ label = "FINISH 3 RIDES", kind = "Finish", target = 3, rewardWins = 175 },
}

function Challenges.dayKey(unixTime: number): number
	return math.floor(math.max(0, unixTime) / 86_400)
end

function Challenges.weekKey(unixTime: number): number
	return math.floor(Challenges.dayKey(unixTime) / 7)
end

function Challenges.daily(unixTime: number): Challenge
	local day = Challenges.dayKey(unixTime)
	local template = DAILY[day % #DAILY + 1]
	return {
		id = "daily-" .. day,
		label = template.label,
		kind = template.kind,
		target = template.target,
		rewardWins = template.rewardWins,
	}
end

function Challenges.weekly(unixTime: number): Challenge
	local week = Challenges.weekKey(unixTime)
	return {
		id = "weekly-" .. week,
		label = "FIND 25 CANDY STARS",
		kind = "Candy",
		target = 25,
		rewardWins = 600,
	}
end

function Challenges.advance(
	challenge: Challenge,
	progress: number,
	eventKind: string,
	amount: number?
): (number, boolean)
	local nextProgress = math.clamp(math.floor(progress), 0, challenge.target)
	if eventKind == challenge.kind then
		nextProgress =
			math.min(challenge.target, nextProgress + math.max(1, math.floor(amount or 1)))
	end
	return nextProgress, nextProgress >= challenge.target
end

return Challenges
