local HudLayout = load("HudLayout")

local VIEWPORTS = {
	{ 1920, 1080 },
	{ 1366, 768 },
}

local PHONE =
	{ width = 844, height = 390, insets = { left = 47, top = 18, right = 34, bottom = 18 } }

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

test("V3 HUD anchors every build element and XP spans the top edge", function()
	for _, viewport in VIEWPORTS do
		local rects = HudLayout.rects(viewport[1], viewport[2], "touch")
		local rect = rects.xp
		eq(rect.x, 0, "XP starts at left edge")
		eq(rect.w, viewport[1], "XP reaches right edge")
		eq(rect.y, 0, "XP sits on the top edge")
		assert(
			rects.topStats.x > 0 and rects.topStats.x + rects.topStats.w < viewport[1],
			"top stats are centred"
		)
		assert(
			rects.waveProgress.y >= rects.topStats.y + rects.topStats.h,
			"wave progress is below labels"
		)
		assert(rects.weaponRow.x < rects.health.x, "weapons are bottom-left")
		assert(rects.passiveRow.x > rects.health.x, "passives are bottom-right")
		assert(rects.health.y > viewport[2] / 2, "health is bottom-centre")
		assert(rects.currencies.x < viewport[1] / 2, "currencies stay left")
		for name, target in HudLayout.touchTargets(viewport[1], viewport[2]) do
			assert(target.w >= HudLayout.MinTouchTarget, name .. " is too narrow")
			assert(target.h >= HudLayout.MinTouchTarget, name .. " is too short")
		end
	end
end)

test("V3 HUD does not overlap at desktop resolutions or in phone safe areas", function()
	local cases = {
		{ width = 1280, height = 720, platform = "keyboard" },
		{ width = 1920, height = 1080, platform = "keyboard" },
		{ width = PHONE.width, height = PHONE.height, platform = "touch", insets = PHONE.insets },
	}
	for _, case in cases do
		local rects = HudLayout.rects(case.width, case.height, case.platform, case.insets)
		local names =
			{ "topStats", "waveProgress", "weaponRow", "passiveRow", "health", "currencies" }
		for first = 1, #names do
			local name = names[first]
			local rect = rects[name]
			local insets = case.insets or { left = 0, top = 0, right = 0, bottom = 0 }
			assert(rect.x >= insets.left, name .. " enters the left safe area")
			assert(rect.y >= insets.top, name .. " enters the top safe area")
			assert(
				rect.x + rect.w <= case.width - insets.right,
				name .. " enters the right safe area"
			)
			assert(
				rect.y + rect.h <= case.height - insets.bottom,
				name .. " enters the bottom safe area"
			)
			for second = first + 1, #names do
				assert(
					not overlaps(rect, rects[names[second]]),
					name .. " overlaps " .. names[second]
				)
			end
		end
	end
end)
