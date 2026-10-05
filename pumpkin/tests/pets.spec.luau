--!strict
local Config = load("Config")
local Pets = load("Pets")

test("rarity rolls stay within 1.5 percentage points over ten thousand samples", function()
	local randomSource = Pets.newSeededRandom(20_261_005)
	local counts = {}
	for rarity in Config.PetRarityWeights do
		counts[rarity] = 0
	end
	for _ = 1, 10_000 do
		local rarity = Pets.rollRarity(randomSource)
		counts[rarity] += 1
	end
	for rarity, expectedPercent in Config.PetRarityWeights do
		local actualPercent = counts[rarity] / 100
		if math.abs(actualPercent - expectedPercent) > 1.5 then
			error(
				string.format(
					"%s: expected %.1f%%, got %.2f%%",
					rarity,
					expectedPercent,
					actualPercent
				)
			)
		end
	end
end)

test("equipped pet multipliers add and empty equipment stays neutral", function()
	local inventory = {
		{ id = "one", name = "Candy Corn", rarity = "Common", multiplier = 1.2 },
		{ id = "two", name = "Gummy Ghost", rarity = "Rare", multiplier = 2 },
		{ id = "three", name = "Golden Pumpkin", rarity = "Legendary", multiplier = 5 },
	}
	eq(Pets.multiplierSum(inventory, {}), 1, "empty multiplier")
	eq(Pets.multiplierSum(inventory, { "one", "two" }), 3.2, "additive multiplier")
	local best = Pets.equipBest(inventory, 2)
	eq(best[1], "three", "best pet first")
	eq(best[2], "two", "second best pet")
end)

test("inventory capacity honors base and expanded limits", function()
	local inventory = {}
	for index = 1, Config.BaseInventoryCap do
		table.insert(inventory, {
			id = tostring(index),
			name = "Pet",
			rarity = "Common",
			multiplier = 1.2,
		})
	end
	eq(Pets.canAdd(inventory, 1, false), false, "base inventory full")
	eq(Pets.canAdd(inventory, 1, true), true, "expanded inventory has room")

	for index = #inventory + 1, Config.StorageInventoryCap do
		table.insert(inventory, {
			id = tostring(index),
			name = "Pet",
			rarity = "Common",
			multiplier = 1.2,
		})
	end
	eq(Pets.canAdd(inventory, 1, true), false, "expanded inventory full")
end)
