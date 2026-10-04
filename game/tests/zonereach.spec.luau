--!strict
local fs = require("@lune/fs")

local ArenaLayout = load("ArenaLayout")
local EnemyWatchdog = load("EnemyWatchdog")
local EnemyFamilies = load("EnemyFamilies")

test("every gate stands on floor (e38b458: Refinery gates hung over the dash trench)", function()
	for _, spawn in ArenaLayout.ZoneSpawns do
		for _, offset in { { 0, 0 }, { -3, -3 }, { 3, 3 }, { -3, 3 }, { 3, -3 } } do
			assert(
				ArenaLayout.onFloor({ x = spawn.x + offset[1], z = spawn.z + offset[2] }),
				spawn.Name .. " has no floor under it"
			)
		end
	end
end)

test("each island can be walked across, and the dash gap is still a hole", function()
	for _, zone in ArenaLayout.Zones do
		for x = zone.x - zone.Width / 2 + 1, zone.x + zone.Width / 2 - 1 do
			assert(ArenaLayout.onFloor({ x = x, z = zone.z }), zone.Id .. " is cut at x " .. x)
		end
	end
	for _, gap in ArenaLayout.DashGaps do
		assert(not ArenaLayout.onFloor({ x = gap.x, z = gap.z }), gap.Name .. " has no hole")
		assert(gap.Width >= 14 and gap.Width <= 18, gap.Name .. " dash width")
	end
end)

test("an open earlier zone keeps spawning while a player stands in it", function()
	local inLanding = ArenaLayout.playerZones({ { x = 0, z = 0 } })
	eq(inLanding.LandingPad, true, "player zone")
	eq(ArenaLayout.gateOpen(1, 5, "LandingPad", 11, inLanding), true, "landing gate, player there")
	eq(ArenaLayout.gateOpen(1, 5, "LandingPad", 11, {}), false, "landing gate, nobody there")
	eq(ArenaLayout.gateOpen(11, 15, "HiveCore", 11, inLanding), true, "current zone gate")
	eq(ArenaLayout.gateOpen(11, 15, "HiveCore", 6, inLanding), false, "locked zone gate")
	eq(ArenaLayout.gateOpen(nil, nil, nil, 3, {}), true, "legacy gate without attributes")
end)

test("an enemy that keeps getting stuck after respawns is killed", function()
	eq(EnemyWatchdog.capRespawns("Respawn", 0), "Respawn", "first respawn")
	eq(EnemyWatchdog.capRespawns("Respawn", EnemyWatchdog.MaxRespawns), "Kill", "respawn loop")
	eq(EnemyWatchdog.capRespawns("Ok", 99), "Ok", "healthy enemy")
end)

test("Nest rigs scale to the S6 height bands, not the old primitive sizes", function()
	local bands = {
		Swarmer = { 4, 5 },
		Runner = { 5, 6 },
		Shooter = { 6, 7 },
		Tank = { 9, 11 },
		Flyer = { 5.5, 6.5 },
	}
	for _, role in EnemyFamilies.RequiredRoles do
		local enemyType = EnemyFamilies.resolve("Nest", role)
		local height = EnemyFamilies.rigHeight("Nest", enemyType)
		assert(height, role .. " has no rig height")
		assert(height >= bands[role][1] and height <= bands[role][2], role .. " height out of band")
	end
	local source = fs.readFile("src/ServerStorage/EnemyRigBuilder.luau")
	assert(source:find("EnemyFamilies.rigHeight", 1, true), "rig builder must scale by rigHeight")
end)
