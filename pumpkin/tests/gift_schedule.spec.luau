--!strict
local Config = load("Config")
local GiftSchedule = load("GiftSchedule")

test("playtime gift schedule unlocks all eight gifts at the brief times", function()
	local expected = { 1, 3, 5, 8, 12, 17, 23, 30 }
	local claims = {}
	for index, minutes in expected do
		eq(Config.PlaytimeGifts[index].Minutes, minutes, "gift minute " .. index)
		eq(GiftSchedule.isClaimable(index, minutes * 60 - 1, claims), false, "too early")
		eq(GiftSchedule.isClaimable(index, minutes * 60, claims), true, "on time")
		local claimed = GiftSchedule.claim(index, minutes * 60, claims)
		eq(claimed, true, "claim " .. index)
		eq(GiftSchedule.isClaimable(index, minutes * 60, claims), false, "only once")
	end
	eq(#GiftSchedule.claimableIndices(30 * 60, claims), 0, "all claimed")
end)

test("session time starts over from each join timestamp", function()
	eq(GiftSchedule.sessionSeconds(1_000, 1_075), 75, "first session")
	eq(GiftSchedule.sessionSeconds(2_000, 2_005), 5, "new session")
end)
