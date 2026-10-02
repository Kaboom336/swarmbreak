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
Feel.HitFlashSeconds = 0.06 -- placeholder
Feel.DamageNumberSeconds = 0.6 -- placeholder
Feel.DamageNumberRiseStuds = 3 -- placeholder
Feel.HitSparkScale = 0.35 -- placeholder
Feel.CritSparkScale = 0.55 -- placeholder
Feel.HitSparkCount = 12 -- placeholder
Feel.CritSparkCount = 20 -- placeholder
Feel.HitSparkSpeed = 18 -- placeholder
Feel.CritSparkSpeed = 24 -- placeholder
Feel.HitSparkSeconds = 0.35 -- placeholder
Feel.HitFlashRange = 8 -- placeholder
Feel.CoinFlightSeconds = 0.55 -- placeholder

-- Each enemy gets its own readable crystal-burst accent on death.
Feel.DeathBurstColors = {
	Walker = { 255, 90, 120 },
	Runner = { 255, 230, 120 },
	Flyer = { 150, 120, 255 },
	Tank = { 120, 255, 140 },
	Spitter = { 190, 255, 90 },
	Brute = { 255, 40, 40 },
	Queen = { 255, 90, 255 },
	Warden = { 90, 200, 255 },
} :: { [string]: { number } }

function Feel.eventFor(killed: boolean, critical: boolean): EventName
	if killed then
		return "Kill"
	elseif critical then
		return "Crit"
	end
	return "Hit"
end

function Feel.deathBurstColor(enemyType: string?, fallback: { number }): { number }
	return if enemyType then Feel.DeathBurstColors[enemyType] or fallback else fallback
end

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
