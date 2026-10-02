--!strict
-- The whole HUD, built in code so it lives in files. Reads ReplicatedStorage.State.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

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
local Invite = require(ReplicatedStorage.Shared.Invite)
local UiTheme = require(ReplicatedStorage.Shared.UiTheme)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local UiKit = require(script.Parent.UiKit)

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local State = ReplicatedStorage:WaitForChild("State")
local StatsChanged = Remotes.StatsChanged :: RemoteEvent
local GameOver = Remotes.GameOver :: RemoteEvent
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

local screen = Instance.new("ScreenGui")
screen.Name = "Hud"
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screen.Parent = gui

local platform: HudLayout.Platform = if UserInputService.TouchEnabled
	then "touch"
	else if UserInputService.GamepadEnabled then "gamepad" else "keyboard"
local camera = workspace.CurrentCamera
local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720) -- placeholder
local currentScale = HudLayout.scaleFor(viewport.X, viewport.Y, platform)
local hudScale = Instance.new("UIScale")
hudScale.Scale = currentScale
hudScale.Parent = screen
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
	f.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
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
finalHud.HitDirection.TextColor3 = Color3.fromRGB(255, 50, 50)
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

-- Top: wave / phase / alive
local waveLabel = text(screen, "Wave", UDim2.new(0.5, -200, 0, 8), UDim2.new(0, 400, 0, 34), "", 28)
waveLabel.TextXAlignment = Enum.TextXAlignment.Left
finalHud.TimerLabel =
	text(screen, "RoundTimer", UDim2.new(0.5, 0, 0, 8), UDim2.new(0, 200, 0, 34), "0:00", 24)
finalHud.TimerLabel.TextXAlignment = Enum.TextXAlignment.Right
local bossChipLabel =
	text(screen, "BossChip", UDim2.new(0.5, -100, 0, 42), UDim2.new(0, 200, 0, 18), "", 13)
bossChipLabel.TextColor3 = Color3.fromRGB(255, 160, 80)
local phaseLabel =
	text(screen, "Phase", UDim2.new(0.5, -200, 0, 60), UDim2.new(0, 400, 0, 22), "", 18)
phaseLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
local mutationLabel =
	text(screen, "Mutation", UDim2.new(0.5, -240, 0, 82), UDim2.new(0, 480, 0, 18), "", 14)
mutationLabel.TextColor3 = Color3.fromRGB(255, 200, 60)

-- Boss bar
local bossFrame = UiKit.Panel(screen, "BossBar")
bossFrame.Size = UDim2.new(0, 480, 0, 22)
bossFrame.Position = UDim2.new(0.5, -240, 0, 106)
bossFrame.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
bossFrame.BorderSizePixel = 0
bossFrame.Visible = false
bossFrame.Parent = screen
local bossFill = Instance.new("Frame")
bossFill.Size = UDim2.fromScale(1, 1)
bossFill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
bossFill.BorderSizePixel = 0
bossFill.Parent = bossFrame
local bossLabel = text(bossFrame, "BossName", UDim2.new(0, 0, 0, 0), UDim2.fromScale(1, 1), "", 16)

-- Run currency is useful between waves, but the fighting HUD stays clear.
finalHud.CurrencyFrame = Instance.new("Frame")
finalHud.CurrencyFrame.Name = "Currencies"
finalHud.CurrencyFrame.BackgroundColor3 = PANEL
finalHud.CurrencyFrame.BackgroundTransparency = 0.1
finalHud.CurrencyFrame.BorderSizePixel = 0
finalHud.CurrencyFrame.Visible = false
finalHud.CurrencyFrame.Parent = screen
local currencyCorner = Instance.new("UICorner")
currencyCorner.CornerRadius = UDim.new(0, 8)
currencyCorner.Parent = finalHud.CurrencyFrame
finalHud.CoinsLabel = text(
	finalHud.CurrencyFrame,
	"Coins",
	UDim2.fromScale(0, 0),
	UDim2.fromScale(0.5, 1),
	"Coins 0",
	18
)
finalHud.CoinsLabel.TextColor3 = ClientFX.c3(Theme.Coin)
finalHud.GemsLabel = text(
	finalHud.CurrencyFrame,
	"Gems",
	UDim2.fromScale(0.5, 0),
	UDim2.fromScale(0.5, 1),
	"Gems 0",
	18
)
finalHud.GemsLabel.TextColor3 = ClientFX.c3(Theme.NeonTeal)

