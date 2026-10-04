local fs = require("@lune/fs")
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
	local dashStart = MovementTuning.fovAt(0, MovementTuning.Fov.DashKick)
	if dashStart <= MovementTuning.Fov.Base then
		error("dash must widen the FOV")
	end
	eq(
		MovementTuning.fovAt(MovementTuning.Fov.ReturnTime, MovementTuning.Fov.SlideKick),
		MovementTuning.Fov.Base,
		"slide kick returns"
	)
	eq(
		MovementTuning.fovAt(MovementTuning.Fov.ReturnTime + 1, MovementTuning.Fov.DashKick),
		MovementTuning.Fov.Base,
		"dash kick stays returned"
	)
	assert(MovementTuning.Fov.DashKick <= 6, "dash FOV kick exceeds six degrees")
	assert(MovementTuning.Fov.SlideKick <= 6, "slide FOV kick exceeds six degrees")
end)

test("sprint is always on at the tuned run speed", function()
	eq(MovementTuning.runSpeed(20), 27, "run speed comes from movement tuning")
end)

test("stat rewards preserve the always-sprint multiplier", function()
	local rewardedSpeed = 24
	eq(
		MovementTuning.runSpeed(rewardedSpeed),
		rewardedSpeed * MovementTuning.RunSpeedMultiplier,
		"rewarded speed remains sprinting"
	)

	local playerData = fs.readFile("src/ServerStorage/PlayerData.luau")
	assert(
		playerData:find("hum.WalkSpeed = MovementTuning.runSpeed(speed)", 1, true),
		"PlayerData.applyStats must apply the sprint multiplier"
	)
	local movement = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Movement.client.luau")
	assert(
		not movement:find("humanoid.WalkSpeed =", 1, true),
		"Movement.client must not overwrite the server-owned speed"
	)
end)

test("slide jump carries its horizontal momentum", function()
	local early = MovementTuning.slideJumpMomentum(12, 0)
	local late = MovementTuning.slideJumpMomentum(25, MovementTuning.Slide.Duration)
	assert(early > 12, "an early slide jump should retain the slide burst")
	eq(late, 25, "a late slide jump must not slow existing momentum")
end)

test("gear perks add air jumps without removing the base double jump", function()
	eq(MovementTuning.extraJumps(nil), 0, "no gear jumps")
	eq(MovementTuning.extraJumps({ ExtraJumps = 2 }), 2, "two gear jumps")
	eq(MovementTuning.airJumps({ ExtraJumps = 2 }), 3, "base double jump plus gear")
	eq(MovementTuning.extraJumps({ ExtraJumps = -5 }), 0, "negative perk values clamp")
end)

test("movement cooldown table stays within play-safe bounds", function()
	for action, cooldown in MovementTuning.Cooldowns do
		assert(cooldown >= MovementTuning.CooldownBounds.Min, action .. " cooldown is too short")
		assert(cooldown <= MovementTuning.CooldownBounds.Max, action .. " cooldown is too long")
	end
	eq(
		MovementTuning.cooldown("Dash", -1),
		MovementTuning.CooldownBounds.Min,
		"cooldown multiplier clamps low"
	)
	eq(
		MovementTuning.cooldown("Dash", 100),
		MovementTuning.CooldownBounds.Max,
		"cooldown multiplier clamps high"
	)
end)

test("slide speed scales by stat ratio only, not the sprint multiplier twice", function()
	local fsx = require("@lune/fs")
	local src = fsx.readFile("src/StarterPlayer/StarterPlayerScripts/Movement.client.luau")
	assert(
		not src:find("baseWalkSpeed / MovementTuning.WalkSpeed)", 1, true),
		"sprint applied twice"
	)
	local _, count =
		src:gsub("baseWalkSpeed / MovementTuning%.runSpeed%(MovementTuning%.WalkSpeed%)", "")
	eq(count, 2, "both slide sites normalise by run speed")
end)
