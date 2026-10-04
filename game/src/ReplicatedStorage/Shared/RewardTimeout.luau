--!strict
-- Pure timing policy for server-owned level-up offers.
local RewardTimeout = {}

RewardTimeout.Seconds = 8

function RewardTimeout.shouldAutoPick(openedAt: number, now: number, offerCount: number): boolean
	return offerCount > 0 and openedAt > 0 and now - openedAt >= RewardTimeout.Seconds
end

function RewardTimeout.first(offer: { string }): string?
	return offer[1]
end

return RewardTimeout
