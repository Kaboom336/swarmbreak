-- Actual mounted Builder + production drop resolver, not idealized route planes.
local fs, rb, luau, serde = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/serde")
local Ray = require("./meadow-v4/OfflineRay")
assert(require("./fix4-fixtures"))
assert(require("./meadow-v4/clearance-fixtures"))
local V = rb.Vector3
local path = "slice-v2/prototype/guardian-greybox.rbxl"
local place = rb.deserializePlace(fs.readFile(path))
local folder = place.ReplicatedStorage.MeadowV4
local cache = {}
local function load(node)
	if cache[node] then
		return cache[node]
	end
	cache[node] = luau.load(node.Source, {
		environment = {
			script = node,
			require = load,
			Vector3 = V,
			CFrame = rb.CFrame,
			Color3 = rb.Color3,
			Enum = rb.Enum,
			Instance = rb.Instance,
		},
	})()
	return cache[node]
end
local D, R = load(folder.ReachableDrops), load(folder.RouteData)
local model = load(folder.Builder).build(rb.Instance.new("Folder"), V.zero)
for _, p in model:GetChildren() do
	local cat = p:GetAttribute("MeadowV4Category")
	if cat == "keeper" or p.Name == "GoldenAcorn" or p.Name == "AcornCap" or p.Name == "AcornStem" then
		p:Destroy()
	end
end
local solid = Ray.new(model)
local lane = Ray.new(model, function(p)
	return p:GetAttribute("WalkableLaneFloor") == true
end)
local centers = {}
for _, route in R do
	for i = 2, #route do
		local a, b = route[i - 1], route[i]
		local u, v = V.new(a.x, a.y, -a.z), V.new(b.x, b.y, -b.z)
		local count = math.max(1, math.ceil((v - u).Magnitude))
		for j = 0, count do
			table.insert(centers, u:Lerp(v, j / count))
		end
	end
end
-- Negative fixtures: previously all these could be labeled generic Floor.
for _, category in
	{
		"terrace",
		"boulder",
		"cover",
		"bridge_structure",
		"tunnel_rock",
		"tunnel_roof",
		"tunnel_hill",
		"wall",
		"fence",
		"prop",
	}
do
	assert(not D.isLane({ name = "edging", category = category, collidable = true }, R), "scenery allowed " .. category)
end
-- Stacked lanes and misleading Floor scenery must never bypass the allowlist/height band.
do
	local fixture = rb.Instance.new("Model")
	local function part(name, y, height, isLane)
		local p = rb.Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, V.new(40, height, 40), rb.CFrame.new(0, y, 0)
		p.Anchored, p.CanCollide, p.CanQuery = true, true, true
		p:SetAttribute("SurfaceRole", "Floor")
		p:SetAttribute("WalkableLaneFloor", isLane)
		p.Parent = fixture
		return p
	end
	part("lane", -1, 2, true)
	part("lower stacked lane", -11, 2, true)
	local roof = part("ceiling", 7, 1, false)
	local function rays()
		return Ray.new(fixture, function(p)
			return p:GetAttribute("WalkableLaneFloor") == true
		end),
			Ray.new(fixture)
	end
	local l, s = rays()
	assert(D.floor(V.new(0, 3, 0), l, V).Y == 0, "roof mistaken for carrier floor")
	assert(not D.valid(V.zero, 0, l, s, V), "ceiling did not reject headroom")
	roof:Destroy()
	local rock = part("rock lip", 2, 4, false)
	l, s = rays()
	assert(not D.valid(V.zero, 0, l, s, V), "rock lip accepted")
	rock:Destroy()
	l, s = rays()
	assert(D.valid(V.zero, 0, l, s, V), "clear lane rejected")
	assert(not D.valid(V.zero, 3, l, s, V), "floor more than two below accepted")
	assert(not D.valid(V.zero, -3, l, s, V), "floor more than two above accepted")
	fixture:Destroy()
