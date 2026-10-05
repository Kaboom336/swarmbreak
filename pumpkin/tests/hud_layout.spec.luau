--!strict
local HudLayout = load("HudLayout")

local function namedRects(layout)
	local result = {
		{ name = "stats", rect = layout.stats },
		{ name = "meter", rect = layout.distanceMeter },
		{ name = "GROW", rect = layout.grow },
		{ name = "wall progress", rect = layout.wallProgress },
		{ name = "chips", rect = layout.multipliers },
		{ name = "starter pack", rect = layout.starterPack },
		{ name = "zone", rect = layout.zone },
		{ name = "banner", rect = layout.tutorial },
		{ name = "grow arrow", rect = layout.growArrow },
	}
	for _, button in layout.menuButtons do
		table.insert(result, { name = "grid button", rect = button })
	end
	return result
end

local function assertInside(rect, width, height, name)
	eq(rect.x >= 0, true, name .. " left edge")
	eq(rect.y >= 0, true, name .. " top edge")
	eq(rect.x + rect.width <= width, true, name .. " right edge")
	eq(rect.y + rect.height <= height, true, name .. " bottom edge")
end

for _, viewport in
	{
		{ width = 667, height = 375, name = "mobile landscape" },
		{ width = 1399, height = 1080, name = "Studio desktop" },
		{ width = 1920, height = 1080, name = "desktop" },
	}
do
	test("HUD has no overlap at " .. viewport.name, function()
		local layout = HudLayout.compute(viewport.width, viewport.height)
		local items = namedRects(layout)
		for index, current in items do
			assertInside(current.rect, viewport.width, viewport.height, current.name)
			for otherIndex = index + 1, #items do
				eq(
					HudLayout.overlaps(current.rect, items[otherIndex].rect),
					false,
					string.format("%s and %s overlap", current.name, items[otherIndex].name)
				)
			end
		end
	end)
end

test("every mobile HUD button is at least 56 pixels", function()
	local layout = HudLayout.compute(667, 375)
	local buttons = { layout.grow, layout.starterPack }
	for _, button in layout.menuButtons do
		table.insert(buttons, button)
	end
	for index, button in buttons do
		eq(button.width >= 56, true, "button " .. index .. " width")
		eq(button.height >= 56, true, "button " .. index .. " height")
	end
end)

test("multiplier chip text is near-white", function()
	eq(HudLayout.isNearWhite(HudLayout.CHIP_TEXT_COLOR), true, "chip text contrast")
end)

for _, viewport in
	{
		{ width = 667, height = 375, name = "mobile landscape" },
		{ width = 1399, height = 1080, name = "Studio desktop" },
		{ width = 1920, height = 1080, name = "desktop" },
	}
do
	test("multiplier chips keep an 8 pixel margin at " .. viewport.name, function()
		local layout = HudLayout.compute(viewport.width, viewport.height)
		local settings = layout.menuButtons[7]
		local claim = layout.menuButtons[8]
		for _, neighbor in
			{
				{ name = "GROW", rect = layout.grow },
				{ name = "Settings", rect = settings },
				{ name = "Claim", rect = claim },
				{ name = "Starter Pack", rect = layout.starterPack },
			}
		do
			eq(
				HudLayout.hasMargin(layout.multipliers, neighbor.rect, 8),
				true,
				"chips need margin from " .. neighbor.name
			)
		end
	end)
end
