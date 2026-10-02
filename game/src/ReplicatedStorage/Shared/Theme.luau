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
		Walker = { Body = { 90, 40, 60 }, Accent = { 255, 90, 120 } },
		Runner = { Body = { 200, 130, 30 }, Accent = { 255, 230, 120 } },
		Flyer = { Body = { 70, 60, 160 }, Accent = { 150, 120, 255 } },
		Tank = { Body = { 55, 70, 60 }, Accent = { 120, 255, 140 } },
		Spitter = { Body = { 80, 130, 50 }, Accent = { 190, 255, 90 } },
		Brute = { Body = { 60, 15, 20 }, Accent = { 255, 40, 40 } },
		Queen = { Body = { 110, 25, 100 }, Accent = { 255, 90, 255 } },
		Warden = { Body = { 20, 25, 60 }, Accent = { 90, 200, 255 } },
	},
	Rarity = {
		Common = { 190, 190, 200 },
		Rare = { 70, 140, 255 },
		Epic = { 170, 80, 255 },
		Legendary = { 255, 170, 30 },
	},
}
return Theme
