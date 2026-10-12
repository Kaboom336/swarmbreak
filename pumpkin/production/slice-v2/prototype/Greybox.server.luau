local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Pathfinding = game:GetService("PathfindingService")
local Config = require(RS:WaitForChild("GreyboxConfig"))
local Layout = require(RS:WaitForChild("GreyboxLayout"))
local world = Instance.new("Folder")
world.Name = "GREYBOX"
world.Parent = workspace
local states, pens, slots = {}, {}, {}
local orange = Color3.fromRGB(255, 150, 35)
local grey = Color3.fromRGB(125, 135, 145)

local function part(parent, name, size, position, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, position
	p.Anchored, p.Color = true, color or grey
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(p, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 48)
	gui.StudsOffset = Vector3.new(0, p.Size.Y / 2 + 3, 0)
	gui.AlwaysOnTop, gui.MaxDistance = true, 180
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	t.Text, t.TextSize, t.TextColor3 = text, 18, Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Parent = gui
	return t
end

local function prompt(p, action, object, hold)
	local q = Instance.new("ProximityPrompt")
	q.ActionText, q.ObjectText, q.HoldDuration = action, object, hold or 0
	q.MaxActivationDistance, q.RequiresLineOfSight = 9, false
	q.Parent = p
	return q
end

local function root(player)
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	local h = character and character:FindFirstChildOfClass("Humanoid")
	if r and h and h.Health > 0 then
		return r, h
	end
	return nil, nil
end

local function near(player, p)
	local r = root(player)
	return r and (r.Position - p.Position).Magnitude <= 11
end

local function update(player, text)
	local s = states[player]
	player:SetAttribute("GreyboxGoal", text)
	player:SetAttribute("GreyboxCarry", s and s.item ~= nil or false)
end

local function carry(player)
	local s = states[player]
	if s.carryVisual then
		s.carryVisual:Destroy()
		s.carryVisual = nil
	end
	local r, h = root(player)
	if not r then
		return
	end
	h.WalkSpeed = s.item and Config.CarrySpeed or Config.WalkSpeed
	if s.item then
		local ball = part(player.Character, "CarriedTreasure", Vector3.new(2.5, 2.5, 2.5), r.Position, orange)
		ball.Shape, ball.Material = Enum.PartType.Ball, Enum.Material.Neon
		ball.Anchored, ball.CanCollide, ball.CanQuery, ball.Massless = false, false, false, true
		ball.CFrame = r.CFrame * CFrame.new(0, 3.5, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = r, ball, ball
		s.carryVisual = ball
	end
end

local function clearRun(s)
	if s.run then
		s.run.model:Destroy()
		s.run = nil
	end
end

local function home(player, escaped)
	local s = states[player]
	if not s then
		return
	end
	if escaped then
		print(
			string.format(
				"[Greybox] escape user=%d seed=%d elapsed=%.3fs catches=%d",
				player.UserId,
				s.run.seed,
				os.clock() - s.run.started,
				s.run.catches
			)
		)
		s.completed += 1
	end
	clearRun(s)
	s.phase, s.hold = "Home", nil
	s.slowUntil, s.mercyUntil = 0, 0
	local r = root(player)
	if r then
		player.Character:PivotTo(CFrame.new(0, 4, -12))
	end
	carry(player)
	update(player, s.item and "Return to your marked pen. Place the ball." or "Enter the central portal.")
end

part(world, "Home 240x192", Vector3.new(240, 4, 192), Vector3.new(0, -2, 0))
local spawn = Instance.new("SpawnLocation")
spawn.Name, spawn.Size, spawn.Position = "HomeSpawn", Vector3.new(10, 1, 10), Vector3.new(0, 0.5, -12)
spawn.Anchored, spawn.Neutral, spawn.Duration, spawn.Parent = true, true, 0, world
local shop = part(world, "Shop", Vector3.new(20, 12, 14), Vector3.new(0, 6, -72))
label(shop, "GREYBOX SHOP — placeholder")
local portal = part(world, "HomePortal", Vector3.new(10, 8, 2), Vector3.new(0, 4, 0), Color3.fromRGB(70, 180, 220))
label(portal, "GREYBOX — Enter guardian island")
local enter = prompt(portal, "Enter", "Guardian island")

for i = 1, 8 do
	local x, z = i <= 4 and -88 or 88, -54 + ((i - 1) % 4) * 36
	local base =
		part(world, "Pen" .. i, Vector3.new(38, 0.2, 28), Vector3.new(x, 0.1, z), Color3.fromRGB(100, 115, 100))
	for _, dz in { -14, 14 } do
		part(world, "PenFence", Vector3.new(38, 2, 0.5), Vector3.new(x, 1, z + dz))
	end
	part(world, "PenBack", Vector3.new(0.5, 2, 28), Vector3.new(x + (x < 0 and -19 or 19), 1, z))
	local marker =
		part(world, "PenMarker" .. i, Vector3.new(2, 3, 2), Vector3.new(x + (x < 0 and 16 or -16), 1.5, z), orange)
	pens[i] = {
		base = base,
		marker = marker,
		text = label(marker, "Pen " .. i .. " — vacant"),
		count = 0,
	}
	local place = prompt(marker, "Place", "Own pen")
	place:SetAttribute("PenSlot", i)
	place.Triggered:Connect(function(player)
		local s = states[player]
		local pen = pens[i]
		if not s or s.slot ~= i or s.phase ~= "Home" or not s.item or not near(player, marker) or pen.count >= 8 then
			return
		end
		local item = s.item
		s.item = nil -- consume identity before creating the placement; duplicate prompt cannot replay
		pen.count += 1
		local n = pen.count - 1
		local ball = part(
			world,
			"Placed_" .. item,
			Vector3.new(3, 3, 3),
			Vector3.new(x - 12 + (n % 4) * 8, 1.7, z - 5 + math.floor(n / 4) * 10),
			orange
		)
		ball.Shape, ball.Material = Enum.PartType.Ball, Enum.Material.Neon
		ball:SetAttribute("PenSlot", i)
		carry(player)
		update(player, "Placed! Enter the portal for another run.")
		print("[Greybox] place user=" .. player.UserId .. " item=" .. item)
	end)
end

local function buildPieces(model, layout, origin)
	local floors = {}
	local function build(name, size, x, y, z, color)
		return part(model, name, size, origin + Vector3.new(x, y, z), color)
	end
	for i, p in layout.pieces do
		local floor = build(p.id, Vector3.new(p.width, 4, p.depth), 0, -2, p.z)
		label(floor, "GREYBOX " .. p.id)
		floors[i] = floor
		local pivot = Instance.new("Attachment")
		pivot.Name, pivot.Position, pivot.Parent = "GroundPivot", Vector3.new(0, 2, 0), floor
		for _, port in { "In", "Out" } do
			local value = port == "In" and p.inZ or p.outZ
			if value then
				local a = Instance.new("Attachment")
				a.Name, a.Position, a.Orientation, a.Parent =
					port, Vector3.new(0, 2, value - p.z), Vector3.new(0, port == "Out" and 180 or 0, 0), floor
			end
		end
		for _, sign in { -1, 1 } do
			build("Rail", Vector3.new(0.5, 1.5, p.depth), sign * (p.width / 2 - 0.25), 0.75, p.z)
		end
		if string.sub(p.id, 1, 3) == "P02" then
			build("CoverLeft", Vector3.new(8, 8, 4), -8, 4, p.z - 3)
			build("CoverRight", Vector3.new(8, 8, 4), 8, 4, p.z + 3)
		elseif p.id == "P07" then
			for _, x in { -12, 12 } do
				build("NestCover", Vector3.new(8, 8, 8), x, 4, p.z - 4)
			end
		end
	end
	for i, floor in floors do
		local p = layout.pieces[i]
		assert(floor.Position.Y + floor.Size.Y / 2 == origin.Y, "runtime floor height")
		assert(floor.Size.X == p.width and floor.Size.Z == p.depth, "runtime piece bounds")
		if i > 1 then
			local previous = floors[i - 1].Out
			assert((previous.WorldPosition - floor.In.WorldPosition).Magnitude < 0.001, "runtime snap gap")
			assert(
				previous.WorldCFrame.LookVector:Dot(floor.In.WorldCFrame.LookVector) < -0.999,
				"runtime connector normals"
			)
		end
	end
	return floors
end
local function assemble(player, seed, first)
	local s = states[player]
	local ok, layout = pcall(function()
		local value = Layout.assemble(Config, seed, first)
		Layout.validate(Config, value)
		return value
	end)
	if not ok then
		warn("[Greybox] rejected seed=" .. seed .. " reason=" .. tostring(layout) .. "; safe fallback")
		layout = Layout.assemble(Config, seed, true)
		Layout.validate(Config, layout)
	end
	local origin = Vector3.new(500 + (s.slot - 1) * 220, 0, 0)
	local model = Instance.new("Model")
	model.Name, model.Parent = "RunSlot" .. s.slot, world
	model:SetAttribute("Seed", seed)
	model:SetAttribute("RecipeVersion", Config.RecipeVersion)
	local function at(x, y, z)
		return origin + Vector3.new(x, y, z)
	end
	local function build(name, size, x, y, z, color)
		return part(model, name, size, at(x, y, z), color)
	end
	buildPieces(model, layout, origin)
	local nest = layout.pieces[#layout.pieces]
	build("BackRail", Vector3.new(48, 1.5, 0.5), 0, 0.75, nest.z + 23.75)
	build("EntryRail", Vector3.new(32, 1.5, 0.5), 0, 0.75, -11.75)
	local safe = build("SafePad", Vector3.new(31, 0.1, 24), 0, 0.05, 0, Color3.fromRGB(80, 190, 160))
	safe.CanCollide, safe.CanQuery = false, false
	local dock = build("ReturnPortal", Vector3.new(10, 8, 2), 0, 4, -8, Color3.fromRGB(70, 180, 220))
	label(dock, "Return home — safe pad")
	local back = prompt(dock, "Return", "Home")
	local loot = build("Treasure", Vector3.new(3, 3, 3), 0, 1.5, nest.z + 16, orange)
	loot.Shape, loot.Material = Enum.PartType.Ball, Enum.Material.Neon
	loot.CanCollide, loot.CanQuery = false, false
	local steal = prompt(loot, "Steal", "Glowing ball", 1)
	local guard = build("Guardian", Vector3.new(4, 11, 4), 12, 5.5, nest.z + 8, Color3.fromRGB(150, 100, 100))
	guard.CanCollide, guard.CanQuery = false, false
	local warning = label(guard, "GUARDIAN — patrol")
	local run = {
		model = model,
		seed = seed,
		token = s.slot .. ":" .. s.counter,
		origin = origin,
		guardian = guard,
		warning = warning,
		nestZ = nest.z,
		started = os.clock(),
		catches = 0,
		mode = "Patrol",
		untilTime = 0,
		nextPath = 0,
		points = {},
		index = 1,
		patrol = 1,
	}
	s.run, s.phase = run, "Run"
	back.Triggered:Connect(function(p)
		if p ~= player or s.run ~= run or s.phase ~= "Run" or not near(p, dock) then
			return
		end
		home(p, s.item ~= nil)
	end)
	steal.PromptButtonHoldBegan:Connect(function(p)
		if p == player and s.run == run and s.phase == "Run" and not s.item and near(p, loot) then
			s.hold = { token = run.token, began = os.clock() }
		end
	end)
	steal.PromptButtonHoldEnded:Connect(function(p)
		if p == player then
			s.hold = nil
		end
	end)
	steal.Triggered:Connect(function(p)
		local hold = s.hold
		if
			p ~= player
			or s.run ~= run
			or s.phase ~= "Run"
			or s.item
			or not near(p, loot)
			or not hold
			or hold.token ~= run.token
			or os.clock() - hold.began < 1
		then
			return
		end
		s.item, s.hold = run.token, nil
		steal.Enabled, loot.Transparency = false, 1
		run.mode, run.untilTime = "HeadStart", os.clock() + Config.HeadStartSeconds
		carry(p)
		update(p, "Carry 1/1 — dodge around cover, return to the same portal.")
		print(string.format("[Greybox] steal user=%d seed=%d fresh=%.3fs", p.UserId, seed, os.clock() - s.joined))
	end)
	player.Character:PivotTo(CFrame.new(at(0, 4, -4)) * CFrame.Angles(0, math.pi, 0))
	update(player, "Dodge around cover. Hold Steal for 1 second at the glowing ball.")
	print("[Greybox] assembled slot=" .. s.slot .. " " .. Layout.signature(layout))
end

enter.Triggered:Connect(function(player)
	local s = states[player]
	if not s or s.phase ~= "Home" or s.run or not near(player, portal) then
		return
	end
	if s.item then
		update(player, "Place your carried ball in your own pen first.")
		return
	end
	if pens[s.slot].count >= 8 then
		update(player, "Your pen is full (8/8). No new run.")
		return
	end
	s.counter += 1
	local override = SSS:GetAttribute("GreyboxSeed")
	local fixed = type(override) == "number" and override > 0 and override < 2147483647 and override % 1 == 0
	local seed = fixed and override
		or (Config.SessionSeed + s.slot * 1009 + s.counter * 9176 + Config.RecipeVersion * 31) % 2147483647
	assemble(player, seed, not fixed and s.counter == 1)
end)

local function addPlayer(player)
	if states[player] then
		return
	end
	local slot
	for i = 1, 8 do
		if not slots[i] then
			slot = i
			break
		end
	end
	if not slot then
		update(player, "Eight solo slots occupied. Wait for a free slot.")
		return
	end
	slots[slot] = player
	states[player] = { slot = slot, counter = 0, completed = 0, phase = "Home", joined = os.clock() }
	pens[slot].text.Text = "Pen " .. slot .. " — " .. player.DisplayName
	player:SetAttribute("GreyboxPen", slot)
	local function characterAdded(character)
		character:WaitForChild("HumanoidRootPart")
		if states[player] then
			if states[player].counter == 0 then
				states[player].joined = os.clock()
			end
			home(player, false)
		end -- committed item stays in session escrow through reset
	end
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then
		task.spawn(characterAdded, player.Character)
	end
	update(player, "Enter the central portal.")
end
Players.PlayerAdded:Connect(addPlayer)
for _, player in Players:GetPlayers() do
	addPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	local s = states[player]
	if not s then
		return
	end
	clearRun(s)
	if s.item then
		print("[Greybox] disconnect: transient item retired " .. s.item .. " (no persistence in T1)")
	end
	for _, p in world:GetChildren() do
		if p:GetAttribute("PenSlot") == s.slot then
			p:Destroy()
		end
	end
	pens[s.slot].count, pens[s.slot].text.Text = 0, "Pen " .. s.slot .. " — vacant"
	slots[s.slot], states[player] = nil, nil
end)

local function selfTest()
	for _, seed in { 101, 202, 303, 101 } do
		local model = Instance.new("Model")
		local passed, problem = pcall(function()
			local layout = Layout.assemble(Config, seed, false)
			Layout.validate(Config, layout)
			buildPieces(model, layout, Vector3.zero)
		end)
		model:Destroy()
		if not passed then
			SSS:SetAttribute("GreyboxSelfTestResult", tostring(problem))
			warn("[GreyboxSelfTest] runtime assembly FAIL seed=" .. seed .. " " .. tostring(problem))
			return
		end
		print("[GreyboxSelfTest] runtime assembly/snap/bounds PASS seed=" .. seed)
	end
	local ok, err = pcall(Layout.selfTest, Config, function(message)
		print("[GreyboxSelfTest] " .. message)
	end)
	SSS:SetAttribute("GreyboxSelfTestResult", ok and "PASS" or tostring(err))
	if not ok then
		warn("[GreyboxSelfTest] FAIL " .. tostring(err))
	end
end
SSS:GetAttributeChangedSignal("GreyboxSelfTest"):Connect(function()
	if SSS:GetAttribute("GreyboxSelfTest") then
		selfTest()
		SSS:SetAttribute("GreyboxSelfTest", false)
	end
end)
if SSS:GetAttribute("GreyboxSelfTest") then
	selfTest()
end

-- Anchored guardian follows server navmesh paths. Sweeps and floor checks prevent clipping/void cuts.
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.05 then
		return
	end
	local step = math.min(accumulator, 0.15)
	accumulator = 0
	local now = os.clock()
	for player, s in states do
		local run = s.run
		local r, h = root(player)
		if not run or not r then
			continue
		end
		local localPosition = r.Position - run.origin
		if
			localPosition.Y < -10
			or math.abs(localPosition.X) > 60
			or localPosition.Z < -16
			or localPosition.Z > run.nestZ + 28
		then
			home(player, false)
			continue
		end
		if s.hold and ((r.Position - (run.origin + Vector3.new(0, 1.5, run.nestZ + 16))).Magnitude > 11) then
			s.hold = nil
		end
		h.WalkSpeed = now < (s.slowUntil or 0) and 5 or (s.item and Config.CarrySpeed or Config.WalkSpeed)
		local safe = math.abs(localPosition.X) <= 16 and localPosition.Z >= -12 and localPosition.Z <= 12
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { run.model }
		local guard = run.guardian
		local sightStart = guard.Position - Vector3.new(0, 3, 0)
		local delta = r.Position - sightStart
		local sight = workspace:Raycast(sightStart, delta, params) == nil
		if s.item then
			if run.mode ~= "Chase" and now >= run.untilTime then
				run.mode = "Chase"
			end
		elseif run.mode == "Patrol" and not safe and delta.Magnitude < 30 and sight then
			run.mode, run.untilTime = "Warn", now + Config.WarningSeconds
		elseif run.mode == "Warn" and now >= run.untilTime then
			run.mode = "Approach"
		elseif run.mode == "Approach" and (safe or delta.Magnitude > 38 or not sight) then
			run.mode = "Patrol"
		end
		local stopped = run.mode == "Warn" or run.mode == "HeadStart"
		run.warning.Text = run.mode == "Warn" and "WARNING — move around cover!" or "GUARDIAN — " .. run.mode
		guard.Color = stopped and orange or Color3.fromRGB(150, 100, 100)
		local aggressive = run.mode == "Chase" or run.mode == "Approach"
		if
			aggressive
			and not safe
			and now >= (s.mercyUntil or 0)
			and (r.Position - Vector3.new(guard.Position.X, r.Position.Y, guard.Position.Z)).Magnitude <= Config.CatchRadius
			and sight
		then
			s.slowUntil, s.mercyUntil = now + Config.SlowSeconds, now + Config.SlowSeconds + Config.MercySeconds
			run.catches += 1
			update(player, "Caught: slow 1 second, then 3 seconds mercy. Loot kept.")
			print("[Greybox] catch seed=" .. run.seed .. " lootKept=" .. tostring(s.item ~= nil))
		end
		if stopped or now < (s.mercyUntil or 0) then
			continue
		end
		local target
		if aggressive and not safe then
			target = Vector3.new(r.Position.X, 1, r.Position.Z)
		else
			local patrols = {
				Vector3.new(12, 1, run.nestZ + 8),
				Vector3.new(-12, 1, run.nestZ + 12),
				Vector3.new(0, 1, run.nestZ - 14),
			}
			target = run.origin + patrols[run.patrol]
			if (Vector3.new(guard.Position.X, 1, guard.Position.Z) - target).Magnitude < 3 then
				run.patrol = run.patrol % #patrols + 1
			end
		end
		if now >= run.nextPath and not run.computing then
			run.nextPath, run.computing = now + 0.7, true
			task.spawn(function()
				local path = Pathfinding:CreatePath({
					AgentRadius = 2.5,
					AgentHeight = 11,
					AgentCanJump = false,
					WaypointSpacing = 3,
				})
				local ok = pcall(function()
					path:ComputeAsync(Vector3.new(guard.Position.X, 1, guard.Position.Z), target)
				end)
				if s.run == run and ok and path.Status == Enum.PathStatus.Success then
					run.points, run.index = path:GetWaypoints(), 2
				end
				path:Destroy()
				run.computing = false
			end)
		end
		local waypoint = run.points[run.index]
		if waypoint then
			local goal = Vector3.new(waypoint.Position.X, 5.5, waypoint.Position.Z)
			local offset = goal - guard.Position
			if offset.Magnitude < 0.5 then
				run.index += 1
			else
				local movement = offset.Unit
					* math.min(offset.Magnitude, (aggressive and Config.CarrySpeed * 0.88 or 7) * step)
				local nextPosition = guard.Position + movement
				local wall = workspace:Blockcast(CFrame.new(guard.Position), Vector3.new(4, 10, 4), movement, params)
				local floor = workspace:Raycast(nextPosition, Vector3.new(0, -8, 0), params)
				if not wall and floor and nextPosition.Z - run.origin.Z > 14 then
					guard.Position = nextPosition
				else
					run.points, run.nextPath = {}, 0
				end
			end
		end
	end
end)
