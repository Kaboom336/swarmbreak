local Theme = load("Theme")
local UiTheme = load("UiTheme")

local function linearChannel(channel)
	local value = channel / 255
	if value <= 0.04045 then
		return value / 12.92
	end
	return ((value + 0.055) / 1.055) ^ 2.4
end

local function luminance(color)
	return 0.2126 * linearChannel(color[1])
		+ 0.7152 * linearChannel(color[2])
		+ 0.0722 * linearChannel(color[3])
end

local function contrast(first, second)
	local lighter = math.max(luminance(first), luminance(second))
	local darker = math.min(luminance(first), luminance(second))
	return (lighter + 0.05) / (darker + 0.05)
end

test("text and stroke styles meet accessible contrast", function()
	for name, style in UiTheme.TextStyles do
		assert(
			contrast(style.TextColor, style.StrokeColor) >= 4.5,
			name .. " text and stroke contrast is below 4.5:1"
		)
	end
end)

test("UI rarity colors share the gameplay rarity palette", function()
	for rarity, color in Theme.Rarity do
		local uiColor = UiTheme.Rarity[rarity]
		assert(uiColor ~= nil, rarity .. " UI rarity color is missing")
		for channel = 1, 3 do
			eq(uiColor[channel], color[channel], rarity .. " channel " .. tostring(channel))
		end
	end
end)

test("touch targets remain at least 44 pixels at the reference viewport", function()
	eq(UiTheme.Sizes.ReferenceViewport.Width, 1334, "reference width")
	eq(UiTheme.Sizes.ReferenceViewport.Height, 750, "reference height")
	assert(UiTheme.Sizes.MinimumTouchTarget >= 44, "minimum touch target is too small")
	for name, size in UiTheme.Sizes.TouchTargets do
		assert(size.Width >= 44, name .. " is too narrow")
		assert(size.Height >= 44, name .. " is too short")
	end
end)

local function rejectThicknessTween(value, path)
	if type(value) ~= "table" then
		return
	end
	for key, child in value do
		local childPath = path .. "." .. tostring(key)
		if tostring(key):lower():find("tween") and type(child) == "table" then
			assert(child.Thickness == nil, childPath .. " tweens text stroke Thickness")
		end
		rejectThicknessTween(child, childPath)
	end
end

test("text stroke thickness is never tweened", function()
	rejectThicknessTween(UiTheme, "UiTheme")
	for _, property in UiTheme.Motion.Button.TweenProperties do
		assert(property ~= "Thickness", "button motion tweens Thickness")
	end
end)
