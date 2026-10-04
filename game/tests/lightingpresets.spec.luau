local fs = require("@lune/fs")
local serde = require("@lune/serde")

local LightingPresets = load("LightingPresets")
local Theme = load("Theme")

local presetNames = { "Station", "BossFight", "NestInterior", "Base", "LowQuality" }
local sectionNames = { "Lighting", "Atmosphere", "Bloom", "ColorCorrection", "Sky" }

local function luminance(color)
	local function linear(channel)
		channel /= 255
		if channel <= 0.04045 then
			return channel / 12.92
		end
		return ((channel + 0.055) / 1.055) ^ 2.4
	end

	return 0.2126 * linear(color[1]) + 0.7152 * linear(color[2]) + 0.0722 * linear(color[3])
end

local function hue(color)
	local high = math.max(color[1], color[2], color[3])
	local low = math.min(color[1], color[2], color[3])
	local difference = high - low
	if difference == 0 then
		return 0
	end
	local value
	if high == color[1] then
		value = (color[2] - color[3]) / difference % 6
	elseif high == color[2] then
		value = (color[3] - color[1]) / difference + 2
	else
		value = (color[1] - color[2]) / difference + 4
	end
	return value / 6
end

local function hueDistance(a, b)
	local difference = math.abs(hue(a) - hue(b))
	return math.min(difference, 1 - difference)
end

local function assertSame(expected, actual, path)
	for key, expectedValue in expected do
		local actualValue = actual[key]
		assert(actualValue ~= nil, path .. "." .. key .. " is missing")
		if type(expectedValue) == "table" then
			assert(type(actualValue) == "table", path .. "." .. key .. " is not a table")
			assertSame(expectedValue, actualValue, path .. "." .. key)
		elseif type(expectedValue) == "number" then
			assert(
				math.abs(expectedValue - actualValue) < 0.000001,
				path .. "." .. key .. " differs"
			)
		else
			eq(actualValue, expectedValue, path .. "." .. key)
		end
	end
end

test("Station is the dusk preset", function()
	assert(LightingPresets.Station.Lighting.Brightness >= 2, "Station is too dim")
	eq(LightingPresets.Station.Lighting.ClockTime, 14.5, "Station ClockTime")
	assert(LightingPresets.Station.Atmosphere.Density <= 0.15, "Station atmosphere is too dense")
end)

test("every lighting preset has the complete schema", function()
	for _, presetName in presetNames do
		local preset = LightingPresets[presetName]
		assert(preset ~= nil, presetName .. " is missing")
		for _, sectionName in sectionNames do
			local section = preset[sectionName]
			assert(section ~= nil, presetName .. "." .. sectionName .. " is missing")
			for key in LightingPresets.Station[sectionName] do
				assert(
					section[key] ~= nil,
					presetName .. "." .. sectionName .. "." .. key .. " is missing"
				)
			end
		end
	end
end)

test("atmosphere follows the sky hue and bloom only catches highlights", function()
	for _, presetName in presetNames do
		local preset = LightingPresets[presetName]
		if presetName ~= "Station" then
			assert(
				hueDistance(preset.Atmosphere.Color, preset.Sky.Tint) <= 0.12,
				presetName .. " atmosphere and sky hues disagree"
			)
		end
		assert(preset.Bloom.Threshold >= 0.8, presetName .. " bloom threshold is too low")
	end
end)

test("every enemy body is darker than the floor", function()
	local floorLuminance = luminance(Theme.Floor)
	for enemyName, colors in Theme.Enemy do
		assert(
			floorLuminance - luminance(colors.Body) >= 0.35,
			enemyName .. " body is not dark enough against the floor"
		)
	end
end)

test("NestInterior defines purple crystal and teal fungus light sources", function()
	local sources = LightingPresets.NestInterior.LightSources
	eq(sources.Crystal.Kind, "PointLight", "crystal light kind")
	eq(sources.Crystal.FixtureMaterial, "Neon", "crystal fixture material")
	assert(sources.Crystal.Color[1] > sources.Crystal.Color[2], "crystal light is not purple")
	assert(sources.Crystal.Color[3] > sources.Crystal.Color[2], "crystal light is not purple")
	eq(sources.Fungus.Kind, "PointLight", "fungus light kind")
	eq(sources.Fungus.FixtureMaterial, "Neon", "fungus fixture material")
	assert(sources.Fungus.Color[2] > sources.Fungus.Color[1], "fungus light is not teal")
	assert(sources.Fungus.Color[3] > sources.Fungus.Color[1], "fungus light is not teal")
	assert(
		sources.Crystal.Range >= 18 and sources.Fungus.Range >= 18,
		"NestInterior leaves black corners"
	)
end)

test("default project Lighting matches Station", function()
	local project = serde.decode("json", fs.readFile("default.project.json"))
	local baked = project.tree.Lighting
	local station = LightingPresets.Station
	assertSame(station.Lighting, baked["$properties"], "Lighting")
	for _, sectionName in { "Atmosphere", "Bloom", "ColorCorrection" } do
		assertSame(station[sectionName], baked[sectionName]["$properties"], sectionName)
	end
	for key, value in station.Sky do
		if key ~= "Tint" then
			eq(baked.Sky["$properties"][key], value, "Sky." .. key)
		end
	end
	assertSame(station.Sky.Tint, station.ColorCorrection.TintColor, "Sky.Tint")
end)
