local AbilityPool = load("AbilityPool")

test("scythe exposes six abilities with three implemented", function()
	local pool = AbilityPool.forWeapon("Reaper")
	eq(#pool >= 6, true, "ability pool size")
	local implemented = 0
	for _, ability in pool do
		eq(ability.Price, 0, ability.Id .. " price")
		if ability.Implemented then
			implemented += 1
		end
	end
	eq(implemented, 3, "implemented ability count")
end)

test("scythe loadout is two distinct pool abilities plus its ultimate", function()
	local default = AbilityPool.defaultLoadout("Reaper")
	eq(AbilityPool.isValidLoadout("Reaper", default), true, "default loadout")
	eq(
		AbilityPool.isValidLoadout("Reaper", {
			Abilities = { default.Abilities[1], default.Abilities[1] },
			Ultimate = default.Ultimate,
		}),
		false,
		"duplicate abilities"
	)
	eq(
		AbilityPool.isValidLoadout("Reaper", {
			Abilities = { "missing", default.Abilities[2] },
			Ultimate = default.Ultimate,
		}),
		false,
		"unknown ability"
	)
end)
