--!strict
-- Pure upgrade math shared by server (validation) and client (labels).
local Config = require(script.Parent.Config)

export type UpgradeDef = {
	Label: string,
	Base: number,
	PerLevel: number,
	BaseCost: number,
	CostGrowth: number,
	MaxLevel: number,
}

local Upgrades = {}

function Upgrades.def(name: string): UpgradeDef?
	return (Config.Upgrades :: any)[name]
end

function Upgrades.costAt(name: string, level: number): number?
	local u = Upgrades.def(name)
	if not u or level >= u.MaxLevel then
		return nil
	end
	return math.floor(u.BaseCost * u.CostGrowth ^ level + 0.5)
end

function Upgrades.valueAt(name: string, level: number): number
	local u = Upgrades.def(name)
	if not u then
		return 0
	end
	return u.Base + u.PerLevel * level
end

-- Returns (ok, newCoins) without mutating anything.
function Upgrades.tryBuy(name: string, level: number, coins: number): (boolean, number)
	local cost = Upgrades.costAt(name, level)
	if not cost or coins < cost then
		return false, coins
	end
	return true, coins - cost
end

return Upgrades
