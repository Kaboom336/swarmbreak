--!strict
-- Pure data for the arenas that can be selected before a run starts.

export type Position = {
	x: number,
	z: number,
}

export type Bounds = {
	Width: number,
	Depth: number,
}

export type MapDefinition = {
	Name: string,
	LightingPreset: string,
	Bounds: Bounds,
	Spawns: { Position },
	Props: { string },
	Boss: string,
	FloorColor: { number },
}

local Maps = {}

Maps.DefaultName = "Station Deck"

Maps.All = {
	{
		Name = "Station Deck",
		LightingPreset = "Station",
		Bounds = { Width = 160, Depth = 160 },
		Spawns = {
			{ x = -58, z = -58 },
			{ x = 58, z = -58 },
			{ x = 58, z = 58 },
			{ x = -58, z = 58 },
			{ x = 0, z = -72 },
			{ x = 72, z = 0 },
			{ x = 0, z = 72 },
			{ x = -72, z = 0 },
		},
		Props = { "Low Ledges", "Pillars", "Crystal Clusters", "Hive Goo" },
		Boss = "Brute",
		FloorColor = { 155, 158, 168 },
	},
	{
		Name = "Hive Caves",
		LightingPreset = "NestInterior",
		Bounds = { Width = 160, Depth = 160 },
		Spawns = {
			{ x = -60, z = -52 },
			{ x = 60, z = -52 },
			{ x = 60, z = 52 },
			{ x = -60, z = 52 },
			{ x = -18, z = -70 },
			{ x = 70, z = 18 },
			{ x = 18, z = 70 },
			{ x = -70, z = -18 },
		},
		Props = { "Purple Crystals", "Teal Crystals", "Rock Columns" },
		Boss = "Queen",
		FloorColor = { 190, 180, 210 },
	},
	{
		Name = "Overgrown Hangar",
		LightingPreset = "Base",
		Bounds = { Width = 160, Depth = 160 },
		Spawns = {
			{ x = -64, z = -48 },
			{ x = 64, z = -48 },
			{ x = 64, z = 48 },
			{ x = -64, z = 48 },
			{ x = -24, z = -70 },
			{ x = 70, z = 24 },
			{ x = 24, z = 70 },
			{ x = -70, z = -24 },
		},
		Props = { "Hanging Vines", "Planter Boxes", "Sunbeams" },
		Boss = "Warden",
		FloorColor = { 185, 195, 175 },
	},
} :: { MapDefinition }

local byName: { [string]: MapDefinition } = {}
for _, map in Maps.All do
	byName[map.Name] = map
end

function Maps.get(name: string?): MapDefinition
	return byName[name or ""] or byName[Maps.DefaultName]
end

return Maps
