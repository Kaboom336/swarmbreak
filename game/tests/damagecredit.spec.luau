local DamageCredit = load("DamageCredit")

local function rewardMap(rewards)
	local out = {}
	for _, reward in rewards do
		out[reward.UserId] = reward.Coins
	end
	return out
end

test("assist ties break deterministically", function()
	local ledger = DamageCredit.new()
	DamageCredit.record(ledger, 20, 50, 1)
	DamageCredit.record(ledger, 10, 50, 1)
	local rewards = DamageCredit.split(ledger, 30, 5, 1, { [10] = true, [20] = true, [30] = true })
	eq(rewards[1].UserId, 10, "lower user id first")
	eq(rewards[1].Coins, 2, "odd coin goes to lower id")
	eq(rewards[2].Coins, 1, "other tied helper")
end)

test("stale damage expires outside the assist window", function()
	local ledger = DamageCredit.new()
	DamageCredit.record(ledger, 1, 40, 0)
	DamageCredit.record(ledger, 2, 60, DamageCredit.AssistWindow + 0.01)
	eq(ledger[1], nil, "stale contributor pruned")
	eq(#DamageCredit.split(ledger, 2, 100, DamageCredit.AssistWindow + 0.01), 0, "killer excluded")
end)

test("contributor ledgers stay bounded", function()
	local ledger = DamageCredit.new()
	for userId = 1, DamageCredit.MaxContributors + 3 do
		DamageCredit.record(ledger, userId, userId, 1)
	end
	local count = 0
	for _ in ledger do
		count += 1
	end
	eq(count, DamageCredit.MaxContributors, "bounded size")
	eq(ledger[1], nil, "weakest contributor evicted")
end)

test("disconnected players and the killer get no assist", function()
	local ledger = DamageCredit.new()
	DamageCredit.record(ledger, 1, 40, 1)
	DamageCredit.record(ledger, 2, 30, 1)
	DamageCredit.record(ledger, 3, 30, 1)
	local rewards = rewardMap(DamageCredit.split(ledger, 1, 100, 1, { [1] = true, [2] = true }))
	eq(rewards[1], nil, "no self assist")
	eq(rewards[2], 50, "connected helper receives pool")
	eq(rewards[3], nil, "disconnected helper excluded")
	eq(
		#DamageCredit.split(ledger, 1, 100, 1, { [2] = true, [3] = true }),
		0,
		"disconnected killer invalidates settlement"
	)
end)

test("zero damage and overkill do not inflate credit", function()
	local ledger = DamageCredit.new()
	DamageCredit.record(ledger, 1, 0, 1)
	-- CombatEffects records health removed, so a 1,000 damage hit on 25 health records 25.
	DamageCredit.record(ledger, 2, math.min(1000, 25), 1)
	eq(ledger[1], nil, "zero ignored")
	eq(ledger[2].Damage, 25, "damage capped to remaining health by caller")
end)

test("boss-sized damage splits without a per-hit ceiling", function()
	local ledger = DamageCredit.new()
	DamageCredit.record(ledger, 1, 750000, 1)
	DamageCredit.record(ledger, 2, 250000, 1)
	local rewards = rewardMap(DamageCredit.split(ledger, 3, 1000, 1))
	eq(rewards[1], 375, "three quarters")
	eq(rewards[2], 125, "one quarter")
end)

test("integer assist rewards conserve the capped pool", function()
	local ledger = DamageCredit.new()
	DamageCredit.record(ledger, 1, 1, 1)
	DamageCredit.record(ledger, 2, 1, 1)
	DamageCredit.record(ledger, 3, 1, 1)
	local total = 0
	for _, reward in DamageCredit.split(ledger, 4, 101, 1) do
		total += reward.Coins
	end
	eq(total, 51, "rounded 50 percent pool")
end)
