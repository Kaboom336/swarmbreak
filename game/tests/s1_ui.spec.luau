local CardStyle = load("CardStyle")
local Feel = load("Feel")
local HudLayout = load("HudLayout")
local LevelUp = load("LevelUp")
local Theme = load("Theme")
local UiTheme = load("UiTheme")

local function sameColor(actual, expected, name)
	for channel = 1, 3 do
		eq(actual[channel], expected[channel], name .. " channel " .. channel)
	end
end

test("S1 uses the art-bible palette and fonts", function()
	sameColor(Theme.OutpostCream, { 255, 233, 201 }, "OutpostCream")
	sameColor(Theme.OutpostShade, { 222, 190, 150 }, "OutpostShade")
	sameColor(Theme.SignalOrange, { 255, 138, 43 }, "SignalOrange")
	sameColor(Theme.Chitin, { 91, 47, 147 }, "Chitin")
	sameColor(Theme.ChitinDark, { 62, 31, 107 }, "ChitinDark")
	sameColor(Theme.Goo, { 46, 230, 197 }, "Goo")
	sameColor(Theme.Hero, { 61, 165, 255 }, "Hero")
	sameColor(Theme.Loot, { 255, 210, 63 }, "Loot")
	sameColor(Theme.Telegraph, { 255, 61, 110 }, "Telegraph")
	sameColor(UiTheme.Colors.Panel, { 42, 33, 86 }, "UiPanel")
	sameColor(UiTheme.Stroke.Color, { 74, 60, 140 }, "UiStroke")
	sameColor(UiTheme.Colors.Text, { 255, 247, 236 }, "Text")
	eq(UiTheme.Font.Title, "FredokaOne", "title font")
	eq(UiTheme.Font.Body, "GothamBold", "body font")
	eq(UiTheme.Font.Banner, "LuckiestGuy", "banner font")
	eq(UiTheme.Stroke.Thickness, 3, "panel stroke")
	eq(UiTheme.Corner.Panel, 14, "panel corner")
	for enemyName, palette in Theme.Enemy do
		local bodyIsS0 = palette.Body == Theme.Chitin or palette.Body == Theme.ChitinDark
		assert(bodyIsS0, enemyName .. " body is outside the S0 chitin palette")
		sameColor(palette.Accent, Theme.Goo, enemyName .. " eyes")
	end
end)

test("S1 screen scale follows the 1920 by 1080 art-bible formula", function()
	eq(UiTheme.Sizes.ReferenceViewport.Width, 1920, "reference width")
	eq(UiTheme.Sizes.ReferenceViewport.Height, 1080, "reference height")
	eq(HudLayout.scaleFor(1920, 1080, "keyboard"), 1, "reference scale")
	eq(HudLayout.scaleFor(1280, 720, "keyboard"), 2 / 3, "720p scale")
	eq(HudLayout.scaleFor(844, 390, "touch"), 0.6, "phone clamp")
	eq(HudLayout.scaleFor(3840, 2160, "keyboard"), 1.2, "large clamp")
end)

test("S1 cards preserve the upper arena view and protect briefly", function()
	for _, viewport in { { 1280, 720 }, { 1920, 1080 }, { 844, 390 } } do
		local rect = HudLayout.rects(viewport[1], viewport[2], "touch").rewardCards
		assert(rect.y >= viewport[2] * 0.45, "cards enter the upper 45 percent")
		assert(rect.y + rect.h <= viewport[2], "cards clip below the viewport")
	end
	eq(CardStyle.WorldDimTransparency, 0.75, "25 percent world dim")
	eq(LevelUp.CardDamageMultiplier, 0.5, "card damage multiplier")
	eq(LevelUp.CardProtectionSeconds, 6, "card protection cap")
	eq(LevelUp.incomingDamage(20, 10, 15, true), 10, "protected damage")
	eq(LevelUp.incomingDamage(20, 10, 16.01, true), 20, "expired damage")
	eq(LevelUp.incomingDamage(20, 10, 11, false), 20, "closed cards")
end)

test("S1 damage numbers use the requested sizes and pop", function()
	eq(Feel.DamageNumberNormalPixels, 28, "normal damage size")
	eq(Feel.DamageNumberCritPixels, 40, "critical damage size")
	eq(Feel.DamageNumberPopScale, 1.3, "damage number pop")
	eq(Feel.DamageNumberFont, "FredokaOne", "damage number font")
end)
