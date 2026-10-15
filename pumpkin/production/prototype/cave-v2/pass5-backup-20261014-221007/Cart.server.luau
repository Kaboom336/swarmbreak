-- Server-driven deterministic cart path. This prototype has no ram or blast damage.
local RunService = game:GetService("RunService")
local data = require(game.ReplicatedStorage.CaveRouteData)
local map = workspace.CaveV2
local Policy = require(script.Parent.CavePolicy)
local actions = {}
local Http = game:GetService("HttpService")
local traces = {}
local blastGeneration = 0
local switchGeneration = 0
local function vec(a)
	return Vector3.new(a[1], a[3], -a[2])
end
local points = data.routes.cartRail
local function at(distance)
	local remaining = distance
	for i = 1, #points - 1 do
		local a, b = vec(points[i]), vec(points[i + 1])
		local length = (b - a).Magnitude
		if remaining <= length then
			local p = a:Lerp(b, math.clamp(remaining / length, 0, 1))
			return p, (b - a).Unit, i
		end
		remaining -= length
	end
	return vec(points[#points]), (vec(points[#points]) - vec(points[#points - 1])).Unit, #points - 1
end
local broken = false
local busy = 0
local lastBreak = -100
local span = map.BreakableSpan
local hook = map.SupportBlastHook
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Blast support (1s fuse + 2s cracks)"
prompt.HoldDuration = 0.4
prompt.MaxActivationDistance = 14
prompt.Parent = hook
local ready = map.JumpReady:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
local function occupiedRepairVolume()
	if busy > 0 then
		return true
	end
	for _, player in game.Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - Vector3.new(0, 4, 25)).Magnitude < 52 then
			return true
		end
	end
	return false
end
local function blast()
	if not Policy.canBlast(busy, lastBreak, os.clock(), hook:GetAttribute("Armed")) then
		return false
	end
	local generation = blastGeneration
	hook:SetAttribute("Armed", true)
	prompt.Enabled = false
	ready.Text = "1s FUSE"
	task.wait(1)
	if generation ~= blastGeneration then return false end
	ready.Text = "2s CRACKS"
	task.wait(2)
	if generation ~= blastGeneration then return false end
	-- Do not change the gap beneath any cart in the reserved approach/flight envelope.
	if busy > 0 then
		ready.Text = "WAIT: CART COMMITTED"
		repeat
			task.wait(0.1)
		until busy == 0 or generation ~= blastGeneration
	end
	if generation ~= blastGeneration then return false end
	broken = true
	lastBreak = os.clock()
	span.CanCollide = false
	span.Transparency = 1
	map.SpanBearingBeam.CanCollide = false
	map.SpanBearingBeam.Transparency = 1
	hook:SetAttribute("Armed", false)
	ready.Text = "JUMP READY / 24"
	task.wait(20)
	if generation ~= blastGeneration then return false end
	repeat
		task.wait(0.2)
	until generation ~= blastGeneration or Policy.canRepair(busy, occupiedRepairVolume(), os.clock() - lastBreak)
	if generation ~= blastGeneration then return false end
	broken = false
	span.CanCollide = true
	span.Transparency = 0
	map.SpanBearingBeam.CanCollide = true
	map.SpanBearingBeam.Transparency = 0
	prompt.Enabled = true
	ready.Text = "JUMP READY"
end
prompt.Triggered:Connect(blast)
local function buildCart(index)
	local model = Instance.new("Model")
	model.Name = "RideableCart" .. index
	model.Parent = map
	local function p(name, size, offset, color, class)
		local part = Instance.new(class or "Part")
		part.Name = name
		part.Size = size
		part.Anchored = true
		part.CanCollide = false
		part.Color = color
		part.CFrame = CFrame.new(vec(points[1]) + offset)
		part.Parent = model
		return part
	end
	local base = p("OreCart", Vector3.new(8, 1, 10), Vector3.new(0, 2, 0), Color3.fromRGB(71, 79, 92))
	model.PrimaryPart = base
	local seats = {
		p("DriverSeat", Vector3.new(3, 1, 3), Vector3.new(-2, 3, 0), Color3.fromRGB(103, 72, 44), "Seat"),
		p("PassengerSeat", Vector3.new(3, 1, 3), Vector3.new(2, 3, 0), Color3.fromRGB(103, 72, 44), "Seat"),
	}
	for _, seat in seats do
		seat.CanCollide = true
		seat.CanTouch = true
		seat.Disabled = false
	end
	local gauge = Instance.new("BillboardGui")
	gauge.Size = UDim2.fromOffset(230, 60)
	gauge.StudsOffset = Vector3.new(0, 6, 0)
	gauge.AlwaysOnTop = true
	gauge.Parent = base
	local gaugeText = Instance.new("TextLabel")
	gaugeText.Size = UDim2.fromScale(1, 1)
	gaugeText.BackgroundColor3 = Color3.fromRGB(28, 32, 46)
	gaugeText.TextScaled = true
	gaugeText.TextColor3 = Color3.new(1, 1, 1)
	gaugeText.Parent = gauge
	for side = -1, 1, 2 do
		p("CartSide", Vector3.new(0.7, 3, 10), Vector3.new(side * 4, 3, 0), Color3.fromRGB(85, 96, 109))
		for z = -3, 3, 6 do
			local w = p("Wheel", Vector3.new(1.2, 2, 2), Vector3.new(side * 4, 1, z), Color3.fromRGB(39, 42, 53))
			w.Shape = Enum.PartType.Cylinder
		end
	end
	-- One anchored assembly root drives both seats and their engine SeatWelds.
	-- Independently anchored cart parts do not form one moving assembly.
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= base then
			part.Anchored = false
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = base
			weld.Part1 = part
			weld.Parent = part
		end
	end
	local board = Instance.new("ProximityPrompt")
	board.ActionText = "Ride cart"
	board.HoldDuration = 0.3
	board.MaxActivationDistance = 12
	board.RequiresLineOfSight = false
	board.Parent = base
	local distance, state, elapsed, waitTime, committed, flightSpeed = 0, "Dock", 0, 0, false, 24
	local boarding = {}
	local approachReserved = false
	local trace = { cart = index, ride = 0, transitions = {}, samples = {}, lastError = "" }
	local lastSample, lastState = -math.huge, nil
	local function diagnostic(event, err)
		local now = os.clock()
		local _, _, segment = at(distance)
		local occupants, welds = {}, {}
		for i, seat in seats do
			occupants[i] = seat.Occupant and seat.Occupant.Parent.Name or "NONE"
			welds[i] = seat:FindFirstChild("SeatWeld") ~= nil
		end
		if err then
			trace.lastError = tostring(err)
		end
		local sample = { t = now, state = state, TrackDistance = distance, Occupant = occupants,
			seatWeld = welds, speed = model:GetAttribute("Speed") or 24, segment = segment,
			jump = state == "Flight" or state == "Fall" or state == "Landing",
			broken = broken, armed = hook:GetAttribute("Armed") == true, committed = committed, reserved = approachReserved }
		trace.current = sample
		if event or state ~= lastState then
			table.insert(trace.transitions, { t = now, state = state, event = event or "transition", distance = distance })
			if #trace.transitions > 40 then
				table.remove(trace.transitions, 1)
			end
		end
		if event or state ~= lastState or (state ~= "Dock" and now - lastSample >= 0.5) then
			table.insert(trace.samples, sample)
			if #trace.samples > 80 then
				table.remove(trace.samples, 1)
			end
			lastSample = now
			traces[index] = trace
			model:SetAttribute("CartLastRide", Http:JSONEncode(trace))
			script.Parent:SetAttribute("CartLastRide", Http:JSONEncode({ carts = traces }))
		end
		lastState = state
		model:SetAttribute("CartLastError", trace.lastError)
	end
	local function boardPlayer(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health <= 0 then
			return false
		end
		for _, seat in seats do
			if seat.Occupant == humanoid then
				return true
			end
		end
		if state ~= "Dock" or (root.Position - base.Position).Magnitude > 14 or humanoid.SeatPart then
			return false
		end
		for _, pending in boarding do
			if pending == humanoid then
				return false
			end
		end
		for _, seat in seats do
			if seat.Occupant or boarding[seat] then
				continue
			end
			boarding[seat] = humanoid
			if not seats[1].Occupant and not seats[2].Occupant then
				trace = { cart = index, ride = trace.ride + 1, transitions = {}, samples = {}, lastError = "" }
			end
			diagnostic("boarding")
			humanoid:MoveTo(root.Position)
			humanoid.Jump = false
			humanoid.Sit = false
			-- Retry through the engine's per-avatar/seat cooldown, and report
			-- success only after a real SeatWeld and Occupant are established.
			local deadline = os.clock() + 4.5
			repeat
				root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				seat:Sit(humanoid)
				task.wait(0.1)
			until (seat.Occupant == humanoid and seat:FindFirstChild("SeatWeld"))
				or os.clock() >= deadline or humanoid.Health <= 0 or not character.Parent
			boarding[seat] = nil
			local seated = seat.Occupant == humanoid and humanoid.SeatPart == seat
				and seat:FindFirstChild("SeatWeld") ~= nil
			diagnostic(seated and "boarded" or "board failed", not seated and "SeatWeld/Occupant timeout" or nil)
			return seated
		end
		return false
	end
	board.Triggered:Connect(boardPlayer)
	local speed = 24
	local brake = Instance.new("ProximityPrompt")
	brake.ActionText = "Toggle speed 24 / 12 (red = pit if committed)"
	brake.MaxActivationDistance = 9
	brake.Parent = seats[1]
	local diverted = false
	local override = Instance.new("ProximityPrompt")
	override.ActionText = "Override amber switch"
	override.MaxActivationDistance = 9
	override.Parent = seats[1]
	override.Triggered:Connect(function(player)
		if seats[1].Occupant and seats[1].Occupant.Parent == player.Character and not diverted then
			map.RailSwitchHook:SetAttribute("DivertNext", false)
			map.RailSwitchHook:SetAttribute("Warning", false)
		end
	end)
	local function bypassPosition(d)
		local pos = at(d)
		local nearest, best = nil, math.huge
		local pts = data.routes.railWalkBypass
		for i = 1, #pts - 1 do
			local a, b = vec(pts[i]), vec(pts[i + 1])
			local t = math.clamp((pos - a):Dot(b - a) / (b - a):Dot(b - a), 0, 1)
			local q = a:Lerp(b, t)
			local l = (q - pos).Magnitude
			if l < best then
				nearest, best = q, l
			end
		end
		return nearest + Vector3.new(0, 4, 0)
	end
	local function toggle(player)
		if not committed and seats[1].Occupant and seats[1].Occupant.Parent == player.Character then
			speed = speed == 24 and 12 or 24
			ready.Text = speed >= 24 and "JUMP READY / 24" or "RED: STOP / BAIL / 12"
			return speed
		end
	end
	brake.Triggered:Connect(toggle)
	actions[index] = { board = boardPlayer, toggle = toggle }
	local bail = Instance.new("ProximityPrompt")
	bail.ActionText = "Emergency dismount to bypass"
	bail.MaxActivationDistance = 9
	bail.Parent = seats[2]
	local exiting = {}
	local function exitHumanoid(h, pos)
		if h then
			exiting[h] = true
			h.Sit = false
			local seat = h.SeatPart
			local weld = seat and seat:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
			local root = h.Parent:FindFirstChild("HumanoidRootPart")
			task.defer(function()
				if root and root.Parent then
					root.CFrame = CFrame.new(pos)
					root.AssemblyLinearVelocity = Vector3.zero
				end
				exiting[h] = nil
			end)
		end
	end
	bail.Triggered:Connect(function(player)
		for _, seat in seats do
			if seat.Occupant and seat.Occupant.Parent == player.Character then
				if state == "Flight" or state == "Fall" then
					player:SetAttribute("CaveDismountDeferred", true)
				else
					exitHumanoid(seat.Occupant, bypassPosition(distance))
				end
			end
		end
	end)
	local function reserve(on, approachOnly)
		if on and not committed then
			if not approachReserved then
				busy += 1
				approachReserved = true
			end
			if not approachOnly then
				committed = true
			end
		elseif not on and approachReserved then
			busy -= 1
			committed = false
			approachReserved = false
		end
	end
	-- Defer ordinary seat jumping as well as the explicit emergency-dismount
	-- prompt during a committed flight. Studio must verify replication behavior.
	for _, seat in seats do
		local previous = nil
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local current = seat.Occupant
			if previous and not current and not exiting[previous]
				and (state == "Flight" or state == "Fall" or state == "Landing") then
				local deferred = previous
				task.defer(function()
					if deferred.Parent and deferred.Health > 0 and not exiting[deferred]
						and (state == "Flight" or state == "Fall" or state == "Landing") then
						seat:Sit(deferred)
					end
				end)
			end
			previous = current
		end)
	end
	local function pivot(pos, dir)
		model:PivotTo(CFrame.lookAt(pos + Vector3.new(0, 2, 0), pos + Vector3.new(0, 2, 0) + dir))
	end
	local function step(dt)
		gaugeText.Text = string.format(
			"CART %d | %d | %s",
			index,
			speed,
			(committed and flightSpeed or speed) >= 24 and "JUMP READY" or "RED / BAIL"
		)
		gaugeText.TextColor3 = (committed and flightSpeed or speed) >= 24 and Color3.fromRGB(128, 255, 150)
			or Color3.fromRGB(255, 121, 111)
		if state == "Dock" then
			if not next(boarding) and (seats[1].Occupant or seats[2].Occupant) then
				waitTime += dt
				if waitTime >= 2 + (index - 1) * 1 and not hook:GetAttribute("Armed") then
					-- Lock span state for the whole approach, including slow Studio frames.
					reserve(true, true)
					state = "Track"
					board.Enabled = false
					waitTime = 0
				end
			else
				waitTime = 0
			end
		elseif state == "Track" then
			local nextDistance = distance + speed * dt
			if distance < data.gapStart - 22 and nextDistance >= data.gapStart - 22 then
				if hook:GetAttribute("Armed") then
					return
				end
				reserve(true)
				flightSpeed = speed
			end
			if broken and nextDistance >= data.gapStart and distance < data.gapStart then
				state = Policy.flight(flightSpeed)
				elapsed = 0
				distance = data.gapStart
			else
				distance = nextDistance
				local position, dir = at(distance)
				pivot(position, dir)
				if distance > data.gapEnd + 24 then
					reserve(false)
				end
				if distance >= data.length then
					state = "End"
					elapsed = 0
				end
				if distance > data.gapEnd + 65 and map.RailSwitchHook:GetAttribute("DivertNext") and not diverted then
					diverted = true
					map.RailSwitchHook:SetAttribute("DivertNext", false)
					state = "Siding"
					elapsed = 0
				end
			end
		elseif state == "Flight" then
			elapsed += dt
			local t = math.clamp(elapsed / (16 / flightSpeed), 0, 1)
			local a, dir = at(data.gapStart)
			local b = at(data.gapEnd)
			pivot(a:Lerp(b, t) + Vector3.new(0, 12 * 4 * t * (1 - t), 0), dir)
			if t >= 1 then
				distance = data.gapEnd + 0.05
				state = "Landing"
				elapsed = 0
			end
		elseif state == "Landing" then
			distance += flightSpeed * dt
			local pos, dir = at(distance)
			pivot(pos, dir)
			elapsed += dt
			if elapsed >= 1 then
				reserve(false)
				state = "Track"
				for _, s in seats do
					local h = s.Occupant
					local pl = h and game.Players:GetPlayerFromCharacter(h.Parent)
					if pl and pl:GetAttribute("CaveDismountDeferred") then
						pl:SetAttribute("CaveDismountDeferred", false)
						exitHumanoid(h, bypassPosition(distance))
					end
				end
			end
		elseif state == "Fall" then
			elapsed += dt
			local t = math.clamp(elapsed / 1.2, 0, 1)
			local a, dir = at(data.gapStart)
			local pit = Vector3.new(0, -14, 25)
			pivot(a:Lerp(pit, t), dir)
			if t >= 1 then
				for _, s in seats do
					exitHumanoid(s.Occupant, pit + Vector3.new(0, 4, 0))
				end
				reserve(false)
				state = "End"
				elapsed = 0
			end
		elseif state == "Siding" then
			elapsed += dt
			local pos, dir = at(distance)
			pivot(pos:Lerp(Vector3.new(-94, 8, 50), math.min(elapsed / 3.5, 1)), dir)
			if elapsed >= 3.5 then
				for _, s in seats do
					exitHumanoid(s.Occupant, Vector3.new(-94, 12, 50))
				end
				state = "End"
				elapsed = 0
			end
		elseif state == "End" then
			elapsed += dt
			if elapsed > 0.5 then
				for _, s in seats do
					exitHumanoid(s.Occupant, bypassPosition(distance))
				end
			end
			if elapsed > 4 then
				reserve(false)
				distance = 0
				state = "Dock"
				diverted = false
				speed = 24
				board.Enabled = true
				local pos, dir = at(0)
				pivot(pos + Vector3.new(index == 2 and 12 or 0, 0, 0), dir)
			end
		end
		-- Publish after transitions/ejections so diagnostics observe one tick's
		-- actual state rather than a stale Fall label on an already ejected rider.
		model:SetAttribute("State", state)
		model:SetAttribute("Speed", speed)
		model:SetAttribute("TrackDistance", distance)
		diagnostic()
	end
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = xpcall(function()
			-- Consume all real elapsed time in bounded integration steps. A cap on
			-- dt alone slows travel while the cargo/repair deadlines keep advancing.
			while dt > 0 do
				local slice = math.min(dt, 0.1)
				step(slice)
				dt -= slice
			end
		end, debug.traceback)
		if not ok then
			diagnostic("Heartbeat error", err)
		end
	end)
	actions[index].snapshot = function(message)
		diagnostic("snapshot", message)
		return model:GetAttribute("CartLastRide")
	end
	actions[index].reset = function()
		for _, seat in seats do
			exitHumanoid(seat.Occupant, bypassPosition(distance))
		end
		table.clear(boarding)
		reserve(false)
		distance, state, elapsed, waitTime, diverted, speed, flightSpeed = 0, "Dock", 0, 0, false, 24, 24
		board.Enabled = true
		local dock, direction = at(0)
		pivot(dock + Vector3.new(index == 2 and 12 or 0, 0, 0), direction)
		model:SetAttribute("State", state)
		model:SetAttribute("Speed", speed)
		model:SetAttribute("TrackDistance", distance)
		diagnostic("reset")
		return true
	end
	local pos, dir = at(0)
	pivot(pos + Vector3.new(index == 2 and 12 or 0, 0, 0), dir)
	diagnostic("created")
