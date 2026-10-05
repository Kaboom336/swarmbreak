--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Style = require(Shared:WaitForChild("Style"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local petAction = remotes:WaitForChild("PetAction") :: RemoteEvent
local petState = remotes:WaitForChild("PetState") :: RemoteEvent
local hatchReveal = remotes:WaitForChild("HatchReveal") :: RemoteEvent
local followerRoot = workspace:WaitForChild("PetFollowers")

local function paletteColor(role: string): Color3
	local value = Style.Palette[role]
	return Color3.fromRGB(value.r, value.g, value.b)
end

local ORANGE = paletteColor("orange")
local PURPLE = paletteColor("purple")
local LIME = paletteColor("lime")
local CYAN = paletteColor("cyan")
local YELLOW = paletteColor("yellow")
local INK = paletteColor("ink")
local TEAL = INK:Lerp(CYAN, 0.18)
local SHADOW = Color3.fromRGB(31, 38, 92)
local WHITE = paletteColor("white")
local RARITY_COLORS = {
	Common = ORANGE,
	Uncommon = LIME,
	Rare = CYAN,
	Epic = PURPLE,
	Legendary = YELLOW,
}

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

local oldGui = playerGui:FindFirstChild("PumpkinPets")
if oldGui then
	oldGui:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "PumpkinPets"
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- child shadows sit at ZIndex - 1
gui.ResetOnSpawn = false
gui.Parent = playerGui

local buttonSound = Instance.new("Sound")
buttonSound.Name = "ButtonPress"
buttonSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
buttonSound.Volume = 0.24
buttonSound.Parent = gui

local function decorate(object: GuiObject, topColor: Color3, bottomColor: Color3)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = object
	local stroke = Instance.new("UIStroke")
	stroke.Name = "PanelStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = INK
	stroke.Thickness = 3
	stroke.Parent = object
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
		-- A UIGradient tints the text too, so text objects get a flat fill
		object.BackgroundColor3 = topColor:Lerp(bottomColor, 0.4)
	else
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(topColor, bottomColor)
		gradient.Rotation = 90
		gradient.Parent = object
	end
	local highlight = Instance.new("Frame")
	highlight.Name = "TopHighlight"
	highlight.BackgroundColor3 = Color3.new(1, 1, 1)
	highlight.BackgroundTransparency = 0.55
	highlight.BorderSizePixel = 0
	highlight.Position = UDim2.fromOffset(12, 5)
	highlight.Size = UDim2.new(1, -24, 0, 4)
	highlight.ZIndex = object.ZIndex + 1
	highlight.Parent = object
	local highlightCorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(1, 0)
	highlightCorner.Parent = highlight
end

local function addInnerShadow(object: GuiObject)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = SHADOW
	shadow.BorderSizePixel = 0
	shadow.Position = UDim2.fromOffset(0, 7)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.ZIndex = object.ZIndex - 1
	shadow.Parent = object
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = shadow
end

local function bindButtonFeedback(button: TextButton)
	button.AutoButtonColor = false
	local scale = Instance.new("UIScale")
	scale.Name = "ButtonFeedbackScale"
	scale.Parent = button
	local clip = Instance.new("Frame")
	clip.Name = "ShineClip"
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Size = UDim2.fromScale(1, 1)
	clip.ZIndex = button.ZIndex + 2
	clip.Parent = button
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 0.55
	shine.BorderSizePixel = 0
	shine.Position = UDim2.new(-0.25, 0, 0.5, 0)
	shine.Rotation = 18
	shine.Size = UDim2.new(0.22, 0, 1.8, 0)
	shine.ZIndex = clip.ZIndex
	shine.Parent = clip
	local pressed = false
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
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			pressed = true
			button.Position += UDim2.fromOffset(0, Style.Button.pressPixels)
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
			button.Position -= UDim2.fromOffset(0, Style.Button.pressPixels)
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

local function playPop(scale: UIScale, tierName: string)
	local tier = Style.popTier(tierName, player:GetAttribute("ReducedMotion") == true)
	scale.Scale = tier.startScale
	local contact = TweenService:Create(
		scale,
		TweenInfo.new(tier.contactSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = tier.overshootScale }
	)
	contact:Play()
	contact.Completed:Wait()
	local settle = TweenService:Create(
		scale,
		TweenInfo.new(tier.settleSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	settle:Play()
	settle.Completed:Wait()
end

local panelShadow = Instance.new("Frame")
panelShadow.Name = "InventoryShadow"
panelShadow.AnchorPoint = Vector2.new(0.5, 0.5)
panelShadow.BackgroundColor3 = SHADOW
panelShadow.BorderSizePixel = 0
panelShadow.Position = UDim2.new(0.5, 0, 0.5, 8)
panelShadow.Size = UDim2.new(0.82, 0, 0.76, 0)
panelShadow.Visible = false
panelShadow.ZIndex = 10
panelShadow.Parent = gui
local panelShadowCorner = Instance.new("UICorner")
panelShadowCorner.CornerRadius = UDim.new(0, 12)
panelShadowCorner.Parent = panelShadow

local panel = Instance.new("Frame")
panel.Name = "Inventory"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = PURPLE
panel.BorderSizePixel = 0
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.82, 0, 0.76, 0)
panel.Visible = false
panel.ZIndex = 11
panel.Parent = gui
decorate(panel, PURPLE, PURPLE:Lerp(INK, 0.55))

local title = newLabel() :: TextLabel
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.new(1, -150, 0, 48)
title.Text = "PETS  0/50"
title.TextColor3 = WHITE
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 13
title.Parent = panel

local close = newLabel("TextButton") :: TextButton
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0)
close.BackgroundColor3 = ORANGE
close.BorderSizePixel = 0
close.Font = Enum.Font.GothamBlack
close.Position = UDim2.new(1, -12, 0, 10)
close.Size = UDim2.fromOffset(56, 56)
close.Text = "×"
close.TextColor3 = WHITE
close.TextSize = 34
close.ZIndex = 13
close.Parent = panel
addInnerShadow(close)
decorate(close, ORANGE, ORANGE:Lerp(INK, 0.35))
bindButtonFeedback(close)

local listShadow = Instance.new("Frame")
listShadow.Name = "PetListShadow"
listShadow.BackgroundColor3 = SHADOW
listShadow.BorderSizePixel = 0
listShadow.Position = UDim2.fromOffset(16, 83)
listShadow.Size = UDim2.new(1, -32, 1, -154)
listShadow.ZIndex = 11
listShadow.Parent = panel
local listShadowCorner = Instance.new("UICorner")
listShadowCorner.CornerRadius = UDim.new(0, 12)
listShadowCorner.Parent = listShadow

local list = Instance.new("ScrollingFrame")
list.Name = "PetList"
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.BackgroundColor3 = TEAL
list.BackgroundTransparency = 0.1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()
list.Position = UDim2.fromOffset(16, 76)
list.ScrollBarThickness = 8
list.Size = UDim2.new(1, -32, 1, -154)
list.ZIndex = 12
list.Parent = panel
decorate(list, TEAL:Lerp(CYAN, 0.08), TEAL)
-- The grid layout would turn the depth-stack highlight into a grey pet cell
local listHighlight = list:FindFirstChild("TopHighlight")
if listHighlight then
	listHighlight:Destroy()
end
local emptyLabel = newLabel() :: TextLabel
emptyLabel.Name = "EmptyPets"
emptyLabel.BackgroundTransparency = 1
emptyLabel.Font = Enum.Font.GothamBlack
emptyLabel.Position = list.Position
emptyLabel.Size = list.Size
emptyLabel.Text = "No pets yet - hatch an egg!"
emptyLabel.TextColor3 = Color3.new(1, 1, 1)
emptyLabel.TextSize = 22
emptyLabel.TextStrokeColor3 = TEAL
emptyLabel.TextStrokeTransparency = 0.2
emptyLabel.TextWrapped = true
emptyLabel.ZIndex = list.ZIndex + 2
emptyLabel.Parent = panel
local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.CellSize = UDim2.fromOffset(150, 116)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list
local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 10)
listPadding.PaddingBottom = UDim.new(0, 10)
listPadding.Parent = list

local equipBest = newLabel("TextButton") :: TextButton
equipBest.Name = "EquipBest"
equipBest.AnchorPoint = Vector2.new(0.5, 1)
equipBest.BackgroundColor3 = LIME
equipBest.BorderSizePixel = 0
equipBest.Font = Enum.Font.GothamBlack
equipBest.Position = UDim2.new(0.34, 0, 1, -12)
equipBest.Size = UDim2.fromOffset(180, 58)
equipBest.Text = "EQUIP BEST"
equipBest.TextColor3 = Color3.new(1, 1, 1)
equipBest.TextStrokeColor3 = TEAL
equipBest.TextStrokeTransparency = 0.2
equipBest.TextSize = 22
equipBest.ZIndex = 13
equipBest.Parent = panel
addInnerShadow(equipBest)
decorate(equipBest, LIME, LIME:Lerp(INK, 0.38))
bindButtonFeedback(equipBest)

local indexButton = newLabel("TextButton") :: TextButton
indexButton.Name = "Index"
indexButton.AnchorPoint = Vector2.new(0.5, 1)
indexButton.BackgroundColor3 = ORANGE
indexButton.BorderSizePixel = 0
indexButton.Font = Enum.Font.GothamBlack
indexButton.Position = UDim2.new(0.7, 0, 1, -12)
indexButton.Size = UDim2.fromOffset(150, 58)
indexButton.Text = "PET INDEX"
indexButton.TextColor3 = WHITE
indexButton.TextStrokeColor3 = TEAL
indexButton.TextStrokeTransparency = 0.2
indexButton.TextSize = 19
indexButton.ZIndex = 13
indexButton.Parent = panel
addInnerShadow(indexButton)
decorate(indexButton, ORANGE, ORANGE:Lerp(INK, 0.35))
bindButtonFeedback(indexButton)

local toast = newLabel() :: TextLabel
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.BackgroundColor3 = ORANGE
toast.BackgroundTransparency = 0.08
toast.Font = Enum.Font.GothamBlack
toast.Position = UDim2.new(0.5, 0, 0, 105)
toast.Size = UDim2.fromOffset(360, 58)
toast.TextColor3 = WHITE
toast.TextSize = 20
toast.Visible = false
toast.ZIndex = 100
toast.Parent = gui
addInnerShadow(toast)
decorate(toast, ORANGE, ORANGE:Lerp(INK, 0.35))

local function applyToastLayout()
	local layout = HudLayout.compute(gui.AbsoluteSize.X, gui.AbsoluteSize.Y)
	local width = math.min(360, gui.AbsoluteSize.X - 16)
	toast.Position =
		UDim2.fromOffset(math.floor((gui.AbsoluteSize.X - width) / 2), layout.distanceMeter.y)
	toast.Size = UDim2.fromOffset(width, if layout.mobile then 48 else 58)
end
toast.AnchorPoint = Vector2.zero
applyToastLayout()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyToastLayout)

