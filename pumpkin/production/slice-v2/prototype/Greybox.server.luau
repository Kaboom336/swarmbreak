local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local PromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(RS:WaitForChild("GreyboxConfig"))
local Layout = require(RS:WaitForChild("GreyboxLayout"))
local Rules = require(RS:WaitForChild("GreyboxLootRules"))
local Arena = require(SSS:WaitForChild("GreyboxArena"))
local Scene = require(RS:WaitForChild("GreyboxScene"))
local Placement = require(RS:WaitForChild("GreyboxPlacement"))
local Traps = require(RS:WaitForChild("GreyboxTraps"))
local rules = Rules.new(Config)
local states, pens, slots = rules.actors, {}, {}
local world = Instance.new("Folder")
world.Name, world.Parent = "GREYBOX", workspace
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name, actionRemote.Parent = "GreyboxAction", RS
local orange, grey = Color3.fromRGB(255, 160, 40), Color3.fromRGB(125, 135, 145)
local arena, testRunning, firstPlayer, session = nil, false, nil, 0
local pvpCourtPaused = false -- Only the Studio runner can pause guardian interference.
local testLog
PromptService.Enabled, PromptService.MaxPromptsVisible = true, 8
pcall(function()
	PhysicsService:RegisterCollisionGroup("GreyboxPlayers")
end)
PhysicsService:CollisionGroupSetCollidable("GreyboxPlayers", "GreyboxPlayers", false)
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

local traps = Traps.new(Config, Arena, part, label)
traps.rattle = function(parent)
	local sound = Instance.new("Sound")
	sound.Name, sound.SoundId = "DecoyRattle", "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume, sound.PlaybackSpeed, sound.RollOffMaxDistance, sound.Parent = 0.5, 1.5, 48, parent
	sound:Play()
end

local function prompt(p, action, object, hold)
	local q = Instance.new("ProximityPrompt")
	q.ActionText, q.ObjectText, q.HoldDuration = action, object, hold or 0
	q.MaxActivationDistance, q.RequiresLineOfSight = 9, false
	q.Enabled, q.Style, q.Exclusivity =
		true, Enum.ProximityPromptStyle.Default, Enum.ProximityPromptExclusivity.AlwaysShow
	q.KeyboardKeyCode, q.GamepadKeyCode, q.ClickablePrompt = Enum.KeyCode.E, Enum.KeyCode.ButtonX, true
	q:SetAttribute("GreyboxAction", action)
	-- Explicit point origin: avoid depending on large-part surface distance semantics.
	local anchor = Instance.new("Attachment")
	anchor.Name, anchor.Parent = "ActionPoint", p
	q.Parent = anchor
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
	return r and (r.Position - p.Position).Magnitude <= 9
end
local function trapAction(actor, stage, position, kind)
	local r = root(actor)
	local s = states[actor]
	if s then
		s.trapActor = actor
		s.trapRoot = function()
			return root(actor)
		end
	end
	return Traps.action(traps, actor, states[actor], arena, r and r.Position, stage, position, os.clock(), kind)
end

local function update(player, text)
	local s = states[player]
	player:SetAttribute("GreyboxGoal", text)
	player:SetAttribute("GreyboxCarry", s and s.item ~= nil or false)
	player:SetAttribute("GreyboxPhase", s and s.phase or "Home")
end

local function goal(actor, text)
	if actor:IsA("Player") then
		update(actor, text)
	end
end
local function publish(actor)
	local s = states[actor]
	actor:SetAttribute("GreyboxTrapUnlocked", s and Traps.unlocked(traps, actor, s) or false)
	actor:SetAttribute(
		"GreyboxTrapAvailable",
		s and s.phase == "Run" and s.trapCharge == true and not s.trapPickedUp and not s.item or false
	)
	actor:SetAttribute("GreyboxMeadowEscapes", s and s.meadowEscapes or 0)
	actor:SetAttribute(
		"GreyboxTrapCooldownUntil",
		workspace:GetServerTimeNow() + math.max(0, (s and s.trapCooldown or 0) - os.clock())
	)
	actor:SetAttribute("GreyboxCarry", s and s.item ~= nil or false)
	actor:SetAttribute("GreyboxPhase", s and s.phase or "Home")
	actor:SetAttribute("GreyboxMercyUntil", s and s.mercy or 0)
	actor:SetAttribute("GreyboxShieldUntil", s and s.shield or 0)
