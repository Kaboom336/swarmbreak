--!strict
-- Pure decision: when the mouse is locked to the crosshair and when it is free for UI.
local MouseMode = {}

export type State = {
	LockPreferred: boolean, -- the player's Mouse Lock setting
	Alive: boolean,
	ModalOpen: boolean, -- run summary, cards, shop, settings, quests, stats
	FreeHeld: boolean, -- Left Alt held to free the cursor for a moment
	TouchOnly: boolean,
}

function MouseMode.locked(state: State): boolean
	return state.LockPreferred
		and state.Alive
		and not state.ModalOpen
		and not state.FreeHeld
		and not state.TouchOnly
end

-- Turning the character toward the crosshair only makes sense while aiming.
function MouseMode.aimsCharacter(state: State): boolean
	return state.Alive and not state.ModalOpen and not state.TouchOnly
end

return MouseMode
