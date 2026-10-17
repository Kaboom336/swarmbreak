local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Style = require(RS:WaitForChild("UIStyle"))
local config = require(RS:WaitForChild("TreasureCore").Config)
local UI = require(RS.TreasureCore:WaitForChild("UIPresentation"))
-- Cave has no economy remote today; optional event wiring must not block its UI.
local event = RS:FindFirstChild("TreasureCoreEvent")
local feel = require(RS.TreasureCore.Feel).new()
script.Destroying:Connect(function()
	feel:Destroy()
end)
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.Parent =
	"TreasureCoreHud", false, 20, player:WaitForChild("PlayerGui")
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
feel.trove:Add(gui)
local function ownPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	local owner, slot = prompt:GetAttribute("CoreOwner"), prompt:GetAttribute("CoreCollectSlot")
	if owner then
		prompt.Enabled = owner == player.UserId
	elseif slot then
		prompt.Enabled = slot == player:GetAttribute("GreyboxPen")
	end
end
workspace.DescendantAdded:Connect(function(prompt)
	if prompt:IsA("ProximityPrompt") then
		ownPrompt(prompt)
		prompt:GetAttributeChangedSignal("CoreOwner"):Connect(function()
			ownPrompt(prompt)
		end)
		prompt:GetAttributeChangedSignal("CoreCollectSlot"):Connect(function()
			ownPrompt(prompt)
		end)
	end
end)
for _, prompt in workspace:GetDescendants() do
	ownPrompt(prompt)
end
player:GetAttributeChangedSignal("GreyboxPen"):Connect(function()
	for _, prompt in workspace:GetDescendants() do
		ownPrompt(prompt)
	end
end)
local function text(parent, name, position, size, value)
	local t = Instance.new("TextLabel")
	t.Name, t.Position, t.Size, t.Text = name, position, size, value
	t.BackgroundColor3, t.BackgroundTransparency = Color3.fromRGB(23, 32, 46), 0.12
	Style.panel(t)
	t.Parent = parent
	return t
end
local counter = text(gui, "Coins", UDim2.fromOffset(16, 104), UDim2.fromOffset(210, 72), "Coins 0\n0 Coins/s")
counter.BackgroundColor3 = Style.Colors.Gold
counter.RichText = true
Style.icon(counter, "coin")
local status = text(gui, "SaveStatus", UDim2.fromOffset(16, 180), UDim2.fromOffset(210, 26), "")
status.TextSize = 12
local function debugStatus()
	local control = RS:FindFirstChild("StudioPassControl")
	status.Visible = RunService:IsStudio() and control ~= nil and control:GetAttribute("ShowDebug") == true
end
debugStatus()
task.spawn(function()
	local control = RS:WaitForChild("StudioPassControl", 20)
	if control then
		control:GetAttributeChangedSignal("ShowDebug"):Connect(debugStatus)
		debugStatus()
	end
end)
local function button(name, pos, size, value)
	local b = Instance.new("TextButton")
	b.Name, b.Position, b.Size, b.Text = name, pos, size, value
	b.BackgroundColor3, b.TextColor3 = Color3.fromRGB(35, 110, 130), Color3.new(1, 1, 1)
	b.Parent = gui
	Style.panel(b, Style.Colors.Cyan, 22)
	return b
end
local indexButton = button("Index", UDim2.new(1, -116, 0, 104), UDim2.fromOffset(100, 48), "Index")
indexButton.Size, indexButton.Position = UDim2.fromOffset(132, 48), UDim2.new(1, -148, 0, 104)
indexButton.Text = ""
local indexPadding = indexButton:FindFirstChild("PanelPadding")
indexPadding.PaddingLeft, indexPadding.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
local indexRow = Instance.new("Frame")
indexRow.Name, indexRow.Size, indexRow.BackgroundTransparency, indexRow.Parent =
	"Content", UDim2.fromScale(1, 1), 1, indexButton
local indexLayout = Instance.new("UIListLayout")
indexLayout.FillDirection, indexLayout.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center
indexLayout.HorizontalAlignment, indexLayout.SortOrder = Enum.HorizontalAlignment.Center, Enum.SortOrder.LayoutOrder
indexLayout.Padding, indexLayout.Parent = UDim.new(0, 8), indexRow
-- Reserve the rotated gem's full 34-pixel visual footprint.
local indexIconSlot = Instance.new("Frame")
indexIconSlot.Size, indexIconSlot.BackgroundTransparency, indexIconSlot.LayoutOrder, indexIconSlot.Parent =
	UDim2.fromOffset(34, 34), 1, 1, indexRow