-- Bottom-left: HP. Detailed run stats live behind this bar instead of in persistent rows.
local hpBack = UiKit.Panel(screen, "Health")
hpBack.Size = UDim2.new(0, 260, 0, 18)
hpBack.Position = UDim2.new(0, 12, 1, -80)
hpBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
hpBack.BorderSizePixel = 0
hpBack.Parent = screen
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = OK
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBack
local hpText = text(hpBack, "HP", UDim2.new(0, 0, 0, 0), UDim2.fromScale(1, 1), "", 14)
finalHud.StatsToggle = Instance.new("TextButton")
finalHud.StatsToggle.Name = "OpenStats"
finalHud.StatsToggle.Size = UDim2.fromScale(1, 1)
finalHud.StatsToggle.BackgroundTransparency = 1
finalHud.StatsToggle.Text = ""
finalHud.StatsToggle.ZIndex = hpText.ZIndex + 1
finalHud.StatsToggle.Parent = hpBack

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

-- Full-width run XP, pinned to the bottom edge by HudLayout.
local xpBack = Instance.new("Frame")
xpBack.Name = "XP"
xpBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
xpBack.BorderSizePixel = 0
xpBack.ClipsDescendants = true
xpBack.Parent = screen
local xpFill = Instance.new("Frame")
xpFill.Name = "Fill"
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = ClientFX.c3(Theme.NeonTeal)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBack
local xpText = text(xpBack, "Value", UDim2.new(), UDim2.fromScale(1, 1), "", 11)
xpText.ZIndex = xpFill.ZIndex + 1

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
		item.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
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
		bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
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
settingsPanel.Size = UDim2.new(0, 260, 0, 116)
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
	track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
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

-- Weapon switching remains on number keys; the clean fighting HUD shows ammo instead of cards.
local hotbar = Instance.new("Frame")
hotbar.Size = UDim2.new(0, 420, 0, 46)
hotbar.Position = UDim2.new(1, -432, 1, -72)
hotbar.BackgroundTransparency = 1
hotbar.Visible = false
hotbar.Parent = screen
local hotLayout = Instance.new("UIListLayout")
hotLayout.FillDirection = Enum.FillDirection.Horizontal
hotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
hotLayout.Padding = UDim.new(0, 4)
hotLayout.Parent = hotbar
-- Under the hotbar: this run's reward cards as "Sharp x2  Greed x1" (empty until a pick)
local boostsLabel =
	text(screen, "Boosts", UDim2.new(1, -432, 1, -24), UDim2.new(0, 420, 0, 14), "", 12)
boostsLabel.TextXAlignment = Enum.TextXAlignment.Right
boostsLabel.TextColor3 = ClientFX.c3(Theme.NeonTeal)
boostsLabel.Visible = false

finalHud.AmmoLabel = text(screen, "Ammo", UDim2.new(), UDim2.new(), "AMMO UNLIMITED", 18)
finalHud.AmmoLabel.TextXAlignment = Enum.TextXAlignment.Right

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
local toast = text(screen, "Toast", UDim2.new(0.5, -300, 0.2, 0), UDim2.new(0, 600, 0, 30), "", 20)
toast.Visible = false
-- the banner and the toast float above everything else, the reward cards included
banner.ZIndex = 4
toast.ZIndex = 4

local function flash(label: TextLabel, str: string, seconds: number)
	label.Text = str
	label.Visible = true
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.4
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
	warning.Color = Color3.fromRGB(255, 40, 40)
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

local goalBannerToken = 0
local function showSpawnGoal()
	goalBannerToken += 1
	local token = goalBannerToken
	task.delay(0.25, function()
		if token == goalBannerToken and stateValue("Wave") <= 1 then
			flash(banner, "Survive 5 waves", 3)
		end
	end)
