-- Real Humanoid movement/jumping and production actions; no obstacle teleports.
local Test = {}
local Layout = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxLayout"))
local SSS = game:GetService("ServerScriptService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxConfig"))
local Placement = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxPlacement"))
local function at(arena, x, y, z)
	return (arena and arena.origin or Vector3.zero) + Vector3.new(x, y + 3, arena and -z or z)
end
-- Resolve against real collidable geometry; never target guessed root heights.
local function validator(world, log)
	local function resolve(position, edge, radius)
		radius = radius or 3
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
			return workspace:Raycast(
				Vector3.new(x, position.Y + (Config.MeadowV4 and 9 or 42), z),
				Vector3.new(0, -70, 0),
				params
			)
		end
		local function walkable(hit)
			return hit
				and hit.Normal.Y >= math.cos(math.rad(35.1))
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
				if ix * ix + iz * iz <= (radius * 2) ^ 2 then
					local x, z = position.X + ix * 0.5, position.Z + iz * 0.5
					local hit = down(x, z)
					assert(walkable(hit), "clearance floor/cover at " .. x .. "," .. z)
					local rise = hit.Position.Y - center.Position.Y
					local tolerance = (center.Normal.Y < 0.999 or hit.Normal.Y < 0.999) and 2.15 or 1.5
					assert(
						rise <= tolerance and (edge or rise >= -tolerance),
						"clearance cliff/wall " .. hit.Instance.Name
					)
					local overhead =
						workspace:Raycast(Vector3.new(x, center.Position.Y + 2.2, z), Vector3.new(0, 6, 0), params)
					assert(not overhead, "head clearance " .. (overhead and overhead.Instance.Name or ""))
				end
			end
		end
		return Vector3.new(position.X, center.Position.Y + 3, position.Z)
	end
	local function checked(position, name, edge, radius)
		local ok, result = pcall(resolve, position, edge, radius)
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
		{ position = at(nil, side * Config.HomeAisleX, 0, 42), name = "home aisle" },
		{ position = at(nil, 0, 0, 42), name = "central lane" },
		{ position = at(nil, 0, 0, 42), name = "home ramp approach" },
		{ position = at(nil, 0, 3, 18), name = "home ramp landing" },
		{ position = at(nil, 0, 3, Config.HomePortalApproachZ), name = "home portal" },
	}
