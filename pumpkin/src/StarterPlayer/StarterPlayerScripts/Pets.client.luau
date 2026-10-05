--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local petAction = remotes:WaitForChild("PetAction") :: RemoteEvent
local petState = remotes:WaitForChild("PetState") :: RemoteEvent
local hatchReveal = remotes:WaitForChild("HatchReveal") :: RemoteEvent

local ORANGE = Color3.fromRGB(255, 116, 25)
local PURPLE = Color3.fromRGB(151, 64, 255)
local LIME = Color3.fromRGB(167, 255, 61)
local TEAL = Color3.fromRGB(13, 53, 63)
local SHADOW = Color3.fromRGB(21, 40, 105)
local WHITE = Color3.fromRGB(255, 250, 218)
local RARITY_COLORS = {
	Common = Color3.fromRGB(255, 151, 55),
	Uncommon = Color3.fromRGB(153, 255, 74),
	Rare = Color3.fromRGB(69, 176, 255),
	Epic = Color3.fromRGB(182, 82, 255),
	Legendary = Color3.fromRGB(255, 226, 64),
}

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

local function decorate(object: GuiObject, topColor: Color3, bottomColor: Color3)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = object
	local stroke = Instance.new("UIStroke")
	stroke.Color = TEAL
	stroke.Thickness = 3
	stroke.Parent = object
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(topColor, bottomColor)
	gradient.Rotation = 90
	gradient.Parent = object
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
decorate(panel, PURPLE, Color3.fromRGB(63, 34, 130))

local title = Instance.new("TextLabel")
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

local close = Instance.new("TextButton")
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
decorate(close, ORANGE, Color3.fromRGB(200, 54, 27))

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
decorate(list, Color3.fromRGB(25, 74, 88), TEAL)
-- The grid layout would turn the depth-stack highlight into a grey pet cell
local listHighlight = list:FindFirstChild("TopHighlight")
if listHighlight then
	listHighlight:Destroy()
end
local emptyLabel = Instance.new("TextLabel")
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

local equipBest = Instance.new("TextButton")
equipBest.Name = "EquipBest"
equipBest.AnchorPoint = Vector2.new(0.5, 1)
equipBest.BackgroundColor3 = LIME
equipBest.BorderSizePixel = 0
equipBest.Font = Enum.Font.GothamBlack
equipBest.Position = UDim2.new(0.5, 0, 1, -12)
equipBest.Size = UDim2.fromOffset(220, 58)
equipBest.Text = "EQUIP BEST"
equipBest.TextColor3 = Color3.new(1, 1, 1)
equipBest.TextStrokeColor3 = TEAL
equipBest.TextStrokeTransparency = 0.2
equipBest.TextSize = 22
equipBest.ZIndex = 13
equipBest.Parent = panel
addInnerShadow(equipBest)
decorate(equipBest, LIME, Color3.fromRGB(83, 190, 50))

local toast = Instance.new("TextLabel")
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
toast.ZIndex = 40
toast.Parent = gui
addInnerShadow(toast)
decorate(toast, ORANGE, Color3.fromRGB(195, 52, 27))

local reveal = Instance.new("Frame")
reveal.Name = "HatchReveal"
reveal.BackgroundColor3 = Color3.fromRGB(4, 25, 31)
reveal.BackgroundTransparency = 0.18
reveal.BorderSizePixel = 0
reveal.Size = UDim2.fromScale(1, 1)
reveal.Visible = false
reveal.ZIndex = 50
reveal.Parent = gui
local eggLabel = Instance.new("TextLabel")
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
		local card = Instance.new("TextButton")
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

player:GetAttributeChangedSignal("PetsPanelRequest"):Connect(function()
	panel.Visible = not panel.Visible
	panelShadow.Visible = panel.Visible
	if panel.Visible and lastState then
		renderState(lastState)
	end
end)
close.Activated:Connect(function()
	panel.Visible = false
	panelShadow.Visible = false
end)
equipBest.Activated:Connect(function()
	petAction:FireServer("EquipBest")
end)
petState.OnClientEvent:Connect(renderState)
petAction:FireServer("Sync")

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
		revealScale.Scale = 0.55
		local pop = TweenService:Create(
			revealScale,
			TweenInfo.new(0.28, Enum.EasingStyle.Back),
			{ Scale = 1 }
		)
		pop:Play()
		pop.Completed:Wait()
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
