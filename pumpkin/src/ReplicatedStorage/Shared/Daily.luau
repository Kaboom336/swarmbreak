--!strict
local Daily = {}

export type Result = {
	claimable: boolean,
	streak: number,
	day: number,
}

function Daily.utcDay(unixTimestamp: number): number
	return math.floor(unixTimestamp / 86_400)
end

function Daily.nextStreak(
	lastClaimDay: number?,
	currentStreak: number,
	unixTimestamp: number
): Result
	local today = Daily.utcDay(unixTimestamp)
	local lastDay = lastClaimDay
	if lastDay == today then
		return { claimable = false, streak = math.max(0, currentStreak), day = today }
	end

	local streak = 1
	if lastDay ~= nil and lastDay == today - 1 then
		streak = math.max(0, currentStreak) % 7 + 1
	end
	return { claimable = true, streak = streak, day = today }
end

return Daily