end
local function visual(item)
	if not item.visual then
		item.visual = part(world, Config.ItemName, Vector3.new(2.5, 2.5, 2.5), Vector3.zero, orange)
		item.visual.Material = Enum.Material.Neon
		item.visual.CanCollide, item.visual.CanQuery, item.visual.Massless = false, false, true
		item.visual:SetAttribute("LootId", item.id)
		item.caption = label(item.visual, Config.ItemName)
		item.caption.Parent.AlwaysOnTop, item.caption.Parent.MaxDistance = false, 32
	end
	local p = item.visual
	if item.weld then
		item.weld:Destroy()
		item.weld = nil
	end
	p.Anchored, p.Parent, p.Transparency = true, world, 0
	if item.state == "Carried" or item.state == "Secured" then
		local r = root(item.holder)
		if r then
			p.Parent, p.CFrame, p.Anchored = item.holder.Character, r.CFrame * CFrame.new(0, 3.5, 0), false
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1, w.Parent = r, p, p
			item.weld = w
		end
	elseif item.state == "Nest" or item.state == "Dropped" then
		p.Position = item.position + Vector3.new(0, 1.4, 0)
		p.Transparency = item.recoverAt and 1 or 0
	elseif item.state == "Placed" then
		p.Size = Vector3.new(3, 3, 3)
		p.CFrame = CFrame.new(item.position) * CFrame.Angles(0, math.rad(item.rotation or 0), 0)
	elseif item.state == "Retired" then
		p:Destroy()
		item.visual = nil
	end
	if p.Parent then
		p:SetAttribute("LootState", item.state)
	end
	for actor in states do
		publish(actor)
	end
end
local function conservation()
	Rules.audit(rules)
	local count = {}
	for _, p in workspace:GetDescendants() do
		if p:IsA("BasePart") then
			local id = p:GetAttribute("LootId")
			if id and rules.items[id] then
				count[id] = (count[id] or 0) + 1
			end
		end
	end
	for id, item in rules.items do
		assert((count[id] or 0) == (item.state == "Retired" and 0 or 1), "physical LOOT duplication/loss " .. id)
	end
	return true
end
local portal = Scene.home(world, part, label)
Scene.skyIslands(world, part)
Scene.surroundings(world, Vector3.new(Config.MeadowX, Config.MeadowHeight, Config.MeadowZ), part)
local spawn = Instance.new("SpawnLocation")
spawn.Name, spawn.Size, spawn.Position = "HomeSpawn", Vector3.new(10, 1, 10), Vector3.new(0, 0.5, Config.HomeSpawnZ)
spawn.Anchored, spawn.Neutral, spawn.Duration, spawn.Parent = true, true, 0, world
spawn.Transparency, spawn.CanCollide = 1, false
local enter = prompt(portal, "Enter", "Meadow")
local function captureCams()
	Scene.captureCams(
		world,
		SSS:GetAttribute("GreyboxCaptureCams") == true,
		Vector3.new(Config.MeadowX, Config.MeadowHeight, Config.MeadowZ)
	)
end
SSS:GetAttributeChangedSignal("GreyboxCaptureCams"):Connect(captureCams)
captureCams()
local function population()
	local n = 0
	for _, s in states do
		if s.phase == "Run" then
			n += 1
		end
	end
	return n
end
local function refreshLoot()
	if not arena then
		return
	end
	local item = rules.active
	world:SetAttribute("EscapeDeadline", item and item.escapeClock or nil)
	world:SetAttribute("EscapeItemId", item and item.escapeDeadline and item.id or nil)
	arena.steal.Enabled = item ~= nil and item.state == "Nest"
	arena.grab.Enabled = item ~= nil and item.state == "Dropped" and os.clock() >= item.settle
	if item and item.state == "Dropped" then
		arena.groundAction.Position = item.position + Vector3.new(0, 1.5, 0)
	end
	for _, s in states do
		if s.bump then
			s.bump.Enabled = s.phase == "Run" and s.item ~= nil and s.item.state == "Carried"
		end
	end
end
local function dropPosition(actor)
	local r = root(actor)
	local last = states[actor] and states[actor].lastSocket
	return arena and Arena.dropSocket(arena, r and r.Position or last or Arena.position(arena, 0, 8, 32))
end
local function presentDrop(item, actor)
	local r = root(actor)
	local now = os.clock()
	if r and Arena.outside(arena, r.Position) then
		item.recoverAt = now + 1
		item.settle = item.recoverAt + Config.SettleSeconds
		item.bounceAt = nil
	else
		item.recoverAt, item.bounceAt = nil, now
	end
	visual(item)
end
local function recoverFallenLoot(item, now)
	if not item.recoverAt or now < item.recoverAt then
		return
	end
	item.recoverAt, item.bounceAt = nil, now
	visual(item)
	local effect =
		part(world, "TreasureRecoveryPoof", Vector3.new(2, 2, 2), item.position + Vector3.new(0, 1.4, 0), orange)
	effect.Shape, effect.Material = Enum.PartType.Ball, Enum.Material.Neon
	effect.CanCollide, effect.CanQuery = false, false
	TweenService:Create(effect, TweenInfo.new(1), { Size = Vector3.new(6, 6, 6), Transparency = 1 }):Play()
	Debris:AddItem(effect, 1)
end
local function expireLoot(now)
	local expired, item = Rules.expire(rules, now)
	if expired then
		visual(item)
		Traps.clearIsland(traps, arena)
		Arena.reset(arena)
		for actor, s in states do
			if s.phase == "Run" then
				goal(actor, "Time up / treasure lost / new treasure in 3s")
			end
		end
		refreshLoot()
		conservation()
	end
	return expired
end
local function drop(actor, reason)
	expireLoot(os.clock())
	local ok, item = Rules.drop(rules, actor, os.clock(), dropPosition(actor))
	if ok then
		presentDrop(item, actor)
		goal(actor, Config.ItemName .. " DROPPED / Grab after settle")
		refreshLoot()
		if testLog then
			testLog("production drop " .. item.id .. " cause=" .. tostring(reason or "reset/disconnect/cleanup"))
		end
	end
	return ok
