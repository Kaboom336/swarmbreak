-- Client side of Pumpkin Patch Panic: which base prompts you see (Place / Pick up / Steal / Lock),
-- lighting for day / midnight / Blood Moon, scythe swings, hit and pop effects, HUD (candy,
-- income, carry, LOCK), tool shop, upgrades, Haunt, Witch's Orders.
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("PatchConfig"))
local remotes = ReplicatedStorage:WaitForChild("PatchRemotes")
local state = ReplicatedStorage:WaitForChild("PatchState")
local player = Players.LocalPlayer

local garden = workspace:WaitForChild("Garden")
local patchFolder = garden:WaitForChild("Patches")
local cauldronFolder = garden:WaitForChild("Cauldrons")
local market = garden:WaitForChild("Market")
local kingFace = market:WaitForChild("KingFace") :: BasePart
local giantJack = market:WaitForChild("GiantJack") :: BasePart
local meterRing = market:WaitForChild("MeterRing") :: BasePart

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local seedById = {}
for i, seed in Config.Seeds do
	seed.order = seed.order or i
	seedById[seed.id] = seed
end
local mutationById = {}
for _, m in Config.Mutations do
	mutationById[m.id] = m
end

-- Small helpers -----------------------------------------------------------------------------

local sfxOn = true
local function play(id: number, pitch: number?, volume: number?)
	if not sfxOn or not id or id == 0 then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.PlaybackSpeed = pitch or 1
	sound.Volume = volume or 0.8
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

local function short(n: number): string
	if n >= 1e6 then
		return (string.gsub(string.format("%.1fM", n / 1e6), "%.0M", "M"))
	elseif n >= 1e4 then
		return (string.gsub(string.format("%.1fk", n / 1e3), "%.0k", "k"))
	end
	return tostring(math.floor(n))
end

local function clockText(seconds: number): string
	seconds = math.max(0, seconds)
	return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function burst(
	at: Vector3,
	color: Color3,
	count: number,
	speed: number,
	texture: string?,
	size: number?
)
	local holder = Instance.new("Attachment")
	holder.WorldPosition = at
	holder.Parent = workspace.Terrain
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture or "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color)
	local s = size or 2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, s),
		NumberSequenceKeypoint.new(1, s * 2.5),
	})
	emitter.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(speed * 0.6, speed)
	emitter.SpreadAngle = Vector2.new(180, 25)
	emitter.Drag = 4
	emitter.LightEmission = texture and 1 or 0
	emitter.Enabled = false
	emitter.Parent = holder
	emitter:Emit(count)
	task.delay(1.5, function()
		holder:Destroy()
	end)
end

local function floatText(at: Vector3, text: string, color: Color3, big: boolean?)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(big and 260 or 200, big and 60 or 46)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 160
	bb.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(30, 12, 40)
	stroke.Parent = label
	local info = TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(
		anchor,
		TweenInfo.new(1.6, Enum.EasingStyle.Quad),
		{ CFrame = anchor.CFrame + Vector3.new(0, 6, 0) }
	):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	task.delay(1.7, function()
		anchor:Destroy()
	end)
end

local function shake(strength: number, steps: number)
	local camera = workspace.CurrentCamera
	for i = 1, steps do
		local s = strength * (1 - i / (steps + 1))
		camera.CFrame *= CFrame.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0)
		task.wait(0.02)
	end
end

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Screen -----------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "PatchHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Small screens: one UIScale shrinks the whole HUD so the 640-wide panels still fit.
-- Narrower than 800 px (or shorter than 560 px, landscape phones) scales down, never below 0.6.
local uiScale = Instance.new("UIScale")
uiScale.Parent = gui
local viewportConn: RBXScriptConnection? = nil
local function refreshScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	if size.X <= 1 or size.Y <= 1 then
		return
	end
	uiScale.Scale = math.clamp(math.min(size.X / 800, size.Y / 560), 0.6, 1)
end
local function watchCamera()
	if viewportConn then
		viewportConn:Disconnect()
		viewportConn = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
	end
	refreshScale()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

local DARK = Color3.fromRGB(34, 22, 48)
local function stroke(parent: Instance, thickness: number)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.fromRGB(20, 10, 30)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end
local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius and UDim.new(0, radius) or UDim.new(1, 0)
	c.Parent = parent
end
local function textLabel(parent: Instance, text: string, color: Color3, font: Enum.Font?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Color = Color3.fromRGB(30, 12, 40)
	s.Parent = label
	return label
end
-- Chunky button look: the button's own background is hidden; a darker "Base" sits 4 px lower
-- and a "Face" with a top-to-bottom gradient and a thick outline sits on top. Both follow the
-- button's BackgroundColor3, so callers keep setting colors, sizes and positions on the button.
-- Hover grows 6 %, press shrinks 6 % (a UIScale, so layouts are untouched) with a click tick.
local OUTLINE = Color3.fromRGB(26, 15, 46)
local function chunky(b: GuiButton): (Frame, UIStroke)
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	local z = b.ZIndex
	local base = Instance.new("Frame")
	base.Name = "Base"
	base.Size = UDim2.fromScale(1, 1)
	base.Position = UDim2.fromOffset(0, 4)
	base.BorderSizePixel = 0
	base.ZIndex = z
	corner(base, 12)
	stroke(base, 3).Color = OUTLINE
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	face.ZIndex = z + 1
	corner(face, 12)
	local faceStroke = stroke(face, 3)
	faceStroke.Color = OUTLINE
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 225, 225)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 165, 165)),
	})
	gradient.Parent = face
	-- A soft white gloss across the top makes the top lighter than the base color.
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.78
	gloss.BorderSizePixel = 0
	gloss.Position = UDim2.new(0, 4, 0, 3)
	gloss.Size = UDim2.new(1, -8, 0.42, 0)
	gloss.ZIndex = z + 1
	gloss.Parent = face
	corner(gloss, 9)
	-- Existing content (seed slot dots and labels) goes above the face.
	for _, child in b:GetChildren() do
		if child:IsA("GuiObject") then
			child.ZIndex = math.max(child.ZIndex, z + 2)
		end
	end
	base.Parent = b
	face.Parent = b
	local function sync()
		face.BackgroundColor3 = b.BackgroundColor3
		base.BackgroundColor3 = b.BackgroundColor3:Lerp(Color3.new(0, 0, 0), 0.45)
	end
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(sync)
	sync()
	local scale = Instance.new("UIScale")
	scale.Parent = b
	local hovered = false
	local function to(target: number, seconds: number)
		TweenService:Create(
			scale,
			TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = target }
		):Play()
	end
	b.MouseEnter:Connect(function()
		hovered = true
		to(1.06, 0.12)
	end)
	b.MouseLeave:Connect(function()
		hovered = false
		to(1, 0.12)
	end)
	b.MouseButton1Down:Connect(function()
		to(0.94, 0.06)
	end)
	b.MouseButton1Up:Connect(function()
		to(hovered and 1.06 or 1, 0.12)
	end)
	b.Activated:Connect(function()
		play(Config.Sounds.Pick, 2.2, 0.35)
		if not hovered then
			to(1, 0.12)
		end
	end)
	return face, faceStroke
end

local function button(parent: Instance, text: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextTransparency = 1
	b.BackgroundColor3 = color
	b.Text = text
	b.Parent = parent
	chunky(b)
	-- The button's own text would draw under the face, so a label on top mirrors it.
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.ZIndex = b.ZIndex + 2
	label.Font = b.Font
	label.TextScaled = true
	label.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = label
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 2
	textStroke.Color = OUTLINE
	textStroke.Parent = label
	local function mirror()
		label.Text = b.Text
		label.TextColor3 = b.TextColor3
	end
	b:GetPropertyChangedSignal("Text"):Connect(mirror)
	b:GetPropertyChangedSignal("TextColor3"):Connect(mirror)
	mirror()
	return b
end

-- Banners queue so two never overlap.
local bannerFreeAt = 0
local showBanner -- forward
local function banner(text: string, sub: string?, seconds: number, color: Color3?)
	local now = os.clock()
	local wait = math.max(0, bannerFreeAt - now)
	bannerFreeAt = now + wait + seconds
	task.delay(wait, showBanner, text, sub, seconds, color)
end
function showBanner(text: string, sub: string?, seconds: number, color: Color3?)
	local title = textLabel(gui, text, color or Color3.fromRGB(255, 214, 80))
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.3)
	title.Size = UDim2.fromScale(0.7, 0)
	title:FindFirstChildOfClass("UIStroke").Thickness = 4
	TweenService
		:Create(
			title,
			TweenInfo.new(0.35, Enum.EasingStyle.Back),
			{ Size = UDim2.fromScale(0.7, 0.1) }
		)
		:Play()
	local subLabel
	if sub then
		subLabel = textLabel(gui, sub, Color3.fromRGB(255, 255, 255))
		subLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		subLabel.Position = UDim2.fromScale(0.5, 0.39)
		subLabel.Size = UDim2.fromScale(0.55, 0.05)
	end
	task.delay(seconds, function()
		title:Destroy()
		if subLabel then
			subLabel:Destroy()
		end
	end)
end

local hintLabel = textLabel(gui, "", Color3.fromRGB(255, 230, 200))
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -178)
hintLabel.Size = UDim2.fromOffset(700, 32)
hintLabel.Visible = false
local hintToken = 0
local function hint(text: string)
	hintToken += 1
	local token = hintToken
	hintLabel.Text = text
	hintLabel.Visible = true
	task.delay(3.5, function()
		if token == hintToken then
			hintLabel.Visible = false
		end
	end)
end
remotes:WaitForChild("Hint").OnClientEvent:Connect(hint)

-- Top: Giant Jack meter and the phase clock.
local meter = Instance.new("Frame")
meter.AnchorPoint = Vector2.new(0.5, 0)
meter.Position = UDim2.new(0.5, 0, 0, 46)
meter.Size = UDim2.fromOffset(470, 44)
meter.BackgroundColor3 = DARK
meter.BackgroundTransparency = 0.1
meter.Parent = gui
corner(meter)
stroke(meter, 3)
local meterFill = Instance.new("Frame")
meterFill.Size = UDim2.fromScale(0.04, 1)
meterFill.BackgroundColor3 = Color3.new(1, 1, 1)
meterFill.ClipsDescendants = true
meterFill.Parent = meter
corner(meterFill)
-- Fill colors come from this gradient (orange to yellow; red to orange in a Blood Moon).
local JACK_FILL = ColorSequence.new(Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 215, 70))
local KING_FILL = ColorSequence.new(Color3.fromRGB(200, 25, 45), Color3.fromRGB(255, 120, 60))
local meterGradient = Instance.new("UIGradient")
meterGradient.Color = JACK_FILL
meterGradient.Parent = meterFill
do
	-- A glossy top band and a shine stripe that sweeps across every few seconds.
	local gloss = Instance.new("Frame")
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.7
	gloss.BorderSizePixel = 0
	gloss.Position = UDim2.new(0, 6, 0, 3)
	gloss.Size = UDim2.new(1, -12, 0.3, 0)
	gloss.Parent = meterFill
	corner(gloss)
	local shine = Instance.new("Frame")
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.55
	shine.BorderSizePixel = 0
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Rotation = 20
	shine.Size = UDim2.new(0, 14, 1.6, 0)
	shine.Position = UDim2.new(0, -20, 0.5, 0)
	shine.Parent = meterFill
	task.spawn(function()
		while shine.Parent do
			shine.Position = UDim2.new(0, -20, 0.5, 0)
			local sweep = TweenService:Create(
				shine,
				TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Position = UDim2.new(1, 20, 0.5, 0) }
			)
			sweep:Play()
			task.wait(2.8)
		end
	end)
end
local meterText = textLabel(meter, "", Color3.fromRGB(255, 255, 255))
meterText.Size = UDim2.fromScale(1, 1)
meterText.ZIndex = 2
local meterPad = Instance.new("UIPadding")
meterPad.PaddingTop = UDim.new(0, 7)
meterPad.PaddingBottom = UDim.new(0, 7)
meterPad.Parent = meterText

local clock = Instance.new("Frame")
clock.AnchorPoint = Vector2.new(0.5, 0)
clock.Position = UDim2.new(0.5, 0, 0, 96)
clock.Size = UDim2.fromOffset(360, 32)
clock.BackgroundColor3 = DARK
clock.BackgroundTransparency = 0.15
clock.Parent = gui
corner(clock)
stroke(clock, 2.5)
local clockLabel = textLabel(clock, "", Color3.fromRGB(200, 210, 255))
clockLabel.Size = UDim2.fromScale(1, 1)
local clockPad = Instance.new("UIPadding")
clockPad.PaddingTop = UDim.new(0, 5)
clockPad.PaddingBottom = UDim.new(0, 5)
clockPad.Parent = clockLabel

-- When the Jack is full but the last Blood Moon was recent, the King waits.
local function jackFull(): boolean
	local candy = state:GetAttribute("JackCandy") or 0
	local goal = math.max(state:GetAttribute("JackGoal") or 1, 1)
	return state:GetAttribute("Phase") ~= "BloodMoon" and candy >= goal
end
local function wakeText(): string
	local left = (state:GetAttribute("KingWakesAt") or 0) - workspace:GetServerTimeNow()
	if left <= 0 then
		return "👑 The King is waking!"
	end
	return "👑 The King wakes in " .. clockText(left)
end

