--!strict
-- Pure validation for the lobby party selection panel.

export type MapName = "Outpost 9"
export type Difficulty = "Easy" | "Normal" | "Hard"
export type Mode = "Survival" | "Infinite"

export type Selection = {
	Map: MapName,
	Difficulty: Difficulty,
	Mode: Mode,
	PartySize: number,
	FriendsOnly: boolean,
}

local PartyConfig = {}

PartyConfig.Maps = { "Outpost 9" } :: { MapName }
PartyConfig.Difficulties = { "Easy", "Normal", "Hard" } :: { Difficulty }
PartyConfig.Modes = { "Survival", "Infinite" } :: { Mode }
PartyConfig.MinimumPartySize = 1
PartyConfig.MaximumPartySize = 8

local validMaps: { [string]: boolean } = {
	["Outpost 9"] = true,
}

local validDifficulties: { [string]: boolean } = {
	Easy = true,
	Normal = true,
	Hard = true,
}

local validModes: { [string]: boolean } = {
	Survival = true,
	Infinite = true,
}

function PartyConfig.clampPartySize(size: number): number
	return math.clamp(math.floor(size), PartyConfig.MinimumPartySize, PartyConfig.MaximumPartySize)
end

function PartyConfig.validate(raw: any): (Selection?, string?)
	if type(raw) ~= "table" then
		return nil, "invalid config"
	end
	if type(raw.Map) ~= "string" or not validMaps[raw.Map] then
		return nil, "invalid map"
	end
	if type(raw.Difficulty) ~= "string" or not validDifficulties[raw.Difficulty] then
		return nil, "invalid difficulty"
	end
	if type(raw.Mode) ~= "string" or not validModes[raw.Mode] then
		return nil, "invalid mode"
	end
	if type(raw.PartySize) ~= "number" or raw.PartySize ~= raw.PartySize then
		return nil, "invalid party size"
	end
	if type(raw.FriendsOnly) ~= "boolean" then
		return nil, "invalid friends-only flag"
	end

	return {
		Map = raw.Map :: MapName,
		Difficulty = raw.Difficulty :: Difficulty,
		Mode = raw.Mode :: Mode,
		PartySize = PartyConfig.clampPartySize(raw.PartySize),
		FriendsOnly = raw.FriendsOnly,
	}
end

return PartyConfig
