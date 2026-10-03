--!strict
local AnimCurves = load("AnimCurves")
local PlayerPose = load("PlayerPose")

local function close(actual: number, expected: number, message: string)
	assert(math.abs(actual - expected) < 1e-6, message)
end

test("player curves start and end at neutral", function()
	local fireStart = AnimCurves.fireLoopAt(0)
	local fireEnd = AnimCurves.fireLoopAt(AnimCurves.FireLoopDuration)
	close(fireStart.BackStuds, 0, "fire start distance")
	close(fireStart.UpDegrees, 0, "fire start angle")
	close(fireEnd.BackStuds, 0, "fire end distance")
	close(fireEnd.UpDegrees, 0, "fire end angle")

	for stage = 1, 3 do
		local start = AnimCurves.comboSwingAt(stage, 0)
		local finish = AnimCurves.comboSwingAt(stage, AnimCurves.ComboDuration)
		close(start.PitchDegrees, 0, "combo pitch start")
		close(start.RollDegrees, 0, "combo roll start")
		close(finish.PitchDegrees, 0, "combo pitch end")
		close(finish.RollDegrees, 0, "combo roll end")
	end

	close(AnimCurves.hitFlinch(0), 0, "flinch start")
	close(AnimCurves.hitFlinch(PlayerPose.HitDuration), 0, "flinch end")
	close(AnimCurves.hitFlinch(PlayerPose.HitDuration / 2), 6, "S0 flinch is six degrees")

	close(AnimCurves.dashRollAt(0), 0, "dash start")
	close(AnimCurves.dashRollAt(AnimCurves.DashRollDuration), 0, "dash end")
	local flourishStart = AnimCurves.levelUpFlourish(0)
	local flourishEnd = AnimCurves.levelUpFlourish(AnimCurves.LevelUpFlourishDuration)
	close(flourishStart.LeftDegrees, 0, "flourish left start")
	close(flourishStart.RightDegrees, 0, "flourish right start")
	close(flourishEnd.LeftDegrees, 0, "flourish left end")
	close(flourishEnd.RightDegrees, 0, "flourish right end")
end)

test("melee combo cycles and resets after eight tenths idle", function()
	eq(AnimCurves.nextComboStage(0, -math.huge, 10), 1, "initial stage")
	eq(AnimCurves.nextComboStage(1, 10, 10.2), 2, "second stage")
	eq(AnimCurves.nextComboStage(2, 10.2, 10.4), 3, "third stage")
	eq(AnimCurves.nextComboStage(3, 10.4, 10.6), 1, "combo wraps")
	eq(AnimCurves.nextComboStage(2, 10, 10.8), 3, "boundary remains in combo")
	eq(AnimCurves.nextComboStage(2, 10, 10.81), 1, "idle combo resets")
end)

test("third combo hit is an overhead instead of another slash", function()
	local slash = AnimCurves.comboSwingAt(1, AnimCurves.ComboPeakTime)
	local reverseSlash = AnimCurves.comboSwingAt(2, AnimCurves.ComboPeakTime)
	local overhead = AnimCurves.comboSwingAt(3, AnimCurves.ComboPeakTime)
	assert(slash.RollDegrees > 0, "first slash should roll right")
	assert(reverseSlash.RollDegrees < 0, "second slash should roll left")
	assert(
		math.abs(overhead.PitchDegrees) > math.abs(overhead.RollDegrees),
		"third hit is overhead"
	)
end)

test("enemy attack uses the S0 limb timing without changing the outer tell", function()
	close(AnimCurves.AttackWindupDuration, 0.15, "wind-up duration")
	close(AnimCurves.AttackStrikeDuration, 0.1, "strike duration")
	close(AnimCurves.AttackRecoveryDuration, 0.25, "recovery duration")
	close(AnimCurves.HitFlashDuration, 0.08, "hit flash duration")
	local tellDuration = 0.6
	local start = AnimCurves.enemyAttackAt(0, tellDuration)
	local pull = AnimCurves.enemyAttackAt(tellDuration, tellDuration)
	local strike =
		AnimCurves.enemyAttackAt(tellDuration + AnimCurves.AttackStrikeDuration, tellDuration)
	local finish = AnimCurves.enemyAttackAt(
		tellDuration + AnimCurves.AttackStrikeDuration + AnimCurves.AttackRecoveryDuration,
		tellDuration
	)
	close(start.Pull, 0, "attack starts neutral")
	close(start.Lunge, 0, "attack starts without lunge")
	close(pull.Pull, 1, "pull peaks at gameplay impact")
	close(strike.Lunge, 1, "strike peaks after one tenth")
	close(finish.Pull, 0, "attack pull recovers")
	close(finish.Lunge, 0, "attack lunge recovers")
end)

