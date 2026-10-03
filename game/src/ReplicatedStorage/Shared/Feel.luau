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
	Kill = { FreezeMs = 0, Shake = 0.15, NumberScale = 1.4 },
	BossHit = { FreezeMs = 60, Shake = 1, NumberScale = 1.6 },
	BossKill = { FreezeMs = 80, Shake = 2, NumberScale = 2 },
} :: { [EventName]: EventBudget }

Feel.NumberCapPerSecond = 20 -- placeholder
Feel.TracerSeconds = 0.08
Feel.MuzzleFlashSeconds = 0.08
Feel.WeaponMuzzleFlashSeconds = 0.05
Feel.WeaponCameraKick = 0.3
Feel.HitFlashSeconds = 0.06
Feel.DamageNumberSeconds = 0.6
Feel.DamageNumberRiseStuds = 3
Feel.HitSparkScale = 0.35
Feel.CritSparkScale = 0.55
Feel.HitSparkCount = 12
Feel.CritSparkCount = 20
Feel.HitSparkSpeed = 18
Feel.CritSparkSpeed = 24
Feel.HitSparkSeconds = 0.35
Feel.HitFlashRange = 8
Feel.CoinFlightSeconds = 0.55
Feel.KnockbackSpeed = 8
Feel.KnockbackStuds = 2

-- Every enemy gets a bloodless teal/green goo-burst accent on death.
Feel.DeathBurstColors = {
	Swarmling = { 45, 225, 180 },
	Walker = { 55, 230, 175 },
	Runner = { 120, 255, 120 },
	Flyer = { 60, 220, 210 },
	Tank = { 80, 190, 105 },
	Spitter = { 180, 255, 70 },
	Brute = { 35, 175, 125 },
	Queen = { 75, 240, 180 },
	Warden = { 45, 205, 160 },
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
