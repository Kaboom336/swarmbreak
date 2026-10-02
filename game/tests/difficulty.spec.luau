local Difficulty = load("Difficulty")

test("multipliers increase strictly by tier", function()
	local previous = nil
	for _, id in Difficulty.Order do
		local tier = Difficulty.Defs[id]
		assert(tier, "missing tier " .. id)
		if previous then
			assert(tier.HealthMultiplier > previous.HealthMultiplier, id .. " health")
			assert(tier.DamageMultiplier > previous.DamageMultiplier, id .. " damage")
			assert(tier.SpawnRateMultiplier > previous.SpawnRateMultiplier, id .. " spawn rate")
		end
		previous = tier
	end
end)

test("rewards scale with risk", function()
	local baseReward = 100
	local previousReward = 0
	for _, id in Difficulty.Order do
		local reward = Difficulty.scaleReward(baseReward, id)
		assert(reward > previousReward, id .. " reward")
		previousReward = reward
	end
end)

test("locked tiers are rejected until the previous tier is beaten", function()
	local noneBeaten = {}
	assert(Difficulty.select("Normal", noneBeaten), "Normal starts unlocked")
	eq(Difficulty.select("Hard", noneBeaten), nil, "Hard starts locked")
	eq(Difficulty.select("Nightmare", noneBeaten), nil, "Nightmare starts locked")

	local normalBeaten = { Normal = true }
	assert(Difficulty.select("Hard", normalBeaten), "Hard unlocks after Normal")
	eq(Difficulty.select("Nightmare", normalBeaten), nil, "Nightmare still locked")

	local hardBeaten = { Normal = true, Hard = true }
	assert(Difficulty.select("Nightmare", hardBeaten), "Nightmare unlocks after Hard")
	eq(Difficulty.select("Unknown", hardBeaten), nil, "unknown tier rejected")
end)

test("difficulty scales wave stats without changing the input", function()
	local base = { Health = 2, Damage = 3, SpawnDelay = 4, Reward = 5 }
	local scaled = Difficulty.apply(base, "Hard")
	assert(scaled ~= base, "returns a new table")
	eq(scaled.Health, base.Health * Difficulty.Defs.Hard.HealthMultiplier, "health")
	eq(scaled.Damage, base.Damage * Difficulty.Defs.Hard.DamageMultiplier, "damage")
	eq(scaled.SpawnDelay, base.SpawnDelay / Difficulty.Defs.Hard.SpawnRateMultiplier, "delay")
	eq(scaled.Reward, Difficulty.scaleReward(base.Reward, "Hard"), "reward")
	eq(base.Health, 2, "input unchanged")
end)
