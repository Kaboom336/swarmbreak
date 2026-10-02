--!strict
-- Wave rewards: on every wave clear each player picks 1 of 3 cards. Pure data + math (no
-- Roblox globals) so tests can load it. A pick adds to a Boosts record that PlayerData folds
-- into its existing multipliers and stats, so Combat never has to read this module.
local Config = require(script.Parent.Config)
local Weapons = require(script.Parent.Weapons)

export type CardKind = "Stat" | "Weapon" | "Utility"
export type Card = {
	Id: string,
	Label: string,
	Blurb: string,
	Kind: CardKind,
	Weight: number, -- offer odds relative to the other eligible cards
	MaxStacks: number, -- how many times one run can pick it
	Kinds: { string }?, -- weapon kinds it is offered for (nil = any weapon)
	Apply: { [string]: number | boolean }, -- Boosts field -> amount added; HealNow = true heals
}

-- What a run has picked so far. Every number starts at 0 and only grows.
export type Boosts = {
	DamageMult: number, -- 0.15 = +15% damage
	FireRateMult: number, -- 0.10 = +10% fire rate
	Speed: number, -- walk speed added
	MaxHealth: number, -- max HP added
	CoinMult: number, -- 0.20 = +20% coins
	DashCooldown: number, -- 0.20 = dash cooldown -20%
	-- The three weapon totals below count every weapon card picked; weaponWith reads Stacks
	-- instead so a card only reaches the weapon kinds it was made for.
	RangeMult: number, -- 0.15 = +15% range
	SpreadAdd: number, -- degrees added to a melee cone
	PelletsAdd: number, -- pellets per shot (Hitscan) / orbs (Orbital) added
	GemMult: number, -- 0.10 = +10% Gems at run end
	Stacks: { [string]: number }, -- card id -> times picked this run
}

local WaveRewards = {}

WaveRewards.Fields = {
	"DamageMult",
	"FireRateMult",
	"Speed",
	"MaxHealth",
	"CoinMult",
	"DashCooldown",
	"RangeMult",
	"SpreadAdd",
	"PelletsAdd",
	"GemMult",
}
WaveRewards.OfferSize = 3
WaveRewards.BossWeightMult = 2 -- Weapon and Utility cards weigh this much more after a boss

local function card(fields: Card): Card
	return fields
end

WaveRewards.Defs = {
	Sharp = card({
		Id = "Sharp",
		Label = "Sharp",
		Blurb = "+15% damage",
		Kind = "Stat",
		Weight = 10,
		MaxStacks = 5,
		Apply = { DamageMult = 0.15 },
	}),
	Trigger = card({
		Id = "Trigger",
		Label = "Trigger",
		Blurb = "+10% fire rate",
		Kind = "Stat",
		Weight = 10,
		MaxStacks = 5,
		Apply = { FireRateMult = 0.10 },
	}),
	["Quick Feet"] = card({
		Id = "Quick Feet",
		Label = "Quick Feet",
		Blurb = "+2 speed",
		Kind = "Stat",
		Weight = 8,
		MaxStacks = 3,
		Apply = { Speed = 2 },
	}),
	["Thick Skin"] = card({
		Id = "Thick Skin",
		Label = "Thick Skin",
		Blurb = "+25 max HP",
		Kind = "Stat",
		Weight = 8,
		MaxStacks = 4,
		Apply = { MaxHealth = 25 },
	}),
	Greed = card({
		Id = "Greed",
		Label = "Greed",
		Blurb = "+20% coins this run",
		Kind = "Utility",
		Weight = 6,
		MaxStacks = 3,
		Apply = { CoinMult = 0.20 },
	}),
	Lucky = card({
		Id = "Lucky",
		Label = "Lucky",
		Blurb = "+10% Gems at run end",
		Kind = "Utility",
		Weight = 4,
		MaxStacks = 2,
		Apply = { GemMult = 0.10 },
	}),
	["Second Wind"] = card({
		Id = "Second Wind",
		Label = "Second Wind",
		Blurb = "Heal to full now",
		Kind = "Utility",
		Weight = 6,
		MaxStacks = 99,
		Apply = { HealNow = true },
	}),
	["Fast Dash"] = card({
		Id = "Fast Dash",
		Label = "Fast Dash",
		Blurb = "Dash cooldown -20%",
		Kind = "Utility",
		Weight = 5,
		MaxStacks = 2,
		Apply = { DashCooldown = 0.20 },
	}),
	Magnet = card({
		Id = "Magnet",
		Label = "Magnet",
		Blurb = "+4 pickup radius",
		Kind = "Utility",
		Weight = 6,
		MaxStacks = 3,
		Apply = {},
	}),
	["Long Barrel"] = card({
		Id = "Long Barrel",
		Label = "Long Barrel",
		Blurb = "+15% range",
		Kind = "Weapon",
		Kinds = { "Hitscan", "Beam" },
		Weight = 6,
		MaxStacks = 3,
		Apply = { RangeMult = 0.15 },
	}),
	["Double Tap"] = card({
		Id = "Double Tap",
		Label = "Double Tap",
		Blurb = "+1 pellet per shot",
		Kind = "Weapon",
		Kinds = { "Hitscan" },
		Weight = 4,
		MaxStacks = 2,
		Apply = { PelletsAdd = 1 },
	}),
	["Wide Swing"] = card({
		Id = "Wide Swing",
		Label = "Wide Swing",
		Blurb = "+20 degrees swing",
		Kind = "Weapon",
		Kinds = { "Melee" },
		Weight = 6,
		MaxStacks = 2,
		Apply = { SpreadAdd = 20 },
	}),
	["Extra Orb"] = card({
		Id = "Extra Orb",
		Label = "Extra Orb",
		Blurb = "+1 orb",
		Kind = "Weapon",
		Kinds = { "Orbital" },
		Weight = 6,
		MaxStacks = 2,
		Apply = { PelletsAdd = 1 },
	}),
} :: { [string]: Card }

