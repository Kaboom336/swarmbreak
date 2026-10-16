-- Authoritative, upload-free kit. Hit acceptance/mercy/drop remain with hitPlayer.
local Kit = {}
Kit.Tuning = {
	Interval = 5.5,
	FanLeadSeconds = 1.25,
	FanLeadMax = 18,
	LobLeadSeconds = 1.25,
	LobLeadMax = 16,
	FanRange = 32,
	FanHeight = 1.5,
	LobRadius = 8,
	LobSize = 8,
	DashTell = 0.5,
	DashSpeed = 48,
	DashDistance = 24,
	DashCooldown = 12,
	DashStun = 1.55,
	LobRelease = 0.62,
	LobFlight = 0.90,
	LobCooldown = 10,
	FanAngle = 16,
	FanSize = 2.4,
	FanRelease = 0.62,
	FanFlight = 0.70,
	FanCooldown = 8,
	SlamRange = 12,
	SlamLand = 0.80,
	SlamRadius = 22,
	SlamSpeed = 24,
	SlamWidth = 1.2,
	JumpClearance = 2.5,
	SlamCooldown = 9,
	Height = 7,
}
local T = Kit.Tuning
local function fx(api, a, name, position, radius)
	if api.fx then
		api.fx(a, name, position, radius)
	end
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function part(a, name, size, position, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position, p.Color = name, size, position, color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Material, p.Parent = Enum.Material.Neon, a.model
	table.insert(a.attack.parts, p)
	return p
end
local red = Color3.fromRGB(255, 45, 50)
local amber = Color3.fromRGB(255, 190, 35)
local function ring(a, position, _radius, color)
	local result = {}
	for i = 0, 39 do
		local angle = i * math.pi / 20
		local p = part(a, "KeeperRing", Vector3.new(0.25, 0.12, 1), position, color)
		table.insert(result, { part = p, angle = angle })
	end
	return result
end
local function resizeRing(segments, center, radius)
	for _, entry in ipairs(segments) do
		local angle, p = entry.angle, entry.part
		local pos = center + Vector3.new(math.cos(angle) * radius, 0.14, math.sin(angle) * radius)
		p.Size = Vector3.new(0.25, 0.12, math.max(0.1, radius * math.pi / 20 + 0.12))
		p.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(angle), 0, math.cos(angle)))
	end
end
function Kit.clear(a)
	if a.attack and a.attack.parts then
		for _, p in ipairs(a.attack.parts) do
			p:Destroy()
		end
	end
	a.attack = nil
end
function Kit.choose(a, target, now, actors, root)
	local r = root(target)
	local distance = flat(r.Position - a.guardian.Position).Magnitude
	local kind = distance <= T.SlamRange and "slam" or "fan"
	if distance > T.FanRange then
		kind = "lob"
	end
	if kind == "fan" and math.abs(r.Position.Y - 3 - (a.guardian.Position.Y - 5.5)) > T.FanHeight then
		kind = "lob"
	end
	for actor, s in pairs(actors) do
		local other = actor ~= target and s.phase == "Run" and root(actor)
		if other and flat(other.Position - r.Position).Magnitude <= 10 and distance > T.SlamRange then
			kind = "lob"
		end
	end
	if kind == "slam" and math.abs(r.Position.Y - (a.guardian.Position.Y - 5.5)) > T.Height then
		return nil
	end
	-- Alternate the mid-range fan with a committed straight charge. No homing.
	local awayFromCorner = not a.wallBaitCorner or flat(a.guardian.Position - a.wallBaitCorner).Magnitude > 28
	if kind == "fan" and awayFromCorner and distance <= 28 and (a.throws or 0) % 2 == 1 and now >= ((a.kitCooldowns or {}).dash or 0) then
		kind = "dash"
	end
	if now < ((a.kitCooldowns or {})[kind] or 0) then
		return nil
	end
	return kind