local function refreshMeter()
	local phase = state:GetAttribute("Phase")
	if phase == "BloodMoon" and state:GetAttribute("KingHp") == nil then
		-- The locks-off window before the King wakes.
		meterGradient.Color = KING_FILL
		meterText.Text = "🩸 BLOOD MOON · LOCKS OFF · STEAL!"
		TweenService:Create(meterFill, TweenInfo.new(0.2), { Size = UDim2.fromScale(1, 1) }):Play()
		return
	elseif phase == "BloodMoon" then
		local hp = state:GetAttribute("KingHp") or 0
		local maxHp = math.max(state:GetAttribute("KingMaxHp") or 1, 1)
		meterGradient.Color = KING_FILL
		local shield = state:GetAttribute("KingShield")
		local kingPhase = state:GetAttribute("KingPhase") or 1
		local pips = string.rep("●", kingPhase) .. string.rep("○", 3 - kingPhase)
		if shield then
			meterText.Text = string.format("🛡 SHIELD! Bonk %d lantern ghosts", shield)
		elseif state:GetAttribute("KingStunned") then
			meterText.Text = string.format("💫 STUNNED! x2  %d / %d", hp, maxHp)
		else
			meterText.Text = string.format("👑 PUMPKIN KING %s  %d / %d", pips, hp, maxHp)
		end
		TweenService:Create(
			meterFill,
			TweenInfo.new(0.2),
			{ Size = UDim2.fromScale(math.clamp(hp / maxHp, 0.03, 1), 1) }
		):Play()
		return
	end
	local candy = state:GetAttribute("JackCandy") or 0
	local goal = math.max(state:GetAttribute("JackGoal") or 1, 1)
	meterGradient.Color = JACK_FILL
	meterText.Text = jackFull() and wakeText()
		or string.format("🎃 Wake the Giant Jack  %s / %s", short(candy), short(goal))
	TweenService:Create(
		meterFill,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad),
		{ Size = UDim2.fromScale(math.clamp(candy / goal, 0.04, 1), 1) }
	):Play()
	meterRing.Color = Color3.fromRGB(255, 140, 40):Lerp(Color3.fromRGB(255, 60, 40), candy / goal)
	meterRing.Transparency = 0.6 - 0.5 * (candy / goal)
end
for _, attr in
	{
		"JackCandy",
		"JackGoal",
		"KingHp",
		"KingMaxHp",
		"Phase",
		"KingShield",
		"KingStunned",
		"KingPhase",
		"KingWakesAt",
		"LocksOff",
	}
do
	state:GetAttributeChangedSignal(attr):Connect(refreshMeter)
end
refreshMeter()

RunService.Heartbeat:Connect(function()
	local phase = state:GetAttribute("Phase") or "Day"
	local left = math.max(0, (state:GetAttribute("PhaseEnds") or 0) - workspace:GetServerTimeNow())
	local time = clockText(left)
	if phase == "Day" then
		clockLabel.Text = "🌙 Ghosts raid at midnight  " .. time
		clockLabel.TextColor3 = Color3.fromRGB(200, 210, 255)
	elseif phase == "Midnight" then
		clockLabel.Text = "👻 MIDNIGHT! Bonk the ghosts  " .. time
		clockLabel.TextColor3 = Color3.fromRGB(170, 230, 255)
	elseif state:GetAttribute("LocksOff") then
		local wake = (state:GetAttribute("LocksOff") or 0) - workspace:GetServerTimeNow()
		clockLabel.Text = "🔓 LOCKS OFF! King wakes in " .. clockText(wake)
		clockLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	else
		clockLabel.Text = "🩸 BLOOD MOON! Bonk the King  " .. time
		clockLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	end
	if jackFull() then
		meterText.Text = wakeText()
	end
end)

-- Left: candy and carried pumpkins.
local column = Instance.new("Frame")
column.BackgroundTransparency = 1
column.Position = UDim2.new(0, 14, 0.34, 0)
column.Size = UDim2.fromOffset(220, 150)
column.Parent = gui
local columnLayout = Instance.new("UIListLayout")
columnLayout.Padding = UDim.new(0, 8)
columnLayout.Parent = column
local function statRow(icon: string, color: Color3): (TextLabel, TextLabel)
	local row = Instance.new("Frame")
	row.Size = UDim2.fromOffset(220, 64)
	row.BackgroundColor3 = DARK
	row.BackgroundTransparency = 0.2
	row.Parent = column
	corner(row, 14)
	stroke(row, 2.5)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Size = UDim2.fromOffset(60, 64)
	iconLabel.TextScaled = true
	iconLabel.Text = icon
	iconLabel.Parent = row
	local big = textLabel(row, "0", color)
	big.Position = UDim2.fromOffset(62, 4)
	big.Size = UDim2.new(1, -70, 0, 36)
	big.TextXAlignment = Enum.TextXAlignment.Left
	local small = textLabel(row, "", Color3.fromRGB(230, 230, 240))
	small.Position = UDim2.fromOffset(62, 40)
	small.Size = UDim2.new(1, -70, 0, 18)
	small.TextXAlignment = Enum.TextXAlignment.Left
	return big, small
end
local candyBig, candySmall = statRow("🍬", Color3.fromRGB(255, 150, 210))
local carryBig, carrySmall = statRow("🎃", Color3.fromRGB(255, 160, 60))
local candyValue = player:WaitForChild("leaderstats"):WaitForChild("Candy") :: IntValue
local function refreshCandy(pop: boolean)
	candyBig.Text = short(candyValue.Value)
	local income = player:GetAttribute("Income") or 0
	candySmall.Text = income > 0
			and ("+" .. (income < 10 and string.format("%.1f", income) or short(income)) .. " / sec")
		or "Candy"
	if pop then
		candyBig.TextColor3 = Color3.fromRGB(255, 255, 220)
		TweenService
			:Create(candyBig, TweenInfo.new(0.4), { TextColor3 = Color3.fromRGB(255, 150, 210) })
			:Play()
	end
end
-- Sell juice: candies fly from the screen center into the candy counter, which punches 1 -> 1.2 -> 1.
-- They live in their own unscaled ScreenGui so screen pixels line up with AbsolutePosition.
local candyShower
do
	local punchScale = Instance.new("UIScale")
	punchScale.Parent = candyBig
	local fxGui = Instance.new("ScreenGui")
	fxGui.Name = "PatchFx"
	fxGui.ResetOnSpawn = false
	fxGui.IgnoreGuiInset = true
	fxGui.DisplayOrder = 5
	fxGui.Parent = player:WaitForChild("PlayerGui")
	local function punch()
		local up = TweenService:Create(
			punchScale,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = 1.2 }
		)
		up:Play()
		up.Completed:Once(function()
			TweenService:Create(
				punchScale,
				TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end)
	end
	function candyShower(count: number)
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local view = camera.ViewportSize
		local target = candyBig.AbsolutePosition + candyBig.AbsoluteSize / 2
		for i = 1, count do
			local candy = Instance.new("TextLabel")
			candy.BackgroundTransparency = 1
			candy.AnchorPoint = Vector2.new(0.5, 0.5)
			candy.Size = UDim2.fromOffset(40, 40)
			candy.TextScaled = true
			candy.Text = "🍬"
			candy.Rotation = math.random(-30, 30)
			local a = math.random() * math.pi * 2
			local spread = 40 + math.random() * 70
			candy.Position = UDim2.fromOffset(
				view.X / 2 + math.cos(a) * spread,
				view.Y / 2 + math.sin(a) * spread * 0.6
			)
			candy.Parent = fxGui
			task.delay((i - 1) * 0.05, function()
				local fly = TweenService:Create(
					candy,
					TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						Position = UDim2.fromOffset(target.X, target.Y),
						Size = UDim2.fromOffset(24, 24),
						Rotation = candy.Rotation + 180,
					}
				)
				fly:Play()
				fly.Completed:Once(function()
					candy:Destroy()
					punch()
				end)
			end)
		end
	end
end

local function refreshCarry()
	local n = player:GetAttribute("Carry") or 0
	local cap = Config.BaseCarry
		+ (player:GetAttribute("Up_Stack") or 0)
		+ (player:GetAttribute("Pass_BigStack") and Config.BigStackCarry or 0)
	carryBig.Text = string.format("%d / %d", n, cap)
	if n == 0 then
		carrySmall.Text = "Carrying"
	else
		carrySmall.Text = "Worth " .. short(player:GetAttribute("CarryValue") or 0) .. " 🍬"
	end
end
candyValue.Changed:Connect(function()
	refreshCandy(true)
end)
player:GetAttributeChangedSignal("Income"):Connect(function()
	refreshCandy(false)
end)
for _, attr in { "Carry", "CarryValue", "Up_Stack", "Pass_BigStack" } do
	player:GetAttributeChangedSignal(attr):Connect(refreshCarry)
end
refreshCandy(false)
refreshCarry()

local function seedColor(seed): Color3
	if seed.color then
		return seed.color
	end
	return seed.template == "pumpkin_yellow" and Color3.fromRGB(255, 210, 70)
		or Color3.fromRGB(255, 130, 40)
end

-- Panels: tool shop (the old seed stall) and upgrade stall.
local function panel(title: string): (Frame, Frame)
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.55)
	frame.Size = UDim2.fromOffset(640, 440)
	frame.BackgroundColor3 = Color3.fromRGB(36, 24, 50)
	frame.Visible = false
	frame.ZIndex = 10
	frame.Parent = gui
	corner(frame, 18)
	stroke(frame, 4)
	local head = textLabel(frame, title, Color3.fromRGB(255, 255, 255))
	head.Position = UDim2.fromOffset(20, 10)
	head.Size = UDim2.new(1, -100, 0, 46)
	head.TextXAlignment = Enum.TextXAlignment.Left
	local close = button(frame, "X", Color3.fromRGB(220, 60, 60))
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12)
	close.Size = UDim2.fromOffset(46, 46)
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(16, 68)
	list.Size = UDim2.new(1, -32, 1, -84)
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	return frame, list
end
local function card(
	list: Frame,
	order: number,
	color: Color3,
	title: string,
	text: string
): (Frame, TextLabel)
	local c = Instance.new("Frame")
	c.Size = UDim2.new(1, -10, 0, 78)
	c.LayoutOrder = order
	c.BackgroundColor3 = Color3.fromRGB(226, 196, 150)
	c.Parent = list
	corner(c, 12)
	stroke(c, 2.5)
	local dot = Instance.new("Frame")
	dot.Position = UDim2.fromOffset(12, 14)
	dot.Size = UDim2.fromOffset(50, 50)
	dot.BackgroundColor3 = color
	dot.Parent = c
	corner(dot)
	stroke(dot, 2)
	local name = textLabel(c, title, Color3.fromRGB(255, 255, 255))
	name.Position = UDim2.fromOffset(74, 6)
	name.Size = UDim2.new(1, -330, 0, 32)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local info = textLabel(c, text, Color3.fromRGB(70, 44, 30), Enum.Font.GothamBold)
	info:FindFirstChildOfClass("UIStroke"):Destroy()
	info.Position = UDim2.fromOffset(74, 42)
	info.Size = UDim2.new(1, -330, 0, 22)
	info.TextXAlignment = Enum.TextXAlignment.Left
	return c, info
end

local buyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteFunction
local upgradePanel, upgradeList = panel("UPGRADES")
-- Tool shop: every tool with BUY / OWNED / EQUIPPED (the best owned one is always held).
local toolPanel, refreshToolCards
do
	local buyTool = remotes:WaitForChild("BuyTool") :: RemoteFunction
	local list
	toolPanel, list = panel("TOOLS")
	local cards = {}
	for i, tool in Config.Tools do
		local c = card(
			list,
			i,
			tool.color,
			tool.name,
			string.format("%s damage per swing", short(tool.damage))
		)
		local b = button(c, "", Color3.fromRGB(60, 190, 70))
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -12, 0.5, 0)
		b.Size = UDim2.fromOffset(170, 52)
		cards[tool.id] = b
		b.Activated:Connect(function()
			if not tool.cost then
				hint("Only the Blood Moon MVP gets the " .. tool.name .. "!")
				return
			end
			local ok, message = buyTool:InvokeServer(tool.id)
			if ok then
				play(Config.Sounds.Coin, 0.9, 0.8)
				banner(string.upper(tool.name) .. "!", short(tool.damage) .. " damage per swing", 2)
			else
				b.Text = tostring(message or "?")
				task.delay(1, refreshToolCards)
			end
		end)
	end
	function refreshToolCards()
		local owned = {}
		for id in string.gmatch(player:GetAttribute("Tools") or "", "[^,]+") do
			owned[id] = true
		end
		local held = player:GetAttribute("Tool")
		for _, tool in Config.Tools do
			local b = cards[tool.id]
			if tool.id == held then
				b.Text = "EQUIPPED"
				b.BackgroundColor3 = Color3.fromRGB(230, 150, 30)
			elseif owned[tool.id] then
				b.Text = "OWNED"
				b.BackgroundColor3 = Color3.fromRGB(110, 100, 120)
			elseif not tool.cost then
				b.Text = "MVP DROP"
				b.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
			else
				b.Text = "BUY · " .. short(tool.cost) .. " 🍬"
				b.BackgroundColor3 = candyValue.Value >= tool.cost and Color3.fromRGB(60, 190, 70)
					or Color3.fromRGB(120, 110, 90)
			end
		end
	end
	player:GetAttributeChangedSignal("Tools"):Connect(refreshToolCards)
	player:GetAttributeChangedSignal("Tool"):Connect(refreshToolCards)
