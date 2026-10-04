--!strict
-- Outpost 9 v2 layout data. All measurements are placeholder studs until playtesting.

export type Position = {
	x: number,
	z: number,
}

export type Bunker = Position & {
	Width: number,
	Height: number,
	Depth: number,
}

export type Prop = Position & {
	Kind: "Pillar" | "LowWall",
	Width: number,
	Height: number,
	Depth: number,
}

export type CrystalCluster = Position & {
	Name: string,
}

export type Beacon = Position & {
	Name: string,
	Width: number,
	Height: number,
	Color: { number },
}

export type Zone = Position & {
	Id: string,
	Name: string,
	FirstWave: number,
	LastWave: number,
	Width: number,
	Depth: number,
}

export type ZoneSpawn = Position & {
	Name: string,
	ZoneId: string,
}

export type Bridge = {
	Id: string,
	FromZone: string,
	ToZone: string,
	OpenWave: number,
	x: number,
	z: number,
	Width: number,
	Depth: number,
}

local ArenaLayout = {}

ArenaLayout.Floor = 160 -- placeholder

ArenaLayout.Spawns = {
	{ x = -58, z = -58 },
	{ x = 58, z = -58 },
	{ x = 58, z = 58 },
	{ x = -58, z = 58 },
	{ x = 0, z = -72 },
	{ x = 72, z = 0 },
	{ x = 0, z = 72 },
	{ x = -72, z = 0 },
} :: { Position }

ArenaLayout.Bunkers = {
	{ x = -66, z = -66, Width = 20, Height = 6, Depth = 20 },
	{ x = 66, z = -66, Width = 20, Height = 6, Depth = 20 },
	{ x = 66, z = 66, Width = 20, Height = 6, Depth = 20 },
	{ x = -66, z = 66, Width = 20, Height = 6, Depth = 20 },
} :: { Bunker }

ArenaLayout.Ring = {
	OuterDiameter = 44, -- placeholder
	Height = 5, -- placeholder
	Thickness = 3, -- placeholder
	Gap = 10, -- placeholder
}

-- Cover stays in the outer ring so the central 90 by 90 fight space remains open.
-- Low walls are short enough to read as ledges; pillars provide the vertical shapes.
ArenaLayout.Props = {
	{ Kind = "Pillar", x = -48, z = -64, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = -28, z = -64, Width = 8, Height = 3, Depth = 4 },
	{ Kind = "Pillar", x = -8, z = -64, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 12, z = -64, Width = 8, Height = 3, Depth = 4 },
	{ Kind = "Pillar", x = 32, z = -64, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 52, z = -64, Width = 8, Height = 3, Depth = 4 },

	{ Kind = "Pillar", x = 64, z = -48, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 64, z = -28, Width = 4, Height = 3, Depth = 8 },
	{ Kind = "Pillar", x = 64, z = -8, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 64, z = 12, Width = 4, Height = 3, Depth = 8 },
	{ Kind = "Pillar", x = 64, z = 32, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 64, z = 52, Width = 4, Height = 3, Depth = 8 },

	{ Kind = "Pillar", x = 48, z = 64, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 28, z = 64, Width = 8, Height = 3, Depth = 4 },
	{ Kind = "Pillar", x = 8, z = 64, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = -12, z = 64, Width = 8, Height = 3, Depth = 4 },
	{ Kind = "Pillar", x = -32, z = 64, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = -52, z = 64, Width = 8, Height = 3, Depth = 4 },

	{ Kind = "Pillar", x = -64, z = 48, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = -64, z = 28, Width = 4, Height = 3, Depth = 8 },
	{ Kind = "Pillar", x = -64, z = 8, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = -64, z = -12, Width = 4, Height = 3, Depth = 8 },
	{ Kind = "Pillar", x = -64, z = -32, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = -64, z = -52, Width = 4, Height = 3, Depth = 8 },
} :: { Prop }

ArenaLayout.CrystalClusters = {
	{ Name = "NorthWest", x = -66, z = -66 },
	{ Name = "NorthEast", x = 66, z = -66 },
	{ Name = "SouthEast", x = 66, z = 66 },
	{ Name = "SouthWest", x = -66, z = 66 },
	{ Name = "NorthPortal", x = 7, z = -72 },
	{ Name = "EastPortal", x = 72, z = 7 },
	{ Name = "SouthPortal", x = -7, z = 72 },
	{ Name = "WestPortal", x = -72, z = -7 },
} :: { CrystalCluster }

ArenaLayout.Beacons = {
	{ Name = "North", x = 0, z = -76, Width = 6, Height = 0.15, Color = { 40, 220, 210 } },
	{ Name = "East", x = 76, z = 0, Width = 6, Height = 0.15, Color = { 255, 170, 40 } },
	{ Name = "South", x = 0, z = 76, Width = 6, Height = 0.15, Color = { 40, 220, 210 } },
	{ Name = "West", x = -76, z = 0, Width = 6, Height = 0.15, Color = { 255, 170, 40 } },
} :: { Beacon }

