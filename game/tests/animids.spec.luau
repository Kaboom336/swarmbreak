--!strict
local AnimIds = load("AnimIds")
local AnimCurves = load("AnimCurves")

test("animation id placeholders match every exposed clip and remain zero", function()
	local expected = {
		Player = {
			"FireLoop",
			"Melee1",
			"Melee2",
			"Melee3",
			"DashRoll",
			"HitFlinch",
			"LevelUpFlourish",
		},
		Enemy = { "Walk", "Idle", "AttackWindup", "AttackStrike", "AttackRecover", "Hit", "Death" },
		FX = { "KillGem", "EvolutionRing" },
	}
	for groupName, keys in expected do
		local group = AnimIds[groupName]
		assert(type(group) == "table", groupName .. " group missing")
		local count = 0
		for key, value in group do
			count += 1
			eq(value, 0, groupName .. "." .. key .. " must remain a placeholder")
		end
		eq(count, #keys, groupName .. " key count")
		for _, key in keys do
			eq(group[key], 0, groupName .. "." .. key .. " missing")
		end
	end
	local curveForClip = {
		Player = {
			FireLoop = "fireLoopAt",
			Melee1 = "comboSwingAt",
			Melee2 = "comboSwingAt",
			Melee3 = "comboSwingAt",
			DashRoll = "dashRollAt",
			HitFlinch = "hitFlinch",
			LevelUpFlourish = "levelUpFlourish",
		},
		Enemy = {
			Walk = "enemyWalkPhase",
			Idle = "idleBreath",
			AttackWindup = "enemyAttackAt",
			AttackStrike = "enemyAttackAt",
			AttackRecover = "enemyAttackAt",
			Hit = "enemyHitSquash",
			Death = "deathSquash",
		},
		FX = {
			KillGem = "gemPop",
			EvolutionRing = "evolutionEnvelope",
		},
	}
	for groupName, clips in curveForClip do
		for clipName, curveName in clips do
			assert(
				type(AnimCurves[curveName]) == "function",
				groupName .. "." .. clipName .. " curve missing"
			)
		end
	end
end)
