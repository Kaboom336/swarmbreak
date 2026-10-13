local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Config = require("./GreyboxConfig")
local Layout = require("./Layout")
local Rules = require("./LootRules")
for _, name in fs.readDir(".") do
	if string.sub(name, -5) == ".luau" then
		for level = 0, 2 do
			luau.compile(fs.readFile(name), { optimizationLevel = level, debugLevel = 2 })
		end
		print("COMPILE PASS " .. name .. " O0/O1/O2")
	end
end
Layout.selfTest(Config, print)
local invalid = Layout.assemble(Config, 101, true)
invalid.pieces[3].x = 0
assert(not pcall(Layout.validate, Config, invalid), "overlap accepted")
invalid = Layout.assemble(Config, 101, true)
invalid.ramps[1].b.y = 30
assert(not pcall(Layout.validate, Config, invalid), "steep ramp accepted")
-- Scalar server transition tests are distinct from Roblox physics evidence.
local function rulesTest()
	local r = Rules.new(Config)
	local a, b, c = {}, {}, {}
	local sa, sb, sc = Rules.actor(r, a), Rules.actor(r, b), Rules.actor(r, c)
	sa.phase, sb.phase, sc.phase = "Run", "Run", "Run"
	local position = { x = 0, y = 4, z = 32 }
	local item = Rules.spawn(r, position)
	local function legal()
		return true
	end
	local function floor()
		return position
	end
	assert(Rules.begin(r, a, "Steal", nil, 0, legal))
	assert(Rules.begin(r, b, "Steal", nil, 0, legal))
	assert(not Rules.finish(r, a, "Steal", 0.99, legal, floor), "short hold")
	assert(Rules.finish(r, a, "Steal", 1, legal, floor))
	assert(not Rules.finish(r, b, "Steal", 1, legal, floor), "simultaneous nest duplicate")
	assert(not Rules.begin(r, b, "Bump", a, 2, legal), "shield/mercy bypass")
	assert(Rules.hit(r, a, "Guardian", 4, floor()))
	assert(sa.item == item and sa.firstHitUsed, "first-hit retention")
	assert(not Rules.hit(r, a, "Guardian", 4.1, floor()), "airborne mercy bypass")
	assert(Rules.begin(r, b, "Bump", a, 13, legal))
	assert(Rules.finish(r, b, "Bump", 13.41, legal, floor))
	assert(item.state == "Dropped" and not sa.item and not sb.item, "direct carrier theft")
	assert(not Rules.begin(r, b, "Grab", nil, 13.7, legal), "settle precharge")
	assert(Rules.begin(r, b, "Grab", nil, 14.02, legal))
	assert(Rules.begin(r, c, "Grab", nil, 14.02, legal))
	assert(Rules.finish(r, b, "Grab", 14.43, legal, floor))
	assert(not Rules.finish(r, c, "Grab", 14.43, legal, floor), "simultaneous Grab duplicate")
	assert(item.id == "arena1:1" and item.firstPickup == 1, "identity/timestamp reroll")
	assert(sb.item == item and not sa.item and not sc.item, "handoff holder")
	Rules.audit(r)
	assert(not Rules.hit(r, b, "Pvp", 15, floor()), "cross-source mercy")
	assert(Rules.begin(r, c, "Bump", b, 18, legal))
	sc.hold = nil -- Cancelled attempt still cools down.
	assert(not Rules.begin(r, c, "Bump", b, 18.5, legal), "cancelled Bump cooldown")
	assert(Rules.secure(r, b, 19))
	assert(sb.completed == 1 and sa.completed == 0 and item.state == "Secured" and item.firstPup, "winner finalization")
	assert(Rules.place(r, b))
	assert(not Rules.place(r, b), "duplicate placement")
	Rules.audit(r)
	local nextItem = Rules.spawn(r, position)
	assert(nextItem.id ~= item.id, "respawn identity")
	sa.phase = "Run"
	assert(Rules.begin(r, a, "Steal", nil, 20, legal))
	assert(Rules.finish(r, a, "Steal", 21, legal, floor))
	assert(sa.shield == 13 and sa.shieldUsed, "shield reset farming")
	assert(Rules.hit(r, a, "Guardian", 25, floor()) and nextItem.state == "Dropped", "first-hit reset farming")
	assert(Rules.begin(r, b, "Grab", nil, 26, legal) == false, "home arena bypass")
	Rules.retire(r)
	Rules.audit(r)
	-- Intentionally corrupt state: audit must detect duplication/loss.
	sb.item = item
	assert(not pcall(Rules.audit, r), "audit missed duplicate holder")
	sb.item = nil
	nextItem.state = "Carried"
	nextItem.holder = c
	assert(not pcall(Rules.audit, r), "audit missed loss")
