local S = script.Parent
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
if not Run:IsStudio() then
	return
end
local map = workspace.CaveV2
local Drops = require(S.CaveDrops)
local D = require(S.CaveReachableDrops)
local P = require(S.CavePolicy)
local Plan = require(S.KitPlan)
local data = require(game.ReplicatedStorage.CaveRouteData)
local function vec(p)
	return Vector3.new(p[1], p[3], -p[2])
end
local function await(predicate, seconds, label)
	local deadline = os.clock() + seconds
	repeat
		local result = predicate()
		if result then
			return result
		end
		task.wait(0.05)
	until os.clock() > deadline
	error("timeout: " .. label)
end
local function ready()
	await(function()
		return map:GetAttribute("KitSwapVersion") == 2
	end, 180, "kits2 swap")
	local templates = game.ServerStorage:FindFirstChild("KitTemplates")
	assert(templates and templates:GetAttribute("Loaded") == 74, "kits2 must load 74/74")
	Drops.refresh()
end
local failures, total, logged = {}, 0, 0
local function failure(reason, fields)
	total += 1
	fields = fields or {}
	fields.reason = tostring(reason)
	if #failures < 30 then
		table.insert(failures, fields)
	end
	if logged < 30 then
		warn("[CaveStudioPass] " .. Http:JSONEncode(fields))
		logged += 1
	end
