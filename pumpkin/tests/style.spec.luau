--!strict
local fs = require("@lune/fs")
local Style = load("Style")

test("label style has readable text and the required dark stroke", function()
	local style = Style.label()
	eq(Style.isNearWhite(style.textColor), true, "near-white text")
	eq(style.strokeColor.r, 23, "stroke red")
	eq(style.strokeColor.g, 18, "stroke green")
	eq(style.strokeColor.b, 37, "stroke blue")
	eq(style.strokeThickness >= 2 and style.strokeThickness <= 3, true, "stroke thickness")
end)

test("Q4 palette uses the exact semantic colors", function()
	local expected = {
		orange = { 255, 107, 0 },
		purple = { 139, 44, 255 },
		lime = { 183, 255, 26 },
		cyan = { 0, 217, 255 },
		magenta = { 255, 45, 149 },
		yellow = { 255, 212, 0 },
		ink = { 23, 18, 37 },
	}
	for role, channels in expected do
		local actual = Style.Palette[role]
		eq(actual.r, channels[1], role .. " red")
		eq(actual.g, channels[2], role .. " green")
		eq(actual.b, channels[3], role .. " blue")
	end
end)

test("text, button, and pop tokens meet the game-feel bounds", function()
	eq(Style.textToken("hero").minimumSize >= 28, true, "hero number size")
	eq(Style.textToken("action").minimumSize >= 18, true, "action size")
	eq(Style.textToken("body").minimumSize >= 14, true, "body size")
	eq(Style.Button.pressPixels >= 4 and Style.Button.pressPixels <= 6, true, "press depth")
	eq(Style.Button.pressSeconds <= 0.06, true, "press timing")
	eq(
		Style.Button.reboundSeconds >= 0.14 and Style.Button.reboundSeconds <= 0.2,
		true,
		"rebound timing"
	)
	for _, name in { "micro", "reward", "rare" } do
		local normal = Style.popTier(name, false)
		local reduced = Style.popTier(name, true)
		eq(normal.overshootScale > 1, true, name .. " overshoots")
		eq(reduced.overshootScale < normal.overshootScale, true, name .. " reduced motion")
	end
end)

test("HUD builder routes every created text object through the label helper", function()
	local source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Hud.client.luau")
	eq(source:find('Instance.new("TextLabel")', 1, true), nil, "raw TextLabel constructor")
	eq(source:find('Instance.new("TextButton")', 1, true), nil, "raw TextButton constructor")
	eq(source:find('Instance.new("TextBox")', 1, true), nil, "raw TextBox constructor")
	eq(source:find("Style.label()", 1, true) ~= nil, true, "shared label helper")
end)

test("HUD never parents a gradient to grow popup text", function()
	local source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Hud.client.luau")
	eq(source:find("rainbow.Parent = label", 1, true), nil, "gradient text")
	eq(source:find("burstGradient.Parent = burst", 1, true) ~= nil, true, "gradient backing plate")
end)
