--!strict
local Weapons = load("Weapons")

local function singleTargetDps(weapon): number
	return weapon.Damage * weapon.FireRate * weapon.Pellets
end

test("weapons at the same rarity stay within 35 percent single-target DPS", function()
	for _, rarity in Weapons.RarityOrder do
		local lowest = math.huge
		local highest = 0
		for _, weapon in Weapons.Defs do
			if weapon.Rarity == rarity then
				local dps = singleTargetDps(weapon)
				lowest = math.min(lowest, dps)
				highest = math.max(highest, dps)
			end
		end
		assert(highest <= lowest * 1.35, rarity .. " weapons differ by more than 35 percent")
	end
end)

test("every weapon has a distinct effective range", function()
	local allRanges = {}
	for id, weapon in Weapons.Defs do
		assert(
			not allRanges[weapon.Range],
			id .. " shares its best range with " .. tostring(allRanges[weapon.Range])
		)
		allRanges[weapon.Range] = id
	end

	local roleWeapons = {
		Starter = Weapons.Defs.Starter,
		Shotgun = Weapons.Defs.Scatter,
		Sniper = Weapons.Defs.Marksman,
		Sword = Weapons.Defs.Saber,
		Scythe = Weapons.Defs.Reaper,
		Laser = Weapons.Defs.Ion,
	}
	assert(roleWeapons.Shotgun.Range < roleWeapons.Starter.Range, "shotgun is a close weapon")
	assert(roleWeapons.Shotgun.Spread > roleWeapons.Starter.Spread, "shotgun has spread")
	assert(roleWeapons.Sniper.Range > roleWeapons.Starter.Range, "sniper is a long weapon")
	eq(roleWeapons.Sniper.Spread, 0, "sniper is precise")
	assert(roleWeapons.Sword.Spread < roleWeapons.Scythe.Spread, "sword has a focused arc")
	assert(roleWeapons.Scythe.Range > roleWeapons.Sword.Range, "scythe has a wider sweep")
	eq(roleWeapons.Laser.Kind, "Beam", "laser uses a beam")
	eq(roleWeapons.Laser.Spread, 0, "laser beam is precise")
end)

test("raw DPS rises strictly at every rarity step", function()
	local previousHighest = 0
	for _, rarity in Weapons.RarityOrder do
		local lowest = math.huge
		local highest = 0
		for _, weapon in Weapons.Defs do
			if weapon.Rarity == rarity then
				local dps = singleTargetDps(weapon)
				lowest = math.min(lowest, dps)
				highest = math.max(highest, dps)
			end
		end
		assert(lowest > previousHighest, rarity .. " DPS does not clear the previous rarity")
		previousHighest = highest
	end
end)

test("higher-rarity weapons have strictly more DPS within a family", function()
	local families = {
		{ "Starter", "Marksman" },
		{ "Burst", "Arc" },
		{ "Blade", "Saber" },
		{ "Scatter", "Hornet", "Nova" },
		{ "Hammer", "Reaper" },
		{ "Guardian", "Storm", "Halo" },
	}
	for _, family in families do
		local previous = 0
		for _, id in family do
			local dps = singleTargetDps(Weapons.Defs[id])
			assert(dps > previous, id .. " does not improve its family DPS")
			previous = dps
		end
	end
end)
