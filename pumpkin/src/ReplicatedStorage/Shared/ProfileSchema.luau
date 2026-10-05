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
	DoubleSize: boolean,
	VIP: boolean,
	ExtraPetEquip: boolean,
	FastTripleHatch: boolean,
	LuckyPotionExpiresAt: number,
	ExpandedPetStorage: boolean,
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
		DoubleSize = false,
		VIP = false,
		ExtraPetEquip = false,
		FastTripleHatch = false,
		LuckyPotionExpiresAt = 0,
		ExpandedPetStorage = false,
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
	profile.DoubleSize = source.DoubleSize == true
	profile.VIP = source.VIP == true
	profile.ExtraPetEquip = source.ExtraPetEquip == true
	profile.FastTripleHatch = source.FastTripleHatch == true
	profile.LuckyPotionExpiresAt = math.max(0, tonumber(source.LuckyPotionExpiresAt) or 0)
	profile.ExpandedPetStorage = source.ExpandedPetStorage == true
	return profile
end

return ProfileSchema
