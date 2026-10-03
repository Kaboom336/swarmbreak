--!strict
-- Engine-free S0 UI tokens. Colors use 0..255 channels so this module is testable in Lune.
local Theme = require(script.Parent.Theme)

local UiTheme = {
	Font = {
		Title = "FredokaOne",
		Number = "FredokaOne",
		Body = "GothamBold",
		Strong = "GothamBold",
		Display = "FredokaOne",
		Banner = "LuckiestGuy",
	},
	Stroke = {
		Color = Theme.UiStroke,
		Thickness = 3,
		Transparency = 0,
	},
	Corner = {
		Small = 10,
		Medium = 14,
		Large = 14,
		Panel = 14,
		Round = 999,
	},
	Shadow = {
		Offset = 4,
		Transparency = 0.5,
		Color = { 0, 0, 0 },
	},
	Colors = {
		Text = Theme.Text,
		MutedText = Theme.OutpostShade,
		Stroke = Theme.UiStroke,
		Panel = Theme.UiPanel,
		PanelRaised = Theme.Chitin,
		Button = Theme.SignalOrange,
		ButtonHover = Theme.Loot,
		ButtonLip = Theme.ChitinDark,
		Success = Theme.Goo,
		Danger = Theme.Telegraph,
		Disabled = Theme.ChitinDark,
		Accent = Theme.SignalOrange,
		BarTrack = Theme.ChitinDark,
	},
	TextStyles = {
		Body = { TextColor = Theme.Text, StrokeColor = Theme.UiStroke },
		Muted = { TextColor = Theme.OutpostShade, StrokeColor = { 0, 0, 0 } },
		Accent = { TextColor = Theme.SignalOrange, StrokeColor = { 0, 0, 0 } },
	},
	Gradients = {
		Panel = {
			Rotation = 90,
			Colors = { Theme.Chitin, Theme.UiPanel },
		},
		Button = {
			Rotation = 90,
			Colors = { Theme.Loot, Theme.SignalOrange },
		},
		Banner = {
			Rotation = 0,
			Colors = { Theme.SignalOrange, Theme.Loot },
		},
	},
	Rarity = Theme.Rarity,
	Sizes = {
		ReferenceViewport = { Width = 1920, Height = 1080 },
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

function UiTheme.scaleFor(viewportX: number, viewportY: number): number
	return math.clamp(
		math.min(
			viewportX / UiTheme.Sizes.ReferenceViewport.Width,
			viewportY / UiTheme.Sizes.ReferenceViewport.Height
		),
		0.6,
		1.2
	)
end

return UiTheme
