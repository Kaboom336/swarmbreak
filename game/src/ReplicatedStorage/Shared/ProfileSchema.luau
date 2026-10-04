--!strict
-- Shape of the saved player profile (shared by the lobby and the arena). Pure + tested.
local Weapons = require(script.Parent.Weapons)
local Evolutions = require(script.Parent.Evolutions)
local Quests = require(script.Parent.Quests)
local Kits = require(script.Parent.Kits)
local Settings = require(script.Parent.Settings)
local ReceiptLedger = require(script.Parent.ReceiptLedger)
local Campaign = require(script.Parent.Campaign)
local CoreStages = require(script.Parent.CoreStages)
local Difficulty = require(script.Parent.Difficulty)

export type Profile = {
	Version: number,
	Gold: number,
	Gems: number,
	Shards: { [string]: number }, -- per element
	Weapons: { string }, -- owned weapon ids
	Equipped: string,
	Evolutions: { [string]: { Element: string, Tier: number } }, -- per weapon id
	Perks: { [string]: number }, -- lobby perks (levels)
	BestWave: number,
	Runs: number,
	CratesSinceLegendary: number, -- Robux crates opened since the last Legendary (pity counter)
	Flags: { [string]: boolean }, -- one-time events already paid out (see FlagKeys)
	BaseThemes: { [string]: boolean },
	Redeemed: { [string]: boolean }, -- redeemable codes already paid out
	LastClaimDay: number, -- UTC day number (Daily.dayIndex) of the last daily reward, 0 = never
	Streak: number, -- days in a row the daily reward was claimed
	Quests: Quests.State,
	Kit: string,
	KitsOwned: { [string]: boolean },
	MusicVolume: number,
	SfxVolume: number,
	MouseLockEnabled: boolean,
	ProcessedPurchaseIds: { string },
}

local ProfileSchema = { Version = 1 }

ProfileSchema.PerkMaxLevel = 10
ProfileSchema.PerkCostCurve = {
	{ Gold = 100, Gems = 5 },
	{ Gold = 180, Gems = 8 },
	{ Gold = 300, Gems = 12 },
	{ Gold = 480, Gems = 18 },
	{ Gold = 750, Gems = 27 },
	{ Gold = 1100, Gems = 40 },
	{ Gold = 1600, Gems = 58 },
	{ Gold = 2300, Gems = 82 },
	{ Gold = 3200, Gems = 115 },
	{ Gold = 4400, Gems = 155 },
}

ProfileSchema.PerkDefs = {
	MaxHealth = { Label = "Max HP", PerLevel = 10, MaxLevel = ProfileSchema.PerkMaxLevel },
	DamagePercent = {
		Label = "Damage %",
		PerLevel = 5,
		MaxLevel = ProfileSchema.PerkMaxLevel,
	},
	MoveSpeedPercent = {
		Label = "Move Speed %",
		PerLevel = 2,
		MaxLevel = ProfileSchema.PerkMaxLevel,
	},
	DashCharges = {
		Label = "Dash charges",
		PerLevel = 1,
		MaxLevel = ProfileSchema.PerkMaxLevel,
	},
	GoldFindPercent = {
		Label = "Gold find %",
		PerLevel = 5,
		MaxLevel = ProfileSchema.PerkMaxLevel,
	},
	GemFindPercent = {
		Label = "Gem find %",
		PerLevel = 5,
		MaxLevel = ProfileSchema.PerkMaxLevel,
	},
}

-- The only flags a profile may carry. FirstBossCrate: the free Gem crate for the first boss kill.
ProfileSchema.FlagKeys = {
	"FirstBossCrate",
	"Tut_Move",
	"Tut_Shoot",
	"Tut_Dash",
	"Tut_Pick",
	"Tut_Upgrade",
	"Tut_Crate",
}

