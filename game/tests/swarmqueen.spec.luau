--!strict
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local ArenaLayout = load("ArenaLayout")
local BossFight = load("BossFight")
local Campaign = load("Campaign")
local Config = load("Config")
local Feel = load("Feel")

local function overlapsCircle(rect, circle): boolean
	local closestX = math.clamp(circle.x, rect.ax, rect.bx)
	local closestZ = math.clamp(circle.z, rect.az, rect.bz)
	local dx = circle.x - closestX
	local dz = circle.z - closestZ
	return dx * dx + dz * dz < circle.Radius * circle.Radius
end

test("Outpost 9 ends with the Swarm Queen in Hive Core", function()
	eq(Campaign.get("Outpost9").BossKey, "Queen", "final boss")
	local spawn = ArenaLayout.bossSpawnForWave(15)
	eq(ArenaLayout.zoneForWave(15).Id, "HiveCore", "boss zone")
	assert(
		ArenaLayout.zoneContains(ArenaLayout.zoneForWave(15), spawn),
		"boss spawn is in Hive Core"
	)
end)

test("Queen phases and attack timing match the brief", function()
	eq(BossFight.PhaseTwoHealthRatio, 0.55, "phase-two threshold")
	eq(BossFight.phaseForHealth(56, 100), 1, "above threshold")
	eq(BossFight.phaseForHealth(55, 100), 2, "at threshold")
	eq(#BossFight.Attacks, 3, "attack count")
	eq(BossFight.Attacks[1].Shape, "Arc", "tail sweep shape")
	eq(BossFight.Attacks[2].Shape, "ThreeCircles", "goo mortar shape")
	eq(BossFight.Attacks[3].Shape, "Line", "charge shape")
	for _, attack in BossFight.Attacks do
		eq(attack.TelegraphSeconds, 0.8, attack.Name .. " telegraph")
		assert(attack.TelegraphSeconds >= 0.6, attack.Name .. " warning is too short")
	end
	eq(BossFight.attackInterval(2), BossFight.attackInterval(1) * 0.8, "phase-two speedup")
end)

test("the runtime drives the Queen encounter from the shared rules", function()
	local aiSource = fs.readFile("src/ServerStorage/EnemyAI.luau")
	local waveSource = fs.readFile("src/ServerScriptService/WaveManager.server.luau")
	local effectsSource = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Effects.client.luau")
	local introSource = fs.readFile("src/StarterPlayer/StarterPlayerScripts/BossIntro.client.luau")
	assert(aiSource:find("BossFight.Attacks", 1, true), "Queen attacks must use BossFight.Attacks")
	assert(aiSource:find("BossFight.attackInterval", 1, true), "Queen cadence must use BossFight")
	assert(waveSource:find("ArenaLayout.floorRects", 1, true), "goo must use floor rects")
	assert(waveSource:find("ArenaLayout.gateOpen", 1, true), "adds must use open Hive gates")
	assert(
		effectsSource:find("handlers.queenKill", 1, true),
		"Queen kill needs client presentation"
	)
	assert(introSource:find("BossIntroShakePulse", 1, true), "intro owns the one shake pulse")
end)

test("phase two adds use two Hive gates every twelve seconds and respect the cap", function()
	eq(BossFight.AddEverySeconds, 12, "add cadence")
	eq(#BossFight.AddGateNames, 2, "add gate count")
	for _, gateName in BossFight.AddGateNames do
		local found = false
		for _, gate in ArenaLayout.ZoneSpawns do
			if gate.Name == gateName then
				found = true
				eq(gate.ZoneId, "HiveCore", gateName .. " zone")
				assert(
					ArenaLayout.gateOpen(11, 15, gate.ZoneId, 15, {}),
					gateName .. " must be open on wave 15"
				)
			end
		end
		assert(found, gateName .. " is not an arena gate")
	end
	eq(BossFight.canAdd(Config.MaxAlive - 1, Config.MaxAlive), true, "one free slot")
	eq(BossFight.canAdd(Config.MaxAlive, Config.MaxAlive), false, "pool is full")
end)

test("goo pools stay on floor rectangles and never cover holes or gates", function()
	local zone = ArenaLayout.zoneForWave(15)
	local floorRects = ArenaLayout.floorRects(zone)
	local pools = BossFight.gooPools(floorRects, ArenaLayout.ZoneSpawns)
	assert(#pools > 0, "phase two needs goo pools")
	for index, pool in pools do
		local insideFloor = false
		for _, rect in floorRects do
			if
				pool.x - pool.Radius >= rect.ax
				and pool.x + pool.Radius <= rect.bx
				and pool.z - pool.Radius >= rect.az
				and pool.z + pool.Radius <= rect.bz
			then
				insideFloor = true
			end
		end
		assert(insideFloor, "goo pool " .. index .. " is not contained by a floor rect")
		for _, gap in ArenaLayout.DashGaps do
			if gap.ZoneId == zone.Id then
				local rect = {
					ax = gap.x - gap.Width / 2,
					az = gap.z - gap.Length / 2,
					bx = gap.x + gap.Width / 2,
					bz = gap.z + gap.Length / 2,
				}
				assert(not overlapsCircle(rect, pool), "goo pool " .. index .. " covers a dash gap")
			end
		end
		for _, gate in ArenaLayout.ZoneSpawns do
			if gate.ZoneId == zone.Id then
				local dx = pool.x - gate.x
				local dz = pool.z - gate.z
				assert(
					dx * dx + dz * dz >= (pool.Radius + BossFight.GateClearance) ^ 2,
					"goo pool " .. index .. " covers gate " .. gate.Name
				)
			end
		end
	end
end)

test("Queen kill slow motion is a client feel constant", function()
	eq(Feel.BossKillSlowMoSeconds, 0.6, "slow-motion duration")
	eq(BossFight.GooDamagePerSecond, 8, "goo damage")
	local waveSource = fs.readFile("src/ServerScriptService/WaveManager.server.luau")
	assert(
		not waveSource:find("KillSlowMoSeconds", 1, true),
		"server must not wait on client slow motion"
	)
end)

test("Queen rig is an all-Part Nest rig with eight legs", function()
	local source = fs.readFile("assets/rigs/Queen.json")
	eq(fs.readFile("src/ReplicatedStorage/Shared/Rigs/Queen.json"), source, "shipped Queen JSON")
	local data = serde.decode("json", source)
	eq(data.PrimaryPart, "Body", "primary part")
	local parts = {}
	for _, part in data.Parts do
		parts[part.Name] = (parts[part.Name] or 0) + 1
		eq(part.ClassName, "Part", part.Name .. " class")
		assert(part.MeshId == nil, part.Name .. " must not have a MeshId")
		assert(
			not (part.Material == "Neon" and math.max(table.unpack(part.Size)) > 1.5),
			part.Name .. " is oversized Neon"
		)
	end
	eq(parts.Body, 1, "Body")
	eq(parts.Head, 1, "Head")
	for index = 1, 8 do
		eq(parts["Leg_" .. index], 1, "Leg_" .. index)
	end

	local motors = {}
	for _, motor in data.Motor6Ds do
		motors[motor.Name] = motor
	end
	eq(motors.Neck.Part0, "Body", "Neck Part0")
	eq(motors.Neck.Part1, "Head", "Neck Part1")
	for index = 1, 8 do
		local motor = motors["Hip_" .. index]
		assert(motor ~= nil, "missing Hip_" .. index)
		eq(motor.Part0, "Body", "Hip Part0")
		eq(motor.Part1, "Leg_" .. index, "Hip Part1")
	end
end)
