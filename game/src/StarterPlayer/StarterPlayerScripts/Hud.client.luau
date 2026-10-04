--!strict
-- The whole HUD, built in code so it lives in files. Reads ReplicatedStorage.State.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Monetization = require(ReplicatedStorage.Shared.Monetization)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local ProfileSchema = require(ReplicatedStorage.Shared.ProfileSchema)
local Goals = require(ReplicatedStorage.Shared.Goals)
local Theme = require(ReplicatedStorage.Shared.Theme)
local WaveRewards = require(ReplicatedStorage.Shared.WaveRewards)
local LevelUp = require(ReplicatedStorage.Shared.LevelUp)
local Daily = require(ReplicatedStorage.Shared.Daily)
local Quests = require(ReplicatedStorage.Shared.Quests)
local Kits = require(ReplicatedStorage.Shared.Kits)
local Tutorial = require(ReplicatedStorage.Shared.Tutorial)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local Settings = require(ReplicatedStorage.Shared.Settings)
local WaveTable = require(ReplicatedStorage.Shared.WaveTable)
local HudLayout = require(ReplicatedStorage.Shared.HudLayout)
local DeathFlow = require(ReplicatedStorage.Shared.DeathFlow)
local UiTheme = require(ReplicatedStorage.Shared.UiTheme)
local Onboarding = require(ReplicatedStorage.Shared.Onboarding)
local CardStyle = require(ReplicatedStorage.Shared.CardStyle)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local State = ReplicatedStorage:WaitForChild("State")
local enemiesFolder = workspace:WaitForChild("Enemies")
local StatsChanged = Remotes.StatsChanged :: RemoteEvent
local GameOver = Remotes.GameOver :: RemoteEvent
local PlayAgain = Remotes.PlayAgain :: RemoteEvent
local Toast = Remotes.Toast :: RemoteEvent
local CrateResult = Remotes.CrateResult :: RemoteEvent
local BuyUpgrade = Remotes.BuyUpgrade :: RemoteFunction
local EquipWeapon = Remotes.EquipWeapon :: RemoteEvent
local Prompt = Remotes.Prompt :: RemoteEvent
local Evolve = Remotes.Evolve :: RemoteFunction
local BuyPerk = Remotes.BuyPerk :: RemoteFunction
local ChooseKit = Remotes.ChooseKit :: RemoteFunction
local GemCrate = Remotes.GemCrate :: RemoteFunction
local PickReward = Remotes.PickReward :: RemoteFunction
local UpdateSettings = Remotes.UpdateSettings :: RemoteEvent

local function stateValue(name: string): any
	return (State:WaitForChild(name) :: any).Value
end
local function onState(name: string, fn: (any) -> ())
	local v = State:WaitForChild(name) :: any
	v.Changed:Connect(fn)
	fn(v.Value)
end

local WHITE = ClientFX.c3(UiTheme.Colors.Text)
local PANEL = ClientFX.c3(UiTheme.Colors.Panel)
local BUTTON = ClientFX.c3(UiTheme.Colors.Button)
local OK = ClientFX.c3(UiTheme.Colors.Success)
local BAD = ClientFX.c3(UiTheme.Colors.Danger)
local GREY = ClientFX.c3(UiTheme.Colors.Disabled) -- a button you cannot afford yet
local finalHud = {}
finalHud.AnimeEffects = require(script.Parent:WaitForChild("AnimeEffects"))

local screen = Instance.new("ScreenGui")
screen.Name = "Hud"
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screen.Parent = gui

-- Panels remain visible, but only actual buttons claim input. This keeps firing responsive
-- when the pointer happens to be over a HUD frame.
local function letCombatClicksThrough(descendant: Instance)
	if descendant:IsA("GuiObject") and not descendant:IsA("GuiButton") then
		descendant.Active = false
	end
end
screen.DescendantAdded:Connect(letCombatClicksThrough)
for _, descendant in screen:GetDescendants() do
	letCombatClicksThrough(descendant)
end

local platform: HudLayout.Platform = if UserInputService.TouchEnabled
	then "touch"
	else if UserInputService.GamepadEnabled then "gamepad" else "keyboard"
local camera = workspace.CurrentCamera
local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720) -- placeholder
local currentScale = HudLayout.scaleFor(viewport.X, viewport.Y, platform)
local hudScale = UiKit.ScreenScale(screen)
local managedButtons: { { Button: TextButton, BaseHeight: number } } = {}

local function resizeManagedButtons()
	for _, managed in managedButtons do
		local size = managed.Button.Size
		managed.Button.Size = UDim2.new(
			size.X.Scale,
			size.X.Offset,
			size.Y.Scale,
			math.max(managed.BaseHeight, HudLayout.buttonHeightFor(currentScale, platform))
		)
	end
end

local function text(
	parent: Instance,
	name: string,
	pos: UDim2,
	size: UDim2,
	str: string,
	textSize: number
): TextLabel
	return UiKit.Label(parent, name, pos, size, str, textSize)
end

local function button(parent: Instance, str: string, size: UDim2): TextButton
	local b = UiKit.Button(parent, str, size)
	if size.Y.Scale == 0 then
		table.insert(managedButtons, { Button = b, BaseHeight = size.Y.Offset })
		resizeManagedButtons()
	end
	return b
end

local function flashButton(b: TextButton, ok: boolean)
	b.BackgroundColor3 = if ok then OK else BAD
	task.delay(0.25, function()
		b.BackgroundColor3 = BUTTON
	end)
end

-- Low-HP vignette + hurt flash (four edge frames with gradients)
local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundTransparency = 1
vignette.Visible = false
vignette.ZIndex = 0
vignette.Parent = screen
for _, side in { "Top", "Bottom", "Left", "Right" } do
	local f = Instance.new("Frame")
	f.BackgroundColor3 = ClientFX.c3(Theme.Goo)
	f.BorderSizePixel = 0
	if side == "Top" then
		f.Size = UDim2.new(1, 0, 0.22, 0)
	elseif side == "Bottom" then
		f.Size = UDim2.new(1, 0, 0.22, 0)
		f.Position = UDim2.new(0, 0, 0.78, 0)
	elseif side == "Left" then
		f.Size = UDim2.new(0.18, 0, 1, 0)
	else
		f.Size = UDim2.new(0.18, 0, 1, 0)
		f.Position = UDim2.new(0.82, 0, 0, 0)
	end
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new(
		if side == "Top" or side == "Left" then 0.45 else 1,
		if side == "Top" or side == "Left" then 1 else 0.45
	)
	g.Rotation = if side == "Top" or side == "Bottom" then 90 else 0
	g.Parent = f
	f.Parent = vignette
end

-- A short red arrow points toward the closest attacker whenever health drops.
finalHud.HitDirection =
	text(screen, "HitDirection", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(48, 48), "^", 42)
finalHud.HitDirection.AnchorPoint = Vector2.new(0.5, 0.5)
finalHud.HitDirection.TextColor3 = ClientFX.c3(Theme.Telegraph)
finalHud.HitDirection.TextStrokeTransparency = 0
finalHud.HitDirection.Visible = false
finalHud.HitDirection.ZIndex = 5
finalHud.HitDirectionToken = 0

function finalHud.closestEnemyPosition(from: Vector3): Vector3?
	local enemies = workspace:FindFirstChild("Enemies")
	local closest: Vector3? = nil
	local closestDistance = math.huge
	if not enemies then
		return nil
	end
	for _, child in enemies:GetChildren() do
		local root = if child:IsA("Model") then child.PrimaryPart else nil
		if root then
			local distance = (root.Position - from).Magnitude
			if distance < closestDistance then
				closest = root.Position
				closestDistance = distance
			end
		end
	end
	return closest
end

function finalHud.showHitDirection(playerPosition: Vector3)
	finalHud.HitDirectionToken += 1
	local token = finalHud.HitDirectionToken
	local source = finalHud.closestEnemyPosition(playerPosition)
	local activeCamera = workspace.CurrentCamera
	local angle = 0
	if source and activeCamera then
		local localDirection = activeCamera.CFrame:VectorToObjectSpace(source - playerPosition)
		angle = math.deg(math.atan2(localDirection.X, -localDirection.Z))
	end
	local radians = math.rad(angle)
	local radius = math.min(viewport.X, viewport.Y) * 0.18 / currentScale
	finalHud.HitDirection.Position =
		UDim2.new(0.5, math.sin(radians) * radius, 0.5, -math.cos(radians) * radius)
	finalHud.HitDirection.Rotation = angle
	finalHud.HitDirection.TextTransparency = 0
	finalHud.HitDirection.Visible = true
	task.delay(0.35, function()
		if token ~= finalHud.HitDirectionToken then
			return
		end
		TweenService:Create(finalHud.HitDirection, TweenInfo.new(0.2), { TextTransparency = 1 })
			:Play()
		task.delay(0.2, function()
			if token == finalHud.HitDirectionToken then
				finalHud.HitDirection.Visible = false
			end
		end)
	end)
end

-- Top build status: level and wave share one centred row below the edge-to-edge XP bar.
finalHud.LevelLabel = text(screen, "Level", UDim2.new(), UDim2.new(), "LV 0", 22)
finalHud.LevelLabel.TextXAlignment = Enum.TextXAlignment.Right
local waveLabel = text(screen, "Wave", UDim2.new(), UDim2.new(), "", 22)
waveLabel.TextXAlignment = Enum.TextXAlignment.Left
local bossChipLabel =
	text(screen, "BossChip", UDim2.new(0.5, -100, 0, 42), UDim2.new(0, 200, 0, 18), "", 13)
bossChipLabel.TextColor3 = ClientFX.c3(Theme.SignalOrange)
local phaseLabel =
	text(screen, "Phase", UDim2.new(0.5, -200, 0, 60), UDim2.new(0, 400, 0, 22), "", 18)
phaseLabel.TextColor3 = ClientFX.c3(Theme.Text)
local mutationLabel =
	text(screen, "Mutation", UDim2.new(0.5, -240, 0, 82), UDim2.new(0, 480, 0, 18), "", 14)
mutationLabel.TextColor3 = ClientFX.c3(Theme.Loot)

-- Wave progress becomes boss health while a boss is alive.
local bossBar = UiKit.Bar(screen, "WaveProgress", UDim2.new(0, 480, 0, 22), Theme.Telegraph)
local bossFrame = bossBar.Frame
bossFrame.Position = UDim2.new(0.5, -240, 0, 106)
bossFrame.Visible = true
local bossFill = bossBar.Fill
local bossLabel = bossBar.Label
bossLabel.TextSize = 12

finalHud.BossUi = require(script.Parent:WaitForChild("BossBar")).new(
	screen,
	bossFrame,
	State,
	Remotes.BossIntro :: RemoteEvent
)

-- Currencies remain as one readable icon column on the left.
finalHud.CurrencyFrame = UiKit.Panel(screen, "Currencies")
finalHud.CurrencyFrame.Name = "Currencies"
finalHud.CurrencyFrame.Visible = true
finalHud.CoinsLabel = text(
	finalHud.CurrencyFrame,
	"Coins",
	UDim2.fromScale(0, 0),
	UDim2.fromScale(1, 0.5),
	"●  0",
	18
)
finalHud.CoinsLabel.TextColor3 = ClientFX.c3(Theme.Coin)
finalHud.GemsLabel = text(
	finalHud.CurrencyFrame,
	"Gems",
	UDim2.fromScale(0, 0.5),
	UDim2.fromScale(1, 0.5),
	"◆  0",
	18
)
finalHud.GemsLabel.TextColor3 = ClientFX.c3(Theme.NeonTeal)

-- Bottom-centre: HP. Detailed run stats live behind this bar.
local healthBar = UiKit.Bar(screen, "Health", UDim2.new(0, 260, 0, 18), UiTheme.Colors.Success)
local hpBack = healthBar.Frame
hpBack.Position = UDim2.new(0, 12, 1, -80)
local hpFill = healthBar.Fill
local hpText = healthBar.Label
finalHud.StatsToggle = Instance.new("TextButton")
finalHud.StatsToggle.Name = "OpenStats"
finalHud.StatsToggle.Size = UDim2.fromScale(1, 1)
finalHud.StatsToggle.BackgroundTransparency = 1
finalHud.StatsToggle.Text = ""
finalHud.StatsToggle.ZIndex = hpText.ZIndex + 1
finalHud.StatsToggle.Parent = hpBack

