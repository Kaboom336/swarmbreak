--!strict
-- Pure formatting and retry admission for the end-of-run recap.

export type Snapshot = {
	Won: boolean?,
	Wave: number?,
	Duration: number?,
	Kills: number?,
	Damage: number?,
	GemsEarned: number?,
	ShardsEarned: number?,
	NewBest: boolean?, -- legacy wave-best flag
	NewBestWave: boolean?,
	NewBestDuration: boolean?,
	NewBestKills: boolean?,
	NewBestDamage: boolean?,
}

export type Formatted = {
	Title: string,
	Wave: string,
	Duration: string,
	Kills: string,
	Damage: string,
	Rewards: string,
	Bests: string,
}

export type RetryState = { [any]: boolean }

local RunSummary = {}

local function value(n: number?): number
	return if type(n) == "number" then math.max(0, n) else 0
end

function RunSummary.formatNumber(n: number?): string
	local text = tostring(math.floor(value(n) + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return if text:sub(1, 1) == "," then text:sub(2) else text
end

function RunSummary.formatDuration(seconds: number?): string
	local whole = math.floor(value(seconds))
	return string.format("%d:%02d", math.floor(whole / 60), whole % 60)
end

local function best(enabled: boolean?, label: string, out: { string })
	if enabled then
		table.insert(out, label)
	end
end

function RunSummary.format(snapshot: Snapshot?): Formatted
	local s = snapshot or {}
	local bests = {}
	best(s.NewBestWave or s.NewBest, "Wave", bests)
	best(s.NewBestDuration, "Time", bests)
	best(s.NewBestKills, "Kills", bests)
	best(s.NewBestDamage, "Damage", bests)
	local gems = RunSummary.formatNumber(s.GemsEarned)
	local shards = RunSummary.formatNumber(s.ShardsEarned)
	return {
		Title = if s.Won then "VICTORY" else "RUN OVER",
		Wave = "Wave " .. RunSummary.formatNumber(s.Wave),
		Duration = "Time " .. RunSummary.formatDuration(s.Duration),
		Kills = "Kills " .. RunSummary.formatNumber(s.Kills),
		Damage = "Damage " .. RunSummary.formatNumber(s.Damage),
		Rewards = string.format("Rewards  +%s Gems  +%s shards", gems, shards),
		Bests = if #bests > 0 then "NEW BEST: " .. table.concat(bests, " / ") else "",
	}
end

function RunSummary.newRetryState(): RetryState
	return {}
end

-- True only for the first request from a key. Replayed network requests are harmless.
function RunSummary.acceptRetry(state: RetryState, key: any): boolean
	if key == nil or state[key] then
		return false
	end
	state[key] = true
	return true
end

return RunSummary
