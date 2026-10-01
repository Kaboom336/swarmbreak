local Goals = load("Goals")
local ProfileSchema = load("ProfileSchema")
local Evolutions = load("Evolutions")

test("fresh profile: the first goal is Start coins Lv 1 at 80 Gems", function()
	local g = Goals.next(ProfileSchema.default())
	assert(g, "a fresh profile has a goal")
	eq(g.Kind, "Perk", "kind")
	eq(g.Key, "StartCoins", "key")
	eq(g.Need, 80, "need")
	eq(g.Have, 0, "have")
	assert(g.Label:find("Start coins Lv 1", 1, true), g.Label)
end)

test("smallest Gems gap wins; perks follow their order once one is maxed", function()
	local p = ProfileSchema.default()
	p.Gems = 79
	local g = Goals.next(p)
	eq(g.Key, "StartCoins", "one Gem short is still the closest")
	eq(g.Have, 79, "have")
	eq(g.Need, 80, "need")

	-- Gems 0 and Start coins maxed: a tier-1 evolution (120) is closer than Max HP (200)
	local q = ProfileSchema.default()
	q.Perks.StartCoins = 5
	local g2 = Goals.next(q)
	eq(g2.Kind, "Evolution", "cheapest unlock wins")
	eq(g2.Need, 120, "tier 1 cost")

	-- with the weapon already at the top tier, only perks remain: Max HP is next in order
	q.Evolutions.Starter = { Element = "Tech", Tier = 3 }
	local g3 = Goals.next(q)
	eq(g3.Kind, "Perk", "kind")
	eq(g3.Key, "MaxHealth", "next perk in order")
	eq(g3.Need, 200, "need")
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
