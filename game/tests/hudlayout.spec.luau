local HudLayout = load("HudLayout")

local VIEWPORTS = {
	{ 1920, 1080 },
	{ 1334, 750 },
}

local function overlaps(a, b)
	return not (a.x + a.w <= b.x or b.x + b.w <= a.x or a.y + a.h <= b.y or b.y + b.h <= a.y)
end

test("clean play HUD has no overlaps at both required resolutions", function()
	for _, viewport in VIEWPORTS do
		local width, height = viewport[1], viewport[2]
		local rects = HudLayout.rects(width, height, "keyboard")
		local visible = HudLayout.playState(nil)
		for first = 1, #visible do
			local firstRect = rects[visible[first]]
			assert(firstRect.x >= 0 and firstRect.y >= 0, visible[first] .. " begins on screen")
			assert(firstRect.x + firstRect.w <= width, visible[first] .. " fits horizontally")
			assert(firstRect.y + firstRect.h <= height, visible[first] .. " fits vertically")
			for second = first + 1, #visible do
				assert(
					not overlaps(firstRect, rects[visible[second]]),
					visible[first] .. " overlaps " .. visible[second]
				)
			end
		end
	end
end)

test("an open utility panel does not overlap the clean play HUD", function()
	for _, viewport in VIEWPORTS do
		local rects = HudLayout.rects(viewport[1], viewport[2], "touch")
		local visible = HudLayout.playState("quests")
		for first = 1, #visible do
			for second = first + 1, #visible do
				assert(
					not overlaps(rects[visible[first]], rects[visible[second]]),
					visible[first] .. " overlaps " .. visible[second]
				)
			end
		end
	end
end)

test("play state never has more than three visible panels", function()
	local _, closedPanels = HudLayout.playState(nil)
	assert(#closedPanels <= HudLayout.MaxVisiblePlayPanels, "closed play HUD has too many panels")
	for _, panel in HudLayout.UtilityPanels do
		local _, visiblePanels = HudLayout.playState(panel)
		assert(#visiblePanels <= HudLayout.MaxVisiblePlayPanels, panel .. " opens too many panels")
	end
end)

test("XP spans the screen and utility icons meet touch target size", function()
	for _, viewport in VIEWPORTS do
		local rect = HudLayout.rects(viewport[1], viewport[2], "touch").xp
		eq(rect.x, 0, "XP starts at left edge")
		eq(rect.w, viewport[1], "XP reaches right edge")
		for name, target in HudLayout.touchTargets(viewport[1], viewport[2]) do
			assert(target.w >= HudLayout.MinTouchTarget, name .. " is too narrow")
			assert(target.h >= HudLayout.MinTouchTarget, name .. " is too short")
		end
	end
end)