local indexIcon = Style.icon(indexIconSlot, "gem", Style.Colors.Cream)
indexIcon.Position, indexIcon.AnchorPoint = UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
local indexCaption = Instance.new("TextLabel")
indexCaption.Name, indexCaption.Text, indexCaption.Size = "Caption", "Index", UDim2.new(0, 68, 1, 0)
indexCaption.BackgroundTransparency, indexCaption.LayoutOrder, indexCaption.Parent = 1, 2, indexRow
Style.lettering(indexCaption, 22)
local openTap = button("OpenTap", UDim2.new(1, -166, 0.5, -24), UDim2.fromOffset(150, 48), "Open acorn")
openTap.Visible = false
openTap.Activated:Connect(function()
	if event then
		event:FireServer("OpenTap")
	end
end)
local nextOpenCheck = 0
RunService.RenderStepped:Connect(function()
	if os.clock() < nextOpenCheck then
		return
	end
	nextOpenCheck = os.clock() + 0.2
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild("GREYBOX")
	local visible = false
	if UserInputService.TouchEnabled and root and world and player:GetAttribute("CoreOpenReady") then
		for _, item in world:GetChildren() do
			if
				item:IsA("BasePart")
				and item:GetAttribute("CoreOwner") == player.UserId
				and item:GetAttribute("CoreState") == "Acorn"
				and item:GetAttribute("CorePlaced")
				and (item.Position - root.Position).Magnitude <= 9
			then
				visible = true
				break
			end
		end
	end
	openTap.Visible = visible
end)
local index = text(gui, "IndexPanel", UDim2.new(0.5, -150, 0.5, -180), UDim2.fromOffset(300, 360), "")
index.Visible = false
index.TextSize = 20
local close = Instance.new("TextButton")
close.Text, close.Size, close.Position, close.Parent =
	"Close", UDim2.fromOffset(90, 48), UDim2.new(1, -98, 1, -56), index
Style.panel(close, Style.Colors.Cyan, 20)
close.Activated:Connect(function()
	index.Visible = false
	if game:GetService("GuiService").SelectedObject == close then
		game:GetService("GuiService").SelectedObject = indexButton
	end
end)
local indexBody = Instance.new("ScrollingFrame")
indexBody.Name, indexBody.Position, indexBody.Size = "Entries", UDim2.fromOffset(0, 38), UDim2.new(1, 0, 1, -100)
indexBody.BackgroundTransparency, indexBody.BorderSizePixel, indexBody.ScrollBarThickness = 1, 0, 4
indexBody.CanvasSize, indexBody.Selectable, indexBody.Parent = UDim2.fromOffset(0, #config.Rarities * 62), true, index
indexBody.NextSelectionDown, indexBody.NextSelectionUp = close, close
close.NextSelectionUp, close.NextSelectionDown = indexBody, indexBody
local function indexText()
	local found = {}
	for name in (player:GetAttribute("PetDiscoveries") or ""):gmatch("[^|]+") do
		found[name] = true
	end
	for i, rarity in config.Rarities do
		local caption = indexBody:FindFirstChild("Entry" .. i)
		if caption then
			caption.Text = found[rarity.pet] and (rarity.pet .. "\n" .. rarity.name) or "?\nUndiscovered"
			caption.TextColor3 = found[rarity.pet] and Style.rarity(rarity) or Style.Colors.Cream
		end
		local view = indexBody:FindFirstChild("Silhouette" .. i)
		if view then
			for _, part in view:GetDescendants() do
				if part:IsA("BasePart") then
					if not part:GetAttribute("OriginalColor") then
						part:SetAttribute("OriginalColor", part.Color)
					end
					part.Color = found[rarity.pet] and part:GetAttribute("OriginalColor") or Color3.fromRGB(12, 16, 24)
				end
			end
		end
	end
end
index.Text = ""
text(index, "Title", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 36), "PET INDEX")
task.spawn(function()
	local preview = RS:WaitForChild("CorePetPreview", 20)
	for i, rarity in config.Rarities do
		local caption = text(
			indexBody,
			"Entry" .. i,
			UDim2.fromOffset(66, (i - 1) * 62),
			UDim2.new(1, -74, 0, 56),
			"?\nUndiscovered"
		)
		caption.TextSize = 16
		local view = Instance.new("ViewportFrame")
		view.Name, view.Position, view.Size =
			"Silhouette" .. i, UDim2.fromOffset(0, (i - 1) * 62), UDim2.fromOffset(60, 56)
		view.BackgroundTransparency, view.Parent = 1, indexBody
		local camera = Instance.new("Camera")
		camera.CFrame, camera.Parent = CFrame.lookAt(Vector3.new(5, 4, 7), Vector3.new(0, 1.5, 0)), view
		view.CurrentCamera = camera
		if preview then
			local ok, model = pcall(function()
				return preview:Invoke(rarity.model)
			end)
			if ok then
				model:PivotTo(CFrame.identity)
				model.Parent = view
			end
		end
	end
	indexText()
end)
indexButton.Activated:Connect(function()
	indexText()
	index.Visible = not index.Visible
	if UserInputService.GamepadEnabled then
		game:GetService("GuiService").SelectedObject = index.Visible and indexBody or indexButton
	end
end)
local card = text(gui, "Reveal", UDim2.new(0.5, -150, 0.62, 0), UDim2.fromOffset(300, 140), "")
card.Visible = false
local skip = Instance.new("TextButton")
skip.Selectable = true
skip.Text, skip.Size, skip.Position, skip.Parent =
	"Tap to skip", UDim2.fromOffset(130, 48), UDim2.new(0.5, -65, 1, -48), card
