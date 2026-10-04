local fs = require("@lune/fs")

test("OutlinePool returns at most the nearest 20 targets", function()
	local OutlinePool = load("OutlinePool")
	local candidates = {}
	for index = 30, 1, -1 do
		table.insert(candidates, {
			Target = "target-" .. index,
			Distance = index,
		})
	end

	local nearest = OutlinePool.nearest(candidates)
	eq(OutlinePool.MaxActive, 20, "outline cap")
	eq(#nearest, 20, "active outlines")
	for index, candidate in nearest do
		eq(candidate.Distance, index, "nearest target " .. index)
	end
end)

test("client outlines are dark and outline-only", function()
	local source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/EnemyHighlights.client.luau")
	assert(source:find("OutlinePool.nearest", 1, true), "client does not use OutlinePool")
	assert(source:find("FillTransparency = 1", 1, true), "highlight must be outline-only")
	assert(source:find("Theme.ChitinDark", 1, true), "outline is not dark")
end)
