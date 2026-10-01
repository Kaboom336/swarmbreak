local Config = load("Config")
local Enemies = load("Enemies")
local WaveTable = load("WaveTable")

test("enemy count grows each wave and is capped", function()
	eq(WaveTable.enemyCount(1), 6, "wave 1")
	eq(WaveTable.enemyCount(2), 9, "wave 2")
	eq(WaveTable.enemyCount(15), 48, "wave 15")
	assert(WaveTable.enemyCount(16) > WaveTable.enemyCount(15), "infinite adds more")
	eq(WaveTable.enemyCount(500), 80, "cap")
end)

test("no scaling in normal mode, compounding after", function()
	local h, d = WaveTable.scaling(15)
	eq(h, 1, "h15")
	eq(d, 1, "d15")
	local h2, d2 = WaveTable.scaling(17)
	assert(math.abs(h2 - Config.InfiniteHealthScale ^ 2) < 1e-9, "health scale wave 17")
	assert(d2 > 1 and d2 < h2, "damage scales slower than health")
end)

test("bosses on 5, 10, 15 and cycle in infinite", function()
	eq(Enemies.bossForWave(1), nil, "w1")
	eq(Enemies.bossForWave(5), "Brute", "w5")
	eq(Enemies.bossForWave(10), "Queen", "w10")
	eq(Enemies.bossForWave(15), "Warden", "w15")
	eq(Enemies.bossForWave(20), "Brute", "w20")
	eq(Enemies.bossForWave(25), "Queen", "w25")
	eq(Enemies.bossForWave(30), "Warden", "w30")
	eq(Enemies.bossForWave(21), nil, "w21")
	for _, name in { "Brute", "Queen", "Warden" } do
		assert(Enemies.Defs[name] and Enemies.Defs[name].Boss, name .. " is a boss def")
	end
end)

test("wave weights only reference real enemies and unlock in order", function()
	eq(Enemies.weightsForWave(1).Runner, nil, "no runners on wave 1")
	assert(Enemies.weightsForWave(3).Flyer, "flyers by wave 3")
	assert(Enemies.weightsForWave(8).Spitter, "spitters by wave 8")
	for wave = 1, 40 do
		for name in Enemies.weightsForWave(wave) do
			assert(Enemies.Defs[name], "unknown enemy " .. name)
			assert(not Enemies.Defs[name].Boss, "boss in normal weights: " .. name)
		end
	end
end)

test("pickFromWeights is deterministic and covers all names", function()
	local w = { A = 1, B = 1, C = 2 }
	eq(Enemies.pickFromWeights(w, 0.0), "A", "roll 0")
	eq(Enemies.pickFromWeights(w, 0.26), "B", "roll .26")
	eq(Enemies.pickFromWeights(w, 0.6), "C", "roll .6")
	eq(Enemies.pickFromWeights(w, 0.999), "C", "roll .999")
	local seen = {}
	for i = 0, 99 do
		seen[Enemies.pickFromWeights(Enemies.weightsForWave(10), i / 100)] = true
	end
	assert(
		seen.Walker and seen.Runner and seen.Flyer and seen.Tank and seen.Spitter,
		"all types reachable on wave 10"
	)
end)

test("enemy defs are well formed", function()
	for name, d in Enemies.Defs do
		assert(#d.Size == 3 and #d.Color == 3, name .. " size/color")
		assert(
			d.Health > 0 and d.Speed > 0 and d.Damage > 0 and d.Coins > 0,
			name .. " positive stats"
		)
		if d.Ranged then
			assert(d.Range and d.AttackCooldown, name .. " ranged needs Range and AttackCooldown")
		end
		if d.Summons then
			assert(Enemies.Defs[d.Summons] and d.SummonEvery, name .. " summons")
		end
	end
end)
