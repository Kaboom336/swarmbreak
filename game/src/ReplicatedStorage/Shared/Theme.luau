--!strict
-- S0 art-bible palette. Colors are {r, g, b} 0..255 so pure tests can load this file.
local OUTPOST_CREAM = { 255, 233, 201 }
local OUTPOST_SHADE = { 222, 190, 150 }
local SIGNAL_ORANGE = { 255, 138, 43 }
local CHITIN = { 91, 47, 147 }
local CHITIN_DARK = { 62, 31, 107 }
local GOO = { 46, 230, 197 }
local HERO = { 61, 165, 255 }
local LOOT = { 255, 210, 63 }
local TELEGRAPH = { 255, 61, 110 }

local Theme = {
	Name = "Swarm Break Dusk",
	OutpostCream = OUTPOST_CREAM,
	OutpostShade = OUTPOST_SHADE,
	SignalOrange = SIGNAL_ORANGE,
	Chitin = CHITIN,
	ChitinDark = CHITIN_DARK,
	Goo = GOO,
	Hero = HERO,
	Loot = LOOT,
	Telegraph = TELEGRAPH,
	UiPanel = { 42, 33, 86 },
	UiStroke = { 74, 60, 140 },
	Text = { 255, 247, 236 },
	SkyHorizon = { 255, 179, 122 },
	SkyTop = { 122, 79, 214 },

	-- Compatibility names used by the existing builders, now mapped to S0 tokens.
	Floor = OUTPOST_CREAM,
	FloorTrim = SIGNAL_ORANGE,
	Wall = OUTPOST_CREAM,
	Metal = OUTPOST_SHADE,
	MetalDark = CHITIN_DARK,
	PropPastel = OUTPOST_SHADE,
	NeonTeal = GOO,
	NeonPurple = CHITIN,
	NeonAmber = SIGNAL_ORANGE,
	NeonRed = TELEGRAPH,
	Swarm = CHITIN,
	Coin = LOOT,
	LaneStripes = {
		{
			Angle = 0,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = SIGNAL_ORANGE,
			Material = "SmoothPlastic",
			CanCollide = false,
		},
		{
			Angle = 90,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = OUTPOST_SHADE,
			Material = "SmoothPlastic",
			CanCollide = false,
		},
		{
			Angle = 180,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = SIGNAL_ORANGE,
			Material = "SmoothPlastic",
			CanCollide = false,
		},
		{
			Angle = 270,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = OUTPOST_SHADE,
			Material = "SmoothPlastic",
			CanCollide = false,
		},
	},
	-- Enemies stay darker than the cream floor; only eyes and veins use neon Goo.
	Enemy = {
		Walker = { Body = CHITIN, Accent = GOO },
		Runner = { Body = CHITIN_DARK, Accent = GOO },
		Flyer = { Body = CHITIN, Accent = GOO },
		Tank = { Body = CHITIN_DARK, Accent = GOO },
		Spitter = { Body = CHITIN, Accent = GOO },
		Brute = { Body = CHITIN_DARK, Accent = GOO },
		Queen = { Body = CHITIN, Accent = GOO },
		Warden = { Body = CHITIN_DARK, Accent = GOO },
	},
	Boss = {
		["Big Brute"] = { Fill = CHITIN_DARK, Accent = SIGNAL_ORANGE, Outline = CHITIN },
		["Swarm Queen"] = { Fill = CHITIN, Accent = GOO, Outline = CHITIN_DARK },
		["Sky King"] = { Fill = CHITIN_DARK, Accent = HERO, Outline = CHITIN },
	},
	Rarity = {
		Common = OUTPOST_SHADE,
		Rare = HERO,
		Epic = CHITIN,
		Legendary = LOOT,
	},
}

local function linearChannel(value: number): number
	local normalized = value / 255
	if normalized <= 0.04045 then
		return normalized / 12.92
	end
	return ((normalized + 0.055) / 1.055) ^ 2.4
end

function Theme.relativeLuminance(color: { number }): number
	return 0.2126 * linearChannel(color[1])
		+ 0.7152 * linearChannel(color[2])
		+ 0.0722 * linearChannel(color[3])
end

function Theme.luminanceContrast(first: { number }, second: { number }): number
	return math.abs(Theme.relativeLuminance(first) - Theme.relativeLuminance(second))
end

return Theme
