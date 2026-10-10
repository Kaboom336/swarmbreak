-- Client side of Steal a Pumpkin: which base prompts you see (Place / Pick up / Steal / Lock),
-- lighting for day / midnight / Blood Moon, scythe swings, hit and pop effects, HUD (candy,
-- income, carry), the Shop (Scythes / Upgrades / Robux tabs), Index, Haunt, Witch's Orders.
-- Systems behind an unlock gate (Config.Unlocks, "Unlock_<Name>" attributes) stay hidden.
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

-- Short numbers: 950, 1.2k, 34.5k, 340k, 3.4M, 1.2B (rounded down so 999.96k never shows 1000k).
local function short(n: number): string
	for _, unit in { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "k" } } do
		if n >= unit[1] then
			local v = n / unit[1]
			local text = v >= 100 and tostring(math.floor(v))
				or (string.gsub(string.format("%.1f", math.floor(v * 10) / 10), "%.0$", ""))
			return text .. unit[2]
		end
	end
	return tostring(math.floor(n))
end

-- Candy per second: one decimal below 10 ("0.5", "4.2"), short above.
local function rateShort(n: number): string
	if n < 10 then
		return (string.gsub(string.format("%.1f", n), "%.0$", ""))
	end
	return short(n)
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

-- Damage numbers (Pet Sim 99 style): short format ("1.2k", "3.4M"), heavy white text with a
-- thick black stroke, 34 px growing to 56 px for big hits. 1.1 s in all: pops in (0.12 s),
-- holds (0.5 s), then rises 46 px and fades. The anchor is pulled a few studs toward the camera so
-- the pumpkin itself never hides the number, and the billboard is AlwaysOnTop.
-- The billboard lives in PlayerGui with an explicit Adornee (an Attachment in Terrain), which
-- always renders; a billboard parented straight under an Attachment did not show on screen.
local function damageText(at: Vector3, damage: number, color: Color3?)
	local px = math.floor(math.clamp(34 + 5.5 * math.log10(math.max(damage, 1)), 34, 56))
	local camera = workspace.CurrentCamera
	local toCamera = camera and (camera.CFrame.Position - at) or Vector3.zero
	if toCamera.Magnitude > 4 then
		at += toCamera.Unit * 3
	end
	local holder = Instance.new("Attachment")
	holder.WorldPosition = at
	holder.Parent = workspace.Terrain
	local bb = Instance.new("BillboardGui")
	bb.Name = "DamageNumber"
	bb.Adornee = holder
	bb.Size = UDim2.fromOffset(px * 5, px + 60)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 200
	bb.ResetOnSpawn = false
	bb.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.fromScale(0, 1)
	label.Size = UDim2.new(1, 0, 0, px)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = short(damage)
	label.TextColor3 = color
		or (
			damage >= 1e4 and Color3.fromRGB(255, 130, 50)
			or damage >= 1e3 and Color3.fromRGB(255, 220, 70)
			or Color3.new(1, 1, 1)
		)
	label.Parent = bb
	local outline = Instance.new("UIStroke")
	outline.Thickness = math.max(3, px / 10)
	outline.Color = Color3.new(0, 0, 0)
	outline.Parent = label
	local pop = Instance.new("UIScale")
	pop.Scale = 1.6
	pop.Parent = label
	TweenService:Create(pop, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- Hold until 0.62 s, then rise and fade over the last 0.48 s.
	local rise =
		TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.62)
	TweenService:Create(label, rise, { Position = UDim2.new(0, 0, 1, -46) }):Play()
	local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.7)
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(outline, fade, { Transparency = 1 }):Play()
	task.delay(1.12, function()
		bb:Destroy()
		holder:Destroy()
	end)
end

-- A big white "+1 🎃" over your own head whenever your carried stack grows (any pickup:
-- smash, loose pumpkin, your plot, a steal). Pops in, holds, rises and fades in 1.2 s.
local function pickupPop(amount: number)
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "PickupPop"
	bb.Adornee = head
	bb.Size = UDim2.fromOffset(220, 72)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 200
	bb.ResetOnSpawn = false
	bb.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "+" .. amount .. " 🎃"
	label.Parent = bb
	local outline = Instance.new("UIStroke")
	outline.Thickness = 4
	outline.Color = Color3.fromRGB(20, 10, 30)
	outline.Parent = label
	local pop = Instance.new("UIScale")
	pop.Scale = 0.3
	pop.Parent = label
	TweenService:Create(pop, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local rise = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.7)
	TweenService:Create(bb, rise, { StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0) }):Play()
	local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.8)
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(outline, fade, { Transparency = 1 }):Play()
	task.delay(1.22, function()
		bb:Destroy()
	end)
end
do
	local lastCarry = player:GetAttribute("Carry") or 0
	player:GetAttributeChangedSignal("Carry"):Connect(function()
		local n = player:GetAttribute("Carry") or 0
		if n > lastCarry and player:GetAttribute("Loaded") then
			pickupPop(n - lastCarry)
		end
		lastCarry = n
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

-- Unlock gates (Config.Unlocks): the server sets sticky "Unlock_<Name>" attributes (PlayerSteal,
-- Sell, Brew, LuckySwing, King, Haunt); systems stay hidden until then.
local function unlocked(name: string, who: Player?): boolean
	return (who or player):GetAttribute("Unlock_" .. name) == true
end

-- Spooky Hour (server state "SpookyEnds"): x Config.SpookyMult base income, tint and bats.
local function spookyOn(): boolean
	return (state:GetAttribute("SpookyEnds") or 0) > workspace:GetServerTimeNow()
end

-- Defined further down, used above their definitions: confetti (Daily panel block, optional
-- ScreenGui to draw in) and queueReveal (the reveal card queue: seedId, mutation, isNew, rate,
-- kind, pet).
local confetti: (ScreenGui?) -> ()
local queueReveal: (string, string?, boolean, number, string?, string?, number?) -> ()
local Center = { busy = false, urgent = false, frames = {}, nextTicket = 0, serving = 1 }
function Center.acquire()
	Center.nextTicket += 1
	local ticket = Center.nextTicket
	while ticket ~= Center.serving or Center.busy or Center.urgent do
		task.wait(0.05)
	end
	Center.busy = true
end
function Center.release()
	Center.busy = false
	Center.serving += 1
	table.clear(Center.frames)
end
function Center.register(frame)
	table.insert(Center.frames, frame)
	frame.Visible = not Center.urgent
end
function Center.interrupt(on: boolean)
	Center.urgent = on
	for _, frame in Center.frames do
		if frame.Parent then
			frame.Visible = not on
		end
	end
end

-- Screen -----------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "PatchHud"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
-- Above the panel dim (PatchDim, order 0), so the HUD stays bright while a panel is open.
gui.DisplayOrder = 1
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
	uiScale.Scale = math.clamp(size.Y / 720, Config.UI.scaleMin, Config.UI.scaleMax)
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
-- Halloween skin (refs aspects/halloween 2.5, ui HOWTO 2): charcoal panels with an orange rim, a
-- lime gradient on buy buttons, purple close / back buttons. HUD numbers: money green, speed yellow.
local CHARCOAL = Config.UI.body
local ORANGE = Color3.fromRGB(242, 140, 26)
local BUY = Color3.fromRGB(141, 248, 22)
local BUY_LOW = Color3.fromRGB(107, 241, 3)
local PURPLE = Color3.fromRGB(122, 82, 191)
local MONEY = Color3.fromRGB(68, 255, 47)
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
	s.Thickness = 3
	s.Color = Config.UI.ink
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		s.Thickness = label.AbsoluteSize.Y < 25 and 2 or 3
	end)
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
	local shade = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 225, 225)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 165, 165)),
	})
	gradient.Color = shade
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
	-- A BUY-coloured button gets the lime gradient #8DF816 -> #6BF103 (the face turns white so
	-- the gradient shows true); every other colour keeps the white-to-grey shading.
	local function sync()
		local c = b.BackgroundColor3
		if c == BUY then
			face.BackgroundColor3 = Color3.new(1, 1, 1)
			gradient.Color = ColorSequence.new(BUY, BUY_LOW)
		else
			face.BackgroundColor3 = c
			gradient.Color = shade
		end
		base.BackgroundColor3 = c:Lerp(Color3.new(0, 0, 0), 0.45)
	end
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(sync)
	sync()
	-- Squash (ui HOWTO 3): hover 1.08, press 0.9, release springs back with Back easing.
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
		to(1.08, 0.12)
	end)
	b.MouseLeave:Connect(function()
		hovered = false
		to(1, 0.12)
	end)
	b.MouseButton1Down:Connect(function()
		to(0.9, 0.06)
	end)
	b.MouseButton1Up:Connect(function()
		to(hovered and 1.08 or 1, 0.18)
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
local showBanner -- forward
local function banner(text: string, sub: string?, seconds: number, color: Color3?)
	task.spawn(function()
		Center.acquire()
		local ok, err = pcall(showBanner, text, sub, seconds, color)
		Center.release()
		if not ok then
			warn("[Patch] Banner:", err)
		end
	end)
end
function showBanner(text: string, sub: string?, seconds: number, color: Color3?)
	local title = textLabel(gui, text, color or Color3.fromRGB(255, 214, 80))
	Center.register(title)
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
		Center.register(subLabel)
		subLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		subLabel.Position = UDim2.fromScale(0.5, 0.39)
		subLabel.Size = UDim2.fromScale(0.55, 0.05)
	end
	do
		local remaining = seconds
		while remaining > 0 do
			local dt = task.wait(0.05)
			if not Center.urgent then
				remaining -= dt
			end
		end
		title:Destroy()
		if subLabel then
			subLabel:Destroy()
		end
	end
end

-- Toasts (Steal an Egg style): small white stroked lines stacked at the bottom centre, newest at
-- the bottom, at most 3, each gone after 3.5 s. Rich text, so a key word can be coloured.
local hint
do
	local holder = Instance.new("Frame")
	holder.Name = "Toasts"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.fromScale(0.5, Config.UI.toastY)
	holder.Size = UDim2.fromScale(0.44, 0.12)
	holder.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 2)
	layout.Parent = holder
	local count = 0
	function hint(text: string)
		count += 1
		local label = textLabel(holder, text, Color3.fromRGB(255, 255, 255))
		label.RichText = true
		label.LayoutOrder = count
		label.Size = UDim2.fromScale(1, 0.28)
		local outline = label:FindFirstChildOfClass("UIStroke") :: UIStroke
		outline.Thickness = 2.5
		local pop = Instance.new("UIScale")
		pop.Scale = 0.6
		pop.Parent = label
		TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		local labels = {}
		for _, child in holder:GetChildren() do
			if child:IsA("TextLabel") then
				table.insert(labels, child)
			end
		end
		table.sort(labels, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #labels - 3 do
			labels[i]:Destroy()
		end
		task.delay(3.2, function()
			if label.Parent then
				local fade = TweenInfo.new(0.3)
				TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
				TweenService:Create(outline, fade, { Transparency = 1 }):Play()
				task.delay(0.3, function()
					label:Destroy()
				end)
			end
		end)
	end
end
remotes:WaitForChild("Hint").OnClientEvent:Connect(hint)

-- Event news that used to be big banners: one small toast line ("TITLE · sub").
local function toast(title: string, sub: string?)
	hint(title .. (sub and sub ~= "" and (" · " .. sub) or ""))
end

-- Bottom right (Steal an Egg): the moon timer to midnight ("🌙 in 1:54", red in its last 10 s; a
-- sun "☀ in 0:32" while the midnight raid runs) and over it the Spooky Hour line ("🦇 Spooky Hour in
-- 6:12", orange "🦇 SPOOKY HOUR! x2 1:12" while it runs). Players past the King gate also see the
-- Blood Moon / King state in the moon line, with a thin bar. On touch screens (jump button
-- bottom right) the stack sits top right instead. The world MeterRing around the Giant Jack
-- still fills. The top centre belongs to the objective banner; the centre stays clear.
local KING_FILL = ColorSequence.new(Color3.fromRGB(200, 25, 45), Color3.fromRGB(255, 120, 60))
do
	local chip = Instance.new("Frame")
	chip.Name = "PhaseChip"
	chip.BackgroundTransparency = 1
	chip.Size = UDim2.fromScale(0.24, 0.075)
	chip.Parent = gui
	local function place()
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		chip.AnchorPoint = touch and Vector2.new(1, 0) or Vector2.new(1, 1)
		chip.Position = touch and UDim2.fromScale(0.988, 0.012) or UDim2.fromScale(0.988, 0.975)
	end
	place()
	UserInputService.LastInputTypeChanged:Connect(place)
	local spookyLine = textLabel(chip, "", Color3.fromRGB(255, 190, 120))
	spookyLine.Name = "Spooky"
	spookyLine.Size = UDim2.fromScale(1, 0.028 / 0.075)
	spookyLine.TextXAlignment = Enum.TextXAlignment.Right
	local label = textLabel(chip, "", Color3.fromRGB(255, 255, 255))
	label.Name = "Moon"
	label.Position = UDim2.fromScale(0, 0.035 / 0.075)
	label.Size = UDim2.fromScale(1, 0.04 / 0.075)
	label.TextXAlignment = Enum.TextXAlignment.Right
	local labelStroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke
	labelStroke.Thickness = 3
	local tray = Instance.new("Frame")
	tray.Name = "BoostTray"
	tray.BackgroundTransparency = 1
	tray.AnchorPoint = Vector2.new(1, 0)
	tray.Position = UDim2.fromScale(-0.05, 0.15)
	tray.Size = UDim2.fromScale(0.65, 0.045 / 0.075)
	tray.Parent = chip
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0.05, 0)
	layout.Parent = tray
	local boosts = {}
	for _, info in Config.UI.boosts do
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = Config.UI.icons[info.icon]
		image.Size = UDim2.fromScale(0.28, 1)
		image.Parent = tray
		local boostLabel = textLabel(image, info.label, Color3.new(1, 1, 1))
		boostLabel.Size = UDim2.fromScale(1, 0.4)
		boostLabel.Position = UDim2.fromScale(0, 0.65)
		boosts[image] = info
	end
	local spookyScale = Instance.new("UIScale")
	spookyScale.Parent = spookyLine
	-- One toast 5 s before midnight (once per day phase).
	local warnedFor = 0
	local function refreshChip()
		for image, info in boosts do
			local value = player:GetAttribute(info.attribute)
			image.Visible = info.timed
					and type(value) == "number"
					and value > workspace:GetServerTimeNow()
				or (not info.timed and value == true)
		end
		local now = workspace:GetServerTimeNow()
		local phase = state:GetAttribute("Phase") or "Day"
		local ends = state:GetAttribute("PhaseEnds") or 0
		local left = math.max(0, ends - now)
		label.Text = (phase ~= "Day" and utf8.char(9728) .. " in " or utf8.char(9790) .. " in ")
			.. clockText(left)
		label.TextColor3 = left <= 10 and Color3.fromRGB(255, 59, 59) or Color3.new(1, 1, 1)
		if phase == "Day" and left <= 5 and left > 0 and warnedFor ~= ends then
			warnedFor = ends
			toast("Midnight in 5s...", "ALL PUMPKINS RESET!")
		end
		-- Spooky Hour line.
		local spookyEnds = state:GetAttribute("SpookyEnds")
		local spookyText
		if spookyOn() and type(spookyEnds) == "number" then
			spookyText = string.format(
				"🦇 SPOOKY HOUR! x%d %s",
				Config.SpookyMult or 2,
				clockText(spookyEnds - now)
			)
			spookyLine.TextColor3 = Color3.fromRGB(255, 150, 40)
			spookyScale.Scale = 1 + 0.06 * math.abs(math.sin(os.clock() * 4))
		else
			local nextAt = state:GetAttribute("SpookyNext")
			spookyText = type(nextAt) == "number"
					and ("🦇 Spooky Hour in " .. clockText(nextAt - now))
				or ""
			spookyLine.TextColor3 = Color3.fromRGB(197, 155, 255)
			spookyScale.Scale = 1
		end
		if spookyLine.Text ~= spookyText then
			spookyLine.Text = spookyText
		end
		meterRing.Transparency = 1
	end
	task.spawn(function()
		while chip.Parent do
			refreshChip()
			task.wait(0.25)
		end
	end)
end

-- Bottom left (Steal an Egg): the speed / carry line in yellow #F8FF43 ("👟 24  🎃 1/3 Carrying"),
-- under it the candy icon and the money in green #44FF2F with a dark stroke and the income
-- "+X/s" after it. Money rolls up to a new value in 0.6 s (a NumberValue tween) while the icon
-- pops 1.25x. Spooky Hour shows the doubled income with "x2".
local candyValue = player:WaitForChild("leaderstats"):WaitForChild("Candy") :: IntValue
local candyBig: TextLabel, incomeLabel: TextLabel, carryLabel: TextLabel
local statsFrame = Instance.new("Frame")
local refreshCandy: (boolean) -> ()
local refreshIncome: () -> ()
do
	local stats = statsFrame
	stats.Name = "Stats"
	stats.BackgroundTransparency = 1
	stats.AnchorPoint = Vector2.new(0, 1)
	stats.Position = UDim2.fromScale(0.012, 0.975)
	stats.Size = UDim2.fromScale(0.26, 0.09)
	stats.Parent = gui
	carryLabel = textLabel(stats, "", Color3.new(1, 1, 1))
	carryLabel.Name = "Carry"
	carryLabel.Position = UDim2.fromScale(0, 0)
	carryLabel.Size = UDim2.fromScale(1, 0.028 / 0.09)
	carryLabel.TextXAlignment = Enum.TextXAlignment.Left
	local icon = Instance.new("TextLabel")
	icon.Name = "CandyIcon"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromScale(0, 0.035 / 0.09)
	icon.Size = UDim2.fromScale(0.14, 0.055 / 0.09)
	icon.TextScaled = true
	icon.Text = "🍬"
	icon.Parent = stats
	local iconScale = Instance.new("UIScale")
	iconScale.Parent = icon
	-- The money number: 36 px, green with a thick dark stroke.
	candyBig = textLabel(stats, "", MONEY)
	candyBig.Name = "Money"
	candyBig.Position = UDim2.fromScale(0.16, 0.035 / 0.09)
	candyBig.Size = UDim2.fromScale(0.65, 0.055 / 0.09)
	candyBig.TextScaled = true
	candyBig.FontFace = Font.new(
		"rbxasset://fonts/families/FredokaOne.json",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Italic
	)
	candyBig.TextSize = 36
	candyBig.TextXAlignment = Enum.TextXAlignment.Left
	local moneyStroke = candyBig:FindFirstChildOfClass("UIStroke") :: UIStroke
	moneyStroke.Thickness = 3
	moneyStroke.Color = Color3.fromRGB(11, 42, 6)
	incomeLabel = textLabel(stats, "", MONEY)
	incomeLabel.Name = "Income"
	incomeLabel.Size = UDim2.fromScale(0.35, 0.30)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	local function placeIncome()
		incomeLabel.Position = UDim2.fromScale(0.80, 0.58)
	end
	candyBig:GetPropertyChangedSignal("TextBounds"):Connect(placeIncome)
	placeIncome()

	local shown = Instance.new("NumberValue")
	shown.Value = candyValue.Value
	shown.Changed:Connect(function(v: number)
		candyBig.Text = short(math.max(0, math.floor(v + 0.5)))
	end)
	candyBig.Text = short(candyValue.Value)
	local roll: Tween? = nil

	function refreshIncome()
		local income = player:GetAttribute("Income") or 0
		local mult = spookyOn() and (Config.SpookyMult or 2) or 1
		local text = income > 0
				and ("+" .. rateShort(income * mult) .. "/s" .. (mult > 1 and (" x" .. mult) or ""))
			or ""
		if incomeLabel.Text ~= text then
			incomeLabel.Text = text
		end
	end

	-- pop = a gain: roll up to the new balance and pop the icon; otherwise jump there.
	function refreshCandy(pop: boolean)
		refreshIncome()
		if roll then
			roll:Cancel()
			roll = nil
		end
		if not pop then
			shown.Value = candyValue.Value
			return
		end
		roll = TweenService:Create(
			shown,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = candyValue.Value }
		)
		roll:Play()
		local up = TweenService:Create(
			iconScale,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = 1.25 }
		)
		up:Play()
		up.Completed:Once(function()
			TweenService:Create(
				iconScale,
				TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end)
	end
	player:GetAttributeChangedSignal("Income"):Connect(refreshIncome)
	state:GetAttributeChangedSignal("SpookyEnds"):Connect(refreshIncome)
end
-- Sell juice: candies fly from the screen center into the candy counter, which punches (the
-- icon 1.25x, the number 1.1x). They live in their own unscaled ScreenGui so screen pixels line up
-- with AbsolutePosition.
local candyShower, candyTick
do
	local punchScale = Instance.new("UIScale")
	punchScale.Parent = candyBig
	local icon = statsFrame:FindFirstChild("CandyIcon") :: TextLabel
	local iconPunch = icon:FindFirstChildOfClass("UIScale") :: UIScale
	local fxGui = Instance.new("ScreenGui")
	fxGui.Name = "PatchFx"
	fxGui.ResetOnSpawn = false
	fxGui.IgnoreGuiInset = true
	fxGui.DisplayOrder = 5
	fxGui.Parent = player:WaitForChild("PlayerGui")
	local function punch()
		for target, size in { [punchScale] = 1.1, [iconPunch] = 1.25 } do
			local up = TweenService:Create(
				target,
				TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Scale = size }
			)
			up:Play()
			up.Completed:Once(function()
				TweenService:Create(
					target,
					TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }
				):Play()
			end)
		end
	end
	-- The counter punches and a green "+N" pops over the end of the number, rises and fades.
	function candyTick(amount: number)
		punch()
		if amount <= 0 then
			return
		end
		local plus = textLabel(statsFrame, "+" .. short(amount), MONEY)
		-- Big enough to read at a glance: 30 px tall, a thick dark stroke, drawn over the HUD,
		-- held for ~0.8 s before it fades.
		plus.Name = "CandyTick"
		plus.TextXAlignment = Enum.TextXAlignment.Left
		plus.Position = UDim2.fromScale(1.02, 0.4)
		plus.Size = UDim2.fromScale(0.45, 0.45)
		plus.ZIndex = 8
		local s = plus:FindFirstChildOfClass("UIStroke") :: UIStroke
		s.Thickness = 3
		s.Color = Color3.fromRGB(10, 40, 10)
		local scale = Instance.new("UIScale")
		scale.Scale = 0.4
		scale.Parent = plus
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		local rise = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(plus, rise, { Position = plus.Position + UDim2.fromOffset(24, 0) })
			:Play()
		local fade =
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.85)
		TweenService:Create(plus, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(s, fade, { Transparency = 1 }):Play()
		task.delay(1.3, function()
			plus:Destroy()
		end)
	end
	function candyShower(count: number)
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local view = camera.ViewportSize
		local target = icon.AbsolutePosition + icon.AbsoluteSize / 2
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

-- The yellow line: walk speed and the carried stack (plus its worth while carrying).
local function refreshCarry()
	local n = player:GetAttribute("Carry") or 0
	local cap = Config.BaseCarry
		+ (player:GetAttribute("Up_Stack") or 0)
		+ (player:GetAttribute("Pass_BigStack") and Config.BigStackCarry or 0)
	local text = string.format(
		"%s Scythe   Carry %d/%d",
		player:GetAttribute("Tool") or Config.StartTool,
		n,
		cap
	)
	if carryLabel.Text ~= text then
		carryLabel.Text = text
	end
end
-- Every gain rolls the counter up and pops a "+N" (not the balance loaded on join).
local lastCandy = candyValue.Value
candyValue.Changed:Connect(function()
	local gain = candyValue.Value - lastCandy
	lastCandy = candyValue.Value
	local loaded = player:GetAttribute("Loaded") == true
	refreshCandy(gain > 0 and loaded)
	if gain > 0 and loaded then
		candyTick(gain)
	end
end)
for _, attr in { "Carry", "CarryValue", "Up_Stack", "Pass_BigStack" } do
	player:GetAttributeChangedSignal(attr):Connect(refreshCarry)
end
refreshCandy(false)
refreshCarry()

-- Left edge: exactly two pill buttons, Shop and Index (Steal an Egg x 1-10.5 %, y 40-54 %; Hit
-- Game Bible: 2 HUD buttons). Haunt lives in the Shop as a tab; the base lock is the prompt on
-- your base's sign post.
local leftBar = Instance.new("Frame")
leftBar.Name = "LeftPills"
leftBar.BackgroundTransparency = 1
leftBar.AnchorPoint = Vector2.zero
leftBar.Position = UDim2.fromScale(0.012, 0.42)
leftBar.Size = UDim2.fromScale(0.085, 0.225)
leftBar.Parent = gui
do
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.015 / 0.225, 0)
	layout.Parent = leftBar