local reveal = Instance.new("Frame")
reveal.Name = "HatchReveal"
reveal.BackgroundColor3 = INK
reveal.BackgroundTransparency = 0.18
reveal.BorderSizePixel = 0
reveal.Size = UDim2.fromScale(1, 1)
reveal.Visible = false
reveal.ZIndex = 50
reveal.Parent = gui
local eggLabel = newLabel() :: TextLabel
eggLabel.AnchorPoint = Vector2.new(0.5, 0.5)
eggLabel.BackgroundTransparency = 1
eggLabel.Font = Enum.Font.GothamBlack
eggLabel.Position = UDim2.fromScale(0.5, 0.46)
eggLabel.Size = UDim2.fromOffset(440, 250)
eggLabel.Text = "🥚"
eggLabel.TextColor3 = ORANGE
eggLabel.TextScaled = true
eggLabel.TextStrokeColor3 = TEAL
eggLabel.TextStrokeTransparency = 0
eggLabel.ZIndex = 51
eggLabel.Parent = reveal
local revealScale = Instance.new("UIScale")
revealScale.Parent = eggLabel
local flash = Instance.new("Frame")
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Size = UDim2.fromScale(1, 1)
flash.ZIndex = 52
flash.Parent = reveal

local selectedId: string? = nil
local lastState: any = nil
local showingIndex = false