end
local upgradeCards = {}
local UPGRADE_ORDER = { "Stack", "Mallet", "Lucky" }
local UPGRADE_COLOR = {
	Stack = Color3.fromRGB(255, 150, 50),
	Mallet = Color3.fromRGB(190, 200, 220),
	Lucky = Color3.fromRGB(110, 210, 90),
}
for i, id in UPGRADE_ORDER do
	local info = Config.Upgrades[id]
	local c, text = card(upgradeList, i, UPGRADE_COLOR[id], info.title, info.text)
	local b = button(c, "", Color3.fromRGB(60, 190, 70))
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -12, 0.5, 0)
	b.Size = UDim2.fromOffset(160, 52)
	upgradeCards[id] = { button = b, text = text }
	b.Activated:Connect(function()
		local ok, message = buyUpgrade:InvokeServer(id)
		if ok then
			play(Config.Sounds.Coin, 0.9, 0.8)
			banner(info.title .. "!", info.text, 1.6)
		else
			b.Text = message
			task.delay(1, function()
				b.Text = ""
			end)
		end
	end)
end
local function refreshUpgradeCards()
	for id, parts in upgradeCards do
		local info = Config.Upgrades[id]
		local level = player:GetAttribute("Up_" .. id) or 0
		parts.text.Text = info.text
			.. "   "
			.. string.rep("●", level)
			.. string.rep("○", info.max - level)
		if level >= info.max then
			parts.button.Text = "MAX"
			parts.button.BackgroundColor3 = Color3.fromRGB(110, 100, 120)
		else
			local cost = math.floor(info.base * (level + 1) ^ Config.CostPower)
			parts.button.Text = short(cost) .. " 🍬"
			parts.button.BackgroundColor3 = candyValue.Value >= cost and Color3.fromRGB(60, 190, 70)
				or Color3.fromRGB(120, 110, 90)
		end
	end
end
for _, id in UPGRADE_ORDER do
	player:GetAttributeChangedSignal("Up_" .. id):Connect(refreshUpgradeCards)
end
candyValue.Changed:Connect(function()
	refreshToolCards()
	refreshUpgradeCards()
end)
refreshToolCards()
refreshUpgradeCards()
remotes:WaitForChild("OpenShop").OnClientEvent:Connect(function(kind: string)
	toolPanel.Visible = kind == "Tools" and not toolPanel.Visible
	upgradePanel.Visible = kind == "Upgrades" and not upgradePanel.Visible
end)

-- Pumpkin Index: a book of every seed x finish. Selling a new kind fills it in. -------------

local FINISHES = { "Plain", "Glowing", "Ghostly", "Candy", "Cursed" }
local indexPanel, indexList = panel("PUMPKIN INDEX")
local indexCells = {}
for i, seed in Config.Seeds do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 52)
	row.LayoutOrder = i
	row.BackgroundTransparency = 1
	row.Parent = indexList
	local name = textLabel(row, seed.name, Color3.fromRGB(255, 255, 255))
	name.Size = UDim2.new(0, 130, 1, -10)
	name.Position = UDim2.fromOffset(0, 5)
	name.TextXAlignment = Enum.TextXAlignment.Left
	indexCells[seed.id] = { name = name }
	for k, finish in FINISHES do
		local cell = Instance.new("Frame")
		cell.Size = UDim2.fromOffset(78, 46)
		cell.Position = UDim2.fromOffset(140 + (k - 1) * 86, 3)
		cell.BackgroundColor3 = Color3.fromRGB(60, 50, 70)
		cell.Parent = row
		corner(cell, 10)
		stroke(cell, 2)
		local label = textLabel(cell, "?", Color3.fromRGB(150, 140, 160))
		label.Size = UDim2.new(1, -8, 1, -8)
		label.Position = UDim2.fromOffset(4, 4)
		indexCells[seed.id][finish] = { cell = cell, label = label }
	end
end
local indexCount = textLabel(indexPanel, "", Color3.fromRGB(255, 214, 80))
indexCount.AnchorPoint = Vector2.new(1, 0)
indexCount.Position = UDim2.new(1, -70, 0, 16)
indexCount.Size = UDim2.fromOffset(200, 36)
local function refreshIndex()
	local found = {}
	for key in string.gmatch(player:GetAttribute("Index") or "", "[^,]+") do
		found[key] = true
	end
	local total = 0
	for _, seed in Config.Seeds do
		local all = true
		for _, finish in FINISHES do
			local parts = indexCells[seed.id][finish]
			if found[seed.id .. ":" .. finish] then
				total += 1
				local m = mutationById[finish]
				parts.cell.BackgroundColor3 = m and m.color or seedColor(seed)
				parts.label.Text = finish == "Plain" and "✓"
					or string.upper(string.sub(finish, 1, 4))
				parts.label.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				all = false
				parts.cell.BackgroundColor3 = Color3.fromRGB(60, 50, 70)
				parts.label.Text = "?"
				parts.label.TextColor3 = Color3.fromRGB(150, 140, 160)
			end
		end
		indexCells[seed.id].name.Text = seed.name .. (all and " +10%" or "")
	end
	indexCount.Text = string.format("%d / %d", total, #Config.Seeds * #FINISHES)
end
player:GetAttributeChangedSignal("Index"):Connect(refreshIndex)
refreshIndex()

-- Music: a calm day loop, a tense midnight loop and a boss loop that crossfade by phase.
do
	local tracks = {}
	for phase, id in
		{
			Day = Config.Sounds.DayMusic,
			Midnight = Config.Sounds.NightMusic,
			BloodMoon = Config.Sounds.BossMusic,
		}
	do
		local music = Instance.new("Sound")
		music.Name = phase .. "Music"
		music.SoundId = "rbxassetid://" .. id
		music.Looped = true
		music.Volume = 0
		music.Parent = SoundService
		music:Play()
		tracks[phase] = music
	end
	local musicOn = true
	local function refreshMusic()
		local phase = state:GetAttribute("Phase") or "Day"
		for name, music in tracks do
			local target = (musicOn and name == phase) and Config.MusicVolume or 0
			TweenService:Create(music, TweenInfo.new(2), { Volume = target }):Play()
		end
	end
	state:GetAttributeChangedSignal("Phase"):Connect(refreshMusic)
	refreshMusic()

	local muteButton = button(gui, "🔊", Color3.fromRGB(70, 60, 90))
	muteButton.Position = UDim2.new(0, 172, 0.34, 152)
	muteButton.Size = UDim2.fromOffset(56, 46)
	muteButton.Activated:Connect(function()
		musicOn = not musicOn
		muteButton.Text = musicOn and "🔊" or "🔇"
		refreshMusic()
	end)
end

local indexButton = button(gui, "📖 INDEX", Color3.fromRGB(120, 80, 170))
indexButton.Position = UDim2.new(0, 14, 0.34, 152)
indexButton.Size = UDim2.fromOffset(150, 46)
local sfxButton = button(gui, "🔔", Color3.fromRGB(70, 60, 90))
sfxButton.Position = UDim2.new(0, 236, 0.34, 152)
sfxButton.Size = UDim2.fromOffset(56, 46)
sfxButton.Activated:Connect(function()
	sfxOn = not sfxOn
	sfxButton.Text = sfxOn and "🔔" or "🔕"
end)

-- LOCK: locks your base for a while (no stealing, ghosts skip it), then recharges.
do
	local lockEvent = remotes:WaitForChild("Lock")
	local lockButton = button(gui, "🔒 LOCK", Color3.fromRGB(140, 80, 220))
	lockButton.Position = UDim2.new(0, 14, 0.34, 204)
	lockButton.Size = UDim2.fromOffset(150, 46)
	lockButton.Activated:Connect(function()
		lockEvent:FireServer()
	end)
	local function myBase(): Instance?
		for _, patch in patchFolder:GetChildren() do
			if patch:GetAttribute("Owner") == player.UserId then
				return patch
			end
		end
		return nil
	end
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = workspace:GetServerTimeNow()
			local base = myBase()
			local lockedUntil = base and base:GetAttribute("LockedUntil") or 0
			local ready = base and base:GetAttribute("LockCooldownUntil") or 0
			local text, color
			if (state:GetAttribute("LocksOff") or 0) > now then
				text, color = "🩸 LOCKS OFF", Color3.fromRGB(200, 50, 60)
			elseif lockedUntil > now then
				text = "🔒 " .. clockText(lockedUntil - now)
				color = Color3.fromRGB(170, 90, 255)
			elseif ready > now then
				text, color = "⏳ " .. clockText(ready - now), Color3.fromRGB(90, 80, 100)
			else
				text, color = "🔒 LOCK", Color3.fromRGB(140, 80, 220)
			end
			if lockButton.Text ~= text then
				lockButton.Text = text
			end
			if lockButton.BackgroundColor3 ~= color then
				lockButton.BackgroundColor3 = color
			end
		end
	end)
end

-- Haunt: reset for +50% sell value forever and Souls to spend in the Soul skill tree. -----------

local hauntRemote = remotes:WaitForChild("Haunt") :: RemoteFunction
local buySkill = remotes:WaitForChild("BuySkill") :: RemoteFunction
local hauntPanel, hauntList = panel("HAUNT")
local soulsLabel = textLabel(hauntPanel, "", Color3.fromRGB(200, 160, 255))
soulsLabel.AnchorPoint = Vector2.new(1, 0)
soulsLabel.Position = UDim2.new(1, -70, 0, 16)
soulsLabel.Size = UDim2.fromOffset(200, 36)
local hauntInfo = textLabel(hauntList, "", Color3.fromRGB(255, 240, 220), Enum.Font.GothamBold)
hauntInfo.LayoutOrder = 0
hauntInfo.Size = UDim2.new(1, -10, 0, 64)
hauntInfo.TextScaled = false
hauntInfo.TextSize = 17
hauntInfo.TextWrapped = true
hauntInfo.TextXAlignment = Enum.TextXAlignment.Left
local hauntCard, hauntCardText = card(hauntList, 1, Color3.fromRGB(150, 90, 255), "Haunt", "")
local hauntGo = button(hauntCard, "", Color3.fromRGB(150, 90, 255))
hauntGo.AnchorPoint = Vector2.new(1, 0.5)
hauntGo.Position = UDim2.new(1, -12, 0.5, 0)
hauntGo.Size = UDim2.fromOffset(200, 52)
-- Soul skill tree: a column per branch, three nodes top to bottom joined by short lines.
-- Node states: owned (bright, check), buyable (pulsing outline, cost), locked (dim, lock).
local BRANCH_COLOR: { [string]: Color3 } = {
	Farmer = Color3.fromRGB(255, 140, 40),
	Witch = Color3.fromRGB(165, 95, 255),
	Hunter = Color3.fromRGB(235, 60, 60),
}
local BRANCH_ICON: { [string]: string } = { Farmer = "🌱", Witch = "🧪", Hunter = "🔨" }
local DIM_TEXT = Color3.fromRGB(150, 140, 160)
local NODE_H, LINK_H, TREE_TOP, BRANCH_H = 80, 16, 34, 30
local skillAt: { [string]: any } = {} -- "Branch:tier" -> skill
for _, skill in Config.Skills do
	skillAt[skill.branch .. ":" .. skill.tier] = skill
end

type SkillNode = {
	skill: any,
	color: Color3,
	before: any?,
	button: TextButton,
	outline: UIStroke,
	title: TextLabel,
	info: TextLabel,
	status: TextLabel,
	link: Frame?,
	state: string,
	holdUntil: number,
}
local skillNodes: { SkillNode } = {}

local tree = Instance.new("Frame")
tree.LayoutOrder = 2
tree.BackgroundTransparency = 1
tree.Size = UDim2.new(1, -10, 0, TREE_TOP + BRANCH_H + 3 * NODE_H + 2 * LINK_H + 6)
tree.Parent = hauntList
local treeHead = textLabel(tree, "", Color3.fromRGB(200, 160, 255))
treeHead.Size = UDim2.new(1, 0, 0, 28)

local function ownedSkills(): { [string]: boolean }
	local owned = {}
	for id in string.gmatch(player:GetAttribute("Skills") or "", "[^,]+") do
		owned[id] = true
	end
	return owned
end

local refreshTree -- forward: node clicks refresh the tree
local buyingSkill = false
local function onNodeClicked(node: SkillNode)
	local skill = node.skill
	if node.state == "owned" then
		hint(skill.title .. " is already yours.")
		return
	elseif node.state == "locked" then
		hint(string.format("Get %s first to unlock %s.", node.before.title, skill.title))
		return
	end
	if buyingSkill then
		return
	end
	buyingSkill = true
	local ok, message = buySkill:InvokeServer(skill.id)
	buyingSkill = false
	if ok then
		play(Config.Sounds.Brew, 1.3, 0.8)
		banner(skill.title .. "!", skill.text, 1.8, node.color)
	else
		node.status.Text = tostring(message or "?")
		node.status.TextColor3 = Color3.fromRGB(255, 130, 130)
		node.holdUntil = os.clock() + 1
		task.delay(1.05, refreshTree)
	end
end

