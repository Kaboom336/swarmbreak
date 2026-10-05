--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Grow = require(Shared:WaitForChild("Grow"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local growRequest = remotes:WaitForChild("GrowRequest") :: RemoteEvent
local growEffect = remotes:WaitForChild("GrowEffect") :: RemoteEvent
local statsChanged = remotes:WaitForChild("StatsChanged") :: RemoteEvent

local ORANGE = Color3.fromRGB(255, 116, 25)
local PURPLE = Color3.fromRGB(151, 64, 255)
local LIME = Color3.fromRGB(167, 255, 61)
local TEAL = Color3.fromRGB(13, 53, 63)
local SHADOW = Color3.fromRGB(21, 40, 105)
local WHITE = Color3.fromRGB(255, 250, 218)

local oldGui = playerGui:FindFirstChild("PumpkinHud")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PumpkinHud"
screenGui.DisplayOrder = 10
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local function decorate(guiObject: GuiObject, topColor: Color3, bottomColor: Color3)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = guiObject

	local stroke = Instance.new("UIStroke")
	stroke.Color = TEAL
	stroke.Thickness = 3
	stroke.Parent = guiObject

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(topColor, bottomColor)
	gradient.Rotation = 90
	gradient.Parent = guiObject

	local highlight = Instance.new("Frame")
	highlight.Name = "TopHighlight"
	highlight.BackgroundColor3 = Color3.new(1, 1, 1)
	highlight.BackgroundTransparency = 0.55
	highlight.BorderSizePixel = 0
	highlight.Position = UDim2.fromOffset(12, 5)
	highlight.Size = UDim2.new(1, -24, 0, 4)
	highlight.ZIndex = guiObject.ZIndex + 1
	highlight.Parent = guiObject
	local highlightCorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(1, 0)
	highlightCorner.Parent = highlight
end

local function makeDepthObject(
	className: string,
	name: string,
	size: UDim2,
	position: UDim2,
	anchorPoint: Vector2,
	topColor: Color3,
	bottomColor: Color3
): GuiObject
	local shadow = Instance.new("Frame")
	shadow.Name = name .. "Shadow"
	shadow.AnchorPoint = anchorPoint
	shadow.BackgroundColor3 = SHADOW
	shadow.BorderSizePixel = 0
	shadow.Position = position + UDim2.fromOffset(0, 7)
	shadow.Size = size
	shadow.ZIndex = 1
	shadow.Parent = screenGui
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 12)
	shadowCorner.Parent = shadow

	local face = Instance.new(className) :: GuiObject
	face.Name = name
	face.AnchorPoint = anchorPoint
	face.BackgroundColor3 = topColor
	face.BorderSizePixel = 0
	face.Position = position
	face.Size = size
	face.ZIndex = 2
	face.Parent = screenGui
	decorate(face, topColor, bottomColor)
	return face
end

local statsPanel = makeDepthObject(
	"Frame",
	"Stats",
	UDim2.fromOffset(420, 76),
	UDim2.new(0.5, 0, 0, 18),
	Vector2.new(0.5, 0),
	Color3.fromRGB(37, 96, 119),
	TEAL
)

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Name = "Size"
sizeLabel.BackgroundTransparency = 1
sizeLabel.Font = Enum.Font.GothamBlack
sizeLabel.Position = UDim2.fromOffset(10, 8)
sizeLabel.Size = UDim2.new(0.5, -15, 1, -14)
sizeLabel.TextColor3 = ORANGE
sizeLabel.TextSize = 26
sizeLabel.TextStrokeColor3 = TEAL
sizeLabel.TextStrokeTransparency = 0
sizeLabel.ZIndex = 4
sizeLabel.Parent = statsPanel

local winsLabel = sizeLabel:Clone()
winsLabel.Name = "Wins"
winsLabel.Position = UDim2.new(0.5, 5, 0, 8)
winsLabel.TextColor3 = LIME
winsLabel.Parent = statsPanel

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.AnchorPoint = Vector2.new(0.5, 0.5)
divider.BackgroundColor3 = PURPLE
divider.BorderSizePixel = 0
divider.Position = UDim2.fromScale(0.5, 0.54)
divider.Size = UDim2.fromOffset(3, 46)
divider.ZIndex = 4
divider.Parent = statsPanel

local growButton = makeDepthObject(
	"TextButton",
	"Grow",
	UDim2.fromOffset(270, 78),
	UDim2.new(0.5, 0, 1, -26),
	Vector2.new(0.5, 1),
	ORANGE,
	Color3.fromRGB(201, 55, 28)
) :: TextButton
growButton.AutoButtonColor = false
growButton.Font = Enum.Font.GothamBlack
growButton.Text = "🎃  GROW  +1"
growButton.TextColor3 = WHITE
growButton.TextSize = 32
growButton.TextStrokeColor3 = TEAL
growButton.TextStrokeTransparency = 0

local function abbreviate(value: number): string
	local absolute = math.abs(value)
	local suffixes = {
		{ 1e12, "T" },
		{ 1e9, "B" },
		{ 1e6, "M" },
		{ 1e3, "K" },
	}
	for _, pair in suffixes do
		if absolute >= pair[1] then
			return string.format("%.1f%s", value / pair[1], pair[2])
		end
	end
	if value % 1 == 0 then
		return tostring(math.floor(value))
	end
	return string.format("%.1f", value)
end

local function updateStats(size: number?, wins: number?)
	local currentSize = size or (player:GetAttribute("Size") :: number?) or 0
	local currentWins = wins or (player:GetAttribute("Wins") :: number?) or 0
	sizeLabel.Text = "🎃 SIZE\n" .. abbreviate(currentSize)
	winsLabel.Text = "★ WINS\n" .. abbreviate(currentWins)
end

updateStats(nil, nil)
statsChanged.OnClientEvent:Connect(updateStats)
player:GetAttributeChangedSignal("Size"):Connect(function()
	updateStats(nil, nil)
end)
player:GetAttributeChangedSignal("Wins"):Connect(function()
	updateStats(nil, nil)
end)

local popupPool = {}
for index = 1, 10 do
	local popup = Instance.new("BillboardGui")
	popup.Name = "GrowPopup" .. index
	popup.AlwaysOnTop = true
	popup.Enabled = false
	popup.LightInfluence = 0
	popup.Size = UDim2.fromOffset(150, 54)
	popup.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	popup.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Name = "Amount"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.TextColor3 = ORANGE
	label.TextSize = 34
	label.TextStrokeColor3 = TEAL
	label.TextStrokeTransparency = 0
	label.Parent = popup

	local scale = Instance.new("UIScale")
	scale.Name = "PopScale"
	scale.Parent = label
	table.insert(popupPool, popup)
end

local popupCursor = 0
local function showPopup(amount: number)
	local character = player.Character
	local pumpkin = if character then character:FindFirstChild("Pumpkin") else nil
	if not pumpkin or not pumpkin:IsA("BasePart") then
		return
	end

	popupCursor = popupCursor % #popupPool + 1
	local popup = popupPool[popupCursor]
	local generation = (popup:GetAttribute("Generation") :: number? or 0) + 1
	popup:SetAttribute("Generation", generation)
	popup.Adornee = pumpkin
	popup.Enabled = true
	popup.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)

	local label = popup:FindFirstChild("Amount") :: TextLabel
	local scale = label:FindFirstChild("PopScale") :: UIScale
	label.Text = "+" .. abbreviate(amount)
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
	scale.Scale = 0.55

	TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back), { Scale = 1.15 }):Play()
	TweenService:Create(
		popup,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = Vector3.new(0, 5.7, 0) }
	):Play()
	local fade = TweenService:Create(
		label,
		TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	fade:Play()
	fade.Completed:Connect(function()
		if popup:GetAttribute("Generation") == generation then
			popup.Enabled = false
		end
	end)
end

local function squashPumpkin(newSize: number)
	local character = player.Character
	local pumpkin = if character then character:FindFirstChild("Pumpkin") else nil
	if not pumpkin then
		return
	end
	local mesh = pumpkin:FindFirstChild("PumpkinMesh")
	if not mesh or not mesh:IsA("SpecialMesh") then
		return
	end
	local diameter = Config.PumpkinBaseDiameter * Grow.pumpkinScale(newSize)
	mesh.Scale = Vector3.new(diameter * 1.14, diameter * 0.66, diameter * 1.14)
	TweenService:Create(
		mesh,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = Vector3.new(diameter, diameter * 0.82, diameter) }
	):Play()
end

growEffect.OnClientEvent:Connect(function(amount: number, newSize: number)
	showPopup(amount)
	squashPumpkin(newSize)
end)

local lastRequest = -math.huge
local function requestGrow()
	local now = os.clock()
	if now - lastRequest < 0.075 then
		return
	end
	lastRequest = now
	growRequest:FireServer()
end

local holdingGrow = false
growButton.Activated:Connect(requestGrow)
growButton.InputBegan:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		holdingGrow = true
		requestGrow()
	end
end)
growButton.InputEnded:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		holdingGrow = false
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		requestGrow()
	end
end)

task.spawn(function()
	while true do
		if holdingGrow then
			requestGrow()
		end
		task.wait(0.05)
	end
end)
