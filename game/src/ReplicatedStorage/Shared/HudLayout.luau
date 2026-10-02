--!strict
-- Pure responsive layout calculations. Rectangles are returned in rendered viewport pixels.

export type Platform = "keyboard" | "touch" | "gamepad"

export type Rect = {
	x: number,
	y: number,
	w: number,
	h: number,
}

local HudLayout = {}

HudLayout.MinScale = 0.6 -- placeholder
HudLayout.MaxScale = 1.4 -- placeholder
HudLayout.MinTouchTarget = 44 -- placeholder
HudLayout.MinButtonHeight = HudLayout.MinTouchTarget -- compatibility for existing callers

-- Screen-space elements use these anchors; world-space feedback is projected by its client.
HudLayout.Anchors = {
	waveTimer = "top-center",
	bossBar = "top-center",
	currencies = "top-right",
	quests = "left",
	damageNumbers = "world",
	hitDirection = "center",
	aoeWarning = "world",
	waveClearBanner = "center",
	rewardCards = "center",
}

local REFERENCE_HEIGHT = 720 -- placeholder
local BUTTON_HEIGHT = 34 -- placeholder
local PANEL_GAP = 8 -- placeholder
local SETTINGS_LAST_SLIDER_Y = 89 -- placeholder

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
	platform: Platform
): { [string]: Rect }
	local scale = HudLayout.scaleFor(viewportX, viewportY, platform)
	local margin = 12 -- placeholder
	local gap = PANEL_GAP * scale
	local buttonHeight = HudLayout.buttonHeightFor(scale, platform) * scale

	local waveWidth = 480 * scale -- placeholder
	local waveHeight = 92 * scale -- placeholder
	local bossHeight = 28 * scale -- placeholder
	local sideWidth = 260 * scale -- placeholder
	local currencyHeight = 52 * scale -- placeholder
	local settingsPanelHeight = math.max(
		116, -- placeholder
		SETTINGS_LAST_SLIDER_Y + HudLayout.buttonHeightFor(scale, platform)
	)
	local settingsHeight = buttonHeight + gap + settingsPanelHeight * scale
	local questHeight = buttonHeight + gap + 180 * scale -- placeholder
	local shopWidth = 360 * scale -- placeholder
	local healthWidth = 420 * scale -- placeholder
	local healthHeight = 80 * scale -- placeholder
	local hotbarWidth = 420 * scale -- placeholder
	local hotbarHeight = buttonHeight + 14 * scale -- placeholder
	local bottomHeight = math.max(healthHeight, hotbarHeight)
	local xpHeight = 12 * scale
	local xp = {
		x = 0,
		y = viewportY - xpHeight,
		w = viewportX,
		h = xpHeight,
	}
	local bottomY = xp.y - gap - bottomHeight

	local waveTimer = {
		x = (viewportX - waveWidth) / 2,
		y = margin,
		w = waveWidth,
		h = waveHeight,
	}
	local bossBar = {
		x = waveTimer.x,
		y = waveTimer.y + waveTimer.h + gap,
		w = waveTimer.w,
		h = bossHeight,
	}
	local currencies = {
		x = viewportX - margin - sideWidth,
		y = margin,
		w = sideWidth,
		h = currencyHeight,
	}
	local settings = {
		x = margin,
		y = margin,
		w = sideWidth,
		h = settingsHeight,
	}
	local questY = settings.y + settings.h + gap
	local quests = {
		x = margin,
		y = questY,
		w = sideWidth,
		h = math.min(questHeight, bottomY - gap - questY),
	}
	local shopY = currencies.y + currencies.h + gap
	local shop = {
		x = viewportX - margin - shopWidth,
		y = shopY,
		w = shopWidth,
		h = bottomY - gap - shopY,
	}
	local health = {
		x = margin,
		y = bottomY,
		w = healthWidth,
		h = bottomHeight,
	}
	local hotbar = {
		x = viewportX - margin - hotbarWidth,
		y = bottomY,
		w = hotbarWidth,
		h = bottomHeight,
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
		currencies = currencies,
		quests = quests,
		waveClearBanner = waveClearBanner,
		rewardCards = rewardCards,
		settings = settings,
		shop = shop,
		hotbar = hotbar,
		health = health,
<<<<<<< HEAD
		-- Compatibility names used by older HUD code.
		wave = waveTimer,
		quest = quests,
	}
end

function HudLayout.touchTargets(viewportX: number, viewportY: number): { [string]: Rect }
	local rects = HudLayout.rects(viewportX, viewportY, "touch")
	local size = HudLayout.MinTouchTarget
	return {
		quests = { x = rects.quests.x, y = rects.quests.y, w = rects.quests.w, h = size },
		settings = { x = rects.settings.x, y = rects.settings.y, w = rects.settings.w, h = size },
		shop = { x = rects.shop.x, y = rects.shop.y, w = rects.shop.w, h = size },
		rewardCard1 = { x = rects.rewardCards.x, y = rects.rewardCards.y, w = 184, h = 180 },
		rewardCard2 = { x = rects.rewardCards.x + 208, y = rects.rewardCards.y, w = 184, h = 180 },
		rewardCard3 = { x = rects.rewardCards.x + 416, y = rects.rewardCards.y, w = 184, h = 180 },
=======
		xp = xp,
>>>>>>> codex/w9-card-cadence-xp
	}
end

return HudLayout