end
local function pill(text: string, color: Color3, order: number): TextButton
	local b = button(leftBar, text, color)
	b.Size = UDim2.fromScale(1, 0.065 / 0.225)
	if order > 0 then
		local name = order == 1 and "Shop"
			or order == 2 and "Index"
			or order == 3 and "Teleport"
			or "Daily"
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Image = Config.UI.icons[name]
		icon.Position = UDim2.fromScale(0.04, 0.15)
		icon.ZIndex = 5
		icon.Parent = b
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.Parent = b
		local function mobile()
			local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
			b.Text = touch and "" or name
			icon.Size = UDim2.fromScale(touch and 0.8 or 0.32, 0.7)
			aspect.AspectRatio = 1
			aspect.Parent = touch and b or nil
			local label = b:FindFirstChild("Label")
			if label then
				label.Position = UDim2.fromScale(0.35, 0)
				label.Size = UDim2.fromScale(0.63, 1)
			end
		end
		mobile()
		UserInputService.LastInputTypeChanged:Connect(mobile)
	end
	b.LayoutOrder = order
	for _, d in b:GetDescendants() do
		if d:IsA("UICorner") then
			d.CornerRadius = UDim.new(1, 0)
		elseif d:IsA("UIStroke") and d.Parent and d.Parent:IsA("Frame") then
			d.Color = Color3.new(0, 0, 0)
			d.Thickness = 2.5
		elseif d:IsA("UIPadding") then
			d.PaddingTop = UDim.new(0, 9)
			d.PaddingBottom = UDim.new(0, 9)
			d.PaddingLeft = UDim.new(0, 10)
			d.PaddingRight = UDim.new(0, 10)
		end
	end
	return b
end

local function seedColor(seed): Color3
	if seed.color then
		return seed.color
	end
	return seed.template == "pumpkin_yellow" and Color3.fromRGB(255, 210, 70)
		or Color3.fromRGB(255, 130, 40)
end

-- Panels (Halloween skin over the Pet Sim 99 layout): a dark charcoal #2A2A2E rounded box with
-- an orange #F28C1A rim and a cobweb in its top-left corner, a FredokaOne title with a pumpkin
-- and a dark stroke tilted -4 degrees over the top-left edge, a purple X over the top-right
-- corner, a 0 -> 1 pop-in (0.3 s Back Out), and a dim over the world (its own ScreenGui under
-- the HUD) while any panel is open. A click on the
-- dim closes the open panel. grid = the items sit in a 3-column grid of cards (gridCard).
local CARD_GREY = Color3.fromRGB(236, 238, 244)
local panelFrames: { Frame } = {}
local panelDim: TextButton
do
	local dimGui = Instance.new("ScreenGui")
	dimGui.Name = "PatchDim"
	dimGui.ResetOnSpawn = false
	dimGui.IgnoreGuiInset = true
	dimGui.DisplayOrder = 0
	dimGui.Parent = player:WaitForChild("PlayerGui")
	panelDim = Instance.new("TextButton")
	panelDim.Name = "Dim"
	panelDim.Text = ""
	panelDim.AutoButtonColor = false
	panelDim.BackgroundColor3 = Color3.new(0, 0, 0)
	panelDim.BackgroundTransparency = 1
	panelDim.BorderSizePixel = 0
	panelDim.Size = UDim2.fromScale(1, 1)
	panelDim.Visible = false
	panelDim.Parent = dimGui
	panelDim.Activated:Connect(function()
		for _, f in panelFrames do
			f.Visible = false
		end
	end)
end
local function anyPanelOpen(): boolean
	for _, f in panelFrames do
		if f.Visible then
			return true
		end
	end
	return false
end
local function refreshDim()
	leftBar.Visible = not anyPanelOpen()
	statsFrame.Visible = not anyPanelOpen()
	if anyPanelOpen() then
		panelDim.Visible = true
		TweenService:Create(panelDim, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
	elseif panelDim.Visible then
		local fade =
			TweenService:Create(panelDim, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Once(function()
			panelDim.Visible = anyPanelOpen()
		end)
	end
end

-- Close control stays inside the gradient header.
local function closeButton(frame: GuiObject): TextButton
	local close = button(frame, "X", Color3.fromRGB(219, 39, 48))
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(0.985, 0.01)
	close.Size = UDim2.fromScale(0.08, 0.10)
	close.ZIndex = 14
	for _, d in close:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += 13
		elseif d:IsA("UICorner") then
			d.CornerRadius = UDim.new(0, 10)
		end
	end
	return close
end

local function panel(title: string, grid: boolean?): (Frame, ScrollingFrame)
	local frame = Instance.new("Frame")
	frame:SetAttribute("PanelTitle", title)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.54)
	frame.Size = UDim2.fromScale(Config.UI.panelSize.X, Config.UI.panelSize.Y)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = Config.UI.panelAspect
	aspect.Parent = frame
	frame.BackgroundColor3 = CHARCOAL
	frame.Visible = false
	frame.ZIndex = 10
	frame.Parent = gui
	corner(frame, 16)
	stroke(frame, 3).Color = ORANGE
	local kind = string.find(title, "Index") and "Index"
		or (string.find(title, "Haunt") or string.find(title, "Rebirth")) and "Haunt"
		or string.find(title, "Admin") and "Admin"
		or string.find(title, "Daily") and "Daily"
		or "Shop"
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.fromScale(1, 0.12)
	header.BackgroundColor3 = Color3.new(1, 1, 1)
	header.ZIndex = 11
	header.Parent = frame
	corner(header, 12)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Config.UI.headers[kind][1], Config.UI.headers[kind][2])
	gradient.Parent = header
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = Config.UI.icons[kind] or Config.UI.icons.Shop
	icon.Position = UDim2.fromScale(0.02, 0.1)
	icon.Size = UDim2.fromScale(0.07, 0.8)
	icon.ZIndex = 14
	icon.Parent = header
	local head = textLabel(header, string.gsub(title, "^[^%a]+", ""), Color3.new(1, 1, 1))
	head.Position = UDim2.fromScale(0.11, 0.1)
	head.Size = UDim2.fromScale(0.75, 0.8)
	head.ZIndex = 14
	head.TextXAlignment = Enum.TextXAlignment.Left
	closeButton(frame).Activated:Connect(function()
		frame.Visible = false
	end)
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromScale(0.025, 0.15)
	list.Size = UDim2.fromScale(0.95, 0.82)
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = Color3.fromRGB(170, 170, 190)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = frame
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = list
	if grid then
		local layout = Instance.new("UIGridLayout")
		layout.CellSize = UDim2.new(1 / 3, -10, 0, 226)
		layout.CellPadding = UDim2.fromOffset(12, 12)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
	else
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
	end
	-- Pops 0 -> 1 in 0.3 s (Back Out) each time it opens.
	local pop = Instance.new("UIScale")
	pop.Parent = frame
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			pop.Scale = 0
			TweenService:Create(
				pop,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
		refreshDim()
	end)
	table.insert(panelFrames, frame)
	return frame, list
end

-- IsAdmin is replicated by the server; every invocation is independently authorized there.
do
	local frame, list = panel("Admin")
	local gear = Instance.new("ImageButton")
	gear.Name = "AdminGear"
	gear.Image = Config.UI.icons.Admin
	gear.BackgroundColor3 = Color3.fromRGB(138, 138, 138)
	gear.Position = UDim2.fromScale(0.012, 0.02)
	gear.Size = UDim2.fromScale(0.045, 0.07)
	gear.Parent = gui
	corner(gear, 12)
	local function refresh()
		gear.Visible = player:GetAttribute("IsAdmin") == true
		if not gear.Visible then
			frame.Visible = false
		end
	end
	gear.Activated:Connect(function()
		local was = frame.Visible
		for _, f in panelFrames do
			f.Visible = false
		end
		frame.Visible = not was
	end)
	local amount = Instance.new("TextBox")
	amount.Text = tostring(Config.Admin.candy)
	amount.PlaceholderText = "Candy amount"
	amount.Font = Enum.Font.FredokaOne
	amount.TextScaled = true
	amount.Size = UDim2.new(1, 0, 0, 40)
	amount.LayoutOrder = 2
	amount.Parent = list
	local confirming, busy = 0, false
	for i, entry in
		{
			{ "Reset my progress", "reset" },
			{ "Give candy", "candy" },
			{ "Unlock all zones", "zone" },
			{ "Start King Night", "king" },
			{ "Start Spooky Hour", "spooky" },
		}
	do
		local b = button(list, entry[1], i == 1 and Color3.fromRGB(219, 39, 48) or PURPLE)
		b.Size = UDim2.new(1, 0, 0, 48)
		b.LayoutOrder = i == 1 and 1 or i + 1
		if i == 1 then
			frame:GetPropertyChangedSignal("Visible"):Connect(function()
				if not frame.Visible then
					b.Text = entry[1]
				end
			end)
		end
		b.Activated:Connect(function()
			if busy then
				return
			end
			if entry[2] == "reset" and os.clock() >= confirming then
				confirming = os.clock() + Config.Admin.confirmSeconds
				b.Text = "Sure? Click again"
				task.delay(Config.Admin.confirmSeconds, function()
					if os.clock() >= confirming then
						b.Text = entry[1]
					end
				end)
				return
			end
			confirming = 0
			b.Text = entry[1]
			busy = true
			local ok, done, message = pcall(function()
				return remotes
					:WaitForChild("Admin")
					:InvokeServer(entry[2], entry[2] == "candy" and tonumber(amount.Text) or nil)
			end)
			busy = false
			hint(
				ok and (message or (done and "Admin action complete" or "Admin action rejected"))
					or "Admin request failed"
			)
		end)
	end
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not frame.Visible then
			confirming = 0
		end
	end)
	player:GetAttributeChangedSignal("IsAdmin"):Connect(refresh)
	refresh()
end

-- A full-width row card (Haunt panel): light grey with a coloured icon, name and a dark line.
local function card(
	list: Instance,
	order: number,
	color: Color3,
	title: string,
	text: string
): (Frame, TextLabel)
	local c = Instance.new("Frame")
	c.Size = UDim2.new(1, -4, 0, 78)
	c.LayoutOrder = order
	c.BackgroundColor3 = CARD_GREY
	c.Parent = list
	corner(c, 14)
	stroke(c, 2.5).Color = OUTLINE
	local dot = Instance.new("Frame")
	dot.Position = UDim2.fromOffset(12, 14)
	dot.Size = UDim2.fromOffset(50, 50)
	dot.BackgroundColor3 = color
	dot.Parent = c
	corner(dot)
	stroke(dot, 2.5).Color = OUTLINE
	local name = textLabel(c, title, Color3.fromRGB(255, 255, 255))
	name.Position = UDim2.fromOffset(74, 6)
	name.Size = UDim2.new(1, -330, 0, 32)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local info = textLabel(c, text, Color3.fromRGB(80, 70, 100), Enum.Font.FredokaOne)
	info:FindFirstChildOfClass("UIStroke"):Destroy()
	info.Position = UDim2.fromOffset(74, 42)
	info.Size = UDim2.new(1, -330, 0, 22)
	info.TextXAlignment = Enum.TextXAlignment.Left
	return c, info
end

-- Grid item card (Pet Sim 99): a light grey square with a round icon, the name, a dark info line
-- and a green buy button with a dark stroke. cardState switches it between:
--   "buy"    light grey card, green button with the price,
--   "owned"  bright green card with a big tilted "Owned!" (or "Equipped!", "MAX!") and no button,
--   "locked" grey card with a padlock over the dimmed icon and a grey price button.
type GridCard = {
	frame: Frame,
	color: Color3,
	icon: Frame,
	info: TextLabel,
	button: TextButton,
	lock: TextLabel,
	tag: TextLabel,
}
local function gridCard(
	list: Instance,
	order: number,
	color: Color3,
	title: string,
	text: string
): GridCard
	local c = Instance.new("Frame")
	c.LayoutOrder = order
	c.BackgroundColor3 = CARD_GREY
	c.Parent = list
	corner(c, 14)
	stroke(c, 2.5).Color = OUTLINE
	local icon = Instance.new("Frame")
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 12)
	icon.Size = UDim2.fromOffset(64, 64)
	icon.BackgroundColor3 = color
	icon.Parent = c
	corner(icon)
	stroke(icon, 3).Color = OUTLINE
	local shine = Instance.new("Frame")
	shine.Position = UDim2.fromOffset(14, 9)
	shine.Size = UDim2.fromOffset(18, 12)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.45
	shine.BorderSizePixel = 0
	shine.Parent = icon
	corner(shine)
	local lock = textLabel(icon, "🔒", Color3.new(1, 1, 1))
	lock.Size = UDim2.fromScale(1, 1)
	lock.Visible = false
	local name = textLabel(c, title, Color3.new(1, 1, 1))
	name.Position = UDim2.new(0, 8, 0, 82)
	name.Size = UDim2.new(1, -16, 0, 26)
	local info = textLabel(c, text, Color3.fromRGB(80, 70, 100), Enum.Font.FredokaOne)
	info:FindFirstChildOfClass("UIStroke"):Destroy()
	info.Position = UDim2.new(0, 10, 0, 110)
	info.Size = UDim2.new(1, -20, 0, 40)
	info.TextWrapped = true
	local b = button(c, "", BUY)
	b.AnchorPoint = Vector2.new(0.5, 1)
	b.Position = UDim2.new(0.5, 0, 1, -14)
	b.Size = UDim2.new(1, -24, 0, 46)
	local tag = textLabel(c, "Owned!", Color3.new(1, 1, 1))
	tag.FontFace = Font.new(
		"rbxasset://fonts/families/FredokaOne.json",
		Enum.FontWeight.Heavy,
		Enum.FontStyle.Italic
	)
	tag.AnchorPoint = Vector2.new(0.5, 1)
	tag.Position = UDim2.new(0.5, 0, 1, -14)
	tag.Size = UDim2.new(1, -24, 0, 44)
	tag.Rotation = -4
	tag.Visible = false
	local tagStroke = tag:FindFirstChildOfClass("UIStroke") :: UIStroke
	tagStroke.Thickness = 3.5
	tagStroke.Color = Color3.fromRGB(20, 70, 15)
	return { frame = c, color = color, icon = icon, info = info, button = b, lock = lock, tag = tag }
end

local function cardState(gc: GridCard, look: string, text: string)
	local owned, locked = look == "owned", look == "locked"
	gc.frame.BackgroundColor3 = owned and Color3.fromRGB(110, 215, 80)
		or locked and Color3.fromRGB(196, 198, 208)
		or CARD_GREY
	gc.icon.BackgroundColor3 = locked and gc.color:Lerp(Color3.fromRGB(120, 120, 130), 0.65)
		or gc.color
	gc.lock.Visible = locked
	gc.info.TextColor3 = owned and Color3.fromRGB(25, 75, 20) or Color3.fromRGB(80, 70, 100)
	gc.tag.Visible = owned
	gc.button.Visible = not owned
	if owned then
		gc.tag.Text = text
	else
		gc.button.Text = text
		gc.button.BackgroundColor3 = locked and Color3.fromRGB(150, 150, 162) or BUY
	end
end

local buyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteFunction
-- The one Shop panel has three tabs, each its own frame: Scythes (toolPanel), Upgrades
-- (upgradePanel) and Robux (shopPanel, hidden while every ID is 0). The tab bar is added further
-- down, where all three exist.
local upgradePanel, upgradeList = panel("🎃 Shop!", true)
-- Scythes tab: every tool as a grid card. The best owned one is always held ("Equipped!"), other
-- owned ones read "Owned!", unaffordable ones and the MVP drop are grey with a padlock.
local toolPanel, refreshToolCards
do
	local buyTool = remotes:WaitForChild("BuyTool") :: RemoteFunction
	local list
	toolPanel, list = panel("🎃 Shop!", true)
	local cards: { [string]: GridCard } = {}
	for i, tool in Config.Tools do
		local gc = gridCard(
			list,
			i,
			tool.color,
			tool.name,
			string.format("%s damage per swing", short(tool.damage))
		)
		cards[tool.id] = gc
		local b = gc.button
		b.Activated:Connect(function()
			if not tool.cost then
				hint("Only the Blood Moon MVP gets the " .. tool.name .. "!")
				return
			end
			local ok, message = buyTool:InvokeServer(tool.id)
			if ok then
				play(Config.Sounds.Coin, 0.9, 0.8)
				toast(string.upper(tool.name) .. "!", short(tool.damage) .. " damage per swing")
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
			local gc = cards[tool.id]
			if tool.id == held then
				cardState(gc, "owned", "Equipped!")
			elseif owned[tool.id] then
				cardState(gc, "owned", "Owned!")
			elseif not tool.cost then
				cardState(gc, "locked", "MVP DROP")
			else
				local price = "🍬 " .. short(tool.cost)
				cardState(gc, candyValue.Value >= tool.cost and "buy" or "locked", price)
			end
		end
	end
	player:GetAttributeChangedSignal("Tools"):Connect(refreshToolCards)
	player:GetAttributeChangedSignal("Tool"):Connect(refreshToolCards)
end
local upgradeCards: { [string]: GridCard } = {}
local refreshUpgradeCards -- forward: a failed buy shows its reason, then refreshes
-- Sharp Blade (Mallet) is cut; Lucky Swing shows once its gate opens.
local UPGRADE_ORDER = { "Boots", "Stack", "Lucky" }
local UPGRADE_COLOR = {
	Boots = Color3.fromRGB(255, 210, 65),
	Stack = Color3.fromRGB(255, 150, 50),
	Lucky = Color3.fromRGB(110, 210, 90),
}
for i, id in UPGRADE_ORDER do
	local info = Config.Upgrades[id]
	local gc = gridCard(upgradeList, i, UPGRADE_COLOR[id], info.title, info.text)
	upgradeCards[id] = gc
	local b = gc.button
	b.Activated:Connect(function()
		local ok, message = buyUpgrade:InvokeServer(id)
		if ok then
			play(Config.Sounds.Coin, 0.9, 0.8)
			toast(info.title, info.text)
		else
			b.Text = message
			task.delay(1, refreshUpgradeCards)
		end
	end)
end
function refreshUpgradeCards()
	for id, gc in upgradeCards do
		local info = Config.Upgrades[id]
		local level = player:GetAttribute("Up_" .. id) or 0
		gc.frame.Visible = id ~= "Lucky" or unlocked("LuckySwing")
		gc.info.Text = info.text
			.. "\n"
			.. string.rep("●", level)
			.. string.rep("○", info.max - level)
		if level >= info.max then
			cardState(gc, "owned", "MAX!")
		else
			local cost = Config.upgradeCost(id, level)
			cardState(gc, candyValue.Value >= cost and "buy" or "locked", "🍬 " .. short(cost))
		end
	end
end
for _, id in UPGRADE_ORDER do
	player:GetAttributeChangedSignal("Up_" .. id):Connect(refreshUpgradeCards)
end
player:GetAttributeChangedSignal("Unlock_LuckySwing"):Connect(refreshUpgradeCards)
player:GetAttributeChangedSignal("Tool"):Connect(refreshCarry)
candyValue.Changed:Connect(function()
	refreshToolCards()
	refreshUpgradeCards()
end)
refreshToolCards()
refreshUpgradeCards()

-- Pumpkin Index: a book of every seed x finish. Selling a new kind fills it in. -------------

local FINISHES = { "Plain", "Glowing", "Ghostly", "Candy", "Cursed" }
local indexPanel, indexList = panel("🎃 Pumpkin Index!")
local indexCells = {}
for i, seed in Config.Seeds do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 56)
	row.LayoutOrder = i
	row.BackgroundColor3 = CARD_GREY
	row.Parent = indexList
	corner(row, 14)
	stroke(row, 2.5).Color = OUTLINE
	local name = textLabel(row, seed.name, Color3.fromRGB(255, 255, 255))
	name.Size = UDim2.fromScale(0.20, 0.8)
	name.Position = UDim2.fromScale(0.015, 0.1)
	name.TextXAlignment = Enum.TextXAlignment.Left
	indexCells[seed.id] = { name = name }
	for k, finish in FINISHES do
		local cell = Instance.new("Frame")
		cell.Size = UDim2.fromScale(0.14, 0.8)
		cell.Position = UDim2.fromScale(0.24 + (k - 1) * 0.15, 0.1)
		cell.BackgroundColor3 = Color3.fromRGB(70, 62, 84)
		cell.Parent = row
		corner(cell, 10)
		stroke(cell, 2.5).Color = OUTLINE
		local label = textLabel(cell, "?", Color3.fromRGB(150, 140, 160))
		label.Size = UDim2.new(1, -8, 1, -8)
		label.Position = UDim2.fromOffset(4, 4)
		indexCells[seed.id][finish] = { cell = cell, label = label }
	end
