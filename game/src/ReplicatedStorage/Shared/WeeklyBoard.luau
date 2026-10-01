--!strict
-- Weekly leaderboard helpers. Pure (no Roblox globals): the server passes os.time().
-- Weeks begin Monday at 00:00 UTC.

export type Entry = {
	Name: string,
	Score: number,
}

local WeeklyBoard = {}

WeeklyBoard.DaySeconds = 86400
WeeklyBoard.WeekSeconds = 7 * WeeklyBoard.DaySeconds

-- OrderedDataStore values are integers. Reserve six digits for elapsed seconds so a higher
-- wave always wins; within one wave, the smaller elapsed time produces the larger score.
WeeklyBoard.TimeBase = 1000000
WeeklyBoard.MaxTimeSeconds = WeeklyBoard.TimeBase - 1

function WeeklyBoard.weekIndex(now: number): number
	-- Unix day zero was a Thursday, three days after Monday.
	return math.floor((now + 3 * WeeklyBoard.DaySeconds) / WeeklyBoard.WeekSeconds)
end

function WeeklyBoard.key(now: number): string
	return "Week_" .. WeeklyBoard.weekIndex(now)
end

function WeeklyBoard.score(wave: number, timeSeconds: number): number
	local wholeWave = math.max(0, math.floor(wave))
	local wholeTime = math.clamp(math.floor(timeSeconds), 0, WeeklyBoard.MaxTimeSeconds)
	return wholeWave * WeeklyBoard.TimeBase + (WeeklyBoard.MaxTimeSeconds - wholeTime)
end

function WeeklyBoard.decode(encoded: number): (number, number)
	local wholeScore = math.max(0, math.floor(encoded))
	local wave = math.floor(wholeScore / WeeklyBoard.TimeBase)
	local timePart = wholeScore % WeeklyBoard.TimeBase
	return wave, WeeklyBoard.MaxTimeSeconds - timePart
end

function WeeklyBoard.top(entries: { Entry }, n: number): { Entry }
	local sorted = table.clone(entries)
	table.sort(sorted, function(a, b)
		if a.Score ~= b.Score then
			return a.Score > b.Score
		end
		return a.Name < b.Name
	end)

	local out = {}
	for i = 1, math.min(math.max(0, math.floor(n)), #sorted) do
		table.insert(out, sorted[i])
	end
	return out
end

return WeeklyBoard
