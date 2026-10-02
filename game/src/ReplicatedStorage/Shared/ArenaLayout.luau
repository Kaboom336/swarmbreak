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
	Kind: "Crate" | "LowWall",
	Width: number,
	Height: number,
	Depth: number,
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

-- The outer clusters leave the edge portals clear. The inner eight remain at least
-- 25 studs beyond the central ring edge, and every cluster is at least 18 studs apart.
ArenaLayout.Props = {
	{ Kind = "Crate", x = -48, z = -72, Width = 4, Height = 4, Depth = 4 },
	{ Kind = "LowWall", x = -24, z = -72, Width = 8, Height = 4, Depth = 4 },
	{ Kind = "Crate", x = 24, z = -72, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 48, z = -72, Width = 8, Height = 3, Depth = 4 },

	{ Kind = "LowWall", x = 72, z = -48, Width = 4, Height = 4, Depth = 8 },
	{ Kind = "Crate", x = 72, z = -24, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 72, z = 24, Width = 4, Height = 3, Depth = 8 },
	{ Kind = "Crate", x = 72, z = 48, Width = 4, Height = 4, Depth = 4 },

	{ Kind = "Crate", x = 48, z = 72, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = 24, z = 72, Width = 8, Height = 3, Depth = 4 },
	{ Kind = "Crate", x = -24, z = 72, Width = 4, Height = 4, Depth = 4 },
	{ Kind = "LowWall", x = -48, z = 72, Width = 8, Height = 4, Depth = 4 },

	{ Kind = "LowWall", x = -72, z = 48, Width = 4, Height = 3, Depth = 8 },
	{ Kind = "Crate", x = -72, z = 24, Width = 4, Height = 4, Depth = 4 },
	{ Kind = "LowWall", x = -72, z = -24, Width = 4, Height = 4, Depth = 8 },
	{ Kind = "Crate", x = -72, z = -48, Width = 4, Height = 5, Depth = 4 },

	{ Kind = "Crate", x = -40, z = -40, Width = 4, Height = 4, Depth = 4 },
	{ Kind = "LowWall", x = 40, z = -40, Width = 8, Height = 3, Depth = 4 },
	{ Kind = "Crate", x = 40, z = 40, Width = 4, Height = 5, Depth = 4 },
	{ Kind = "LowWall", x = -40, z = 40, Width = 8, Height = 4, Depth = 4 },

	{ Kind = "LowWall", x = 0, z = -48, Width = 8, Height = 3, Depth = 4 },
	{ Kind = "Crate", x = 48, z = 0, Width = 4, Height = 4, Depth = 4 },
	{ Kind = "LowWall", x = 0, z = 48, Width = 8, Height = 4, Depth = 4 },
	{ Kind = "Crate", x = -48, z = 0, Width = 4, Height = 5, Depth = 4 },
} :: { Prop }

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
