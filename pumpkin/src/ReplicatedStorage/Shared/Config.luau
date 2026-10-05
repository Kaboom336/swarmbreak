--!strict
-- All gameplay tuning lives here so later systems can share the same source of truth.
local Config = {
	GameName = "+1 Pumpkin Every Click",
	DataStoreName = "PumpkinEveryClick_Profile_v1",
	DataVersion = 1,
	AutosaveSeconds = 60,
	SessionLockSeconds = 180,
	DataRetries = 4,
	FirstRetryDelay = 1,

	SizePerClick = 1,
	ClicksPerSecond = 10,
	ClickWindowSeconds = 1,
	PumpkinBaseScale = 1,
	PumpkinLogScale = 1.5,
	PumpkinMaxScale = 12,
	PumpkinBaseDiameter = 2.5,

	WallSpacing = 50,
	WallHealthGrowth = 1.6,
	RebirthBaseCost = 1_000,
	RebirthSizeBonus = 0.5,
	BasePetEquipSlots = 3,
	ExtraPetEquipSlots = 1,
	BaseInventoryCap = 50,
	StorageInventoryCap = 100,

	Zones = {
		{
			Name = "PumpkinPatch",
			DisplayName = "Pumpkin Patch",
			RequiredWins = 0,
			WinMultiplier = 1,
		},
		{
			Name = "HauntedForest",
			DisplayName = "Haunted Forest",
			RequiredWins = 500,
			WinMultiplier = 3,
		},
		{ Name = "Graveyard", DisplayName = "Graveyard", RequiredWins = 5_000, WinMultiplier = 10 },
		{
			Name = "WitchCastle",
			DisplayName = "Witch Castle",
			RequiredWins = 50_000,
			WinMultiplier = 30,
		},
	},
	Eggs = {
		{ Name = "CandyEgg", DisplayName = "Candy Egg", Zone = "PumpkinPatch", Cost = 100 },
		{ Name = "SpookyEgg", DisplayName = "Spooky Egg", Zone = "HauntedForest", Cost = 1_500 },
		{ Name = "BoneEgg", DisplayName = "Bone Egg", Zone = "Graveyard", Cost = 15_000 },
	},
	PetRarityWeights = {
		Common = 60,
		Uncommon = 25,
		Rare = 10,
		Epic = 4.5,
		Legendary = 0.5,
	},
}

return Config