for b, branch in Config.SkillBranches do
	local color = BRANCH_COLOR[branch] or Color3.fromRGB(200, 200, 200)
	local col = Instance.new("Frame")
	col.BackgroundTransparency = 1
	col.Position = UDim2.new((b - 1) / 3, 4, 0, TREE_TOP)
	col.Size = UDim2.new(1 / 3, -8, 1, -TREE_TOP)
	col.Parent = tree
	local head = textLabel(col, (BRANCH_ICON[branch] or "") .. " " .. string.upper(branch), color)
	head.Size = UDim2.new(1, 0, 0, BRANCH_H - 4)
	for tier = 1, 3 do
		local skill = skillAt[branch .. ":" .. tier]
		if not skill then
			continue
		end
		local y = BRANCH_H + (tier - 1) * (NODE_H + LINK_H)
		local link: Frame? = nil
		if tier > 1 then
			local l = Instance.new("Frame")
			l.AnchorPoint = Vector2.new(0.5, 0)
			l.Position = UDim2.new(0.5, 0, 0, y - LINK_H)
			l.Size = UDim2.fromOffset(6, LINK_H)
			l.BorderSizePixel = 0
			l.BackgroundColor3 = Color3.fromRGB(70, 60, 80)
			l.Parent = col
			link = l
		end
		local nodeButton = Instance.new("TextButton")
		nodeButton.Text = ""
		nodeButton.AutoButtonColor = true
		nodeButton.Position = UDim2.fromOffset(0, y)
		nodeButton.Size = UDim2.new(1, 0, 0, NODE_H)
		nodeButton.BackgroundColor3 = color
		nodeButton.Parent = col
		corner(nodeButton, 12)
		local outline = stroke(nodeButton, 2.5)
		local title = textLabel(nodeButton, skill.title, Color3.fromRGB(255, 255, 255))
		title.Position = UDim2.fromOffset(6, 4)
		title.Size = UDim2.new(1, -12, 0, 26)
		local info =
			textLabel(nodeButton, skill.text, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
		info.Position = UDim2.fromOffset(6, 32)
		info.Size = UDim2.new(1, -12, 0, 18)
		local status = textLabel(nodeButton, "", Color3.fromRGB(255, 255, 255))
		status.Position = UDim2.fromOffset(6, 53)
		status.Size = UDim2.new(1, -12, 0, 22)
		local node: SkillNode = {
			skill = skill,
			color = color,
			before = skillAt[branch .. ":" .. (tier - 1)],
			button = nodeButton,
			outline = outline,
			title = title,
			info = info,
			status = status,
			link = link,
			state = "locked",
			holdUntil = 0,
		}
		table.insert(skillNodes, node)
		nodeButton.Activated:Connect(function()
			onNodeClicked(node)
		end)
	end
end

function refreshTree()
	local owned = ownedSkills()
	local souls = player:GetAttribute("Souls") or 0
	treeHead.Text = string.format("SOUL SKILLS · 👻 %d to spend", souls)
	for _, node in skillNodes do
		local skill = node.skill
		local ready = node.before == nil or owned[node.before.id] == true
		if node.link then
			node.link.BackgroundColor3 = ready and node.color or Color3.fromRGB(70, 60, 80)
		end
		local textColor = Color3.fromRGB(255, 255, 255)
		local statusText, statusColor
		if owned[skill.id] then
			node.state = "owned"
			node.button.BackgroundColor3 = node.color
			node.title.Text = "✓ " .. skill.title
			node.outline.Color = Color3.fromRGB(255, 245, 210)
			node.outline.Thickness = 3
			statusText, statusColor = "✓ OWNED", textColor
		elseif ready then
			node.state = "buyable"
			node.button.BackgroundColor3 = node.color:Lerp(DARK, 0.55)
			node.title.Text = skill.title
			if souls >= skill.cost then
				statusText = string.format("BUY · %d 👻", skill.cost)
				statusColor = Color3.fromRGB(255, 225, 110)
			else
				statusText = string.format("%d 👻 · need more", skill.cost)
				statusColor = Color3.fromRGB(230, 200, 220)
			end
		else
			node.state = "locked"
			node.button.BackgroundColor3 = node.color:Lerp(DARK, 0.82)
			node.title.Text = "🔒 " .. skill.title
			node.outline.Color = Color3.fromRGB(20, 10, 30)
			node.outline.Thickness = 2.5
			textColor = DIM_TEXT
			statusText, statusColor = string.format("🔒 %d 👻", skill.cost), DIM_TEXT
		end
		node.title.TextColor3 = textColor
		node.info.TextColor3 = textColor
		-- A failed buy shows its reason for a moment before the normal status comes back.
		if os.clock() >= node.holdUntil then
			node.status.Text = statusText
			node.status.TextColor3 = statusColor
		end
	end
end

-- Buyable nodes pulse their outline while the Haunt panel is open.
RunService.Heartbeat:Connect(function()
	if not hauntPanel.Visible then
		return
	end
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 5)
	for _, node in skillNodes do
		if node.state == "buyable" then
			node.outline.Thickness = 2.5 + 2 * pulse
			node.outline.Color = Color3.fromRGB(255, 200, 60)
				:Lerp(Color3.fromRGB(255, 255, 255), pulse)
		end
	end
end)
player:GetAttributeChangedSignal("Skills"):Connect(refreshTree)

local function hauntCost(): number
	return math.floor(Config.HauntCost * Config.HauntGrowth ^ (player:GetAttribute("Haunts") or 0))
end
local confirmUntil = 0
local function refreshHaunt()
	local haunts = player:GetAttribute("Haunts") or 0
	local souls = player:GetAttribute("Souls") or 0
	local cost = hauntCost()
	local gain = haunts + 1
	soulsLabel.Text = string.format("👻 %d Souls", souls)
	hauntInfo.Text = string.format(
		"Haunts: %d (sell and income x%.1f). Haunting resets candy, upgrades, unlocked zones and "
			.. "your base pumpkins. You keep your tools, Index, Kings, Souls, skills and titles.",
		haunts,
		1 + Config.HauntSellBonus * haunts
	)
	hauntCardText.Text = string.format(
		"Costs %s 🍬 · +%d%% sell · +%d Soul%s",
		short(cost),
		math.floor(Config.HauntSellBonus * 100 + 0.5),
		gain,
		gain == 1 and "" or "s"
	)
	if os.clock() < confirmUntil then
		hauntGo.Text = "SURE? Click again"
		hauntGo.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	else
		hauntGo.Text = "HAUNT · " .. short(cost) .. " 🍬"
		hauntGo.BackgroundColor3 = candyValue.Value >= cost and Color3.fromRGB(150, 90, 255)
			or Color3.fromRGB(120, 110, 90)
	end
	refreshTree()
end
hauntGo.Activated:Connect(function()
	local cost = hauntCost()
	if candyValue.Value < cost then
		hauntGo.Text = "Need " .. short(cost)
		task.delay(1, refreshHaunt)
		return
	end
	if os.clock() >= confirmUntil then
		confirmUntil = os.clock() + 4
		refreshHaunt()
		task.delay(4.1, refreshHaunt)
		return
	end
	confirmUntil = 0
	local gain = (player:GetAttribute("Haunts") or 0) + 1
	local ok, message = hauntRemote:InvokeServer()
	if ok then
		play(Config.Sounds.Brew, 0.5, 1)
		banner(
			"HAUNTED!",
			string.format(
				"+%d%% sell forever · +%d Soul%s",
				math.floor(Config.HauntSellBonus * 100),
				gain,
				gain == 1 and "" or "s"
			),
			3,
			Color3.fromRGB(190, 120, 255)
		)
	else
		hauntGo.Text = message
		task.delay(1, refreshHaunt)
		return
	end
	refreshHaunt()
end)
for _, attr in { "Haunts", "Souls" } do
	player:GetAttributeChangedSignal(attr):Connect(refreshHaunt)
end
candyValue.Changed:Connect(refreshHaunt)
refreshHaunt()

-- Shop: game passes and developer products whose Config ID is not 0. ----------------------------

local shopRemote = remotes:WaitForChild("Shop") :: RemoteFunction
type ShopItem = { kind: string, name: string, title: string, text: string, color: Color3 }
type ShopCard = { item: ShopItem, id: number, button: TextButton, info: TextLabel, price: string }
local SHOP_ITEMS: { ShopItem } = {
	{
		kind = "pass",
		name = "DoubleCandy",
		title = "2x Candy",
		text = "Double candy from every sale",
		color = Color3.fromRGB(255, 120, 210),
	},
	{
		kind = "pass",
		name = "VIP",
		title = "VIP",
		text = string.format(
			"+%d%% sell · VIP tag · gold name",
			math.floor(Config.VipSellBonus * 100 + 0.5)
		),
		color = Color3.fromRGB(255, 205, 60),
	},
	{
		kind = "pass",
		name = "BigStack",
		title = "Big Stack",
		text = string.format("Carry %d more pumpkins", Config.BigStackCarry),
		color = Color3.fromRGB(255, 150, 50),
	},
	{
		kind = "product",
		name = "CandySmall",
		title = "Candy Bag",
		text = "A bag of candy",
		color = Color3.fromRGB(255, 150, 210),
	},
	{
		kind = "product",
		name = "CandyBig",
		title = "Candy Chest",
		text = "A chest of candy",
		color = Color3.fromRGB(200, 110, 255),
	},
}
local shopPanel, shopList = panel("SHOP")
local shopCards: { ShopCard } = {}
local shopQuotes: { [string]: number } = {}
local lastPromptAt = -math.huge

local function ownsPass(name: string): boolean
	return player:GetAttribute("Pass_" .. name) == true
end

local function refreshShop()
	for _, entry in shopCards do
		local item = entry.item
		if item.kind == "pass" and ownsPass(item.name) then
			entry.button.Text = "OWNED"
			entry.button.BackgroundColor3 = Color3.fromRGB(110, 100, 120)
		else
			entry.button.Text = entry.price
			entry.button.BackgroundColor3 = Color3.fromRGB(60, 190, 70)
		end
		local quote = shopQuotes[item.name]
		if type(quote) == "number" then
			entry.info.Text = string.format("+%s candy right now", short(quote))
		end
	end
end

local function buyShopItem(entry: ShopCard)
	local item = entry.item
	if item.kind == "pass" and ownsPass(item.name) then
		hint("You already own " .. item.title .. "!")
		return
	end
	lastPromptAt = os.clock()
	task.spawn(pcall, shopRemote.InvokeServer, shopRemote, "prompt")
	if item.kind == "pass" then
		MarketplaceService:PromptGamePassPurchase(player, entry.id)
	else
		MarketplaceService:PromptProductPurchase(player, entry.id)
	end
end

for i, item in SHOP_ITEMS do
	local ids = item.kind == "pass" and Config.GamePasses or Config.Products
	local id = ids[item.name] or 0
	if id == 0 then
		continue
	end
	local c, info = card(shopList, i, item.color, item.title, item.text)
	local b = button(c, "BUY", Color3.fromRGB(60, 190, 70))
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -12, 0.5, 0)
	b.Size = UDim2.fromOffset(160, 52)
	local entry: ShopCard = { item = item, id = id, button = b, info = info, price = "BUY" }
	table.insert(shopCards, entry)
	b.Activated:Connect(function()
		buyShopItem(entry)
	end)
	-- Prices live in the Creator Dashboard: read them once.
	task.spawn(function()
		local infoType = item.kind == "pass" and Enum.InfoType.GamePass or Enum.InfoType.Product
		local ok, product = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and type(product) == "table" and type(product.PriceInRobux) == "number" then
			entry.price = "R$ " .. product.PriceInRobux
			refreshShop()
		end
	end)
end
refreshShop()

-- A pass bought just now (not one found on join) gets a banner.
for name in Config.GamePasses do
	player:GetAttributeChangedSignal("Pass_" .. name):Connect(function()
		refreshShop()
		if ownsPass(name) and os.clock() - lastPromptAt < 300 then
			for _, item in SHOP_ITEMS do
				if item.name == name then
					banner(item.title .. "!", item.text, 2.4, Color3.fromRGB(255, 205, 60))
				end
			end
			play(Config.Sounds.Coin, 0.8, 1)
		end
	end)
end

local shopButton = button(gui, "🛒 SHOP", Color3.fromRGB(230, 150, 30))
shopButton.Position = UDim2.new(0, 14, 0.34, 256)
shopButton.Size = UDim2.fromOffset(150, 46)
shopButton.Visible = #shopCards > 0
shopButton.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	indexPanel.Visible = false
	toolPanel.Visible = false
	upgradePanel.Visible = false
	hauntPanel.Visible = false
	if shopPanel.Visible then
		task.spawn(function()
			local ok, quotes = pcall(shopRemote.InvokeServer, shopRemote, "open")
			if ok and type(quotes) == "table" then
				shopQuotes = quotes
				refreshShop()
			end
		end)
	end
end)

local hauntButton = button(gui, "👻 HAUNT", Color3.fromRGB(120, 70, 190))
hauntButton.Position = UDim2.new(0, 172, 0.34, 204)
hauntButton.Size = UDim2.fromOffset(120, 46)
hauntButton.Activated:Connect(function()
	hauntPanel.Visible = not hauntPanel.Visible
	indexPanel.Visible = false
	toolPanel.Visible = false
	upgradePanel.Visible = false
	shopPanel.Visible = false
end)

indexButton.Activated:Connect(function()
	indexPanel.Visible = not indexPanel.Visible
	toolPanel.Visible = false
	upgradePanel.Visible = false
	hauntPanel.Visible = false
	shopPanel.Visible = false
end)

