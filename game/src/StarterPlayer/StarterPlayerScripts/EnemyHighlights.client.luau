--!strict
-- Keeps outlines on the nearest enemies without exceeding Roblox's practical highlight budget.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local localPlayer = Players.LocalPlayer
local enemies = workspace:WaitForChild("Enemies")

local MAX_HIGHLIGHTS = 30
local UPDATE_INTERVAL = 0.15
local HIGHLIGHT_NAME = "EnemyOutline"

type Candidate = {
	Model: Model,
	Distance: number,
}

local function viewPosition(): Vector3?
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

local function addHighlight(model: Model)
	if model:FindFirstChild(HIGHLIGHT_NAME) then
		return
	end
	local outline = Instance.new("Highlight")
	outline.Name = HIGHLIGHT_NAME
	outline.Adornee = model
	outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	outline.FillTransparency = 1
	outline.OutlineColor =
		Color3.fromRGB(Theme.NeonAmber[1], Theme.NeonAmber[2], Theme.NeonAmber[3])
	outline.OutlineTransparency = 0.2
	outline.Parent = model
end

local function removeHighlight(model: Model)
	local outline = model:FindFirstChild(HIGHLIGHT_NAME)
	if outline and outline:IsA("Highlight") then
		outline:Destroy()
	end
end

local function updateHighlights()
	local origin = viewPosition()
	if not origin then
		return
	end

	local candidates: { Candidate } = {}
	for _, child in enemies:GetChildren() do
		if child:IsA("Model") then
			local root = child.PrimaryPart
			local humanoid = child:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				table.insert(candidates, {
					Model = child,
					Distance = (root.Position - origin).Magnitude,
				})
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.Distance < b.Distance
	end)

	local highlighted: { [Model]: boolean } = {}
	for index, candidate in candidates do
		if index > MAX_HIGHLIGHTS then
			break
		end
		highlighted[candidate.Model] = true
		addHighlight(candidate.Model)
	end
	for _, child in enemies:GetChildren() do
		if child:IsA("Model") and not highlighted[child] then
			removeHighlight(child)
		end
	end
end

local elapsed = UPDATE_INTERVAL
RunService.Heartbeat:Connect(function(deltaTime)
	elapsed += deltaTime
	if elapsed >= UPDATE_INTERVAL then
		elapsed = 0
		updateHighlights()
	end
end)
