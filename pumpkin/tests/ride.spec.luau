--!strict
local Config = load("Config")
local Ride = load("Ride")

test("seeded bonus layout is deterministic", function()
	local first = Ride.layout(812_345)
	local second = Ride.layout(812_345)
	eq(#first, Config.RideBonusTargetCount, "target count")
	for index, target in first do
		eq(target.id, second[index].id, "target id")
		eq(target.kind, second[index].kind, "target kind")
		eq(target.lane, second[index].lane, "target lane")
		eq(target.time, second[index].time, "target time")
	end
	local different = Ride.layout(812_346)
	eq(first[1].time == different[1].time, false, "different seed changes layout")
end)

test("pickup validation rejects the wrong lane or time", function()
	local target = { id = 3, kind = "Candy", lane = -1, time = 0.5 }
	local duration = 6
	local onTime = Ride.elapsedForProgress(target.time, duration)
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

test("bonus wins combine candy additions and gold multipliers", function()
	eq(Ride.winsWithBonuses(100, {}), 100, "no bonuses")
	eq(Ride.winsWithBonuses(100, { "Candy" }), 110, "one candy")
	eq(Ride.winsWithBonuses(100, { "Candy", "Candy", "GoldPumpkin" }), 240, "mixed")
	eq(Ride.winsWithBonuses(100, { "GoldPumpkin", "GoldPumpkin", "SpeedPad" }), 400, "gold stack")
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