end
local indexCount = textLabel(indexPanel, "", Color3.fromRGB(255, 214, 80))
indexCount.AnchorPoint = Vector2.new(1, 0)
indexCount.Position = UDim2.fromScale(0.87, 0.125)
indexCount.Size = UDim2.fromScale(0.4, 0.045)
local function refreshIndex()
	local found = {}
	for key in string.gmatch(player:GetAttribute("Index") or "", "[^,]+") do
		found[key] = true
	end
	-- Finishes come with brewing; before that the book is one slot per type.
	local brew = player:GetAttribute("Unlock_Brew") == true
	local total = 0
	for _, seed in Config.Seeds do
		local all = true
		for k, finish in FINISHES do
			local parts = indexCells[seed.id][finish]
			parts.cell.Visible = brew or k == 1
			if not (brew or k == 1) then
				continue
			end
			if found[seed.id .. ":" .. finish] then
				total += 1
				local m = mutationById[finish]
				parts.cell.BackgroundColor3 = m and m.color or seedColor(seed)
				parts.label.Text = finish == "Plain" and "✓"
					or string.upper(string.sub(finish, 1, 4))
				parts.label.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				all = false
				-- Not found yet: a dark "?" silhouette (Pet Sim 99 index).
				parts.cell.BackgroundColor3 = Color3.fromRGB(70, 62, 84)
				parts.label.Text = "?"
				parts.label.TextColor3 = Color3.fromRGB(170, 165, 185)
			end
		end
		indexCells[seed.id].name.Text = seed.name .. ((all and brew) and " +10%" or "")
	end
	indexCount.Text =
		string.format("Collected %d/%d", total, #Config.Seeds * (brew and #FINISHES or 1))
end
player:GetAttributeChangedSignal("Index"):Connect(refreshIndex)
player:GetAttributeChangedSignal("Unlock_Brew"):Connect(refreshIndex)
refreshIndex()

-- Music: a calm day loop, a tense midnight loop and a boss loop that crossfade by phase.
-- toggleSound (the small speaker button in the Shop panel corner) mutes music and effects.
local toggleSound: () -> boolean
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
	-- Spooky Hour plays the day loop a little faster (the "faster variant" of the hub music).
	local function refreshTempo()
		local fast = state:GetAttribute("SpookyEnds") ~= nil
		for name, music in tracks do
			local speed = (fast and name == "Day") and 1.12 or 1
			TweenService:Create(music, TweenInfo.new(1.5), { PlaybackSpeed = speed }):Play()
		end
	end
	state:GetAttributeChangedSignal("SpookyEnds"):Connect(refreshTempo)
	refreshTempo()

	function toggleSound(): boolean
		musicOn = not musicOn
		sfxOn = musicOn
		refreshMusic()
		return musicOn
	end
end

-- Red round count badge on the top-right corner of a pill (Pet Sim 99 / Steal an Egg style).
local function pillBadge(b: GuiButton): TextLabel
	local badge = textLabel(b, "", Color3.fromRGB(255, 255, 255))
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(1, -4, 0, 2)
	badge.Size = UDim2.fromOffset(24, 24)
	badge.BackgroundColor3 = Color3.fromRGB(224, 32, 74)
	badge.BackgroundTransparency = 0
	badge.ZIndex = b.ZIndex + 5
	badge.Visible = false
	corner(badge)
	return badge
end

local indexButton = pill("📖 Index", Color3.fromRGB(40, 190, 235), 2)
-- Red badge: Index entries found since the Index was last opened.
local indexBadge = pillBadge(indexButton)

-- Gate news. The base lock has no pill (2 HUD buttons only): the LOCK prompt on your base's sign
-- post does it. When the new-player shield ends one banner says so; the later gates arrive as one
-- toast each. Only a gate that opens while playing is announced (not one a returning player had).
do
	local loadedAt = player:GetAttribute("Loaded") and -math.huge or nil
	player:GetAttributeChangedSignal("Loaded"):Connect(function()
		loadedAt = loadedAt or os.clock()
	end)
	local function fresh(): boolean
		return loadedAt ~= nil and os.clock() - loadedAt > 3
	end
	player:GetAttributeChangedSignal("Unlock_PlayerSteal"):Connect(function()
		if unlocked("PlayerSteal") and fresh() then
			banner(
				"Ghosts and players can raid you now!",
				"Lock your Base at its sign post!",
				3.5,
				Color3.fromRGB(200, 140, 255)
			)
			play(Config.Sounds.Bonk, 0.6, 0.9)
		end
	end)
	for name, text in
		{
			Sell = "The Witch buys pumpkins now! Pick some up from your base and sell them.",
			Brew = "The Magic Cauldrons are open! Brew pumpkins for x2 to x10.",
			LuckySwing = "New upgrade in the Shop: Lucky Swing!",
			King = "The Pumpkin King wakes in every Blood Moon. Bonk him for candy!",
			Haunt = "Rebirth is open! Finish the Throne quest, own a Legendary and bring 5M candy.",
		}
	do
		player:GetAttributeChangedSignal("Unlock_" .. name):Connect(function()
			if unlocked(name) and fresh() then
				hint(text)
			end
		end)
	end
end

-- Haunt: reset for +50% sell value forever and Souls to spend in the Soul skill tree. -----------

local hauntRemote = remotes:WaitForChild("Haunt") :: RemoteFunction
local buySkill = remotes:WaitForChild("BuySkill") :: RemoteFunction
local hauntPanel, hauntList = panel("Rebirth!")
local soulsLabel = textLabel(hauntPanel, "", Color3.fromRGB(200, 160, 255))
soulsLabel.AnchorPoint = Vector2.new(1, 0)
soulsLabel.Position = UDim2.new(1, -54, 0, 10)
soulsLabel.Size = UDim2.fromOffset(200, 34)
local hauntInfo = textLabel(hauntList, "", Color3.fromRGB(225, 220, 240), Enum.Font.FredokaOne)
hauntInfo:FindFirstChildOfClass("UIStroke"):Destroy()
hauntInfo.LayoutOrder = 0
hauntInfo.Size = UDim2.new(1, -10, 0, 64)
hauntInfo.TextScaled = false
hauntInfo.TextSize = 17
hauntInfo.TextWrapped = true
hauntInfo.TextXAlignment = Enum.TextXAlignment.Left
local hauntCard, hauntCardText = card(hauntList, 1, Color3.fromRGB(150, 90, 255), "Rebirth", "")
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
		toast(skill.title .. "!", skill.text)
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
			textLabel(nodeButton, skill.text, Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne)
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
	return Config.Progression.rebirthCost
end
local confirmUntil = 0
local function refreshHaunt()
	local n = player:GetAttribute("Rebirths") or 0
	soulsLabel.Text = string.format("Rebirth %d/%d", n, Config.Progression.rebirthCap)
	hauntInfo.Text =
		"Finish the Throne quest + own a Legendary + 5M candy. Resets candy, scythe and gates. Keeps pets, pen and stamps."
	hauntCardText.Text = string.format(
		"+25%% candy each | current bonus +%d%%",
		n * Config.Progression.rebirthBonus * 100
	)
	hauntGo.Text = os.clock() < confirmUntil and "SURE? Click again" or "REBIRTH | 5M candy"
	for _, node in skillNodes do
		node.button.Visible = false
	end
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
	local ok, message = hauntRemote:InvokeServer()
	if ok then
		play(Config.Sounds.Brew, 0.5, 1)
		toast("REBIRTH!", "+25% candy forever")
	else
		hauntGo.Text = message
		task.delay(1, refreshHaunt)
		return
	end
	refreshHaunt()
end)
for _, attr in { "Rebirths", "Unlock_Haunt" } do
	player:GetAttributeChangedSignal(attr):Connect(refreshHaunt)
end
candyValue.Changed:Connect(refreshHaunt)
refreshHaunt()

-- Shop: game passes and developer products whose Config ID is not 0. ----------------------------

local shopRemote = remotes:WaitForChild("Shop") :: RemoteFunction
type ShopItem = { kind: string, name: string, title: string, text: string, color: Color3 }
type ShopCard = { item: ShopItem, id: number, card: GridCard, price: string }
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
local shopPanel, shopList = panel("🎃 Shop!", true)
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
			cardState(entry.card, "owned", "Owned!")
		else
			cardState(entry.card, "buy", entry.price)
		end
		local quote = shopQuotes[item.name]
		if type(quote) == "number" then
			entry.card.info.Text = string.format("+%s candy right now", short(quote))
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
	local gc = gridCard(shopList, i, item.color, item.title, item.text)
	local entry: ShopCard = { item = item, id = id, card = gc, price = "BUY" }
	table.insert(shopCards, entry)
	gc.button.Activated:Connect(function()
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
					toast(item.title .. "!", item.text)
				end
			end
			play(Config.Sounds.Coin, 0.8, 1)
		end
	end)
end

-- Left pills (Steal an Egg footprint): exactly Shop and Index. Each pill opens one panel at a time
-- (the same pill closes it again). Shop is one panel with tabs (Scythes / Upgrades / Haunt once
-- its gate opens / Robux while any ID is set) and a small speaker (mute) button.
do
	local panels = panelFrames
	local SHOP_TABS = {
		{ name = "Scythes", label = "⚒ Scythes", frame = toolPanel },
		{ name = "Upgrades", label = "⭐ Upgrades", frame = upgradePanel },
		{ name = "Haunt", label = "Rebirth", frame = hauntPanel },
		{ name = "Robux", label = "💎 Robux", frame = shopPanel },
	}
	local TAB_ON, TAB_OFF = BUY, Color3.fromRGB(150, 150, 162)
	local hasRobux = #shopCards > 0
	local lastTab = "Scythes"
	local tabButtons: { { button: TextButton, name: string } } = {}
	local muteButtons: { TextButton } = {}

	local function tabShown(name: string): boolean
		if name == "Robux" then
			return hasRobux
		elseif name == "Haunt" then
			return unlocked("Haunt")
		end
		return true
	end

	-- Shown tabs sit left to right without gaps (each tab frame has its own row).
	local function layoutTabs()
		local slot: { [Instance]: number } = {}
		for _, t in tabButtons do
			local frame = t.button.Parent :: Instance
			local shown = tabShown(t.name)
			t.button.Visible = shown
			if shown then
				local k = slot[frame] or 0
				slot[frame] = k + 1
				t.button.Position = UDim2.fromScale(0.025 + k * 0.21, 0.14)
			end
		end
	end

	local function shopOpen(): boolean
		for _, tab in SHOP_TABS do
			if tab.frame.Visible then
				return true
			end
		end
		return false
	end

	-- name = the tab to show; nil closes every panel.
	local function openShop(name: string?)
		for _, p in panels do
			p.Visible = false
		end
		if not name then
			return
		end
		if not tabShown(name) then
			name = "Scythes"
		end
		lastTab = name :: string
		for _, tab in SHOP_TABS do
			tab.frame.Visible = tab.name == name
		end
		for _, t in tabButtons do
			t.button.BackgroundColor3 = t.name == name and TAB_ON or TAB_OFF
		end
		if name == "Robux" then
			task.spawn(function()
				local ok, quotes = pcall(shopRemote.InvokeServer, shopRemote, "open")
				if ok and type(quotes) == "table" then
					shopQuotes = quotes
					refreshShop()
				end
			end)
		end
	end

	local function toggle(which: Frame)
		local open = not which.Visible
		for _, p in panels do
			p.Visible = false
		end
		which.Visible = open
	end

	-- Every tab frame gets the same tab row under its title (the item list moves down under it)
	-- and the speaker button at the row's right end.
	for _, tab in SHOP_TABS do
		local frame = tab.frame
		local list = frame:FindFirstChildOfClass("ScrollingFrame")
		if list then
			list.Position = UDim2.fromScale(0.025, 0.28)
			list.Size = UDim2.fromScale(0.95, 0.69)
		end
		for _, other in SHOP_TABS do
			local b = button(frame, other.label, TAB_OFF)
			b.Size = UDim2.fromScale(0.20, 0.10)
			b.Activated:Connect(function()
				openShop(other.name)
			end)
			table.insert(tabButtons, { button = b, name = other.name })
		end
		local mute = button(frame, "🔊", Color3.fromRGB(95, 95, 115))
		mute.AnchorPoint = Vector2.new(1, 0)
		mute.Position = UDim2.fromScale(0.975, 0.14)
		mute.Size = UDim2.fromScale(0.08, 0.10)
		mute.Activated:Connect(function()
			local on = toggleSound()
			for _, m in muteButtons do
				m.Text = on and "🔊" or "🔇"
			end
		end)
		table.insert(muteButtons, mute)
	end
	layoutTabs()
	-- Haunt costs millions: its tab waits for the HauntPillAt gate (lifetime candy).
	player:GetAttributeChangedSignal("Unlock_Haunt"):Connect(layoutTabs)

	local shopButton = pill("🛒 Shop", Color3.fromRGB(240, 170, 30), 1)
	shopButton.Activated:Connect(function()
		openShop(if shopOpen() then nil else lastTab)
	end)
	-- "!" badge while a better scythe than the one you hold is affordable.
	local shopBadge = pillBadge(shopButton)
	shopBadge.Text = "!"
	local function refreshShopBadge()
		local owned = {}
		for id in string.gmatch(player:GetAttribute("Tools") or "", "[^,]+") do
			owned[id] = true
		end
		local best = 0
		for _, tool in Config.Tools do
			if owned[tool.id] or tool.id == player:GetAttribute("Tool") then
				best = math.max(best, tool.damage)
			end
		end
		local affordable = false
		for _, tool in Config.Tools do
			if
				tool.cost
				and not owned[tool.id]
				and tool.damage > best
				and candyValue.Value >= tool.cost
			then
				affordable = true
			end
		end
		shopBadge.Visible = affordable
	end
	candyValue.Changed:Connect(refreshShopBadge)
	player:GetAttributeChangedSignal("Tools"):Connect(refreshShopBadge)
	player:GetAttributeChangedSignal("Tool"):Connect(refreshShopBadge)
	refreshShopBadge()

	-- Walking into a stall opens the Shop on its tab (Tools stall: Scythes, Upgrades stall:
	-- Upgrades); again on the open tab closes it.
	remotes:WaitForChild("OpenShop").OnClientEvent:Connect(function(kind: string)
		local name = kind == "Tools" and "Scythes" or "Upgrades"
		local frame = name == "Scythes" and toolPanel or upgradePanel
		openShop(if frame.Visible then nil else name)
	end)

	indexButton.Activated:Connect(function()
		toggle(indexPanel)
		indexBadge.Visible = false
		indexBadge.Text = ""
	end)
end

remotes:WaitForChild("IndexNew").OnClientEvent:Connect(function(keys: { string })
	if not indexPanel.Visible then
		local n = (tonumber(indexBadge.Text) or 0) + #keys
		indexBadge.Text = tostring(math.min(n, 99))
		indexBadge.Visible = n > 0
	end
	for i, key in keys do
		local seedId, finish = string.match(key, "([^:]+):(.+)")
		local seed = seedById[seedId or ""]
		if seed then
			task.delay((i - 1) * 0.9, function()
				local label = finish == "Plain" and seed.name or (finish .. " " .. seed.name)
				toast("NEW IN YOUR INDEX!", label)
				play(Config.Sounds.Brew, 1.5, 0.6)
			end)
		end
	end
end)

remotes:WaitForChild("Announce").OnClientEvent:Connect(function(text: string)
	if
		text == "Ghosts coming! Lock base or go home"
		or text == "PUMPKIN KING RISES! PET + LOOT!"
	then
		banner(text, nil, 3, Color3.fromRGB(255, 80, 70))
		play(Config.Sounds.Roar, 0.6, 1)
	else
		toast(text)
	end
	play(Config.Sounds.Brew, 0.7, 0.8)
end)

-- Reward reveal (Steal an Egg hatch / Pet Sim 99 "New Item!"): a 0.15 s white flash, then a
-- centred white card: the pumpkin itself turning slowly in a ViewportFrame over a ray burst, the
-- rarity in its colour, the name, its income "+X/s" and a green "NEW!" tag for a type you never
-- had. The server sends one for a new type, a rare type or a Cursed brew; a hatch (kind "jack")
-- is queued by the client's hatch sequence (it did its own pink flash, so no white one), with
-- confetti for Rare and up. The world behind blurs (BlurEffect 0 -> 18) while a card shows. It
-- closes after Config.RevealSeconds or on a click (clicks count after the first second); more
-- queue up and show one after another.
do
	local blur = Instance.new("BlurEffect")
	blur.Name = "RevealBlur"
	blur.Size = 0
	blur.Parent = Lighting
	local revealGui = Instance.new("ScreenGui")
	revealGui.Name = "PatchReveal"
	revealGui.ResetOnSpawn = false
	revealGui.IgnoreGuiInset = true
	revealGui.DisplayOrder = 6
	revealGui.Parent = player:WaitForChild("PlayerGui")
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Size = UDim2.fromScale(1, 1)
	flash.ZIndex = 5
	flash.Parent = revealGui
	local MAX_QUEUE = 5
	local queue: { { any } } = {}
	local busy = false

	local function rarityOf(order: number)
		for _, r in Config.Rarities do
			if order <= r.upTo then
				return r
			end
		end
		return Config.Rarities[#Config.Rarities]
	end

	-- The pumpkin you just got (on your head stack, or on the ground when your hands were full),
	-- else any pumpkin of that type around; the same finish (and the same pet) is preferred.
	local function findPumpkin(seedId: string, mutation: string?, pet: string?): BasePart?
		local fallback: BasePart? = nil
		local roots = { player.Character, garden:FindFirstChild("Loose"), patchFolder }
		table.insert(roots, garden:FindFirstChild("Wild"))
		for _, root in roots do
			for _, d in root and root:GetDescendants() or {} do
				if
					d:IsA("BasePart")
					and d:GetAttribute("Seed") == seedId
					and (pet == nil or d:GetAttribute("Pet") == pet)
				then
					if d:GetAttribute("Mutation") == mutation then
						return d
					end
					fallback = fallback or d
				end
			end
		end
		return fallback
	end

	-- A copy for the ViewportFrame (children such as welds, prompts and billboards removed);
	-- a hatched pet (or mystery pumpkin) shows its model look ("PetLook"); a coloured ball
	-- stands in when no pumpkin of that type is around.
	local function pumpkinCopy(seed, mutation: string?, pet: string?): PVInstance
		local source = findPumpkin(seed.id, mutation, pet)
			or (pet and findPumpkin(seed.id, mutation))
		local look = source and source:FindFirstChild("PetLook")
		if look and look:IsA("Model") then
			look.Archivable = true
			local m = look:Clone()
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
				elseif
					d:IsA("JointInstance")
					or d:IsA("WeldConstraint")
					or d:IsA("Light")
					or d:IsA("ParticleEmitter")
					or d:IsA("BillboardGui")
				then
					d:Destroy()
				end
			end
			local cf = m:GetBoundingBox()
			m:PivotTo(cf:ToObjectSpace(m:GetPivot()))
			return m
		end
		local copy: BasePart
		if source then
			source.Archivable = true
			copy = source:Clone()
			for _, child in copy:GetChildren() do
				if not child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
		else
			local ball = Instance.new("Part")
			ball.Shape = Enum.PartType.Ball
			ball.Size = Vector3.new(2.6, 2.6, 2.6)
			ball.Material = Enum.Material.SmoothPlastic
			ball.Color = seedColor(seed)
			copy = ball
		end
		copy.Anchored = true
		copy.CFrame = CFrame.new()
		return copy
	end

	-- kind: "jack" (it just hatched: a pet, or a living Jack without a pet model) or "hoard" (a
	-- Hoard pumpkin delivered). pet = the pet it hatched into (the card shows the pet's name).
	local function showCard(
		seedId: string,
		mutation: string?,
		isNew: boolean,
		rate: number,
		kind: string?,
		pet: string?,
		weight: number?
	)
		Center.acquire()
		local seed = seedById[seedId]
		local rarity = rarityOf(seed.order)
		local rarityPet = Config.Pets[pet or seed.pet]
		if rarityPet then
			for _, r in Config.Rarities do
				if r.name == rarityPet.rarity then
					rarity = r
					break
				end
			end
		end
		local m = mutation and mutationById[mutation]
		-- White flash first (a hatch already flashed pink).
		if kind ~= "jack" then
			flash.BackgroundTransparency = 0
			TweenService:Create(
				flash,
				TweenInfo.new(Config.RevealFlash, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }
			):Play()
		end
		play(Config.Sounds.Brew, isNew and 1.5 or 1.2, 0.8)
		task.wait(Config.RevealFlash)
		TweenService:Create(blur, TweenInfo.new(0.3), { Size = 18 }):Play()
		if kind == "jack" and seed.order >= 3 then
			-- Rare and up: confetti over the card.
			confetti(revealGui)
		end

		-- A full-screen button under the card dims the world (black at 0.45) and closes the card
		-- on a click anywhere.
		local catcher = Instance.new("TextButton")
		catcher.Name = "Reveal"
		catcher.Text = ""
		catcher.AutoButtonColor = false
		catcher.BackgroundColor3 = Color3.new(0, 0, 0)
		catcher.BackgroundTransparency = 1
		catcher.BorderSizePixel = 0
		catcher.Size = UDim2.fromScale(1, 1)
		catcher.ZIndex = 2
		catcher.Parent = revealGui
		Center.register(catcher)
		TweenService:Create(catcher, TweenInfo.new(0.2), { BackgroundTransparency = 0.45 }):Play()
		local cardFrame = Instance.new("Frame")
		cardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		cardFrame.Position = UDim2.fromScale(0.5, 0.46)
		cardFrame.Size = UDim2.fromOffset(340, 410)
		cardFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		cardFrame.Parent = catcher
		corner(cardFrame, 16)
		-- Rarity-coloured border: a thick rarity ring inside a thin dark outline.
		local border = stroke(cardFrame, 6)
		border.Color = rarity.color
		local outer = Instance.new("Frame")
		outer.AnchorPoint = Vector2.new(0.5, 0.5)
		outer.Position = UDim2.fromScale(0.5, 0.5)
		outer.Size = UDim2.new(1, 12, 1, 12)
		outer.BackgroundTransparency = 1
		outer.ZIndex = 0
		outer.Parent = cardFrame
		corner(outer, 20)
		stroke(outer, 3).Color = OUTLINE
		-- Pop-in: 0.6 -> 1 (x the HUD scale) with Back easing (overshoots ~1.05).
		local scale = Instance.new("UIScale")
		scale.Scale = 0.6 * uiScale.Scale
		scale.Parent = cardFrame
		TweenService:Create(
			scale,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = uiScale.Scale }
		):Play()

		-- Light rays in the rarity colour behind the pumpkin.
		local rays = Instance.new("Frame")
		rays.AnchorPoint = Vector2.new(0.5, 0.5)
		rays.Position = UDim2.new(0.5, 0, 0, 132)
		rays.Size = UDim2.fromOffset(290, 290)
		rays.BackgroundTransparency = 1
		rays.ZIndex = 1
		rays.Parent = cardFrame
		for k = 1, 8 do
			local ray = Instance.new("Frame")
			ray.AnchorPoint = Vector2.new(0.5, 0.5)
			ray.Position = UDim2.fromScale(0.5, 0.5)
			ray.Size = UDim2.new(0, 30, 1, 0)
			ray.Rotation = k * 22.5
			-- Rarity tint, a little lighter so the rays glow behind the pumpkin.
			ray.BackgroundColor3 = rarity.color:Lerp(Color3.new(1, 1, 1), 0.15)
			ray.BackgroundTransparency = 0.2
			ray.BorderSizePixel = 0
			ray.ZIndex = 1
			ray.Parent = rays
			local fadeEnds = Instance.new("UIGradient")
			fadeEnds.Rotation = 90
			fadeEnds.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			})
			fadeEnds.Parent = ray
		end

		-- The pumpkin itself, slowly turning.
		local view = Instance.new("ViewportFrame")
		view.AnchorPoint = Vector2.new(0.5, 0.5)
		view.Position = UDim2.new(0.5, 0, 0, 132)
		view.Size = UDim2.fromOffset(220, 220)
		view.BackgroundTransparency = 1
		view.Ambient = Color3.fromRGB(190, 190, 200)
		view.LightColor = Color3.new(1, 1, 1)
		view.LightDirection = Vector3.new(-0.6, -1, -0.8)
		view.ZIndex = 2
		view.Parent = cardFrame
		local cam = Instance.new("Camera")
		cam.FieldOfView = 40
		cam.Parent = view
		view.CurrentCamera = cam
		local model = pumpkinCopy(seed, mutation, pet)
		model.Parent = view
		local extents = if model:IsA("Model")
			then model:GetExtentsSize()
			else (model :: BasePart).Size
		local radius = math.max(extents.Magnitude / 2, 0.5)
		local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.1
		cam.CFrame = CFrame.lookAt(Vector3.new(0, radius * 0.45, dist), Vector3.zero)

		local rarityLabel = textLabel(cardFrame, string.upper(rarity.name), rarity.color)
		rarityLabel.Position = UDim2.fromOffset(12, 250)
		rarityLabel.Size = UDim2.new(1, -24, 0, 40)
		rarityLabel.ZIndex = 3
		local rarityStroke = rarityLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
		rarityStroke.Thickness = 3.5
		rarityStroke.Color = OUTLINE
		local petDef = pet and Config.Pets and Config.Pets[pet]
		local nameText = (mutation and (mutation .. " ") or "")
			.. (petDef and petDef.display or seed.name)
			.. (
				kind == "jack" and not petDef and " Jack"
				or kind == "hoard" and " · Hoard x" .. Config.HoardMult
				or ""
			)
		local nameLabel = textLabel(cardFrame, nameText, m and m.color or Color3.new(1, 1, 1))
		nameLabel.Position = UDim2.fromOffset(12, 292)
		nameLabel.Size = UDim2.new(1, -24, 0, 46)
		nameLabel.ZIndex = 3
		local nameStroke = nameLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
		nameStroke.Thickness = 4
		nameStroke.Color = OUTLINE
		local incomeText = "+"
			.. rateShort(rate)
			.. "/s"
			.. (weight and string.format(" · %.1f kg", weight) or "")
		local income = textLabel(cardFrame, incomeText, MONEY)
		income.Position = UDim2.fromOffset(12, 344)
		income.Size = UDim2.new(1, -24, 0, 42)
		income.ZIndex = 3
		local incomeStroke = income:FindFirstChildOfClass("UIStroke") :: UIStroke
		incomeStroke.Thickness = 3.5
		incomeStroke.Color = Color3.fromRGB(10, 50, 10)

		if isNew then
			-- Green "NEW!" tag hanging over the top-right corner, gently pulsing.
			local tag = Instance.new("Frame")
			tag.AnchorPoint = Vector2.new(1, 0)
			tag.Position = UDim2.new(1, 16, 0, -16)
			tag.Size = UDim2.fromOffset(112, 46)
			tag.Rotation = 8
			tag.BackgroundColor3 = Color3.fromRGB(60, 205, 70)
			tag.ZIndex = 4
			tag.Parent = cardFrame
			corner(tag, 12)
			stroke(tag, 3.5).Color = OUTLINE
			local newLabel = textLabel(tag, "NEW!", Color3.new(1, 1, 1))
			newLabel.FontFace = Font.new(
				"rbxasset://fonts/families/FredokaOne.json",
				Enum.FontWeight.Heavy,
				Enum.FontStyle.Italic
			)
			newLabel.Position = UDim2.fromOffset(6, 5)
			newLabel.Size = UDim2.new(1, -12, 1, -10)
			newLabel.ZIndex = 5
			local tagScale = Instance.new("UIScale")
			tagScale.Parent = tag
			TweenService:Create(
				tagScale,
				TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Scale = 1.12 }
			):Play()
		end

		local angle = 0
		local spin = RunService.RenderStepped:Connect(function(dt)
			angle += dt * 1.1
			model:PivotTo(CFrame.Angles(math.rad(-10), angle, 0))
			rays.Rotation += dt * 20
		end)
		local closed = false
		local function close()
			if closed then
				return
			end
			closed = true
			spin:Disconnect()
			TweenService:Create(blur, TweenInfo.new(0.3), { Size = 0 }):Play()
			local shrink = TweenService:Create(
				scale,
				TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{ Scale = 0 }
			)
			shrink:Play()
			TweenService:Create(catcher, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
			shrink.Completed:Once(function()
				catcher:Destroy()
			end)
		end
		local shownAt = os.clock()
		catcher.Activated:Connect(function()
			if os.clock() - shownAt >= 1 then
				close()
			end
		end)
		while not closed and os.clock() - shownAt < Config.RevealSeconds do
			local dt = task.wait(0.05)
			if Center.urgent then
				shownAt += dt
			end
		end
		close()
		task.wait(0.2)
		Center.release()
	end

	function queueReveal(
		seedId: string,
		mutation: string?,
		isNew: boolean,
		rate: number,
		kind: string?,
		pet: string?,
		weight: number?
	)
		if not seedById[seedId] or #queue >= MAX_QUEUE then
			return
		end
		table.insert(
			queue,
			{ seedId, mutation, isNew == true, tonumber(rate) or 0, kind, pet, weight }
		)
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			while #queue > 0 do
				local item = table.remove(queue, 1) :: { any }
				-- pcall: one bad card must never jam the queue.
				local ok, err =
					pcall(showCard, item[1], item[2], item[3], item[4], item[5], item[6], item[7])
				if not ok then
					warn("[Patch] Reveal card failed:", err)
					for _, frame in Center.frames do
						frame:Destroy()
					end
					Center.release()
					blur.Size = 0
				end
			end
			busy = false
		end)
	end
	remotes:WaitForChild("Reveal").OnClientEvent:Connect(queueReveal)
