--!strict

export type RGB = { r: number, g: number, b: number }
export type LabelStyle = {
	textColor: RGB,
	strokeColor: RGB,
	strokeThickness: number,
}
export type TextToken = {
	minimumSize: number,
	strokeThickness: number,
	maxCharacters: number,
}
export type PopTier = {
	startScale: number,
	overshootScale: number,
	contactSeconds: number,
	settleSeconds: number,
}

local Style = {}

Style.Palette = {
	orange = { r = 255, g = 107, b = 0 },
	purple = { r = 139, g = 44, b = 255 },
	lime = { r = 183, g = 255, b = 26 },
	cyan = { r = 0, g = 217, b = 255 },
	magenta = { r = 255, g = 45, b = 149 },
	yellow = { r = 255, g = 212, b = 0 },
	ink = { r = 23, g = 18, b = 37 },
	white = { r = 255, g = 255, b = 255 },
} :: { [string]: RGB }

Style.Text = {
	hero = { minimumSize = 28, strokeThickness = 3, maxCharacters = 18 },
	action = { minimumSize = 18, strokeThickness = 3, maxCharacters = 24 },
	body = { minimumSize = 14, strokeThickness = 3, maxCharacters = 42 },
} :: { [string]: TextToken }

Style.Pop = {
	micro = { startScale = 0.9, overshootScale = 1.08, contactSeconds = 0.06, settleSeconds = 0.14 },
	reward = { startScale = 0.62, overshootScale = 1.16, contactSeconds = 0.1, settleSeconds = 0.2 },
	rare = { startScale = 0.45, overshootScale = 1.24, contactSeconds = 0.14, settleSeconds = 0.28 },
} :: { [string]: PopTier }

Style.Button = {
	pressPixels = 5,
	pressSeconds = 0.055,
	reboundSeconds = 0.17,
	shineSeconds = 0.42,
}

local TEXT_COLOR = Style.Palette.white
local STROKE_COLOR = Style.Palette.ink
local STROKE_THICKNESS = Style.Text.body.strokeThickness

function Style.label(): LabelStyle
	return {
		textColor = { r = TEXT_COLOR.r, g = TEXT_COLOR.g, b = TEXT_COLOR.b },
		strokeColor = { r = STROKE_COLOR.r, g = STROKE_COLOR.g, b = STROKE_COLOR.b },
		strokeThickness = STROKE_THICKNESS,
	}
end

function Style.isNearWhite(color: RGB): boolean
	return math.min(color.r, color.g, color.b) >= 240
end

function Style.textToken(name: string): TextToken
	local token = Style.Text[name]
	assert(token ~= nil, "unknown text token")
	return {
		minimumSize = token.minimumSize,
		strokeThickness = token.strokeThickness,
		maxCharacters = token.maxCharacters,
	}
end

function Style.popTier(name: string, reducedMotion: boolean?): PopTier
	local tier = Style.Pop[name]
	assert(tier ~= nil, "unknown pop tier")
	if reducedMotion then
		return {
			startScale = 0.96,
			overshootScale = 1.02,
			contactSeconds = tier.contactSeconds,
			settleSeconds = tier.settleSeconds,
		}
	end
	return {
		startScale = tier.startScale,
		overshootScale = tier.overshootScale,
		contactSeconds = tier.contactSeconds,
		settleSeconds = tier.settleSeconds,
	}
end

return Style
