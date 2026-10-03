--!strict
-- Visual theme: "Overrun research station" (deep violet floor, pastel structures, bright enemies).
-- Colors are {r, g, b} 0..255 so tests can load this file.
local Theme = {
	Name = "Overrun Station",
	Floor = { 70, 40, 140 },
	FloorTrim = { 115, 80, 180 },
	Wall = { 220, 205, 240 },
	Metal = { 250, 248, 255 },
	MetalDark = { 90, 95, 105 }, -- weapons and lobby boards (white text sits on it)
	PropPastel = { 205, 185, 230 }, -- arena props and trims (V1 high-contrast look)
	NeonTeal = { 40, 220, 210 },
	NeonPurple = { 180, 70, 255 },
	NeonAmber = { 255, 170, 40 },
	NeonRed = { 255, 60, 60 },
	Swarm = { 150, 40, 170 }, -- enemy accent glow
	Coin = { 255, 210, 60 },
	LaneStripes = {
		{
			Angle = 0,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = { 40, 220, 210 },
			Material = "Neon",
			CanCollide = false,
		},
		{
			Angle = 90,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = { 255, 170, 40 },
			Material = "Neon",
			CanCollide = false,
		},
		{
			Angle = 180,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = { 40, 220, 210 },
			Material = "Neon",
			CanCollide = false,
		},
		{
			Angle = 270,
			Length = 68,
			Width = 5,
			Thickness = 0.1,
			Color = { 255, 170, 40 },
			Material = "Neon",
			CanCollide = false,
		},
	},
	-- enemy body palette per type (overrides Enemies.Defs Color for the rig)
	Enemy = {
		Walker = { Body = { 245, 245, 250 }, Accent = { 255, 90, 120 } },
		Runner = { Body = { 225, 240, 255 }, Accent = { 255, 230, 120 } },
		Flyer = { Body = { 220, 205, 250 }, Accent = { 150, 120, 255 } },
		Tank = { Body = { 210, 245, 220 }, Accent = { 120, 255, 140 } },
		Spitter = { Body = { 220, 250, 190 }, Accent = { 190, 255, 90 } },
		Brute = { Body = { 250, 220, 215 }, Accent = { 255, 40, 40 } },
		Queen = { Body = { 240, 210, 245 }, Accent = { 255, 90, 255 } },
		Warden = { Body = { 210, 230, 255 }, Accent = { 90, 200, 255 } },
	},
	Rarity = {
		Common = { 190, 190, 200 },
		Rare = { 70, 140, 255 },
		Epic = { 170, 80, 255 },
		Legendary = { 255, 170, 30 },
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
