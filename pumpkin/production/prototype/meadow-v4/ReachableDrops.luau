-- Only authored walking decks qualify; generic SurfaceRole=Floor is insufficient.
local D = {}
local slope = math.cos(math.rad(35.1))
function D.isLane(item, routes)
	if not item.collidable or item.name:match("_Base$") then
		return false
	end
	-- This explicitly authored connector overlaps the west/valley lane decks.
	-- Its name has no numeric route suffix, so the route-name matcher missed it.
	if item.name == "TunnelValleyJoin" then
		return item.category == "lane"
	end
	local authored = item.name:match("^Fix2Lane_(.-)_%d+$") or item.name:match("^Fix2Junction_(.-)_%d+$")
	if authored then
		return item.category == "lane" and routes[authored] ~= nil
	end
	if
		item.category == "court"
		or item.category == "protected"
		or item.category == "portal"
		or item.category == "jump"
	then
		return true
	end
	local route = item.name:match("^(.-)%d+$")
	return routes[route] ~= nil
		and (
			item.category == "lane"
			or item.category == "bridge"
			or item.category == "tunnel_floor"
			or item.category == "jump_access"
		)
end
function D.floor(position, ray, V)
	-- Sample from root + 1, but skip overlapping decks above the carrier's feet.
	local expected = position.Y - 3
	local top = position.Y + 1
	local best, distance = nil, math.huge
	while top >= expected - 2 do
		local h = ray(V.new(position.X, top, position.Z), V.new(0, expected - 2 - top - 0.01, 0))
		if not h then break end
		local delta = math.abs(h.Position.Y - expected)
		if h.Normal.Y >= slope and h.Instance:GetAttribute("WalkableLaneFloor") == true
			and delta <= 2 and delta < distance then
			best, distance = h.Position, delta
		end
		top = h.Position.Y - 0.01
	end
	return best
end
function D.graph(routes, V, origin)
	local graph = {}
	for name, route in routes do
		for i = 2, #route do
			local a, b = route[i - 1], route[i]
			table.insert(graph, { route = name, index = i, a = origin + V.new(a.x, a.y, -a.z), b = origin + V.new(b.x, b.y, -b.z) })
		end
	end
	return graph
end
function D.project(point, segment)
	local d = segment.b - segment.a
	local t = if d:Dot(d) > 0 then math.clamp((point - segment.a):Dot(d) / d:Dot(d), 0, 1) else 0
	return segment.a + d * t
end
function D.segment(point, graph)
	local best, distance = nil, math.huge
	local pointX,pointY,pointZ = point.X,point.Y,point.Z
	for _, segment in graph do
		-- Scalar squared distances avoid allocating several vectors for every
		-- graph edge during thousands of live samples and Heartbeat lookups.
		local m = segment.metrics
		if not m then
			local a,b = segment.a,segment.b
			local dx,dy,dz = b.X-a.X,b.Y-a.Y,b.Z-a.Z
			m = {a.X,a.Y,a.Z,dx,dy,dz,dx*dx+dy*dy+dz*dz}
			segment.metrics = m
		end
		local dx,dy,dz,length = m[4],m[5],m[6],m[7]
		local px, py, pz = pointX-m[1], pointY-m[2], pointZ-m[3]
		local t = if length > 0 then math.clamp((px*dx+py*dy+pz*dz)/length,0,1) else 0
		local x,y,z = px-dx*t,py-dy*t,pz-dz*t
		local d = x*x+y*y+z*z
		if d < distance then
			best, distance = segment, d
		end
	end
	return best
end
function D.connected(a, b)
	if not a or not b then return false end
	if a.route == b.route and math.abs(a.index - b.index) <= 1 then return true end
	-- Cross-route edges require a shared 3D endpoint, never an X/Z crossing.
	return (a.a - b.a).Magnitude < 0.5 or (a.a - b.b).Magnitude < 0.5
		or (a.b - b.a).Magnitude < 0.5 or (a.b - b.b).Magnitude < 0.5
end
function D.valid(point, floorY, laneRay, solidRay, V)
	local function down(x, z)
		return laneRay(V.new(x, floorY + 2.05, z), V.new(0, -4.1, 0))
	end
	local c = down(point.X, point.Z)
	if
		not c
		or c.Normal.Y < slope
		or c.Instance:GetAttribute("WalkableLaneFloor") ~= true
		or math.abs(c.Position.Y - floorY) > 2
	then
		return nil
	end
	for ix = -6, 6 do
		for iz = -6, 6 do
			if ix * ix + iz * iz > 36 then
				continue
			end
			local x, z = point.X + ix * 0.5, point.Z + iz * 0.5
			local h = down(x, z)
			if
				not h
				or h.Normal.Y < slope
				or h.Instance:GetAttribute("WalkableLaneFloor") ~= true
				or math.abs(h.Position.Y - c.Position.Y)
					> ((h.Normal.Y < 0.999 or c.Normal.Y < 0.999) and 2.15 or 1.5)
			then
				return nil
			end
			-- Full collision query rejects edging/rocks even when lane exists beneath.
			-- Start above the body envelope so a four-stud lip cannot contain the
			-- ray origin (Roblox ignores the containing part for such a ray).
			local top = solidRay(V.new(x, c.Position.Y + 8.25, z), V.new(0, -10.45, 0))
			if not top or top.Instance:GetAttribute("WalkableLaneFloor") ~= true
				or math.abs(top.Position.Y - h.Position.Y) > 0.1 then
				return nil
			end
			if solidRay(V.new(x, c.Position.Y + 2.2, z), V.new(0, 6, 0)) then
				return nil
			end
		end
	end
	return c.Position
end
local offsets = {}
for x = -12, 12 do
	for z = -12, 12 do
		if x * x + z * z <= 144 then
			table.insert(offsets, { x = x, z = z, d = x * x + z * z })
		end
	end
end
table.sort(offsets, function(a, b)
	return a.d < b.d
end)
function D.settle(position, floorY, centers, laneRay, solidRay, V, graph, carrier)
	local current = graph and D.segment(carrier or V.new(position.X, floorY, position.Z), graph)
	local neighbours = {}
	if graph then
		for _, segment in graph do
			if D.connected(current, segment) then
				table.insert(neighbours, segment)
			end
		end
	end
	local function permitted(p)
		if not graph then return true end
		local near = false
		for _, segment in neighbours do
			if (D.project(p, segment) - p).Magnitude <= 12 then
				near = true
				break
			end
		end
		return near and D.connected(current, D.segment(p, graph))
	end
	for _, o in offsets do
		local candidate = V.new(position.X + o.x, floorY, position.Z + o.z)
		local p = permitted(candidate) and D.valid(candidate, floorY, laneRay, solidRay, V)
		if p and permitted(p) then
			return p, "local"
		end
	end
	-- Route graph fallback remains on the carrier's floor level, including stacked lanes.
	local candidates = {}
	local fallback = centers
	if current then
		fallback = { D.project(carrier or position, current) }
		local count = math.max(1, math.ceil((current.b - current.a).Magnitude))
		for j = 0, count do
			table.insert(fallback, current.a:Lerp(current.b, j / count))
		end
	end
	for _, p in fallback do
		if math.abs(p.Y - floorY) <= 2 then
			table.insert(candidates, p)
		end
	end
	table.sort(candidates, function(a, b)
		return (a - position).Magnitude < (b - position).Magnitude
	end)
	for _, p in candidates do
		local q = D.valid(p, floorY, laneRay, solidRay, V)
		if q and permitted(q) then
			return q, "route"
		end
	end
	return nil, "no reachable lane at carrier floor"
end
return D