end
local function homePoints(pen)
	local side = pen.marker.Position.X < 0 and -1 or 1
	local points = homeEntryPoints(pen)
	for _, p in
		{
			{ position = at(nil, side * Config.HomeAisleX, 0, 42), name = "home aisle" },
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
local function driver(actor, states, api, log, checked, monitor)
	local character = actor.Character
	local r, h = api.root(actor)
	assert(r and h, "character missing")
	r:SetNetworkOwner(nil)
	local function walk(position, name, jump, autoReturn, takeoff, runup, edgeGoal, radius, arrivalLine, navigation)
		if not navigation then
			position = checked(position, name, edgeGoal, radius)
		end
		if takeoff then
			takeoff = checked(takeoff, "takeoff " .. name, true)
		end
		if runup then
			local reached, reason = walk(runup, "straight run-up " .. name, false, false, nil, nil, true, nil, true)
			if not reached then
				return false, reason
			end
		end
		log((jump and "Jump " or "Walk ") .. name)
		local started, progressed, best, nextLog = os.clock(), os.clock(), 0, 0
		local airborne, landed, launched = false, false, false
		local expected = states[actor].run
		local cargo = states[actor].item
		local function interruption()
			local item = monitor and monitor.item or cargo
			if item and item.state ~= "Secured" and item.state ~= "Placed" then
				if item.state == "Retired" or os.clock() >= item.escapeDeadline then
					h:Move(Vector3.zero, false)
					return "expiry"
				end
				if cargo and states[actor].phase == "Run" and states[actor].item ~= cargo then
					h:Move(Vector3.zero, false)
					return "drop"
				end
			end
			if monitor and monitor.item and os.clock() < (states[actor].slowUntil or 0) then
				h:Move(Vector3.zero, false)
				return "stumble"
			end
		end
		if jump then
			while os.clock() < (states[actor].slowUntil or 0) or h.FloorMaterial == Enum.Material.Air do
				h:Move(Vector3.zero, false)
				local reason = interruption()
				if reason then
					return false, reason
				end
				if navigation and (navigation.blocked or os.clock() - started >= 3) then
					return false, "recompute"
				end
				assert(os.clock() - started < 3, "jump readiness >3s: " .. name)
				task.wait(0.03)
			end
		end
		-- One command per segment. Run-ups cross a line rather than braking at a point.
		local origin = r.Position
		local segment = Vector3.new(position.X - origin.X, 0, position.Z - origin.Z)
		local length = segment.Magnitude
		local routeDirection = length > 0.001 and segment.Unit or Vector3.zero
		local movementGoal = arrivalLine and position + routeDirection * 3 or position
		local commanded = false
		local launchDirection = takeoff and Vector3.new(position.X - takeoff.X, 0, position.Z - takeoff.Z).Unit
		while true do
			assert(actor.Character == character and h.Health > 0, "character lost")
			api.audit()
			local reason = interruption()
			if reason then
				return false, reason
			end
			if os.clock() < (states[actor].slowUntil or 0) then
				started, progressed = os.clock(), os.clock()
				task.wait(0.03)
				continue
			end
			if autoReturn and cargo and not states[actor].item and states[actor].phase == "Run" then
				h:Move(Vector3.zero, false)
				log("return interrupted by legal drop / recover before crossing cyan")
				return false
			end
			if (autoReturn or (monitor and monitor.item)) and expected ~= nil and states[actor].phase == "Home" then
				local secured = monitor and monitor.item or cargo
				assert(
					secured
						and states[actor].item == secured
						and secured.state == "Secured"
						and secured.holder == actor
						and secured.securedAt < secured.escapeDeadline,
					"automatic return lost cargo or missed deadline"
				)
				log("legal automatic secure / " .. secured.id .. " / " .. name)
				break
			end
			assert(states[actor].run == expected, "unexpected arena reset/return")
			local now = os.clock()
			if navigation and (navigation.blocked or now - progressed >= 3) then
				h:Move(Vector3.zero, false)
				return false, "recompute"
			end
			if jump and takeoff and r.Position.Y < math.min(takeoff.Y, position.Y) - 2 then
				h:Move(Vector3.zero, false)
				log("missed jump / climb-out and walking bypass " .. name)
				return false, "missed jump"
			end
			if h.FloorMaterial == Enum.Material.Air then
				airborne = true
			elseif airborne then
				landed = true
			end
			local delta = position - r.Position
			local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
			local along = Vector3.new(r.Position.X - origin.X, 0, r.Position.Z - origin.Z):Dot(routeDirection)
			local passed = along >= length
			local arrived = passed or (not arrivalLine and horizontal <= 3)
			if
				not autoReturn -- Return legs finish only after the production boundary handler secures cargo.
				and arrived
				and math.abs(delta.Y) < 2
				and h.FloorMaterial ~= Enum.Material.Air
				and (not jump or (launched and landed))
			then
				break
			end
			if along > best + 0.2 then
				best, progressed = along, now
			end
			if not navigation and (monitor or api.arena) and now - progressed >= 3 then
				return false, "displaced"
			end
			assert(now - progressed <= 8, "stuck >8s at " .. name)
			assert(now - started <= 30, "waypoint >30s at " .. name)
			if now >= nextLog then
				log(
					string.format(
						"progress %s goal=%s horizontal=%.2f route=%.2f/%.2f noProgress=%.2fs",
						name,
						tostring(position),
						horizontal,
						along,
						length,
						now - progressed
					)
				)
				nextLog = now + 1
			end
			if not commanded then
				h:MoveTo(movementGoal)
				commanded = true
			end
			if jump and not launched then
				local toEdge = takeoff and takeoff - r.Position or Vector3.zero
				local remaining = launchDirection and toEdge:Dot(launchDirection) or 0
				if remaining <= 0 then
					assert(h.FloorMaterial ~= Enum.Material.Air, "jump takeoff not grounded: " .. name)
					assert(now >= (states[actor].slowUntil or 0), "jump takeoff during stumble: " .. name)
					h.Jump = true
					h:ChangeState(Enum.HumanoidStateType.Jumping)
					airborne, landed = false, false
					launched = true
					log("takeoff " .. name)
				end
			end
			task.wait(0.03)
		end
		-- Return synchronously so the next walk replaces MoveTo without losing momentum.
		log("arrived " .. name)
		if jump then
			assert(airborne and landed, "no takeoff/landing")
			SSS:SetAttribute("GreyboxLoopTestJumpObserved", true)
		end
		return true
	end
	local function navigate(position, name, autoReturn)
		local started = os.clock()
		while true do
			local item = monitor and monitor.item or states[actor].item
			if
				item
				and item.state ~= "Secured"
				and item.state ~= "Placed"
				and (item.state == "Retired" or os.clock() >= item.escapeDeadline)
			then
				return false, "expiry"
			end
			assert(os.clock() - started < 30, "path recovery >30s: " .. name)
			local path = game:GetService("PathfindingService"):CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
				WaypointSpacing = 4,
				Costs = { JumpGully = 20 },
			})
			local computed, problem = pcall(function()
				path:ComputeAsync(r.Position, position)
			end)
			if not computed or path.Status ~= Enum.PathStatus.Success then
				log("path retry from live position / " .. name .. " / " .. tostring(problem or path.Status))
				path:Destroy()
				task.wait(0.2)
				continue
			end
			local navigation = { blocked = false, index = 2 }
			local connection = path.Blocked:Connect(function(index)
				if index >= navigation.index then
					navigation.blocked = true
				end
			end)
			local reached, reason = true, nil
			local ok, followProblem = pcall(function()
				local waypoints = path:GetWaypoints()
				for i = 2, #waypoints do
					local waypoint = waypoints[i]
					navigation.index = i
					-- Navmesh positions are floor points, not authored clearance markers.
					reached, reason = walk(
						waypoint.Position + Vector3.new(0, 3, 0),
						name .. " path " .. i,
						waypoint.Action == Enum.PathWaypointAction.Jump,
						false,
						nil,
						nil,
						nil,
						nil,
						nil,
						navigation
					)
					if not reached or states[actor].phase == "Home" then
						return
					end
				end
				if autoReturn and states[actor].phase ~= "Home" then
					reached, reason =
						walk(position, name .. " secure boundary", false, true, nil, nil, nil, nil, nil, navigation)
				end
			end)
			connection:Disconnect()
			path:Destroy()
			assert(ok, followProblem)
			if reached or reason ~= "recompute" then
				return reached, reason
			end
			log("recompute from live position / " .. name)
		end
	end
	local function routeWalk(position, name, jump, autoReturn, takeoff, runup, edgeGoal, radius, arrivalLine)
		local reached, reason = walk(position, name, jump, autoReturn, takeoff, runup, edgeGoal, radius, arrivalLine)
		if not monitor and api.arena and not reached and (reason == "displaced" or reason == "missed jump") then
			return navigate(position, "recover to next goal " .. name, autoReturn)
		end
		return reached, reason
	end
	return routeWalk, r, h, navigate
