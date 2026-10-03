local Config = load("Config")
local Enemies = load("Enemies")
local EnemyAnimCurves = load("EnemyAnimCurves")
local SwarmlingStep = load("SwarmlingStep")
local WaveTable = load("WaveTable")

test("one pure step advances one hundred swarmlings", function()
	local units = {}
	for index = 1, 100 do
		table.insert(units, {
			Position = { x = index, y = 3, z = 0 },
			Speed = 12,
		})
	end
	local targets = {
		{ x = 0, y = 3, z = 100 },
		{ x = 200, y = 3, z = 0 },
	}
	local moved = SwarmlingStep.step(units, targets, 0.1)
	eq(#moved, 100, "batch size")
	for index, transform in moved do
		local before = units[index].Position
		assert(transform.x ~= before.x or transform.z ~= before.z, "unit did not advance")
	end
end)

test("client bob and limb swing come from shared curves", function()
	local bob, swing = EnemyAnimCurves.swarmlingPose(math.pi / 4)
	assert(bob > 0, "bob curve")
	assert(swing > 0, "limb swing curve")
end)

test("swarmlings have their own cap and stream sizes", function()
	eq(Config.MaxAlive, 60, "regular cap")
	eq(Config.MaxSwarmlings, 100, "swarmling cap")
	eq(WaveTable.swarmlingCount(1), 0, "wave 1")
	for wave = 2, #WaveTable.Compositions do
		assert(WaveTable.swarmlingCount(wave) >= 10, "wave " .. wave .. " needs a stream")
	end
	for _, stream in WaveTable.swarmlingStreams(47) do
		assert(stream >= 10 and stream <= 20, "stream outside 10..20")
	end
end)

test("swarmlings are cheap XP-only enemies with scale contrast", function()
	local def = Enemies.Defs.Swarmling
	assert(def.NoHumanoid, "Swarmling must not use a Humanoid")
	assert(def.Health <= 20, "Swarmling should die in one or two starter hits")
	assert(def.Damage < Enemies.Defs.Walker.Damage, "Swarmling damage should be low")
	eq(def.Coins, 0, "Swarmling coin drop")
	eq(def.Scale, 1.2, "Swarmling height")
	eq(Enemies.Defs.Tank.Scale, 3.38, "Tank elite height")
	eq(Enemies.Defs.Brute.Scale, 4.68, "Brute elite height")
	eq(Enemies.Defs.Queen.Scale, 5.28, "Queen boss height")
	eq(Enemies.Defs.Warden.Scale, 5.28, "Warden boss height")
end)