end
player.CharacterAdded:Connect(showSpawnGoal)
if player.Character then
	task.defer(showSpawnGoal)
end

-- Latest stats snapshot from the server (filled by StatsChanged below)
local stats: any

-- The parts of the stats snapshot that the pure profile helpers (perk costs, next goal) read.
local function profileSnapshot(): any
	return {
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
local cardPanel = Instance.new("Frame")
cardPanel.Name = "RewardCards"
cardPanel.Size = UDim2.new(0, 600, 0, 200)
cardPanel.Position = UDim2.new(0.5, -300, 0.3, 0)
cardPanel.BackgroundTransparency = 1
cardPanel.Visible = false
cardPanel.ZIndex = 2 -- above the shop panel
cardPanel.Parent = screen
local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Horizontal
cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
cardLayout.Padding = UDim.new(0, 12)
cardLayout.Parent = cardPanel

local cardIds: { string } = {} -- ids on offer in card order (key 1 = first card)
local cardKey = "" -- the offer the cards were last built from
local cardPending = false -- our pick is in flight

local function pickCard(id: string)
	if cardPending then
		return
	end
	cardPending = true
	-- pcall: a failed invoke (server error, remote gone on teleport) must never leave cardPending
	-- stuck and every later offer unpickable. The server's auto-pick still saves the reward.
	local called, ok, why = pcall(function()
		return PickReward:InvokeServer(id)
	end)
	cardPending = false
	if not called then
		warn("PickReward failed:", ok)
	end
	if called and ok == true then
		local def = WaveRewards.Defs[id]
		ClientFX.sound("Buy")
		flash(toast, "Picked: " .. (if def then def.Label else id), 2)
		cardIds = {}
		cardPanel.Visible = false
	else
		ClientFX.sound("Deny")
		if called and typeof(why) == "string" and why ~= "" then
			flash(toast, why, 2.5)
		end
	end
end

local function rebuildCards(offer: { string }, rarities: { [string]: string })
	for _, c in cardPanel:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	cardIds = {}
	for _, id in offer do
		local def = WaveRewards.Defs[id]
		if def and #cardIds < WaveRewards.OfferSize then
			table.insert(cardIds, id)
			local i = #cardIds
			local b = UiKit.Button(cardPanel, "", UDim2.new(0, 184, 0, 180))
			b.Name = "Card" .. i
			local targetSize = UDim2.new(0, 184, 0, 180)
			b.Size = UDim2.new(0, 0, 0, 180)
			b.Text = ""
			b.BackgroundColor3 = PANEL
			b.BorderSizePixel = 0
			b.Active = false
			b.ClipsDescendants = true
			b.LayoutOrder = i
			local rarity = rarities[id] or "Common"
			local rarityColor = ClientFX.c3(Theme.Rarity[rarity] or Theme.Rarity.Common)
			local outline = b:FindFirstChild("Outline")
			if outline and outline:IsA("UIStroke") then
				outline.Color = rarityColor
				outline.Thickness = 2
			end
			local stripe = Instance.new("Frame") -- rarity colour reads before the card text
			stripe.Name = "Stripe"
			stripe.Size = UDim2.new(1, -20, 0, 4)
			stripe.Position = UDim2.new(0, 10, 0, 0)
			stripe.BackgroundColor3 = rarityColor
			stripe.BorderSizePixel = 0
			stripe.Parent = b
			local rarityLabel = text(
				b,
				"Rarity",
				UDim2.new(0, 10, 0, 12),
				UDim2.new(1, -20, 0, 18),
				string.upper(rarity),
				11
			)
			rarityLabel.TextColor3 = rarityColor
			text(b, "Label", UDim2.new(0, 10, 0, 32), UDim2.new(1, -20, 0, 26), def.Label, 18)
			local blurb =
				text(b, "Blurb", UDim2.new(0, 10, 0, 64), UDim2.new(1, -20, 0, 76), def.Blurb, 13)
			blurb.Font = Enum.Font.Gotham
			blurb.TextWrapped = true
			blurb.TextYAlignment = Enum.TextYAlignment.Top
			blurb.TextColor3 = Color3.fromRGB(210, 210, 220)
			local hint = text(
				b,
				"Key",
				UDim2.new(0, 10, 1, -28),
				UDim2.new(1, -20, 0, 20),
				"Press " .. i,
				12
			)
			hint.TextColor3 = Color3.fromRGB(160, 160, 175)
			b.MouseButton1Click:Connect(function()
				pickCard(id)
			end)
			task.delay((i - 1) * 0.08, function()
				if b.Parent then
					TweenService:Create(
						b,
						TweenInfo.new(LevelUp.CardFlipSeconds, Enum.EasingStyle.Quad),
						{ Size = targetSize }
					):Play()
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
	local rarityKey = {}
	for _, id in offer do
		table.insert(rarityKey, rarities[id] or "Common")
	end
	local offerKey = table.concat(offer, "|") .. ":" .. table.concat(rarityKey, "|")
	if offerKey ~= cardKey then
		cardKey = offerKey
		rebuildCards(offer, rarities)
	end
	local phase = stateValue("Phase")
	cardPanel.Visible = #cardIds > 0 and (phase == "fighting" or phase == "intermission")
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not cardPanel.Visible then
		return
	end
	local n = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
	if n >= 1 and n <= #cardIds then
		pickCard(cardIds[n])
	end
end)

-- Lobby perk buttons (Gems, forever). One helper builds them for both the shop and the run
-- summary panel; refreshPerkButtons repaints every one from the latest stats.
local perkButtons: { { Key: string, Button: TextButton } } = {}
local function refreshPerkButtons()
	local p = profileSnapshot()
	for _, row in perkButtons do
		local def = ProfileSchema.PerkDefs[row.Key]
		local cost = ProfileSchema.perkCost(p, row.Key)
		if cost then
			local lvl = ProfileSchema.perkLevel(p, row.Key)
			row.Button.Text = string.format("%s  Lv %d  ->  %d Gems", def.Label, lvl + 1, cost)
			row.Button.BackgroundColor3 = if p.Gems >= cost then BUTTON else GREY
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
	l.TextColor3 = Color3.fromRGB(255, 200, 60)
	l.LayoutOrder = order
end
local function shopButton(str: string): TextButton
	order += 1
	local b = button(shop, str, UDim2.new(1, 0, 0, 34))
	b.LayoutOrder = order
	return b
end

section("UPGRADES (coins)")
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
	odds.TextColor3 = Color3.fromRGB(200, 200, 200)
end

section("WEAPON EVOLUTION (Gems + shards, forever)")
order += 1
local evoInfo = text(shop, "EvoInfo", UDim2.new(), UDim2.new(1, 0, 0, 36), "", 12)
evoInfo.LayoutOrder = order
evoInfo.TextXAlignment = Enum.TextXAlignment.Left
evoInfo.TextYAlignment = Enum.TextYAlignment.Top
evoInfo.TextWrapped = true
evoInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
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

section("PERKS (Gems, forever)")
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
		b.Text = string.format("%s\n%s\n%s", def.Label, def.Blurb, cost)
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

section("COINS (Robux)")
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
closeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)

