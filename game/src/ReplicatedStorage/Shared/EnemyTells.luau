--!strict
-- Readable attack warnings. Colors are {r, g, b} 0..255 so tests can load this file.
export type EnemyTell = {
	SoundKey: string,
	GlowPulse: boolean,
	GlowColor: { number },
	Windup: number,
	GroundAoeCircle: boolean,
	WindupDecal: boolean,
}

export type AttackTimeline = {
	TellStartsAt: number,
	DamageAt: number,
	ShowGroundCircle: boolean,
	ShowWindupDecal: boolean,
}

local Defs: { [string]: EnemyTell } = {
	Walker = {
		SoundKey = "Hurt",
		GlowPulse = true,
		GlowColor = { 255, 130, 40 },
		Windup = 0.4,
		GroundAoeCircle = false,
		WindupDecal = true,
	},
	Runner = {
		SoundKey = "Dash",
		GlowPulse = true,
		GlowColor = { 255, 180, 50 },
		Windup = 0.4,
		GroundAoeCircle = false,
		WindupDecal = true,
	},
	Flyer = {
		SoundKey = "EnemySpawn",
		GlowPulse = true,
		GlowColor = { 255, 150, 70 },
		Windup = 0.5,
		GroundAoeCircle = false,
		WindupDecal = true,
	},
	Tank = {
		SoundKey = "Slam",
		GlowPulse = true,
		GlowColor = { 255, 100, 30 },
		Windup = 0.7,
		GroundAoeCircle = false,
		WindupDecal = true,
	},
	Spitter = {
		SoundKey = "Crate",
		GlowPulse = true,
		GlowColor = { 255, 190, 60 },
		Windup = 0.6,
		GroundAoeCircle = true,
		WindupDecal = true,
	},
	Brute = {
		SoundKey = "BossRoar",
		GlowPulse = true,
		GlowColor = { 255, 80, 20 },
		Windup = 0.8,
		GroundAoeCircle = true,
		WindupDecal = true,
	},
	Queen = {
		SoundKey = "BossRoar",
		GlowPulse = true,
		GlowColor = { 255, 120, 30 },
		Windup = 0.7,
		GroundAoeCircle = true,
		WindupDecal = true,
	},
	Warden = {
		SoundKey = "BossThunder",
		GlowPulse = true,
		GlowColor = { 255, 170, 40 },
		Windup = 0.8,
		GroundAoeCircle = true,
		WindupDecal = true,
	},
}

local EnemyTells = { Defs = Defs }

function EnemyTells.attackTimeline(tell: EnemyTell, now: number): AttackTimeline
	return {
		TellStartsAt = now,
		DamageAt = now + math.max(0, tell.Windup),
		ShowGroundCircle = tell.GroundAoeCircle,
		ShowWindupDecal = tell.WindupDecal,
	}
end

return EnemyTells
