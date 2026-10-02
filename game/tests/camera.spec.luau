local CameraConfig = load("CameraConfig")

test("third-person camera uses a close right-shoulder view", function()
	assert(
		CameraConfig.Distance >= 10 and CameraConfig.Distance <= 14,
		"camera distance out of range"
	)
	assert(
		CameraConfig.RightOffset >= 1 and CameraConfig.RightOffset <= 3,
		"right offset out of range"
	)
	eq(CameraConfig.Distance, 12, "briefed camera distance")
	eq(CameraConfig.RightOffset, 2, "briefed shoulder offset")
	eq(CameraConfig.MouseLockDefault, true, "PC mouse lock default")
end)

test("crosshair is hidden on touch-only devices", function()
	eq(CameraConfig.crosshairVisible(true, false), false, "touch-only crosshair")
	eq(CameraConfig.crosshairVisible(false, true), true, "PC crosshair")
	eq(CameraConfig.crosshairVisible(true, true), true, "hybrid device with a mouse")
end)
