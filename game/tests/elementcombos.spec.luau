--!strict
local ElementCombos = load("ElementCombos")

test("every different element pair has exactly one combo", function()
	local seen = {}
	for firstIndex, first in ElementCombos.Elements do
		for secondIndex = firstIndex + 1, #ElementCombos.Elements do
			local second = ElementCombos.Elements[secondIndex]
			local forward = ElementCombos.resolve(first, second)
			local reverse = ElementCombos.resolve(second, first)
			assert(forward ~= nil, first .. " and " .. second .. " need a combo")
			eq(forward, reverse, first .. " and " .. second .. " resolve consistently")
			assert(not seen[forward.Name], "duplicate combo " .. forward.Name)
			seen[forward.Name] = true
		end
	end
	eq(#ElementCombos.Elements, 4, "element count")
end)

test("same elements and the same player never combo", function()
	for _, element in ElementCombos.Elements do
		eq(ElementCombos.resolve(element, element), nil, element .. " self combo")
	end
	eq(
		ElementCombos.resolve("Nature", "Lightning", "player-one", "player-one"),
		nil,
		"same player combo"
	)
	assert(
		ElementCombos.resolve("Nature", "Lightning", "player-one", "player-two") ~= nil,
		"different players should combo"
	)
end)

test("combo definitions have safe combat values", function()
	for key, combo in ElementCombos.Combos do
		assert(combo.BonusDamageMultiplier >= 1.2, key .. " multiplier is too low")
		assert(combo.BonusDamageMultiplier <= 2.5, key .. " multiplier is too high")
		assert(combo.Radius > 0, key .. " radius")
		assert(combo.Cooldown > 0, key .. " cooldown")
		eq(#combo.Color, 3, key .. " color channels")
	end
	eq(ElementCombos.resolve("Nature", "Lightning").Name, "Chain Storm", "rooted combo")
	eq(ElementCombos.resolve("Tech", "Dark").Name, "Void Burst", "marked combo")
end)

test("every element status has a duration", function()
	for _, element in ElementCombos.Elements do
		local status = ElementCombos.Statuses[element]
		assert(status ~= nil, element .. " status")
		assert(status.Name ~= "", element .. " status name")
		assert(status.Duration > 0, element .. " status duration")
	end
end)

test("per-enemy cooldown includes its boundary", function()
	local cooldown = ElementCombos.Cooldown
	assert(ElementCombos.canTrigger(10, nil), "an enemy without a combo should trigger")
	assert(not ElementCombos.canTrigger(10 + cooldown - 0.01, 10), "cooldown bypassed")
	assert(ElementCombos.canTrigger(10 + cooldown, 10), "cooldown boundary rejected")
end)
