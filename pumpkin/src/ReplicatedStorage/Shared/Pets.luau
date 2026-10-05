--!strict
local Config = require(script.Parent.Config)

export type Pet = {
	id: string,
	name: string,
	rarity: string,
	multiplier: number,
}

export type RandomSource = () -> number

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
local Pets = {}

function Pets.newSeededRandom(seed: number): RandomSource
	local modulus = 2_147_483_647
	local state = math.floor(math.abs(seed)) % modulus
	if state == 0 then
		state = 1
	end
	return function(): number
		state = (state * 16_807) % modulus
		return (state - 1) / (modulus - 1)
	end
end

function Pets.findEgg(eggName: string): any?
	for _, egg in Config.Eggs do
		if egg.Name == eggName then
			return egg
		end
	end
	return nil
end

function Pets.rollRarity(randomSource: RandomSource, luckMultiplier: number?): string
	local luck = math.max(1, luckMultiplier or 1)
	local totalWeight = 0
	for _, rarity in RARITIES do
		local weight = Config.PetRarityWeights[rarity]
		if rarity ~= "Common" then
			weight *= luck
		end
		totalWeight += weight
	end

	local target = math.clamp(randomSource(), 0, 1 - 1e-12) * totalWeight
	local cumulative = 0
	for _, rarity in RARITIES do
		local weight = Config.PetRarityWeights[rarity]
		if rarity ~= "Common" then
			weight *= luck
		end
		cumulative += weight
		if target < cumulative then
			return rarity
		end
	end
	return "Legendary"
end

function Pets.roll(eggName: string, randomSource: RandomSource, luckMultiplier: number?): Pet?
	local egg = Pets.findEgg(eggName)
	if not egg then
		return nil
	end
	local rarity = Pets.rollRarity(randomSource, luckMultiplier)
	local definition = egg.Pets[rarity]
	return {
		id = "",
		name = definition.Name,
		rarity = rarity,
		multiplier = definition.Multiplier,
	}
end

function Pets.inventoryCap(expandedStorage: boolean?): number
	return if expandedStorage then Config.StorageInventoryCap else Config.BaseInventoryCap
end

function Pets.canAdd(inventory: { Pet }, count: number, expandedStorage: boolean?): boolean
	return count >= 0 and #inventory + count <= Pets.inventoryCap(expandedStorage)
end

function Pets.equippedMultipliers(inventory: { Pet }, equippedIds: { string }): { number }
	local equipped = {}
	for _, petId in equippedIds do
		equipped[petId] = true
	end
	local multipliers = {}
	for _, pet in inventory do
		if equipped[pet.id] then
			table.insert(multipliers, pet.multiplier)
		end
	end
	return multipliers
end

function Pets.multiplierSum(inventory: { Pet }, equippedIds: { string }): number
	local total = 0
	for _, multiplier in Pets.equippedMultipliers(inventory, equippedIds) do
		total += math.max(0, multiplier)
	end
	return if total > 0 then total else 1
end

function Pets.equipBest(inventory: { Pet }, slots: number): { string }
	local candidates = table.clone(inventory)
	table.sort(candidates, function(left, right)
		if left.multiplier == right.multiplier then
			return left.id < right.id
		end
		return left.multiplier > right.multiplier
	end)
	local equipped = {}
	for index = 1, math.min(math.max(0, math.floor(slots)), #candidates) do
		table.insert(equipped, candidates[index].id)
	end
	return equipped
end

function Pets.delete(
	inventory: { Pet },
	equippedIds: { string },
	petId: string
): ({ Pet }, { string }, boolean)
	local keptPets = {}
	local deleted = false
	for _, pet in inventory do
		if pet.id == petId then
			deleted = true
		else
			table.insert(keptPets, pet)
		end
	end
	local keptEquipped = {}
	for _, equippedId in equippedIds do
		if equippedId ~= petId then
			table.insert(keptEquipped, equippedId)
		end
	end
	return keptPets, keptEquipped, deleted
end

return Pets
