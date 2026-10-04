local Goals = load("Goals")
local ProfileSchema = load("ProfileSchema")
local Evolutions = load("Evolutions")

test("fresh profile: the first goal is Max HP Lv 1", function()
	local g = Goals.next(ProfileSchema.default())
	assert(g, "a fresh profile has a goal")
	eq(g.Kind, "Perk", "kind")
	eq(g.Key, "MaxHealth", "key")
	eq(g.Need, 5, "need")
	eq(g.Have, 0, "have")
	assert(g.Label:find("Max HP Lv 1", 1, true), g.Label)
end)

test("perks follow their display order once one is maxed", function()
	local p = ProfileSchema.default()
	p.Gold = 100
	p.Gems = 4
	local g = Goals.next(p)
	eq(g.Key, "MaxHealth", "one Gem short is still the closest")
	eq(g.Have, 4, "have")
	eq(g.Need, 5, "need")

	local q = ProfileSchema.default()
	q.Perks.MaxHealth = 10
	local g2 = Goals.next(q)
	eq(g2.Kind, "Perk", "kind")
	eq(g2.Key, "DamagePercent", "next perk in order")
	eq(g2.Need, 5, "need")
end)

test("perk goals require both currencies and show the scarcer one", function()
	local p = ProfileSchema.default()
	p.Gems = 5
	p.Gold = 40
	local g = Goals.next(p)
	eq(g.Kind, "Perk", "kind")
	eq(g.Key, "MaxHealth", "key")
	eq(g.Have, 40, "Gold in hand")
	eq(g.Need, 100, "Gold cost")
	assert((g.Need - g.Have) / g.Need > 0, "an unfunded perk has a positive gap")
	assert(g.Label:find("need 60 Gold", 1, true), g.Label)
	local canBuy = ProfileSchema.canBuyPerk(p, g.Key)
	eq(canBuy, false, "the goal is not presented as funded when purchase rejects it")

	p.Gold = 100
	local funded = Goals.next(p)
	assert(funded.Have >= funded.Need, "a buyable perk is presented as funded")
	eq(ProfileSchema.canBuyPerk(p, funded.Key), true, "funded goal can be purchased")
end)

test("all perks maxed: the equipped weapon's next tier; shards in hand break ties", function()
	local p = ProfileSchema.default()
	p.Gems = 1000
	p.Equipped = "Starter"
	p.Shards.Dark = 1
	for key, def in ProfileSchema.PerkDefs do
		p.Perks[key] = def.MaxLevel
	end
	local g = Goals.next(p)
	eq(g.Kind, "Evolution", "kind")
	eq(g.Need, 120, "tier 1 cost")
	eq(g.Have, 1000, "have")
	assert(g.Label:find("tier 1", 1, true), g.Label)
	eq(g.Key, "Dark", "the element whose shard is already in hand")
	eq(g.Label:find("need", 1, true), nil, "no shard note when shards are in hand")
end)

test("no shards yet: the label says how many and where they come from", function()
	local p = ProfileSchema.default()
	p.Gems = 1000
	for key, def in ProfileSchema.PerkDefs do
		p.Perks[key] = def.MaxLevel
	end
	local g = Goals.next(p)
	eq(g.Kind, "Evolution", "kind")
	assert(g.Label:find("need 1 more", 1, true), g.Label)
	assert(g.Label:find(Goals.ShardSource[g.Key], 1, true), g.Label)
	-- a weapon already on a path only chases that path
	p.Evolutions.Starter = { Element = "Lightning", Tier = 1 }
	local g2 = Goals.next(p)
	eq(g2.Key, "Lightning", "locked to the weapon's path")
	eq(g2.Need, 320, "tier 2 cost")
	assert(g2.Label:find("Sky King", 1, true), g2.Label)
end)

test("everything unlocked returns nil; every element has a shard source", function()
	local p = ProfileSchema.default()
	for key, def in ProfileSchema.PerkDefs do
		p.Perks[key] = def.MaxLevel
	end
	p.Evolutions.Starter = { Element = "Tech", Tier = 3 }
	eq(Goals.next(p), nil, "nothing left to chase")
	for _, el in Evolutions.Order do
		assert(type(Goals.ShardSource[el]) == "string", el .. " shard source")
	end
end)
