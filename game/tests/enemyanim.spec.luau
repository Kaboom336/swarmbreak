--!strict
local EnemyAnimCurves = load("EnemyAnimCurves")
local EnemyTells = load("EnemyTells")

local function bounded(value: number, label: string)
	assert(value >= 0 and value <= 1, label .. " must stay between zero and one")
end

test("walk phase advances in proportion to speed", function()
	local idle = EnemyAnimCurves.walkPhase(2, 0, 0.25)
	local walking = EnemyAnimCurves.walkPhase(2, 8, 0.25)
	local running = EnemyAnimCurves.walkPhase(2, 16, 0.25)
	assert(walking > idle, "walking should advance beyond idle")
	assert(running - 2 > walking - 2, "running should advance farther than walking")
end)

test("attack wind-up matches every enemy tell", function()
	for enemyType, tell in EnemyTells.Defs do
		eq(EnemyAnimCurves.attackWindup(tell.Windup), tell.Windup, enemyType .. " attack wind-up")
		local windup, lunge = EnemyAnimCurves.attackPose(tell.Windup, tell.Windup)
		eq(windup, 1, enemyType .. " wind-up pose at impact")
		eq(lunge, 0, enemyType .. " lunge starts after impact")
	end
end)

test("hit and death timings fit the animation budget", function()
	eq(EnemyAnimCurves.HitDuration, 0.12, "hit squash duration")
	eq(EnemyAnimCurves.DeathDissolveDuration, 0.6, "death dissolve duration")
	assert(EnemyAnimCurves.DeathDuration <= 1, "death sequence is too long")
end)

test("animation curves remain bounded", function()
	for step = -10, 110 do
		local t = step / 100
		bounded(EnemyAnimCurves.hitSquash(t), "hit squash")
		bounded(EnemyAnimCurves.deathCollapse(t), "death collapse")
		bounded(EnemyAnimCurves.deathDissolve(t), "death dissolve")
		local windup, lunge = EnemyAnimCurves.attackPose(t, 0.6)
		bounded(windup, "attack wind-up")
		bounded(lunge, "attack lunge")
	end
end)