remotes:WaitForChild("IndexNew").OnClientEvent:Connect(function(keys: { string })
	for i, key in keys do
		local seedId, finish = string.match(key, "([^:]+):(.+)")
		local seed = seedById[seedId or ""]
		if seed then
			task.delay((i - 1) * 0.9, function()
				local label = finish == "Plain" and seed.name or (finish .. " " .. seed.name)
				banner("NEW IN YOUR INDEX!", label, 1.8, Color3.fromRGB(190, 140, 255))
				play(Config.Sounds.Brew, 1.5, 0.6)
			end)
		end
	end
end)

remotes:WaitForChild("Announce").OnClientEvent:Connect(function(text: string)
	banner("☠ " .. text, nil, 3, Color3.fromRGB(190, 90, 255))
	play(Config.Sounds.Brew, 0.7, 0.8)
end)

local function myPatch(): Model?
	for _, patch in patchFolder:GetChildren() do
		if patch:GetAttribute("Owner") == player.UserId then
			return patch
		end
	end
	return nil
end

-- Base prompts are made by the server; this shows only the ones that apply to you:
-- Place (your empty plot, while you carry), Pick up (your filled plot), LOCK (your sign post),
-- Steal (a filled, unprotected plot on someone else's unlocked base).
do
	local function set(prompt: Instance?, on: boolean, objectText: string?)
		if not prompt or not prompt:IsA("ProximityPrompt") then
			return
		end
		if prompt.Enabled ~= on then
			prompt.Enabled = on
		end
		if on and objectText and prompt.ObjectText ~= objectText then
			prompt.ObjectText = objectText
		end
	end
	local function pumpkinName(plot: Instance): string
		local pumpkin = plot:FindFirstChild("Pumpkin")
		local seed = pumpkin and seedById[pumpkin:GetAttribute("Seed") or ""]
		if not seed then
			return "Pumpkin"
		end
		local mutation = pumpkin:GetAttribute("Mutation")
		return (mutation and (mutation .. " ") or "") .. seed.name .. " pumpkin"
	end
	local function refreshPrompts()
		local now = workspace:GetServerTimeNow()
		local locksOff = (state:GetAttribute("LocksOff") or 0) > now
		local carrying = (player:GetAttribute("Carry") or 0) > 0
		for _, patch in patchFolder:GetChildren() do
			local owner = patch:GetAttribute("Owner") or 0
			local mine = owner == player.UserId
			local locked = not locksOff and (patch:GetAttribute("LockedUntil") or 0) > now
			for _, plot in patch:GetChildren() do
				if plot.Name == "Plot" then
					local filled = plot:GetAttribute("Filled") == true
					local name = filled and pumpkinName(plot) or nil
					set(
						plot:FindFirstChild("PlacePrompt"),
						mine and carrying and not filled,
						"Your plot"
					)
					set(plot:FindFirstChild("PickupPrompt"), mine and filled, name)
					set(
						plot:FindFirstChild("StealPrompt"),
						not mine
							and owner ~= 0
							and filled
							and not locked
							and plot:GetAttribute("Protected") ~= true,
						name
					)
				end
			end
			set(patch:FindFirstChild("LockPrompt", true), mine and not locksOff)
		end
	end
	patchFolder.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then
			task.defer(refreshPrompts)
		end
	end)
	task.spawn(function()
		while true do
			refreshPrompts()
			task.wait(0.25)
		end
	end)
end

-- "YOUR BASE" marker over your patch.
do
	local marker: BillboardGui? = nil
	local function refreshMarker()
		if marker then
			marker:Destroy()
			marker = nil
		end
		local patch = myPatch()
		local soil = patch and patch:FindFirstChild("Soil") :: BasePart?
		if not soil then
			return
		end
		marker = Instance.new("BillboardGui")
		marker.Size = UDim2.fromOffset(240, 56)
		marker.StudsOffsetWorldSpace = Vector3.new(0, 14, 0)
		marker.LightInfluence = 0
		marker.MaxDistance = 1000
		marker.Parent = soil
		textLabel(marker, "⬇ YOUR BASE ⬇", Color3.fromRGB(140, 255, 110)).Size =
			UDim2.fromScale(1, 1)
	end
	for _, patch in patchFolder:GetChildren() do
		patch:GetAttributeChangedSignal("Owner"):Connect(refreshMarker)
	end
	refreshMarker()
end

-- Lighting by phase ----------------------------------------------------------------------------

do
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local correction = Lighting:FindFirstChild("PhaseTint") :: ColorCorrectionEffect?
	if not correction then
		correction = Instance.new("ColorCorrectionEffect")
		correction.Name = "PhaseTint"
		correction.Parent = Lighting
	end
	local base = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		AtmosphereColor = atmosphere and atmosphere.Color or Color3.new(),
		AtmosphereDecay = atmosphere and atmosphere.Decay or Color3.new(),
		AtmosphereDensity = atmosphere and atmosphere.Density or 0.3,
	}
	-- The default look is bright daytime (captured above from Studio Lighting). Events only grade
	-- softly: Midnight is a blue dusk (never black), the Blood Moon a soft red, then back to base.
	local EVENT_LOOK = {
		Midnight = {
			lighting = {
				Ambient = Color3.fromRGB(95, 105, 160),
				OutdoorAmbient = Color3.fromRGB(120, 130, 185),
				Brightness = math.max(1.2, base.Brightness * 0.7),
				ClockTime = 18.4,
			},
			tint = {
				TintColor = Color3.fromRGB(215, 225, 255),
				Saturation = -0.05,
				Contrast = 0.05,
			},
			atmosphere = {
				Color = Color3.fromRGB(110, 120, 180),
				Decay = Color3.fromRGB(60, 60, 120),
				Density = math.max(base.AtmosphereDensity, 0.32),
			},
		},
		BloodMoon = {
			lighting = {
				Ambient = Color3.fromRGB(110, 60, 70),
				OutdoorAmbient = Color3.fromRGB(135, 75, 85),
				Brightness = math.max(1.1, base.Brightness * 0.65),
				ClockTime = 18.8,
			},
			tint = {
				TintColor = Color3.fromRGB(255, 179, 168),
				Saturation = 0.15,
				Contrast = 0.1,
			},
			atmosphere = {
				Color = Color3.fromRGB(122, 16, 32),
				Decay = Color3.fromRGB(42, 5, 8),
				Density = 0.4,
			},
		},
	}
	local function setLighting(phase: string)
		local info = TweenInfo.new(2.5, Enum.EasingStyle.Sine)
		local tint = correction :: ColorCorrectionEffect
		local look = EVENT_LOOK[phase]
		if look then
			TweenService:Create(Lighting, info, look.lighting):Play()
			TweenService:Create(tint, info, look.tint):Play()
			if atmosphere then
				TweenService:Create(atmosphere, info, look.atmosphere):Play()
			end
		else
			TweenService:Create(Lighting, info, {
				Ambient = base.Ambient,
				OutdoorAmbient = base.OutdoorAmbient,
				Brightness = base.Brightness,
				ClockTime = base.ClockTime,
			}):Play()
			TweenService
				:Create(
					tint,
					info,
					{ TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0 }
				)
				:Play()
			if atmosphere then
				TweenService:Create(atmosphere, info, {
					Color = base.AtmosphereColor,
					Decay = base.AtmosphereDecay,
					Density = base.AtmosphereDensity,
				}):Play()
			end
		end
	end
	local lastPhase = nil
	local function onPhase()
		local phase = state:GetAttribute("Phase") or "Day"
		if phase == lastPhase then
			return
		end
		local previous = lastPhase
		lastPhase = phase
		setLighting(phase)
		if phase == "Midnight" then
			banner(
				"MIDNIGHT!",
				"Ghosts are raiding the bases. Lock yours and bonk them!",
				3,
				Color3.fromRGB(170, 220, 255)
			)
			play(Config.Sounds.Brew, 0.5, 0.8)
		elseif phase == "BloodMoon" then
			local locksOff = (state:GetAttribute("LocksOff") or 0) > workspace:GetServerTimeNow()
			banner(
				"BLOOD MOON!",
				locksOff and "Every lock is OFF! Steal from any base before the King wakes!"
					or "The Pumpkin King wakes! Everyone bonk him!",
				3.5,
				Color3.fromRGB(255, 90, 80)
			)
			play(Config.Sounds.Brew, 0.4, 1)
		elseif previous == "Midnight" then
			banner("DAWN", "The ghosts flee. Back to farming!", 2.4)
		end
	end
	state:GetAttributeChangedSignal("Phase"):Connect(onPhase)
	onPhase()
end

-- Scythe ---------------------------------------------------------------------------------------

do
	local bonkEvent = remotes:WaitForChild("Bonk")
	local lastSwing = 0
	local function swingTool(tool: Tool)
		if tool:GetAttribute("Swinging") then
			return
		end
		tool:SetAttribute("Swinging", true)
		local grip = tool.Grip
		-- Wind up, whip down, return.
		tool.Grip = grip * CFrame.Angles(math.rad(30), 0, 0)
		task.delay(0.06, function()
			tool.Grip = grip * CFrame.Angles(math.rad(-100), 0, 0)
			task.delay(0.1, function()
				tool.Grip = grip * CFrame.Angles(math.rad(-50), 0, 0)
				task.delay(0.08, function()
					tool.Grip = grip
					tool:SetAttribute("Swinging", nil)
				end)
			end)
		end)
	end
	-- Equipping re-parents the tool into the character (ChildAdded again): hook each tool once.
	local hookedTools: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any
	local function hookTool(tool: Instance)
		if not tool:IsA("Tool") or tool.Name ~= "Scythe" or hookedTools[tool] then
			return
		end
		hookedTools[tool] = true
		tool.Activated:Connect(function()
			local now = os.clock()
			-- Fast Hands (skill id QuickRoots) swings faster.
			local fast = string.find(player:GetAttribute("Skills") or "", "QuickRoots", 1, true)
			if
				now - lastSwing
				< Config.BonkCooldown / (fast and 1 + Config.SkillSwingBonus or 1)
			then
				return
			end
			lastSwing = now
			swingTool(tool)
			play(Config.Sounds.Whoosh, 0.9 + math.random() * 0.25, 0.5)
			bonkEvent:FireServer()
		end)
	end
	local function hookCharacter(character: Model)
		character.ChildAdded:Connect(hookTool)
		for _, child in character:GetChildren() do
			hookTool(child)
		end
		-- Equip the scythe right away so the first click swings (the server hands it over a
		-- moment after spawning, so keep trying for a few seconds).
		task.spawn(function()
			for _ = 1, 12 do
				task.wait(0.5)
				if player.Character ~= character or character:FindFirstChild("Scythe") then
					return
				end
				local backpack = player:FindFirstChildOfClass("Backpack")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local scythe = backpack and backpack:FindFirstChild("Scythe")
				if humanoid and scythe then
					humanoid:EquipTool(scythe)
					return
				end
			end
		end)
	end
	player.CharacterAdded:Connect(hookCharacter)
	if player.Character then
		hookCharacter(player.Character)
	end
	remotes:WaitForChild("Swing").OnClientEvent:Connect(function(who: Player)
		if who ~= player then
			local tool = who.Character and who.Character:FindFirstChild("Scythe")
			if tool then
				swingTool(tool :: Tool)
			end
		end
	end)
end

-- Effects ----------------------------------------------------------------------------------------

local combo, comboAt = 0, 0
local function countHit(at: Vector3)
	local now = os.clock()
	combo = now - comboAt < 2 and combo + 1 or 1
	comboAt = now
	if combo >= 3 then
		floatText(
			at + Vector3.new(0, 6, 0),
			"x" .. combo .. " COMBO!",
			Color3.fromRGB(255, 240, 120)
		)
	end
end

-- A pumpkin went onto a base plot (income = its candy per second there).
remotes
	:WaitForChild("Placed").OnClientEvent
	:Connect(function(who: Player, at: Vector3, income: number)
		burst(at + Vector3.new(0, 1, 0), Color3.fromRGB(150, 255, 110), 18, 12, SPARKLE, 0.8)
		burst(at + Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 80, 50), 10, 8)
		if who == player then
			play(Config.Sounds.Pick, 0.8, 0.7)
			if income > 0 then
				local text = income < 10 and string.format("%.1f", income) or short(income)
				floatText(
					at + Vector3.new(0, 4, 0),
					"+" .. text .. " 🍬/s",
					Color3.fromRGB(150, 255, 110)
				)
			end
		end
	end)

-- Swing hits on wild pumpkins: a small burst for everyone, a damage number for the hitter.
remotes
	:WaitForChild("WildHit").OnClientEvent
	:Connect(function(who: Player, at: Vector3, damage: number)
		burst(at + Vector3.new(0, 1, 0), Color3.fromRGB(255, 160, 60), 6, 10, SPARKLE, 0.5)
		if who == player then
			local jitter = Vector3.new((math.random() - 0.5) * 2, 3, (math.random() - 0.5) * 2)
			floatText(at + jitter, "-" .. short(damage), Color3.fromRGB(255, 235, 110))
			play(Config.Sounds.Bonk, 1.1 + math.min(combo, 10) * 0.03, 0.55)
			countHit(at)
		end
	end)

-- A wild pumpkin popped; the winner (most damage) got it.
remotes
	:WaitForChild("WildPopped").OnClientEvent
	:Connect(function(at: Vector3, seedId: string, winner: Player?)
		local seed = seedById[seedId or ""]
		local color = seed and seedColor(seed) or Color3.fromRGB(255, 130, 40)
		burst(at, color, 26, 24, SPARKLE, 1.1)
		burst(at, color, 14, 10, nil, 2.2)
		play(Config.Sounds.Pick, 1.3, 0.7)
		if winner == player and seed then
			floatText(at + Vector3.new(0, 4, 0), "+1 " .. seed.name .. "!", color, seed.order >= 3)
			if seed.order >= 4 then
				banner("RARE PUMPKIN!", seed.name .. " pumpkin", 2, color)
			end
			task.spawn(shake, 0.4, 5)
		end
	end)