finalHud.AbilityUi = (function()
	local tray = Instance.new("Frame")
	tray.Name = "Abilities"
	tray.Size = UDim2.fromOffset(116, 52)
	tray.Position = UDim2.new(0, 282, 1, -98)
	tray.BackgroundTransparency = 1
	tray.Parent = screen
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 12)
	layout.Parent = tray

	local function makeButton(name: string): (TextButton, UIStroke, TextLabel)
		local b = UiKit.Button(tray, name, UDim2.fromOffset(52, 52))
		b.Name = name
		b.BackgroundColor3 = PANEL
		b.TextColor3 = WHITE
		b.TextSize = 11
		b.Font = UiKit.Fonts.Body
		b.TextWrapped = true
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = b
		local ring = Instance.new("UIStroke")
		ring.Name = "CooldownRing"
		ring.Thickness = 4
		ring.Color = OK
		ring.Parent = b
		local cooldown = text(b, "Cooldown", UDim2.new(), UDim2.fromScale(1, 1), "", 18)
		cooldown.Font = UiKit.Fonts.Number
		cooldown.ZIndex = b.ZIndex + 1
		return b, ring, cooldown
	end

	local dash = makeButton("Dash")
	local signature, ring, cooldown = makeButton("Signature")
	dash.Text = "DASH\nQ"
	signature.Text = "ABILITY\nE"
	cooldown.Text = ""
	return {
		Dash = dash,
		Signature = signature,
		Ring = ring,
		Cooldown = cooldown,
		ReadyAt = 0,
	}
end)()

finalHud.StatsPanel = UiKit.Panel(screen, "Stats")
finalHud.StatsPanel.BackgroundColor3 = PANEL
finalHud.StatsPanel.BackgroundTransparency = 0.1
finalHud.StatsPanel.BorderSizePixel = 0
finalHud.StatsPanel.Visible = false
finalHud.StatsPanel.Parent = screen
text(finalHud.StatsPanel, "Title", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 24), "STATS", 18).TextXAlignment =
	Enum.TextXAlignment.Left
local statsLabel =
	text(finalHud.StatsPanel, "Values", UDim2.fromOffset(12, 40), UDim2.new(1, -24, 0, 90), "", 16)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Thin full-width run XP, pinned to the very top edge by HudLayout.
local experienceBar = UiKit.Bar(screen, "XP", UDim2.new(), Theme.Goo)
local xpBack = experienceBar.Frame
local xpFill = experienceBar.Fill
xpFill.Size = UDim2.fromScale(0, 1)
local xpText = experienceBar.Label
xpText.TextSize = 11
xpText.Visible = false

-- A compact left icon column opens utility panels only when requested.
local questToggle = button(screen, "Q", UDim2.fromOffset(48, 48))
questToggle.Name = "QuestToggle"
questToggle.Position = UDim2.new(1, -272, 0, 50)
local questPanel = Instance.new("ScrollingFrame")
questPanel.Name = "Quests"
questPanel.Size = UDim2.new(0, 260, 0, 0)
questPanel.Position = UDim2.new(1, -272, 0, 88)
questPanel.BackgroundColor3 = PANEL
questPanel.BackgroundTransparency = 0.1
questPanel.BorderSizePixel = 0
questPanel.ScrollBarThickness = 4
questPanel.CanvasSize = UDim2.new()
questPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
questPanel.Parent = screen
local questCorner = Instance.new("UICorner")
questCorner.CornerRadius = UDim.new(0, 8)
questCorner.Parent = questPanel
local questPadding = Instance.new("UIPadding")
questPadding.PaddingTop = UDim.new(0, 6)
questPadding.PaddingBottom = UDim.new(0, 6)
questPadding.PaddingLeft = UDim.new(0, 6)
questPadding.PaddingRight = UDim.new(0, 6)
questPadding.Parent = questPanel
local questLayout = Instance.new("UIListLayout")
questLayout.Padding = UDim.new(0, 6)
questLayout.SortOrder = Enum.SortOrder.LayoutOrder
questLayout.Parent = questPanel

local function setQuestsOpen(open: boolean)
	questPanel.Visible = open
	questToggle.Text = if open then "Q-" else "Q"
end
setQuestsOpen(false)

local function refreshQuests(state: any)
	for _, child in questPanel:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local rows = Quests.rows(state)
	for order, row in rows do
		local item = Instance.new("Frame")
		item.Name = row.Id
		item.Size = UDim2.new(1, 0, 0, 50)
		item.BackgroundColor3 = ClientFX.c3(UiTheme.Colors.PanelRaised)
		item.BorderSizePixel = 0
		item.LayoutOrder = order
		item.Parent = questPanel
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 6)
		itemCorner.Parent = item

		local title =
			text(item, "Text", UDim2.new(0, 8, 0, 3), UDim2.new(1, -16, 0, 22), row.Text, 13)
		title.TextXAlignment = Enum.TextXAlignment.Left

		local bar = Instance.new("Frame")
		bar.Name = "Progress"
		bar.Size = UDim2.new(0, 156, 0, 16)
		bar.Position = UDim2.new(0, 8, 0, 31)
		bar.BackgroundColor3 = ClientFX.c3(UiTheme.Colors.BarTrack)
		bar.BorderSizePixel = 0
		bar.Parent = item
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(row.Progress / row.Target, 1)
		fill.BackgroundColor3 = if row.Done then OK else ClientFX.c3(Theme.NeonTeal)
		fill.BorderSizePixel = 0
		fill.Parent = bar
		local progressText = text(
			bar,
			"Value",
			UDim2.new(),
			UDim2.fromScale(1, 1),
			string.format("%d / %d", row.Progress, row.Target),
			11
		)
		progressText.ZIndex = fill.ZIndex + 1

		local reward = text(
			item,
			"Reward",
			UDim2.new(0, 170, 0, 28),
			UDim2.new(1, -178, 0, 22),
			if row.Done then "Done" else string.format("+%d Gems", row.Gems),
			12
		)
		reward.TextColor3 = if row.Done then OK else ClientFX.c3(Theme.NeonAmber)
	end
end

-- Settings shares the utility-panel slot. Volume changes save on release.
local settingsToggle = button(screen, "S", UDim2.fromOffset(48, 48))
settingsToggle.Name = "SettingsToggle"
settingsToggle.Position = UDim2.new(1, -404, 0, 8)

local settingsPanel = UiKit.Panel(screen, "Settings")
settingsPanel.Name = "Settings"
settingsPanel.Size = UDim2.new(0, 260, 0, 278)
settingsPanel.Position = UDim2.new(1, -544, 0, 50)
settingsPanel.BackgroundColor3 = PANEL
settingsPanel.BackgroundTransparency = 0.1
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.Parent = screen

type SliderSetter = (number, boolean?) -> ()

local function makeSlider(
	label: string,
	y: number,
	onChanged: (number, boolean) -> ()
): SliderSetter
	local valueLabel =
		text(settingsPanel, label, UDim2.new(0, 12, 0, y), UDim2.new(1, -24, 0, 24), label, 14)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left

	local track = Instance.new("TextButton")
	track.Name = label .. " Slider"
	track.Position = UDim2.new(0, 12, 0, y + 27)
	track.Size = UDim2.new(1, -24, 0, 12)
	track.Text = ""
	track.AutoButtonColor = false
	track.BackgroundColor3 = ClientFX.c3(UiTheme.Colors.BarTrack)
	track.BorderSizePixel = 0
	track.Parent = settingsPanel
	table.insert(managedButtons, { Button = track, BaseHeight = 12 })
	resizeManagedButtons()
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = ClientFX.c3(Theme.NeonTeal)
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local value = Settings.DefaultVolume
	local dragging = false
	local dragInput: InputObject? = nil
	local function setValue(nextValue: number, persist: boolean?)
		value = Settings.clamp(nextValue)
		fill.Size = UDim2.fromScale(value, 1)
		valueLabel.Text = string.format("%s  %d%%", label, math.floor(value * 100 + 0.5))
		onChanged(value, persist == true)
	end
	local function updateAt(x: number)
		setValue((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), false)
	end

	track.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragInput = input
			updateAt(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement)
		then
			updateAt(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			dragging
			and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1)
		then
			dragging = false
			dragInput = nil
			onChanged(value, true)
		end
	end)

	setValue(value, false)
	return setValue
end

local setMusicSlider = makeSlider("Music volume", 8, function(value, persist)
	ClientFX.setMusicVolume(value)
	if persist then
		UpdateSettings:FireServer({ MusicVolume = value })
	end
end)
local setSfxSlider = makeSlider("SFX volume", 62, function(value, persist)
	ClientFX.setSfxVolume(value)
	if persist then
		UpdateSettings:FireServer({ SfxVolume = value })
	end
end)

local mouseLockButton = button(settingsPanel, "Mouse lock  ON", UDim2.new(1, -24, 0, 34))
mouseLockButton.Name = "MouseLock"
mouseLockButton.Position = UDim2.new(0, 12, 0, 108)
mouseLockButton.Visible = not (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
local mouseLockEnabled = Settings.DefaultMouseLock
local function setMouseLock(enabled: boolean)
	mouseLockEnabled = enabled
	player:SetAttribute("MouseLockEnabled", enabled)
	mouseLockButton.Text = if enabled then "Mouse lock  ON" else "Mouse lock  OFF"
end
mouseLockButton.MouseButton1Click:Connect(function()
	setMouseLock(not mouseLockEnabled)
	UpdateSettings:FireServer({ MouseLockEnabled = mouseLockEnabled })
end)

local autoFireButton = button(settingsPanel, "Auto-fire  ON", UDim2.new(1, -24, 0, 34))
autoFireButton.Name = "AutoFire"
autoFireButton.Position = UDim2.new(0, 12, 0, 150)
local autoFireEnabled = Settings.AutoFire
local function setAutoFire(enabled: boolean)
	autoFireEnabled = enabled
	Settings.AutoFire = enabled
	player:SetAttribute("AutoFire", enabled)
	autoFireButton.Text = if enabled then "Auto-fire  ON" else "Auto-fire  OFF"
end
autoFireButton.MouseButton1Click:Connect(function()
	setAutoFire(not autoFireEnabled)
end)
setAutoFire(autoFireEnabled)

do
	local combatCameraButton = button(settingsPanel, "Combat camera  ON", UDim2.new(1, -24, 0, 34))
	combatCameraButton.Name = "CombatCamera"
	combatCameraButton.Position = UDim2.new(0, 12, 0, 192)
	finalHud.CombatCameraEnabled = Settings.DefaultCombatCamera
	finalHud.SetCombatCamera = function(enabled: boolean)
		finalHud.CombatCameraEnabled = enabled
		player:SetAttribute("CombatCameraEnabled", enabled)
		combatCameraButton.Text = if enabled then "Combat camera  ON" else "Combat camera  OFF"
	end
	combatCameraButton.MouseButton1Click:Connect(function()
		finalHud.SetCombatCamera(not finalHud.CombatCameraEnabled)
		UpdateSettings:FireServer({ CombatCameraEnabled = finalHud.CombatCameraEnabled })
	end)
	finalHud.SetCombatCamera(finalHud.CombatCameraEnabled)
end

do
	local cinematicModes = { Full = "Short", Short = "Off", Off = "Full" }
	local cinematicButton = button(settingsPanel, "Ultimate  FULL", UDim2.new(1, -24, 0, 34))
	cinematicButton.Name = "UltimateCinematics"
	cinematicButton.Position = UDim2.new(0, 12, 0, 234)
	finalHud.CinematicMode = Settings.DefaultUltimateCinematics
	finalHud.SetCinematicMode = function(mode: string)
		finalHud.CinematicMode = cinematicModes[mode] and mode or Settings.DefaultUltimateCinematics
		player:SetAttribute("UltimateCinematics", finalHud.CinematicMode)
		cinematicButton.Text = "Ultimate  " .. string.upper(finalHud.CinematicMode)
	end
	cinematicButton.MouseButton1Click:Connect(function()
		finalHud.SetCinematicMode(cinematicModes[finalHud.CinematicMode])
		UpdateSettings:FireServer({ UltimateCinematics = finalHud.CinematicMode })
	end)
	finalHud.SetCinematicMode(finalHud.CinematicMode)
end

-- Bottom build view. Number keys still switch inventory weapons; this row describes the
-- equipped weapon and its current evolved/element state.
local hotbar = Instance.new("Frame")
hotbar.Name = "Weapons"
hotbar.Size = UDim2.new(0, 420, 0, 46)
hotbar.Position = UDim2.new(1, -432, 1, -72)
hotbar.BackgroundTransparency = 1
hotbar.Visible = true
hotbar.Parent = screen
local hotLayout = Instance.new("UIListLayout")
hotLayout.FillDirection = Enum.FillDirection.Horizontal
hotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
hotLayout.Padding = UDim.new(0, 4)
hotLayout.Parent = hotbar

finalHud.PassiveTray = Instance.new("Frame")
finalHud.PassiveTray.Name = "Passives"
finalHud.PassiveTray.BackgroundTransparency = 1
finalHud.PassiveTray.Parent = screen
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 10)
	layout.Parent = finalHud.PassiveTray
