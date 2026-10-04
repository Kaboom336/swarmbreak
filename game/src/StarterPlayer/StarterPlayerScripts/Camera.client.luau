--!strict
-- Fixed over-the-shoulder camera for mouse and gamepad. Touch keeps Roblox's camera and auto-aim.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraConfig = require(ReplicatedStorage.Shared.CameraConfig)
local MouseMode = require(ReplicatedStorage.Shared.MouseMode)
local Theme = require(ReplicatedStorage.Shared.Theme)
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local StatsChanged = (ReplicatedStorage:WaitForChild("Remotes") :: Folder):WaitForChild(
	"StatsChanged"
) :: RemoteEvent
local touchOnly =
	CameraConfig.isTouchOnly(UserInputService.TouchEnabled, UserInputService.MouseEnabled)
local mouseLockEnabled = CameraConfig.MouseLockDefault

local cameraGui = Instance.new("ScreenGui")
cameraGui.Name = "CameraHud"
cameraGui.DisplayOrder = 5
cameraGui.IgnoreGuiInset = true
cameraGui.ResetOnSpawn = false
cameraGui.Parent = player:WaitForChild("PlayerGui")
UiKit.ScreenScale(cameraGui)

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(CameraConfig.CrosshairSize, CameraConfig.CrosshairSize)
crosshair.BackgroundTransparency = 1
crosshair.Visible =
	CameraConfig.crosshairVisible(UserInputService.TouchEnabled, UserInputService.MouseEnabled)
crosshair.Parent = cameraGui

local function crosshairLine(name: string, position: UDim2, size: UDim2)
	local line = Instance.new("Frame")
	line.Name = name
	line.Position = position
	line.Size = size
	line.BackgroundColor3 = Color3.fromRGB(Theme.Text[1], Theme.Text[2], Theme.Text[3])
	line.BorderColor3 = Color3.new(0, 0, 0)
	line.BorderSizePixel = 1
	line.Parent = crosshair
end

crosshairLine("Horizontal", UDim2.new(0, 0, 0.5, -1), UDim2.new(1, 0, 0, 2))
crosshairLine("Vertical", UDim2.new(0.5, -1, 0, 0), UDim2.new(0, 2, 1, 0))

local alive = false
local freeHeld = false
local cameraPopped: { [BasePart]: boolean } = {}

local function fadeEnemiesNearCamera(dt: number)
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies or not camera then
		return
	end
	local seen: { [BasePart]: boolean } = {}
	for _, enemy in enemies:GetChildren() do
		if not enemy:IsA("Model") then
			continue
		end
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			continue -- EnemyAnimator.playDeath hides the corpse; don't fade it back in
		end
		local boss = enemy:GetAttribute("Boss") == true
		local fade = math.min(
			1,
			CameraConfig.EnemyFadeTransparency
				* (if boss then CameraConfig.BossFadeMultiplier else 1)
		)
		for _, descendant in enemy:GetDescendants() do
			if descendant:IsA("BasePart") then
				seen[descendant] = true
				local near = (descendant.Position - camera.CFrame.Position).Magnitude
					<= CameraConfig.EnemyFadeRadius
				local target = if near then fade else 0
				local alpha = 1 - math.exp(-12 * dt)
				descendant.LocalTransparencyModifier += (target - descendant.LocalTransparencyModifier) * alpha
				if near and cameraPopped[descendant] == nil then
					cameraPopped[descendant] = descendant.CanCollide
					descendant.CanCollide = false
				elseif not near and cameraPopped[descendant] ~= nil then
					descendant.CanCollide = cameraPopped[descendant]
					cameraPopped[descendant] = nil
				end
			end
		end
	end
	for part, originalCanCollide in cameraPopped do
		if not seen[part] or not part.Parent then
			if part.Parent then
				part.CanCollide = originalCanCollide
			end
			cameraPopped[part] = nil
		end
	end
end

RunService:BindToRenderStep(
	"SwarmBreakEnemyCameraFade",
	Enum.RenderPriority.Camera.Value + 4,
	fadeEnemiesNearCamera
)

local function nearbyEnemyCount(origin: Vector3): number
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then
		return 0
	end

	local radiusSquared = CameraConfig.CrowdRadius * CameraConfig.CrowdRadius
	local count = 0
	for _, enemy in enemies:GetChildren() do
		if enemy:IsA("Model") then
			local enemyRoot = enemy.PrimaryPart or enemy:FindFirstChild("HumanoidRootPart")
			if enemyRoot and enemyRoot:IsA("BasePart") then
				local offset = enemyRoot.Position - origin
				if offset:Dot(offset) <= radiusSquared then
					count += 1
				end
			end
		end
	end
	return count