remotes:WaitForChild("Harvested").OnClientEvent:Connect(function(who: Player, at: Vector3)
	burst(at + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 200, 90), 20, 14, SPARKLE, 0.8)
	burst(at + Vector3.new(0, 1, 0), Color3.fromRGB(255, 130, 40), 12, 11, SPARKLE, 0.5)
	if who == player then
		play(Config.Sounds.Pick, 1.1, 0.8)
		floatText(at + Vector3.new(0, 3, 0), "+1 🎃", Color3.fromRGB(255, 170, 60))
	end
end)

remotes
	:WaitForChild("Brewed").OnClientEvent
	:Connect(function(who: Player, at: Vector3, results: { any })
		burst(at + Vector3.new(0, 2, 0), Color3.fromRGB(200, 140, 255), 40, 26, SPARKLE, 1.2)
		burst(at + Vector3.new(0, 2, 0), Color3.fromRGB(150, 90, 255), 16, 12)
		if who ~= player then
			return
		end
		play(Config.Sounds.Brew, 1.2, 0.8)
		local root = rootPart()
		for i, r in results do
			local m = mutationById[r.id]
			task.delay((i - 1) * 0.35, function()
				local where = (root and root.Position or at) + Vector3.new(0, 8 + i * 1.5, 0)
				floatText(
					where,
					string.format("%s x%d!", string.upper(r.id), m and m.mult or 1),
					m and m.color or Color3.new(1, 1, 1),
					r.id == "Cursed" or r.id == "Candy"
				)
				if r.id == "Cursed" then
					banner("CURSED x10!", "Super rare pumpkin!", 2, Color3.fromRGB(190, 90, 255))
				end
			end)
		end
	end)

remotes
	:WaitForChild("Sold").OnClientEvent
	:Connect(function(who: Player, at: Vector3, total: number, _count: number, raw: number)
		burst(at + Vector3.new(0, 3, 0), Color3.fromRGB(255, 150, 210), 30, 22, SPARKLE, 1)
		if who == player then
			floatText(
				at + Vector3.new(0, 7, 0),
				"+" .. total .. " 🍬",
				Color3.fromRGB(255, 160, 220),
				true
			)
			play(Config.Sounds.Coin, 1, 0.9)
			candyShower(8)
			if raw > 0 then
				task.delay(1.2, function()
					hint("Tip: brew pumpkins in a Magic Cauldron first. They sell for x2 to x10!")
				end)
			end
		end
		floatText(
			giantJack.Position + Vector3.new(0, 6, 0),
			"+" .. total,
			Color3.fromRGB(255, 170, 60)
		)
	end)

remotes
	:WaitForChild("GhostPopped").OnClientEvent
	:Connect(function(at: Vector3, by: Player?, candy: number)
		if candy > 0 then
			burst(at, Color3.fromRGB(220, 235, 255), 26, 26, SPARKLE, 1.2)
			-- White poof: a puffy smoke cloud on top of the sparkles.
			burst(at, Color3.fromRGB(255, 255, 255), 18, 9, nil, 3)
			play(Config.Sounds.Bonk, 1.25, 0.9)
			if by == player then
				floatText(
					at + Vector3.new(0, 3, 0),
					"BONK! +" .. candy .. " 🍬",
					Color3.fromRGB(200, 230, 255)
				)
				-- About 0.15 s of shake (7 steps of 0.02 s).
				task.spawn(shake, 0.6, 7)
			end
		elseif by == nil then
			burst(at, Color3.fromRGB(220, 235, 255), 8, 12, SPARKLE, 0.8)
			burst(at, Color3.fromRGB(255, 255, 255), 6, 6, nil, 1.6)
			play(Config.Sounds.Bonk, 1.4, 0.6)
		end
	end)

remotes:WaitForChild("Stolen").OnClientEvent:Connect(function()
	hint("👻 A ghost got away with your pumpkin. Bonk them before they fly off!")
end)

remotes
	:WaitForChild("KingHit").OnClientEvent
	:Connect(function(who: Player, power: number, stunned: boolean)
		local at = kingFace.Position
			+ Vector3.new(
				(math.random() - 0.5) * 10,
				(math.random() - 0.5) * 6,
				(math.random() - 0.5) * 10
			)
		burst(at, Color3.fromRGB(255, 120, 60), stunned and 18 or 10, 14, SPARKLE, 0.9)
		if who == player then
			floatText(
				at,
				"-" .. power,
				stunned and Color3.fromRGB(255, 150, 40) or Color3.fromRGB(255, 230, 90),
				stunned
			)
			play(Config.Sounds.Bonk, 0.9 + math.min(combo, 10) * 0.03, 0.8)
			countHit(at)
		end
	end)

remotes:WaitForChild("Stomp").OnClientEvent:Connect(function(kind: string, circles: { any })
	local root = rootPart()
	for _, c in circles do
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 90, 50)
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CastShadow = false
		ring.Transparency = 0.2
		ring.Size = Vector3.new(0.3, 2, 2)
		ring.CFrame = CFrame.new(c.pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace
		TweenService
			:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.3, c.radius * 2.4, c.radius * 2.4),
				Transparency = 1,
			})
			:Play()
		task.delay(0.5, function()
			ring:Destroy()
		end)
		burst(
			c.pos + Vector3.new(0, 1, 0),
			Color3.fromRGB(120, 90, 70),
			kind == "Slam" and 30 or 10,
			20
		)
	end
	play(Config.Sounds.Bonk, kind == "Slam" and 0.45 or 0.7, 1)
	if root and (Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude < 60 then
		task.spawn(shake, kind == "Slam" and 1.4 or 0.6, 10)
	end
end)

remotes
	:WaitForChild("KingDone").OnClientEvent
	:Connect(function(kind: string, payouts: { [string]: number }, mvp: Player?)
		if kind == "won" then
			local mine = payouts[tostring(player.UserId)]
			banner(
				"THE KING IS DEFEATED!",
				(mine and ("+" .. mine .. " 🍬 for helping! ") or "")
					.. (mvp and ("MVP: " .. mvp.DisplayName) or ""),
				4
			)
			burst(kingFace.Position, Color3.fromRGB(255, 220, 120), 120, 60, SPARKLE, 2.4)
			burst(kingFace.Position, Color3.fromRGB(255, 140, 40), 40, 30)
			play(Config.Sounds.Coin, 0.8, 1)
			task.spawn(shake, 2, 14)
			local camera = workspace.CurrentCamera
			camera.FieldOfView = 90
			TweenService
				:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { FieldOfView = 70 })
				:Play()
		elseif kind == "wake" then
			banner("THE PUMPKIN KING WAKES!", "Everyone bonk him!", 3, Color3.fromRGB(255, 90, 80))
			play(Config.Sounds.Brew, 0.4, 1)
		elseif kind == "swell" then
			banner("HE'S GOING TO BURST!", nil, 1.5, Color3.fromRGB(255, 120, 60))
			play(Config.Sounds.Brew, 0.5, 1)
		elseif kind == "phase2" then
			banner(
				"SHIELD UP!",
				"Bonk the Lantern ghosts at the cauldrons!",
				3,
				Color3.fromRGB(200, 140, 255)
			)
			play(Config.Sounds.Brew, 0.6, 1)
		elseif kind == "stun" then
			banner("HE'S STUNNED! SMASH HIM!", "Double damage!", 2.5, Color3.fromRGB(255, 200, 60))
			play(Config.Sounds.Bonk, 0.5, 1)
			task.spawn(shake, 1, 8)
		elseif kind == "phase3" then
			banner(
				"THE KING IS ANGRY!",
				"Faster attacks. Finish him!",
				2.5,
				Color3.fromRGB(255, 70, 50)
			)
			play(Config.Sounds.Brew, 0.4, 1)
		else
			banner(
				"THE KING ESCAPED",
				"The Jack is half full. Sell to try again!",
				3,
				Color3.fromRGB(255, 140, 120)
			)
		end
	end)

remotes:WaitForChild("RainCollected").OnClientEvent:Connect(function(collector: Player, at: Vector3)
	burst(at, Color3.fromRGB(255, 210, 80), 14, 14, SPARKLE, 0.8)
	if collector == player then
		floatText(
			at + Vector3.new(0, 3, 0),
			"+" .. Config.RainCandy .. " 🍬",
			Color3.fromRGB(255, 214, 80)
		)
		play(Config.Sounds.Coin, 1.1 + math.random() * 0.2, 0.6)
	end
end)

-- Zones: gate walls open locally for zones you unlocked, gate signs say UNLOCKED, and a banner
-- names each zone you walk into. The server keeps every wall solid for everyone else. --------

local ZoneView: { [string]: any } = {}
do
	local GREEN = Color3.fromRGB(150, 255, 110)
	local folders: { [string]: Instance } = {}
	-- X/Z box around each zone's Spawn parts: { minX, maxX, minZ, maxZ }.
	local boxes: { [string]: { number } } = {}
	local wallLook: { [BasePart]: number } = {}

	local function ownedSet(): { [string]: boolean }
		local owned = {}
		for id in string.gmatch(player:GetAttribute("Zones") or "", "[^,]+") do
			owned[id] = true
		end
		return owned
	end

	function ZoneView.has(zoneId: string, owned: { [string]: boolean }?): boolean
		local def = Config.Zones[zoneId]
		if def and (def.cost or 0) <= 0 then
			return true
		end
		return (owned or ownedSet())[zoneId] == true
	end

	-- The first zone in unlock order you do not have yet.
	function ZoneView.nextLocked(): string?
		local owned = ownedSet()
		for _, zoneId in Config.ZoneOrder do
			if Config.Zones[zoneId] and not ZoneView.has(zoneId, owned) then
				return zoneId
			end
		end
		return nil
	end

	function ZoneView.gate(zoneId: string): Vector3?
		local folder = folders[zoneId]
		local wall = folder and folder:FindFirstChild("GateWall") :: BasePart?
		return wall and wall.Position
	end

	local function refreshGates()
		local owned = ownedSet()
		for zoneId, folder in folders do
			local def = Config.Zones[zoneId]
			if not def or (def.cost or 0) <= 0 then
				continue
			end
			local open = ZoneView.has(zoneId, owned)
			local wall = folder:FindFirstChild("GateWall")
			if wall and wall:IsA("BasePart") then
				if wallLook[wall] == nil then
					wallLook[wall] = wall.Transparency
				end
				local transparency = open and 1 or wallLook[wall]
				if wall.CanCollide == open then
					wall.CanCollide = not open
				end
				if wall.Transparency ~= transparency then
					wall.Transparency = transparency
				end
				local prompt = wall:FindFirstChild("UnlockPrompt") :: ProximityPrompt?
				if prompt and prompt.Enabled == open then
					prompt.Enabled = not open
				end
			end
			local sign = folder:FindFirstChild("GateSign")
			local gateGui = sign and sign:FindFirstChild("GateGui")
			local costLabel = gateGui and gateGui:FindFirstChild("Cost") :: TextLabel?
			if costLabel then
				local text = open and "✅ UNLOCKED" or ("🔒 " .. short(def.cost) .. " 🍬")
				if costLabel.Text ~= text then
					costLabel.Text = text
					costLabel.TextColor3 = open and GREEN or Color3.fromRGB(255, 240, 220)
				end
			end
		end
	end

	local function inBox(zoneId: string, pos: Vector3, margin: number): boolean
		local box = boxes[zoneId]
		return box ~= nil
			and pos.X >= box[1] - margin
			and pos.X <= box[2] + margin
			and pos.Z >= box[3] - margin
			and pos.Z <= box[4] + margin
	end

	local function zoneBanner(zoneId: string)
		local def = Config.Zones[zoneId]
		if not def then
			return
		end
		local level = table.find(Config.ZoneOrder, zoneId) or 1
		local sub = ZoneView.has(zoneId)
				and string.format("Zone %d · smash the wild pumpkins!", level)
			or string.format(
				"🔒 Locked · unlock it at the gate for %s 🍬",
				short(def.cost or 0)
			)
		banner(string.upper(def.title), sub, 2, Color3.fromRGB(255, 190, 90))
	end

	local known = ownedSet()
	player:GetAttributeChangedSignal("Zones"):Connect(function()
		local now = ownedSet()
		if player:GetAttribute("Loaded") then
			for _, zoneId in Config.ZoneOrder do
				local def = Config.Zones[zoneId]
				if def and now[zoneId] and not known[zoneId] and (def.cost or 0) > 0 then
					banner(
						string.upper(def.title) .. " UNLOCKED!",
						"New pumpkins to smash inside!",
						2.6,
						GREEN
					)
					play(Config.Sounds.Coin, 0.8, 1)
				end
			end
		end
		known = now
		refreshGates()
	end)

	task.spawn(function()
		local zones = garden:WaitForChild("Zones", 15)
		if not zones then
			return
		end
		for _, zoneId in Config.ZoneOrder do
			local folder = zones:WaitForChild(zoneId, 5)
			if not folder then
				continue
			end
			folders[zoneId] = folder
			local box = nil
			for _, d in folder:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Spawn" then
					local p = d.Position
					if not box then
						box = { p.X, p.X, p.Z, p.Z }
					else
						box[1] = math.min(box[1], p.X)
						box[2] = math.max(box[2], p.X)
						box[3] = math.min(box[3], p.Z)
						box[4] = math.max(box[4], p.Z)
					end
				end
			end
			boxes[zoneId] = box
		end
		refreshGates()
		-- Entering a zone (a little past its outer spawn spots) shows its banner; leaving needs
		-- a wider margin so walking along the edge does not repeat it.
		local inside: string? = nil
		while true do
			task.wait(0.5)
			refreshGates()
			local root = rootPart()
			if not root or not player:GetAttribute("Loaded") then
				continue
			end
			local here: string? = nil
			if inside and inBox(inside, root.Position, 16) then
				here = inside
			else
				for _, zoneId in Config.ZoneOrder do
					if inBox(zoneId, root.Position, 8) then
						here = zoneId
						break
					end
				end
			end
			if here ~= inside then
				inside = here
				if here then
					zoneBanner(here)
				end
			end
		end
	end)