end

-- Bottom-center first-run hint. Only the first unfinished tutorial step is visible.
local tutorialPill = UiKit.Panel(screen, "Tutorial")
tutorialPill.Name = "TutorialHint"
tutorialPill.AnchorPoint = Vector2.new(0.5, 1)
tutorialPill.Size = UDim2.new(0, 300, 0, 38)
tutorialPill.Position = UDim2.new(0.5, 0, 1, -24)
tutorialPill.BackgroundColor3 = PANEL
tutorialPill.BackgroundTransparency = 0.08
tutorialPill.BorderSizePixel = 0
tutorialPill.Visible = false
tutorialPill.Parent = screen
local tutorialHint =
	text(tutorialPill, "Text", UDim2.new(0, 12, 0, 0), UDim2.new(1, -24, 1, 0), "", 17)
tutorialHint.TextColor3 = ClientFX.c3(Theme.NeonTeal)

-- Banner + toast
local banner = UiKit.Banner(screen, "Banner", "")
banner.Visible = false
local objectiveBanner = text(
	screen,
	"ObjectiveBanner",
	UDim2.new(0, 0, 0.12, 0),
	UDim2.new(1, 0, 0, 64),
	Onboarding.ObjectiveText,
	28
)
objectiveBanner.BackgroundColor3 = PANEL
objectiveBanner.BackgroundTransparency = 0.08
objectiveBanner.Font = UiKit.Fonts.Banner
objectiveBanner.Visible = false
local countdownLabel =
	text(screen, "Countdown", UDim2.new(0.5, -100, 0.3, 0), UDim2.new(0, 200, 0, 120), "", 72)
countdownLabel.Visible = false
local enemyArrow = text(
	screen,
	"FirstEnemyArrow",
	UDim2.new(0.5, -24, 0.5, -24),
	UDim2.fromOffset(48, 48),
	"▲",
	42
)
enemyArrow.TextColor3 = ClientFX.c3(Theme.NeonTeal)
enemyArrow.Visible = false
local toast = text(screen, "Toast", UDim2.new(0.5, -300, 0.2, 0), UDim2.new(0, 600, 0, 30), "", 20)
toast.Visible = false
-- the banner and the toast float above everything else, the reward cards included
banner.ZIndex = 4
objectiveBanner.ZIndex = 4
countdownLabel.ZIndex = 4
enemyArrow.ZIndex = 4
toast.ZIndex = 4

local function flash(label: TextLabel, str: string, seconds: number)
	label.Text = str
	label.Visible = true
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
	finalHud.AnimeEffects.slam(label)
	task.delay(seconds, function()
		if label.Text ~= str then
			return
		end
		TweenService
			:Create(label, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 })
			:Play()
		task.delay(0.5, function()
			if label.Text == str then
				label.Visible = false
			end
		end)
	end)
end

onState("ZoneBanner", function(message)
	if message ~= "" then
		flash(banner, message, 0.5)
	end
end)