-- Third button in the compact utility icon column.
local shopToggle = button(screen, "$", UDim2.fromOffset(48, 48))
shopToggle.Name = "ShopToggle"
shopToggle.Position = UDim2.new(1, -122, 0, 8)
local reviveBtn = button(screen, "REVIVE NOW (Robux)", UDim2.new(0, 220, 0, 40))
reviveBtn.Position = UDim2.new(0.5, -110, 0.6, 0)
reviveBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 30)
reviveBtn.Visible = false
reviveBtn.MouseButton1Click:Connect(function()
	Prompt:FireServer("product", "Revive")
end)
local deathInviteBtn = button(screen, "Invite a friend", reviveBtn.Size)
deathInviteBtn.Position = reviveBtn.Position + UDim2.new(0, 0, 0, 48) -- placeholder
deathInviteBtn.Visible = false

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

	local wave = rects.waveTimer
	waveLabel.Position = UDim2.fromOffset(logical(wave.x), logical(wave.y))
	waveLabel.Size = UDim2.fromOffset(logical(wave.w) / 2, 34)
	finalHud.TimerLabel.Position = UDim2.fromOffset(logical(wave.x + wave.w / 2), logical(wave.y))
	finalHud.TimerLabel.Size = UDim2.fromOffset(logical(wave.w) / 2, 34)
	bossChipLabel.Position =
		UDim2.fromOffset(logical(wave.x + (wave.w - 200 * currentScale) / 2), logical(wave.y) + 34)
	bossChipLabel.Size = UDim2.fromOffset(200, 18)
	phaseLabel.Position = UDim2.fromOffset(logical(wave.x), logical(wave.y) + 52)
	phaseLabel.Size = UDim2.fromOffset(logical(wave.w), 22)
	mutationLabel.Position = UDim2.fromOffset(logical(wave.x), logical(wave.y) + 74)
	mutationLabel.Size = UDim2.fromOffset(logical(wave.w), 18)

	local boss = rects.bossBar
	bossFrame.Position = UDim2.fromOffset(logical(boss.x), logical(boss.y))
	bossFrame.Size = UDim2.fromOffset(logical(boss.w), logical(boss.h))

	local health = rects.health
	hpBack.Position = UDim2.fromOffset(logical(health.x), logical(health.y))
	hpBack.Size = UDim2.fromOffset(logical(health.w), logical(health.h))

	local xp = rects.xp
	xpBack.Position = UDim2.fromOffset(logical(xp.x), logical(xp.y))
	xpBack.Size = UDim2.fromOffset(logical(xp.w), logical(xp.h))

	local ammo = rects.ammo
	finalHud.AmmoLabel.Position = UDim2.fromOffset(logical(ammo.x), logical(ammo.y))
	finalHud.AmmoLabel.Size = UDim2.fromOffset(logical(ammo.w), logical(ammo.h))

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
	settingsPanel.Size = UDim2.fromOffset(logical(settings.w), 116)

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
	cardPanel.Position = UDim2.fromOffset(logical(rewardRect.x), logical(rewardRect.y))
	cardPanel.Size = UDim2.fromOffset(logical(rewardRect.w), logical(rewardRect.h))
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

