--!strict
local Config = load("Config")
local Ride = load("Ride")

test("rolling angle accumulates distance over radius in the forward direction", function()
	eq(Ride.axleRotation(12, 3), -4, "forward axle angle")
	eq(Ride.axleRotation(5, 0), 0, "zero radius is safe")
	eq(
		Ride.axleRotation(4, 2) + Ride.axleRotation(6, 2),
		Ride.axleRotation(10, 2),
		"frame deltas accumulate"
	)
end)

test("ride contact and latch tuning meet Q4-A bounds", function()
	eq(Config.RideGroundClearance <= 0.15, true, "ground clearance")
	eq(Config.RideLatchSeconds >= 0.35, true, "minimum latch")
	eq(Config.RideLatchSeconds <= 0.6, true, "maximum latch")
end)

test("seeded bonus layout is deterministic", function()
	local first = Ride.layout(812_345, 8)
	local second = Ride.layout(812_345, 8)
	eq(#first, Config.RideBonusTargetCount, "target count")
	for index, target in first do
		eq(target.id, second[index].id, "target id")
		eq(target.kind, second[index].kind, "target kind")
		eq(target.lane, second[index].lane, "target lane")
		eq(target.time, second[index].time, "target time")
	end
	local different = Ride.layout(812_346, 8)
	local changed = false
	for index, target in first do
		if target.kind ~= different[index].kind or target.lane ~= different[index].lane then
			changed = true
		end
	end
	eq(changed, true, "different seed changes layout")
end)

test("pickup validation rejects the wrong lane or time", function()
	local target = { id = 3, kind = "Candy", lane = -1, time = 0.5 }
	local duration = 8
	local onTime = target.time
	local accepted = Ride.validatePickup(target, onTime, duration, -1, {}, 0)
	eq(accepted, true, "valid pickup")
	local wrongLane, laneReason = Ride.validatePickup(target, onTime, duration, 1, {}, 0)
	eq(wrongLane, false, "wrong lane")
	eq(laneReason, "lane", "lane reason")
	local wrongTime, timeReason = Ride.validatePickup(target, onTime + 2, duration, -1, {}, 0)
	eq(wrongTime, false, "wrong time")
	eq(timeReason, "time", "time reason")
	local duplicate, duplicateReason =
		Ride.validatePickup(target, onTime, duration, -1, { [3] = true }, 1)
	eq(duplicate, false, "duplicate")
	eq(duplicateReason, "claimed", "duplicate reason")
	local capped, capReason =
		Ride.validatePickup(target, onTime, duration, -1, {}, Config.RideMaxPickups)
	eq(capped, false, "pickup cap")
	eq(capReason, "cap", "cap reason")
end)

test("ride duration stays playable at every tested size", function()
	for _, size in { 10, 100, 1_000, 1_200_000 } do
		local physical = Ride.physicalDuration(size)
		eq(physical >= 10 and physical <= 11, true, "physical duration at " .. size)
		eq(
			Ride.duration(size, 40) >= 10 and Ride.duration(size, 40) <= 14,
			true,
			"physical plus bonus duration at " .. size
		)
		eq(Ride.bonusDuration(15) >= 2, true, "15 bonus walls take at least 2 s")
	end
end)

test("bonus layout is hittable and guarantees its kinds", function()
	local duration = Ride.physicalDuration(1_000)
	local targets = Ride.layout(44, duration)
	local speedPads = 0
	local goldPumpkins = 0
	eq(#targets, Config.RideMaxPickups, "every visible target is claimable")
	for index, target in targets do
		eq(target.time >= duration * 0.15, true, "target starts after 15 percent")
		eq(target.time <= duration * 0.85, true, "target ends before 85 percent")
		if index > 1 then
			eq(target.time - targets[index - 1].time >= 0.7, true, "target spacing")
		end
		if target.kind == "SpeedPad" then
			speedPads += 1
		elseif target.kind == "GoldPumpkin" then
			goldPumpkins += 1
		end
	end
	eq(speedPads >= 1, true, "at least one speed pad")
	eq(goldPumpkins <= 2, true, "at most two gold pumpkins")
end)

test("final wins applies every multiplier once", function()
	eq(Ride.finalWins(100, { "Candy" }, { 1.5, 2, 1.5 }), 495, "credited wins")
	eq(Ride.finalWins(5, { "Candy" }, { 1.5 }), 8, "floors only the final value")
	eq(Ride.finalWins(100, { "SpeedPad" }, { 1 }), 100, "speed does not change wins")
end)

test("bonus wins combine candy additions and gold multipliers", function()
	eq(Ride.winsWithBonuses(100, {}), 100, "no bonuses")
	eq(Ride.winsWithBonuses(100, { "Candy" }), 110, "one candy")
	eq(Ride.winsWithBonuses(100, { "Candy", "Candy", "GoldPumpkin" }), 220, "mixed")
	eq(Ride.winsWithBonuses(100, { "GoldPumpkin", "GoldPumpkin", "SpeedPad" }), 300, "gold adds up")
end)

test("combo counter reports the clean event streak and capped multiplier", function()
	eq(Ride.comboText(0), nil, "no combo")
	eq(Ride.comboText(1), "COMBO 1  x1.1", "first clean event")
	eq(Ride.comboText(7), "COMBO 7  x1.7", "seventh clean event")
	eq(Ride.comboMultiplier(0), 1, "empty combo")
	eq(Ride.comboMultiplier(20), 3, "combo cap")
	eq(Ride.comboMultiplier(100), 3, "combo stays capped")
end)

test("combo reward is calculated once and floored only at the end", function()
	eq(Ride.finalWins(5, { "Candy" }, { 1.5 }, 3), 10, "single final floor")
	eq(Ride.finalWins(100, {}, { 1 }, 20), 300, "capped combo applies to ride wins")
end)

test("seeded obstacles are deterministic and always leave a free lane", function()
	local duration = Ride.physicalDuration(10)
	local first = Ride.obstacleLayout(8_001, duration)
	local second = Ride.obstacleLayout(8_001, duration)
	eq(#first, Config.RideObstacleCount, "obstacle wave count")
	for index, wave in first do
		eq(wave.kind, second[index].kind, "deterministic kind")
		eq(wave.time, second[index].time, "deterministic time")
		eq(wave.freeLane, second[index].freeLane, "deterministic free lane")
		eq(Ride.waveHitsLane(wave, wave.freeLane), false, "free lane remains traversable")
		eq(#wave.lanes >= 1 and #wave.lanes <= 2, true, "one or two blocked lanes")
		if index > 1 then
			eq(
				wave.time - first[index - 1].time >= Config.RideObstacleReactionSeconds,
				true,
				"reaction time"
			)
		end
	end
	eq(first[1].time >= Config.RideGentleStartSeconds, true, "safe steering teach")
	eq(first[1].kind, "RollingLog", "all obstacle kinds begin cycling")
	eq(first[2].kind, "Tombstone", "tombstone included")
	eq(first[3].kind, "LowFence", "low fence included")
end)

test("ride speed, hit penalty, and path meet Q4-B bounds", function()
	local duration = Ride.physicalDuration(10)
	eq(Ride.speedAtTime(0, duration), 60, "start speed")
	eq(Ride.speedAtTime(duration, duration) >= 140, true, "top speed")
	eq(
		Ride.speedAtTime(duration * 0.5, duration, 0.8),
		Ride.speedAtTime(duration * 0.5, duration) * 0.8,
		"hit costs twenty percent"
	)
	eq(Ride.speedScaleAfterHit(0), 0.8, "instant hit penalty")
	eq(Ride.speedScaleAfterHit(Config.RideHitRecoverySeconds), 1, "speed recovers")
	eq(Config.RideSlopeDegrees >= 18 and Config.RideSlopeDegrees <= 25, true, "chute slope")
	local firstTurn = Ride.pathSample(Config.RidePathCurveLength * 0.25)
	local secondTurn = Ride.pathSample(Config.RidePathCurveLength * 0.75)
	eq(firstTurn.bank > 0, true, "first bank")
	eq(secondTurn.bank < 0, true, "opposite bank")
end)

test("pickup validation includes authoritative path overlap", function()
	local target = { id = 1, kind = "Candy", lane = 0, time = 2 }
	local accepted = Ride.validatePickupSpatial(target, 2, 10, 0, 3, {}, 0)
	eq(accepted, true, "nearby pickup")
	local rejected, reason = Ride.validatePickupSpatial(target, 2, 10, 0, 100, {}, 0)
	eq(rejected, false, "distant pickup")
	eq(reason, "position", "spatial reason")
end)

test("touch steering snaps visibly between three lanes", function()
	eq(Ride.snapLane(0, -1), -1, "left lane")
	eq(Ride.snapLane(-1, -1), -1, "left edge clamps")
	eq(Ride.snapLane(-1, 1), 0, "returns center")
	eq(Ride.snapLane(0, 1), 1, "right lane")
end)

test("downhill ride progress accelerates and round-trips", function()
	local duration = 8
	local halfway = Ride.progress(4, duration)
	eq(halfway < 0.5, true, "starts slower and gains speed")
	local elapsed = Ride.elapsedForProgress(halfway, duration)
	eq(math.abs(elapsed - 4) < 1e-9, true, "inverse progress")
end)

test("speed distance curve round-trips wall timing", function()
	local duration = Ride.physicalDuration(10)
	for _, distance in { 50, 250, 750 } do
		local elapsed = Ride.timeAtBaseDistance(distance, duration)
		eq(
			math.abs(Ride.baseDistanceAtTime(elapsed, duration) - distance) < 0.001,
			true,
			"distance time inverse"
		)
	end
end)
