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

test("multiplier chips stay visible on a narrow portrait screen", function()
	local layout = HudLayout.compute(375, 667)
	local chips = layout.multipliers
	eq(chips.width >= 100, true, "chip width")
	eq(chips.x >= 0 and chips.x + chips.width <= 375, true, "chips inside width")
	eq(HudLayout.overlaps(chips, layout.menu), false, "chips clear of the menu")
	eq(HudLayout.overlaps(chips, layout.wallProgress), false, "chips clear of the wall bar")
end)

test("ride HUD has fixed speed, combo, and reward slots and hides secondary chrome", function()
	for _, viewport in { { 667, 375 }, { 1920, 1080 } } do
		local layout = HudLayout.compute(viewport[1], viewport[2], "ride")
		eq(layout.secondaryVisible, false, "ride secondary chrome")
		eq(HudLayout.overlaps(layout.distanceMeter, layout.combo), false, "speed and combo")
		eq(HudLayout.overlaps(layout.distanceMeter, layout.reward), false, "speed and reward")
		eq(HudLayout.overlaps(layout.combo, layout.reward), false, "combo and reward")
		eq(layout.distanceMeter.height >= 54, true, "two-line ride meter")
	end
end)

for _, viewport in
	{
		{ width = 667, height = 375, name = "mobile landscape" },
		{ width = 1399, height = 1080, name = "Studio desktop" },
	}
do
	test("ride controls stay clear at " .. viewport.name, function()
		local layout = HudLayout.compute(viewport.width, viewport.height, "ride")
		for name, control in { left = layout.steerLeft, right = layout.steerRight } do
			assertInside(control, viewport.width, viewport.height, "steer " .. name)
			eq(control.width, 72, "steer width")
			eq(control.height, 72, "steer height")
			eq(HudLayout.overlaps(control, layout.stats), false, "steer clears stats")
			eq(HudLayout.overlaps(control, layout.distanceMeter), false, "steer clears meter")
			eq(HudLayout.overlaps(control, layout.zone), false, "steer clears zone")
		end
		eq(HudLayout.overlaps(layout.steerLeft, layout.steerRight), false, "steer buttons")
	end)
end
