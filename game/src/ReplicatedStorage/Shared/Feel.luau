--!strict
-- Shared tuning for hit stop, camera shake, and floating damage numbers.
local Theme = require(script.Parent.Theme)

export type EventName = "Hit" | "Crit" | "Kill" | "EliteKill" | "BossHit" | "BossKill"
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
	Hit = { FreezeMs = 0, Shake = 0, NumberScale = 1 }, -- auto-fire hits every few frames; no shake
	Crit = { FreezeMs = 40, Shake = 0.2, NumberScale = 1.25 },
	Kill = { FreezeMs = 50, Shake = 0, NumberScale = 1.4 },
	EliteKill = { FreezeMs = 80, Shake = 1, NumberScale = 1.6 },
	BossHit = { FreezeMs = 60, Shake = 1, NumberScale = 1.6 },
	BossKill = { FreezeMs = 80, Shake = 2, NumberScale = 2 },
} :: { [EventName]: EventBudget }

Feel.NumberCapPerSecond = 20 -- placeholder
Feel.TracerSeconds = 0.08
Feel.MuzzleFlashSeconds = 0.06
Feel.WeaponMuzzleFlashSeconds = 0.05
Feel.WeaponCameraKick = 0.15 -- melee swings only
Feel.HitFlashSeconds = 0.08
Feel.DamageNumberSeconds = 0.6
Feel.DamageNumberRiseStuds = 3
Feel.DamageNumberNormalPixels = 28
Feel.DamageNumberCritPixels = 40
Feel.DamageNumberPopScale = 1.3
Feel.DamageNumberFont = "FredokaOne"
Feel.ScytheDamageNumberScale = 1.5
Feel.ScytheHitStopSeconds = 0.04
Feel.HitSparkScale = 0.35
Feel.CritSparkScale = 0.55
Feel.HitSparkCount = 4
Feel.CritSparkCount = 4
Feel.HitSparkSpeed = 18
Feel.CritSparkSpeed = 24
Feel.HitSparkSeconds = 0.1
Feel.HitFlashRange = 8
Feel.CoinFlightSeconds = 0.55
Feel.KnockbackSpeed = 8
Feel.KnockbackStuds = 2
Feel.GhostKnockbackStuds = 3
Feel.GemMagnetRadius = 18
Feel.BossIntroShakePulse = 0.3
Feel.BossKillSlowMoSeconds = 0.6
Feel.BossKillSlowMoScale = 0.35

-- Every enemy gets a bloodless teal/green goo-burst accent on death.
Feel.DeathBurstColors = {
	Walker = Theme.Enemy.Walker.Accent,
	Runner = Theme.Enemy.Runner.Accent,
	Flyer = Theme.Enemy.Flyer.Accent,
	Tank = Theme.Enemy.Tank.Accent,
	Spitter = Theme.Enemy.Spitter.Accent,
	Brute = Theme.Enemy.Brute.Accent,
	Queen = Theme.Enemy.Queen.Accent,
	Warden = Theme.Enemy.Warden.Accent,
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
