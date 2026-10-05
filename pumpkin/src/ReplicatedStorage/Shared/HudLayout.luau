--!strict

export type Rect = { x: number, y: number, width: number, height: number }
export type RGB = { r: number, g: number, b: number }
export type Layout = {
	stats: Rect,
	distanceMeter: Rect,
	menu: Rect,
	menuButtons: { Rect },
	grow: Rect,
	wallProgress: Rect,
	multipliers: Rect,
	starterPack: Rect,
	zone: Rect,
	tutorial: Rect,
	growArrow: Rect,
	mobile: boolean,
}

local HudLayout = {}

HudLayout.CHIP_TEXT_COLOR = { r = 255, g = 255, b = 255 }

function HudLayout.isNearWhite(color: RGB): boolean
	return math.min(color.r, color.g, color.b) >= 240
end

local function rect(x: number, y: number, width: number, height: number): Rect
	return { x = x, y = y, width = width, height = height }
end

function HudLayout.compute(viewportWidth: number, viewportHeight: number): Layout
	assert(viewportWidth > 0 and viewportHeight > 0, "viewport must be positive")
	local mobile = viewportWidth <= 800 or viewportHeight <= 500
	local margin = if mobile then 8 else 18
	local cell = if mobile then 56 else 64
	local gap = if mobile then 6 else 8
	local menuWidth = cell * 2 + gap
	local menuHeight = cell * 4 + gap * 3
	local menuY = if mobile then margin else math.floor((viewportHeight - menuHeight) / 2)
	local menu = rect(margin, menuY, menuWidth, menuHeight)
	local menuButtons = {}
	for index = 1, 8 do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		table.insert(
			menuButtons,
			rect(menu.x + column * (cell + gap), menu.y + row * (cell + gap), cell, cell)
		)
	end

	local statsWidth = if mobile then 240 else 360
	local statsHeight = if mobile then 56 else 66
	local stats =
		rect(math.floor((viewportWidth - statsWidth) / 2), margin, statsWidth, statsHeight)
	local distanceWidth = if mobile then 180 else 240
	local distanceHeight = if mobile then 48 else 56
	local distanceMeter = rect(
		math.floor((viewportWidth - distanceWidth) / 2),
		stats.y + stats.height + 8,
		distanceWidth,
		distanceHeight
	)
	local growWidth = if mobile then 200 else 270
	local growHeight = if mobile then 64 else 78
	local growBottom = if mobile then 8 else 24
	local grow = rect(
		math.floor((viewportWidth - growWidth) / 2),
		viewportHeight - growBottom - growHeight,
		growWidth,
		growHeight
	)
	local wallWidth = if mobile then 260 else 360
	local wallHeight = if mobile then 36 else 42
	local wallX = math.floor((viewportWidth - wallWidth) / 2) + if mobile then 40 else 0
	local wallProgress = rect(wallX, grow.y - wallHeight - 8, wallWidth, wallHeight)
	local zoneWidth = if mobile then 130 else 220
	local zoneHeight = if mobile then 76 else 92
	local zone = rect(
		viewportWidth - margin - zoneWidth,
		math.floor((viewportHeight - zoneHeight) / 2),
		zoneWidth,
		zoneHeight
	)
	local multiplierHeight = if mobile then 84 else 152
	local multipliers
	if not mobile then
		multipliers =
			rect(margin, viewportHeight - margin - multiplierHeight, 150, multiplierHeight)
	elseif wallProgress.x - (menu.x + menu.width) - 16 >= 100 then
		multipliers = rect(
			menu.x + menu.width + 8,
			wallProgress.y - 8 - multiplierHeight,
			wallProgress.x - (menu.x + menu.width) - 16,
			multiplierHeight
		)
	else
		-- Narrow (portrait) screens: no room beside the wall bar, so stack the chips under the menu grid
		multipliers = rect(menu.x, menu.y + menu.height + 8, menu.width, multiplierHeight)
	end
	local starterPackWidth = 190
	local starterPackHeight = 58
	local starterPack = rect(
		viewportWidth - margin - starterPackWidth,
		viewportHeight - margin - starterPackHeight,
		starterPackWidth,
		starterPackHeight
	)
	local tutorialWidth = math.min(if mobile then 290 else 380, viewportWidth - 2 * margin)
	local tutorial = rect(
		math.floor((viewportWidth - tutorialWidth) / 2),
		distanceMeter.y + distanceMeter.height + 8,
		tutorialWidth,
		if mobile then 36 else 40
	)
	local growArrow = rect(math.floor((viewportWidth - 48) / 2), wallProgress.y - 44, 48, 40)

	return {
		stats = stats,
		distanceMeter = distanceMeter,
		menu = menu,
		menuButtons = menuButtons,
		grow = grow,
		wallProgress = wallProgress,
		multipliers = multipliers,
		starterPack = starterPack,
		zone = zone,
		tutorial = tutorial,
		growArrow = growArrow,
		mobile = mobile,
	}
end

function HudLayout.overlaps(first: Rect, second: Rect): boolean
	return first.x < second.x + second.width
		and second.x < first.x + first.width
		and first.y < second.y + second.height
		and second.y < first.y + first.height
end

function HudLayout.hasMargin(first: Rect, second: Rect, margin: number): boolean
	assert(margin >= 0, "margin must be non-negative")
	local expanded = rect(
		first.x - margin,
		first.y - margin,
		first.width + margin * 2,
		first.height + margin * 2
	)
	return not HudLayout.overlaps(expanded, second)
end

return HudLayout
