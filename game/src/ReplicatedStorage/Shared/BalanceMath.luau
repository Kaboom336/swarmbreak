--!strict
-- Pure combat math for offline balance reports and tests.
export type WeaponStats = {
	Damage: number,
	FireRate: number,
	Pellets: number,
}

local BalanceMath = {}

function BalanceMath.damagePerAttack(weapon: WeaponStats, damageMultiplier: number?): number
	return weapon.Damage * weapon.Pellets * (damageMultiplier or 1)
end

function BalanceMath.attacksPerSecond(weapon: WeaponStats, fireRateMultiplier: number?): number
	return weapon.FireRate * (fireRateMultiplier or 1)
end

function BalanceMath.damagePerSecond(
	weapon: WeaponStats,
	damageMultiplier: number?,
	fireRateMultiplier: number?
): number
	return BalanceMath.damagePerAttack(weapon, damageMultiplier)
		* BalanceMath.attacksPerSecond(weapon, fireRateMultiplier)
end

-- TTK follows the game's existing convention: whole attacks divided by attacks per second.
-- For multi-pellet weapons, the estimate assumes every pellet hits the same enemy.
function BalanceMath.timeToKill(
	enemyHealth: number,
	weapon: WeaponStats,
	healthMultiplier: number?,
	damageMultiplier: number?,
	fireRateMultiplier: number?
): number
	if enemyHealth <= 0 then
		return 0
	end

	local damage = BalanceMath.damagePerAttack(weapon, damageMultiplier)
	local rate = BalanceMath.attacksPerSecond(weapon, fireRateMultiplier)
	if damage <= 0 or rate <= 0 then
		return math.huge
	end

	local scaledHealth = enemyHealth * (healthMultiplier or 1)
	return math.ceil(scaledHealth / damage) / rate
end

-- Returns the last consecutive wave whose estimated clear time fits the supplied budget.
function BalanceMath.expectedWaveReached(
	clearSecondsByWave: { number },
	clearBudget: number
): number
	local reached = 0
	for wave, seconds in clearSecondsByWave do
		if seconds > clearBudget then
			break
		end
		reached = wave
	end
	return reached
end

return BalanceMath