-- S3 Outpost 9: three equal sky islands, separated by forty-stud bridge gaps.
-- Their combined walkable area is exactly three times the former 160 by 160 deck.
ArenaLayout.Zones = {
	{
		Id = "LandingPad",
		Name = "Landing Pad",
		FirstWave = 1,
		LastWave = 5,
		x = 0,
		z = 0,
		Width = 160,
		Depth = 160,
	},
	{
		Id = "Refinery",
		Name = "Refinery",
		FirstWave = 6,
		LastWave = 10,
		x = 200,
		z = 0,
		Width = 160,
		Depth = 160,
	},
	{
		Id = "HiveCore",
		Name = "Hive Core",
		FirstWave = 11,
		LastWave = 15,
		x = 400,
		z = 0,
		Width = 160,
		Depth = 160,
	},
} :: { Zone }

ArenaLayout.ZoneSpawns = {
	{ Name = "LandingGateNorth", ZoneId = "LandingPad", x = -55, z = -65 },
	{ Name = "LandingGateSouth", ZoneId = "LandingPad", x = -55, z = 65 },
	{ Name = "LandingGateWest", ZoneId = "LandingPad", x = -70, z = 0 },
	{ Name = "RefineryGateNorth", ZoneId = "Refinery", x = 200, z = -68 },
	{ Name = "RefineryGateSouth", ZoneId = "Refinery", x = 200, z = 68 },
	{ Name = "RefineryGateEast", ZoneId = "Refinery", x = 268, z = 0 },
	{ Name = "HiveGateNorth", ZoneId = "HiveCore", x = 400, z = -68 },
	{ Name = "HiveGateSouth", ZoneId = "HiveCore", x = 400, z = 68 },
	{ Name = "HiveGateEast", ZoneId = "HiveCore", x = 468, z = 0 },
} :: { ZoneSpawn }

ArenaLayout.Bridges = {
	{
		Id = "LandingToRefinery",
		FromZone = "LandingPad",
		ToZone = "Refinery",
		OpenWave = 6,
		x = 100,
		z = 0,
		Width = 40,
		Depth = 18,
	},
	{
		Id = "RefineryToHive",
		FromZone = "Refinery",
		ToZone = "HiveCore",
		OpenWave = 11,
		x = 300,
		z = 0,
		Width = 40,
		Depth = 18,
	},
} :: { Bridge }

ArenaLayout.JumpPads = {
	{ Name = "RefineryLower", x = 160, z = 38, Velocity = { 54, 68, 0 } },
	{ Name = "RefineryLoop", x = 240, z = -42, Velocity = { -45, 72, 8 } },
}

ArenaLayout.DashGaps = {
	{ Name = "RefineryGap", x = 200, z = 24, Width = 16 },
}

ArenaLayout.Landmarks = {
	{ Name = "RadioMast", ZoneId = "LandingPad", x = -48, z = -42, Kind = "OrangeBeacon" },
	{ Name = "RefineryTower", ZoneId = "Refinery", x = 232, z = -42, Kind = "Tower" },
	{ Name = "NestCore", ZoneId = "HiveCore", x = 448, z = 0, Kind = "GooCore" },
}

function ArenaLayout.zoneContains(zone: Zone, position: Position): boolean
	return math.abs(position.x - zone.x) <= zone.Width / 2
		and math.abs(position.z - zone.z) <= zone.Depth / 2
end

function ArenaLayout.zoneForWave(wave: number): Zone
	for _, zone in ArenaLayout.Zones do
		if wave >= zone.FirstWave and wave <= zone.LastWave then
			return zone
		end
	end
	return ArenaLayout.Zones[#ArenaLayout.Zones]
end

function ArenaLayout.spawnsForWave(wave: number): { ZoneSpawn }
	local zone = ArenaLayout.zoneForWave(wave)
	local result = {}
	for _, spawn in ArenaLayout.ZoneSpawns do
		if spawn.ZoneId == zone.Id then
			table.insert(result, spawn)
		end
	end
	return result
end

function ArenaLayout.bridgeOpenWave(id: string): number?
	for _, bridge in ArenaLayout.Bridges do
		if bridge.Id == id then
			return bridge.OpenWave
		end
	end
	return nil
end

function ArenaLayout.openBridges(wave: number): { Bridge }
	local result = {}
	for _, bridge in ArenaLayout.Bridges do
		if wave >= bridge.OpenWave then
			table.insert(result, bridge)
		end
	end
	return result
end

local gridCells = {}
for _, zone in ArenaLayout.Zones do
	for x = zone.x - 72, zone.x + 72, 16 do
		for z = zone.z - 72, zone.z + 72, 16 do
			table.insert(gridCells, { x = x, z = z, ZoneId = zone.Id })
		end
	end
end
ArenaLayout.WalkableGrid = {
	CellSize = 16,
	Cells = gridCells,
}

function ArenaLayout.playArea(players: number): number
	if players < 4 then
		return 120 -- placeholder
	end
	return ArenaLayout.Floor
end

return ArenaLayout
