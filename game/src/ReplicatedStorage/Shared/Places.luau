--!strict
-- Place ids and same-place lobby layout. 0 = not created or published yet.
local Places = {
	LobbyPlaceId = 0,
	ArenaPlaceId = 0,
	LobbyMaxPlayers = 30, -- set in the Creator Dashboard per place, noted here for reference
	ArenaMaxPlayers = 8,
	PartySize = 4,
	StartPadSeconds = 3,
	DropCountdownSeconds = 3, -- compatibility name for the old drop-pad UI
	LobbyOrigin = { x = 125, y = 0, z = 0 },
	ArenaArrival = { x = 0, y = 4, z = 0 },
}
return Places
