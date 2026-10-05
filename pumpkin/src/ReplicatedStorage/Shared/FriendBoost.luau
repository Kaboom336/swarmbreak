--!strict

local FriendBoost = {}

function FriendBoost.boost(friendCount: number): number
	return math.min(5, math.max(0, math.floor(friendCount))) * 0.1
end

function FriendBoost.multiplier(friendCount: number): number
	return 1 + FriendBoost.boost(friendCount)
end

return FriendBoost
