local Mutations = load("Mutations")

local numericFields = {
	"EnemySpeedMult",
	"EnemyHealthMult",
	"PlayerDamageMult",
	"BossScale",
	"CoinMult",
	"Gravity",
	"SpawnMult",
}

test("mutation definitions are well formed", function()
	eq(#Mutations.Order, 7, "seven mutations")
	local seen = {}
	for _, id in Mutations.Order do
		local def = Mutations.Defs[id]
		assert(def, "missing definition " .. id)
		eq(def.Id, id, "id matches key")
		assert(def.Label ~= "", id .. " has a label")
		assert(def.Blurb ~= "", id .. " has a blurb")
		assert(not seen[id], "duplicate id " .. id)
		seen[id] = true
		for _, field in numericFields do
			assert(type(def[field]) == "number", id .. " has numeric " .. field)
			assert(def[field] > 0, id .. " has positive " .. field)
		end
	end
end)

test("daily mutation is deterministic", function()
	for day = 0, 30 do
		eq(Mutations.forDay(day), Mutations.forDay(day), "day " .. day)
	end
end)

test("daily mutation does not repeat on consecutive days", function()
	for day = 0, 364 do
		assert(Mutations.forDay(day) ~= Mutations.forDay(day + 1), "repeat on day " .. day)
	end
end)

test("apply returns a changed copy without mutating its input", function()
	local base = {
		EnemySpeed = 10,
		EnemyHealth = 100,
		PlayerDamage = 20,
		BossScale = 1,
		Coin = 5,
		Gravity = 196.2,
		Spawn = 8,
	}
	local changed = Mutations.apply(base, "FastSwarm")
	assert(changed ~= base, "new table")
	eq(changed.EnemySpeed, 13, "speed applied")
	eq(base.EnemySpeed, 10, "input speed unchanged")
	eq(base.EnemyHealth, 100, "input health unchanged")
	eq(base.Gravity, 196.2, "input gravity unchanged")
end)

test("Double Coins flows through apply", function()
	local changed = Mutations.apply({ Coin = 25, CoinMult = 1 }, "DoubleCoins")
	eq(changed.Coin, 50, "coins doubled")
	eq(changed.CoinMult, 2, "coin multiplier doubled")
end)