-- Run summary panel: what the run earned, the next forever-unlock, and perks to buy right here.
-- Shown on GameOver, hidden when the Phase leaves "over".
local summaryPanel = UiKit.Panel(screen, "Summary")
summaryPanel.Name = "RunSummary"
summaryPanel.Size = UDim2.new(0, 460, 0, 420) -- placeholder
summaryPanel.Position = UDim2.new(0.5, -230, 0.5, -210) -- placeholder
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
local summaryBest = summaryRow("NewBest", 20, 16)
summaryBest.Text = "NEW BEST"
summaryBest.TextColor3 = ClientFX.c3(Theme.NeonAmber)
summaryBest.Visible = false
local summaryKills = summaryRow("Kills", 18, 16)
local summaryCoins = summaryRow("Coins", 18, 16)
local summaryGems = summaryRow("Gems", 18, 16)
local summaryShards = summaryRow("Shards", 18, 16)
local goalLabel = summaryRow("Goal", 20, 16)
goalLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
for _, l in { summaryKills, summaryCoins, summaryGems, summaryShards, goalLabel } do
	l.TextXAlignment = Enum.TextXAlignment.Left
end
summaryOrder += 1
local goalBar = Instance.new("Frame")
goalBar.Name = "GoalBar"
goalBar.Size = UDim2.new(1, 0, 0, 14)
goalBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
goalBar.BorderSizePixel = 0
goalBar.LayoutOrder = summaryOrder
goalBar.Parent = summaryPanel
local goalFill = Instance.new("Frame")
goalFill.Name = "Fill"
goalFill.Size = UDim2.fromScale(0, 1)
goalFill.BackgroundColor3 = OK
goalFill.BorderSizePixel = 0
goalFill.Parent = goalBar
local goalText = summaryRow("GoalText", 18, 14)
goalText.TextXAlignment = Enum.TextXAlignment.Left
for _, key in Goals.PerkOrder do
	summaryOrder += 1
	perkRow(summaryPanel, key, 28).LayoutOrder = summaryOrder
