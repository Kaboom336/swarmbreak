--!strict
-- Pure responsive layout calculations. Rectangles are returned in rendered viewport pixels.

export type Platform = "keyboard" | "touch" | "gamepad"

export type Rect = {
	x: number,
	y: number,
	w: number,
	h: number,
}

export type IconEntry = {
	id: string,
	name: string,
	hotkey: string,
	colour: {
		red: number,
		green: number,
		blue: number,
	},
}

export type IconColumns = {
	left: { IconEntry },
	right: { IconEntry },
}

local HudLayout = {}

HudLayout.MinScale = 0.6 -- placeholder
HudLayout.MaxScale = 1.4 -- placeholder
HudLayout.MinButtonHeight = 44 -- placeholder
HudLayout.MinIconSize = 44 -- placeholder

HudLayout.IconColumns = {
	left = {
		{
			id = "inventoryIcon",
			name = "Inventory",
			hotkey = "I",
			colour = { red = 55, green = 125, blue = 220 }, -- placeholder
		},
		{
			id = "kitsIcon",
			name = "Kits",
			hotkey = "K",
			colour = { red = 230, green = 125, blue = 45 }, -- placeholder
		},
		{
			id = "questsIcon",
			name = "Quests",
			hotkey = "Q",
			colour = { red = 55, green = 175, blue = 95 }, -- placeholder
		},
		{
			id = "shopIcon",
			name = "Shop",
			hotkey = "B",
			colour = { red = 235, green = 185, blue = 45 }, -- placeholder
		},
		{
			id = "settingsIcon",
			name = "Settings",
			hotkey = "O",
			colour = { red = 115, green = 120, blue = 135 }, -- placeholder
		},
	},
	right = {
		{
			id = "codesIcon",
			name = "Codes",
			hotkey = "C",
			colour = { red = 45, green = 185, blue = 210 }, -- placeholder
		},
		{
			id = "passIcon",
			name = "Pass",
			hotkey = "P",
			colour = { red = 145, green = 80, blue = 210 }, -- placeholder
		},
		{
			id = "rewardsIcon",
			name = "Rewards",
			hotkey = "R",
			colour = { red = 220, green = 75, blue = 140 }, -- placeholder
		},
		{
			id = "guidesIcon",
			name = "Guides",
			hotkey = "G",
			colour = { red = 45, green = 155, blue = 145 }, -- placeholder
		},
	},
} :: IconColumns

local REFERENCE_HEIGHT = 720 -- placeholder
local BUTTON_HEIGHT = 34 -- placeholder
local PANEL_GAP = 8 -- placeholder
local COMPACT_WIDTH = 1000 -- placeholder
local SETTINGS_LAST_SLIDER_Y = 89 -- placeholder
local ICON_SIZE = 48 -- placeholder
local MONEY_WIDTH = 260 -- placeholder
local MONEY_HEIGHT = 56 -- placeholder

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
	local iconSize = math.max(HudLayout.MinIconSize, ICON_SIZE * scale)
	local iconGap = gap * scale
	local leftRailX = margin
	local rightRailX = viewportX - margin - iconSize
	local sidePanelX = if compact then margin else leftRailX + iconSize + iconGap

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
	local bottomY = viewportY - margin - bottomHeight

	local wave = {
		x = (viewportX - waveWidth) / 2,
		y = margin,
		w = waveWidth,
		h = waveHeight,
	}
	local settings = {
		x = sidePanelX,
		y = margin,
		w = sideWidth,
		h = settingsHeight,
	}
	local questY = settings.y + settings.h + gap
	local quest = {
		x = sidePanelX,
		y = questY,
		w = sideWidth,
		h = math.min(questHeight, bottomY - gap - questY),
	}
	local shopY = wave.y + wave.h + gap
	local shop = {
		x = if compact then viewportX - margin - shopWidth else rightRailX - iconGap - shopWidth,
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

	local rects: { [string]: Rect } = {
		quest = quest,
		settings = settings,
		shop = shop,
		hotbar = hotbar,
		wave = wave,
		health = health,
		money = {
			x = rightRailX - iconGap - MONEY_WIDTH * scale,
			y = margin,
			w = MONEY_WIDTH * scale,
			h = MONEY_HEIGHT * scale,
		},
	}

	local function addIconColumn(entries: { IconEntry }, x: number)
		local height = #entries * iconSize + (#entries - 1) * iconGap
		local y = math.max(margin, (viewportY - height) / 2)
		for _, entry in entries do
			rects[entry.id] = {
				x = x,
				y = y,
				w = iconSize,
				h = iconSize,
			}
			y += iconSize + iconGap
		end
	end

	addIconColumn(HudLayout.IconColumns.left, leftRailX)
	addIconColumn(HudLayout.IconColumns.right, rightRailX)

	return rects
end

return HudLayout