end

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
	-- Prompts of systems behind an unlock gate stay hidden until it opens (the server refuses them
	-- too): Pick up and the Witch (Sell), cauldrons (Brew), Steal and LOCK (PlayerSteal).
	local sellPrompt = market:WaitForChild("Sell"):FindFirstChild("PromptPart")
	local function refreshPrompts()
		local now = workspace:GetServerTimeNow()
		local locksOff = (state:GetAttribute("LocksOff") or 0) > now
		local carrying = (player:GetAttribute("Carry") or 0) > 0
		local canSell, canSteal = unlocked("Sell"), unlocked("PlayerSteal")
		for _, patch in patchFolder:GetChildren() do
			local owner = patch:GetAttribute("Owner") or 0
			local mine = owner == player.UserId
			local locked = not locksOff and (patch:GetAttribute("LockedUntil") or 0) > now
			-- A shielded owner (new farmer) cannot be robbed.
			local ownerPlayer = not mine and owner ~= 0 and Players:GetPlayerByUserId(owner) or nil
			local robbable = canSteal
				and ownerPlayer ~= nil
				and unlocked("PlayerSteal", ownerPlayer)
				and not locked
			for _, plot in patch:GetChildren() do
				if plot.Name == "Plot" then
					local active = (plot:GetAttribute("Index") or 1)
						<= (patch:GetAttribute("PenSlots") or Config.Progression.baseSlots)
					local filled = plot:GetAttribute("Filled") == true
					local name = filled and pumpkinName(plot) or nil
					set(
						plot:FindFirstChild("PlacePrompt"),
						active and mine and carrying and not filled,
						"Your plot"
					)
					set(
						plot:FindFirstChild("PickupPrompt", true),
						active
							and mine
							and filled
							and canSell
							and not (
								carrying
								and (player:GetAttribute("PenFilled") or 0)
									>= (player:GetAttribute("PenSlots") or 6)
							),
						name
					)
					set(
						plot:FindFirstChild("StealPrompt", true),
						active and robbable and filled and plot:GetAttribute("Protected") ~= true,
						name
					)
				end
			end
			set(patch:FindFirstChild("LockPrompt", true), mine and not locksOff and canSteal)
			local count = 0
			for _, plot in patch:GetChildren() do
				if
					plot.Name == "Plot"
					and plot:IsA("BasePart")
					and (plot:GetAttribute("Index") or 1)
						<= (patch:GetAttribute("PenSlots") or Config.Progression.baseSlots)
				then
					count += 1
				end
			end
			local full = mine
				and player:GetAttribute("CarryPet")
				and carrying
				and count > 0
				and (player:GetAttribute("PenFilled") or 0) >= count
			local soil = patch:FindFirstChild("Soil")
			local root = rootPart()
			local inside = false
			if full and soil and root then
				local at = soil.CFrame:PointToObjectSpace(root.Position)
				inside = math.abs(at.X) <= soil.Size.X / 2 + 4
					and math.abs(at.Z) <= soil.Size.Z / 2 + 4
			end
			set(patch:FindFirstChild("SwapPrompt", true), full and inside)
			local sell = patch:FindFirstChild("SellCarryPrompt", true)
			set(sell, full and inside)
			if sell and sell:IsA("ProximityPrompt") then
				sell.ActionText = "Sell for "
					.. short(player:GetAttribute("CarryTopValue") or 0)
					.. " 🍬"
			end
		end
		for _, p in sellPrompt and sellPrompt:GetChildren() or {} do
			if p:IsA("ProximityPrompt") then
				if p.Name == "RebirthPrompt" then
					set(p, unlocked("Haunt"))
				elseif string.sub(p.Name, 1, 10) == "WitchOffer" then
					set(p, unlocked("Witch"))
				else
					set(p, canSell)
				end
			end
		end
		local canBrew = unlocked("Brew")
		for _, cauldron in cauldronFolder:GetChildren() do
			local pot = cauldron:FindFirstChild("Pot")
			for _, p in pot and pot:GetChildren() or {} do
				if p:IsA("ProximityPrompt") then
					set(
						p,
						p.Name == "FusePrompt" and unlocked("Fuse")
							or p.Name ~= "FusePrompt" and canBrew
					)
				end
			end
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
	-- The default look is bright daytime (captured above from Studio Lighting), and Midnight keeps
	-- it (the ghost raid is the event, never real night). Spooky Hour grades the day orange-purple
	-- (TintColor #FFD9B0, Saturation +0.25, an orange haze with a purple decay; same sun), the
	-- Blood Moon a soft red; then back to base.
	local EVENT_LOOK = {
		Spooky = {
			lighting = {
				Ambient = base.Ambient:Lerp(Color3.fromRGB(170, 110, 160), 0.35),
				OutdoorAmbient = base.OutdoorAmbient:Lerp(Color3.fromRGB(190, 120, 170), 0.35),
				Brightness = base.Brightness,
				ClockTime = base.ClockTime,
			},
			tint = {
				TintColor = Color3.fromRGB(255, 217, 176),
				Saturation = 0.25,
				Contrast = 0.05,
			},
			atmosphere = {
				Color = Color3.fromRGB(242, 163, 94),
				Decay = Color3.fromRGB(122, 82, 191),
				Density = base.AtmosphereDensity,
			},
		},
		BloodMoon = {
			lighting = {
				Ambient = Config.KingNight.look.ambient,
				OutdoorAmbient = Config.KingNight.look.outdoor,
				Brightness = base.Brightness,
				ClockTime = Config.KingNight.look.clock,
			},
			tint = {
				TintColor = Config.KingNight.look.tint,
				Brightness = Config.KingNight.look.brightness,
				Saturation = Config.KingNight.look.saturation,
				Contrast = Config.KingNight.look.contrast,
			},
			atmosphere = {
				Color = Config.KingNight.look.sky,
				Decay = Config.KingNight.look.decay,
				Density = Config.KingNight.look.density,
			},
		},
	}
	local function setLighting(name: string?)
		local info = TweenInfo.new(name == "Spooky" and 3 or 2.5, Enum.EasingStyle.Sine)
		local tint = correction :: ColorCorrectionEffect
		local look = name and EVENT_LOOK[name]
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
	local lastLook: string? = "none"
	local function refreshLook()
		local phase = state:GetAttribute("Phase") or "Day"
		local name = (phase == "BloodMoon" or state:GetAttribute("KingWarning")) and "BloodMoon"
			or state:GetAttribute("SpookyEnds") ~= nil and "Spooky"
			or nil
		if name ~= lastLook then
			lastLook = name
			setLighting(name)
		end
	end
	local lastPhase = nil
	local function onPhase()
		refreshLook()
		local phase = state:GetAttribute("Phase") or "Day"
		if phase == lastPhase then
			return
		end
		local previous = lastPhase
		lastPhase = phase
		-- The midnight reset keeps its big banner; the other phase news are toasts, and only for
		-- players whose gate is open (new farmers are never sent to ghosts or the King).
		if phase == "Midnight" then
			local hoard = seedById[Config.Zones.Zone1.pets[1]]
			banner(
				"ALL PUMPKINS RESET!",
				string.format(
					"Midnight! The %s's nest is full of %s Pumpkins again!",
					Config.Hoards.Zone1.guardian,
					hoard and hoard.name or "Hoard"
				),
				3,
				Color3.fromRGB(170, 220, 255)
			)

			play(Config.Sounds.Brew, 0.5, 0.8)
		elseif phase == "BloodMoon" and unlocked("King") then
			toast("KING NIGHT!", "Pet + loot! Join the raid!")
			play(Config.Sounds.Brew, 0.4, 1)
		elseif previous == "Midnight" and unlocked("PlayerSteal") then
			toast("Dawn!", "The ghosts flee. Back to farming!")
		end
	end
	state:GetAttributeChangedSignal("Phase"):Connect(onPhase)
	state:GetAttributeChangedSignal("KingWarning"):Connect(refreshLook)
	onPhase()

	-- Spooky Hour: the tint above, a banner, and Config.SpookyBats bats (client only) circling over
	-- the lane around you: a dark purple body with two flapping wings (+-35 degrees) and tiny
	-- glowing eyes, each on its own loop (R 20-40 studs) 18-30 studs up.
	local BAT = Color3.fromRGB(45, 22, 70)
	local bats: { { parts: { BasePart }, offsets: { CFrame }, r: number, h: number, w: number, p: number } } =
		{}
	local batFolder: Folder? = nil
	local batConn: RBXScriptConnection? = nil
	local function batPart(folder: Folder, size: Vector3, color: Color3, neon: boolean?): Part
		local p = Instance.new("Part")
		p.Size = size
		p.Color = color
		p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = folder
		return p
	end
	local function stopBats()
		if batConn then
			batConn:Disconnect()
			batConn = nil
		end
		if batFolder then
			batFolder:Destroy()
			batFolder = nil
		end
		table.clear(bats)
	end
	local function startBats()
		stopBats()
		local folder = Instance.new("Folder")
		folder.Name = "SpookyBats"
		folder.Parent = workspace
		batFolder = folder
		for i = 1, Config.SpookyBats or 20 do
			local s = 0.8 + math.random() * 0.5
			local body = batPart(folder, Vector3.new(0.9, 0.7, 1.1) * s, BAT)
			local wingL = batPart(folder, Vector3.new(1.6, 0.12, 0.9) * s, BAT)
			local wingR = batPart(folder, Vector3.new(1.6, 0.12, 0.9) * s, BAT)
			local eyes =
				batPart(folder, Vector3.new(0.5, 0.12, 0.1) * s, Color3.fromRGB(255, 200, 60), true)
			table.insert(bats, {
				parts = { body, wingL, wingR, eyes },
				offsets = {
					CFrame.new(),
					CFrame.new(-0.8 * s, 0.1, 0),
					CFrame.new(0.8 * s, 0.1, 0),
					CFrame.new(0, 0.1 * s, -0.56 * s),
				},
				r = 20 + math.random() * 20,
				h = 18 + math.random() * 12,
				w = (0.25 + math.random() * 0.2) * (i % 2 == 0 and 1 or -1),
				p = math.random() * math.pi * 2,
			})
		end
		local moved: { BasePart } = {}
		local frames: { CFrame } = {}
		batConn = RunService.RenderStepped:Connect(function()
			local root = rootPart()
			local t = os.clock()
			local z = root and root.Position.Z or Config.SafeLineZ or 150
			local y = root and root.Position.Y or 0
			local center = Vector3.new(Config.MapCenterX or 0, y, z)
			table.clear(moved)
			table.clear(frames)
			for _, bat in bats do
				local a = t * bat.w + bat.p
				local pos = center
					+ Vector3.new(
						math.cos(a) * bat.r,
						bat.h + 2 * math.sin(2 * a),
						math.sin(a) * bat.r * 1.5
					)
				-- Fly along the loop (the derivative of the path), wings flapping.
				local ahead = Vector3.new(-math.sin(a) * bat.r, 0, math.cos(a) * bat.r * 1.5)
					* math.sign(bat.w)
				local cf =
					CFrame.lookAt(pos, pos + (ahead.Magnitude > 0.01 and ahead or Vector3.zAxis))
				local flap = math.rad(35) * math.sin(t * 22 + bat.p)
				for k, part in bat.parts do
					local o = bat.offsets[k]
					if k == 2 then
						o = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, flap) * o
					elseif k == 3 then
						o = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, -flap) * o
					end
					table.insert(moved, part)
					table.insert(frames, cf * o)
				end
			end
			workspace:BulkMoveTo(moved, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end)
	end
	local spookyWas = false
	local function onSpooky()
		refreshLook()
		local on = state:GetAttribute("SpookyEnds") ~= nil
		if on == spookyWas then
			return
		end
		spookyWas = on
		if on then
			startBats()
			banner(
				"🦇 SPOOKY HOUR! 2x CANDY",
				"Your base earns double candy for " .. clockText(Config.SpookyLength or 90) .. "!",
				3.5,
				Color3.fromRGB(255, 150, 40)
			)
			play(Config.Sounds.Brew, 0.6, 0.9)
		else
			stopBats()
			toast("Spooky Hour is over", "See you in " .. clockText(Config.SpookyEvery or 600))
		end
	end
	state:GetAttributeChangedSignal("SpookyEnds"):Connect(onSpooky)
	onSpooky()
end

-- Scythe ---------------------------------------------------------------------------------------