local function showToast(message: string)
	toast.Text = message
	toast.Visible = true
	local generation = (toast:GetAttribute("Generation") or 0) + 1
	toast:SetAttribute("Generation", generation)
	task.delay(2.2, function()
		if toast:GetAttribute("Generation") == generation then
			toast.Visible = false
		end
	end)
end

local function renderState(state: any)
	lastState = state
	showingIndex = false
	indexButton.Text = "PET INDEX"
	local equipped = {}
	for _, petId in state.equippedPetIds or {} do
		equipped[petId] = true
	end
	emptyLabel.Visible = #(state.pets or {}) == 0
	for _, child in list:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	title.Text = string.format(
		"PETS  %d/%d   •   %d EQUIPPED",
		#(state.pets or {}),
		state.capacity or 50,
		#(state.equippedPetIds or {})
	)
	for index, pet in state.pets or {} do
		local card = newLabel("TextButton") :: TextButton
		card.Name = pet.id
		card.AutoButtonColor = false
		card.BackgroundColor3 = RARITY_COLORS[pet.rarity] or ORANGE
		card.BorderSizePixel = 0
		card.Font = Enum.Font.GothamBold
		card.LayoutOrder = index
		card.Text = string.format(
			"%s%s\n%s\n×%.1f",
			if equipped[pet.id] then "✓ " else "",
			pet.name,
			pet.rarity,
			pet.multiplier
		)
		card.TextColor3 = WHITE
		card.TextSize = 16
		card.TextStrokeColor3 = TEAL
		card.TextStrokeTransparency = 0
		card.ZIndex = 13
		card.Parent = list
		addInnerShadow(card)
		decorate(card, card.BackgroundColor3, card.BackgroundColor3:Lerp(TEAL, 0.4))
		bindButtonFeedback(card)
		card.Activated:Connect(function()
			if selectedId == pet.id then
				petAction:FireServer("Delete", pet.id)
				selectedId = nil
			else
				selectedId = pet.id
				showToast("Tap " .. pet.name .. " again to delete")
			end
		end)
	end
	if state.message then
		showToast(state.message)
	end
