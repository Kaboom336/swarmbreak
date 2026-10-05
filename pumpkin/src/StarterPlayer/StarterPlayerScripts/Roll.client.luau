--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Grow = require(Shared:WaitForChild("Grow"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rollPlayback = remotes:WaitForChild("RollPlayback") :: RemoteEvent

local ORANGE = Color3.fromRGB(255, 116, 25)
local TEAL = Color3.fromRGB(13, 53, 63)
local LIME = Color3.fromRGB(167, 255, 61)

local effectGui = Instance.new("ScreenGui")
effectGui.Name = "RollEffects"
effectGui.DisplayOrder = 20
effectGui.IgnoreGuiInset = false
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

local distanceMeter = Instance.new("TextLabel")
distanceMeter.Name = "DistanceMeter"
distanceMeter.AnchorPoint = Vector2.new(0.5, 0)
distanceMeter.BackgroundTransparency = 1
distanceMeter.Font = Enum.Font.GothamBlack
distanceMeter.Position = UDim2.new(0.5, 0, 0, 86)
distanceMeter.Size = UDim2.fromOffset(360, 80)
distanceMeter.Text = "0 m"
distanceMeter.TextColor3 = Color3.new(1, 1, 1)
distanceMeter.TextSize = 54
distanceMeter.TextStrokeColor3 = TEAL
distanceMeter.TextStrokeTransparency = 0
distanceMeter.Visible = false
distanceMeter.ZIndex = 30
distanceMeter.Parent = effectGui

local function applyDistanceMeterLayout()
	local layout = HudLayout.compute(effectGui.AbsoluteSize.X, effectGui.AbsoluteSize.Y)
	local bounds = layout.distanceMeter
	distanceMeter.AnchorPoint = Vector2.zero
	distanceMeter.Position = UDim2.fromOffset(bounds.x, bounds.y)
	distanceMeter.Size = UDim2.fromOffset(bounds.width, bounds.height)
	distanceMeter.TextSize = if layout.mobile then 38 else 48
end

applyDistanceMeterLayout()
effectGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyDistanceMeterLayout)

local coinPool = {}
for index = 1, 8 do
	local coin = Instance.new("Frame")
	coin.Name = "WinCoin" .. index
	coin.AnchorPoint = Vector2.new(0.5, 0.5)
	coin.BackgroundColor3 = LIME
	coin.BorderSizePixel = 0
	coin.Size = UDim2.fromOffset(22, 22)
	coin.Visible = false
	coin.ZIndex = 31
	coin.Parent = effectGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = coin
	table.insert(coinPool, coin)
end

local debrisFolder = Instance.new("Folder")
debrisFolder.Name = "PumpkinDebrisPool"
debrisFolder.Parent = workspace
local debrisPool = {}
for index = 1, 16 do
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

local wallPopupPool = {}
for index = 1, 8 do
	local popup = Instance.new("BillboardGui")
	popup.Name = "WallWins" .. index
	popup.AlwaysOnTop = true
	popup.Enabled = false
	popup.LightInfluence = 0
	popup.Size = UDim2.fromOffset(240, 72)
	popup.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
	popup.Parent = playerGui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Size = UDim2.fromScale(1, 1)
	label.TextColor3 = LIME
	label.TextSize = 35
	label.TextStrokeColor3 = TEAL
	label.TextStrokeTransparency = 0
	label.Parent = popup
	table.insert(wallPopupPool, popup)
end
local wallPopupCursor = 0

local function showWallWins(wall: BasePart, wins: number)
	wallPopupCursor = wallPopupCursor % #wallPopupPool + 1
	local popup = wallPopupPool[wallPopupCursor]
	local generation = (popup:GetAttribute("Generation") :: number? or 0) + 1
	popup:SetAttribute("Generation", generation)
	popup.Adornee = wall
	popup.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	popup.Enabled = true
	local label = popup:FindFirstChildWhichIsA("TextLabel") :: TextLabel
	label.Text = "+" .. wins .. " WINS"
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
	TweenService
		:Create(popup, TweenInfo.new(0.65), { StudsOffsetWorldSpace = Vector3.new(0, 9, 0) })
		:Play()
	local fade = TweenService:Create(
		label,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4),
		{
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	fade:Play()
	fade.Completed:Connect(function()
		if popup:GetAttribute("Generation") == generation then
			popup.Enabled = false
		end
	end)
end

local function flyCoins(winsGained: number, winsBefore: number)
	local hud = playerGui:FindFirstChild("PumpkinHud")
	local stats = if hud then hud:FindFirstChild("Stats") else nil
	local winsLabel = if stats then stats:FindFirstChild("Wins") else nil
	local target = if winsLabel and winsLabel:IsA("GuiObject")
		then winsLabel.AbsolutePosition + winsLabel.AbsoluteSize * 0.5
		else Vector2.new(effectGui.AbsoluteSize.X * 0.62, 50)
	local center = effectGui.AbsoluteSize * 0.5
	for index, coin in coinPool do
		coin.Position =
			UDim2.fromOffset(center.X + (index - 4.5) * 12, center.Y + math.random(-24, 24))
		coin.Visible = true
		local tween = TweenService:Create(
			coin,
			TweenInfo.new(0.42 + index * 0.025, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(10, 10) }
		)
		tween:Play()
		tween.Completed:Connect(function()
			coin.Visible = false
			coin.Size = UDim2.fromOffset(22, 22)
		end)
	end
	if winsLabel and winsLabel:IsA("TextLabel") then
		-- Count from the total captured at roll start: the server's stats sync can land before playback ends
		local before = winsBefore
		task.spawn(function()
			for step = 1, 12 do
				winsLabel.Text = "WINS\n" .. Format.abbrev(before + winsGained * step / 12)
				task.wait(0.025)
			end
		end)
	end
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
	local winsBefore = (player:GetAttribute("Wins") :: number?) or 0
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
	pumpkin.Transparency = 0
	local rollMesh = Instance.new("SpecialMesh")
	rollMesh.MeshType = Enum.MeshType.FileMesh
	rollMesh.MeshId = Config.PumpkinMeshId
	rollMesh.TextureId = Config.PumpkinTextureId
	rollMesh.Scale = Vector3.new(diameter, diameter * 0.82, diameter) * Config.PumpkinMeshScale
	rollMesh.Parent = pumpkin
	pumpkin.Parent = workspace

	local smashSound = Instance.new("Sound")
	smashSound.Name = "Smash"
	smashSound.SoundId = "rbxasset://sounds/collide.wav"
	smashSound.Volume = 0.75
	smashSound.Parent = pumpkin

	local isLocalRoll = userId == player.UserId
	local camera = workspace.CurrentCamera
	local previousSubject = if camera then camera.CameraSubject else nil
	local previousType = if camera then camera.CameraType else Enum.CameraType.Custom
	local previousFov = if camera then camera.FieldOfView else 70
	local cameraConnection: RBXScriptConnection? = nil
	if isLocalRoll and camera then
		camera.CameraType = Enum.CameraType.Scriptable
		cameraConnection = RunService.RenderStepped:Connect(function()
			local behind = -start.CFrame.LookVector * 20 + Vector3.new(0, 11, 0)
			camera.CFrame =
				CFrame.lookAt(pumpkin.Position + behind, pumpkin.Position + Vector3.new(0, 2, 0))
		end)
		TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = previousFov + 8 }):Play()
		distanceMeter.Visible = true
		task.spawn(function()
			local began = os.clock()
			while pumpkin.Parent do
				local elapsed = math.min(1, (os.clock() - began) / duration)
				distanceMeter.Text = string.format("%d m", math.floor(distance * elapsed + 0.5))
				if elapsed >= 1 then
					break
				end
				RunService.RenderStepped:Wait()
			end
		end)
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
				showWallWins(wall, math.floor(wins / math.max(1, wallsBroken)))
				if camera then
					camera.FieldOfView = previousFov + 14
					TweenService
						:Create(camera, TweenInfo.new(0.2), { FieldOfView = previousFov + 8 })
						:Play()
				end
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
		flyCoins(wins, winsBefore)
		distanceMeter.Visible = false
		if camera then
			if cameraConnection then
				cameraConnection:Disconnect()
			end
			camera.CameraType = previousType
			camera.CameraSubject = previousSubject
			TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = previousFov }):Play()
		end
	end
	pumpkin:Destroy()
end

rollPlayback.OnClientEvent:Connect(function(...)
	task.spawn(playRoll, ...)
end)