Style.panel(skip, Style.Colors.Cyan, 18)
local revealTitle = text(card, "RewardTitle", UDim2.fromOffset(0, 12), UDim2.new(1, 0, 0, 40), "")
revealTitle.BackgroundTransparency = 1
for _, name in { "PanelEdge", "PanelShadow", "PanelGradient" } do
	revealTitle[name]:Destroy()
end
local revealRarity = Instance.new("TextLabel")
revealRarity.Name, revealRarity.BackgroundTransparency = "Rarity", 1
revealRarity.Position, revealRarity.Size, revealRarity.Parent = UDim2.fromOffset(0, 56), UDim2.new(1, 0, 0, 36), card
Style.lettering(revealRarity, 18)
local sparkles = {}
for i = 1, 6 do
	local star = Instance.new("TextLabel")
	star.Name, star.Text, star.BackgroundTransparency = "Sparkle" .. i, "✦", 1
	star.Size, star.Position, star.Parent =
		UDim2.fromOffset(20, 20), UDim2.new((i % 2 == 0) and 0.9 or 0.02, 0, 0, 6 + math.floor((i - 1) / 2) * 32), card
	Style.lettering(star, 20)
	table.insert(sparkles, star)
end
local revealFocus
local function hideReveal()
	card.Visible = false
	local selection = game:GetService("GuiService")
	if selection.SelectedObject == skip then
		selection.SelectedObject = revealFocus and revealFocus.Parent and revealFocus or nil
	end
end
skip.Activated:Connect(hideReveal)
local revealGeneration = 0
local function onEvent(kind, a, b, c)
	if kind == "Reveal" then
		revealGeneration += 1
		local generation = revealGeneration
		revealTitle.Text = tostring(a)
		revealRarity.Text = tostring(b) .. "  ·  +" .. tostring(c) .. " Coins/s"
		for _, rarity in config.Rarities do
			if rarity.name == b then
				revealTitle.TextColor3 = Style.rarity(rarity)
				card.BackgroundColor3 = Style.rarity(rarity):Lerp(Style.Colors.Ink, 0.45)
				revealRarity.TextColor3 = Style.rarity(rarity)
				for _, star in sparkles do
					star.TextColor3 = Style.rarity(rarity)
				end
			end
		end
		card.Visible = true
		if UserInputService.GamepadEnabled then
			local selection = game:GetService("GuiService")
			if selection.SelectedObject ~= skip then
				revealFocus = selection.SelectedObject
			end
			selection.SelectedObject = skip
		end
		feel:pop(card)
		task.delay(config.RevealSeconds, function()
			if generation == revealGeneration then
				hideReveal()
			end
		end)
	end
end
local boundEvent
local function bindEvent(node)
	if node.Name ~= "TreasureCoreEvent" or not node:IsA("RemoteEvent") or boundEvent == node then
		return
	end
	if boundEvent then
		return
	end
	event, boundEvent = node, node
	feel.trove:Connect(node.OnClientEvent, onEvent)
end
if event then
	bindEvent(event)
