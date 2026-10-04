--!strict
-- The cheapest next forever-unlock for a profile: a lobby perk level or a weapon evolution
-- tier. Pure + tested. The server sends one in the run summary; the client draws it as a
-- progress bar and recomputes it from its stats snapshot while the summary panel is open.
local ProfileSchema = require(script.Parent.ProfileSchema)
local Evolutions = require(script.Parent.Evolutions)

export type Goal = {
	Label: string,
	Have: number, -- amount held of the currency currently blocking this unlock
	Need: number, -- cost in that currency
	Kind: "Perk" | "Evolution",
	Key: string, -- perk key, or the element for an evolution
}

local Goals = {}

-- Perks are considered in this order; ties in funding gap go to the earlier one.
Goals.PerkOrder = {
	"MaxHealth",
	"DamagePercent",
	"MoveSpeedPercent",
	"DashCharges",
	"GoldFindPercent",
	"GemFindPercent",
}

-- Where each element's shards come from, in plain words, for the goal label.
Goals.ShardSource = {
	Dark = "Big Brute (wave 5)",
	Nature = "Swarm Queen (wave 10)",
	Lightning = "Sky King (wave 15)",
	Tech = "every 5th wave clear",
}

type Candidate = { Goal: Goal, Gap: number, ShardsShort: boolean }

-- Picks the candidate with the smallest fractional gap (0 = affordable, 1 = nothing saved). On an equal gap, one whose shards are
-- already in hand beats one that still needs a boss drop; after that, the earlier candidate.
local function better(a: Candidate, b: Candidate?): boolean
	if not b then
		return true
	end
	if a.Gap ~= b.Gap then
		return a.Gap < b.Gap
	end
	return b.ShardsShort and not a.ShardsShort
end

function Goals.next(p: ProfileSchema.Profile): Goal?
	local gems = p.Gems or 0
	local best: Candidate? = nil
	local function consider(goal: Goal, shardsShort: boolean, gap: number?)
		local c = {
			Goal = goal,
			-- Every candidate uses the same unit: the fraction of its cost still missing.
			Gap = gap
				or (if goal.Need > 0 then math.max(0, goal.Need - goal.Have) / goal.Need else 0),
			ShardsShort = shardsShort,
		}
		if better(c, best) then
			best = c
		end
	end

	-- (a) lobby perks
	for _, key in Goals.PerkOrder do
		local cost = ProfileSchema.perkCost(p, key)
		local def = ProfileSchema.PerkDefs[key]
		if cost and def then
			local lvl = ProfileSchema.perkLevel(p, key)
			local goldGap = math.max(0, (cost.Gold - p.Gold) / cost.Gold)
			local gemsGap = math.max(0, (cost.Gems - gems) / cost.Gems)
			local useGold = goldGap > gemsGap
			local have = if useGold then p.Gold else gems
			local need = if useGold then cost.Gold else cost.Gems
			local currency = if useGold then "Gold" else "Gems"
			local label = string.format("%s Lv %d", def.Label, lvl + 1)
			local gap = math.max(goldGap, gemsGap)
			if gap > 0 then
				label ..= string.format(": need %d %s", need - have, currency)
			end
			consider({
				Label = label,
				Have = have,
				Need = need,
				Kind = "Perk",
				Key = key,
			}, false, gap)
		end
	end

	-- (b) the equipped weapon's next evolution tier
	local current = p.Evolutions[p.Equipped]
	local nextTier = (if current then current.Tier else 0) + 1
	local function considerElement(el: string)
		local tier = Evolutions.tierDef(el, nextTier)
		if not tier then
			return
		end
		local label = string.format("%s tier %d", el, tier.Tier)
		local shards = p.Shards[el] or 0
		local short = shards < tier.ShardsCost
		if short then
			local missing = tier.ShardsCost - shards
			label = string.format(
				"%s: need %d more %s shard%s (%s)",
				label,
				missing,
				el,
				if missing == 1 then "" else "s",
				Goals.ShardSource[el] or "?"
			)
		end
		consider(
			{ Label = label, Have = gems, Need = tier.GemsCost, Kind = "Evolution", Key = el },
			short
		)
	end
	if current then
		considerElement(current.Element)
	else
		for _, el in Evolutions.Order do
			considerElement(el)
		end
	end

	return if best then best.Goal else nil
end

return Goals