function ProfileSchema.default(): Profile
	local shards = {}
	for _, el in Evolutions.Order do
		shards[el] = 0
	end
	return {
		Version = ProfileSchema.Version,
		Gold = 0,
		Gems = 0,
		Shards = shards,
		Weapons = { "Starter" },
		Equipped = "Starter",
		Evolutions = {},
		Perks = {},
		BestWave = 0,
		Runs = 0,
		CratesSinceLegendary = 0,
		Flags = {},
		BaseThemes = {},
		Redeemed = {},
		LastClaimDay = 0,
		Streak = 0,
		Quests = { Day = 0, Ids = {}, Progress = {}, Claimed = {} },
		Kit = "Soldier",
		KitsOwned = { Soldier = true },
		MusicVolume = Settings.DefaultVolume,
		SfxVolume = Settings.DefaultVolume,
		MouseLockEnabled = Settings.DefaultMouseLock,
		ProcessedPurchaseIds = {},
	}
end

-- Takes whatever came out of the DataStore and returns a valid profile, dropping junk.
function ProfileSchema.sanitize(raw: any): Profile
	local p = ProfileSchema.default()
	if type(raw) ~= "table" then
		return p
	end
	if type(raw.Gold) == "number" and raw.Gold >= 0 then
		p.Gold = math.floor(raw.Gold)
	end
	if type(raw.Gems) == "number" and raw.Gems >= 0 then
		p.Gems = math.floor(raw.Gems)
	end
	if type(raw.Shards) == "table" then
		for _, el in Evolutions.Order do
			local n = raw.Shards[el]
			if type(n) == "number" and n >= 0 then
				p.Shards[el] = math.floor(n)
			end
		end
	end
	if type(raw.Weapons) == "table" then
		for _, id in raw.Weapons do
			if type(id) == "string" and Weapons.Defs[id] and not table.find(p.Weapons, id) then
				table.insert(p.Weapons, id)
			end
		end
	end
	if type(raw.Equipped) == "string" and table.find(p.Weapons, raw.Equipped) then
		p.Equipped = raw.Equipped
	end
	if type(raw.Evolutions) == "table" then
		for id, evo in raw.Evolutions do
			if
				type(id) == "string"
				and Weapons.Defs[id]
				and type(evo) == "table"
				and Evolutions.Elements[evo.Element]
			then
				local tier = if type(evo.Tier) == "number"
					then math.clamp(math.floor(evo.Tier), 0, 3)
					else 0
				if tier > 0 then
					p.Evolutions[id] = { Element = evo.Element, Tier = tier }
				end
			end
		end
	end
	if type(raw.Perks) == "table" then
		for k, lvl in raw.Perks do
			local def = ProfileSchema.PerkDefs[k]
			if def and type(lvl) == "number" then
				p.Perks[k] = math.clamp(math.floor(lvl), 0, def.MaxLevel)
			end
		end
	end
	if type(raw.BestWave) == "number" then
		p.BestWave = math.max(0, math.floor(raw.BestWave))
	end
	if type(raw.Runs) == "number" then
		p.Runs = math.max(0, math.floor(raw.Runs))
	end
	if type(raw.CratesSinceLegendary) == "number" then
		p.CratesSinceLegendary = math.clamp(math.floor(raw.CratesSinceLegendary), 0, 9999)
	end
	if type(raw.Flags) == "table" then
		for _, k in ProfileSchema.FlagKeys do
			if raw.Flags[k] == true then
				p.Flags[k] = true
			end
		end
		-- In-run recipe discoveries (J2) are flags keyed per recipe id.
		for _, recipe in Evolutions.Recipes do
			local k = Evolutions.RecipeFlagPrefix .. recipe.Id
			if raw.Flags[k] == true then
				p.Flags[k] = true
			end
		end
		for _, map in Campaign.All do
			for _, tier in Difficulty.Order do
				local key = Campaign.clearFlag(map.Id, tier)
				if raw.Flags[key] == true then
					p.Flags[key] = true
					for stageNumber = 1, CoreStages.Count do
						p.Flags[CoreStages.clearFlag(map.Id, tier, stageNumber)] = true
					end
				end
				for stageNumber = 1, CoreStages.Count do
					local stageKey = CoreStages.clearFlag(map.Id, tier, stageNumber)
					if CoreStages.get(map.Id, stageNumber) and raw.Flags[stageKey] == true then
						p.Flags[stageKey] = true
					end
				end
			end
		end
	end
	if type(raw.BaseThemes) == "table" and raw.BaseThemes.Mars == true then
		p.BaseThemes.Mars = true
	end
	if type(raw.Redeemed) == "table" then
		for code, redeemed in raw.Redeemed do
			if type(code) == "string" and redeemed == true then
				p.Redeemed[code] = true
			end
		end
	end
	if type(raw.LastClaimDay) == "number" then
		p.LastClaimDay = math.max(0, math.floor(raw.LastClaimDay))
	end
	if type(raw.Streak) == "number" then
		p.Streak = math.max(0, math.floor(raw.Streak))
	end
	if type(raw.Quests) == "table" then
		local quests = raw.Quests
		if type(quests.Day) == "number" and quests.Day >= 0 then
			p.Quests.Day = math.floor(quests.Day)
		end
		if type(quests.Ids) == "table" then
			for _, id in quests.Ids do
				if
					type(id) == "string"
					and Quests.Defs[id]
					and not table.find(p.Quests.Ids, id)
					and #p.Quests.Ids < 3
				then
					table.insert(p.Quests.Ids, id)
				end
			end
		end
		for _, id in p.Quests.Ids do
			local def = Quests.Defs[id]
			local value = if type(quests.Progress) == "table" then quests.Progress[id] else nil
			if type(value) == "number" and value >= 0 then
				p.Quests.Progress[id] = math.min(def.Target, math.floor(value))
			end
			if
				type(quests.Claimed) == "table"
				and quests.Claimed[id] == true
				and p.Quests.Progress[id] == def.Target
			then
				p.Quests.Claimed[id] = true
			end
		end
	end
	if type(raw.KitsOwned) == "table" then
		for _, id in Kits.Order do
			if raw.KitsOwned[id] == true then
				p.KitsOwned[id] = true
			end
		end
	end
	if type(raw.Kit) == "string" and Kits.isUnlocked(p, raw.Kit) then
		p.Kit = raw.Kit
	end
	p.MusicVolume = Settings.clamp(raw.MusicVolume)
	p.SfxVolume = Settings.clamp(raw.SfxVolume)
	p.MouseLockEnabled = if type(raw.MouseLockEnabled) == "boolean"
		then raw.MouseLockEnabled
		else Settings.DefaultMouseLock
	p.ProcessedPurchaseIds = ReceiptLedger.sanitize(raw.ProcessedPurchaseIds)
	return p
