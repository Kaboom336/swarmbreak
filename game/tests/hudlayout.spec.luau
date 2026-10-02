local HudLayout = load("HudLayout")

local VIEWPORTS = {
	{ 640, 360 },
	{ 844, 390 },
	{ 1280, 720 },
	{ 1920, 1080 },
}

local PANEL_NAMES = { "quest", "settings", "shop", "hotbar", "wave", "health" }

local function overlaps(a, b)
	return not (a.x + a.w <= b.x or b.x + b.w <= a.x or a.y + a.h <= b.y or b.y + b.h <= a.y)
end

test("panel rectangles stay inside each required viewport", function()
	for _, viewport in VIEWPORTS do
		local width, height = viewport[1], viewport[2]
		local rects = HudLayout.rects(width, height, "touch")
		for _, name in PANEL_NAMES do
			local rect = rects[name]
			assert(rect ~= nil, name .. " rectangle exists")
			assert(rect.w > 0 and rect.h > 0, name .. " has positive size")
			assert(rect.x >= 0 and rect.y >= 0, name .. " starts inside the viewport")
			assert(rect.x + rect.w <= width, name .. " fits horizontally")
			assert(rect.y + rect.h <= height, name .. " fits vertically")
		end
	end
end)

test("panel rectangles are pairwise disjoint", function()
	for _, viewport in VIEWPORTS do
		local rects = HudLayout.rects(viewport[1], viewport[2], "touch")
		for first = 1, #PANEL_NAMES do
			for second = first + 1, #PANEL_NAMES do
				local firstName = PANEL_NAMES[first]
				local secondName = PANEL_NAMES[second]
				assert(
					not overlaps(rects[firstName], rects[secondName]),
					firstName .. " overlaps " .. secondName
				)
			end
		end
	end
end)

test("touch button height remains at least the platform minimum", function()
	for _, viewport in VIEWPORTS do
		local scale = HudLayout.scaleFor(viewport[1], viewport[2], "touch")
		local renderedHeight = HudLayout.buttonHeightFor(scale, "touch") * scale
		assert(renderedHeight >= HudLayout.MinButtonHeight, "touch target is too short")
	end
end)

test("scale is monotonic and clamped", function()
	local heights = { 200, 360, 390, 720, 1080, 1600 }
	local previous = HudLayout.MinScale
	for _, height in heights do
		local scale = HudLayout.scaleFor(1280, height, "keyboard")
		assert(scale >= previous, "scale decreased as viewport height grew")
		assert(scale >= HudLayout.MinScale, "scale fell below the minimum")
		assert(scale <= HudLayout.MaxScale, "scale exceeded the maximum")
		previous = scale
	end
	eq(HudLayout.scaleFor(640, 100, "touch"), HudLayout.MinScale, "minimum clamp")
	eq(HudLayout.scaleFor(1920, 2000, "keyboard"), HudLayout.MaxScale, "maximum clamp")
end)

test("side icon hotkeys are unique", function()
	local expectedColumns = {
		{ "Inventory", "Kits", "Quests", "Shop", "Settings" },
		{ "Codes", "Pass", "Rewards", "Guides" },
	}
	local seen = {}
	for columnIndex, column in { HudLayout.IconColumns.left, HudLayout.IconColumns.right } do
		eq(#column, #expectedColumns[columnIndex], "icon column length")
		for entryIndex, entry in column do
			eq(entry.name, expectedColumns[columnIndex][entryIndex], "icon name")
			assert(not seen[entry.hotkey], entry.hotkey .. " is assigned more than once")
			seen[entry.hotkey] = true
		end
	end
end)

test("side icons are large squares that do not overlap the T6 HUD", function()
	local rects = HudLayout.rects(1334, 750, "keyboard")
	local icons = {}

	for _, column in { HudLayout.IconColumns.left, HudLayout.IconColumns.right } do
		for _, entry in column do
			local icon = rects[entry.id]
			assert(icon ~= nil, entry.name .. " rectangle exists")
			eq(icon.w, icon.h, entry.name .. " is square")
			assert(icon.w >= 44, entry.name .. " is at least 44 pixels")

			for _, panelName in PANEL_NAMES do
				assert(
					not overlaps(icon, rects[panelName]),
					entry.name .. " overlaps " .. panelName
				)
			end

			for _, other in icons do
				assert(not overlaps(icon, other), entry.name .. " overlaps another side icon")
			end
			table.insert(icons, icon)
		end
	end
end)

test("giant money counter does not overlap the T6 HUD or side icons", function()
	local rects = HudLayout.rects(1334, 750, "keyboard")
	local money = rects.money
	assert(money ~= nil, "money rectangle exists")
	assert(money.w >= 200 and money.h >= 44, "money counter is prominent")

	for _, panelName in PANEL_NAMES do
		assert(not overlaps(money, rects[panelName]), "money overlaps " .. panelName)
	end
	for _, column in { HudLayout.IconColumns.left, HudLayout.IconColumns.right } do
		for _, entry in column do
			assert(not overlaps(money, rects[entry.id]), "money overlaps " .. entry.name)
		end
	end
end)