end
summaryOrder += 1
local summaryInviteBtn = button(summaryPanel, "Invite a friend", UDim2.new(1, 0, 0, 34)) -- placeholder
summaryInviteBtn.LayoutOrder = summaryOrder
summaryInviteBtn.Visible = false
local summaryFooter = summaryRow("Footer", 20, 14)
summaryFooter.TextColor3 = Color3.fromRGB(200, 200, 200)

local summaryEarned = 0 -- Gems this run paid, kept for the row after the count-up
local summaryCounting = 0 -- token: a newer summary cancels an older count-up
local lastInviteShownAt: number? = nil

local function canSendGameInvite(): boolean
	local ok, canSend = pcall(function(): boolean
		return SocialService:CanSendGameInviteAsync(player)
	end)
	return ok and canSend
end

local function connectInviteButton(inviteButton: TextButton)
	inviteButton.MouseButton1Click:Connect(function()
		if not canSendGameInvite() then
			inviteButton.Visible = false
			return
		end
		SocialService:PromptGameInvite(player)
	end)
end

local function offerInvite(
	inviteButton: TextButton,
	moment: "summary" | "death",
	isStillActive: () -> boolean
)
	inviteButton.Visible = false
	local now = os.clock()
	if not Invite.shouldShow(#Players:GetPlayers(), moment, lastInviteShownAt, now) then
		return
	end
	task.spawn(function()
		if not canSendGameInvite() or not isStillActive() then
			inviteButton.Visible = false
			return
		end
		local shownAt = os.clock()
		if Invite.shouldShow(#Players:GetPlayers(), moment, lastInviteShownAt, shownAt) then
			inviteButton.Visible = true
			lastInviteShownAt = shownAt
		end
	end)
end

connectInviteButton(summaryInviteBtn)
connectInviteButton(deathInviteBtn)

local function watchCharacter(character: Model)
	deathInviteBtn.Visible = false
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		offerInvite(deathInviteBtn, "death", function(): boolean
			return stateValue("Phase") == "fighting"
				and humanoid.Health <= 0
				and not summaryPanel.Visible
		end)
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

local function refreshGoal(goal: any)
	if not goal then
		goalLabel.Text = "Everything unlocked. Chase the board."
		goalBar.Visible = false
		goalText.Visible = false
		return
	end
	goalBar.Visible = true
	goalText.Visible = true
	goalLabel.Text = "Next: " .. tostring(goal.Label)
	local have = goal.Have or 0
	local need = math.max(goal.Need or 1, 1)
	goalFill.Size = UDim2.fromScale(math.clamp(have / need, 0, 1), 1)
	goalText.Text = if have >= need
		then "Ready to buy"
		else string.format("%d / %d Gems", have, need)
end

-- Daily reward strip: the server pays today's login streak slot when the profile loads and the
-- popup rides on StatsChanged (PlayerData.claimDaily). It shows once per session and never over
-- a fight: a popup that lands mid-wave waits for the next phase, and a wave that starts while
-- the strip is still up hides it until the wave ends.
local DAILY_LATER = Color3.fromRGB(40, 40, 50) -- a day not reached yet
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
	r.Font = Enum.Font.Gotham
	r.TextWrapped = true
	table.insert(dailyBoxes, box)
end
local dailyNext = text(dailyBody, "Next", UDim2.new(0, 14, 0, 98), UDim2.new(1, -28, 0, 20), "", 14)
dailyNext.TextXAlignment = Enum.TextXAlignment.Left
dailyNext.TextColor3 = Color3.fromRGB(200, 200, 200)

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
			dailyPending = true
			hideDaily()
		end
	elseif dailyPending and dailyPopup then
		dailyPending = false
		showDaily(dailyPopup)
	end
end

-- Stats -> labels, upgrade buttons, hotbar
stats = {
	Coins = 0,
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
	XP = 0,
	Level = 0,
	XPNeeded = LevelUp.requiredXp(1),
	Quests = {},
	Flags = {},
	MusicVolume = Settings.DefaultVolume,
	SfxVolume = Settings.DefaultVolume,
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
	for i, id in ids do
		local def = Weapons.Defs[id]
		local b = button(
			hotbar,
			string.format("%d  %s\n%s", i, def.Name, def.Kind),
			UDim2.new(0, 100, 1, 0)
		)
		b.TextSize = 11
		b.TextWrapped = true
		local c = Weapons.RarityColor[def.Rarity]
		b.BackgroundColor3 = if id == stats.Equipped
			then Color3.fromRGB(c[1], c[2], c[3])
			else Color3.fromRGB(40, 40, 50)
		b.MouseButton1Click:Connect(function()
			EquipWeapon:FireServer(id)
		end)
	end
	-- number keys
	stats._hotIds = ids
end

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
	local shards = stats.Shards or {}
	finalHud.CoinsLabel.Text = string.format("Coins %d", stats.Coins or 0)
	finalHud.GemsLabel.Text = string.format("Gems %d", stats.Gems or 0)
	statsLabel.Text = string.format(
		"Kills %d    Level %d    Dash %d\nCoins %d    Gems %d\nShards  Nature %d  Tech %d  Lightning %d  Dark %d",
		stats.Kills,
		stats.Level or 0,
		dash,
		stats.Coins or 0,
		stats.Gems or 0,
		shards.Nature or 0,
		shards.Tech or 0,
		shards.Lightning or 0,
		shards.Dark or 0
	)
	local xp = stats.XP or 0
	local xpNeeded = math.max(stats.XPNeeded or 1, 1)
	xpFill.Size = UDim2.fromScale(math.clamp(xp / xpNeeded, 0, 1), 1)
	xpText.Text = string.format("LEVEL %d    XP %d / %d", stats.Level or 0, xp, xpNeeded)
	-- Evolution section follows the equipped weapon
	local equippedDef = Weapons.Defs[stats.Equipped]
	finalHud.AmmoLabel.Text = string.format(
		"%s   AMMO UNLIMITED",
		if equippedDef then string.upper(equippedDef.Name) else "WEAPON"
	)
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
				else Color3.fromRGB(60, 60, 70)
		else
			b.Text = string.format("%s  %s", element, why)
			b.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		end
		b.TextSize = 12
	end
	for name, b in upgradeButtons do
		local level = (stats.Levels and stats.Levels[name]) or 0
		local cost = Upgrades.costAt(name, level)
		local u = Upgrades.def(name)
		local label = if u then u.Label else name
		if cost then
			b.Text = string.format("%s  Lv %d  ->  %d coins", label, level, cost)
			b.BackgroundColor3 = if stats.Coins >= cost then BUTTON else Color3.fromRGB(60, 60, 70)
		else
			b.Text = string.format("%s  MAX", label)
			b.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
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
	boostsLabel.Text = WaveRewards.stacksText((stats.Boosts and stats.Boosts.Stacks) or {})
	refreshCards()
	refreshQuests(stats.Quests)
	refreshTutorial()
	if summaryPanel.Visible then
		-- a perk bought from the panel moves the goal on and updates the Gems total
		refreshGoal(Goals.next(profileSnapshot()))
		if summaryCounting == 0 then
			summaryGems.Text = string.format("Gems +%d  (now %d)", summaryEarned, stats.Gems or 0)
		end
	end
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
	refreshStats()
	onDailyPopup(s.DailyPopup)
end)
player:GetAttributeChangedSignal("DashReady"):Connect(refreshStats)
refreshStats()

-- State -> top labels
onState("Wave", function(w)
	waveLabel.Text = if w > 0 then string.format("WAVE %d", w) else "SWARM BREAK"
	bossChipLabel.Text = if w > 0 then WaveTable.bossChipText(w) else ""
end)
local function refreshPhase()
	local phase = stateValue("Phase")
	local t = stateValue("TimeLeft")
	local alive = stateValue("Alive")
	local wholeSeconds = math.max(0, math.floor(t))
	finalHud.TimerLabel.Text =
		string.format("%d:%02d", math.floor(wholeSeconds / 60), wholeSeconds % 60)
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
		phaseLabel.Text = string.format("Restarting in %d", t)
		summaryFooter.Text = string.format("Play again in %d", t)
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
	bossFrame.Visible = not fighting and stateValue("BossName") ~= ""
	finalHud.CurrencyFrame.Visible = false
	if phase ~= "over" then
		summaryPanel.Visible = false
		summaryInviteBtn.Visible = false
	end
	if phase ~= "fighting" then
		deathInviteBtn.Visible = false
	end
	if phase == "intermission" then
		setShop(false)
		banner.TextColor3 = WHITE
		local wave = stateValue("Wave")
		flash(banner, string.format("Wave clear  +%d Coins", 10 * wave), 2)
	elseif phase == "starting" then
		setShop(false)
		flash(banner, "WAVE " .. tostring(stateValue("Wave")), 2)
	end
end)
onState("TimeLeft", refreshPhase)
onState("Alive", refreshPhase)
onState("MutationLabel", function(label)
	mutationLabel.Text = "Today: " .. label
	mutationLabel.Visible = label ~= "" and stateValue("Phase") ~= "fighting"
end)
onState("BossName", function(name)
	bossFrame.Visible = name ~= "" and stateValue("Phase") ~= "fighting"
	bossLabel.Text = name
end)
local function refreshBoss()
	local max = stateValue("BossMaxHealth")
	local h = stateValue("BossHealth")
	bossFill.Size = UDim2.fromScale(if max > 0 then math.clamp(h / max, 0, 1) else 0, 1)
end
onState("BossHealth", refreshBoss)
onState("BossMaxHealth", refreshBoss)

-- HP bar + revive visibility
local lastHealth = 0
RunService.Heartbeat:Connect(function()
	refreshTutorial()
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
			else if frac > 0.25 then Color3.fromRGB(220, 160, 40) else BAD
		hpText.Text =
			string.format("HP %d / %d   STATS", math.floor(hum.Health), math.floor(hum.MaxHealth))
		reviveBtn.Visible = hum.Health <= 0 and stateValue("Phase") == "fighting"
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
		reviveBtn.Visible = stateValue("Phase") == "fighting"
	end
end)

-- End of run: the server sends each player their own summary (see PlayerData.endRun).
GameOver.OnClientEvent:Connect(function(summary: any)
	setShop(false)
	cardPanel.Visible = false
	deathInviteBtn.Visible = false
	local wave = summary.Wave or 0
	summaryTitle.Text = if summary.Won
		then string.format("SURVIVED TO WAVE %d", wave)
		else string.format("FELL ON WAVE %d", wave)
	summaryBest.Visible = summary.NewBest == true
	summaryKills.Text = "Kills " .. commas(summary.Kills or 0)
	summaryCoins.Text = "Coins " .. commas(summary.Coins or 0)
	summaryShards.Text = string.format("Shards +%d", summary.ShardsEarned or 0)
	refreshGoal(summary.Goal)
	refreshPerkButtons()
	summaryPanel.Visible = true
	offerInvite(summaryInviteBtn, "summary", function(): boolean
		return summaryPanel.Visible
	end)
	-- Gems count up from 0 to what the run paid over one second, a coin tick per step
	summaryEarned = summary.GemsEarned or 0
	local total = summary.Gems or 0
	summaryCounting += 1
	local token = summaryCounting
	task.spawn(function()
		for step = 1, 10 do
			if token ~= summaryCounting or not summaryPanel.Visible then
				return
			end
			local shown = math.floor(summaryEarned * step / 10 + 0.5)
			summaryGems.Text = string.format("Gems +%d  (now %d)", shown, total)
			ClientFX.sound("Coin")
			task.wait(0.1)
		end
		if token == summaryCounting then
			summaryCounting = 0
		end
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
