--!strict
-- Daily reward and login streak. Pure (no Roblox globals): the server passes os.time().
-- Days are UTC day numbers (unix seconds / 86400), so "tomorrow" starts at midnight UTC.
-- A claim on the day after the last claim grows the streak; a missed day starts it over at 1.
-- The streak walks the 7 reward slots and wraps (day 8 pays slot 1 again).

export type Reward = { Gems: number, Shard: string?, Crate: string? }
export type Result = {
	Claimable: boolean, -- true when today's reward has not been paid yet
	NewStreak: number, -- the streak after this claim (unchanged when nothing is claimable)
	Slot: number, -- 1..7, the reward slot that this claim pays (or paid today)
	Today: number, -- today's day number, stored as LastClaimDay on a claim
}
-- What the client shows once per session (rides on StatsChanged as DailyPopup).
export type Popup = { Slot: number, Streak: number, Text: string, NextText: string }

local Daily = {}

Daily.DaySeconds = 86400
Daily.SlotCount = 7

-- Placeholders, tuned so a week of logins pays one 80-Gem perk on day 2 and a 150-Gem crate on
-- day 7. Shard "Equipped" resolves to the equipped weapon's element (Tech when it has none).
Daily.Rewards = {
	{ Gems = 40 },
	{ Gems = 60 },
	{ Gems = 60, Shard = "Tech" },
	{ Gems = 80 },
	{ Gems = 100, Shard = "Equipped" },
	{ Gems = 120 },
	{ Gems = 150, Crate = "Gem" },
} :: { Reward }

-- UTC day number of a unix time.
function Daily.dayIndex(unix: number): number
	return math.floor(unix / Daily.DaySeconds)
end

-- Reward slot (1..7) for a streak length (1 -> 1, 7 -> 7, 8 -> 1).
function Daily.slot(streak: number): number
	return ((streak - 1) % Daily.SlotCount) + 1
end

function Daily.nextSlot(slot: number): number
	return slot % Daily.SlotCount + 1
end

-- Decide today's claim from the saved LastClaimDay / Streak and the current unix time.
function Daily.evaluate(lastClaimDay: number, streak: number, now: number): Result
	local today = Daily.dayIndex(now)
	if lastClaimDay == today then
		return {
			Claimable = false,
			NewStreak = streak,
			Slot = Daily.slot(math.max(streak, 1)),
			Today = today,
		}
	end
	local newStreak = if lastClaimDay == today - 1 then streak + 1 else 1
	return {
		Claimable = true,
		NewStreak = newStreak,
		Slot = Daily.slot(newStreak),
		Today = today,
	}
end

-- A copy of the slot's reward with Shard "Equipped" resolved to a real element.
function Daily.reward(slot: number, equippedElement: string?): Reward
	local entry = Daily.Rewards[slot] or Daily.Rewards[1]
	local shard = entry.Shard
	if shard == "Equipped" then
		shard = equippedElement or "Tech"
	end
	return { Gems = entry.Gems, Shard = shard, Crate = entry.Crate }
end

-- "+60 Gems, +1 Tech shard" / "+150 Gems, free Gem crate"
function Daily.rewardText(reward: Reward): string
	local parts = { string.format("+%d Gems", reward.Gems) }
	if reward.Shard then
		table.insert(parts, string.format("+1 %s shard", reward.Shard))
	end
	if reward.Crate then
		table.insert(parts, string.format("free %s crate", reward.Crate))
	end
	return table.concat(parts, ", ")
end

-- The short label of one box in the 7-day strip: "40", "60 +shard", "150 +crate".
function Daily.shortText(reward: Reward): string
	local s = tostring(reward.Gems)
	if reward.Shard then
		s ..= " +shard"
	end
	if reward.Crate then
		s ..= " +crate"
	end
	return s
end

return Daily
