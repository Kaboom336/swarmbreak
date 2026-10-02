local BossPhases = load("BossPhases")
local Enemies = load("Enemies")

test("boss phase threshold is inclusive and ignores dead bosses", function()
	for typeName, phase in BossPhases.Defs do
		local maxHealth = 1000
		assert(
			not BossPhases.shouldTransition(
				typeName,
				maxHealth * phase.Threshold + 1,
				maxHealth,
				false
			)
		)
		assert(BossPhases.shouldTransition(typeName, maxHealth * phase.Threshold, maxHealth, false))
		assert(
			BossPhases.shouldTransition(typeName, maxHealth * phase.Threshold - 1, maxHealth, false)
		)
		assert(not BossPhases.shouldTransition(typeName, 0, maxHealth, false))
	end
end)

test("boss phase transition is one shot", function()
	for typeName, phase in BossPhases.Defs do
		assert(phase.OneShot, typeName .. " phase must be one shot")
		assert(
			BossPhases.shouldTransition(typeName, 1, 100, false),
			typeName .. " first transition"
		)
		assert(
			not BossPhases.shouldTransition(typeName, 1, 100, true),
			typeName .. " repeated transition"
		)
	end
end)

test("every boss has exactly one valid phase definition", function()
	local bossCount = 0
	for typeName, enemy in Enemies.Defs do
		if enemy.Boss then
			bossCount += 1
			assert(BossPhases.Defs[typeName], typeName .. " has no phase")
		end
	end
	local phaseCount = 0
	for typeName, phase in BossPhases.Defs do
		phaseCount += 1
		assert(Enemies.Defs[typeName] and Enemies.Defs[typeName].Boss, typeName .. " is not a boss")
		assert(phase.Threshold > 0 and phase.Threshold < 1, typeName .. " threshold")
		assert(#phase.Banner > 0, typeName .. " banner")
		assert(#phase.Color == 3, typeName .. " color")
		for _, channel in phase.Color do
			assert(channel >= 0 and channel <= 255, typeName .. " color channel")
		end
	end
	eq(phaseCount, bossCount, "phase coverage")
end)

test("phase attack modifiers stay within safe bounds", function()
	for typeName, phase in BossPhases.Defs do
		local modifiers = phase.Modifiers
		assert(
			modifiers.AttackCooldownMultiplier >= 0.5 and modifiers.AttackCooldownMultiplier <= 1,
			typeName .. " attack cooldown"
		)
		assert(
			modifiers.SummonCooldownMultiplier >= 0.5 and modifiers.SummonCooldownMultiplier <= 1,
			typeName .. " summon cooldown"
		)
		assert(
			modifiers.SummonCount >= 1 and modifiers.SummonCount <= 3,
			typeName .. " summon count"
		)
		assert(
			modifiers.VolleyCount >= 1 and modifiers.VolleyCount <= 4,
			typeName .. " volley count"
		)
		assert(
			modifiers.VolleyInterval >= 0.1 and modifiers.VolleyInterval <= 0.5,
			typeName .. " volley interval"
		)
	end
end)
