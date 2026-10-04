--!strict
-- Pure raid-end banking. Run currency is never written directly to a profile.
export type Outcome = "Clear" | "Death" | "EarlyLeave"
export type Result = { Gold: number, Gems: number, Rate: number }

local Deposit = {}

Deposit.Rates = {
	Clear = 1,
	Death = 0.5,
	EarlyLeave = 0,
}

local function currency(value: number): number
	if value ~= value or value < 0 then
		return 0
	end
	return math.floor(value)
end

function Deposit.calculate(runGold: number, runGems: number, outcome: Outcome): Result
	local rate = Deposit.Rates[outcome] or 0
	return {
		Gold = math.floor(currency(runGold) * rate),
		Gems = math.floor(currency(runGems) * rate),
		Rate = rate,
	}
end

return Deposit
