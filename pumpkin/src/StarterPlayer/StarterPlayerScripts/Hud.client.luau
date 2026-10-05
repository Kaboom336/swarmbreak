--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Grow = require(Shared:WaitForChild("Grow"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Monetization = require(Shared:WaitForChild("Monetization"))
local WallProgress = require(Shared:WaitForChild("WallProgress"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local growRequest = remotes:WaitForChild("GrowRequest") :: RemoteEvent
local growEffect = remotes:WaitForChild("GrowEffect") :: RemoteEvent
local statsChanged = remotes:WaitForChild("StatsChanged") :: RemoteEvent
local economyRequest = remotes:WaitForChild("EconomyRequest") :: RemoteFunction
local economyState = remotes:WaitForChild("EconomyState") :: RemoteEvent

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
-- Global: the depth stack puts shadows at ZIndex - 1 as children, which Sibling would draw over the button text
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
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

local function addButtonShadow(button: GuiObject)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = SHADOW
	shadow.BorderSizePixel = 0
	shadow.Position = UDim2.fromOffset(0, 7)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.ZIndex = button.ZIndex - 1
	shadow.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = shadow
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
sizeLabel.Position = UDim2.fromOffset(40, 8)
sizeLabel.Size = UDim2.new(0.5, -45, 1, -14)
sizeLabel.TextColor3 = ORANGE
sizeLabel.TextSize = 26
sizeLabel.TextStrokeColor3 = TEAL
sizeLabel.TextStrokeTransparency = 0
sizeLabel.ZIndex = 4
sizeLabel.Parent = statsPanel
local sizeScale = Instance.new("UIScale")
sizeScale.Parent = sizeLabel

local function addStatIcon(name: string, iconId: string, xScale: number, color: Color3)
	if iconId ~= "" then
		local icon = Instance.new("ImageLabel")
		icon.Name = name .. "Icon"
		icon.BackgroundTransparency = 1
		icon.Image = iconId
		icon.Position = UDim2.new(xScale, 10, 0.5, -16)
		icon.Size = UDim2.fromOffset(32, 32)
		icon.ZIndex = 5
		icon.Parent = statsPanel
	else
		local icon = Instance.new("Frame")
		icon.Name = name .. "VectorIcon"
		icon.BackgroundColor3 = color
		icon.BorderSizePixel = 0
		icon.Position = UDim2.new(xScale, 10, 0.5, -14)
		icon.Size = UDim2.fromOffset(28, 28)
		icon.Rotation = if name == "Wins" then 45 else 0
		icon.ZIndex = 5
		icon.Parent = statsPanel
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, if name == "Size" then 14 else 5)
		corner.Parent = icon
	end
end

addStatIcon("Size", Config.Icons.Size, 0, ORANGE)

local winsLabel = sizeLabel:Clone()
winsLabel.Name = "Wins"
winsLabel.Position = UDim2.new(0.5, 40, 0, 8)
winsLabel.TextColor3 = LIME
winsLabel.Parent = statsPanel
local winsScale = Instance.new("UIScale")
winsScale.Parent = winsLabel
addStatIcon("Wins", Config.Icons.Wins, 0.5, LIME)

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
growButton.Text = "GROW  +1"
growButton.TextColor3 = WHITE
growButton.TextSize = 32
growButton.TextStrokeColor3 = TEAL
growButton.TextStrokeTransparency = 0

local zonePanel = makeDepthObject(
	"Frame",
	"Zone",
	UDim2.fromOffset(250, 104),
	UDim2.new(1, -20, 0.5, 0),
	Vector2.new(1, 0.5),
	PURPLE,
	Color3.fromRGB(73, 33, 130)
)

local zoneLabel = Instance.new("TextLabel")
zoneLabel.Name = "ZoneName"
zoneLabel.BackgroundTransparency = 1
zoneLabel.Font = Enum.Font.GothamBlack
zoneLabel.Position = UDim2.fromOffset(12, 9)
zoneLabel.Size = UDim2.new(1, -24, 0, 48)
zoneLabel.TextColor3 = WHITE
zoneLabel.TextSize = 19
zoneLabel.TextStrokeColor3 = TEAL
zoneLabel.TextStrokeTransparency = 0
zoneLabel.ZIndex = 4
zoneLabel.Parent = zonePanel

local progressBack = Instance.new("Frame")
progressBack.Name = "UnlockProgress"
progressBack.BackgroundColor3 = TEAL
progressBack.BorderSizePixel = 0
progressBack.Position = UDim2.fromOffset(14, 66)
progressBack.Size = UDim2.new(1, -28, 0, 24)
progressBack.ZIndex = 4
progressBack.Parent = zonePanel
addButtonShadow(progressBack)
local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 12)
progressCorner.Parent = progressBack

local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.BackgroundColor3 = LIME
progressFill.BorderSizePixel = 0
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.ZIndex = 5
progressFill.Parent = progressBack
local fillCorner = progressCorner:Clone()
fillCorner.Parent = progressFill

local progressText = Instance.new("TextLabel")
progressText.Name = "NextUnlock"
progressText.BackgroundTransparency = 1
progressText.Font = Enum.Font.GothamBold
progressText.Size = UDim2.fromScale(1, 1)
progressText.TextColor3 = WHITE
progressText.TextSize = 14
progressText.TextStrokeColor3 = TEAL
progressText.TextStrokeTransparency = 0
progressText.ZIndex = 6
progressText.Parent = progressBack

local wallPanel = makeDepthObject(
	"Frame",
	"WallProgress",
	UDim2.fromOffset(360, 42),
	UDim2.new(0.5, 0, 1, -112),
	Vector2.new(0.5, 1),
	Color3.fromRGB(37, 96, 119),
	TEAL
)
local wallFill = Instance.new("Frame")
wallFill.Name = "Fill"
wallFill.BackgroundColor3 = ORANGE
wallFill.BorderSizePixel = 0
wallFill.Size = UDim2.fromScale(0, 1)
wallFill.ZIndex = 3
wallFill.Parent = wallPanel
local wallCorner = Instance.new("UICorner")
wallCorner.CornerRadius = UDim.new(0, 12)
wallCorner.Parent = wallFill
local wallText = Instance.new("TextLabel")
wallText.Name = "Label"
wallText.BackgroundTransparency = 1
wallText.Font = Enum.Font.GothamBlack
wallText.Size = UDim2.fromScale(1, 1)
wallText.TextColor3 = WHITE
wallText.TextSize = 15
wallText.TextStrokeColor3 = TEAL
wallText.TextStrokeTransparency = 0
wallText.ZIndex = 5
wallText.Parent = wallPanel

local multiplierPanel = makeDepthObject(
	"TextLabel",
	"Multipliers",
	UDim2.fromOffset(310, 58),
	UDim2.new(0, 18, 1, -18),
	Vector2.new(0, 1),
	PURPLE,
	Color3.fromRGB(73, 33, 130)
) :: TextLabel
multiplierPanel.Font = Enum.Font.GothamBold
multiplierPanel.TextColor3 = WHITE
multiplierPanel.TextSize = 14
multiplierPanel.TextStrokeColor3 = TEAL
multiplierPanel.TextStrokeTransparency = 0.2
multiplierPanel.TextWrapped = true

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0, 0.5)
menu.BackgroundTransparency = 1
menu.Position = UDim2.new(0, 18, 0.5, 0)
menu.Size = UDim2.fromOffset(150, 318)
menu.ZIndex = 5
menu.Parent = screenGui

local function makeMenuButton(name: string, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = false
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Size = UDim2.fromOffset(64, 64)
	button.Text = ""
	button.TextColor3 = WHITE
	button.TextSize = 20
	button.TextStrokeColor3 = TEAL
	button.TextStrokeTransparency = 0
	button.ZIndex = 6
	button.Parent = menu
	addButtonShadow(button)
	decorate(button, color, color:Lerp(TEAL, 0.3))
	local iconId = Config.Icons[name]
	if iconId and iconId ~= "" then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Image = iconId
		icon.Position = UDim2.new(0.5, -18, 0, 7)
		icon.Size = UDim2.fromOffset(36, 32)
		icon.ZIndex = 8
		icon.Parent = button
	else
		local glyph = Instance.new("Frame")
		glyph.Name = "VectorGlyph"
		glyph.AnchorPoint = Vector2.new(0.5, 0)
		glyph.BackgroundColor3 = WHITE
		glyph.BorderSizePixel = 0
		glyph.Position = UDim2.new(0.5, 0, 0, 10)
		glyph.Size = UDim2.fromOffset(30, 25)
		glyph.ZIndex = 8
		glyph.Parent = button
		local glyphCorner = Instance.new("UICorner")
		glyphCorner.CornerRadius = UDim.new(0, if name == "Settings" then 12 else 5)
		glyphCorner.Parent = glyph
		local cutout = Instance.new("Frame")
		cutout.Name = "GlyphCutout"
		cutout.AnchorPoint = Vector2.new(0.5, 0.5)
		cutout.BackgroundColor3 = color
		cutout.BorderSizePixel = 0
		cutout.Position = UDim2.fromScale(0.5, 0.5)
		cutout.Size = UDim2.fromOffset(10, 10)
		cutout.ZIndex = 9
		cutout.Parent = glyph
	end
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Position = UDim2.new(0.5, 0, 1, -3)
	label.Size = UDim2.new(1, -4, 0, 18)
	label.Text = text
	label.TextColor3 = WHITE
	label.TextSize = 10
	label.TextStrokeColor3 = TEAL
	label.TextStrokeTransparency = 0
	label.ZIndex = 9
	label.Parent = button
	return button
end

local shopButton = makeMenuButton("Shop", "SHOP", ORANGE)
local petsButton = makeMenuButton("Pets", "PETS", PURPLE)
local rebirthButton = makeMenuButton("Rebirth", "REBIRTH", LIME)
local codesButton = makeMenuButton("Codes", "CODES", Color3.fromRGB(55, 190, 214))
local dailyButton = makeMenuButton("Daily", "DAILY", Color3.fromRGB(255, 81, 158))
local passesButton = makeMenuButton("Passes", "PASSES", ORANGE)
local settingsButton = makeMenuButton("Settings", "SETTINGS", Color3.fromRGB(55, 190, 214))
local dailyDot = Instance.new("Frame")
dailyDot.Name = "Notification"
dailyDot.AnchorPoint = Vector2.new(1, 0)
dailyDot.BackgroundColor3 = Color3.fromRGB(245, 45, 60)
dailyDot.BorderSizePixel = 0
dailyDot.Position = UDim2.new(1, 4, 0, -4)
dailyDot.Size = UDim2.fromOffset(15, 15)
dailyDot.Visible = false
dailyDot.ZIndex = 12
dailyDot.Parent = dailyButton
local dailyDotCorner = Instance.new("UICorner")
dailyDotCorner.CornerRadius = UDim.new(1, 0)
dailyDotCorner.Parent = dailyDot

local tutorialPanel = makeDepthObject(
	"TextLabel",
	"Tutorial",
	UDim2.fromOffset(380, 56),
	UDim2.new(0.5, 0, 0, 104),
	Vector2.new(0.5, 0),
	PURPLE,
	Color3.fromRGB(73, 33, 130)
) :: TextLabel
tutorialPanel.Font = Enum.Font.GothamBlack
tutorialPanel.Text = "DOWN  Grow to 10 then roll!"
tutorialPanel.TextColor3 = WHITE
tutorialPanel.TextSize = 20
tutorialPanel.TextStrokeColor3 = TEAL
tutorialPanel.TextStrokeTransparency = 0
tutorialPanel.ZIndex = 8

local growArrow = Instance.new("TextLabel")
growArrow.Name = "GrowArrow"
growArrow.BackgroundTransparency = 1
growArrow.Font = Enum.Font.GothamBlack
growArrow.Text = utf8.char(0x2193)
growArrow.TextColor3 = LIME
growArrow.TextSize = 48
growArrow.TextStrokeColor3 = TEAL
growArrow.TextStrokeTransparency = 0
growArrow.ZIndex = 8
growArrow.Parent = screenGui

local milestone = makeDepthObject(
	"TextLabel",
	"Milestone",
	UDim2.fromOffset(380, 72),
	UDim2.new(0.5, 0, 0.3, 0),
	Vector2.new(0.5, 0.5),
	ORANGE,
	Color3.fromRGB(201, 55, 28)
) :: TextLabel
milestone.Font = Enum.Font.GothamBlack
milestone.TextColor3 = WHITE
milestone.TextSize = 34
milestone.TextStrokeColor3 = TEAL
milestone.TextStrokeTransparency = 0
milestone.Visible = false
milestone.ZIndex = 30
local milestoneShadow = screenGui:FindFirstChild("MilestoneShadow") :: Frame
milestoneShadow.Visible = false
milestoneShadow.ZIndex = 29
local milestoneScale = Instance.new("UIScale")
milestoneScale.Parent = milestone

local clickSound = Instance.new("Sound")
clickSound.Name = "GrowClick"
clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
clickSound.Volume = 0.45
clickSound.Parent = screenGui

local sfxEnabled = true
player:SetAttribute("SFXEnabled", true)
settingsButton.Activated:Connect(function()
	sfxEnabled = not sfxEnabled
	player:SetAttribute("SFXEnabled", sfxEnabled)
	local label = settingsButton:FindFirstChild("Label") :: TextLabel
	label.Text = if sfxEnabled then "SFX ON" else "SFX OFF"
end)

local function applyRect(object: GuiObject, bounds: any, shadowName: string?)
	object.AnchorPoint = Vector2.zero
	object.Position = UDim2.fromOffset(bounds.x, bounds.y)
	object.Size = UDim2.fromOffset(bounds.width, bounds.height)
	if shadowName then
		local shadow = screenGui:FindFirstChild(shadowName)
		if shadow and shadow:IsA("GuiObject") then
			shadow.AnchorPoint = Vector2.zero
			shadow.Position = UDim2.fromOffset(bounds.x, bounds.y + 7)
			shadow.Size = object.Size
		end
	end
end

local function applyLayout(viewport: Vector2)
	local layout = HudLayout.compute(viewport.X, viewport.Y)
	applyRect(statsPanel, layout.stats, "StatsShadow")
	applyRect(growButton, layout.grow, "GrowShadow")
	applyRect(wallPanel, layout.wallProgress, "WallProgressShadow")
	applyRect(multiplierPanel, layout.multipliers, "MultipliersShadow")
	applyRect(zonePanel, layout.zone, "ZoneShadow")
	applyRect(tutorialPanel, layout.tutorial, "TutorialShadow")
	applyRect(growArrow, layout.growArrow, nil)
	menu.AnchorPoint = Vector2.zero
	menu.Position = UDim2.fromOffset(layout.menu.x, layout.menu.y)
	menu.Size = UDim2.fromOffset(layout.menu.width, layout.menu.height)
	for index, button in
		{
			shopButton,
			petsButton,
			rebirthButton,
			codesButton,
			dailyButton,
			passesButton,
			settingsButton,
		}
	do
		local bounds = layout.menuButtons[index]
		button.Position = UDim2.fromOffset(bounds.x - layout.menu.x, bounds.y - layout.menu.y)
		button.Size = UDim2.fromOffset(bounds.width, bounds.height)
	end
	sizeLabel.TextSize = if layout.mobile then 22 else 26
	winsLabel.TextSize = if layout.mobile then 22 else 26
	zoneLabel.TextSize = if layout.mobile then 16 else 19
	progressBack.Position = UDim2.fromOffset(14, if layout.mobile then 53 else 66)
	progressBack.Size = UDim2.new(1, -28, 0, if layout.mobile then 20 else 24)
	wallText.TextSize = if layout.mobile then 13 else 15
	multiplierPanel.TextSize = if layout.mobile then 11 else 14
end

local viewportConnection: RBXScriptConnection? = nil
local function bindViewport()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	-- AbsoluteSize excludes the top-bar inset (IgnoreGuiInset is false), so 667x375 fits
	applyLayout(screenGui.AbsoluteSize)
	viewportConnection = screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applyLayout(screenGui.AbsoluteSize)
	end)
end

bindViewport()

local modal = makeDepthObject(
	"Frame",
	"EconomyPanel",
	UDim2.new(0.72, 0, 0.82, 0),
	UDim2.fromScale(0.5, 0.52),
	Vector2.new(0.5, 0.5),
	Color3.fromRGB(64, 33, 102),
	TEAL
) :: Frame
modal.Visible = false
local modalShadow = screenGui:FindFirstChild("EconomyPanelShadow") :: Frame
modalShadow.Visible = false
-- The panel lives in its own ScreenGui so it always draws above the HUD menu
local modalGui = Instance.new("ScreenGui")
modalGui.Name = "PumpkinPanel"
modalGui.DisplayOrder = screenGui.DisplayOrder + 1
modalGui.ResetOnSpawn = false
modalGui.IgnoreGuiInset = screenGui.IgnoreGuiInset
modalGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
modalGui.Parent = screenGui.Parent
modalShadow.Parent = modalGui
modal.Parent = modalGui
for _, item in { modal, modalShadow } do
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(500, 390)
	constraint.Parent = item
end

local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "Title"
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBlack
modalTitle.Position = UDim2.fromOffset(24, 16)
modalTitle.Size = UDim2.new(1, -80, 0, 50)
modalTitle.TextColor3 = ORANGE
modalTitle.TextSize = 30
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.TextStrokeColor3 = TEAL
modalTitle.TextStrokeTransparency = 0
modalTitle.ZIndex = 5
modalTitle.Parent = modal

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.AutoButtonColor = false
closeButton.BackgroundColor3 = Color3.fromRGB(230, 62, 70)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBlack
closeButton.Position = UDim2.new(1, -14, 0, 12)
closeButton.Size = UDim2.fromOffset(56, 56)
closeButton.Text = "X"
closeButton.TextColor3 = WHITE
closeButton.TextSize = 25
closeButton.ZIndex = 6
closeButton.Parent = modal
addButtonShadow(closeButton)
decorate(closeButton, Color3.fromRGB(255, 91, 93), Color3.fromRGB(189, 40, 70))

local modalContent = Instance.new("Frame")
modalContent.Name = "Content"
modalContent.BackgroundTransparency = 1
modalContent.Position = UDim2.fromOffset(22, 82)
modalContent.Size = UDim2.new(1, -44, 1, -104)
modalContent.ZIndex = 5
modalContent.Parent = modal

local notice = Instance.new("TextLabel")
notice.Name = "Notice"
notice.AnchorPoint = Vector2.new(0.5, 1)
notice.BackgroundTransparency = 1
notice.Font = Enum.Font.GothamBold
notice.Position = UDim2.new(0.5, 0, 1, -8)
notice.Size = UDim2.new(1, -30, 0, 38)
notice.Text = ""
notice.TextColor3 = WHITE
notice.TextSize = 17
notice.TextWrapped = true
notice.ZIndex = 8
notice.Parent = modal

local function clearContent()
	for _, child in modalContent:GetChildren() do
		child:Destroy()
	end
	notice.Text = ""
end

local function showPanel(title: string)
	clearContent()
	modalTitle.Text = title
	modal.Visible = true
	modalShadow.Visible = true
end

local function actionButton(
	parent: Instance,
	text: string,
	position: UDim2,
	color: Color3
): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Position = position
	button.Size = UDim2.new(1, 0, 0, 62)
	button.Text = text
	button.TextColor3 = WHITE
	button.TextSize = 21
	button.TextStrokeColor3 = TEAL
	button.TextStrokeTransparency = 0
	button.ZIndex = 7
	button.Parent = parent
	addButtonShadow(button)
	decorate(button, color, color:Lerp(TEAL, 0.3))
	return button
end

local currentEconomyState: any = nil
local function requestEconomy(action: string, value: any?): any
	local ok, response = pcall(function()
		return economyRequest:InvokeServer(action, value)
	end)
	if not ok then
		notice.Text = "The server is busy. Try again."
		return nil
	end
	if response.State then
		currentEconomyState = response.State
		dailyDot.Visible = response.State.DailyClaimable == true
	end
	notice.Text = response.Message or ""
	return response
end

local function showShop()
	showPanel("HALLOWEEN SHOP")
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Offers"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.ScrollBarThickness = 8
	scroll.Size = UDim2.new(1, 0, 1, -40)
	scroll.ZIndex = 6
	scroll.Parent = modalContent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local offerCount = 0
	for name, offer in Monetization.GamePasses do
		if offer.Id > 0 then
			offerCount += 1
			local button =
				actionButton(scroll, name .. "  •  " .. offer.Price .. " R$", UDim2.new(), PURPLE)
			button.Activated:Connect(function()
				MarketplaceService:PromptGamePassPurchase(player, offer.Id)
			end)
		end
	end
	for name, offer in Monetization.DeveloperProducts do
		if offer.Id > 0 then
			offerCount += 1
			local button =
				actionButton(scroll, name .. "  •  " .. offer.Price .. " R$", UDim2.new(), ORANGE)
			button.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, offer.Id)
			end)
		end
	end
	if offerCount == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.GothamBlack
		empty.Size = UDim2.new(1, 0, 0, 120)
		empty.Text = "NEW TREATS\nCOMING SOON!"
		empty.TextColor3 = LIME
		empty.TextSize = 28
		empty.ZIndex = 7
		empty.Parent = scroll
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
	end)