end
local function hit(actor, from, source)
	local r = root(actor)
	if not r or Arena.safe(arena, r.Position) then
		return false
	end
	local s, item = states[actor], states[actor].item
	local ok, retained = Rules.hit(rules, actor, source or "Guardian", os.clock(), dropPosition(actor))
	if not ok then
		return false
	end
	s.catches = (s.catches or 0) + 1
	local away = Vector3.new(r.Position.X - from.X, 0, r.Position.Z - from.Z)
	if away.Magnitude > 0 then
		local movement = away.Unit * Config.GuardianKnockback
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { actor.Character }
		local collision = workspace:Blockcast(r.CFrame, Vector3.new(2, 4, 2), movement, params)
		local distance = collision and math.max(0, collision.Distance - 0.5) or Config.GuardianKnockback
		r.CFrame += away.Unit * distance
	end
	if item then
		if item.state == "Dropped" then
			presentDrop(item, actor)
		else
			visual(item)
		end
	end
	goal(
		actor,
		retained and "Stumble / first hit: kept " .. Config.ItemName
			or Config.ItemName .. " DROPPED / " .. Config.MercySeconds .. "s mercy"
	)
	publish(actor)
	refreshLoot()
	if testLog then
		testLog("production hit " .. tostring(source or "Guardian") .. " retained=" .. tostring(retained))
	end
	return true
end
local function check(actor, action, target, item)
	local r = root(actor)
	if not arena or not r or states[actor].run ~= arena or Arena.safe(arena, r.Position) then
		return false, "arena/safe"
	end
	if action == "Bump" then
		local victim = states[target]
		local v = victim and root(target)
		if not v or victim.run ~= arena or Arena.safe(arena, v.Position) then
			return false, "victim/safe"
		end
		return (r.Position - v.Position).Magnitude <= 4 and math.abs(r.Position.Y - v.Position.Y) <= 3 and Arena.sight(
			arena,
			r.Position,
			v.Position
		),
			"Bump range/sight/height"
	end
	local position = item.position + Vector3.new(0, 1.5, 0)
	return (r.Position - position).Magnitude <= (action == "Steal" and 9 or 4) and Arena.sight(
		arena,
		r.Position,
		position
	),
		"item range/sight"
end
local function bumpTarget(actor)
	local r = root(actor)
	if not r then
		return nil
	end
	local nearest, distance = nil, 4.001
	for other, s in states do
		local v = root(other)
		if other ~= actor and s.item and s.phase == "Run" and v then
			local d = (r.Position - v.Position).Magnitude
			if d < distance then
				nearest, distance = other, d
			end
		end
	end
	return nearest
end
local function holdAction(actor, action, stage)
	expireLoot(os.clock())
	if testLog then
		testLog("hold " .. action .. " / " .. stage)
	end
	local s = states[actor]
	if not s then
		return false, "no state"
	end
	if stage == "cancel" then
		s.hold = nil
		return true
	end
	if stage == "begin" then
		local target = action == "Bump" and bumpTarget(actor) or nil
		local now = os.clock()
		local ok, why = Rules.begin(rules, actor, action, target, now, check)
		if ok and target then
			s.combatUntil, states[target].combatUntil = now + 2, now + 2
		end
		return ok, why
	end
	if stage ~= "finish" then
		return false, "invalid stage"
	end
	local hold = s.hold
	if hold and hold.action == action then
		local remainder = Config.HoldSeconds[action] - (os.clock() - hold.began)
		if remainder > 0 and remainder < 0.2 then
			task.wait(remainder)
		end
	end
	expireLoot(os.clock())
	local oldItem = rules.active
	local oldPosition = oldItem and oldItem.position
	local target = s.hold and s.hold.target
	local ok, result = Rules.finish(rules, actor, action, os.clock(), check, dropPosition)
	if not ok then
		return false, result
	end
	if action == "Bump" then
		local v = root(target)
		if v then
			local from = root(actor).Position
			local delta = Vector3.new(v.Position.X - from.X, 0, v.Position.Z - from.Z)
			if delta.Magnitude > 0 then
				local movement = delta.Unit * 3.5
				local obstruction = workspace:Blockcast(v.CFrame, Vector3.new(2, 4, 2), movement, arena.params)
				v.CFrame += delta.Unit * (obstruction and math.max(0, obstruction.Distance - 0.5) or 3.5)
			end
		end
		goal(target, Config.ItemName .. " DROPPED")
	else
		s.trapPickedUp, s.trapHold = true, nil
		s.lastSocket = oldPosition or s.lastSocket
		if not oldItem.eventTimestamp then
			oldItem.eventTimestamp = workspace:GetServerTimeNow()
			oldItem.escapeClock = oldItem.eventTimestamp + math.max(0, oldItem.escapeDeadline - os.clock())
			oldItem.baseOutcome = "GreyboxPlaceholder" -- No economy or reward reroll in T1.
		end
		goal(actor, Config.ItemName .. " is yours when you escape. RUN!")
		if action == "Steal" then
			Arena.warn(arena, actor, os.clock())
		end
	end
	if action == "Bump" then
		presentDrop(oldItem, target)
	else
		visual(oldItem)
	end
	refreshLoot()
	Rules.audit(rules)
	return true
