--!strict
local Config = require(script.Parent.Config)

export type Pet = {
	id: string,
	name: string,
	rarity: string,
	multiplier: number,
}

export type Profile = {
	Version: number,
	Size: number,
	Wins: number,
	TotalWins: number,
	BiggestPumpkin: number,
	Rebirths: number,
	Pets: { Pet },
	EquippedPetIds: { string },
	RedeemedCodes: { [string]: boolean },
	Receipts: { [string]: boolean },
	DailyStreak: number,
	DailyLastClaimDay: number?,
	LuckyUntil: number,
	SkipWalls: number,
	DoubleSize: boolean,
	AutoClick: boolean,
	DoubleWins: boolean,
	ExtraPetEquip: boolean,
	VIP: boolean,
	TutorialDone: boolean,
	FastTripleHatch: boolean,
	ExpandedPetStorage: boolean,
	FreeCandyHatchUsed: boolean,
	StarterGiftClaimed: boolean,
	PlaytimeGiftClaims: { [string]: boolean },
	DiscoveredPets: { [string]: boolean },
	FreeSpookyHatches: number,
	AutoHatch: boolean,
	DoubleLuck: boolean,
	StarterPackPurchased: boolean,
	StarterPackOfferEndsAt: number,
}

local ProfileSchema = {}

function ProfileSchema.default(): Profile
	return {
		Version = Config.DataVersion,
		Size = 0,
		Wins = 0,
		TotalWins = 0,
		BiggestPumpkin = 0,
		Rebirths = 0,
		Pets = {},
		EquippedPetIds = {},
		RedeemedCodes = {},
		Receipts = {},
		DailyStreak = 0,
		DailyLastClaimDay = nil,
		LuckyUntil = 0,
		SkipWalls = 0,
		DoubleSize = false,
		AutoClick = false,
		DoubleWins = false,
		ExtraPetEquip = false,
		VIP = false,
		TutorialDone = false,
		FastTripleHatch = false,
		ExpandedPetStorage = false,
		FreeCandyHatchUsed = false,
		StarterGiftClaimed = false,
		PlaytimeGiftClaims = {},
		DiscoveredPets = {},
		FreeSpookyHatches = 0,
		AutoHatch = false,
		DoubleLuck = false,
		StarterPackPurchased = false,
		StarterPackOfferEndsAt = 0,
	}
end

local function copyMap(source: any): { [any]: any }
	local result = {}
	if type(source) == "table" then
		for key, value in source do
			result[key] = value
		end
	end
	return result
end

function ProfileSchema.fromStored(stored: any): Profile
	local source = if type(stored) == "table" then stored else {}
	local profile = ProfileSchema.default()
	profile.Size = math.max(0, tonumber(source.Size) or 0)
	profile.Wins = math.max(0, tonumber(source.Wins) or 0)
	profile.TotalWins = math.max(profile.Wins, tonumber(source.TotalWins) or 0)
	profile.BiggestPumpkin = math.max(profile.Size, tonumber(source.BiggestPumpkin) or 0)
	profile.Rebirths = math.max(0, math.floor(tonumber(source.Rebirths) or 0))
	profile.Pets = copyMap(source.Pets) :: any
	profile.EquippedPetIds = copyMap(source.EquippedPetIds) :: any
	profile.RedeemedCodes = copyMap(source.RedeemedCodes) :: any
	profile.Receipts = copyMap(source.Receipts) :: any
	profile.DailyStreak = math.clamp(math.floor(tonumber(source.DailyStreak) or 0), 0, 7)
	profile.DailyLastClaimDay = if source.DailyLastClaimDay == nil
		then nil
		else math.floor(tonumber(source.DailyLastClaimDay) or 0)
	profile.LuckyUntil = math.max(0, math.floor(tonumber(source.LuckyUntil) or 0))
	profile.SkipWalls = math.max(0, math.floor(tonumber(source.SkipWalls) or 0))
	profile.DoubleSize = source.DoubleSize == true
	profile.AutoClick = source.AutoClick == true
	profile.DoubleWins = source.DoubleWins == true
	profile.ExtraPetEquip = source.ExtraPetEquip == true
	profile.VIP = source.VIP == true
	-- Profiles from before the flag count as done once they have any progress
	profile.TutorialDone = source.TutorialDone == true
		or (tonumber(source.TotalWins) or 0) > 0
		or (tonumber(source.Rebirths) or 0) > 0
	profile.FastTripleHatch = source.FastTripleHatch == true
	profile.ExpandedPetStorage = source.ExpandedPetStorage == true
	profile.FreeCandyHatchUsed = source.FreeCandyHatchUsed == true
	profile.StarterGiftClaimed = source.StarterGiftClaimed == true
	profile.PlaytimeGiftClaims = copyMap(source.PlaytimeGiftClaims) :: any
	profile.DiscoveredPets = copyMap(source.DiscoveredPets) :: any
	for _, pet in profile.Pets do
		if type(pet) == "table" and type(pet.name) == "string" then
			profile.DiscoveredPets[pet.name] = true
		end
	end
	profile.FreeSpookyHatches = math.max(0, math.floor(tonumber(source.FreeSpookyHatches) or 0))
	profile.AutoHatch = source.AutoHatch == true
	profile.DoubleLuck = source.DoubleLuck == true
	profile.StarterPackPurchased = source.StarterPackPurchased == true
	profile.StarterPackOfferEndsAt =
		math.max(0, math.floor(tonumber(source.StarterPackOfferEndsAt) or 0))
	return profile
end

return ProfileSchema
