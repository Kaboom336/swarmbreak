local AiSchedule = load("AiSchedule")

test("update slots are evenly distributed", function()
	local counts = {}
	for slot = 0, 5 do
		counts[slot] = 0
	end
	for enemyId = 1, 60 do
		local slot = AiSchedule.updateSlot(enemyId, 6)
		counts[slot] += 1
	end
	for slot = 0, 5 do
		eq(counts[slot], 10, "slot " .. slot)
	end
end)

test("next repath cadence is deterministic", function()
	local first = AiSchedule.nextRepathFrame(17, 100, 24)
	eq(first, AiSchedule.nextRepathFrame(17, 100, 24), "same inputs")
	local second = AiSchedule.nextRepathFrame(17, first, 24)
	eq(second - first, 24, "cadence")
	eq(first % 24, AiSchedule.updateSlot(17, 24), "assigned slot")
end)

test("urgent work bypasses the next repath frame", function()
	eq(AiSchedule.shouldRepath(10, 20, false), false, "normal work waits")
	eq(AiSchedule.shouldRepath(10, 20, true), true, "urgent work runs")
end)

test("invalid intervals are rejected safely", function()
	for _, interval in { 0, -1, 1.5, 0 / 0, math.huge } do
		eq(AiSchedule.updateSlot(1, interval), nil, "update slot")
		eq(AiSchedule.nextRepathFrame(1, 10, interval), nil, "next repath")
	end
	eq(AiSchedule.shouldRepath(10, nil, false), false, "invalid schedule waits")
	eq(AiSchedule.shouldRepath(10, nil, true), true, "urgent invalid schedule runs")
end)