end
rulesTest()
print(
	"PASS contested nest/Grab; Bump/drop/settle; cooldown; shared mercy; reset protections; winner-only secure/place; conservation rejects loss/duplication"
)
-- Execute the production server eligibility adapter, with only roots/sight/floor mocked.
-- This checks real PvP rules and range code, not Humanoid movement or replication.
local function pvpLogicTest()
	local vector = require("@lune/roblox").Vector3
	local r, player, dummy, rival = Rules.new(Config), {}, {}, {}
	local s, ds, rs = Rules.actor(r, player), Rules.actor(r, dummy), Rules.actor(r, rival)
	local arena, otherArena = {}, {}
	for _, actorState in { s, ds, rs } do
		actorState.phase, actorState.run = "Run", arena
	end
	local roots = {
		[player] = { Position = vector.new(-62, 3, -56) },
		[dummy] = { Position = vector.new(0, 7, 32) },
		[rival] = { Position = vector.new(-62, 3, -56) },
	}
	local visible = true
	local source = fs.readFile("Greybox.server.luau")
	local beginAt = assert(string.find(source, "local function check(actor, action, target, item)", 1, true))
	local endAt = assert(string.find(source, "local function bumpTarget", beginAt, true))
	local check = luau.load(string.sub(source, beginAt, endAt - 1) .. "\nreturn check", {
		debugName = "production PvP eligibility",
		environment = {
			Vector3 = vector,
			arena = arena,
			states = r.actors,
			root = function(actor)
				return roots[actor]
			end,
			Arena = {
				safe = function(_, p)
					return Layout.protected(p.X, p.Z)
				end,
				sight = function()
					return visible
				end,
			},
		},
	})()
	local item = Rules.spawn(r, vector.new(0, 4, 32))
	local function floor()
		return vector.new(-64, 0, -56)
	end
	assert(Rules.begin(r, dummy, "Steal", nil, 0, check))
	assert(Rules.finish(r, dummy, "Steal", 1.05, check, floor))
	local timestamp = item.firstPickup
	Rules.audit(r)
	roots[dummy].Position = vector.new(-64, 3, -56)
	assert(not Rules.begin(r, player, "Bump", dummy, 2, check), "PvP shield bypass")
	assert(check(player, "Bump", dummy, item), "live court range refused")
	roots[player].Position = vector.new(-59, 3, -56)
	assert(not check(player, "Bump", dummy, item), "live 4-stud range bypass")
	roots[player].Position = vector.new(-64, 6.1, -56)
	assert(not check(player, "Bump", dummy, item), "live vertical range bypass")
	roots[player].Position = vector.new(-62, 3, -56)
	visible = false
	assert(not check(player, "Bump", dummy, item), "live sight bypass")
	visible = true
	ds.run = otherArena
	assert(not check(player, "Bump", dummy, item), "live arena bypass")
	ds.run = arena
	roots[dummy].Position = vector.new(0, 3, -56)
	assert(not check(player, "Bump", dummy, item), "live safe victim bypass")
	roots[dummy].Position = vector.new(-64, 3, -56)
	assert(Rules.hit(r, dummy, "Guardian", 13.1, floor()))
	assert(not Rules.begin(r, player, "Bump", dummy, 14, check), "PvP mercy bypass")
	assert(Rules.begin(r, player, "Bump", dummy, 16.2, check))
	roots[player].Position = vector.new(-59, 3, -56)
	assert(not Rules.finish(r, player, "Bump", 16.65, check, floor), "range not rechecked on finish")
	roots[player].Position = vector.new(-62, 3, -56)
	assert(Rules.begin(r, player, "Bump", dummy, 18.3, check))
	assert(Rules.finish(r, player, "Bump", 18.75, check, floor))
	assert(item.state == "Dropped" and not ds.item and not s.item, "PvP direct grant/loss")
	assert(not Rules.begin(r, player, "Grab", nil, 19.34, check), "PvP settle precharge")
	assert(Rules.begin(r, player, "Grab", nil, 19.38, check))
	assert(Rules.begin(r, rival, "Grab", nil, 19.38, check))
	assert(Rules.finish(r, player, "Grab", 19.83, check, floor))
	assert(not Rules.finish(r, rival, "Grab", 19.83, check, floor), "PvP contested duplicate")
	assert(not Rules.finish(r, player, "Grab", 19.83, check, floor), "PvP replay accepted")
	assert(s.item == item and item.holder == player and item.firstPickup == timestamp, "PvP identity/holder")
	Rules.audit(r)
	assert(Rules.secure(r, player, 20))
	assert(not Rules.secure(r, player, 20), "PvP duplicate secure")
	assert(Rules.place(r, player) and not Rules.place(r, player), "PvP placement replay")
	assert(s.completed == 1 and ds.completed == 0 and item.state == "Placed", "PvP winner award")
	Rules.audit(r)
