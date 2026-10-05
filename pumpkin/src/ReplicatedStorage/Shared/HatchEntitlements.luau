--!strict
local HatchEntitlements = {}

export type State = {
	freeCandyUsed: boolean,
	freeSpookyHatches: number,
}

function HatchEntitlements.cost(
	eggName: string,
	count: number,
	unitCost: number,
	state: State
): (number, State)
	local units = math.max(0, math.floor(count))
	local nextState = {
		freeCandyUsed = state.freeCandyUsed,
		freeSpookyHatches = math.max(0, math.floor(state.freeSpookyHatches)),
	}
	local freeUnits = 0
	if eggName == "CandyEgg" and not nextState.freeCandyUsed and units > 0 then
		freeUnits += 1
		nextState.freeCandyUsed = true
	elseif eggName == "SpookyEgg" and nextState.freeSpookyHatches > 0 then
		freeUnits = math.min(units, nextState.freeSpookyHatches)
		nextState.freeSpookyHatches -= freeUnits
	end
	return math.max(0, units - freeUnits) * math.max(0, unitCost), nextState
end

return HatchEntitlements