end

local function showRebirth()
	showPanel("REBIRTH")
	requestEconomy("GetState")
	local cost = if currentEconomyState then currentEconomyState.RebirthCost else 0
	local description = Instance.new("TextLabel")
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.GothamBold
	description.Size = UDim2.new(1, 0, 0, 130)
	description.Text = string.format(
		"Reset Size, Wins, and zones\nfor a permanent +0.5x Size boost.\n\nCost: %d Wins",
		cost
	)
	description.TextColor3 = WHITE
	description.TextSize = 21
	description.TextWrapped = true
	description.ZIndex = 6
	description.Parent = modalContent
	local confirm = actionButton(modalContent, "REBIRTH NOW", UDim2.new(0, 0, 0, 150), LIME)
	confirm.Activated:Connect(function()
		local response = requestEconomy("Rebirth")
		if response and response.Ok then
			confirm.Text = "REBIRTHED!"
		end
	end)
end

local function showCodes()
	showPanel("REDEEM A CODE")
	local box = Instance.new("TextBox")
	box.Name = "Code"
	box.BackgroundColor3 = Color3.fromRGB(25, 74, 88)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamBlack
	box.PlaceholderText = "ENTER CODE"
	box.Position = UDim2.fromOffset(0, 40)
	box.Size = UDim2.new(1, 0, 0, 64)
	box.Text = ""
	box.TextColor3 = WHITE
	box.TextSize = 24
	box.ZIndex = 6
	box.Parent = modalContent
	addButtonShadow(box)
	decorate(box, Color3.fromRGB(37, 106, 125), TEAL)
	local redeem = actionButton(modalContent, "REDEEM", UDim2.new(0, 0, 0, 130), ORANGE)
	redeem.Activated:Connect(function()
		requestEconomy("RedeemCode", box.Text)
	end)