test("enemy idle death and gem curves return to neutral", function()
	close(AnimCurves.idleBreath(0), 0, "idle start")
	close(AnimCurves.idleBreath(AnimCurves.IdleBreathSeconds), 0, "idle end")
	close(AnimCurves.deathSquash(0), 0, "death squash start")
	close(AnimCurves.deathSquash(1), 0, "death squash end")
	close(AnimCurves.enemyHitSquash(0), 0, "enemy hit start")
	close(AnimCurves.enemyHitSquash(1), 0, "enemy hit end")
	close(AnimCurves.DeathSquashDuration, 0.12, "death squash duration")
	local gemStart = AnimCurves.gemPop(0)
	local gemEnd = AnimCurves.gemPop(AnimCurves.GemPopDuration)
	close(gemStart.SpinDegrees, 0, "gem spin start")
	close(gemStart.BounceHeight, 0, "gem bounce start")
	close(gemEnd.SpinDegrees, 0, "gem spin end")
	close(gemEnd.BounceHeight, 0, "gem bounce end")
end)

test("enemy walk profiles vary by type", function()
	local walker = AnimCurves.enemyWalkProfileFor("Walker")
	local tank = AnimCurves.enemyWalkProfileFor("Tank")
	assert(walker.PhaseRate ~= tank.PhaseRate, "phase rate should differ by type")
	assert(walker.SwingDegrees ~= tank.SwingDegrees, "swing amplitude should differ by type")
	assert(walker.BobScale ~= tank.BobScale, "bob should differ by type")
	local unknown = AnimCurves.enemyWalkProfileFor("NotARealType")
	eq(unknown.PhaseRate, 1, "unknown types fall back to the default profile")
end)

test("enemy hit curves add a six degree flinch on top of the squash", function()
	close(AnimCurves.enemyHitFlinch(0), 0, "enemy flinch start")
	close(AnimCurves.enemyHitFlinch(1), 0, "enemy flinch end")
	close(
		AnimCurves.enemyHitFlinch(0.5),
		AnimCurves.EnemyHitFlinchDegrees,
		"S0 enemy flinch is six degrees"
	)
	eq(AnimCurves.EnemyHitFlinchDegrees, 6, "enemy flinch matches S0")
end)

test("evolution curves use a six tenth local cinematic envelope", function()
	close(AnimCurves.EvolutionDuration, 0.6, "evolution duration")
	close(AnimCurves.evolutionEnvelope(0), 0, "evolution start")
	assert(AnimCurves.evolutionEnvelope(AnimCurves.EvolutionDuration / 2) > 0, "evolution peaks")
	close(AnimCurves.evolutionEnvelope(AnimCurves.EvolutionDuration), 0, "evolution end")
	close(AnimCurves.evolutionRingDelay(1, 3), 0, "first ring")
	close(AnimCurves.evolutionRingDelay(3, 3), AnimCurves.EvolutionRingStagger * 2, "last ring")
end)

test("evolution slow-mo scales the local cinematic by a single factor", function()
	assert(
		AnimCurves.SlowMoScale > 0 and AnimCurves.SlowMoScale < 1,
		"slow-mo must actually slow down"
	)
	close(AnimCurves.SlowMoSeconds, 0.6, "S2 evolution slow-mo window")
	close(AnimCurves.slowMoElapsed(0), 0, "slow-mo starts at neutral")
	close(
		AnimCurves.slowMoElapsed(1),
		AnimCurves.SlowMoScale,
		"slow-mo scales elapsed time linearly"
	)
end)
