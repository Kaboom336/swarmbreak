local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Style = require(RS:WaitForChild("UIStyle"))
local config = require(RS:WaitForChild("TreasureCore").Config)
local event = RS:WaitForChild("TreasureCoreEvent")
local feel = require(RS.TreasureCore.Feel).new()
script.Destroying:Connect(function()
	feel:Destroy()
end)
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.Parent =
	"TreasureCoreHud", false, 20, player:WaitForChild("PlayerGui")
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
local counter =
	text(gui, "Coins", UDim2.fromOffset(16, 104), UDim2.fromOffset(210, 72), "Coins 0\n0 Coins/s")
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
indexRow.Name, indexRow.Size, indexRow.BackgroundTransparency, indexRow.Parent = "Content", UDim2.fromScale(1, 1), 1, indexButton
local indexLayout = Instance.new("UIListLayout")
indexLayout.FillDirection, indexLayout.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center
indexLayout.HorizontalAlignment, indexLayout.SortOrder = Enum.HorizontalAlignment.Center, Enum.SortOrder.LayoutOrder
indexLayout.Padding, indexLayout.Parent = UDim.new(0, 8), indexRow
-- Reserve the rotated gem's full 34-pixel visual footprint.
local indexIconSlot = Instance.new("Frame")
indexIconSlot.Size, indexIconSlot.BackgroundTransparency, indexIconSlot.LayoutOrder, indexIconSlot.Parent = UDim2.fromOffset(34, 34), 1, 1, indexRow
local indexIcon = Style.icon(indexIconSlot, "gem", Style.Colors.Cream)
indexIcon.Position, indexIcon.AnchorPoint = UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
local indexCaption = Instance.new("TextLabel")
indexCaption.Name, indexCaption.Text, indexCaption.Size = "Caption", "Index", UDim2.new(0, 68, 1, 0)
indexCaption.BackgroundTransparency, indexCaption.LayoutOrder, indexCaption.Parent = 1, 2, indexRow
Style.lettering(indexCaption, 22)
local openTap =
	button("OpenTap", UDim2.new(1, -166, 0.5, -24), UDim2.fromOffset(150, 48), "Open acorn")
