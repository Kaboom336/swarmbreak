--!strict
-- Mobile-first scythe controls, pooled sharp VFX, and the local-only Reaper Arc camera.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AbilityPool = require(ReplicatedStorage.Shared.AbilityPool)
local TouchLayout = require(ReplicatedStorage.Shared.TouchLayout)
local UltimateTimeline = require(ReplicatedStorage.Shared.UltimateTimeline)

local player = Players.LocalPlayer
local WeaponAbility = (ReplicatedStorage:WaitForChild("Remotes") :: Folder):WaitForChild(
	"WeaponAbility"
) :: RemoteEvent
local WeaponFeelEvent = script.Parent:WaitForChild("WeaponFeelEvent") :: BindableEvent
local DashRequestEvent = script.Parent:WaitForChild("DashRequestEvent") :: BindableEvent
local loadout = AbilityPool.defaultLoadout("Reaper")

local overlay = Instance.new("ScreenGui")
overlay.Name = "ReaperArcGui"
overlay.DisplayOrder = 30
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Name = "SpeedLines"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(35, 12, 60)
backdrop.BackgroundTransparency = 0.28
backdrop.Visible = false
backdrop.Parent = overlay

for index = 1, 12 do
	local line = Instance.new("Frame")
	line.Name = "Line" .. index
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale((index - 0.5) / 12, 0.5)
	line.Size = UDim2.new(0, 5, 1.4, 0)
	line.Rotation = if index % 2 == 0 then 24 else -24
	line.BackgroundColor3 = if index % 3 == 0
		then Color3.fromRGB(255, 210, 55)
		else Color3.fromRGB(188, 70, 255)
	line.BackgroundTransparency = 0.45
	line.BorderSizePixel = 0
	line.Parent = backdrop
end

local callout = Instance.new("TextLabel")
callout.Name = "NameCallout"
callout.AnchorPoint = Vector2.new(0.5, 0.5)
callout.Position = UDim2.fromScale(0.5, 0.72)
callout.Size = UDim2.fromScale(0.8, 0.18)
callout.BackgroundTransparency = 1
callout.Font = Enum.Font.LuckiestGuy
callout.Text = "REAPER ARC"
callout.TextColor3 = Color3.fromRGB(255, 225, 60)
callout.TextStrokeColor3 = Color3.fromRGB(30, 8, 48)
callout.TextStrokeTransparency = 0
callout.TextScaled = true
callout.Parent = backdrop

local impact = Instance.new("Frame")
impact.Name = "ImpactFrame"
impact.Size = UDim2.fromScale(1, 1)
impact.BackgroundColor3 = Color3.new(1, 1, 1)
impact.BorderSizePixel = 0
impact.Visible = false
impact.ZIndex = 20
impact.Parent = overlay

local skip = Instance.new("TextButton")
skip.Name = "Skip"
skip.AnchorPoint = Vector2.new(1, 0)
skip.Position = UDim2.new(1, -18, 0, 18)
skip.Size = UDim2.fromOffset(96, 44)
skip.BackgroundColor3 = Color3.fromRGB(42, 18, 62)
skip.TextColor3 = Color3.new(1, 1, 1)
skip.Font = Enum.Font.GothamBold
skip.Text = "SKIP"
skip.Visible = false
skip.ZIndex = 21
skip.Parent = overlay

local vfxFolder = Instance.new("Folder")
vfxFolder.Name = "ScytheVFX"
vfxFolder.Parent = workspace
local slashPool: { Part } = {}
for index = 1, 8 do
	local slash = Instance.new("Part")
	slash.Name = "Crescent" .. index
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.CanTouch = false
	slash.CastShadow = false
	slash.Material = Enum.Material.SmoothPlastic
	slash.Color = if index % 2 == 0
		then Color3.fromRGB(255, 210, 55)
		else Color3.fromRGB(190, 70, 255)
	slash.Shape = Enum.PartType.Wedge
	slash.Size = Vector3.new(0.25, 0.8, 4)
	slash.Transparency = 1
	slash.Parent = vfxFolder
	table.insert(slashPool, slash)
end

local function playSlashRing(root: BasePart, large: boolean)
	task.spawn(function()
		local started = os.clock()
		local duration = if large then 0.45 else 0.28
		repeat
			local progress = math.clamp((os.clock() - started) / duration, 0, 1)
			local radius = (if large then 5 else 3) + progress * (if large then 18 else 10)
			for index, slash in slashPool do
				local angle = (index - 1) / #slashPool * math.pi * 2 + progress * math.pi
				slash.Transparency = progress ^ 2
				slash.Size = Vector3.new(0.25, 0.8 + 1.5 * (1 - progress), radius * 0.45)
				slash.CFrame = CFrame.new(root.Position)
					* CFrame.Angles(0, angle, 0)
					* CFrame.new(0, 1.2, -radius)
					* CFrame.Angles(0, math.rad(25), math.rad(18))
			end
			RunService.RenderStepped:Wait()
		until progress >= 1 or not root.Parent
		for _, slash in slashPool do
			slash.Transparency = 1
		end
	end)
