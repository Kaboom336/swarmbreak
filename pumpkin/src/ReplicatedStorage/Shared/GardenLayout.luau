--!strict
local Layout = {}
function Layout.calculate(width: number, height: number): any
	local buttonWidth = math.clamp(width - 216, 56, 145)
	local main =
		{ x = (width - buttonWidth) / 2, y = height - 68, width = buttonWidth, height = 56 }
	local burst = { x = main.x, y = main.y - 64, width = buttonWidth, height = 56 }
	if height < 244 then
		buttonWidth = math.clamp((width * 0.4 - 8) / 2, 56, 145)
		main =
			{ x = width / 2 - 4 - buttonWidth, y = height - 68, width = buttonWidth, height = 56 }
		burst = { x = width / 2 + 4, y = height - 68, width = buttonWidth, height = 56 }
	end
	return {
		hud = { x = 12, y = 12, width = math.min(width - 24, 460), height = 100 },
		main = main,
		burst = burst,
	}
end
return Layout
