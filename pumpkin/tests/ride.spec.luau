--!strict
local Config = load("Config")
local Ride = load("Ride")

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
		eq(physical >= 7 and physical <= 10, true, "physical duration at " .. size)
		eq(
			Ride.duration(size, 40) <= 10 + Config.BonusZoneMaxSeconds,
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
	eq(#targets, 7, "seven targets")
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

test("combo counter reports the current wall streak", function()
	eq(Ride.comboText(0), nil, "no combo")
	eq(Ride.comboText(1), "WALL x1!", "first wall")
	eq(Ride.comboText(7), "WALL x7!", "seventh wall")
end)

test("downhill ride progress accelerates and round-trips", function()
	local duration = 8
	local halfway = Ride.progress(4, duration)
	eq(halfway < 0.5, true, "starts slower and gains speed")
	local elapsed = Ride.elapsedForProgress(halfway, duration)
	eq(math.abs(elapsed - 4) < 1e-9, true, "inverse progress")
end)
