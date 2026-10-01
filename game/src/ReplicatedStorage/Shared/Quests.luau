--!strict
-- Three deterministic quests per player and UTC day. Pure: the server supplies os.time().
local Daily = require(script.Parent.Daily)

export type QuestDef = {
	Id: string,
	Text: string,
	Stat: string,
	Target: number,
	Gems: number,
}

export type State = {
	Day: number,
	Ids: { string },
	Progress: { [string]: number },
	Claimed: { [string]: boolean },
}

export type Row = {
	Id: string,
	Text: string,
	Progress: number,
	Target: number,
	Gems: number,
	Done: boolean,
}

local Quests = {}

local function quest(def: QuestDef): QuestDef
	return def
end

Quests.Defs = {
	["Clear the Crowd"] = quest({
		Id = "Clear the Crowd",
		Text = "Defeat 50 enemies",
		Stat = "Kills",
		Target = 50,
		Gems = 30,
	}),
	["Climb the Waves"] = quest({
		Id = "Climb the Waves",
		Text = "Reach wave 8",
		Stat = "Wave",
		Target = 8,
		Gems = 35,
	}),
	["Boss Breaker"] = quest({
		Id = "Boss Breaker",
		Text = "Defeat a boss",
		Stat = "BossKills",
		Target = 1,
		Gems = 40,
	}),
	["Up Close"] = quest({
		Id = "Up Close",
		Text = "Deal 1,500 damage with a Melee weapon",
		Stat = "MeleeDamage",
		Target = 1500,
		Gems = 35,
	}),
	["Open a Crate"] = quest({
		Id = "Open a Crate",
		Text = "Open a crate",
		Stat = "Crates",
		Target = 1,
		Gems = 25,
	}),
	["Finish a Run"] = quest({
		Id = "Finish a Run",
		Text = "Finish a run",
		Stat = "Runs",
		Target = 1,
		Gems = 30,
	}),
	["Choose Rewards"] = quest({
		Id = "Choose Rewards",
		Text = "Pick 3 wave rewards",
		Stat = "WaveRewards",
		Target = 3,
		Gems = 25,
	}),
	["Friendly Backup"] = quest({
		Id = "Friendly Backup",
		Text = "Finish a run with a friend",
		Stat = "FriendRuns",
		Target = 1,
		Gems = 40,
	}),
} :: { [string]: QuestDef }

-- Kept explicit so quest selection does not depend on table iteration order.
Quests.Order = {
	"Clear the Crowd",
	"Climb the Waves",
	"Boss Breaker",
	"Up Close",
	"Open a Crate",
	"Finish a Run",
	"Choose Rewards",
	"Friendly Backup",
}

local function copyState(state: State): State
	local ids = {}
	for _, id in state.Ids do
		table.insert(ids, id)
	end
	return {
		Day = state.Day,
		Ids = ids,
		Progress = table.clone(state.Progress),
		Claimed = table.clone(state.Claimed),
	}
end

function Quests.forDay(dayIndex: number, userId: number): { string }
	local pool = table.clone(Quests.Order)
	local state = (math.floor(dayIndex) * 1000000 + math.floor(userId)) % 4294967296
	local picked = {}
	for i = 1, 3 do
		state = (state * 1664525 + 1013904223) % 4294967296
		local choice = i + (state % (#pool - i + 1))
		pool[i], pool[choice] = pool[choice], pool[i]
		table.insert(picked, pool[i])
	end
	return picked
end

-- Wave is an absolute milestone; all other stats are amounts added by an event.
function Quests.progress(state: State, stat: string, amount: number): State
	local nextState = copyState(state)
	if amount <= 0 then
		return nextState
	end
	for _, id in nextState.Ids do
		local def = Quests.Defs[id]
		if def and def.Stat == stat and not nextState.Claimed[id] then
			local old = nextState.Progress[id] or 0
			local value = if stat == "Wave" then math.max(old, amount) else old + amount
			nextState.Progress[id] = math.min(def.Target, value)
		end
	end
	return nextState
end

function Quests.claim(state: State, id: string): (State, number)
	local nextState = copyState(state)
	local def = Quests.Defs[id]
	if
		def
		and table.find(nextState.Ids, id)
		and not nextState.Claimed[id]
		and (nextState.Progress[id] or 0) >= def.Target
	then
		nextState.Claimed[id] = true
		return nextState, def.Gems
	end
	return nextState, 0
end

-- Turn a replicated quest snapshot into display-ready rows without trusting client data.
function Quests.rows(state: any): { Row }
	if typeof(state) ~= "table" or typeof(state.Ids) ~= "table" then
		return {}
	end

	local progress = if typeof(state.Progress) == "table" then state.Progress else {}
	local claimed = if typeof(state.Claimed) == "table" then state.Claimed else {}
	local rows = {}
	for _, id in state.Ids do
		if typeof(id) == "string" then
			local def = Quests.Defs[id]
			if def then
				local value = progress[id]
				if typeof(value) ~= "number" or value ~= value then
					value = 0
				end
				table.insert(rows, {
					Id = id,
					Text = def.Text,
					Progress = math.clamp(value, 0, def.Target),
					Target = def.Target,
					Gems = def.Gems,
					Done = claimed[id] == true,
				})
			end
		end
	end
	return rows
end

-- userId is optional for pure callers; the server supplies it for per-player picks.
function Quests.evaluate(state: State, now: number, userId: number?): State
	local today = Daily.dayIndex(now)
	local validPicks = #state.Ids == 3
	local seen = {}
	for _, id in state.Ids do
		if not Quests.Defs[id] or seen[id] then
			validPicks = false
		end
		seen[id] = true
	end
	if state.Day == today and validPicks then
		return copyState(state)
	end
	return {
		Day = today,
		Ids = Quests.forDay(today, userId or 0),
		Progress = {},
		Claimed = {},
	}
end

return Quests