do
	local bonkEvent = remotes:WaitForChild("Bonk")
	local lastSwing = 0
	-- The idle Grip of each tool (the server's value) and the swing currently playing on it.
	local idleGrip: { [Tool]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
	local swingId: { [Tool]: number } = setmetatable({}, { __mode = "k" }) :: any
	-- The hand frame is the arm frame turned -90 on X; poses rotate the idle hold around the hand
	-- in the arm frame (pitch < 0 tips the upright scythe's top forward and down; with the arm
	-- raised forward, roll turns it around the vertical, sweeping the blade across).
	local HAND = CFrame.Angles(math.rad(-90), 0, 0)
	local function pose(base: CFrame, pitch: number, roll: number): CFrame
		local rot = CFrame.Angles(math.rad(pitch), 0, math.rad(roll))
		return base * HAND:Inverse() * rot:Inverse() * HAND
	end
	-- Wind up high and to the right, slash down and across to the left, settle back.
	local KEYS = {
		{ 0, 0, 0 },
		{ 0.08, 38, -32 },
		{ 0.18, -112, 34 },
		{ 0.27, -88, 20 },
		{ 0.42, 0, 0 },
	}
	local function swingTool(tool: Tool)
		local base = idleGrip[tool]
		if not base then
			base = tool.Grip
			idleGrip[tool] = base
		end
		local id = (swingId[tool] or 0) + 1
		swingId[tool] = id
		local trail = tool:FindFirstChild("SwingTrail", true) :: Trail?
		local started = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			if swingId[tool] ~= id or not tool.Parent then
				conn:Disconnect()
				return
			end
			local t = os.clock() - started
			local last = KEYS[#KEYS]
			if t >= last[1] then
				tool.Grip = base
				if trail then
					trail.Enabled = false
				end
				conn:Disconnect()
				return
			end
			for k = 1, #KEYS - 1 do
				local a, b = KEYS[k], KEYS[k + 1]
				if t < b[1] then
					local f = (t - a[1]) / (b[1] - a[1])
					f = f * f * (3 - 2 * f)
					tool.Grip = pose(base, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f)
					break
				end
			end
			-- The white arc only during the slash itself.
			if trail then
				local on = t >= 0.07 and t <= 0.3
				if trail.Enabled ~= on then
					trail.Enabled = on
				end
			end
		end)
	end
	-- Equipping re-parents the tool into the character (ChildAdded again): hook each tool once.
	local hookedTools: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any
	local function hookTool(tool: Instance)
		if not tool:IsA("Tool") or tool.Name ~= "Scythe" or hookedTools[tool] then
			return
		end
		hookedTools[tool] = true
		if not idleGrip[tool] then
			idleGrip[tool] = tool.Grip
		end
		tool.Activated:Connect(function()
			if player:GetAttribute("FightActive") or Center.urgent then
				return
			end
			local now = os.clock()
			-- Fast Hands (skill id QuickRoots) swings faster.
			local fast = string.find(player:GetAttribute("Skills") or "", "QuickRoots", 1, true)
			if
				now - lastSwing
				< (
						player:GetAttribute("LearningFarm") and Config.Farm.firstSwingSeconds
						or Config.BonkCooldown
					)
					/ (fast and 1 + Config.SkillSwingBonus or 1)
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
				local text = rateShort(income)
				floatText(
					at + Vector3.new(0, 4, 0),
					"+" .. text .. " 🍬/s",
					Color3.fromRGB(150, 255, 110)
				)
			end
		end
	end)

-- Wild pumpkins (Pet Sim 99 farming feel). Each hit: a white flash (Highlight, 0.08 s), a
-- squash to 90 % and back, sparkles and, for the hitter, a damage number. A pop bursts 8 candy
-- pieces that magnet into the hitter in 0.4 s, then the candy counter punches with "+N".
-- HP bars (made hidden by the server) show only on your target or on what you hit lately.
do
	local wildFolder = garden:WaitForChild("Wild", 10)
	local hitAt: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
	local rest: { [BasePart]: { size: Vector3, cf: CFrame } } = setmetatable({}, { __mode = "k" }) :: any

	local function juice(part: BasePart)
		local flash = Instance.new("Highlight")
		flash.FillColor = Color3.new(1, 1, 1)
		flash.FillTransparency = 0
		flash.OutlineColor = Color3.new(1, 1, 1)
		flash.OutlineTransparency = 0
		flash.DepthMode = Enum.HighlightDepthMode.Occluded
		flash.Parent = part
		task.delay(0.08, function()
			flash:Destroy()
		end)
		-- The server never resizes a wild pumpkin, so the local squash is safe.
		local r = rest[part]
		if not r then
			r = { size = part.Size, cf = part.CFrame }
			rest[part] = r
		end
		part.Size, part.CFrame = r.size, r.cf
		local info = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
		TweenService:Create(part, info, {
			Size = r.size * Vector3.new(1.08, 0.9, 1.08),
			CFrame = r.cf * CFrame.new(0, -r.size.Y * 0.05, 0),
		}):Play()
	end

	remotes
		:WaitForChild("WildHit").OnClientEvent
		:Connect(function(who: Player, at: Vector3, damage: number, part: BasePart?, crit: boolean?)
			burst(at + Vector3.new(0, 1, 0), Color3.fromRGB(255, 160, 60), 6, 10, SPARKLE, 0.5)
			if part and part.Parent then
				juice(part)
			end
			if who == player then
				if part then
					hitAt[part] = os.clock()
				end
				local top = part and part.Parent and part.Size.Y / 2 or 1.5
				local jitter =
					Vector3.new((math.random() - 0.5) * 2.5, top + 1, (math.random() - 0.5) * 2.5)
				damageText(at + jitter, damage, crit and ORANGE or Color3.new(1, 1, 1))
				play(Config.Sounds.Bonk, 1.1 + math.min(combo, 10) * 0.03, 0.55)
				countHit(at)
			end
		end)

	local CANDY_COLORS = {
		Color3.fromRGB(255, 90, 170),
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(120, 230, 255),
		Color3.fromRGB(150, 255, 110),
		Color3.fromRGB(255, 140, 40),
	}
	-- Small neon candies jump out of the pumpkin, then home in on the player's chest.
	local function candyBurst(at: Vector3, count: number)
		local landed = 0
		for i = 1, count do
			local candy = Instance.new("Part")
			candy.Name = "CandyBit"
			candy.Shape = i % 2 == 0 and Enum.PartType.Ball or Enum.PartType.Block
			candy.Size = Vector3.one * (0.45 + math.random() * 0.2)
			candy.Material = Enum.Material.Neon
			candy.Color = CANDY_COLORS[(i - 1) % #CANDY_COLORS + 1]
			candy.Anchored = true
			candy.CanCollide = false
			candy.CanQuery = false
			candy.CanTouch = false
			candy.CastShadow = false
			candy.CFrame = CFrame.new(at)
			candy.Parent = workspace
			local a = (i / count) * math.pi * 2 + math.random() * 0.5
			local out = at
				+ Vector3.new(math.cos(a) * 3, 2.5 + math.random() * 1.5, math.sin(a) * 3)
			local spin = CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
			local t0 = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.RenderStepped:Connect(function()
				local t = os.clock() - t0
				local root = rootPart()
				local goal = root and root.Position + Vector3.new(0, 1, 0) or at
				local p: Vector3
				if t < 0.15 then
					-- Pop out (ease out).
					local f = t / 0.15
					p = at:Lerp(out, 1 - (1 - f) * (1 - f))
				else
					-- Magnet in over 0.4 s (ease in).
					local f = math.min(1, (t - 0.15) / 0.4)
					p = out:Lerp(goal, f * f)
				end
				candy.CFrame = CFrame.new(p) * spin * CFrame.Angles(t * 9, t * 7, 0)
				if t >= 0.55 then
					conn:Disconnect()
					candy:Destroy()
					landed += 1
					if landed == 1 then
						play(Config.Sounds.Coin, 1.3 + math.random() * 0.2, 0.45)
					end
					if landed == count then
						-- The "+N" already popped when the candy arrived; just punch the counter.
						candyTick(0)
					end
				end
			end)
		end
	end

	remotes
		:WaitForChild("WildPopped").OnClientEvent
		:Connect(function(at: Vector3, seedId: string, winner: Player?, candy: number?)
			local seed = seedById[seedId or ""]
			local color = seed and seedColor(seed) or Color3.fromRGB(255, 130, 40)
			burst(at, color, 26, 24, SPARKLE, 1.1)
			burst(at, color, 14, 10, nil, 2.2)
			play(Config.Sounds.Pick, 1.3, 0.7)
			if winner == player and seed then
				candyBurst(at + Vector3.new(0, 1, 0), math.random(6, 10))
				floatText(
					at + Vector3.new(0, 4, 0),
					"+" .. short(candy or 0) .. " 🍬",
					color,
					seed.order >= 3
				)
				task.spawn(shake, 0.4, 5)
			end
		end)

	-- The pumpkin your next swing would hit: same reach and facing rule as the server.
	local function currentTarget(root: BasePart): Instance?
		local look = root.CFrame.LookVector
		local best, bestDist = nil, math.huge
		for _, part in wildFolder and wildFolder:GetChildren() or {} do
			if part:IsA("BasePart") then
				local offset = part.Position - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local dist = math.max(0, flat.Magnitude - part.Size.X / 2)
				if
					math.abs(offset.Y) < 12
					and dist <= Config.BonkRange
					and dist < bestDist
					and (flat.Magnitude < 3 or flat.Unit:Dot(look) > -0.2)
				then
					best, bestDist = part, dist
				end
			end
		end
		return best
	end

	task.spawn(function()
		while true do
			task.wait(0.1)
			local root = rootPart()
			local target = root and currentTarget(root)
			local now = os.clock()
			for _, part in wildFolder and wildFolder:GetChildren() or {} do
				local bar = part:FindFirstChild("HpBar")
				if bar and bar:IsA("BillboardGui") then
					local want = part == target
						or now - (hitAt[part] or -math.huge) < Config.HitBarSeconds
					if bar.Enabled ~= want then
						bar.Enabled = want
					end
				end
			end
		end
	end)
end

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
			if raw > 0 and unlocked("Brew") then
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
			damageText(at, power, stunned and Color3.fromRGB(255, 150, 40) or nil)
			play(Config.Sounds.Bonk, 0.9 + math.min(combo, 10) * 0.03, 0.8)
			countHit(at)
		end
	end)

remotes:WaitForChild("Stomp").OnClientEvent:Connect(function(kind: string, circles: { any })
	local root = rootPart()
	for _, c in circles do
		if c.cf then
			local lane = Instance.new("Part")
			lane.Anchored = true
			lane.CanCollide = false
			lane.CanQuery = false
			lane.CanTouch = false
			lane.Material = Enum.Material.Neon
			lane.Color = Color3.fromRGB(255, 70, 50)
			lane.Size = Vector3.new(c.width, 0.3, c.length)
			lane.CFrame = c.cf
			lane.Parent = workspace
			TweenService:Create(lane, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			task.delay(0.4, function()
				lane:Destroy()
			end)
			continue
		end
		if kind == "GuardBat" then
			burst(c.pos, Color3.fromRGB(170, 80, 255), 30, 15)
			continue
		end
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
	local fromKing = root
		and Vector3.new(
			root.Position.X - kingFace.Position.X,
			0,
			root.Position.Z - kingFace.Position.Z
		)
	if fromKing and fromKing.Magnitude < 60 then
		task.spawn(shake, kind == "Slam" and 1.4 or 0.6, 10)
	end
end)

remotes
	:WaitForChild("KingDone").OnClientEvent
	:Connect(function(kind: string, payouts: { [string]: number }, mvp: Player?)
		if kind == "results" then
			return
		end
		local mine = kind == "won" and payouts[tostring(player.UserId)] or nil
		if kind ~= "results" and not unlocked("King") and not mine then
			return
		end
		if kind == "won" then
			toast(
				"THE KING IS DEFEATED!",
				(mine and ("+" .. mine .. " 🍬 for helping! ") or "")
					.. (mvp and ("MVP: " .. mvp.DisplayName) or "")
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
			toast("THE PUMPKIN KING WAKES!", "Everyone bonk him!")
			play(Config.Sounds.Brew, 0.4, 1)
		elseif kind == "swell" then
			for _, who in Players:GetPlayers() do
				local humanoid = who.Character and who.Character:FindFirstChildOfClass("Humanoid")
				local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
				for _, track in animator and animator:GetPlayingAnimationTracks() or {} do
					local speed = track.Speed
					track:AdjustSpeed(Config.KingNight.finaleSpeed)
					task.delay(Config.KingNight.finale, function()
						if track.Parent then
							track:AdjustSpeed(speed)
						end
					end)
				end
			end
			toast("HE'S GOING TO BURST!")
			play(Config.Sounds.Brew, 0.5, 1)
		elseif kind == "phase2" then
			toast("SHIELD UP!", "Bonk the Lantern ghosts at the cauldrons!")
			play(Config.Sounds.Brew, 0.6, 1)
		elseif kind == "stun" then
			toast("HE'S STUNNED! SMASH HIM!", "Double damage!")
			play(Config.Sounds.Bonk, 0.5, 1)
			task.spawn(shake, 1, 8)
		elseif kind == "phase3" then
			toast("THE KING IS ANGRY!", "Faster attacks. Finish him!")
			play(Config.Sounds.Brew, 0.4, 1)
		elseif kind == "escaped" then
			toast(
				"THE KING ESCAPED",
				"Qualifiers receive 25% candy. Next King Night is on the clock."
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
	local folders: { [string]: Instance } = {}
	-- X/Z boxes per zone: { minX, maxX, minZ, maxZ, lane? }. On the lane map one box per zone
	-- covers its Z range (ZMin / ZMax attributes, else Config zMin / zMax; lane = true); without a
	-- range each Spawn part's footprint is its own box.
	local boxes: { [string]: { { number } } } = {}
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

	local function gateCost(zoneId)
		local before = Config.ZoneOrder[(table.find(Config.ZoneOrder, zoneId) or 1) - 1]
		local ok, d = pcall(function()
			return HttpService:JSONDecode(player:GetAttribute("ZoneProgress") or "{}")
		end)
		local q = ok and d.quests and before and d.quests[before]
		local complete = q
			and (q.smash or 0) >= Config.Progression.questSmashes
			and (q.steal or 0) >= Config.Progression.questSteals
			and q.own
		return math.floor(
			Config.Zones[zoneId].cost * (complete and (1 - Config.Progression.gateDiscount) or 1)
		),
			complete
	end
	local function refreshGates()
		local owned = ownedSet()
		for zoneId, folder in folders do
			local def = Config.Zones[zoneId]
			if not def or (def.cost or 0) <= 0 then
				continue
			end
			local open = ZoneView.has(zoneId, owned)
			local price, discount = gateCost(zoneId)
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
				if prompt then
					prompt.ActionText = "Unlock "
						.. def.title
						.. " ("
						.. short(price)
						.. " candy)"
						.. (discount and " -25%" or "")
				end
				if prompt and prompt.Enabled == open then
					prompt.Enabled = not open
				end
			end
			-- The server's sign has a yellow price pill ("🍬 1k"); owned zones show a green
			-- "UNLOCKED ✅" pill instead (local only).
			local sign = folder:FindFirstChild("GateSign")
			local gateGui = sign and sign:FindFirstChild("GateGui")
			if gateGui and gateGui:IsA("BillboardGui") then
				gateGui.Size = UDim2.fromOffset(open and 150 or 300, open and 60 or 120)
				gateGui.MaxDistance = 80
			end
			local costLabel = gateGui and gateGui:FindFirstChild("Cost", true) :: TextLabel?
			if costLabel then
				local text = open and "UNLOCKED"
					or (short(price) .. " candy" .. (discount and " -25%" or ""))
				if costLabel.Text ~= text then
					costLabel.Text = text
					local pillFrame = costLabel.Parent
					if pillFrame and pillFrame:IsA("Frame") then
						pillFrame.BackgroundColor3 = open and Color3.fromRGB(60, 200, 70)
							or Color3.fromRGB(255, 205, 40)
						pillFrame.Size = UDim2.fromOffset(open and 115 or 180, open and 21 or 42)
					end
				end
			end
		end
	end

	local function inBox(zoneId: string, pos: Vector3, margin: number): boolean
		for _, box in boxes[zoneId] or {} do
			-- Lane zones touch each other: entering needs no margin, leaving a small one.
			local m = box[5] and margin - 6 or margin
			if
				pos.X >= box[1] - m
				and pos.X <= box[2] + m
				and pos.Z >= box[3] - m
				and pos.Z <= box[4] + m
			then
				return true
			end
		end
		return false
	end

	-- Zone name line under the top objective banner (Steal an Egg zone label): the zone's emoji
	-- and name in its Config colour with a dark stroke, on a faint dark band; "SAFE ZONE" in the
	-- hub. It pops when it changes.
	local zoneLine = Instance.new("Frame")
	zoneLine.Name = "ZoneLine"
	zoneLine.AnchorPoint = Vector2.new(0.5, 0)
	zoneLine.Position = UDim2.fromScale(0.5, Config.UI.zoneY)
	zoneLine.Size = UDim2.fromScale(0.30, 0.035)
	zoneLine.BackgroundColor3 = Color3.new(0, 0, 0)
	zoneLine.BackgroundTransparency = 0.45
	zoneLine.BorderSizePixel = 0
	zoneLine.Parent = gui
	local band = Instance.new("UIGradient")
	band.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	band.Parent = zoneLine
	local zoneText = textLabel(zoneLine, "", Color3.new(1, 1, 1))
	zoneText.Size = UDim2.fromScale(1, 1)
	local zoneStroke = zoneText:FindFirstChildOfClass("UIStroke") :: UIStroke
	zoneStroke.Thickness = 3
	local zonePop = Instance.new("UIScale")
	zonePop.Parent = zoneLine
	local function showZone(zoneId: string?)
		local def = zoneId and Config.Zones[zoneId]
		zoneText.Text = def and ((def.emoji or "") .. " " .. def.title) or "🛡 Safe Zone"
		zoneText.TextColor3 = def and def.color or Color3.fromRGB(190, 255, 170)
		zonePop.Scale = 1.2
		TweenService:Create(zonePop, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 })
			:Play()
	end
	showZone(nil)

	-- Walking into a zone you have not unlocked still explains the gate in a toast.
	local function zoneBanner(zoneId: string)
		local def = Config.Zones[zoneId]
		if not def then
			return
		end
		showZone(zoneId)
		if not ZoneView.has(zoneId) then
			toast(
				string.upper(def.title),
				string.format(
					"🔒 Locked · unlock it at the gate for %s 🍬",
					short(def.cost or 0)
				)
			)
		end
	end

	player:GetAttributeChangedSignal("ZoneProgress"):Connect(refreshGates)
	local known = ownedSet()
	player:GetAttributeChangedSignal("Zones"):Connect(function()
		local now = ownedSet()
		if player:GetAttribute("Loaded") then
			for _, zoneId in Config.ZoneOrder do
				local def = Config.Zones[zoneId]
				if def and now[zoneId] and not known[zoneId] and (def.cost or 0) > 0 then
					toast(string.upper(def.title) .. " UNLOCKED!", "New pumpkins to smash inside!")
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
		local lastGateToast = 0
		for _, zoneId in Config.ZoneOrder do
			local folder = zones:WaitForChild(zoneId, 5)
			if not folder then
				continue
			end
			folders[zoneId] = folder
			local def = Config.Zones[zoneId]
			local wall = folder:FindFirstChild("GateWall")
			if def and (def.cost or 0) > 0 and wall and wall:IsA("BasePart") then
				wall.CanTouch = true
				wall.Touched:Connect(function(hit)
					local character = player.Character
					if
						not character
						or not hit:IsDescendantOf(character)
						or ZoneView.has(zoneId)
						or os.clock() - lastGateToast < 2.5
					then
						return
					end
					lastGateToast = os.clock()
					hint(
						string.format(
							'You need <font color="#FFD23C">🍬 %s</font> to enter the %s!',
							short(def.cost),
							def.title
						)
					)
					play(Config.Sounds.Bonk, 0.6, 0.6)
				end)
			end
			local list = {}
			local zMin = folder:GetAttribute("ZMin") or (def and def.zMin)
			local zMax = folder:GetAttribute("ZMax") or (def and def.zMax)
			if type(zMin) == "number" and type(zMax) == "number" then
				table.insert(list, {
					-math.huge,
					math.huge,
					math.min(zMin, zMax),
					math.max(zMin, zMax),
					true,
				})
			end
			for _, d in #list == 0 and folder:GetDescendants() or {} do
				if d:IsA("BasePart") and d.Name == "Spawn" then
					-- The part's own footprint (rotation-safe), so big strip parts work too.
					local cf, size = d.CFrame, d.Size / 2
					local hx = math.abs(cf.RightVector.X) * size.X
						+ math.abs(cf.UpVector.X) * size.Y
						+ math.abs(cf.LookVector.X) * size.Z
					local hz = math.abs(cf.RightVector.Z) * size.X
						+ math.abs(cf.UpVector.Z) * size.Y
						+ math.abs(cf.LookVector.Z) * size.Z
					local p = d.Position
					table.insert(list, { p.X - hx, p.X + hx, p.Z - hz, p.Z + hz })
				end
			end
			boxes[zoneId] = list
		end
		refreshGates()
		-- Entering a zone (within a few studs of one of its spawn spots) shows its banner; leaving
		-- needs a wider margin so walking along the edge does not repeat it.
		local inside: string? = nil
		while true do
			task.wait(0.5)
			refreshGates()
			local root = rootPart()
			if not root or not player:GetAttribute("Loaded") then
				continue
			end
			local here: string? = nil
			if inside and inBox(inside, root.Position, 12) then
				here = inside
			else
				for _, zoneId in Config.ZoneOrder do
					if inBox(zoneId, root.Position, 6) then
						here = zoneId
						break
					end
				end
			end
			if here ~= inside then
				inside = here
				if here then
					zoneBanner(here)
				else
					showZone(nil)
				end
			end
		end
	end)
end

-- Objective (Steal an Egg style): ONE verb for the current Witch's Order in a top-centre banner
-- ("Smash a Pumpkin!"), a tiny progress line under it, and a short trail of big red 3D arrows on
-- the ground from you toward the target, recomputed every 0.3 s. --------------------------------

do
	local bar = Instance.new("Frame")
	bar.Name = "Objective"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.fromScale(0.5, Config.UI.objectiveY)
	bar.Size = UDim2.fromScale(0.32, 0.065)
	-- A solid rounded dark plate, so world signs behind it never show through the text.
	bar.BackgroundColor3 = Color3.fromRGB(22, 14, 32)
	bar.BackgroundTransparency = 0.25
	bar.BorderSizePixel = 0
	bar.Parent = gui
	corner(bar, 16)
	local barStroke = stroke(bar, 2.5)
	barStroke.Color = Color3.fromRGB(10, 5, 16)
	barStroke.Transparency = 0.2
	local title = textLabel(bar, "", Color3.new(1, 1, 1))
	title.Position = UDim2.fromScale(0, 0.05)
	title.Size = UDim2.fromScale(1, 0.55)
	local titleStroke = title:FindFirstChildOfClass("UIStroke") :: UIStroke
	titleStroke.Thickness = 3
	titleStroke.Color = Color3.fromRGB(15, 8, 20)
	local progress = textLabel(bar, "", Color3.fromRGB(255, 225, 150))
	progress.Position = UDim2.fromScale(0, 0.65)
	progress.Size = UDim2.fromScale(1, 0.30)
	local questToggle = button(gui, "Zone quests", Color3.fromRGB(100, 70, 150))
	questToggle.Position = UDim2.fromScale(0.67, Config.UI.zoneY)
	questToggle.Size = UDim2.fromScale(0.11, 0.025)
	local questPanel = textLabel(gui, "", Color3.new(1, 1, 1))
	questPanel.BackgroundColor3 = Config.UI.body
	questPanel.BackgroundTransparency = 0.1
	questPanel.Position = UDim2.fromScale(0.67, Config.UI.zoneY + 0.03)
	questPanel.Size = UDim2.fromScale(0.20, 0.11)
	questPanel.Visible = false
	corner(questPanel, 10)
	questToggle.Activated:Connect(function()
		questPanel.Visible = not questPanel.Visible
	end)
	local function refreshQuests(root)
		questToggle.Visible = not anyPanelOpen()
		if anyPanelOpen() then
			questPanel.Visible = false
		end
		local ok, data =
			pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("ZoneProgress") or "{}")
		if not ok then
			return
		end
		for _, id in Config.ZoneOrder do
			local folder = garden.Zones:FindFirstChild(id)
			local z = Config.Zones[id]
			if
				folder
				and root.Position.Z >= (folder:GetAttribute("ZMin") or z.zMin)
				and root.Position.Z < (folder:GetAttribute("ZMax") or z.zMax)
			then
				local q = data.quests and data.quests[id] or {}
				questPanel.Text = string.format(
					"%s\n[%s] Smash %d/%d\n[%s] Steal  [%s] Own pet\nNext gate -%d%%",
					z.title,
					(q.smash or 0) >= Config.Progression.questSmashes and "x" or " ",
					q.smash or 0,
					Config.Progression.questSmashes,
					(q.steal or 0) >= Config.Progression.questSteals and "x" or " ",
					q.own and "x" or " ",
					Config.Progression.gateDiscount * 100
				)
				return
			end
		end
		questPanel.Text = "Enter a zone to see its quests"
	end
	local popScale = Instance.new("UIScale")
	popScale.Parent = bar

	local function setObjective(verb: string, sub: string)
		if title.Text ~= verb then
			title.Text = verb
			popScale.Scale = 1.18
			TweenService:Create(popScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 })
				:Play()
		end
		if progress.Text ~= sub then
			progress.Text = sub
		end
	end

	-- Red 3D ground arrows (Steal an Egg style). Each arrow lies flat, 0.4 studs over the ground:
	-- a neon arrowhead 2.2 studs wide (two WedgeParts) plus a shaft, the tip on the arrow's local
	-- -Z, over a slightly bigger dark-red copy. An arrow's frame is CFrame.lookAt(at, at + dir),
	-- whose -Z is dir (the flat unit vector from you to the target), so every tip points TOWARD
	-- the target. 7 arrows, 2.6 studs apart, starting 2.5 studs from you; a bright wave
	-- runs along them toward the target. The target gets a pulsing red ring on the ground and a
	-- bobbing ⬇. A smash re-targets at once (the popped pumpkin is skipped).
	-- Why only one arrow showed before: with the target behind the camera the chain ran from the
	-- player toward (and past) the camera, starting 5 studs out with 3-stud gaps, so arrow 1 sat
	-- right at the lens (the big red block at the bottom edge) and the rest were behind it. Now
	-- the chain starts 2.5 studs out with 2.6-stud gaps (several arrows sit between you and the
	-- camera even then), each arrow is 2.2 wide over a 1.22x dark-red underlay for contrast on
	-- the pink ground, lifted 0.4 studs, and nearly opaque (the wave only brightens).
	-- Arrow and ring constants live in one table (keeps the register count under 200).
	local AK = {
		RED = Color3.fromRGB(224, 24, 24),
		HOT = Color3.fromRGB(255, 125, 110),
		DEEP = Color3.fromRGB(92, 6, 12),
		ARROWS = 36,
		SPACING = 4.6,
		FIRST = 4,
		STOP = 8,
		LIFT = 0.5,
		THICK = 0.35,
		HEAD_W = 4,
		HEAD_L = 2.4,
		SHAFT_W = 1.5,
		SHAFT_L = 2,
		HEAD_BASE = 0.15,
		UNDER = 1.22,
		UNDER_DROP = 0.1,
		RING_R = 3.2,
	}
	-- Z centre of one arrow (tip at HEAD_BASE - HEAD_L, shaft end at HEAD_BASE + SHAFT_L): the
	-- underlay is the same arrow scaled about it.
	AK.MID = AK.HEAD_BASE + (AK.SHAFT_L - AK.HEAD_L) / 2
	local arrowFolder = Instance.new("Folder")
	arrowFolder.Name = "GuideArrows"
	arrowFolder.Parent = workspace
	local arrowParts: { BasePart } = {}
	local arrowOffsets: { CFrame } = {}
	local arrowOf: { number } = {}
	local arrowUnder: { boolean } = {}
	local function arrowPart(p: BasePart, size: Vector3, offset: CFrame, i: number, under: boolean)
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = under and Enum.Material.SmoothPlastic or Enum.Material.Neon
		p.Color = under and AK.DEEP or AK.RED
		p.Transparency = 1
		p.Parent = arrowFolder
		table.insert(arrowParts, p)
		table.insert(arrowOffsets, offset)
		table.insert(arrowOf, i)
		table.insert(arrowUnder, under)
	end
	-- One arrow scaled by s about (0, AK.MID) and dropped `drop` studs.
	local function buildArrow(i: number, s: number, drop: number, under: boolean)
		local function z(v: number): number
			return AK.MID + (v - AK.MID) * s
		end
		-- Shaft: behind the head (+Z), overlapping it a little.
		arrowPart(
			Instance.new("Part"),
			Vector3.new(AK.SHAFT_W * s, AK.THICK, AK.SHAFT_L * s),
			CFrame.new(0, -drop, z(AK.HEAD_BASE + AK.SHAFT_L / 2 - 0.05)),
			i,
			under
		)
		-- Head: two flat right triangles. A WedgePart's triangle (in its Y/Z plane) has its right
		-- angle at local (y -h/2, z +d/2), the tip at (y -h/2, z -d/2) and the far corner at
		-- (y +h/2, z +d/2). Wedge Y = side * arrow X, wedge Z = arrow Z (so wedge X = Y x Z is
		-- vertical): the right angle lands on (0, AK.HEAD_BASE), the tip on (0, AK.HEAD_BASE - AK.HEAD_L)
		-- (forward, -Z) and the far corner on (side * AK.HEAD_W / 2, AK.HEAD_BASE).
		for side = -1, 1, 2 do
			arrowPart(
				Instance.new("WedgePart"),
				Vector3.new(AK.THICK, AK.HEAD_W / 2 * s, AK.HEAD_L * s),
				CFrame.fromMatrix(
					Vector3.new(side * AK.HEAD_W / 4 * s, -drop, z(AK.HEAD_BASE - AK.HEAD_L / 2)),
					Vector3.new(0, -side, 0),
					Vector3.new(side, 0, 0),
					Vector3.zAxis
				),
				i,
				under
			)
		end
	end
	for i = 1, AK.ARROWS do
		buildArrow(i, AK.UNDER, AK.UNDER_DROP, true)
		buildArrow(i, 1, 0, false)
	end
	-- Ring on the ground around the target: a steady pulsing ring plus a ping that grows and
	-- fades. The holder part is turned 90 degrees on X so the adornments' Z axis is vertical.
	local ringHolder = Instance.new("Part")
	ringHolder.Name = "GuideRing"
	ringHolder.Anchored = true
	ringHolder.CanCollide = false
	ringHolder.CanQuery = false
	ringHolder.CanTouch = false
	ringHolder.Transparency = 1
	ringHolder.Size = Vector3.one
	ringHolder.Parent = arrowFolder
	local function ringAdornment(transparency: number): CylinderHandleAdornment
		local ring = Instance.new("CylinderHandleAdornment")
		ring.Adornee = ringHolder
		ring.Radius = AK.RING_R
		ring.InnerRadius = AK.RING_R - 0.5
		ring.Height = 0.2
		ring.Color3 = AK.RED
		ring.Transparency = transparency
		ring.Visible = false
		ring.Parent = ringHolder
		return ring
	end
	local ring = ringAdornment(0.05)
	local ping = ringAdornment(0.4)
	-- A bobbing red marker over the target itself.
	local marker = Instance.new("Part")
	marker.Name = "GuideTarget"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Transparency = 1
	marker.Size = Vector3.one
	marker.Parent = arrowFolder
	local markerGui = Instance.new("BillboardGui")
	markerGui.Size = UDim2.fromScale(6, 6)
	markerGui.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
	markerGui.AlwaysOnTop = true
	markerGui.LightInfluence = 0
	markerGui.Enabled = false
	markerGui.Parent = marker
	textLabel(markerGui, "⬇", AK.RED).Size = UDim2.fromScale(1, 1)
	local edgeGui = Instance.new("ScreenGui")
	edgeGui.Name = "GuideEdge"
	edgeGui.IgnoreGuiInset = true
	edgeGui.ResetOnSpawn = false
	edgeGui.Parent = player:WaitForChild("PlayerGui")
	local edge = textLabel(edgeGui, "▲", AK.RED)
	edge.AnchorPoint = Vector2.new(0.5, 0.5)
	edge.Size = UDim2.fromOffset(44, 44)
	edge.Visible = false
	local guide = { target = nil, home = false, green = Color3.fromRGB(50, 240, 70) }

	-- A pumpkin that just popped is skipped by zoneTarget for a moment (its part may still be
	-- there for a frame or two), and the loop below re-targets right away.
	local ignoreAt: Vector3? = nil
	local ignoreUntil = 0
	local retarget = false
	remotes:WaitForChild("WildPopped").OnClientEvent:Connect(function(at: Vector3)
		ignoreAt, ignoreUntil = at, os.clock() + 1.5
		retarget = true
	end)

	-- Arrow index -> where it lies (missing = hidden).
	local arrowBase: { [number]: CFrame } = {}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local function groundY(p: Vector3, fallback: number): number
		local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rayParams)
		return hit and hit.Position.Y or fallback
	end
	local function placeArrows(target: Vector3?)
		guide.target = target
		guide.home = (player:GetAttribute("Carry") or 0) > 0
			and (
				target ~= nil
				and myPatch() ~= nil
				and (target - myPatch().Soil.Position).Magnitude < 1
			)
		table.clear(arrowBase)
		local root = rootPart()
		local on = target ~= nil and root ~= nil
		markerGui.Enabled = on
		ring.Visible = on
		ping.Visible = on
		if not target or not root then
			return
		end
		local skip: { Instance } = { arrowFolder }
		for _, name in { "Wild", "Loose", "Ghosts" } do
			local f = garden:FindFirstChild(name)
			if f then
				table.insert(skip, f)
			end
		end
		-- Every character (and the tools and pumpkin stacks they hold), not only yours.
		for _, other in Players:GetPlayers() do
			if other.Character then
				table.insert(skip, other.Character)
			end
		end
		rayParams.FilterDescendantsInstances = skip
		marker.Position = target + Vector3.new(0, 2, 0)
		local floor = groundY(target, target.Y - 1.5)
		ringHolder.CFrame = CFrame.new(target.X, floor + AK.LIFT, target.Z)
			* CFrame.Angles(math.rad(90), 0, 0)
		local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
		local dist = flat.Magnitude
		if dist < AK.STOP then
			return
		end
		-- Flat unit vector from you to the target: each arrow's -Z (its tip) points along it. The
		-- chain is drawn even when the target is behind the camera: it then runs toward the lens
		-- and leads the eye round.
		local dir = flat.Unit
		local feet = groundY(root.Position, root.Position.Y - 3)
		-- The chain always reaches the target: spacing stretches when it is far away.
		local span = dist - AK.FIRST - AK.RING_R - 1
		local spacing = math.max(AK.SPACING, span / (AK.ARROWS - 1))
		for i = 1, AK.ARROWS do
			local d = AK.FIRST + (i - 1) * spacing
			-- Stop before the ring around the target.
			if d > dist - AK.RING_R - 1 then
				break
			end
			local p = root.Position + dir * d
			local y = groundY(p, feet)
			-- A hit on a roof, stall or plinth would float the arrow: stay near your feet.
			if y > feet + 2.5 then
				y = feet
			end
			local at = Vector3.new(p.X, y + AK.LIFT, p.Z)
			arrowBase[i] = CFrame.lookAt(at, at + dir)
		end
	end

	-- A bright wave runs along the arrows toward the target (the crest moves to higher i as time
	-- goes on); the ring pulses and pings; the marker bobs.
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local camera = workspace.CurrentCamera
		edge.Visible = false
		if guide.target and camera then
			local _, visible = camera:WorldToViewportPoint(guide.target)
			if not visible then
				local view = camera.ViewportSize
				local localPos = camera.CFrame:PointToObjectSpace(guide.target)
				local dir = Vector2.new(localPos.X, -localPos.Y)
				if localPos.Z > 0 then
					dir = Vector2.new(localPos.X, 0.6 * view.Y)
				end
				if dir.Magnitude < 0.01 then
					dir = Vector2.new(0, 1)
				end
				dir = dir.Unit
				local bounds = view / 2 - Vector2.new(32, 32)
				local distance = math.min(
					bounds.X / math.max(math.abs(dir.X), 0.001),
					bounds.Y / math.max(math.abs(dir.Y), 0.001)
				)
				local at = view / 2 + dir * distance
				edge.Position = UDim2.fromOffset(at.X, at.Y)
				edge.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
				edge.Visible = true
			end
		end
		local moved: { BasePart } = {}
		local frames: { CFrame } = {}
		for k, p in arrowParts do
			local i = arrowOf[k]
			local base = arrowBase[i]
			if base then
				local wave = math.max(0, math.sin(t * 7 - i * 0.9)) ^ 2
				if arrowUnder[k] then
					if p.Transparency ~= 0.45 then
						p.Transparency = 0.45
					end
				else
					p.Transparency = 0.3 + 0.15 * (1 - wave)
					p.Color = guide.home and guide.green:Lerp(Color3.new(1, 1, 1), wave * 0.3)
						or AK.RED:Lerp(AK.HOT, wave)
				end
				table.insert(moved, p)
				table.insert(frames, base * CFrame.new(0, 0.15 * wave, 0) * arrowOffsets[k])
			elseif p.Transparency ~= 1 then
				p.Transparency = 1
			end
		end
		if #moved > 0 then
			workspace:BulkMoveTo(moved, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end
		if markerGui.Enabled then
			markerGui.StudsOffsetWorldSpace = Vector3.new(0, 6 + math.sin(t * 4) * 0.7, 0)
		end
		if ring.Visible then
			local beat = 0.5 + 0.5 * math.sin(t * 6)
			ring.Radius = AK.RING_R + 0.25 * beat
			ring.InnerRadius = ring.Radius - 0.55
			ring.Transparency = 0.25 * (1 - beat)
			local f = (t * 0.9) % 1
			ping.Radius = AK.RING_R + 2.6 * f
			ping.InnerRadius = ping.Radius - 0.35
			ping.Transparency = 0.3 + 0.7 * f
		end
	end)

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

	local function nearestCauldron(from: Vector3): Vector3?
		local best, bestDist = nil, math.huge
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

	local function stallPosition(name: string): Vector3?
		local stall = market:FindFirstChild(name)
		return stall and (stall :: Model):GetPivot().Position
	end

	-- The nearest wild pumpkin in a zone you unlocked, else the nearest spawn spot of Zone1.
	local function zoneTarget(from: Vector3): Vector3?
		local best, bestDist = nil, math.huge
		local wild = garden:FindFirstChild("Wild")
		local zones = garden:FindFirstChild("Zones")
		local zone = zones and zones:FindFirstChild("Zone1")
		local skip = os.clock() < ignoreUntil and ignoreAt or nil
		for _, list in { wild and wild:GetChildren() or {}, zone and zone:GetChildren() or {} } do
			for _, part in list do
				local zoneId = part:GetAttribute("Zone")
				if
					part:IsA("BasePart")
					and (part.Name == "WildPumpkin" or part.Name == "Spawn")
					and (type(zoneId) ~= "string" or ZoneView.has(zoneId))
					and not (skip and (part.Position - skip).Magnitude < 1.5)
				then
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

	-- The nearest base of another player (steal orders, Blood Moon).
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

	local function nearestGhost(from: Vector3): Vector3?
		local folder = garden:FindFirstChild("Ghosts")
		local best, bestDist = nil, math.huge
		for _, ghost in folder and folder:GetChildren() or {} do
			local body = ghost:IsA("Model") and ghost.PrimaryPart
			if body then
				local d = (body.Position - from).Magnitude
				if d < bestDist then
					best, bestDist = body.Position, d
				end
			end
		end
		return best
	end

	-- A zone's Hoard nest (the server builds it as Zones.<zone>.Hoard.Nest).
	local function hoardSpot(zoneId: string): (Vector3?, boolean)
		local zones = garden:FindFirstChild("Zones")
		local zone = zones and zones:FindFirstChild(zoneId)
		local hoard = zone and zone:FindFirstChild("Hoard")
		local nest = hoard and hoard:FindFirstChild("Nest") :: BasePart?
		for _, p in hoard and hoard:GetChildren() or {} do
			if
				p:IsA("BasePart")
				and p.Name == "HoardPumpkin"
				and p:FindFirstChild("StealPrompt")
			then
				return p.Position, true
			end
		end
		return nest and nest.Position, false
	end

	-- Carrying toward your base: "Go to your Base!" until you stand on it, then "Place it!".
	local function goHome(root: BasePart, soil: BasePart): string
		local d =
			Vector3.new(root.Position.X - soil.Position.X, 0, root.Position.Z - soil.Position.Z)
		local reach = math.max(soil.Size.X, soil.Size.Z) / 2 + 6
		return d.Magnitude < reach and "Place in your pen!" or "Run to your pen!"
	end

	local function objective(data, root: BasePart, soil: BasePart): (string, string, Vector3?)
		local carry = player:GetAttribute("Carry") or 0
		local current = nil
		for _, order in data.list or {} do
			if not order.done then
				current = order
				break
			end
		end
		local kind = current and current.target or "zone"
		local stat = current and current.stat or "smash"
		if kind == "king" and not state:GetAttribute("KingActive") then
			current = nil
			kind = "zone"
			stat = "smash"
		end
		local sub = current
				and string.format(
					"%s  %s/%s",
					current.text,
					short(current.have or 0),
					short(current.need or 1)
				)
			or "Smash for candy"
		if state:GetAttribute("KingWarning") then
			return "JOIN KING NIGHT!", "Pet + loot!", kingFace.Position
		end
		local zone = zoneTarget(root.Position) or soil.Position
		local _, nestReady = hoardSpot("Zone1")
		if
			carry == 0
			and (kind == "hoard" or (kind == "place" and (player:GetAttribute("PenFilled") or 0) == 0))
			and not nestReady
		then
			return "Nest refilling...", "Smash for candy while you wait", zone
		end
		if carry > 0 then
			if
				player:GetAttribute("CarryPet")
				and (player:GetAttribute("PenFilled") or 0)
					>= (player:GetAttribute("PenSlots") or 6)
			then
				return "Pens full! Swap or Sell", "Choose in your pen", soil.Position
			end
			if not data.tutorial and kind == "witch" and unlocked("Sell") then
				return "Sell to the Witch!", sub, stallPosition("Sell")
			elseif not data.tutorial and kind == "cauldron" and unlocked("Brew") then
				return "Brew your pumpkin!", sub, nearestCauldron(root.Position)
			end
			return goHome(root, soil), "Place it in your pen!", soil.Position
		end
		if data.tutorial then
			local step = data.step or 1
			if step == 1 then
				return "Smash pumpkins!",
					"Collect " .. short(current and current.have or 0) .. "/30 🍬",
					zone
			end
			if step == 2 then
				return "Buy the Iron Scythe!", "150 🍬 at the Shop", stallPosition("Seeds")
			end
			if step == 3 then
				return "Steal a glowing pumpkin!", "Hold E for pets", hoardSpot("Zone1") or zone
			end
			if step == 4 then
				if (player:GetAttribute("PenFilled") or 0) == 0 then
					return "Steal a glowing pumpkin!",
						"Replace your lost pumpkin",
						hoardSpot("Zone1") or zone
				end
				return "Place it in your pen!", "Wait for it to hatch", soil.Position
			end
			return "Fill your pen "
				.. (player:GetAttribute("PenFilled") or 0)
				.. "/"
				.. (player:GetAttribute("PenSlots") or Config.Progression.baseSlots),
				"Steal another glowing pumpkin",
				hoardSpot("Zone1") or zone
		end
		if kind == "gate" then
			local id = ZoneView.nextLocked()
			local def = id and Config.Zones[id]
			if def then
				return "Unlock the " .. def.title .. "!",
					"Costs " .. short(def.cost) .. " 🍬",
					ZoneView.gate(id) or soil.Position
			end
		elseif kind == "tools" or kind == "seeds" then
			return "Buy a better Scythe!", sub, stallPosition("Seeds")
		elseif kind == "upgrades" then
			return "Upgrade your Base!", sub, stallPosition("Upgrades")
		elseif kind == "hoard" or kind == "place" then
			return "Steal a glowing pumpkin!", sub, hoardSpot("Zone1") or zone
		elseif kind == "witch" then
			return "Sell to the Witch!", sub .. " · pick up a pet", soil.Position
		elseif kind == "cauldron" then
			return "Brew your pumpkin!", sub .. " · pick up a pet", soil.Position
		elseif kind == "steal" then
			return "Steal a Pumpkin!", sub, otherBase(root.Position) or soil.Position
		elseif
			kind == "king"
			and state:GetAttribute("KingActive")
			and (state:GetAttribute("KingHp") or 0) > 0
		then
			return "Hit the Pumpkin King!", sub, kingFace.Position
		elseif stat == "bonkGhost" then
			return "Bonk the Ghosts!", sub, nearestGhost(root.Position) or soil.Position
		elseif stat == "stopThief" then
			return "Guard your Base!", sub, soil.Position
		elseif stat == "rescue" then
			return "Save your Pumpkins!", sub, soil.Position
		elseif stat == "income" then
			return "Earn more candy!", sub, soil.Position
		elseif stat == "lock" then
			return "Lock your Base!", sub, soil.Position
		end
		return "Smash pumpkins!", sub, zone
	end

	task.spawn(function()
		while true do
			-- Every 0.3 s, or right away after a smash.
			local waited = 0
			while waited < 0.3 and not retarget do
				waited += task.wait(0.05)
			end
			retarget = false
			local root = rootPart()
			local patch = myPatch()
			local soil = patch and patch:FindFirstChild("Soil") :: BasePart?
			local data = ordersData
			if not root or not soil or not data or not player:GetAttribute("Loaded") then
				setObjective("Loading your farm...", "")
				placeArrows(nil)
				continue
			end
			refreshQuests(root)
			local verb, sub, target = objective(data, root, soil)
			setObjective(verb, sub)
			placeArrows(target)
		end
	end)
end

-- Steal drama: while you carry a stolen pumpkin a dark-red RUN!! pill, a pulsing red screen-edge
-- vignette and a red Drop button show. A robbed owner gets a toast, a red flash and sees the
-- thief glowing red. --------------------------------------------------------------------------

do
	local dropRemote = remotes:WaitForChild("Drop")
	local run = Instance.new("Frame")
	run.Name = "Run"
	run.AnchorPoint = Vector2.new(0.5, 0)
	run.Position = UDim2.fromScale(0.44, Config.UI.actionY)
	run.Size = UDim2.fromScale(0.10, 0.055)
	run.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
	run.Visible = false
	run.Parent = gui
	corner(run, 12)
	stroke(run, 2.5).Color = Color3.new(0, 0, 0)
	local runLabel = textLabel(run, "RUN!!", Color3.new(1, 1, 1), Enum.Font.LuckiestGuy)
	runLabel.Position = UDim2.fromOffset(8, 5)
	runLabel.Size = UDim2.new(1, -16, 1, -10)
	local runScale = Instance.new("UIScale")
	runScale.Parent = run

	local drop = pill("🗑 Drop", Color3.fromRGB(225, 40, 40), 0)
	drop.Parent = gui
	drop.AnchorPoint = Vector2.new(0.5, 0)
	drop.Position = UDim2.fromScale(0.56, Config.UI.actionY)
	drop.Size = UDim2.fromScale(0.10, 0.055)
	drop.Visible = false
	drop.Activated:Connect(function()
		dropRemote:FireServer()
	end)

	-- Vignette and flash live in their own unscaled ScreenGui so they always cover the screen.
	local alarmGui = Instance.new("ScreenGui")
	alarmGui.Name = "PatchAlarm"
	alarmGui.ResetOnSpawn = false
	alarmGui.IgnoreGuiInset = true
	alarmGui.DisplayOrder = 3
	alarmGui.Parent = player:WaitForChild("PlayerGui")
	local vignette = Instance.new("Frame")
	vignette.BackgroundTransparency = 1
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.Visible = false
	vignette.Parent = alarmGui
	local edges: { Frame } = {}
	for _, e in
		{
			{ Vector2.new(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.18), 90 },
			{ Vector2.new(0, 1), UDim2.fromScale(0, 1), UDim2.fromScale(1, 0.18), -90 },
			{ Vector2.new(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(0.13, 1), 0 },
			{ Vector2.new(1, 0), UDim2.fromScale(1, 0), UDim2.fromScale(0.13, 1), 180 },
		}
	do
		local edge = Instance.new("Frame")
		edge.AnchorPoint = e[1]
		edge.Position = e[2]
		edge.Size = e[3]
		edge.BackgroundColor3 = Color3.fromRGB(230, 20, 30)
		edge.BorderSizePixel = 0
		edge.Parent = vignette
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = e[4]
		gradient.Transparency = NumberSequence.new(0, 1)
		gradient.Parent = edge
		table.insert(edges, edge)
	end
	local flash = Instance.new("Frame")
	flash.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Size = UDim2.fromScale(1, 1)
	flash.Parent = alarmGui

	-- A Hoard pumpkin fresh from a nest (CarryHoard) gets the same drama: the guardian is coming.
	local function refresh()
		local stolen = (player:GetAttribute("CarryStolen") or 0) > 0
			or (player:GetAttribute("CarryHoard") or 0) > 0
		run.Visible = stolen
		drop.Visible = stolen
		vignette.Visible = stolen
	end
	player:GetAttributeChangedSignal("CarryStolen"):Connect(refresh)
	player:GetAttributeChangedSignal("CarryHoard"):Connect(refresh)
	refresh()

	RunService.RenderStepped:Connect(function()
		if not vignette.Visible then
			return
		end
		local wave = 0.5 + 0.5 * math.sin(os.clock() * 6)
		for _, edge in edges do
			edge.BackgroundTransparency = 0.1 + 0.4 * (1 - wave)
		end
		runScale.Scale = 1 + 0.07 * wave
	end)

	remotes:WaitForChild("StealAlarm").OnClientEvent:Connect(function(kind: string, a, b, c)
		if kind == "stole" then
			hint('You stole a <font color="#FF3B3B">PUMPKIN</font>!')
			play(Config.Sounds.Coin, 1.4, 0.8)
			task.spawn(shake, 0.5, 6)
		elseif kind == "robbed" then
			hint('⚠ Someone is <font color="#FF3B3B">stealing</font> from your base!')
			hint(
				string.format(
					"%s took your %s pumpkin (+%s 🍬). Bonk them to get it back!",
					tostring(a),
					tostring(b),
					short(tonumber(c) or 0)
				)
			)
			play(Config.Sounds.Bonk, 0.5, 1)
			for k = 0, 1 do
				task.delay(k * 0.45, function()
					flash.BackgroundTransparency = 0.45
					TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
						:Play()
				end)
			end
		end
	end)

	-- Thieves carrying your pumpkins glow red (StealingFrom = ",ownerId,...").
	local glows: { [Player]: Highlight } = {}
	task.spawn(function()
		while true do
			task.wait(0.3)
			local mine = "," .. player.UserId .. ","
			for _, who in Players:GetPlayers() do
				local from = who:GetAttribute("StealingFrom")
				local character = who.Character
				local want = who ~= player
					and character ~= nil
					and type(from) == "string"
					and string.find(from, mine, 1, true) ~= nil
				local glow = glows[who]
				if want and (not glow or glow.Parent ~= character) then
					if glow then
						glow:Destroy()
					end
					glow = Instance.new("Highlight")
					glow.FillColor = Color3.fromRGB(255, 30, 30)
					glow.FillTransparency = 0.45
					glow.OutlineColor = Color3.fromRGB(255, 90, 90)
					glow.OutlineTransparency = 0
					glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					glow.Parent = character
					glows[who] = glow
				elseif not want and glow then
					glow:Destroy()
					glows[who] = nil
				end
			end
			for who, glow in glows do
				if not who.Parent then
					glow:Destroy()
					glows[who] = nil
				end
			end
		end
	end)
end

-- Income pops: every second each pet / pumpkin on YOUR base pops a green #44FF2F "+X" with a dark
-- stroke (its candy per second from the server's "Rate" attribute, x2 in a Spooky Hour). The
-- BillboardGui pops in, floats up 3 studs over 0.8 s (its offset is tweened) and fades. A short
-- pop sound plays only every 5th tick. ------------------------------------------------------------

do
	local playerGui = player:WaitForChild("PlayerGui")
	local function incomePop(p: BasePart, rate: number)
		if not p.Parent then
			return
		end
		local y = p.Size.Y / 2 + 2
		local bb = Instance.new("BillboardGui")
		bb.Name = "IncomePop"
		bb.Adornee = p
		bb.Size = UDim2.fromOffset(120, 34)
		bb.StudsOffsetWorldSpace = Vector3.new((math.random() - 0.5) * 0.8, y, 0)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.MaxDistance = 90
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = MONEY
		label.Text = "+" .. rateShort(rate)
		label.Parent = bb
		local outline = Instance.new("UIStroke")
		outline.Thickness = 3
		outline.Color = Color3.fromRGB(10, 40, 10)
		outline.Parent = label
		local pop = Instance.new("UIScale")
		pop.Scale = 0.3
		pop.Parent = label
		bb.Parent = playerGui
		TweenService:Create(pop, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		TweenService:Create(
			bb,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ StudsOffsetWorldSpace = bb.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }
		):Play()
		local fade =
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.5)
		TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(outline, fade, { Transparency = 1 }):Play()
		task.delay(0.85, function()
			bb:Destroy()
		end)
	end
	task.spawn(function()
		local ticks = 0
		while true do
			task.wait(1)
			local patch = myPatch()
			local root = rootPart()
			if not patch or not root then
				continue
			end
			local mult = spookyOn() and (Config.SpookyMult or 2) or 1
			local any = false
			for _, plot in patch:GetChildren() do
				local p = plot.Name == "Plot" and plot:FindFirstChild("Pumpkin")
				if p and p:IsA("BasePart") then
					local rate = p:GetAttribute("Rate")
					if
						type(rate) == "number"
						and rate > 0
						and (p.Position - root.Position).Magnitude < 90
					then
						any = true
						task.delay(math.random() * 0.25, incomePop, p, rate * mult)
					end
				end
			end
			if any then
				ticks += 1
				if ticks % 5 == 0 then
					play(Config.Sounds.Pick, 2.4, 0.25)
				end
			end
		end
	end)
end

remotes:WaitForChild("OrderDone").OnClientEvent:Connect(function(text: string, reward: string)
	toast("✅ " .. text .. "!", reward)
	play(Config.Sounds.Coin, 1.2, 0.9)
	play(Config.Sounds.Brew, 1.6, 0.5)
end)

-- Daily: visible only while the server says a reward can be claimed.
do
	function confetti(parentGui: ScreenGui?)
		local colors = {
			Color3.fromRGB(255, 80, 120),
			Color3.fromRGB(255, 210, 60),
			Color3.fromRGB(90, 220, 255),
			Color3.fromRGB(120, 235, 90),
			Color3.fromRGB(190, 120, 255),
			Color3.fromRGB(255, 150, 50),
		}
		for i = 1, 70 do
			local bit = Instance.new("Frame")
			bit.Name = "Confetti"
			bit.BorderSizePixel = 0
			bit.AnchorPoint = Vector2.new(0.5, 0.5)
			bit.BackgroundColor3 = colors[(i - 1) % #colors + 1]
			bit.Size = UDim2.fromOffset(math.random(10, 16), math.random(16, 26))
			bit.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.1, 0.55)
			bit.Rotation = math.random(0, 360)
			bit.ZIndex = 50
			bit.Parent = parentGui or gui
			local x = 0.5 + (math.random() - 0.5) * 0.9
			local y = 0.08 + math.random() * 0.4
			local up = 0.35 + math.random() * 0.2
			local fall = 1.2 + math.random() * 0.8
			local out = TweenService:Create(
				bit,
				TweenInfo.new(up, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.fromScale(x, y),
					Rotation = bit.Rotation + math.random(-180, 180),
				}
			)
			out:Play()
			out.Completed:Once(function()
				TweenService
					:Create(
						bit,
						TweenInfo.new(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{
							Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.2, 1.08),
							Rotation = bit.Rotation + math.random(-540, 540),
						}
					)
					:Play()
			end)
			task.delay(up + fall + 0.05, function()
				bit:Destroy()
			end)
		end
	end

	local frame, list = panel("Daily Reward")
	local daily = pill("Daily", BUY, 4)
	local reward = textLabel(list, "Claim today's candy gift!", Color3.new(1, 1, 1))
	reward.Size = UDim2.new(1, 0, 0, 60)
	local claim = button(list, "Claim daily gift", BUY)
	claim.Size = UDim2.new(1, 0, 0, 60)
	claim.LayoutOrder = 2
	local busy = false
	local function refresh()
		daily.Visible = player:GetAttribute("DailyClaimable") == true
		claim.Visible = daily.Visible
	end
	daily.Activated:Connect(function()
		for _, f in panelFrames do
			f.Visible = false
		end
		frame.Visible = true
	end)
	claim.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		local ok, claimed = pcall(function()
			return remotes:WaitForChild("ClaimDaily"):InvokeServer()
		end)
		busy = false
		if not ok or not claimed then
			hint("Daily gift is not ready")
		end
		refresh()
	end)
	remotes:WaitForChild("Daily").OnClientEvent:Connect(function(streak, candy)
		reward.Text = string.format("Day %d: +%s candy!", streak, short(candy))
		hint(reward.Text)
		confetti(gui)
		play(Config.Sounds.Coin, 0.9, 1)
	end)
	player:GetAttributeChangedSignal("DailyClaimable"):Connect(refresh)
	refresh()
end

-- Movement: faster by default, sprint on Shift or the RUN button, slower per carried pumpkin. --

local ContextActionService = game:GetService("ContextActionService")
local sprinting = false
local dizzyUntil = 0
local function setSprint(on: boolean)
	if sprinting == on then
		return
	end
	sprinting = on
	remotes:WaitForChild("Sprint"):FireServer(on)
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
end, false, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle("Sprint", "RUN")
ContextActionService:SetPosition("Sprint", UDim2.fromScale(0.64, 0.52))

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local speed = Config.walkSpeed(player:GetAttribute("Up_Boots"))
		* (sprinting and Config.Movement.sprintMult or 1)
	speed = math.max(
		Config.MinCarrySpeed,
		speed - (player:GetAttribute("Carry") or 0) * Config.SlowPerPumpkin
	)
	if os.clock() < dizzyUntil then
		speed = 6
	end
	if workspace:GetServerTimeNow() < (player:GetAttribute("GuardEffectUntil") or 0) then
		speed *= player:GetAttribute("WalkSpeedMultiplier") or 1
	end
	if player:GetAttribute("FightActive") then
		speed = 0
	end
	if humanoid.WalkSpeed ~= speed then
		humanoid.WalkSpeed = speed
		-- The yellow HUD line shows the walk speed.
		refreshCarry()
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
		if dizzy > 0 then
			floatText(root.Position + Vector3.new(0, 4, 0), "DIZZY!", Color3.fromRGB(255, 230, 120))
		end
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

local function circlePart(pos: Vector3, radius: number, warn: number, color: Color3?)
	local disc = Instance.new("Part")
	disc.Shape = Enum.PartType.Cylinder
	disc.Material = Enum.Material.Neon
	disc.Color = color or Color3.fromRGB(255, 60, 50)
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
	ring.Color3 = color or Color3.fromRGB(255, 70, 50)
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

remotes:WaitForChild("Telegraph").OnClientEvent:Connect(
	function(
		kind: string,
		circles: { any },
		warn: number,
		sound: number?,
		lifetime: number?,
		pitch: number?
	)
		if sound then
			play(sound, pitch or 1, Config.GuardTwists.volume)
		end
		for _, c in circles do
			if c.cf then
				local lane = Instance.new("Part")
				lane.Anchored = true
				lane.CanCollide = false
				lane.CanQuery = false
				lane.CanTouch = false
				lane.Material = Enum.Material.Neon
				lane.Color = Color3.fromRGB(255, 60, 50)
				lane.Transparency = 0.65
				lane.Size = Vector3.new(c.width, 0.2, c.length)
				lane.CFrame = c.cf
				lane.Parent = workspace
				task.delay(warn, function()
					if kind == "Guard:Boulder" then
						local rock = Instance.new("Part")
						rock.Shape = Enum.PartType.Ball
						rock.Size = Vector3.one * c.width
						rock.Anchored = true
						rock.CanCollide = false
						rock.Color = Color3.fromRGB(80, 45, 30)
						rock.Position = c.origin + Vector3.yAxis * c.width / 2
						rock.Parent = workspace
						local cfg = Config.GuardTwists.Zone7
						TweenService:Create(
							rock,
							TweenInfo.new(cfg.length / cfg.speed, Enum.EasingStyle.Linear),
							{ Position = rock.Position + c.direction * cfg.length }
						):Play()
						task.delay(cfg.length / cfg.speed, function()
							rock:Destroy()
						end)
					end
					lane:Destroy()
				end)
			else
				circlePart(
					c.pos,
					c.radius,
					warn,
					kind == "Guard:Bat" and Color3.fromRGB(170, 80, 255)
						or kind == "Guard:Sticky" and Color3.fromRGB(255, 110, 199)
						or nil
				)
				if kind == "Guard:Sticky" then
					local puddle = Instance.new("Part")
					puddle.Shape = Enum.PartType.Cylinder
					puddle.Anchored = true
					puddle.CanCollide = false
					puddle.CanQuery = false
					puddle.CanTouch = false
					puddle.Material = Enum.Material.Neon
					puddle.Color = Color3.fromRGB(255, 110, 199)
					puddle.Transparency = 0.55
					puddle.Size = Vector3.new(0.2, c.radius * 2, c.radius * 2)
					puddle.CFrame = CFrame.new(c.pos) * CFrame.Angles(0, 0, math.pi / 2)
					puddle.Parent = workspace
					task.delay(warn + (lifetime or 0), function()
						puddle:Destroy()
					end)
				elseif kind == "Guard:Bat" then
					local ghost = Instance.new("Part")
					ghost.Anchored = true
					ghost.CanCollide = false
					ghost.CanQuery = false
					ghost.Size = Vector3.new(3, 6, 3)
					ghost.Color = Color3.fromRGB(180, 80, 255)
					ghost.Transparency = 0.65
					ghost.CFrame = CFrame.new(c.pos + Vector3.yAxis * 3)
					ghost.Parent = workspace
					task.delay(warn, function()
						burst(ghost.Position, ghost.Color, 30, 15)
						ghost:Destroy()
					end)
				end
			end
			if kind == "Volley" and not c.cf then
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
	end
)

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
		if
			phase == "BloodMoon"
			and (state:GetAttribute("KingStunned") or (state:GetAttribute("KingPhase") or 1) >= 3)
		then
			if not enrageGlow then
				local h = Instance.new("Highlight")
				h.FillColor = Color3.fromRGB(255, 30, 30)
				h.FillTransparency = 0.55
				h.OutlineColor = Color3.fromRGB(255, 120, 60)
				h.Parent = kingFace
				enrageGlow = h
			end
			if enrageGlow then
				enrageGlow.FillColor = state:GetAttribute("KingStunned")
						and Color3.fromRGB(255, 240, 120)
					or Color3.fromRGB(255, 30, 30)
			end
		elseif enrageGlow then
			enrageGlow:Destroy()
			enrageGlow = nil
		end
	end
	for _, attr in { "Phase", "KingShield", "KingPhase", "KingStunned" } do
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

	-- Single King HP readout.
	local wide = Instance.new("Frame")
	wide.Name = "KingTopHp"
	wide.AnchorPoint = Vector2.new(0.5, 0)
	wide.Position = UDim2.fromScale(0.5, Config.UI.bossY)
	wide.Size = UDim2.fromScale(0.46, 0.04)
	wide.BackgroundColor3 = Color3.fromRGB(42, 10, 18)
	wide.Parent = gui
	corner(wide, 8)
	local wideFill = Instance.new("Frame")
	wideFill.Size = UDim2.fromScale(1, 1)
	wideFill.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
	wideFill.Parent = wide
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = KING_FILL
	fillGradient.Parent = wideFill
	local cap = textLabel(wide, utf8.char(9819), Color3.fromRGB(242, 193, 46))
	cap.Position = UDim2.fromScale(-0.06, -0.2)
	cap.Size = UDim2.fromScale(0.07, 1.4)
	cap.ZIndex = 4
	corner(wideFill, 8)
	local wideText = textLabel(wide, "", Color3.new(1, 1, 1))
	wideText.Size = UDim2.fromScale(1, 1)
	wideText.ZIndex = 3
	for _, fraction in { 0.33, 0.66 } do
		local tick = Instance.new("Frame")
		tick.Size = UDim2.new(0, 3, 1, 0)
		tick.Position = UDim2.fromScale(fraction, 0)
		tick.BackgroundColor3 = Color3.new(1, 1, 1)
		tick.ZIndex = 2
		tick.Parent = wide
	end
	local function refreshHpBar()
		local on = state:GetAttribute("Phase") == "BloodMoon"
			and state:GetAttribute("KingHp") ~= nil
		wide.Visible = on
		if not on then
			return
		end
		local hp = state:GetAttribute("KingHp") or 0
		local maxHp = math.max(state:GetAttribute("KingMaxHp") or 1, 1)
		wideFill.Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1)
		wideText.Text = string.format("PUMPKIN KING %s/%s", short(hp), short(maxHp))
		fillGradient.Color = KING_FILL
	end
	for _, attr in { "Phase", "KingHp", "KingMaxHp", "KingShield", "KingShieldMax", "KingStunned" } do
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
	topLabel.Size = UDim2.fromOffset(260, 165)
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

-- Hoards: the thief's side of a guardian chase. The server sends "grab" (you took a Hoard
-- pumpkin: shake, RUN!!), "bonk" (the guardian caught you), "safe" (it gave up) and "deliver" (you
-- placed it: confetti; the server also sends a reveal card). -----------------------------------

