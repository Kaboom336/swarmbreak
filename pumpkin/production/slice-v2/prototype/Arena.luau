local Pathfinding = game:GetService("PathfindingService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxConfig"))
local Layout = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxLayout"))
local Scene = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxScene"))
local Arena = {}
function Arena.fx(a, name, position, radius)
	local event = game:GetService("ReplicatedStorage"):WaitForChild("MeadowKeeper"):FindFirstChild("FXEvent")
	if event then
		event:FireAllClients(a.guardian, name, position, radius)
	end
end
local detectRange, throwRange = Config.GuardianDetectRange, Config.GuardianThrowRange
local leashRadius, stuckSeconds, returnSeconds =
	Config.GuardianLeashRadius, Config.GuardianStuckSeconds, Config.GuardianReturnSeconds
local campOffset =
	Vector3.new(Config.GuardianGuardOffset.x, Config.GuardianGuardOffset.y, -Config.GuardianGuardOffset.z)
function Arena.dashLegal(a, position)
	if Config.MeadowV4 then
		local p = position - a.origin
		if require(game:GetService("ReplicatedStorage").MeadowV4.TunnelPolicy).inside(p.X, p.Y, p.Z) then
			return false
		end
	end
	local camp = a.guardCamp or a.origin + campOffset
	return Vector3.new(position.X - camp.X, 0, position.Z - camp.Z).Magnitude <= leashRadius
end
local cyan, red = Color3.fromRGB(60, 210, 230), Color3.fromRGB(255, 40, 40)
local function vector(p)
	return Vector3.new(p.x, p.y, -p.z)
end
-- Map north (+local Z) points toward world -Z, keeping west on screen-left.
function Arena.position(a, x, y, z)
	return a.origin + Vector3.new(x, y, -z)
