--!strict
-- Pure orchestration curves for the S0 animation pass. Existing pose modules own
-- their original curves; this module composes them and adds only missing clips.

local AnimIds = require(script.Parent.AnimIds)
local EnemyAnimCurves = require(script.Parent.EnemyAnimCurves)
local PlayerPose = require(script.Parent.PlayerPose)
local WeaponPose = require(script.Parent.WeaponPose)

export type RecoilPose = WeaponPose.RecoilPose
export type ComboPose = {
	PitchDegrees: number,
	RollDegrees: number,
}
export type FlourishPose = {
	LeftDegrees: number,
	RightDegrees: number,
}
export type EnemyAttackPose = {
	Pull: number,
	Lunge: number,
}
export type GemPose = {
	SpinDegrees: number,
	BounceHeight: number,
}

local AnimCurves = {}

AnimCurves.FireLoopDuration = WeaponPose.RecoilSeconds
AnimCurves.FireLoopScale = 0.55
AnimCurves.ComboDuration = WeaponPose.SwingSeconds
AnimCurves.ComboPeakTime = WeaponPose.SwingWindupSeconds + WeaponPose.SwingArcSeconds * 0.75
AnimCurves.ComboResetSeconds = 0.8
AnimCurves.DashRollDuration = PlayerPose.DashDuration
AnimCurves.LevelUpFlourishDuration = 0.4
AnimCurves.IdleBreathSeconds = 2.4
AnimCurves.AttackWindupDuration = 0.15
AnimCurves.AttackStrikeDuration = 0.1
AnimCurves.AttackRecoveryDuration = 0.25
AnimCurves.HitFlashDuration = 0.08
AnimCurves.DeathSquashDuration = 0.12
AnimCurves.GemPopDuration = 0.6
AnimCurves.EvolutionDuration = 0.6
AnimCurves.EvolutionRingStagger = 0.08
AnimCurves.SlowMoScale = 0.35
AnimCurves.SlowMoSeconds = 0.6
AnimCurves.EnemyHitFlinchDegrees = 6

local function unit(value: number): number
	return math.clamp(value, 0, 1)
end

local function smooth(value: number): number
	local t = unit(value)
	return t * t * (3 - 2 * t)
end

function AnimCurves.animationIdFor(group: "Player" | "Enemy" | "FX", clip: string): number
	local groupIds = AnimIds[group]
	return (groupIds and groupIds[clip]) or 0
end

function AnimCurves.fireLoopAt(elapsed: number): RecoilPose
	local recoil = WeaponPose.recoilAt(elapsed)
	return {
		BackStuds = recoil.BackStuds * AnimCurves.FireLoopScale,
		UpDegrees = recoil.UpDegrees * AnimCurves.FireLoopScale,
	}
end

function AnimCurves.comboSwingAt(stage: number, elapsed: number): ComboPose
	local safeStage = math.clamp(math.floor(stage), 1, 3)
	local swing = WeaponPose.swingAt(elapsed)
	if safeStage == 1 then
		return { PitchDegrees = 0, RollDegrees = swing }
	elseif safeStage == 2 then
		return { PitchDegrees = 0, RollDegrees = -swing }
	end
	return {
		PitchDegrees = -swing * 1.15,
		RollDegrees = swing * 0.12,
	}
end

function AnimCurves.nextComboStage(stage: number, lastHitAt: number, now: number): number
	if now - lastHitAt > AnimCurves.ComboResetSeconds + 1e-9 then
		return 1
	end
	return math.clamp(math.floor(stage), 0, 3) % 3 + 1
end

function AnimCurves.dashRollAt(elapsed: number): number
	if elapsed < 0 or elapsed >= AnimCurves.DashRollDuration then
		return 0
	end
	return 360 * smooth(elapsed / AnimCurves.DashRollDuration)
end

function AnimCurves.hitFlinch(elapsed: number): number
	return PlayerPose.hitFlinch(elapsed)
