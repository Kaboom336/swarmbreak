--!strict
-- Fill in IDs before publishing. Runtime UI must hide every offer whose ID is zero.
local Monetization = {
	GamePasses = {
		DoubleSize = { Id = 0, Price = 199 },
		AutoClick = { Id = 0, Price = 149 },
		DoubleWins = { Id = 0, Price = 249 },
		ExtraPetEquip = { Id = 0, Price = 99 },
		VIP = { Id = 0, Price = 399 },
		FastTripleHatch = { Id = 0, Price = 149 },
		AutoHatch = { Id = 0, Price = 149 },
		DoubleLuck = { Id = 0, Price = 199 },
	},
	DeveloperProducts = {
		LuckyPotion = { Id = 0, Price = 49 },
		SizeBoost = { Id = 0, Price = 25 },
		WinPack = { Id = 0, Price = 99 },
		SkipWall = { Id = 0, Price = 39 },
		StarterPack = { Id = 0, Price = 99 },
	},
}

return Monetization
