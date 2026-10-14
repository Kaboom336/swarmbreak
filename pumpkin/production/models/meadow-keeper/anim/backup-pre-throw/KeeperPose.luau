-- Same ground frame, pivot hierarchy and release socket as the approved Rig.
local Animator = require(script.Parent.Animator)
local Geometry = require(script.Parent.Geometry)
local Pose = { ReleaseSeconds = 0.620 }
local pivots = {}
for _, section in ipairs(Geometry) do
	pivots[section.rig_part] = Vector3.new(table.unpack(section.pivot))
end
function Pose.ground(guard)
	-- lookAt faces -Z; the authored mesh faces +Z. Keep its feet at hitbox bottom.
	return guard.CFrame * CFrame.new(0, -guard.Size.Y / 2, 0) * CFrame.Angles(0, math.pi, 0)
end
function Pose.release(guard, clip, time)
	local pose = Animator.sample(clip or "throw", time or Pose.ReleaseSeconds)
	return Pose.ground(guard)
		* CFrame.new(pivots.Torso)
		* pose.Torso
		* CFrame.new(pivots["Arm.R"] - pivots.Torso)
		* pose["Arm.R"]
		* CFrame.new(0.89, -3.55, 1.5)
end
return Pose
