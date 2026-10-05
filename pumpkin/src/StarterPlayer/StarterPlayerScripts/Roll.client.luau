--!strict
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
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
local RideSurface = require(Shared:WaitForChild("RideSurface"))
local Style = require(Shared:WaitForChild("Style"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rollPlayback = remotes:WaitForChild("RollPlayback") :: RemoteEvent
local rollControl = remotes:WaitForChild("RollControl") :: RemoteEvent
local sfxGroup = SoundService:FindFirstChild("PumpkinSFX") :: SoundGroup?
if not sfxGroup then
	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "PumpkinSFX"
	sfxGroup.Parent = SoundService
end
local traversalSound = Instance.new("Sound")
traversalSound.Name = "TraversalPop"
traversalSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
traversalSound.Volume = 0.4
traversalSound.PlaybackSpeed = 0.78
traversalSound.SoundGroup = sfxGroup
traversalSound.Parent = playerGui

local function paletteColor(role: string): Color3
	local value = Style.Palette[role]
	return Color3.fromRGB(value.r, value.g, value.b)
end

local ORANGE = paletteColor("orange")
local PURPLE = paletteColor("purple")
local LIME = paletteColor("lime")
local CYAN = paletteColor("cyan")
local MAGENTA = paletteColor("magenta")
local YELLOW = paletteColor("yellow")
local INK = paletteColor("ink")
local WHITE = paletteColor("white")
local TEAL = INK:Lerp(CYAN, 0.18)

local function playPop(scale: UIScale, tierName: string)
	local tier = Style.popTier(tierName, player:GetAttribute("ReducedMotion") == true)
	scale.Scale = tier.startScale
	local contact = TweenService:Create(
		scale,
		TweenInfo.new(tier.contactSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = tier.overshootScale }
	)
	contact:Play()
	contact.Completed:Once(function()
		TweenService:Create(
			scale,
			TweenInfo.new(tier.settleSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end)
end

local effectGui = Instance.new("ScreenGui")
effectGui.Name = "RollEffects"
effectGui.DisplayOrder = 100
effectGui.IgnoreGuiInset = false
effectGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
effectGui.ClipToDeviceSafeArea = true
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

local rideMeterPlate = Instance.new("Frame")
rideMeterPlate.Name = "RideMeterPlate"
rideMeterPlate.BackgroundColor3 = PURPLE
rideMeterPlate.BorderSizePixel = 0
rideMeterPlate.Visible = false
rideMeterPlate.ZIndex = 98
rideMeterPlate.Parent = effectGui
local rideMeterCorner = Instance.new("UICorner")
rideMeterCorner.CornerRadius = UDim.new(0, 12)
rideMeterCorner.Parent = rideMeterPlate
local rideMeterStroke = Instance.new("UIStroke")
rideMeterStroke.Color = INK
rideMeterStroke.Thickness = 3
rideMeterStroke.Parent = rideMeterPlate
local rideMeterGradient = Instance.new("UIGradient")
rideMeterGradient.Color = ColorSequence.new(PURPLE, CYAN)
rideMeterGradient.Rotation = 12
rideMeterGradient.Parent = rideMeterPlate

local distanceMeter = Instance.new("TextLabel")
distanceMeter.Name = "DistanceMeter"
distanceMeter.AnchorPoint = Vector2.new(0.5, 0)
distanceMeter.BackgroundTransparency = 1
distanceMeter.Font = Enum.Font.GothamBlack
distanceMeter.Position = UDim2.new(0.5, 0, 0, 86)
distanceMeter.Size = UDim2.fromOffset(360, 80)
distanceMeter.Text = "SPEED  60 studs/s\nDISTANCE  0"
distanceMeter.TextColor3 = Color3.new(1, 1, 1)
distanceMeter.TextSize = 28
distanceMeter.TextStrokeColor3 = INK
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

local comboBar = Instance.new("Frame")
comboBar.Name = "ComboBar"
comboBar.AnchorPoint = Vector2.new(0.5, 0.5)
comboBar.BackgroundColor3 = TEAL
comboBar.BackgroundTransparency = 0.15
comboBar.BorderSizePixel = 0
comboBar.Position = UDim2.fromScale(0.5, 0.34)
comboBar.Size = UDim2.fromOffset(320, 14)
comboBar.Visible = false
comboBar.ZIndex = 98
comboBar.Parent = effectGui
local comboBarCorner = Instance.new("UICorner")
comboBarCorner.CornerRadius = UDim.new(1, 0)
comboBarCorner.Parent = comboBar
local comboFill = Instance.new("Frame")
comboFill.Name = "Fill"
comboFill.BackgroundColor3 = LIME
comboFill.BorderSizePixel = 0
comboFill.Size = UDim2.fromScale(0, 1)
comboFill.ZIndex = 99
comboFill.Parent = comboBar
local comboFillCorner = Instance.new("UICorner")
comboFillCorner.CornerRadius = UDim.new(1, 0)
comboFillCorner.Parent = comboFill

local hitFlash = Instance.new("Frame")
hitFlash.Name = "HitFlash"
hitFlash.BackgroundColor3 = MAGENTA
hitFlash.BackgroundTransparency = 1
hitFlash.BorderSizePixel = 0
hitFlash.Size = UDim2.fromScale(1, 1)
hitFlash.ZIndex = 90
hitFlash.Parent = effectGui

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
	local layout = HudLayout.compute(effectGui.AbsoluteSize.X, effectGui.AbsoluteSize.Y, "ride")
	local bounds = layout.distanceMeter
	rideMeterPlate.Position = UDim2.fromOffset(bounds.x, bounds.y)
	rideMeterPlate.Size = UDim2.fromOffset(bounds.width, bounds.height)
	distanceMeter.AnchorPoint = Vector2.zero
	distanceMeter.Position = UDim2.fromOffset(bounds.x, bounds.y)
	distanceMeter.Size = UDim2.fromOffset(bounds.width, bounds.height)
	distanceMeter.TextSize = if layout.mobile then 21 else 26
	local toastBounds = layout.reward
	winBurst.AnchorPoint = Vector2.zero
	winBurst.Position = UDim2.fromOffset(toastBounds.x, toastBounds.y)
	winBurst.Size = UDim2.fromOffset(toastBounds.width, toastBounds.height)
	winBurst.TextSize = if layout.mobile then 28 else 36
	bonusCounter.AnchorPoint = Vector2.zero
	bonusCounter.Position = UDim2.fromOffset(toastBounds.x, toastBounds.y + toastBounds.height)
	bonusCounter.Size = UDim2.fromOffset(toastBounds.width, toastBounds.height)
	bonusCounter.TextSize = if layout.mobile then 26 else 34
	local comboBounds = layout.combo
	comboCounter.AnchorPoint = Vector2.zero
	comboCounter.Position = UDim2.fromOffset(comboBounds.x, comboBounds.y)
	comboCounter.Size = UDim2.fromOffset(comboBounds.width, comboBounds.height)
	comboCounter.TextSize = if layout.mobile then 28 else 38
	comboBar.Position = UDim2.fromOffset(
		comboBounds.x + comboBounds.width * 0.5,
		comboBounds.y + comboBounds.height
	)
	comboBar.Size = UDim2.fromOffset(math.min(320, comboBounds.width), 14)
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

local function burstBonusParticle(color: Color3?)
	bonusParticleCursor = bonusParticleCursor % #bonusParticlePool + 1
	local particle = bonusParticlePool[bonusParticleCursor]
	local generation = (particle:GetAttribute("Generation") :: number? or 0) + 1
	particle:SetAttribute("Generation", generation)
	particle.BackgroundColor3 = color or ORANGE
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
local activeControl: any = nil
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
	playPop(winScale, "reward")
	TweenService:Create(
		winBurst,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.2),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	):Play()
end

local function showCombo(combo: number, eventText: string?)
	local text = Ride.comboText(combo)
	comboCounter.Text = text or ""
	comboCounter.Visible = text ~= nil
	comboBar.Visible = text ~= nil
	comboFill.Size = UDim2.fromScale(
		math.clamp((Ride.comboMultiplier(combo) - 1) / (Config.RideComboCap - 1), 0, 1),
		1
	)
	playPop(comboScale, "micro")
	if eventText then
		comboCounter.Text = eventText .. "\n" .. (text or "")
	end
end

local function showComboLost()
	comboCounter.Text = "COMBO LOST"
	comboCounter.TextColor3 = MAGENTA
	comboCounter.Visible = true
	comboBar.Visible = true
	comboFill.Size = UDim2.fromScale(0, 1)
	hitFlash.BackgroundTransparency = 0.68
	TweenService:Create(hitFlash, TweenInfo.new(0.24), { BackgroundTransparency = 1 }):Play()
	task.delay(0.7, function()
		comboCounter.TextColor3 = LIME
		if activeControl and activeControl.combo == 0 then
			comboCounter.Visible = false
			comboBar.Visible = false
		end
	end)
end

local function findPart(name: string): BasePart?
	local found = workspace:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

local function rideWorldSample(start: BasePart, distance: number, lane: number): (Vector3, Vector3)
	local sample = Ride.pathSample(distance)
	local horizontal = Vector3.new(start.CFrame.LookVector.X, 0, start.CFrame.LookVector.Z).Unit
	local originalRight = Vector3.new(-horizontal.Z, 0, horizontal.X)
	local center = start.Position
		+ horizontal * sample.forward
		+ Vector3.yAxis * sample.height
		+ originalRight * sample.lateral
	local tangent = (
		horizontal * sample.forwardTangent
		+ Vector3.yAxis * sample.heightTangent
		+ originalRight * sample.lateralTangent
	).Unit
	local right = tangent:Cross(Vector3.yAxis)
	if right.Magnitude < 1e-4 then
		right = originalRight
	else
		right = right.Unit
	end
	return center + right * (lane * Config.RideLaneStuds), tangent
end

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
		elseif
			descendant:IsA("BillboardGui")
			or descendant:IsA("Beam")
			or descendant:IsA("Highlight")
		then
			descendant.Enabled = visible
		end
	end
end

local function createBonusTargets(
	start: BasePart,
	_physicalDistance: number,
	physicalDuration: number,
	seed: number
): (Folder, { [number]: BasePart })
	local folder = Instance.new("Folder")
	folder.Name = "RideBonusTargets"
	folder.Parent = workspace
	local parts = {}
	for _, target in Ride.layout(seed, physicalDuration) do
		local part = Instance.new("Part")
		part.Name = target.kind .. "_" .. target.id
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.SmoothPlastic
		local targetPosition = rideWorldSample(
			start,
			Ride.baseDistanceAtTime(target.time, physicalDuration),
			target.lane
		)
		part.Position = targetPosition + Vector3.new(0, 2, 0)
		if target.kind == "Candy" then
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(3.5, 3.5, 3.5)
			part.Color = MAGENTA
		elseif target.kind == "GoldPumpkin" then
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(5, 4.1, 5)
			part.Color = YELLOW
			part.Material = Enum.Material.Neon
		else
			part.Size = Vector3.new(8, 0.6, 7)
			part.Color = LIME
			part.Material = Enum.Material.Neon
		end
		part.Parent = folder
		parts[target.id] = part
		local outline = Instance.new("Highlight")
		outline.Name = "PickupSeparation"
		outline.Adornee = part
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.FillTransparency = 0.86
		outline.OutlineColor = INK
		outline.OutlineTransparency = 0.08
		outline.Parent = part

		local beaconBottom = Instance.new("Attachment")
		beaconBottom.Name = "BeaconBottom"
		beaconBottom.Position = Vector3.new(0, 1, 0)
		beaconBottom.Parent = part
		local beaconTop = Instance.new("Attachment")
		beaconTop.Name = "BeaconTop"
		beaconTop.Position = Vector3.new(0, 16, 0)
		beaconTop.Parent = part
		local beacon = Instance.new("Beam")
		beacon.Name = "TaperedBeacon"
		beacon.Attachment0 = beaconBottom
		beacon.Attachment1 = beaconTop
		beacon.Brightness = 2
		beacon.Color = ColorSequence.new(part.Color, WHITE)
		beacon.FaceCamera = true
		beacon.LightEmission = 0.85
		beacon.Transparency = NumberSequence.new(0.18, 0.7)
		beacon.Width0 = if target.kind == "SpeedPad" then 5 else 2.8
		beacon.Width1 = 0.25
		beacon.Parent = part

		local icon = Instance.new("BillboardGui")
		icon.Name = "TargetIcon"
		icon.AlwaysOnTop = true
		icon.LightInfluence = 0
		icon.Size = UDim2.fromOffset(54, 54)
		icon.StudsOffsetWorldSpace = Vector3.new(0, 15, 0)
		icon.Parent = part
		local iconLabel = Instance.new("TextLabel")
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.GothamBlack
		iconLabel.Size = UDim2.fromScale(1, 1)
		iconLabel.Text = if target.kind == "Candy"
			then "CANDY"
			elseif target.kind == "GoldPumpkin" then "GOLD"
			else "BOOST"
		iconLabel.TextColor3 = WHITE
		iconLabel.TextSize = 18
		iconLabel.TextStrokeColor3 = INK
		iconLabel.TextStrokeTransparency = 0
		iconLabel.Parent = icon

		local laneMarker = Instance.new("Part")
		laneMarker.Name = "LaneMarker"
		laneMarker.Anchored = true
		laneMarker.CanCollide = false
		laneMarker.CanQuery = false
		laneMarker.CanTouch = false
		laneMarker.Color = part.Color
		laneMarker.Material = Enum.Material.Neon
		laneMarker.Size = if target.kind == "SpeedPad"
			then Vector3.new(8, 0.12, 18)
			else Vector3.new(0.12, 7, 7)
		laneMarker.Shape = if target.kind == "SpeedPad"
			then Enum.PartType.Block
			else Enum.PartType.Cylinder
		local markerPosition = part.Position - Vector3.new(0, 2, 0)
		local _, targetTangent = rideWorldSample(
			start,
			Ride.baseDistanceAtTime(target.time, physicalDuration),
			target.lane
		)
		laneMarker.CFrame = CFrame.lookAt(markerPosition, markerPosition + targetTangent)
			* (if target.kind == "SpeedPad" then CFrame.new() else CFrame.Angles(0, 0, math.pi / 2))
		laneMarker.Transparency = 0.45
		laneMarker.Parent = part
		part:SetAttribute("VisibleTransparency", part.Transparency)
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
	if UserInputService.TouchEnabled and inputState == Enum.UserInputState.Begin then
		local direction = if actionName == "PumpkinSteerLeft" then -1 else 1
		activeControl.lane = Ride.snapLane(activeControl.lane, direction)
		rollControl:FireServer("Steer", activeControl.token, activeControl.lane)
		return Enum.ContextActionResult.Sink
	end
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

rollControl.OnClientEvent:Connect(function(action: string, token: number, value: any, detail: any)
	if action == "Complete" then
		completedResults[token] = { wins = tonumber(value) or 0, pickups = tonumber(detail) or 0 }
	elseif action == "Rejected" then
		bonusCounter.Text = tostring(value)
		bonusCounter.TextColor3 = MAGENTA
		bonusCounter.Visible = true
		playPop(bonusScale, "reward")
		task.delay(1.2, function()
			if not activeControl then
				bonusCounter.Visible = false
			end
		end)
	elseif action == "Bounce" then
		bonusCounter.Text = "BOING!"
		bonusCounter.TextColor3 = LIME
		bonusCounter.Visible = true
		playPop(bonusScale, "micro")
		for _ = 1, 5 do
			burstBonusParticle(LIME)
		end
		local bouncePad = workspace:FindFirstChild("PlazaBouncePad", true)
		local puff = if bouncePad then bouncePad:FindFirstChild("LandingPuff", true) else nil
		if puff and puff:IsA("ParticleEmitter") then
			puff:Emit(if player:GetAttribute("ReducedEffects") == true then 5 else 12)
		end
		if player:GetAttribute("SFXEnabled") ~= false then
			traversalSound:Play()
		end
		task.delay(0.6, function()
			if not activeControl then
				bonusCounter.Visible = false
			end
		end)
	elseif action == "BankPending" then
		bonusCounter.Text = "PENDING  +" .. tostring(value) .. " WINS"
		bonusCounter.TextColor3 = YELLOW
		bonusCounter.Visible = true
		playPop(bonusScale, "reward")
	elseif action == "FinishBeat" and activeControl and activeControl.token == token then
		bonusCounter.Text = "CASH OUT!"
		bonusCounter.TextColor3 = LIME
		bonusCounter.Visible = true
		playPop(bonusScale, "rare")
		for _ = 1, 6 do
			burstBonusParticle(LIME)
		end
	elseif action == "PendingUpdate" and activeControl and activeControl.token == token then
		bonusCounter.Text = "BANK  " .. tostring(value) .. " WINS"
		bonusCounter.TextColor3 = YELLOW
		bonusCounter.Visible = true
		playPop(bonusScale, "micro")
	elseif action == "PickupAccepted" and activeControl and activeControl.token == token then
		local part = activeControl.targetParts[value]
		if part then
			setTargetVisible(part, false)
		end
		if detail == "SpeedPad" then
			activeControl.speedBoostUntil = os.clock() + Config.RideSpeedPadSeconds
		end
		activeControl.pickups += 1
		bonusCounter.Text = "PICKUP  •  BANK AT FINISH"
		bonusCounter.TextColor3 = YELLOW
		bonusCounter.Visible = true
		playPop(bonusScale, "micro")
	elseif action == "Combo" and activeControl and activeControl.token == token then
		activeControl.combo = value
		showCombo(value, if type(detail) == "string" then detail else nil)
		if activeControl.comboSound and player:GetAttribute("SFXEnabled") ~= false then
			activeControl.comboSound.PlaybackSpeed = math.min(1.45, 0.92 + value * 0.05)
			activeControl.comboSound:Play()
		end
	elseif action == "Dodge" and activeControl and activeControl.token == token then
		activeControl.combo = tonumber(detail) or activeControl.combo
		for _ = 1, 4 do
			burstBonusParticle(LIME)
		end
	elseif action == "ObstacleHit" and activeControl and activeControl.token == token then
		activeControl.combo = 0
		activeControl.lastHitAt = os.clock()
		activeControl.bumpUntil = os.clock() + 0.22
		activeControl.speedLinesPauseUntil = os.clock() + 0.18
		if activeControl.hitSound and player:GetAttribute("SFXEnabled") ~= false then
			activeControl.hitSound:Play()
		end
		showComboLost()
	end
end)

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
	task.spawn(function()
		pcall(player.RequestStreamAroundAsync, player, start.Position, 2)
		local finishPosition = rideWorldSample(start, Config.RideTrackLength, 0)
		pcall(player.RequestStreamAroundAsync, player, finishPosition, 2)
	end)

	local diameter = Config.PumpkinBaseDiameter * Grow.pumpkinScale(size)
	local physicalDuration = Ride.physicalDuration(size)
	local bonusDuration = Ride.bonusDuration(bonusWalls)
	local bonusDistance = bonusWalls * Config.WallSpacing
	local physicalDistance = math.max(0, distance - bonusDistance)
	local surfaces = RideSurface.collect(track)
	local pumpkin = workspace:WaitForChild("RollingPumpkin_" .. userId, 3)
	if not pumpkin or not pumpkin:IsA("BasePart") then
		return
	end
	local pumpkinMesh = pumpkin:FindFirstChildWhichIsA("SpecialMesh")
	local stemWeld = pumpkin:FindFirstChild("RideStemWeld", true)
	local stemLean = 0

	local smashSound = Instance.new("Sound")
	smashSound.Name = "Smash"
	smashSound.SoundId = "rbxasset://sounds/collide.wav"
	smashSound.Volume = 0.75
	smashSound.RollOffMaxDistance = 90
	smashSound.RollOffMinDistance = 8
	smashSound.SoundGroup = sfxGroup
	smashSound.Parent = pumpkin
	local hitSound = Instance.new("Sound")
	hitSound.Name = "ObstacleThud"
	hitSound.SoundId = "rbxasset://sounds/impact_water.mp3"
	hitSound.Volume = 0.7
	hitSound.RollOffMaxDistance = 70
	hitSound.RollOffMinDistance = 8
	hitSound.SoundGroup = sfxGroup
	hitSound.Parent = pumpkin
	local comboSound = Instance.new("Sound")
	comboSound.Name = "ComboRise"
	comboSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	comboSound.Volume = 0.45
	comboSound.SoundGroup = sfxGroup
	comboSound.Parent = pumpkin
	local rollBed = Instance.new("Sound")
	rollBed.Name = "RollingBed"
	rollBed.SoundId = "rbxasset://sounds/impact_water.mp3"
	rollBed.Looped = true
	rollBed.Volume = 0.08
	rollBed.PlaybackSpeed = 0.72
	rollBed.RollOffMaxDistance = 90
	rollBed.SoundGroup = sfxGroup
	rollBed.Parent = pumpkin
	local windBed = Instance.new("Sound")
	windBed.Name = "WindBed"
	windBed.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
	windBed.Looped = true
	windBed.Volume = 0
	windBed.PlaybackSpeed = 0.55
	windBed.RollOffMaxDistance = 110
	windBed.SoundGroup = sfxGroup
	windBed.Parent = pumpkin
	local tunnelFilter = Instance.new("EqualizerSoundEffect")
	tunnelFilter.Name = "TunnelFilter"
	tunnelFilter.HighGain = 0
	tunnelFilter.MidGain = 0
	tunnelFilter.LowGain = 0
	tunnelFilter.Parent = rollBed
	if player:GetAttribute("SFXEnabled") ~= false then
		rollBed:Play()
		windBed:Play()
	end

	local isLocalRoll = userId == player.UserId
	local camera = workspace.CurrentCamera
	local previousSubject = if camera then camera.CameraSubject else nil
	local previousType = if camera then camera.CameraType else Enum.CameraType.Custom
	local previousFov = if camera then camera.FieldOfView else 70
	local cameraConnection: RBXScriptConnection? = nil
	local targetFolder: Folder? = nil
	local occluded: { [BasePart]: number } = {}
	local controlConnection: RBXScriptConnection? = nil
	local shakeUntil = 0
	local shakeMagnitude = 0
	local hitStopUntil = 0
	local heldCamera: CFrame? = nil
	local heldPumpkinPosition = Vector3.zero
	if isLocalRoll and camera then
		pumpkin.LocalTransparencyModifier = 0.35
		TweenService:Create(
			pumpkin,
			TweenInfo.new(Config.RideLatchSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ LocalTransparencyModifier = 0 }
		):Play()
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
			passed = {},
			speedBoostUntil = 0,
			pickups = 0,
			combo = 0,
			lastHitAt = -math.huge,
			traveled = 0,
			measuredSpeed = Config.RideStartSpeed,
			bumpUntil = 0,
			speedLinesPauseUntil = 0,
			hitSound = hitSound,
			comboSound = comboSound,
		}
		local speedAttachment = Instance.new("Attachment")
		speedAttachment.Name = "SpeedLinesAttachment"
		speedAttachment.Parent = pumpkin
		local speedLines = Instance.new("ParticleEmitter")
		speedLines.Name = "SpeedLines"
		speedLines.Color = ColorSequence.new(Color3.new(1, 1, 1), LIME)
		speedLines.LightEmission = 0.8
		speedLines.Lifetime = NumberRange.new(0.12, 0.2)
		speedLines.Rate = 18
		speedLines.Speed = NumberRange.new(16, 26)
		speedLines.SpreadAngle = Vector2.new(12, 12)
		speedLines.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		speedLines.Parent = speedAttachment
		activeControl.speedLines = speedLines
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
			-- Poll the keys too, so steering works even when another binding sinks the CAS action
			local steerRight = activeControl.right
				or UserInputService:IsKeyDown(Enum.KeyCode.D)
				or UserInputService:IsKeyDown(Enum.KeyCode.Right)
			local steerLeft = activeControl.left
				or UserInputService:IsKeyDown(Enum.KeyCode.A)
				or UserInputService:IsKeyDown(Enum.KeyCode.Left)
			local keyAxis = (if steerRight then 1 else 0) - (if steerLeft then 1 else 0)
			local axis = if math.abs(activeControl.thumbstick) > 0.2
				then activeControl.thumbstick
				else keyAxis
			if not UserInputService.TouchEnabled or math.abs(axis) > 0 then
				activeControl.lane =
					math.clamp(activeControl.lane + axis * Config.RideSteerSpeed * deltaTime, -1, 1)
			end
			local laneIndex = math.clamp(math.floor(activeControl.lane + 1.5), 1, 3)
			local dots = { "○", "○", "○" }
			dots[laneIndex] = "●"
			steerHint.Text = "LANE  " .. table.concat(dots, "  ")
			local now = os.clock()
			if
				now - lastSend >= 0.08 and (math.abs(axis) > 0 or now - lastControlUpdate >= 0.25)
			then
				lastSend = now
				lastControlUpdate = now
				rollControl:FireServer("Steer", token, activeControl.lane)
				player:SetAttribute("RideLane", math.floor(activeControl.lane * 100 + 0.5) / 100)
			end
			local elapsed = workspace:GetServerTimeNow() - startedAt
			for _, target in activeControl.targets do
				local targetDistance = Ride.baseDistanceAtTime(target.time, physicalDuration)
				local remaining = targetDistance - activeControl.traveled
				if not activeControl.revealed[target.id] and elapsed >= target.time - 2 then
					activeControl.revealed[target.id] = true
					local part = activeControl.targetParts[target.id]
					if part then
						setTargetVisible(part, true)
					end
				end
				local targetPart = activeControl.targetParts[target.id]
				if
					targetPart
					and activeControl.revealed[target.id]
					and not activeControl.passed[target.id]
				then
					local reactionAlpha = 1
						- math.clamp(remaining / (Config.RideTopSpeed * 2), 0, 1)
					local pulse = 0.5 + 0.5 * math.sin(os.clock() * (5 + reactionAlpha * 9))
					local beacon = targetPart:FindFirstChild("TaperedBeacon")
					if beacon and beacon:IsA("Beam") then
						local baseWidth = if target.kind == "SpeedPad" then 5 else 2.8
						beacon.Width0 = baseWidth * (1 + pulse * 0.18 * reactionAlpha)
					end
					local marker = targetPart:FindFirstChild("LaneMarker")
					if marker and marker:IsA("BasePart") then
						marker.Transparency = 0.5 - pulse * 0.22 * reactionAlpha
					end
					if remaining < -Config.RidePickupClientRadius then
						activeControl.passed[target.id] = true
						setTargetVisible(targetPart, false)
					end
				end
				if
					not activeControl.reported[target.id]
					and math.abs(activeControl.traveled - targetDistance) <= Config.RidePickupClientRadius
					and math.abs(activeControl.lane - target.lane)
						<= Config.RidePickupLaneTolerance
				then
					activeControl.reported[target.id] = true
					rollControl:FireServer("Pickup", token, target.id)
				end
			end
		end)
		local initialDirection = start.CFrame.LookVector.Unit
		local cameraForward = Vector3.new(initialDirection.X, 0, initialDirection.Z).Unit
		local previousPumpkinPosition = pumpkin.Position
		local smoothedFov = previousFov + 8
		local occlusionParams = RaycastParams.new()
		occlusionParams.FilterType = Enum.RaycastFilterType.Exclude
		cameraConnection = RunService.RenderStepped:Connect(function(deltaTime)
			-- Predict the pumpkin locally from the shared ride curve, so the rider sees smooth motion
			-- and their own steering at once instead of the server's replicated steps
			if activeControl and activeControl.token == token then
				local now = os.clock()
				local elapsed = math.max(0, workspace:GetServerTimeNow() - startedAt)
				local speedScale = Ride.speedScaleAfterHit(now - activeControl.lastHitAt)
				local boostScale = if now < activeControl.speedBoostUntil
					then Config.RideSpeedPadMultiplier
					else 1
				local predictedSpeed =
					Ride.speedAtTime(elapsed, physicalDuration, speedScale, boostScale)
				if workspace:GetServerTimeNow() >= startedAt then
					activeControl.traveled = math.min(
						Config.RideTrackLength,
						activeControl.traveled + predictedSpeed * deltaTime
					)
				end
				local nominalPosition, pathTangent =
					rideWorldSample(start, activeControl.traveled, activeControl.lane)
				local radius = pumpkin.Size.X * 0.5
				local position, normal, tangent =
					RideSurface.sample(surfaces, nominalPosition, radius, pathTangent)
				local hopStart = physicalDuration * 0.54
				local hopAlpha = math.clamp((elapsed - hopStart) / 0.65, 0, 1)
				local hop = if hopAlpha > 0 and hopAlpha < 1
					then math.sin(hopAlpha * math.pi) * 1.1
					else 0
				pumpkin.CFrame = CFrame.lookAt(
					position + normal * hop,
					position + normal * hop + tangent,
					normal
				) * CFrame.Angles(
					Ride.axleRotation(activeControl.traveled, radius),
					0,
					math.rad(-activeControl.lane * 8)
				)
				stemLean += (activeControl.lane - stemLean) * (1 - math.exp(-7 * deltaTime))
				if stemWeld and stemWeld:IsA("Weld") then
					stemWeld.C0 = CFrame.new(0, diameter * 0.48, 0)
						* CFrame.Angles(0, 0, math.rad(stemLean * 12))
				end
				if pumpkinMesh then
					local boostStretch = if now < activeControl.speedBoostUntil then 0.08 else 0
					local landingSquash = if hopAlpha >= 0.86 and hopAlpha < 1 then 0.09 else 0
					local base = diameter * Config.PumpkinMeshScale
					pumpkinMesh.Scale = Vector3.new(
						base * (1 + landingSquash),
						base * 0.82 * (1 - landingSquash - boostStretch * 0.35),
						base * (1 + boostStretch)
					)
				end
			end
			if os.clock() < hitStopUntil and heldCamera then
				-- Hold the framing, but keep following the moving pumpkin so a fast smash never pops the distance
				camera.CFrame = heldCamera + (pumpkin.Position - heldPumpkinPosition)
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
			local motion = pumpkin.Position - previousPumpkinPosition
			previousPumpkinPosition = pumpkin.Position
			local measuredSpeed = motion.Magnitude / math.max(deltaTime, 1 / 240)
			if activeControl then
				activeControl.measuredSpeed += (measuredSpeed - activeControl.measuredSpeed) * (1 - math.exp(
					-10 * deltaTime
				))
			end
			local heading = CameraFraming.horizontalHeading(
				motion.X,
				motion.Z,
				cameraForward.X,
				cameraForward.Z
			)
			local measuredForward = Vector3.new(heading.x, 0, heading.z)
			local headingAlpha = 1 - math.exp(-8 * deltaTime)
			cameraForward = cameraForward:Lerp(measuredForward, headingAlpha).Unit
			local behind = -cameraForward * smoothDistance + Vector3.new(0, smoothHeight, 0)
			local shake = Vector3.zero
			if os.clock() < shakeUntil then
				shake = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shakeMagnitude
			end
			if activeControl and os.clock() < activeControl.bumpUntil then
				shake += Vector3.new(0, 0.5, 0)
			end
			camera.CFrame = CFrame.lookAt(
				pumpkin.Position + behind + shake,
				pumpkin.Position
					+ cameraForward * math.min(12, smoothDistance * 0.25)
					+ Vector3.new(0, 2, 0),
				Vector3.yAxis
			)
			heldCamera = camera.CFrame
			heldPumpkinPosition = pumpkin.Position
			-- Fade anything (gate banners, signs) between the camera and the pumpkin
			local blockers: { [BasePart]: boolean } = {}
			local ignore: { Instance } = { pumpkin }
			if player.Character then
				table.insert(ignore, player.Character)
			end
			if targetFolder then
				table.insert(ignore, targetFolder)
			end
			local origin = pumpkin.Position
			local toCamera = camera.CFrame.Position - origin
			for _ = 1, 6 do
				occlusionParams.FilterDescendantsInstances = ignore
				local hit = workspace:Raycast(origin, toCamera, occlusionParams)
				if not hit then
					break
				end
				local part = hit.Instance
				if part:IsA("BasePart") then
					blockers[part] = true
					if occluded[part] == nil then
						occluded[part] = part.LocalTransparencyModifier
					end
					part.LocalTransparencyModifier = 0.85
				end
				table.insert(ignore, part)
			end
			for part in occluded do
				if not blockers[part] then
					if part.Parent then
						part.LocalTransparencyModifier = occluded[part]
					end
					occluded[part] = nil
				end
			end
			local currentSpeed = if activeControl
				then activeControl.measuredSpeed
				else Config.RideStartSpeed
			local speedAlpha = math.clamp(
				(currentSpeed - Config.RideStartSpeed)
					/ (Config.RideTopSpeed - Config.RideStartSpeed),
				0,
				1
			)
			local targetFov = previousFov + 8 + speedAlpha * 10
			smoothedFov += (targetFov - smoothedFov) * (1 - math.exp(-5 * deltaTime))
			camera.FieldOfView = smoothedFov
			rollBed.PlaybackSpeed = 0.72 + speedAlpha * 0.48
			rollBed.Volume = 0.08 + speedAlpha * 0.12
			windBed.PlaybackSpeed = 0.55 + speedAlpha * 0.65
			windBed.Volume = speedAlpha * 0.16
			local inTunnel = activeControl
				and activeControl.traveled >= 850
				and activeControl.traveled <= 1_075
			tunnelFilter.HighGain = if inTunnel then -9 else 0
			tunnelFilter.MidGain = if inTunnel then -3 else 0
			if activeControl and activeControl.speedLines then
				activeControl.speedLines.Enabled = os.clock() >= activeControl.speedLinesPauseUntil
				local maximumRate = if player:GetAttribute("ReducedEffects") == true then 34 else 80
				activeControl.speedLines.Rate = math.floor(18 + speedAlpha * (maximumRate - 18))
				activeControl.speedLines.Speed =
					NumberRange.new(16 + speedAlpha * 18, 26 + speedAlpha * 24)
			end
		end)
		TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = previousFov + 8 }):Play()
		distanceMeter.Visible = true
		rideMeterPlate.Visible = true
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
			while pumpkin.Parent and activeControl and activeControl.token == token do
				distanceMeter.Text = string.format(
					"SPEED  %d studs/s\nDISTANCE  %d",
					math.floor(activeControl.measuredSpeed + 0.5),
					math.floor(activeControl.traveled + 0.5)
				)
				if workspace:GetServerTimeNow() - startedAt >= _duration then
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
		local wallTime = startedAt
			+ Ride.timeAtBaseDistance(wallIndex * Config.WallSpacing, physicalDuration)
		while pumpkin.Parent and workspace:GetServerTimeNow() < wallTime do
			RunService.RenderStepped:Wait()
		end
		if wallIndex <= wallsBroken then
			wall.LocalTransparencyModifier = 1
			burstDebris(wall.Position, wallIndex)
			if player:GetAttribute("SFXEnabled") ~= false then
				local speedAccent = if activeControl
					then math.clamp(activeControl.measuredSpeed / Config.RideTopSpeed, 0, 1) * 0.18
					else 0
				smashSound.PlaybackSpeed = math.min(
					1.55,
					0.82
						+ wallIndex * 0.05
						+ speedAccent
						+ (if activeControl then activeControl.combo else 0) * 0.015
				)
				smashSound:Play()
			end
			if isLocalRoll then
				hitStopUntil = os.clock() + 0.05
				shakeUntil = os.clock() + 0.18
				shakeMagnitude = math.min(0.6, 0.2 + wallIndex * 0.04)
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
				playPop(bonusScale, "micro")
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
		rollBed:Stop()
		windBed:Stop()
		if player:GetAttribute("SFXEnabled") ~= false then
			comboSound.PlaybackSpeed = 1.35
			comboSound:Play()
		end
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
		rideMeterPlate.Visible = false
		steerHint.Visible = false
		comboCounter.Visible = false
		comboBar.Visible = false
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
			for part in occluded do
				if part.Parent then
					part.LocalTransparencyModifier = occluded[part]
				end
			end
			table.clear(occluded)
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
