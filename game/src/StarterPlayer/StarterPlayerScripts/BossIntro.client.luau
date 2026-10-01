--!strict
-- Cinematic boss intro: letterbox bars, camera sweep on the boss spawn, name card.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local BossIntro = ReplicatedStorage:WaitForChild("Remotes").BossIntro :: RemoteEvent

BossIntro.OnClientEvent:Connect(function(bossName: string, seconds: number)
	local arena = workspace:FindFirstChild("Arena")
	local bossSpawn = arena and arena:FindFirstChild("BossSpawn") :: BasePart?
	local gui = player:WaitForChild("PlayerGui")

	local card = Instance.new("ScreenGui")
	card.Name = "BossCard"
	card.IgnoreGuiInset = true
	card.DisplayOrder = 50
	card.Parent = gui
	for _, y in { 0, 0.85 } do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, 0, 0.15, 0)
		bar.Position = UDim2.new(0, 0, y, 0)
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Parent = card
	end
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 80)
	name.Position = UDim2.new(0, 0, 0.62, 0)
	name.BackgroundTransparency = 1
	name.Text = string.upper(bossName)
	name.Font = Enum.Font.Antique
	name.TextSize = 64
	name.TextColor3 = Color3.fromRGB(220, 40, 40)
	name.TextStrokeTransparency = 0
	name.TextTransparency = 1
	name.Parent = card
	TweenService:Create(name, TweenInfo.new(0.8), { TextTransparency = 0 }):Play()

	if bossSpawn then
		camera.CameraType = Enum.CameraType.Scriptable
		local from = bossSpawn.Position + Vector3.new(30, 25, 30)
		local to = bossSpawn.Position + Vector3.new(14, 10, 14)
		camera.CFrame = CFrame.lookAt(from, bossSpawn.Position)
		TweenService:Create(camera, TweenInfo.new(seconds, Enum.EasingStyle.Sine), {
			CFrame = CFrame.lookAt(to, bossSpawn.Position + Vector3.new(0, 6, 0)),
		}):Play()
	end
	task.wait(seconds)
	camera.CameraType = Enum.CameraType.Custom
	card:Destroy()
end)