end
feel.trove:Connect(RS.ChildAdded, bindEvent)
local activePops, pendingCoins = 0, 0
local flights = {}
local pulse = Instance.new("UIScale")
pulse.Name, pulse.Parent = "CoinArrival", counter
local pulseTween
local function bounce()
	if pulseTween then
		pulseTween:Cancel()
		pulseTween:Destroy()
	end
	pulse.Scale = player:GetAttribute("ReducedMotion") and 1 or 1.08
	pulseTween = TweenService:Create(pulse, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 })
	pulseTween:Play()
end
local function coinPop(amount)
	if activePops >= 6 then
		pendingCoins += amount
		return
	end
	activePops += 1
	local pop = text(gui, "CoinPop", UDim2.new(0.5, 0, 0, 210), UDim2.fromOffset(112, 48), "+" .. tostring(amount))
	pop.AnchorPoint, pop.TextColor3 = Vector2.new(0.5, 0.5), Style.Colors.Gold
	Style.icon(pop, "coin")
	pop.PanelPadding.PaddingLeft = UDim.new(0, 36)
	pop.StyleIcon.Position = UDim2.new(0, -28, 0.5, 0)
	local target = counter.AbsolutePosition - gui.AbsolutePosition + counter.AbsoluteSize / 2
	local reduced = player:GetAttribute("ReducedMotion") == true
	if reduced then
		pop.Position = UDim2.fromOffset(target.X, target.Y + 60)
	end
	local flight = TweenService:Create(
		pop,
		TweenInfo.new(reduced and 0.5 or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		reduced and { TextTransparency = 0.3 } or { Position = UDim2.fromOffset(target.X, target.Y) }
	)
	flight:Play()
	flights[flight] = pop
	flight.Completed:Once(function()
		flights[flight] = nil
		flight:Destroy()
		pop:Destroy()
		activePops -= 1
		if not gui.Parent then
			return
		end
		bounce()
		if pendingCoins > 0 then
			local amountPending = pendingCoins
			pendingCoins = 0
			coinPop(amountPending)
		end
	end)
end
script.Destroying:Connect(function()
	for flight, pop in flights do
		flight:Cancel()
		flight:Destroy()
		pop:Destroy()
	end
	if pulseTween then
		pulseTween:Cancel()
		pulseTween:Destroy()
	end
end)
local previousCoins = player:GetAttribute("Coins")
feel.trove:Connect(player:GetAttributeChangedSignal("Coins"), function()
	local current = player:GetAttribute("Coins")
	local amount = UI.gain(previousCoins, current)
	previousCoins = current
	if amount > 0 then
		coinPop(amount)
	end
end)
local function update()
	counter.Visible = type(player:GetAttribute("Coins")) == "number"
	feel:counter(counter, player:GetAttribute("Coins") or 0, function(value)
		counter.Text = '<font size="24">Coins '
			.. tostring(math.floor(value + 0.5))
			.. '</font>\n<font size="14">'
			.. tostring(player:GetAttribute("CoinsPerSecond") or 0)
			.. " Coins/s</font>"
	end)
	status.Text = (player:GetAttribute("CoreSaveStatus") or "Loading")
		.. " / plot "
		.. tostring(player:GetAttribute("PlotCoins") or 0)
	indexText()
end
for _, attribute in { "Coins", "CoinsPerSecond", "PlotCoins", "CoreSaveStatus", "PetDiscoveries" } do
	feel.trove:Connect(player:GetAttributeChangedSignal(attribute), update)
end
update()

-- Safe-area coordinates from ScreenGui; fit the modal on small landscape phones.
local function fit()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local v = camera.ViewportSize
	local compact = v.Y < 520 or v.X < 600
	counter.Position, counter.Size =
		UDim2.fromOffset(12, 56), UDim2.fromOffset(compact and 165 or 210, compact and 60 or 72)
	status.Position, status.Size = UDim2.fromOffset(12, compact and 120 or 132), UDim2.fromOffset(210, 26)
	indexButton.Position = UDim2.new(1, -144, 0, 56)
	index.AnchorPoint, index.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	local safe = gui.AbsoluteSize
	index.Size = UDim2.fromOffset(math.min(300, safe.X - 24), math.min(360, safe.Y - 24))
	card.AnchorPoint, card.Position, card.Size =
		Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.new(0, math.min(340, v.X - 32), 0, 172)
end
local viewportConnection
local function bindCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
	end
	fit()
	if workspace.CurrentCamera then
		viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
