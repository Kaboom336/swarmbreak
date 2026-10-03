--!strict
local Enemies = load("Enemies")
local EnemyTells = load("EnemyTells")
local Sounds = load("Sounds")
local Theme = load("Theme")

local function sameColor(left: { number }, right: { number }): boolean
	return left[1] == right[1] and left[2] == right[2] and left[3] == right[3]
end

test("every enemy type has a complete warning tell", function()
	for enemyType in Enemies.Defs do
		local tell = EnemyTells.Defs[enemyType]
		assert(tell ~= nil, enemyType .. " needs a tell")
		assert(Sounds[tell.SoundKey] ~= nil, enemyType .. " needs a valid sound key")
		eq(tell.GlowPulse, true, enemyType .. " uses a glow pulse")
		assert(#tell.GlowColor == 3, enemyType .. " needs an RGB glow color")
	end

	for enemyType in EnemyTells.Defs do
		assert(Enemies.Defs[enemyType] ~= nil, "tell references unknown enemy " .. enemyType)
	end
end)

test("windups stay within the readable attack window", function()
	for enemyType, tell in EnemyTells.Defs do
		assert(tell.Windup >= 0.4, enemyType .. " windup is too short")
		assert(tell.Windup <= 0.8, enemyType .. " windup is too long")
	end
end)

test("tell colors are warm and never use player hues", function()
	for enemyType, tell in EnemyTells.Defs do
		local color = tell.GlowColor
		assert(color[1] >= color[2] and color[2] > color[3], enemyType .. " tell must be warm")
		assert(not sameColor(color, Theme.NeonTeal), enemyType .. " tell uses the player teal")
		assert(not sameColor(color, Theme.Rarity.Rare), enemyType .. " tell uses the player blue")
	end
end)

test("Spitter and bosses show a ground area warning", function()
	for enemyType, enemy in Enemies.Defs do
		local needsGroundCircle = enemyType == "Spitter" or enemy.Boss == true
		eq(
			EnemyTells.Defs[enemyType].GroundAoeCircle,
			needsGroundCircle,
			enemyType .. " ground area warning"
		)
	end
end)

test("every enemy wind-up lights a ground telegraph decal", function()
	for enemyType in Enemies.Defs do
		local tell = EnemyTells.Defs[enemyType]
		local timeline = EnemyTells.attackTimeline(tell, 0)
		eq(timeline.ShowWindupDecal, true, enemyType .. " must show a windup decal")
	end
end)

test("attack damage cannot land before the windup ends", function()
	local now = 12.5
	for enemyType, tell in EnemyTells.Defs do
		local timeline = EnemyTells.attackTimeline(tell, now)
		eq(timeline.TellStartsAt, now, enemyType .. " tell start")
		eq(timeline.DamageAt, now + tell.Windup, enemyType .. " damage time")
		assert(timeline.DamageAt >= timeline.TellStartsAt, enemyType .. " damage is too early")
	end
end)

test("zero-windup attacks may land immediately", function()
	local tell = table.clone(EnemyTells.Defs.Walker)
	tell.Windup = 0
	local timeline = EnemyTells.attackTimeline(tell, 24)
	eq(timeline.DamageAt, timeline.TellStartsAt, "zero windup damage time")
end)

test("attack timeline ground circle follows the tell", function()
	for enemyType, tell in EnemyTells.Defs do
		local timeline = EnemyTells.attackTimeline(tell, 0)
		eq(timeline.ShowGroundCircle, tell.GroundAoeCircle, enemyType .. " timeline circle")
	end
end)
