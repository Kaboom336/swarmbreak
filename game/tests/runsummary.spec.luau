local RunSummary = load("RunSummary")

test("run summary formats every recap stat", function()
	local recap = RunSummary.format({
		Won = true,
		Wave = 12,
		Duration = 754,
		Kills = 1234,
		Damage = 98765,
		GemsEarned = 42,
		ShardsEarned = 3,
	})
	eq(recap.Title, "VICTORY", "victory title")
	eq(recap.Wave, "Wave 12", "wave")
	eq(recap.Duration, "Time 12:34", "duration")
	eq(recap.Kills, "Kills 1,234", "kills")
	eq(recap.Damage, "Damage 98,765", "damage")
	eq(recap.Rewards, "Rewards  +42 Gems  +3 shards", "rewards")
end)

test("run summary tolerates missing stats", function()
	local recap = RunSummary.format(nil)
	eq(recap.Title, "RUN OVER", "default title")
	eq(recap.Duration, "Time 0:00", "missing duration")
	eq(recap.Damage, "Damage 0", "missing damage")
	eq(recap.Rewards, "Rewards  +0 Gems  +0 shards", "missing rewards")
	eq(recap.Bests, "", "no bests")
end)

test("run summary calls out personal bests", function()
	local recap = RunSummary.format({
		NewBestWave = true,
		NewBestKills = true,
		NewBestDamage = true,
	})
	eq(recap.Bests, "NEW BEST: Wave / Kills / Damage", "best callouts")
	eq(RunSummary.format({ NewBest = true }).Bests, "NEW BEST: Wave", "legacy wave best")
end)

test("run summary keeps reward totals separate", function()
	local recap = RunSummary.format({ GemsEarned = 1200, ShardsEarned = 10 })
	eq(recap.Rewards, "Rewards  +1,200 Gems  +10 shards", "reward totals")
end)

test("retry state rejects duplicate requests", function()
	local state = RunSummary.newRetryState()
	eq(RunSummary.acceptRetry(state, 101), true, "first request")
	eq(RunSummary.acceptRetry(state, 101), false, "duplicate request")
	eq(RunSummary.acceptRetry(state, 202), true, "different player")
	eq(RunSummary.acceptRetry(state, nil), false, "missing player")
end)
