--!strict
-- Visual theme: "Overrun research station" (bright floor, dark metal, teal + amber neon, purple swarm).
-- Colors are {r, g, b} 0..255 so tests can load this file.
local Theme = {
	Name = "Overrun Station",
	Floor = { 155, 158, 168 },
	FloorTrim = { 24, 25, 30 },
	Wall = { 30, 32, 40 },
	Metal = { 70, 74, 84 },
	MetalDark = { 45, 48, 56 },
	NeonTeal = { 40, 220, 210 },
	NeonAmber = { 255, 170, 40 },
	NeonRed = { 255, 60, 60 },
	Swarm = { 150, 40, 170 }, -- enemy accent glow
	Coin = { 255, 210, 60 },
	-- enemy body palette per type (overrides Enemies.Defs Color for the rig)
	Enemy = {
		Walker = { Body = { 125, 40, 60 }, Accent = { 255, 90, 120 } },
		Runner = { Body = { 115, 60, 5 }, Accent = { 255, 230, 120 } },
		Flyer = { Body = { 70, 55, 150 }, Accent = { 150, 120, 255 } },
		Tank = { Body = { 35, 80, 40 }, Accent = { 120, 255, 140 } },
		Spitter = { Body = { 45, 85, 15 }, Accent = { 190, 255, 90 } },
		Brute = { Body = { 135, 35, 30 }, Accent = { 255, 40, 40 } },
		Queen = { Body = { 120, 35, 115 }, Accent = { 255, 90, 255 } },
		Warden = { Body = { 40, 75, 145 }, Accent = { 90, 200, 255 } },
	},
	Rarity = {
		Common = { 190, 190, 200 },
		Rare = { 70, 140, 255 },
		Epic = { 170, 80, 255 },
		Legendary = { 255, 170, 30 },
	},
}
return Theme
