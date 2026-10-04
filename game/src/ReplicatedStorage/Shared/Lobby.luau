--!strict
-- Pure lobby rules and display data. Runtime geometry lives in LobbyBuilder.
local Places = require(script.Parent.Places)
local Campaign = require(script.Parent.Campaign)
local Difficulty = require(script.Parent.Difficulty)

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
	Map = "MAP SELECT",
	Difficulty = "DIFFICULTY SELECT",
}

function Lobby.completedTiers(
	profile: { Flags: { [string]: boolean } },
	mapId: string
): { [string]: boolean }
	local completed = {}
	for _, tier in Difficulty.Order do
		completed[tier] = profile.Flags[Campaign.clearFlag(mapId, tier)] == true
	end
	return completed
end

function Lobby.mapOptions(profile: { Flags: { [string]: boolean } })
	local options = {}
	for _, definition in Campaign.All do
		local unlockReason = Campaign.lockReason(profile, definition.Id)
		table.insert(options, {
			Id = definition.Id,
			Name = definition.Name,
			Locked = unlockReason ~= nil or definition.Locked,
			LockText = unlockReason or if definition.Locked then "Coming soon" else nil,
		})
	end
	return options
end

function Lobby.canSelectMap(
	profile: { Flags: { [string]: boolean } },
	mapId: string
): (boolean, string)
	local definition = Campaign.get(mapId)
	if definition.Id ~= mapId then
		return false, "Unknown map"
	end
	local reason = Campaign.lockReason(profile, mapId)
	if reason then
		return false, reason
	end
	if definition.Locked then
		return false, "Coming soon"
	end
	return true, ""
end

function Lobby.canSelectDifficulty(
	profile: { Flags: { [string]: boolean } },
	mapId: string,
	tier: string
): (boolean, string)
	if Difficulty.isUnlocked(tier, Lobby.completedTiers(profile, mapId)) then
		return true, ""
	end
	local definition = Difficulty.Defs[tier :: Difficulty.TierName]
	return false,
		if definition and definition.UnlockAfter
			then "Clear " .. mapId .. " on " .. definition.UnlockAfter
			else "Locked"
end

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