end

-- Witch's Orders: a card with the current order and a glowing line to where it happens. -----

local guideFrame = Instance.new("Frame")
guideFrame.AnchorPoint = Vector2.new(0.5, 1)
guideFrame.Position = UDim2.new(0.5, 0, 1, -14)
guideFrame.Size = UDim2.fromOffset(600, 66)
guideFrame.BackgroundColor3 = DARK
guideFrame.BackgroundTransparency = 0.1
guideFrame.Parent = gui
corner(guideFrame, 18)
stroke(guideFrame, 3)
local guideText = textLabel(guideFrame, "", Color3.fromRGB(150, 255, 110))
guideText.Position = UDim2.fromOffset(20, 6)
guideText.Size = UDim2.new(1, -40, 0, 32)
local guideReward = textLabel(guideFrame, "", Color3.fromRGB(255, 220, 120))
guideReward.Position = UDim2.fromOffset(20, 40)
guideReward.Size = UDim2.new(1, -40, 0, 20)

local beamEnd = Instance.new("Part")
beamEnd.Name = "GuideTarget"
beamEnd.Anchored = true
beamEnd.CanCollide = false
beamEnd.CanQuery = false
beamEnd.Transparency = 1
beamEnd.Size = Vector3.one
beamEnd.Parent = workspace
local endAttach = Instance.new("Attachment")
endAttach.Parent = beamEnd
local beam = Instance.new("Beam")
beam.Attachment1 = endAttach
beam.Width0 = 0.8
beam.Width1 = 0.8
beam.Color = ColorSequence.new(Color3.fromRGB(255, 179, 71))
beam.LightEmission = 1
beam.Transparency = NumberSequence.new(0.5)
beam.FaceCamera = true
beam.Segments = 1
beam.Parent = beamEnd
local arrow = Instance.new("BillboardGui")
arrow.Size = UDim2.fromOffset(70, 70)
arrow.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
arrow.AlwaysOnTop = true
arrow.LightInfluence = 0
arrow.Parent = beamEnd
textLabel(arrow, "⬇", Color3.fromRGB(255, 179, 71)).Size = UDim2.fromScale(1, 1)

local function nearestCauldron(from: Vector3): Vector3
	local best, bestDist = Vector3.zero, math.huge
	for _, c in cauldronFolder:GetChildren() do
		local pot = c:FindFirstChild("Pot") :: BasePart?
		if pot then
			local d = (pot.Position - from).Magnitude
			if d < bestDist then
				best, bestDist = pot.Position, d
			end
		end
	end
	return best
end

local function setGuide(text: string, sub: string, target: Vector3?)
	guideText.Text = text
	guideReward.Text = sub
	if target then
		beamEnd.Position = target + Vector3.new(0, 2, 0)
		local root = rootPart()
		local a0 = root and root:FindFirstChild("GuideStart") :: Attachment?
		if root and not a0 then
			local a = Instance.new("Attachment")
			a.Name = "GuideStart"
			a.Position = Vector3.new(0, -2, 0)
			a.Parent = root
			a0 = a
		end
		beam.Attachment0 = a0
		beam.Enabled = true
		arrow.Enabled = true
	else
		beam.Enabled = false
		arrow.Enabled = false
	end
end

-- The server publishes orders as JSON in the "Orders" attribute.
local ordersData: { [string]: any }? = nil
local function readOrders()
	local raw = player:GetAttribute("Orders")
	if type(raw) ~= "string" then
		ordersData = nil
		return
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	ordersData = ok and type(data) == "table" and data or nil
end
player:GetAttributeChangedSignal("Orders"):Connect(readOrders)
readOrders()

local function stallPosition(name: string): Vector3?
	local stall = market:FindFirstChild(name)
	return stall and (stall :: Model):GetPivot().Position
end

-- The zone: the nearest wild pumpkin in a zone you unlocked, else the nearest spawn spot of Zone1.
local function zoneTarget(from: Vector3): Vector3?
	local best, bestDist = nil, math.huge
	local wild = garden:FindFirstChild("Wild")
	local zones = garden:FindFirstChild("Zones")
	local zone = zones and zones:FindFirstChild("Zone1")
	for _, list in { wild and wild:GetChildren() or {}, zone and zone:GetChildren() or {} } do
		for _, part in list do
			local zoneId = part:GetAttribute("Zone")
			if part:IsA("BasePart") and (type(zoneId) ~= "string" or ZoneView.has(zoneId)) then
				local d = (part.Position - from).Magnitude
				if d < bestDist then
					best, bestDist = part.Position, d
				end
			end
		end
		if best then
			return best
		end
	end
	return nil
end

-- The nearest base of another player (for steal orders).
local function otherBase(from: Vector3): Vector3?
	local best, bestDist = nil, math.huge
	for _, patch in patchFolder:GetChildren() do
		local owner = patch:GetAttribute("Owner") or 0
		local soil = patch:FindFirstChild("Soil") :: BasePart?
		if soil and owner ~= 0 and owner ~= player.UserId then
			local d = (soil.Position - from).Magnitude
			if d < bestDist then
				best, bestDist = soil.Position, d
			end
		end
	end
	return best
end

-- Where the beam points for an order, given what you carry right now. Without pumpkins the
-- way to the cauldron / Witch / your base starts in the zone.
local function orderTarget(kind: string, root: BasePart, soil: BasePart): Vector3?
	local carry = player:GetAttribute("Carry") or 0
	local zone = zoneTarget(root.Position) or soil.Position
	if kind == "zone" then
		return zone
	elseif kind == "place" then
		return carry > 0 and soil.Position or zone
	elseif kind == "steal" then
		return carry > 0 and soil.Position or otherBase(root.Position) or soil.Position
	elseif kind == "cauldron" then
		return carry > 0 and nearestCauldron(root.Position) or zone
	elseif kind == "witch" then
		return carry > 0 and stallPosition("Sell") or zone
	elseif kind == "tools" or kind == "seeds" then
		return stallPosition("Seeds")
	elseif kind == "upgrades" then
		return stallPosition("Upgrades")
	elseif kind == "king" then
		return state:GetAttribute("Phase") == "BloodMoon" and kingFace.Position
			or giantJack.Position
	elseif kind == "gate" then
		local nextZone = ZoneView.nextLocked()
		return nextZone and ZoneView.gate(nextZone) or soil.Position
	end
	return soil.Position
end

-- Keep the order card clear of the touch SWING / RUN buttons (about 260 px from the right edge,
-- not affected by uiScale).
local function fitBottom()
	local camera = workspace.CurrentCamera
	if not camera or uiScale.Scale <= 0 then
		return
	end
	local scale = uiScale.Scale
	local w = camera.ViewportSize.X / scale
	local side = UserInputService.TouchEnabled and 270 / scale or 20
	local guideWidth = math.floor(math.min(600, math.max(300, w - 2 * side)))
	if guideFrame.Size.X.Offset ~= guideWidth then
		guideFrame.Size = UDim2.fromOffset(guideWidth, 66)
	end
end

task.spawn(function()
	while true do
		task.wait(0.4)
		fitBottom()
		local root = rootPart()
		local patch = myPatch()
		if not root or not patch then
			continue
		end
		local soil = patch:FindFirstChild("Soil") :: BasePart
		local data = ordersData
		if not data or not player:GetAttribute("Loaded") then
			setGuide("Loading your farm...", "", nil)
			continue
		end
		-- After the tutorial: when the next zone's gate is affordable, the beam points there.
		local nextZone = not data.tutorial and ZoneView.nextLocked() or nil
		local nextDef = nextZone and Config.Zones[nextZone]
		local gatePos = nextZone and ZoneView.gate(nextZone)
		if nextDef and gatePos and candyValue.Value >= (nextDef.cost or 0) then
			setGuide(
				"NEW ZONE: Unlock the " .. nextDef.title .. "!",
				"Costs " .. short(nextDef.cost or 0) .. " 🍬 · follow the beam to its gate",
				gatePos
			)
			continue
		end
		local current = nil
		for _, order in data.list or {} do
			if not order.done then
				current = order
				break
			end
		end
		if not current then
			local left = (data.refreshAt or 0) - workspace:GetServerTimeNow()
			setGuide("All orders done!", "New orders from the Witch in " .. clockText(left), nil)
			continue
		end
		local text = string.format("ORDER: %s  %d/%d", current.text, current.have, current.need)
		local sub = "Reward: " .. current.reward
		if data.tutorial then
			sub = string.format("Step %d/%d · %s", data.step or 1, data.steps or 8, sub)
		end
		setGuide(text, sub, orderTarget(current.target, root, soil))
	end
end)

remotes:WaitForChild("OrderDone").OnClientEvent:Connect(function(text: string, reward: string)
	banner("ORDER DONE!", text .. " · " .. reward, 2.6, Color3.fromRGB(150, 255, 110))
	play(Config.Sounds.Coin, 1.2, 0.9)
	play(Config.Sounds.Brew, 1.6, 0.5)
end)

remotes
	:WaitForChild("Daily").OnClientEvent
	:Connect(function(streak: number, candy: number, token: boolean)
		banner(
			string.format("DAILY CHEST · DAY %d", streak),
			string.format("+%s candy", short(candy)) .. (token and " · next brew is CURSED!" or ""),
			3.5,
			Color3.fromRGB(255, 214, 80)
		)
		play(Config.Sounds.Coin, 0.9, 1)
	end)

-- Movement: faster by default, sprint on Shift or the RUN button, slower per carried pumpkin. --

local ContextActionService = game:GetService("ContextActionService")
local sprinting = false
local dizzyUntil = 0
local function setSprint(on: boolean)
	if sprinting == on then
		return
	end
	sprinting = on
	local camera = workspace.CurrentCamera
	TweenService:Create(camera, TweenInfo.new(on and 0.2 or 0.3, Enum.EasingStyle.Quad), {
		FieldOfView = on and Config.SprintFov or 70,
	}):Play()
end
ContextActionService:BindAction("Sprint", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		setSprint(not sprinting or UserInputService.KeyboardEnabled)
	elseif inputState == Enum.UserInputState.End and UserInputService.KeyboardEnabled then
		setSprint(false)
	end
	return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle("Sprint", "RUN")
ContextActionService:SetPosition("Sprint", UDim2.new(1, -170, 1, -150))

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local speed = sprinting and Config.SprintSpeed or Config.WalkSpeed
	speed = math.max(
		Config.MinCarrySpeed,
		speed - (player:GetAttribute("Carry") or 0) * Config.SlowPerPumpkin
	)
	if os.clock() < dizzyUntil then
		speed = 6
	end
	if humanoid.WalkSpeed ~= speed then
		humanoid.WalkSpeed = speed
	end
	if humanoid.JumpPower ~= Config.JumpPower then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = Config.JumpPower
	end
end)

-- Humanoids cancel sideways velocity, so push sideways with a short LinearVelocity.
local function launch(root: BasePart, velocity: Vector3, seconds: number)
	root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
	local attachment = root:FindFirstChild("RootAttachment") :: Attachment?
	if not attachment then
		return
	end
	local push = Instance.new("LinearVelocity")
	push.Attachment0 = attachment
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	push.PrimaryTangentAxis = Vector3.xAxis
	push.SecondaryTangentAxis = Vector3.zAxis
	push.PlaneVelocity = Vector2.new(velocity.X, velocity.Z)
	push.MaxForce = 1e6
	push.Parent = root
	task.delay(seconds, function()
		push:Destroy()
	end)
end

-- Jump pads on the roads.
do
	local padFolder = garden:WaitForChild("JumpPads", 5)
	local lastPad = 0
	if padFolder then
		for _, pad in padFolder:GetChildren() do
			if pad:IsA("BasePart") then
				pad.Touched:Connect(function(hit)
					local character = player.Character
					local root = rootPart()
					if
						not character
						or not root
						or not hit:IsDescendantOf(character)
						or os.clock() - lastPad < 1
					then
						return
					end
					lastPad = os.clock()
					local dir = pad:GetAttribute("Dir") or Vector3.new(0, 0, -1)
					launch(root, dir * Config.PadForward + Vector3.new(0, Config.PadUp, 0), 0.6)
					play(Config.Sounds.Pick, 0.6, 0.9)
					burst(
						root.Position - Vector3.new(0, 2, 0),
						Color3.fromRGB(255, 160, 60),
						20,
						18,
						SPARKLE,
						1
					)
				end)
			end
		end
	end
