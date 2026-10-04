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

test("Outpost 9 floor uses the OutpostCream theme color", function()
	sameColor(Theme.Floor, { 255, 233, 201 }, "Theme.Floor")
	sameColor(Maps.get("Outpost 9").FloorColor, Theme.Floor, "Outpost 9 floor")
end)

test("four wide flat-colour lanes radiate from the arena centre", function()
	eq(#Theme.LaneStripes, 4, "lane stripe count")
	for index, stripe in Theme.LaneStripes do
		assert(stripe.Width >= 4, "lane stripe " .. index .. " is not wide")
		assert(stripe.Length >= 60, "lane stripe " .. index .. " is too short")
		assert(stripe.Thickness <= 0.15, "lane stripe " .. index .. " is not thin")
		eq(stripe.Material, "SmoothPlastic", "lane stripe " .. index .. " material")
		eq(stripe.CanCollide, false, "lane stripe " .. index .. " collision")
		local expectedColor = if index % 2 == 1 then Theme.SignalOrange else Theme.OutpostShade
		assert(
			stripe.Color[1] == expectedColor[1]
				and stripe.Color[2] == expectedColor[2]
				and stripe.Color[3] == expectedColor[3],
			"lane stripe " .. index .. " has the wrong color"
		)
	end
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
	eq(station.Lighting.ClockTime, 18.5, "Station ClockTime")
	assert(station.Lighting.Brightness >= 2.5, "Station is not bright")
	assert(station.Atmosphere.Density <= 0.15, "Station atmosphere is too dense")
	sameColor(LightingPresets.DuskGradient.Horizon, { 1, 0.7019607843, 0.4784313725 }, "horizon")
	sameColor(LightingPresets.DuskGradient.Top, { 0.4784313725, 0.3098039216, 0.8392156863 }, "top")
	eq(LightingPresets.DuskGradient.CloudSea, true, "cloud sea")
end)
