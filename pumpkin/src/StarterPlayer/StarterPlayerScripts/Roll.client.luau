--!strict
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CameraFraming = require(Shared:WaitForChild("CameraFraming"))
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Grow = require(Shared:WaitForChild("Grow"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Ride = require(Shared:WaitForChild("Ride"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rollPlayback = remotes:WaitForChild("RollPlayback") :: RemoteEvent
local rollControl = remotes:WaitForChild("RollControl") :: RemoteEvent

local ORANGE = Color3.fromRGB(255, 116, 25)
local TEAL = Color3.fromRGB(13, 53, 63)
local LIME = Color3.fromRGB(167, 255, 61)

local effectGui = Instance.new("ScreenGui")
effectGui.Name = "RollEffects"
effectGui.DisplayOrder = 100
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
winBurst.ZIndex = 100
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
distanceMeter.ZIndex = 100
distanceMeter.Parent = effectGui

local bonusCounter = Instance.new("TextLabel")
bonusCounter.Name = "BonusCounter"
bonusCounter.AnchorPoint = Vector2.new(0.5, 0)
bonusCounter.BackgroundTransparency = 1
bonusCounter.Font = Enum.Font.GothamBlack
bonusCounter.Text = "BONUS +0"
bonusCounter.TextColor3 = ORANGE
bonusCounter.TextSize = 34
bonusCounter.TextStrokeColor3 = TEAL
bonusCounter.TextStrokeTransparency = 0
bonusCounter.Visible = false
bonusCounter.ZIndex = 100
bonusCounter.Parent = effectGui
local bonusScale = Instance.new("UIScale")
bonusScale.Parent = bonusCounter

local comboCounter = Instance.new("TextLabel")
comboCounter.Name = "ComboCounter"
comboCounter.AnchorPoint = Vector2.new(0.5, 0.5)
comboCounter.BackgroundTransparency = 1
comboCounter.Font = Enum.Font.GothamBlack
comboCounter.Position = UDim2.fromScale(0.5, 0.28)
comboCounter.Size = UDim2.fromOffset(360, 64)
comboCounter.TextColor3 = LIME
comboCounter.TextSize = 38
comboCounter.TextStrokeColor3 = TEAL
comboCounter.TextStrokeTransparency = 0
comboCounter.Visible = false
comboCounter.ZIndex = 100
comboCounter.Parent = effectGui
local comboScale = Instance.new("UIScale")
comboScale.Parent = comboCounter

local steerHint = Instance.new("TextLabel")
steerHint.Name = "SteerHint"
steerHint.AnchorPoint = Vector2.new(0.5, 0.5)
steerHint.BackgroundTransparency = 1
steerHint.Font = Enum.Font.GothamBlack
steerHint.Position = UDim2.fromScale(0.5, 0.72)
steerHint.Size = UDim2.fromOffset(360, 80)
steerHint.TextColor3 = Color3.new(1, 1, 1)
steerHint.TextSize = 30
steerHint.TextStrokeColor3 = TEAL
steerHint.TextStrokeTransparency = 0
steerHint.Visible = false
steerHint.ZIndex = 100
steerHint.Parent = effectGui

local function applyDistanceMeterLayout()
	local layout = HudLayout.compute(effectGui.AbsoluteSize.X, effectGui.AbsoluteSize.Y)
	local bounds = layout.distanceMeter
	distanceMeter.AnchorPoint = Vector2.zero
	distanceMeter.Position = UDim2.fromOffset(bounds.x, bounds.y)
	distanceMeter.Size = UDim2.fromOffset(bounds.width, bounds.height)
	distanceMeter.TextSize = if layout.mobile then 38 else 48
	local toastBounds = layout.tutorial
	winBurst.AnchorPoint = Vector2.zero
	winBurst.Position = UDim2.fromOffset(toastBounds.x, toastBounds.y)
	winBurst.Size = UDim2.fromOffset(toastBounds.width, toastBounds.height)
	winBurst.TextSize = if layout.mobile then 28 else 36
	bonusCounter.AnchorPoint = Vector2.zero
	bonusCounter.Position = UDim2.fromOffset(toastBounds.x, toastBounds.y + toastBounds.height)
	bonusCounter.Size = UDim2.fromOffset(toastBounds.width, toastBounds.height)
	bonusCounter.TextSize = if layout.mobile then 26 else 34
	comboCounter.Position = UDim2.fromOffset(toastBounds.x, toastBounds.y + toastBounds.height)
	comboCounter.Size = UDim2.fromOffset(toastBounds.width, toastBounds.height)
	comboCounter.TextSize = if layout.mobile then 28 else 38
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

local bonusParticlePool = {}
for index = 1, 8 do
	local particle = Instance.new("Frame")
	particle.Name = "BonusParticle" .. index
	particle.AnchorPoint = Vector2.new(0.5, 0.5)
	particle.BackgroundColor3 = ORANGE
	particle.BorderSizePixel = 0
	particle.Size = UDim2.fromOffset(9, 9)
	particle.Visible = false
	particle.ZIndex = 29
	particle.Parent = effectGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = particle
	table.insert(bonusParticlePool, particle)
end
local bonusParticleCursor = 0
local bonusSummaryGeneration = 0

local function burstBonusParticle()
	bonusParticleCursor = bonusParticleCursor % #bonusParticlePool + 1
	local particle = bonusParticlePool[bonusParticleCursor]
	local generation = (particle:GetAttribute("Generation") :: number? or 0) + 1
	particle:SetAttribute("Generation", generation)
	local center = bonusCounter.AbsolutePosition + bonusCounter.AbsoluteSize * 0.5
	particle.Position = UDim2.fromOffset(center.X + math.random(-45, 45), center.Y + 12)
	particle.BackgroundTransparency = 0
	particle.Visible = true
	TweenService
		:Create(particle, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = particle.Position - UDim2.fromOffset(0, 35),
			BackgroundTransparency = 1,
		})
		:Play()
	task.delay(0.36, function()
		if particle:GetAttribute("Generation") == generation then
			particle.Visible = false
		end
	end)
end

local debrisFolder = Instance.new("Folder")
debrisFolder.Name = "PumpkinDebrisPool"
debrisFolder.Parent = workspace
local debrisPool = {}
for index = 1, 20 do
	local debris = Instance.new("Part")
	debris.Name = "Debris" .. index
	debris.Anchored = true
	debris.CanCollide = false
	debris.CanQuery = false
	debris.CanTouch = false
	debris.Color = ORANGE
	debris.Material = Enum.Material.SmoothPlastic
	debris.Size = Vector3.new(0.8, 0.8, 0.8)
	debris.Transparency = 1
	debris.Parent = debrisFolder
	table.insert(debrisPool, debris)
end

local shockwavePool = {}
for index = 1, 3 do
	local shockwave = Instance.new("Part")
	shockwave.Name = "Shockwave" .. index
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.CanQuery = false
	shockwave.CanTouch = false
	shockwave.Color = LIME
	shockwave.Material = Enum.Material.Neon
	shockwave.Size = Vector3.new(0.15, 2, 2)
	shockwave.Transparency = 1
	shockwave.Parent = debrisFolder
	table.insert(shockwavePool, shockwave)
end
local shockwaveCursor = 0

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

local winsTickGeneration = 0
local function flyCoins(origin: Vector2, winsGained: number, winsBefore: number)
	local hud = playerGui:FindFirstChild("PumpkinHud")
	local stats = if hud then hud:FindFirstChild("Stats") else nil
	local winsLabel = if stats then stats:FindFirstChild("Wins") else nil
	local target = if winsLabel and winsLabel:IsA("GuiObject")
		then winsLabel.AbsolutePosition + winsLabel.AbsoluteSize * 0.5
		else Vector2.new(effectGui.AbsoluteSize.X * 0.62, 50)
	for index, coin in coinPool do
		local generation = (coin:GetAttribute("Generation") :: number? or 0) + 1
		coin:SetAttribute("Generation", generation)
		coin.Position =
			UDim2.fromOffset(origin.X + (index - 4.5) * 8, origin.Y + math.random(-18, 18))
		coin.Visible = true
		local tween = TweenService:Create(
			coin,
			TweenInfo.new(0.42 + index * 0.025, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(10, 10) }
		)
		tween:Play()
		tween.Completed:Connect(function()
			if coin:GetAttribute("Generation") == generation then
				coin.Visible = false
				coin.Size = UDim2.fromOffset(22, 22)
			end
		end)
	end
	if winsLabel and winsLabel:IsA("TextLabel") then
		-- Count from the total captured at roll start: the server's stats sync can land before playback ends
		local before = winsBefore
		winsTickGeneration += 1
		local generation = winsTickGeneration
		task.spawn(function()
			for step = 1, 12 do
				if winsTickGeneration ~= generation then
					return
				end
				winsLabel.Text = "WINS\n" .. Format.abbrev(before + winsGained * step / 12)
				task.wait(0.025)
			end
		end)
	end
end

local debrisCursor = 0
local function burstDebris(position: Vector3, wallIndex: number)
	local chunkCount = 12 + (wallIndex - 1) % 9
	for chunkIndex = 1, chunkCount do
		debrisCursor = debrisCursor % #debrisPool + 1
		local debris = debrisPool[debrisCursor]
		local generation = (debris:GetAttribute("Generation") :: number? or 0) + 1
		debris:SetAttribute("Generation", generation)
		local direction =
			Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.25, math.random() - 0.5).Unit
		debris.Position = position
		debris.Transparency = 0
		local apex = position + direction * math.random(3, 6) + Vector3.new(0, math.random(3, 6), 0)
		local rise = TweenService:Create(
			debris,
			TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = apex, Orientation = Vector3.new(chunkIndex * 31, chunkIndex * 47, 0) }
		)
		rise:Play()
		rise.Completed:Connect(function()
			if debris:GetAttribute("Generation") ~= generation then
				return
			end
			TweenService
				:Create(
					debris,
					TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						Position = apex + direction * math.random(3, 7) - Vector3.new(0, 5, 0),
						Transparency = 1,
					}
				)
				:Play()
		end)
	end

	shockwaveCursor = shockwaveCursor % #shockwavePool + 1
	local shockwave = shockwavePool[shockwaveCursor]
	shockwave.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	shockwave.Size = Vector3.new(0.15, 2, 2)
	shockwave.Transparency = 0.15
	TweenService:Create(
		shockwave,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.15, 22, 22), Transparency = 1 }
	):Play()
