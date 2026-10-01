--!strict
-- Coin bonus for playing with friends. Pure.
local CoPlay = {}

local BONUS_PER_FRIEND = 0.1 -- placeholder
local MAX_BONUS = 0.3 -- placeholder

function CoPlay.coinMult(friendsInArena: number): number
	local friendCount = math.max(0, friendsInArena)
	return 1 + math.min(friendCount * BONUS_PER_FRIEND, MAX_BONUS)
end

return CoPlay