end
local rules = load(place.ReplicatedStorage.GreyboxLootRules)
local cfg = luau.load(place.ReplicatedStorage.GreyboxConfig.Source, { environment = { workspace = place.Workspace } })()
local rs = place.ReplicatedStorage
local adapter = luau.load(place.ServerScriptService.GreyboxArena.Source, {
	environment = {
		Vector3 = V,
		Enum = rb.Enum,
		Color3 = rb.Color3,
		RaycastParams = {
			new = function()
				return {}
			end,
		},
		game = {
			GetService = function(_, name)
				return if name == "ReplicatedStorage"
					then setmetatable({
						WaitForChild = function(_, child)
							return rs[child]
						end,
					}, {
						__index = function(_, child)
							return rs[child]
						end,
					})
					else {}
			end,
		},
		require = function(node)
			if node == rs.GreyboxConfig then
				return cfg
			end
			if node == rs.GreyboxLayout or node == rs.GreyboxScene then
				return {}
			end
			return load(node)
		end,
		workspace = {
			Raycast = function(_, o, d, params)
				return (if params.FilterType == rb.Enum.RaycastFilterType.Include then lane else solid)(o, d)
			end,
		},
	},
})()
local arena = { v4 = model, origin = V.zero, params = {} }
local rows, total, routeCounts, modes = {}, 0, {}, {}
local graph = D.graph(R, V, V.zero)
do
	local function segment(route, index, y, z)
		return { route = route, index = index, a = V.new(-20, y, z), b = V.new(20, y, z) }
	end
	local own = segment("spiral", 18, 0, 0)
	assert(D.connected(own, segment("spiral", 19, 0, 0)), "adjacent spiral segment")
	assert(not D.connected(own, segment("spiral", 21, 4, 0)), "stacked spiral shortcut")
	assert(not D.connected(segment("bridge", 2, 20, 0), segment("ravine", 2, 0, 0)), "bridge/ravine shortcut")
	assert(not D.connected(segment("tunnel", 2, 0, 0), segment("hill", 2, 20, 0)), "tunnel/hill shortcut")
	assert(not D.connected(own, segment("unconnected", 18, 0, 2)), "same-height disconnected lane")
end
local function check(point, floorY, label, carrier)
	carrier = carrier or V.new(point.X, floorY, point.Z)
	local q, mode = adapter.dropSocket(arena, point, carrier)
	total += 1
	modes[mode] = (modes[mode] or 0) + 1
	if not q then
		table.insert(rows, { label = label, reason = mode, point = { point.X, point.Y, point.Z }, floorY = floorY })
		return
	end
	assert(math.abs(q.Y - floorY) <= 2, "carrier height bound " .. label)
	assert(D.valid(q, floorY, lane, solid, V), "unreachable settled drop " .. label)
	assert(D.connected(D.segment(carrier, graph), D.segment(q, graph)), "disconnected landing " .. label)
	local h = lane(q + V.new(0, 0.2, 0), V.new(0, -0.4, 0))
	assert(h and h.Instance:GetAttribute("WalkableLaneFloor") == true, "settled on scenery " .. label)
	if mode == "local" then
		assert(V.new(q.X - point.X, 0, q.Z - point.Z).Magnitude <= 12.001, "radius")
	end
	-- All knock sources share the same authoritative transition and conserve ID/deadline.
	for _, source in { "Pvp", "Guardian", "Blast", "Trap", "Drop" } do
		local r = rules.new(cfg)
		local actor = {}
		local s = rules.actor(r, actor)
		s.phase, s.completed = "Run", 1
		local item = rules.spawn(r, point)
		item.state, item.holder, item.firstPickup, item.escapeDeadline = "Carried", actor, 1, 100
		s.item = item
		local id = item.id
		local ok = if source == "Drop" then rules.drop(r, actor, 10, q) else rules.hit(r, actor, source, 10, q)
		assert(ok and item.state == "Dropped" and item.position == q, "knock/drop " .. source)
		assert(item.id == id and item.escapeDeadline == 100, "identity/deadline " .. source)
		rules.audit(r)
	end
	return q, mode
end
-- Studio pass-3 shelf position, translated by the production (0,76,-360) origin.
local shelf = V.new(84.43, 39.81, -108)
local floor = D.floor(shelf, lane, V)
assert(floor, "reported shelf carrier floor")
local q = assert(check(shelf, floor.Y, "pass3 east shelf regression"))
assert(q.Y < 41, "old elevated shelf drop survived")
local regression =
	{ carrier = { shelf.X, shelf.Y + 76, shelf.Z - 360 }, floor = floor.Y + 76, settled = { q.X, q.Y + 76, q.Z - 360 } }