end
local function bindHold(q, action)
	q.PromptButtonHoldBegan:Connect(function(actor)
		if not testRunning then
			holdAction(actor, action, "begin")
		end
	end)
	q.PromptButtonHoldEnded:Connect(function(actor)
		local s = states[actor]
		local held = s and s.hold
		task.delay(0.2, function()
			if s and s.hold == held then
				s.hold = nil
			end
		end)
	end)
	q.Triggered:Connect(function(actor)
		if not testRunning then
			holdAction(actor, action, "finish")
		end
	end)
end
local function home(actor)
	local s = states[actor]
	Traps.remove(traps, actor)
	s.trapHold = nil
	s.run, s.hold = nil, nil
	if actor.Character then
		local pen = s.item and pens[s.slot]
		actor.Character:PivotTo(pen and CFrame.new(pen.gate) or CFrame.new(0, 6, Config.HomeSpawnZ))
	end
	if s.item then
		visual(s.item)
	end
	publish(actor)
	goal(actor, s.item and "Secured / choose a free plot spot / Place, Rotate, Snap" or "Enter the central portal")
end
local function returnRun(actor, automatic)
	expireLoot(os.clock())
	local s, r = states[actor], root(actor)
	if
		not s
		or s.phase ~= "Run"
		or not r
		or not arena
		or (not Arena.safe(arena, r.Position) and not (not automatic and near(actor, arena.dock)))
	then
		return false, "return boundary/phase"
	end
	local ok, why = Rules.secure(rules, actor, os.clock())
	if ok then
		if s.item and s.item.state == "Secured" then
			-- RAM-only greybox progression; production unlock requires durable awards.
			s.meadowEscapes = (s.meadowEscapes or 0) + 1
		end
		print(
			string.format(
				"[Greybox] return source=%s boundary=%s position=%s item=%s",
				automatic and "protected apron" or "return action",
				tostring(Arena.safe(arena, r.Position)),
				tostring(r.Position),
				s.item and (s.item.id .. "/" .. s.item.state) or "empty"
			)
		)
		home(actor)
		refreshLoot()
		Rules.audit(rules)
	end
	return ok, why
end
local function placeItem(actor, slot, position, rotation)
	local s, pen = states[actor], pens[slot]
	local r = root(actor)
	if not s or not pen or s.slot ~= slot or not r then
		return false, "plot owner"
	end
	if typeof(position) ~= "Vector3" or type(rotation) ~= "number" then
		return false, "placement required"
	end
	local valid, extent = Placement.validate(Config, slot, position.X, position.Z, rotation, pen.occupied)
	if not valid then
		return false, extent
	end
	if position.Y ~= position.Y or math.abs(position.Y - 0.2) > 0.05 or (r.Position - position).Magnitude > 24 then
		return false, "floor/range"
	end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { pen.base }
	local floor = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -4, 0), params)
	if not floor or math.abs(floor.Position.Y - position.Y) > 0.05 then
		return false, "plot floor"
	end
	local ok, item = Rules.place(rules, actor)
	if not ok then
		return false, item
	end
	pen.count += 1
	item.position = Vector3.new(position.X, 1.7, position.Z)
	item.rotation = rotation % 360
	item.penSlot = slot
	table.insert(pen.occupied, { x = position.X, z = position.Z, extent = extent })
	visual(item)
	item.visual.Name = "Placed_" .. item.id
	item.visual:SetAttribute("PenSlot", slot)
	item.visual:SetAttribute("PlacementX", position.X)
	item.visual:SetAttribute("PlacementZ", position.Z)
	item.visual:SetAttribute("PlacementExtent", extent)
	goal(actor, "Placed / enter for another run")
	publish(actor)
	Rules.audit(rules)
	return true
end
for i = 1, 8 do
	local x, z = Placement.center(i)
	local base =
		part(world, "Pen" .. i, Vector3.new(64, 0.2, 48), Vector3.new(x, 0.1, z), Color3.fromRGB(100, 115, 100))
	base:SetAttribute("SurfaceRole", "Floor")
	Scene.pen(world, x, z, part)
	local marker =
		part(world, "PenMarker" .. i, Vector3.new(2, 3, 2), Vector3.new(x + (x < 0 and 32 or -32), 1.5, z + 8), orange)
	marker.CanCollide = false
	pens[i] = {
		base = base,
		marker = marker,
		text = label(marker, "Pen " .. i .. " / vacant"),
		count = 0,
		occupied = {},
		gate = Vector3.new(x < 0 and -16 or 16, 4, z),
	}
