--!strict
local Config = require(script.Parent.Config)

local RideSurface = {}

function RideSurface.collect(track: Instance): { Instance }
	local surfaces: { Instance } = {}
	local chuteFloors: { Instance } = {}
	for _, descendant in track:GetDescendants() do
		if descendant:IsA("BasePart") and not string.match(descendant.Name, "^Wall_") then
			table.insert(surfaces, descendant)
			if string.match(descendant.Name, "^ChuteFloor_") then
				table.insert(chuteFloors, descendant)
			end
		end
	end
	return if #chuteFloors > 0 then chuteFloors else surfaces
end

function RideSurface.sample(
	surfaces: { Instance },
	nominalPosition: Vector3,
	radius: number,
	forward: Vector3
): (Vector3, Vector3, Vector3)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = surfaces
	local castHeight = radius + 24
	local result = workspace:Raycast(
		nominalPosition + Vector3.yAxis * castHeight,
		-Vector3.yAxis * (castHeight + radius + 24),
		params
	)
	if not result then
		return nominalPosition + Vector3.yAxis * (radius + Config.RideGroundClearance),
			Vector3.yAxis,
			forward
	end
	local normal = result.Normal
	local tangent = forward - normal * forward:Dot(normal)
	if tangent.Magnitude < 1e-4 then
		tangent = forward
	else
		tangent = tangent.Unit
	end
	return result.Position + normal * (radius + Config.RideGroundClearance), normal, tangent
end

return RideSurface
