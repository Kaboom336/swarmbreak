--!strict
-- Limits concurrent client sounds while preserving important stingers and player feedback.

export type Priority = number
export type State = {
	Active: number,
	ActiveByName: { [string]: number },
	LastPlayedAt: { [string]: number },
}

local SoundBudget = {}

SoundBudget.GlobalCap = 24 -- placeholder
SoundBudget.PerNameCap = 6 -- placeholder
SoundBudget.MinIntervalSec = 0.06 -- placeholder

SoundBudget.P0 = 0 :: Priority
SoundBudget.P1 = 1 :: Priority
SoundBudget.P2 = 2 :: Priority
SoundBudget.P3 = 3 :: Priority
SoundBudget.Priority = {
	P0 = SoundBudget.P0,
	P1 = SoundBudget.P1,
	P2 = SoundBudget.P2,
	P3 = SoundBudget.P3,
}

local function copyCounts(source: { [string]: number }): { [string]: number }
	return table.clone(source)
end

function SoundBudget.new(): State
	return {
		Active = 0,
		ActiveByName = {},
		LastPlayedAt = {},
	}
end

function SoundBudget.allow(
	state: State,
	name: string,
	priority: Priority,
	now: number
): (State, boolean)
	local activeForName = state.ActiveByName[name] or 0
	local lastPlayedAt = state.LastPlayedAt[name]
	local isP0 = priority == SoundBudget.P0
	local insideInterval = lastPlayedAt ~= nil and now - lastPlayedAt < SoundBudget.MinIntervalSec

	if
		not isP0
		and (
			state.Active >= SoundBudget.GlobalCap
			or activeForName >= SoundBudget.PerNameCap
			or insideInterval
		)
	then
		return state, false
	end

	local activeByName = copyCounts(state.ActiveByName)
	activeByName[name] = activeForName + 1
	local lastPlayedByName = copyCounts(state.LastPlayedAt)
	lastPlayedByName[name] = now
	return {
		Active = state.Active + 1,
		ActiveByName = activeByName,
		LastPlayedAt = lastPlayedByName,
	},
		true
end

function SoundBudget.release(state: State, name: string, _now: number): State
	local activeForName = state.ActiveByName[name] or 0
	if activeForName <= 0 then
		return state
	end

	local activeByName = copyCounts(state.ActiveByName)
	if activeForName == 1 then
		activeByName[name] = nil
	else
		activeByName[name] = activeForName - 1
	end
	return {
		Active = math.max(0, state.Active - 1),
		ActiveByName = activeByName,
		LastPlayedAt = copyCounts(state.LastPlayedAt),
	}
end

return SoundBudget
