-- Real Humanoid movement/jumping and production actions; no obstacle teleports.
local Test = {}
local Layout = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxLayout"))
local SSS = game:GetService("ServerScriptService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxConfig"))
local function at(arena, x, y, z)
	return (arena and arena.origin or Vector3.zero) + Vector3.new(x, y + 3, arena and -z or z)
end
-- Resolve against real collidable geometry; never target guessed root heights.
local function validator(world, log)
	local function resolve(position, edge)
		local parts = {}
		for _, p in world:GetDescendants() do
			if p:IsA("BasePart") and p.Anchored and p.CanCollide then
				table.insert(parts, p)
			end
		end
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, parts
		params.RespectCanCollide = true
		local function down(x, z)
			return workspace:Raycast(Vector3.new(x, position.Y + 42, z), Vector3.new(0, -70, 0), params)
		end
		local function walkable(hit)
			return hit
				and hit.Normal.Y >= math.cos(math.rad(25.1))
				and (
					hit.Instance:GetAttribute("SurfaceRole") == "Floor"
					or hit.Instance:GetAttribute("SurfaceRole") == nil
				)
		end
		local center = down(position.X, position.Z)
		assert(walkable(center), "no walkable center floor")
		assert(
			math.abs(center.Position.Y - (position.Y - 3)) < 0.7,
			"authored Y disagrees with " .. center.Instance.Name
		)
		-- Half-stud samples across a 3-stud radius, with six studs of head/body space.
		-- A launch lip requires center support; lower floor beside it is intentional.
		for ix = -6, 6 do
			for iz = -6, 6 do
				if ix * ix + iz * iz <= 36 then
					local x, z = position.X + ix * 0.5, position.Z + iz * 0.5
					local hit = down(x, z)
					assert(walkable(hit), "clearance floor/cover at " .. x .. "," .. z)
					local rise = hit.Position.Y - center.Position.Y
					assert(rise <= 1.5 and (edge or rise >= -1.5), "clearance cliff/wall " .. hit.Instance.Name)
					local overhead =
						workspace:Raycast(Vector3.new(x, center.Position.Y + 1.55, z), Vector3.new(0, 6, 0), params)
					assert(not overhead, "head clearance " .. (overhead and overhead.Instance.Name or ""))
				end
			end
		end
		return Vector3.new(position.X, center.Position.Y + 3, position.Z)
	end
	local function checked(position, name, edge)
		local ok, result = pcall(resolve, position, edge)
		if not ok then
			log("BAD WAYPOINT " .. name .. " at " .. tostring(position) .. ": " .. tostring(result))
		end
		assert(ok, "bad waypoint " .. name .. ": " .. tostring(result))
		return result
	end
	local function preflight(points)
		local bad = 0
		for _, p in points do
			local ok, reason = pcall(resolve, p.position, p.edge)
			if not ok then
				bad += 1
				log("BAD WAYPOINT " .. p.name .. " at " .. tostring(p.position) .. ": " .. tostring(reason))
			end
		end
		assert(bad == 0, "waypoint preflight: " .. bad .. " bad points")
		log("waypoint preflight PASS " .. #points .. " points / 3-stud clearance")
	end
	return checked, preflight
end
local function homeEntryPoints(pen)
	local side = pen.marker.Position.X < 0 and -1 or 1
	return {
		{ position = at(nil, side * Config.HomeAisleX, 0, pen.marker.Position.Z), name = "pen aisle" },
		{ position = at(nil, side * Config.HomeAisleX, 0, Config.HomeSpawnZ), name = "home aisle" },
		{ position = at(nil, 0, 0, Config.HomeSpawnZ), name = "central lane" },
		{ position = at(nil, 0, 0, 24), name = "home ramp approach" },
		{ position = at(nil, 0, 3, -6), name = "home ramp landing" },
		{ position = at(nil, 0, 3, Config.HomePortalApproachZ), name = "home portal" },
	}
end
local function homePoints(pen)
	local side = pen.marker.Position.X < 0 and -1 or 1
	local points = homeEntryPoints(pen)
	for _, p in
		{
			{ position = at(nil, side * Config.HomeAisleX, 0, Config.HomeSpawnZ), name = "home aisle" },
			{
				position = at(nil, side * Config.HomeAisleX, 0, pen.marker.Position.Z),
				name = "own pen aisle",
			},
			{
				position = Vector3.new(pen.marker.Position.X - side * 5, 3, pen.marker.Position.Z),
				name = "own pen",
			},
		}
	do
		table.insert(points, p)
	end
	return points
end
local function driver(actor, states, api, log, checked)
	local character = actor.Character
	local r, h = api.root(actor)
	assert(r and h, "character missing")
	r:SetNetworkOwner(nil)
	local function walk(position, name, jump, autoReturn, takeoff)
		position = checked(position, name)
		if takeoff then
			takeoff = checked(takeoff, "takeoff " .. name, true)
		end
		log((jump and "Jump " or "Walk ") .. name)
		local started, progressed, best, nextLog = os.clock(), os.clock(), math.huge, 0
		local airborne, landed, launched = false, false, false
		local expected = states[actor].run
		local cargo = states[actor].item
		if jump then
			h:Move(Vector3.zero, false)
			while os.clock() < (states[actor].slowUntil or 0) or h.FloorMaterial == Enum.Material.Air do
				assert(os.clock() - started < 3, "jump readiness >3s: " .. name)
				task.wait(0.03)
			end
		end
		-- Continuous movement to a grounded launch marker; no MoveTo re-targeting.
		local launchDirection = takeoff and Vector3.new(position.X - takeoff.X, 0, position.Z - takeoff.Z).Unit
		while true do
			assert(actor.Character == character and h.Health > 0, "character lost")
			api.audit()
			if cargo and cargo.state ~= "Secured" then
				assert(os.clock() < cargo.escapeDeadline, "escape deadline exceeded at " .. name)
			end
			if autoReturn and cargo and not states[actor].item and states[actor].phase == "Run" then
				h:Move(Vector3.zero, false)
				log("return interrupted by legal drop / recover before crossing cyan")
				return false
			end
			if autoReturn and states[actor].phase == "Home" then
				assert(
					cargo
						and states[actor].item == cargo
						and cargo.state == "Secured"
						and cargo.holder == actor
						and cargo.securedAt < cargo.escapeDeadline,
					"automatic return lost cargo or missed deadline"
				)
				log("legal automatic secure / " .. cargo.id .. " / " .. name)
				break
			end
			assert(states[actor].run == expected, "unexpected arena reset/return")
			local now = os.clock()
			if h.FloorMaterial == Enum.Material.Air then
				airborne = true
			elseif airborne then
				landed = true
			end
			local delta = position - r.Position
			local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
			local distance = horizontal + math.abs(delta.Y) * 0.2
			if
				not autoReturn -- Return legs finish only after the production boundary handler secures cargo.
				and horizontal <= (jump and 0.8 or 2.25)
				and math.abs(delta.Y) < 2
				and h.FloorMaterial ~= Enum.Material.Air
				and (not jump or (launched and landed))
			then
				break
			end
			if distance < best - 0.2 then
				best, progressed = distance, now
			end
			assert(now - progressed <= 8, "stuck >8s at " .. name)
			assert(now - started <= 30, "waypoint >30s at " .. name)
			if now >= nextLog then
				log(
					string.format(
						"progress %s goal=%s distance=%.2f noProgress=%.2fs",
						name,
						tostring(position),
						distance,
						now - progressed
					)
				)
				nextLog = now + 1
			end
			local direction = Vector3.new(delta.X, 0, delta.Z)
			if jump and not launched then
				local toEdge = takeoff and takeoff - r.Position or Vector3.zero
				local remaining = launchDirection and toEdge:Dot(launchDirection) or 0
				if remaining <= 0.4 then
					assert(h.FloorMaterial ~= Enum.Material.Air, "jump takeoff not grounded: " .. name)
					assert(now >= (states[actor].slowUntil or 0), "jump takeoff during stumble: " .. name)
					h:Move(direction.Unit, false)
					h.Jump = true
					h:ChangeState(Enum.HumanoidStateType.Jumping)
					airborne, landed = false, false
					launched = true
					log("takeoff " .. name)
				end
			end
			-- Slow near an endpoint to avoid oscillating over a sub-stud goal.
			h:Move(direction.Magnitude > 0.05 and direction.Unit * math.min(1, horizontal / 1.5) or Vector3.zero, false)
			task.wait(0.03)
		end
		h:Move(Vector3.zero, false)
		log("arrived " .. name)
		if jump then
			assert(airborne and landed, "no takeoff/landing")
			SSS:SetAttribute("GreyboxLoopTestJumpObserved", true)
		end
		return true
	end
	return walk, r, h
end
local function act(api, actor, name, ...)
	local ok, why = api[name](actor, ...)
	assert(ok, "illegal refusal " .. name .. ": " .. tostring(why))
end
local function hold(api, actor, action)
	for attempt = 1, Config.TestHoldRetries do
		act(api, actor, "holdAction", action, "begin")
		task.wait(Config.HoldSeconds[action] + 0.05)
		local ok, why = api.holdAction(actor, action, "finish")
		api.audit()
		if ok then
			return
		end
		assert(action ~= "Bump" and why == "missing/short hold", "illegal hold refusal: " .. tostring(why))
		assert(attempt < Config.TestHoldRetries, "hold repeatedly interrupted by guardian")
	end
end
local function recoveryPoint(checked, item)
	-- Production drops already require this clearance. Retain nearby recovery
	-- candidates so the test independently checks the actual settled position.
	for _, offset in
		{
			Vector3.zero,
			Vector3.new(2, 0, 0),
			Vector3.new(-2, 0, 0),
			Vector3.new(0, 0, 2),
			Vector3.new(0, 0, -2),
		}
	do
		local ok, position = pcall(checked, item.position + Vector3.new(0, 3, 0) + offset, "recover " .. item.id)
		if ok then
			return position
		end
	end
	error("no standable Grab point for " .. item.id)
end
local function closeToDummy(api, walk, player, dummy)
	local closeDeadline = os.clock() + 8
	while true do
		local pr, dr = api.root(player), api.root(dummy)
		if (pr.Position - dr.Position).Magnitude <= 3 then
			return pr, dr
		end
		assert(os.clock() < closeDeadline, "cannot close to live dummy within 3 studs >8s")
		local floor = assert(api.floor(dr.Position), "dummy court floor missing")
		walk(floor + Vector3.new(0, 3, 0), "close to live dummy within 3 studs")
	end
end
local function recover(api, actor, states, walk, item, log, checked)
	if states[actor].item == item then
		return
	end
	assert(
		states[actor].phase == "Run" and api.rules.active == item and item.state == "Dropped",
		"loot lost/taken before recovery"
	)
	local timestamp, escapeDeadline = item.firstPickup, item.escapeDeadline
	log("legal drop / recover " .. item.id)
	for attempt = 1, Config.TestRecoverRetries do
		walk(recoveryPoint(checked, item), "recover same dropped loot")
		task.wait(math.max(0, item.settle - os.clock()) + 0.03)
		local ok, why = api.holdAction(actor, "Grab", "begin")
		if ok then
			task.wait(Config.HoldSeconds.Grab + 0.05)
			ok, why = api.holdAction(actor, "Grab", "finish")
		end
		api.audit()
		if ok then
			break
		end
		assert(api.rules.active == item and item.state == "Dropped", "recovery loot lost/taken")
		log("recovery interrupted / retry " .. attempt .. " / " .. tostring(why))
		assert(attempt < Config.TestRecoverRetries, "recovery retry limit")
	end
	assert(
		states[actor].item == item and item.firstPickup == timestamp and item.escapeDeadline == escapeDeadline,
		"recovery identity/timestamp changed"
	)
	api.audit()
end
-- Live production expiry: no shortened clock, immunity, teleport or synthetic award.
local function expiryTest(player, states, pens, world, api, log, walk)
	local s = states[player]
	local count, completed = pens[s.slot].count, s.completed
	-- Retrace the open pen aisle before using the central ramp. A direct
	-- diagonal to the raised portal hits the platform's three-stud side.
	local pen = pens[s.slot]
	for _, p in homeEntryPoints(pen) do
		walk(p.position, "expiry " .. p.name)
	end
	act(api, player, "enterRun")
	local arena = api.arena()
	local waitUntil = os.clock() + 8
	while not api.rules.active or api.rules.active.state ~= "Nest" do
		assert(os.clock() < waitUntil, "expiry nest unavailable")
		task.wait(0.05)
	end
	for _, p in arena.layout.routes.Quick do
		walk(at(arena, p.x, p.y, p.z), "expiry approach")
	end
	hold(api, player, "Steal")
	local item = assert(s.item, "expiry missing cargo")
	local deadline = item.escapeDeadline
	assert(math.abs(deadline - item.firstPickup - Config.EscapeSeconds) < 0.001, "deadline start")
	while os.clock() < deadline + 0.15 do
		api.audit()
		task.wait(0.05)
	end
	assert(item.state == "Retired" and not item.holder and not item.visual and not item.weld, "expiry orphan cargo")
	assert(not s.item and not api.rules.active, "expiry duplicate active/holder")
	for _, actorState in states do
		assert(not actorState.hold or actorState.hold.item ~= item, "expiry orphan hold")
	end
	assert(s.completed == completed and pens[s.slot].count == count, "expiry awarded")
	assert(not api.placeItem(player, s.slot), "expired placement accepted")
	assert(not api.holdAction(player, "Grab", "begin"), "expired Grab accepted")
	assert(world:GetAttribute("EscapeDeadline") == nil, "stale shared clock")
	waitUntil = os.clock() + 4
	while not api.rules.active do
		assert(os.clock() < waitUntil, "expiry refill missing")
		task.wait(0.05)
	end
	local replacement = api.rules.active
	assert(
		replacement.id ~= item.id and replacement.state == "Nest" and not replacement.escapeDeadline,
		"expiry reused ID/clock"
	)
	assert(api.rules.respawnAt >= deadline + Config.RespawnSeconds, "early refill")
	api.audit()
	local originals, replacements = 0, 0
	for _, p in workspace:GetDescendants() do
		if p:IsA("BasePart") then
			if p:GetAttribute("LootId") == item.id then
				originals += 1
			end
			if p:GetAttribute("LootId") == replacement.id then
				replacements += 1
			end
		end
	end
	assert(originals == 0 and replacements == 1, "expiry physical duplicate")
	for i = #arena.layout.routes.Quick, 1, -1 do
		local p = arena.layout.routes.Quick[i]
		walk(at(arena, p.x, p.y, p.z), "empty return after expiry")
	end
	act(api, player, "returnRun")
	log("expiry PASS / retired " .. item.id .. " / fresh " .. replacement.id .. " / no award or duplicate")
end
local function place(player, states, pens, api, walk, log, item, initialCount)
	local s = states[player]
	assert(s.phase == "Home" and s.item == item and item.state == "Secured", "return lost loot")
	assert(not api.returnRun(player), "duplicate return accepted")
	local pen = pens[s.slot]
	local side = pen.marker.Position.X < 0 and -1 or 1
	walk(at(nil, side * Config.HomeAisleX, 0, Config.HomeSpawnZ), "home aisle")
	walk(at(nil, side * Config.HomeAisleX, 0, pen.marker.Position.Z), "own pen aisle")
	walk(Vector3.new(pen.marker.Position.X - side * 5, 3, pen.marker.Position.Z), "own pen")
	act(api, player, "placeItem", s.slot)
	assert(not api.placeItem(player, s.slot), "duplicate place accepted")
	assert(not s.item and item.state == "Placed" and pen.count == initialCount + 1, "placement loss/duplication")
	local count = 0
	for _, p in workspace:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("LootId") == item.id then
			count += 1
		end
	end
	assert(count == 1, "physical loot duplication/loss: " .. count)
	api.audit()
	log("conserved " .. item.id .. " / exactly one placed block")
end
function Test.run(player, states, pens, world, api, log)
	local s = states[player]
	assert(s.counter == 0 and not s.item and pens[s.slot].count == 0, "fresh solo Play state required")
	local checked, preflight = validator(world, log)
	preflight(homePoints(pens[s.slot]))
	local walk, r, h = driver(player, states, api, log, checked)
	walk(at(nil, 0, 3, Config.HomePortalApproachZ), "home portal")
	act(api, player, "enterRun")
	local arena = api.arena()
	local started = s.started
	local carrySteps = Layout.loopCarrySteps(arena.layout)
	local dodgePoints = Layout.dodgePoints()
	local north = at(arena, dodgePoints[1].x, dodgePoints[1].y, dodgePoints[1].z)
	local south = at(arena, dodgePoints[2].x, dodgePoints[2].y, dodgePoints[2].z)
	local points = {}
	for i, p in dodgePoints do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "disc dodge option " .. i })
	end
	for _, p in arena.layout.routes.Quick do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "approach " .. p.kind })
	end
	for _, p in carrySteps do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = p.name })
		if p.takeoff then
			local t = p.takeoff
			table.insert(points, { position = at(arena, t.x, t.y, t.z), name = "takeoff " .. p.name, edge = true })
		end
	end
	preflight(points) -- enterRun creates the island; validate before island walking/Steal.
	for _, p in arena.layout.routes.Quick do
		walk(at(arena, p.x, p.y, p.z), p.kind .. " approach")
	end
	hold(api, player, "Steal")
	local item = s.item
	assert(item and item.state == "Carried", "missing nest loot")
	assert(not api.holdAction(player, "Steal", "finish"), "duplicate nest accepted")
	SSS:SetAttribute("GreyboxLoopTestFreshToSteal", os.clock() - s.joined)
	local function dodge()
		h:Move(Vector3.zero, false)
		local began = os.clock()
		local telegraph
		repeat
			local t = arena.attack
			if t and t.disc and t.actor == player and t.start >= began then
				telegraph = t
				break
			end
			local flat =
				Vector3.new(r.Position.X - arena.guardian.Position.X, 0, r.Position.Z - arena.guardian.Position.Z)
			if flat.Magnitude < Config.GuardianThrowMinRange then
				local destination = (north - arena.guardian.Position).Magnitude
							> (south - arena.guardian.Position).Magnitude
						and north
					or south
				walk(destination, "make room for readable throw")
			end
			assert(os.clock() - began <= 8, "no normal throw/telegraph >8s")
			api.audit()
			task.wait(0.03)
		until false
		assert(
			telegraph.disc.Parent
				and telegraph.disc:GetAttribute("ImpactDue") - telegraph.disc:GetAttribute("TelegraphStarted")
					>= Config.ThrowSeconds - 0.01,
			"telegraph missing/pre-impact delay"
		)
		local locked = telegraph.position
		local destination = (north - locked).Magnitude > (south - locked).Magnitude and north or south
		walk(destination, "Dodge locked red disc")
		assert(
			(Vector3.new(r.Position.X, locked.Y, r.Position.Z) - locked).Magnitude > Config.ThrowRadius,
			"failed disc dodge"
		)
		local deadline = os.clock() + 8
		while arena.attack == telegraph do
			assert(os.clock() < deadline, "throw stuck >8s")
			task.wait(0.03)
		end
		assert(arena.throws > 0 and arena.chaseTicks > 0 and arena.chaseDistance > 0.1, "guardian never threw/chased")
		SSS:SetAttribute("GreyboxLoopTestTelegraphObserved", true)
	end
	for _, step in carrySteps do
		recover(api, player, states, walk, item, log, checked)
		local reached = walk(
			at(arena, step.x, step.y, step.z),
			step.kind .. " " .. step.name,
			step.kind == "Jump",
			step.kind == "Return",
			step.takeoff and at(arena, step.takeoff.x, step.takeoff.y, step.takeoff.z)
		)
		if not reached then
			for attempt = 1, Config.TestRecoverRetries do
				recover(api, player, states, walk, item, log, checked)
				if walk(at(arena, step.x, step.y, step.z), step.name .. " retry", false, true) then
					break
				end
				assert(attempt < Config.TestRecoverRetries, "return retry limit")
			end
		end
		if step.kind == "Dodge" then
			dodge()
		end
		if s.phase == "Run" then
			recover(api, player, states, walk, item, log, checked)
		end
		if step.kind == "ClimbRamp" then
			assert(s.item == item, "lost carrying loot on hill/recovery ramp")
			SSS:SetAttribute("GreyboxLoopTestClimbObserved", true)
		end
		if step.kind == "Jump" then
			assert(s.item == item, "jump lost loot")
		end
	end
	SSS:SetAttribute("GreyboxLoopTestPortalToPortal", os.clock() - started)
	SSS:SetAttribute("GreyboxLoopTestCatches", s.catches or 0)
	assert(item.securedAt < item.escapeDeadline, "solo did not escape inside deadline")
	place(player, states, pens, api, walk, log, item, 0)
	expiryTest(player, states, pens, world, api, log, walk)
	return "steal, one stone set, one carrying hill, one red-disc dodge, secure/place; conserved " .. item.id
