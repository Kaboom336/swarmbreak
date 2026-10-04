local PlayerPose = load("PlayerPose")

local function near(a: number, b: number, epsilon: number, message: string)
	if math.abs(a - b) > epsilon then
		error(string.format("%s: expected %.4f, got %.4f", message, b, a), 2)
	end
end

test("run lean is bounded and settles at rest", function()
	local pitch, roll = PlayerPose.targetRunLean(10, -10)
	assert(math.abs(pitch) <= PlayerPose.RunLeanDegrees, "pitch exceeds run lean limit")
	assert(math.abs(roll) <= PlayerPose.RunLeanDegrees, "roll exceeds run lean limit")

	for _ = 1, 30 do
		pitch, roll = PlayerPose.stepRunLean(pitch, roll, 0, 0, 1 / 60)
	end
	assert(math.abs(pitch) < 0.02, "pitch does not decay to neutral at rest")
	assert(math.abs(roll) < 0.02, "roll does not decay to neutral at rest")
end)

test("dash pose peaks at fifteen degrees and returns within 0.3 seconds", function()
	local peak = PlayerPose.dashPose(PlayerPose.DashDuration / 2)
	near(peak.LeanDegrees, PlayerPose.DashLeanDegrees, 1e-6, "dash lean peak")
	assert(peak.Stretch > 0, "dash pose must stretch the character")

	local neutral = PlayerPose.dashPose(0.3)
	near(neutral.LeanDegrees, 0, 1e-6, "dash lean returns")
	near(neutral.Stretch, 0, 1e-6, "dash stretch returns")
	assert(PlayerPose.DashDuration <= 0.3, "dash pose lasts too long")
end)

test("hit flinch lasts one tenth of a second", function()
	assert(PlayerPose.hitFlinch(PlayerPose.HitDuration / 2) > 0, "hit flinch must have a peak")
	near(PlayerPose.hitFlinch(PlayerPose.HitDuration), 0, 1e-6, "hit flinch returns")
	near(PlayerPose.HitDuration, 0.1, 1e-6, "hit duration")
end)

test("each movement action has three distinct procedural poses", function()
	for _, action in { "Dash", "DoubleJump", "Slide" } do
		local seen = {}
		for variant = 1, 3 do
			local pose = PlayerPose.movementPose(action, variant, 1, 0.5)
			local signature = string.format(
				"%.2f/%.2f/%.2f/%.2f",
				pose.LeanDegrees,
				pose.TuckStuds,
				pose.SpinDegrees,
				pose.ArmSweepDegrees
			)
			assert(not seen[signature], action .. " variants must be visually distinct")
			seen[signature] = true
		end
	end
end)

test("double-jump spin eases monotonically through a full turn", function()
	local previous = PlayerPose.spinAngle(0)
	near(previous, 0, 1e-6, "spin starts neutral")
	for step = 1, 20 do
		local angle = PlayerPose.spinAngle(step / 20)
		assert(angle >= previous, "spin angle must never reverse")
		previous = angle
	end
	near(previous, 2 * math.pi, 1e-6, "spin completes one turn")

	local pose = PlayerPose.movementPose("DoubleJump", 2, 0, 1)
	near(pose.SpinDegrees, 360, 1e-6, "double-jump spin completes visually")
end)
