--!strict
-- Weapon evolution trees: four Evolution elements, three tiers each. Pure data + math (tested).
-- A weapon takes ONE element path. Tier bonuses stack additively within the path.
export type Element = "Nature" | "Tech" | "Lightning" | "Dark"
export type TierDef = {
	Tier: number,
	GemsCost: number,
	ShardsCost: number,
	DamageMult: number, -- multiplier added to 1.0 (0.1 = +10%)
	FireRateMult: number,
	Effect: string?, -- effect key the server applies (see EFFECTS)
	Label: string,
}
export type ElementDef = {
	Name: Element,
	Blurb: string,
	Color: { number }, -- 0..255
	Tiers: { TierDef },
}

local Evolutions = {}

Evolutions.Order = { "Nature", "Tech", "Lightning", "Dark" } :: { Element }

-- Effect keys, applied by the server in Combat / PlayerData:
--   HealOnKill  : heal the wielder 4% max HP per kill
--   Slow        : enemies hit move 30% slower for 2 s
--   Arc         : each hit also damages one other enemy within 12 studs for 40%
--   Chain       : lightning jumps to up to 3 enemies for 30% each
--   Haste       : +15% walk speed while this weapon is equipped
--   Lifesteal   : heal 8% of damage dealt
--   Pull        : kills pull enemies within 14 studs toward the kill spot
Evolutions.Effects = {
	HealOnKill = { Label = "Heal on kill", Value = 0.04 },
	Slow = { Label = "Poison: slows enemies", Value = 0.3 },
	Arc = { Label = "Hits bounce to a second enemy", Value = 0.4 },
	Chain = { Label = "Chain lightning", Value = 0.3 },
	Haste = { Label = "Faster movement", Value = 0.15 },
	Lifesteal = { Label = "Lifesteal (heal on hit)", Value = 0.08 },
	Pull = { Label = "Kills pull enemies together", Value = 14 },
}

local function tiers(
	t1: string,
	e2: string,
	e3: string,
	dmg: { number },
	rate: { number }
): { TierDef }
	return {
		{
			Tier = 1,
			GemsCost = 120,
			ShardsCost = 1,
			DamageMult = dmg[1],
			FireRateMult = rate[1],
			Effect = nil,
			Label = t1,
		},
		{
			Tier = 2,
			GemsCost = 320,
			ShardsCost = 2,
			DamageMult = dmg[2],
			FireRateMult = rate[2],
			Effect = e2,
			Label = Evolutions.Effects[e2].Label,
		},
		{
			Tier = 3,
			GemsCost = 800,
			ShardsCost = 4,
			DamageMult = dmg[3],
			FireRateMult = rate[3],
			Effect = e3,
			Label = Evolutions.Effects[e3].Label,
		},
	}
end

Evolutions.Elements = {
	Nature = {
		Name = "Nature",
		Blurb = "Nature. Heal on kills, poison that slows.",
		Color = { 90, 220, 110 },
		Tiers = tiers("Nature glow", "HealOnKill", "Slow", { 0.05, 0.10, 0.18 }, { 0, 0, 0.05 }),
	},
	Tech = {
		Name = "Tech",
		Blurb = "Tech. Raw damage and bouncing hits.",
		Color = { 60, 220, 255 },
		Tiers = tiers("Tech glow", "Arc", "Arc", { 0.10, 0.20, 0.35 }, { 0.05, 0.10, 0.15 }),
	},
	Lightning = {
		Name = "Lightning",
		Blurb = "Lightning. Chains between enemies, faster feet.",
		Color = { 200, 230, 255 },
		Tiers = tiers(
			"Lightning glow",
			"Chain",
			"Haste",
			{ 0.05, 0.12, 0.20 },
			{ 0.05, 0.10, 0.20 }
		),
	},
	Dark = {
		Name = "Dark",
		Blurb = "Dark. Lifesteal and kills that pull enemies together.",
		Color = { 150, 60, 220 },
		Tiers = tiers("Dark glow", "Lifesteal", "Pull", { 0.08, 0.16, 0.30 }, { 0, 0.05, 0.10 }),
	},
} :: { [string]: ElementDef }

-- Which element a boss drops shards of.
Evolutions.BossShards = { Brute = "Dark", Queen = "Nature", Warden = "Lightning" }
-- Tech shards come from wave clears: one every N waves.
Evolutions.TechShardEveryWaves = 5

export type WeaponEvo = { Element: Element, Tier: number }
export type Recipe = {
	Id: string,
	Weapon: string,
	Passive: string,
	Kind: string,
	MaxLevel: number,
	Evolved: string,
	Icon: string,
	Element: Element,
}

Evolutions.CardId = "EVOLVE"
Evolutions.RecipeFlagPrefix = "Recipe_"

-- Run recipes pair V2's weapon cards with passive cards. Their Element selects the existing
-- shop evolution's top-tier multipliers and effects; no second stats catalog can drift.
Evolutions.Recipes = {
	{
		Id = "Railstorm",
		Weapon = "Long Barrel",
		Passive = "Magnet",
		Kind = "Beam",
		MaxLevel = 3,
		Evolved = "Railstorm",
		Icon = "RLS",
		Element = "Tech",
	},
	{
		Id = "Thunderburst",
		Weapon = "Double Tap",
		Passive = "Fast Dash",
		Kind = "Hitscan",
		MaxLevel = 2,
		Evolved = "Thunderburst",
		Icon = "THN",
		Element = "Lightning",
	},
	{
		Id = "Soul Reaper",
		Weapon = "Wide Swing",
		Passive = "Second Wind",
		Kind = "Melee",
		MaxLevel = 2,
		Evolved = "Soul Reaper",
		Icon = "RPR",
		Element = "Dark",
	},
	{
		Id = "Verdant Halo",
		Weapon = "Extra Orb",
		Passive = "Lucky",
		Kind = "Orbital",
		MaxLevel = 2,
		Evolved = "Verdant Halo",
		Icon = "HAL",
		Element = "Nature",
	},
} :: { Recipe }