end
pvpLogicTest()
print(
	"PASS offline PvP production range/sight/height/arena/safe adapter; shield/mercy; hold revalidation; Bump/drop/settle/contested Grab/secure/place; same ID/time"
)
-- Height sampling against the actual generated ramps/boxes, at 0.5-stud steps.
local function height(l, x, z)
	local value = 0
	for _, g in l.gullies do
		if math.abs(x - g.x) < g.w / 2 and math.abs(z - g.z) < g.d / 2 then
			value = -3
		end
	end
	for _, b in l.solids do
		if b.role == "Floor" and math.abs(x - b.x) <= b.w / 2 and math.abs(z - b.z) <= b.d / 2 then
			value = math.max(value, b.y + b.h / 2)
		end
	end
	for _, r in l.ramps do
		local dx, dz = r.b.x - r.a.x, r.b.z - r.a.z
		local length = math.sqrt(dx * dx + dz * dz)
		local along = ((x - r.a.x) * dx + (z - r.a.z) * dz) / (length * length)
		local across = math.abs((x - r.a.x) * dz - (z - r.a.z) * dx) / length
		if along >= 0 and along <= 1 and across <= r.width / 2 then
			value = math.max(value, r.a.y + (r.b.y - r.a.y) * along)
		end
	end
	return value
end
-- Match the live preflight's radius/slope envelope using the scalar collision recipe.
-- This cannot replace Studio raycasts or Humanoid physics.
local function standable(l, p, edge)
	local center = height(l, p.x, p.z)
	assert(math.abs(center - p.y) < 0.7, "waypoint Y mismatch")
	for ix = -6, 6 do
		for iz = -6, 6 do
			if ix * ix + iz * iz <= 36 then
				local x, z = p.x + ix * 0.5, p.z + iz * 0.5
				local rise = height(l, x, z) - center
				assert(rise <= 1.5 and (edge or rise >= -1.5), "waypoint cliff/wall " .. tostring(p.name))
				for _, b in l.solids do
					if b.role == "Cover" then
						assert(
							math.abs(x - b.x) > b.w / 2 or math.abs(z - b.z) > b.d / 2 or b.y + b.h / 2 <= center,
							"waypoint clearance cover " .. b.name
						)
					end
				end
			end
		end
	end
