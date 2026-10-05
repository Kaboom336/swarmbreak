--!strict
local Monetization = load("Monetization")

test("monetization IDs stay unpublished while brief prices are preserved", function()
	local expectedPassPrices = {
		DoubleSize = 199,
		AutoClick = 149,
		DoubleWins = 249,
		ExtraPetEquip = 99,
		VIP = 399,
		FastTripleHatch = 149,
	}
	local expectedProductPrices = {
		LuckyPotion = 49,
		SizeBoost = 25,
		WinPack = 99,
		SkipWall = 39,
	}
	for name, price in expectedPassPrices do
		eq(Monetization.GamePasses[name].Id, 0, name .. " id")
		eq(Monetization.GamePasses[name].Price, price, name .. " price")
	end
	for name, price in expectedProductPrices do
		eq(Monetization.DeveloperProducts[name].Id, 0, name .. " id")
		eq(Monetization.DeveloperProducts[name].Price, price, name .. " price")
	end
end)
