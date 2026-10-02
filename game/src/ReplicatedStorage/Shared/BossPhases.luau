--!strict
-- One health-gated phase per boss. Kept as pure data + math so transitions are testable.
export type AttackModifiers = {
	AttackCooldownMultiplier: number,
	SummonCooldownMultiplier: number,
	SummonCount: number,
	VolleyCount: number,
	VolleyInterval: number,
}

export type Definition = {
	Threshold: number,
	OneShot: boolean,
	Banner: string,
	Color: { number },
	Modifiers: AttackModifiers,
}

local Defs: { [string]: Definition } = {
	Brute = {
		Threshold = 0.5,
		OneShot = true,
		Banner = "BRUTE RAMPAGE",
		Color = { 255, 92, 35 },
		Modifiers = {
			AttackCooldownMultiplier = 0.65,
			SummonCooldownMultiplier = 1,
			SummonCount = 1,
			VolleyCount = 1,
			VolleyInterval = 0.2,
		},
	},
	Queen = {
		Threshold = 0.5,
		OneShot = true,
		Banner = "THE SWARM SURGES",
		Color = { 255, 82, 190 },
		Modifiers = {
			AttackCooldownMultiplier = 1,
			SummonCooldownMultiplier = 0.75,
			SummonCount = 2,
			VolleyCount = 1,
			VolleyInterval = 0.2,
		},
	},
	Warden = {
		Threshold = 0.5,
		OneShot = true,
		Banner = "SKYFIRE VOLLEY",
		Color = { 92, 175, 255 },
		Modifiers = {
			AttackCooldownMultiplier = 1,
			SummonCooldownMultiplier = 1,
			SummonCount = 1,
			VolleyCount = 3,
			VolleyInterval = 0.18,
		},
	},
}

local BossPhases = { Defs = Defs }

-- Inclusive threshold: landing exactly on the health boundary starts phase two.
function BossPhases.shouldTransition(
	typeName: string,
	health: number,
	maxHealth: number,
	alreadyTransitioned: boolean
): boolean
	local def = Defs[typeName]
	return def ~= nil
		and def.OneShot
		and not alreadyTransitioned
		and maxHealth > 0
		and health > 0
		and health / maxHealth <= def.Threshold
end

return BossPhases
