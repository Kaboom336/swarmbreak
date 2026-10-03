local Evolutions = load("Evolutions")
local LevelUp = load("LevelUp")
local WaveRewards = load("WaveRewards")
local Weapons = load("Weapons")

local function hasCard(offer, id: string): boolean
	for _, card in offer do
		if card.Id == id then
			return true
		end
	end
	return false
end

test("four elements, three tiers each, rising costs", function()
	for _, name in Evolutions.Order do
		local e = Evolutions.Elements[name]
		assert(e, name)
		eq(#e.Tiers, 3, name .. " tiers")
		eq(#e.Color, 3, name .. " color")
		local prev = 0
		for i, t in e.Tiers do
			eq(t.Tier, i, name .. " tier index")
			assert(t.GemsCost > prev, name .. " cost rises")
			prev = t.GemsCost
			assert(t.DamageMult >= 0 and t.FireRateMult >= 0, name .. " non-negative")
			if t.Effect then
				assert(Evolutions.Effects[t.Effect], name .. " unknown effect " .. t.Effect)
			end
		end
		assert(e.Tiers[2].Effect, name .. " tier 2 has an effect")
	end
end)

test("multipliers and effects accumulate by tier", function()
	local d0, r0 = Evolutions.multipliers(nil)
	eq(d0, 1, "no evo dmg")
	eq(r0, 1, "no evo rate")
	local d3 = Evolutions.multipliers({ Element = "Tech", Tier = 3 })
	assert(math.abs(d3 - 1.35) < 1e-9, "circuit t3 dmg")
	eq(#Evolutions.effects({ Element = "Lightning", Tier = 1 }), 0, "tier 1 no effect")
	eq(#Evolutions.effects({ Element = "Lightning", Tier = 2 }), 1, "tier 2 one effect")
	eq(#Evolutions.effects({ Element = "Lightning", Tier = 3 }), 2, "tier 3 two effects")
	eq(#Evolutions.effects({ Element = "Tech", Tier = 3 }), 1, "circuit repeats Arc once")
	eq(#Evolutions.effects({ Element = "Nope", Tier = 3 }), 0, "unknown element")
end)

test("canBuy enforces one path, costs and top tier", function()
	local ok, why = Evolutions.canBuy(nil, "Dark", 0, 0)
	eq(ok, false, "poor")
	assert(why:find("Gems"), why)
	ok = Evolutions.canBuy(nil, "Dark", 120, 1)
	eq(ok, true, "tier 1 affordable")
	ok, why = Evolutions.canBuy({ Element = "Dark", Tier = 1 }, "Lightning", 9999, 99)
	eq(ok, false, "locked to path")
	assert(why:find("Dark"), why)
	ok, why = Evolutions.canBuy({ Element = "Dark", Tier = 3 }, "Dark", 9999, 99)
	eq(ok, false, "top tier")
	assert(why:find("top"), why)
	ok, why = Evolutions.canBuy({ Element = "Dark", Tier = 1 }, "Dark", 320, 1)
	eq(ok, false, "shards short")
	assert(why:find("shards"), why)
end)

test("boss shards map to real elements; gems grow with waves", function()
	for boss, el in Evolutions.BossShards do
		assert(Evolutions.Elements[el], boss .. " -> " .. el)
	end
	assert(Evolutions.gemsForRun(15, true) > Evolutions.gemsForRun(15, false), "win bonus")
	assert(
		Evolutions.gemsForRun(10, false) > Evolutions.gemsForRun(5, false),
		"more waves more gems"
	)
	eq(Evolutions.gemsForRun(0, false), 0, "zero")
end)

test("first runs pay a flat Gems bonus; wave 0 never does", function()
	eq(Evolutions.gemsForRun(5, false, 0), 76, "first run: 36 + 40")
	eq(Evolutions.gemsForRun(5, false, 2), 76, "third run still gets the bonus")
	eq(Evolutions.gemsForRun(5, false, 3), 36, "fourth run: no bonus")
	eq(Evolutions.gemsForRun(5, false), 36, "no run count, no bonus")
	eq(Evolutions.gemsForRun(0, false, 0), 0, "wave 0 pays nothing")
end)

test("EVOLVE is offered only for a max weapon card with its passive", function()
	local recipe = Evolutions.Recipes[1]
	local maxed = { [recipe.Weapon] = recipe.MaxLevel }
	local ready = { [recipe.Weapon] = recipe.MaxLevel, [recipe.Passive] = 1 }
	local rolls = { 0.1, 0.5, 0.9 }
	local rarities = { 0.1, 0.5, 0.9 }

	local weaponOnly = LevelUp.offer(6, maxed, recipe.Kind, rolls, rarities)
	assert(not hasCard(weaponOnly, Evolutions.CardId), "passive is required")
	local passiveOnly = LevelUp.offer(6, { [recipe.Passive] = 1 }, recipe.Kind, rolls, rarities)
	assert(not hasCard(passiveOnly, Evolutions.CardId), "max weapon card is required")
	local offered = LevelUp.offer(6, ready, recipe.Kind, rolls, rarities)
	eq(offered[1].Id, Evolutions.CardId, "ready recipe is the next offer")
	eq(offered[1].Evolution, recipe.Id, "offer identifies the recipe")
end)

test("every run recipe uses real weapon and passive cards", function()
	for _, recipe in Evolutions.Recipes do
		local weapon = WaveRewards.Defs[recipe.Weapon]
		local passive = WaveRewards.Defs[recipe.Passive]
		assert(weapon and weapon.Kind == "Weapon", recipe.Id .. " weapon card")
		assert(passive and passive.Kind == "Utility", recipe.Id .. " passive card")
		eq(recipe.MaxLevel, weapon.MaxStacks, recipe.Id .. " max card level")
		assert(Evolutions.Elements[recipe.Element], recipe.Id .. " shop stats")
	end
end)

test("EVOLVE is offered only once", function()
	local recipe = Evolutions.Recipes[1]
	local ready = { [recipe.Weapon] = recipe.MaxLevel, [recipe.Passive] = 1 }
	local offered = LevelUp.offer(6, ready, recipe.Kind, { 0.1, 0.5, 0.9 }, { 0.1, 0.5, 0.9 })
	eq(offered[1].Id, Evolutions.CardId, "first offer evolves")
	local afterPick = LevelUp.offer(
		7,
		ready,
		recipe.Kind,
		{ 0.1, 0.5, 0.9 },
		{ 0.1, 0.5, 0.9 },
		nil,
		nil,
		recipe.Id
	)
	assert(not hasCard(afterPick, Evolutions.CardId), "picked evolution never returns")
end)

test("picking EVOLVE swaps to the shop evolution stats", function()
	local recipe = Evolutions.Recipes[1]
	local original = Weapons.Defs.Starter
	local originalDamage = original.Damage
	local evolved, evolution = Evolutions.pickInRun(original, recipe.Id)
	local damageMult, rateMult = Evolutions.multipliers(evolution)
	eq(evolved.Id, original.Id, "equipped weapon identity stays")
	assert(math.abs(evolved.Damage - original.Damage * damageMult) < 1e-9, "damage swaps")
	assert(math.abs(evolved.FireRate - original.FireRate * rateMult) < 1e-9, "rate swaps")
	eq(original.Damage, originalDamage, "catalog stays pure")
end)
