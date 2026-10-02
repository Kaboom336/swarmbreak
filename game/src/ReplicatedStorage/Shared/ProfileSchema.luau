--!strict
-- Shape of the saved player profile (shared by the lobby and the arena). Pure + tested.
local Weapons = require(script.Parent.Weapons)
local Evolutions = require(script.Parent.Evolutions)
local Quests = require(script.Parent.Quests)
local Kits = require(script.Parent.Kits)
local Settings = require(script.Parent.Settings)

export type Profile = {
	Version: number,
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
	Redeemed: { [string]: boolean }, -- redeemable codes already paid out
	LastClaimDay: number, -- UTC day number (Daily.dayIndex) of the last daily reward, 0 = never
	Streak: number, -- days in a row the daily reward was claimed
	Quests: Quests.State,
	Kit: string,
	KitsOwned: { [string]: boolean },
	MusicVolume: number,
	SfxVolume: number,
	MouseLockEnabled: boolean,
	AutoAim: boolean,
	AimAssistStrength: number,
	UiScale: number,
	LeftHanded: boolean,
	ReduceMotion: boolean,
	Mute: boolean,
}

local ProfileSchema = { Version = 1 }

ProfileSchema.PerkDefs = {
	StartCoins = { Label = "Start coins", PerLevel = 100, MaxLevel = 5, GemsCost = 80 },
	MaxHealth = { Label = "Max HP", PerLevel = 10, MaxLevel = 5, GemsCost = 200 },
	CoinBonus = { Label = "Coin bonus %", PerLevel = 5, MaxLevel = 5, GemsCost = 250 },
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
		Redeemed = {},
		LastClaimDay = 0,
		Streak = 0,
		Quests = { Day = 0, Ids = {}, Progress = {}, Claimed = {} },
		Kit = "Soldier",
		KitsOwned = { Soldier = true },
		MusicVolume = Settings.DefaultVolume,
		SfxVolume = Settings.DefaultVolume,
		MouseLockEnabled = Settings.DefaultMouseLock,
		AutoAim = Settings.DefaultAutoAim,
		AimAssistStrength = Settings.DefaultAimAssistStrength,
		UiScale = Settings.DefaultUiScale,
		LeftHanded = Settings.DefaultLeftHanded,
		ReduceMotion = Settings.DefaultReduceMotion,
		Mute = Settings.DefaultMute,
	}
end

-- Takes whatever came out of the DataStore and returns a valid profile, dropping junk.
function ProfileSchema.sanitize(raw: any): Profile
	local p = ProfileSchema.default()
	if type(raw) ~= "table" then
		return p
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
	local savedSettings = Settings.sanitize(raw)
	for _, field in Settings.Fields do
		(p :: any)[field] = savedSettings[field]
	end
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
	local cost = def.GemsCost * (lvl + 1)
	if p.Gems < cost then
		return false, string.format("Need %d Gems.", cost)
	end
	return true, ""
end

function ProfileSchema.perkCost(p: Profile, key: string): number?
	local def = ProfileSchema.PerkDefs[key]
	if not def then
		return nil
	end
	local lvl = ProfileSchema.perkLevel(p, key)
	if lvl >= def.MaxLevel then
		return nil
	end
	return def.GemsCost * (lvl + 1)
end

return ProfileSchema
