--!strict

export type RGB = { r: number, g: number, b: number }
export type LabelStyle = {
	textColor: RGB,
	strokeColor: RGB,
	strokeThickness: number,
}

local Style = {}

local TEXT_COLOR = { r = 255, g = 250, b = 240 }
local STROKE_COLOR = { r = 42, g = 14, b = 61 }
local STROKE_THICKNESS = 2

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

return Style
