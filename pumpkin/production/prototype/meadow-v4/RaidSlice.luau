-- Authored surface forks share one state machine. No player attacks or health.
local R = {}
local V = Vector3.new
R.Tuning = {
	Tell = 1.5,
	Warning = 1.2,
	Charge = 0.45,
	Recover = 1,
	Lifetime = 18,
	Radius = 2.6,
	VaultSeconds = 0.38,
	VaultCooldown = 1,
}
R.Lanes = { { V(-88, 0, 48), V(-98, 0, 48) }, { V(-88, 0, 58), V(-98, 0, 58) } }
R.Wall = V(-98, 1.12, 53)
R.Bypass = { V(-98, 0, 48), V(-92, 0, 48), V(-92, 0, 58), V(-98, 0, 58) }
R.Connectors = {
	{ V(-96, 0, 40), V(-88, 0, 40) },
	{ V(-88, 0, 40), V(-88, 0, 48) },
	{ V(-88, 0, 48), V(-88, 0, 58) },
	{ V(-98, 0, 48), V(-92, 0, 48) },
	{ V(-92, 0, 48), V(-92, 0, 58) },
	{ V(-92, 0, 58), V(-98, 0, 58) },
	{ V(-92, 0, 58), V(-88, 0, 66) },
}
R.Encounters = {
 {name='RaidJunction', lanes=R.Lanes, wall=R.Wall, bypass=R.Bypass, connectors=R.Connectors,
  approach=V(-94,3,40), min=V(-108,-1,36), max=V(-84,7,70), escapes=0},
 {name='RaidJunctionEast', markLift=0.44,
  lanes={{V(116,20,43),V(106,20,43)},{V(116,20,53),V(106,20,53)}},
  wall=V(106,21.12,48), bypass={V(106,20,43),V(112,20,43),V(112,20,53),V(106,20,53)},
  connectors={{V(108,20,42),V(116,20,42)},{V(116,20,42),V(116,20,43)},
   {V(116,20,43),V(116,20,53)},{V(106,20,43),V(112,20,43)},
   {V(112,20,43),V(112,20,53)},{V(112,20,53),V(106,20,53)}},
  approach=V(106,23,42), min=V(102,19,41), max=V(119,27,60), escapes=1},
}
function R.encounterAt(p)
 for _,e in R.Encounters do
  if p.X>=e.min.X and p.X<=e.max.X and p.Y>=e.min.Y and p.Y<=e.max.Y
   and p.Z>=e.min.Z and p.Z<=e.max.Z then return e end
 end
 return nil
end
function R.wallFor(a,p)
 local selected,dist=nil,math.huge
 for _,e in R.Encounters do
  local d=(p-a.origin-e.wall).Magnitude
  if d<dist then selected,dist=e,d end
 end
 local map=selected and a.v4:FindFirstChild(selected.name)
 return map and map:FindFirstChild('JumpVaultWall'),selected
end
local amber, green = Color3.fromRGB(255, 190, 65), Color3.fromRGB(108, 163, 66)
local function part(parent, name, size, p, color, solid)
	local q = Instance.new("Part")
	q.Name, q.Size, q.CFrame, q.Color = name, size, CFrame.new(p), color
	q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch = true, solid == true, solid == true, false
	q.Material, q.Parent = Enum.Material.SmoothPlastic, parent
	return q