end
function Arena.build(world, layout, make, label)
	local model = Instance.new("Model")
	model.Name, model.Parent = "SharedIsland", world
	model:SetAttribute("Seed", layout.seed)
	model:SetAttribute("RecipeVersion", Config.RecipeVersion)
	model:SetAttribute("ArenaId", 1)
	model:SetAttribute("Difficulty", "Meadow")
	local a = {
		model = model,
		layout = layout,
		origin = Vector3.new(Config.MeadowX, Config.MeadowHeight, Config.MeadowZ),
		occupants = {},
		mode = "Guard",
		untilTime = 0,
		nextThrow = 0,
		nextPath = 0,
		points = {},
		index = 1,
		patrol = 1,
		chaseDistance = 0,
		chaseTicks = 0,
		throws = 0,
		impacts = 0,
		obstacles = {},
	}
	local chunks = {}
	for _, p in layout.pieces do
		local chunk = Instance.new("Model")
		chunk.Name, chunk.Parent = p.id, model
		chunk:SetAttribute("ChunkId", p.id)
		chunk:SetAttribute("Width", p.width)
		chunk:SetAttribute("Depth", p.depth)
		chunks[p] = chunk
		local ports = {
			{ "N", 0, p.depth / 2, 180 },
			{ "S", 0, -p.depth / 2, 0 },
			{ "E", p.width / 2, 0, -90 },
			{ "W", -p.width / 2, 0, 90 },
		}
		for _, port in ports do
			if not (p.id == "I01" and port[1] == "S") and not (p.id == "I02" and port[1] == "N") then
				local socket = Instance.new("Part")
				socket.Name, socket.Size, socket.Position =
					"Port" .. port[1], Vector3.new(12, 0.05, 1), Arena.position(a, p.x + port[2], 0, p.z + port[3])
				socket.Anchored, socket.Transparency, socket.CanCollide, socket.CanQuery, socket.Parent =
					true, 1, false, false, chunk
				local attachment = Instance.new("Attachment")
				attachment.Name, attachment.Orientation, attachment.Parent =
					"GroundPort", Vector3.new(0, port[4], 0), socket
				attachment:SetAttribute("Width", 12)
			end
		end
	end
	local function build(name, size, position, color, role)
		local p = make(model, name, size, Arena.position(a, position.X, position.Y, position.Z), color)
		if name ~= "IslandGround" and name ~= "RockUnderside" then
			for definition, chunk in chunks do
				if
					math.abs(position.X - definition.x) <= definition.width / 2
					and math.abs(position.Z - definition.z) <= definition.depth / 2
				then
					p.Parent = chunk
					break
				end
			end
		end
		p:SetAttribute("SurfaceRole", role or "Floor")
		if role == "Cover" then
			table.insert(a.obstacles, p)
		end
		return p
	end
	-- Tile the base around exact authored gully cutouts; no terrain/noise.
	local xs, zs = { -Config.IslandSize / 2, Config.IslandSize / 2 }, { -Config.IslandSize / 2, Config.IslandSize / 2 }
	for _, g in layout.gullies do
		table.insert(xs, g.x - g.w / 2)
		table.insert(xs, g.x + g.w / 2)
		table.insert(zs, g.z - g.d / 2)
		table.insert(zs, g.z + g.d / 2)
	end
	table.sort(xs)
	table.sort(zs)
	for i = 2, #xs do
		for j = 2, #zs do
			local x, z = (xs[i] + xs[i - 1]) / 2, (zs[j] + zs[j - 1]) / 2
			local hole = false
			for _, g in layout.gullies do
				if math.abs(x - g.x) < g.w / 2 and math.abs(z - g.z) < g.d / 2 then
					hole = true
				end
			end
			if not hole then
				build(
					"IslandGround",
					Vector3.new(xs[i] - xs[i - 1], 4, zs[j] - zs[j - 1]),
					Vector3.new(x, -2, z),
					Color3.fromRGB(115, 145, 110)
				)
			end
		end
	end

	for _, b in layout.solids do
		build(
			b.name,
			Vector3.new(b.w, b.h, b.d),
			Vector3.new(b.x, b.y, b.z),
			b.role == "Cover" and Color3.fromRGB(110, 115, 125) or nil,
			b.role
		)
	end
	for _, r in layout.ramps do
		local start, finish = vector(r.a), vector(r.b)
		local p = build(
			r.name,
			Vector3.new(r.width, 1, (finish - start).Magnitude),
			Vector3.new((start.X + finish.X) / 2, (start.Y + finish.Y) / 2, -(start.Z + finish.Z) / 2)
		)
		local forward = (finish - start).Unit
		local right = forward:Cross(Vector3.yAxis).Unit
		p.CFrame = CFrame.fromMatrix(a.origin + (start + finish) / 2, right, right:Cross(forward).Unit, -forward)
			* CFrame.new(0, -0.5, 0)
	end
	for _, p in layout.pieces do
		local marker =
			build(p.id .. "Socket", Vector3.new(p.width, 0.03, p.depth), Vector3.new(p.x, 0.02, p.z), nil, "Marker")
		marker.CanCollide, marker.CanQuery, marker.Transparency = false, false, 0.93
	end
	a.safe = build("SafePadAndApron", Vector3.new(48, 0.06, 40), Vector3.new(0, 0.04, -58), cyan, "Marker")
	a.safe.CanCollide, a.safe.CanQuery = false, false
	a.safe.Transparency = 0.88
	local entryPad = build("SafeEntryPad", Vector3.new(32, 0.08, 24), Vector3.new(0, 0.08, -58), cyan, "Marker")
	entryPad.CanCollide, entryPad.CanQuery, entryPad.Transparency = false, false, 0.65
	local extension = build("SafeWestApron", Vector3.new(22, 0.06, 32), Vector3.new(-27, 0.04, -58), cyan, "Marker")
	extension.CanCollide, extension.CanQuery, extension.Transparency = false, false, 0.88
	a.dock = build("ReturnPortal", Vector3.new(10, 8, 2), Vector3.new(-24, 4, -58), cyan, "Marker")
	a.dock.CanCollide, a.dock.CanQuery = false, false
	a.dock.Transparency = 1
	label(a.dock, "CYAN = secured / home")
	a.guardian = build(
		"Guardian",
		Vector3.new(4, 11, 4),
		Vector3.new(campOffset.X, campOffset.Y + 5.5, -campOffset.Z),
		Color3.fromRGB(155, 115, 95),
		"Marker"
	)
	a.guardian.CanCollide, a.guardian.CanQuery = false, false
	a.arm = build("ThrowArm", Vector3.new(2, 6, 2), Vector3.new(11, 11, 32), nil, "Marker")
	a.arm.CanCollide, a.arm.CanQuery = false, false
	a.guardian.Transparency, a.arm.Transparency = 1, 1
	a.guardian.CanTouch, a.arm.CanTouch = false, false
	a.guardian:SetAttribute("MeadowKeeper", true)
	a.guardian:SetAttribute("KeeperMode", a.mode)
	a.guardian:SetAttribute("KeeperClip", "idle")
	a.guardian:SetAttribute("KeeperElapsed", 0)
	a.keeper = true
	a.warning = label(a.guardian, "GUARDIAN / guarding")
	Scene.meadow(model, a.origin, layout, make)
	if Config.MeadowV4 then
		a.v4 = model:FindFirstChild("MeadowV4")
		a.safe.Position = Arena.position(a, 0, 0.04, -136)
		entryPad.Position = Arena.position(a, 0, 0.08, -136)
		extension.Transparency = 1 -- v4 has no west safe extension.
		a.dock.Position = Arena.position(a, 0, 4, -136)
		a.obstacles = {}
		for _, p in a.v4:GetDescendants() do
			if p:IsA("BasePart") and p.CanCollide then
				local category = p:GetAttribute("MeadowV4Category")
				if
					category == "cover"
					or category == "boulder"
					or category == "tunnel_rock"
					or category == "tunnel_roof"
					or category == "tunnel_hill"
				then
					p:SetAttribute("SurfaceRole", "Cover")
					table.insert(a.obstacles, p)
				end
			end
		end
	end
	a.params = RaycastParams.new()
	a.params.RespectCanCollide = true
	a.params.FilterType, a.params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { model }
	a.wallParams = RaycastParams.new()
	a.wallParams.RespectCanCollide = true
	a.wallParams.FilterType, a.wallParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, a.obstacles
	-- Snapshot structural colliders only. Late cosmetic kit assemblies never enter
	-- this query, even if an imported prop accidentally keeps CanQuery enabled.
	local sightParts = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide and not p:GetAttribute("Cosmetic")
			and not p:FindFirstAncestor("KitDressing") then table.insert(sightParts,p) end
	end
	a.sightParams = RaycastParams.new()
	a.sightParams.RespectCanCollide = true
	a.sightParams.FilterType, a.sightParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, sightParts
	return a
end
function Arena.floor(a, position)
	-- Query near the intended surface: below tunnel roofs and bridges, above summit.
	local height = Config.MeadowV4 and position.Y + 12 or a.origin.Y + 45
	local hit = workspace:Raycast(
		Vector3.new(position.X, height, position.Z),
		Vector3.new(0, Config.MeadowV4 and -90 or -70, 0),
		a.params
	)
	if hit and hit.Instance:GetAttribute("SurfaceRole") == "Floor" and hit.Normal.Y >= math.cos(math.rad(35.1)) then
		return hit.Position, hit.Normal
	end
	return nil
end
function Arena.sight(a, from, to)
	local hit = workspace:Raycast(from, to - from, a.sightParams or a.params)
	return hit == nil, hit
end
function Arena.safe(a, position, radius)
	local p = position - a.origin
	return Layout.protected(p.X, -p.Z, radius)
end
function Arena.outside(a, position)
	local p = position - a.origin
	return p.Y < (Config.MeadowV4 and -45 or -10)
		or math.abs(p.X) > Config.IslandSize / 2 + 2
		or math.abs(p.Z) > Config.IslandSize / 2 + 2
