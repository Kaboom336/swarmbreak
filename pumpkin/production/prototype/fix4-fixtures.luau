local rb = require("@lune/roblox")
local D = require("./meadow-v4/ReachableDrops")
local V = rb.Vector3
assert(D.isLane({name="TunnelValleyJoin",category="lane",collidable=true},{}),"authored named valley connector")
assert(not D.isLane({name="TunnelValleyJoin",category="rock",collidable=true},{}),"forged named connector rock")
local function segment(route, index, y, z)
	return { route = route, index = index, a = V.new(-20, y, z), b = V.new(20, y, z) }
end
local own = segment("spiral", 18, 0, 0)
assert(D.connected(own, segment("spiral", 19, 0, 0)), "adjacent spiral segment")
assert(not D.connected(own, segment("spiral", 21, 4, 0)), "stacked spiral shortcut")
assert(not D.connected(segment("bridge", 2, 20, 0), segment("ravine", 2, 0, 0)), "bridge/ravine shortcut")
assert(not D.connected(segment("tunnel", 2, 0, 0), segment("hill", 2, 20, 0)), "tunnel/hill shortcut")
assert(not D.connected(own, segment("unconnected", 18, 0, 2)), "same-height disconnected lane")
local floorPart = rb.Instance.new("Part")
floorPart:SetAttribute("WalkableLaneFloor", true)
local function ray(o, d)
	for _, y in { 3.5, 0, -20 } do
		if y <= o.Y and y >= o.Y + d.Y then
			return { Position = V.new(o.X, y, o.Z), Normal = V.yAxis, Instance = floorPart }
		end
	end
	return nil
end
assert(D.floor(V.new(0, 3, 0), ray, V).Y == 0, "first ray hit above carrier lane")
assert(D.floor(V.new(0, 10, 0), ray, V) == nil, "airborne carrier fabricated floor")
local function closeStack(o,d)
 for _,y in {1.8,0} do
  if y<=o.Y and y>=o.Y+d.Y then return {Position=V.new(o.X,y,o.Z),Normal=V.yAxis,Instance=floorPart} end
 end
end
assert(D.floor(V.new(0,3,0),closeStack,V).Y==0,"nearest feet floor must beat first upper deck within tolerance")
print("PASS stacked spiral, bridge/ravine, tunnel/hill, disconnected peer and overlapping down-ray fixtures")
return true
