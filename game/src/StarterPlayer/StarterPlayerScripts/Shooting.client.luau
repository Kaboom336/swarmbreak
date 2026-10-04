--!strict
-- Auto-fire at the best visible target; click / touch aiming remains a manual override.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local AimAssist = require(ReplicatedStorage.Shared.AimAssist)
local AutoAim = require(ReplicatedStorage.Shared.AutoAim)
local Settings = require(ReplicatedStorage.Shared.Settings)
local TouchTracker = require(ReplicatedStorage.Shared.TouchTracker)
local CameraConfig = require(ReplicatedStorage.Shared.CameraConfig)
local AnimCurves = require(ReplicatedStorage.Shared.AnimCurves)
local WeaponFeelEvent = script.Parent:WaitForChild("WeaponFeelEvent") :: BindableEvent

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent
local StatsChanged = Remotes.StatsChanged :: RemoteEvent
local enemies = workspace:WaitForChild("Enemies")

local TOUCH_AIM_RANGE = 100 -- placeholder
local TOUCH_AIM_ANGLE_DEG = 70 -- placeholder
local touchAutoAim =
	CameraConfig.isTouchOnly(UserInputService.TouchEnabled, UserInputService.MouseEnabled)

local manualFiring = false
local lastFiredAt: number? = nil
local equipped = "Starter"
local fireRateMult = 1
local touchState = TouchTracker.new()
local currentTarget: BasePart? = nil
local aimedMotor: Motor6D? = nil
local aimedBaseC0: CFrame? = nil
local comboStage = 0
local lastMeleeAt = -math.huge

StatsChanged.OnClientEvent:Connect(function(stats)
	equipped = stats.Equipped or "Starter"
	currentTarget = nil
	-- The same rate the server checks shots against (PlayerData.fireRateMultiplier): run
	-- upgrades x the equipped weapon's evolution tier x this run's Trigger cards. This throttle
	-- is what sets the real cadence (the server only guards), so every part is folded in here.
	local _, evoRate = Evolutions.multipliers((stats.Evolutions or {})[equipped])
	fireRateMult = Upgrades.valueAt("FireRate", (stats.Levels and stats.Levels.FireRate) or 0)
		* evoRate
		* (1 + ((stats.Boosts and stats.Boosts.FireRateMult) or 0))
end)

local function restoreUpperBody()
	if aimedMotor and aimedMotor.Parent and aimedBaseC0 then
		aimedMotor.C0 = aimedBaseC0
	end
	aimedMotor = nil
	aimedBaseC0 = nil
end

local function turnUpperBody(char: Model, root: BasePart, direction: Vector3?)
	if not direction then
		restoreUpperBody()
		return
	end

	local found = char:FindFirstChild("Waist", true) or char:FindFirstChild("RootJoint", true)
	local motor = if found and found:IsA("Motor6D") then found else nil
	if motor ~= aimedMotor then
		restoreUpperBody()
		aimedMotor = motor
		aimedBaseC0 = if motor then motor.C0 else nil
	end
	if not motor or not aimedBaseC0 then
		return
	end

	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude <= 0.001 then
		motor.C0 = aimedBaseC0
		return
	end
	local localDirection = root.CFrame:VectorToObjectSpace(flat.Unit)
	local yaw = -math.atan2(localDirection.X, -localDirection.Z)
	motor.C0 = aimedBaseC0 * CFrame.Angles(0, math.clamp(yaw, math.rad(-60), math.rad(60)), 0)
end

local function aliveRoot(model: Instance): (BasePart?, Humanoid?)
	if not model:IsA("Model") then
		return nil, nil
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end

local function hasLineOfSight(origin: Vector3, char: Model, model: Model, target: BasePart): boolean
	local offset = target.Position - origin
	if offset.Magnitude <= 0.001 then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local hit = workspace:Raycast(origin, offset, params)
	return hit == nil or hit.Instance:IsDescendantOf(model)
end

