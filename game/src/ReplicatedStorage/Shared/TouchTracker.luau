--!strict
export type State = {
	FireTouch: any,
}

local TouchTracker = {}

function TouchTracker.new(): State
	return {
		FireTouch = nil,
	}
end

local function copy(state: State): State
	return {
		FireTouch = state.FireTouch,
	}
end

function TouchTracker.began(state: State, id: any, onGui: boolean): State
	local nextState = copy(state)
	if not onGui and nextState.FireTouch == nil then
		nextState.FireTouch = id
	end
	return nextState
end

function TouchTracker.ended(state: State, id: any): State
	local nextState = copy(state)
	if nextState.FireTouch == id then
		nextState.FireTouch = nil
	end
	return nextState
end

function TouchTracker.isFiring(state: State): boolean
	return state.FireTouch ~= nil
end

function TouchTracker.fireTouch(state: State): any?
	return state.FireTouch
end

return TouchTracker
