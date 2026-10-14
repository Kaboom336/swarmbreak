-- Same ground frame, pivot hierarchy and release socket as the approved Rig.
local Animator = require(script.Parent.Animator)
local Kinematics = require(script.Parent.Kinematics)
local Pose = { ReleaseSeconds = 0.620 }
function Pose.ground(guard)
	-- lookAt faces -Z; the authored mesh faces +Z. Keep its feet at hitbox bottom.
	return guard.CFrame * CFrame.new(0, -guard.Size.Y / 2, 0) * CFrame.Angles(0, math.pi, 0)
end
function Pose.release(guard, clip, time)
	local pose = Animator.sample(clip or "throw", time or Pose.ReleaseSeconds)
	return Kinematics.socket(pose, Pose.ground(guard), clip or "throw")
end
return Pose
