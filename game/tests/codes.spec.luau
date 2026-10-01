local Codes = load("Codes")
local ProfileSchema = load("ProfileSchema")

local function profile()
	return ProfileSchema.default()
end

test("unknown code is refused", function()
	local ok = Codes.check("NOT-A-CODE", profile(), 0)
	eq(ok, false, "unknown refused")
end)

test("lower-case and padded input is accepted", function()
	local p, reward = Codes.redeem(profile(), "  welcome  ", 0)
	assert(reward, "reward returned")
	eq(p.Gems, 100, "gems paid")
	eq(p.Redeemed.WELCOME, true, "normalized key stored")
end)

test("minimum wave blocks until the best wave is reached", function()
	local p = profile()
	local ok = Codes.check("WAVE10", p, 0)
	eq(ok, false, "too early")
	p.BestWave = 10
	eq(Codes.check("WAVE10", p, 0), true, "wave reached")
end)

test("expired code is refused", function()
	local expires = Codes.Defs.OCTOBER.ExpiresDay
	assert(expires, "expiring definition")
	eq(Codes.check("OCTOBER", profile(), expires + 1), false, "expired")
	eq(Codes.check("OCTOBER", profile(), expires), true, "valid through expiry day")
end)

test("a code can only be redeemed once", function()
	local first, reward = Codes.redeem(profile(), "WELCOME", 0)
	assert(reward, "first reward")
	local second, secondReward = Codes.redeem(first, "WELCOME", 0)
	eq(second, first, "refusal returns existing profile")
	eq(secondReward, nil, "no second reward")
end)

test("reward and updated tables are copied, not shared", function()
	local original = profile()
	local updated, reward = Codes.redeem(original, "OUTPOST", 0)
	assert(reward, "reward returned")
	eq(original.Shards.Tech, 0, "original shards untouched")
	eq(original.Redeemed.OUTPOST, nil, "original redeemed untouched")
	eq(updated.Shards.Tech, 1, "shard paid")
	reward.Shard = "Dark"
	eq(Codes.Defs.OUTPOST.Reward.Shard, "Tech", "definition untouched")
end)

test("sanitize drops non-boolean Redeemed entries", function()
	local p = ProfileSchema.sanitize({
		Redeemed = { WELCOME = true, OUTPOST = false, WAVE10 = "yes", [5] = true },
	})
	eq(p.Redeemed.WELCOME, true, "true kept")
	eq(p.Redeemed.OUTPOST, nil, "false dropped")
	eq(p.Redeemed.WAVE10, nil, "string dropped")
	eq(p.Redeemed[5], nil, "non-string key dropped")
end)