end

local function showDaily()
	showPanel("7-DAY REWARDS")
	requestEconomy("GetState")
	local streak = if currentEconomyState then currentEconomyState.DailyStreak else 0
	local calendar = Instance.new("Frame")
	calendar.BackgroundTransparency = 1
	calendar.Size = UDim2.new(1, 0, 0, 112)
	calendar.Parent = modalContent
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(6, 6)
	layout.CellSize = UDim2.new(1 / 4, -6, 0, 50)
	layout.Parent = calendar
	for day = 1, 7 do
		local cell = Instance.new("TextLabel")
		cell.BackgroundColor3 = if day <= streak then LIME else PURPLE
		cell.BorderSizePixel = 0
		cell.Font = Enum.Font.GothamBlack
		cell.Text = string.format("DAY %d\n%d WINS", day, Config.DailyRewards[day])
		cell.TextColor3 = if day <= streak then TEAL else WHITE
		cell.TextSize = 15
		cell.ZIndex = 6
		cell.Parent = calendar
		addButtonShadow(cell)
		decorate(cell, cell.BackgroundColor3, cell.BackgroundColor3:Lerp(TEAL, 0.25))
	end
	local claim = actionButton(
		modalContent,
		"CLAIM TODAY",
		UDim2.new(0, 0, 0, 142),
		Color3.fromRGB(255, 81, 158)
	)
	if currentEconomyState and not currentEconomyState.DailyClaimable then
		claim.Text = "COME BACK TOMORROW"
	end
	claim.Activated:Connect(function()
		local response = requestEconomy("ClaimDaily")
		if response and response.Ok then
			claim.Text = "CLAIMED!"
		end
	end)
