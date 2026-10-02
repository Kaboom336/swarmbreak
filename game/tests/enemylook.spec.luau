local Enemies = load("Enemies")
local Theme = load("Theme")

local function channel(value: number): number
	local normalized = value / 255
	if normalized <= 0.04045 then
		return normalized / 12.92
	end
	return ((normalized + 0.055) / 1.055) ^ 2.4
end

local function luminance(color: { number }): number
	return 0.2126 * channel(color[1]) + 0.7152 * channel(color[2]) + 0.0722 * channel(color[3])
end

local function contrast(a: { number }, b: { number }): number
	local lighter = math.max(luminance(a), luminance(b))
	local darker = math.min(luminance(a), luminance(b))
	return (lighter + 0.05) / (darker + 0.05)
end

test("enemy body colors contrast with the floor", function()
	for name in Enemies.Defs do
		local palette = Theme.Enemy[name]
		assert(palette, name .. " needs an enemy palette")
		assert(contrast(palette.Body, Theme.Floor) >= 3, name .. " body is hard to read")
	end
end)

test("every enemy has a readable relative height", function()
	for name, def in Enemies.Defs do
		if def.Boss then
			assert(def.Scale >= 2.5 and def.Scale <= 4, name .. " boss scale")
		else
			assert(def.Scale >= 1 and def.Scale <= 1.6, name .. " enemy scale")
		end
	end
	eq(Enemies.Defs.Walker.Scale, 1.2, "Walker height relative to player")
end)
