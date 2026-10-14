-- Upload-free local EditableMesh visuals; gameplay and projectile stay on server.
local RunService = game:GetService("RunService")
local folder = game:GetService("ReplicatedStorage"):WaitForChild("MeadowKeeper")
local Rig = require(folder.Rig)
local Animator = require(folder.Animator)
local Pose = require(folder.Pose)
local FX = require(folder:WaitForChild("Effects"))
local Props = require(folder:WaitForChild("Projectiles"))
local projectiles = {}
folder:WaitForChild("FXEvent").OnClientEvent:Connect(function(guard, name, position, radius)
	FX.emit(guard, name, position, radius)
end)
local function projectile(node)
	if not node:IsA("BasePart") or projectiles[node] then
		return
	end
	local kind = node:GetAttribute("KeeperProjectile")
	if not kind then
		return
	end
	projectiles[node] = { pending = true }
	task.spawn(function()
		local ok, prop = pcall(Props.build, kind, workspace)
		if not ok then
			projectiles[node] = nil
			warn("[Keeper prop] " .. tostring(prop))
			return
		end
		if not node.Parent then
			prop.model:Destroy()
			projectiles[node] = nil
			return
		end
		projectiles[node] = { prop = prop, kind = kind, at = os.clock() }
		node.LocalTransparencyModifier = 1
		FX.trail(kind == "fan" and prop.pieces[1].part or node, kind)
	end)
end
local loading, active = {}, {}
local function attach(guard)
	if not guard:IsA("BasePart") or not guard:GetAttribute("MeadowKeeper") or loading[guard] or active[guard] then
		return
	end
	loading[guard] = true
	task.spawn(function()
		local ok, rig = pcall(Rig.build, Pose.ground(guard))
		loading[guard] = nil
		if not ok then
			warn("[MeadowKeeper] EditableMesh loader failed: " .. tostring(rig))
			return -- Do not change settings or silently substitute a stand-in.
		end
		if not guard:IsDescendantOf(workspace) then
			Rig.destroy(rig)
			return
		end
		rig.model.Name, rig.model.Parent = "MeadowKeeper", guard.Parent
		local anim = Animator.new(rig)
		anim.connection:Disconnect() -- The shared server timestamp drives rendering.
		local held = Instance.new("Part")
		held.Name, held.Shape, held.Size = "KeeperHeldRock", Enum.PartType.Ball, Vector3.new(2, 2, 2)
		held.Anchored, held.CanCollide, held.CanTouch, held.CanQuery = true, false, false, false
		held.Transparency, held.Parent = 1, rig.model
		local cap = Instance.new("Part")
		cap.Name, cap.Shape, cap.Size = "KeeperHeldAcornCap", Enum.PartType.Ball, Vector3.new(2.52, 1.08, 2.52)
		cap.Color, cap.Material = Color3.fromRGB(75, 48, 27), Enum.Material.Wood
		cap.Anchored, cap.CanCollide, cap.CanTouch, cap.CanQuery = true, false, false, false
		cap.Transparency, cap.Parent = 1, rig.model
		local log = Props.build("lob", rig.model)
		local acornOk, acorn = pcall(Props.build, "fan", rig.model)
		if not acornOk then
			warn("[Keeper acorn] " .. tostring(acorn))
			acorn = nil
		end
		active[guard] = { rig = rig, anim = anim, held = held, cap = cap, log = log, acorn = acorn }
	end)
end
local function observe(node)
	projectile(node)
	if node:IsA("BasePart") then
		node:GetAttributeChangedSignal("KeeperProjectile"):Connect(function()
			projectile(node)
		end)
	end
	if node:IsA("BasePart") and node.Name == "Guardian" then
		node:GetAttributeChangedSignal("MeadowKeeper"):Connect(function()
			attach(node)
		end)
		attach(node)
	end
end
workspace.DescendantAdded:Connect(observe)
for _, node in ipairs(workspace:GetDescendants()) do
	observe(node)
end
RunService.PreSimulation:Connect(function()
	for node, entry in pairs(projectiles) do
		if not node.Parent then
			if entry.prop then
				entry.prop.model:Destroy()
			end
			projectiles[node] = nil
		elseif entry.prop then
			Props.move(
				entry.prop,
				node.CFrame * CFrame.Angles((os.clock() - entry.at) * 18, 0, 0),
				node.Transparency < 1
			)
		end
	end
	for guard, entry in pairs(active) do
		if not guard:IsDescendantOf(workspace) then
			entry.anim:Destroy()
			Rig.destroy(entry.rig)
			FX.reset(guard)
			active[guard] = nil
		else
			entry.rig.root.CFrame = Pose.ground(guard)
			local name = guard:GetAttribute("KeeperClip") or "idle"
			if name ~= entry.clip then
				entry.clip = name
				local events =
					{ warn = "Warn", chase = "Chase", ["return"] = "Return", celebrate = "Celebrate", stun = "Stun" }
				if events[name] then
					FX.emit(guard, events[name], guard.Position)
				end
			end
			local clip = Animator.Clips[name]
			local time = guard:GetAttribute("KeeperElapsed") or 0
			local started = guard:GetAttribute("KeeperStartedAt")
			if started then
				time = math.max(0, workspace:GetServerTimeNow() - started)
			end
			if clip.loop then
				time %= clip.duration
			else
				time = math.min(time, clip.duration)
			end
			local pose = Animator.sample(name, time)
			local target = guard:GetAttribute("KeeperLookTarget")
			if target then
				local direction = Pose.ground(guard):VectorToObjectSpace(target - guard.Position)
				local yaw = math.clamp(math.atan2(direction.X, direction.Z), -0.45, 0.45)
				-- Two-hand heave keeps the gaze on the committed forward aim.
				-- Turning the broad hat toward a moving target would hit the raised mittens.
				if name == "lob" then
					yaw = 0
				end
				pose.Head *= CFrame.Angles(0, yaw, 0)
			end
			entry.anim:Apply(pose)
			entry.held.Size = name == "lob" and Vector3.new(4, 4, 4) or Vector3.new(2.4, 2.4, 2.4)
			entry.held.Transparency = (name == "throw" or name == "lob" or name == "fan")
					and time < Pose.ReleaseSeconds
					and 0
				or 1
			entry.held.CFrame = entry.rig:ReleaseCFrame(pose, name)
			entry.cap.Transparency = name == "fan" and time < Pose.ReleaseSeconds and 0 or 1
			entry.cap.CFrame = CFrame.new(entry.held.Position + Vector3.new(0, 0.912, 0))
			-- Legacy carriers are hidden; real themed props follow the identical socket.
			entry.held.Transparency, entry.cap.Transparency = 1, 1
			Props.move(entry.log, entry.held.CFrame, name == "lob" and time >= 0.20 and time < Pose.ReleaseSeconds)
			if entry.acorn then
				Props.move(entry.acorn, entry.held.CFrame, name == "fan" and time < Pose.ReleaseSeconds)
			end
		end
	end
end)
