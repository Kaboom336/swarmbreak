local Pathfinding = game:GetService("PathfindingService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxConfig"))
local Layout = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxLayout"))
local Arena = {}
local detectRange, throwRange = 24, 36
local cyan, red = Color3.fromRGB(60, 210, 230), Color3.fromRGB(255, 40, 40)
local function vector(p)
	return Vector3.new(p.x, p.y, p.z)
end
function Arena.build(world, layout, make, label)
	local model = Instance.new("Model")
	model.Name, model.Parent = "SharedIsland", world
	model:SetAttribute("Seed", layout.seed)
	model:SetAttribute("RecipeVersion", Config.RecipeVersion)
	model:SetAttribute("ArenaId", 1)
	model:SetAttribute("Difficulty", "Easy")
	local a = {
		model = model,
		layout = layout,
		origin = Vector3.new(500, 0, 0),
		occupants = {},
		mode = "Patrol",
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
		hides = {},
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
					"Port" .. port[1], Vector3.new(12, 0.05, 1), a.origin + Vector3.new(p.x + port[2], 0, p.z + port[3])
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
		local p = make(model, name, size, a.origin + position, color)
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
	build("RockUnderside", Vector3.new(Config.IslandSize - 8, 8, Config.IslandSize - 8), Vector3.new(0, -10, 0))
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
		local p = build(r.name, Vector3.new(r.width, 1, (finish - start).Magnitude), (start + finish) / 2)
		p.CFrame = CFrame.lookAt(a.origin + (start + finish) / 2, a.origin + finish) * CFrame.new(0, -0.5, 0)
	end
	for _, p in layout.pieces do
		local marker =
			build(p.id .. "Socket", Vector3.new(p.width, 0.03, p.depth), Vector3.new(p.x, 0.02, p.z), nil, "Marker")
		marker.CanCollide, marker.CanQuery, marker.Transparency = false, false, 0.93
	end
	for _, h in layout.hides do
		local p = build(
			"HidePocket",
			Vector3.new(h.w, 0.05, h.d),
			Vector3.new(h.x, 0.04, h.z),
			Color3.fromRGB(95, 160, 95),
			"Marker"
		)
		p.CanCollide, p.CanQuery = false, false
		label(p, h.log and "HIDE / two exits" or "HIDE / stop 0.5s")
		table.insert(a.hides, { definition = h, marker = p })
	end
	a.safe = build("SafePadAndApron", Vector3.new(48, 0.06, 40), Vector3.new(0, 0.04, -58), cyan, "Marker")
	a.safe.CanCollide, a.safe.CanQuery = false, false
	a.dock = build("ReturnPortal", Vector3.new(10, 8, 2), Vector3.new(0, 4, -64), cyan, "Marker")
	a.dock.CanCollide, a.dock.CanQuery = false, false
	label(a.dock, "CYAN = secured / home")
	a.guardian =
		build("Guardian", Vector3.new(4, 11, 4), Vector3.new(8, 9.5, 32), Color3.fromRGB(155, 115, 95), "Marker")
	a.guardian.CanCollide, a.guardian.CanQuery = false, false
	a.arm = build("ThrowArm", Vector3.new(2, 6, 2), Vector3.new(11, 11, 32), nil, "Marker")
	a.arm.CanCollide, a.arm.CanQuery = false, false
	a.warning = label(a.guardian, "GUARDIAN / patrol")
	a.params = RaycastParams.new()
	a.params.FilterType, a.params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { model }
	a.wallParams = RaycastParams.new()
	a.wallParams.FilterType, a.wallParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, a.obstacles
	return a
end
function Arena.floor(a, position)
	local hit =
		workspace:Raycast(Vector3.new(position.X, a.origin.Y + 45, position.Z), Vector3.new(0, -70, 0), a.params)
	if hit and hit.Instance:GetAttribute("SurfaceRole") == "Floor" and hit.Normal.Y >= math.cos(math.rad(25.1)) then
		return hit.Position
	end
	return nil
end
function Arena.sight(a, from, to)
	return workspace:Raycast(from, to - from, a.params) == nil
end
function Arena.safe(a, position, radius)
	local p = position - a.origin
	return Layout.protected(p.X, p.Z, radius)
end
function Arena.dropSocket(a, position)
	local best, distance = nil, 6.001
	for _, socket in a.layout.sockets do
		local p = a.origin + vector(socket)
		if (Vector3.new(p.X, position.Y, p.Z) - position).Magnitude <= 6 then
			local floor = Arena.floor(a, p)
			if floor and math.abs(position.Y - floor.Y - 3) <= 5 and not Arena.safe(a, floor) then
				local d = (floor + Vector3.new(0, 3, 0) - position).Magnitude
				if d < distance and Arena.sight(a, position, floor + Vector3.new(0, 1.6, 0)) then
					best, distance = floor, d
				end
			end
		end
	end
	return best
end
function Arena.warn(a, actor, now)
	a.target, a.mode, a.untilTime, a.targetSince = actor, "Warn", now + Config.WarningSeconds, now
	a.lostTarget = nil
	a.points, a.index = {}, 1
end
local function attack(a, actor, position, now, close)
	local floor = Arena.floor(a, position)
	if not floor or Arena.safe(a, floor, close and 0 or Config.ThrowRadius) then
		return
	end
	a.nextThrow = now + Config.ThrowCooldown
	a.attack = {
		actor = actor,
		position = floor,
		start = now,
		from = a.guardian.Position + Vector3.new(0, 3, 0),
		close = close,
		closeRadius = a.searchActor == actor and 4 or Config.CatchRadius,
		previous = a.guardian.Position + Vector3.new(0, 3, 0),
	}
	if not close then
		a.throws += 1
		local disc = Instance.new("Part")
		disc.Name, disc.Shape = "RedGroundDisc", Enum.PartType.Cylinder
		disc.Size, disc.CFrame =
			Vector3.new(0.08, 8, 8), CFrame.new(floor + Vector3.new(0, 0.09, 0)) * CFrame.Angles(0, 0, math.pi / 2)
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
			local segmentPosition = floor + Vector3.new(math.cos(angle) * 4, 0.15, math.sin(angle) * 4)
			local segment = Instance.new("Part")
			segment.Size, segment.CFrame =
				Vector3.new(0.12, 0.08, 1.05),
				CFrame.lookAt(segmentPosition, segmentPosition + Vector3.new(-math.sin(angle), 0, math.cos(angle)))
			segment.Color, segment.Material, segment.Anchored = red, Enum.Material.Neon, true
			segment.CanCollide, segment.CanQuery, segment.Parent = false, false, outline
		end
		a.attack.outline = outline
		local rock = Instance.new("Part")
		rock.Name, rock.Size, rock.Position = "ThrownRock", Vector3.new(2, 2, 2), a.attack.from
		rock.Anchored, rock.CanCollide, rock.CanQuery, rock.Parent = true, false, false, a.model
		a.attack.disc, a.attack.fill, a.attack.rock = disc, ring, rock
		a.model:SetAttribute("TelegraphStarted", now)
	else
		a.warning.Text = "! / close poke"
		a.attack.standing = a.guardian.CFrame
		a.guardian.Size = Vector3.new(4, 6, 4)
		a.guardian.CFrame += Vector3.new(0, -2.5, 0)
	end
end
function Arena.tick(a, dt, now, actors, root, hitPlayer, goal)
	local guard = a.guardian
	guard.Color = (a.mode == "Warn" or a.attack) and Color3.fromRGB(255, 180, 40) or Color3.fromRGB(155, 115, 95)
	a.warning.TextColor3 = (a.mode == "Warn" or a.attack) and Color3.fromRGB(255, 190, 40) or Color3.new(1, 1, 1)
	a.arm.CFrame = guard.CFrame * CFrame.new(3, (a.mode == "Warn" or a.attack) and 5 or 1, 0)
	local function visible(actor, detect)
		local s = actors[actor]
		local r = root(actor)
		if not s or s.phase ~= "Run" or not r or Arena.safe(a, r.Position) or s.hidden then
			return false
		end
		local distance = (r.Position - guard.Position).Magnitude
		-- A visible carrier is actionable across the whole throw range, even after
		-- Search expires. Empty-handed entrants retain the shorter patrol aggro.
		local range = s.item and throwRange or detectRange
		return (not detect or distance <= range) and Arena.sight(a, guard.Position + Vector3.new(0, 1, 0), r.Position)
	end
	if a.attack then
		local t = a.attack
		local alpha = math.min(1, (now - t.start) / Config.ThrowSeconds)
		if t.rock then
			local nextPoint = t.from:Lerp(t.position + Vector3.new(0, 1, 0), alpha)
				+ Vector3.new(0, 40 * alpha * (1 - alpha), 0)
			t.fill.Size = Vector3.new(0.1, math.max(0.1, 8 * alpha), math.max(0.1, 8 * alpha))
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
						and math.abs(r.Position.Y - t.position.Y) <= 5
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
							hitPlayer(actor, guard.Position)
						end
					end
				end
			end
			if t.disc then
				t.disc:Destroy()
				t.fill:Destroy()
				t.rock:Destroy()
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
	if target and not visible(target, false) then
		a.lostTarget = target
		local s = actors[target]
		a.searchActor = s and s.hidePocket and target or nil
		a.target, a.mode, a.untilTime = nil, "Search", now + 3
		a.searchAt, a.sniffAt = a.lastSeen, now + 1
		if a.searchActor then
			a.searchAt = a.origin + vector(s.hidePocket.definition.opening)
			a.untilTime, a.sniffAt = now + 8, nil
		end
	end
	if not a.target or now - (a.targetSince or 0) >= 2 then
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
		a.mode, a.lostTarget, a.searchActor = "Patrol", nil, nil
	end
	a.warning.Text = a.mode == "Warn" and "!" or (a.mode == "Search" and "?" or "GUARDIAN / " .. a.mode)
	if a.mode == "Warn" then
		if target then
			local r = root(target)
			local towards = Vector3.new(r.Position.X, guard.Position.Y, r.Position.Z)
			if (towards - guard.Position).Magnitude > 0.1 then
				guard.CFrame = CFrame.lookAt(guard.Position, towards)
			end
			goal(target, "! / move: 1.2s warning")
		end
		return
	end
	local destination
	if target and a.mode == "Chase" then
		a.chaseTicks += 1
		local s, r = actors[target], root(target)
		destination = r.Position
		goal(target, "RUN! / dodge the red disc")
		local distance = (r.Position - guard.Position).Magnitude
		if now >= s.mercy and now >= a.nextThrow then
			if distance >= 12 and distance <= throwRange then
				attack(a, target, r.Position, now, false)
				return
			end
			local horizontal = (Vector3.new(r.Position.X, guard.Position.Y, r.Position.Z) - guard.Position).Magnitude
			if horizontal <= Config.CatchRadius and math.abs(r.Position.Y - (guard.Position.Y - 2.5)) <= 3 then
				attack(a, target, r.Position, now, true)
				return
			end
		end
	elseif a.mode == "Search" then
		destination = a.searchAt
		if a.searchActor then
			local s, r = actors[a.searchActor], root(a.searchActor)
			if
				s
				and r
				and s.phase == "Run"
				and (guard.Position - destination - Vector3.new(0, 5.5, 0)).Magnitude < 3
			then
				a.sniffAt = a.sniffAt or now
				a.untilTime = math.max(a.untilTime, a.sniffAt + 2)
				local eye = Vector3.new(guard.Position.X, destination.Y + 3, guard.Position.Z)
				-- Opening poke uses a crouched eye, never a ray through the log wall.
				if
					not s.hidden
					and now >= s.mercy
					and now >= a.nextThrow
					and (eye - r.Position).Magnitude <= 4
					and Arena.sight(a, eye, r.Position)
				then
					attack(a, a.searchActor, r.Position, now, true)
					return
				end
			end
		end
	else
		local patrols = { Vector3.new(8, 4, 32), Vector3.new(0, 0, 8), Vector3.new(-16, 0, -28) }
		destination = a.origin + patrols[a.patrol]
		if (guard.Position - destination - Vector3.new(0, 5.5, 0)).Magnitude < 3 then
			a.patrol = a.patrol % #patrols + 1
		end
	end
	if not destination then
		return
	end
	if a.mode == "Search" and a.sniffAt and now >= a.sniffAt then
		return
	end -- Two-second sniff.
	if now >= a.nextPath and not a.computing then
		a.nextPath, a.computing = now + 0.7, true
		local requested = destination
		task.spawn(function()
			local path =
				Pathfinding:CreatePath({ AgentRadius = 2, AgentHeight = 11, AgentCanJump = false, WaypointSpacing = 3 })
			local ok = pcall(function()
				path:ComputeAsync(guard.Position - Vector3.new(0, 4.5, 0), requested)
			end)
			if a.model.Parent and ok and path.Status == Enum.PathStatus.Success then
				a.points, a.index = path:GetWaypoints(), 2
			end
			path:Destroy()
			a.computing = false
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
	local movement = offset.Unit
		* math.min(offset.Magnitude, (a.mode == "Chase" and Config.CarrySpeed * Config.ChaseRatio or 7) * dt)
	local nextPoint = guard.Position + movement
	local floor = Arena.floor(a, nextPoint)
	local blocked = workspace:Blockcast(guard.CFrame, Vector3.new(4, 10, 4), movement, a.wallParams)
	if
		floor
		and not blocked
		and not Arena.safe(a, floor)
		and math.abs(floor.Y - (guard.Position.Y - 5.5)) <= movement.Magnitude * 0.5 + 0.25
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
return Arena
