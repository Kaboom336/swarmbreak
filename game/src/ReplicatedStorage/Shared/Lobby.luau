--!strict
-- Pure lobby rules and display data. Runtime geometry lives in LobbyBuilder.
local Places = require(script.Parent.Places)

export type ShopItem = {
	Id: string,
	Name: string,
	Price: number,
}

local Lobby = {}

Lobby.StartPadSeconds = Places.StartPadSeconds
Lobby.PartySize = Places.PartySize

Lobby.Boards = {
	WeaponAndKit = "WEAPON + KIT SELECT",
	DailyQuests = "DAILY QUESTS",
	Shop = "SHOP",
}

-- Placeholder storefront prices stay at zero until products are configured and published.
Lobby.ShopItems = {
	{ Id = "QuickCrate", Name = "Quick Crate", Price = 0 },
	{ Id = "LuckyCrate", Name = "Lucky Crate", Price = 0 },
	{ Id = "VIP", Name = "VIP", Price = 0 },
	{ Id = "StarterPack", Name = "Starter Pack", Price = 0 },
	{ Id = "DoubleRunRewards", Name = "Double Run Rewards", Price = 0 },
} :: { ShopItem }

function Lobby.isPadReady(enteredAt: number, now: number): boolean
	return now >= enteredAt and now - enteredAt >= Lobby.StartPadSeconds
end

-- Preserve arrival order, ignore duplicate ids, and split the queue into bounded parties.
function Lobby.groupParties(userIds: { number }): { { number } }
	local parties = {}
	local seen = {}
	local party = {}
	for _, userId in userIds do
		if not seen[userId] then
			seen[userId] = true
			table.insert(party, userId)
			if #party == Lobby.PartySize then
				table.insert(parties, party)
				party = {}
			end
		end
	end
	if #party > 0 then
		table.insert(parties, party)
	end
	return parties
end

return Lobby
