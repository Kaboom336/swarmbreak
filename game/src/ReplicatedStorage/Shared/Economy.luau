--!strict
-- Coin math. Pure.
local Config = require(script.Parent.Config)
local CoPlay = require(script.Parent.CoPlay)

local Economy = {}

function Economy.catchUpCoins(list: { any }): number
	local total = 0
	local count = 0
	for _, coins in list do
		if type(coins) == "number" and coins >= 0 then
			total += coins
			count += 1
		end
	end
	if count == 0 then
		return 0
	end
	return math.floor(total / count + 0.5)
end

function Economy.coinsForKill(
	baseCoins: number,
	hasDoubleCoins: boolean,
	wave: number,
	friendsInArena: number?
): number
	local mult = if hasDoubleCoins then Config.DoubleCoinsMultiplier else Config.CoinsBaseMultiplier
	local waveBonus = 1 + 0.05 * math.max(0, wave - 1)
	return math.floor(baseCoins * mult * waveBonus * CoPlay.coinMult(friendsInArena or 0) + 0.5)
end

function Economy.waveClearBonus(wave: number): number
	return 10 * wave
end

return Economy