end

function AnimCurves.levelUpFlourish(elapsed: number): FlourishPose
	if elapsed < 0 or elapsed >= AnimCurves.LevelUpFlourishDuration then
		return { LeftDegrees = 0, RightDegrees = 0 }
	end
	local lift = math.sin(unit(elapsed / AnimCurves.LevelUpFlourishDuration) * math.pi) * 135
	return { LeftDegrees = -lift, RightDegrees = -lift }
end

function AnimCurves.idleBreath(elapsed: number): number
	return math.sin((elapsed / AnimCurves.IdleBreathSeconds) * math.pi * 2) * 0.04
end

function AnimCurves.enemyWalkPhase(
	phase: number,
	speed: number,
	deltaTime: number,
	typeName: string?
): number
	return EnemyAnimCurves.walkPhase(phase, speed, deltaTime, typeName)
end

function AnimCurves.enemyWalkProfileFor(typeName: string?): EnemyAnimCurves.WalkProfile
	return EnemyAnimCurves.walkProfileFor(typeName)
end

function AnimCurves.enemyAttackAt(elapsed: number, tellDuration: number): EnemyAttackPose
	local outerWindup = EnemyAnimCurves.attackWindup(tellDuration)
	local pullStart = math.max(0, outerWindup - AnimCurves.AttackWindupDuration)
	if elapsed <= pullStart then
		return { Pull = 0, Lunge = 0 }
	elseif elapsed <= outerWindup then
		return {
			Pull = smooth((elapsed - pullStart) / AnimCurves.AttackWindupDuration),
			Lunge = 0,
		}
	end

	local strikeElapsed = elapsed - outerWindup
	if strikeElapsed <= AnimCurves.AttackStrikeDuration then
		local strike = smooth(strikeElapsed / AnimCurves.AttackStrikeDuration)
		return { Pull = 1 - strike, Lunge = strike }
	end

	local recoveryElapsed = strikeElapsed - AnimCurves.AttackStrikeDuration
	if recoveryElapsed < AnimCurves.AttackRecoveryDuration then
		local recovery = smooth(recoveryElapsed / AnimCurves.AttackRecoveryDuration)
		return { Pull = 0, Lunge = 1 - recovery }
	end
	return { Pull = 0, Lunge = 0 }
end

function AnimCurves.enemyHitSquash(progress: number): number
	return EnemyAnimCurves.hitSquash(progress)
end

function AnimCurves.enemyHitFlinch(progress: number): number
	return AnimCurves.EnemyHitFlinchDegrees * EnemyAnimCurves.hitSquash(progress)
end

function AnimCurves.deathSquash(progress: number): number
	return math.sin(unit(progress) * math.pi)
end

function AnimCurves.gemPop(elapsed: number): GemPose
	if elapsed < 0 or elapsed >= AnimCurves.GemPopDuration then
		return { SpinDegrees = 0, BounceHeight = 0 }
	end
	local progress = unit(elapsed / AnimCurves.GemPopDuration)
	return {
		SpinDegrees = 720 * smooth(progress),
		BounceHeight = 2.25 * math.sin(progress * math.pi),
	}
end

function AnimCurves.slowMoElapsed(realElapsed: number): number
	return math.max(0, realElapsed) * AnimCurves.SlowMoScale
end

function AnimCurves.evolutionEnvelope(elapsed: number): number
	if elapsed < 0 or elapsed >= AnimCurves.EvolutionDuration then
		return 0
	end
	return math.sin(unit(elapsed / AnimCurves.EvolutionDuration) * math.pi)
end

function AnimCurves.evolutionRingDelay(index: number, count: number): number
	local safeCount = math.max(1, math.floor(count))
	local safeIndex = math.clamp(math.floor(index), 1, safeCount)
	return (safeIndex - 1) * AnimCurves.EvolutionRingStagger
end

return AnimCurves
