--!strict
-- Full-screen boss poster with a camera sweep. Repeat views can be skipped.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BossIntroData = require(ReplicatedStorage.Shared.BossIntro)

local player = Players.LocalPlayer
local BossIntroRemote = ReplicatedStorage:WaitForChild("Remotes").BossIntro :: RemoteEvent
local seenBosses: { [string]: boolean } = {}

local function textLabel(parent: Instance, text: string, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -48, 0, size + 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Antique
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = size
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

BossIntroRemote.OnClientEvent:Connect(function(bossId: string)
	local poster = BossIntroData.Posters[bossId]
	if not poster then
		warn("Missing boss poster for " .. bossId)
		return
	end

	local canSkip = BossIntroData.canSkip(seenBosses[bossId] == true)
	seenBosses[bossId] = true

	local arena = workspace:FindFirstChild("Arena")
	local bossSpawn = arena and arena:FindFirstChild("BossSpawn") :: BasePart?
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local gui = player:WaitForChild("PlayerGui")
	local elementColor =
		Color3.fromRGB(poster.ElementColor[1], poster.ElementColor[2], poster.ElementColor[3])

	local screen = Instance.new("ScreenGui")
	screen.Name = "BossPoster"
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 50
	screen.Parent = gui

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.15
	shade.BorderSizePixel = 0
	shade.Parent = screen

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, -0.5)
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = elementColor:Lerp(Color3.new(0, 0, 0), 0.68)
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = screen

	local border = Instance.new("UIStroke")
	border.Color = elementColor
	border.Thickness = 8
	border.Parent = card

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(1, 0, 0, 18)
	accent.BackgroundColor3 = elementColor
	accent.BorderSizePixel = 0
	accent.Parent = card

	local name = textLabel(card, string.upper(poster.Name), 64)
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.Position = UDim2.fromScale(0.5, 0.46)

	local title = textLabel(card, string.upper(poster.Title), 26)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.67)
	title.TextColor3 = elementColor

	local skipped = false
	if canSkip then
		local skip = Instance.new("TextButton")
		skip.AnchorPoint = Vector2.new(1, 1)
		skip.Position = UDim2.new(1, -24, 1, -20)
		skip.Size = UDim2.fromOffset(150, 48)
		skip.BackgroundColor3 = Color3.new(0, 0, 0)
		skip.BackgroundTransparency = 0.25
		skip.Font = Enum.Font.GothamBold
		skip.Text = "SKIP"
		skip.TextColor3 = Color3.new(1, 1, 1)
		skip.TextSize = 20
		skip.Parent = screen
		skip.Activated:Connect(function()
			skipped = true
		end)
	end

	local cardTween = TweenService:Create(
		card,
		TweenInfo.new(BossIntroData.Duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.5) }
	)
	cardTween:Play()

	local previousCameraType = camera.CameraType
	local cameraTween: Tween? = nil
	if bossSpawn then
		camera.CameraType = Enum.CameraType.Scriptable
		local from = bossSpawn.Position + Vector3.new(30, 25, 30)
		local to = bossSpawn.Position + Vector3.new(14, 10, 14)
		camera.CFrame = CFrame.lookAt(from, bossSpawn.Position)
		cameraTween = TweenService:Create(
			camera,
			TweenInfo.new(BossIntroData.Duration, Enum.EasingStyle.Sine),
			{ CFrame = CFrame.lookAt(to, bossSpawn.Position + Vector3.new(0, 6, 0)) }
		)
		cameraTween:Play()
	end

	local startedAt = os.clock()
	while not skipped and os.clock() - startedAt < BossIntroData.Duration do
		RunService.RenderStepped:Wait()
	end

	cardTween:Cancel()
	if cameraTween then
		cameraTween:Cancel()
	end
	camera.CameraType = previousCameraType
	screen:Destroy()
end)