function finalHud.showAreaWarning(position: Vector3, radius: number, duration: number)
	local warning = Instance.new("Part")
	warning.Name = "AreaWarning"
	warning.Shape = Enum.PartType.Cylinder
	warning.Size = Vector3.new(0.08, radius * 2, radius * 2)
	warning.CFrame = CFrame.new(position + Vector3.new(0, 0.08, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	warning.Anchored = true
	warning.CanCollide = false
	warning.CanQuery = false
	warning.CanTouch = false
	warning.CastShadow = false
	warning.Material = Enum.Material.Neon
	warning.Color = ClientFX.c3(Theme.Telegraph)
	warning.Transparency = 0.45
	warning.Parent = workspace:FindFirstChild("ClientFX") or workspace
	TweenService:Create(
		warning,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 0.8, Size = Vector3.new(0.08, radius * 2.15, radius * 2.15) }
	):Play()
	task.delay(duration, function()
		warning:Destroy()
	end)
end

-- Latest stats snapshot from the server (filled by StatsChanged below)
local stats: any

-- The parts of the stats snapshot that the pure profile helpers (perk costs, next goal) read.
local function profileSnapshot(): any
	return {
		Gold = stats.Gold or 0,
		Gems = stats.Gems or 0,
		Shards = stats.Shards or {},
		Equipped = stats.Equipped or "Starter",
		Evolutions = stats.Evolutions or {},
		Perks = stats.Perks or {},
		Kit = stats.Kit or "Soldier",
		KitsOwned = stats.KitsOwned or { Soldier = true },
	}
end

-- Wave reward cards: pick 1 of 3 after every wave clear (Shared/WaveRewards). They sit over
-- the open shop during the intermission while the server holds an offer for us; a click or
-- keys 1-3 pick one, and the server takes the first card for us when the countdown runs out.
local cardDimmer = Instance.new("Frame")
cardDimmer.Name = "RewardDimmer"
cardDimmer.Size = UDim2.fromScale(1, 1)
cardDimmer.BackgroundColor3 = Color3.new(0, 0, 0)
cardDimmer.BackgroundTransparency = CardStyle.WorldDimTransparency
cardDimmer.BorderSizePixel = 0
cardDimmer.Visible = false
cardDimmer.ZIndex = 1
cardDimmer.Parent = screen

local cardPanel = Instance.new("Frame")
cardPanel.Name = "RewardCards"
cardPanel.Size =
	UDim2.fromOffset(CardStyle.Width * WaveRewards.OfferSize + 24, CardStyle.Height + 48)
cardPanel.Position = UDim2.new(0.5, -((CardStyle.Width * WaveRewards.OfferSize + 24) / 2), 0.22, 0)
cardPanel.BackgroundTransparency = 1
cardPanel.Visible = false
cardPanel.ZIndex = 2 -- above the shop panel
cardPanel.Parent = screen
player:SetAttribute("CardPanelOpen", false)
local cardUi: any = {
	Ids = {},
	Key = "",
	Pending = false,
	Selected = nil,
	Outlines = {},
}
cardUi.Row = Instance.new("Frame")
cardUi.Row.Name = "Cards"
cardUi.Row.Size = UDim2.new(1, 0, 0, CardStyle.Height)
cardUi.Row.BackgroundTransparency = 1
cardUi.Row.Parent = cardPanel
local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Horizontal
cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
cardLayout.Padding = UDim.new(0, 12)
cardLayout.Parent = cardUi.Row

local actionRow = Instance.new("Frame")
actionRow.Name = "Actions"
actionRow.Size = UDim2.new(1, 0, 0, 40)
actionRow.Position = UDim2.fromOffset(0, CardStyle.Height + 8)
actionRow.BackgroundTransparency = 1
actionRow.Parent = cardPanel
local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.Padding = UDim.new(0, 10)
actionLayout.Parent = actionRow

local function selectCard(id: string)
	cardUi.Selected = id
	for cardId, outline in cardUi.Outlines do
		local selected = cardId == id
		local isEvolution = (stats.OfferEvolutions or {})[cardId] ~= nil
		outline.Color = ClientFX.c3(
			if selected
				then CardStyle.SelectedStroke
				else CardStyle.strokeFor(
					(stats.OfferRarities or {})[cardId] or "Common",
					isEvolution
				)
		)
		outline.Thickness = if selected
			then CardStyle.SelectedStrokeThickness
			else CardStyle.StrokeThickness
	end
end

local function rewardAction(action: string, id: string?)
	if cardUi.Pending then
		return
	end
	cardUi.Pending = true
	-- rebuildCards swaps in a new Ids table, so identity tells us whether the server pushed the
	-- next offer (pending levels, or the skip refund levelling up) before this invoke returned.
	local offerBefore = cardUi.Ids
	-- pcall: a failed invoke (server error, remote gone on teleport) must never leave Pending
	-- stuck and every later offer unpickable. The server's auto-pick still saves the reward.
	local called, ok, why = pcall(function()
		return PickReward:InvokeServer(action, id)
	end)
	cardUi.Pending = false
	if not called then
		warn("PickReward failed:", ok)
	end
	if called and ok == true then
		ClientFX.sound("Buy")
		if action == WaveRewards.Actions.Pick then
			local evolution = (stats.OfferEvolutions or {})[id or ""]
			local def = WaveRewards.Defs[id or ""]
			flash(
				toast,
				if evolution
					then "EVOLVED: " .. evolution
					else "Picked: " .. (if def then def.Label else id or "reward"),
				2
			)
			if cardUi.Ids == offerBefore then
				cardUi.Ids = {}
				cardPanel.Visible = false
			end
		elseif action == WaveRewards.Actions.Skip then
			flash(toast, "+10% XP", 2)
			if cardUi.Ids == offerBefore then
				cardUi.Ids = {}
				cardPanel.Visible = false
			end
		elseif action == WaveRewards.Actions.Reroll then
			flash(toast, "New cards", 1.5)
		else
			flash(toast, "Banished", 1.5)
		end
	else
		ClientFX.sound("Deny")
		if called and typeof(why) == "string" and why ~= "" then
			flash(toast, why, 2.5)
		end
	end
end

local function pickCard(id: string)
	rewardAction(WaveRewards.Actions.Pick, id)
end

cardUi.RerollButton = UiKit.Button(actionRow, "REROLL", UDim2.fromOffset(170, 40))
cardUi.RerollButton.Name = "Reroll"
cardUi.SkipButton = UiKit.Button(actionRow, "SKIP  +10% XP", UDim2.fromOffset(170, 40))
cardUi.SkipButton.Name = "Skip"
cardUi.BanishButton = UiKit.Button(actionRow, "BANISH", UDim2.fromOffset(170, 40))
cardUi.BanishButton.Name = "Banish"
cardUi.RerollButton.MouseButton1Click:Connect(function()
	rewardAction(WaveRewards.Actions.Reroll)
end)
cardUi.SkipButton.MouseButton1Click:Connect(function()
	rewardAction(WaveRewards.Actions.Skip)
end)
cardUi.BanishButton.MouseButton1Click:Connect(function()
	rewardAction(WaveRewards.Actions.Banish, cardUi.Selected)
end)

local function rebuildCards(
	offer: { string },
	rarities: { [string]: string },
	elements: { [string]: string },
	evolutionOffers: { [string]: string }
)
	for _, c in cardUi.Row:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	cardUi.Ids = {}
	cardUi.Outlines = {}
	cardUi.Selected = nil
	for _, id in offer do
		local evolutionId = evolutionOffers[id]
		local recipe = if evolutionId then Evolutions.recipe(evolutionId) else nil
		local def = if recipe
			then {
				Label = recipe.Evolved,
				Blurb = "Transform the equipped weapon with " .. recipe.Element .. " power",
				Kind = "Weapon",
			}
			else WaveRewards.Defs[id]
		if def and #cardUi.Ids < WaveRewards.OfferSize then
			table.insert(cardUi.Ids, id)
			local i = #cardUi.Ids
			local b =
				UiKit.Button(cardUi.Row, "", UDim2.fromOffset(CardStyle.Width, CardStyle.Height))
			b.Name = "Card" .. i
			local targetSize = UDim2.fromOffset(CardStyle.Width, CardStyle.Height)
			b.Size = UDim2.fromOffset(0, CardStyle.Height)
			b.Text = ""
			b.BackgroundColor3 = ClientFX.c3(Theme.ChitinDark)
			b.BorderSizePixel = 0
			b.Active = false
			b.ClipsDescendants = true
			b.LayoutOrder = i
			local rarity = rarities[id] or "Common"
			local style = CardStyle.styleFor(rarity)
			local textColor = ClientFX.c3(style.Text)
			local rarityColor = ClientFX.c3(CardStyle.strokeFor(rarity, recipe ~= nil))
			local backgroundGradient = b:FindFirstChildOfClass("UIGradient")
			if backgroundGradient then
				backgroundGradient.Color = ColorSequence.new(
					ClientFX.c3(style.Background[1]),
					ClientFX.c3(style.Background[2])
				)
				backgroundGradient.Rotation = 90
			end
			local outline = b:FindFirstChild("Outline")
			if outline and outline:IsA("UIStroke") then
				outline.Color = rarityColor
				outline.Thickness = CardStyle.StrokeThickness
				outline.Transparency = 0
				cardUi.Outlines[id] = outline
			end
			local elementName = elements[id]
			local category = if recipe
				then "EVOLVE"
				else CardStyle.categoryFor(def.Kind, elementName)
			local categoryColor = if recipe
				then CardStyle.EvolveStroke
				else if elementName and Evolutions.Elements[elementName]
					then Evolutions.Elements[elementName].Color
					else CardStyle.CategoryColors[category]
			local categoryBar = Instance.new("Frame")
			categoryBar.Name = "CategoryBar"
			categoryBar.Size = UDim2.new(1, 0, 0, 28)
			categoryBar.BackgroundColor3 = ClientFX.c3(categoryColor)
			categoryBar.BorderSizePixel = 0
			categoryBar.ZIndex = b.ZIndex + 2
			categoryBar.Parent = b
			local categoryLabel = text(
				categoryBar,
				"Category",
				UDim2.fromOffset(10, 2),
				UDim2.new(1, -20, 1, -4),
				category,
				14
			)
			categoryLabel.Font = UiKit.Fonts.Body
			categoryLabel.TextColor3 = ClientFX.c3(Theme.Text)
			categoryLabel.ZIndex = categoryBar.ZIndex + 1
			local rarityLabel = text(
				b,
				"Rarity",
				UDim2.new(0, 12, 0, 34),
				UDim2.new(0.55, -12, 0, 20),
				string.upper(rarity),
				13
			)
			rarityLabel.TextColor3 = textColor
			local levelBadge = text(
				b,
				"Level",
				UDim2.new(1, -72, 0, 34),
				UDim2.fromOffset(60, 22),
				"Lv " .. tostring((((stats.Boosts or {}).Stacks or {})[id] or 0) + 1),
				14
			)
			levelBadge.TextXAlignment = Enum.TextXAlignment.Right
			levelBadge.TextColor3 = rarityColor
			local icon = text(
				b,
				"Icon",
				UDim2.new(0, 12, 0, 50),
				UDim2.new(1, -24, 0, 70),
				if recipe then recipe.Icon else CardStyle.iconFor(id, elementName) or "",
				60
			)
			icon.Font = UiKit.Fonts.Title
			icon.TextColor3 = textColor
			local nameLabel = text(
				b,
				"Label",
				UDim2.new(0, 12, 0, 120),
				UDim2.new(1, -24, 0, 34),
				def.Label,
				CardStyle.NameTextSize
			)
			nameLabel.TextColor3 = rarityColor
			local blurb = text(
				b,
				"Blurb",
				UDim2.new(0, 12, 0, 156),
				UDim2.new(1, -24, 0, 44),
				CardStyle.richEffect(def.Blurb),
				CardStyle.EffectTextSize
			)
			blurb.Font = UiKit.Fonts.Body
			blurb.RichText = true
			blurb.TextWrapped = true
			-- Long effects shrink instead of spilling into the rows below.
			blurb.TextScaled = true
			local blurbCap = Instance.new("UITextSizeConstraint")
			blurbCap.MaxTextSize = CardStyle.EffectTextSize
			blurbCap.MinTextSize = 10
			blurbCap.Parent = blurb
			blurb.TextYAlignment = Enum.TextYAlignment.Top
			blurb.TextColor3 = textColor
			local statTag = text(
				b,
				"StatTag",
				UDim2.new(1, -102, 1, -66),
				UDim2.fromOffset(90, 24),
				"▲ " .. def.Blurb,
				13
			)
			statTag.TextXAlignment = Enum.TextXAlignment.Right
			statTag.TextColor3 = ClientFX.c3(CardStyle.CategoryColors.UPGRADE)
			local equipped = Weapons.Defs[stats.Equipped or ""]
			local cardRecipe = if equipped
				then Evolutions.recipeForWeaponCard(id, equipped.Kind)
				else nil
			if cardRecipe or elementName then
				-- The stat tag repeats the effect line; drop it so the rows stack cleanly.
				statTag.Visible = false
			end
			if cardRecipe then
				local evolveStrip = text(
					b,
					"EvolutionStrip",
					UDim2.new(0, 12, 0, 226),
					UDim2.new(1, -24, 0, 20),
					"CAN EVOLVE INTO  " .. cardRecipe.Icon .. "  " .. cardRecipe.Evolved,
					12
				)
				evolveStrip.TextTruncate = Enum.TextTruncate.AtEnd
				evolveStrip.TextColor3 = ClientFX.c3(CardStyle.EvolveStroke)
			end
			if
				equipped
				and Evolutions.completesRecipe(
					id,
					((stats.Boosts or {}).Stacks or {}),
					equipped.Kind
				)
			then
				local evolvesTag = text(
					b,
					"EvolvesTag",
					UDim2.new(0, 12, 0, 34),
					UDim2.fromOffset(82, 22),
					"EVOLVES",
					13
				)
				evolvesTag.TextColor3 = ClientFX.c3(CardStyle.EvolveStroke)
			end
			if elementName then
				local element = Evolutions.Elements[elementName]
				local elementLabel = text(
					b,
					"Element",
					UDim2.new(0, 12, 0, 202),
					UDim2.new(1, -24, 0, 22),
					elementName .. " ELEMENT",
					CardStyle.EffectTextSize
				)
				if element then
					elementLabel.TextColor3 = ClientFX.c3(element.Color)
					icon.TextColor3 = ClientFX.c3(element.Color)
				end
				elementLabel.TextStrokeTransparency = 0.15
			end
			local hint = text(
				b,
				"Key",
				UDim2.new(0, 12, 1, -28),
				UDim2.new(1, -24, 0, 22),
				"Press " .. i,
				14
			)
			hint.TextColor3 = textColor
			local shine: Frame? = nil
			if style.Shine then
				shine = Instance.new("Frame")
				shine.Name = "Shine"
				shine.Size = UDim2.new(0, 54, 1.3, 0)
				shine.Position = UDim2.new(0, -90, -0.15, 0)
				shine.Rotation = 16
				shine.BackgroundColor3 = ClientFX.c3(Theme.Text)
				shine.BackgroundTransparency = 0.55
				shine.BorderSizePixel = 0
				shine.ZIndex = b.ZIndex + 2
				shine.Parent = b
				local shineGradient = Instance.new("UIGradient")
				shineGradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				})
				shineGradient.Parent = shine
			end
			b.MouseEnter:Connect(function()
				selectCard(id)
			end)
			b.MouseButton1Click:Connect(function()
				if cardUi.Selected == id then
					pickCard(id)
				else
					selectCard(id)
				end
			end)
			task.delay((i - 1) * LevelUp.CardFlipSeconds, function()
				if b.Parent then
					TweenService:Create(
						b,
						TweenInfo.new(LevelUp.CardFlipSeconds, Enum.EasingStyle.Quad),
						{ Size = targetSize }
					):Play()
					if shine then
						TweenService:Create(
							shine,
							TweenInfo.new(0.45, Enum.EasingStyle.Quad),
							{ Position = UDim2.new(1, 40, -0.15, 0) }
						):Play()
					end
					if rarity == "Legendary" then
						ClientFX.sound(SfxMap.forEvent("level up") or "LevelUp")
						if outline and outline:IsA("UIStroke") then
							TweenService:Create(
								outline,
								TweenInfo.new(
									0.4,
									Enum.EasingStyle.Quad,
									Enum.EasingDirection.Out,
									1,
									true
								),
								{
									Thickness = CardStyle.StrokeThickness + 4,
									Transparency = 0.15,
								}
							):Play()
						end
					end
					task.delay(LevelUp.CardFlipSeconds, function()
						if b.Parent then
							b.Active = true
						end
					end)
				end
			end)
		end
	end
end

-- Rebuild when the offer changes; level-up cards can appear during a fight or intermission.
local function refreshCards()
	local offer: { string } = stats.Offer or {}
	local rarities: { [string]: string } = stats.OfferRarities or {}
	local elements: { [string]: string } = stats.OfferElements or {}
	local evolutionOffers: { [string]: string } = stats.OfferEvolutions or {}
	local rarityKey = {}
	local elementKey = {}
	local evolutionKey = {}
	for _, id in offer do
		table.insert(rarityKey, rarities[id] or "Common")
		table.insert(elementKey, elements[id] or "")
		table.insert(evolutionKey, evolutionOffers[id] or "")
	end
	local offerKey = table.concat(offer, "|")
		.. ":"
		.. table.concat(rarityKey, "|")
		.. ":"
		.. table.concat(elementKey, "|")
		.. ":"
		.. table.concat(evolutionKey, "|")
	if offerKey ~= cardUi.Key then
		cardUi.Key = offerKey
		rebuildCards(offer, rarities, elements, evolutionOffers)
	end
	local actions = stats.RewardActions or {}
	cardUi.RerollButton.Text = "REROLL  " .. tostring(actions.Rerolls or 0)
	cardUi.BanishButton.Text = "BANISH  " .. tostring(actions.Banishes or 0)
	local phase = stateValue("Phase")
	cardPanel.Visible = #cardUi.Ids > 0 and (phase == "fighting" or phase == "intermission")
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not cardPanel.Visible then
		return
	end
	local n = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
	if n >= 1 and n <= #cardUi.Ids then
		pickCard(cardUi.Ids[n])
	end
end)

-- Lobby perk buttons (Gold + Gems, forever). refreshPerkButtons repaints every one from the
-- latest server snapshot.
local perkButtons: { { Key: string, Button: TextButton } } = {}
local function refreshPerkButtons()
	local p = profileSnapshot()
	finalHud.PerkCurrencyLabel.Text = string.format("Bank: %d Gold   %d Gems", p.Gold, p.Gems)
	for _, row in perkButtons do
		local def = ProfileSchema.PerkDefs[row.Key]
		local cost = ProfileSchema.perkCost(p, row.Key)
		if cost then
			local lvl = ProfileSchema.perkLevel(p, row.Key)
			row.Button.Text = string.format(
				"%s  Lv %d  ->  %d Gold + %d Gems",
				def.Label,
				lvl + 1,
				cost.Gold,
				cost.Gems
			)
			row.Button.BackgroundColor3 = if p.Gold >= cost.Gold and p.Gems >= cost.Gems
				then BUTTON
				else GREY
		else
			row.Button.Text = string.format("%s  MAX", def.Label)
			row.Button.BackgroundColor3 = GREY
		end
	end
end
local function perkRow(parent: Instance, key: string, height: number): TextButton
	local b = button(parent, ProfileSchema.PerkDefs[key].Label, UDim2.new(1, 0, 0, height))
	b.Name = "Perk" .. key
	table.insert(perkButtons, { Key = key, Button = b })
	b.MouseButton1Click:Connect(function()
		local ok, why = BuyPerk:InvokeServer(key)
		ClientFX.sound(if ok then "Buy" else "Deny")
		flashButton(b, ok == true)
		if not ok and typeof(why) == "string" and why ~= "" then
			flash(toast, why, 2.5)
		end
		task.delay(0.3, refreshPerkButtons) -- back to its real colour after the flash
	end)
	return b
