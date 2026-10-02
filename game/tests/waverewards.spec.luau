local WaveRewards = load("WaveRewards")
local Weapons = load("Weapons")

-- n roll triplets spread over [0, 1): the first roll walks a grid, the others are offset from it.
local function grid(n: number): { { number } }
	local out = {}
	for i = 0, n - 1 do
		local r = i / n
		table.insert(out, { r, (r + 0.37) % 1, (r + 0.71) % 1 })
	end
	return out
end

local function everOffered(id: string, stacks: { [string]: number }, kind: string): boolean
	for _, rolls in grid(300) do
		if table.find(WaveRewards.offer(1, stacks, kind, rolls), id) then
			return true
		end
	end
	return false
end

test("reward cards are well formed", function()
	eq(#WaveRewards.Order, 13, "thirteen cards")
	local kinds = { Stat = true, Weapon = true, Utility = true }
	for _, id in WaveRewards.Order do
		local c = WaveRewards.Defs[id]
		assert(c, "missing def " .. id)
		eq(c.Id, id, id .. " id")
		assert(c.Label ~= "" and c.Blurb ~= "", id .. " words")
		assert(c.Weight > 0, id .. " weight")
		assert(c.MaxStacks >= 1, id .. " stacks")
		assert(kinds[c.Kind], id .. " kind " .. tostring(c.Kind))
		if c.Kinds then
			for _, k in c.Kinds do
				assert(table.find(Weapons.KindOrder, k), id .. " weapon kind " .. k)
			end
		end
		for key, value in c.Apply do
			if type(value) == "number" then
				assert(table.find(WaveRewards.Fields, key), id .. " unknown field " .. key)
			else
				eq(key, "HealNow", id .. " boolean key")
			end
		end
	end
	for id in WaveRewards.Defs do
		assert(table.find(WaveRewards.Order, id), id .. " missing from Order")
	end
	eq(#WaveRewards.Fields, 10, "ten boost fields")
end)

test("offer gives three distinct real cards", function()
	local offer = WaveRewards.offer(1, {}, "Hitscan", { 0.1, 0.5, 0.9 })
	eq(#offer, 3, "three cards")
	local seen = {}
	for _, id in offer do
		assert(WaveRewards.Defs[id], "unknown card " .. tostring(id))
		assert(not seen[id], "duplicate " .. id)
		seen[id] = true
	end
end)

test("offer is deterministic for the same rolls", function()
	local a = WaveRewards.offer(1, {}, "Hitscan", { 0.1, 0.5, 0.9 })
	local b = WaveRewards.offer(1, {}, "Hitscan", { 0.1, 0.5, 0.9 })
	eq(table.concat(a, ","), table.concat(b, ","), "same rolls, same offer")
	local c = WaveRewards.offer(1, {}, "Hitscan", { 0.9, 0.1, 0.5 })
	assert(a[1] ~= c[1], "different rolls change the first card")
end)

test("a maxed card is never offered", function()
	eq(everOffered("Sharp", { Sharp = 5 }, "Hitscan"), false, "Sharp at max")
	eq(everOffered("Sharp", { Sharp = 4 }, "Hitscan"), true, "Sharp one below max")
end)

test("weapon cards follow the equipped weapon kind", function()
	eq(everOffered("Extra Orb", {}, "Hitscan"), false, "no orb card for a gun")
	eq(everOffered("Extra Orb", {}, "Orbital"), true, "orb card for orbs")
	eq(everOffered("Wide Swing", {}, "Melee"), true, "swing card for melee")
	for _, kind in { "Hitscan", "Orbital", "Beam" } do
		eq(everOffered("Wide Swing", {}, kind), false, "no swing card for " .. kind)
	end
	eq(everOffered("Long Barrel", {}, "Beam"), true, "range card for a beam")
	eq(everOffered("Double Tap", {}, "Melee"), false, "no pellet card for melee")
end)

test("fewer than three eligible cards gives a shorter offer", function()
	local stacks = {}
	for id, c in WaveRewards.Defs do
		if id ~= "Sharp" then
			stacks[id] = c.MaxStacks
		end
	end
	local offer = WaveRewards.offer(1, stacks, "Hitscan", { 0.1, 0.5, 0.9 })
	eq(#offer, 1, "one card")
	eq(offer[1], "Sharp", "the one card left")
	eq(offer[2], nil, "no nils")
	eq(#WaveRewards.offer(1, stacks, "Hitscan", { 0.99, 0.99, 0.99 }), 1, "high rolls too")
	stacks.Sharp = 5
	eq(#WaveRewards.offer(1, stacks, "Hitscan", { 0.1, 0.5, 0.9 }), 0, "nothing left")
end)

test("boss clears offer weapon and utility cards more often", function()
	local function statFirsts(wave: number): number
		local n = 0
		for _, rolls in grid(300) do
			local first = WaveRewards.offer(wave, {}, "Hitscan", rolls)[1]
			if WaveRewards.Defs[first].Kind == "Stat" then
				n += 1
			end
		end
		return n
	end
	assert(statFirsts(5) < statFirsts(1), "fewer stat cards after a boss")
	eq(statFirsts(4), statFirsts(1), "wave 4 is a normal wave")
end)

test("apply stacks boosts and reports a heal", function()
	local b = WaveRewards.newBoosts()
	for _, f in WaveRewards.Fields do
		eq(b[f], 0, f .. " starts at 0")
	end
	WaveRewards.apply(b, "Sharp")
	local _, heal = WaveRewards.apply(b, "Sharp")
	assert(math.abs(b.DamageMult - 0.30) < 1e-9, "two Sharp = +30%")
	eq(b.Stacks.Sharp, 2, "Sharp x2")
	eq(heal, false, "Sharp does not heal")
	local _, heal2 = WaveRewards.apply(b, "Second Wind")
	eq(heal2, true, "Second Wind heals")
	eq(b.Stacks["Second Wind"], 1, "Second Wind x1")
	local before = b.DamageMult
	local same, heal3 = WaveRewards.apply(b, "Nope")
	eq(same, b, "unknown card hands back the same boosts")
	eq(heal3, false, "unknown card no heal")
	eq(b.DamageMult, before, "unknown card changes nothing")
	eq(b.Stacks.Nope, nil, "unknown card not stacked")
end)

test("weaponWith copies the weapon with the boosts folded in", function()
	local orb = WaveRewards.newBoosts()
	WaveRewards.apply(orb, "Extra Orb")
	eq(WaveRewards.weaponWith(orb, Weapons.Defs.Guardian).Pellets, 3, "one more orb")
	eq(Weapons.Defs.Guardian.Pellets, 2, "catalog untouched")
	local barrel = WaveRewards.newBoosts()
	WaveRewards.apply(barrel, "Long Barrel")
	local starter = WaveRewards.weaponWith(barrel, Weapons.Defs.Starter)
	assert(math.abs(starter.Range - 92) < 1e-9, "Starter range 80 -> 92")
	eq(Weapons.Defs.Starter.Range, 80, "catalog range untouched")
	local swing = WaveRewards.newBoosts()
	WaveRewards.apply(swing, "Wide Swing")
	eq(WaveRewards.weaponWith(swing, Weapons.Defs.Starter).Spread, 0, "no spread on a gun")
	eq(WaveRewards.weaponWith(swing, Weapons.Defs.Blade).Spread, 80, "melee cone 60 -> 80")
	local copy = WaveRewards.weaponWith(WaveRewards.newBoosts(), Weapons.Defs.Blade)
	eq(copy.Id, "Blade", "copy keeps the id")
	eq(copy.Damage, Weapons.Defs.Blade.Damage, "copy keeps the damage")
end)

test("stacks line lists picks in card order", function()
	eq(WaveRewards.stacksText({}), "", "empty")
	eq(WaveRewards.stacksText({ Greed = 1, Sharp = 2 }), "Sharp x2  Greed x1", "card order")
end)

-- Stacks that leave only `keep` below MaxStacks, so an offer draws from a known small set.
local function maxedExcept(keep: { string }): { [string]: number }
	local stacks = {}
	for id, c in WaveRewards.Defs do
		if not table.find(keep, id) then
			stacks[id] = c.MaxStacks
		end
	end
	return stacks
end

test("offer walks the sorted weights exactly like Enemies.pickFromWeights", function()
	-- four cards left, sorted by name: Lucky 4, Quick Feet 8, Sharp 10, Trigger 10 (total 32,
	-- so the rolls below land on exact edges). r = roll * total, subtract each weight in
	-- sorted order, pick the first name that takes r below 0.
	local stacks = maxedExcept({ "Sharp", "Trigger", "Quick Feet", "Lucky" })
	eq(
		table.concat(WaveRewards.eligible(stacks, "Hitscan"), ","),
		"Sharp,Trigger,Quick Feet,Lucky",
		"the four left"
	)
	-- roll 0.125 -> r = 4 = Lucky's edge: r < 0 fails at Lucky, so the next name is picked;
	-- then r = 12 of {Lucky 4, Sharp 10, Trigger 10}; then r = 7 of {Lucky 4, Trigger 10}
	local offer = WaveRewards.offer(1, stacks, "Hitscan", { 0.125, 0.5, 0.5 })
	eq(table.concat(offer, ","), "Quick Feet,Sharp,Trigger", "edge walk")
	eq(
		WaveRewards.offer(1, stacks, "Hitscan", { 0, 0, 0 })[1],
		"Lucky",
		"roll 0 takes the first name"
	)
	-- a roll of 1 walks past every weight and falls back to the last sorted name
	eq(
		table.concat(WaveRewards.offer(1, stacks, "Hitscan", { 1, 1, 1 }), ","),
		"Trigger,Sharp,Quick Feet",
		"roll 1 fallback"
	)
	-- after a boss, Lucky (Utility) weighs 8: r = 0.125 * 36 = 4.5 lands inside it
	eq(WaveRewards.offer(5, stacks, "Hitscan", { 0.125, 0.5, 0.5 })[1], "Lucky", "boss weight")
end)

test("missing rolls count as 0 and still give a full offer", function()
	local stacks = maxedExcept({ "Sharp", "Trigger", "Quick Feet", "Lucky" })
	-- roll 0.5 -> r = 16: Lucky 12, Quick Feet 4, Sharp -6; the two missing rolls are 0 and
	-- take the first sorted name that is left each time
	eq(
		table.concat(WaveRewards.offer(1, stacks, "Hitscan", { 0.5 }), ","),
		"Sharp,Lucky,Quick Feet",
		"one roll"
	)
	eq(
		table.concat(WaveRewards.offer(1, stacks, "Hitscan", {}), ","),
		"Lucky,Quick Feet,Sharp",
		"no rolls"
	)
	eq(#WaveRewards.offer(1, {}, "Hitscan", {}), 3, "three cards from no rolls")
end)

test("every offered card is eligible for that run and weapon", function()
	local cases = {
		{ {}, "Hitscan" },
		{ {}, "Orbital" },
		{ { Sharp = 5, ["Extra Orb"] = 1 }, "Orbital" },
		{ { Trigger = 5, ["Wide Swing"] = 2, ["Second Wind"] = 3 }, "Melee" },
	}
	for _, case in cases do
		local stacks, kind = case[1], case[2]
		local ok = WaveRewards.eligible(stacks, kind)
		for _, rolls in grid(120) do
			for wave = 4, 5 do
				local offer = WaveRewards.offer(wave, stacks, kind, rolls)
				eq(#offer, math.min(3, #ok), "offer size for " .. kind)
				for _, id in offer do
					assert(table.find(ok, id), string.format("%s offered to %s", id, kind))
				end
			end
		end
	end
end)

test("weapon cards only count for the kind they were made for", function()
	local b = WaveRewards.newBoosts()
	WaveRewards.apply(b, "Extra Orb")
	WaveRewards.apply(b, "Extra Orb")
	WaveRewards.apply(b, "Long Barrel")
	WaveRewards.apply(b, "Wide Swing")
	eq(b.PelletsAdd, 2, "the total still adds up")
	eq(WaveRewards.weaponWith(b, Weapons.Defs.Guardian).Pellets, 4, "orbs get both orbs")
	eq(WaveRewards.weaponWith(b, Weapons.Defs.Nova).Pellets, 4, "a gun gets no orbs")
	eq(WaveRewards.weaponWith(b, Weapons.Defs.Guardian).Range, 7, "no range on orbs")
	eq(WaveRewards.weaponWith(b, Weapons.Defs.Blade).Range, 9, "no range on a blade")
	local ion = WaveRewards.weaponWith(b, Weapons.Defs.Ion)
	assert(math.abs(ion.Range - 80.5) < 1e-9, "beam range 70 -> 80.5")
	eq(WaveRewards.weaponWith(b, Weapons.Defs.Blade).Spread, 80, "melee cone 60 -> 80")
	local tap = WaveRewards.newBoosts()
	WaveRewards.apply(tap, "Double Tap")
	eq(WaveRewards.weaponWith(tap, Weapons.Defs.Starter).Pellets, 2, "pistol +1 pellet")
	eq(WaveRewards.weaponWith(tap, Weapons.Defs.Guardian).Pellets, 2, "orbs unchanged")
end)
