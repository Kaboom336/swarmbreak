--!strict
-- Hold mouse / touch to fire. Touch-only devices aim at a nearby enemy automatically.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local AimAssist = require(ReplicatedStorage.Shared.AimAssist)
local TouchTracker = require(ReplicatedStorage.Shared.TouchTracker)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent
local StatsChanged = Remotes.StatsChanged :: RemoteEvent
local enemies = workspace:WaitForChild("Enemies")

local TOUCH_AIM_RANGE = 100 -- placeholder
local TOUCH_AIM_ANGLE_DEG = 70 -- placeholder
local touchAutoAim = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local firing = false
local last = 0
local equipped = "Starter"
local fireRateMult = 1
local touchState = TouchTracker.new()

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
		-- GetMouseLocation and ViewportPointToRay share the same raw space.
		local m = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(m.X, m.Y)
		local aimPoint = ray.Origin + ray.Direction * 500
		local rawDirection = (aimPoint - origin).Unit
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
		firing = true
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