end

closeButton.Activated:Connect(function()
	modal.Visible = false
	modalShadow.Visible = false
end)
shopButton.Activated:Connect(showShop)
petsButton.Activated:Connect(function()
	local request = (player:GetAttribute("PetsPanelRequest") :: number?) or 0
	player:SetAttribute("PetsPanelRequest", request + 1)
end)
rebirthButton.Activated:Connect(showRebirth)
codesButton.Activated:Connect(showCodes)
dailyButton.Activated:Connect(showDaily)
passesButton.Activated:Connect(showShop)
economyState.OnClientEvent:Connect(function(state)
	currentEconomyState = state
	dailyDot.Visible = state.DailyClaimable == true
end)
task.spawn(function()
	local response = requestEconomy("GetState")
	if response and response.State then
		dailyDot.Visible = response.State.DailyClaimable == true
	end
end)

TextChatService.OnIncomingMessage = function(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	if not source then
		return nil
	end
	local speaker = Players:GetPlayerByUserId(source.UserId)
	if not speaker or speaker:GetAttribute("VIP") ~= true then
		return nil
	end
	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = '<font color="#A7FF3D">[VIP]</font> ' .. message.PrefixText
	return properties
end

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

local startArrow = Instance.new("BillboardGui")
startArrow.Name = "TutorialStartArrow"
startArrow.AlwaysOnTop = true
startArrow.Enabled = false
startArrow.LightInfluence = 0
startArrow.Size = UDim2.fromOffset(190, 100)
startArrow.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
startArrow.Parent = playerGui
local startArrowText = Instance.new("TextLabel")
startArrowText.BackgroundTransparency = 1
startArrowText.Font = Enum.Font.GothamBlack
startArrowText.Size = UDim2.fromScale(1, 1)
startArrowText.Text = "START HERE\n" .. utf8.char(0x2193)
startArrowText.TextColor3 = LIME
startArrowText.TextSize = 25
startArrowText.TextStrokeColor3 = TEAL
startArrowText.TextStrokeTransparency = 0
startArrowText.Parent = startArrow

local tutorialReady = false
local function updateTutorial(size: number)
	if player:GetAttribute("TutorialDone") == true then
		tutorialPanel.Visible = false
		local shadow = screenGui:FindFirstChild("TutorialShadow")
		if shadow and shadow:IsA("GuiObject") then
			shadow.Visible = false
		end
		startArrow.Enabled = false
		growArrow.Visible = false
		return
	end
	if size >= Config.TutorialRollSize then
		tutorialReady = true
	end
	tutorialPanel.Visible = true
	local shadow = screenGui:FindFirstChild("TutorialShadow")
	if shadow and shadow:IsA("GuiObject") then
		shadow.Visible = true
	end
	if tutorialReady then
		tutorialPanel.Text = "FOLLOW THE ARROW - STEP ON THE START PAD!"
		startArrow.Enabled = startArrow.Adornee ~= nil
		growArrow.Visible = false
	else
		tutorialPanel.Text = "Grow to 10 then roll!"
		startArrow.Enabled = false
		growArrow.Visible = true
	end
end

task.spawn(function()
	while true do
		local candidate = workspace:FindFirstChild("ZoneStart_" .. Config.Zones[1].Name, true)
		if candidate and candidate:IsA("BasePart") then
			startArrow.Adornee = candidate
			updateTutorial((player:GetAttribute("Size") :: number?) or 0)
			return
		end
		task.wait(0.5)
	end
end)

local milestoneGeneration = 0
local function showMilestone(amount: number, newSize: number)
	-- Compare against the size before this grow, so a returning player's saved size never fires a banner
	local before = newSize - amount
	local crossed = nil
	for _, target in { 10, 100, 1_000, 10_000, 100_000, 1_000_000 } do
		if before < target and newSize >= target then
			crossed = target
		end
	end
	if not crossed then
		return
	end
	milestoneGeneration += 1
	local generation = milestoneGeneration
	milestone.Text = "SIZE " .. string.upper(abbreviate(crossed)) .. "!"
	milestone.Visible = true
	milestoneShadow.Visible = true
	milestoneScale.Scale = 0.55
	TweenService:Create(
		milestoneScale,
		TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
	task.delay(1.4, function()
		if milestoneGeneration == generation then
			milestone.Visible = false
			milestoneShadow.Visible = false
		end
	end)
end

local displayedSize: number? = nil
local displayedWins: number? = nil
local function popNumber(scale: UIScale)
	scale.Scale = 1.28
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function updateStats(size: number?, wins: number?)
	local currentSize = size or (player:GetAttribute("Size") :: number?) or 0
	local currentWins = wins or (player:GetAttribute("Wins") :: number?) or 0
	if displayedSize ~= nil and displayedSize ~= currentSize then
		popNumber(sizeScale)
	end
	if displayedWins ~= nil and displayedWins ~= currentWins then
		popNumber(winsScale)
	end
	displayedSize = currentSize
	displayedWins = currentWins
	sizeLabel.Text = "SIZE\n" .. abbreviate(currentSize)
	winsLabel.Text = "WINS\n" .. abbreviate(currentWins)

	local currentZoneName = (player:GetAttribute("CurrentZone") :: string?) or Config.Zones[1].Name
	local currentDisplay = Config.Zones[1].DisplayName
	for _, zone in Config.Zones do
		if zone.Name == currentZoneName then
			currentDisplay = zone.DisplayName
			break
		end
	end
	zoneLabel.Text = "ZONE\n" .. currentDisplay
	local wallState = WallProgress.compute(currentSize, currentZoneName, Config.FallbackWallCount)
	wallFill.Size = UDim2.fromScale(wallState.progress, 1)
	if wallState.nextWall then
		wallText.Text = string.format(
			"%d WALLS  •  %s / %s TO NEXT",
			wallState.wallsBroken,
			abbreviate(currentSize),
			abbreviate(wallState.nextHealth or 0)
		)
	else
		wallText.Text = string.format("%d WALLS  •  TRACK CLEARED", wallState.wallsBroken)
	end
	local petMultiplier = (player:GetAttribute("PetMultiplier") :: number?) or 1
	local rebirths = (player:GetAttribute("Rebirths") :: number?) or 0
	local rebirthMultiplier = 1 + rebirths * Config.RebirthSizeBonus
	local friendPercent =
		math.floor(((player:GetAttribute("FriendBoost") :: number?) or 0) * 100 + 0.5)
	local passChips = {}
	if player:GetAttribute("DoubleSize") == true then
		table.insert(passChips, "2x SIZE")
	end
	if player:GetAttribute("DoubleWins") == true then
		table.insert(passChips, "2x WINS")
	end
	multiplierPanel.Text = string.format(
		"PETS ×%.1f  •  REBIRTH ×%.1f\nFRIEND BOOST +%d%%%s",
		petMultiplier,
		rebirthMultiplier,
		friendPercent,
		if #passChips > 0 then "  •  " .. table.concat(passChips, "  ") else ""
	)

	local totalWins = (player:GetAttribute("TotalWins") :: number?) or 0
	local nextZone = nil
	for _, zone in Config.Zones do
		if totalWins < zone.RequiredWins then
			nextZone = zone
			break
		end
	end
	if nextZone then
		progressFill.Size = UDim2.fromScale(math.clamp(totalWins / nextZone.RequiredWins, 0, 1), 1)
		progressText.Text = abbreviate(totalWins) .. " / " .. abbreviate(nextZone.RequiredWins)
	else
		progressFill.Size = UDim2.fromScale(1, 1)
		progressText.Text = "ALL ZONES UNLOCKED"
	end
	updateTutorial(currentSize)
end

updateStats(nil, nil)
statsChanged.OnClientEvent:Connect(updateStats)
player:GetAttributeChangedSignal("Size"):Connect(function()
	updateStats(nil, nil)
end)
player:GetAttributeChangedSignal("Wins"):Connect(function()
	updateStats(nil, nil)
end)
player:GetAttributeChangedSignal("TotalWins"):Connect(function()
	updateStats(nil, nil)
end)
player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	updateStats(nil, nil)
end)
player:GetAttributeChangedSignal("TutorialDone"):Connect(function()
	updateStats(nil, nil)
end)
for _, attribute in { "PetMultiplier", "Rebirths", "FriendBoost", "DoubleSize", "DoubleWins" } do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		updateStats(nil, nil)
	end)