end

-- Shop panel
local shop = Instance.new("ScrollingFrame")
shop.Name = "Shop"
shop.Size = UDim2.new(0, 360, 0.9, 0)
shop.Position = UDim2.new(1, -372, 0.05, 0)
shop.BackgroundColor3 = PANEL
shop.BackgroundTransparency = 0.1
shop.BorderSizePixel = 0
shop.ScrollBarThickness = 6
shop.CanvasSize = UDim2.new()
shop.AutomaticCanvasSize = Enum.AutomaticSize.Y
shop.Visible = false
shop.Parent = screen
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shop
local shopPad = Instance.new("UIPadding")
shopPad.PaddingLeft = UDim.new(0, 10)
shopPad.PaddingRight = UDim.new(0, 10)
shopPad.PaddingTop = UDim.new(0, 8)
shopPad.Parent = shop
local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 5)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shop

local order = 0
local function section(str: string)
	order += 1
	local l = text(shop, "Sec" .. str, UDim2.new(), UDim2.new(1, 0, 0, 22), str, 16)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = ClientFX.c3(Theme.Loot)
	l.LayoutOrder = order
end
local function shopButton(str: string): TextButton
	order += 1
	local b = button(shop, str, UDim2.new(1, 0, 0, 34))
	b.LayoutOrder = order
	return b
end

section("RUN UPGRADES (Gold)")
local upgradeButtons: { [string]: TextButton } = {}
for _, name in Config.UpgradeOrder do
	local b = shopButton(name)
	upgradeButtons[name] = b
	b.MouseButton1Click:Connect(function()
		local ok = BuyUpgrade:InvokeServer(name) == true
		ClientFX.sound(if ok then "Buy" else "Deny")
		flashButton(b, ok)
	end)
end

-- One row per crate: the Gem crate (the free path, paid in Gems earned in runs) and the Robux
-- crates. Every row shows its odds and the pity rule in words (Roblox policy for paid random items).
section("WEAPON CRATES")
local crateRows: { { Cost: number, Button: TextButton } } = {} -- the Gem-priced rows
local gemCratePending = false -- our own Gem crate request is in flight
local function refreshCrateButtons()
	for _, row in crateRows do
		row.Button.BackgroundColor3 = if (stats.Gems or 0) >= row.Cost then BUTTON else GREY
	end
end
for _, key in Weapons.CrateOrder do
	local crate = Weapons.Crates[key]
	local cost = crate.Gems
	if cost then
		local b = shopButton(string.format("%s  %d Gems", crate.Label, cost))
		table.insert(crateRows, { Cost = cost, Button = b })
		b.MouseButton1Click:Connect(function()
			if gemCratePending then
				return
			end
			gemCratePending = true
			local ok, why = GemCrate:InvokeServer()
			gemCratePending = false
			ClientFX.sound(if ok then "Crate" else "Deny")
			flashButton(b, ok == true)
			if not ok and typeof(why) == "string" and why ~= "" then
				flash(toast, why, 2.5)
			end
			task.delay(0.3, refreshCrateButtons) -- back to its real colour after the flash
		end)
	else
		local product = crate.Product or ""
		local b = shopButton(crate.Label .. " (Robux)")
		b.MouseButton1Click:Connect(function()
			Prompt:FireServer("product", product)
		end)
	end
	order += 1
	local odds = text(
		shop,
		"Odds" .. key,
		UDim2.new(),
		UDim2.new(1, 0, 0, 18),
		"Odds: " .. Weapons.oddsText(key),
		12
	)
	odds.LayoutOrder = order
	odds.TextWrapped = true
	odds.AutomaticSize = Enum.AutomaticSize.Y
	odds.TextColor3 = ClientFX.c3(UiTheme.Colors.MutedText)
end

section("WEAPON EVOLUTION (Gems + shards, forever)")
order += 1
local evoInfo = text(shop, "EvoInfo", UDim2.new(), UDim2.new(1, 0, 0, 36), "", 12)
evoInfo.LayoutOrder = order
evoInfo.TextXAlignment = Enum.TextXAlignment.Left
evoInfo.TextYAlignment = Enum.TextYAlignment.Top
evoInfo.TextWrapped = true
evoInfo.TextColor3 = ClientFX.c3(UiTheme.Colors.MutedText)
local evoButtons: { [string]: TextButton } = {}
for _, element in Evolutions.Order do
	local b = shopButton(element)
	evoButtons[element] = b
	b.MouseButton1Click:Connect(function()
		local equipped = (stats :: any).Equipped
		local ok, why = Evolve:InvokeServer(equipped, element)
		ClientFX.sound(if ok then "Buy" else "Deny")
		flashButton(b, ok == true)
		if not ok and typeof(why) == "string" and why ~= "" then
			flash(toast, why, 2.5)
		end
	end)
end

finalHud.RecipeLabels = {}
do
	local recipesButton = shopButton("RECIPES")
	recipesButton.Name = "RecipesTabButton"
	order += 1
	local recipesTab = Instance.new("Frame")
	recipesTab.Name = "RecipesTab"
	recipesTab.Size = UDim2.new(1, 0, 0, #Evolutions.Recipes * 48)
	recipesTab.BackgroundTransparency = 1
	recipesTab.LayoutOrder = order
	recipesTab.Visible = false
	recipesTab.Parent = shop
	local recipesLayout = Instance.new("UIListLayout")
	recipesLayout.Padding = UDim.new(0, 4)
	recipesLayout.Parent = recipesTab
	for _, recipe in Evolutions.Recipes do
		local recipeLabel = text(
			recipesTab,
			"Recipe" .. recipe.Id:gsub("%s", ""),
			UDim2.new(),
			UDim2.new(1, 0, 0, 44),
			"???",
			12
		)
		recipeLabel.BackgroundColor3 = ClientFX.c3(UiTheme.Colors.PanelRaised)
		recipeLabel.TextWrapped = true
		recipeLabel.TextColor3 = ClientFX.c3(CardStyle.EvolveStroke)
		finalHud.RecipeLabels[recipe.Id] = recipeLabel
	end
	recipesButton.MouseButton1Click:Connect(function()
		recipesTab.Visible = not recipesTab.Visible
		recipesButton.Text = if recipesTab.Visible then "RECIPES -" else "RECIPES"
	end)
end

local function refreshRecipesTab()
	local flags = stats.Flags or {}
	for _, recipe in Evolutions.Recipes do
		local found = flags[Evolutions.RecipeFlagPrefix .. recipe.Id] == true
		finalHud.RecipeLabels[recipe.Id].Text = if found
			then string.format(
				"%s %s + %s -> %s",
				recipe.Icon,
				recipe.Weapon,
				recipe.Passive,
				recipe.Evolved
			)
			else "???"
	end
end

section("PERMANENT STATS")
order += 1
finalHud.PerkCurrencyLabel = text(shop, "Bank", UDim2.new(), UDim2.new(1, 0, 0, 24), "", 15)
finalHud.PerkCurrencyLabel.LayoutOrder = order
finalHud.PerkCurrencyLabel.TextXAlignment = Enum.TextXAlignment.Left
for _, key in Goals.PerkOrder do
	order += 1
	perkRow(shop, key, 34).LayoutOrder = order
end

section("KITS")
order += 1
local kitsRow = Instance.new("Frame")
kitsRow.Name = "Kits"
kitsRow.Size = UDim2.new(1, 0, 0, 100)
kitsRow.BackgroundTransparency = 1
kitsRow.LayoutOrder = order
kitsRow.Parent = shop
local kitsLayout = Instance.new("UIListLayout")
kitsLayout.FillDirection = Enum.FillDirection.Horizontal
kitsLayout.Padding = UDim.new(0, 4)
kitsLayout.Parent = kitsRow
local kitButtons: { [string]: TextButton } = {}
local function refreshKitButtons()
	local owned = stats.KitsOwned or {}
	for _, id in Kits.Order do
		local def = Kits.Defs[id]
		local b = kitButtons[id]
		local isOwned = owned[id] == true
		local cost = if isOwned then "Owned" else string.format("%d Gems", def.UnlockGems)
		b.Text = string.format(
			"%s\n%s\nWeapon: %s\nAbility: %s\n%s",
			def.Label,
			def.Blurb,
			Weapons.Defs[def.StartWeapon].Name,
			def.Signature.Label,
			cost
		)
		b.BackgroundColor3 = if stats.Kit == id
			then OK
			else if isOwned or (stats.Gems or 0) >= def.UnlockGems then BUTTON else GREY
	end
end
for _, id in Kits.Order do
	local b = button(kitsRow, id, UDim2.new(0.25, -3, 1, 0))
	b.Name = "Kit" .. id
	b.TextSize = 10
	b.TextWrapped = true
	kitButtons[id] = b
	b.MouseButton1Click:Connect(function()
		local ok, why = ChooseKit:InvokeServer(id)
		local soundName = if ok then SfxMap.forEvent("kit equip") else "Deny"
		if soundName then
			ClientFX.sound(soundName)
		end
		flashButton(b, ok == true)
		if not ok and typeof(why) == "string" and why ~= "" then
			flash(toast, why, 2.5)
		end
		task.delay(0.3, refreshKitButtons)
	end)
end

section("GOLD (Robux)")
for _, key in { "Coins500", "Coins1500" } do
	local b = shopButton(Monetization.DeveloperProducts[key].Name)
	b.MouseButton1Click:Connect(function()
		Prompt:FireServer("product", key)
	end)
end

section("PASSES (Robux, forever)")
local passButtons: { [string]: TextButton } = {}
for _, key in { "DoubleCoins", "ExtraDash", "StarterPack" } do
	local b = shopButton(Monetization.GamePasses[key].Name)
	passButtons[key] = b
	b.MouseButton1Click:Connect(function()
		Prompt:FireServer("pass", key)
	end)
end

local closeBtn = shopButton("Close  [B]")
closeBtn.BackgroundColor3 = GREY

-- Third button in the compact utility icon column.
local shopToggle = button(screen, "$", UDim2.fromOffset(48, 48))
shopToggle.Name = "ShopToggle"
shopToggle.Position = UDim2.new(1, -122, 0, 8)
local spectateLabel = text(
	screen,
	"SpectateStatus",
	UDim2.new(0.5, -140, 0.58, 0),
	UDim2.new(0, 280, 0, 44),
	"Respawn next wave",
	22
)
spectateLabel.BackgroundColor3 = PANEL
spectateLabel.BackgroundTransparency = 0.08
spectateLabel.Visible = false

local function applyHudLayout()
	local activeCamera = workspace.CurrentCamera
	if activeCamera then
		viewport = activeCamera.ViewportSize
	end
	currentScale = HudLayout.scaleFor(viewport.X, viewport.Y, platform)
	hudScale.Scale = currentScale
	resizeManagedButtons()

	local rects = HudLayout.rects(viewport.X, viewport.Y, platform)
	local function logical(value: number): number
		return value / currentScale
	end

	local wave = rects.topStats
	finalHud.LevelLabel.Position = UDim2.fromOffset(logical(wave.x), logical(wave.y))
	finalHud.LevelLabel.Size = UDim2.fromOffset(logical(wave.w) / 2 - 8, logical(wave.h))
	waveLabel.Position = UDim2.fromOffset(logical(wave.x + wave.w / 2 + 8), logical(wave.y))
	waveLabel.Size = UDim2.fromOffset(logical(wave.w) / 2 - 8, logical(wave.h))
	bossChipLabel.Position =
		UDim2.fromOffset(logical(wave.x + (wave.w - 200 * currentScale) / 2), logical(wave.y) + 34)
	bossChipLabel.Size = UDim2.fromOffset(200, 18)
	phaseLabel.Position = UDim2.fromOffset(logical(wave.x), logical(wave.y) + 52)
	phaseLabel.Size = UDim2.fromOffset(logical(wave.w), 22)
	mutationLabel.Position = UDim2.fromOffset(logical(wave.x), logical(wave.y) + 74)
	mutationLabel.Size = UDim2.fromOffset(logical(wave.w), 18)

	local boss = rects.waveProgress
	bossFrame.Position = UDim2.fromOffset(logical(boss.x), logical(boss.y))
	bossFrame.Size = UDim2.fromOffset(logical(boss.w), logical(boss.h))
	finalHud.BossUi:SetLayout(viewport, currentScale)

	local health = rects.health
	hpBack.Position = UDim2.fromOffset(logical(health.x), logical(health.y))
	hpBack.Size = UDim2.fromOffset(logical(health.w), logical(health.h))
	tutorialPill.Position =
		UDim2.fromOffset(logical(health.x + health.w / 2), logical(health.y) - 8)

	local xp = rects.xp
	xpBack.Position = UDim2.fromOffset(logical(xp.x), logical(xp.y))
	xpBack.Size = UDim2.fromOffset(logical(xp.w), logical(xp.h))

	local weapons = rects.weaponRow
	hotbar.Position = UDim2.fromOffset(logical(weapons.x), logical(weapons.y))
	hotbar.Size = UDim2.fromOffset(logical(weapons.w), logical(weapons.h))

	local passives = rects.passiveRow
	finalHud.PassiveTray.Position = UDim2.fromOffset(logical(passives.x), logical(passives.y))
	finalHud.PassiveTray.Size = UDim2.fromOffset(logical(passives.w), logical(passives.h))

	local currencies = rects.currencies
	finalHud.CurrencyFrame.Position = UDim2.fromOffset(logical(currencies.x), logical(currencies.y))
	finalHud.CurrencyFrame.Size = UDim2.fromOffset(logical(currencies.w), logical(currencies.h))

	local targets = HudLayout.touchTargets(viewport.X, viewport.Y)
	local function placeIcon(icon: TextButton, target: HudLayout.Rect)
		icon.Position = UDim2.fromOffset(logical(target.x), logical(target.y))
		icon.Size = UDim2.fromOffset(logical(target.w), logical(target.h))
	end
	placeIcon(questToggle, targets.quests)
	placeIcon(shopToggle, targets.shop)
	placeIcon(settingsToggle, targets.settings)

	local quest = rects.quests
	questPanel.Position = UDim2.fromOffset(logical(quest.x), logical(quest.y))
	questPanel.Size = UDim2.fromOffset(logical(quest.w), logical(quest.h))
	questPanel.ClipsDescendants = true

	local settings = rects.settings
	settingsPanel.Position = UDim2.fromOffset(logical(settings.x), logical(settings.y))
	settingsPanel.Size = UDim2.fromOffset(logical(settings.w), math.min(194, logical(settings.h)))

	local shopRect = rects.shop
	shop.Position = UDim2.fromOffset(logical(shopRect.x), logical(shopRect.y))
	shop.Size = UDim2.fromOffset(logical(shopRect.w), logical(shopRect.h))

	local statsRect = rects.stats
	finalHud.StatsPanel.Position = UDim2.fromOffset(logical(statsRect.x), logical(statsRect.y))
	finalHud.StatsPanel.Size =
		UDim2.fromOffset(logical(statsRect.w), math.min(146, logical(statsRect.h)))

	local bannerRect = rects.waveClearBanner
	banner.Position = UDim2.fromOffset(logical(bannerRect.x), logical(bannerRect.y))
	banner.Size = UDim2.fromOffset(logical(bannerRect.w), logical(bannerRect.h))
	local rewardRect = rects.rewardCards
	local rewardWidth =
		math.max(logical(rewardRect.w), CardStyle.Width * WaveRewards.OfferSize + 24)
	cardPanel.Position =
		UDim2.fromOffset((logical(viewport.X) - rewardWidth) / 2, logical(rewardRect.y))
	cardPanel.Size =
		UDim2.fromOffset(rewardWidth, math.max(logical(rewardRect.h), CardStyle.Height + 48))
end

applyHudLayout()
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyHudLayout)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	applyHudLayout()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyHudLayout)
	end