end
for i = 1, 2 do
	buildCart(i)
end
if RunService:IsStudio() then
	local api = Instance.new("BindableFunction")
	api.Name = "CaveCartActions"
	api.Parent = script.Parent
	api.OnInvoke = function(action, index, player)
		if action == "resetAll" then
			blastGeneration += 1
			switchGeneration += 1
			broken, lastBreak = false, -100
			for _, cart in actions do
				cart.reset()
			end
			span.CanCollide, span.Transparency = true, 0
			map.SpanBearingBeam.CanCollide, map.SpanBearingBeam.Transparency = true, 0
			hook:SetAttribute("Armed", false)
			prompt.Enabled = true
			ready.Text = "JUMP READY"
			map.RailSwitchHook:SetAttribute("DivertNext", false)
			map.RailSwitchHook:SetAttribute("Warning", false)
			map.RailSwitchHook.Color = Color3.fromRGB(226, 123, 58)
			for _, rider in game.Players:GetPlayers() do
				rider:SetAttribute("CaveDismountDeferred", false)
			end
			local switchPrompt = map.RailSwitchHook:FindFirstChildOfClass("ProximityPrompt")
			if switchPrompt then
				switchPrompt.Enabled = true
			end
			return true
		end
		if action == "blast" then
			task.spawn(blast)
			return true
		end
		local cart = actions[index]
		if cart and cart[action] then
			return cart[action](player)
		end
	end
end
-- Switch hook demonstrates its complete 2s warning, 12s lock and harmless siding.
local switch = map.RailSwitchHook
local sw = Instance.new("ProximityPrompt")
sw.ActionText = "Switch next cart"
sw.HoldDuration = 0.4
sw.Parent = switch
sw.Triggered:Connect(function()
	if switch:GetAttribute("DivertNext") or not sw.Enabled then
		return
	end
	sw.Enabled = false
	local generation = switchGeneration
	switch:SetAttribute("Warning", true)
	switch.Color = Color3.fromRGB(255, 190, 34)
	task.wait(2)
	if generation ~= switchGeneration then return end
	local active = switch:GetAttribute("Warning")
	switch:SetAttribute("Warning", false)
	switch:SetAttribute("DivertNext", active)
	task.wait(12)
	if generation ~= switchGeneration then return end
	switch.Color = Color3.fromRGB(226, 123, 58)
	sw.Enabled = true
end)
