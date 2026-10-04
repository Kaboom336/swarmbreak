--!strict
export type Insets = { Left: number, Top: number, Right: number, Bottom: number }
export type Rect = { X: number, Y: number, Size: number }

local TouchLayout = {}

TouchLayout.MinimumSize = 56

function TouchLayout.layout(width: number, height: number, insets: Insets): { [string]: Rect }
	local left = insets.Left + 16
	local right = width - insets.Right - 16
	local bottom = height - insets.Bottom - 16
	return {
		Slide = { X = left, Y = bottom - 56, Size = 56 },
		Jump = { X = left + 64, Y = bottom - 56, Size = 56 },
		Dash = { X = left + 32, Y = bottom - 120, Size = 56 },
		Attack = { X = right - 64, Y = bottom - 64, Size = 64 },
		Ability1 = { X = right - 136, Y = bottom - 56, Size = 56 },
		Ability2 = { X = right - 200, Y = bottom - 56, Size = 56 },
		Ultimate = { X = right - 136, Y = bottom - 120, Size = 56 },
	}
end

return TouchLayout
