--!strict
local StarterPack = {}

function StarterPack.purchase(alreadyPurchased: boolean, grant: () -> boolean): (boolean, boolean)
	if alreadyPurchased then
		return true, false
	end
	if not grant() then
		return false, false
	end
	return true, true
end

return StarterPack
