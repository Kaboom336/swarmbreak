local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "GreyboxGoal", false
gui.Parent = player:WaitForChild("PlayerGui")
local goal = Instance.new("TextLabel")
goal.AnchorPoint, goal.Position = Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.96)
goal.Size, goal.BackgroundTransparency = UDim2.fromScale(0.9, 0.1), 0.2
goal.BackgroundColor3, goal.TextColor3 = Color3.fromRGB(30, 35, 40), Color3.new(1, 1, 1)
goal.TextSize, goal.TextWrapped = 20, true
goal.Parent = gui
local function refresh()
	goal.Text = (player:GetAttribute("GreyboxCarry") and "Carry 1/1 | " or "")
		.. (player:GetAttribute("GreyboxGoal") or "Enter the central portal.")
end
player:GetAttributeChangedSignal("GreyboxGoal"):Connect(refresh)
player:GetAttributeChangedSignal("GreyboxCarry"):Connect(refresh)
refresh()
local highlight = Instance.new("Highlight")
highlight.Name, highlight.FillTransparency, highlight.OutlineColor = "OwnPen", 1, Color3.fromRGB(255, 220, 80)
highlight.Parent = gui
RunService.RenderStepped:Connect(function()
	local world = workspace:FindFirstChild("GREYBOX")
	local slot = player:GetAttribute("GreyboxPen")
	local marker = world and slot and world:FindFirstChild("PenMarker" .. slot)
	highlight.Adornee = marker or nil
	if world then
		for _, child in world:GetChildren() do
			local q = child:FindFirstChildOfClass("ProximityPrompt")
			if q and q:GetAttribute("PenSlot") then
				q.Enabled = q:GetAttribute("PenSlot") == slot
			end
		end
	end
end)