end

local function renderIndex()
	if not lastState then
		return
	end
	showingIndex = true
	indexButton.Text = "MY PETS"
	emptyLabel.Visible = false
	for _, child in list:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	local discovered = lastState.discoveredPets or {}
	local found = 0
	local total = 0
	for _, egg in Config.Eggs do
		for rarity, pet in egg.Pets do
			total += 1
			local known = discovered[pet.Name] == true
			if known then
				found += 1
			end
			local card = newLabel("TextButton") :: TextButton
			card.Name = "Index_" .. pet.Name
			card.AutoButtonColor = false
			card.BackgroundColor3 = if known then RARITY_COLORS[rarity] or ORANGE else INK
			card.BorderSizePixel = 0
			card.Font = Enum.Font.GothamBold
			card.Text = string.format(
				"%s\n%s\n%s",
				egg.DisplayName,
				if known then pet.Name else "SILHOUETTE",
				rarity
			)
			card.TextColor3 = WHITE
			card.TextSize = 14
			card.TextStrokeColor3 = TEAL
			card.TextStrokeTransparency = 0
			card.ZIndex = 13
			card.Parent = list
			addInnerShadow(card)
			decorate(card, card.BackgroundColor3, card.BackgroundColor3:Lerp(TEAL, 0.35))
			bindButtonFeedback(card)
		end
	end
	title.Text = string.format("PET INDEX  %d/%d  -  +10%% SIZE PER EGG", found, total)
end

player:GetAttributeChangedSignal("PetsPanelRequest"):Connect(function()
	panel.Visible = not panel.Visible
	panelShadow.Visible = panel.Visible
	if panel.Visible and lastState then
		renderState(lastState)
	end
end)
player:GetAttributeChangedSignal("Rolling"):Connect(function()
	if player:GetAttribute("Rolling") == true then
		panel.Visible = false
		panelShadow.Visible = false
	end
end)
close.Activated:Connect(function()
	panel.Visible = false
	panelShadow.Visible = false
end)
equipBest.Activated:Connect(function()
	petAction:FireServer("EquipBest")
end)
indexButton.Activated:Connect(function()
	if showingIndex then
		renderState(lastState)
	else
		renderIndex()
	end
end)
petState.OnClientEvent:Connect(renderState)
petAction:FireServer("Sync")
player:GetAttributeChangedSignal("StarterPackPurchased"):Connect(function()
	if player:GetAttribute("StarterPackPurchased") == true then
		petAction:FireServer("Sync")
	end
end)

