--!strict
-- Pure pickup tuning and XP-gem value math.
local LevelUp = require(script.Parent.LevelUp)

local Drops = {}

Drops.BaseMagnetRadius = 12
Drops.MagnetRadiusPerCard = 4
Drops.AutoCollectSeconds = 6
Drops.GemDenominations = { 10, 5, 1 }

function Drops.magnetRadius(magnetCards: number): number
	return Drops.BaseMagnetRadius + math.max(0, math.floor(magnetCards)) * Drops.MagnetRadiusPerCard
end

function Drops.gemValues(totalXp: number): { number }
	local values = {}
	local remaining = math.max(0, math.floor(totalXp))
	for _, denomination in Drops.GemDenominations do
		while remaining >= denomination do
			table.insert(values, denomination)
			remaining -= denomination
		end
	end
	return values
end

function Drops.gemsForKill(enemyType: string): { number }
	return Drops.gemValues(LevelUp.xpForKill(enemyType))
end

return Drops
