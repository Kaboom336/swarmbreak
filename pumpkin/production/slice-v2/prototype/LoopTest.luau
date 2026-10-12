-- Shared scalar route can be audited in Lune; walking/actions run only in Studio.
local LoopTest = {}

function LoopTest.route(layout)
	local points = {}
	for _, p in layout.pieces do
		if string.sub(p.id, 1, 3) == "P02" then
			-- S-turn inside the eight-stud gap between the staggered cover blocks.
			table.insert(points, { x = 2, z = p.z - 8, name = p.id .. " cover in" })
			table.insert(points, { x = 0, z = p.z, name = p.id .. " centre" })
			table.insert(points, { x = -2, z = p.z + 8, name = p.id .. " cover out" })
		else
			table.insert(points, { x = 0, z = p.z, name = p.id .. " centre" })
		end
	end
	local nest = layout.pieces[#layout.pieces]
	table.insert(points, { x = 0, z = nest.z + 12, name = "nest steal range" })
	return points
end

function LoopTest.run(player, states, pens, world, actions, log)
	local s = states[player]
	assert(s and s.counter == 0 and not s.item and pens[s.slot].count == 0, "start a fresh Play session")
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	local h = character and character:FindFirstChildOfClass("Humanoid")
	assert(r and h and h.Health > 0, "fresh character missing")
	r:SetNetworkOwner(nil)
	local function walk(position, name, expectedRun)
		log("walk " .. name)
		local started, progressed = os.clock(), os.clock()
		local bestDistance = math.huge
		local nextMove = 0
		while true do
			assert(
				player.Character == character and h.Health > 0 and states[player] == s,
				"character/player lost at " .. name
			)
			assert(s.run == expectedRun, "run reset or escaped unexpectedly at " .. name)
			local offset = Vector3.new(r.Position.X - position.X, 0, r.Position.Z - position.Z)
			if offset.Magnitude <= 1.5 then
				break
			end
			local now = os.clock()
			if offset.Magnitude < bestDistance - 0.3 then
				bestDistance, progressed = offset.Magnitude, now
			end
			assert(now - progressed <= 8, "stuck >8s at " .. name)
			assert(now - started <= 30, "waypoint not reached within 30s at " .. name)
			if now >= nextMove then
				h:MoveTo(Vector3.new(position.X, r.Position.Y, position.Z))
				nextMove = now + 1
			end
			task.wait(0.05)
		end
		h:MoveTo(r.Position)
	end
	local function act(name, ...)
		local ok, reason = actions[name](player, ...)
		assert(ok, "legal " .. name .. " refused: " .. tostring(reason))
	end
	local function at(x, z)
		return Vector3.new(x, 3, z)
	end
	walk(at(0, -12), "home spawn", nil)
	walk(at(0, -5), "home portal", nil)
	act("enterRun")
	local run = s.run
	local route = LoopTest.route(run.layout)
	for _, p in route do
		walk(run.origin + at(p.x, p.z), p.name, run)
	end
	act("stealHold", "begin")
	local holdStarted = os.clock()
	task.wait(1)
	act("stealHold", "finish")
	local freshToSteal = os.clock() - s.joined
	game:GetService("ServerScriptService"):SetAttribute("GreyboxLoopTestFreshToSteal", freshToSteal)
	assert(os.clock() - holdStarted >= 1, "steal hold less than 1s")
	assert(s.item == run.token and run.grants == 1, "missing item or double grant")
	assert(not actions.stealHold(player, "finish"), "duplicate steal accepted")
	assert(run.grants == 1, "double grant after repeated steal")
	log(string.format("fresh spawn -> steal %.3fs; hold %.3fs", freshToSteal, os.clock() - holdStarted))
	for i = #route - 1, 1, -1 do
		local p = route[i]
		walk(run.origin + at(p.x, p.z), "back " .. p.name, run)
	end
	walk(run.origin + at(0, -3), "return portal", run)
	local portalToPortal, catches = os.clock() - run.started, run.catches
	local service = game:GetService("ServerScriptService")
	service:SetAttribute("GreyboxLoopTestPortalToPortal", portalToPortal)
	service:SetAttribute("GreyboxLoopTestCatches", catches)
	log(
		string.format(
			"portal -> portal %.3fs; catches=%d; chase ticks=%d distance=%.3f",
			portalToPortal,
			catches,
			run.chaseTicks,
			run.chaseDistance
		)
	)
	assert(run.chaseTicks > 0 and run.chaseDistance > 0.1, "guardian never chasing/moving during chase")
	assert(run.grants == 1, "double grant")
	act("returnRun")
	assert(
		not s.run and s.phase == "Home" and s.item == run.token and s.completed == 1,
		"return lost item or escape not counted"
	)
	local pen = pens[s.slot]
	local side = pen.marker.Position.X < 0 and -1 or 1
	walk(at(side * 60, -12), "home aisle", nil)
	walk(at(side * 60, pen.marker.Position.Z), "own pen aisle", nil)
	walk(at(pen.marker.Position.X - side * 5, pen.marker.Position.Z), "own pen", nil)
	act("placeItem", s.slot)
	assert(not s.item and pen.count == 1, "item not placed")
	assert(not actions.placeItem(player, s.slot), "duplicate placement accepted")
	local count = 0
	for _, child in world:GetChildren() do
		if child.Name == "Placed_" .. run.token and child:GetAttribute("PenSlot") == s.slot then
			count += 1
		end
	end
	assert(count == 1 and pen.count == 1 and run.grants == 1, "item not placed exactly once / double grant")
	log(
		string.format(
			"portal -> portal %.3fs; catches=%d; chase ticks=%d distance=%.3f; success=true",
			portalToPortal,
			catches,
			run.chaseTicks,
			run.chaseDistance
		)
	)
	return { freshToSteal = freshToSteal, portalToPortal = portalToPortal, catches = catches }
end

return LoopTest