do
	local drama = { token = 0, camera = nil, saved = nil, fight = false, ends = 0 }
	local screen = Instance.new("ScreenGui")
	screen.Name = "PatchStealBeat"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 9
	screen.Parent = player:WaitForChild("PlayerGui")
	local top = Instance.new("Frame")
	top.BackgroundColor3 = Color3.new(0, 0, 0)
	top.BorderSizePixel = 0
	top.Size = UDim2.fromScale(1, 0.12)
	top.Visible = false
	top.Parent = screen
	local bottom = top:Clone()
	bottom.AnchorPoint = Vector2.new(0, 1)
	bottom.Position = UDim2.fromScale(0, 1)
	bottom.Parent = screen
	local skip = button(screen, "Skip", PURPLE)
	skip.AnchorPoint = Vector2.new(1, 1)
	skip.Position = UDim2.new(1, -24, 1, -24)
	skip.Size = UDim2.fromOffset(120, 52)
	skip.Visible = false
	local fight = Instance.new("Frame")
	fight.Name = "FightBar"
	fight.AnchorPoint = Vector2.new(0.5, 0.5)
	fight.Position = UDim2.fromScale(0.5, Config.UI.fightY)
	fight.Size = UDim2.fromScale(0.30, 0.035)
	fight.BackgroundTransparency = 1
	fight.Visible = false
	fight.Parent = screen
	corner(fight, 16)
	stroke(fight, 4).Color = ORANGE
	local scale = Instance.new("UIScale")
	scale.Scale = uiScale.Scale
	scale.Parent = fight
	local title = textLabel(fight, "TAP!", BUY, Enum.Font.LuckiestGuy)
	title.Position = UDim2.fromScale(0, -1.7)
	title.Size = UDim2.fromScale(1, 1.4)
	local track = Instance.new("Frame")
	track.Position = UDim2.fromScale(0, 0)
	track.Size = UDim2.fromScale(1, 1)
	track.BackgroundColor3 = DARK
	track.Parent = fight
	corner(track, 10)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = BUY
	fill.Parent = track
	corner(fill, 10)
	local tap = button(fight, "TAP TO FIGHT!", ORANGE)
	tap.Position = UDim2.fromScale(0, -1.7)
	tap.Size = UDim2.fromScale(1, 2.7)
	tap.Visible = false
	local remote = remotes:WaitForChild("Fight")
	local wakeRemote = remotes:WaitForChild("GuardianWake")
	local function restore()
		drama.token += 1
		if drama.camera and drama.saved then
			drama.camera.CameraType = drama.saved.kind
			if
				drama.saved.subject
				and drama.saved.subject.Parent
				and not (drama.saved.subject:IsA("Humanoid") and drama.saved.subject.Health <= 0)
			then
				drama.camera.CameraSubject = drama.saved.subject
			else
				drama.camera.CameraType = Enum.CameraType.Custom
				drama.camera.CameraSubject = player.Character
					and player.Character:FindFirstChildOfClass("Humanoid")
			end
			drama.camera.CFrame = drama.saved.cf
			drama.camera.FieldOfView = drama.saved.fov
		end
		drama.camera, drama.saved = nil, nil
		top.Visible, bottom.Visible, skip.Visible, fight.Visible = false, false, false, false
		drama.fight = false
		Center.interrupt(false)
	end
	local function finishWake()
		restore()
		wakeRemote:FireServer()
		hint('<font color="#FF3B3B">RUN!!</font> Get it to your pen!')
	end
	skip.Activated:Connect(finishWake)
	wakeRemote.OnClientEvent:Connect(function(guard: Model, full: boolean)
		restore()
		if not full then
			task.spawn(shake, 0.8, 20)
			hint("RUN!! Get it to your pen!")
			return
		end
		local camera = workspace.CurrentCamera
		if not camera or not guard or not guard.Parent then
			return
		end
		Center.interrupt(true)
		drama.camera = camera
		drama.saved = {
			kind = camera.CameraType,
			subject = camera.CameraSubject,
			cf = camera.CFrame,
			fov = camera.FieldOfView,
		}
		local cf, size = guard:GetBoundingBox()
		local eye = guard:FindFirstChild("Eye", true)
		local face = eye and eye:IsA("BasePart") and eye.Position
			or cf.Position + Vector3.new(0, size.Y * 0.25, 0)
		local root = guard.PrimaryPart
		local forward = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame =
			CFrame.lookAt(face + forward * math.max(7, size.Y * 0.6) + Vector3.new(0, 1, 0), face)
		top.Visible, bottom.Visible, skip.Visible = true, true, true
		play(Config.Sounds.Roar, Config.GuardianRoarPitch, 0.8)
		local token = drama.token
		task.delay(Config.GuardianWake, function()
			if token == drama.token then
				finishWake()
			end
		end)
	end)
	tap.Activated:Connect(function()
		if drama.fight then
			remote:FireServer()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if
			drama.fight
			and (
				input.UserInputType == Enum.UserInputType.Touch
				or (
					not processed
					and (
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.KeyCode == Enum.KeyCode.E
						or input.KeyCode == Enum.KeyCode.Space
					)
				)
			)
		then
			remote:FireServer()
		end
	end)
	remote.OnClientEvent:Connect(function(kind: string, value: number?)
		if kind == "start" then
			restore()
			drama.fight = true
			drama.ends = os.clock() + (value or Config.Fight.seconds)
			Center.interrupt(true)
			fight.Visible = true
			scale.Scale = uiScale.Scale
			fill.Size = UDim2.fromScale(0, 1)
			title.Text = "TAP!"
		elseif kind == "fill" and drama.fight then
			fill.Size = UDim2.fromScale(math.clamp(value or 0, 0, 1), 1)
		elseif kind == "win" or kind == "lose" or kind == "cancel" then
			restore()
			if kind == "win" then
				hint("Guard stunned! RUN!!")
				play(Config.Sounds.Bonk, 1.4, 0.8)
			end
		end
	end)
	RunService.RenderStepped:Connect(function()
		if drama.fight then
			title.Text = "TAP!"
			title.TextTransparency = 0.15 + 0.15 * math.sin(os.clock() * 12)
			local elapsed = 1 - math.clamp((drama.ends - os.clock()) / Config.Fight.seconds, 0, 1)
			fill.BackgroundColor3 = fill.Size.X.Scale >= elapsed and BUY
				or Color3.fromRGB(219, 39, 48)
		end
	end)
	player.CharacterAdded:Connect(restore)
	player:GetAttributeChangedSignal("Carry"):Connect(function()
		if (player:GetAttribute("Carry") or 0) == 0 and drama.camera then
			restore()
		end
	end)
