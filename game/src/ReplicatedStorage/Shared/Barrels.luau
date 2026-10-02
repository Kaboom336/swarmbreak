--!strict
-- Pure tuning and math for the server-owned energy barrels.
local Barrels = {
	Health = 90,
	BlastRadius = 18,
	MaxDamage = 120,
	MinDamage = 24,
	Knockback = 72,
	FuseDelay = 0.2,
	ChainDelay = 0.35,
	FriendlyFire = false,
	MaxChainFX = 8,
	Color = { 40, 220, 210 },
}

export type State = {
	Health: number,
	Spent: boolean,
	Queued: boolean,
}

function Barrels.damageAtDistance(distance: number): number
	if distance < 0 or distance > Barrels.BlastRadius then
		return 0
	end
	local alpha = distance / Barrels.BlastRadius
	return Barrels.MaxDamage + (Barrels.MinDamage - Barrels.MaxDamage) * alpha
end

function Barrels.knockbackAtDistance(distance: number): number
	if distance < 0 or distance > Barrels.BlastRadius then
		return 0
	end
	return Barrels.Knockback * (1 - 0.6 * distance / Barrels.BlastRadius)
end

function Barrels.canDamageTarget(isPlayer: boolean): boolean
	return not isPlayer or Barrels.FriendlyFire
end

function Barrels.shouldChain(distance: number): boolean
	return distance >= 0 and distance <= Barrels.BlastRadius
end

function Barrels.newState(): State
	return { Health = Barrels.Health, Spent = false, Queued = false }
end

function Barrels.reset(state: State): State
	state.Health = Barrels.Health
	state.Spent = false
	state.Queued = false
	return state
end

return Barrels
