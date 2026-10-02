local ArenaLayout = load("ArenaLayout")
local LightingPresets = load("LightingPresets")
local Maps = load("Maps")
local Theme = load("Theme")

local function sameColor(actual, expected, message)
	for channel = 1, 3 do
		eq(actual[channel], expected[channel], message .. " channel " .. channel)
	end
end

local function overlapsCentralSquare(piece)
	local halfWidth = piece.Width / 2
	local halfDepth = piece.Depth / 2
	return piece.x - halfWidth < 45
		and piece.x + halfWidth > -45
		and piece.z - halfDepth < 45
		and piece.z + halfDepth > -45
end

test("cover footprints leave the central 90 by 90 fight space open", function()
	for index, piece in ArenaLayout.Props do
		assert(
			not overlapsCentralSquare(piece),
			"layout piece " .. index .. " enters the fight space"
		)
		if piece.Kind == "LowWall" then
			assert(piece.Height <= 3, "low ledge " .. index .. " is taller than 3 studs")
		else
			eq(piece.Kind, "Pillar", "outer-ring cover kind")
		end
	end
end)

test("station floor uses the concrete theme color", function()
	sameColor(Theme.Floor, { 155, 158, 168 }, "Theme.Floor")
	sameColor(Maps.get("Station Deck").FloorColor, Theme.Floor, "Station Deck floor")
end)

test("every arena corner has a crystal cluster", function()
	local corners = {
		["-1,-1"] = false,
		["-1,1"] = false,
		["1,-1"] = false,
		["1,1"] = false,
	}
	for _, cluster in ArenaLayout.CrystalClusters do
		if math.abs(cluster.x) >= 60 and math.abs(cluster.z) >= 60 then
			corners[tostring(math.sign(cluster.x)) .. "," .. tostring(math.sign(cluster.z))] = true
		end
	end
	for corner, present in corners do
		assert(present, "corner " .. corner .. " has no crystal cluster")
	end
end)

test("Station preset is dusk", function()
	local station = LightingPresets.Station
	eq(station.Lighting.ClockTime, 17, "Station ClockTime")
	eq(station.Lighting.ExposureCompensation, -0.3, "Station ExposureCompensation")
	assert(station.Sky.StarCount > 0, "Station sky is still daytime")
end)
