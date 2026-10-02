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

local HudLayout = {}

HudLayout.MinScale = 0.8
HudLayout.MaxScale = 1.25
HudLayout.MinTouchTarget = 44
HudLayout.MinButtonHeight = HudLayout.MinTouchTarget

HudLayout.Anchors = {
	waveTimer = "top-center",
	health = "bottom-left",
	xp = "bottom-full-width",
	ammo = "bottom-right",
	icons = "left",
	damageNumbers = "world",
	hitDirection = "center",
	aoeWarning = "world",
	waveClearBanner = "center",
	rewardCards = "center",
}

HudLayout.PlayElements = { "waveTimer", "health", "xp", "ammo", "icons" }
HudLayout.UtilityPanels = { "quests", "shop", "settings", "stats" }
HudLayout.MaxVisiblePlayPanels = 3

local REFERENCE_HEIGHT = 750
local MARGIN = 16
local GAP = 10
local BUTTON_HEIGHT = 34
local ICON_SIZE = 48
local ICON_GAP = 8

function HudLayout.scaleFor(_viewportX: number, viewportY: number, _platform: Platform): number
	return math.clamp(viewportY / REFERENCE_HEIGHT, HudLayout.MinScale, HudLayout.MaxScale)
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
	scaleMultiplier: number?
): { [string]: Rect }
	local scale = HudLayout.scaleFor(viewportX, viewportY, platform) * (scaleMultiplier or 1)
	local margin = MARGIN * scale
	local gap = GAP * scale
	local iconSize = math.max(ICON_SIZE, HudLayout.buttonHeightFor(scale, platform)) * scale
	local xpHeight = 10 * scale
	local bottomHeight = 44 * scale
	local bottomY = viewportY - xpHeight - gap - bottomHeight
	local waveWidth = math.min(360 * scale, viewportX - margin * 2)
	local healthWidth = math.min(280 * scale, viewportX * 0.3)
	local ammoWidth = math.min(180 * scale, viewportX * 0.22)
	local iconColumnHeight = iconSize * 3 + ICON_GAP * scale * 2
	local panelX = margin + iconSize + gap
	local panelY = 76 * scale
	local panelWidth = math.min(340 * scale, viewportX - panelX - margin)
	local panelHeight = math.max(0, bottomY - gap - panelY)

	local waveTimer = {
		x = (viewportX - waveWidth) / 2,
		y = margin,
		w = waveWidth,
		h = 44 * scale,
	}
	local bossBar = {
		x = waveTimer.x,
		y = waveTimer.y + waveTimer.h + gap,
		w = waveTimer.w,
		h = 22 * scale,
	}
	local health = {
		x = margin,
		y = bottomY,
		w = healthWidth,
		h = bottomHeight,
	}
	local ammo = {
		x = viewportX - margin - ammoWidth,
		y = bottomY,
		w = ammoWidth,
		h = bottomHeight,
	}
	local xp = {
		x = 0,
		y = viewportY - xpHeight,
		w = viewportX,
		h = xpHeight,
	}
	local icons = {
		x = margin,
		y = panelY,
		w = iconSize,
		h = iconColumnHeight,
	}
	local utilityPanel = {
		x = panelX,
		y = panelY,
		w = panelWidth,
		h = panelHeight,
	}

	local waveClearBanner = {
		x = (viewportX - 600 * scale) / 2,
		y = viewportY * 0.38,
		w = 600 * scale,
		h = 80 * scale,
	}
	local rewardCards = {
		x = (viewportX - 600 * scale) / 2,
		y = viewportY * 0.3,
		w = 600 * scale,
		h = 200 * scale,
	}

	return {
		waveTimer = waveTimer,
		bossBar = bossBar,
		health = health,
		xp = xp,
		ammo = ammo,
		icons = icons,
		quests = utilityPanel,
		shop = utilityPanel,
		settings = utilityPanel,
		stats = utilityPanel,
		hotbar = ammo,
		waveClearBanner = waveClearBanner,
		rewardCards = rewardCards,
		-- Compatibility names for transient elements owned by the existing HUD.
		wave = waveTimer,
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

function HudLayout.touchTargets(
	viewportX: number,
	viewportY: number,
	scaleMultiplier: number?
): { [string]: Rect }
	local rects = HudLayout.rects(viewportX, viewportY, "touch", scaleMultiplier)
	local size = rects.icons.w
	local step = size
		+ ICON_GAP * HudLayout.scaleFor(viewportX, viewportY, "touch") * (scaleMultiplier or 1)
	return {
		quests = { x = rects.icons.x, y = rects.icons.y, w = size, h = size },
		shop = { x = rects.icons.x, y = rects.icons.y + step, w = size, h = size },
		settings = { x = rects.icons.x, y = rects.icons.y + step * 2, w = size, h = size },
	}
end

return HudLayout