end
local function act(api, actor, name, ...)
	local ok, why = api[name](actor, ...)
	assert(ok, "illegal refusal " .. name .. ": " .. tostring(why))
end
local function hold(api, actor, action)
	local _, humanoid = api.root(actor)
	if humanoid then
		humanoid:Move(Vector3.zero, false)
	end
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
	local _, humanoid = api.root(actor)
	humanoid:Move(Vector3.zero, false)
	while os.clock() < (states[actor].slowUntil or 0) do
		api.audit()
		if item.state == "Retired" or os.clock() >= item.escapeDeadline then
			return false, "expiry"
		end
		task.wait(0.03)
	end
	if item.state == "Retired" or os.clock() >= item.escapeDeadline then
		return false, "expiry"
	end
	if states[actor].item == item then
		return true
	end
	assert(
		states[actor].phase == "Run" and api.rules.active == item and item.state == "Dropped",
		"loot lost/taken before recovery"
	)
	local timestamp, escapeDeadline = item.firstPickup, item.escapeDeadline
	log("legal drop / recover " .. item.id)
	local attempt = 0
	while states[actor].item ~= item do
		attempt += 1
		if item.state == "Retired" or os.clock() >= item.escapeDeadline then
			return false, "expiry"
		end
		local reached, reason = walk(recoveryPoint(checked, item), "recover same dropped loot")
		if not reached then
			if reason == "expiry" then
				return false, reason
			end
			task.wait(math.max(0, (states[actor].slowUntil or 0) - os.clock()) + 0.03)
			continue
		end
		task.wait(math.max(0, item.settle - os.clock()) + 0.03)
		if item.state == "Retired" or os.clock() >= item.escapeDeadline then
			return false, "expiry"
		end
		local ok, why = api.holdAction(actor, "Grab", "begin")
		if ok then
			task.wait(Config.HoldSeconds.Grab + 0.05)
			ok, why = api.holdAction(actor, "Grab", "finish")
		end
		api.audit()
		if ok then
			break
		end
		if item.state == "Retired" or os.clock() >= item.escapeDeadline then
			return false, "expiry"
		end
		assert(api.rules.active == item and item.state == "Dropped", "recovery loot lost/taken")
		log("recovery interrupted / retry " .. attempt .. " / " .. tostring(why))
	end
	assert(
		states[actor].item == item and item.firstPickup == timestamp and item.escapeDeadline == escapeDeadline,
		"recovery identity/timestamp changed"
	)
	api.audit()
	return true