openTap.Visible = false
openTap.Activated:Connect(function()
	event:FireServer("OpenTap")
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
	if
		UserInputService.TouchEnabled
		and root
		and world
		and player:GetAttribute("CoreOpenReady")
	then
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
local index =
	text(gui, "IndexPanel", UDim2.new(0.5, -150, 0.5, -180), UDim2.fromOffset(300, 360), "")
index.Visible = false
index.TextSize = 20
local close = Instance.new("TextButton")
close.Text, close.Size, close.Position, close.Parent =
	"Close", UDim2.fromOffset(90, 48), UDim2.new(1, -98, 1, -56), index
Style.panel(close, Style.Colors.Cyan, 20)
close.Activated:Connect(function()
	index.Visible = false
end)
local function indexText()
	local found = {}
	for name in (player:GetAttribute("PetDiscoveries") or ""):gmatch("[^|]+") do
		found[name] = true
	end
	for i, rarity in config.Rarities do
		local caption = index:FindFirstChild("Entry" .. i)
		if caption then
			caption.Text = found[rarity.pet] and (rarity.pet .. "\n" .. rarity.name)
				or "?\nUndiscovered"
			caption.TextColor3 = found[rarity.pet] and Style.rarity(rarity) or Style.Colors.Cream
		end
		local view = index:FindFirstChild("Silhouette" .. i)
		if view then
			for _, part in view:GetDescendants() do
				if part:IsA("BasePart") then
					if not part:GetAttribute("OriginalColor") then
						part:SetAttribute("OriginalColor", part.Color)
					end
					part.Color = found[rarity.pet] and part:GetAttribute("OriginalColor")
						or Color3.fromRGB(12, 16, 24)
				end
			end
		end
	end
end
index.Text = ""
text(index, "Title", UDim2.fromOffset(0, 0), UDim2.fromOffset(300, 36), "PET INDEX")
task.spawn(function()
	local preview = RS:WaitForChild("CorePetPreview", 20)
	for i, rarity in config.Rarities do
		local caption = text(
			index,
			"Entry" .. i,
			UDim2.fromOffset(76, 38 + (i - 1) * 62),
			UDim2.fromOffset(210, 56),
			"?\nUndiscovered"
		)
		caption.TextSize = 16
		local view = Instance.new("ViewportFrame")
		view.Name, view.Position, view.Size =
			"Silhouette" .. i, UDim2.fromOffset(10, 38 + (i - 1) * 62), UDim2.fromOffset(60, 56)
		view.BackgroundTransparency, view.Parent = 1, index
		local camera = Instance.new("Camera")
		camera.CFrame, camera.Parent =
			CFrame.lookAt(Vector3.new(5, 4, 7), Vector3.new(0, 1.5, 0)), view
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
end)
local card = text(gui, "Reveal", UDim2.new(0.5, -150, 0.62, 0), UDim2.fromOffset(300, 140), "")
card.Visible = false
local skip = Instance.new("TextButton")
skip.Text, skip.Size, skip.Position, skip.Parent =
	"Tap to skip", UDim2.fromOffset(130, 48), UDim2.new(0.5, -65, 1, -48), card
Style.panel(skip, Style.Colors.Cyan, 18)
local revealTitle = text(card, "RewardTitle", UDim2.fromScale(0, 0), UDim2.new(1, 0, 1, -52), "")
revealTitle.BackgroundTransparency = 1
for _, name in {"PanelEdge", "PanelShadow", "PanelGradient"} do
	revealTitle[name]:Destroy()
end
skip.Activated:Connect(function()
	card.Visible = false
end)
local revealGeneration = 0
feel.trove:Connect(event.OnClientEvent, function(kind, a, b, c)
	if kind == "Reveal" then
		revealGeneration += 1
		local generation = revealGeneration
		revealTitle.Text = a .. "\n" .. b .. "  /  +" .. c .. " Coins/s"
		for _, rarity in config.Rarities do
			if rarity.name == b then
				revealTitle.TextColor3 = Style.rarity(rarity)
			end
		end
		card.Visible = true
		feel:pop(card)
		task.delay(config.RevealSeconds, function()
			if generation == revealGeneration then
				card.Visible = false
			end
		end)
	elseif kind == "Collect" then
		local pop = text(
			gui,
			"CoinPop",
			UDim2.new(0.5, -100, 0.4, 0),
			UDim2.fromOffset(200, 54),
			"+" .. a .. " Coins"
		)
		pop.TextColor3 = Color3.fromRGB(255, 221, 80)
		feel:pop(pop)
		TweenService:Create(pop, TweenInfo.new(0.8), {
			Position = UDim2.new(0.5, -100, 0.3, 0),
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.8, function()
			pop:Destroy()
		end)
	end
end)
local function update()
	feel:counter(counter, player:GetAttribute("Coins") or 0, function(value)
		counter.Text = '<font size="24">Coins ' .. tostring(math.floor(value + .5)) .. '</font>\n<font size="14">'
			.. tostring(player:GetAttribute("CoinsPerSecond") or 0) .. ' Coins/s</font>'
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
	if not camera then return end
	local v = camera.ViewportSize
	local compact = v.Y < 520 or v.X < 600
	counter.Position, counter.Size = UDim2.fromOffset(12, 56), UDim2.fromOffset(compact and 165 or 210, compact and 60 or 72)
	status.Position, status.Size = UDim2.fromOffset(12, compact and 120 or 132), UDim2.fromOffset(210, 26)
	indexButton.Position = UDim2.new(1, -144, 0, 56)
	index.AnchorPoint, index.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	local scale = index:FindFirstChild("Fit") or Instance.new("UIScale")
	scale.Name, scale.Scale, scale.Parent = "Fit", math.min(1, (v.Y - 60) / 360, (v.X - 32) / 300), index
	card.AnchorPoint, card.Position, card.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.new(0, math.min(340, v.X - 32), 0, 160)
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