end
local function buildEncounter(map, origin, e)
	local markLift=e.markLift or 0
	local old = map:FindFirstChild(e.name)
	if old then
		return old
	end
	local m = Instance.new("Model")
	m.Name = e.name
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for i, lane in e.lanes do
		local mid = (lane[1] + lane[2]) / 2 + origin
		local stripe = part(
			m,
			"Lane" .. i,
			V((lane[2] - lane[1]).Magnitude, 0.06, 5),
			mid + V(0, 0.18+markLift, 0),
			Color3.fromRGB(152, 128, 89)
		)
		stripe:SetAttribute("RaidLane", i)
		for step = 2, 10, 4 do
			local x = lane[1].X-step
			local arrow = part(m, "Arrow" .. i, V(1.6, 0.08, 1.6), origin + V(x, lane[1].Y+0.26+markLift, lane[1].Z), amber)
			arrow.Size = V(1.8, 0.08, 0.3)
			arrow.CFrame *= CFrame.Angles(0, math.rad(40), 0)
			local wing = arrow:Clone()
			wing.CFrame = CFrame.new(origin + V(x, lane[1].Y+0.26+markLift, lane[1].Z + 0.95))
				* CFrame.Angles(0, math.rad(-40), 0)
			wing.Parent = m
			arrow.Material, arrow.Transparency = Enum.Material.Neon, 0.75
		end
	end
	for _, edge in e.connectors do
		local d = edge[2] - edge[1]
		local mid = (edge[1] + edge[2]) / 2 + origin + V(0, 0.18+markLift, 0)
		local path = part(m, "ForkPath", V(3, 0.05, d.Magnitude), mid, Color3.fromRGB(152, 128, 89))
		path.CFrame = CFrame.lookAt(mid, mid + d)
	end
	local wall = part(m, "JumpVaultWall", V(2.8, 2, 1), origin + e.wall, Color3.fromRGB(115, 79, 47), true)
	wall:SetAttribute("RaidVaultWall", true)
	wall:SetAttribute("SurfaceRole", "Cover")
	local sign = Instance.new("SurfaceGui")
	sign.Face = Enum.NormalId.Front
	sign.CanvasSize = Vector2.new(320, 90)
	sign.Parent = wall
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text, text.Font, text.TextScaled, text.TextColor3 =
		"JUMP TO VAULT", Enum.Font.FredokaOne, true, Color3.fromRGB(255, 239, 202)
	text.Parent = sign
	local back = sign:Clone()
	back.Face = Enum.NormalId.Back
	back.Parent = wall
	m.Parent = map
	return m
end
function R.build(map,origin)
 for _,e in R.Encounters do buildEncounter(map,origin,e) end
 return map:FindFirstChild('RaidJunction')
end
local function flat(p)
	return V(p.X, 0, p.Z)
end
local function distance(p, a, b)
	local d = flat(b - a)
	local t = math.clamp(flat(p - a):Dot(d) / d:Dot(d), 0, 1)
	return (flat(p - a) - d * t).Magnitude
end
R.distance = distance
function R.clear(a)
	if a.raid then
		a.raid.model:Destroy()
		a.raid = nil
	end
	for _,e in R.Encounters do
	local map = a.v4 and a.v4:FindFirstChild(e.name)
	if map then
		for _, q in map:GetChildren() do
			if q:IsA("BasePart") and q.Name:match("^Arrow") then
				q.Transparency = 0.75
			end
		end
	end
	end
	a.raidBusy = false
end
function R.ready(a, actor, serial, now)
	local c = a.raid and a.raid.commit
	if c and c.serial == serial and not c.ready[actor] then
		c.ready[actor] = now
	end
end
local function creature(parent, index, p)
	local m = Instance.new("Model")
	m.Name = "SproutRunner" .. index
	m.Parent = parent
	local body = part(m, "Body", V(2.2, 2, 1.8), p + V(0, 1.1, 0), green)
	body.Shape = Enum.PartType.Ball
	for _, x in { -0.5, 0.5 } do
		local eye = part(m, "Eye", V(0.28, 0.36, 0.22), p + V(x, 1.4, -0.87), Color3.fromRGB(35, 43, 30))
		eye.Shape = Enum.PartType.Ball
		local foot = part(m, "Foot", V(0.7, 0.4, 1), p + V(x, 0.25, -0.2), Color3.fromRGB(110, 76, 48))
		foot.Shape = Enum.PartType.Ball
	end
	local stem = part(m, "Stem", V(0.25, 0.7, 0.25), p + V(0, 2.35, 0), green)
	local leaf = part(m, "Leaf", V(1.5, 0.35, 0.65), p + V(0.45, 2.65, 0), Color3.fromRGB(147, 190, 77))
	leaf.Shape = Enum.PartType.Ball
	stem.CFrame *= CFrame.Angles(0, 0, -0.25)
	m.PrimaryPart = body
	return m
end
local function begin(a, now, api, e)
	local model = Instance.new("Model")
	model.Name = "RaidSquad"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model:SetAttribute('Encounter',e.name)
	model.Parent = a.model
	local r = { model = model, encounter=e, start = now, index = 0, nextAt = now, units = {}, serial = 0 }
	for i, lane in e.lanes do
		r.units[i] = creature(model, i, a.origin + lane[1])
	end
	a.raid = r
	a.raidCleanup = function()
		R.clear(a)
	end
	-- Persistent lifetime key: cargo drop, handoff and recovery never spawn a second pair.
	a.raidItem = api.itemId
