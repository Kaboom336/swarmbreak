--!strict
-- Compatibility view of campaign maps for arena systems written before S3.
local ArenaLayout = require(script.Parent.ArenaLayout)
local Campaign = require(script.Parent.Campaign)

export type Position = { x: number, z: number }
export type Bounds = { x: number?, z: number?, Width: number, Depth: number }
export type MapDefinition = {
	Id: string,
	Name: string,
	LightingPreset: string,
	Bounds: Bounds,
	Spawns: { Position },
	Props: { string },
	Boss: string,
	FloorColor: { number },
}

local Maps = {}

Maps.DefaultName = Campaign.get(Campaign.DefaultId).Name
Maps.All = {} :: { MapDefinition }

local outpostSpawns = {}
for _, spawn in ArenaLayout.ZoneSpawns do
	table.insert(outpostSpawns, { x = spawn.x, z = spawn.z })
end

for _, campaignMap in Campaign.All do
	local isOutpost = campaignMap.Id == Campaign.DefaultId
	table.insert(Maps.All, {
		Id = campaignMap.Id,
		Name = campaignMap.Name,
		LightingPreset = campaignMap.LightingPreset,
		Bounds = if isOutpost
			then { x = 200, z = 0, Width = 560, Depth = 160 }
			else { x = 0, z = 0, Width = 160, Depth = 160 },
		Spawns = if isOutpost
			then outpostSpawns
			else {
				{ x = -58, z = -58 },
				{ x = 58, z = -58 },
				{ x = 58, z = 58 },
				{ x = -58, z = 58 },
				{ x = 0, z = -70 },
				{ x = 0, z = 70 },
			},
		Props = if isOutpost
			then { "Radio Mast", "Refinery Tower", "Nest Core", "Bridges" }
			else { "Coming Soon" },
		Boss = campaignMap.BossKey,
		FloorColor = { 255, 233, 201 },
	})
end

local byName: { [string]: MapDefinition } = {}
for _, map in Maps.All do
	byName[map.Name] = map
	byName[map.Id] = map
end

function Maps.get(name: string?): MapDefinition
	return byName[name or ""] or byName[Maps.DefaultName]
end

return Maps
