-- Server-owned entry/charge/placement lifecycle. Geometry and presentation are injected
-- so offline tests execute the same validation without pretending to run physics.
local Traps = {}
Traps.RattleSignal, Traps.RattleTimeSignal = "Rattled", "RattleAt"
function Traps.new(config, arenaAPI, make, label)
	return {
		config = config.Traps,
		islandSize = config.IslandSize,
		arenaAPI = arenaAPI,
		make = make,
		label = label,
		active = {},
	}
end
function Traps.unlocked(t, actor, s)
	return (s.meadowEscapes or 0) >= t.config.UnlockEscapes or actor:GetAttribute("GreyboxDevTrapUnlock") == true
end
function Traps.remove(t, actor)
	for i = #t.active, 1, -1 do
		local trap = t.active[i]
		if not actor or trap.owner == actor then
			if trap.arena.decoy and trap.arena.decoy.trap == trap then
				trap.arena.decoy = nil
				trap.arena.decoyImmuneUntil = (trap.effectEnd or trap.expires) + t.config.Decoy.ImmunitySeconds
			end
			trap.part:Destroy()
			table.remove(t.active, i)
		end
	end
end
function Traps.entry(t, actor, s)
	Traps.remove(t, actor)
	s.trapCharge, s.trapPickedUp, s.trapHold = true, false, nil
	-- Deliberately preserve trapCooldown across entries.
end
function Traps.clearIsland(t, a)
	for i = #t.active, 1, -1 do
		local trap = t.active[i]
		if trap.arena == a then
			trap.part:Destroy()
			table.remove(t.active, i)
		end
	end
	a.decoy = nil
end
function Traps.spot(t, a, position, rootPosition)
	local c, api = t.config, t.arenaAPI
	if typeof(position) ~= "Vector3" then
		return false, "floor required"
	end
	for _, value in { position.X, position.Y, position.Z } do
		if value ~= value or math.abs(value) == math.huge then
			return false, "invalid coordinates"
		end
	end
	if (position - rootPosition).Magnitude > c.Range then
		return false, "trap range"
	end
	local p = position - a.origin
	local x, z = p.X, -p.Z
	if math.abs(x) > t.islandSize / 2 - c.ClearRadius or math.abs(z) > t.islandSize / 2 - c.ClearRadius then
		return false, "island edge"
	end
	local nest = a.layout.version == 4 and { x = 0, z = 96 } or { x = 0, z = 32 }
	if
		Vector3.new(x - nest.x, 0, z - nest.z).Magnitude < c.ProtectedMargin or api.safe(a, position, c.ProtectedMargin)
	then
		return false, "nest/spawn/portal margin"
	end
	-- Exclude all jump/recovery footprints and cross-link junctions, not just
	-- authored route centre lines. Remaining open floor is freely selectable.
	for _, g in a.layout.gullies do
		if math.abs(x - g.x) < g.w / 2 + c.ClearRadius and math.abs(z - g.z) < g.d / 2 + c.ClearRadius then
			return false, "jump recovery"
		end
	end
	for _, box in a.layout.solids do
		if string.find(box.name, "Jump", 1, true) or string.find(box.name, "Stone", 1, true) then
			if math.abs(x - box.x) < box.w / 2 + c.ClearRadius and math.abs(z - box.z) < box.d / 2 + c.ClearRadius then
				return false, "jump landing"
			end
		end
	end
	for _, link in a.layout.crossLinks do
		for _, point in link do
			if Vector3.new(x - point.x, 0, z - point.z).Magnitude < 12 then
				return false, "junction"
			end
		end
	end
	local floor = api.floor(a, position)
	if not floor or math.abs(floor.Y - position.Y) > 0.3 or math.abs(rootPosition.Y - floor.Y - 3) > 1.5 then
		return false, "reachable floor"
	end
	if not api.sight(a, rootPosition, floor + Vector3.new(0, 0.5, 0)) then
		return false, "trap sight"
	end
	-- Check an entire 18x18 flat walking envelope, including headroom. This
	-- rejects cover tops, narrow bridges, ramps and ledges; visuals never collide.
	for ix = -6, 6 do
		for iz = -6, 6 do
			local sample = floor + Vector3.new(ix * 1.5, 0, iz * 1.5)
			local f, normal = api.floor(a, sample)
			if
				not f
				or not normal
				or normal.Y < math.cos(math.rad(c.MaxSlope))
				or math.abs(f.Y - floor.Y) > 0.3
				or not api.sight(a, f + Vector3.new(0, 0.5, 0), f + Vector3.new(0, 7, 0))
			then
				return false, "open flat floor/bypass"
			end
		end
	end
	return true, floor
end
function Traps.eligible(t, actor, s, a, position, rootPosition, now, finishing)
	if not s or s.phase ~= "Run" or s.run ~= a or s.item or s.hold or s.trapPickedUp then
		return false, "pre-steal entry only"
	end
	if not Traps.unlocked(t, actor, s) then
		return false, "Decoy unlock: 3 Meadow escapes"
	end
	if not s.trapCharge then
		return false, "charge spent"
	end
	if not finishing and now < (s.trapCooldown or 0) then
		return false, "15s placement cooldown"
	end
	local islandCount, ownerCount = 0, 0
	for _, trap in t.active do
		islandCount += trap.arena == a and 1 or 0
		ownerCount += trap.owner == actor and 1 or 0
		if trap.arena == a and (trap.position - position).Magnitude < t.config.Spacing then
			return false, "12-stud trap spacing"
		end
	end
	if
		ownerCount >= t.config.MaxPerPlayer
		or islandCount >= t.config.MaxPerIsland
		or #t.active >= t.config.MaxServer
	then
		return false, "trap limit"
	end
	return Traps.spot(t, a, position, rootPosition)