end
local function dropFloor(a, p)
	local center, normal = Arena.floor(a, p)
	if not center or math.abs(center.Y - p.Y) >= 0.7 or Arena.safe(a, center, 3) then
		return nil
	end
	-- Same body/head and 3-stud ledge envelope as the live walk preflight.
	for ix = -6, 6 do
		for iz = -6, 6 do
			if ix * ix + iz * iz <= 36 then
				local sample = center + Vector3.new(ix * 0.5, 0, iz * 0.5)
				local floor, sampleNormal = Arena.floor(a, sample)
				local slope = (normal and normal.Y < 0.999) or (sampleNormal and sampleNormal.Y < 0.999)
				if not floor or math.abs(floor.Y - center.Y) > (slope and 2.15 or 1.5) then
					return nil
				end
				if workspace:Raycast(sample + Vector3.new(0, 2.2, 0), Vector3.new(0, 6, 0), a.params) then
					return nil
				end
			end
		end
	end
	return center
end
function Arena.rimDropSocket(a, position)
	if not a.dropPoints then
		a.dropPoints, a.dropFloors = Layout.dropPoints(a.layout), {}
	end
	local best, distance = nil, math.huge
	for i, socket in a.dropPoints do
		local p = a.origin + vector(socket)
		local d = (p + Vector3.new(0, 3, 0) - position).Magnitude
		if d < distance and a.dropFloors[i] ~= false then
			if a.dropFloors[i] == nil then
				a.dropFloors[i] = dropFloor(a, p) or false
			end
			if a.dropFloors[i] then
				best, distance = a.dropFloors[i], d
			end
		end
	end
	assert(best, "arena has no reachable drop floor")
	return best
end
local function laneQueries(a)
	if not a.laneParams then
		local parts = {}
		for _, p in a.v4:GetDescendants() do
			if p:IsA("BasePart") and p.Parent == a.v4 and p.CanCollide
				and p:HasTag("AuthoredLaneFloor") and p:GetAttribute("WalkableLaneFloor") == true
				and p:GetAttribute("KitAssemblyId") == nil then
				table.insert(parts, p)
			end
		end
		a.laneParams = RaycastParams.new()
		a.laneParams.FilterType = Enum.RaycastFilterType.Include
		a.laneParams.RespectCanCollide = true
		a.laneParams.FilterDescendantsInstances = parts
		a.laneCenters = {}
		local routes = require(game:GetService("ReplicatedStorage").MeadowV4.RouteData)
		a.laneGraph = require(game:GetService("ReplicatedStorage").MeadowV4.ReachableDrops).graph(routes, Vector3, a.origin)
		for _, route in routes do
			for i = 2, #route do
				local u, v = route[i - 1], route[i]
				local from, to = Vector3.new(u.x, u.y, -u.z), Vector3.new(v.x, v.y, -v.z)
				local count = math.max(1, math.ceil((to - from).Magnitude))
				for j = 0, count do
					table.insert(a.laneCenters, a.origin + from:Lerp(to, j / count))
				end
			end
		end
	end
	return function(o, d)
		return workspace:Raycast(o, d, a.laneParams)
	end
end
function Arena.dropDiagnostic(a, position, carrierFloor, label, carrierPos)
	local laneRay = laneQueries(a)
	local o, d = position + Vector3.new(0, 0.2, 0), Vector3.new(0, -30, 0)
	local lane, solid = laneRay(o, d), workspace:Raycast(o, d, a.params)
	local function describe(h)
		if not h then return "NONE" end
		local p = h.Instance
		return string.format("%s Walkable=%s WalkableLaneFloor=%s tag=%s landingY=%.3f lane=%s",
			p:GetFullName(), tostring(p:GetAttribute("Walkable")), tostring(p:GetAttribute("WalkableLaneFloor")),
			tostring(p:HasTag("AuthoredLaneFloor")), h.Position.Y, tostring(p:GetAttribute("LaneId")))
	end
	local function xyz(p)
		return p and {p.X, p.Y, p.Z} or "UNKNOWN"
	end
	return {
		carrierPos = xyz(carrierPos), carrierFloorY = carrierFloor and carrierFloor.Y or "UNKNOWN",
		laneId = lane and lane.Instance:GetAttribute("LaneId") or "UNKNOWN",
		landingInstance = solid and solid.Instance:GetFullName() or "NONE",
		landingY = solid and solid.Position.Y or "UNKNOWN", lootPos = xyz(position),
		recoverPath = {}, reason = label, laneSurface = describe(lane), solidSurface = describe(solid),
	}
end
function Arena.carrierFloor(a, position)
	if not Config.MeadowV4 then
		return Arena.floor(a, position)
	end
	local drops = require(game:GetService("ReplicatedStorage").MeadowV4.ReachableDrops)
	return drops.floor(position, laneQueries(a), Vector3)
end
function Arena.dropSocket(a, position, carrierFloor)
	if not Config.MeadowV4 then
		return Arena.rimDropSocket(a, position)
	end
	local laneRay = laneQueries(a)
	local drops = require(game:GetService("ReplicatedStorage").MeadowV4.ReachableDrops)
	local floor = carrierFloor or Arena.carrierFloor(a, position)
	if not floor then return nil, "no grounded carrier lane" end
	local point, why = drops.settle(
		position,
		floor and floor.Y or position.Y - 3,
		a.laneCenters,
		laneRay,
		function(o, d)
			return workspace:Raycast(o, d, a.params)
		end,
		Vector3,
		a.laneGraph,
		floor
	)
	if not point and not a.samplingDrops then
		a.dropFailureLogs = (a.dropFailureLogs or 0) + 1
		if a.dropFailureLogs <= 30 then
			warn("[DropDiagnostic] FAIL " .. tostring(why))
		end
	end
	if point and not a.samplingDrops then
		-- Retain the pre-displacement carrier reference without logging successes.
		a.lastDropResolution = {position=point, carrierPos=position, floor=floor, reason=why}
	end
	return point, why -- No floor means refuse the drop; never park loot on scenery.