end
function Kit.begin(a, actor, position, now, kind, api, pose)
	local floor = api.floor(a, kind == "slam" and a.guardian.Position or position)
	if
		not floor
		or api.safe(a, floor, kind == "lob" and T.LobRadius or kind == "slam" and T.SlamRadius or T.FanSize / 2)
	then
		return false
	end
	if (kind == "fan" or kind == "dash") and math.abs(floor.Y - (a.guardian.Position.Y - 5.5)) > T.FanHeight then
		return false -- Prediction over a hill cannot create an unsafe upward fan arc.
	end
	if kind ~= "slam" and flat(floor - a.guardian.Position).Magnitude < T.SlamRange then
		return false -- Closing targets enter the slam zone instead of a point-blank projectile arc.
	end
	local toward = flat(position - a.guardian.Position)
	if toward.Magnitude < 0.1 then
		toward = a.guardian.CFrame.LookVector
	end
	a.guardian.CFrame = CFrame.lookAt(a.guardian.Position, a.guardian.Position + toward)
	local release = kind == "dash" and T.DashTell
		or kind == "slam" and T.SlamLand
		or kind == "lob" and T.LobRelease
		or T.FanRelease
	local duration = kind == "slam" and T.SlamLand + T.SlamRadius / T.SlamSpeed
		or release + (kind == "lob" and T.LobFlight or T.FanFlight)
	if kind == "dash" then
		duration = release + T.DashDistance / T.DashSpeed
	end
	a.attack = {
		kind = kind,
		actor = actor,
		position = floor,
		start = now,
		release = release,
		duration = duration,
		parts = {},
		hit = {},
		projectiles = {},
		direction = toward.Unit,
		dashOrigin = a.guardian.Position,
	}
	if kind == "dash" then
		a.model:SetAttribute("DashStopReason", nil)
		a.model:SetAttribute("DashStopCollider", nil)
	end
	a.kitCooldowns = a.kitCooldowns or {}
	a.kitCooldowns[kind] = now
		+ (
			kind == "dash" and T.DashCooldown
			or kind == "lob" and T.LobCooldown
			or kind == "fan" and T.FanCooldown
			or T.SlamCooldown
		)
	a.nextThrow = now + T.Interval
	a.throws += 1
	a.warning.Text = kind == "dash" and "CHARGE / step aside"
		or kind == "slam" and "JUMP / shockwave"
		or kind == "fan" and "ACORNS / change direction"
		or "BOULDER / leave ring"
	a.model:SetAttribute("TelegraphStarted", now)
	a.model:SetAttribute("KeeperAttack", kind)
	a.model:SetAttribute("KeeperImpactDue", now + release + (kind == "slam" and 0 or duration - release))
	fx(api, a, kind .. "Windup", a.guardian.Position - Vector3.new(0, 5.5, 0))
	if kind == "dash" then
		local endPoint = a.guardian.Position + toward.Unit * T.DashDistance
		local lane = part(
			a,
			"ChargeLane",
			Vector3.new(4, 0.12, T.DashDistance),
			(a.guardian.Position + endPoint) / 2 - Vector3.new(0, 5.35, 0),
			red
		)
		lane.CFrame = CFrame.lookAt(lane.Position, endPoint - Vector3.new(0, 5.35, 0))
	elseif kind ~= "fan" then
		a.attack.ring = ring(a, floor, kind == "lob" and T.LobRadius or T.SlamRadius, kind == "slam" and amber or red)
		resizeRing(a.attack.ring, floor, kind == "lob" and T.LobRadius or T.SlamRadius)
	else
		local from = pose.release(a.guardian, kind, release).Position
		local origin = api.floor(a, from)
		if not origin then
			Kit.clear(a)
			return false
		end
		for _, degrees in ipairs({ -T.FanAngle, 0, T.FanAngle }) do
			local destination = from
				+ CFrame.Angles(0, math.rad(degrees), 0):VectorToWorldSpace(floor + Vector3.new(0, 3, 0) - from)
			local endPoint = Vector3.new(destination.X, origin.Y, destination.Z)
			local lane = part(
				a,
				"AcornLane",
				Vector3.new(0.24, 0.10, (endPoint - origin).Magnitude),
				(origin + endPoint) / 2 + Vector3.new(0, 0.12, 0),
				red
			)
			lane.CFrame = CFrame.lookAt(lane.Position, endPoint + Vector3.new(0, 0.12, 0))
		end
	end
	return true
end
local function segmentDistance(p, from, to)
	local delta = to - from
	local alpha = delta:Dot(delta) > 1e-6 and math.clamp((p - from):Dot(delta) / delta:Dot(delta), 0, 1) or 0
	return (p - from - delta * alpha).Magnitude
