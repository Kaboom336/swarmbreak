-- Production adapter for reviewed tunnel policy: live Keeper and shared treasure ownership.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Policy = require(script.Parent:WaitForChild("TunnelPolicy"))
local Controller = {}
function Controller.attach(adapter)
	assert(
		adapter.getCarrier and adapter.drop and adapter.intercept and adapter.map and adapter.origin,
		"Production tunnel requires live ownership, Keeper, map and origin adapters"
	)
	local map = adapter.map or workspace:WaitForChild("MeadowV4")
	local origin = adapter.origin or Vector3.zero
	local function insideWorld(p)
		local q = p - origin
		return Policy.inside(q.X, q.Y, q.Z)
	end
	local function mudWorld(p)
		local q = p - origin
		return Policy.inMud(q.X, q.Y, q.Z)
	end
	local effects = Instance.new("Folder")
	effects.Name = "TunnelTransientEffects"
	effects.Parent = map
	local states = {}
	local random = Random.new(1013)
	local active = true
	local activeExit = nil
	local pursuedEntrant = nil
	local pursuedEpoch = nil
	local externalCleanup = nil
	local function restore(player, state)
		local hum = state.hum
		if state.originalSpeed and hum and hum.Parent then
			hum.WalkSpeed = state.originalSpeed
		end
		state.originalSpeed = nil
		state.hum = nil
		if player.Parent then
			player:SetAttribute("TunnelInside", false)
			player:SetAttribute("TunnelRumbling", false)
		end
	end
	local function intercept(exitId, entrant, epoch)
		-- Dropping/re-picking cannot cancel this player's already-running/waiting intercept.
		if not Policy.shouldIntercept(pursuedEntrant, activeExit, pursuedEpoch, entrant, exitId, epoch) then
			return
		end
		pursuedEntrant = entrant
		activeExit = exitId
		pursuedEpoch = epoch
		if externalCleanup then
			externalCleanup()
			externalCleanup = nil
		end
		externalCleanup = adapter.intercept(exitId, Policy.path(exitId), Policy.Tuning.ExitHoldSeconds, entrant, epoch)
	end
	local function hazard(player, root)
		local originalCharacter = player.Character
		local velocity = root.AssemblyLinearVelocity
		local localPoint = root.Position - origin
		local x, z = Policy.hazardTarget(localPoint.X, localPoint.Z, velocity.X, velocity.Z)
		local target = origin + Vector3.new(x, 0.22, z)
		local shadow = Instance.new("Part")
		shadow.Name = "TunnelRedShadow"
		shadow.Size = Vector3.new(6, 0.06, 6)
		shadow.Anchored = true
		shadow.CanCollide = false
		shadow.CanTouch = false
		shadow.CanQuery = false
		shadow.Color = Color3.fromRGB(250, 48, 44)
		shadow.Material = Enum.Material.Neon
		shadow.Transparency = 0.18
		shadow.Position = target
		shadow.Parent = effects
		Debris:AddItem(shadow, 2)
		task.delay(Policy.Tuning.ShadowSeconds, function()
			if not active or not shadow.Parent then
				return
			end
			local rock = Instance.new("WedgePart")
			rock.Name = "TunnelFallingStalactite"
			rock.Size = Vector3.new(2.7, 4, 2.7)
			rock.Anchored = true
			rock.CanCollide = false
			rock.CanTouch = false
			rock.CanQuery = false
			rock.Color = Color3.fromRGB(100, 106, 127)
			rock.Material = Enum.Material.Slate
			rock.CFrame = CFrame.new(target + Vector3.new(0, 23, 0)) * CFrame.Angles(math.pi, 0, 0)
			rock.Parent = effects
			Debris:AddItem(rock, 0.8)
			TweenService:Create(
				rock,
				TweenInfo.new(Policy.Tuning.FallSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = target + Vector3.new(0, 2, 0) }
			):Play()
			task.delay(Policy.Tuning.FallSeconds, function()
				if not active then
					return
				end
				shadow:Destroy()
				local character = player.Character
				local currentRoot = character and character:FindFirstChild("HumanoidRootPart")
				local hum = character and character:FindFirstChildOfClass("Humanoid")
				if character ~= originalCharacter or currentRoot ~= root or not hum or hum.Health <= 0 then
					return
				end
				local p = currentRoot.Position
				if
					insideWorld(p)
					and Vector2.new(p.X - target.X, p.Z - target.Z).Magnitude <= Policy.Tuning.ImpactRadius
				then
					if adapter.getCarrier() == player then
						adapter.drop(Vector3.new(p.X, origin.Y + 2.8, p.Z), "tunnel stalactite")
					end
					currentRoot.AssemblyLinearVelocity = Vector3.new(Policy.Tuning.KnockVelocity, 8, 0)
				end
			end)
		end)
	end
	local connection = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local carrier = adapter.getCarrier()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local hum = character and character:FindFirstChildOfClass("Humanoid")
			local s = states[player]
			local inside = root and hum and hum.Health > 0 and insideWorld(root.Position)
			if inside then
				if not s then
					s = { entered = now, nextHazard = now + Policy.Tuning.FirstHazardSeconds }
					states[player] = s
				end
				if s.hum and s.hum ~= hum then
					restore(player, s)
				end
				if not s.inside then
					if s.left and now - s.left > Policy.Tuning.ReentryGrace then
						s.entered = now
						s.prediction = nil
						s.rumbleStarted = nil
						s.wasCarrier = nil
						s.nextHazard = now + Policy.Tuning.FirstHazardSeconds
					end
					s.inside = true
				end
				player:SetAttribute("TunnelInside", true)
				local age = now - s.entered
				player:SetAttribute("TunnelRumbling", age >= Policy.Tuning.RumbleAfter)
				if not adapter.managedSpeed and mudWorld(root.Position) then
					if not s.originalSpeed then
						s.originalSpeed = hum.WalkSpeed
						s.hum = hum
					end
					hum.WalkSpeed = math.min(s.originalSpeed, Policy.Tuning.MudSpeed)
				elseif s.originalSpeed then
					hum.WalkSpeed = s.originalSpeed
					s.originalSpeed = nil
					s.hum = nil
				end
				if carrier == player then
					s.wasCarrier = true
					player:SetAttribute("TunnelKeeperThrowsSuppressed", true)
					if not s.carrying then
						s.carrying = true
						if not s.prediction then
							s.prediction = Policy.predict(
								root.Position.X - origin.X,
								root.Position.Z - origin.Z,
								random:NextNumber()
							)
						end
						workspace:SetAttribute("TunnelGuardedExit", s.prediction)
						intercept(s.prediction, player, s.entered)
					end
				else
					s.carrying = false
					player:SetAttribute("TunnelKeeperThrowsSuppressed", false)
				end
				-- Former thieves still face rumble after dropping, so dropping cannot create a hide spot.
				if carrier == player or (s.wasCarrier and age >= Policy.Tuning.RumbleAfter) then
					if age >= Policy.Tuning.RumbleAfter and not s.rumbleStarted then
						s.rumbleStarted = true
						s.nextHazard = math.min(s.nextHazard, now + Policy.Tuning.RumbleInterval)
					end
					if now >= s.nextHazard then
						hazard(player, root)
						s.nextHazard = now + Policy.interval(age)
					end
				end
			elseif s then
				s.carrying = false
				if s.inside then
					s.inside = false
					s.left = now
				end
				restore(player, s)
				player:SetAttribute("TunnelKeeperThrowsSuppressed", false)
				if not hum or hum.Health <= 0 then
					states[player] = nil
				end
			end
		end
		workspace:SetAttribute("TunnelRumbleActive", carrier ~= nil and carrier:GetAttribute("TunnelRumbling") == true)
	end)
	local removing = Players.PlayerRemoving:Connect(function(player)
		if states[player] then
			restore(player, states[player])
			states[player] = nil
		end
	end)
	workspace:SetAttribute(
		"TunnelRuntime",
		adapter.intercept and "Production Keeper adapter / shared treasure state"
			or "Prototype hazards/slow/rumble and surface stand-in intercept"
	)
	return {
		disconnect = function()
			active = false
			connection:Disconnect()
			removing:Disconnect()
			for p, s in states do
				restore(p, s)
				if p.Parent then
					p:SetAttribute("TunnelKeeperThrowsSuppressed", false)
				end
			end
			if externalCleanup then
				externalCleanup()
				externalCleanup = nil
			end
			effects:Destroy()
			workspace:SetAttribute("TunnelGuardWaiting", false)
			workspace:SetAttribute("TunnelRumbleActive", false)
			workspace:SetAttribute("TunnelGuardedExit", nil)
		end,
	}
end
return Controller