end

remotes:WaitForChild("Hoard").OnClientEvent:Connect(function(kind: string, seedId: string?)
	local seed = seedById[seedId or ""]
	local hoardSeed = seedById[Config.Zones.Zone1.pets[1]]
	local name = string.upper((seed or hoardSeed or { name = "Hoard" }).name)
	if kind == "grab" then
		hint("Glowing pumpkin grabbed!")
		play(Config.Sounds.Coin, 1.4, 0.8)
		-- GuardianWake owns the first-zone camera and repeat shake.
	elseif kind == "bonk" then
		hint('<font color="#FF3B3B">BONKED!</font> The guardian took the Hoard pumpkin back.')
		local root = rootPart()
		if root then
			floatText(
				root.Position + Vector3.new(0, 5, 0),
				"BONKED!",
				Color3.fromRGB(255, 70, 60),
				true
			)
		end
		play(Config.Sounds.Bonk, 0.6, 1)
		task.spawn(shake, 1.6, 12)
	elseif kind == "safe" then
		hint("You got away! The guardian gives up. Place it on your base!")
	elseif kind == "deliver" then
		hint(string.format('You stole a <font color="#FFD23C">%s PUMPKIN</font>!', name))
		confetti()
		play(Config.Sounds.Coin, 0.8, 1)
		play(Config.Sounds.Brew, 1.6, 0.6)
	end
end)

-- Hatching (Steal an Egg, about 4 s from the first rock to the card). World part, for every
-- client near it: over the last 1.6 s before a placed pumpkin hatches (the replicated CarveAt) it
-- rocks +-15 degrees about its base in 10 cycles, each shorter than the last, glowing whiter; it
-- keeps rocking at full speed until the server hatches it (the server checks once a second).
-- Then Carved: a white flash and it bursts into 6-10 shell slabs in its colour that fly out, lie
-- on the ground about 2.5 s and fade. Owner part (near the pumpkin and not running with loot): a
-- pink/white screen flash, a small shake, a camera punch (FOV 70 -> 85 -> 70, Back easing), then
-- the reveal card (blur behind, the pet turning, rarity / name / green +X/s, confetti for Rare
-- and up; a click skips it after 1 s). A far-away owner gets a toast, and the card for a new type.
do
	local SHAKE_TIME = 1.6
	local LATE = 1.5
	local shaking: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any

	local function rock(p: BasePart, carveAt: number)
		shaking[p] = true
		local base = p.CFrame
		local h = p.Size.Y / 2
		local dur = math.max(0.4, carveAt - workspace:GetServerTimeNow())
		-- 10 cycles, each 6 % shorter than the one before (weights 1 .. 0.46, sum 7.3).
		local ends: { number } = {}
		local acc = 0
		for i = 1, 10 do
			acc += dur * (1 - 0.06 * (i - 1)) / 7.3
			ends[i] = acc
		end
		local last = ends[10] - ends[9]
		local glow = Instance.new("Highlight")
		glow.FillColor = Color3.new(1, 1, 1)
		glow.FillTransparency = 1
		glow.OutlineColor = Color3.new(1, 1, 1)
		glow.OutlineTransparency = 1
		glow.DepthMode = Enum.HighlightDepthMode.Occluded
		glow.Parent = p
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			local hatched = p:GetAttribute("CarveAt") == nil or p:GetAttribute("Jack") == true
			if not p.Parent or hatched or t > dur + LATE then
				conn:Disconnect()
				glow:Destroy()
				if p.Parent and not hatched then
					p.CFrame = base
				end
				return
			end
			local f, amp
			if t < dur then
				local i = 1
				while i < 10 and t > ends[i] do
					i += 1
				end
				local start = i == 1 and 0 or ends[i - 1]
				f = (t - start) / (ends[i] - start)
				amp = math.rad(15) * (0.6 + 0.04 * i)
			else
				-- Waiting for the server: the fastest cycle, full swing.
				f = ((t - dur) / last) % 1
				amp = math.rad(15)
			end
			p.CFrame = base
				* CFrame.new(0, -h, 0)
				* CFrame.Angles(0, 0, math.sin(f * math.pi * 2) * amp)
				* CFrame.new(0, h, 0)
			glow.FillTransparency = 1 - 0.6 * math.clamp((t / dur - 0.5) * 2, 0, 1)
		end)
	end

	task.spawn(function()
		while true do
			task.wait(0.1)
			local camera = workspace.CurrentCamera
			local now = workspace:GetServerTimeNow()
			for _, patch in patchFolder:GetChildren() do
				for _, plot in patch:GetChildren() do
					local p = plot.Name == "Plot" and plot:FindFirstChild("Pumpkin")
					local carveAt = p and p:GetAttribute("CarveAt")
					if
						p
						and p:IsA("BasePart")
						and type(carveAt) == "number"
						and not shaking[p]
						and camera
						and carveAt - now <= SHAKE_TIME
						and carveAt - now > 0.05
						and (p.Position - camera.CFrame.Position).Magnitude < 150
					then
						task.spawn(rock, p, carveAt + Config.Plots.readySeconds)
					end
				end
			end
		end
	end)

	-- 6-10 shell slabs fly out of the pumpkin's base, land, lie about 2.5 s and fade (local parts).
	local function slabs(p: BasePart, color: Color3)
		local baseSize = p:GetAttribute("BaseSize")
		local size = if typeof(baseSize) == "Vector3" then baseSize else p.Size
		local w = math.clamp(size.X * 0.42, 0.8, 2.4)
		local bottom = p.Position - Vector3.new(0, p.Size.Y / 2, 0)
		local n = math.random(6, 10)
		for i = 1, n do
			local slab = Instance.new("Part")
			slab.Name = "ShellSlab"
			slab.Size = Vector3.new(
				w * (0.8 + math.random() * 0.4),
				w * 0.22,
				w * (0.7 + math.random() * 0.4)
			)
			slab.Color = color:Lerp(Color3.fromRGB(211, 82, 8), math.random() * 0.35)
			slab.Material = Enum.Material.SmoothPlastic
			slab.CanCollide = true
			slab.CanQuery = false
			slab.CanTouch = false
			local a = (i / n) * math.pi * 2 + math.random() * 0.4
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			slab.CFrame = CFrame.new(bottom + Vector3.new(0, size.Y * 0.5, 0) + out * w * 0.4)
				* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
			slab.Parent = workspace
			slab.AssemblyLinearVelocity = out * (10 + math.random() * 8)
				+ Vector3.new(0, 18 + math.random() * 10, 0)
			slab.AssemblyAngularVelocity = Vector3.new(
				(math.random() - 0.5) * 24,
				(math.random() - 0.5) * 24,
				(math.random() - 0.5) * 24
			)
			task.delay(2.5 + math.random() * 0.2, function()
				if slab.Parent then
					TweenService:Create(slab, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				end
				task.wait(0.32)
				slab:Destroy()
			end)
		end
	end

	-- The owner's screen flash: white turning pink while it fades (0.5 s).
	local hatchGui = Instance.new("ScreenGui")
	hatchGui.Name = "PatchHatch"
	hatchGui.ResetOnSpawn = false
	hatchGui.IgnoreGuiInset = true
	hatchGui.DisplayOrder = 7
	hatchGui.Parent = player:WaitForChild("PlayerGui")
	local screenFlash = Instance.new("Frame")
	screenFlash.Name = "Flash"
	screenFlash.BackgroundColor3 = Color3.new(1, 1, 1)
	screenFlash.BackgroundTransparency = 1
	screenFlash.BorderSizePixel = 0
	screenFlash.Size = UDim2.fromScale(1, 1)
	screenFlash.Parent = hatchGui

	local function ownerHatch()
		screenFlash.BackgroundColor3 = Color3.new(1, 1, 1)
		screenFlash.BackgroundTransparency = 0.1
		TweenService:Create(
			screenFlash,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 150, 215) }
		):Play()
		task.spawn(shake, 0.5, 8)
		local camera = workspace.CurrentCamera
		if camera then
			local out = TweenService:Create(
				camera,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ FieldOfView = 85 }
			)
			out:Play()
			out.Completed:Once(function()
				TweenService:Create(
					camera,
					TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ FieldOfView = sprinting and Config.SprintFov or 70 }
				):Play()
			end)
		end
	end

	remotes
		:WaitForChild("Carved").OnClientEvent
		:Connect(function(p: BasePart?, ownerId: number?, pet: string?, isNew: boolean?)
			local camera = workspace.CurrentCamera
			if not p or not p.Parent or not camera then
				return
			end
			local seed = seedById[p:GetAttribute("Seed") or ""]
			if (p.Position - camera.CFrame.Position).Magnitude <= 150 then
				local flash = Instance.new("Highlight")
				flash.FillColor = Color3.new(1, 1, 1)
				flash.FillTransparency = 0
				flash.OutlineColor = Color3.new(1, 1, 1)
				flash.OutlineTransparency = 0
				flash.DepthMode = Enum.HighlightDepthMode.Occluded
				flash.Parent = p
				TweenService:Create(
					flash,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ FillTransparency = 1, OutlineTransparency = 1 }
				):Play()
				task.delay(0.55, function()
					flash:Destroy()
				end)
				burst(p.Position + Vector3.new(0, 1, 0), Color3.new(1, 1, 1), 24, 16, SPARKLE, 1)
				burst(p.Position, Color3.fromRGB(255, 240, 220), 10, 10, nil, 1.4)
				slabs(p, seed and seedColor(seed) or ORANGE)
				play(Config.Sounds.Bonk, 1.5, 0.6)
			end
			if ownerId ~= player.UserId or not seed then
				return
			end
			local def = pet and Config.Pets and Config.Pets[pet]
			local name = def and def.display or (seed.name .. " Jack")
			local rate = tonumber(p:GetAttribute("Rate")) or 0
			local mutation = p:GetAttribute("Mutation")
			local root = rootPart()
			local running = (player:GetAttribute("CarryStolen") or 0) > 0
				or (player:GetAttribute("CarryHoard") or 0) > 0
			if root and not running and (p.Position - root.Position).Magnitude < 90 then
				ownerHatch()
				task.delay(
					0.35,
					queueReveal,
					seed.id,
					mutation,
					isNew == true,
					rate,
					"jack",
					pet,
					p:GetAttribute("WeightKg")
				)
			else
				hint(
					string.format(
						'🐣 Your pumpkin hatched: <font color="#44FF2F">%s</font>!',
						name
					)
				)
				if isNew then
					queueReveal(
						seed.id,
						mutation,
						true,
						rate,
						"jack",
						pet,
						p:GetAttribute("WeightKg")
					)
				end
			end
		end)
