local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PromptService = game:GetService("ProximityPromptService")
local Input = game:GetService("UserInputService")
local Style = require(RS:WaitForChild("UIStyle"))
local player = Players.LocalPlayer
local cards = {}
local function styledPrompt(node)
	return node:IsA("ProximityPrompt") and (node.Name == "CoreOpen" or node:GetAttribute("CoreCollectSlot") ~= nil)
end
local function decorate(node)
	if not node:IsDescendantOf(workspace) then return end
	if node:IsA("BasePart") then
		local route = node:GetAttribute("RouteLabel")
		if route then
			for _, gui in node:GetChildren() do
				if gui:IsA("SurfaceGui") then
					gui:Destroy()
				end
			end
			Style.sign(node, route)
		end
	elseif styledPrompt(node) then
		-- Greybox actions retain their existing single action button/input path.
		node.Style = Enum.ProximityPromptStyle.Custom
	elseif node:IsA("TextLabel") and not node:FindFirstChild("LetterOutline") then
		local gui = node.Parent
		if gui and (gui:IsA("SurfaceGui") or gui:IsA("BillboardGui")) then
			local color = node.TextColor3
			Style.lettering(node, node.Text == "!" and 64 or 36, 1)
			node.TextColor3 = color
		end
	end
end
workspace.DescendantAdded:Connect(function(node)
	task.defer(decorate, node)
end)
for _, node in workspace:GetDescendants() do
	decorate(node)
end

local function hide(prompt)
	local card = cards[prompt]
	if not card then return end
	cards[prompt] = nil
	if card.held then
		prompt:InputHoldEnd()
	end
	for _, connection in card.connections do
		connection:Disconnect()
	end
	card.gui:Destroy()
end
PromptService.PromptShown:Connect(function(prompt, inputType)
	if not styledPrompt(prompt) or cards[prompt] then return end
	local owner = prompt:GetAttribute("CoreOwner")
	if owner and owner ~= player.UserId then return end
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Adornee, gui.Size = "OpenPrompt", prompt.Parent, UDim2.fromOffset(220, 68)
	gui.AlwaysOnTop, gui.MaxDistance, gui.StudsOffsetWorldSpace = true, 40, Vector3.new(0, 3, 0)
	gui.Parent = player:WaitForChild("PlayerGui")
	local button = Instance.new("TextButton")
	button.Size, button.Parent = UDim2.fromScale(1, 1), gui
	Style.panel(button, Style.Colors.Gold, 22)
	Style.icon(button, "route")
	local hold = prompt.HoldDuration > 0
	local key = inputType == Enum.ProximityPromptInputType.Touch and (hold and "Tap + hold" or "Tap")
		or inputType == Enum.ProximityPromptInputType.Gamepad and (hold and "Hold X" or "X") or (hold and "Hold E" or "E")
	local caption = key .. "  " .. prompt.ActionText .. "\n" .. prompt.ObjectText
	button.Text = caption
	local card = {gui = gui, connections = {}, held = false}
	cards[prompt] = card
	local function finish()
		if card.held then
			card.held = false
			prompt:InputHoldEnd()
		end
	end
	table.insert(card.connections, button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			card.held = true
			prompt:InputHoldBegin()
		end
	end))
	table.insert(card.connections, Input.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			finish()
		end
	end))
	table.insert(card.connections, prompt.PromptButtonHoldBegan:Connect(function()
		button.Text = prompt.ActionText .. "...\n" .. prompt.ObjectText
	end))
	table.insert(card.connections, prompt.PromptButtonHoldEnded:Connect(function()
		button.Text = caption
	end))
end)
PromptService.PromptHidden:Connect(hide)
workspace.DescendantRemoving:Connect(function(node)
	if cards[node] then
		hide(node)
	end
end)
