--!strict
local Codes = load("Codes")

test("codes normalize input and block one-use reuse", function()
	local used = {}
	local rewards = { SPOOKY = { Kind = "Wins", Amount = 500 } }
	local ok, reward, reason = Codes.redeem(used, rewards, "  spooky ")
	eq(ok, true, "first redemption")
	eq(reward.Amount, 500, "reward")
	eq(reason, "OK", "success reason")

	ok, reward, reason = Codes.redeem(used, rewards, "SPOOKY")
	eq(ok, false, "reuse blocked")
	eq(reward, nil, "no duplicate reward")
	eq(reason, "USED", "reuse reason")
end)

test("unknown codes do not alter the redemption ledger", function()
	local used = {}
	local ok, _, reason = Codes.redeem(used, {}, "nope")
	eq(ok, false, "unknown rejected")
	eq(reason, "INVALID", "invalid reason")
	eq(next(used), nil, "ledger unchanged")
end)