end
for seed = 1, 50 do
	local l = Layout.assemble(Config, seed, false)
	local routes = table.clone(l.routes)
	for i, route in l.crossLinks do
		routes["CrossLink" .. i] = route
	end
	local carry = { { x = 0, y = 4, z = 32, kind = "Walk" } }
	for _, p in Layout.loopCarrySteps(l) do
		standable(l, p)
		if p.kind == "Jump" then
			local edge = assert(p.takeoff, "missing live takeoff edge")
			local start = carry[#carry]
			standable(l, edge, true)
			assert(math.abs(height(l, edge.x, edge.z) - edge.y) < 0.1, "takeoff not on authored floor")
			local runup = math.sqrt((edge.x - start.x) ^ 2 + (edge.z - start.z) ^ 2)
			assert(runup >= 2.5 and runup <= 6, "jump run-up ordering")
			-- Check the grounded lead-in separately; only the airborne segment may skip cliffs.
			table.insert(carry, { x = edge.x, y = edge.y, z = edge.z, kind = "Walk" })
		end
		table.insert(carry, p)
	end
	routes.CarryingLoop = carry
	for name, route in Layout.pvpRoutes() do
		routes["PvP" .. name] = route
		for _, p in route do
			standable(l, p)
		end
	end
	for _, p in l.routes.Quick do
		standable(l, p)
	end
	for name, route in routes do
		for i = 2, #route do
			local a, b = route[i - 1], route[i]
			local count = math.ceil(math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2) * 2)
			local last = height(l, a.x, a.z)
			for n = 0, count do
				local t = n / count
				local x, z = a.x + (b.x - a.x) * t, a.z + (b.z - a.z) * t
				assert(
					math.abs(x) < Config.IslandSize / 2 - 1 and math.abs(z) < Config.IslandSize / 2 - 1,
					"route envelope " .. name
				)
				local y = height(l, x, z)
				assert(
					math.abs(y - last) <= 0.65 or b.kind == "Jump" or (b.kind == "Recovery" and y <= last),
					"walk route cliff/gully seed=" .. seed .. " " .. name .. " step=" .. i .. " x=" .. x .. " z=" .. z
				)
				assert(
					b.kind == "Jump" or b.kind == "Recovery" or math.abs(y - (a.y + (b.y - a.y) * t)) < 0.7,
					"route disagrees with actual floor " .. name .. " step=" .. i
				)
				for _, box in l.solids do
					if box.role == "Cover" then
						assert(
							math.abs(x - box.x) >= box.w / 2 + 1.5
								or math.abs(z - box.z) >= box.d / 2 + 1.5
								or y >= box.y + box.h / 2,
							"route hits cover " .. name .. " step=" .. i
						)
					end
				end
				last = y
			end
		end
	end
	for _, hide in l.hides do
		assert(not Layout.protected(hide.x, hide.z, 4), "safe hide")
	end
	for _, g in l.gullies do
		assert(g.w >= 24 and g.d >= 24, "recovery volume")
	end
end
local first = Layout.assemble(Config, 101, true)
for _, p in
	{
		{ x = -12, y = 0, z = -24 }, -- inside cover
		{ x = -18, y = 0, z = -24 }, -- less than 3 studs from cover
		{ x = -38, y = 0, z = -30 }, -- wrong gully/stone height
	}
do
	assert(not pcall(standable, first, p), "bad waypoint accepted")
end
local carry = { { x = 0, y = 4, z = 32 } }
for _, p in Layout.loopCarrySteps(first) do
	table.insert(carry, p)
end
print(string.format("MEASURE simplified nest-to-cyan route %.2f studs", Layout.length(carry)))
print("PASS 50-seed solo/PvP waypoint 3-stud clearance; bad waypoint negatives; PvP court/pacing/mercy/exit paths")
for name, route in first.routes do
	print(
		string.format(
			"MEASURE route %s %.2f studs (authored points; excludes pad approach)",
			name,
			Layout.length(route)
		)
	)
end
print(
	"PASS 50-seed actual 3D walking-floor, cliff, cover-clearance checks; same segments reversible. Live jump/navmesh UNKNOWN."
)
if fs.isFile("guardian-greybox.rbxl") then
	local roblox = require("@lune/roblox")
	local place = roblox.deserializePlace(fs.readFile("guardian-greybox.rbxl"))
	for _, map in
		{
			{ "ServerScriptService", "Greybox", "Greybox.server.luau" },
			{ "ServerScriptService", "GreyboxLoopTestRunner", "LoopTest.luau" },
			{ "ServerScriptService", "GreyboxArena", "Arena.luau" },
			{ "ReplicatedStorage", "GreyboxConfig", "GreyboxConfig.luau" },
			{ "ReplicatedStorage", "GreyboxLayout", "Layout.luau" },
			{ "ReplicatedStorage", "GreyboxLootRules", "LootRules.luau" },
		}
	do
		local node = place:FindFirstChild(map[1]):FindFirstChild(map[2])
		assert(node and node.Source == fs.readFile(map[3]), "built source mismatch " .. map[3])
	end
	assert(
		place.StarterPlayer.StarterPlayerScripts.Greybox.Source == fs.readFile("Greybox.client.luau"),
		"client source mismatch"
	)
	local sss = place.ServerScriptService
	for _, mode in { "GreyboxLoopTest", "GreyboxPvpTest" } do
		assert(
			sss:GetAttribute(mode) == false
				and sss:GetAttribute(mode .. "Success") == false
				and sss:GetAttribute(mode .. "Result") == "NOT RUN",
			"fabricated runtime result"
		)
	end
	print("PASS built binary sources; both runtime gates NOT RUN/locked")
end
