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
		AutoHatch = 149,
		DoubleLuck = 199,
	}
	local expectedProductPrices = {
		LuckyPotion = 49,
		SizeBoost = 25,
		WinPack = 99,
		SkipWall = 39,
		StarterPack = 99,
	}
	for name, price in expectedPassPrices do
		eq(Monetization.GamePasses[name].Id, 0, name .. " id")
		eq(Monetization.GamePasses[name].Price, price, name .. " price")
		eq(Monetization.GamePasses[name].DisplayName ~= "", true, name .. " display")
		eq(Monetization.GamePasses[name].Benefit ~= "", true, name .. " benefit")
	end
	for name, price in expectedProductPrices do
		eq(Monetization.DeveloperProducts[name].Id, 0, name .. " id")
		eq(Monetization.DeveloperProducts[name].Price, price, name .. " price")
		eq(Monetization.DeveloperProducts[name].Duration ~= "", true, name .. " duration")
		eq(Monetization.DeveloperProducts[name].Stacking ~= "", true, name .. " stacking")
	end
	eq(Monetization.liveOfferCount(), 0, "placeholder offers stay hidden")
	eq(#Monetization.validationErrors() > 0, true, "pre-publish report catches every zero ID")
end)
