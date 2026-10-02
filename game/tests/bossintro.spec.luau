local BossIntro = load("BossIntro")
local Enemies = load("Enemies")

test("boss poster slam duration stays in the briefed range", function()
	assert(BossIntro.Duration >= 1.5, "boss poster is too brief")
	assert(BossIntro.Duration <= 2, "boss poster is too long")
end)

test("every boss has complete poster data", function()
	for bossId, enemy in Enemies.Defs do
		if enemy.Boss then
			local poster = BossIntro.Posters[bossId]
			assert(poster, bossId .. " needs poster data")
			assert(poster.Name ~= "", bossId .. " needs a poster name")
			assert(poster.Title ~= "", bossId .. " needs a title line")
			assert(#poster.ElementColor == 3, bossId .. " needs an RGB element colour")
			for _, channel in poster.ElementColor do
				assert(channel >= 0 and channel <= 255, bossId .. " has an invalid colour")
			end
		end
	end
end)

test("only repeat views can be skipped", function()
	eq(BossIntro.canSkip(false), false, "first view")
	eq(BossIntro.canSkip(true), true, "repeat view")
end)
