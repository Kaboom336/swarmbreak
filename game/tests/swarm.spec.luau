local BalanceMath = load("BalanceMath")
local Config = load("Config")
local Enemies = load("Enemies")
local WaveTable = load("WaveTable")
local Weapons = load("Weapons")

local function total(composition: { [string]: number }): number
	local count = 0
	for _, amount in composition do
		count += amount
	end
	return count
end

test("early waves build to a swarm", function()
	eq(WaveTable.Compositions[1].Walker, 16, "wave 1 Walkers")
	eq(total(WaveTable.Compositions[1]), 16, "wave 1 total")
	assert(total(WaveTable.Compositions[3]) >= 20, "wave 3 has fewer than 20 enemies")
	assert(total(WaveTable.Compositions[5]) >= 40, "wave 5 has fewer than 40 enemies")
end)

test("packs sum to each composition and use at most two portals", function()
	for wave, composition in WaveTable.Compositions do
		local packed = {}
		local packs = WaveTable.packs(composition)
		for _, pack in packs do
			assert(pack.Size >= 3 and pack.Size <= 6, "pack size out of range")
			assert(pack.PortalCount >= 1 and pack.PortalCount <= 2, "portal count out of range")
			for enemyName, amount in pack.Composition do
				packed[enemyName] = (packed[enemyName] or 0) + amount
			end
		end
		for enemyName, amount in composition do
			eq(packed[enemyName], amount, string.format("wave %d %s", wave, enemyName))
		end
		eq(total(packed), total(composition), "packed total")
	end
	eq(#WaveTable.packs(WaveTable.Compositions[1]), 4, "wave 1 pack count")
end)

test("wave 1 starter time to kill stays at most one second", function()
	local healthScale = WaveTable.scaling(1)
	local ttk =
		BalanceMath.timeToKill(Enemies.Defs.Walker.Health, Weapons.Defs.Starter, healthScale)
	assert(ttk <= 1, "wave 1 Walker TTK exceeds one second: " .. tostring(ttk))
end)

test("whole packs respect MaxAlive", function()
	eq(Config.MaxAlive, 60, "MaxAlive")
	assert(WaveTable.packFits(54, 6, Config.MaxAlive), "six open slots should fit")
	assert(not WaveTable.packFits(55, 6, Config.MaxAlive), "pack must not cross cap")
	assert(not WaveTable.packFits(Config.MaxAlive, 3, Config.MaxAlive), "full cap")
end)
