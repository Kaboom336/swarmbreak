--!strict
-- Pure death and restart state machine shared by the HUD and its tests.

export type State = "alive" | "dead" | "spectate" | "respawn" | "summary"
export type Event = "died" | "spectate" | "respawned" | "all-dead" | "ready" | "play-again"

local DeathFlow = {}

DeathFlow.SpectateSeconds = 3

local transitions: { [State]: { [Event]: State } } = {
	alive = {
		died = "dead",
	},
	dead = {
		spectate = "spectate",
	},
	spectate = {
		respawned = "respawn",
		["all-dead"] = "summary",
	},
	respawn = {
		ready = "alive",
	},
	summary = {
		["play-again"] = "alive",
	},
}

function DeathFlow.initialState(): State
	return "alive"
end

function DeathFlow.transition(state: State, event: Event): State
	return transitions[state][event] or state
end

return DeathFlow
