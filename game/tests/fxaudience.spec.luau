--!strict
local FxAudience = load("FxAudience")

local source = { Name = "source" }
local edge = { Name = "edge" }
local outside = { Name = "outside" }
local missing = { Name = "missing" }
local origin = { x = 0, y = 0, z = 0 }

test("radius includes its edge and excludes players beyond it", function()
	local radius = FxAudience.radiusFor("swing")
	assert(radius ~= nil, "swing must have a radius")
	local players = { edge, outside }
	local selected = FxAudience.selectPlayers(players, {
		[edge] = { x = radius, y = 0, z = 0 },
		[outside] = { x = radius + 0.001, y = 0, z = 0 },
	}, origin, radius, nil)

	eq(#selected, 1, "only the edge player")
	eq(selected[1], edge, "edge player included")
end)

test("players with missing characters are omitted", function()
	local selected = FxAudience.selectPlayers({ edge, missing }, {
		[edge] = { x = 1, y = 0, z = 0 },
	}, origin, 10, nil)
	eq(#selected, 1, "missing character omitted")
	eq(selected[1], edge, "positioned player retained")
end)

test("source player is always included exactly once", function()
	local selected = FxAudience.selectPlayers({ source, edge }, {
		[edge] = { x = 1, y = 0, z = 0 },
	}, origin, 10, source)
	eq(#selected, 2, "source plus nearby player")
	eq(selected[1], source, "source included without a position")

	local absentSource = FxAudience.selectPlayers({}, {}, origin, 10, source)
	eq(#absentSource, 1, "source outside player snapshot included")
	eq(absentSource[1], source, "absent source")
end)

test("coalescing keys share only the same short bucket and identity", function()
	local first = FxAudience.coalescingKey("death", origin, 1.001, "7")
	local sameBucket = FxAudience.coalescingKey("death", origin, 1.049, "7")
	local nextBucket = FxAudience.coalescingKey("death", origin, 1.05, "7")
	local otherEffect = FxAudience.coalescingKey("tell", origin, 1.001, "7")

	eq(first, sameBucket, "same effect bucket")
	assert(first ~= nextBucket, "next bucket needs a new key")
	assert(first ~= otherEffect, "effect name is part of key")
end)

test("announcements remain global while combat effects have radii", function()
	eq(FxAudience.isGlobal("sound"), true, "sound announcement")
	eq(FxAudience.isGlobal("futureAnnouncement"), true, "unknown effects stay global")
	eq(FxAudience.isGlobal("shot"), false, "shot is positional")
	assert(FxAudience.radiusFor("shot") ~= FxAudience.radiusFor("swing"), "per-effect radii")
end)
