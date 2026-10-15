-- Vertical ray/convex native-part intersection, including WedgePart slope faces.
-- Spatial grid only narrows candidates; intersections use full built CFrames.
local rb = require("@lune/roblox")
local V = rb.Vector3
local M = {}
function M.new(model, include, cellSize)
	cellSize = cellSize or 8
	local grid = {}
	for _, p in model:GetDescendants() do
		if not (p:IsA("BasePart") and p.Anchored and p.CanCollide and p.CanQuery) then
			continue
		end
		if include and not include(p) then
			continue
		end
		assert(p.ClassName == "Part" or p.ClassName == "WedgePart", "unsupported ray shape " .. p.ClassName)
		if p.ClassName == "Part" then
			assert(p.Shape == rb.Enum.PartType.Block, "unsupported collidable shape")
		end
		local h = p.Size / 2
		local planes = {
			{ V.xAxis, h.X },
			{ -V.xAxis, h.X },
			{ V.yAxis, h.Y },
			{ -V.yAxis, h.Y },
			{ V.zAxis, h.Z },
			{
				-V.zAxis,
				h.Z,
			},
		}
		if p.ClassName == "WedgePart" then
			table.insert(planes, { V.new(0, 1, -h.Y / h.Z), 0 })
		end
		local worldPlanes = {}
		for _, plane in planes do
			local n = p.CFrame:VectorToWorldSpace(plane[1])
			table.insert(worldPlanes, { n.X, n.Y, n.Z, plane[2] + n:Dot(p.CFrame.Position), n.Unit })
		end
		local role = p:GetAttribute("SurfaceRole")
		local lane = p:GetAttribute("WalkableLaneFloor")
		local instance = {
			Name = p.Name,
			GetFullName = function() return p:GetFullName() end,
			HasTag = function(_, name) return p:HasTag(name) end,
			GetAttribute = function(_, name)
				return if name == "SurfaceRole" then role elseif name == "WalkableLaneFloor" then lane else p:GetAttribute(name)
			end,
		}
		local q = { part = instance, planes = worldPlanes }
		local lo, hi = V.new(math.huge, math.huge, math.huge), V.new(-math.huge, -math.huge, -math.huge)
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					local v = p.CFrame:PointToWorldSpace(V.new(x * h.X, y * h.Y, z * h.Z))
					lo = V.new(math.min(lo.X, v.X), math.min(lo.Y, v.Y), math.min(lo.Z, v.Z))
					hi = V.new(math.max(hi.X, v.X), math.max(hi.Y, v.Y), math.max(hi.Z, v.Z))
				end
			end
		end
		for x = math.floor(lo.X / cellSize), math.floor(hi.X / cellSize) do
			for z = math.floor(lo.Z / cellSize), math.floor(hi.Z / cellSize) do
				local key = x .. ":" .. z
				grid[key] = grid[key] or {}
				table.insert(grid[key], q)
			end
		end
	end
	return function(origin, direction)
		assert(direction.X == 0 and direction.Z == 0, "vertical ray only")
		local ox, oy, oz, dy = origin.X, origin.Y, origin.Z, direction.Y
		local best, bestT = nil, math.huge
		for _, q in grid[(math.floor(ox / cellSize) + 0) .. ":" .. (math.floor(oz / cellSize) + 0)] or {} do
			local enter, leave, normal, exitNormal = -math.huge, math.huge, nil, nil
			local valid = true
			for _, plane in q.planes do
				local speed = plane[2] * dy
				local dist = plane[4] - plane[1] * ox - plane[2] * oy - plane[3] * oz
				if math.abs(speed) < 1e-8 then
					if dist < -1e-6 then
						valid = false
						break
					end
				elseif speed < 0 then
					local t = dist / speed
					if t > enter then
						enter, normal = t, plane[5]
					end
				else
					local t = dist / speed
					if t < leave then
						leave, exitNormal = t, plane[5]
					end
				end
			end
			local t, n = enter, normal
			if t < 0 then
				t, n = leave, exitNormal
			end
			if valid and enter <= leave + 1e-7 and t >= 0 and t <= 1 and t < bestT then
				bestT = t
				best = { Position = origin + direction * t, Normal = n, Instance = q.part }
			end
		end
		return best
	end
end
return M
