local MovementTuning = load("MovementTuning")

test("slide speed decays to walk speed", function()
	local previous = MovementTuning.slideSpeed(0)
	eq(previous, MovementTuning.Slide.StartSpeed, "slide starts at its tuned speed")

	for step = 1, 20 do
		local elapsed = MovementTuning.Slide.Duration * step / 20
		local speed = MovementTuning.slideSpeed(elapsed)
		if speed > previous then
			error("slide speed must decay monotonically")
		end
		previous = speed
	end

	eq(previous, MovementTuning.WalkSpeed, "slide ends at walk speed")
	eq(
		MovementTuning.slideSpeed(MovementTuning.Slide.Duration + 1),
		MovementTuning.WalkSpeed,
		"slide stays at walk speed"
	)
end)

test("dash cooldown reports when another dash is ready", function()
	local cooldown = MovementTuning.Dash.Cooldown
	eq(MovementTuning.dashReady(10, 10 + cooldown - 0.01, 1), false, "still cooling down")
	eq(MovementTuning.dashReady(10, 10 + cooldown, 1), true, "base cooldown elapsed")
	eq(MovementTuning.dashReady(10, 10 + cooldown * 0.8, 0.8), true, "reward multiplier")
end)

test("jump forgiveness windows are short", function()
	if MovementTuning.Jump.CoyoteTime < 0.08 or MovementTuning.Jump.CoyoteTime > 0.2 then
		error("coyote time must stay between 0.08 and 0.20 seconds")
	end
	if MovementTuning.Jump.BufferTime < 0.08 or MovementTuning.Jump.BufferTime > 0.2 then
		error("jump buffer must stay between 0.08 and 0.20 seconds")
	end
end)

test("FOV kicks return to the base FOV", function()
	local sprintStart = MovementTuning.fovAt(0, MovementTuning.Fov.SprintKick)
	if sprintStart <= MovementTuning.Fov.Base then
		error("sprint must widen the FOV")
	end
	eq(
		MovementTuning.fovAt(MovementTuning.Fov.ReturnTime, MovementTuning.Fov.SprintKick),
		MovementTuning.Fov.Base,
		"sprint kick returns"
	)
	eq(
		MovementTuning.fovAt(MovementTuning.Fov.ReturnTime + 1, MovementTuning.Fov.DashKick),
		MovementTuning.Fov.Base,
		"dash kick stays returned"
	)
end)

test("mobile sprint is on by default", function()
	eq(MovementTuning.defaultSprint(true), true, "touch default")
	eq(MovementTuning.defaultSprint(false), false, "keyboard default")
end)
