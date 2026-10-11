--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(shared:WaitForChild("Config"))
if Config.GameplayMode == "Coop" or Config.GameplayMode == "Garden" then
	return
end
local Catapult = require(shared:WaitForChild("Catapult"))
local Style = require(shared:WaitForChild("Style"))
local remote =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CatapultAction") :: RemoteEvent
local function color(name: string): Color3
	local value = Style.Palette[name]
	return Color3.fromRGB(value.r, value.g, value.b)
end

local gui = Instance.new("ScreenGui")
gui.Name = "CatapultSetup"
gui.ResetOnSpawn = false
gui.DisplayOrder = 150
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.BackgroundColor3 = color("ink")
backdrop.BackgroundTransparency = 0.3
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.Selectable = false
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Active = true
panel.Name = "LaunchPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.92, 0, 0, 326)
panel.BackgroundColor3 = color("purple")
panel.BorderSizePixel = 0
panel.ZIndex = 2
panel.Parent = backdrop
local bounds = Instance.new("UISizeConstraint")
bounds.MaxSize = Vector2.new(580, 326)
bounds.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = color("ink")
stroke.Thickness = 3
stroke.Parent = panel
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(color("purple"), Color3.fromRGB(64, 26, 119))
gradient.Rotation = 90
gradient.Parent = panel
local scale = Instance.new("UIScale")
scale.Parent = panel

local function label(name: string, text: string, y: number, height: number): TextLabel
	local result = Instance.new("TextLabel")
	result.Name = name
	result.Text = text
	result.BackgroundTransparency = 1
	result.Position = UDim2.fromOffset(14, y)
	result.Size = UDim2.new(1, -28, 0, height)
	result.Font = Enum.Font.GothamBlack
	result.TextSize = 18
	result.TextColor3 = color("white")
	result.TextStrokeColor3 = color("ink")
	result.TextStrokeTransparency = 0
	result.ZIndex = 3
	result.Parent = panel
	return result
end

