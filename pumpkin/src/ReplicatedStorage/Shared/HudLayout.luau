--!strict

export type Rect = {
	x: number,
	y: number,
	width: number,
	height: number,
}

export type Layout = {
	stats: Rect,
	menu: Rect,
	menuButtons: { Rect },
	grow: Rect,
	zone: Rect,
	settings: Rect,
	tutorial: Rect,
	growArrow: Rect,
	mobile: boolean,
}

local HudLayout = {}

local function rect(x: number, y: number, width: number, height: number): Rect
	return { x = x, y = y, width = width, height = height }
end

function HudLayout.compute(viewportWidth: number, viewportHeight: number): Layout
	assert(viewportWidth > 0 and viewportHeight > 0, "viewport must be positive")
	local mobile = viewportWidth <= 800 or viewportHeight <= 500
	local margin = if mobile then 8 else 18
	local statsWidth = if mobile then 320 else 420
	local statsHeight = if mobile then 64 else 76
	local menuWidth = if mobile then 112 else 142
	local buttonHeight = if mobile then 56 else 58
	local buttonGap = if mobile then 6 else 7
	local menuHeight = buttonHeight * 5 + buttonGap * 4
	local zoneWidth = if mobile then 144 else 250
	local zoneHeight = if mobile then 84 else 104
	local growWidth = if mobile then 220 else 270
	local growHeight = if mobile then 68 else 78
	local growBottom = if mobile then 8 else 26

	local menu = rect(margin, math.floor((viewportHeight - menuHeight) / 2), menuWidth, menuHeight)
	local menuButtons = {}
	for index = 1, 5 do
		table.insert(
			menuButtons,
			rect(menu.x, menu.y + (index - 1) * (buttonHeight + buttonGap), menuWidth, buttonHeight)
		)
	end

	local stats =
		rect(math.floor((viewportWidth - statsWidth) / 2), margin, statsWidth, statsHeight)
	local zone = rect(
		viewportWidth - margin - zoneWidth,
		math.floor((viewportHeight - zoneHeight) / 2),
		zoneWidth,
		zoneHeight
	)
	local grow = rect(
		math.floor((viewportWidth - growWidth) / 2),
		viewportHeight - growBottom - growHeight,
		growWidth,
		growHeight
	)
	local settings = rect(viewportWidth - margin - 56, margin, 56, 56)
	local tutorialWidth = math.min(if mobile then 300 else 380, viewportWidth - 2 * margin)
	local tutorial = rect(
		math.floor((viewportWidth - tutorialWidth) / 2),
		stats.y + stats.height + 10,
		tutorialWidth,
		56
	)
	local growArrow = rect(math.floor((viewportWidth - 60) / 2), grow.y - 54, 60, 48)

	return {
		stats = stats,
		menu = menu,
		menuButtons = menuButtons,
		grow = grow,
		zone = zone,
		settings = settings,
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

return HudLayout