end
local function logState(a, root)
	local state = a.attack and (a.attack.close and "Poke" or "Throw") or a.mode
	if a.loggedState == state then
		return
	end
	a.loggedState = state
	local p = a.guardian.Position - a.origin
	local r = a.target and root(a.target)
	local target = r and r.Position - a.origin
	print(
		string.format(
			"[GreyboxGuardian] state=%s pos=(%.1f,%.1f,%.1f) target=%s range=%.1f reason=%s",
			state,
			p.X,
			p.Y,
			p.Z,
			target and string.format("(%.1f,%.1f,%.1f)", target.X, target.Y, target.Z) or "none",
			r and (r.Position - a.guardian.Position).Magnitude or -1,
			a.returnReason or "none"
		)
	)
end
local function clearPath(a)
	a.pathVersion = (a.pathVersion or 0) + 1
	a.points, a.index, a.nextPath = {}, 1, 0
	a.computing = false -- The invalidated worker no longer owns the request slot.
end
local function returnToCamp(a, now, reason)
	a.mode, a.untilTime, a.returnReason = "Return", now + returnSeconds, reason
	a.target, a.lostTarget, a.searchAt = nil, nil, nil
	a.progressAt, a.progressPosition = now, a.guardian.Position
	clearPath(a)
end
local function poof(a, position, now)
	if a.poof then
		a.poof.part:Destroy()
	end
	local p = Instance.new("Part")
	p.Name, p.Shape = "GuardianRecoveryPoof", Enum.PartType.Ball
	p.Size, p.CFrame = Vector3.new(6, 6, 6), CFrame.new(position)
	p.Color, p.Material = Color3.fromRGB(220, 205, 180), Enum.Material.Neon
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency, p.Parent = 0.2, a.model
	a.poof = { part = p, start = now }
end
function Arena.warn(a, actor, now)
	if a.target == actor and (a.mode == "Chase" or a.mode == "Warn") then
		return -- Pickup must not restart the approach warning.
	end
	a.target, a.mode, a.untilTime, a.targetSince = actor, "Warn", now + Config.WarningSeconds, now
	a.chaseBegan = now + Config.WarningSeconds
	a.lostTarget = nil
	clearPath(a)
	a.progressAt, a.progressPosition = now, a.guardian.Position