local revealQueue = {}
local revealing = false
local function playRevealQueue()
	if revealing then
		return
	end
	revealing = true
	while #revealQueue > 0 do
		local item = table.remove(revealQueue, 1)
		local pet = item.pet
		reveal.Visible = true
		eggLabel.Text = "🥚\n" .. item.eggName
		eggLabel.TextColor3 = ORANGE
		revealScale.Scale = 0.82
		for direction = -1, 1, 2 do
			local tween =
				TweenService:Create(eggLabel, TweenInfo.new(0.12), { Rotation = direction * 12 })
			tween:Play()
			tween.Completed:Wait()
		end
		eggLabel.Text = "💥 CRACK!"
		TweenService
			:Create(revealScale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1.25 })
			:Play()
		flash.BackgroundTransparency = 0
		TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		task.wait(0.22)
		eggLabel.Rotation = 0
		eggLabel.TextColor3 = RARITY_COLORS[pet.rarity] or WHITE
		eggLabel.Text =
			string.format("✨ %s ✨\n%s  •  ×%.1f", pet.name, pet.rarity, pet.multiplier)
		playPop(
			revealScale,
			if pet.rarity == "Rare"
					or pet.rarity == "Epic"
					or pet.rarity == "Legendary"
				then "rare"
				else "reward"
		)
		task.wait(
			if pet.rarity == "Rare"
					or pet.rarity == "Epic"
					or pet.rarity == "Legendary"
				then 1.35
				else 0.75
		)
		reveal.Visible = false
	end
	revealing = false
end

hatchReveal.OnClientEvent:Connect(function(eggName: string, pets: { any })
	for _, pet in pets do
		table.insert(revealQueue, { eggName = eggName, pet = pet })
	end
	task.spawn(playRevealQueue)
end)

RunService.RenderStepped:Connect(function(deltaTime)
	local alpha = 1 - math.exp(-12 * deltaTime)
	local now = os.clock()
	for _, owner in Players:GetPlayers() do
		local character = owner.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local folder = followerRoot:FindFirstChild(tostring(owner.UserId))
		if root and root:IsA("BasePart") and folder then
			local rideTransparency = if owner:GetAttribute("Rolling") == true then 1 else 0
			for _, follower in folder:GetChildren() do
				local slot = (follower:GetAttribute("Slot") :: number?) or 1
				local side = if slot % 2 == 0 then 1 else -1
				local row = math.ceil(slot / 2)
				local bob = math.sin(now * 3 + slot) * 0.3
				local target = root.CFrame * CFrame.new(side * (2 + row), 1.5 + bob, 2.5 + row)
				if follower:IsA("Model") then
					follower:PivotTo(follower:GetPivot():Lerp(target, alpha))
				elseif follower:IsA("BasePart") then
					follower.CFrame = follower.CFrame:Lerp(target, alpha)
				end
				if follower:IsA("BasePart") then
					follower.LocalTransparencyModifier += (rideTransparency - follower.LocalTransparencyModifier) * alpha
				else
					for _, descendant in follower:GetDescendants() do
						if descendant:IsA("BasePart") then
							descendant.LocalTransparencyModifier += (rideTransparency - descendant.LocalTransparencyModifier) * alpha
						end
					end
				end
			end
		end
	end
end)

-- Egg prompts are shared server objects; show this player's free hatches by editing the local copy
local function refreshHatchPrompt(prompt: ProximityPrompt)
	local eggName = prompt:GetAttribute("EggName")
	local cost = prompt:GetAttribute("Cost")
	if type(eggName) ~= "string" or type(cost) ~= "number" then
		return
	end
	local free = (eggName == "CandyEgg" and player:GetAttribute("FreeCandyHatch") == true)
		or (
			eggName == "SpookyEgg"
			and ((player:GetAttribute("FreeSpookyHatches") :: number?) or 0) > 0
		)
	prompt.ActionText = if free then "Hatch - FREE!" else string.format("Hatch - %d Wins", cost)
end

local function refreshHatchPrompts()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "HatchPrompt" then
			refreshHatchPrompt(descendant)
		end
	end
end

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") and descendant.Name == "HatchPrompt" then
		task.defer(refreshHatchPrompt, descendant)
	end
end)
player:GetAttributeChangedSignal("FreeCandyHatch"):Connect(refreshHatchPrompts)
player:GetAttributeChangedSignal("FreeSpookyHatches"):Connect(refreshHatchPrompts)
refreshHatchPrompts()
