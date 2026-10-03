local WeaponPose = load("WeaponPose")

local function close(actual, expected, message)
	assert(math.abs(actual - expected) < 1e-6, message)
end

test("recoil starts and ends neutral and reaches the stated kick", function()
	local atStart = WeaponPose.recoilAt(0)
	local atPeak = WeaponPose.recoilAt(WeaponPose.RecoilOutSeconds)
	local atEnd = WeaponPose.recoilAt(WeaponPose.RecoilSeconds)

	close(atStart.BackStuds, 0, "recoil start distance")
	close(atStart.UpDegrees, 0, "recoil start angle")
	close(atPeak.BackStuds, WeaponPose.RecoilBackStuds, "recoil peak distance")
	close(atPeak.UpDegrees, WeaponPose.RecoilUpDegrees, "recoil peak angle")
	close(atEnd.BackStuds, 0, "recoil end distance")
	close(atEnd.UpDegrees, 0, "recoil end angle")
end)

test("swing has an eighty millisecond wind-up and a 160 millisecond arc", function()
	close(WeaponPose.swingAt(0), 0, "swing start")
	close(WeaponPose.SwingWindupSeconds, 0.08, "wind-up duration")
	close(WeaponPose.SwingArcSeconds, 0.16, "swing arc duration")
	close(
		WeaponPose.swingAt(WeaponPose.SwingWindupSeconds + WeaponPose.SwingArcSeconds * 0.75),
		WeaponPose.SwingPeakDegrees,
		"swing peak"
	)
	close(WeaponPose.swingAt(WeaponPose.SwingSeconds), 0, "swing end")
end)

test("weapon target lengths match each visual kind", function()
	eq(WeaponPose.TargetLengths.Gun, 2.6, "gun length")
	eq(WeaponPose.TargetLengths.Rifle, 3.4, "rifle length")
	eq(WeaponPose.TargetLengths.Melee, 4.5, "melee length")
	eq(WeaponPose.TargetLengths.OrbitalEmitter, 1.2, "orbital emitter length")
	eq(WeaponPose.targetLength("Starter", "Hitscan"), 2.6, "gun mapping")
	eq(WeaponPose.targetLength("Marksman", "Hitscan"), 3.4, "rifle mapping")
	eq(WeaponPose.targetLength("Blade", "Melee"), 4.5, "melee mapping")
	eq(WeaponPose.targetLength("Guardian", "Orbital"), 1.2, "orbital mapping")
end)
