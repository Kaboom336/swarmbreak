-- Production coordinate contract, derived from the reviewed v4 scene.
local G = {}
-- Regenerate test/navigation stations from the same centerlines used by Builder.
local R = require(script.Parent.Fix2Routes).waypoints(require(script.Parent.RouteData))
G.Nest = { x = 0, y = 48, z = 96 }
G.Camp = { x = -7, y = 48, z = 110 }
G.Portal = { x = 0, y = 0, z = -136 }
-- The existing fork is the first broad, level junction after the descent.
-- Keep the physical court and every test station on this shared placement.
G.PvpCourt = { x = 0, y = 0, z = 42 }
local function point(x, y, z)
	return { x = x, y = y, z = z, kind = "Walk" }
end
local function append(out, name, reverse)
	local route = R[name]
	for n = 1, #route do
		local p = table.clone(route[if reverse then #route + 1 - n else n])
		p.name = name .. " " .. n
		if name == "shelf" or name == "spiral" then
			p.kind = "ClimbRamp"
		end
		table.insert(out, p)
	end
end
function G.protected(x, z, r)
	r = r or 0
	return math.abs(x) <= 24 + r and z >= -156 - r and z <= -116 + r
end
function G.approach()
	local out = { point(0, 0, -136) }
	for _, name in { "bridge_south", "bridge", "fork_link", "spiral", "summit_radial" } do
		append(out, name, true)
	end
	table.insert(out, point(0, 48, 96))
	return out
end
function G.carry()
	local out = { point(0, 48, 108) }
	for _, name in { "summit_radial", "shelf", "shelf_link", "bridge", "bridge_south" } do
		append(out, name, false)
	end
	-- Stop inside the protected rectangle, with a margin beyond its boundary.
	table.insert(out, point(0, 0, -120))
	for i, p in out do
		p.name = p.name or "camp/return " .. i
	end
	out[#out].kind = "Return"
	return out
end
function G.assemble(_config, seed)
	return {
		seed = seed,
		version = 4,
		pieces = {},
		solids = {},
		ramps = {},
		sockets = {},
		routes = { Quick = G.approach(), Ridge = R.west, Grove = R.east },
		crossLinks = { R.north_crosslink, R.south_crosslink },
		jumps = {
			{ from = point(148, 20, -24), to = point(148, 22, -40), gap = 4 },
			{ from = point(148, 22, -40), to = point(148, 24, -56), gap = 4 },
		},
		gullies = { { x = 0, z = 0, w = 158, d = 36 } },
	}
end
function G.dropPoints()
	local out = {}
	for name, route in R do
		-- Optional pad approaches/recovery and ravine floor are not drop sockets.
		if not name:match("^jump") and not name:match("^ravine") then
			for i, p in route do
				local previous = route[i - 1] or p
				local length = math.sqrt((p.x - previous.x) ^ 2 + (p.y - previous.y) ^ 2 + (p.z - previous.z) ^ 2)
				for j = 1, math.max(1, math.ceil(length / 2)) do
					local t = j / math.max(1, math.ceil(length / 2))
					local q = point(
						previous.x + (p.x - previous.x) * t,
						previous.y + (p.y - previous.y) * t,
						previous.z + (p.z - previous.z) * t
					)
					if not G.protected(q.x, q.z, 3) then
						table.insert(out, q)
					end
				end
			end
		end
	end
	table.insert(out, G.Nest)
	-- Reachable rim candidates, validated by production floor/body clearance.
	for x = -72, 72, 2 do
		table.insert(out, point(x, 0, 24))
		if x <= -36 or x >= -8 then
			table.insert(out, point(x, 0, -24))
		end
	end
	for z = -12, 12, 2 do
		table.insert(out, point(-84, 0, z))
		table.insert(out, point(84, 0, z))
	end
	return out
end
function G.pvpRoutes()
	local court = point(G.PvpCourt.x, G.PvpCourt.y, G.PvpCourt.z)
	local dummy = { point(0, 48, 96), point(0, 48, 108) }
	for _, name in { "summit_radial", "spiral", "fork_link" } do
		append(dummy, name, false)
	end
	local tester = { point(0, 0, -136) }
	for _, name in { "bridge_south", "bridge" } do
		append(tester, name, true)
	end
	return {
		Tester = tester,
		Dummy = dummy,
		Pacing = { court, point(-4, 0, 42), court },
		Mercy = { court, point(-7, 0, 42), court },
		Leave = { court, point(-7, 0, 42) },
		Winner = { court },
	}
end
function G.decorate(root)
	local data = require(script.Parent.Data)
	local seed
	for _, item in data do
		if item.name == "GoldenAcorn" then
			seed = item
		end
	end
	assert(seed, "reviewed acorn geometry")
	root.Shape = Enum.PartType[seed.shape]
	root.Size = Vector3.new(unpack(seed.size))
	root.Material = Enum.Material[seed.material]
	root.Color = Color3.fromRGB(unpack(seed.color))
	for _, item in data do
		if item.name == "AcornCap" or item.name == "AcornStem" then
			local p = Instance.new("Part")
			p.Name = item.name
			p.Shape = Enum.PartType[item.shape]
			p.Size = Vector3.new(unpack(item.size))
			p.Color = Color3.fromRGB(unpack(item.color))
			p.Material = Enum.Material[item.material]
			local r, v = item.rotation, item.position
			p.CFrame = root.CFrame
				* CFrame.new(
					v[1] - seed.position[1],
					v[2] - seed.position[2],
					v[3] - seed.position[3],
					r[1],
					r[2],
					r[3],
					r[4],
					r[5],
					r[6],
					r[7],
					r[8],
					r[9]
				)
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.Parent = root
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
end
function G.install(Layout)
	Layout.protected = G.protected
	Layout.assemble = G.assemble
	Layout.loopCarrySteps = G.carry
	Layout.dropPoints = G.dropPoints
	Layout.pvpRoutes = G.pvpRoutes
	Layout.referencePoints = function()
		return { G.Nest, G.Camp, point(110, 20, -60) }
	end
	Layout.hillPaths = function()
		return { R.spiral, R.shelf, R.east_climb }
	end
	Layout.dodgePoints = function()
		return { point(0, 48, 108), point(20, 48, 108) }
	end
	Layout.validate = function(_, l)
		assert(l.version == 4 and #l.routes.Quick > 100 and #G.dropPoints() > 100, "v4 route contract")
		assert(not G.protected(G.Nest.x, G.Nest.z, 22), "camp protected")
		return true
	end
	Layout.signature = function(l)
		return "MeadowV4:" .. l.seed
	end
	Layout.selfTest = function(config, log)
		Layout.validate(config, G.assemble(config, 1))
		log("PASS v4 coordinate contract; physical routes audited separately")
	end
end
return G
