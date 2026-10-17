-- Camera/UI only. No input sink, character writes, remote sends or gameplay ownership.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local VR = game:GetService("VRService")
local player = Players.LocalPlayer
local function dependency(parent, name, path)
	local node = parent:WaitForChild(name, 15)
	if not node then
		warn("[TreasureCutscenes] Missing dependency: " .. path .. "; cutscenes disabled")
	end
	return node
end
local core = dependency(RS, "TreasureCore", "ReplicatedStorage.TreasureCore")
if not core then return end
local StyleModule = dependency(RS, "UIStyle", "ReplicatedStorage.UIStyle")
if not StyleModule then return end
local playerGui = dependency(player, "PlayerGui", "LocalPlayer.PlayerGui")
if not playerGui then return end
local cutsceneModule = dependency(core, "Cutscenes", "TreasureCore.Cutscenes")
if not cutsceneModule then return end
local packages = dependency(core, "Packages", "TreasureCore.Packages")
if not packages then return end
local troveModule = dependency(packages, "Trove", "TreasureCore.Packages.Trove")
if not troveModule then return end
local Cutscenes = require(cutsceneModule)
local Style = require(StyleModule)
local Trove = require(troveModule)
local trove = Trove.new()
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "TreasureCutscenes", false, 30, true
gui.Enabled, gui.Parent = false, playerGui
trove:Add(gui)
local bars = {}
for _, y in { 0, 0.94 } do
	local bar = Instance.new("Frame")
	bar.Size, bar.Position = UDim2.fromScale(1, 0.06), UDim2.fromScale(0, y)
	bar.BackgroundColor3, bar.BorderSizePixel, bar.Parent = Style.Colors.Ink, 0, gui
	table.insert(bars, bar)
end
local title = Instance.new("TextLabel")
title.Name, title.AnchorPoint = "TitleCard", Vector2.new(0.5, 0)
-- Below the shared countdown at 26%, clear of the top counters and bottom controls.
title.Position, title.Size = UDim2.new(0.5, 0, 0.38, 36), UDim2.fromScale(0.72, 0.075)
title.Parent = gui
Style.panel(title, Style.Colors.Gold, 36)
local skip = Instance.new("TextButton")
skip.Name, skip.Text, skip.Selectable = "Skip", "Skip", true
skip.AnchorPoint, skip.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0.455, 44)
skip.Size, skip.Parent = UDim2.fromOffset(112, 48), gui
Style.panel(skip, Style.Colors.Cyan, 22)

local function characterParts()
	local character = player.Character
	return character,
		character and character:FindFirstChildOfClass("Humanoid"),
		character and character:FindFirstChild("HumanoidRootPart")
end
local function release(active)
	if active.tween then
		active.tween:Cancel()
		active.tween:Destroy()
		active.tween = nil
	end
	if active.progress then
		active.progress:Destroy()
		active.progress = nil
	end
	local camera = active.lease
	if camera then
		-- Only our leased camera is restored; external capture/replacement owns its own camera.
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = active.fov
		local _, hum = characterParts()
		if hum then
			camera.CameraSubject = hum
		end
		active.lease = nil
	end
	for _, bar in bars do
		bar.Visible = false
	end
end
local runner = Cutscenes.new({
	after = task.delay,
	warn = warn,
	finish = function(active)
		release(active)
		gui.Enabled = false
		local selection = game:GetService("GuiService")
		if selection.SelectedObject == skip then
			selection.SelectedObject = nil
		end
	end,
	titleOnly = release,
	begin = function(active, state)
		title.Text = active.beat.title
		gui.Enabled = true
		local camera = workspace.CurrentCamera
		if active.titleOnly or not camera or camera.CameraType ~= Enum.CameraType.Custom then
			active.titleOnly = true
			for _, bar in bars do
				bar.Visible = false
			end
			return
		end
		-- A missing/streamed target degrades to the card without acquiring the camera.
		local target = active.id == "keeper" and state.keeperPosition or state.target
		if (active.beat.path == "vista" or active.beat.path == "warn") and not target then
			active.titleOnly = true
			for _, bar in bars do
				bar.Visible = false
			end
			return
		end
		active.lease, active.fov, active.start = camera, camera.FieldOfView, camera.CFrame
		active.startRoot, active.target = state.rootPosition, target
		active.portal = state.homePortal
		active.progress = Instance.new("NumberValue")
		active.tween = Tween:Create(
			active.progress,
			TweenInfo.new(active.duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Value = 1 }
		)
		camera.CameraType = Enum.CameraType.Scriptable
		for _, bar in bars do
			bar.Visible = true
		end
		active.tween:Play()
	end,
})
-- Synchronous local handshake: capture must save Custom, not our leased Scriptable type.
local releaseForCapture = Instance.new("BindableFunction")
releaseForCapture.Name, releaseForCapture.Parent = "ReleaseCamera", gui
releaseForCapture.OnInvoke = function()
	runner:finish("capture")
