--!strict
-- Place ids inside the Swarm Break experience. 0 = not created yet.
-- Zion creates the second place in Studio (File > Publish to Roblox As... under the same experience),
-- then Claude pastes the ids here. With 0, the lobby's drop pads say "not linked yet" and the
-- arena is playtested by opening the arena place directly.
local Places = {
	LobbyPlaceId = 0,
	ArenaPlaceId = 0,
	LobbyMaxPlayers = 30, -- set in the Creator Dashboard per place, noted here for reference
	ArenaMaxPlayers = 8,
	PartySize = 4,
	DropCountdownSeconds = 8,
}
return Places