end

-- Knocked by the King: fly back and stay dizzy for a moment.
remotes:WaitForChild("Knock").OnClientEvent:Connect(function(velocity: Vector3, dizzy: number)
	local root = rootPart()
	if root then
		launch(root, velocity, 0.35)
		dizzyUntil = os.clock() + dizzy
		floatText(root.Position + Vector3.new(0, 4, 0), "DIZZY!", Color3.fromRGB(255, 230, 120))
		task.spawn(shake, 1.4, 10)
	end
end)

-- Mobile SWING button that swings the scythe you hold.
ContextActionService:BindAction("Bonk", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		local character = player.Character
		local tool = character and character:FindFirstChild("Scythe") :: Tool?
		if not tool then
			local backpack = player:FindFirstChildOfClass("Backpack")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local scythe = backpack and backpack:FindFirstChild("Scythe")
			if humanoid and scythe then
				humanoid:EquipTool(scythe)
			end
			return Enum.ContextActionResult.Sink
		end
		tool:Activate()
	end
	return Enum.ContextActionResult.Pass
end, true)
ContextActionService:SetTitle("Bonk", "SWING")
ContextActionService:SetPosition("Bonk", UDim2.new(1, -250, 1, -100))

-- Boss: warnings, shield bubble, enrage glow, MVP crowns, top damage. -----------------------

local function circlePart(pos: Vector3, radius: number, warn: number)
	local disc = Instance.new("Part")
	disc.Shape = Enum.PartType.Cylinder
	disc.Material = Enum.Material.Neon
	disc.Color = Color3.fromRGB(255, 60, 50)
	-- A see-through fill grows inside a thin glowing outline ring (no solid red floor).
	disc.Transparency = 0.75
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc.CastShadow = false
	disc.Size = Vector3.new(0.2, 0.5, 0.5)
	disc.CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disc.Parent = workspace
	local edge = Instance.new("Part")
	edge.Anchored = true
	edge.CanCollide = false
	edge.CanQuery = false
	edge.CanTouch = false
	edge.Transparency = 1
	edge.Size = Vector3.one
	edge.CFrame = CFrame.new(pos + Vector3.new(0, 0.25, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	edge.Parent = workspace
	local ring = Instance.new("CylinderHandleAdornment")
	ring.Adornee = edge
	ring.Radius = radius
	ring.InnerRadius = math.max(0, radius - 0.7)
	ring.Height = 0.25
	ring.Color3 = Color3.fromRGB(255, 70, 50)
	ring.Transparency = 0.4
	ring.Parent = edge
	TweenService:Create(disc, TweenInfo.new(warn, Enum.EasingStyle.Linear), {
		Size = Vector3.new(0.2, radius * 2, radius * 2),
	}):Play()
	task.delay(warn + 0.15, function()
		disc:Destroy()
		edge:Destroy()
	end)
end

remotes
	:WaitForChild("Telegraph").OnClientEvent
	:Connect(function(kind: string, circles: { any }, warn: number)
		for _, c in circles do
			circlePart(c.pos, c.radius, warn)
			if kind == "Volley" then
				-- A seed ball arcs from the King onto each circle.
				task.delay(warn - 0.45, function()
					local seed = Instance.new("Part")
					seed.Shape = Enum.PartType.Ball
					seed.Size = Vector3.new(3, 3, 3)
					seed.Material = Enum.Material.SmoothPlastic
					seed.Color = Color3.fromRGB(40, 24, 20)
					seed.Anchored = true
					seed.CanCollide = false
					seed.CanQuery = false
					seed.Position = kingFace.Position + Vector3.new(0, 6, 0)
					seed.Parent = workspace
					local from = seed.Position
					local to = c.pos + Vector3.new(0, 1.5, 0)
					local t0 = os.clock()
					local conn
					conn = RunService.RenderStepped:Connect(function()
						local t = math.min(1, (os.clock() - t0) / 0.45)
						local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 18, 0)
						seed.Position = p
						if t >= 1 then
							conn:Disconnect()
							seed:Destroy()
						end
					end)
				end)
			end
		end
		if kind == "Slam" then
			play(Config.Sounds.Brew, 0.35, 0.9)
		end
	end)

do
	local shieldBubble: Part? = nil
	local enrageGlow: Highlight? = nil
	local function refreshBossLook()
		local phase = state:GetAttribute("Phase")
		local shield = state:GetAttribute("KingShield")
		if phase == "BloodMoon" and shield then
			if not shieldBubble then
				local b = Instance.new("Part")
				b.Shape = Enum.PartType.Ball
				b.Material = Enum.Material.ForceField
				b.Color = Color3.fromRGB(170, 90, 255)
				b.Anchored = true
				b.CanCollide = false
				b.CanQuery = false
				b.Size = Vector3.one * (kingFace.Size.X * 1.5)
				b.CFrame = CFrame.new(kingFace.Position)
				b.Parent = workspace
				shieldBubble = b
			end
		elseif shieldBubble then
			shieldBubble:Destroy()
			shieldBubble = nil
		end
		if phase == "BloodMoon" and (state:GetAttribute("KingPhase") or 1) >= 3 then
			if not enrageGlow then
				local h = Instance.new("Highlight")
				h.FillColor = Color3.fromRGB(255, 30, 30)
				h.FillTransparency = 0.55
				h.OutlineColor = Color3.fromRGB(255, 120, 60)
				h.Parent = kingFace
				enrageGlow = h
			end
		elseif enrageGlow then
			enrageGlow:Destroy()
			enrageGlow = nil
		end
	end
	for _, attr in { "Phase", "KingShield", "KingPhase" } do
		state:GetAttributeChangedSignal(attr):Connect(refreshBossLook)
	end
	refreshBossLook()
end

-- The Pumpkin King's look (client only): a glowing core, a gold neon crown that follows the
-- face, and an HP bar over his head. The server's bob and slam tweens move KingFace.
task.spawn(function()
	local GOLD = Color3.fromRGB(255, 200, 40)
	local glow = market:WaitForChild("KingGlow", 10) :: BasePart?
	local glowLight: PointLight? = nil
	if glow then
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 176, 0)
		l.Range = 30
		l.Brightness = 3
		l.Shadows = false
		l.Enabled = false
		l.Parent = glow
		glowLight = l
	end

	-- Crown: a neon band plus spikes made of wedge pairs, built around the local origin.
	local crownParts: { BasePart } = {}
	local crownOffsets: { CFrame } = {}
	local radius = math.max(2, kingFace.Size.X * 0.24)
	local function crownPart(p: BasePart, offset: CFrame, color: Color3)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = 1
		p.Parent = workspace
		table.insert(crownParts, p)
		table.insert(crownOffsets, offset)
	end
	local band = Instance.new("Part")
	band.Shape = Enum.PartType.Cylinder
	band.Size = Vector3.new(1.2, radius * 2, radius * 2)
	crownPart(band, CFrame.Angles(0, 0, math.rad(90)), GOLD)
	local spikes = 6
	local spikeH, spikeD, spikeT = radius * 0.9, radius * 0.45, 0.5
	for k = 1, spikes do
		local around = CFrame.Angles(0, k / spikes * math.pi * 2, 0)
			* CFrame.new(radius - 0.2, 0, 0)
		local up = 0.6 + spikeH / 2
		for side = 0, 1 do
			local w = Instance.new("WedgePart")
			w.Size = Vector3.new(spikeT, spikeH, spikeD)
			local turn = side == 0 and CFrame.new() or CFrame.Angles(0, math.pi, 0)
			local shift = side == 0 and -spikeD / 2 or spikeD / 2
			crownPart(w, around * CFrame.new(0, up, shift) * turn, GOLD)
		end
		local gem = Instance.new("Part")
		gem.Shape = Enum.PartType.Ball
		gem.Size = Vector3.one * 0.7
		crownPart(
			gem,
			around * CFrame.new(0.35, 0, 0),
			k % 2 == 0 and Color3.fromRGB(255, 60, 90) or Color3.fromRGB(120, 220, 255)
		)
	end

	-- HP bar over the King.
	local hpGui = Instance.new("BillboardGui")
	hpGui.Name = "KingHpBar"
	hpGui.Adornee = kingFace
	hpGui.Size = UDim2.new(16, 0, 2.2, 0)
	hpGui.StudsOffsetWorldSpace = Vector3.new(0, kingFace.Size.Y / 2 + radius + 4, 0)
	hpGui.LightInfluence = 0
	hpGui.MaxDistance = 300
	hpGui.Enabled = false
	hpGui.Parent = player:WaitForChild("PlayerGui")
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = DARK
	back.BorderSizePixel = 0
	back.Parent = hpGui
	corner(back)
	stroke(back, 3).Color = OUTLINE
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = back
	corner(fill)
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = KING_FILL
	fillGradient.Parent = fill
	local hpText = textLabel(back, "", Color3.fromRGB(255, 255, 255))
	hpText.Size = UDim2.fromScale(1, 0.8)
	hpText.Position = UDim2.fromScale(0, 0.1)
	hpText.ZIndex = 2
	local function refreshHpBar()
		local on = state:GetAttribute("Phase") == "BloodMoon"
			and state:GetAttribute("KingHp") ~= nil
		hpGui.Enabled = on
		if not on then
			return
		end
		local hp = state:GetAttribute("KingHp") or 0
		local maxHp = math.max(state:GetAttribute("KingMaxHp") or 1, 1)
		local shielded = state:GetAttribute("KingShield") ~= nil
		fillGradient.Color = shielded
				and ColorSequence.new(Color3.fromRGB(140, 80, 255), Color3.fromRGB(200, 150, 255))
			or KING_FILL
		hpText.Text = (shielded and "🛡 " or "👑 ") .. short(hp) .. " / " .. short(maxHp)
		TweenService:Create(
			fill,
			TweenInfo.new(0.2),
			{ Size = UDim2.fromScale(math.clamp(hp / maxHp, 0.02, 1), 1) }
		):Play()
	end
	for _, attr in { "Phase", "KingHp", "KingMaxHp", "KingShield" } do
		state:GetAttributeChangedSignal(attr):Connect(refreshHpBar)
	end
	refreshHpBar()

	local shown = false
	RunService.RenderStepped:Connect(function()
		local want = state:GetAttribute("Phase") == "BloodMoon" and kingFace.Transparency < 1
		if want ~= shown then
			shown = want
			for _, p in crownParts do
				p.Transparency = want and 0 or 1
			end
			if glow then
				glow.Transparency = want and 0.15 or 1
			end
			if glowLight then
				glowLight.Enabled = want
			end
		end
		if not want then
			return
		end
		local top = kingFace.CFrame * CFrame.new(0, kingFace.Size.Y / 2 - 0.6, 0)
		local frames = table.create(#crownParts)
		for i, offset in crownOffsets do
			frames[i] = top * offset
		end
		workspace:BulkMoveTo(crownParts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		if glow then
			glow.CFrame = CFrame.new(kingFace.Position)
		end
	end)
end)

do
	local topLabel = textLabel(gui, "", Color3.fromRGB(255, 220, 200))
	topLabel.AnchorPoint = Vector2.new(1, 0)
	topLabel.Position = UDim2.new(1, -16, 0, 150)
	-- Header + top 3 = 4 lines: scale to fit, capped at the old 22 px.
	topLabel.Size = UDim2.fromOffset(260, 110)
	topLabel.TextXAlignment = Enum.TextXAlignment.Right
	topLabel.TextYAlignment = Enum.TextYAlignment.Top
	topLabel.TextScaled = true
	topLabel.TextWrapped = true
	local topSize = Instance.new("UITextSizeConstraint")
	topSize.MaxTextSize = 22
	topSize.Parent = topLabel
	local function refreshTop()
		local top = state:GetAttribute("KingTop")
		if state:GetAttribute("Phase") == "BloodMoon" and top and top ~= "" then
			topLabel.Text = "TOP BONKERS\n" .. top
			topLabel.Visible = true
		else
			topLabel.Visible = false
		end
	end
	state:GetAttributeChangedSignal("KingTop"):Connect(refreshTop)
	state:GetAttributeChangedSignal("Phase"):Connect(refreshTop)
	refreshTop()
end

do
	local crowns: { [Player]: BillboardGui } = {}
	local function refreshCrown(who: Player)
		local head = who.Character and who.Character:FindFirstChild("Head")
		local want = who:GetAttribute("MVP") == true and head ~= nil
		if want and not crowns[who] then
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(120, 50)
			bb.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)
			bb.LightInfluence = 0
			bb.Parent = head
			textLabel(bb, "👑 MVP", Color3.fromRGB(255, 214, 80)).Size = UDim2.fromScale(1, 1)
			crowns[who] = bb
		elseif not want and crowns[who] then
			crowns[who]:Destroy()
			crowns[who] = nil
		end
	end
	local function watchPlayer(who: Player)
		who:GetAttributeChangedSignal("MVP"):Connect(function()
			refreshCrown(who)
		end)
		who.CharacterAdded:Connect(function()
			crowns[who] = nil
			task.wait(1)
			refreshCrown(who)
		end)
		refreshCrown(who)
	end
	for _, who in Players:GetPlayers() do
		watchPlayer(who)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(function(who)
		local bb = crowns[who]
		crowns[who] = nil
		if bb then
			bb:Destroy()
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		toolPanel.Visible = false
		upgradePanel.Visible = false
		indexPanel.Visible = false
		hauntPanel.Visible = false
		shopPanel.Visible = false
	end
end)
