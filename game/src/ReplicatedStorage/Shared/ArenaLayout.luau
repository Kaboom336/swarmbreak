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

function ArenaLayout.playArea(players: number): number
	if players < 4 then
		return 120 -- placeholder
	end
	return ArenaLayout.Floor
end

return ArenaLayout
