--!strict
-- Pure timing curves shared by the procedural enemy animator and its tests.

local EnemyAnimCurves = {}

EnemyAnimCurves.RigGaitPhase = {
	Odd = 0,
	Even = math.pi,
}

export type WalkProfile = {
	PhaseRate: number,
	SwingDegrees: number,
	BobScale: number,
}

local DEFAULT_WALK_PROFILE: WalkProfile = { PhaseRate = 1, SwingDegrees = 35, BobScale = 1 }

local WalkProfiles: { [string]: WalkProfile } = {
	Walker = { PhaseRate = 1, SwingDegrees = 35, BobScale = 1 },
	Runner = { PhaseRate = 1.4, SwingDegrees = 30, BobScale = 0.6 },
	Flyer = { PhaseRate = 1, SwingDegrees = 20, BobScale = 1.3 },
	Tank = { PhaseRate = 0.6, SwingDegrees = 40, BobScale = 1.6 },
	Spitter = { PhaseRate = 0.9, SwingDegrees = 28, BobScale = 1 },
	Brute = { PhaseRate = 0.7, SwingDegrees = 38, BobScale = 1.5 },
	Queen = { PhaseRate = 0.8, SwingDegrees = 32, BobScale = 1.2 },
	Warden = { PhaseRate = 0.9, SwingDegrees = 22, BobScale = 1.4 },
}
EnemyAnimCurves.WalkProfiles = WalkProfiles

EnemyAnimCurves.HitDuration = 0.12
EnemyAnimCurves.AttackLungeDuration = 0.24
EnemyAnimCurves.DeathCollapseDuration = 0.25
EnemyAnimCurves.DeathDissolveDuration = 0.6
EnemyAnimCurves.DeathDuration = EnemyAnimCurves.DeathCollapseDuration
	+ EnemyAnimCurves.DeathDissolveDuration

local function unit(value: number): number
	return math.clamp(value, 0, 1)
end

local function smooth(value: number): number
	local t = unit(value)
	return t * t * (3 - 2 * t)
end

function EnemyAnimCurves.walkProfileFor(typeName: string?): WalkProfile
	return (typeName and WalkProfiles[typeName]) or DEFAULT_WALK_PROFILE
end

function EnemyAnimCurves.rigGaitPhase(index: number): number
	return if index % 2 == 1
		then EnemyAnimCurves.RigGaitPhase.Odd
		else EnemyAnimCurves.RigGaitPhase.Even
end

function EnemyAnimCurves.walkPhase(
	phase: number,
	speed: number,
	dt: number,
	typeName: string?
): number
	local profile = EnemyAnimCurves.walkProfileFor(typeName)
	return phase + math.max(0, dt) * (2 + math.max(0, speed) * 0.35) * profile.PhaseRate
end

function EnemyAnimCurves.attackWindup(tellDuration: number): number
	return math.max(0, tellDuration)
end

function EnemyAnimCurves.attackPose(elapsed: number, tellDuration: number): (number, number)
	local windupDuration = EnemyAnimCurves.attackWindup(tellDuration)
	if elapsed <= windupDuration then
		local progress = if windupDuration == 0 then 1 else elapsed / windupDuration
		return smooth(progress), 0
	end
	local lungeProgress = unit((elapsed - windupDuration) / EnemyAnimCurves.AttackLungeDuration)
	return 1 - smooth(lungeProgress), math.sin(lungeProgress * math.pi)
end

function EnemyAnimCurves.hitSquash(progress: number): number
	return math.sin(unit(progress) * math.pi)
end

function EnemyAnimCurves.deathCollapse(progress: number): number
	return smooth(progress)
end

function EnemyAnimCurves.deathDissolve(progress: number): number
	return smooth(progress)
end

return EnemyAnimCurves
