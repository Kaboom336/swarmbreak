--!strict
-- Hold mouse / touch / R2 to fire. Touch auto-aims; the right stick aims on gamepad.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local AimAssist = require(ReplicatedStorage.Shared.AimAssist)
local PadAim = require(ReplicatedStorage.Shared.PadAim)
local TouchTracker = require(ReplicatedStorage.Shared.TouchTracker)
local CameraConfig = require(ReplicatedStorage.Shared.CameraConfig)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent
local StatsChanged = Remotes.StatsChanged :: RemoteEvent
local enemies = workspace:WaitForChild("Enemies")

local TOUCH_AIM_RANGE = 100 -- placeholder
local TOUCH_AIM_ANGLE_DEG = 70 -- placeholder
local touchAutoAim =
	CameraConfig.isTouchOnly(UserInputService.TouchEnabled, UserInputService.MouseEnabled)

local firing = false
local last = 0
local equipped = "Starter"
local fireRateMult = 1
local touchState = TouchTracker.new()
local rightStick = { x = 0, y = 0 }
local heldPadAim = { x = 0, y = 0 }
local padAimActive = false

StatsChanged.OnClientEvent:Connect(function(stats)
	equipped = stats.Equipped or "Starter"
	-- The same rate the server checks shots against (PlayerData.fireRateMultiplier): run
	-- upgrades x the equipped weapon's evolution tier x this run's Trigger cards. This throttle
	-- is what sets the real cadence (the server only guards), so every part is folded in here.
	local _, evoRate = Evolutions.multipliers((stats.Evolutions or {})[equipped])
	fireRateMult = Upgrades.valueAt("FireRate", (stats.Levels and stats.Levels.FireRate) or 0)
		* evoRate
		* (1 + ((stats.Boosts and stats.Boosts.FireRateMult) or 0))
end)

local function tryShoot()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end
	local weapon = Weapons.Defs[equipped] or Weapons.Defs.Starter
	if weapon.Kind == "Orbital" then
		return -- passive weapon: nothing to send
	end
	local now = os.clock()
	if now - last < 1 / (weapon.FireRate * fireRateMult) then
		return
	end
	last = now
	local origin = root.Position + Vector3.new(0, 1, 0)
	local direction: Vector3
	if touchAutoAim then
		local positions = {}
		local roots = {}
		for _, enemy in enemies:GetChildren() do
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
			local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
			if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
				table.insert(positions, { x = enemyRoot.Position.X, z = enemyRoot.Position.Z })
				table.insert(roots, enemyRoot)
			end
		end
		local look = root.CFrame.LookVector
		local targetIndex = AimAssist.pickTarget(
			{ x = origin.X, z = origin.Z },
			{ x = look.X, z = look.Z },
			positions,
			TOUCH_AIM_RANGE,
			TOUCH_AIM_ANGLE_DEG
		)
		local target = if targetIndex then roots[targetIndex] else nil
		direction = if target then (target.Position - origin).Unit else look
	else
		-- Mouse lock fires through the centred reticle; the Settings toggle restores cursor aim.
		local rawDirection: Vector3
		if padAimActive then
			local filtered = PadAim.applyDeadzone(rightStick)
			if filtered.x ~= 0 or filtered.y ~= 0 then
				local cameraLook = camera.CFrame.LookVector
				local forward = Vector3.new(cameraLook.X, 0, cameraLook.Z)
				if forward.Magnitude <= 0.001 then
					forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				end
				forward = forward.Unit
				local right = Vector3.new(-forward.Z, 0, forward.X)
				local worldAim = (right * filtered.x + forward * filtered.y).Unit
				heldPadAim = { x = worldAim.X, y = worldAim.Z }
				rawDirection = worldAim
			else
				local look = root.CFrame.LookVector
				local resolved = PadAim.resolveDirection(
					{ x = 0, y = 0 },
					heldPadAim,
					{ x = look.X, y = look.Z }
				)
				rawDirection = Vector3.new(resolved.x, 0, resolved.y)
			end
		else
			local mouseLock = player:GetAttribute("MouseLockEnabled") ~= false
			local m = if mouseLock or not UserInputService.MouseEnabled
				then camera.ViewportSize / 2
				else UserInputService:GetMouseLocation()
			local ray = camera:ViewportPointToRay(m.X, m.Y)
			local aimPoint = ray.Origin + ray.Direction * 500
			rawDirection = (aimPoint - origin).Unit
		end
		local positions = {}
		local roots = {}
		for _, enemy in enemies:GetChildren() do
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
			local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
			if
				enemyRoot
				and enemyHumanoid
				and enemyHumanoid.Health > 0
				and (enemyRoot.Position - origin).Magnitude <= weapon.Range
			then
				table.insert(positions, { x = enemyRoot.Position.X, z = enemyRoot.Position.Z })
				table.insert(roots, enemyRoot)
			end
		end
		local targetIndex = AimAssist.pickTargetInCone(
			{ x = origin.X, z = origin.Z },
			{ x = rawDirection.X, z = rawDirection.Z },
			positions,
			weapon.Range,
			AimAssist.PcConeDegrees
		)
		local target = if targetIndex then roots[targetIndex] else nil
		direction = if target then (target.Position - origin).Unit else rawDirection
	end
	local facing = Vector3.new(direction.X, 0, direction.Z)
	if facing.Magnitude > 0.001 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + facing.Unit)
	end
	Shoot:FireServer(origin, direction)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.Touch then
		touchState = TouchTracker.began(touchState, input, gp)
		firing = TouchTracker.isFiring(touchState)
	elseif gp then
		return
	elseif
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		if input.KeyCode == Enum.KeyCode.ButtonR2 then
			padAimActive = true
		else
			padAimActive = false
		end
		firing = true
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick2 then
		rightStick = { x = input.Position.X, y = input.Position.Y }
		local filtered = PadAim.applyDeadzone(rightStick)
		if filtered.x ~= 0 or filtered.y ~= 0 then
			padAimActive = true
		end
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		padAimActive = false
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		touchState = TouchTracker.ended(touchState, input)
		firing = TouchTracker.isFiring(touchState)
	elseif
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		firing = false
	end
end)
RunService.RenderStepped:Connect(function()
	if firing then
		tryShoot()
	end
end)