end
function Kit.step(a, now, actors, root, hitPlayer, api, pose)
	local t, guard = a.attack, a.guardian
	local elapsed = now - t.start
	local function accept(actor, s, r, legal)
		if
			legal
			and not t.hit[actor]
			and s.phase == "Run"
			and not api.safe(a, r.Position)
			and api.sight(a, t.position + Vector3.new(0, 0.5, 0), r.Position)
		then
			t.hit[actor] = true
			if hitPlayer(actor, guard.Position) then
				a.keeperCelebrateUntil = now + 1.9
				fx(api, a, "PlayerHit", r.Position)
				if t.kind == "fan" then
					fx(api, a, "AcornPop", r.Position)
				end
			end
		end
	end
	if elapsed >= t.release and not t.released then
		t.released = true
		a.model:SetAttribute("KeeperReleaseAt", t.start + t.release)
		a.model:SetAttribute("KeeperReleaseObservedAt", now)
		fx(
			api,
			a,
			t.kind .. "Release",
			t.kind == "slam" and t.position or guard.Position,
			t.kind == "slam" and T.SlamRadius or nil
		)
		if t.kind ~= "slam" and t.kind ~= "dash" then
			local from = pose.release(guard, t.kind, t.release).Position
			a.model:SetAttribute("KeeperReleaseOrigin", from)
			for _, degrees in ipairs(t.kind == "fan" and { -T.FanAngle, 0, T.FanAngle } or { 0 }) do
				local destination = t.position + Vector3.new(0, t.kind == "fan" and 3 or 2, 0)
				if t.kind == "fan" then
					destination = from + CFrame.Angles(0, math.rad(degrees), 0):VectorToWorldSpace(destination - from)
				end
				local size = t.kind == "lob" and T.LobSize or T.FanSize
				local p = part(
					a,
					t.kind == "lob" and "KeeperBoulder" or "KeeperAcorn",
					Vector3.new(size, size, size),
					from,
					Color3.fromRGB(130, 98, 65)
				)
				p.Shape, p.Material = Enum.PartType.Ball, Enum.Material.Slate
				p:SetAttribute("KeeperProjectile", t.kind)
				p:SetAttribute("KeeperProjectileStarted", now)
				local cap
				if t.kind == "fan" then
					cap = part(
						a,
						"AcornCap",
						Vector3.new(size * 1.05, size * 0.45, size * 1.05),
						from,
						Color3.fromRGB(75, 48, 27)
					)
					cap.Shape, cap.Material = Enum.PartType.Ball, Enum.Material.Wood
					-- Client replaces this collision-neutral cap with the approved acorn mesh.
					cap.Transparency = 1
				end
				table.insert(
					t.projectiles,
					{ part = p, cap = cap, from = from, previous = from, destination = destination, size = size }
				)
			end
		elseif t.kind == "slam" then
			for _, entry in ipairs(t.ring) do
				entry.part.Transparency = 0.75
			end
			t.wave = ring(a, t.position, 0, amber)
		end
	end
	if t.kind == "dash" and t.released then
		local nextPoint = t.dashOrigin
			+ t.direction * math.min(T.DashDistance, math.max(0, elapsed - T.DashTell) * T.DashSpeed)
		local delta = nextPoint - guard.Position
		-- Cover carriers survive KitSwap. Floor seams are checked by floor()
		-- below; their side faces must not consume a charge before real cover.
		local wall = delta.Magnitude > 0.001 and workspace:Blockcast(guard.CFrame, guard.Size, delta, a.wallParams or a.params)
		local floor = api.floor(a, nextPoint)
		local leashed = not api.dashLegal or api.dashLegal(a, nextPoint)
		local safe = api.safe(a, nextPoint, 3)
		-- A tagged cover's footing may be returned by the floor probe just
		-- before the body sweep reaches its face. Only bridge the existing
		-- step tolerance, never an arbitrary gap or a different obstacle.
		if not wall and delta.Magnitude > 0.001 and leashed and not safe
			and (not floor or math.abs(floor.Y-(guard.Position.Y-5.5)) > T.FanHeight) then
			local near = workspace:Blockcast(guard.CFrame, guard.Size, delta + t.direction*T.FanHeight, a.wallParams or a.params)
			if near and near.Normal.Y < 0.5 and near.Instance:GetAttribute("OutsmartBaitCover")
				and math.abs(near.Instance.CFrame.Position.Y-near.Instance.Size.Y/2-(guard.Position.Y-5.5)) <= T.FanHeight then
				wall = near
			end
		end
		a.model:SetAttribute("DashStopCollider", wall and wall.Instance:GetFullName() or nil)
		if
			wall
			or not floor
			or math.abs(floor.Y - (guard.Position.Y - 5.5)) > T.FanHeight
			or safe
			or not leashed
		then
			a.model:SetAttribute("DashStopReason", wall and "collision" or not floor and "missing floor"
				or math.abs(floor.Y - (guard.Position.Y - 5.5)) > T.FanHeight and "floor height"
				or not leashed and "leash/tunnel" or "safe zone")
			-- Only a vertical cover impact earns stars. Floor/lip/leash stops do not.
			-- Keep the last fooled corner across navigation resets: waiting here
			-- cannot refresh a stun or repeatedly select charges into this cover.
			if wall and wall.Normal.Y < 0.5 and wall.Instance:GetAttribute("SurfaceRole") == "Cover"
				and leashed and not safe
				and (not a.wallBaitCorner or flat(wall.Position - a.wallBaitCorner).Magnitude > 28) then
				a.wallBaitCorner = wall.Position
				a.keeperStunUntil = now + T.DashStun
				a.model:SetAttribute("WallBaitAt", now)
				a.model:SetAttribute("WallBaitCorner", wall.Position)
				fx(api, a, "WallStun", guard.Position + Vector3.new(0, 5, 0))
			end
			Kit.clear(a)
			return
		end
		for actor, s in pairs(actors) do
			local r = root(actor)
			if r then
				accept(
					actor,
					s,
					r,
					segmentDistance(r.Position, guard.Position, nextPoint) <= 3
						and math.abs(r.Position.Y - nextPoint.Y) <= 5
				)
			end
		end
		guard.CFrame = CFrame.lookAt(
			Vector3.new(nextPoint.X, floor.Y + 5.5, nextPoint.Z),
			Vector3.new(nextPoint.X, floor.Y + 5.5, nextPoint.Z) + t.direction
		)
	end
	for _, projectile in ipairs(t.projectiles) do
		if not projectile.blocked then
			local flight = math.clamp((elapsed - t.release) / (t.duration - t.release), 0, 1)
			local nextPoint = projectile.from:Lerp(projectile.destination, flight)
				+ Vector3.new(0, (t.kind == "lob" and 36 or 3) * flight * (1 - flight), 0)
			local delta = nextPoint - projectile.previous
			local obstruction = delta.Magnitude > 0.001
				and workspace:Spherecast(projectile.previous, projectile.size / 2, delta, a.params)
			if obstruction then
				-- A lob's floor landing is expected; all intervening cover cancels it.
				local landingFloor = obstruction.Instance
					and obstruction.Instance:GetAttribute("SurfaceRole") == "Floor"
					and obstruction.Normal.Y > 0.7
					and (obstruction.Position - t.position).Magnitude <= T.LobSize
				projectile.blocked = t.kind ~= "lob" or not landingFloor
				if projectile.blocked then
					fx(api, a, t.kind == "fan" and "AcornPop" or "LogBlocked", obstruction.Position)
					projectile.part.Transparency = 1
					if projectile.cap then
						projectile.cap.Transparency = 1
					end
				end
			end
			if t.kind == "fan" and not projectile.blocked then
				for actor, s in pairs(actors) do
					local r = root(actor)
					if r then
						accept(
							actor,
							s,
							r,
							segmentDistance(r.Position, projectile.previous, nextPoint) <= projectile.size / 2 + 1
						)
					end
				end
			end
			projectile.part.CFrame = CFrame.new(nextPoint) * CFrame.Angles(flight * 12, 0, 0)
			projectile.previous = nextPoint
			if projectile.cap then
				projectile.cap.Position = nextPoint + Vector3.new(0, projectile.size * 0.38, 0)
			end
		end
	end
	if t.kind == "slam" and t.released then
		local radius = math.min(T.SlamRadius, (elapsed - T.SlamLand) * T.SlamSpeed)
		resizeRing(t.wave, t.position, radius)
		for actor, s in pairs(actors) do
			local r = root(actor)
			if r then
				local distance = flat(r.Position - t.position).Magnitude
				local previousDistance = t.distances and t.distances[actor] or distance
				local previousRadius = t.radius or 0
				local crossed = math.min(previousDistance - previousRadius, distance - radius) <= T.SlamWidth
					and math.max(previousDistance - previousRadius, distance - radius) >= -T.SlamWidth
				local floor = api.floor(a, r.Position)
				local feet = r.Position.Y - 3
				accept(
					actor,
					s,
					r,
					crossed
						and floor ~= nil
						and math.abs(floor.Y - t.position.Y) <= T.JumpClearance
						and feet - floor.Y <= T.JumpClearance
						and feet >= floor.Y - 1
				)
				t.distances = t.distances or {}
				t.distances[actor] = distance
			end
		end
		t.radius = radius
	end
	if elapsed >= t.duration then
		if t.kind == "lob" and t.projectiles[1] and not t.projectiles[1].blocked then
			fx(api, a, "lobImpact", t.position, T.LobRadius)
			for actor, s in pairs(actors) do
				local r = root(actor)
				if r then
					accept(
						actor,
						s,
						r,
						flat(r.Position - t.position).Magnitude <= T.LobRadius
							and math.abs(r.Position.Y - t.position.Y) <= T.Height
					)
				end
			end
		end
		a.impacts += 1
		a.model:SetAttribute("LastImpactAt", now)
		a.model:SetAttribute("LastImpactDelay", elapsed)
		Kit.clear(a)
	end
end
return Kit