end
function Test.pvp(player, states, pens, world, api, log, setDummy)
	local s = states[player]
	assert(s.phase == "Home" and not s.item, "PvP requires Home/empty hands")
	local initialCount = pens[s.slot].count
	local checked, preflight = validator(world, log)
	preflight(homePoints(pens[s.slot]))
	local walk = driver(player, states, api, log, checked)
	walk(at(nil, 0, 3, Config.HomePortalApproachZ), "home portal")
	act(api, player, "enterRun")
	local arena = api.arena()
	local routes, points = Layout.pvpRoutes(), {}
	for name, route in routes do
		for _, p in route do
			table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "PvP " .. name })
		end
	end
	preflight(points)
	local deadline = os.clock() + 8
	while not api.rules.active or api.rules.active.state ~= "Nest" do
		assert(os.clock() < deadline, "nest unavailable >8s")
		task.wait(0.05)
	end
	-- Finish the tester approach before pickup: the dummy must not AFK-drop during it.
	for i = 2, #routes.Tester do
		local p = routes.Tester[i]
		walk(at(arena, p.x, p.y, p.z), "PvP court approach " .. i)
	end
	local dummy = api.dummy(at(arena, 0, 4, 32))
	setDummy(dummy)
	hold(api, dummy, "Steal")
	local ds = states[dummy]
	local item = ds.item
	local timestamp, escapeDeadline = item.firstPickup, item.escapeDeadline
	-- Consume the real one-time shield by waiting, never altering protection state.
	local dummyWalk = driver(dummy, states, api, log, checked)
	for i = 2, #routes.Dummy do
		recover(api, dummy, states, dummyWalk, item, log, checked)
		local p = routes.Dummy[i]
		dummyWalk(at(arena, p.x, p.y, p.z), "dummy court approach " .. i)
	end
	recover(api, dummy, states, dummyWalk, item, log, checked)
	api.pvpCourt(true)
	log("guardian isolated at camp for PvP court; real shield/mercy/holds unchanged")
	-- Keep the dummy moving to avoid the production AFK drop while shield expires.
	while os.clock() < ds.shield + 0.05 do
		dummyWalk(at(arena, -64, 0, -54), "dummy shield pacing")
		dummyWalk(at(arena, -64, 0, -56), "dummy shield pacing")
		recover(api, dummy, states, dummyWalk, item, log, checked)
	end
	local handoff = false
	for attempt = 1, Config.TestRecoverRetries do
		recover(api, dummy, states, dummyWalk, item, log, checked)
		dummyWalk(at(arena, -64, 0, -56), "dummy handoff court")
		local vulnerableDeadline = os.clock() + 8
		while os.clock() < ds.mercy or os.clock() < s.cooldown or not ds.item do
			assert(os.clock() < vulnerableDeadline, "no legal handoff window >8s")
			dummyWalk(at(arena, -72, 0, -48), "dummy dodges during impact mercy")
			dummyWalk(at(arena, -64, 0, -56), "dummy returns to handoff court")
			recover(api, dummy, states, dummyWalk, item, log, checked)
		end
		-- Fixed court goals plus normal walk tolerance do not establish Bump range.
		-- Follow the live root using Humanoid movement, then re-read both roots.
		closeToDummy(api, walk, player, dummy)
		local pr, dr = api.root(player), api.root(dummy)
		assert(ds.item == item and item.holder == dummy and item.state == "Carried", "dummy not carrying at Bump")
		assert((pr.Position - dr.Position).Magnitude <= 3, "Bump setup outside live 3-stud approach range")
		log("Bump begin / actual distance " .. (pr.Position - dr.Position).Magnitude)
		act(api, player, "holdAction", "Bump", "begin")
		task.wait(Config.HoldSeconds.Bump + 0.05)
		local ok, why = api.holdAction(player, "Bump", "finish")
		api.audit()
		if ok then
			handoff = true
			break
		end
		assert(
			why == "missing/short hold" or why == "Taken" or why == "carrier/Taken",
			"illegal Bump refusal: " .. tostring(why)
		)
		log("guardian interrupted PvP handoff / retry " .. attempt)
		assert(attempt < Config.TestRecoverRetries, "PvP Bump retry limit")
	end
	assert(handoff, "no completed production Bump")
	assert(item.state == "Dropped" and not ds.item and not s.item, "Bump directly granted/lost/duplicated")
	assert(item.firstPickup == timestamp and item.escapeDeadline == escapeDeadline, "handoff rerolled timestamp")
	assert(not api.holdAction(player, "Grab", "begin"), "settle allowed precharge")
	dummyWalk(at(arena, -68, 0, -52), "former carrier leaves contest")
	-- A fresh production Grab wins; legal interruptions may retry the same item.
	recover(api, player, states, walk, item, log, checked)
	assert(not api.holdAction(player, "Grab", "finish"), "duplicate Grab accepted")
	assert(s.item == item and item.holder == player and item.state == "Carried", "handoff conservation")
	api.audit()
	SSS:SetAttribute("GreyboxPvpTestItemId", item.id)
	SSS:SetAttribute("GreyboxPvpTestHandoffs", 1)
	for i = 2, #routes.Winner do
		local p = routes.Winner[i]
		for attempt = 1, Config.TestRecoverRetries do
			recover(api, player, states, walk, item, log, checked)
			if walk(at(arena, p.x, p.y, p.z), "winner " .. p.kind .. " " .. i, false, p.kind == "Return") then
				break
			end
			assert(attempt < Config.TestRecoverRetries, "PvP return retry limit")
		end
	end
	assert(
		item.securedAt < item.escapeDeadline and item.escapeDeadline == escapeDeadline,
		"PvP deadline refreshed/late"
	)
	place(player, states, pens, api, walk, log, item, initialCount)
	api.pvpCourt(false)
	expiryTest(player, states, pens, world, api, log, walk)
	return "legal Bump/drop/settle/Grab/secure/place with dummy carrier; no duplicate/lost " .. item.id
end
return Test
