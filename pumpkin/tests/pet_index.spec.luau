--!strict
local Config = load("Config")
local PetIndex = load("PetIndex")

test("completing each egg page gives ten percent permanent Size", function()
	local discovered = {}
	eq(PetIndex.completedEggs(discovered), 0, "empty index")
	eq(PetIndex.sizeMultiplier(discovered), 1, "empty bonus")
	for _, pet in Config.Eggs[1].Pets do
		eq(PetIndex.discover(discovered, pet.Name), true, "first discovery")
		eq(PetIndex.discover(discovered, pet.Name), false, "repeat discovery")
	end
	eq(PetIndex.isEggComplete(Config.Eggs[1], discovered), true, "Candy page complete")
	eq(PetIndex.completedEggs(discovered), 1, "one page")
	eq(PetIndex.sizeMultiplier(discovered), 1.1, "ten percent bonus")
end)