end
local function assemble()
	session += 1
	local override = SSS:GetAttribute("GreyboxSeed")
	local fixed = type(override) == "number" and override > 0 and override < 2147483647 and override % 1 == 0
	local seed = fixed and override
		or (Config.SessionSeed + 1009 + session * 9176 + Config.RecipeVersion * 31) % 2147483647
	local layout
	for retry = 1, 8 do
		local ok, value = pcall(function()
			local candidate = Layout.assemble(Config, seed + retry - 1, session == 1 and not fixed)
			Layout.validate(Config, candidate)
			return candidate
		end)
		if ok then
			layout = value
			break
		else
			warn("[Greybox] recipe rejected: " .. tostring(value))
		end
	end
	if not layout then
		layout = Layout.assemble(Config, 101, true)
		Layout.validate(Config, layout)
	end
	arena = Arena.build(world, layout, part, label)
	arena.nest = part(arena.model, "NestAction", Vector3.new(1, 1, 1), Arena.position(arena, 0, 5.5, 32), orange)
	arena.nest.Transparency, arena.nest.CanCollide, arena.nest.CanQuery = 1, false, false
	arena.steal = prompt(arena.nest, "Steal", Config.ItemName, Config.HoldSeconds.Steal)
	bindHold(arena.steal, "Steal")
	arena.groundAction = part(arena.model, "GroundAction", Vector3.new(1, 1, 1), arena.nest.Position)
	arena.groundAction.Transparency, arena.groundAction.CanCollide, arena.groundAction.CanQuery = 1, false, false
	arena.grab = prompt(arena.groundAction, "Grab", Config.ItemName, Config.HoldSeconds.Grab)
	arena.grab.MaxActivationDistance = 4
	bindHold(arena.grab, "Grab")
	local back = prompt(arena.dock, "Return", "Home")
	back.Triggered:Connect(function(actor)
		if not testRunning then
			returnRun(actor)
		end
	end)
	visual(Rules.spawn(rules, Arena.position(arena, 0, 8, 32)))
	refreshLoot()
	print("[Greybox] shared arena: " .. Layout.signature(layout))
end
assemble() -- The floating Meadow is visible from home before the first entry.
local function enterRun(actor)
	local s = states[actor]
	if not s or s.phase ~= "Home" or s.item or not near(actor, portal) or (s.slot and pens[s.slot].count >= 8) then
		return false, "enter phase/range/cargo/full pen"
	end
	if
		not testRunning
		and (SSS:GetAttribute("GreyboxLoopTestSuccess") ~= true or SSS:GetAttribute("GreyboxPvpTestSuccess") ~= true)
	then
		goal(actor, "Locked / run GreyboxLoopTest AND GreyboxPvpTest in Server attributes")
		return false, "runtime gates not passed"
	end
	if population() >= Config.Capacity then
		return false, "shared island full (8)"
	end
	if not arena then
		assemble()
	elseif arena.idle then
		-- Keep the empty island visible; shuffle only when the next run begins.
		arena.model:Destroy()
		assemble()
	end
	arena.hasEntrants = true
	s.phase, s.run, s.counter, s.started, s.mercy, s.catches =
		"Run", arena, (s.counter or 0) + 1, os.clock(), os.clock() + Config.MercySeconds, 0
	Traps.entry(traps, actor, s)
	local arrivals = { -12, 0, 12 }
	s.lastSafe = Arena.position(arena, arrivals[((population() - 1) % 3) + 1], 3, -58)
	actor.Character:PivotTo(CFrame.new(Arena.position(arena, arrivals[((population() - 1) % 3) + 1], 4, -58)))
	publish(actor)
	goal(actor, "Choose a route / hold Steal at " .. Config.ItemName .. " / escape commits ownership")
	return true
end
enter.Triggered:Connect(function(actor)
	if not testRunning then
		enterRun(actor)
	end
end)
local lastAction = {}
actionRemote.OnServerEvent:Connect(function(actor, action, stage, rotation)
	if testRunning or type(action) ~= "string" then
		return
	end
	local now = os.clock()
	if now - (lastAction[actor] or 0) < 0.08 and stage ~= "cancel" then
		return
	end
	lastAction[actor] = now
	local ok, why
	if action == "Trap" then
		ok, why = trapAction(actor, stage, rotation)
	elseif action == "TrapRecall" then
		ok, why = trapAction(actor, "recall")
	elseif Config.HoldSeconds[action] then
		ok, why = holdAction(actor, action, stage)
	elseif action == "Enter" then
		ok, why = enterRun(actor)
	elseif action == "Return" then
		ok, why = returnRun(actor)
	elseif action == "Place" then
		ok, why = placeItem(actor, states[actor] and states[actor].slot, stage, rotation)
	else
		return
	end
	actionRemote:FireClient(actor, ok, why)
end)
local function configureCharacter(actor, character)
	local r = character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Humanoid")
	local s = states[actor]
	if not s then
		return
	end
	-- Last legal danger socket survives the destroyed character; no provisional home escrow.
	if s.phase == "Run" then
		local item = s.item
		if item then
			local ok = Rules.drop(
				rules,
				actor,
				os.clock(),
				Arena.dropSocket(arena, s.lastSocket or Arena.position(arena, 0, 8, 32))
			)
			if ok then
				visual(item)
			end
		end
		s.phase = "Home"
	end
	for _, p in character:GetDescendants() do
		if p:IsA("BasePart") then
			p.CollisionGroup = "GreyboxPlayers"
		end
	end
	character.DescendantAdded:Connect(function(p)
		if p:IsA("BasePart") then
			p.CollisionGroup = "GreyboxPlayers"
		end
	end)
	if s.bump then
		s.bump:Destroy()
	end
	s.bump = prompt(r, "Bump", "Carrier", Config.HoldSeconds.Bump)
	s.bump.MaxActivationDistance, s.bump.RequiresLineOfSight = 4, true
	s.bump:SetAttribute("CarrierUserId", actor.UserId)
	bindHold(s.bump, "Bump")
	home(actor)
	actor:SetAttribute("GreyboxReady", true)
	refreshLoot()
