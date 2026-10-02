local DeathFlow = load("DeathFlow")

test("death flow follows the respawn branch", function()
	local state = DeathFlow.initialState()
	eq(state, "alive", "initial state")

	state = DeathFlow.transition(state, "died")
	eq(state, "dead", "death state")

	state = DeathFlow.transition(state, "spectate")
	eq(state, "spectate", "spectate state")
	eq(DeathFlow.SpectateSeconds, 3, "spectate duration")

	state = DeathFlow.transition(state, "respawned")
	eq(state, "respawn", "respawn state")

	state = DeathFlow.transition(state, "ready")
	eq(state, "alive", "returned alive")
end)

test("death flow follows the all-dead summary branch", function()
	local state = DeathFlow.transition(DeathFlow.initialState(), "died")
	state = DeathFlow.transition(state, "spectate")
	state = DeathFlow.transition(state, "all-dead")
	eq(state, "summary", "all-dead state")

	state = DeathFlow.transition(state, "play-again")
	eq(state, "alive", "play again state")
end)

test("death flow ignores events that are invalid for the current state", function()
	eq(DeathFlow.transition("alive", "all-dead"), "alive", "living player summary")
	eq(DeathFlow.transition("spectate", "ready"), "spectate", "early ready")
	eq(DeathFlow.transition("summary", "respawned"), "summary", "summary respawn")
end)