end)

local function setUtilityPanel(panel: HudLayout.UtilityPanel?)
	if panel ~= nil and cardPanel.Visible then
		return
	end
	finalHud.OpenUtilityPanel = panel
	player:SetAttribute("UtilityPanelOpen", panel ~= nil)
	setQuestsOpen(panel == "quests")
	shop.Visible = panel == "shop"
	settingsPanel.Visible = panel == "settings"
	finalHud.StatsPanel.Visible = panel == "stats"
	shopToggle.Text = if panel == "shop" then "$-" else "$"
	settingsToggle.Text = if panel == "settings" then "S-" else "S"
end

local function setShop(open: boolean)
	setUtilityPanel(if open then "shop" else nil)
end
questToggle.MouseButton1Click:Connect(function()
	setUtilityPanel(if finalHud.OpenUtilityPanel == "quests" then nil else "quests")
end)
settingsToggle.MouseButton1Click:Connect(function()
	setUtilityPanel(if finalHud.OpenUtilityPanel == "settings" then nil else "settings")
end)
finalHud.StatsToggle.MouseButton1Click:Connect(function()
	setUtilityPanel(if finalHud.OpenUtilityPanel == "stats" then nil else "stats")
end)
shopToggle.MouseButton1Click:Connect(function()
	ClientFX.sound("Buy", nil, 0.3)
	setUtilityPanel(if finalHud.OpenUtilityPanel == "shop" then nil else "shop")
end)
cardPanel:GetPropertyChangedSignal("Visible"):Connect(function()
	player:SetAttribute("CardPanelOpen", cardPanel.Visible)
	cardDimmer.Visible = cardPanel.Visible
	if cardPanel.Visible then
		setUtilityPanel(nil)
	end
end)
closeBtn.MouseButton1Click:Connect(function()
	setShop(false)
end)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		setShop(not shop.Visible)
	end
end)

-- Compact all-dead summary, hidden whenever a run is active.
local summaryPanel = UiKit.Panel(screen, "Summary")
summaryPanel.Name = "RunSummary"
summaryPanel.Size = UDim2.new(0, 360, 0, 246)
summaryPanel.Position = UDim2.new(0.5, -180, 0.5, -123)
summaryPanel.BackgroundColor3 = PANEL
summaryPanel.BorderSizePixel = 0
summaryPanel.Visible = false
summaryPanel.Parent = screen
local summaryPad = Instance.new("UIPadding")
summaryPad.PaddingLeft = UDim.new(0, 12)
summaryPad.PaddingRight = UDim.new(0, 12)
summaryPad.PaddingTop = UDim.new(0, 12)
summaryPad.PaddingBottom = UDim.new(0, 12)
summaryPad.Parent = summaryPanel
local summaryLayout = Instance.new("UIListLayout")
summaryLayout.Padding = UDim.new(0, 6)
summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
summaryLayout.Parent = summaryPanel

local summaryOrder = 0
local function summaryRow(name: string, height: number, textSize: number): TextLabel
	summaryOrder += 1
	local l = text(summaryPanel, name, UDim2.new(), UDim2.new(1, 0, 0, height), "", textSize)
	l.LayoutOrder = summaryOrder
	return l
end
local summaryTitle = summaryRow("Title", 36, 34)
local summaryWave = summaryRow("Wave", 26, 18)
local summaryKills = summaryRow("Kills", 26, 18)
local summaryGems = summaryRow("Deposit", 26, 18)
for _, l in { summaryWave, summaryKills, summaryGems } do
	l.TextXAlignment = Enum.TextXAlignment.Left
end
summaryOrder += 1
-- Any open panel frees the mouse (Camera.client reads ModalOpen through MouseMode).
local function updateModalOpen()
	local open = cardPanel.Visible
		or summaryPanel.Visible
		or shop.Visible
		or settingsPanel.Visible
		or finalHud.StatsPanel.Visible
		or player:GetAttribute("UtilityPanelOpen") == true
	player:SetAttribute("ModalOpen", open)
end
for _, panel in { cardPanel, summaryPanel, shop, settingsPanel, finalHud.StatsPanel } do
	panel:GetPropertyChangedSignal("Visible"):Connect(updateModalOpen)
end
player:GetAttributeChangedSignal("UtilityPanelOpen"):Connect(updateModalOpen)
updateModalOpen()

local playAgainButton = button(summaryPanel, "PLAY AGAIN", UDim2.new(1, 0, 0, 56))
playAgainButton.LayoutOrder = summaryOrder

local deathState: DeathFlow.State = DeathFlow.initialState()
local diedAt: number? = nil
local summaryToken = 0

playAgainButton.MouseButton1Click:Connect(function()
	if deathState ~= "summary" then
		return
	end
	deathState = DeathFlow.transition(deathState, "play-again")
	summaryPanel.Visible = false
	PlayAgain:FireServer()
end)

local function watchCharacter(character: Model)
	summaryToken += 1
	spectateLabel.Visible = false
	deathState = DeathFlow.transition(deathState, "respawned")
	deathState = DeathFlow.transition(deathState, "ready")
	diedAt = nil
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		deathState = DeathFlow.transition(deathState, "died")
		deathState = DeathFlow.transition(deathState, "spectate")
		diedAt = os.clock()
		spectateLabel.Visible = true
	end)
end

player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	task.spawn(watchCharacter, player.Character)
end

local function commas(n: number): string
	local s = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return if s:sub(1, 1) == "," then s:sub(2) else s
end

-- Daily reward strip: the server pays today's login streak slot when the profile loads and the
-- popup rides on StatsChanged (PlayerData.claimDaily). It shows once per session and never over
-- a fight: a popup that lands mid-wave waits for the next phase, and a wave that starts while
-- the strip is still up hides it until the wave ends.
local DAILY_LATER = ClientFX.c3(Theme.ChitinDark) -- a day not reached yet
local dailyStrip = UiKit.Panel(screen, "DailyReward")
dailyStrip.Name = "DailyReward"
dailyStrip.Size = UDim2.new(0, 540, 0, 130)
dailyStrip.Position = UDim2.new(0.5, -270, 0.12, 0)
dailyStrip.BackgroundColor3 = PANEL
dailyStrip.BorderSizePixel = 0
dailyStrip.Visible = false
dailyStrip.ZIndex = 3 -- over the shop and the reward cards, under the banner and the toast
dailyStrip.Parent = screen
-- an invisible button that fills the strip, so a click anywhere on it dismisses it
local dailyBody = Instance.new("TextButton")
dailyBody.Name = "Body"
dailyBody.Size = UDim2.fromScale(1, 1)
dailyBody.BackgroundTransparency = 1
dailyBody.Text = ""
dailyBody.AutoButtonColor = false
dailyBody.Parent = dailyStrip
local dailyTitle =
	text(dailyBody, "Title", UDim2.new(0, 14, 0, 8), UDim2.new(1, -104, 0, 22), "", 18)
dailyTitle.TextXAlignment = Enum.TextXAlignment.Left
local dailyOk = button(dailyBody, "OK", UDim2.new(0, 64, 0, 26))
dailyOk.Position = UDim2.new(1, -78, 0, 6)
local dailyRow = Instance.new("Frame")
dailyRow.Name = "Days"
dailyRow.Size = UDim2.new(1, -28, 0, 54)
dailyRow.Position = UDim2.new(0, 14, 0, 36)
dailyRow.BackgroundTransparency = 1
dailyRow.Parent = dailyBody
local dailyLayout = Instance.new("UIListLayout")
dailyLayout.FillDirection = Enum.FillDirection.Horizontal
dailyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dailyLayout.SortOrder = Enum.SortOrder.LayoutOrder
dailyLayout.Padding = UDim.new(0, 6)
dailyLayout.Parent = dailyRow
local dailyBoxes: { Frame } = {} -- one box per slot, in slot order
for i, reward in Daily.Rewards do
	local box = Instance.new("Frame")
	box.Name = "Day" .. i
	box.Size = UDim2.new(0, 62, 0, 54)
	box.BackgroundColor3 = DAILY_LATER
	box.BorderSizePixel = 0
	box.LayoutOrder = i
	box.Parent = dailyRow
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = box
	text(box, "Day", UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 16), "Day " .. i, 12)
	local r = text(
		box,
		"Reward",
		UDim2.new(0, 2, 0, 22),
		UDim2.new(1, -4, 0, 28),
		Daily.shortText(reward),
		12
	)
	r.Font = UiKit.Fonts.Body
	r.TextWrapped = true
	table.insert(dailyBoxes, box)