end

local popupPool = {}
for index = 1, 10 do
	local popup = Instance.new("BillboardGui")
	popup.Name = "GrowPopup" .. index
	popup.AlwaysOnTop = true
	popup.Enabled = false
	popup.LightInfluence = 0
	popup.Size = UDim2.fromOffset(300, 108)
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
	label.TextSize = 68
	label.TextStrokeColor3 = TEAL
	label.TextStrokeTransparency = 0
	label.Parent = popup

	local scale = Instance.new("UIScale")
	scale.Name = "PopScale"
	scale.Parent = label
	table.insert(popupPool, popup)
end

local seedPool = {}
for index = 1, 8 do
	local seed = Instance.new("Frame")
	seed.Name = "PumpkinSeed" .. index
	seed.AnchorPoint = Vector2.new(0.5, 0.5)
	seed.BackgroundColor3 = Color3.fromRGB(255, 211, 94)
	seed.BorderSizePixel = 0
	seed.Size = UDim2.fromOffset(12, 18)
	seed.Rotation = 35
	seed.Visible = false
	seed.ZIndex = 25
	seed.Parent = screenGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = seed
	table.insert(seedPool, seed)
end

local seedCursor = 0
local function burstSeeds()
	local start = growButton.AbsolutePosition + growButton.AbsoluteSize * 0.5
	local target = sizeLabel.AbsolutePosition + sizeLabel.AbsoluteSize * 0.5
	for index = 1, 5 do
		seedCursor = seedCursor % #seedPool + 1
		local seed = seedPool[seedCursor]
		seed.Position = UDim2.fromOffset(start.X + (index - 3) * 12, start.Y + math.random(-6, 6))
		seed.Visible = true
		seed.BackgroundTransparency = 0
		local tween = TweenService:Create(
			seed,
			TweenInfo.new(0.38 + index * 0.025, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromOffset(target.X, target.Y), Rotation = seed.Rotation + 180 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			seed.Visible = false
		end)
	end
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
	popup.StudsOffsetWorldSpace =
		Vector3.new(math.random(-24, 24) / 10, 2.8, math.random(-12, 12) / 10)

	local label = popup:FindFirstChild("Amount") :: TextLabel
	local scale = label:FindFirstChild("PopScale") :: UIScale
	label.Text = "+" .. abbreviate(amount)
	local rainbow = label:FindFirstChild("Rainbow") :: UIGradient?
	if amount >= 1_000 then
		label.TextColor3 = Color3.new(1, 1, 1)
		if not rainbow then
			rainbow = Instance.new("UIGradient")
			rainbow.Name = "Rainbow"
			rainbow.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 130)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 55)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 220, 255)),
			})
			rainbow.Parent = label
		end
		rainbow.Enabled = true
	else
		if rainbow then
			rainbow.Enabled = false
		end
		label.TextColor3 = if amount >= 100
			then Color3.fromRGB(255, 81, 158)
			elseif amount >= 25 then ORANGE
			elseif amount >= 5 then Color3.fromRGB(255, 224, 73)
			else WHITE
	end
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
	local diameter = Config.PumpkinBaseDiameter
		* Grow.pumpkinScale(newSize)
		* Config.PumpkinMeshScale
	mesh.Scale = Vector3.new(diameter * 1.14, diameter * 0.66, diameter * 1.14)
	TweenService:Create(
		mesh,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = Vector3.new(diameter, diameter * 0.82, diameter) }
	):Play()
end

growEffect.OnClientEvent:Connect(function(amount: number, newSize: number)
	if sfxEnabled then
		clickSound:Play()
	end
	showPopup(amount)
	squashPumpkin(newSize)
	showMilestone(amount, newSize)
	burstSeeds()
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
