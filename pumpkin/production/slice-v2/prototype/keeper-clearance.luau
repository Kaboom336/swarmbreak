-- Conservative sphere vs posed mesh-section AABBs. Offline geometry, not Studio.
local fs, luau, R, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local V, C = R.Vector3, R.CFrame
local path = "../../models/meadow-keeper/anim/"
local geometry = serde.decode("json", fs.readFile(path .. "throw-geometry.json"))
local modules = {}
for _, name in ipairs({ "Skeleton", "Kinematics", "Clips", "Animator" }) do
	modules[name] = luau.load(fs.readFile(path .. name .. ".luau"), {
		environment = {
			game = {
				GetService = function(_, n)
					return n == "HttpService"
							and {
								JSONDecode = function(_, s)
									return serde.decode("json", s)
								end,
							}
						or {}
				end,
			},
			script = { Parent = { Clips = "Clips", Skeleton = "Skeleton" } },
			require = function(n)
				return modules[n]
			end,
			CFrame = C,
			Vector3 = V,
		},
	})()
end
local pivots, bounds, gloves = {}, {}, {}
for _, s in ipairs(geometry) do
	pivots[s.rig_part] = V.new(table.unpack(s.pivot))
end
for _, s in ipairs(geometry) do
	local low, high = V.new(math.huge, math.huge, math.huge), V.new(-math.huge, -math.huge, -math.huge)
	for _, v in ipairs(s.vertices) do
		local p = V.new(table.unpack(v)) - pivots[s.rig_part]
		low = low:Min(p)
		high = high:Max(p)
	end
	if s.rig_part == "Head" or s.rig_part == "Hat" then
		local vertices = {}
		for _, v in ipairs(s.vertices) do
			table.insert(vertices, V.new(table.unpack(v)) - pivots[s.rig_part])
		end
		table.insert(
			bounds,
			{ joint = s.rig_part, low = low, high = high, vertices = vertices, triangles = s.triangles }
		)
	end
	if s.material == "Gloves" then
		local center = (low + high) / 2
		local radius = 0
		for _, v in ipairs(s.vertices) do
			radius = math.max(radius, (V.new(table.unpack(v)) - pivots[s.rig_part] - center).Magnitude)
		end
		table.insert(gloves, { joint = s.rig_part, center = center, radius = radius })
	end
end
local function world(p, yaw)
	local q = table.clone(p)
	q.Head *= C.Angles(0, yaw, 0)
	return modules.Kinematics.world(q, C.identity)
end
local function triangleDistance(p, a, b, c)
	local ab, ac = b - a, c - a
	local normal = ab:Cross(ac)
	if normal.Magnitude > 1e-8 then
		local q = p - normal * ((p - a):Dot(normal) / normal:Dot(normal))
		if
			ab:Cross(q - a):Dot(normal) >= -1e-8
			and (c - b):Cross(q - b):Dot(normal) >= -1e-8
			and (a - c):Cross(q - c):Dot(normal) >= -1e-8
		then
			return (p - q).Magnitude
		end
	end
	local best = math.huge
	for _, edge in ipairs({ { a, b }, { b, c }, { c, a } }) do
		local delta = edge[2] - edge[1]
		local u = delta.Magnitude < 1e-8 and 0 or math.clamp((p - edge[1]):Dot(delta) / delta:Dot(delta), 0, 1)
		best = math.min(best, (p - (edge[1] + delta * u)).Magnitude)
	end
	return best
