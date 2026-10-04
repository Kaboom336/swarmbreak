--!strict
-- Ordered campaign data and pure unlock rules. Runtime map construction lives on the server.
export type MapDefinition = {
	Id: string,
	Name: string,
	StoryLine: string,
	Family: string,
	Zones: { string },
	BossKey: string,
	LightingPreset: string,
	Locked: boolean,
}

local Campaign = {}

Campaign.All = {
	{
		Id = "Outpost9",
		Name = "Outpost 9",
		StoryLine = "The Nest has cut off Outpost 9. Break through and relight the beacon.",
		Family = "Nest",
		Zones = { "Landing Pad", "Refinery", "Hive Core" },
		BossKey = "Queen",
		LightingPreset = "Station",
		Locked = false,
	},
	{
		Id = "FrostRelay",
		Name = "Frost Relay",
		StoryLine = "A frozen relay carries a signal from deeper in the swarm.",
		Family = "Nest",
		Zones = { "Relay Approach", "Coolant Works", "Signal Vault" },
		BossKey = "Queen",
		LightingPreset = "Station",
		Locked = true,
	},
	{
		Id = "MagmaRefinery",
		Name = "Magma Refinery",
		StoryLine = "The refinery is feeding the Hive with stolen heat.",
		Family = "Nest",
		Zones = { "Freight Deck", "Smelter", "Magma Heart" },
		BossKey = "Queen",
		LightingPreset = "Station",
		Locked = true,
	},
	{
		Id = "HiveHeart",
		Name = "Hive Heart",
		StoryLine = "Follow the Queen's trail to the source of the invasion.",
		Family = "Nest",
		Zones = { "Outer Shell", "Brood Tunnels", "Heart Chamber" },
		BossKey = "Queen",
		LightingPreset = "NestInterior",
		Locked = true,
	},
} :: { MapDefinition }

Campaign.Order = Campaign.All
Campaign.DefaultId = "Outpost9"

local byId: { [string]: MapDefinition } = {}
for _, definition in Campaign.All do
	byId[definition.Id] = definition
end

function Campaign.get(id: string?): MapDefinition
	return byId[id or ""] or byId[Campaign.DefaultId]
end

function Campaign.clearFlag(id: string, tier: string): string
	return string.format("MapClear_%s_%s", id, tier)
end

function Campaign.nextMap(id: string): MapDefinition?
	for index, definition in Campaign.All do
		if definition.Id == id then
			return Campaign.All[index + 1]
		end
	end
	return nil
end

function Campaign.unlockedMaps(profile: { Flags: { [string]: boolean } }): { MapDefinition }
	local unlocked = { Campaign.All[1] }
	for index = 2, #Campaign.All do
		local previous = Campaign.All[index - 1]
		if profile.Flags[Campaign.clearFlag(previous.Id, "Normal")] ~= true then
			break
		end
		table.insert(unlocked, Campaign.All[index])
	end
	return unlocked
end

function Campaign.isUnlocked(profile: { Flags: { [string]: boolean } }, id: string): boolean
	for _, definition in Campaign.unlockedMaps(profile) do
		if definition.Id == id then
			return true
		end
	end
	return false
end

function Campaign.lockReason(profile: { Flags: { [string]: boolean } }, id: string): string?
	if Campaign.isUnlocked(profile, id) then
		return nil
	end
	for index, definition in Campaign.All do
		if definition.Id == id and index > 1 then
			return "Clear " .. Campaign.All[index - 1].Name .. " on Normal"
		end
	end
	return "Locked"
end

return Campaign