end
-- Live production expiry: no shortened clock, immunity, teleport or synthetic award.
local function verifyExpiry(player, states, pens, world, api, log, item, count, completed)
	local s = states[player]
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
	local waitUntil = os.clock() + Config.RespawnSeconds + 2
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
	log("expiry PASS / retired " .. item.id .. " / fresh " .. replacement.id .. " / no award or duplicate")
	return replacement
end
local function expiryExitSteps()
	if Config.MeadowV4 then
		return Layout.loopCarrySteps()
	end
	return {
		{ x = 0, y = 8, z = 32 },
		{ x = -4, y = 8, z = 18 },
		{ x = -4, y = 8, z = 12 },
		{ x = -4, y = 0, z = 0 },
		{ x = 0, y = 0, z = -2 },
		{ x = 0, y = 0, z = -22 },
		{ x = 0, y = 0, z = -40 },
	}
end
local function returnPortal(player, states, api, log, navigate, item)
	local s = states[player]
	if s.phase == "Run" then
		local dock = api.arena().dock
		local floor = assert(api.floor(dock.Position), "return portal floor missing")
		local reached, reason = navigate(floor + Vector3.new(0, 3, 0), "return portal", item ~= nil)
		if not reached then
			return false, reason
		end
	end
	if s.phase == "Run" then
		assert(api.returnInRange(player), "return portal approach outside action range")
		act(api, player, "returnRun")
	end
	assert(s.phase == "Home" and s.run == nil, "return did not reach Home")
	if item then
		assert(
			s.item == item
				and item.holder == player
				and item.state == "Secured"
				and item.securedAt < item.escapeDeadline,
			"return lost cargo or missed deadline"
		)
	else
		assert(not s.item, "empty return gained cargo")
	end
	api.audit()
	log(item and "return conserved " .. item.id or "empty return conserved")
	return true
end
local function expiryTest(player, states, pens, world, api, log, walk, navigate)
	local s = states[player]
	local count, completed = pens[s.slot].count, s.completed
	for _, p in homeEntryPoints(pens[s.slot]) do
		walk(p.position, "expiry " .. p.name)
	end
	act(api, player, "enterRun")
	local arena = api.arena()
	local checked, preflight = validator(world, log)
	local exit = expiryExitSteps()
	local points = {}
	for _, p in exit do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "expiry reachable exit" })
	end
	preflight(points)
	local waitUntil = os.clock() + Config.RespawnSeconds + 2
	while not api.rules.active or api.rules.active.state ~= "Nest" do
		assert(os.clock() < waitUntil, "expiry nest unavailable")
		task.wait(0.05)
	end
	for _, p in arena.layout.routes.Quick do
		walk(at(arena, p.x, p.y, p.z), "expiry approach")
	end
	hold(api, player, "Steal")
	local item = assert(s.item, "expiry missing cargo")
	-- Put the empty-return regression on the terrace before waiting. Hits may
	-- drop cargo; its original deadline and the actor's location remain legal.
	walk(
		checked(
			at(arena, Config.MeadowV4 and 0 or -4, Config.MeadowV4 and 48 or 8, Config.MeadowV4 and 108 or 18),
			"expiry wait terrace"
		),
		"expiry wait terrace"
	)
	verifyExpiry(player, states, pens, world, api, log, item, count, completed)
	assert(returnPortal(player, states, api, log, navigate))
