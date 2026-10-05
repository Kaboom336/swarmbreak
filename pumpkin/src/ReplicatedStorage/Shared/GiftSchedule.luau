--!strict
local Config = require(script.Parent.Config)

local GiftSchedule = {}

function GiftSchedule.sessionSeconds(joinedAt: number, now: number): number
	return math.max(0, math.floor(now - joinedAt))
end

function GiftSchedule.isClaimable(
	index: number,
	sessionSeconds: number,
	claims: { [string]: boolean }
): boolean
	local gift = Config.PlaytimeGifts[index]
	return gift ~= nil and sessionSeconds >= gift.Minutes * 60 and claims[tostring(index)] ~= true
end

function GiftSchedule.claimableIndices(
	sessionSeconds: number,
	claims: { [string]: boolean }
): { number }
	local result = {}
	for index in Config.PlaytimeGifts do
		if GiftSchedule.isClaimable(index, sessionSeconds, claims) then
			table.insert(result, index)
		end
	end
	return result
end

function GiftSchedule.nextGift(
	sessionSeconds: number,
	claims: { [string]: boolean }
): (number?, number)
	for index, gift in Config.PlaytimeGifts do
		if claims[tostring(index)] ~= true then
			return index, math.max(0, gift.Minutes * 60 - sessionSeconds)
		end
	end
	return nil, 0
end

function GiftSchedule.claim(
	index: number,
	sessionSeconds: number,
	claims: { [string]: boolean }
): (boolean, any?)
	if not GiftSchedule.isClaimable(index, sessionSeconds, claims) then
		return false, nil
	end
	claims[tostring(index)] = true
	return true, Config.PlaytimeGifts[index]
end

return GiftSchedule
