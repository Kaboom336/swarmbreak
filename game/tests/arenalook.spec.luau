local fs = require("@lune/fs")
local serde = require("@lune/serde")

local ArenaLayout = load("ArenaLayout")
local ArenaModelGenerator = load("ArenaModelGenerator")
local LightingPresets = load("LightingPresets")
local Theme = load("Theme")

local function relativeLuminance(color)
	local function linear(channel)
		channel /= 255
		if channel <= 0.04045 then
			return channel / 12.92
		end
		return ((channel + 0.055) / 1.055) ^ 2.4
	end

	return 0.2126 * linear(color[1]) + 0.7152 * linear(color[2]) + 0.0722 * linear(color[3])
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

local function inspectNeon(value, path)
	if type(value) ~= "table" then
		return
	end
	if value.className == "Part" and value.properties.Material == "Neon" then
		for axis, size in value.properties.Size do
			assert(size <= 12, path .. " neon axis " .. axis .. " exceeds 12 studs")
		end
	end
	for key, child in value do
		inspectNeon(child, path .. "." .. tostring(key))
	end
end

test("arena floor uses OutpostCream and stays lighter than enemies", function()
	for channel = 1, 3 do
		eq(Theme.Floor[channel], Theme.OutpostCream[channel], "floor channel " .. channel)
	end
	assert(relativeLuminance(Theme.Floor) > relativeLuminance(Theme.Chitin), "floor is not lighter")
end)

test("arena contains no oversized neon parts", function()
	for _, output in ArenaModelGenerator.build(ArenaLayout, Theme) do
		inspectNeon(output.Contents, output.Name)
	end
end)

test("Station uses the S0 dusk preset", function()
	local station = LightingPresets.Station
	eq(station.Lighting.ClockTime, 18.5, "ClockTime")
	eq(station.Lighting.ExposureCompensation, 0, "ExposureCompensation")
	eq(station.Lighting.Brightness, 2.5, "Brightness")
	eq(station.Bloom.Threshold, 0.9, "Bloom threshold")
	eq(station.ColorCorrection.Contrast, 0.1, "color correction contrast")
end)

test("default project Lighting equals Station", function()
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
end)

test("survivor board lives in the Base only", function()
	assert(
		not fs.isFile("src/Workspace/Arena/LeaderboardWall.model.json"),
		"board is still in Arena"
	)
	assert(fs.isFile("src/Workspace/Base/LeaderboardWall.model.json"), "board is missing from Base")
end)