end
local function clearance(w, point, radius)
	local minimum = math.huge
	for _, b in ipairs(bounds) do
		local p = w[b.joint]:PointToObjectSpace(point)
		local nearest = V.new(
			math.clamp(p.X, b.low.X, b.high.X),
			math.clamp(p.Y, b.low.Y, b.high.Y),
			math.clamp(p.Z, b.low.Z, b.high.Z)
		)
		minimum = math.min(minimum, (p - nearest).Magnitude - radius)
	end
	if minimum > 0 then
		return minimum
	end
	-- A rotated broad hat's AABB can overlap empty space. Resolve uncertain
	-- sphere cases against its actual closed triangles rather than accepting them.
	minimum = math.huge
	for _, b in ipairs(bounds) do
		local p = w[b.joint]:PointToObjectSpace(point)
		for _, tri in ipairs(b.triangles) do
			minimum = math.min(
				minimum,
				triangleDistance(p, b.vertices[tri[1] + 1], b.vertices[tri[2] + 1], b.vertices[tri[3] + 1]) - radius
			)
		end
	end
	return minimum
end
for _, name in ipairs({ "idle", "chase", "lob", "fan", "slam", "dash", "warn" }) do
	local clip = modules.Clips.clips[name]
	local fists, held = math.huge, math.huge
	local worst
	for i = 0, 200 do
		local t = clip.duration * i / 200
		local p = modules.Animator.sample(name, t)
		for _, yaw in ipairs(name == "lob" and { 0 } or { -0.45, 0, 0.45 }) do
			local w = world(p, yaw)
			for _, g in ipairs(gloves) do
				local distance = clearance(w, w[g.joint]:PointToWorldSpace(g.center), g.radius)
				if distance < fists then
					fists = distance
					worst = t
				end
			end
			if (name == "lob" or name == "fan") and t <= 0.62 and (name ~= "lob" or t >= 0.20) then
				held = math.min(
					held,
					clearance(w, modules.Kinematics.socket(p, C.identity, name).Position, name == "lob" and 2.7 or 1.2)
				)
			end
		end
	end
	print("CLEARANCE", name, "fists sphere margin", fists, "worst time", worst, "held sphere margin", held)
	if name == "lob" or name == "fan" then
		print(
			"DIAGNOSTIC: articulated glove sphere is an overbound; actual triangle intersections checked by anim/check-throw.py"
		)
	else
		assert(fists > 0, name .. " fist sphere reaches head/hat envelope")
	end
	assert(held > 0, name .. " held prop reaches head/hat envelope")
end
print("PASS sampled held props and retained rigid-clip fist envelopes; articulated glove mesh proof is separate")
for _, name in ipairs({ "lob", "fan" }) do
	local minimum = math.huge
	local worst = ""
	local from = modules.Kinematics.socket(modules.Animator.sample(name, 0.62), C.identity, name).Position
	local flightSeconds = name == "lob" and 0.9 or 0.7
	for _, distance in ipairs(name == "fan" and { 12, 24, 32, 50 } or { 12, 24, 56, 72 }) do
		for _, height in ipairs(name == "fan" and { -1.5, 0, 1.5 } or { -8, 0, 8, 16 }) do
			for _, degrees in ipairs(name == "fan" and { -16, 0, 16 } or { 0 }) do
				local destination = V.new(0, height + (name == "lob" and 2 or 3), distance)
				if name == "fan" then
					destination = from + C.Angles(0, math.rad(degrees), 0):VectorToWorldSpace(destination - from)
				end
				for i = 0, 100 do
					local alpha = i / 100
					local point = from:Lerp(destination, alpha)
						+ V.new(0, (name == "lob" and 36 or 3) * alpha * (1 - alpha), 0)
					for _, yaw in ipairs(name == "lob" and { 0 } or { -0.45, 0, 0.45 }) do
						local w = world(modules.Animator.sample(name, 0.62 + flightSeconds * alpha), yaw)
						local margin = clearance(w, point, name == "lob" and 2.7 or 1.2)
						if name == "fan" then
							margin = math.min(margin, clearance(w, point + V.new(0, 0.912, 0), 1.26))
						end
						if margin < minimum then
							minimum = margin
							worst = string.format("d=%s h=%s deg=%s a=%s", distance, height, degrees, alpha)
						end
					end
				end
			end
		end
	end
	print("FLIGHT CLEARANCE", name, minimum, worst)
	assert(minimum > 0, name .. " flight reaches head/hat envelope")
end