end

function ProfileSchema.perkLevel(p: Profile, key: string): number
	return p.Perks[key] or 0
end

function ProfileSchema.perkValue(p: Profile, key: string): number
	local def = ProfileSchema.PerkDefs[key]
	if not def then
		return 0
	end
	return def.PerLevel * ProfileSchema.perkLevel(p, key)
end

-- Returns ok, reason. Does not mutate.
function ProfileSchema.canBuyPerk(p: Profile, key: string): (boolean, string)
	local def = ProfileSchema.PerkDefs[key]
	if not def then
		return false, "Unknown perk."
	end
	local lvl = ProfileSchema.perkLevel(p, key)
	if lvl >= def.MaxLevel then
		return false, "Maxed."
	end
	local cost = ProfileSchema.PerkCostCurve[lvl + 1]
	if p.Gold < cost.Gold then
		return false, string.format("Need %d Gold.", cost.Gold)
	end
	if p.Gems < cost.Gems then
		return false, string.format("Need %d Gems.", cost.Gems)
	end
	return true, ""
end

function ProfileSchema.perkCost(p: Profile, key: string): { Gold: number, Gems: number }?
	local def = ProfileSchema.PerkDefs[key]
	if not def then
		return nil
	end
	local lvl = ProfileSchema.perkLevel(p, key)
	if lvl >= def.MaxLevel then
		return nil
	end
	return ProfileSchema.PerkCostCurve[lvl + 1]
end

-- Validates both balances before changing either one, so a rejected purchase is atomic.
function ProfileSchema.buyPerk(p: Profile, key: string): (boolean, string)
	local ok, why = ProfileSchema.canBuyPerk(p, key)
	if not ok then
		return false, why
	end
	local cost = ProfileSchema.perkCost(p, key)
	if not cost then
		return false, "Maxed."
	end
	p.Gold -= cost.Gold
	p.Gems -= cost.Gems
	p.Perks[key] = ProfileSchema.perkLevel(p, key) + 1
	return true, ""
end

return ProfileSchema