end
local dailyNext = text(dailyBody, "Next", UDim2.new(0, 14, 0, 98), UDim2.new(1, -28, 0, 20), "", 14)
dailyNext.TextXAlignment = Enum.TextXAlignment.Left
dailyNext.TextColor3 = ClientFX.c3(UiTheme.Colors.MutedText)

local dailyShown = false -- once per session: the popup stays in every stats push
local dailyPopup: Daily.Popup? = nil -- this session's popup, once StatsChanged brought it
local dailyPending = false -- the strip waits for the current wave to end
local dailySounded = false -- the appearance sound plays on the first showing only

local function showDaily(popup: Daily.Popup)
	dailyTitle.Text = string.format("DAY %d STREAK   %s", popup.Streak, popup.Text)
	dailyNext.Text = "Come back tomorrow for " .. popup.NextText
	for i, box in dailyBoxes do
		box.BackgroundColor3 = if i < popup.Slot
			then OK
			else if i == popup.Slot then ClientFX.c3(Theme.NeonAmber) else DAILY_LATER
	end
	dailyStrip.Visible = true
	-- Close on its own: during a fight the cursor is locked, so a click-to-close strip would stick.
	task.delay(5, function()
		dailyStrip.Visible = false
	end)
	if not dailySounded then
		dailySounded = true
		ClientFX.sound("Buy")
	end
end
local function hideDaily()
	dailyStrip.Visible = false
end
dailyOk.MouseButton1Click:Connect(hideDaily)
dailyBody.MouseButton1Click:Connect(hideDaily)

-- From StatsChanged: the snapshot's DailyPopup (nil until the server paid today's reward).
local function onDailyPopup(popup: Daily.Popup?)
	if not popup or dailyShown then
		return
	end
	dailyShown = true
	dailyPopup = popup
	if stateValue("Phase") == "fighting" then
		dailyPending = true
	else
		showDaily(popup)
	end
end

-- Phase changes: hold the strip through a fight, bring it back once the wave is over.
local function onDailyPhase(phase: string)
	if phase == "fighting" then
		if dailyStrip.Visible then
			hideDaily() -- already seen once; do not bring it back after every wave
		end
	elseif dailyPending and dailyPopup then
		dailyPending = false
		showDaily(dailyPopup)
	end
end

-- Stats -> labels, upgrade buttons, hotbar
stats = {
	Coins = 0,
	Gold = 0,
	Kills = 0,
	Levels = {},
	Weapons = { "Starter" },
	Equipped = "Starter",
	Passes = {},
	Gems = 0,
	Shards = {},
	Evolutions = {},
	Perks = {},
	Kit = "Soldier",
	KitsOwned = { Soldier = true },
	Offer = {},
	OfferRarities = {},
	OfferElements = {},
	OfferEvolutions = {},
	XP = 0,
	Level = 0,
	XPNeeded = LevelUp.requiredXp(1),
	Quests = {},
	Flags = {},
	MusicVolume = Settings.DefaultVolume,
	SfxVolume = Settings.DefaultVolume,
	MouseLockEnabled = Settings.DefaultMouseLock,
}

local tutorialContext: Tutorial.Context = "arena"
local tutorialContextStartedAt = os.clock()

local function currentTutorialContext(): Tutorial.Context
	if cardPanel.Visible then
		return "cards"
	elseif shop.Visible then
		return "shop"
	end
	return "arena"
end

local function currentTutorialPlatform(): Tutorial.Platform
	if UserInputService.TouchEnabled then
		return "touch"
	elseif UserInputService.GamepadEnabled then
		return "gamepad"
	end
	return "keyboard"
end

local function refreshTutorial()
	local context = currentTutorialContext()
	local now = os.clock()
	if context ~= tutorialContext then
		tutorialContext = context
		tutorialContextStartedAt = now
	end
	local tutorialStep = Tutorial.pick(stats.Flags or {}, context)
	local visible = tutorialStep ~= nil
		and Tutorial.shouldShow(tutorialStep.Id, now - tutorialContextStartedAt)
		and stateValue("Phase") ~= "fighting"
	tutorialPill.Visible = visible
	tutorialHint.Text = if visible and tutorialStep
		then Tutorial.hintFor(tutorialStep.Id, currentTutorialPlatform())
		else ""
end

local function rebuildHotbar()
	for _, c in hotbar:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local ids = {}
	for _, id in stats.Weapons do
		if Weapons.Defs[id] then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		return Weapons.power(Weapons.Defs[a]) < Weapons.power(Weapons.Defs[b])
	end)
	local function weaponLevel(kind: string): number
		local level = 1
		for id, count in (stats.Boosts and stats.Boosts.Stacks) or {} do
			local card = WaveRewards.Defs[id]
			if
				card
				and card.Kind == "Weapon"
				and (not card.Kinds or table.find(card.Kinds, kind))
			then
				level += count
			end
		end
		return level
	end
	-- One slot per owned weapon, labelled with the number key that equips it (_hotIds order).
	-- Tapping or clicking a slot equips it, so touch and gamepad players can switch too.
	for n, id in ids do
		local slotDef = Weapons.Defs[id]
		local isEquipped = id == stats.Equipped
		local slot = button(
			hotbar,
			string.format(
				"%s\n%s\nLv %d",
				if n <= 9 then tostring(n) else "",
				string.upper(slotDef.Name),
				weaponLevel(slotDef.Kind)
			),
			UDim2.new(0, 64, 1, 0)
		)
		slot.Name = "Weapon_" .. id
		slot.TextSize = 10
		slot.TextWrapped = true
		local rarity = Weapons.RarityColor[slotDef.Rarity]
		local border = Instance.new("UIStroke")
		border.Name = "Rarity"
		border.Thickness = if isEquipped then 4 else 2
		border.Transparency = if isEquipped then 0 else 0.4
		border.Color = Color3.fromRGB(rarity[1], rarity[2], rarity[3])
		border.Parent = slot
		if not isEquipped then
			slot.MouseButton1Click:Connect(function()
				EquipWeapon:FireServer(id)
			end)
		end
	end
	local def = Weapons.Defs[stats.Equipped]
	if def then
		-- The run's evolution belongs to the weapon it transformed (PlayerData.equippedEvo).
		local runRecipe = if stats.EvolvedWeapon == stats.Equipped
			then Evolutions.recipe(stats.EvolvedRecipe or "")
			else nil
		local ownedEvolution = (stats.Evolutions or {})[stats.Equipped]
		local element = if runRecipe then runRecipe.Element else stats.RunElement
		local stateName = if runRecipe
			then runRecipe.Evolved
			else if element
				then element
				else if ownedEvolution then ownedEvolution.Element else "BASE"
		local stateLevel = if runRecipe
			then 3
			else if ownedEvolution then ownedEvolution.Tier else if element then 1 else 0
		local stateSlot = button(
			hotbar,
			string.format("STATE\n%s\nLv %d", string.upper(stateName), stateLevel),
			UDim2.new(0, 64, 1, 0)
		)
		stateSlot.TextSize = 10
		stateSlot.TextWrapped = true
		stateSlot.AutoButtonColor = false
	end
	-- number keys
	stats._hotIds = ids

	for _, child in finalHud.PassiveTray:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, name in Config.UpgradeOrder do
		local upgrade = Upgrades.def(name)
		local slot = Instance.new("Frame")
		slot.Name = name
		slot.Size = UDim2.new(0, 64, 1, 0)
		slot.BackgroundColor3 = PANEL
		slot.BorderSizePixel = 0
		slot.Parent = finalHud.PassiveTray
		local border = Instance.new("UIStroke")
		border.Color = ClientFX.c3(Theme.NeonTeal)
		border.Thickness = 2
		border.Parent = slot
		local label = text(
			slot,
			"Value",
			UDim2.new(),
			UDim2.fromScale(1, 1),
			string.format(
				"%s\nLv %d",
				if upgrade then string.upper(upgrade.Label) else name,
				(stats.Levels and stats.Levels[name]) or 0
			),
			10
		)
		label.TextWrapped = true
	end
end

finalHud.AbilityUi.Cast = function()
	if os.clock() >= finalHud.AbilityUi.ReadyAt and not cardPanel.Visible then
		finalHud.AnimeEffects.speedLines("Ultimate")
		local signature = Remotes.Signature :: RemoteEvent
		signature:FireServer()
	end
end

finalHud.AbilityUi.Signature.MouseButton1Click:Connect(finalHud.AbilityUi.Cast)
Remotes.Signature.OnClientEvent:Connect(function(cooldown: number)
	finalHud.AbilityUi.ReadyAt = os.clock() + cooldown
end)

RunService.RenderStepped:Connect(function()
	local cooldown = (player:GetAttribute("SignatureCooldown") :: number?) or 1
	local remaining = math.max(0, finalHud.AbilityUi.ReadyAt - os.clock())
	finalHud.AbilityUi.Cooldown.Text = if remaining > 0 then tostring(math.ceil(remaining)) else ""
	finalHud.AbilityUi.Ring.Color = if remaining > 0 then GREY else OK
	finalHud.AbilityUi.Ring.Transparency = if remaining > 0
		then math.clamp(1 - remaining / cooldown, 0, 0.8)
		else 0
	finalHud.AbilityUi.Signature.AutoButtonColor = remaining <= 0
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if
		not gameProcessed
		and (input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX)
	then
		finalHud.AbilityUi.Cast()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not stats._hotIds or cardPanel.Visible then
		return -- while reward cards are up, the number keys pick a card instead
	end
	local n = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
	if n >= 1 and n <= 9 and stats._hotIds[n] then
		EquipWeapon:FireServer(stats._hotIds[n])
	end
end)

local function refreshStats()
	local dash = (player:GetAttribute("DashReady") :: number?) or 0
	local kit = Kits.Defs[stats.Kit] or Kits.Defs.Soldier
	finalHud.AbilityUi.Dash.Text = string.format("DASH %d\nQ", dash)
	finalHud.AbilityUi.Signature.Text = string.format("%s\nE", kit.Signature.Icon)
	local shards = stats.Shards or {}
	finalHud.CoinsLabel.Text = string.format("●  %d Gold", stats.Coins or 0)
	finalHud.GemsLabel.Text = string.format("◆  %d", stats.Gems or 0)
	statsLabel.Text = string.format(
		"Kills %d    Level %d    Dash %d\nRun Gold %d    Bank %d Gold / %d Gems\nShards  Nature %d  Tech %d  Lightning %d  Dark %d",
		stats.Kills,
		stats.Level or 0,
		dash,
		stats.Coins or 0,
		stats.Gold or 0,
		stats.Gems or 0,
		shards.Nature or 0,
		shards.Tech or 0,
		shards.Lightning or 0,
		shards.Dark or 0
	)
	local xp = stats.XP or 0
	local xpNeeded = math.max(stats.XPNeeded or 1, 1)
	xpFill.Size = UDim2.fromScale(math.clamp(xp / xpNeeded, 0, 1), 1)
	xpText.Text = string.format("XP %d / %d", xp, xpNeeded)
	finalHud.LevelLabel.Text = string.format("LV %d", stats.Level or 0)
	-- Evolution section follows the equipped weapon
	local equippedDef = Weapons.Defs[stats.Equipped]
	local evo = (stats.Evolutions or {})[stats.Equipped]
	evoInfo.Text = string.format(
		"%s: %s\nOne path per weapon. Shards drop from bosses (Dark, Nature, Lightning) and every 5th wave (Tech).",
		if equippedDef then equippedDef.Name else "?",
		if evo then string.format("%s tier %d", evo.Element, evo.Tier) else "no path yet"
	)
	for element, b in evoButtons do
		local el = Evolutions.Elements[element]
		local ok, why, tier = Evolutions.canBuy(evo, element, stats.Gems or 0, shards[element] or 0)
		local c = el.Color
		if tier then
			b.Text = string.format(
				"%s  T%d  %d Gems + %d shard%s   %s",
				element,
				tier.Tier,
				tier.GemsCost,
				tier.ShardsCost,
				if tier.ShardsCost == 1 then "" else "s",
				tier.Label
			)
			b.BackgroundColor3 = if ok
				then Color3.fromRGB(c[1], c[2], c[3]):Lerp(Color3.new(), 0.45)
				else GREY
		else
			b.Text = string.format("%s  %s", element, why)
			b.BackgroundColor3 = ClientFX.c3(UiTheme.Colors.PanelRaised)
		end
		b.TextSize = 12
	end
	for name, b in upgradeButtons do
		local level = (stats.Levels and stats.Levels[name]) or 0
		local cost = Upgrades.costAt(name, level)
		local u = Upgrades.def(name)
		local label = if u then u.Label else name
		if cost then
			b.Text = string.format("%s  Lv %d  ->  %d Gold", label, level, cost)
			b.BackgroundColor3 = if stats.Coins >= cost then BUTTON else GREY
		else
			b.Text = string.format("%s  MAX", label)
			b.BackgroundColor3 = GREY
		end
	end
	for key, b in passButtons do
		if stats.Passes and stats.Passes[key] then
			b.Text = Monetization.GamePasses[key].Name .. "  (owned)"
			b.BackgroundColor3 = OK
		end
	end
	refreshPerkButtons()
	refreshKitButtons()
	refreshCrateButtons()
	refreshRecipesTab()
	refreshCards()
	refreshQuests(stats.Quests)
	refreshTutorial()
	rebuildHotbar()
