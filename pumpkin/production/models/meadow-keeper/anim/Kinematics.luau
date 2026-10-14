local Skeleton = require(script.Parent.Skeleton)
local Kinematics = {}
function Kinematics.world(pose, ground)
	local world = { Root = ground or CFrame.identity }
	for _, joint in ipairs(Skeleton.jointOrder) do
		local parent = Skeleton.parents[joint]
		local pivot = Vector3.new(table.unpack(Skeleton.pivots[joint]))
		local parentPivot = parent == "Root" and Vector3.zero
			or Vector3.new(table.unpack(Skeleton.pivots[parent]))
		world[joint] = world[parent] * CFrame.new(pivot - parentPivot) * pose[joint]
	end
	return world
end
function Kinematics.socket(pose, ground, clip)
	local world = Kinematics.world(pose, ground)
	local right = world["Wrist.R"] * CFrame.new(table.unpack(Skeleton.hand))
	if clip == "lob" then
		local left = world["Wrist.L"] * CFrame.new(table.unpack(Skeleton.hand))
		local half = (right.Position - left.Position) / 2
		local basis = ground or CFrame.identity
		local middle = (right.Position + left.Position) / 2
		local height = basis:PointToObjectSpace(middle).Y
		local blend = math.clamp((height - 7) / 2.6, 0, 1)
		local direction =
			basis:VectorToWorldSpace(Vector3.new(0, 0.2 + 0.8 * blend, 1 - 0.95 * blend).Unit)
		local localHalf = basis:VectorToObjectSpace(half)
		local cross = basis:VectorToWorldSpace(Vector3.new(0, localHalf.Y, localHalf.Z))
		if cross.Magnitude > 0.001 then
			local axis = cross.Unit
			direction -= axis * direction:Dot(axis)
		end
		-- 8x6 cylinder along local X: both mittens support the circular underside.
		local offset = math.sqrt(math.max(0, 9 - cross.Magnitude ^ 2))
		return CFrame.new(middle + direction.Unit * offset) * (ground or CFrame.identity).Rotation
	end
	return right
end
return Kinematics
