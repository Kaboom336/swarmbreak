local Config = load("Config")
local Upgrades = load("Upgrades")
local Economy = load("Economy")

test("catch-up coins use the rounded average", function()
	eq(Economy.catchUpCoins({ 10, 20, 30 }), 20, "average")
	eq(Economy.catchUpCoins({ 2, 3 }), 3, "round half up")
end)

test("catch-up coins ignore invalid entries", function()
	local coins = { [1] = 10, [2] = -4, [3] = "bad", [5] = 20 }
	eq(Economy.catchUpCoins(coins), 15, "only non-negative numbers")
	eq(Economy.catchUpCoins({}), 0, "empty list")
	eq(Economy.catchUpCoins({ nil, -1, "bad" }), 0, "no valid entries")
end)

test("upgrade cost rises and stops at max level", function()
	for _, name in Config.UpgradeOrder do
		local u = Upgrades.def(name)
		assert(u, name)
		local prev = 0
		for level = 0, u.MaxLevel - 1 do
			local c = Upgrades.costAt(name, level)
			assert(c and c > prev, name .. " cost at " .. level)
			prev = c
		end
		eq(Upgrades.costAt(name, u.MaxLevel), nil, name .. " maxed")
	end
end)

test("tryBuy never mutates and refuses when poor", function()
	local ok, coins = Upgrades.tryBuy("Damage", 0, 10)
	eq(ok, false, "poor")
	eq(coins, 10, "coins untouched")
	local ok2, coins2 = Upgrades.tryBuy("Damage", 0, 100)
	eq(ok2, true, "rich")
	eq(coins2, 100 - Upgrades.costAt("Damage", 0), "coins spent")
	eq(Upgrades.tryBuy("Nope", 0, 999), false, "unknown upgrade")
end)

test("valueAt follows base + per level", function()
	eq(Upgrades.valueAt("Speed", 0), 20, "speed base")
	eq(Upgrades.valueAt("Speed", 2), 23, "speed lv2")
	eq(Upgrades.valueAt("MaxHealth", 3), 160, "hp lv3")
end)

test("double coins pass doubles and wave bonus grows", function()
	eq(Economy.coinsForKill(10, false, 1), 10, "base")
	eq(Economy.coinsForKill(10, true, 1), 20, "double")
	assert(Economy.coinsForKill(10, false, 11) > Economy.coinsForKill(10, false, 1), "wave bonus")
	eq(Economy.waveClearBonus(3), 30, "clear bonus")
end)