end

-- Guardian tags: the cyan "Z z Z" bobs slowly while it sleeps, the red "!" jumps while it is awake
-- (local only, so nothing replicates every frame).
do
	local tags: { [BillboardGui]: Vector3 } = setmetatable({}, { __mode = "k" }) :: any
	local function watch(d: Instance)
		if d:IsA("BillboardGui") and (d.Name == "SleepTag" or d.Name == "AlertTag") then
			if not tags[d] then
				tags[d] = d.StudsOffsetWorldSpace
			end
		end
	end
	task.spawn(function()
		local zones = garden:WaitForChild("Zones", 15)
		if not zones then
			return
		end
		zones.DescendantAdded:Connect(watch)
		for _, d in zones:GetDescendants() do
			watch(d)
		end
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for bb, base in tags do
			if bb.Enabled and bb.Parent then
				local y = bb.Name == "SleepTag" and math.sin(t * 2) * 0.8
					or math.abs(math.sin(t * 7)) * 0.7
				bb.StudsOffsetWorldSpace = base + Vector3.new(0, y, 0)
			end
		end
	end)
end

-- Pets render a random walk through their whole pen; the server validates the same waypoints.
do
	local pets = {}
	task.spawn(function()
		while true do
			local list = {}
			for _, pen in patchFolder:GetChildren() do
				for _, plot in pen:GetChildren() do
					local p = plot.Name == "Plot" and plot:FindFirstChild("Pumpkin")
					if
						p
						and p:IsA("BasePart")
						and p:GetAttribute("Jack")
						and p:GetAttribute("Placed")
					then
						table.insert(list, p)
					end
				end
			end
			pets = list
			task.wait(0.5)
		end
	end)
	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		for _, p in pets do
			if not p.Parent or not p:GetAttribute("Placed") or not p:GetAttribute("JackHome") then
				continue
			end
			if p:GetAttribute("Stashed") then
				continue
			end
			local from = p:GetAttribute("RoamFrom")
			local goal = p:GetAttribute("RoamTo")
			local at = Config.roamPoint(p, now)
			local moving = now < (p:GetAttribute("RoamEnd") or 0)
			local direction = from and goal and (goal - from) * Vector3.new(1, 0, 1) or Vector3.zero
			local rotation = (p:GetAttribute("JackHome") :: CFrame).Rotation
			if direction.Magnitude > 0.01 then
				rotation = CFrame.lookAt(Vector3.zero, direction).Rotation
			end
			local bob = moving and math.abs(math.sin(now * 9)) * Config.PetRoam.bob
				or math.abs(math.sin(now * 3)) * 0.06
			p.CFrame = CFrame.new(at + Vector3.yAxis * bob) * rotation
			local anchor = p:FindFirstChild("PetPromptAnchor")
			if anchor then
				anchor.Position = Vector3.zero
			end
		end
	end)
end
-- Carry look (Steal an Egg): every pumpkin carried over a head floats inside a soft rainbow halo,
-- a see-through Neon ball (local, anchored, following the pumpkin each frame) whose colour cycles
-- slowly. RUN!!, Drop and the red vignette stay as they are. -----------------------------------
do
	local halos: { [BasePart]: Part } = {}
	local folder = Instance.new("Folder")
	folder.Name = "CarryHalos"
	folder.Parent = workspace
	task.spawn(function()
		while true do
			task.wait(0.25)
			local want: { [BasePart]: boolean } = {}
			for _, who in Players:GetPlayers() do
				local character = who.Character
				for _, child in character and character:GetChildren() or {} do
					if child:IsA("BasePart") and child:GetAttribute("Seed") ~= nil then
						want[child] = true
					end
				end
			end
			for p, halo in halos do
				if not want[p] then
					halo:Destroy()
					halos[p] = nil
				end
			end
			for p in want do
				if not halos[p] then
					local halo = Instance.new("Part")
					halo.Name = "Halo"
					halo.Shape = Enum.PartType.Ball
					halo.Material = Enum.Material.Neon
					halo.Transparency = 0.8
					halo.Anchored = true
					halo.CanCollide = false
					halo.CanQuery = false
					halo.CanTouch = false
					halo.CastShadow = false
					halo.Parent = folder
					halos[p] = halo
				end
			end
		end
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local k = 0
		for p, halo in halos do
			k += 1
			local s = math.max(p.Size.X, p.Size.Y, p.Size.Z) * 1.45
			if halo.Size.X ~= s then
				halo.Size = Vector3.one * s
			end
			halo.CFrame = CFrame.new(p.Position)
			halo.Color = Color3.fromHSV((t * 0.12 + k * 0.17) % 1, 0.45, 1)
		end
	end)
end

-- Glow. Nest (Hoard) mystery pumpkins pulse: a PointLight 1.5 <-> 3 every 1.2 s (the model's own
-- LookGlow is switched off locally so it is the only light). Rare pets (Rare and up, on a plot)
-- get a Highlight outline in their rarity colour (the 20 nearest: Roblox draws at most 31) and a
-- sparkle emitter (LightEmission 1, LightInfluence 0). ------------------------------------------
do
	local pulsed: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
	local function pulse(d: Instance)
		if not d:IsA("BasePart") or d.Name ~= "HoardPumpkin" or pulsed[d] then
			return
		end
		pulsed[d] = true
		local own = d:FindFirstChild("LookGlow", true)
		if own and own:IsA("PointLight") then
			own.Enabled = false
		end
		local light = Instance.new("PointLight")
		light.Name = "NestPulse"
		light.Color = Color3.fromRGB(255, 170, 70)
		light.Range = 11
		light.Shadows = false
		light.Brightness = 1.5
		light.Parent = d
		TweenService:Create(
			light,
			TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Brightness = 3 }
		):Play()
	end
	task.spawn(function()
		local zones = garden:WaitForChild("Zones", 15)
		if not zones then
			return
		end
		zones.DescendantAdded:Connect(pulse)
		for _, d in zones:GetDescendants() do
			pulse(d)
		end
	end)

	local function rarityColor(order: number): Color3
		for _, r in Config.Rarities do
			if order <= r.upTo then
				return r.color
			end
		end
		return Config.Rarities[#Config.Rarities].color
	end
	local MAX_OUTLINES = 20
	type Glow = { outline: Highlight, sparkle: ParticleEmitter }
	local glows: { [BasePart]: Glow } = {}
	task.spawn(function()
		while true do
			task.wait(0.6)
			local camera = workspace.CurrentCamera
			local eye = camera and camera.CFrame.Position or Vector3.zero
			local list: { BasePart } = {}
			for _, patch in patchFolder:GetChildren() do
				for _, plot in patch:GetChildren() do
					local p = plot.Name == "Plot" and plot:FindFirstChild("Pumpkin")
					local seed = p and seedById[p:GetAttribute("Seed") or ""]
					if
						p
						and p:IsA("BasePart")
						and seed
						and seed.order >= 3
						and p:GetAttribute("Pet") ~= nil
						and p:GetAttribute("Placed") == true
					then
						table.insert(list, p)
					end
				end
			end
			local keep: { [BasePart]: boolean } = {}
			for _, p in list do
				keep[p] = true
			end
			for p, g in glows do
				if not keep[p] or not p.Parent then
					g.outline:Destroy()
					g.sparkle:Destroy()
					glows[p] = nil
				end
			end
			table.sort(list, function(a, b)
				return (a.Position - eye).Magnitude < (b.Position - eye).Magnitude
			end)
			for i, p in list do
				local g = glows[p]
				if not g then
					local color = rarityColor(seedById[p:GetAttribute("Seed")].order)
					local outline = Instance.new("Highlight")
					outline.Name = "RareGlow"
					outline.FillTransparency = 1
					outline.OutlineColor = color
					outline.OutlineTransparency = 0
					outline.DepthMode = Enum.HighlightDepthMode.Occluded
					outline.Adornee = p:FindFirstChild("PetLook") or p
					outline.Parent = p
					local sparkle = Instance.new("ParticleEmitter")
					sparkle.Name = "RareSparkle"
					sparkle.Texture = SPARKLE
					sparkle.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.25))
					sparkle.LightEmission = 1
					sparkle.LightInfluence = 0
					sparkle.Size = NumberSequence.new(0.45, 0)
					sparkle.Lifetime = NumberRange.new(0.6, 1)
					sparkle.Rate = 4
					sparkle.Speed = NumberRange.new(0.5, 1.5)
					sparkle.SpreadAngle = Vector2.new(180, 180)
					sparkle.Parent = p
					g = { outline = outline, sparkle = sparkle }
					glows[p] = g
				end
				local on = i <= MAX_OUTLINES
				if g.outline.Enabled ~= on then
					g.outline.Enabled = on
				end
			end
		end
	end)
end

-- Zone stamps and quests extend the existing Index book, leaving two HUD pills.
do
	local rows = {}
	for i, id in Config.ZoneOrder do
		local row = textLabel(indexList, "", Color3.fromRGB(255, 214, 80))
		row.LayoutOrder = -20 + i
		row.Size = UDim2.new(1, -10, 0, 70)
		row.TextWrapped = true
		row.TextScaled = true
		rows[id] = row
	end
	local function refresh()
		local ok, d = pcall(function()
			return HttpService:JSONDecode(player:GetAttribute("ZoneProgress") or "{}")
		end)
		if not ok then
			return
		end
		for _, id in Config.ZoneOrder do
			local zone = Config.Zones[id]
			local q = d.quests and d.quests[id] or {}
			local pets = zone.pets
			local stamp = d.stamps and d.stamps[id]
			rows[id].Visible = id == "Zone1" or player:GetAttribute("Zone_" .. id) == true
			-- Zones are published as a comma list, so keep the same source as the gates.
			rows[id].Visible = id == "Zone1"
				or string.find(
						"," .. (player:GetAttribute("Zones") or "") .. ",",
						"," .. id .. ",",
						1,
						true
					)
					~= nil
			rows[id].Text = string.format(
				"%s %s: %s + %s | %s\n[%s] Smash %d/%d  [%s] Steal  [%s] Own pet",
				stamp and "STAMP +10%" or "[ ]",
				zone.title,
				Config.Pets[seedById[pets[1]].pet].display,
				Config.Pets[seedById[pets[2]].pet].display,
				zone.unlock,
				(q.smash or 0) >= Config.Progression.questSmashes and "x" or " ",
				q.smash or 0,
				Config.Progression.questSmashes,
				(q.steal or 0) >= Config.Progression.questSteals and "x" or " ",
				q.own and "x" or " "
			)
		end
	end
	for _, attr in { "ZoneProgress", "Zones" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	refresh()
end
-- King join, results and status icons use the existing event/Center queue.
do
	local join = button(gui, "JOIN RAID", Color3.fromRGB(220, 50, 60))
	join.AnchorPoint = Vector2.new(1, 1)
	join.Position = UDim2.fromScale(0.68, 0.58)
	join.Size = UDim2.fromScale(0.13, 0.05)
	join.Activated:Connect(function()
		remotes:WaitForChild("KingJoin"):FireServer()
	end)
	local function refreshJoin()
		join.Visible = state:GetAttribute("KingWarning") == true
			or state:GetAttribute("Phase") == "BloodMoon"
	end
	for _, attr in { "KingWarning", "Phase" } do
		state:GetAttributeChangedSignal(attr):Connect(refreshJoin)
	end
	refreshJoin()
	local icons = {}
	local function icon(who)
		local character = who.Character
		local head = character and character:FindFirstChild("Head")
		local text = who:GetAttribute("IdleShield") and "Zzz" or who:GetAttribute("GuardEffectIcon")
		if icons[who] and (not head or not text or icons[who].Adornee ~= head) then
			icons[who]:Destroy()
			icons[who] = nil
		end
		if head and text then
			local bb = icons[who]
			if not bb then
				bb = Instance.new("BillboardGui")
				bb.Name = "StatusIcon"
				bb.Size = UDim2.fromOffset(90, 32)
				bb.StudsOffsetWorldSpace = Vector3.yAxis * Config.GuardTwists.iconHeight
				bb.AlwaysOnTop = true
				bb.Adornee = head
				bb.Parent = head
				local label = textLabel(bb, "", Color3.fromRGB(200, 230, 255))
				label.Size = UDim2.fromScale(1, 1)
				icons[who] = bb
			end
			bb:FindFirstChildOfClass("TextLabel").Text = text
		end
	end
	local function hook(who)
		for _, attr in { "IdleShield", "GuardEffectIcon" } do
			who:GetAttributeChangedSignal(attr):Connect(function()
				icon(who)
			end)
		end
		who.CharacterAdded:Connect(function()
			task.delay(1, function()
				icon(who)
			end)
		end)
		icon(who)
	end
	for _, who in Players:GetPlayers() do
		hook(who)
	end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(function(who)
		if icons[who] then
			icons[who]:Destroy()
			icons[who] = nil
		end
	end)
	remotes:WaitForChild("KingDone").OnClientEvent:Connect(function(kind, data)
		if kind ~= "results" then
			return
		end
		task.spawn(function()
			Center.acquire()
			local resultCard
			local ok, err = pcall(function()
				resultCard = Instance.new("Frame")
				resultCard.Name = "KingResults"
				resultCard.AnchorPoint = Vector2.new(0.5, 0.5)
				resultCard.Position = UDim2.fromScale(0.5, 0.5)
				resultCard.Size = UDim2.fromScale(0.62, 0.42)
				resultCard.BackgroundColor3 = DARK
				resultCard.Parent = gui
				corner(resultCard, 18)
				Center.register(resultCard)
				local title = textLabel(
					resultCard,
					data.won and "KING NIGHT COMPLETE!" or "King escaped!",
					Color3.fromRGB(255, 214, 80)
				)
				title.Position = UDim2.fromScale(0.05, 0.06)
				title.Size = UDim2.fromScale(0.9, 0.16)
				local loot = {}
				for _, id in data.crates or {} do
					table.insert(loot, seedById[id].name)
				end
				local body = textLabel(
					resultCard,
					string.format(
						"Damage %s | Rank #%d | %d hits\n+%s candy\n%s\nPODIUM\n1. %s  2. %s  3. %s",
						short(data.damage),
						data.rank,
						data.hits,
						short(data.candy),
						#loot > 0 and table.concat(loot, " + ")
							or data.qualified and "25% consolation | no crate"
							or "15 hits or 3% damage needed",
						data.podium[1] or "-",
						data.podium[2] or "-",
						data.podium[3] or "-"
					),
					Color3.new(1, 1, 1)
				)
				body.Position = UDim2.fromScale(0.05, 0.25)
				body.Size = UDim2.fromScale(0.9, 0.65)
				body.TextWrapped = true
				task.wait(Config.KingNight.resultsSeconds)
			end)
			if resultCard then
				resultCard:Destroy()
			end
			Center.release()
			if not ok then
				warn("[Patch] King results:", err)
			end
		end)
	end)
end

-- Local house marker follows pen ownership, including release/reclaim.
do
	local function watch(patch)
		local soil = patch:FindFirstChild("Soil")
		if not soil then
			return
		end
		local bb = Instance.new("BillboardGui")
		bb.Name = "MyPenHouse"
		bb.Adornee = soil
		bb.Size = UDim2.fromOffset(70, 60)
		bb.StudsOffsetWorldSpace = Vector3.new(4, Config.Plots.markerHeight, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 300
		bb.Parent = gui
		local icon = textLabel(bb, utf8.char(8962), Color3.new(1, 1, 1))
		icon.Size = UDim2.fromScale(1, 1)
		local function refresh()
			bb.Enabled = patch:GetAttribute("Owner") == player.UserId
		end
		patch:GetAttributeChangedSignal("Owner"):Connect(refresh)
		patch.Destroying:Connect(function()
			bb:Destroy()
		end)
		refresh()
	end
	for _, patch in patchFolder:GetChildren() do
		watch(patch)
	end
	patchFolder.ChildAdded:Connect(watch)
end

-- Free travel menu and tier-two dash. Only action names leave this client.
do
	local travel, list = panel("Teleport")
	local teleport = pill("Teleport", Color3.fromRGB(135, 90, 225), 3)
	local pending = false
	teleport.Activated:Connect(function()
		local open = not travel.Visible
		for _, f in panelFrames do
			f.Visible = false
		end
		travel.Visible = open
	end)
	for i, target in { "My Pen", "Zone Gate", "Shop" } do
		local b = button(list, target, BUY)
		b.Size = UDim2.new(1, 0, 0, 48)
		b.LayoutOrder = i
		b.Activated:Connect(function()
			if pending then
				return
			end
			pending = true
			local ok, success, message = pcall(function()
				return remotes:WaitForChild("Teleport"):InvokeServer(target)
			end)
			pending = false
			if ok and success then
				travel.Visible = false
			else
				hint(message or "Travel unavailable")
			end
		end)
	end
	local index = button(list, "Open Index", Color3.fromRGB(40, 190, 235))
	index.Size = UDim2.new(1, 0, 0, 42)
	index.LayoutOrder = 4
	index.Activated:Connect(function()
		travel.Visible = false
		indexPanel.Visible = true
	end)
	local daily = button(list, "Daily gift", BUY)
	daily.Size = UDim2.new(1, 0, 0, 42)
	daily.LayoutOrder = 5
	daily.Activated:Connect(function()
		travel.Visible = false
		for _, f in panelFrames do
			if f:GetAttribute("PanelTitle") == "Daily Reward" then
				f.Visible = true
			end
		end
	end)
	local run = button(list, "Toggle sprint", Color3.fromRGB(255, 210, 65))
	run.Size = UDim2.new(1, 0, 0, 42)
	run.LayoutOrder = 6
	run.Activated:Connect(function()
		setSprint(not sprinting)
		travel.Visible = false
	end)
	local dashPending = false
	local function dash(_, inputState)
		if
			inputState ~= Enum.UserInputState.Begin
			or UserInputService:GetFocusedTextBox()
			or anyPanelOpen()
			or dashPending
		then
			return Enum.ContextActionResult.Pass
		end
		if (player:GetAttribute("Tool") or Config.StartTool) == Config.StartTool then
			return Enum.ContextActionResult.Pass
		end
		dashPending = true
		task.spawn(function()
			local ok, success, message = pcall(function()
				return remotes:WaitForChild("Dash"):InvokeServer()
			end)
			dashPending = false
			if not ok or not success then
				hint(message or "Dash unavailable")
			end
		end)
		return Enum.ContextActionResult.Sink
	end
	ContextActionService:BindAction("ScytheDash", dash, true, Enum.KeyCode.Q)
	ContextActionService:SetTitle("ScytheDash", "DASH")
	ContextActionService:SetPosition(
		"ScytheDash",
		UDim2.fromScale(Config.Dash.mobile.X, Config.Dash.mobile.Y)
	)
	RunService.Heartbeat:Connect(function()
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		local unlockedDash = (player:GetAttribute("Tool") or Config.StartTool) ~= Config.StartTool
		local dashButton = ContextActionService:GetButton("ScytheDash")
		if dashButton then
			dashButton.Visible = touch
				and unlockedDash
				and not anyPanelOpen()
				and (player:GetAttribute("CarryHoard") or 0) == 0
				and (player:GetAttribute("CarryStolen") or 0) == 0
				and not player:GetAttribute("FightActive")
				and not state:GetAttribute("PurgeEnds")
			local remaining = math.max(
				0,
				math.ceil((player:GetAttribute("DashReadyAt") or 0) - workspace:GetServerTimeNow())
			)
			ContextActionService:SetTitle(
				"ScytheDash",
				remaining > 0 and tostring(remaining) or "DASH"
			)
		end
		-- Index remains accessible inside the travel menu when dash takes the third mobile slot.
		indexButton.Visible = not (
			touch and (unlockedDash or (player:GetAttribute("Carry") or 0) > 0)
		)
		for _, b in leftBar:GetChildren() do
			if b:IsA("TextButton") and b.LayoutOrder == 4 then
				b.Visible = not touch and player:GetAttribute("DailyClaimable") == true
			end
		end
		daily.Visible = player:GetAttribute("DailyClaimable") == true
		local remaining = math.max(
			0,
			math.ceil((player:GetAttribute("TeleportReadyAt") or 0) - workspace:GetServerTimeNow())
		)
		teleport.Text = touch and "" or remaining > 0 and ("Teleport " .. remaining) or "Teleport"
	end)
end
