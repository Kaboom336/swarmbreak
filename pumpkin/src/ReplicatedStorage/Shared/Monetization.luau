--!strict
-- Fill in IDs before publishing. Runtime UI must hide every offer whose ID is zero.
local Monetization = {
	GamePasses = {
		DoubleSize = {
			Id = 0,
			Price = 199,
			DisplayName = "2× Size",
			Benefit = "2× Size from every grow",
			Duration = "Permanent",
			Stacking = "Multiplies after pets",
		},
		AutoClick = {
			Id = 0,
			Price = 149,
			DisplayName = "Auto Click",
			Benefit = "Grows every 0.5 seconds",
			Duration = "Permanent",
			Stacking = "Uses your Size boosts",
		},
		DoubleWins = {
			Id = 0,
			Price = 249,
			DisplayName = "2× Wins",
			Benefit = "2× banked ride Wins",
			Duration = "Permanent",
			Stacking = "Does not stack with itself",
		},
		ExtraPetEquip = {
			Id = 0,
			Price = 99,
			DisplayName = "+1 Pet Equip",
			Benefit = "Equip one extra pet",
			Duration = "Permanent",
			Stacking = "Maximum 4 equipped",
		},
		VIP = {
			Id = 0,
			Price = 399,
			DisplayName = "VIP",
			Benefit = "1.5× Size and Wins + chat tag",
			Duration = "Permanent",
			Stacking = "Multiplies once",
		},
		FastTripleHatch = {
			Id = 0,
			Price = 149,
			DisplayName = "Fast + Triple Hatch",
			Benefit = "Hatch 3 pets with a faster reveal",
			Duration = "Permanent",
			Stacking = "Uses 3 egg costs",
		},
		AutoHatch = {
			Id = 0,
			Price = 149,
			DisplayName = "Auto Hatch",
			Benefit = "Hatches while you stand by an egg",
			Duration = "Permanent",
			Stacking = "One egg at a time",
		},
		DoubleLuck = {
			Id = 0,
			Price = 199,
			DisplayName = "2× Luck",
			Benefit = "2× rare-pet weight",
			Duration = "Permanent",
			Stacking = "Stacks with one potion",
		},
	},
	DeveloperProducts = {
		LuckyPotion = {
			Id = 0,
			Price = 49,
			DisplayName = "Lucky Potion",
			Benefit = "2× hatch luck",
			Duration = "10 minutes",
			Stacking = "Adds 10 minutes",
		},
		SizeBoost = {
			Id = 0,
			Price = 25,
			DisplayName = "+10K Size",
			Benefit = "+10,000 Size now",
			Duration = "Instant",
			Stacking = "Repeatable",
		},
		WinPack = {
			Id = 0,
			Price = 99,
			DisplayName = "Win Pack",
			Benefit = "+5,000 Wins now",
			Duration = "Instant",
			Stacking = "Repeatable",
		},
		SkipWall = {
			Id = 0,
			Price = 39,
			DisplayName = "Skip Wall",
			Benefit = "One wall skip",
			Duration = "Until used",
			Stacking = "Adds one use",
		},
		StarterPack = {
			Id = 0,
			Price = 99,
			DisplayName = "Pumpkin Starter Pack",
			Benefit = "Sugar Skull pet + 1,500 Wins + 3 Lucky Potions",
			Duration = "One purchase",
			Stacking = "Does not stack",
		},
	},
}

function Monetization.liveOfferCount(): number
	local count = 0
	for _, group in { Monetization.GamePasses, Monetization.DeveloperProducts } do
		for _, offer in group do
			if offer.Id > 0 then
				count += 1
			end
		end
	end
	return count
end

function Monetization.validationErrors(): { string }
	local errors = {}
	for groupName, group in
		{ GamePasses = Monetization.GamePasses, DeveloperProducts = Monetization.DeveloperProducts }
	do
		for name, offer in group do
			if offer.Id <= 0 then
				table.insert(errors, groupName .. "." .. name .. " has no live ID")
			end
			if offer.Price <= 0 or offer.DisplayName == "" or offer.Benefit == "" then
				table.insert(errors, groupName .. "." .. name .. " has incomplete display metadata")
			end
		end
	end
	return errors
end

return Monetization
