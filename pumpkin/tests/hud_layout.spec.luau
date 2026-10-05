--!strict
local HudLayout = load("HudLayout")

local function primaryRects(layout)
	local result = {
		layout.stats,
		layout.grow,
		layout.zone,
		layout.settings,
		layout.tutorial,
		layout.growArrow,
	}
	for _, button in layout.menuButtons do
		table.insert(result, button)
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
		{ width = 1920, height = 1080, name = "desktop" },
	}
do
	test("HUD has no overlap at " .. viewport.name, function()
		local layout = HudLayout.compute(viewport.width, viewport.height)
		local rects = primaryRects(layout)
		for index, current in rects do
			assertInside(current, viewport.width, viewport.height, "item " .. index)
			for otherIndex = index + 1, #rects do
				eq(
					HudLayout.overlaps(current, rects[otherIndex]),
					false,
					string.format("items %d and %d overlap", index, otherIndex)
				)
			end
		end
	end)
end

test("every mobile HUD button is at least 56 pixels", function()
	local layout = HudLayout.compute(667, 375)
	local buttons = { layout.grow, layout.settings }
	for _, button in layout.menuButtons do
		table.insert(buttons, button)
	end
	for index, button in buttons do
		eq(button.width >= 56, true, "button " .. index .. " width")
		eq(button.height >= 56, true, "button " .. index .. " height")
	end
end)