end
local function place(player, states, pens, api, walk, log, item, initialCount)
	local s = states[player]
	assert(s.phase == "Home" and s.item == item and item.state == "Secured", "return lost loot")
	assert(not api.returnRun(player), "duplicate return accepted")
	local pen = pens[s.slot]
	local side = pen.marker.Position.X < 0 and -1 or 1
	-- Secure return is already at this plot's gate. Pick a legal free point,
	-- rather than treating the logical active count as a pad index.
	local cx, cz = Placement.center(s.slot)
	local floorY = Placement.height(s.slot) + 0.2
	local position
	for dz = -14, 14, 7 do
		for dx = -22, 22, 7 do
			local x, z = cx + dx, cz + dz
			if Placement.validate(Config, s.slot, x, z, 15, pen.occupied) then
				position = Vector3.new(x, floorY, z)
				break
			end
		end
		if position then
			break
		end
	end
	assert(position, "no free plot point")
	walk(Vector3.new(side * 1.4, 3, cz), "plot stairs approach")
	for step = 1, math.ceil(Placement.height(s.slot) / 0.5) do
		walk(
			Vector3.new(side * (1.4 + step * 0.9), 3 + math.min(step * 0.5, Placement.height(s.slot)), cz),
			"plot stair"
		)
	end
	walk(Vector3.new(side * 22, floorY + 3, cz), "own plot gate")
	walk(Vector3.new(position.X, floorY + 3, position.Z), "free plot point")
	assert(not api.placeItem(player, s.slot, Vector3.new(cx + 40, floorY, cz), 15), "out-of-bounds accepted")
	-- Reserve a fixture footprint while secured to test overlap before mutation.
	table.insert(pen.occupied, { x = position.X, z = position.Z, extent = 2 })
	assert(not api.placeItem(player, s.slot, position, 15), "overlap accepted")
	table.remove(pen.occupied)
	assert(s.item == item and item.state == "Secured" and pen.count == initialCount, "rejected Place consumed cargo")
	act(api, player, "placeItem", s.slot, position, 15)
	assert(not api.placeItem(player, s.slot, position, 15), "duplicate place accepted")
	assert(item.position == position + Vector3.new(0, 1.5, 0) and item.rotation == 15, "chosen transform lost")
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
	-- Retrace the placement approach through the open gate before the next
	-- loop tries to enter the hub aisle from inside a fenced plot.
	walk(Vector3.new(pen.marker.Position.X - side * 5, 3, cz), "leave placed plot through gate")
end
-- Harness-only traversal costs; leave collision and production rules untouched.
local function recoveryCosts(world)
	for _, part in world:GetDescendants() do
		if
			part:IsA("BasePart")
			and (part.Name == "RecoveryFloor" or part.Name:match("^Stone%d"))
			and not part:FindFirstChild("RecoveryPathCost")
		then
			local modifier = Instance.new("PathfindingModifier")
			modifier.Name, modifier.Label, modifier.Parent = "RecoveryPathCost", "JumpGully", part
		end
	end
