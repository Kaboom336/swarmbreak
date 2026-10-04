--!strict
-- Keeps outlines on the nearest enemies without exceeding Roblox's practical highlight budget.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OutlinePool = require(Shared:WaitForChild("OutlinePool"))
local Theme = require(Shared:WaitForChild("Theme"))
local localPlayer = Players.LocalPlayer
local enemies = workspace:WaitForChild("Enemies")

local UPDATE_INTERVAL = 0.15
local HIGHLIGHT_NAME = "EnemyOutline"
local tracked: { [Model]: Highlight } = {}

local function viewPosition(): Vector3?
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

local function addHighlight(model: Model): Highlight
	local existing = model:FindFirstChild(HIGHLIGHT_NAME)
	if existing and existing:IsA("Highlight") then
		tracked[model] = existing
		return existing
	end
	local outline = Instance.new("Highlight")
	outline.Name = HIGHLIGHT_NAME
	outline.Adornee = model
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.FillTransparency = 1
	outline.OutlineColor =
		Color3.fromRGB(Theme.ChitinDark[1], Theme.ChitinDark[2], Theme.ChitinDark[3])
	outline.OutlineTransparency = 0.2
	outline.Parent = model
	tracked[model] = outline
	return outline
end

local function addCandidate(candidates: { OutlinePool.Candidate }, model: Model, origin: Vector3)
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		table.insert(candidates, {
			Target = model,
			Distance = (root.Position - origin).Magnitude,
		})
	end
end

local function updateHighlights()
	local origin = viewPosition()
	if not origin then
		return
	end

	local candidates: { OutlinePool.Candidate } = {}
	for _, child in enemies:GetChildren() do
		if child:IsA("Model") then
			addCandidate(candidates, child, origin)
		end
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			addCandidate(candidates, player.Character, origin)
		end
	end

	local highlighted: { [Model]: boolean } = {}
	for _, candidate in OutlinePool.nearest(candidates) do
		highlighted[candidate.Target] = true
	end
	-- Remove displaced targets first, so a changing selection never briefly exceeds the cap.
	for model, outline in tracked do
		if not highlighted[model] then
			if outline.Parent then
				outline:Destroy()
			end
			tracked[model] = nil
		end
	end
	for model in highlighted do
		if model.Parent and not tracked[model] then
			addHighlight(model)
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