end

local function mouseState(): MouseMode.State
	return {
		LockPreferred = mouseLockEnabled,
		Alive = alive,
		ModalOpen = player:GetAttribute("ModalOpen") == true,
		FreeHeld = freeHeld,
		TouchOnly = touchOnly,
	}
end

-- One place decides the mouse every frame, so a stats push or death can never strand it locked.
local function applyMouse()
	if touchOnly or not UserInputService.MouseEnabled then
		return
	end
	local locked = MouseMode.locked(mouseState())
	UserInputService.MouseBehavior = if locked
		then Enum.MouseBehavior.LockCenter
		else Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not locked
	crosshair.Visible = locked
end

local function applyMouseLock(enabled: boolean)
	mouseLockEnabled = enabled
	player:SetAttribute("MouseLockEnabled", enabled)
	applyMouse()
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		freeHeld = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		freeHeld = false
	end
end)

-- Bound after the default camera so its per-frame MouseBehavior reset cannot undo the choice.
-- Stays bound through death and menus: that is when the mouse must be released.
RunService:BindToRenderStep("SwarmBreakMouse", Enum.RenderPriority.Camera.Value + 2, applyMouse)

player:GetAttributeChangedSignal("MouseLockEnabled"):Connect(function()
	local enabled = player:GetAttribute("MouseLockEnabled")
	if type(enabled) == "boolean" and enabled ~= mouseLockEnabled then
		applyMouseLock(enabled)
	end
end)

StatsChanged.OnClientEvent:Connect(function(stats: any)
	applyMouseLock(stats.MouseLockEnabled ~= false)
end)

local function bindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	if touchOnly then
		humanoid.AutoRotate = true
		return
	end

	player.CameraMinZoomDistance = CameraConfig.Distance
	player.CameraMaxZoomDistance = CameraConfig.Distance
	humanoid.CameraOffset = Vector3.new(CameraConfig.RightOffset, CameraConfig.HeightOffset, 0)
	humanoid.AutoRotate = false
	alive = true
	local currentDistance = CameraConfig.Distance
	local pitchInitialized = false
	humanoid.Died:Connect(function()
		alive = false
	end)

	local bindName = "SwarmBreakAimCamera"
	local function unbind()
		pcall(function()
			RunService:UnbindFromRenderStep(bindName)
		end)
	end
	unbind()
	RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		if humanoid.Health <= 0 or not character.Parent then
			alive = false
			unbind()
			return
		end

		local enemyCount = 0
		if
			player:GetAttribute("AutoFire") ~= false
			and player:GetAttribute("CardPanelOpen") ~= true
		then
			enemyCount = nearbyEnemyCount(root.Position)
		end
		local targetDistance = CameraConfig.distanceForEnemyCount(enemyCount)
		local distanceAlpha = 1 - math.exp(-CameraConfig.DistanceResponse * dt)
		currentDistance += (targetDistance - currentDistance) * distanceAlpha
		currentDistance =
			math.clamp(currentDistance, CameraConfig.Distance, CameraConfig.CrowdedDistance)
		player.CameraMinZoomDistance = currentDistance
		player.CameraMaxZoomDistance = currentDistance

		local look = camera.CFrame.LookVector
		local horizontalLook = Vector3.new(look.X, 0, look.Z)
		if horizontalLook.Magnitude > 0.001 then
			local pitchDegrees = if pitchInitialized
				then math.deg(math.asin(math.clamp(-look.Y, -1, 1)))
				else CameraConfig.StartPitchDegrees
			pitchInitialized = true
			pitchDegrees =
				math.clamp(pitchDegrees, CameraConfig.MinPitchDegrees, CameraConfig.MaxPitchDegrees)
			local pitch = math.rad(pitchDegrees)
			local direction = horizontalLook.Unit * math.cos(pitch)
				+ Vector3.new(0, -math.sin(pitch), 0)
			camera.CFrame =
				CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + direction)
		end

		if not MouseMode.aimsCharacter(mouseState()) then
			return
		end

		local screenPoint = if mouseLockEnabled or not UserInputService.MouseEnabled
			then camera.ViewportSize / 2
			else UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
		local direction = Vector3.new(ray.Direction.X, 0, ray.Direction.Z)
		if direction.Magnitude > 0.001 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + direction.Unit)
		end
	end)

	humanoid.Died:Connect(unbind)
end

applyMouseLock(CameraConfig.MouseLockDefault)
if player.Character then
	bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)