end
local function player()
	local players = game.Players:GetPlayers()
	assert(#players == 1, "one Studio player required")
	local pl = players[1]
	assert(pl.Character, "character required")
	return pl, pl.Character:WaitForChild("HumanoidRootPart"), pl.Character:FindFirstChildOfClass("Humanoid")
end
local function move(root, hum, goal)
	local untilTime = os.clock() + 30
	repeat
		assert(hum.Health > 0, "avatar died")
		hum:MoveTo(goal)
		task.wait(0.1)
		assert(os.clock() < untilTime, "walk/recovery >30s at " .. tostring(goal))
	until (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(goal.X, 0, goal.Z)).Magnitude < 2.5
		and math.abs(root.Position.Y - goal.Y) < 4.5
end
local function walk(root, hum, points)
	for i = 2, #points do
		local a, b = vec(points[i - 1]), vec(points[i])
		local n = math.max(1, math.ceil((b - a).Magnitude / 6))
		for j = 1, n do
			move(root, hum, a:Lerp(b, j / n) + Vector3.new(0, 3, 0))
			task.wait()
		end
	end
end
local suites = {}
function suites.SelfTest()
	ready()
	local lanes = Drops.refresh()
	assert(#lanes > 0, "no strict floors")
	for i, p in map:GetDescendants() do
		if p:GetAttribute("WalkableLaneFloor") then
			assert(
				p.Parent == map
					and p:GetAttribute("CaveCategory") == "lane"
					and p.CanCollide
					and not p:GetAttribute("KitAssemblyId"),
				"forged floor " .. p.Name
			)
		end
		if i % 100 == 0 then
			task.wait()
		end
	end
	assert(Plan.laneClear(map.CaveKitDressing:GetDescendants(), lanes), "kit lane encroachment")
	local fences = 0
	for _, model in map.CaveKitDressing:GetChildren() do
		if model.Name:find("kenney_nature-kit__fence_simple", 1, true) then
			assert(model:GetAttribute("FenceEndpoints") == 2, "fence missing joint posts")
			fences += 1
		end
	end
	assert(fences > 0, "no safe kit fences mounted")
	for _, p in map.CaveKitDressing:GetDescendants() do
		if p:IsA("BasePart") then
			assert(not p.CanQuery and not p.CanCollide, "kit physics/query")
		end
	end
	local fake = { name = "main1", category = "rock", collidable = true }
	assert(not D.isLane(fake, { main = {} }), "rock forged lane accepted")
	-- Upper deck 1.8 studs above feet must not steal floor selection.
	local lower = {
		GetAttribute = function()
			return true
		end,
	}
	local ray = function(o)
		local y = o.Y >= 1.8 and 1.8 or o.Y >= 0 and 0 or nil
		return y and { Position = Vector3.new(0, y, 0), Normal = Vector3.yAxis, Instance = lower }
	end
	assert(D.floor(Vector3.new(0, 3, 0), ray, Vector3).Y == 0, "stacked floor selection")
end
function suites.DropSampleTest()
	ready()
	-- Exact owner-reported pass-2 main1/main2 joint, including both knock sides.
	local joint = Vector3.new(150.625, 51, -115)
	local jointFloor = assert(Drops.floor(joint), "main joint carrier floor")
	for _, knock in { -20, 0, 20 } do
		local socket = Drops.socket(joint + Vector3.new(0, 0, knock), jointFloor, joint)
		assert(socket and D.valid(socket, jointFloor.Y, Drops.laneRay, Drops.solidRay, Vector3), "main joint repeatable socket")
	end
	local samples = 0
	local n = math.clamp(S:GetAttribute("DropSampleTestN") or 8, 2, 64)
	for name, points in data.routes do
		if name ~= "cartRail" then
			for i = 2, #points do
				local a, b = vec(points[i - 1]), vec(points[i])
				local side = Vector3.new(-(b - a).Z, 0, (b - a).X).Unit
				for j = 0, n - 1 do
					for _, edge in { -5, 0, 5 } do
						local carrier = a:Lerp(b, (j + 0.5) / n) + side * edge + Vector3.new(0, 3, 0)
						local floor = Drops.floor(carrier)
						for _, knock in { -20, 0, 20 } do
							samples += 1
							local socket, why
							if floor then
								socket, why = Drops.socket(carrier + side * knock, floor, carrier)
							end
							if not socket or not D.valid(socket, floor.Y, Drops.laneRay, Drops.solidRay, Vector3) then
								local hit = Drops.solidRay(carrier + Vector3.new(0, 8, 0), Vector3.new(0, -16, 0))
								failure(why or "missing carrier floor", {
									laneId = name .. ":" .. i,
									position = { carrier.X, carrier.Y, carrier.Z },
									landingInstance = hit and hit.Instance:GetFullName() or "NONE",
									landingY = hit and hit.Position.Y or "UNKNOWN",
									knock = knock,
									socket = socket and { socket.X, socket.Y, socket.Z } or "NONE",
								})
							end
							S:SetAttribute("DropSampleTestSamples", samples)
							if samples % 16 == 0 then
								task.wait()
							end
						end
					end
				end
			end
		end
	end
	assert(total == 0, tostring(total) .. " unreachable drops")
end
local function loopRoute(name, points)
	local pl, root, hum = player()
	local api = S:WaitForChild("CaveLoopActions")
	api:Invoke("reset", pl)
	pl:SetAttribute("CaveSecured", nil)
	root.CFrame = CFrame.new(160, 51, -120)
	root.AssemblyLinearVelocity = Vector3.zero
	hum.WalkSpeed = 16
	task.wait(0.3)
	local id = api:Invoke("take", pl)
	assert(id, "steal failed")
	-- Actual forced drop + physical recovery, preserving the item and clock.
	local _, _, started = api:Invoke("status")
	assert(api:Invoke("drop", pl, root.Position + Vector3.new(20, 0, 0)), "drop failed")
	move(root, hum, map.Geode.Position + Vector3.new(0, 1.5, 0))
	task.wait(0.65)
	assert(api:Invoke("recover", pl) == id, "recover same item")
	local _, _, after = api:Invoke("status")
	assert(after == started, "recovery reset deadline")
	walk(root, hum, points)
	move(root, hum, Vector3.new(-150, 3, 120))
	await(function()
		return pl:GetAttribute("CaveSecured") == id
	end, 3, name .. " secure original")
	assert(api:Invoke("open", pl), "place/open original")
	S:SetAttribute("LoopTestRoute_" .. name, "PASS")
end
-- cart route is a physical cart escape; separate suite also exercises its fail path.
local function ride(speed, carry, index)
	index = index or 1
	local pl, root, hum = player()
	local cart = map["RideableCart" .. index]
	local actions = S:WaitForChild("CaveCartActions")
	await(function()
		return cart:GetAttribute("State") == "Dock"
	end, 60, "cart dock")
	-- Approach the prompt from beside the cart; production owns the seating
	-- teleport, cooldown retry and confirmed SeatWeld (no test-only Sit).
	root.CFrame = cart.OreCart.CFrame * CFrame.new(0, 3, 7)
	root.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.2)
	assert(actions:Invoke("board", index, pl), "board action did not confirm SeatWeld/Occupant")
	await(function()
		return cart.DriverSeat.Occupant == hum
	end, 3, "seat occupant")
	assert(cart.DriverSeat:FindFirstChild("SeatWeld"), "missing engine SeatWeld")
	if speed == 12 then
		assert(actions:Invoke("toggle", index, pl) == 12, "brake")
	end
	local seen = {}
	local highest = -math.huge
	local deadline = os.clock() + 70
	repeat
		local state = cart:GetAttribute("State")
		seen[state] = true
		if state == "Track" or state == "Flight" or state == "Landing" or state == "Fall" then
			assert(cart.DriverSeat.Occupant == hum and hum.SeatPart == cart.DriverSeat, "rider left seat: " .. state)
			assert((root.Position - cart.DriverSeat.Position).Magnitude < 6, "cart moved without rider: " .. state)
		end
		if state == "Flight" then
			highest = math.max(highest, root.Position.Y)
		end
		assert(hum.Health > 0, "cart rider died")
		task.wait(0.05)
		if os.clock() >= deadline then
			actions:Invoke("snapshot", index, "ride timeout; expected " .. (speed == 24 and "Flight/Landing/End" or "Fall/End"))
			error("ride timeout; see CartLastRide on cart/ServerScriptService")
		end
	until seen[speed == 24 and "Landing" or "Fall"] and cart:GetAttribute("State") == "End"
	assert(seen.Track, "no track ride")
	await(function()
		return hum.SeatPart == nil
	end, 5, "ride dismount")
	if speed == 24 then
		assert(seen.Flight and seen.Landing, "no big-air landing")
		assert(highest > 35, "no visible jump arc")
	else
		move(root, hum, vec(data.routes.pitRecovery[1]) + Vector3.new(0, 3, 0))
		walk(root, hum, data.routes.pitRecovery)
	end
	if carry then
		assert(pl:GetAttribute("CaveItemID") == carry, "cart lost original cargo")
	end
	return pl, root, hum
end
function suites.CartRideTest()
	ready()
	local label = map.JumpReady:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
	assert(label.Text:find("JUMP READY"), "missing JUMP READY")
	S.CaveCartActions:Invoke("blast")
	await(function()
		return not map.BreakableSpan.CanCollide
	end, 8, "blast gap")
	ride(24)
	-- Repair waits until the pit envelope is empty; re-arm only after minimum age.
	local _, root = player()
	root.CFrame = CFrame.new(160, 51, -120)
	await(function()
		return map.BreakableSpan.CanCollide
	end, 65, "safe repair")
	S.CaveCartActions:Invoke("blast")
	await(function()
		return not map.BreakableSpan.CanCollide
	end, 8, "second gap")
	ride(12, nil, 2)
end
-- Override the cart branch with the full approach/ride/secure path.
function suites.LoopTest()
	ready()
	loopRoute("main", data.routes.main)
	local pl, root, hum = player()
	local api = S.CaveLoopActions
	api:Invoke("reset", pl)
	pl:SetAttribute("CaveSecured", nil)
	root.CFrame = CFrame.new(160, 51, -120)
	task.wait(0.3)
	local id = api:Invoke("take", pl)
	walk(root, hum, data.routes.cartApproach)
	-- The full-chain cart escape runs before CartRideTest. Arm its own real
	-- gap rather than relying on a previous suite's broken-span state.
	if map.BreakableSpan.CanCollide then
		S.CaveCartActions:Invoke("blast")
		await(function()
			return not map.BreakableSpan.CanCollide
		end, 8, "loop cart blast gap")
	end
	ride(24, id)
	await(function()
		return hum.SeatPart == nil
	end, 6, "cart dismount")
	move(root, hum, Vector3.new(-150, 3, 120))
	await(function()
		return pl:GetAttribute("CaveSecured") == id
	end, 3, "cart secure")
	assert(api:Invoke("open", pl), "cart place/open")
	S:SetAttribute("LoopTestRoute_cart", "PASS")
	loopRoute("cave", data.routes.cave)
end
function suites.BlastPolicyTest()
	assert(P.flight(24) == "Flight" and P.flight(12) == "Fall", "committed speed policy")
	assert(
		P.canBlast(0, 0, 20, false)
			and not P.canBlast(1, 0, 20, false)
			and not P.canBlast(0, 0, 19, false)
			and not P.canBlast(0, 0, 20, true),
		"blast occupancy/cooldown/arming"
	)
	assert(
		P.canRepair(0, false, 20)
			and not P.canRepair(1, false, 20)
			and not P.canRepair(0, true, 20)
			and not P.canRepair(0, false, 19),
		"repair age/occupancy"
	)
	assert(P.previews.TNTHook.stages[1] == 1 and P.previews.TNTHook.cooldown == 15, "TNT tell/cooldown")
	assert(
		P.previews.DynamiteGuardianHook.stages[1] == 1.5 and P.previews.DynamiteGuardianHook.stages[2] == 1,
		"guardian preview tell/fuse"
	)
	for _, p in map:GetDescendants() do
		assert(not p:IsA("Explosion"), "unexpected damaging Explosion")
	end
	local pl, root, hum = player()
	local api = S.CaveLoopActions
	api:Invoke("reset", pl)
	root.CFrame = CFrame.new(160, 51, -120)
	task.wait(0.3)
	local id = api:Invoke("take", pl)
	local health = hum.Health
	for _, name in { "TNTHook", "DynamiteGuardianHook", "ShatterCavernHook" } do
		local hook = map[name]
		local prompt = hook:FindFirstChildOfClass("ProximityPrompt")
		await(function()
			return prompt.Enabled
		end, 35, name .. " cooldown")
		local begin = os.clock()
		assert(api:Invoke("preview", pl, name), name .. " preview action")
		await(function()
			assert(hum.Health == health and pl:GetAttribute("CaveItemID") == id, "preview damaged rider/cargo")
			return hook:GetAttribute("PayoffPreview") or hook:GetAttribute("Cluster1Burst")
		end, 5, name .. " visible payoff")
		local tell = name == "DynamiteGuardianHook" and 2.5 or 1
		assert(os.clock() - begin >= tell - 0.05, name .. " payoff before tell")
		assert(not prompt.Enabled, name .. " cooldown missing")
	end
end
local running = false
local order = { "SelfTest", "DropSampleTest", "LoopTest", "CartRideTest", "BlastPolicyTest" }
local function run(name)
	failures, total, logged = {}, 0, 0
	S:SetAttribute(name .. "Result", "RUNNING")
	S:SetAttribute(name .. "Success", false)
	S:SetAttribute(name .. "Failures", "[]")
	S:SetAttribute(name .. "FailureCount", 0)
	S:SetAttribute(name .. "Error", "")
	if name == "DropSampleTest" then
		S:SetAttribute("DropSampleTestSamples", 0)
	end
	local done, ok, err = false, false, nil
	local worker = task.spawn(function()
		ok, err = xpcall(function()
			if name == "LoopTest" or name == "CartRideTest" then
				assert(S:WaitForChild("CaveCartActions"):Invoke("resetAll"), "cart fixture reset")
				task.wait(0.3)
			end
			suites[name]()
		end, debug.traceback)
		done = true
	end)
	local deadline = os.clock() + (name == "DropSampleTest" and 900 or 360)
	repeat
		task.wait(0.1)
	until done or os.clock() > deadline
	if not done then
		task.cancel(worker)
		ok = false
		err = "suite watchdog: " .. name
	end
	if not ok and total == 0 then
		failure(err, { suite = name, lastDrop = S:GetAttribute("LoopTestLastDrop") or "UNKNOWN" })
	end
	if not ok then
		S:SetAttribute(name .. "Error", tostring(err))
	end
	if name == "LoopTest" or name == "CartRideTest" then
		local carts = S:FindFirstChild("CaveCartActions")
		if carts then
			for index = 1, 2 do
				carts:Invoke("snapshot", index, not ok and tostring(err) or nil)
			end
			S:SetAttribute(name .. "CartLastRide", S:GetAttribute("CartLastRide"))
			carts:Invoke("resetAll")
		end
	end
	S:SetAttribute(name .. "Failures", Http:JSONEncode(failures))
	S:SetAttribute(name .. "FailureCount", total)
	S:SetAttribute(name .. "Success", ok)
	S:SetAttribute(name .. "Result", ok and "PASS" or "FAIL")
	print("[CaveStudioPass] " .. name .. " " .. (ok and "PASS" or "FAIL"))
	return ok
end
local function execute(name)
	if running then
		S:SetAttribute(name, false)
		return
	end
	running = true
	S:SetAttribute(name, false)
	local pl, root, hum
	local cf, speed
	if #game.Players:GetPlayers() == 1 then
		pl, root, hum = player()
		cf = root.CFrame
		speed = hum.WalkSpeed
	end
	local fixture = name == "StudioPassAll" or name == "LoopTest" or name == "CartRideTest" or name == "BlastPolicyTest"
	if fixture then
		assert(
			pl and S:WaitForChild("CaveLoopActions"):Invoke("pristine", pl),
			"fresh Play with one empty cave profile required"
		)
	end
	local ok = true
	if name == "StudioPassAll" then
		S:SetAttribute(name .. "Result", "RUNNING")
		S:SetAttribute(name .. "Success", false)
		for _, suite in order do
			S:SetAttribute(suite .. "Result", "NOT RUN")
			S:SetAttribute(suite .. "Failures", "[]")
		end
		for _, suite in order do
			if not run(suite) then
				ok = false
				break
			end
			task.wait()
		end
		S:SetAttribute(name .. "Result", ok and "PASS" or "FAIL")
		S:SetAttribute(name .. "Success", ok)
		S:SetAttribute(name .. "Failures", Http:JSONEncode(failures))
		S:SetAttribute(name .. "FailureCount", total)
	else
		ok = run(name)
	end
	if fixture and pl and S:FindFirstChild("CaveLoopActions") then
		S.CaveLoopActions:Invoke("reset", pl)
	end
	if root and root.Parent then
		hum.Sit = false
		task.wait(0.2)
		root.CFrame = cf
		root.AssemblyLinearVelocity = Vector3.zero
		hum.WalkSpeed = speed
	end
	running = false
end
local function trigger(name)
	local ok, err = xpcall(function()
		execute(name)
	end, debug.traceback)
	if not ok then
		failure(err, { suite = name })
		S:SetAttribute(name .. "Result", "FAIL")
		S:SetAttribute(name .. "Success", false)
		S:SetAttribute(name .. "Failures", Http:JSONEncode(failures))
		S:SetAttribute(name .. "FailureCount", total)
		running = false
	end
end
for _, name in { "SelfTest", "DropSampleTest", "LoopTest", "CartRideTest", "BlastPolicyTest", "StudioPassAll" } do
	S:GetAttributeChangedSignal(name):Connect(function()
		if S:GetAttribute(name) == true then
			task.spawn(trigger, name)
		end
	end)
end