end

local skipping = false
skip.Activated:Connect(function()
	skipping = true
end)

local function playReaperArc()
	local mode = (player:GetAttribute("UltimateCinematics") :: string?) or "Full"
	local duration = UltimateTimeline.duration(mode)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not root:IsA("BasePart") then
		return
	end
	if duration <= 0 or not camera then
		playSlashRing(root, true)
		return
	end

	skipping = false
	player:SetAttribute("ReaperArcActive", true)
	player:SetAttribute("LocalAnimationSpeed", UltimateTimeline.LocalAnimationScale)
	local oldType = camera.CameraType
	local oldSubject = camera.CameraSubject
	local returnCFrame = camera.CFrame
	local started = os.clock()
	local impactShown = false
	backdrop.Visible = true
	skip.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	repeat
		local elapsed = os.clock() - started
		local sample = UltimateTimeline.sample(mode, elapsed)
		local angle = sample.Progress * math.pi * 1.5 - math.pi * 0.25
		local focus = root.Position + Vector3.new(0, 2, 0)
		local orbit = CFrame.lookAt(
			focus + Vector3.new(math.cos(angle) * 11, 4.5, math.sin(angle) * 11),
			focus
		)
		local returnAlpha = math.clamp((sample.Progress - 0.78) / 0.22, 0, 1)
		returnAlpha = 1 - (1 - returnAlpha) * (1 - returnAlpha)
		camera.CFrame = orbit:Lerp(returnCFrame, returnAlpha)
		if sample.Impact and not impactShown then
			impactShown = true
			impact.Visible = true
			playSlashRing(root, true)
		elseif impactShown then
			impact.Visible = false
		end
		RunService.RenderStepped:Wait()
	until skipping or os.clock() - started >= duration or not root.Parent

	impact.Visible = false
	backdrop.Visible = false
	skip.Visible = false
	camera.CameraType = oldType
	camera.CameraSubject = oldSubject
	player:SetAttribute("LocalAnimationSpeed", 1)
	player:SetAttribute("ReaperArcActive", false)
end

local function cast(abilityId: string)
	WeaponAbility:FireServer(abilityId)
end

local actions = {
	Attack = { Key = Enum.KeyCode.ButtonR2, Label = "ATTACK" },
	Ability1 = { Key = Enum.KeyCode.ButtonL1, Label = "HEAVY" },
	Ability2 = { Key = Enum.KeyCode.ButtonR1, Label = "SPIN" },
	Ultimate = { Key = Enum.KeyCode.ButtonY, Label = "ULT" },
}

ContextActionService:BindAction("Attack", function(_, state)
	if state == Enum.UserInputState.Begin then
		player:SetAttribute("CombatAttackHeld", true)
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		player:SetAttribute("CombatAttackHeld", false)
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.UserInputType.MouseButton1, actions.Attack.Key)
ContextActionService:BindAction("Ability1", function(_, state)
	if state == Enum.UserInputState.Begin then
		cast(loadout.Abilities[1])
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.Z, actions.Ability1.Key)
ContextActionService:BindAction("Ability2", function(_, state)
	if state == Enum.UserInputState.Begin then
		cast(loadout.Abilities[2])
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.X, actions.Ability2.Key)
ContextActionService:BindAction("Ultimate", function(_, state)
	if state == Enum.UserInputState.Begin then
		cast(loadout.Ultimate)
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.R, actions.Ultimate.Key)

for action, definition in actions do
	ContextActionService:SetTitle(action, definition.Label)
end

local function layoutTouchButtons()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local topLeft, bottomRight = GuiService:GetGuiInset()
	local rects = TouchLayout.layout(camera.ViewportSize.X, camera.ViewportSize.Y, {
		Left = topLeft.X,
		Top = topLeft.Y,
		Right = bottomRight.X,
		Bottom = bottomRight.Y,
	})
	for _, action in { "Attack", "Ability1", "Ability2", "Ultimate" } do
		local button = ContextActionService:GetButton(action)
		local rect = rects[action]
		if button and rect then
			button.Size = UDim2.fromOffset(rect.Size, rect.Size)
			ContextActionService:SetPosition(action, UDim2.fromOffset(rect.X, rect.Y))
		end
	end
end

task.defer(layoutTouchButtons)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutTouchButtons)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if player:GetAttribute("ReaperArcActive") == true and not gameProcessed then
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			skipping = true
		end
	end
end)

WeaponAbility.OnClientEvent:Connect(function(abilityId: string)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		WeaponFeelEvent:Fire("ability", root.CFrame.LookVector, abilityId)
		if abilityId == "ReaperArc" then
			task.spawn(playReaperArc)
		else
			if abilityId == "DashSpin" then
				DashRequestEvent:Fire()
			end
			playSlashRing(root, abilityId == "DashSpin")
		end
	end
end)
