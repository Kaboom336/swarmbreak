local D = require(script.Parent.CaveReachableDrops)
local data = require(game.ReplicatedStorage.CaveRouteData)
local map = workspace.CaveV2
local M = {}
local routes = {}
for name, points in data.routes do
	if name ~= "cartRail" then
		routes[name] = {}
		for _, p in points do
			table.insert(routes[name], { x = p[1], y = p[3], z = p[2] })
		end
	end
end
M.graph = D.graph(routes, Vector3, Vector3.zero)
function M.refresh()
	local floors = {}
	for _, p in map:GetChildren() do
		if
			p:IsA("BasePart")
			and p.CanCollide
			and p:HasTag("AuthoredLaneFloor")
			and p:GetAttribute("WalkableLaneFloor") == true
			and p:GetAttribute("CaveCategory") == "lane"
			and not p:GetAttribute("KitAssemblyId")
		then
			table.insert(floors, p)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = floors
	params.RespectCanCollide = true
	local solid = RaycastParams.new()
	solid.FilterType = Enum.RaycastFilterType.Include
	solid.FilterDescendantsInstances = { map }
	solid.RespectCanCollide = true
	M.laneRay = function(o, d)
		local hit = workspace:Raycast(o, d, params)
		if not hit or hit.Normal.Y >= math.cos(math.rad(35.1)) then
			return hit
		end
		-- A ramp end face can sit <.01 above a coincident flat deck. Recast
		-- without that steep part rather than lowering past the valid floor.
		local remaining = table.clone(floors)
		local retry = RaycastParams.new()
		retry.FilterType = Enum.RaycastFilterType.Include
		retry.RespectCanCollide = true
		while hit and hit.Normal.Y < math.cos(math.rad(35.1)) do
			for i = #remaining, 1, -1 do
				if remaining[i] == hit.Instance then
					table.remove(remaining, i)
				end
			end
			retry.FilterDescendantsInstances = remaining
			hit = workspace:Raycast(o, d, retry)
		end
		return hit
	end
	M.solidRay = function(o, d)
		return workspace:Raycast(o, d, solid)
	end
	return floors
end
function M.floor(root)
	return D.floor(root, M.laneRay, Vector3)
end
function M.socket(target, floor, carrier)
	return D.settle(target, floor.Y, {}, M.laneRay, M.solidRay, Vector3, M.graph, carrier or floor)
end
function M.reachable(root, loot)
	local floor = M.floor(root)
	return floor
		and math.abs(loot.Y - floor.Y) <= 4.5
		and (Vector3.new(root.X, 0, root.Z) - Vector3.new(loot.X, 0, loot.Z)).Magnitude <= 7
end
M.refresh()
return M