-- Deterministic id list: the HUD's boosts line and the tests walk the cards in this order.
WaveRewards.Order = {
	"Sharp",
	"Trigger",
	"Quick Feet",
	"Thick Skin",
	"Greed",
	"Lucky",
	"Second Wind",
	"Fast Dash",
	"Magnet",
	"Long Barrel",
	"Double Tap",
	"Wide Swing",
	"Extra Orb",
}

function WaveRewards.newBoosts(): Boosts
	return {
		DamageMult = 0,
		FireRateMult = 0,
		Speed = 0,
		MaxHealth = 0,
		CoinMult = 0,
		DashCooldown = 0,
		RangeMult = 0,
		SpreadAdd = 0,
		PelletsAdd = 0,
		GemMult = 0,
		Stacks = {},
	}
end

-- Ids (in Order) a run can still be offered: not at MaxStacks, and made for the equipped weapon.
function WaveRewards.eligible(stacks: { [string]: number }, equippedKind: string): { string }
	local out = {}
	for _, id in WaveRewards.Order do
		local c = WaveRewards.Defs[id]
		local fitsWeapon = c.Kinds == nil or table.find(c.Kinds :: { string }, equippedKind) ~= nil
		if (stacks[id] or 0) < c.MaxStacks and fitsWeapon then
			table.insert(out, id)
		end
	end
	return out
end

-- The same walk as Enemies.pickFromWeights: sorted names, r = roll * total, subtract until < 0.
local function pickFromWeights(weights: { [string]: number }, roll01: number): string
	local names = {}
	for name in weights do
		table.insert(names, name)
	end
	table.sort(names)
	local total = 0
	for _, name in names do
		total += weights[name]
	end
	local r = roll01 * total
	for _, name in names do
		r -= weights[name]
		if r < 0 then
			return name
		end
	end
	return names[#names]
end

-- The cards offered after clearing `wave`: up to OfferSize distinct ids drawn without
-- replacement from the eligible cards, weighted by Weight (Weapon and Utility cards weigh
-- BossWeightMult times more after a boss wave). rolls holds one number in [0, 1) per pick;
-- the same rolls always give the same offer. Never returns nils or duplicates.
function WaveRewards.offer(
	wave: number,
	stacks: { [string]: number },
	equippedKind: string,
	rolls: { number }
): { string }
	local bossClear = wave > 0 and wave % Config.BossEvery == 0
	local weights: { [string]: number } = {}
	for _, id in WaveRewards.eligible(stacks, equippedKind) do
		local c = WaveRewards.Defs[id]
		weights[id] = if bossClear and c.Kind ~= "Stat"
			then c.Weight * WaveRewards.BossWeightMult
			else c.Weight
	end
	local picks = {}
	for i = 1, WaveRewards.OfferSize do
		if next(weights) == nil then
			break
		end
		local id = pickFromWeights(weights, rolls[i] or 0)
		table.insert(picks, id)
		weights[id] = nil
	end
	return picks
end

-- Take a card: every numeric Apply value is added to its Boosts field and the card's stack
-- count goes up by one. Changes boosts in place and returns it, plus true when the card heals
-- right now (Second Wind). An unknown id changes nothing and returns false.
function WaveRewards.apply(boosts: Boosts, id: string): (Boosts, boolean)
	local c = WaveRewards.Defs[id]
	if not c then
		return boosts, false
	end
	local fields = boosts :: any
	local healNow = false
	for key, value in c.Apply do
		if type(value) == "number" and type(fields[key]) == "number" then
			fields[key] += value
		elseif key == "HealNow" and value == true then
			healNow = true
		end
	end
	boosts.Stacks[id] = (boosts.Stacks[id] or 0) + 1
	return boosts, healNow
end

local function num(v: (number | boolean)?): number
	return if type(v) == "number" then v else 0
end

-- A copy of the weapon with the run's boosts folded in: range, pellets/orbs, and (melee only)
-- the swing cone. Only cards made for this weapon's kind count (their Kinds list), so an
-- Extra Orb picked with orbs out never adds a pellet to a gun equipped later, and a Long
-- Barrel never reaches a blade. The catalog entry is never changed.
function WaveRewards.weaponWith(boosts: Boosts, weapon: Weapons.WeaponDef): Weapons.WeaponDef
	local rangeMult, pelletsAdd, spreadAdd = 0, 0, 0
	for _, id in WaveRewards.Order do
		local n = boosts.Stacks[id] or 0
		local c = WaveRewards.Defs[id]
		if n > 0 and c.Kinds and table.find(c.Kinds :: { string }, weapon.Kind) then
			rangeMult += n * num(c.Apply.RangeMult)
			pelletsAdd += n * num(c.Apply.PelletsAdd)
			spreadAdd += n * num(c.Apply.SpreadAdd)
		end
	end
	local w = table.clone(weapon)
	w.Range = weapon.Range * (1 + rangeMult)
	w.Pellets = weapon.Pellets + pelletsAdd
	if weapon.Kind == "Melee" then
		w.Spread = weapon.Spread + spreadAdd
	end
	return w
end

-- The HUD's boosts line: "Sharp x2  Greed x1" in card order, or "" when nothing was picked.
function WaveRewards.stacksText(stacks: { [string]: number }): string
	local parts = {}
	for _, id in WaveRewards.Order do
		local n = stacks[id] or 0
		if n > 0 then
			table.insert(parts, string.format("%s x%d", WaveRewards.Defs[id].Label, n))
		end
	end
	return table.concat(parts, "  ")
end

return WaveRewards
