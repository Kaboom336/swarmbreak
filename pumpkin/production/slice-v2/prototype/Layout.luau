-- Pure scalar layout: same code runs in Studio and Lune. No reward RNG.
local Layout = {}

function Layout.assemble(config, seed, first)
	assert(type(seed) == "number" and seed == seed and seed % 1 == 0, "integer seed required")
	local state = seed % 2147483647
	local function nextInt(n)
		state = (state * 48271) % 2147483647
		return state % n + 1
	end
	local recipes = {
		{ "P02", "P06" },
		{ "P02" },
		{ "P02Short", "P06Short", "P02Short" },
	}
	local travel = table.clone(recipes[first and 1 or nextInt(#recipes)])
	if not first then
		for i = #travel, 2, -1 do
			local j = nextInt(i)
			travel[i], travel[j] = travel[j], travel[i]
		end
	end
	local ids = { "P01" }
	for _, id in travel do
		table.insert(ids, id)
	end
	table.insert(ids, "P07")
	local result = { seed = seed, pieces = {}, route = 0, width = 0, depth = 0 }
	local cursor = -12
	for _, id in ids do
		local p = config.Pieces[id]
		table.insert(result.pieces, {
			id = id,
			z = cursor + p.depth / 2,
			inZ = cursor,
			outZ = id ~= "P07" and cursor + p.depth or nil,
			width = p.width,
			depth = p.depth,
		})
		cursor += p.depth
		result.route += p.route
		result.width = math.max(result.width, p.width)
		result.depth += p.depth
	end
	return result
end

function Layout.validate(config, layout)
	assert(#layout.pieces >= 3 and #layout.pieces <= 5, "piece count")
	assert(layout.route >= 84 and layout.route <= 112, "route bounds")
	assert(layout.width <= 96 and layout.depth <= 144, "island envelope")
	assert(layout.pieces[1].id == "P01" and layout.pieces[#layout.pieces].id == "P07", "terminals")
	local route = 0
	for i, p in layout.pieces do
		local definition = assert(config.Pieces[p.id], "unknown template")
		assert(p.width == definition.width and p.depth == definition.depth, "template bounds")
		assert(p.width >= 12 and p.inZ == p.z - p.depth / 2, "floor/width")
		if i > 1 then
			assert(layout.pieces[i - 1].outZ == p.inZ, "connector gap")
		end
		for j = 1, i - 2 do
			local other = layout.pieces[j]
			assert(other.z + other.depth / 2 < p.z - p.depth / 2, "nonadjacent shortcut")
		end
		route += definition.route
	end
	assert(route == layout.route, "centerline length")
	return true
end

function Layout.signature(layout)
	local values = { tostring(layout.seed), tostring(layout.route) }
	for _, p in layout.pieces do
		table.insert(values, string.format("%s:0,%g:0,%g:0,%s", p.id, p.z, p.inZ, tostring(p.outZ)))
	end
	return table.concat(values, "|")
end

function Layout.selfTest(config, log)
	local seen = {}
	for _, seed in { 101, 202, 303 } do
		local a = Layout.assemble(config, seed, false)
		Layout.validate(config, a)
		local b = Layout.assemble(config, seed, false)
		assert(Layout.signature(a) == Layout.signature(b), "seed replay mismatch")
		seen[table.concat(
			(function()
				local ids = {}
				for _, p in a.pieces do
					table.insert(ids, p.id)
				end
				return ids
			end)(),
			"/"
		)] =
			true
		log("PASS seed=" .. seed .. " " .. Layout.signature(a))
	end
	local count = 0
	for _ in seen do
		count += 1
	end
	assert(count == 3, "three distinct layouts required")
	for seed = 1, 50 do
		Layout.validate(config, Layout.assemble(config, seed, false))
	end
	log("PASS 50-seed sweep; three distinct recipes; identical replays")
end

return Layout