local function autoDirection(char: Model, root: BasePart, origin: Vector3, weapon): Vector3?
	local roots: { BasePart } = {}
	local targets = {}
	local currentIndex: number? = nil
	local range = weapon.Range + if weapon.Kind == "Melee" then 2 else 0

	for _, enemy in enemies:GetChildren() do
		local enemyRoot = aliveRoot(enemy)
		if enemyRoot then
			local model = enemy :: Model
			table.insert(roots, enemyRoot)
			table.insert(targets, {
				position = {
					x = enemyRoot.Position.X,
					y = enemyRoot.Position.Y,
					z = enemyRoot.Position.Z,
				},
				velocity = {
					x = enemyRoot.AssemblyLinearVelocity.X,
					y = enemyRoot.AssemblyLinearVelocity.Y,
					z = enemyRoot.AssemblyLinearVelocity.Z,
				},
				boss = model:GetAttribute("Boss") == true,
				-- Raycast only enemies in range: one ray per enemy per frame adds up in late waves.
				visible = (enemyRoot.Position - origin).Magnitude <= range
					and hasLineOfSight(origin, char, model, enemyRoot),
			})
			if enemyRoot == currentTarget then
				currentIndex = #roots
			end
		end
	end

	local index = AutoAim.pickTarget(
		{ x = origin.X, y = origin.Y, z = origin.Z },
		targets,
		range,
		currentIndex
	)
	currentTarget = if index then roots[index] else nil
	if not currentTarget then
		return nil
	end
	local offset = currentTarget.Position - origin
	return if offset.Magnitude > 0.001 then offset.Unit else root.CFrame.LookVector
end

local function manualDirection(origin: Vector3, root: BasePart, weapon): Vector3
	if touchAutoAim then
		local positions = {}
		local roots = {}
		for _, enemy in enemies:GetChildren() do
			local enemyRoot = aliveRoot(enemy)
			if enemyRoot then
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
		return if target then (target.Position - origin).Unit else look
	end

	-- Mouse lock fires through the centred reticle; the Settings toggle restores cursor aim.
	local camera = workspace.CurrentCamera
	if not camera then
		return root.CFrame.LookVector
	end
	local mouseLock = player:GetAttribute("MouseLockEnabled") ~= false
	local mouse = if mouseLock or not UserInputService.MouseEnabled
		then camera.ViewportSize / 2
		else UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local aimPoint = ray.Origin + ray.Direction * 500
	local rawDirection = (aimPoint - origin).Unit
	local positions = {}
	local roots = {}
	for _, enemy in enemies:GetChildren() do
		local enemyRoot = aliveRoot(enemy)
		if enemyRoot and (enemyRoot.Position - origin).Magnitude <= weapon.Range then
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
	return if target then (target.Position - origin).Unit else rawDirection
end

local function tryShoot(root: BasePart, weapon, origin: Vector3, direction: Vector3)
	if weapon.Kind == "Orbital" then
		return
	end
	local now = os.clock()
	if not AutoAim.canFire(now, lastFiredAt, weapon.FireRate * fireRateMult) then
		return
	end
	lastFiredAt = now
	local facing = Vector3.new(direction.X, 0, direction.Z)
	if facing.Magnitude > 0.001 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + facing.Unit)
	end
	Shoot:FireServer(origin, direction)
	if weapon.Kind == "Melee" then
		comboStage = AnimCurves.nextComboStage(comboStage, lastMeleeAt, now)
		lastMeleeAt = now
		WeaponFeelEvent:Fire("swing", direction, comboStage)
	else
		WeaponFeelEvent:Fire("shot", direction)
	end
end

local function autoFireEnabled(): boolean
	local setting = player:GetAttribute("AutoFire")
	return if type(setting) == "boolean" then setting else Settings.AutoFire
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Touch then
		touchState = TouchTracker.began(touchState, input, gameProcessed)
		manualFiring = TouchTracker.isFiring(touchState)
	elseif gameProcessed then
		return
	elseif
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		manualFiring = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		touchState = TouchTracker.ended(touchState, input)
		manualFiring = TouchTracker.isFiring(touchState)
	elseif
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		manualFiring = false
	end
end)

RunService.RenderStepped:Connect(function()
	if player:GetAttribute("BossIntroInputLocked") == true then
		currentTarget = nil
		manualFiring = false
		restoreUpperBody()
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not root or not humanoid or humanoid.Health <= 0 then
		currentTarget = nil
		restoreUpperBody()
		return
	end

	local weapon = Weapons.Defs[equipped] or Weapons.Defs.Starter
	if weapon.Kind == "Orbital" then
		currentTarget = nil
		restoreUpperBody()
		return
	end
	local origin = root.Position + Vector3.new(0, 1, 0)
	local direction: Vector3? = nil
	if manualFiring then
		currentTarget = nil
		direction = manualDirection(origin, root, weapon)
	elseif autoFireEnabled() then -- keep auto-firing while cards are open (eca9fb2: packs walked onto idle players)
		direction = autoDirection(char, root, origin, weapon)
	else
		currentTarget = nil
	end

	turnUpperBody(char, root, direction)
	WeaponFeelEvent:Fire("aim", direction)
	if direction then
		tryShoot(root, weapon, origin, direction)
	end
end)
