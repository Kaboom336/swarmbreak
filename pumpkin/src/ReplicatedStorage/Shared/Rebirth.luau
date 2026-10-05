--!strict
local Config = require(script.Parent.Config)

local Rebirth = {}

function Rebirth.cost(rebirths: number): number
	local count = math.max(0, math.floor(rebirths))
	return Config.RebirthBaseCost * 2 ^ count
end

function Rebirth.multiplier(rebirths: number): number
	return 1 + math.max(0, math.floor(rebirths)) * Config.RebirthSizeBonus
end

function Rebirth.canAfford(wins: number, rebirths: number): boolean
	return math.max(0, wins) >= Rebirth.cost(rebirths)
end

return Rebirth
