--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BossFight = require(ReplicatedStorage.Shared.BossFight)
local Rules = require(ReplicatedStorage.Shared.ScreenEffects)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local BossBar = {}
local DISPLAY_NAMES = {
	Brute = "Big Brute",
	Queen = "Swarm Queen",
	Warden = "Sky King",
}

local function label(
	parent: Instance,
	name: string,
	position: UDim2,
	size: UDim2,
	content: string,
	textSize: number
): TextLabel
	return UiKit.Label(parent, name, position, size, content, textSize)
end

function BossBar.new(parent: Instance, waveFrame: Frame, state: Folder, introRemote: RemoteEvent)
	local health = state:WaitForChild("BossHealth") :: NumberValue
	local maxHealth = state:WaitForChild("BossMaxHealth") :: NumberValue
	local bossName = state:WaitForChild("BossName") :: StringValue
	local root = Instance.new("Frame")
	root.Name = "BossHealth"
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = parent

	local portraitSlot = Instance.new("Frame")
	portraitSlot.Name = "PortraitSlot"
	portraitSlot.Size = UDim2.fromOffset(54, 54)
	portraitSlot.BackgroundColor3 = ClientFX.c3(Theme.ChitinDark)
	portraitSlot.BorderSizePixel = 0
	portraitSlot.Parent = root
	local portraitOutline = Instance.new("UIStroke")
	portraitOutline.Name = "Outline"
	portraitOutline.Thickness = 4
	portraitOutline.Parent = portraitSlot
	local portrait = Instance.new("ImageLabel")
	portrait.Name = "Portrait"
	portrait.Size = UDim2.fromScale(1, 1)
	portrait.BackgroundTransparency = 1
	portrait.Parent = portraitSlot
	local initial = label(portraitSlot, "Initial", UDim2.new(), UDim2.fromScale(1, 1), "?", 32)
	initial.Font = UiKit.Fonts.Banner

	local namePlate =
		label(root, "NamePlate", UDim2.fromOffset(62, 0), UDim2.new(1, -62, 0, 26), "", 22)
	namePlate.Font = UiKit.Fonts.Banner
	namePlate.TextXAlignment = Enum.TextXAlignment.Left
	namePlate.TextStrokeTransparency = 0
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(62, 31)
	track.Size = UDim2.new(1, -62, 0, 22)
	track.BackgroundColor3 = ClientFX.c3(Theme.ChitinDark)
	track.BorderSizePixel = 0
	track.ClipsDescendants = false
	track.Parent = root
	local trackOutline = Instance.new("UIStroke")
	trackOutline.Name = "Outline"
	trackOutline.Thickness = 4
	trackOutline.Parent = track
	local trail = Instance.new("Frame")
	trail.Name = "DamageTrail"
	trail.Size = UDim2.fromScale(1, 1)
	trail.BackgroundColor3 = Color3.new(1, 1, 1)
	trail.BorderSizePixel = 0
	trail.ZIndex = track.ZIndex + 1
	trail.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = trail.ZIndex + 1
	fill.Parent = track
	local value = label(track, "Value", UDim2.new(), UDim2.fromScale(1, 1), "", 13)
	value.TextStrokeTransparency = 0
	value.ZIndex = fill.ZIndex + 2

	local notches: { Frame } = {}
	for index, ratio in Rules.phaseNotches() do
		local notch = Instance.new("Frame")
		notch.Name = "PhaseNotch" .. index
		notch.AnchorPoint = Vector2.new(0.5, 0.5)
		notch.Position = UDim2.fromScale(ratio, 0.5)
		notch.Size = UDim2.fromOffset(5, 30)
		notch.BackgroundColor3 = ClientFX.c3(Theme.Goo)
		notch.BorderSizePixel = 0
		notch.ZIndex = value.ZIndex + 1
		notch.Parent = track
		local scale = Instance.new("UIScale")
		scale.Name = "PopScale"
		scale.Parent = notch
		table.insert(notches, notch)
	end
	local flash = Instance.new("Frame")
	flash.Name = "PhaseFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = value.ZIndex + 2
	flash.Parent = root

	local controller = { Root = root, BasePosition = UDim2.new() }
	local shown = false
	local introToken = 0
	local previousHealth = 0
	local previousMax = 0
	local previousPhase = 1
	local trailTween: Tween? = nil
	local shakeToken = 0

	local function show()
		if maxHealth.Value <= 0 then
			return
		end
		shown = true
		waveFrame.Visible = false
		root.Visible = true
		root.Position =
			UDim2.new(controller.BasePosition.X.Scale, controller.BasePosition.X.Offset, 0, -70)
		TweenService:Create(
			root,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = controller.BasePosition }
		):Play()
	end

	local function hide()
		introToken += 1
		shown = false
		local tween = TweenService:Create(
			root,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = UDim2.new(
					controller.BasePosition.X.Scale,
					controller.BasePosition.X.Offset,
					0,
					-70
				),
			}
		)
		tween:Play()
		tween.Completed:Once(function()
			if not shown then
				root.Visible = false
				waveFrame.Visible = true
			end
		end)
	end

	local function shake()
		shakeToken += 1
		local token = shakeToken
		task.spawn(function()
			local startedAt = os.clock()
			while token == shakeToken do
				local progress = (os.clock() - startedAt) / Rules.ShakeSeconds
				if progress >= 1 then
					break
				end
				local x, y = Rules.shakeOffset(progress)
				root.Position = controller.BasePosition + UDim2.fromOffset(x, y)
				task.wait()
			end
			if token == shakeToken then
				root.Position = controller.BasePosition
			end
		end)
	end

	local function popPhase(phase: number)
		flash.BackgroundTransparency = 0.2
		TweenService:Create(flash, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		local notch = notches[phase - 1]
		local scale = notch and notch:FindFirstChild("PopScale") :: UIScale?
		if scale then
			scale.Scale = 1.7
			TweenService:Create(
				scale,
				TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
	end

	local function refresh()
		local maximum = maxHealth.Value
		local current = health.Value
		if maximum <= 0 then
			if previousMax > 0 then
				hide()
			end
			previousHealth, previousMax, previousPhase = 0, 0, 1
			return
		end
		waveFrame.Visible = false
		local ratio = math.clamp(current / maximum, 0, 1)
		local displayName = DISPLAY_NAMES[bossName.Value] or bossName.Value
		local palette = Theme.Boss[displayName] or Theme.Boss["Swarm Queen"]
		namePlate.Text = string.upper(displayName)
		namePlate.TextColor3 = ClientFX.c3(palette.Accent)
		fill.BackgroundColor3 = ClientFX.c3(palette.Fill)
		trackOutline.Color = ClientFX.c3(palette.Outline)
		portraitOutline.Color = ClientFX.c3(palette.Accent)
		local portraitId = Rules.BossPortraitIds[displayName] or 0
		portrait.Image = if portraitId == 0 then "" else "rbxassetid://" .. portraitId
		initial.Text = string.sub(displayName, 1, 1)
		initial.Visible = portraitId == 0
		fill.Size = UDim2.fromScale(ratio, 1)
		value.Text = string.format("%d / %d", math.ceil(current), math.ceil(maximum))
		if previousMax == maximum and current < previousHealth then
			if trailTween then
				trailTween:Cancel()
			end
			trail.Size = UDim2.fromScale(math.max(trail.Size.X.Scale, previousHealth / maximum), 1)
			trailTween = TweenService:Create(
				trail,
				TweenInfo.new(Rules.TrailSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.fromScale(ratio, 1) }
			)
			trailTween:Play()
			if previousHealth - current >= maximum * Rules.BigHitRatio and shown then
				shake()
			end
		else
			trail.Size = UDim2.fromScale(ratio, 1)
		end
		local phase = BossFight.phaseForHealth(current, maximum)
		if previousMax == maximum and phase > previousPhase then
			popPhase(phase)
		end
		previousHealth, previousMax, previousPhase = current, maximum, phase
	end

	function controller:SetLayout(viewport: Vector2, scale: number)
		local rect = Rules.bossBarRect(viewport.X, viewport.Y, scale, 0)
		self.BasePosition = UDim2.fromOffset(rect.x / scale, rect.y / scale)
		root.Size = UDim2.fromOffset(rect.w / scale, rect.h / scale)
		if shown then
			root.Position = self.BasePosition
		end
	end

	introRemote.OnClientEvent:Connect(function(_name, seconds)
		introToken += 1
		local token = introToken
		task.delay(seconds, function()
			if token == introToken then
				show()
			end
		end)
	end)
	health.Changed:Connect(refresh)
	maxHealth.Changed:Connect(refresh)
	bossName.Changed:Connect(refresh)
	local joinedDuringBoss = maxHealth.Value > 0
	refresh()
	if joinedDuringBoss then
		show()
	end
	return controller
end

return BossBar
