local Enemies = load("Enemies")
local WaveTable = load("WaveTable")

local function threat(composition: { [string]: number }): number
	local total = 0
	for name, count in composition do
		total += Enemies.Defs[name].Health * count
	end
	return total
end

test("waves 1 through 25 have explicit valid compositions", function()
	eq(#WaveTable.Compositions, 25, "composition count")
	for wave = 1, 25 do
		local composition = WaveTable.Compositions[wave]
		assert(composition, "missing wave " .. wave)
		local count = 0
		for name, amount in composition do
			assert(Enemies.Defs[name], "unknown enemy " .. name)
			assert(amount > 0 and amount % 1 == 0, "invalid count for " .. name)
			count += amount
		end
		assert(count > 0, "empty wave " .. wave)
	end
end)

test("total threat grows except for post-boss breathers", function()
	local previous = threat(WaveTable.Compositions[1])
	for wave = 2, 25 do
		local current = threat(WaveTable.Compositions[wave])
		if (wave - 1) % 5 ~= 0 then
			assert(current >= previous, string.format("wave %d threat fell", wave))
		end
		previous = current
	end
end)

test("enemy types are introduced gradually", function()
	local firstWave = {}
	for wave = 1, 25 do
		local introductions = 0
		for name in WaveTable.Compositions[wave] do
			if not firstWave[name] then
				firstWave[name] = wave
				introductions += 1
			end
		end
		assert(
			introductions <= 1,
			string.format("wave %d introduces %d types", wave, introductions)
		)
	end
	eq(firstWave.Spitter, 3, "Spitter first wave")
	eq(firstWave.Flyer, 4, "Flyer first wave")
end)

test("every fifth wave has one boss", function()
	for wave = 1, 25 do
		local bosses = 0
		for name, count in WaveTable.Compositions[wave] do
			if Enemies.Defs[name].Boss then
				bosses += count
			end
		end
		eq(bosses, if wave % 5 == 0 then 1 else 0, "bosses on wave " .. wave)
	end
end)

test("wave 1 stays eight Walkers", function()
	local first = WaveTable.Compositions[1]
	eq(first.Walker, 8, "Walker count")
	for name in first do
		eq(name, "Walker", "only enemy type")
	end
end)
