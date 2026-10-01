local Weapons = load("Weapons")

test("rarity odds sum to 100", function()
	local sum = 0
	for _, v in Weapons.RarityOdds do
		sum += v
	end
	assert(math.abs(sum - 100) < 1e-9, "sum = " .. sum)
end)

test("rollRarity boundaries", function()
	eq(Weapons.rollRarity(0), "Common", "0")
	eq(Weapons.rollRarity(0.6499), "Common", ".6499")
	eq(Weapons.rollRarity(0.65), "Rare", ".65")
	eq(Weapons.rollRarity(0.8999), "Rare", ".8999")
	eq(Weapons.rollRarity(0.90), "Epic", ".90")
	eq(Weapons.rollRarity(0.985), "Legendary", ".985")
	eq(Weapons.rollRarity(0.99999), "Legendary", ".99999")
end)

test("every rarity has at least one weapon and rollCrate returns a real id", function()
	for _, r in Weapons.RarityOrder do
		assert(#Weapons.idsOfRarity(r) >= 1, r .. " has no weapons")
	end
	for i = 0, 99 do
		for j = 0, 9 do
			local id = Weapons.rollCrate(i / 100, j / 10)
			assert(Weapons.Defs[id], "bad id " .. tostring(id))
		end
	end
	eq(Weapons.rollCrate(0.99, 0.0), "Halo", "first legendary id")
	eq(Weapons.rollCrate(0.99, 0.99), "Reaper", "last legendary id")
end)

test("odds text lists every rarity", function()
	local t = Weapons.oddsText()
	for _, r in Weapons.RarityOrder do
		assert(t:find(r, 1, true), "missing " .. r)
	end
end)

test("weapon defs are sane and rarity roughly tracks power", function()
	local best = {}
	for id, w in Weapons.Defs do
		eq(w.Id, id, "id matches key")
		assert(w.Damage > 0 and w.FireRate > 0 and w.Range > 0 and w.Pellets >= 1, id)
		local p = Weapons.power(w)
		best[w.Rarity] = math.max(best[w.Rarity] or 0, p)
	end
	assert(
		best.Legendary > best.Epic and best.Epic > best.Rare and best.Rare > best.Common,
		"power by rarity"
	)
end)

test("every kind has at least one weapon and kind fields are consistent", function()
	local kinds = {}
	for id, w in Weapons.Defs do
		kinds[w.Kind] = (kinds[w.Kind] or 0) + 1
		assert(#w.Description > 0, id .. " description")
		if w.Kind == "Orbital" then
			assert(w.Pellets >= 2, id .. " orbital needs 2+ orbs")
		end
		if w.Lunge then
			assert(w.Kind == "Melee", id .. " lunge only on melee")
		end
	end
	for _, k in Weapons.KindOrder do
		assert(kinds[k] and kinds[k] >= 1, "no weapon of kind " .. k)
	end
	assert(kinds.Hitscan <= #Weapons.KindOrder * 3, "sanity")
end)

test("every crate has a label and odds that sum to 100", function()
	for _, key in Weapons.CrateOrder do
		local crate = Weapons.Crates[key]
		assert(crate, "missing crate " .. key)
		assert(type(crate.Label) == "string" and #crate.Label > 0, key .. " label")
		local sum = 0
		for _, r in Weapons.RarityOrder do
			sum += crate.Odds[r] or 0
		end
		assert(math.abs(sum - 100) < 1e-9, key .. " sum = " .. sum)
	end
end)

test("the Gem crate never rolls Legendary", function()
	local odds = Weapons.Crates.Gem.Odds
	for i = 0, 999 do
		assert(Weapons.rollRarity(i / 1000, odds) ~= "Legendary", "roll " .. i)
	end
	eq(Weapons.rollRarity(0.9999, odds), "Epic", "top of the Gem crate")
end)

test("the Epic crate never rolls Common", function()
	local odds = Weapons.Crates.Epic.Odds
	for i = 0, 999 do
		assert(Weapons.rollRarity(i / 1000, odds) ~= "Common", "roll " .. i)
	end
	eq(Weapons.rollRarity(0, odds), "Rare", "bottom of the Epic crate")
end)

test("pity turns the 40th crate Legendary and the counter resets on one", function()
	eq(Weapons.PityAt, 40, "pity at")
	eq(Weapons.applyPity("Common", 38), "Common", "39th crate")
	eq(Weapons.applyPity("Common", 39), "Legendary", "40th crate")
	eq(Weapons.nextPityCount("Legendary", 39), 0, "reset")
	eq(Weapons.nextPityCount("Rare", 3), 4, "count up")
end)

test("duplicate Gems are positive integers rising with rarity", function()
	local prev = 0
	for _, r in Weapons.RarityOrder do
		local g = Weapons.DuplicateGems[r]
		assert(type(g) == "number" and g > 0 and g == math.floor(g), r)
		assert(g > prev, r .. " should pay more than the rarity below")
		prev = g
	end
end)

test("the Gem crate costs a whole number of Gems and has no pity", function()
	local g = Weapons.Crates.Gem.Gems
	assert(type(g) == "number" and g > 0 and g == math.floor(g), "gem cost")
	eq(Weapons.Crates.Gem.Pity, false, "no pity")
end)

test("odds text hides 0% rarities and says the pity rule", function()
	assert(not Weapons.oddsText("Gem"):find("Legendary", 1, true), "Gem crate text")
	assert(Weapons.oddsText("Basic"):find("guaranteed", 1, true), "Basic crate text")
	assert(Weapons.oddsText("Epic"):find("40th", 1, true), "Epic crate text")
	assert(not Weapons.oddsText("Epic"):find("Common", 1, true), "Epic crate hides Common")
end)

test("rollCrate on the Epic crate never returns a Common weapon", function()
	for i = 0, 99 do
		for j = 0, 9 do
			local id = Weapons.rollCrate(i / 100, j / 10, "Epic")
			local def = Weapons.Defs[id]
			assert(def, "bad id " .. tostring(id))
			assert(def.Rarity ~= "Common", id .. " is Common")
		end
	end
end)
