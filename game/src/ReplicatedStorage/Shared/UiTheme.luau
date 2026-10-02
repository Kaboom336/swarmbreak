--!strict
-- Engine-free UI tokens. Colors use 0..255 channels so this module is testable in Lune.
local Theme = require(script.Parent.Theme)

local darkStroke = { 8, 10, 16 }

local UiTheme = {
	Font = {
		Body = "Gotham",
		Strong = "GothamBold",
		Display = "GothamBlack",
	},
	Stroke = {
		Color = darkStroke,
		Thickness = 2,
		Transparency = 0.15,
	},
	Corner = {
		Small = 6,
		Medium = 8,
		Large = 12,
		Round = 999,
	},
	Colors = {
		Text = { 255, 255, 255 },
		MutedText = { 205, 212, 224 },
		Stroke = darkStroke,
		Panel = { 18, 18, 26 },
		PanelRaised = { 29, 32, 44 },
		Button = { 50, 90, 160 },
		ButtonHover = { 62, 112, 194 },
		Success = { 40, 160, 80 },
		Danger = { 160, 40, 40 },
		Disabled = { 60, 60, 70 },
		Accent = Theme.NeonAmber,
	},
	TextStyles = {
		Body = { TextColor = { 255, 255, 255 }, StrokeColor = darkStroke },
		Muted = { TextColor = { 205, 212, 224 }, StrokeColor = darkStroke },
		Accent = { TextColor = Theme.NeonAmber, StrokeColor = darkStroke },
	},
	Gradients = {
		Panel = {
			Rotation = 90,
			Colors = { { 35, 38, 52 }, { 18, 18, 26 } },
		},
		Button = {
			Rotation = 90,
			Colors = { { 70, 125, 210 }, { 38, 72, 135 } },
		},
		Banner = {
			Rotation = 0,
			Colors = { Theme.NeonAmber, { 255, 235, 150 } },
		},
	},
	Rarity = Theme.Rarity,
	Sizes = {
		ReferenceViewport = { Width = 1334, Height = 750 },
		MinimumTouchTarget = 44,
		Text = { Small = 14, Body = 16, Heading = 24, Banner = 48 },
		TouchTargets = {
			Button = { Width = 44, Height = 44 },
			Counter = { Width = 120, Height = 44 },
			Portrait = { Width = 64, Height = 64 },
		},
	},
	Motion = {
		Button = {
			HoverScale = 1.05,
			PressScale = 0.95,
			Seconds = 0.08,
			TweenProperties = { "Scale" },
		},
		CounterSeconds = 0.35,
		BannerSeconds = 0.2,
	},
}

return UiTheme
