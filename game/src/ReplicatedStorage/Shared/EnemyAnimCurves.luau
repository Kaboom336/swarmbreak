--!strict
-- Pure timing curves shared by the procedural enemy animator and its tests.

local EnemyAnimCurves = {}

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

function EnemyAnimCurves.walkPhase(phase: number, speed: number, dt: number): number
	return phase + math.max(0, dt) * (2 + math.max(0, speed) * 0.35)
end

function EnemyAnimCurves.swarmlingPose(phase: number): (number, number)
	return math.sin(phase * 2) * 0.16, math.sin(phase) * math.rad(38)
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