end
trove:Connect(skip.Activated, function()
	runner:finish("skip")
end)
trove:Connect(Input.InputBegan, function()
	runner:finish("input")
end)
trove:Connect(Input.InputChanged, function(input)
	if
		(input.KeyCode == Enum.KeyCode.Thumbstick1 or input.KeyCode == Enum.KeyCode.Thumbstick2)
		and input.Position.Magnitude > 0.15
	then
		runner:finish("stick")
	end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		runner:finish("wheel")
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement and input.Delta.Magnitude > 0 then
		runner:finish("mouse")
	end
end)
trove:Connect(Input.WindowFocusReleased, function()
	runner:finish("focus")
end)
trove:Connect(player.CharacterRemoving, function()
	runner:finish("respawn")
end)
trove:Connect(player:GetAttributeChangedSignal("ReducedMotion"), function()
	if player:GetAttribute("ReducedMotion") and runner.active then
		runner.active.titleOnly = true
		release(runner.active)
	end
end)
-- Capture's changed signal runs before its render binding; never restore over a live capture.
local captureControl, captureConnection
local function bindCapture()
	local control = RS:FindFirstChild("StudioPassControl")
	if control == captureControl then
		return
	end
	if captureConnection then
		captureConnection:Disconnect()
	end
	captureControl = control
	if control then
		captureConnection = control:GetAttributeChangedSignal("CaptureShots"):Connect(function()
			runner:finish("capture")
		end)
	end
end

local function partPosition(part)
	return part and part:IsA("BasePart") and part.Position or nil
end
local landmarks, nextDiscovery = {}, 0
local function discover()
	if os.clock() < nextDiscovery then
		return
	end
	nextDiscovery = os.clock() + 0.5
	local world = workspace:FindFirstChild("GREYBOX")
	local cave = workspace:FindFirstChild("CaveV2")
	landmarks = {
		cave = cave,
		guardian = world and world:FindFirstChild("Guardian", true),
		-- NestAction is the replicated summit landmark underneath the existing gold beam.
		nest = world and world:FindFirstChild("NestAction", true),
		geode = cave and cave:FindFirstChild("Geode"),
		beacon = cave and cave:FindFirstChild("PortalBeacon"),
		homePortal = world and world:FindFirstChild("HomePortal", true),
	}
