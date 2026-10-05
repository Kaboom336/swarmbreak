--!strict
local Config = require(script.Parent.Config)

local PetIndex = {}

function PetIndex.discover(discovered: { [string]: boolean }, petName: string): boolean
	if discovered[petName] then
		return false
	end
	discovered[petName] = true
	return true
end

function PetIndex.isEggComplete(egg: any, discovered: { [string]: boolean }): boolean
	for _, pet in egg.Pets do
		if not discovered[pet.Name] then
			return false
		end
	end
	return true
end

function PetIndex.completedEggs(discovered: { [string]: boolean }): number
	local completed = 0
	for _, egg in Config.Eggs do
		if PetIndex.isEggComplete(egg, discovered) then
			completed += 1
		end
	end
	return completed
end

function PetIndex.sizeMultiplier(discovered: { [string]: boolean }): number
	return 1 + PetIndex.completedEggs(discovered) * Config.PetIndexSizeBonus
end

return PetIndex