-- Pass 4: carrier roots must not use the deck above their feet, even on overlap.
local pass4 = V.new(86.3, 117.2 - 76, -468.3 + 360)
local prior = assert(lane(pass4 + V.new(0, 1, 0), V.new(0, -12, 0)), "pass4 underlying lane")
-- This captured root is airborne (>5 studs over the mounted floor): retain the
-- last grounded lane, rather than manufacture a new floor from the knock pose.
local pass4Floor = assert(D.floor(prior.Position + V.new(0, 3, 0), lane, V), "pass4 cached grounded floor")
assert(D.floor(pass4, lane, V) == nil, "airborne pose must use cached lane")
local pass4Drop = assert(check(pass4, pass4Floor.Y, "pass4 east descending shelf", pass4Floor))
assert(math.abs(pass4Drop.Y - pass4Floor.Y) <= 2, "pass4 upper lane landing")
-- Actual spiral/shelf, bridge/ravine and tunnel/hill rays, plus hostile remote
-- knock targets. The carrier reference is captured before any displacement.
for _, name in { "spiral", "shelf", "bridge", "tunnel_trunk" } do
	local route = assert(R[name], name)
	for i = 2, #route do
		local a, b = route[i - 1], route[i]
		local root = V.new((a.x + b.x) / 2, (a.y + b.y) / 2 + 3, -(a.z + b.z) / 2)
		local f = assert(D.floor(root, lane, V), "stacked carrier " .. name)
		check(root + V.new(40, 8, 0), f.Y, "stacked knock " .. name .. "/" .. i, f)
	end
end
-- Sample every route segment at <=2 studs, across the lane and with lateral knock origins.
for name, route in R do
	local before = total
	for i = 2, #route do
		local a, b = route[i - 1], route[i]
		local dx, dz = b.x - a.x, b.z - a.z
		local run = math.sqrt(dx * dx + dz * dz)
		if run < 0.001 then
			continue
		end
		local steps = math.max(1, math.ceil(run / 2))
		for j = 0, steps do
			local t = j / steps
			for _, side in { -6, -3, 0, 3, 6 } do
				local point =
					V.new(a.x + dx * t + dz / run * side, a.y + (b.y - a.y) * t + 3, -a.z - dz * t + dx / run * side)
				-- Carrier floor is measured on the lane before the knock, not on a prop.
				local carrier = V.new(a.x + dx * t, point.Y, -a.z - dz * t)
				local f = D.floor(carrier, lane, V)
				check(point, f and f.Y or carrier.Y - 3, name .. "/" .. i .. "/" .. j .. "/" .. side)
			end
		end
	end
	routeCounts[name] = total - before
	print(name, routeCounts[name], "failures", #rows)
end
-- Force radius failure: the nearest route centre at the same floor is mandatory.
local fallback, mode = check(shelf + V.new(500, 0, 0), floor.Y, "route fallback", floor)
assert(fallback and mode == "route", "route centre fallback not exercised")
-- No matching level must fail closed, never choose another shelf or a roof.
assert(D.settle(shelf, 1000, centers, lane, solid, V) == nil, "wrong-level fallback")
local report = {
	state = if #rows == 0 then "PASS" else "FAIL",
	checks = total,
	sources_per_check = { "Pvp", "Guardian", "Blast", "Trap", "Drop" },
	routes = routeCounts,
	modes = modes,
	regression = regression,
	failures = rows,
	Studio = "UNKNOWN",
}
report.pass4 = { root = { 86.3, 117.2, -468.3 }, floor = pass4Floor.Y + 76, landing = { pass4Drop.X, pass4Drop.Y + 76, pass4Drop.Z - 360 } }
fs.writeFile("prototype/FIX4-DROPS.json", serde.encode("json", report, true))
for i = 1, math.min(15, #rows) do
	print(serde.encode("json", rows[i]))
end
print(report.state, total, "reachable drop samples; failures", #rows)
assert(#rows == 0, "reachable drops regression")
