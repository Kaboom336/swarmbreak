local Pickups = load("Pickups")

local function point(x, y, z)
	return { x = x, y = y or 0, z = z or 0 }
end

test("drop odds use a half-open boundary", function()
	for kind, odds in Pickups.DropOdds do
		eq(Pickups.shouldDrop(kind, 0), true, kind .. " at zero")
		eq(Pickups.shouldDrop(kind, odds), false, kind .. " at boundary")
		if odds > 0 then
			eq(Pickups.shouldDrop(kind, odds - 0.000001), true, kind .. " below boundary")
		end
	end
	eq(Pickups.shouldDrop("Nope", 0), false, "unknown kind")
end)

test("nearest target wins and user id breaks ties", function()
	local candidates = {
		{ Id = 20, Position = point(5), Eligible = true },
		{ Id = 10, Position = point(-5), Eligible = true },
		{ Id = 1, Position = point(1), Eligible = false },
	}
	eq(Pickups.chooseTarget(point(0), candidates, 0).Id, 10, "lower id wins tie")
	eq(Pickups.chooseTarget(point(0), candidates, 0, 4), nil, "nobody in range")
end)

test("range checks include their boundary", function()
	eq(
		Pickups.inRange(point(0), point(Pickups.AttractionRadius), Pickups.AttractionRadius),
		true,
		"edge"
	)
	eq(
		Pickups.inRange(point(0), point(Pickups.AttractionRadius + 0.01), Pickups.AttractionRadius),
		false,
		"outside"
	)
end)

test("vacuum reaches the screen and expires exactly on time", function()
	local untilTime = Pickups.vacuumExpiry(100)
	eq(untilTime, 100 + Pickups.VacuumDuration, "duration")
	eq(Pickups.isVacuumActive(untilTime, untilTime - 0.001), true, "before expiry")
	eq(Pickups.isVacuumActive(untilTime, untilTime), false, "at expiry")
	local far = { Id = 7, Position = point(1000), Eligible = true, VacuumUntil = untilTime }
	eq(Pickups.chooseTarget(point(0), { far }, untilTime - 1), far, "vacuum ignores radius")
	eq(Pickups.chooseTarget(point(0), { far }, untilTime), nil, "radius returns after expiry")
end)

test("collection rejects range and duplicates", function()
	local collector = { Id = 4, Position = point(10), Eligible = true }
	local drop = { Position = point(0), TargetId = 4, ExpiresAt = 20 }
	local ok, reason = Pickups.tryCollect(drop, collector, 5)
	eq(ok, false, "too far")
	eq(reason, "range", "range reason")
	collector.Position = point(Pickups.CollectionRadius)
	ok = Pickups.tryCollect(drop, collector, 5)
	eq(ok, true, "in range")
	local again, duplicateReason = Pickups.tryCollect(drop, collector, 5)
	eq(again, false, "second claim")
	eq(duplicateReason, "collected", "duplicate reason")
end)