end

local receivedStats = false
StatsChanged.OnClientEvent:Connect(function(s)
	if receivedStats then
		local oldClaimed = (stats.Quests and stats.Quests.Claimed) or {}
		local newClaimed = (s.Quests and s.Quests.Claimed) or {}
		for questId, claimed in newClaimed do
			if claimed and not oldClaimed[questId] then
				local soundName = SfxMap.forEvent("quest done")
				if soundName then
					ClientFX.sound(soundName)
				end
			end
		end
	else
		receivedStats = true
	end
	stats = s
	setMusicSlider(s.MusicVolume)
	setSfxSlider(s.SfxVolume)
	setMouseLock(s.MouseLockEnabled ~= false)
	finalHud.SetCombatCamera(s.CombatCameraEnabled ~= false)
	finalHud.SetCinematicMode(s.UltimateCinematics or Settings.DefaultUltimateCinematics)
	refreshStats()
	onDailyPopup(s.DailyPopup)
end)
player:GetAttributeChangedSignal("DashReady"):Connect(refreshStats)
refreshStats()

-- State -> top labels and the shared wave/boss progress bar.
finalHud.WavePeakAlive = 0
onState("Wave", function(w)
	waveLabel.Text = if w > 0 then string.format("WAVE %d", w) else "SWARM BREAK"
	bossChipLabel.Text = if w > 0 then WaveTable.bossChipText(w) else ""
	finalHud.WavePeakAlive = 0
end)
local function refreshPhase()
	local phase = stateValue("Phase")
	local t = stateValue("TimeLeft")
	local alive = stateValue("Alive")
	-- Countdowns show time left; a fight shows how long this wave has run.
	local startedAt = workspace:GetAttribute("WaveStartedAt")
	local clock = if phase == "fighting" and type(startedAt) == "number"
		then workspace:GetServerTimeNow() - startedAt
		else t
	local wholeSeconds = math.max(0, math.floor(clock))
	if stateValue("BossMaxHealth") <= 0 then
		finalHud.WavePeakAlive = math.max(finalHud.WavePeakAlive, alive)
		bossFill.Size = UDim2.fromScale(
			if finalHud.WavePeakAlive > 0
				then math.clamp(1 - alive / finalHud.WavePeakAlive, 0, 1)
				else 0,
			1
		)
		bossLabel.Text = string.format(
			"%d LEFT   %d:%02d",
			alive,
			math.floor(wholeSeconds / 60),
			wholeSeconds % 60
		)
	end
	if phase == "idle" then
		phaseLabel.Text = "Waiting for players"
	elseif phase == "starting" then
		phaseLabel.Text = string.format("Get ready  %d", t)
	elseif phase == "fighting" then
		phaseLabel.Text = string.format("Enemies left: %d", alive)
	elseif phase == "intermission" then
		phaseLabel.Text = string.format("Shop open  %ds", t)
	elseif phase == "chest" then
		phaseLabel.Text = "Opening run chest"
	elseif phase == "over" then
		phaseLabel.Text = "Run over"
	end
end
onState("Phase", function(phase)
	refreshPhase()
	refreshCards()
	onDailyPhase(phase) -- the daily reward strip never covers a fight
	local fighting = phase == "fighting"
	if fighting then
		setUtilityPanel(nil)
	end
	phaseLabel.Visible = not fighting
	bossChipLabel.Visible = not fighting
	mutationLabel.Visible = not fighting and stateValue("MutationLabel") ~= ""
	bossFrame.Visible = true
	finalHud.CurrencyFrame.Visible = true
	if phase ~= "over" then
		summaryToken += 1
		summaryPanel.Visible = false
	end
	if phase == "idle" or phase == "starting" or phase == "intermission" then
		spectateLabel.Visible = false
	end
	if phase == "intermission" then
		setShop(false)
		banner.TextColor3 = WHITE
		local wave = stateValue("Wave")
		flash(banner, string.format("Wave clear  +%d Gold", 10 * wave), 2)
	elseif phase == "starting" then
		setShop(false)
		if stateValue("Wave") == 1 then
			flash(objectiveBanner, Onboarding.ObjectiveText, Onboarding.ObjectiveSeconds)
		else
			flash(banner, "WAVE " .. tostring(stateValue("Wave")), 2)
		end
	end
end)
onState("TimeLeft", function(timeLeft)
	refreshPhase()
	local openingCountdown = stateValue("Phase") == "starting"
		and stateValue("Wave") == 1
		and timeLeft > 0
		and timeLeft <= Onboarding.CountdownSeconds
	countdownLabel.Visible = openingCountdown
	countdownLabel.Text = if openingCountdown then tostring(math.ceil(timeLeft)) else ""
	if openingCountdown then
		ClientFX.sound("WaveStart")
	end
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		if stateValue("Phase") == "fighting" then
			refreshPhase()
		end
	end
end)
onState("Alive", refreshPhase)
onState("MutationLabel", function(label)
	mutationLabel.Text = "Today: " .. label
	mutationLabel.Visible = label ~= "" and stateValue("Phase") ~= "fighting"
end)

-- HP bar and hit feedback.
local lastHealth = 0
RunService.Heartbeat:Connect(function()
	refreshTutorial()
	enemyArrow.Visible = false
	if
		stateValue("Phase") == "fighting"
		and Onboarding.shouldShowArrow(stats.Kills or 0)
		and camera
	then
		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		local nearestRoot: BasePart? = nil
		local nearestDistance = math.huge
		if playerRoot and playerRoot:IsA("BasePart") then
			for _, enemy in enemiesFolder:GetChildren() do
				local root = enemy:FindFirstChild("HumanoidRootPart", true)
				if root and root:IsA("BasePart") then
					local distance = (root.Position - playerRoot.Position).Magnitude
					if distance < nearestDistance then
						nearestDistance = distance
						nearestRoot = root
					end
				end
			end
		end
		if nearestRoot then
			local point, onScreen = camera:WorldToViewportPoint(nearestRoot.Position)
			local center = camera.ViewportSize / 2
			local direction = Vector2.new(point.X, point.Y) - center
			if point.Z < 0 then
				direction = -direction
			end
			if direction.Magnitude > 0.01 then
				local radius = math.min(center.X, center.Y) * (if onScreen then 0.18 else 0.38)
				local position = center + direction.Unit * radius
				enemyArrow.Position = UDim2.fromOffset(position.X - 24, position.Y - 24)
				enemyArrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
				enemyArrow.Visible = true
			end
		end
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		if hum.Health < lastHealth - 0.5 then
			ClientFX.shake(1.5)
			ClientFX.sound("Hurt", nil, 0.3)
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				finalHud.showHitDirection(root.Position)
			end
		end
		lastHealth = hum.Health
		local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		hpFill.Size = UDim2.fromScale(frac, 1)
		hpFill.BackgroundColor3 = if frac > 0.5
			then OK
			else if frac > 0.25 then ClientFX.c3(Theme.SignalOrange) else BAD
		hpText.Text =
			string.format("HP %d / %d   STATS", math.floor(hum.Health), math.floor(hum.MaxHealth))
		local low = frac < 0.35 and hum.Health > 0
		vignette.Visible = low
		if low then
			vignette.BackgroundTransparency = 1
			for _, f in vignette:GetChildren() do
				if f:IsA("Frame") then
					f.BackgroundTransparency = 0.35 + 0.25 * math.sin(os.clock() * 5)
				end
			end
		end
	else
		hpText.Text = ""
	end
end)

-- End of run: the server sends each player their own summary (see PlayerData.endRun).
GameOver.OnClientEvent:Connect(function(summary: any)
	setShop(false)
	cardPanel.Visible = false
	if deathState == "alive" then
		deathState = DeathFlow.transition(deathState, "died")
	end
	if deathState == "dead" then
		deathState = DeathFlow.transition(deathState, "spectate")
	end
	deathState = DeathFlow.transition(deathState, "all-dead")
	summaryToken += 1
	local token = summaryToken
	local remaining = if diedAt
		then math.max(0, DeathFlow.SpectateSeconds - (os.clock() - diedAt))
		else DeathFlow.SpectateSeconds
	task.delay(remaining, function()
		if token ~= summaryToken or deathState ~= "summary" or stateValue("Phase") ~= "over" then
			return
		end
		spectateLabel.Visible = false
		summaryTitle.Text = if summary.NewMapUnlocked
			then "NEW MAP UNLOCKED\n" .. (summary.UnlockedMapName or "")
			else if summary.Won then "VICTORIOUS" else "RUN OVER"
		summaryWave.Text = "Wave " .. commas(summary.Wave or 0)
		summaryKills.Text = "Kills " .. commas(summary.Kills or 0)
		local goldDeposited = summary.GoldDeposited or 0
		local gemsDeposited = summary.GemsDeposited or summary.GemsEarned or 0
		summaryGems.Text = "Deposited: 0 Gold, 0 Gems"
		summaryPanel.Visible = true
		task.spawn(function()
			local startedAt = os.clock()
			local duration = 0.9
			while token == summaryToken and summaryPanel.Visible do
				local progress = math.clamp((os.clock() - startedAt) / duration, 0, 1)
				summaryGems.Text = string.format(
					"Deposited: %s Gold, %s Gems",
					commas(goldDeposited * progress),
					commas(gemsDeposited * progress)
				)
				if progress >= 1 then
					break
				end
				task.wait()
			end
		end)
	end)
end)

Toast.OnClientEvent:Connect(function(msg: string, seconds: number)
	flash(toast, msg, seconds or 3)
end)
Remotes.FX.OnClientEvent:Connect(function(kind: string, data: any)
	if kind == "aoeWarning" and typeof(data.Position) == "Vector3" then
		finalHud.showAreaWarning(data.Position, data.Radius or 6, data.Duration or 0.65)
	end
end)

CrateResult.OnClientEvent:Connect(
	function(
		id: string,
		rarity: string,
		isNew: boolean,
		gemsBack: number,
		crateKey: string,
		revealContext: string?
	)
		local def = Weapons.Defs[id]
		local c = Weapons.RarityColor[rarity]
		banner.TextColor3 = Color3.fromRGB(c[1], c[2], c[3])
		local msg = if isNew
			then string.format("%s: %s!", rarity, def.Name)
			else string.format("Duplicate %s: +%d Gems", def.Name, gemsBack)
		flash(
			banner,
			if revealContext == "RunEnd" then "CHEST OPEN  " .. msg else msg,
			if revealContext == "RunEnd" then LevelUp.ChestRevealSeconds else 4
		)
		-- crates we did not click open here (Robux receipts, the free first-boss crate) sound
		-- now; a Gem crate we asked for sounds once, when its request comes back
		if not (crateKey == "Gem" and gemCratePending) then
			ClientFX.sound("Crate")
		end
		task.delay(4.5, function()
			banner.TextColor3 = WHITE
		end)
	end
)