end
local function addPlayer(actor)
	if states[actor] then
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
		actor:SetAttribute("GreyboxGoal", "Eight home pens occupied")
		return
	end
	slots[slot], firstPlayer = actor, firstPlayer or actor
	local s = Rules.actor(rules, actor)
	s.slot, s.counter, s.joined = slot, 0, os.clock()
	pens[slot].text.Text = "Pen " .. slot .. " / " .. actor.DisplayName
	actor:SetAttribute("GreyboxPen", slot)
	actor.CharacterAdded:Connect(function(character)
		configureCharacter(actor, character)
	end)
	actor.CharacterRemoving:Connect(function()
		Traps.remove(traps, actor)
		s.trapHold = nil
		if s.phase == "Run" and s.item then
			drop(actor)
		end
		if s.item and s.item.state == "Secured" and s.item.visual then
			if s.item.weld then
				s.item.weld:Destroy()
				s.item.weld = nil
			end
			s.item.visual.Parent, s.item.visual.Anchored = world, true
			s.item.visual.Position = Vector3.new(0, 3, Config.HomeSpawnZ)
		end
		s.phase, s.run, s.hold = "Home", nil, nil
		actor:SetAttribute("GreyboxReady", false)
	end)
	if actor.Character then
		task.spawn(configureCharacter, actor, actor.Character)
	end
end
Players.PlayerAdded:Connect(addPlayer)
for _, actor in Players:GetPlayers() do
	addPlayer(actor)
end
Players.PlayerRemoving:Connect(function(actor)
	Traps.remove(traps, actor)
	local s = states[actor]
	if not s then
		return
	end
	if s.phase == "Run" and s.item then
		drop(actor)
	end
	if s.item then
		s.item.state, s.item.holder = "Retired", nil
		visual(s.item)
		s.item = nil
	end
	for _, item in rules.items do
		if item.visual and item.visual:GetAttribute("PenSlot") == s.slot then
			item.state = "Retired"
			visual(item)
		end
	end
	pens[s.slot].count, pens[s.slot].text.Text = 0, "Pen " .. s.slot .. " / vacant"
	pens[s.slot].occupied = {}
	slots[s.slot], states[actor], lastAction[actor] = nil, nil, nil
end)
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.05 then
		return
	end
	local step, now = math.min(accumulator, 0.15), os.clock()
	accumulator = 0
	for _, item in rules.items do
		if item.state == "Placed" and item.visual then
			local drift = Config.PetsWander and Vector3.new(math.sin(now * 0.7) * 0.25, 0, math.cos(now * 0.7) * 0.25)
				or Vector3.zero
			item.visual.CFrame = CFrame.new(
				item.position + drift + Vector3.new(0, math.abs(math.sin(now * 2)) * 0.15, 0)
			) * CFrame.Angles(0, math.rad(item.rotation or 0), 0)
		end
	end
	expireLoot(now)
	for actor, s in states do
		local r, h = root(actor)
		if not r then
			continue
		end
		h.UseJumpPower, h.JumpHeight = false, s.item and Config.CarryJumpHeight or Config.JumpHeight
		h.WalkSpeed = now < (s.slowUntil or 0) and Config.StumbleSpeed
			or (s.item and Config.CarrySpeed or Config.WalkSpeed)
		if s.phase ~= "Run" or not arena then
			continue
		end
		if Arena.outside(arena, r.Position) then
			if s.item then
				drop(actor, "outside island fall/recovery")
			end
			actor.Character:PivotTo(CFrame.new(s.lastSafe or Arena.position(arena, 0, 3, -58)))
			r.AssemblyLinearVelocity, r.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			continue
		end
		if s.item and Arena.safe(arena, r.Position) then
			returnRun(actor, true)
			continue
		end
		local socket = Arena.dropSocket(arena, r.Position)
		if h.FloorMaterial ~= Enum.Material.Air then
			local floor = Arena.floor(arena, r.Position)
			if floor and math.abs(r.Position.Y - floor.Y - 3) < 1 and (socket - floor).Magnitude < 3 then
				s.lastSafe = socket + Vector3.new(0, 3, 0)
			end
		end
		if socket then
			s.lastSocket = socket
		end
		if s.hold then
			local hold = s.hold
			local ok = Rules.eligible(rules, actor, hold.action, hold.target, now, check)
			if not ok or rules.active ~= hold.item or hold.item.version ~= hold.version then
				s.hold = nil
			end
		end
		if s.item then
			if
				arena.target == actor
				or (arena.attack and arena.attack.actor == actor)
				or now < (s.combatUntil or 0)
			then
				s.idleAt = now
			end
			if not s.lastPosition or (r.Position - s.lastPosition).Magnitude > 0.4 then
				s.idleAt, s.lastPosition = now, r.Position
			end
			if now - (s.idleAt or now) > 10 then
				goal(actor, Config.ItemName .. " drops in 2s / move!")
				if now - s.idleAt > 12 then
					drop(actor, "idle 10s + warning 2s")
				end
			end
		end
		-- Shared blue mercy pulse and bounded FIRST RUN label on the single item.
		if s.item and s.item.visual then
			s.item.visual.Color = now < s.mercy and Color3.fromRGB(80, 160, 255) or orange
			s.item.caption.Text = Config.ItemName .. (now < s.shield and " / FIRST RUN" or "")
		end
		publish(actor)
	end
	if not arena then
		return
	end
	if population() == 0 and not testRunning then
		if arena.hasEntrants and not arena.idle then
			Traps.clearIsland(traps, arena)
			Rules.retire(rules)
			for _, item in rules.items do
				if item.state == "Retired" and item.visual then
					visual(item)
				end
			end
			arena.idle = true
		end
		return
	end
	if not rules.active and now >= (rules.respawnAt or math.huge) then
		visual(Rules.spawn(rules, Arena.position(arena, 0, 8, 32)))
		arena.mode, arena.target = "Guard", nil
	end
	if rules.active and rules.active.state == "Dropped" then
		recoverFallenLoot(rules.active, now)
	end
	if rules.active and rules.active.state == "Dropped" and rules.active.bounceAt then
		local item = rules.active
		local t = math.min(1, (now - item.bounceAt) / Config.SettleSeconds)
		item.visual.Position = item.position + Vector3.new(0, 1.4 + math.sin(t * math.pi) * 0.7, 0)
		if t >= 1 then
			item.bounceAt = nil
		end
	end
	Traps.tick(traps, now, states)
	if not pvpCourtPaused then
		Arena.tick(arena, step, now, states, root, hit, goal, rules.active)
	end
	refreshLoot()
	local ok, why = pcall(conservation)
	SSS:SetAttribute("GreyboxConservation", ok and "PASS" or "FAIL: " .. tostring(why))
	if not ok then
		for _, mode in { "GreyboxLoopTest", "GreyboxPvpTest" } do
			SSS:SetAttribute(mode .. "Success", false)
			SSS:SetAttribute(mode .. "Result", "FAIL: conservation " .. tostring(why))
			warn("[" .. mode .. "] conservation FAIL " .. tostring(why))
		end
	end
