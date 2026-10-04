--!strict
-- Pure screen-space layout and visibility rules for the in-run HUD.

export type Platform = "keyboard" | "touch" | "gamepad"
export type UtilityPanel = "quests" | "shop" | "settings" | "stats"

export type Rect = {
	x: number,
	y: number,
	w: number,
	h: number,
}

export type Insets = {
	left: number,
	top: number,
	right: number,
	bottom: number,
}

local HudLayout = {}

local UiTheme = require(script.Parent.UiTheme)

HudLayout.MinScale = 0.6
HudLayout.MaxScale = 1.2
HudLayout.MinTouchTarget = 44
HudLayout.MinButtonHeight = HudLayout.MinTouchTarget

HudLayout.Anchors = {
	xp = "top-full-width",
	topStats = "top-center",
	waveProgress = "top-center",
	weaponRow = "bottom-left",
	passiveRow = "bottom-right",
	health = "bottom-center",
	currencies = "left",
	waveTimer = "top-center",
	ammo = "bottom-left",
	icons = "left",
	damageNumbers = "world",
	hitDirection = "center",
	aoeWarning = "world",
	waveClearBanner = "center",
	rewardCards = "center",
}

HudLayout.PlayElements =
	{ "topStats", "waveProgress", "health", "xp", "weaponRow", "passiveRow", "currencies" }
HudLayout.UtilityPanels = { "quests", "shop", "settings", "stats" }
HudLayout.MaxVisiblePlayPanels = 3

local MARGIN = 16
local GAP = 10
local BUTTON_HEIGHT = 34
local ICON_SIZE = 48
local ICON_GAP = 8

function HudLayout.scaleFor(viewportX: number, viewportY: number, _platform: Platform): number
	return UiTheme.scaleFor(viewportX, viewportY)
end

function HudLayout.buttonHeightFor(scale: number, platform: Platform): number
	if platform == "touch" then
		return math.max(BUTTON_HEIGHT, HudLayout.MinButtonHeight / scale)
	end
	return BUTTON_HEIGHT
end

function HudLayout.rects(
	viewportX: number,
	viewportY: number,
	platform: Platform,
	insets: Insets?
): { [string]: Rect }
	local scale = HudLayout.scaleFor(viewportX, viewportY, platform)
	local safe = insets or { left = 0, top = 0, right = 0, bottom = 0 }
	local safeLeft = safe.left
	local safeTop = safe.top
	local safeRight = viewportX - safe.right
	local safeBottom = viewportY - safe.bottom
	local safeWidth = safeRight - safeLeft
	local margin = MARGIN * scale
	local gap = GAP * scale
	local iconSize = math.max(ICON_SIZE, HudLayout.buttonHeightFor(scale, platform)) * scale
	local xpHeight = 8 * scale
	local slotSize = 64 * scale
	local bottomHeight = 40 * scale
	local bottomY = safeBottom - margin - bottomHeight
	local waveWidth = math.min(420 * scale, safeWidth - margin * 2)
	local healthWidth = math.min(420 * scale, safeWidth * 0.38)
	local weaponWidth = slotSize * 2 + gap
	local passiveWidth = slotSize * 4 + gap * 3
	local iconColumnHeight = iconSize * 3 + ICON_GAP * scale * 2
	local panelY = safeTop + 76 * scale
	local panelWidth = math.min(340 * scale, safeWidth - iconSize - gap - margin * 2)
	local panelX = safeRight - margin - iconSize - gap - panelWidth
	local panelHeight = math.max(0, bottomY - gap - panelY)
	local compact = weaponWidth + passiveWidth + healthWidth + gap * 4 > safeWidth
	local buildY = safeBottom - margin - slotSize
	local passiveY = buildY
	if compact then
		buildY = bottomY - slotSize - gap
		passiveY = buildY - slotSize - gap
		weaponWidth = math.min(weaponWidth, safeWidth)
		passiveWidth = math.min(passiveWidth, safeWidth)
	end
	panelHeight = math.max(0, math.min(buildY, passiveY) - gap - panelY)

	local topStats = {
		x = safeLeft + (safeWidth - waveWidth) / 2,
		y = math.max(safeTop, xpHeight + 4 * scale),
		w = waveWidth,
		h = 24 * scale,
	}
	local waveProgress = {
		x = topStats.x,
		y = topStats.y + topStats.h + 4 * scale,
		w = topStats.w,
		h = 14 * scale,
	}
	local health = {
		x = safeLeft + (safeWidth - healthWidth) / 2,
		y = bottomY,
		w = healthWidth,
		h = bottomHeight,
	}
	local weaponRow = {
		x = safeLeft + margin,
		y = buildY,
		w = weaponWidth,
		h = slotSize,
	}
	local passiveRow = {
		x = safeRight - margin - passiveWidth,
		y = passiveY,
		w = passiveWidth,
		h = slotSize,
	}
	local xp = {
		x = 0,
		y = 0,
		w = viewportX,
		h = xpHeight,
	}
	local icons = {
		x = safeRight - margin - iconSize,
		y = panelY,
		w = iconSize,
		h = iconColumnHeight,
	}
	local currencies = {
		x = safeLeft + margin,
		y = panelY,
		w = iconSize,
		h = iconSize * 2,
	}
	local utilityPanel = {
		x = panelX,
		y = panelY,
		w = panelWidth,
		h = panelHeight,
	}

	local waveClearBanner = {
		x = (viewportX - 600 * scale) / 2,
		y = viewportY * 0.22,
		w = 600 * scale,
		h = 80 * scale,
	}
	local rewardY = safeTop + (safeBottom - safeTop) * 0.45
	local rewardCards = {
		x = (viewportX - 600 * scale) / 2,
		y = rewardY,
		w = 600 * scale,
		h = math.max(0, safeBottom - rewardY),
	}

	return {
		topStats = topStats,
		waveProgress = waveProgress,
		waveTimer = topStats,
		bossBar = waveProgress,
		health = health,
		xp = xp,
		weaponRow = weaponRow,
		passiveRow = passiveRow,
		currencies = currencies,
		ammo = weaponRow,
		icons = icons,
		quests = utilityPanel,
		shop = utilityPanel,
		settings = utilityPanel,
		stats = utilityPanel,
		hotbar = weaponRow,
		waveClearBanner = waveClearBanner,
		rewardCards = rewardCards,
		-- Compatibility names for transient elements owned by the existing HUD.
		wave = topStats,
		quest = utilityPanel,
	}
end

function HudLayout.playState(openPanel: UtilityPanel?): ({ string }, { string })
	local visible = table.clone(HudLayout.PlayElements)
	local visiblePanels = { "health", "xp" }
	if openPanel then
		table.insert(visible, openPanel)
		table.insert(visiblePanels, openPanel)
	end
	return visible, visiblePanels
end

function HudLayout.touchTargets(viewportX: number, viewportY: number): { [string]: Rect }
	local rects = HudLayout.rects(viewportX, viewportY, "touch")
	local size = rects.icons.w
	local step = size + ICON_GAP * HudLayout.scaleFor(viewportX, viewportY, "touch")
	return {
		quests = { x = rects.icons.x, y = rects.icons.y, w = size, h = size },
		shop = { x = rects.icons.x, y = rects.icons.y + step, w = size, h = size },
		settings = { x = rects.icons.x, y = rects.icons.y + step * 2, w = size, h = size },
	}
end

return HudLayout
