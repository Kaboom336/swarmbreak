--!strict
-- Pure presentation data and reveal timing for level-up cards.
local LevelUp = require(script.Parent.LevelUp)
local Theme = require(script.Parent.Theme)

export type Color = { number }
export type RarityStyle = {
	Background: { Color },
	Stroke: Color,
	Text: Color,
	Shine: boolean,
}

local CardStyle = {}

CardStyle.WorldDimTransparency = 0.75
CardStyle.Width = 220
CardStyle.Height = 276
CardStyle.NameTextSize = 22
CardStyle.EffectTextSize = 16
CardStyle.MinimumContrast = 4.5
CardStyle.StrokeThickness = 3
CardStyle.SelectedStrokeThickness = 9
CardStyle.SelectedStroke = Theme.Text
CardStyle.EvolveStroke = Theme.Loot

CardStyle.CategoryColors = {
	WEAPON = Theme.SignalOrange,
	PASSIVE = Theme.Hero,
	ELEMENT = Theme.Goo,
	UPGRADE = Theme.Loot,
}

CardStyle.KeywordColors = {
	fire = "#FF8A2B",
	chain = "#2EE6C5",
	pierce = "#FFD23F",
	slow = "#3DA5FF",
	heal = "#2EE6C5",
	damage = "#FF3D6E",
	health = "#2EE6C5",
	speed = "#3DA5FF",
	range = "#FFD23F",
	orb = "#5B2F93",
	pellet = "#FF8A2B",
	coins = "#FFD23F",
	gems = "#2EE6C5",
}

CardStyle.Rarities = {
	Common = {
		Background = { Theme.UiPanel, Theme.ChitinDark },
		Stroke = Theme.OutpostShade,
		Text = Theme.Text,
		Shine = false,
	},
	Rare = {
		Background = { Theme.UiPanel, Theme.ChitinDark },
		Stroke = Theme.Hero,
		Text = Theme.Text,
		Shine = false,
	},
	Epic = {
		Background = { Theme.UiPanel, Theme.ChitinDark },
		Stroke = Theme.Chitin,
		Text = Theme.Text,
		Shine = true,
	},
	Legendary = {
		Background = { Theme.UiPanel, Theme.ChitinDark },
		Stroke = Theme.Loot,
		Text = Theme.Text,
		Shine = true,
	},
} :: { [string]: RarityStyle }

CardStyle.Icons = {
	Damage = "DMG",
	FireRate = "RPM",
	Range = "RNG",
	Health = "HP",
	Speed = "SPD",
	Magnet = "MAG",
	Element = "ELEM",
}

CardStyle.UpgradeFamilies = {
	Sharp = "Damage",
	Trigger = "FireRate",
	["Quick Feet"] = "Speed",
	["Thick Skin"] = "Health",
	Greed = "Magnet",
	Lucky = "Magnet",
	["Second Wind"] = "Health",
	["Fast Dash"] = "Speed",
	Magnet = "Magnet",
	["Long Barrel"] = "Range",
	["Double Tap"] = "FireRate",
	["Wide Swing"] = "Range",
	["Extra Orb"] = "Damage",
} :: { [string]: string }

local function linearChannel(channel: number): number
	local normalized = math.clamp(channel, 0, 255) / 255
	return if normalized <= 0.04045
		then normalized / 12.92
		else ((normalized + 0.055) / 1.055) ^ 2.4
end

local function luminance(color: Color): number
	return 0.2126 * linearChannel(color[1])
		+ 0.7152 * linearChannel(color[2])
		+ 0.0722 * linearChannel(color[3])
end

function CardStyle.contrastRatio(a: Color, b: Color): number
	local lighter = math.max(luminance(a), luminance(b))
	local darker = math.min(luminance(a), luminance(b))
	return (lighter + 0.05) / (darker + 0.05)
end

function CardStyle.styleFor(rarity: string): RarityStyle
	return CardStyle.Rarities[rarity] or CardStyle.Rarities.Common
end

function CardStyle.strokeFor(rarity: string, isEvolution: boolean?): Color
	return if isEvolution then CardStyle.EvolveStroke else CardStyle.styleFor(rarity).Stroke
end

function CardStyle.iconFor(upgradeId: string, elementName: string?): string?
	local family = if elementName then "Element" else CardStyle.UpgradeFamilies[upgradeId]
	return if family then CardStyle.Icons[family] else nil
end

function CardStyle.categoryFor(kind: string, elementName: string?): string
	if elementName then
		return "ELEMENT"
	elseif kind == "Weapon" then
		return "WEAPON"
	elseif kind == "Utility" then
		return "PASSIVE"
	end
	return "UPGRADE"
end

function CardStyle.richEffect(effect: string): string
	local escaped = effect:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return escaped:gsub("(%a+)", function(word: string): string
		local color = CardStyle.KeywordColors[string.lower(word)]
		return if color then string.format('<font color="%s">%s</font>', color, word) else word
	end)
end

function CardStyle.revealSchedule(count: number): { { Index: number, Delay: number } }
	local schedule = {}
	for index = 1, math.max(0, math.floor(count)) do
		table.insert(schedule, {
			Index = index,
			Delay = (index - 1) * LevelUp.CardFlipSeconds,
		})
	end
	return schedule
end

function CardStyle.totalRevealTime(count: number): number
	if count <= 0 then
		return 0
	end
	return math.max(0, math.floor(count)) * LevelUp.CardFlipSeconds
end

return CardStyle