end

local function showWins(wins: number)
	if wins <= 0 then
		return
	end
	winBurst.Text = "+" .. wins .. " WINS!"
	winBurst.TextTransparency = 0
	winBurst.TextStrokeTransparency = 0
	winScale.Scale = 0.55
	TweenService:Create(winScale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1.15 })
		:Play()
	TweenService:Create(
		winBurst,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.2),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	):Play()
end

local function showCombo(wallsBroken: number)
	local text = Ride.comboText(wallsBroken)
	comboCounter.Text = text or ""
	comboCounter.Visible = text ~= nil
	comboScale.Scale = 0.6
	TweenService:Create(
		comboScale,
		TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
end

local function findPart(name: string): BasePart?
	local found = workspace:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

local activeControl: any = nil
local completedResults: { [number]: { wins: number, pickups: number } } = {}

local function setTargetVisible(part: BasePart, visible: boolean)
	part.Transparency = if visible
		then (part:GetAttribute("VisibleTransparency") :: number?) or 0
		else 1
	for _, descendant in part:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if visible
				then (descendant:GetAttribute("VisibleTransparency") :: number?) or 0
				else 1
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = visible
		end
	end
end

local function createBonusTargets(
	start: BasePart,
	physicalDistance: number,
	physicalDuration: number,
	seed: number
): (Folder, { [number]: BasePart })
	local folder = Instance.new("Folder")
	folder.Name = "RideBonusTargets"
	folder.Parent = workspace
	local parts = {}
	local direction = Vector3.new(start.CFrame.LookVector.X, -0.06, start.CFrame.LookVector.Z).Unit
	local horizontal = Vector3.new(direction.X, 0, direction.Z).Unit
	local right = Vector3.new(-horizontal.Z, 0, horizontal.X)
	for _, target in Ride.layout(seed, physicalDuration) do
		local part = Instance.new("Part")
		part.Name = target.kind .. "_" .. target.id
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.SmoothPlastic
		part.Position = start.Position
			+ direction * (physicalDistance * Ride.progress(target.time, physicalDuration))
			+ right * (target.lane * Config.RideLaneStuds)
			+ Vector3.new(0, 2, 0)
		if target.kind == "Candy" then
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(3.5, 3.5, 3.5)
			part.Color = Color3.fromRGB(255, 95, 185)
		elseif target.kind == "GoldPumpkin" then
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(5, 4.1, 5)
			part.Color = Color3.fromRGB(255, 205, 45)
			part.Material = Enum.Material.Neon
		else
			part.Size = Vector3.new(8, 0.6, 7)
			part.Color = LIME
			part.Material = Enum.Material.Neon
		end
		part.Parent = folder
		parts[target.id] = part

		local beacon = Instance.new("Part")
		beacon.Name = "Beacon"
		beacon.Anchored = true
		beacon.CanCollide = false
		beacon.CanQuery = false
		beacon.CanTouch = false
		beacon.Color = part.Color
		beacon.Material = Enum.Material.Neon
		beacon.Size = Vector3.new(0.45, 14, 0.45)
		beacon.CFrame = part.CFrame + Vector3.new(0, 8, 0)
		beacon.Transparency = 0.2
		beacon.Parent = part

		local icon = Instance.new("BillboardGui")
		icon.Name = "TargetIcon"
		icon.AlwaysOnTop = true
		icon.LightInfluence = 0
		icon.Size = UDim2.fromOffset(54, 54)
		icon.StudsOffsetWorldSpace = Vector3.new(0, 15, 0)
		icon.Parent = part
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = Config.Icons.Star
		image.ImageColor3 = part.Color
		image.Size = UDim2.fromScale(1, 1)
		image.Parent = icon

		local laneMarker = Instance.new("Part")
		laneMarker.Name = "LaneMarker"
		laneMarker.Anchored = true
		laneMarker.CanCollide = false
		laneMarker.CanQuery = false
		laneMarker.CanTouch = false
		laneMarker.Color = part.Color
		laneMarker.Material = Enum.Material.Neon
		laneMarker.Size = Vector3.new(6, 0.12, 18)
		local markerPosition = part.Position - Vector3.new(0, 2, 0)
		laneMarker.CFrame = CFrame.lookAt(markerPosition, markerPosition + horizontal)
		laneMarker.Transparency = 0.45
		laneMarker.Parent = part
		part:SetAttribute("VisibleTransparency", part.Transparency)
		beacon:SetAttribute("VisibleTransparency", beacon.Transparency)
		laneMarker:SetAttribute("VisibleTransparency", laneMarker.Transparency)
		setTargetVisible(part, false)
	end
	return folder, parts
end

local function steerAction(
	actionName: string,
	inputState: Enum.UserInputState
): Enum.ContextActionResult
	if not activeControl then
		return Enum.ContextActionResult.Pass
	end
	local down = inputState == Enum.UserInputState.Begin or inputState == Enum.UserInputState.Change
	if actionName == "PumpkinSteerLeft" then
		activeControl.left = down
	else
		activeControl.right = down
	end
	return Enum.ContextActionResult.Sink
end

local function bindSteering()
	ContextActionService:BindAction(
		"PumpkinSteerLeft",
		steerAction,
		true,
		Enum.KeyCode.A,
		Enum.KeyCode.Left,
		Enum.KeyCode.DPadLeft
	)
	ContextActionService:BindAction(
		"PumpkinSteerRight",
		steerAction,
		true,
		Enum.KeyCode.D,
		Enum.KeyCode.Right,
		Enum.KeyCode.DPadRight
	)
	ContextActionService:SetTitle("PumpkinSteerLeft", "<")
	ContextActionService:SetTitle("PumpkinSteerRight", ">")
	ContextActionService:SetPosition("PumpkinSteerLeft", UDim2.new(0, 16, 1, -88))
	ContextActionService:SetPosition("PumpkinSteerRight", UDim2.new(1, -88, 1, -88))
	for _, actionName in { "PumpkinSteerLeft", "PumpkinSteerRight" } do
		local button = ContextActionService:GetButton(actionName)
		if button then
			button.Size = UDim2.fromOffset(72, 72)
		end
	end
end

local function unbindSteering()
	ContextActionService:UnbindAction("PumpkinSteerLeft")
	ContextActionService:UnbindAction("PumpkinSteerRight")
end

UserInputService.InputChanged:Connect(function(input: InputObject)
	if activeControl and input.KeyCode == Enum.KeyCode.Thumbstick1 then
		activeControl.thumbstick = input.Position.X
	end
end)

rollControl.OnClientEvent:Connect(
	function(action: string, token: number, value: number, detail: any)
		if action == "Complete" then
			completedResults[token] = { wins = value, pickups = tonumber(detail) or 0 }
		elseif action == "PickupAccepted" and activeControl and activeControl.token == token then
			local part = activeControl.targetParts[value]
			if part then
				setTargetVisible(part, false)
			end
			if detail == "SpeedPad" then
				activeControl.speedBoostUntil = os.clock() + Config.RideSpeedPadSeconds
				activeControl.combo += 1
				showCombo(activeControl.combo)
			end
			activeControl.pickups += 1
		end
	end
)

local function playRoll(
	userId: number,
	zoneName: string,
	size: number,
	wallsBroken: number,
	distance: number,
	wins: number,
	_duration: number,
	physicalCount: number,
	bonusWalls: number,
	token: number,
	seed: number,
	startedAt: number
)
	local winsBefore = (player:GetAttribute("Wins") :: number?) or 0
	local start = findPart("ZoneStart_" .. zoneName)
	local track = workspace:FindFirstChild("Track_" .. zoneName, true)
	if not start or not track then
		return
	end

	local diameter = Config.PumpkinBaseDiameter * Grow.pumpkinScale(size)
	local physicalDuration = Ride.physicalDuration(size)
	local bonusDuration = Ride.bonusDuration(bonusWalls)
	local bonusDistance = bonusWalls * Config.WallSpacing
	local physicalDistance = math.max(0, distance - bonusDistance)
	local pumpkin = workspace:WaitForChild("RollingPumpkin_" .. userId, 3)
	if not pumpkin or not pumpkin:IsA("BasePart") then
		return
	end

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
	local targetFolder: Folder? = nil
	local controlConnection: RBXScriptConnection? = nil
	local shakeUntil = 0
	local shakeMagnitude = 0
	local hitStopUntil = 0
	local heldCamera: CFrame? = nil
	if isLocalRoll and camera then
		local folder, targetParts =
			createBonusTargets(start, physicalDistance, physicalDuration, seed)
		targetFolder = folder
		activeControl = {
			token = token,
			lane = 0,
			left = false,
			right = false,
			thumbstick = 0,
			targets = Ride.layout(seed, physicalDuration),
			targetParts = targetParts,
			reported = {},
			revealed = {},
			speedBoostUntil = 0,
			pickups = 0,
			combo = 0,
		}
		bindSteering()
		local framing = CameraFraming.compute(diameter, true)
		local smoothDistance = framing.distance
		local smoothHeight = framing.height
		local distanceVelocity = 0
		local heightVelocity = 0
		camera.CameraType = Enum.CameraType.Scriptable
		local lastControlUpdate = os.clock()
		local lastSend = 0
		controlConnection = RunService.RenderStepped:Connect(function(deltaTime)
			if not activeControl or activeControl.token ~= token then
				return
			end
			local keyAxis = (if activeControl.right then 1 else 0)
				- (if activeControl.left then 1 else 0)
			local axis = if math.abs(activeControl.thumbstick) > 0.12
				then activeControl.thumbstick
				else keyAxis
			activeControl.lane =
				math.clamp(activeControl.lane + axis * Config.RideSteerSpeed * deltaTime, -1, 1)
			local now = os.clock()
			if
				now - lastSend >= 0.08 and (math.abs(axis) > 0 or now - lastControlUpdate >= 0.25)
			then
				lastSend = now
				lastControlUpdate = now
				rollControl:FireServer("Steer", token, activeControl.lane)
			end
			local elapsed = workspace:GetServerTimeNow() - startedAt
			for _, target in activeControl.targets do
				if not activeControl.revealed[target.id] and elapsed >= target.time - 2 then
					activeControl.revealed[target.id] = true
					local part = activeControl.targetParts[target.id]
					if part then
						setTargetVisible(part, true)
					end
				end
				if
					not activeControl.reported[target.id]
					and math.abs(elapsed - target.time) <= Config.RidePickupTimeTolerance
					and math.abs(activeControl.lane - target.lane)
						<= Config.RidePickupLaneTolerance
				then
					activeControl.reported[target.id] = true
					rollControl:FireServer("Pickup", token, target.id)
				end
			end
		end)
		cameraConnection = RunService.RenderStepped:Connect(function(deltaTime)
			if os.clock() < hitStopUntil and heldCamera then
				camera.CFrame = heldCamera
				return
			end
			smoothDistance, distanceVelocity = CameraFraming.springStep(
				smoothDistance,
				distanceVelocity,
				framing.distance,
				deltaTime
			)
			smoothHeight, heightVelocity =
				CameraFraming.springStep(smoothHeight, heightVelocity, framing.height, deltaTime)
			local behind = -start.CFrame.LookVector * smoothDistance
				+ Vector3.new(0, smoothHeight, 0)
			local shake = Vector3.zero
			if os.clock() < shakeUntil then
				shake = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shakeMagnitude
			end
			camera.CFrame = CFrame.lookAt(
				pumpkin.Position + behind + shake,
				pumpkin.Position + Vector3.new(0, 2, 0)
			)
			heldCamera = camera.CFrame
			local rideProgress =
				Ride.progress(workspace:GetServerTimeNow() - startedAt, physicalDuration)
			local speedFov = 8 + rideProgress * 10
			if activeControl and os.clock() < activeControl.speedBoostUntil then
				speedFov += 8
			end
			camera.FieldOfView = previousFov + speedFov
		end)
		TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = previousFov + 8 }):Play()
		distanceMeter.Visible = true
		steerHint.Text = if UserInputService.KeyboardEnabled
			then "STEER  " .. utf8.char(0x25C0) .. "  " .. utf8.char(0x25B6) .. "\nA  /  D"
			else "STEER  " .. utf8.char(0x25C0) .. "  " .. utf8.char(0x25B6)
		steerHint.Visible = true
		task.delay(Config.RideGentleStartSeconds, function()
			if activeControl and activeControl.token == token then
				steerHint.Visible = false
			end
		end)
		task.spawn(function()
			while pumpkin.Parent do
				local elapsed = workspace:GetServerTimeNow() - startedAt
				local traveled = Ride.distanceAtTime(
					elapsed,
					physicalDuration,
					physicalDistance,
					bonusDuration,
					bonusDistance
				)
				distanceMeter.Text = string.format("%d m", math.floor(traveled + 0.5))
				if traveled >= distance then
					break
				end
				RunService.RenderStepped:Wait()
			end
		end)
	end

	local reachedWalls = math.max(1, math.floor(distance / Config.WallSpacing + 0.5))
	local physicalReached = math.min(reachedWalls, physicalCount)
	local winsPerWall = math.floor(wins / math.max(1, wallsBroken))
	local displayedWallWins = 0
	for wallIndex = 1, physicalReached do
		local wall = track:FindFirstChild("Wall_" .. wallIndex, true)
		if not wall or not wall:IsA("BasePart") then
			break
		end
		local wallProgress =
			math.clamp(wallIndex * Config.WallSpacing / math.max(1, physicalDistance), 0, 1)
		local wallTime = startedAt + Ride.elapsedForProgress(wallProgress, physicalDuration)
		while pumpkin.Parent and workspace:GetServerTimeNow() < wallTime do
			RunService.RenderStepped:Wait()
		end
		if wallIndex <= wallsBroken then
			wall.LocalTransparencyModifier = 1
			burstDebris(wall.Position, wallIndex)
			if player:GetAttribute("SFXEnabled") ~= false then
				smashSound.PlaybackSpeed = math.min(1.55, 0.82 + wallIndex * 0.08)
				smashSound:Play()
			end
			if isLocalRoll then
				hitStopUntil = os.clock() + 0.05
				shakeUntil = os.clock() + 0.18
				shakeMagnitude = math.min(0.6, 0.2 + wallIndex * 0.04)
				if activeControl and activeControl.token == token then
					activeControl.combo += 1
					showCombo(activeControl.combo)
				else
					showCombo(wallIndex)
				end
				showWallWins(wall, winsPerWall)
				local projected = if camera
					then camera:WorldToViewportPoint(wall.Position)
					else Vector3.new(
						effectGui.AbsoluteSize.X * 0.5,
						effectGui.AbsoluteSize.Y * 0.5,
						0
					)
				flyCoins(
					Vector2.new(projected.X, projected.Y),
					winsPerWall,
					winsBefore + displayedWallWins
				)
				displayedWallWins += winsPerWall
			end
			task.delay(0.8, function()
				if wall.Parent then
					wall.LocalTransparencyModifier = 0
				end
			end)
		end
	end

	if bonusWalls > 0 then
		if isLocalRoll then
			bonusSummaryGeneration += 1
			bonusCounter.Visible = true
		end
		for bonusIndex = 1, bonusWalls do
			local bonusTime = startedAt
				+ physicalDuration
				+ bonusDuration * bonusIndex / math.max(1, bonusWalls)
			while pumpkin.Parent and workspace:GetServerTimeNow() < bonusTime do
				RunService.RenderStepped:Wait()
			end
			if isLocalRoll then
				bonusCounter.Text = "BONUS +" .. bonusIndex
				bonusScale.Scale = 0.72
				TweenService:Create(
					bonusScale,
					TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }
				):Play()
				burstBonusParticle()
			end
		end
	end

	if isLocalRoll then
		local resultDeadline = os.clock() + 0.75
		while completedResults[token] == nil and os.clock() < resultDeadline do
			task.wait()
		end
		local completion = completedResults[token] or { wins = wins, pickups = 0 }
		local finalWins = completion.wins
		completedResults[token] = nil
		player:SetAttribute(
			"LastRollSummary",
			string.format(
				"walls=%d bonus=%d pickups=%d wins=%d",
				wallsBroken,
				bonusWalls,
				completion.pickups,
				finalWins
			)
		)
		showWins(finalWins)
		-- Hide the pad's 3D signs while the end toast is up, so the two don't stack
		local hiddenSigns: { BillboardGui } = {}
		if start then
			for _, descendant in start:GetDescendants() do
				if descendant:IsA("BillboardGui") and descendant.Enabled then
					descendant.Enabled = false
					table.insert(hiddenSigns, descendant)
				end
			end
		end
		task.delay(1.6, function()
			for _, sign in hiddenSigns do
				sign.Enabled = true
			end
		end)
		flyCoins(
			Vector2.new(effectGui.AbsoluteSize.X * 0.5, effectGui.AbsoluteSize.Y * 0.5),
			finalWins,
			winsBefore
		)
		distanceMeter.Visible = false
		steerHint.Visible = false
		comboCounter.Visible = false
		if bonusWalls > 0 then
			local summaryGeneration = bonusSummaryGeneration
			task.delay(1.2, function()
				if bonusSummaryGeneration == summaryGeneration then
					bonusCounter.Visible = false
				end
			end)
		else
			bonusCounter.Visible = false
		end
		if camera then
			if cameraConnection then
				cameraConnection:Disconnect()
			end
			if controlConnection then
				controlConnection:Disconnect()
			end
			unbindSteering()
			if activeControl and activeControl.token == token then
				activeControl = nil
			end
			if targetFolder then
				targetFolder:Destroy()
			end
			camera.CameraType = previousType
			camera.CameraSubject = previousSubject
			TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = previousFov }):Play()
			task.delay(0.1, function()
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if not root or not root:IsA("BasePart") then
					return
				end
				local direction =
					Vector3.new(start.CFrame.LookVector.X, 0, start.CFrame.LookVector.Z).Unit
				local returnDiameter =
					Grow.pumpkinVisualDiameter((player:GetAttribute("Size") :: number?) or 0, 5)
				local framing = CameraFraming.compute(returnDiameter, false)
				camera.CFrame = CFrame.lookAt(
					root.Position - direction * framing.distance + Vector3.new(0, framing.height, 0),
					root.Position + Vector3.new(0, 2, 0)
				)
			end)
		end
	end
end

rollPlayback.OnClientEvent:Connect(function(...)
	task.spawn(playRoll, ...)
end)
