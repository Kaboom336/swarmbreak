--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CameraFraming = require(Shared:WaitForChild("CameraFraming"))
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Grow = require(Shared:WaitForChild("Grow"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Monetization = require(Shared:WaitForChild("Monetization"))
local Style = require(Shared:WaitForChild("Style"))
local Tutorial = require(Shared:WaitForChild("Tutorial"))
local WallProgress = require(Shared:WaitForChild("WallProgress"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local growRequest = remotes:WaitForChild("GrowRequest") :: RemoteEvent
local growEffect = remotes:WaitForChild("GrowEffect") :: RemoteEvent
local statsChanged = remotes:WaitForChild("StatsChanged") :: RemoteEvent
local economyRequest = remotes:WaitForChild("EconomyRequest") :: RemoteFunction
local economyState = remotes:WaitForChild("EconomyState") :: RemoteEvent

local function paletteColor(role: string): Color3
	local value = Style.Palette[role]
	return Color3.fromRGB(value.r, value.g, value.b)
end

local ORANGE = paletteColor("orange")
local PURPLE = paletteColor("purple")
local LIME = paletteColor("lime")
local CYAN = paletteColor("cyan")
local MAGENTA = paletteColor("magenta")
local YELLOW = paletteColor("yellow")
local INK = paletteColor("ink")
local TEAL = INK:Lerp(CYAN, 0.18)
local SHADOW = Color3.fromRGB(31, 38, 92)
local WHITE = paletteColor("white")
local baseCameraMinZoomDistance = player.CameraMinZoomDistance

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

local buttonSound = Instance.new("Sound")
buttonSound.Name = "ButtonPress"
buttonSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
buttonSound.Volume = 0.24
buttonSound.Parent = screenGui

local contactShadow = Instance.new("Part")
contactShadow.Name = "PumpkinContactShadow"
contactShadow.Anchored = true
contactShadow.CanCollide = false
contactShadow.CanQuery = false
contactShadow.CanTouch = false
contactShadow.CastShadow = false
contactShadow.Color = INK
contactShadow.Material = Enum.Material.SmoothPlastic
contactShadow.Shape = Enum.PartType.Cylinder
contactShadow.Size = Vector3.new(0.08, 4, 4)
contactShadow.Transparency = 1
contactShadow.Parent = workspace

local shadowRaycastParams = RaycastParams.new()
shadowRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RunService.RenderStepped:Connect(function()
	local character = player.Character
	local pumpkin = if character then character:FindFirstChild("Pumpkin") else nil
	if player:GetAttribute("Rolling") == true or not pumpkin or not pumpkin:IsA("BasePart") then
		contactShadow.Transparency = 1
		return
	end
	shadowRaycastParams.FilterDescendantsInstances = { character :: Model }
	local hit = workspace:Raycast(pumpkin.Position, Vector3.new(0, -100, 0), shadowRaycastParams)
	if not hit then
		contactShadow.Transparency = 1
		return
	end
	local diameter = math.clamp(pumpkin.Size.X * 0.72, 3.2, 16)
	contactShadow.Size = Vector3.new(0.08, diameter, diameter)
	contactShadow.CFrame = CFrame.new(hit.Position + hit.Normal * 0.06)
		* CFrame.Angles(0, 0, math.pi / 2)
	contactShadow.Transparency = 0.56
end)

local function newLabel(className: string?): any
	local label = Instance.new(className or "TextLabel") :: any
	local labelStyle = Style.label()
	label.TextColor3 =
		Color3.fromRGB(labelStyle.textColor.r, labelStyle.textColor.g, labelStyle.textColor.b)
	label.TextStrokeTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Name = "LabelStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color =
		Color3.fromRGB(labelStyle.strokeColor.r, labelStyle.strokeColor.g, labelStyle.strokeColor.b)
	stroke.Thickness = labelStyle.strokeThickness
	stroke.Parent = label
	return label
end

local function applyTextToken(label: TextLabel | TextButton | TextBox, tokenName: string)
	local token = Style.textToken(tokenName)
	label.TextSize = math.max(label.TextSize, token.minimumSize)
	local stroke = label:FindFirstChild("LabelStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Thickness = token.strokeThickness
	end
end

local function playPop(scale: UIScale, tierName: string)
	local tier = Style.popTier(tierName, player:GetAttribute("ReducedMotion") == true)
	scale.Scale = tier.startScale
	local contact = TweenService:Create(
		scale,
		TweenInfo.new(tier.contactSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = tier.overshootScale }
	)
	contact:Play()
	contact.Completed:Once(function()
		TweenService:Create(
			scale,
			TweenInfo.new(tier.settleSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end)
end

local function decorate(guiObject: GuiObject, topColor: Color3, bottomColor: Color3)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = guiObject

	local stroke = Instance.new("UIStroke")
	stroke.Name = "PanelStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = INK
	stroke.Thickness = 3
	stroke.Parent = guiObject

	if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
		-- A UIGradient tints the text too (white text turns purple), so text objects get a flat fill
		guiObject.BackgroundColor3 = topColor:Lerp(bottomColor, 0.4)
	else
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(topColor, bottomColor)
		gradient.Rotation = 90
		gradient.Parent = guiObject
	end

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

local function bindButtonFeedback(button: TextButton)
	local scale = Instance.new("UIScale")
	scale.Name = "ButtonFeedbackScale"
	scale.Parent = button

	local shineClip = Instance.new("Frame")
	shineClip.Name = "ShineClip"
	shineClip.BackgroundTransparency = 1
	shineClip.ClipsDescendants = true
	shineClip.Size = UDim2.fromScale(1, 1)
	shineClip.ZIndex = button.ZIndex + 2
	shineClip.Parent = button
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 0.55
	shine.BorderSizePixel = 0
	shine.Position = UDim2.new(-0.25, 0, 0.5, 0)
	shine.Rotation = 18
	shine.Size = UDim2.new(0.22, 0, 1.8, 0)
	shine.ZIndex = shineClip.ZIndex
	shine.Parent = shineClip

	local pressed = false
	local pressOffsetApplied = false
	local function refreshDisabled()
		button.BackgroundTransparency = if button.Active then 0 else 0.35
		if not button.Active then
			scale.Scale = 0.96
		end
	end
	local function sweep()
		shine.Position = UDim2.new(-0.25, 0, 0.5, 0)
		TweenService:Create(
			shine,
			TweenInfo.new(
				Style.Button.shineSeconds,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{ Position = UDim2.new(1.25, 0, 0.5, 0) }
		):Play()
	end
	button.MouseEnter:Connect(function()
		if not pressed and button.Active then
			TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1.03 }):Play()
		end
	end)
	button.MouseLeave:Connect(function()
		if not pressed then
			TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
		end
	end)
	button.InputBegan:Connect(function(input)
		if
			button.Active
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			pressed = true
			button.Position += UDim2.fromOffset(0, Style.Button.pressPixels)
			pressOffsetApplied = true
			TweenService:Create(
				scale,
				TweenInfo.new(Style.Button.pressSeconds, Enum.EasingStyle.Quad),
				{ Scale = 0.94 }
			):Play()
		end
	end)
	button.InputEnded:Connect(function(input)
		if
			pressed
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			pressed = false
			if pressOffsetApplied then
				button.Position -= UDim2.fromOffset(0, Style.Button.pressPixels)
				pressOffsetApplied = false
			end
			TweenService:Create(
				scale,
				TweenInfo.new(
					Style.Button.reboundSeconds,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),
				{ Scale = 1 }
			):Play()
			sweep()
			if player:GetAttribute("SFXEnabled") ~= false then
				buttonSound:Play()
			end
		end
	end)
	button.SelectionGained:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1.03 }):Play()
		sweep()
	end)
	button.SelectionLost:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	button:GetPropertyChangedSignal("Active"):Connect(refreshDisabled)
	refreshDisabled()
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

	local face = if className == "TextLabel"
			or className == "TextButton"
			or className == "TextBox"
		then newLabel(className) :: GuiObject
		else Instance.new(className) :: GuiObject
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

local sizeLabel = newLabel() :: TextLabel
sizeLabel.Name = "Size"
sizeLabel.BackgroundTransparency = 1
sizeLabel.Font = Enum.Font.GothamBlack
sizeLabel.Position = UDim2.fromOffset(40, 8)
sizeLabel.Size = UDim2.new(0.5, -45, 1, -14)
sizeLabel.TextSize = 26
sizeLabel.ZIndex = 4
sizeLabel.Parent = statsPanel
applyTextToken(sizeLabel, "hero")
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
winsLabel.Parent = statsPanel
applyTextToken(winsLabel, "hero")
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
growButton.TextSize = 32
applyTextToken(growButton, "hero")
bindButtonFeedback(growButton)

local zonePanel = makeDepthObject(
	"Frame",
	"Zone",
	UDim2.fromOffset(250, 104),
	UDim2.new(1, -20, 0.5, 0),
	Vector2.new(1, 0.5),
	PURPLE,
	Color3.fromRGB(73, 33, 130)
)

local zoneLabel = newLabel() :: TextLabel
zoneLabel.Name = "ZoneName"
zoneLabel.BackgroundTransparency = 1
zoneLabel.Font = Enum.Font.GothamBlack
zoneLabel.Position = UDim2.fromOffset(12, 9)
zoneLabel.Size = UDim2.new(1, -24, 0, 48)
zoneLabel.TextSize = 19
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

local progressText = newLabel() :: TextLabel
progressText.Name = "NextUnlock"
progressText.BackgroundTransparency = 1
progressText.Font = Enum.Font.GothamBold
progressText.Size = UDim2.fromScale(1, 1)
progressText.TextSize = 14
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
local wallText = newLabel() :: TextLabel
wallText.Name = "Label"
wallText.BackgroundTransparency = 1
wallText.Font = Enum.Font.GothamBlack
wallText.Size = UDim2.fromScale(1, 1)
wallText.TextSize = 15
wallText.ZIndex = 5
wallText.Parent = wallPanel

local multiplierPanel = Instance.new("Frame")
multiplierPanel.Name = "Multipliers"
multiplierPanel.BackgroundTransparency = 1
multiplierPanel.ClipsDescendants = false
multiplierPanel.ZIndex = 5
multiplierPanel.Parent = screenGui
local multiplierLayout = Instance.new("UIListLayout")
multiplierLayout.FillDirection = Enum.FillDirection.Vertical
multiplierLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
multiplierLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
multiplierLayout.Padding = UDim.new(0, 4)
multiplierLayout.SortOrder = Enum.SortOrder.LayoutOrder
multiplierLayout.Parent = multiplierPanel
local multiplierChips: { TextLabel } = {}

local function setMultiplierChips(texts: { string })
	for index, text in texts do
		local chip = multiplierChips[index]
		if not chip then
			chip = newLabel() :: TextLabel
			chip.Name = "MultiplierChip" .. index
			chip.BackgroundColor3 = PURPLE
			chip.BorderSizePixel = 0
			chip.Font = Enum.Font.GothamBlack
			chip.TextSize = 12
			chip.TextTruncate = Enum.TextTruncate.AtEnd
			chip.Size = UDim2.new(1, 0, 0, if screenGui.AbsoluteSize.X <= 800 then 20 else 24)
			chip.ZIndex = 6
			chip.Parent = multiplierPanel
			addButtonShadow(chip)
			decorate(chip, PURPLE, Color3.fromRGB(73, 33, 130))
			table.insert(multiplierChips, chip)
		end
		chip.LayoutOrder = #texts - index + 1
		chip.Text = text
		chip.Visible = true
	end
	for index = #texts + 1, #multiplierChips do
		multiplierChips[index].Visible = false
	end
end

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0, 0.5)
menu.BackgroundTransparency = 1
menu.Position = UDim2.new(0, 18, 0.5, 0)
menu.Size = UDim2.fromOffset(150, 318)
menu.ZIndex = 5
menu.Parent = screenGui

local function makeMenuButton(name: string, text: string, color: Color3): TextButton
	local button = newLabel("TextButton") :: TextButton
	button.Name = name
	button.AutoButtonColor = false
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Size = UDim2.fromOffset(64, 64)
	button.Text = ""
	button.TextSize = 20
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
	local label = newLabel() :: TextLabel
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Position = UDim2.new(0.5, 0, 1, -3)
	label.Size = UDim2.new(1, -4, 0, 18)
	label.Text = text
	label.TextSize = 14
	label.ZIndex = 9
	label.Parent = button
	applyTextToken(label, "body")
	bindButtonFeedback(button)
	return button
end

local shopButton = makeMenuButton("Shop", "SHOP", ORANGE)
local petsButton = makeMenuButton("Pets", "PETS", PURPLE)
local rebirthButton = makeMenuButton("Rebirth", "REBIRTH", LIME)
local codesButton = makeMenuButton("Codes", "CODES", CYAN)
local dailyButton = makeMenuButton("Daily", "DAILY", MAGENTA)
local passesButton = makeMenuButton("Passes", "PASSES", ORANGE)
local settingsButton = makeMenuButton("Settings", "SETTINGS", CYAN)
local giftsButton = makeMenuButton("Gift", "GIFTS", MAGENTA)
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
local giftsDot = dailyDot:Clone()
giftsDot.Name = "Notification"
giftsDot.Parent = giftsButton

local starterPackChip = makeDepthObject(
	"TextButton",
	"StarterPack",
	UDim2.fromOffset(190, 58),
	UDim2.new(1, -18, 1, -92),
	Vector2.new(1, 1),
	ORANGE,
	Color3.fromRGB(201, 55, 28)
) :: TextButton
starterPackChip.AutoButtonColor = false
starterPackChip.Font = Enum.Font.GothamBlack
starterPackChip.TextSize = 16
applyTextToken(starterPackChip, "action")
bindButtonFeedback(starterPackChip)
starterPackChip.Visible = false
local starterPackShadow = screenGui:FindFirstChild("StarterPackShadow") :: Frame
starterPackShadow.Visible = false
starterPackChip.Activated:Connect(function()
	local offer = Monetization.DeveloperProducts.StarterPack
	if offer.Id > 0 then
		MarketplaceService:PromptProductPurchase(player, offer.Id)
	end
end)

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
tutorialPanel.TextSize = 20
tutorialPanel.ZIndex = 8
applyTextToken(tutorialPanel, "action")

local growArrow = newLabel() :: TextLabel
growArrow.Name = "GrowArrow"
growArrow.BackgroundTransparency = 1
growArrow.Font = Enum.Font.GothamBlack
growArrow.Text = utf8.char(0x2193)
growArrow.TextSize = 48
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
milestone.TextSize = 34
milestone.Visible = false
milestone.ZIndex = 30
local milestoneShadow = screenGui:FindFirstChild("MilestoneShadow") :: Frame
milestoneShadow.Visible = false
milestoneShadow.ZIndex = 29
local milestoneScale = Instance.new("UIScale")
milestoneScale.Parent = milestone
applyTextToken(milestone, "hero")

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
	local layout = HudLayout.compute(
		viewport.X,
		viewport.Y,
		if player:GetAttribute("Rolling") == true then "ride" else nil
	)
	applyRect(statsPanel, layout.stats, "StatsShadow")
	applyRect(growButton, layout.grow, "GrowShadow")
	applyRect(wallPanel, layout.wallProgress, "WallProgressShadow")
	applyRect(multiplierPanel, layout.multipliers, nil)
	applyRect(starterPackChip, layout.starterPack, "StarterPackShadow")
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
			giftsButton,
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
	multiplierLayout.Padding = UDim.new(0, if layout.mobile then 2 else 4)
	for _, chip in multiplierChips do
		chip.Size = UDim2.new(1, 0, 0, if layout.mobile then 20 else 24)
		chip.TextSize = 14
	end
	tutorialPanel.TextSize = if layout.mobile then 18 else 20
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

local modalTitle = newLabel() :: TextLabel
modalTitle.Name = "Title"
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBlack
modalTitle.Position = UDim2.fromOffset(24, 16)
modalTitle.Size = UDim2.new(1, -80, 0, 50)
modalTitle.TextSize = 30
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.ZIndex = 5
modalTitle.Parent = modal

local closeButton = newLabel("TextButton") :: TextButton
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.AutoButtonColor = false
closeButton.BackgroundColor3 = Color3.fromRGB(230, 62, 70)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBlack
closeButton.Position = UDim2.new(1, -14, 0, 12)
closeButton.Size = UDim2.fromOffset(56, 56)
closeButton.Text = "X"
closeButton.TextSize = 25
closeButton.ZIndex = 6
closeButton.Parent = modal
addButtonShadow(closeButton)
decorate(closeButton, MAGENTA, MAGENTA:Lerp(INK, 0.35))
applyTextToken(closeButton, "action")
bindButtonFeedback(closeButton)

local modalContent = Instance.new("Frame")
modalContent.Name = "Content"
modalContent.BackgroundTransparency = 1
modalContent.Position = UDim2.fromOffset(22, 82)
modalContent.Size = UDim2.new(1, -44, 1, -104)
modalContent.ZIndex = 5
modalContent.Parent = modal

local notice = newLabel() :: TextLabel
notice.Name = "Notice"
notice.AnchorPoint = Vector2.new(0.5, 1)
notice.BackgroundTransparency = 1
notice.Font = Enum.Font.GothamBold
notice.Position = UDim2.new(0.5, 0, 1, -8)
notice.Size = UDim2.new(1, -30, 0, 38)
notice.Text = ""
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
	local button = newLabel("TextButton") :: TextButton
	button.AutoButtonColor = false
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Position = position
	button.Size = UDim2.new(1, 0, 0, 62)
	button.Text = text
	button.TextSize = 21
	button.ZIndex = 7
	button.Parent = parent
	addButtonShadow(button)
	decorate(button, color, color:Lerp(TEAL, 0.3))
	applyTextToken(button, "action")
	bindButtonFeedback(button)
	return button
end

local currentEconomyState: any = nil
local economyStateReceivedAt = os.clock()
local function acceptEconomyState(state: any)
	currentEconomyState = state
	economyStateReceivedAt = os.clock()
	dailyDot.Visible = state.DailyClaimable == true
end
local function requestEconomy(action: string, value: any?): any
	local ok, response = pcall(function()
		return economyRequest:InvokeServer(action, value)
	end)
	if not ok then
		notice.Text = "The server is busy. Try again."
		return nil
	end
	if response.State then
		acceptEconomyState(response.State)
	end
	notice.Text = response.Message or ""
	return response
end

local function giftDescription(gift: any): string
	if gift.Kind == "Wins" then
		return "+" .. gift.Amount .. " WINS"
	elseif gift.Kind == "Size" then
		return "+" .. gift.Amount .. " SIZE"
	elseif gift.Kind == "LuckyPotion" then
		return "LUCKY POTION"
	end
	return "FREE SPOOKY EGG"
end

local function showGifts()
	showPanel("PLAYTIME GIFTS")
	requestEconomy("GetState")
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "GiftList"
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new()
	scroll.ScrollBarThickness = 8
	scroll.Size = UDim2.new(1, 0, 1, -30)
	scroll.ZIndex = 6
	scroll.Parent = modalContent
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.CellSize = UDim2.new(0.5, -8, 0, 64)
	grid.Parent = scroll

	local starterClaimed = currentEconomyState and currentEconomyState.StarterGiftClaimed
	local starter = actionButton(
		scroll,
		if starterClaimed then "STARTER CLAIMED" else "CLAIM STARTER\n50 WINS + 5M LUCK",
		UDim2.new(),
		LIME
	)
	starter.Activated:Connect(function()
		local response = requestEconomy("ClaimStarterGift")
		if response and response.Ok then
			showGifts()
		end
	end)

	local sessionSeconds = if currentEconomyState then currentEconomyState.SessionSeconds else 0
	local claims = if currentEconomyState then currentEconomyState.PlaytimeGiftClaims else {}
	for index, gift in Config.PlaytimeGifts do
		local ready = sessionSeconds >= gift.Minutes * 60 and claims[tostring(index)] ~= true
		local claimed = claims[tostring(index)] == true
		local button = actionButton(
			scroll,
			string.format(
				"%d MIN  %s\n%s",
				gift.Minutes,
				giftDescription(gift),
				if claimed then "CLAIMED" elseif ready then "CLAIM!" else "LOCKED"
			),
			UDim2.new(),
			if ready then ORANGE elseif claimed then LIME else PURPLE
		)
		button.Activated:Connect(function()
			if ready then
				local response = requestEconomy("ClaimPlaytimeGift", index)
				if response and response.Ok then
					showGifts()
				end
			end
		end)
	end
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
		local empty = newLabel() :: TextLabel
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.GothamBlack
		empty.Size = UDim2.new(1, 0, 0, 120)
		empty.Text = "NEW TREATS\nCOMING SOON!"
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
	local description = newLabel() :: TextLabel
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.GothamBold
	description.Size = UDim2.new(1, 0, 0, 130)
	description.Text = string.format(
		"Reset Size, Wins, and zones\nfor a permanent +0.5x Size boost.\n\nCost: %d Wins",
		cost
	)
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
	local box = newLabel("TextBox") :: TextBox
	box.Name = "Code"
	box.BackgroundColor3 = Color3.fromRGB(25, 74, 88)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamBlack
	box.PlaceholderText = "ENTER CODE"
	box.Position = UDim2.fromOffset(0, 40)
	box.Size = UDim2.new(1, 0, 0, 64)
	box.Text = ""
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
		local cell = newLabel() :: TextLabel
		cell.BackgroundColor3 = if day <= streak then LIME else PURPLE
		cell.BorderSizePixel = 0
		cell.Font = Enum.Font.GothamBlack
		cell.Text = string.format("DAY %d\n%d WINS", day, Config.DailyRewards[day])
		cell.TextSize = 15
		cell.ZIndex = 6
		cell.Parent = calendar
		addButtonShadow(cell)
		decorate(cell, cell.BackgroundColor3, cell.BackgroundColor3:Lerp(TEAL, 0.25))
	end
	local claim = actionButton(modalContent, "CLAIM TODAY", UDim2.new(0, 0, 0, 142), MAGENTA)
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
giftsButton.Activated:Connect(function()
	if currentEconomyState and not currentEconomyState.StarterGiftClaimed then
		requestEconomy("ClaimStarterGift")
	end
	showGifts()
end)
economyState.OnClientEvent:Connect(function(state)
	acceptEconomyState(state)
end)
task.spawn(function()
	local response = requestEconomy("GetState")
	if response and response.State then
		dailyDot.Visible = response.State.DailyClaimable == true
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		local state = currentEconomyState
		if state then
			local sessionSeconds = state.SessionSeconds
				+ math.max(0, math.floor(os.clock() - economyStateReceivedAt))
			local claims = state.PlaytimeGiftClaims or {}
			local nextSeconds = 0
			local claimable = not state.StarterGiftClaimed
			for index, gift in Config.PlaytimeGifts do
				if claims[tostring(index)] ~= true then
					local remaining = math.max(0, gift.Minutes * 60 - sessionSeconds)
					if remaining == 0 then
						claimable = true
					end
					if nextSeconds == 0 or remaining < nextSeconds then
						nextSeconds = remaining
					end
				end
			end
			local label = giftsButton:FindFirstChild("Label") :: TextLabel
			label.Text = if claimable
				then "CLAIM"
				else string.format("%d:%02d", math.floor(nextSeconds / 60), nextSeconds % 60)
			giftsDot.Visible = claimable
		end

		local offer = Monetization.DeveloperProducts.StarterPack
		local endsAt = (player:GetAttribute("StarterPackOfferEndsAt") :: number?) or 0
		local purchased = player:GetAttribute("StarterPackPurchased") == true
		local remaining = math.max(0, endsAt - os.time())
		local visible = offer.Id > 0
			and not purchased
			and remaining > 0
			and player:GetAttribute("Rolling") ~= true
		starterPackChip.Visible = visible
		starterPackShadow.Visible = visible
		if visible then
			starterPackChip.Text = string.format(
				"STARTER PACK  %d R$\n%d:%02d",
				offer.Price,
				math.floor(remaining / 60),
				remaining % 60
			)
		end
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
	properties.PrefixText = '<font color="#B7FF1A">[VIP]</font> ' .. message.PrefixText
	return properties
end

local startArrow = Instance.new("BillboardGui")
startArrow.Name = "TutorialStartArrow"
startArrow.AlwaysOnTop = true
startArrow.Enabled = false
startArrow.LightInfluence = 0
startArrow.Size = UDim2.fromOffset(190, 100)
startArrow.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
startArrow.Parent = playerGui
local startArrowText = newLabel() :: TextLabel
startArrowText.BackgroundTransparency = 1
startArrowText.Font = Enum.Font.GothamBlack
startArrowText.Size = UDim2.fromScale(1, 1)
startArrowText.Text = "ROLL HERE\n" .. utf8.char(0x25BC)
startArrowText.TextSize = 25
startArrowText.Parent = startArrow
applyTextToken(startArrowText, "action")

local startHalo = Instance.new("Highlight")
startHalo.Name = "TutorialTargetHalo"
startHalo.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
startHalo.FillColor = ORANGE
startHalo.FillTransparency = 0.72
startHalo.OutlineColor = YELLOW
startHalo.OutlineTransparency = 0
startHalo.Enabled = false
startHalo.Parent = workspace

local guideRibbon = Instance.new("Folder")
guideRibbon.Name = "TutorialGuideRibbon"
guideRibbon.Parent = workspace
local guideDots = {}
for index = 1, 7 do
	local dot = Instance.new("Part")
	dot.Name = "GuideDot" .. index
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanQuery = false
	dot.CanTouch = false
	dot.Color = ORANGE
	dot.Material = Enum.Material.Neon
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.new(0.75, 0.22, 0.75)
	dot.Transparency = 1
	dot.Parent = guideRibbon
	table.insert(guideDots, dot)
end

local function updateTutorial(size: number)
	local rolling = player:GetAttribute("Rolling") == true
	if rolling then
		modal.Visible = false
		modalShadow.Visible = false
	end
	menu.Visible = not rolling
	zonePanel.Visible = not rolling
	local zoneShadow = screenGui:FindFirstChild("ZoneShadow")
	if zoneShadow and zoneShadow:IsA("GuiObject") then
		zoneShadow.Visible = not rolling
	end
	growButton.Visible = not rolling
	local growShadow = screenGui:FindFirstChild("GrowShadow")
	if growShadow and growShadow:IsA("GuiObject") then
		growShadow.Visible = not rolling
	end
	multiplierPanel.Visible = not rolling
	starterPackChip.Visible = starterPackChip.Visible and not rolling
	starterPackShadow.Visible = starterPackShadow.Visible and not rolling
	wallPanel.Visible = not rolling
	local wallShadow = screenGui:FindFirstChild("WallProgressShadow")
	if wallShadow and wallShadow:IsA("GuiObject") then
		wallShadow.Visible = not rolling
	end
	local banner = Tutorial.banner(size, player:GetAttribute("TutorialDone") == true)
	if rolling or not banner then
		tutorialPanel.Visible = false
		local shadow = screenGui:FindFirstChild("TutorialShadow")
		if shadow and shadow:IsA("GuiObject") then
			shadow.Visible = false
		end
		startArrow.Enabled = false
		startHalo.Enabled = false
		for _, dot in guideDots do
			dot.Transparency = 1
		end
		growArrow.Visible = false
		applyLayout(screenGui.AbsoluteSize)
		return
	end
	tutorialPanel.Visible = true
	tutorialPanel.Text = banner
	local shadow = screenGui:FindFirstChild("TutorialShadow")
	if shadow and shadow:IsA("GuiObject") then
		shadow.Visible = true
	end
	if size >= Config.TutorialRollSize then
		startArrow.Enabled = startArrow.Adornee ~= nil
		startHalo.Enabled = startHalo.Adornee ~= nil
		growArrow.Visible = false
	else
		startArrow.Enabled = false
		startHalo.Enabled = false
		for _, dot in guideDots do
			dot.Transparency = 1
		end
		growArrow.Visible = true
	end
	applyLayout(screenGui.AbsoluteSize)
end

task.spawn(function()
	while true do
		local candidate = workspace:FindFirstChild("ZoneStart_" .. Config.Zones[1].Name, true)
		if candidate and candidate:IsA("BasePart") then
			startArrow.Adornee = candidate
			startHalo.Adornee = candidate
			updateTutorial((player:GetAttribute("Size") :: number?) or 0)
			return
		end
		task.wait(0.5)
	end
end)

local guideClock = 0
RunService.RenderStepped:Connect(function(deltaTime)
	guideClock += deltaTime
	local bounce = math.sin(guideClock * math.pi * 3)
	startArrow.StudsOffsetWorldSpace = Vector3.new(0, 7.2 + bounce * 0.55, 0)
	if growArrow.Visible then
		growArrow.Rotation = bounce * 6
	end
	if not startArrow.Enabled then
		return
	end
	local target = startArrow.Adornee
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not target or not target:IsA("BasePart") or not root or not root:IsA("BasePart") then
		return
	end
	local distance = (target.Position - root.Position).Magnitude
	startArrowText.Text = string.format("ROLL HERE  %d STUDS\n%s", distance, utf8.char(0x25BC))
	for index, dot in guideDots do
		local alpha = index / (#guideDots + 1)
		local position = root.Position:Lerp(target.Position, alpha)
		dot.Position = Vector3.new(position.X, math.max(0.15, position.Y - 2.8), position.Z)
		dot.Transparency = 0.18 + 0.22 * math.sin(guideClock * 5 - index * 0.7) ^ 2
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
	milestone.Text = "SIZE " .. string.upper(Format.abbrev(crossed)) .. "!"
	milestone.Visible = true
	milestoneShadow.Visible = true
	playPop(milestoneScale, "rare")
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
	playPop(scale, "micro")
end

local cameraZoomGeneration = 0
-- Only move the camera when the zoom target really changes, so stat updates keep the player's own zoom
local lastZoomTarget: number? = nil
local function updateCameraZoom(size: number)
	local character = player.Character
	local pumpkin = if character then character:FindFirstChild("Pumpkin") else nil
	local diameter = if pumpkin and pumpkin:IsA("BasePart")
		then pumpkin:GetAttribute("VisualDiameter") :: number?
		else nil
	local visualDiameter = diameter or Grow.pumpkinVisualDiameter(size, 5)
	local persistentMinZoom = math.min(
		player.CameraMaxZoomDistance,
		math.max(baseCameraMinZoomDistance, visualDiameter * Config.PumpkinMinZoomPerDiameter)
	)
	local framing = CameraFraming.compute(visualDiameter, false)
	local startingDistance = math.min(player.CameraMaxZoomDistance, framing.distance)
	if lastZoomTarget and math.abs(startingDistance - lastZoomTarget) < 0.5 then
		return
	end
	lastZoomTarget = startingDistance
	cameraZoomGeneration += 1
	local generation = cameraZoomGeneration
	player.CameraMinZoomDistance = startingDistance
	task.spawn(function()
		RunService.RenderStepped:Wait()
		if generation ~= cameraZoomGeneration then
			return
		end
		if player:GetAttribute("Rolling") ~= true then
			local camera = workspace.CurrentCamera
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if camera and root and root:IsA("BasePart") then
				local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
				if look.Magnitude < 0.01 then
					look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				end
				look = look.Unit
				local position = root.Position
					- look * startingDistance
					+ Vector3.new(0, framing.height, 0)
				camera.CFrame = CFrame.lookAt(position, root.Position + Vector3.new(0, 2, 0))
			end
		end
		RunService.RenderStepped:Wait()
		if generation == cameraZoomGeneration then
			player.CameraMinZoomDistance = persistentMinZoom
		end
	end)
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
	updateCameraZoom(currentSize)
	sizeLabel.Text = "SIZE\n" .. Format.abbrev(currentSize)
	winsLabel.Text = "WINS\n" .. Format.abbrev(currentWins)

	local currentZoneName = (player:GetAttribute("CurrentZone") :: string?) or Config.Zones[1].Name
	local currentDisplay = Config.Zones[1].DisplayName
	local currentZoneIndex = 1
	for index, zone in Config.Zones do
		if zone.Name == currentZoneName then
			currentDisplay = zone.DisplayName
			currentZoneIndex = index
			break
		end
	end
	zoneLabel.Text = "ZONE\n" .. currentDisplay
	local totalWins = (player:GetAttribute("TotalWins") :: number?) or 0
	local wallState = WallProgress.compute(currentSize, currentZoneName, Config.FallbackWallCount)
	wallFill.Size = UDim2.fromScale(wallState.progress, 1)
	if wallState.nextWall then
		wallText.Text = string.format(
			"%d WALLS  •  %s / %s  •  +%s WINS",
			wallState.wallsBroken,
			Format.abbrev(currentSize),
			Format.abbrev(wallState.nextHealth or 0),
			Format.abbrev(wallState.wins)
		)
	else
		local followingZone = Config.Zones[currentZoneIndex + 1]
		if followingZone and totalWins < followingZone.RequiredWins then
			wallText.Text = string.format(
				"%d WALLS  •  +%s WINS  •  NEXT: %s %s%d",
				wallState.totalWallsBroken,
				Format.abbrev(wallState.wins),
				followingZone.DisplayName,
				utf8.char(0x00D7),
				followingZone.WinMultiplier
			)
		elseif followingZone then
			wallText.Text = string.format(
				"%d WALLS  •  +%s WINS  •  TRY %s %s%d %s",
				wallState.totalWallsBroken,
				Format.abbrev(wallState.wins),
				followingZone.DisplayName,
				utf8.char(0x00D7),
				followingZone.WinMultiplier,
				utf8.char(0x2192)
			)
		else
			wallText.Text = string.format(
				"%d WALLS  •  +%s WINS",
				wallState.totalWallsBroken,
				Format.abbrev(wallState.wins)
			)
		end
	end
	local petMultiplier = (player:GetAttribute("PetMultiplier") :: number?) or 1
	local rebirths = (player:GetAttribute("Rebirths") :: number?) or 0
	local rebirthMultiplier = 1 + rebirths * Config.RebirthSizeBonus
	local friendPercent =
		math.floor(((player:GetAttribute("FriendBoost") :: number?) or 0) * 100 + 0.5)
	local chipLines = {}
	if petMultiplier > 1 then
		table.insert(chipLines, string.format("PETS %s%.1f", utf8.char(0x00D7), petMultiplier))
	end
	if rebirthMultiplier > 1 then
		table.insert(
			chipLines,
			string.format("REBIRTH %s%.1f", utf8.char(0x00D7), rebirthMultiplier)
		)
	end
	if friendPercent > 0 then
		table.insert(chipLines, "FRIEND +" .. friendPercent .. "%")
	end
	local indexPercent =
		math.floor((((player:GetAttribute("IndexMultiplier") :: number?) or 1) - 1) * 100 + 0.5)
	if indexPercent > 0 then
		table.insert(chipLines, "INDEX +" .. indexPercent .. "%")
	end
	if player:GetAttribute("DoubleSize") == true then
		table.insert(chipLines, "2" .. utf8.char(0x00D7) .. " SIZE")
	end
	if player:GetAttribute("DoubleWins") == true then
		table.insert(chipLines, "2" .. utf8.char(0x00D7) .. " WINS")
	end
	setMultiplierChips(chipLines)

	local nextZone = nil
	for _, zone in Config.Zones do
		if totalWins < zone.RequiredWins then
			nextZone = zone
			break
		end
	end
	if nextZone then
		progressFill.Size = UDim2.fromScale(math.clamp(totalWins / nextZone.RequiredWins, 0, 1), 1)
		progressText.Text = Format.abbrev(totalWins)
			.. " / "
			.. Format.abbrev(nextZone.RequiredWins)
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
player:GetAttributeChangedSignal("Rolling"):Connect(function()
	if player:GetAttribute("Rolling") ~= true then
		-- The ride camera was scripted, so reframe the normal camera once the ride ends
		lastZoomTarget = nil
	end
	updateStats(nil, nil)
end)
for _, attribute in
	{ "PetMultiplier", "Rebirths", "FriendBoost", "IndexMultiplier", "DoubleSize", "DoubleWins" }
do
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
	local burst = Instance.new("Frame")
	burst.Name = "RewardPlate"
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.BackgroundColor3 = ORANGE
	burst.BorderSizePixel = 0
	burst.Position = UDim2.fromScale(0.5, 0.5)
	burst.Rotation = 8
	burst.Size = UDim2.fromScale(0.72, 0.7)
	burst.Visible = false
	burst.ZIndex = 1
	burst.Parent = popup
	local burstCorner = Instance.new("UICorner")
	burstCorner.CornerRadius = UDim.new(0, 18)
	burstCorner.Parent = burst
	local burstGradient = Instance.new("UIGradient")
	burstGradient.Color = ColorSequence.new(ORANGE, MAGENTA)
	burstGradient.Rotation = 22
	burstGradient.Parent = burst

	local label = newLabel() :: TextLabel
	label.Name = "Amount"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.TextSize = 68
	label.ZIndex = 2
	label.Parent = popup
	applyTextToken(label, "hero")

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

local function burstGrowDust(pumpkin: BasePart)
	local attachment = pumpkin:FindFirstChild("GrowDustAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		attachment = Instance.new("Attachment")
		attachment.Name = "GrowDustAttachment"
		attachment.Position = Vector3.new(0, -pumpkin.Size.Y * 0.5, 0)
		attachment.Parent = pumpkin
		local dust = Instance.new("ParticleEmitter")
		dust.Name = "Dust"
		dust.Color = ColorSequence.new(YELLOW, ORANGE)
		dust.Drag = 5
		dust.EmissionDirection = Enum.NormalId.Top
		dust.Lifetime = NumberRange.new(0.24, 0.42)
		dust.LightEmission = 0.25
		dust.Rate = 0
		dust.Rotation = NumberRange.new(0, 360)
		dust.RotSpeed = NumberRange.new(-80, 80)
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		})
		dust.Speed = NumberRange.new(4, 8)
		dust.SpreadAngle = Vector2.new(65, 65)
		dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dust.Parent = attachment
	end
	local dust = attachment:FindFirstChild("Dust")
	if dust and dust:IsA("ParticleEmitter") then
		dust:Emit(if player:GetAttribute("ReducedEffects") == true then 3 else 7)
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
	local rewardPlate = popup:FindFirstChild("RewardPlate") :: Frame
	local scale = label:FindFirstChild("PopScale") :: UIScale
	label.Text = "+" .. Format.abbrev(amount)
	rewardPlate.Visible = amount >= 1_000
	if amount >= 1_000 then
		label.TextColor3 = WHITE
	else
		label.TextColor3 = if amount >= 100
			then MAGENTA
			elseif amount >= 25 then ORANGE
			elseif amount >= 5 then YELLOW
			else WHITE
	end
	label.TextTransparency = 0
	local labelStroke = label:FindFirstChild("LabelStroke") :: UIStroke
	labelStroke.Transparency = 0
	playPop(scale, if amount >= 1_000 then "rare" else "reward")
	TweenService:Create(
		popup,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = Vector3.new(0, 5.7, 0) }
	):Play()
	local fade = TweenService:Create(
		label,
		TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4),
		{ TextTransparency = 1 }
	)
	TweenService:Create(
		labelStroke,
		TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4),
		{ Transparency = 1 }
	):Play()
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
	local visualDiameter = pumpkin:GetAttribute("VisualDiameter") :: number?
		or Grow.pumpkinVisualDiameter(newSize, 5)
	local diameter = visualDiameter * Config.PumpkinMeshScale
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
	updateCameraZoom(newSize)
	showMilestone(amount, newSize)
	burstSeeds()
	local character = player.Character
	local pumpkin = if character then character:FindFirstChild("Pumpkin") else nil
	if pumpkin and pumpkin:IsA("BasePart") then
		burstGrowDust(pumpkin)
	end
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

-- VisualDiameter replicates after the pumpkin attaches; recompute the zoom whenever it changes
local function watchPumpkinZoom(character: Model)
	local pumpkin = character:WaitForChild("Pumpkin", 15)
	if not pumpkin then
		return
	end
	lastZoomTarget = nil
	local function refresh()
		updateCameraZoom((player:GetAttribute("Size") :: number?) or 0)
	end
	pumpkin:GetAttributeChangedSignal("VisualDiameter"):Connect(refresh)
	refresh()
end
player.CharacterAdded:Connect(watchPumpkinZoom)
if player.Character then
	task.spawn(watchPumpkinZoom, player.Character)
end