local function button(
	name: string,
	text: string,
	position: UDim2,
	size: UDim2,
	face: string
): TextButton
	local result = Instance.new("TextButton")
	result.Name = name
	result.Text = text
	result.Position = position
	result.Size = size
	result.Font = Enum.Font.GothamBlack
	result.TextSize = 18
	result.TextColor3 = color("white")
	result.TextStrokeColor3 = color("ink")
	result.TextStrokeTransparency = 0
	result.BackgroundColor3 = color(face)
	result.BorderSizePixel = 0
	result.ZIndex = 4
	result.Parent = panel
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 12)
	round.Parent = result
	local outline = Instance.new("UIStroke")
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Color = color("ink")
	outline.Thickness = 3
	outline.Parent = result
	local pop = Instance.new("UIScale")
	pop.Parent = result
	result.Activated:Connect(function()
		pop.Scale = 0.97
		TweenService:Create(pop, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	return result
end

local title = label("Title", "READY TO LAUNCH?", 12, 34)
title.TextSize = 26
title.Size = UDim2.new(1, -92, 0, 34)
local subtitle = label("Hint", "Choose your arc, then roll downhill!", 48, 24)
subtitle.Size = UDim2.new(1, -92, 0, 24)
subtitle.TextSize = 16
local status = label("Status", "", 78, 24)
local closeButton =
	button("Close", "X", UDim2.new(1, -70, 0, 12), UDim2.fromOffset(56, 56), "magenta")

local angles = { 15, 35, 60 }
local presets = {}
local chosenAngle, chosenPower = 35, 0.75
local activeZone: string? = nil
local rank, balance = 0, 0
local lastAction = -math.huge
local previousSelection: GuiObject? = nil
for index, text in { "LOW 15°", "ROLL 35°", "HIGH 60°" } do
	presets[index] = button(
		"Arc" .. index,
		text,
		UDim2.new((index - 1) / 3, 14, 0, 110),
		UDim2.new(1 / 3, -28, 0, 56),
		"cyan"
	)
end
local less = button("LessPower", "−", UDim2.fromOffset(14, 176), UDim2.fromOffset(56, 56), "cyan")
local powerLabel = label("Power", "POWER 75%", 180, 48)
powerLabel.Position = UDim2.fromOffset(78, 180)
powerLabel.Size = UDim2.new(1, -156, 0, 48)
local more = button("MorePower", "+", UDim2.new(1, -70, 0, 176), UDim2.fromOffset(56, 56), "cyan")
local upgrade =
	button("Upgrade", "", UDim2.fromOffset(14, 242), UDim2.new(0.5, -21, 0, 64), "orange")
upgrade.TextWrapped = true
local launch =
	button("Launch", "LAUNCH!", UDim2.new(0.5, 7, 0, 242), UDim2.new(0.5, -21, 0, 64), "lime")
launch.TextSize = 24

local function refresh(message: string?)
	for index, preset in presets do
		preset.BackgroundColor3 = color(if angles[index] == chosenAngle then "lime" else "cyan")
	end
	powerLabel.Text = string.format("POWER %d%%", math.floor(chosenPower * 100 + 0.5))
	status.Text = message
		or string.format("RANK %d  •  +%d%% REWARDS  •  %d WINS", rank, rank * 15, balance)
	local cost = Catapult.upgradeCost(rank)
	upgrade.Text = if cost then string.format("UPGRADE +15%%\n%d WINS", cost) else "MAX RANK"
end

local function close()
	if not gui.Enabled then
		return
	end
	gui.Enabled = false
	activeZone = nil
	player:SetAttribute("CatapultSetup", false)
	ContextActionService:UnbindAction("CloseCatapult")
	if previousSelection and previousSelection.Parent then
		GuiService.SelectedObject = previousSelection
	else
		GuiService.SelectedObject = nil
	end
end

for index, preset in presets do
	preset.Activated:Connect(function()
		chosenAngle = angles[index]
		refresh()
	end)
end
less.Activated:Connect(function()
	chosenPower = math.max(0.5, chosenPower - 0.25)
	refresh()
end)
more.Activated:Connect(function()
	chosenPower = math.min(1, chosenPower + 0.25)
	refresh()
end)
closeButton.Activated:Connect(close)
backdrop.Activated:Connect(close)
local function send(action: string)
	if not activeZone or os.clock() - lastAction < 0.3 then
		return
	end
	lastAction = os.clock()
	remote:FireServer(action, activeZone, chosenAngle, chosenPower)
end
upgrade.Activated:Connect(function()
	send("Upgrade")
end)
launch.Activated:Connect(function()
	send("Launch")
end)

-- Explicit gamepad paths, with launch selected when entering from a controller.
presets[1].NextSelectionRight = presets[2]
presets[2].NextSelectionLeft = presets[1]
presets[2].NextSelectionRight = presets[3]
presets[3].NextSelectionLeft = presets[2]
for _, preset in presets do
	preset.NextSelectionDown = less
end
less.NextSelectionRight = more
more.NextSelectionLeft = less
less.NextSelectionUp = presets[1]
more.NextSelectionUp = presets[3]
less.NextSelectionDown = upgrade
more.NextSelectionDown = launch
upgrade.NextSelectionRight = launch
launch.NextSelectionLeft = upgrade
upgrade.NextSelectionUp = less
launch.NextSelectionUp = more
closeButton.NextSelectionDown = presets[3]

remote.OnClientEvent:Connect(
	function(action: string, zoneName: string?, newRank: number?, wins: number?, message: string?)
		if action == "Close" then
			close()
		elseif action == "Setup" and player:GetAttribute("Rolling") ~= true then
			if not gui.Enabled then
				previousSelection = GuiService.SelectedObject
				scale.Scale = 0.96
				TweenService:Create(scale, TweenInfo.new(0.16), { Scale = 1 }):Play()
			end
			activeZone = zoneName
			rank, balance = newRank or 0, wins or 0
			gui.Enabled = true
			player:SetAttribute("CatapultSetup", true)
			refresh(message)
			if UserInputService.GamepadEnabled then
				GuiService.SelectedObject = launch
			end
			ContextActionService:BindAction("CloseCatapult", function(_, state)
				if state == Enum.UserInputState.Begin then
					close()
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
		end
	end
)

player:GetAttributeChangedSignal("Rolling"):Connect(function()
	if player:GetAttribute("Rolling") == true then
		close()
	end
end)
player.CharacterRemoving:Connect(close)
task.spawn(function()
	while true do
		task.wait(0.25)
		if activeZone then
			local start = workspace:FindFirstChild("ZoneStart_" .. activeZone, true)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if
				not start
				or not start:IsA("BasePart")
				or not root
				or not root:IsA("BasePart")
				or (root.Position - start.Position).Magnitude > 28
			then
				close()
			end
		end
	end
end)