end
function Traps.action(t, actor, s, a, rootPosition, stage, position, now, kind)
	if not s then
		return false, "no actor"
	end
	if stage == "cancel" then
		s.trapHold = nil
		return true
	end
	if kind and kind ~= "Decoy" then
		return false, "Sticky locked: future Crystal island"
	end
	if stage == "recall" then
		if s.phase ~= "Run" or s.trapPickedUp or s.item then
			return false, "recall before pickup only"
		end
		Traps.remove(t, actor)
		s.trapHold = nil
		return true
	end
	if stage ~= "begin" and stage ~= "finish" then
		return false, "trap stage"
	end
	if not a or not rootPosition then
		return false, "arena/root"
	end
	local hold = s.trapHold
	if stage == "finish" then
		s.trapHold = nil
		if not hold or hold.arena ~= a or now - hold.began < t.config.PlacementSeconds then
			return false, "hold Decoy 1s"
		end
		position = hold.position -- Client finish cannot move the committed preview.
	end
	if typeof(position) ~= "Vector3" then
		return false, "floor required"
	end
	local ok, floor = Traps.eligible(t, actor, s, a, position, rootPosition, now, stage == "finish")
	if stage == "begin" and now >= (s.trapCooldown or 0) then
		s.trapCooldown, s.trapHold = now + t.config.Cooldown, nil
	end
	if not ok then
		return false, floor
	end
	if stage == "begin" then
		s.trapHold = { position = floor, began = now, arena = a }
		return true
	end
	local part = t.make(
		a.model,
		"DecoyBell",
		Vector3.new(0.1, 6, 6),
		floor + Vector3.new(0, 0.12, 0),
		Color3.fromRGB(255, 210, 60)
	)
	part.Shape, part.CFrame = Enum.PartType.Cylinder, CFrame.new(part.Position) * CFrame.Angles(0, 0, math.pi / 2)
	part.Material, part.Transparency = Enum.Material.Neon, 0.35
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part:SetAttribute("TrapOwner", actor.UserId)
	part:SetAttribute("TrapType", "Decoy")
	local bell = t.make(part, "Bell", Vector3.new(1.8, 2, 1.8), floor + Vector3.new(0, 1.4, 0), Color3.fromRGB(255, 204, 65))
	bell.Shape = Enum.PartType.Ball
	bell.Color, bell.Material = Color3.fromRGB(255, 204, 65), Enum.Material.Metal
	bell.Anchored, bell.CanCollide, bell.CanTouch, bell.CanQuery = true, false, false, false
	bell.Position, bell.Parent = floor + Vector3.new(0, 1.4, 0), part
	local trap = {
		owner = actor,
		arena = a,
		position = floor,
		part = part,
		bell = bell,
		caption = t.label(part, "DECOY / arming 2s"),
		armed = now + t.config.ArmSeconds,
		expires = now + t.config.Lifetime,
	}
	part:SetAttribute("ExpiresAt", trap.expires)
	part:SetAttribute("ArmedAt", trap.armed)
	table.insert(t.active, trap)
	s.trapCharge = false
	return true
end
function Traps.tick(t, now, states)
	for _, s in states do
		local hold = s.trapHold
		if hold then
			local actorRoot = s.trapRoot and s.trapRoot()
			if
				s.trapRoot
				and (
					not actorRoot
					or not Traps.eligible(t, s.trapActor, s, hold.arena, hold.position, actorRoot.Position, now, true)
				)
			then
				s.trapHold = nil
			end
		end
	end
	for i = #t.active, 1, -1 do
		local trap, c = t.active[i], t.config.Decoy
		local s = states[trap.owner]
		if now >= trap.expires or not s or s.phase ~= "Run" or s.run ~= trap.arena then
			Traps.remove(t, trap.owner)
			continue
		end
		local a = trap.arena
		if trap.effectEnd and now >= trap.effectEnd then
			a.decoy, a.decoyImmuneUntil = nil, now + c.ImmunitySeconds
			Traps.remove(t, trap.owner)
		elseif trap.triggered then
			trap.caption.Text = now < trap.tellEnd and "DECOY / RATTLE!" or "DECOY / investigating"
			trap.part.Transparency = 0.15 + 0.2 * math.abs(math.sin(now * 12))
			if trap.bell then
				trap.bell.CFrame = CFrame.new(trap.position + Vector3.new(0, 1.4, 0))
					* CFrame.Angles(0, 0, now < trap.tellEnd and math.sin(now * 28) * 0.4 or 0)
			end
		elseif now >= trap.armed then
			trap.caption.Text = "DECOY / guardian only"
			local p = a.guardian.Position - trap.position
			if
				not a.attack
				and not a.decoy
				and now >= (a.decoyImmuneUntil or 0)
				and Vector3.new(p.X, 0, p.Z).Magnitude <= c.TriggerRange
			then
				trap.triggered, trap.tellEnd = true, now + c.TellSeconds
				-- Emit presentation before publishing attention to the guardian tick.
				trap.caption.Text = "DECOY / RATTLE!"
				trap.part.Transparency = 0.15
				if t.rattle then
					t.rattle(trap.part)
				end
				trap.part:SetAttribute(Traps.RattleTimeSignal, now)
				trap.part:SetAttribute(Traps.RattleSignal, true)
				trap.effectEnd = trap.tellEnd + c.EffectSeconds
				a.decoy = { trap = trap, position = trap.position, started = now, tellEnd = trap.tellEnd, ends = trap.effectEnd }
				a.pathVersion = (a.pathVersion or 0) + 1
				a.points, a.index, a.nextPath = {}, 1, 0
			end
		end
	end
end
return Traps
