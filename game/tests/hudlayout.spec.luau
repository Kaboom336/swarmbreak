local HudLayout = load("HudLayout")

local VIEWPORTS = {
	{ 1334, 750 },
	{ 1920, 1080 },
}

local PERSISTENT_NAMES = {
	"waveTimer",
	"bossBar",
	"currencies",
	"quests",
	"settings",
	"shop",
	"hotbar",
	"health",
}

local function overlaps(a, b)
	return not (a.x + a.w <= b.x or b.x + b.w <= a.x or a.y + a.h <= b.y or b.y + b.h <= a.y)
end

local function centreX(rect)
	return rect.x + rect.w / 2
end

test("final swarm elements use their required anchors", function()
	eq(HudLayout.Anchors.waveTimer, "top-center", "wave and timer anchor")
	eq(HudLayout.Anchors.bossBar, "top-center", "boss bar anchor")
	eq(HudLayout.Anchors.currencies, "top-right", "currency anchor")
	eq(HudLayout.Anchors.quests, "left", "quest anchor")
	eq(HudLayout.Anchors.damageNumbers, "world", "damage number anchor")
	eq(HudLayout.Anchors.hitDirection, "center", "hit direction anchor")
	eq(HudLayout.Anchors.aoeWarning, "world", "area warning anchor")
	eq(HudLayout.Anchors.waveClearBanner, "center", "wave clear anchor")
	eq(HudLayout.Anchors.rewardCards, "center", "reward card anchor")
end)

test("persistent rectangles stay inside each required viewport", function()
	for _, viewport in VIEWPORTS do
		local width, height = viewport[1], viewport[2]
		local rects = HudLayout.rects(width, height, "touch")
		for _, name in PERSISTENT_NAMES do
			local rect = rects[name]
			assert(rect ~= nil, name .. " rectangle exists")
			assert(rect.w > 0 and rect.h > 0, name .. " has positive size")
			assert(rect.x >= 0 and rect.y >= 0, name .. " starts inside the viewport")
			assert(rect.x + rect.w <= width, name .. " fits horizontally")
			assert(rect.y + rect.h <= height, name .. " fits vertically")
		end
	end
end)

test("persistent rectangles do not overlap", function()
	for _, viewport in VIEWPORTS do
		local rects = HudLayout.rects(viewport[1], viewport[2], "touch")
		for first = 1, #PERSISTENT_NAMES do
			for second = first + 1, #PERSISTENT_NAMES do
				local firstName = PERSISTENT_NAMES[first]
				local secondName = PERSISTENT_NAMES[second]
				assert(
					not overlaps(rects[firstName], rects[secondName]),
					firstName .. " overlaps " .. secondName
				)
			end
		end
	end
end)

test("top and side elements are positioned at their named anchors", function()
	for _, viewport in VIEWPORTS do
		local width = viewport[1]
		local rects = HudLayout.rects(width, viewport[2], "touch")
		assert(
			math.abs(centreX(rects.waveTimer) - width / 2) < 0.01,
			"wave and timer are not centred"
		)
		assert(math.abs(centreX(rects.bossBar) - width / 2) < 0.01, "boss bar is not centred")
		assert(rects.currencies.x > width / 2, "currencies are not on the right")
		assert(rects.quests.x < width / 2, "quests are not on the left")
	end
end)

test("every declared touch target is at least 44 pixels", function()
	for _, viewport in VIEWPORTS do
		local targets = HudLayout.touchTargets(viewport[1], viewport[2])
		for name, rect in targets do
			assert(rect.w >= HudLayout.MinTouchTarget, name .. " is too narrow")
			assert(rect.h >= HudLayout.MinTouchTarget, name .. " is too short")
		end
	end
end)

test("scale is monotonic and clamped", function()
	local heights = { 200, 360, 390, 720, 750, 1080, 1600 }
	local previous = HudLayout.MinScale
	for _, height in heights do
		local scale = HudLayout.scaleFor(1334, height, "keyboard")
		assert(scale >= previous, "scale decreased as viewport height grew")
		assert(scale >= HudLayout.MinScale, "scale fell below the minimum")
		assert(scale <= HudLayout.MaxScale, "scale exceeded the maximum")
		previous = scale
	end
	eq(HudLayout.scaleFor(640, 100, "touch"), HudLayout.MinScale, "minimum clamp")
	eq(HudLayout.scaleFor(1920, 2000, "keyboard"), HudLayout.MaxScale, "maximum clamp")
end)
