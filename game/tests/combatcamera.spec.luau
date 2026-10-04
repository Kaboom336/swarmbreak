local Camera = load("CombatCameraMath")

test("combat camera widens monotonically with crowd size", function()
	local previous = Camera.target(0, false, false)
	for count = 1, 30 do
		local current = Camera.target(count, false, false)
		eq(current.Distance >= previous.Distance, true, "distance is monotonic")
		eq(current.Fov >= previous.Fov, true, "FOV is monotonic")
		previous = current
	end
end)

test("combat camera is rate limited and freezes for fresh input", function()
	local current = Camera.target(0, false, false)
	local crowded = Camera.target(30, false, false)
	local frozen = Camera.step(current, crowded, 1 / 60, 0.1)
	eq(frozen.Distance, current.Distance, "fresh aim or dash freezes distance")
	eq(frozen.Height, current.Height, "fresh aim or dash freezes height")
	eq(frozen.Fov, current.Fov, "fresh aim or dash freezes FOV")

	local moved = Camera.step(current, crowded, 0.1, 1)
	eq(
		moved.Distance - current.Distance <= Camera.MaxDistanceRate * 0.1 + 1e-6,
		true,
		"distance rate"
	)
	eq(moved.Fov - current.Fov <= Camera.MaxFovRate * 0.1 + 1e-6, true, "FOV rate")
end)

test("elite and boss framing is closer and lower", function()
	local normal = Camera.target(4, false, false)
	local elite = Camera.target(4, true, false)
	local boss = Camera.target(4, false, true)
	eq(elite.Distance < normal.Distance, true, "elite closer")
	eq(elite.Height < normal.Height, true, "elite lower")
	eq(boss.Distance <= elite.Distance, true, "boss at least as close")
end)