function Evolutions.recipe(id: string): Recipe?
	for _, recipe in Evolutions.Recipes do
		if recipe.Id == id then
			return recipe
		end
	end
	return nil
end

function Evolutions.recipeForWeaponCard(cardId: string, equippedKind: string): Recipe?
	for _, recipe in Evolutions.Recipes do
		if recipe.Weapon == cardId and recipe.Kind == equippedKind then
			return recipe
		end
	end
	return nil
end

function Evolutions.readyRecipe(
	stacks: { [string]: number },
	equippedKind: string,
	evolvedRecipe: string?
): Recipe?
	if evolvedRecipe then
		return nil
	end
	for _, recipe in Evolutions.Recipes do
		if
			recipe.Kind == equippedKind
			and (stacks[recipe.Weapon] or 0) >= recipe.MaxLevel
			and (stacks[recipe.Passive] or 0) > 0
		then
			return recipe
		end
	end
	return nil
end

function Evolutions.completesRecipe(
	cardId: string,
	stacks: { [string]: number },
	equippedKind: string
): boolean
	for _, recipe in Evolutions.Recipes do
		if recipe.Kind == equippedKind then
			if
				cardId == recipe.Weapon
				and (stacks[recipe.Weapon] or 0) + 1 >= recipe.MaxLevel
				and (stacks[recipe.Passive] or 0) > 0
			then
				return true
			elseif
				cardId == recipe.Passive
				and (stacks[recipe.Weapon] or 0) >= recipe.MaxLevel
				and (stacks[recipe.Passive] or 0) == 0
			then
				return true
			end
		end
	end
	return false
end

-- Pure preview used by specs and UI: picking a recipe swaps numeric combat stats to the
-- matching shop evolution's tier-3 values without mutating the weapon catalog.
function Evolutions.pickInRun(weapon: any, recipeId: string): (any, WeaponEvo?)
	local recipe = Evolutions.recipe(recipeId)
	if not recipe then
		return table.clone(weapon), nil
	end
	local evolution: WeaponEvo = { Element = recipe.Element, Tier = 3 }
	local damageMult, rateMult = Evolutions.multipliers(evolution)
	local evolved = table.clone(weapon)
	evolved.Name = recipe.Evolved
	evolved.Rarity = "Legendary"
	evolved.Damage = weapon.Damage * damageMult
	evolved.FireRate = weapon.FireRate * rateMult
	return evolved, evolution
end

function Evolutions.tierDef(element: string, tier: number): TierDef?
	local e = Evolutions.Elements[element]
	if not e then
		return nil
	end
	return e.Tiers[tier]
end

-- Total multipliers for a weapon at (element, tier). Tier 0 = none.
function Evolutions.multipliers(evo: WeaponEvo?): (number, number)
	if not evo or evo.Tier <= 0 then
		return 1, 1
	end
	local t = Evolutions.tierDef(evo.Element, evo.Tier)
	if not t then
		return 1, 1
	end
	return 1 + t.DamageMult, 1 + t.FireRateMult
end

-- Active effect keys at (element, tier): every effect from tier 2 up to the current tier.
function Evolutions.effects(evo: WeaponEvo?): { string }
	local out = {}
	if not evo then
		return out
	end
	local e = Evolutions.Elements[evo.Element]
	if not e then
		return out
	end
	for i = 1, math.min(evo.Tier, #e.Tiers) do
		local eff = e.Tiers[i].Effect
		if eff and not table.find(out, eff) then
			table.insert(out, eff)
		end
	end
	return out
end

-- Can the player buy the next tier? Returns ok, reason, cost table.
function Evolutions.canBuy(
	current: WeaponEvo?,
	element: string,
	gems: number,
	shards: number
): (boolean, string, TierDef?)
	if current and current.Tier > 0 and current.Element ~= element then
		return false, "This weapon already follows " .. current.Element .. ".", nil
	end
	local nextTier = (if current then current.Tier else 0) + 1
	local t = Evolutions.tierDef(element, nextTier)
	if not t then
		return false, "Already at the top tier.", nil
	end
	if gems < t.GemsCost then
		return false, string.format("Need %d Gems.", t.GemsCost), t
	end
	if shards < t.ShardsCost then
		return false, string.format("Need %d %s shards.", t.ShardsCost, element), t
	end
	return true, "", t
end

-- A flat Gems bonus on each of a player's first few runs, so one lobby perk is in reach
-- after run one or two (placeholder numbers).
Evolutions.FirstRunsBonus = 40
Evolutions.FirstRunsCount = 3

-- Gems earned at the end of a run from the wave reached. `runsBefore` is how many runs the
-- player had finished before this one; when given and small, the first-runs bonus applies.
-- Wave 0 (fell before the first wave) always pays nothing.
function Evolutions.gemsForRun(waveReached: number, won: boolean, runsBefore: number?): number
	if waveReached <= 0 then
		return 0
	end
	local base = 6 * waveReached + math.floor(waveReached * waveReached / 4)
	if won then
		base += 100
	end
	if runsBefore ~= nil and runsBefore < Evolutions.FirstRunsCount then
		base += Evolutions.FirstRunsBonus
	end
	return base
end

return Evolutions