end
local function corridor(a, api, e)
	-- Both lanes and the walking switch must be legal before any reservation.
	for _, lane in e.lanes do
		for t = 0, 16 do
			local p = a.origin + lane[1]:Lerp(lane[2], t / 16)
			local floor = api.floor(a, p + V(0, 3, 0))
			if not floor or math.abs(floor.Y - p.Y) > 0.6 or api.safe(a, floor, 4) then
				return false
			end
		end
	end
	return true
end
function R.tick(a, dt, now, actors, root, hit, api, loot)
	local r = a.raid
	local tunnel = script and script.Parent:FindFirstChild("TunnelPolicy")
	if tunnel then
		local policy = require(tunnel)
		for actor, s in actors do
			local q = root(actor)
			if s.run == a and q then
				local p = q.Position - a.origin
				if policy.inside(p.X, p.Y, p.Z) then
					R.clear(a)
					a.raidTunnelUntil = now + 2
					return false
				end
			end
		end
	end
	if now < (a.raidTunnelUntil or 0) then
		return false
	end
	local active = loot and (loot.state == "Carried" or loot.state == "Dropped")
	if not active then
		R.clear(a)
		return false
	end
	if r and (a.tunnelGuard or a.attack or a.decoy or a.keeperStunUntil and now < a.keeperStunUntil) then
		R.clear(a)
		return false -- Intercept/reset wins; never stack with a tunnel threat.
	end
	if not r then
		if
			a.raidItem == loot.id
			or a.attack
			or a.tunnelGuard
			or a.decoy
			or a.recoveryStarted
			or a.keeperStunUntil and now < a.keeperStunUntil
		then
			return false
		end
		local holder = loot.holder
		local s = holder and actors[holder]
		local q = holder and root(holder)
		if not s or not q or s.run ~= a or now < (s.mercy or 0) + 0.5 then
			return false
		end
		local p = q.Position - a.origin
		local e=R.encounterAt(p)
		if not e or (s.meadowEscapes or 0)<e.escapes then
			return false
		end
		if not corridor(a, api, e) then
			return false
		end
		-- No spawning on entrants, dropped loot or the player's recovery space.
		for _, lane in e.lanes do
			local spawn = a.origin + lane[1]
			for actor, state in actors do
				local rr = root(actor)
				if state.run == a and rr and (rr.Position - spawn).Magnitude < 7 then
					return false
				end
			end
			if loot.position and (loot.position - spawn).Magnitude < 7 then
				return false
			end
		end
		begin(a, now, { itemId = loot.id },e)
		r = a.raid
	end
	if now - r.start > R.Tuning.Lifetime then
		R.clear(a)
		return false
	end
	a.raidBusy = true
	local c = r.commit
	if not c and now >= r.nextAt then
		r.index += 1
		if r.index > 2 then
			R.clear(a)
			a.nextThrow = math.max(a.nextThrow or 0, now + 1)
			return false
		end
		r.serial += 1
		c = {
			lane = r.index,
			serial = (a.raidSerial or 0) + 1,
			start = now,
			ready = {},
			hit = {},
			previous = 0,
		}
		a.raidSerial = c.serial
		r.commit = c
		r.model:SetAttribute("TellLane", c.lane)
		r.model:SetAttribute("TellSerial", c.serial)
		r.model:SetAttribute("TellStarted", workspace:GetServerTimeNow())
		a.keeperMode = "Command"
		a.keeperClip = "warn"
		a.keeperClipStart = now
		a.guardian:SetAttribute("KeeperMode", "Command")
		a.guardian:SetAttribute("KeeperClip", "warn")
		a.guardian:SetAttribute("KeeperElapsed", 0)
		a.guardian:SetAttribute("KeeperStartedAt", workspace:GetServerTimeNow())
		a.guardian:SetAttribute("KeeperLookTarget", a.origin + r.encounter.lanes[c.lane][1])
		a.warning.Text = "! / SQUAD: CHOOSE THE OTHER LANE"
		local map = a.v4:FindFirstChild(r.encounter.name)
		if map then
			for _, q in map:GetChildren() do
				if q:IsA("BasePart") and q.Name == "Arrow" .. c.lane then
					q.Transparency = 0.05
				end
			end
		end
	end
	if not c then
		return true
	end
	local age = now - c.start
	local lane = r.encounter.lanes[c.lane]
	local start, finish = a.origin + lane[1], a.origin + lane[2]
	local t = math.clamp((age - R.Tuning.Tell) / R.Tuning.Charge, 0, 1)
	local unit = r.units[c.lane]
	local shift = start:Lerp(finish, t) + V(0, 1.1, 0) - unit.PrimaryPart.CFrame.Position
	for _, q in unit:GetChildren() do
		if q:IsA("BasePart") then
			q.CFrame += shift
		end
	end
	if age >= R.Tuning.Tell and age < R.Tuning.Tell + R.Tuning.Charge then
		r.model:SetAttribute("Charging", true)
		for actor, s in actors do
			local q = root(actor)
			local warned = c.ready[actor]
			if
				q
				and s.run == a
				and s.phase == "Run"
				and not c.hit[actor]
				and warned
				and now - warned >= R.Tuning.Warning
				and now >= (s.mercy or 0) + 0.5
				and not api.safe(a, q.Position, 3)
				and math.abs(q.Position.Y - start.Y - 3) < 4
				and distance(q.Position, start:Lerp(finish, c.previous), start:Lerp(finish, t))
					<= R.Tuning.Radius
			then
				c.hit[actor] = true
				hit(actor, start, "Guardian") -- Existing reachable knock/drop/mercy, no HP.
			end
		end
	end
	c.previous = t
	if age >= R.Tuning.Tell + R.Tuning.Charge + R.Tuning.Recover then
		r.model:SetAttribute("Charging", false)
		r.model:SetAttribute("TellLane", nil)
		local map = a.v4:FindFirstChild(r.encounter.name)
		if map then
			for _, q in map:GetChildren() do
				if q:IsA("BasePart") and q.Name == "Arrow" .. c.lane then
					q.Transparency = 0.75
				end
			end
		end
		r.units[c.lane]:Destroy()
		r.commit = nil
		r.nextAt = now + 0.3
	end
	return true -- Guardian's full attack opportunity is traded for this finite squad.