end
local function snapshot()
	bindCapture()
	discover()
	local character, hum, root = characterParts()
	local camera = workspace.CurrentCamera
	local cave = landmarks.cave
	local guardian = landmarks.guardian
	local keeperPosition = partPosition(guardian)
	local position = root and root.Position
	local item = player:GetAttribute("CaveItemID")
	local carry = player:GetAttribute("GreyboxCarry") == true or item ~= nil
	local danger = not hum or hum.Health <= 0 or hum.WalkSpeed < 16 or hum.Sit or hum.FloorMaterial == Enum.Material.Air
	local spotted = false
	if keeperPosition and position then
		local clip = guardian:GetAttribute("KeeperClip")
		danger = danger
			or (keeperPosition - position).Magnitude < 50
			or (clip ~= nil and clip ~= "idle" and clip ~= "walk")
		if camera and not danger then
			local screen, visible = camera:WorldToViewportPoint(keeperPosition)
			if visible and screen.Z > 0 and (keeperPosition - position).Magnitude < 170 then
				local params = RaycastParams.new()
				params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { character }
				local hit = workspace:Raycast(camera.CFrame.Position, keeperPosition - camera.CFrame.Position, params)
				spotted = not hit
					or hit.Instance == guardian
					or hit.Instance:IsDescendantOf(guardian)
					or (hit.Position - keeperPosition).Magnitude < 10
			end
		end
	end
	local flight = false
	if cave then
		for _, name in { "TNTHook", "DynamiteGuardianHook", "SupportBlastHook" } do
			local hook = cave:FindFirstChild(name)
			if
				hook
				and (
					hook:GetAttribute("Armed")
					or hook:GetAttribute("PayoffPreview")
					or (hook:GetAttribute("TelegraphStage") or 0) > 0
				)
			then
				danger = true
			end
		end
		local seat = hum and hum.SeatPart
		local cart = seat and seat.Parent
		flight = cart ~= nil
			and cart.Parent == cave
			and cart.Name:match("^RideableCart") ~= nil
			and cart:GetAttribute("State") == "Flight"
			and hum:GetAttribute("CaveCartRiding") == true
	end
	local nest = partPosition(landmarks.nest)
	local target = cave and partPosition(landmarks.geode) or nest and nest + Vector3.new(0, 8, 0)
	local beacon = partPosition(landmarks.beacon)
	local shot = player:GetAttribute("StudioPassShot")
	local capture = Run:IsStudio() and shot ~= nil and shot ~= "DONE" and not tostring(shot):match("^FAIL")
	local active = runner.active
	return {
		biome = cave and "cave" or "meadow",
		character = character,
		camera = camera,
		humanoid = hum,
		alive = hum ~= nil and hum.Health > 0 and root ~= nil and camera ~= nil,
		rootPosition = position,
		homePortal = cave and beacon or partPosition(landmarks.homePortal),
		target = target,
		keeperPosition = keeperPosition,
		spotted = spotted,
		danger = danger,
		carry = carry,
		phase = player:GetAttribute("GreyboxPhase"),
		escapes = player:GetAttribute("GreyboxMeadowEscapes") or 0,
		item = item,
		secured = player:GetAttribute("CaveSecured"),
		flight = flight,
		entry = beacon ~= nil and position ~= nil and (position - beacon).Magnitude < 38,
		reduced = player:GetAttribute("ReducedMotion") == true,
		vr = VR.VREnabled,
		moving = hum ~= nil and hum.MoveDirection.Magnitude > 0.05,
		otherCamera = camera ~= nil
			and camera.CameraType ~= Enum.CameraType.Custom
			and not (active and active.lease == camera),
		capture = capture,
	}
end

trove:BindToRenderStep("TreasureCutscenes", Enum.RenderPriority.Camera.Value + 3, function()
	local ok, why = pcall(function()
		local state = snapshot()
		runner:update(state)
		local active = runner.active
		if not active or not active.lease then
			return
		end
		local camera = active.lease
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			runner:finish("ownership")
			return
		end
		local t = active.progress.Value
		local weight = math.sin(t * math.pi) -- exact start/end player view, no final snap.
		local delta = state.rootPosition - active.startRoot
		local follow = active.start + delta
		local path = active.beat.path
		local goal
		if path == "vista" then
			goal = CFrame.lookAt(active.target + Vector3.new(30, 24, 42), active.target)
		elseif path == "warn" then
			goal = CFrame.lookAt(follow.Position, active.target)
		elseif path == "orbit" then
			goal = CFrame.new(state.rootPosition)
				* CFrame.Angles(0, math.rad(12) * weight, 0)
				* CFrame.new(-state.rootPosition)
				* follow
		elseif path == "pull" and active.portal then
			-- Frame the actual return portal, even when the server returns the player to a pen gate.
			goal = CFrame.lookAt(active.portal + Vector3.new(0, 12, 28 + 12 * t), active.portal + Vector3.new(0, 4, 0))
		else
			goal = follow * CFrame.new(0, path == "blast" and 1 or 2, path == "blast" and 4 or 8)
		end
		camera.CFrame = follow:Lerp(goal, weight)
	end)
	if not ok then
		runner:finish("error")
		warn("Cutscenes: " .. tostring(why))
	end
end)
script.Destroying:Connect(function()
	runner:Destroy()
	if captureConnection then
		captureConnection:Disconnect()
	end
	trove:Destroy()
end)