end)
local api = {
	traps = traps,
	trapAction = trapAction,
	enterRun = enterRun,
	holdAction = holdAction,
	returnRun = returnRun,
	returnInRange = function(actor)
		return arena and near(actor, arena.dock)
	end,
	placeItem = placeItem,
	root = root,
	floor = function(position)
		return Arena.floor(arena, position)
	end,
	rules = rules,
	audit = function()
		conservation()
	end,
	arena = function()
		return arena
	end,
}
-- A test-only dummy actor uses the exact same authoritative hold/hit/item functions.
function api.dummy(position)
	local character = Instance.new("Model")
	character.Name, character.Parent = "PvpDummy", world
	local r = part(character, "HumanoidRootPart", Vector3.new(2, 2, 1), position)
	r.Anchored, r.CanCollide, r.Transparency, r.CollisionGroup = false, true, 1, "GreyboxPlayers"
	local torso = part(character, "Torso", Vector3.new(2, 2, 1), position)
	torso.Anchored, torso.CollisionGroup = false, "GreyboxPlayers"
	local function joint(name, a, b, offset)
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1, motor.C0, motor.Parent = name, a, b, CFrame.new(offset), a
	end
	joint("RootJoint", r, torso, Vector3.zero)
	for _, definition in
		{
			{ "Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0), "Neck" },
			{ "Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0), "Left Shoulder" },
			{ "Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0), "Right Shoulder" },
			{ "Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0), "Left Hip" },
			{ "Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0), "Right Hip" },
		}
	do
		local limb = part(character, definition[1], definition[2], position + definition[3])
		limb.Anchored, limb.CanCollide, limb.CollisionGroup = false, false, "GreyboxPlayers"
		joint(definition[4], torso, limb, definition[3])
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck, humanoid.HipHeight, humanoid.Parent = false, 0, character
	character.PrimaryPart = r
	local actor = { Character = character, UserId = -1 }
	local attributes = {}
	function actor:SetAttribute(key, value)
		attributes[key] = value
	end
	function actor:GetAttribute(key)
		return attributes[key]
	end
	function actor:IsA()
		return false
	end
	local s = Rules.actor(rules, actor)
	s.phase, s.run, s.joined = "Run", arena, os.clock()
	r:SetNetworkOwner(nil)
	return actor
end
function api.pvpCourt(enabled)
	assert(testRunning, "court isolation requires active Studio test")
	pvpCourtPaused = enabled
	if enabled then
		Arena.reset(arena) -- Cancel in-flight pokes/throws and pending paths.
		arena.guardian.CFrame = CFrame.new(
			Arena.position(
				arena,
				Config.GuardianGuardOffset.x,
				Config.GuardianGuardOffset.y + 5.5,
				Config.GuardianGuardOffset.z
			)
		)
	end
end
function api.removeDummy(actor)
	Traps.remove(traps, actor)
	local s = states[actor]
	if s and s.item then
		drop(actor)
	end
	states[actor] = nil
	actor.Character:Destroy()
end
local function startTest(mode)
	if testRunning then
		return
	end
	testRunning = true
	SSS:SetAttribute(mode .. "Success", false)
	SSS:SetAttribute(mode .. "Result", "RUNNING")
	task.spawn(function()
		local player, dummy
		local function snapshot(actor, name)
			local r, h
			if actor then
				r, h = root(actor)
			end
			-- Logical and physical state together distinguish range misses from legal drops.
			local s = actor and states[actor]
			if not r or not s then
				return name .. "=missing"
			end
			local p = arena and s.phase == "Run" and r.Position - arena.origin or r.Position
			return string.format(
				"%s pos=(%.2f,%.2f,%.2f) phase=%s carry=%s item=%s shield=%.2f mercy=%.2f floor=%s speed=%.1f",
				name,
				p.X,
				p.Y,
				p.Z,
				s.phase,
				tostring(s.item ~= nil),
				s.item and (s.item.id .. "/" .. s.item.state) or "none",
				math.max(0, s.shield - os.clock()),
				math.max(0, s.mercy - os.clock()),
				h.FloorMaterial.Name,
				h.WalkSpeed
			)
		end
		local function log(message)
			local item = rules.active
			print(
				"["
					.. mode
					.. "] "
					.. message
					.. " | "
					.. snapshot(player, "player")
					.. (dummy and (" | " .. snapshot(dummy, "dummy")) or "")
					.. " | active="
					.. (item and (item.id .. "/" .. item.state) or "none")
			)
		end
		testLog = log
		local ok, result = pcall(function()
			local deadline = os.clock() + 8
			repeat
				player = firstPlayer
				if player and player:GetAttribute("GreyboxReady") then
					break
				end
				task.wait(0.1)
			until os.clock() >= deadline
			assert(player and player:GetAttribute("GreyboxReady"), "player not ready >8s")
			player:SetAttribute("GreyboxLoopTesting", true)
			local runner = require(SSS:WaitForChild("GreyboxLoopTestRunner"))
			if mode == "GreyboxTrapTest" then
				return require(SSS:WaitForChild("GreyboxTrapTestRunner")).run(player, states, api, log)
			end
			if mode == "GreyboxPvpTest" then
				return runner.pvp(player, states, pens, world, api, log, function(value)
					dummy = value
				end)
			end
			local runs = SSS:GetAttribute("GreyboxLoopTestRuns") or 3
			assert(type(runs) == "number" and runs >= 3 and runs % 1 == 0, "GreyboxLoopTestRuns must be an integer >=3")
			local passed, expiries = 0, 0
			SSS:SetAttribute("GreyboxLoopTestPassCount", 0)
			SSS:SetAttribute("GreyboxLoopTestExpiryCount", 0)
			for i = 1, runs do
				log("loop " .. i .. "/" .. runs .. " START")
				local loopOk, detail, outcome = pcall(runner.run, player, states, pens, world, api, log)
				if not loopOk then
					error(passed .. "/" .. runs .. " passed; loop " .. i .. " harness error: " .. tostring(detail))
				end
				passed += 1
				expiries += outcome == "expiry" and 1 or 0
				SSS:SetAttribute("GreyboxLoopTestPassCount", passed)
				SSS:SetAttribute("GreyboxLoopTestExpiryCount", expiries)
				log("loop " .. i .. "/" .. runs .. " PASS: " .. detail)
			end
			return passed
				.. "/"
				.. runs
				.. " passed; "
				.. expiries
				.. " legal expiries; "
				.. (passed - expiries)
				.. " placed"
		end)
		log((ok and "PASS: " or "FAIL: ") .. tostring(result))
		pvpCourtPaused = false -- Always restore on success or failure.
		testLog = nil
		if dummy then
			api.removeDummy(dummy)
		end
		if player then
			player:SetAttribute("GreyboxLoopTesting", false)
			local r, h = root(player)
			if r then
				h:Move(Vector3.zero, false)
				pcall(function()
					r:SetNetworkOwnershipAuto()
				end)
			end
		end
		testRunning = false
		SSS:SetAttribute(mode, false)
		SSS:SetAttribute(mode .. "Success", ok)
		SSS:SetAttribute(mode .. "Result", (ok and "PASS: " or "FAIL: ") .. tostring(result))
	end)
end
for _, mode in { "GreyboxLoopTest", "GreyboxPvpTest", "GreyboxTrapTest" } do
	SSS:GetAttributeChangedSignal(mode):Connect(function()
		if SSS:GetAttribute(mode) then
			startTest(mode)
		end
	end)
end
SSS:GetAttributeChangedSignal("GreyboxSelfTest"):Connect(function()
	if SSS:GetAttribute("GreyboxSelfTest") then
		local ok, why = pcall(Layout.selfTest, Config, print)
		SSS:SetAttribute("GreyboxSelfTestResult", ok and "PASS" or tostring(why))
		SSS:SetAttribute("GreyboxSelfTest", false)
	end
end)
