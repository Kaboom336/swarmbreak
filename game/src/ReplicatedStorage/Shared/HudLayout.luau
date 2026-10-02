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
HudLayout.MinButtonHeight = 44 -- placeholder

local REFERENCE_HEIGHT = 720 -- placeholder
local BUTTON_HEIGHT = 34 -- placeholder
local PANEL_GAP = 8 -- placeholder
local COMPACT_WIDTH = 1000 -- placeholder
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
	local compact = viewportX < COMPACT_WIDTH
	local margin = (if compact then 8 else 12) -- placeholder
	local gap = PANEL_GAP
	local buttonHeight = HudLayout.buttonHeightFor(scale, platform) * scale

	local waveWidth = 480 * scale -- placeholder
	local waveHeight = 128 * scale -- placeholder
	local sideWidth = 260 * scale -- placeholder
	local settingsPanelHeight = math.max(
		116, -- placeholder
		SETTINGS_LAST_SLIDER_Y + HudLayout.buttonHeightFor(scale, platform)
	)
	local settingsHeight = buttonHeight + gap * scale + settingsPanelHeight * scale
	local questHeight = buttonHeight + gap * scale + 180 * scale -- placeholder
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

	local wave = {
		x = (viewportX - waveWidth) / 2,
		y = margin,
		w = waveWidth,
		h = waveHeight,
	}
	local settings = {
		x = margin,
		y = margin,
		w = sideWidth,
		h = settingsHeight,
	}
	local questY = settings.y + settings.h + gap
	local quest = {
		x = margin,
		y = questY,
		w = sideWidth,
		h = math.min(questHeight, bottomY - gap - questY),
	}
	local shopY = wave.y + wave.h + gap
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

	return {
		quest = quest,
		settings = settings,
		shop = shop,
		hotbar = hotbar,
		wave = wave,
		health = health,
		xp = xp,
	}
end

return HudLayout
