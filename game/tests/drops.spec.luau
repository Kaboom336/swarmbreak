local Drops = load("Drops")
local LevelUp = load("LevelUp")

test("magnet starts at twelve studs and grows with the Magnet card", function()
	eq(Drops.magnetRadius(0), 12, "base magnet radius")
	eq(Drops.magnetRadius(1), 16, "one Magnet card radius")
	eq(Drops.magnetRadius(2), 20, "two Magnet cards radius")
end)

test("uncollected drops fall back after six seconds", function()
	eq(Drops.AutoCollectSeconds, 6, "auto-collect fallback")
end)

test("gem values preserve the old kill XP exactly", function()
	for enemyType in LevelUp.KillXp do
		local sum = 0
		for _, value in Drops.gemsForKill(enemyType) do
			sum += value
		end
		eq(sum, LevelUp.xpForKill(enemyType), enemyType .. " gem XP")
	end
end)
