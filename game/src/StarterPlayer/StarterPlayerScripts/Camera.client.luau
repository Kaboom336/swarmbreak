--!strict
-- Fixed over-the-shoulder camera for mouse and gamepad. Touch keeps Roblox's camera and auto-aim.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraConfig = require(ReplicatedStorage.Shared.CameraConfig)

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
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BorderColor3 = Color3.new(0, 0, 0)
	line.BorderSizePixel = 1
	line.Parent = crosshair
end

crosshairLine("Horizontal", UDim2.new(0, 0, 0.5, -1), UDim2.new(1, 0, 0, 2))
crosshairLine("Vertical", UDim2.new(0.5, -1, 0, 0), UDim2.new(0, 2, 1, 0))

local function applyMouseLock(enabled: boolean)
	mouseLockEnabled = enabled
	player:SetAttribute("MouseLockEnabled", enabled)
	if not touchOnly and UserInputService.MouseEnabled then
		UserInputService.MouseBehavior = if enabled
			then Enum.MouseBehavior.LockCenter
			else Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = not enabled
	end
end

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

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if humanoid.Health <= 0 or not character.Parent then
			connection:Disconnect()
			return
		end

		if UserInputService.MouseEnabled then
			UserInputService.MouseBehavior = if mouseLockEnabled
				then Enum.MouseBehavior.LockCenter
				else Enum.MouseBehavior.Default
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

	humanoid.Died:Connect(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end

applyMouseLock(CameraConfig.MouseLockDefault)
if player.Character then
	bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)
