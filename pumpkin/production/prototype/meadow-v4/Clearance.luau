-- Shared Studio/offline resolve contract. Ray provider returns engine-shaped hits.
local C = {}
function C.resolve(position, edge, radius, ray, meadow, V)
	radius = radius or 3
	local function down(x, z)
		return ray(V.new(x, position.Y + (meadow and 9 or 42), z), V.new(0, -70, 0))
	end
	local function walkable(hit)
		return hit and hit.Normal.Y >= math.cos(math.rad(35.1))
			and (hit.Instance:GetAttribute("SurfaceRole") == "Floor" or hit.Instance:GetAttribute("SurfaceRole") == nil)
	end
	local center = down(position.X, position.Z)
	assert(walkable(center), "no walkable center floor")
	assert(math.abs(center.Position.Y - (position.Y - 3)) < 0.7, "authored Y disagrees with " .. center.Instance.Name)
	for ix = -6, 6 do
		for iz = -6, 6 do
			if ix * ix + iz * iz <= (radius * 2) ^ 2 then
				local x, z = position.X + ix * 0.5, position.Z + iz * 0.5
				local hit = down(x, z)
				assert(walkable(hit), "clearance floor/cover at " .. x .. "," .. z)
				local rise = hit.Position.Y - center.Position.Y
				local tolerance = (center.Normal.Y < 0.999 or hit.Normal.Y < 0.999) and 2.15 or 1.5
				assert(rise <= tolerance and (edge or rise >= -tolerance), "clearance cliff/wall " .. hit.Instance.Name .. " at " .. x .. "," .. z .. " rise " .. rise)
				local overhead = ray(V.new(x, center.Position.Y + 2.2, z), V.new(0, 6, 0))
				assert(not overhead, "head clearance " .. (overhead and overhead.Instance.Name or ""))
			end
		end
	end
	return V.new(position.X, center.Position.Y + 3, position.Z)
end
return C