end
function Test.run(player, states, pens, world, api, log)
	local s = states[player]
	assert(s.phase == "Home" and not s.item, "solo loop requires Home/empty hands")
	local initialCount, completed = pens[s.slot].count, s.completed
	local checked, preflight = validator(world, log)
	preflight(homePoints(pens[s.slot]))
	local monitor = {}
	local walk, r, h, navigate = driver(player, states, api, log, checked, monitor)
	for _, p in homeEntryPoints(pens[s.slot]) do
		walk(p.position, p.name)
	end
	act(api, player, "enterRun")
	local arena = api.arena()
	recoveryCosts(world)
	local started = s.started
	local carrySteps = Layout.loopCarrySteps(arena.layout)
	local dodgePoints = Layout.dodgePoints()
	local north = at(arena, dodgePoints[1].x, dodgePoints[1].y, dodgePoints[1].z)
	local south = at(arena, dodgePoints[2].x, dodgePoints[2].y, dodgePoints[2].z)
	local points = {}
	for i, p in dodgePoints do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "disc dodge option " .. i })
	end
	for i, p in Layout.referencePoints(arena.layout) do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "raised reference surface " .. i })
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
		if p.runup then
			local t = p.runup
			table.insert(points, { position = at(arena, t.x, t.y, t.z), name = "run-up " .. p.name, edge = true })
		end
	end
	for i, p in expiryExitSteps() do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "empty expiry exit " .. i })
	end
	preflight(points) -- enterRun creates the island; validate before island walking/Steal.
	local nestWait = os.clock() + Config.RespawnSeconds + 2
	while not api.rules.active or api.rules.active.state ~= "Nest" do
		assert(os.clock() < nestWait, "nest unavailable")
		task.wait(0.05)
	end
	for _, p in arena.layout.routes.Quick do
		walk(at(arena, p.x, p.y, p.z), p.kind .. " approach")
	end
	hold(api, player, "Steal")
	local item = s.item
	assert(item and item.state == "Carried", "missing nest loot")
	monitor.item = item
	assert(not api.holdAction(player, "Steal", "finish"), "duplicate nest accepted")
	if s.counter == 1 then
		SSS:SetAttribute("GreyboxLoopTestFreshToSteal", os.clock() - s.joined)
	end
	local function dodge()
		h:Move(Vector3.zero, false)
		local began = os.clock()
		local telegraph
		repeat
			if s.item ~= item or os.clock() < (s.slowUntil or 0) or os.clock() >= item.escapeDeadline then
				return false
			end
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
				if not walk(destination, "make room for readable throw") then
					return false
				end
			end
			if os.clock() - began > 8 then
				log("no throw window / continuing legal carry")
				return true
			end
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
		if not walk(destination, "Dodge locked red disc") then
			return false
		end
		if (Vector3.new(r.Position.X, locked.Y, r.Position.Z) - locked).Magnitude <= Config.ThrowRadius then
			log("still inside locked disc / observe legal impact before recovery")
		end
		local deadline = os.clock() + 8
		while arena.attack == telegraph do
			if s.item ~= item or os.clock() < (s.slowUntil or 0) or os.clock() >= item.escapeDeadline then
				return false
			end
			assert(os.clock() < deadline, "throw stuck >8s")
			task.wait(0.03)
		end
		assert(arena.throws > 0 and arena.chaseTicks > 0 and arena.chaseDistance > 0.1, "guardian never threw/chased")
		SSS:SetAttribute("GreyboxLoopTestTelegraphObserved", true)
		return true
	end
	local index, rejoin, expired = 1, false, false
	while index <= #carrySteps and s.phase == "Run" do
		if s.item ~= item then
			rejoin = true
		end
		local recovered = recover(api, player, states, navigate, item, log, checked)
		if not recovered then
			expired = true
			break
		end
		if rejoin then
			local portal = carrySteps[#carrySteps]
			local reached, reason =
				navigate(at(arena, portal.x, portal.y, portal.z), "recover directly to return portal", true)
			if not reached then
				if reason == "expiry" then
					expired = true
					break
				end
				continue
			end
			break
		end
		local step = carrySteps[index]
		if not step then
			break
		end
		local reached, reason = walk(
			at(arena, step.x, step.y, step.z),
			step.kind .. " " .. step.name,
			step.kind == "Jump",
			step.kind == "Return",
			step.takeoff and at(arena, step.takeoff.x, step.takeoff.y, step.takeoff.z),
			step.runup and at(arena, step.runup.x, step.runup.y, step.runup.z)
		)
		if not reached then
			if reason == "expiry" then
				expired = true
				break
			end
			rejoin = true
			continue
		end
		if s.phase == "Home" then
			break
		end
		if step.kind == "Dodge" then
			if not dodge() then
				rejoin = true
				continue
			end
		end
		if step.kind == "ClimbRamp" then
			SSS:SetAttribute("GreyboxLoopTestClimbObserved", true)
		end
		index += 1
	end
	if expired then
		verifyExpiry(player, states, pens, world, api, log, item, initialCount, completed)
		monitor.item = nil
		assert(returnPortal(player, states, api, log, navigate))
		api.audit()
		return "PASS-with-expiry / conserved loss " .. item.id, "expiry"
	end
	SSS:SetAttribute("GreyboxLoopTestPortalToPortal", os.clock() - started)
	SSS:SetAttribute("GreyboxLoopTestCatches", s.catches or 0)
	assert(item.securedAt < item.escapeDeadline, "solo did not escape inside deadline")
	place(player, states, pens, api, walk, log, item, initialCount)
	return "steal/secure/place; conserved " .. item.id, "placed"
end
function Test.pvp(player, states, pens, world, api, log, setDummy)
	local s = states[player]
	assert(s.phase == "Home" and not s.item, "PvP requires Home/empty hands")
	local initialCount = pens[s.slot].count
	local checked, preflight = validator(world, log)
	preflight(homePoints(pens[s.slot]))
	local monitor = {}
	local walk, _, _, navigate = driver(player, states, api, log, checked, monitor)
	walk(at(nil, 0, 3, Config.HomePortalApproachZ), "home portal")
	act(api, player, "enterRun")
	local arena = api.arena()
	recoveryCosts(world)
	local routes, points = Layout.pvpRoutes(), {}
	for i, p in Layout.referencePoints(arena.layout) do
		table.insert(points, { position = at(arena, p.x, p.y, p.z), name = "raised reference surface " .. i })
	end
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
	local dummy = api.dummy(at(arena, Config.Nest.x, Config.Nest.y, Config.Nest.z))
	setDummy(dummy)
	hold(api, dummy, "Steal")
	local ds = states[dummy]
	local item = ds.item
	local timestamp, escapeDeadline = item.firstPickup, item.escapeDeadline
	-- Consume the real one-time shield by waiting, never altering protection state.
	local dummyWalk, _, _, dummyNavigate = driver(dummy, states, api, log, checked)
	for i = 2, #routes.Dummy do
		recover(api, dummy, states, dummyNavigate, item, log, checked)
		local p = routes.Dummy[i]
		dummyWalk(at(arena, p.x, p.y, p.z), "dummy court approach " .. i)
	end
	recover(api, dummy, states, dummyNavigate, item, log, checked)
	api.pvpCourt(true)
	log("guardian isolated at camp for PvP court; real shield/mercy/holds unchanged")
	-- Keep the dummy moving to avoid the production AFK drop while shield expires.
	while os.clock() < ds.shield + 0.05 do
		local pacing = routes.Pacing
		dummyWalk(at(arena, pacing[2].x, pacing[2].y, pacing[2].z), "dummy shield pacing")
		dummyWalk(at(arena, pacing[1].x, pacing[1].y, pacing[1].z), "dummy shield pacing")
		recover(api, dummy, states, dummyNavigate, item, log, checked)
	end
	local handoff = false
	for attempt = 1, Config.TestRecoverRetries do
		recover(api, dummy, states, dummyNavigate, item, log, checked)
		local court = routes.Pacing[1]
		dummyWalk(at(arena, court.x, court.y, court.z), "dummy handoff court")
		local vulnerableDeadline = os.clock() + 8
		while os.clock() < ds.mercy or os.clock() < s.cooldown or not ds.item do
			assert(os.clock() < vulnerableDeadline, "no legal handoff window >8s")
			local mercy = routes.Mercy[2]
			dummyWalk(at(arena, mercy.x, mercy.y, mercy.z), "dummy dodges during impact mercy")
			dummyWalk(at(arena, court.x, court.y, court.z), "dummy returns to handoff court")
			recover(api, dummy, states, dummyNavigate, item, log, checked)
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
	local leave = routes.Leave[2]
	dummyWalk(at(arena, leave.x, leave.y, leave.z), "former carrier leaves contest")
	-- A fresh production Grab wins; legal interruptions may retry the same item.
	recover(api, player, states, navigate, item, log, checked)
	assert(not api.holdAction(player, "Grab", "finish"), "duplicate Grab accepted")
	assert(s.item == item and item.holder == player and item.state == "Carried", "handoff conservation")
	api.audit()
	SSS:SetAttribute("GreyboxPvpTestItemId", item.id)
	SSS:SetAttribute("GreyboxPvpTestHandoffs", 1)
	monitor.item = item
	for attempt = 1, Config.TestRecoverRetries do
		if s.phase == "Run" then
			assert(recover(api, player, states, navigate, item, log, checked), "PvP cargo expired before return")
		end
		local reached, reason = returnPortal(player, states, api, log, navigate, item)
		if reached then
			break
		end
		assert(reason ~= "expiry", "PvP cargo expired before return")
		assert(attempt < Config.TestRecoverRetries, "PvP return retry limit")
	end
	assert(
		item.securedAt < item.escapeDeadline and item.escapeDeadline == escapeDeadline and item.firstPickup == timestamp,
		"PvP deadline refreshed/late"
	)
	place(player, states, pens, api, walk, log, item, initialCount)
	monitor.item = nil
	api.pvpCourt(false)
	expiryTest(player, states, pens, world, api, log, walk, navigate)
	return "legal Bump/drop/settle/Grab/secure/place with dummy carrier; no duplicate/lost " .. item.id
end
return Test
