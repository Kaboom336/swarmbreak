--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Grow = require(Shared:WaitForChild("Grow"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rollPlayback = remotes:WaitForChild("RollPlayback") :: RemoteEvent

local ORANGE = Color3.fromRGB(255, 116, 25)
local TEAL = Color3.fromRGB(13, 53, 63)

local effectGui = Instance.new("ScreenGui")
effectGui.Name = "RollEffects"
effectGui.DisplayOrder = 20
effectGui.IgnoreGuiInset = true
effectGui.ResetOnSpawn = false
effectGui.Parent = playerGui

local winBurst = Instance.new("TextLabel")
winBurst.Name = "WinBurst"
winBurst.AnchorPoint = Vector2.new(0.5, 0.5)
winBurst.BackgroundTransparency = 1
winBurst.Font = Enum.Font.GothamBlack
winBurst.Position = UDim2.fromScale(0.5, 0.36)
winBurst.Size = UDim2.fromOffset(440, 90)
winBurst.TextColor3 = ORANGE
winBurst.TextSize = 50
winBurst.TextStrokeColor3 = TEAL
winBurst.TextStrokeTransparency = 0
winBurst.TextTransparency = 1
winBurst.Parent = effectGui

local winScale = Instance.new("UIScale")
winScale.Parent = winBurst

local debrisFolder = Instance.new("Folder")
debrisFolder.Name = "PumpkinDebrisPool"
debrisFolder.Parent = workspace
local debrisPool = {}
for index = 1, 24 do
	local debris = Instance.new("Part")
	debris.Name = "Debris" .. index
	debris.Anchored = true
	debris.CanCollide = false
	debris.CanQuery = false
	debris.CanTouch = false
	debris.Color = ORANGE
	debris.Material = Enum.Material.Neon
	debris.Size = Vector3.new(0.8, 0.8, 0.8)
	debris.Transparency = 1
	debris.Parent = debrisFolder
	table.insert(debrisPool, debris)
end

local debrisCursor = 0
local function burstDebris(position: Vector3)
	for _ = 1, 8 do
		debrisCursor = debrisCursor % #debrisPool + 1
		local debris = debrisPool[debrisCursor]
		local direction =
			Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.25, math.random() - 0.5).Unit
		debris.Position = position
		debris.Transparency = 0
		TweenService:Create(
			debris,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = position + direction * math.random(5, 10), Transparency = 1 }
		):Play()
	end
end

local function shakeCamera()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		return
	end
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < 0.18 do
			humanoid.CameraOffset =
				Vector3.new(math.random(-10, 10) / 25, math.random(-10, 10) / 25, 0)
			RunService.RenderStepped:Wait()
		end
		humanoid.CameraOffset = Vector3.zero
	end)
end

local function showWins(wins: number)
	if wins <= 0 then
		return
	end
	winBurst.Text = "+" .. wins .. " WINS"
	winBurst.TextTransparency = 0
	winBurst.TextStrokeTransparency = 0
	winScale.Scale = 0.55
	TweenService:Create(winScale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1.15 })
		:Play()
	TweenService:Create(
		winBurst,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.7),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	):Play()
end

local function findPart(name: string): BasePart?
	local found = workspace:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

local function playRoll(
	userId: number,
	zoneName: string,
	size: number,
	wallsBroken: number,
	distance: number,
	wins: number,
	duration: number
)
	local start = findPart("ZoneStart_" .. zoneName)
	local track = workspace:FindFirstChild("Track_" .. zoneName, true)
	if not start or not track then
		return
	end

	local diameter = Config.PumpkinBaseDiameter * Grow.pumpkinScale(size)
	local pumpkin = Instance.new("Part")
	pumpkin.Name = "RollingPumpkin_" .. userId
	pumpkin.Shape = Enum.PartType.Ball
	pumpkin.Anchored = true
	pumpkin.CanCollide = false
	pumpkin.CanQuery = false
	pumpkin.CanTouch = false
	pumpkin.Color = ORANGE
	pumpkin.Material = Enum.Material.SmoothPlastic
	pumpkin.Size = Vector3.new(diameter, diameter * 0.82, diameter)
	pumpkin.CFrame = CFrame.new(start.Position + Vector3.new(0, diameter * 0.5 + 1, 0))
	pumpkin.Parent = workspace

	local smashSound = Instance.new("Sound")
	smashSound.Name = "Smash"
	smashSound.SoundId = "rbxasset://sounds/collide.wav"
	smashSound.Volume = 0.75
	smashSound.Parent = pumpkin

	local isLocalRoll = userId == player.UserId
	local camera = workspace.CurrentCamera
	local previousSubject = if camera then camera.CameraSubject else nil
	local previousFov = if camera then camera.FieldOfView else 70
	if isLocalRoll and camera then
		camera.CameraSubject = pumpkin
		TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = previousFov + 8 }):Play()
	end

	local reachedWalls = math.max(1, math.floor(distance / Config.WallSpacing + 0.5))
	local segmentDuration = duration / reachedWalls
	for wallIndex = 1, reachedWalls do
		local wall = track:FindFirstChild("Wall_" .. wallIndex, true)
		if not wall or not wall:IsA("BasePart") then
			break
		end
		local target = wall.Position - start.CFrame.LookVector * (diameter * 0.4)
		target =
			Vector3.new(target.X, wall.Position.Y - wall.Size.Y * 0.5 + diameter * 0.41, target.Z)
		local tween =
			TweenService:Create(pumpkin, TweenInfo.new(segmentDuration, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(target) * CFrame.Angles(0, 0, -math.pi * wallIndex),
			})
		tween:Play()
		tween.Completed:Wait()
		if wallIndex <= wallsBroken then
			wall.LocalTransparencyModifier = 1
			burstDebris(wall.Position)
			if player:GetAttribute("SFXEnabled") ~= false then
				smashSound:Play()
			end
			if isLocalRoll then
				shakeCamera()
			end
			task.delay(0.8, function()
				if wall.Parent then
					wall.LocalTransparencyModifier = 0
				end
			end)
		end
	end

	if isLocalRoll then
		showWins(wins)
		if camera then
			camera.CameraSubject = previousSubject
			TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = previousFov }):Play()
		end
	end
	pumpkin:Destroy()
end

rollPlayback.OnClientEvent:Connect(function(...)
	task.spawn(playRoll, ...)
end)