end
function R.vaultTarget(a, p, intent, jump, now, last, api)
	if not jump or now - (last or -math.huge) < R.Tuning.VaultCooldown or intent.Magnitude < 0.1 then
		return nil
	end
	local localP = p - a.origin
	local e=R.encounterAt(localP)
	if not e then return nil end
	local wall=e.wall
	local side = localP.Z < wall.Z and 1 or -1
	if
		math.abs(localP.X - wall.X) > 0.9
		or math.abs(localP.Z - wall.Z) > 4.5
		or math.abs(localP.Z - wall.Z) < 1.3
		or math.abs(localP.Y - wall.Y - 2) > 2
		or intent.Unit:Dot(V(0, 0, side)) < 0.65
	then
		return nil
	end
	local target = a.origin + V(localP.X, wall.Y+2, wall.Z + side * 4)
	if not api.vaultClear(a, p, target) then
		return nil
	end
	return target
end
function R.vaultPoint(start, target, t)
	return start:Lerp(target, t) + V(0, math.sin(t * math.pi) * 3, 0)
end
function R.vaultClear(a, start, target, character)
	local wall = R.wallFor(a,start)
	if not wall then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and { character, wall } or { wall }
	-- Complete two-stud landing footprint, grounded path, overhead and swept body.
	for _, offset in { V(0, 0, 0), V(1, 0, 1), V(-1, 0, 1), V(1, 0, -1), V(-1, 0, -1) } do
		local q = target + offset
		local floor = workspace:Raycast(q + V(0, 1, 0), V(0, -6, 0), params)
		if
			not floor
			or floor.Instance:GetAttribute("SurfaceRole") ~= "Floor"
			or math.abs(floor.Position.Y - (target.Y - 3)) > 0.4
			or floor.Normal.Y < 0.9
		then
			return false
		end
	end
	local previous = start
	for i = 1, 16 do
		local p = R.vaultPoint(start, target, i / 16)
		local delta = p - previous
		if workspace:Blockcast(CFrame.new(previous), V(2, 4, 2), delta, params) then
			return false
		end
		if
			#workspace:GetPartBoundsInBox(CFrame.new(p), V(1.9, 3.9, 1.9), R.overlapParams(character, wall))
			> 0
		then
			return false
		end
		previous = p
	end
	return true
end
function R.overlapParams(character, wall)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and { character, wall } or { wall }
	params.RespectCanCollide = true
	return params
end
return R