end
local function attack(a, actor, position, now, close)
	local floor = Arena.floor(a, position)
	if not floor or Arena.safe(a, floor, close and 0 or Config.ThrowRadius) then
		return
	end
	a.nextThrow = now + Config.ThrowCooldown
	if not close then
		local facing = Vector3.new(floor.X, a.guardian.Position.Y, floor.Z)
		if (facing - a.guardian.Position).Magnitude > 0.1 then
			a.guardian.CFrame = CFrame.lookAt(a.guardian.Position, facing)
		end
	end
	a.attack = {
		actor = actor,
		position = floor,
		start = now,
		from = a.guardian.Position + Vector3.new(0, 3, 0),
		close = close,
		closeRadius = Config.CatchRadius,
		previous = a.guardian.Position + Vector3.new(0, 3, 0),
	}
	if not close then
		a.throws += 1
		local disc = Instance.new("Part")
		disc.Name, disc.Shape = "RedGroundDisc", Enum.PartType.Cylinder
		disc.Size, disc.CFrame =
			Vector3.new(0.08, Config.ThrowRadius * 2, Config.ThrowRadius * 2),
			CFrame.new(floor + Vector3.new(0, 0.09, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		disc.Color, disc.Material, disc.Transparency = red, Enum.Material.Neon, 0.55
		disc.Anchored, disc.CanCollide, disc.CanQuery, disc.Parent = true, false, false, a.model
		disc:SetAttribute("TelegraphStarted", now)
		disc:SetAttribute("ImpactDue", now + Config.ThrowSeconds)
		local ring = disc:Clone()
		ring.Name, ring.Size, ring.Transparency, ring.Parent = "DiscFill", Vector3.new(0.1, 0.1, 0.1), 0.2, a.model
		local outline = Instance.new("Folder")
		outline.Name, outline.Parent = "DiscOutline", a.model
		for i = 0, 23 do
			local angle = i * math.pi / 12
			local segmentPosition = floor
				+ Vector3.new(math.cos(angle) * Config.ThrowRadius, 0.15, math.sin(angle) * Config.ThrowRadius)
			local segment = Instance.new("Part")
			segment.Size, segment.CFrame =
				Vector3.new(0.12, 0.08, 1.05),
				CFrame.lookAt(segmentPosition, segmentPosition + Vector3.new(-math.sin(angle), 0, math.cos(angle)))
			segment.Color, segment.Material, segment.Anchored = red, Enum.Material.Neon, true
			segment.CanCollide, segment.CanQuery, segment.Parent = false, false, outline
		end
		a.attack.outline = outline
		a.attack.disc, a.attack.fill = disc, ring
		a.model:SetAttribute("TelegraphStarted", now)
	else
		a.warning.Text = "! / close poke"
		a.attack.standing = a.guardian.CFrame
		a.guardian.Size = Vector3.new(4, 6, 4)
		a.guardian.CFrame += Vector3.new(0, -2.5, 0)
	end
end
local function tick(a, dt, now, actors, root, hitPlayer, goal, loot)
	if a.tunnelGuard then
		local t = a.tunnelGuard
		if t.waiting then
			local carrier = loot and loot.holder
			local r = carrier and root(carrier)
			if
				r
				and not Arena.safe(a, r.Position)
				and (Vector3.new(r.Position.X, t.exit.Y, r.Position.Z) - t.exit).Magnitude < 12
				and math.abs(r.Position.Y - t.exit.Y) < 10
			then
				if hitPlayer(carrier, a.guardian.Position, "TunnelGuard") then
					a.keeperCelebrateUntil = now + 1.9
				end
			end
		end
		return
	end
	local guard = a.guardian
	if a.poof then
		local alpha = math.min(1, now - a.poof.start)
		a.poof.part.Size = Vector3.new(6, 6, 6) * (1 + alpha)
		a.poof.part.Transparency = 0.2 + 0.8 * alpha
		if alpha >= 1 then
			a.poof.part:Destroy()
			a.poof = nil
		end
	end
	local nestCamp = a.origin + campOffset
	local camp = a.guardCamp or nestCamp
	if loot and loot.state == "Dropped" and a.guardedVersion ~= loot.version then
		a.guardedVersion = loot.version
		local delta = loot.position - nestCamp
		local nearby = loot.position - guard.Position
		if
			Vector3.new(delta.X, 0, delta.Z).Magnitude <= Config.GuardianDroppedGuardRadius
			or Vector3.new(nearby.X, 0, nearby.Z).Magnitude <= Config.GuardianDroppedGuardRadius
		then
			local beside = loot.position + Vector3.new(Config.GuardianGuardOffset.x, 0, 0)
			camp = Arena.floor(a, beside) or nestCamp
			a.guardCamp = camp
			if not a.attack then
				returnToCamp(a, now, "guard nearby dropped treasure")
			else
				a.returnAfterAttack = true
			end
		end
	elseif not loot or loot.state ~= "Dropped" then
		a.guardCamp, a.guardedVersion, a.returnAfterAttack = nil, nil, nil
		camp = nestCamp
	end
	if a.returnAfterAttack and not a.attack then
		a.returnAfterAttack = nil
		returnToCamp(a, now, "guard nearby dropped treasure")
	end
	logState(a, root)
	-- Windups stay planted; recovery takes priority after impact.
	if a.keeperStunUntil and now < a.keeperStunUntil then
		a.warning.Text = "STUNNED / wall hit"
		a.progressAt, a.progressPosition = now, guard.Position
		return
	end
	if not a.attack and not a.decoy then
		if a.progressPosition and (guard.Position - a.progressPosition).Magnitude >= Config.GuardianProgressStuds then
			a.progressAt, a.progressPosition = now, guard.Position
			a.recoveryStarted = nil
		end
		local flat = Vector3.new(guard.Position.X - camp.X, 0, guard.Position.Z - camp.Z)
		if a.mode ~= "Return" and flat.Magnitude > leashRadius then
			returnToCamp(a, now, "outside camp leash")
		elseif a.mode ~= "Return" and a.progressAt and now - a.progressAt >= stuckSeconds then
			returnToCamp(a, now, "navigation made no progress")
		end
		if a.mode == "Return" then
			logState(a, root)
			local home = camp + Vector3.new(0, 5.5, 0)
			if (guard.Position - home).Magnitude < Config.GuardianGuardArrival then
				a.mode, a.returnReason, a.patrol = "Guard", nil, 1
				a.recoveryStarted = nil
				a.progressAt, a.progressPosition = nil, nil
				clearPath(a)
				logState(a, root)
			elseif a.progressAt and now - a.progressAt >= returnSeconds then
				if not a.recoveryStarted then
					a.recoveryStarted = now
					poof(a, guard.Position, now)
					print("[GreyboxGuardian] recovery poof / stationary >=20s / " .. tostring(a.returnReason))
				elseif now - a.recoveryStarted >= 1 then
					guard.CFrame = CFrame.new(home)
					poof(a, home, now)
					a.recoveryStarted = nil
					a.progressAt, a.progressPosition = now, guard.Position
					clearPath(a)
				end
				return -- Visible departure before the exceptional NPC-only relocation.
			end
		end
	end
	guard.Color = (a.mode == "Warn" or a.attack) and Color3.fromRGB(255, 180, 40) or Color3.fromRGB(155, 115, 95)
	a.warning.TextColor3 = (a.mode == "Warn" or a.attack) and Color3.fromRGB(255, 190, 40) or Color3.new(1, 1, 1)
	a.arm.CFrame = guard.CFrame * CFrame.new(3, (a.mode == "Warn" or a.attack) and 5 or 1, 0)
	local function visible(actor, detect)
		local s = actors[actor]
		local r = root(actor)
		if Config.MeadowV4 and r then
			local p = r.Position - a.origin
			if require(game:GetService("ReplicatedStorage").MeadowV4.TunnelPolicy).inside(p.X, p.Y, p.Z) then
				return false
			end
		end
		if not s or s.phase ~= "Run" or not r or Arena.safe(a, r.Position) then
			return false
		end
		local distance = (r.Position - guard.Position).Magnitude
		-- A visible carrier is actionable across the whole throw range, even after
		-- Search expires. Empty-handed entrants retain the shorter patrol aggro.
		local range = s.item and throwRange or detectRange
		-- Upper-body sight clears small cover tops without ignoring walls/terrain.
		return (not detect or distance <= range)
			and Arena.sight(a, guard.Position + Vector3.new(0, 3, 0), r.Position + Vector3.new(0, 2, 0))
	end
	if a.attack then
		a.progressAt, a.progressPosition = nil, nil
		local t = a.attack
		if t.kind then
			local folder = game:GetService("ReplicatedStorage"):WaitForChild("MeadowKeeper")
			require(folder:WaitForChild("Attacks")).step(
				a,
				now,
				actors,
				root,
				hitPlayer,
				Arena,
				require(folder:WaitForChild("Pose"))
			)
			return
		end
		local alpha = math.min(1, (now - t.start) / Config.ThrowSeconds)
		-- Lock aim at attack creation; spawn exactly once on the authored Release.
		if not t.close and not t.rock and now - t.start >= 0.620 then
			if a.keeper then
				local pose =
					require(game:GetService("ReplicatedStorage"):WaitForChild("MeadowKeeper"):WaitForChild("Pose"))
				t.from = pose.release(guard).Position
			end
			t.previous = t.from
			local rock = Instance.new("Part")
			rock.Name, rock.Size, rock.Position = "ThrownRock", Vector3.new(2, 2, 2), t.from
			rock.Anchored, rock.CanCollide, rock.CanQuery, rock.CanTouch, rock.Parent =
				true, false, false, false, a.model
			t.rock = rock
			a.model:SetAttribute("KeeperReleaseAt", t.start + 0.620)
			a.model:SetAttribute("KeeperReleaseObservedAt", now)
			a.model:SetAttribute("KeeperReleaseOrigin", t.from)
		end
		if t.fill then
			t.fill.Size = Vector3.new(
				0.1,
				math.max(0.1, Config.ThrowRadius * 2 * alpha),
				math.max(0.1, Config.ThrowRadius * 2 * alpha)
			)
		end
		if t.rock then
			-- Keep the original impact deadline; remaining flight follows release.
			local flight = math.clamp((now - t.start - 0.620) / (Config.ThrowSeconds - 0.620), 0, 1)
			local nextPoint = t.from:Lerp(t.position + Vector3.new(0, 1, 0), flight)
				+ Vector3.new(0, 40 * flight * (1 - flight), 0)
			local obstruction = workspace:Spherecast(t.previous, 0.9, nextPoint - t.previous, a.params)
			-- Floor at the locked destination is an impact; other geometry intercepts.
			if obstruction and (obstruction.Position - t.position).Magnitude > 2 then
				t.cancelled = true
			end
			t.rock.Position, t.previous = nextPoint, nextPoint
		end
		if alpha >= 1 or t.cancelled then
			if not t.cancelled then
				a.impacts += 1
				a.model:SetAttribute("LastImpactAt", now)
				a.model:SetAttribute("LastImpactDelay", now - t.start)
				for actor, s in actors do
					local r = root(actor)
					if
						s.phase == "Run"
						and r
						and not Arena.safe(a, r.Position)
						and math.abs(r.Position.Y - t.position.Y) <= Config.GuardianImpactHeight
					then
						local distance = (Vector3.new(r.Position.X, t.position.Y, r.Position.Z) - t.position).Magnitude
						local closeLegal = not t.close
							or (
								actor == t.actor
								and (r.Position - guard.Position).Magnitude <= t.closeRadius
								and Arena.sight(a, guard.Position, r.Position)
							)
						if
							distance <= (t.close and t.closeRadius or Config.ThrowRadius)
							and Arena.sight(a, t.position + Vector3.new(0, 0.5, 0), r.Position)
							and closeLegal
						then
							if hitPlayer(actor, guard.Position) then
								a.keeperCelebrateUntil = now + 1.9
							end
						end
					end
				end
			end
			if t.disc then
				t.disc:Destroy()
				t.fill:Destroy()
				if t.rock then
					t.rock:Destroy()
				end
				t.outline:Destroy()
			end
			if t.standing then
				guard.Size, guard.CFrame = Vector3.new(4, 11, 4), t.standing
			end
			a.attack = nil
		end
		return -- Plant feet; never overlap windups.
	end
	local target = a.target
	if a.decoy then
		-- Locked windups resolved above. The visible rattle turns attention;
		-- investigation then uses normal walking/pathfinding, never a stun.
		a.target, target = nil, nil
		a.lostTarget, a.searchAt = nil, nil
		a.mode = now < a.decoy.tellEnd and "DecoyTell" or "Investigate"
		a.warning.Text = a.mode == "DecoyTell" and "! / DECOY RATTLE" or "? / investigate DECOY"
		if a.mode == "DecoyTell" then
			local towards = Vector3.new(a.decoy.position.X, guard.Position.Y, a.decoy.position.Z)
			-- Let the head notice the sound before the body follows it.
			if (towards - guard.Position).Magnitude > 0.1 and now - (a.decoy.started or now - 1) >= 0.3 then
				guard.CFrame = CFrame.lookAt(guard.Position, towards)
			end
			return
		end
	elseif a.mode == "Investigate" or a.mode == "DecoyTell" then
		a.mode, a.progressAt, a.progressPosition = "Guard", nil, nil
		clearPath(a)
	end
	if target and not visible(target, false) then
		a.lostTarget = target
		a.target, a.mode, a.untilTime = nil, "Search", now + Config.GuardianSearchSeconds
		a.searchAt = a.lastSeen
	end
	if
		not a.decoy
		and a.mode ~= "Return"
		and (not a.target or now - (a.targetSince or 0) >= Config.GuardianTargetLockSeconds)
	then
		local candidate, best = nil, math.huge
		for actor, s in actors do
			if visible(actor, actor ~= a.target and actor ~= a.lostTarget) then
				local score = (root(actor).Position - guard.Position).Magnitude - (s.item and 100 or 0)
				if score < best then
					candidate, best = actor, score
				end
			end
		end
		if candidate and candidate ~= a.target then
			Arena.warn(a, candidate, now)
		end
	end
	target = a.target
	if target then
		a.lastSeen = root(target).Position
		if a.mode == "Warn" and now >= a.untilTime then
			a.mode = "Chase"
		end
	elseif a.mode == "Search" and now >= a.untilTime then
		a.mode, a.lostTarget = "Guard", nil
	end
	logState(a, root)
	a.warning.Text = a.mode == "Investigate" and "? / investigate DECOY"
		or (a.mode == "Warn" and "!" or (a.mode == "Search" and "?" or "GUARDIAN / " .. a.mode))
	if a.mode == "Warn" then
		if target then
			local r = root(target)
			local towards = Vector3.new(r.Position.X, guard.Position.Y, r.Position.Z)
			if (towards - guard.Position).Magnitude > 0.1 then
				guard.CFrame = CFrame.lookAt(guard.Position, towards)
			end
			goal(target, "! / move: " .. Config.WarningSeconds .. "s warning")
		end
		return
	end
	local destination
	if a.decoy then
		destination = a.decoy.position
	elseif target and a.mode == "Chase" then
		a.chaseTicks += 1
		local s, r = actors[target], root(target)
		destination = r.Position
		goal(target, "RUN! / leave red rings; jump amber waves")
		local distance = (r.Position - guard.Position).Magnitude
		if now >= s.mercy and now >= a.nextThrow then
			if a.keeper then
				local kit =
					require(game:GetService("ReplicatedStorage"):WaitForChild("MeadowKeeper"):WaitForChild("Attacks"))
				local kind = distance <= throwRange and kit.choose(a, target, now, actors, root)
				if kind then
					local velocity = r.AssemblyLinearVelocity or Vector3.zero
					local leadSeconds = kind == "lob" and kit.Tuning.LobLeadSeconds or kit.Tuning.FanLeadSeconds
					local leadMax = kind == "lob" and kit.Tuning.LobLeadMax or kit.Tuning.FanLeadMax
					local lead = Vector3.new(velocity.X, 0, velocity.Z) * leadSeconds
					if lead.Magnitude > leadMax then
						lead = lead.Unit * leadMax
					end
					local predicted = kind == "dash" and r.Position or r.Position + lead
					if not Arena.floor(a, predicted) then
						predicted = r.Position
					end
					local pose =
						require(game:GetService("ReplicatedStorage"):WaitForChild("MeadowKeeper"):WaitForChild("Pose"))
					if kit.begin(a, target, predicted, now, kind, Arena, pose) then
						return
					end
				end
			else
				if distance >= Config.GuardianThrowMinRange and distance <= throwRange then
					local velocity = r.AssemblyLinearVelocity or Vector3.zero
					local lead = Vector3.new(velocity.X, 0, velocity.Z) * Config.GuardianLeadSeconds
					if lead.Magnitude > Config.GuardianLeadMaxStuds then
						lead = lead.Unit * Config.GuardianLeadMaxStuds
					end
					local predicted = r.Position + lead
					if not Arena.floor(a, predicted) or Arena.safe(a, predicted, Config.ThrowRadius) then
						predicted = r.Position
					end
					attack(a, target, predicted, now, false)
					logState(a, root)
					return
				end
				local horizontal = (Vector3.new(r.Position.X, guard.Position.Y, r.Position.Z) - guard.Position).Magnitude
				if
					horizontal <= Config.CatchRadius
					and math.abs(r.Position.Y - (guard.Position.Y - 2.5)) <= Config.GuardianPokeVertical
				then
					attack(a, target, r.Position, now, true)
					return
				end
			end
		end
	elseif a.mode == "Return" then
		destination = camp
	elseif a.mode == "Search" then
		destination = a.searchAt
	else
		destination = camp
		if (guard.Position - camp - Vector3.new(0, 5.5, 0)).Magnitude < Config.GuardianGuardArrival then
			a.mode, a.progressAt, a.progressPosition = "Guard", nil, nil
			return
		end
	end
	if not destination then
		return
	end
	a.progressAt = a.progressAt or now
	a.progressPosition = a.progressPosition or guard.Position
	if (guard.Position - a.progressPosition).Magnitude >= Config.GuardianProgressStuds then
		a.progressAt, a.progressPosition = now, guard.Position
	end
	if now >= a.nextPath and not a.computing then
		a.nextPath, a.computing = now + Config.GuardianPathRefreshSeconds, true
		local requested, version = destination, a.pathVersion or 0
		task.spawn(function()
			local path
			local ok = pcall(function()
				path = Pathfinding:CreatePath({
					AgentRadius = 2,
					AgentHeight = 11,
					AgentCanJump = false,
					WaypointSpacing = 3,
				})
				path:ComputeAsync(guard.Position - Vector3.new(0, 4.5, 0), requested)
			end)
			if a.model.Parent and version == (a.pathVersion or 0) and ok and path.Status == Enum.PathStatus.Success then
				a.points, a.index = path:GetWaypoints(), 2
			end
			if path then
				path:Destroy()
			end
			-- A cancelled request must not unlock a newer request after reset.
			if version == (a.pathVersion or 0) then
				a.computing = false
			end
		end)
	end
	local waypoint = a.points[a.index]
	if not waypoint then
		return
	end
	local offset = Vector3.new(waypoint.Position.X - guard.Position.X, 0, waypoint.Position.Z - guard.Position.Z)
	if offset.Magnitude < 0.5 then
		a.index += 1
		return
	end
	local speed = Config.GuardianReturnSpeed
	if a.mode == "Chase" then
		local burst = (now - (a.chaseBegan or now)) % Config.GuardianBurstCooldown < Config.GuardianBurstSeconds
		speed = burst and Config.GuardianBurstSpeed or Config.GuardianSpeed
		a.warning.Text = burst and "GUARDIAN / BURST!" or "GUARDIAN / Chase"
	end
	local movement = offset.Unit * math.min(offset.Magnitude, speed * dt)
	local nextPoint = guard.Position + movement
	if Config.MeadowV4 then
		local p = nextPoint - a.origin - Vector3.new(0, 5.5, 0)
		if require(game:GetService("ReplicatedStorage").MeadowV4.TunnelPolicy).inside(p.X, math.max(0, p.Y), p.Z) then
			a.points, a.nextPath = {}, 0
			return
		end
	end
	local floor = Arena.floor(a, nextPoint)
	local blocked = workspace:Blockcast(guard.CFrame, Vector3.new(4, 10, 4), movement, a.wallParams)
	if
		floor
		and not blocked
		and not Arena.safe(a, floor)
		and (a.mode == "Return" or Vector3.new(floor.X - camp.X, 0, floor.Z - camp.Z).Magnitude <= leashRadius)
		and math.abs(floor.Y - (guard.Position.Y - 5.5)) <= movement.Magnitude * math.tan(math.rad(35)) + 0.25
	then
		local position = floor + Vector3.new(0, 5.5, 0)
		guard.CFrame = CFrame.lookAt(position, position + movement)
		if a.mode == "Chase" then
			a.chaseDistance += movement.Magnitude
		end
	else
		a.points, a.nextPath = {}, 0
	end
end
function Arena.tick(a, dt, now, actors, root, hitPlayer, goal, loot)
	local before = a.guardian.Position
	tick(a, dt, now, actors, root, hitPlayer, goal, loot)
	-- Presentation signal uses gameplay mode, independent of attack animation clips.
	if a.keeperMode ~= a.mode then
		a.keeperMode = a.mode
		a.guardian:SetAttribute("KeeperMode", a.mode)
	end
	if not a.keeper then
		return
	end
	local moved = (a.guardian.Position - before).Magnitude > 0.001
	local clip = "idle"
	if a.attack then
		clip = a.attack.kind or (a.attack.close and "warn" or "throw")
	elseif a.recoveryStarted or a.mode == "Stun" or a.keeperStunUntil and now < a.keeperStunUntil then
		clip = "stun"
	elseif a.mode == "Warn" or a.mode == "DecoyTell" then
		clip = "warn"
	elseif a.mode == "Return" then
		clip = "return"
	elseif a.keeperCelebrateUntil and now < a.keeperCelebrateUntil or a.mode == "Celebrate" then
		clip = "celebrate"
	elseif a.keeperClip == "throw" and now - a.keeperClipStart < 1.4 then
		clip = "throw"
	elseif a.mode == "Chase" then
		clip = "chase"
	elseif moved or a.mode == "Patrol" then
		clip = "patrol"
	end
	local attackStart = a.attack and a.attack.start
	if clip ~= a.keeperClip or attackStart and attackStart ~= a.keeperAttackStart then
		a.keeperClip, a.keeperClipStart, a.keeperAttackStart = clip, attackStart or now, attackStart
		a.guardian:SetAttribute("KeeperClip", clip)
		if workspace.GetServerTimeNow then
			a.guardian:SetAttribute("KeeperStartedAt", workspace:GetServerTimeNow() - (now - a.keeperClipStart))
		end
	end
	a.guardian:SetAttribute("KeeperElapsed", math.max(0, now - a.keeperClipStart))
	local targetRoot = a.target and root(a.target)
	a.guardian:SetAttribute("KeeperLookTarget", a.decoy and a.decoy.position or targetRoot and targetRoot.Position or nil)
	a.guardian:SetAttribute("KeeperAttention", a.decoy and a.mode or "")
end
function Arena.reset(a)
	a.tunnelGeneration = (a.tunnelGeneration or 0) + 1
	a.tunnelGuard = nil
	if Config.MeadowV4 then
		workspace:SetAttribute("TunnelGuardWaiting", false)
	end
	a.decoy = nil
	if a.poof then
		a.poof.part:Destroy()
		a.poof = nil
	end
	a.recoveryStarted = nil
	if a.attack then
		for _, name in { "disc", "fill", "rock", "outline" } do
			if a.attack[name] then
				a.attack[name]:Destroy()
			end
		end
		if a.attack.parts then
			for _, part in ipairs(a.attack.parts) do
				part:Destroy()
			end
		end
		if a.attack.standing then
			a.guardian.Size, a.guardian.CFrame = Vector3.new(4, 11, 4), a.attack.standing
		end
	end
	a.attack, a.target, a.lostTarget, a.searchAt, a.lastSeen = nil, nil, nil, nil, nil
	a.mode, a.patrol, a.nextThrow = "Guard", 1, 0
	a.keeperMode = "Guard"
	a.guardian:SetAttribute("KeeperMode", "Guard")
	a.untilTime, a.chaseBegan, a.targetSince = 0, nil, nil
	a.guardCamp, a.guardedVersion, a.returnAfterAttack, a.returnReason = nil, nil, nil, nil
	a.computing = false
	a.kitCooldowns = nil
	a.keeperStunUntil = nil
	if a.keeper then
		Arena.fx(a, "Reset", a.guardian.Position)
	end
	a.keeperClip, a.keeperClipStart, a.keeperAttackStart, a.keeperCelebrateUntil = nil, nil, nil, nil
	if a.keeper then
		a.guardian:SetAttribute("KeeperClip", "idle")
		a.guardian:SetAttribute("KeeperElapsed", 0)
		a.guardian:SetAttribute("KeeperStartedAt", nil)
		a.guardian:SetAttribute("KeeperLookTarget", nil)
	end
	a.progressAt, a.progressPosition = nil, nil
	clearPath(a)
end
-- Adapter called once per entrant/exit/occupancy epoch. Live rig follows this handle.
function Arena.intercept(a, exitId, path, holdSeconds, entrant, _epoch)
	Arena.reset(a)
	local token = a.tunnelGeneration
	local t = { waiting = false }
	a.tunnelGuard = t
	a.mode = "TunnelIntercept"
	local function valid()
		return a.model.Parent and a.tunnelGeneration == token and a.tunnelGuard == t
	end
	local function cleanup()
		if not valid() then
			return
		end
		a.tunnelGuard = nil
		a.target = nil
		a.mode = "Guard"
		a.progressAt = nil
		clearPath(a)
		workspace:SetAttribute("TunnelGuardWaiting", false)
	end
	task.spawn(function()
		for i, p in path do
			local start = a.guardian.Position
			local target = a.origin + Vector3.new(p.x, 5.5, p.z)
			local seconds = i == 1 and 0.8 or (target - start).Magnitude / 32
			local elapsed = 0
			while elapsed < seconds do
				elapsed += game:GetService("RunService").Heartbeat:Wait()
				if not valid() then
					return
				end
				local alpha = math.min(elapsed / math.max(seconds, 0.05), 1)
				local pos = start:Lerp(target, alpha)
				if i == 1 then
					pos += Vector3.new(0, math.sin(alpha * math.pi) * 18, 0)
				end
				local forward = Vector3.new(target.X - start.X, 0, target.Z - start.Z)
				a.guardian.CFrame = forward.Magnitude > 0.01 and CFrame.lookAt(pos, pos + forward)
					or CFrame.new(pos) * a.guardian.CFrame.Rotation
			end
		end
		if not valid() then
			return
		end
		local e = require(game:GetService("ReplicatedStorage").MeadowV4.TunnelPolicy).Exits[exitId]
		t.exit = a.origin + Vector3.new(e.x, 0, e.z)
		t.waiting = true
		workspace:SetAttribute("TunnelGuardWaiting", true)
		local deadline = os.clock() + 14
		local left = false
		while valid() and os.clock() < deadline do
			if not left and (not entrant.Parent or entrant:GetAttribute("TunnelInside") ~= true) then
				left = true
				deadline = math.min(deadline, os.clock() + holdSeconds)
			end
			task.wait(0.05)
		end
		cleanup()
	end)
	return cleanup
end
return Arena
