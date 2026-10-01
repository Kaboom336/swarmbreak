--!strict
-- Shared tuning for hit stop, camera shake, and floating damage numbers.

export type EventName = "Hit" | "Crit" | "Kill" | "BossHit" | "BossKill"
export type ShakeSetting = "Off" | "Low" | "Full"
export type EventBudget = {
	FreezeMs: number,
	Shake: number,
	NumberScale: number,
}
export type NumberState = { number }

local Feel = {}

-- Placeholder values until playtesting establishes final feel tuning.
Feel.Events = {
	Hit = { FreezeMs = 0, Shake = 0.2, NumberScale = 1 },
	Crit = { FreezeMs = 40, Shake = 0.5, NumberScale = 1.25 },
	Kill = { FreezeMs = 0, Shake = 0.7, NumberScale = 1.4 },
	BossHit = { FreezeMs = 60, Shake = 1, NumberScale = 1.6 },
	BossKill = { FreezeMs = 80, Shake = 2, NumberScale = 2 },
} :: { [EventName]: EventBudget }

Feel.NumberCapPerSecond = 20 -- placeholder

function Feel.allowNumber(state: NumberState, now: number): (NumberState, boolean)
	local nextState: NumberState = {}
	for _, shownAt in state do
		if now - shownAt < 1 then
			table.insert(nextState, shownAt)
		end
	end

	local allowed = #nextState < Feel.NumberCapPerSecond
	if allowed then
		table.insert(nextState, now)
	end
	return nextState, allowed
end

function Feel.shakeFor(event: EventName, setting: ShakeSetting): number
	if setting == "Off" then
		return 0
	end

	local full = Feel.Events[event].Shake
	if setting == "Low" then
		return full * 0.5
	end
	return full
end

return Feel
