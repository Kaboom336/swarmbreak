local Daily = load("Daily")
local Evolutions = load("Evolutions")
local Weapons = load("Weapons")

local DAY = 86400

test("dayIndex counts whole UTC days", function()
	eq(Daily.dayIndex(0), 0, "day 0")
	eq(Daily.dayIndex(86399), 0, "last second of day 0")
	eq(Daily.dayIndex(86400), 1, "day 1")
end)

test("a fresh profile claims slot 1 today", function()
	local d = Daily.evaluate(0, 0, 10 * DAY + 5)
	eq(d.Claimable, true, "claimable")
	eq(d.NewStreak, 1, "streak")
	eq(d.Slot, 1, "slot")
	eq(d.Today, 10, "today")
end)

test("the next day grows the streak", function()
	local d = Daily.evaluate(10, 1, 11 * DAY)
	eq(d.Claimable, true, "claimable")
	eq(d.NewStreak, 2, "streak")
	eq(d.Slot, 2, "slot")
end)

test("the same day is not paid twice", function()
	local d = Daily.evaluate(11, 2, 11 * DAY + 3000)
	eq(d.Claimable, false, "not claimable")
	eq(d.NewStreak, 2, "streak kept")
	eq(d.Slot, 2, "today's slot")
	eq(d.Today, 11, "today")
end)

test("a missed day starts the streak over", function()
	local d = Daily.evaluate(11, 6, 14 * DAY)
	eq(d.Claimable, true, "claimable")
	eq(d.NewStreak, 1, "streak reset")
	eq(d.Slot, 1, "slot 1")
end)

test("slots wrap after a week", function()
	eq(Daily.slot(7), 7, "slot 7")
	eq(Daily.slot(8), 1, "slot 8 wraps")
	local d = Daily.evaluate(20, 7, 21 * DAY)
	eq(d.Slot, 1, "day 8 pays slot 1")
	eq(d.NewStreak, 8, "streak keeps counting")
end)

test("every reward pays Gems; shards and the crate name real things", function()
	eq(#Daily.Rewards, 7, "seven slots")
	local crates = 0
	for i, r in Daily.Rewards do
		assert(r.Gems > 0, "slot " .. i .. " pays Gems")
		if r.Shard ~= nil then
			assert(
				r.Shard == "Equipped" or table.find(Evolutions.Order, r.Shard) ~= nil,
				"slot " .. i .. " shard " .. tostring(r.Shard)
			)
		end
		if r.Crate ~= nil then
			crates += 1
			if Weapons.Crates then
				assert(Weapons.Crates[r.Crate], "slot " .. i .. " crate " .. tostring(r.Crate))
			end
		end
	end
	eq(crates, 1, "exactly one crate slot")
end)

test("reward resolves the equipped element and never mutates the table", function()
	eq(Daily.reward(5, "Dark").Shard, "Dark", "equipped element")
	eq(Daily.reward(5, nil).Shard, "Tech", "no element -> Tech")
	eq(Daily.reward(3, "Dark").Shard, "Tech", "fixed Tech slot")
	eq(Daily.Rewards[5].Shard, "Equipped", "table untouched")
	eq(Daily.reward(7).Crate, "Gem", "crate slot")
	eq(Daily.reward(7).Gems, 150, "crate slot gems")
end)

test("reward text and the next slot", function()
	local s = Daily.rewardText(Daily.reward(3))
	assert(s:find("Gems"), s)
	assert(s:find("Tech"), s)
	eq(Daily.rewardText(Daily.reward(1)), "+40 Gems", "plain gems")
	eq(Daily.rewardText(Daily.reward(7)), "+150 Gems, free Gem crate", "crate text")
	eq(Daily.shortText(Daily.reward(1)), "40", "short plain")
	eq(Daily.shortText(Daily.reward(3)), "60 +shard", "short shard")
	eq(Daily.shortText(Daily.reward(7)), "150 +crate", "short crate")
	eq(Daily.nextSlot(7), 1, "next after 7")
	eq(Daily.nextSlot(3), 4, "next after 3")
end)
