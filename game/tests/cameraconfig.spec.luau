local CameraConfig = load("CameraConfig")

test("camera is close, low, and pitched down", function()
	eq(CameraConfig.Distance, 12, "camera distance")
	eq(CameraConfig.HeightOffset, 2.2, "camera height")
	eq(CameraConfig.RightOffset, 2.5, "camera shoulder offset")
	eq(CameraConfig.StartPitchDegrees, 18, "starting pitch")
	eq(CameraConfig.MinPitchDegrees, 8, "minimum pitch")
	eq(CameraConfig.MaxPitchDegrees, 40, "maximum pitch")
end)

test("crosshair is hidden on touch-only devices", function()
	eq(CameraConfig.crosshairVisible(true, false), false, "touch-only crosshair")
	eq(CameraConfig.crosshairVisible(false, true), true, "PC crosshair")
	eq(CameraConfig.crosshairVisible(true, true), true, "hybrid device with a mouse")
end)

test("crowd distance is monotonic and clamped", function()
	local previous = CameraConfig.distanceForEnemyCount(-1)
	for enemyCount = 0, 24 do
		local distance = CameraConfig.distanceForEnemyCount(enemyCount)
		assert(distance >= previous, "distance decreased as enemy count increased")
		assert(distance >= CameraConfig.Distance, "distance below close distance")
		assert(distance <= CameraConfig.CrowdedDistance, "distance above crowded distance")
		previous = distance
	end

	eq(CameraConfig.distanceForEnemyCount(11), CameraConfig.Distance, "below crowd threshold")
	eq(CameraConfig.distanceForEnemyCount(12), CameraConfig.CrowdedDistance, "crowd threshold")
	eq(CameraConfig.distanceForEnemyCount(100), CameraConfig.CrowdedDistance, "large crowd")
end)
