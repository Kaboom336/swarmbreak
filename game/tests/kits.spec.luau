local Kits = load("Kits")
local ProfileSchema = load("ProfileSchema")

test("the four kits have plain labels and placeholder prices", function()
	eq(#Kits.Order, 4, "four kits")
	eq(Kits.Defs.Soldier.UnlockGems, 0, "Soldier is free")
	for _, id in { "Brawler", "Engineer", "Medic" } do
		eq(Kits.Defs[id].Id, id, id .. " id")
		eq(Kits.Defs[id].Label, id, id .. " label")
		eq(Kits.Defs[id].UnlockGems, 300, id .. " placeholder cost")
	end
end)

test("mods resolve every field to a number for the weapon kind", function()
	local soldierDamage, soldierHealth, soldierSpeed, soldierOrbs, soldierHeal =
		Kits.mods("Soldier", "Hitscan")
	eq(soldierDamage, 1.10, "Soldier Hitscan damage")
	eq(Kits.mods("Soldier", "Melee"), 1, "Soldier other damage")
	eq(soldierHealth, 0, "Soldier health")
	eq(soldierSpeed, 0, "Soldier speed")
	eq(soldierOrbs, 0, "Soldier orbs")
	eq(soldierHeal, 0, "Soldier healing")

	local brawlerDamage, brawlerHealth = Kits.mods("Brawler", "Melee")
	eq(brawlerDamage, 1.15, "Brawler Melee damage")
	eq(brawlerHealth, 25, "Brawler health")

	local engineerDamage, _, _, engineerOrbs = Kits.mods("Engineer", "Orbital")
	eq(engineerDamage, 1.10, "Engineer Orbital damage")
	eq(engineerOrbs, 1, "Engineer orb")

	local _, _, medicSpeed, _, medicHeal = Kits.mods("Medic", "Hitscan")
	eq(medicHeal, 2, "Medic healing")
	eq(medicSpeed, 1, "Medic speed")
end)

test("mods never changes definitions", function()
	Kits.mods("Engineer", "Orbital")
	eq(Kits.Defs.Engineer.Mods.OrbsAdd, 1, "definition untouched")
	eq(Kits.Defs.Engineer.Mods.DamageMultByKind.Orbital, 0.10, "kind map untouched")
end)

test("unlock spends Gems once and failed unlocks spend nothing", function()
	local p = ProfileSchema.default()
	p.Gems = 300
	local same, ok, why = Kits.unlock(p, "Brawler")
	eq(same, p, "same profile")
	eq(ok, true, "unlocked")
	eq(why, "", "no failure reason")
	eq(p.Gems, 0, "paid in Gems")
	eq(Kits.isUnlocked(p, "Brawler"), true, "owned")

	local _, again = Kits.unlock(p, "Brawler")
	eq(again, false, "cannot buy twice")
	eq(p.Gems, 0, "duplicate spends nothing")
	local _, poor = Kits.unlock(p, "Medic")
	eq(poor, false, "cannot afford")
	eq(p.KitsOwned.Medic, nil, "failed kit not granted")
end)

test("profile defaults and sanitize repair kit ownership and selection", function()
	local fresh = ProfileSchema.default()
	eq(fresh.Kit, "Soldier", "default kit")
	eq(fresh.KitsOwned.Soldier, true, "default ownership")

	local clean = ProfileSchema.sanitize({
		Kit = "Engineer",
		KitsOwned = { Engineer = true, Bogus = true, Medic = "yes" },
	})
	eq(clean.Kit, "Engineer", "owned selection kept")
	eq(clean.KitsOwned.Soldier, true, "Soldier repaired")
	eq(clean.KitsOwned.Engineer, true, "known ownership kept")
	eq(clean.KitsOwned.Bogus, nil, "unknown ownership dropped")
	eq(clean.KitsOwned.Medic, nil, "non-boolean ownership dropped")

	local repaired = ProfileSchema.sanitize({ Kit = "Brawler", KitsOwned = {} })
	eq(repaired.Kit, "Soldier", "unowned selection repaired")
end)
