--!strict
-- Pure participation scoring. The server records only validated gameplay events; recent
-- events count more than old ones so doing one thing at the start cannot cover a whole run.
local Participation = {}

export type Kind = "Movement" | "Damage" | "Kill" | "DamageTaken" | "RewardChoice"
export type Event = {
	At: number,
	Points: number,
}
export type State = {
	StartedAt: number,
	JoinedLate: boolean,
	Events: { Event },
}

Participation.WindowSeconds = 180
Participation.MinimumScore = 3

local function pointsFor(kind: Kind, amount: number): number
	if amount <= 0 then
		return 0
	elseif kind == "Movement" then
		return math.min(amount / 16, 1)
	elseif kind == "Damage" then
		return math.min(amount / 30, 2)
	elseif kind == "Kill" then
		return 2.5 * math.min(amount, 1)
	elseif kind == "DamageTaken" then
		return math.min(amount / 20, 2)
	elseif kind == "RewardChoice" then
		return 1.5 * math.min(amount, 1)
	end
	return 0
end

function Participation.new(startedAt: number, joinedLate: boolean?): State
	return {
		StartedAt = startedAt,
		JoinedLate = joinedLate == true,
		Events = {},
	}
end

function Participation.record(state: State, kind: Kind, amount: number, now: number): number
	local points = pointsFor(kind, amount)
	if points > 0 and now >= state.StartedAt then
		table.insert(state.Events, { At = now, Points = points })
	end
	return points
end

-- Linear decay avoids a cliff at the window edge and makes the threshold predictable.
function Participation.score(state: State, now: number): number
	local score = 0
	for _, event in state.Events do
		local age = math.max(0, now - event.At)
		if age < Participation.WindowSeconds then
			score += event.Points * (1 - age / Participation.WindowSeconds)
		end
	end
	return score
end

function Participation.isEligible(state: State, now: number): boolean
	-- A player admitted after a run starts never has to make up activity they could not do.
	return state.JoinedLate or Participation.score(state, now) >= Participation.MinimumScore
end

return Participation
