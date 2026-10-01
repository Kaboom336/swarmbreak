--!strict
-- Coin math. Pure.
local Config = require(script.Parent.Config)

local Economy = {}

function Economy.coinsForKill(baseCoins: number, hasDoubleCoins: boolean, wave: number): number
	local mult = if hasDoubleCoins then Config.DoubleCoinsMultiplier else Config.CoinsBaseMultiplier
	local waveBonus = 1 + 0.05 * math.max(0, wave - 1)
	return math.floor(baseCoins * mult * waveBonus + 0.5)
end

function Economy.waveClearBonus(wave: number): number
	return 10 * wave
end

return Economy
