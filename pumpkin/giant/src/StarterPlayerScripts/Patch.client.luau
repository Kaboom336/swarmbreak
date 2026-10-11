local Services: { [string]: any } = {}
local Palette: { [string]: any } = {}
local UI: { [string]: any } = { icons = {}, views = 0 }
-- Client side of Steal a Pumpkin: which base prompts you see (Place / Pick up / Steal / Lock),
-- lighting for day / midnight / Blood Moon, scythe swings, hit and pop effects, HUD (candy,
-- income, carry), the Shop (Scythes / Upgrades / Robux tabs), Index, Haunt, Witch's Orders.
-- Systems behind an unlock gate (Config.Unlocks, "Unlock_<Name>" attributes) stay hidden.
Services.HttpService = game:GetService("HttpService")
Services.Lighting = game:GetService("Lighting")
Services.MarketplaceService = game:GetService("MarketplaceService")
Services.Players = game:GetService("Players")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.RunService = game:GetService("RunService")
Services.SoundService = game:GetService("SoundService")
Services.TextService = game:GetService("TextService")
Services.TweenService = game:GetService("TweenService")
Services.UserInputService = game:GetService("UserInputService")
function Palette.mobile()
	return Services.UserInputService.TouchEnabled
		and (
			not Services.UserInputService.KeyboardEnabled
			or workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X <= 900
		)
end

local Config = require(Services.ReplicatedStorage:WaitForChild("PatchConfig"))
local function fontFace(role: string, weight: string?, style: string?): Font
	-- A role is an Enum.Font name, or { family = "rbxasset://fonts/families/X.json", weight = "Heavy" }
	-- whose weight overrides the caller's.
	local spec = Config.Fonts[role]
	if type(spec) == "table" then
		return Font.new(
			spec.family,
			Enum.FontWeight[spec.weight or weight or "Regular"],
			Enum.FontStyle[style or "Normal"]
		)
	end
	local base = Font.fromEnum(Enum.Font[spec])
	return Font.new(
		base.Family,
		Enum.FontWeight[weight or "Regular"],
		Enum.FontStyle[style or "Normal"]
	)
end
local remotes = Services.ReplicatedStorage:WaitForChild("PatchRemotes")
local state = Services.ReplicatedStorage:WaitForChild("PatchState")
local player = Services.Players.LocalPlayer

local garden = workspace:WaitForChild("Garden")
local patchFolder = garden:WaitForChild("Patches")
local cauldronFolder = garden:WaitForChild("Cauldrons")
local market = garden:WaitForChild("Market")
local kingFace = market:WaitForChild("KingFace") :: BasePart
local giantJack = market:WaitForChild("GiantJack") :: BasePart
local meterRing = market:WaitForChild("MeterRing") :: BasePart

Palette.SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
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
-- Prebuilt pools keep farming allocation bounded.
local FarmFX = { freezeUntil = 0, impactAt = 0, step = 1, held = false }
do
	FarmFX.steps = setmetatable({}, { __mode = "k" })
	local groups, pools = {}, {}
	for name, volume in Config.SoundMix do
		local group = Services.SoundService:FindFirstChild("Patch" .. name)
			or Instance.new("SoundGroup")
		group.Name, group.Volume, group.Parent = "Patch" .. name, volume, Services.SoundService
		groups[name] = group
	end
	FarmFX.groups = groups
	for cue, id in Config.Sounds do
		if id ~= 0 and not pools[id] and not string.find(cue, "Music") then
			local pool = { next = 0, voices = {} }
			pools[id] = pool
			for i = 1, 6 do
				local sound = Instance.new("Sound")
				sound.Name = "Patch" .. cue .. i
				sound.SoundId = "rbxassetid://" .. id
				sound.SoundGroup = (cue == "Click" or cue == "Buy") and groups.UI or groups.SFX
				sound.Parent = Services.SoundService
				pool.voices[i] = { sound = sound, token = 0 }
			end
		end
	end
	FarmFX.sounds = pools
	FarmFX.particles, FarmFX.particleNext = {}, 0
	for i = 1, 8 do
		local holder = Instance.new("Attachment")
		holder.Name, holder.Parent = "PatchBurst", workspace.Terrain
		local emitter = Instance.new("ParticleEmitter")
		emitter.Enabled, emitter.Rate = false, 0
		emitter.LightInfluence = 0
		emitter.Parent = holder
		FarmFX.particles[i] = { holder = holder, emitter = emitter }
	end
end
local function play(id: number, pitch: number?, volume: number?)
	if not sfxOn or not id or id == 0 then
		return
	end
	local pool = FarmFX.sounds[id]
	if not pool then
		return
	end
	local voice
	for _, candidate in pool.voices do
		if not candidate.sound.IsPlaying then
			voice = candidate
			break
		end
	end
	if not voice then
		pool.next = pool.next % 6 + 1
		voice = pool.voices[pool.next]
	end
	voice.token += 1
	if voice.fade then
		voice.fade:Cancel()
		voice.fade = nil
	end
	local sound = voice.sound
	sound:Stop()
	sound.PlaybackSpeed, sound.Volume = pitch or 1, volume or 0.8
	sound:Play()
	if id == Config.Sounds.Growl then
		local token = voice.token
		task.delay(1.2, function()
			if voice.token ~= token then
				return
			end
			voice.fade = Services.TweenService:Create(sound, TweenInfo.new(0.25), { Volume = 0 })
			voice.fade:Play()
			task.delay(0.25, function()
				if voice.token == token then
					sound:Stop()
				end
			end)
		end)
	end
end
-- Short numbers: 950, 1.2k, 34.5k, 340k, 3.4M, 1.2B (rounded down so 999.96k never shows 1000k).
local function short(n: number): string
	local sign = n < 0 and "-" or ""
	n = math.abs(n)
	if n < 10000 then
		local value = tostring(math.floor(n))
		return sign .. value:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	end
	for _, unit in { { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } } do
		if n >= unit[1] then
			local v = n / unit[1]
			local decimals = v >= 100 and 0 or v >= 10 and 1 or 2
			local factor = 10 ^ decimals
			local text = string.format("%." .. decimals .. "f", math.floor(v * factor) / factor)
			if decimals > 0 then
				text = text:gsub("0+$", ""):gsub("%.$", "")
			end
			return sign .. text .. unit[2]
		end
	end
	return sign .. tostring(math.floor(n))
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
	return string.format("%dm %ds", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function burst(
	at: Vector3,
	color: Color3,
	count: number,
	speed: number,
	texture: string?,
	size: number?
)
	FarmFX.particleNext = FarmFX.particleNext % #FarmFX.particles + 1
	local slot = FarmFX.particles[FarmFX.particleNext]
	local emitter = slot.emitter
	emitter:Clear()
	slot.holder.WorldPosition = at
	emitter.Texture = texture or "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color)
	local s = size or 2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, s),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.4, 0.7)
	emitter.Speed = NumberRange.new(speed * 0.6, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -35, 0)
	emitter.Drag = 2
	emitter.LightEmission = texture and 1 or 0
	local mobile = Palette.mobile()

	emitter:Emit(math.max(1, math.floor(count * (mobile and 0.5 or 1))))
end
local function floatText(at: Vector3, text: string, color: Color3, big: boolean?)
	if text:sub(1, 1) == "+" and not text:find("/s") then
		return
	end
	if UI.floatAnchor then
		UI.floatAnchor:Destroy()
	end
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = workspace
	UI.floatAnchor = anchor
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(big and 260 or 200, big and 60 or 46)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 60
	bb.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = fontFace("small")
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = Palette.uiText(text)
	label.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(30, 12, 40)
	stroke.Parent = label
	local info = TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Services.TweenService
		:Create(
			anchor,
			TweenInfo.new(1.6, Enum.EasingStyle.Quad),
			{ CFrame = anchor.CFrame + Vector3.new(0, 6, 0) }
		)
		:Play()
	Services.TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	Services.TweenService:Create(stroke, info, { Transparency = 1 }):Play()
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
	local now = os.clock()
	UI.damageTotal = now - (UI.damageAt or 0) <= 0.3 and (UI.damageTotal or 0) + damage or damage
	UI.damageAt = now
	damage = UI.damageTotal
	if UI.damageGui then
		UI.damageGui:Destroy()
		UI.damageHolder:Destroy()
	end
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
	UI.damageGui, UI.damageHolder = bb, holder
	bb.Adornee = holder
	bb.Size = UDim2.fromOffset(px * 5, px + 60)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 60
	bb.ResetOnSpawn = false
	bb.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.fromScale(0, 1)
	label.Size = UDim2.new(1, 0, 0, px)
	label.FontFace = fontFace("number")
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
	Services.TweenService
		:Create(pop, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 })
		:Play()
	-- Hold until 0.62 s, then rise and fade over the last 0.48 s.
	local rise =
		TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.62)
	Services.TweenService:Create(label, rise, { Position = UDim2.new(0, 0, 1, -46) }):Play()
	local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.7)
	Services.TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	Services.TweenService:Create(outline, fade, { Transparency = 1 }):Play()
	task.delay(1.12, function()
		bb:Destroy()
		holder:Destroy()
	end)
end

-- A big white "+1 🎃" over your own head whenever your carried stack grows (any pickup:
-- smash, loose pumpkin, your plot, a steal). Pops in, holds, rises and fades in 1.2 s.
local function pickupPop(amount: number)
	if UI.pickupGui then
		UI.pickupGui:Destroy()
	end
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "PickupPop"
	UI.pickupGui = bb
	bb.Adornee = head
	bb.Size = UDim2.fromOffset(220, 72)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 60
	bb.ResetOnSpawn = false
	bb.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = fontFace("number")
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "+" .. amount .. " Pumpkin"
	label.Parent = bb
	local outline = Instance.new("UIStroke")
	outline.Thickness = 4
	outline.Color = Color3.fromRGB(20, 10, 30)
	outline.Parent = label
	local pop = Instance.new("UIScale")
	pop.Scale = 0.3
	pop.Parent = label
	Services.TweenService
		:Create(pop, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 })
		:Play()
	local rise = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.7)
	Services.TweenService
		:Create(bb, rise, { StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0) })
		:Play()
	local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.8)
	Services.TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	Services.TweenService:Create(outline, fade, { Transparency = 1 }):Play()
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

local shakeState =
	{ strength = 0, ends = 0, duration = 0.2, camera = nil, offset = CFrame.identity }
local function shake(strength: number, steps: number)
	local duration = math.max(0.1, (steps or 10) * 0.02)
	shakeState.strength = math.max(shakeState.strength, math.min(0.15, strength * 0.075))
	shakeState.ends = math.max(shakeState.ends, os.clock() + duration)
	shakeState.duration = math.max(duration, shakeState.ends - os.clock())
end
Services.RunService:BindToRenderStep(
	"PatchShakeRestore",
	Enum.RenderPriority.Camera.Value - 1,
	function()
		if shakeState.camera and shakeState.camera == workspace.CurrentCamera then
			shakeState.camera.CFrame *= shakeState.offset:Inverse()
		end
		shakeState.offset = CFrame.identity
	end
)
Services.RunService:BindToRenderStep("PatchShake", Enum.RenderPriority.Camera.Value + 1, function()
	local t = os.clock()
	local camera = workspace.CurrentCamera
	if not camera or t >= shakeState.ends then
		shakeState.strength = 0
		return
	end
	local k = shakeState.strength * math.clamp((shakeState.ends - t) / shakeState.duration, 0, 1)
	shakeState.camera = camera
	shakeState.offset = CFrame.Angles(
		math.noise(t * 32, 1) * k,
		math.noise(2, t * 32) * k,
		math.noise(t * 32, 3) * k * 0.5
	)
	camera.CFrame *= shakeState.offset
end)

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
local confetti: (Instance?) -> ()
local queueReveal: (string, string?, boolean, number, string?, string?, number?) -> ()
local function inHub(): boolean
	local root = rootPart()
	return root ~= nil and root.Position.Z < (state:GetAttribute("SafeLineZ") or Config.SafeLineZ)
end

local Center = {
	busy = false,
	urgent = false,
	frames = {},
	nextTicket = 0,
	serving = 1,
	revealBusy = false,
	toasts = {},
}
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

-- Screen -----------------------------------------------------------------------------------

UI.screen = Instance.new("ScreenGui")
UI.screen.Name = "PatchHud"
UI.screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.screen.ResetOnSpawn = false
UI.screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
-- Above the panel dim (PatchDim, order 0), so the HUD stays bright while a panel is open.
UI.screen.DisplayOrder = 1
UI.screen.Parent = player:WaitForChild("PlayerGui")
local gui = Instance.new("Frame")
gui.Name, gui.BackgroundTransparency, gui.Size, gui.Parent =
	"Root", 1, UDim2.fromScale(1, 1), UI.screen

-- Screen fractions remain unscaled; component UIScales animate buttons and panels.
-- Phone panels and grid columns adapt to AbsoluteSize and touch input below.
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
	uiScale.Scale = Palette.mobile() and math.clamp(size.Y / 720, 0.75, 1.15) or 1
	-- Preserve the screen bounds while scaling pixel-sized controls and the text floor.
	gui.Size = UDim2.fromScale(1 / uiScale.Scale, 1 / uiScale.Scale)
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

Palette.DARK = Color3.fromRGB(34, 22, 48)
-- Halloween skin (refs aspects/halloween 2.5, ui HOWTO 2): charcoal panels with an orange rim, a
-- lime gradient on buy buttons, purple close / back buttons. HUD numbers: money green, speed yellow.
Palette.CHARCOAL = Config.UI.body
Palette.ORANGE = Color3.fromRGB(242, 140, 26)
Palette.BUY = Config.UI.Tokens.go
Palette.BUY_LOW = Config.UI.Tokens.goLip
Palette.PURPLE = Config.UI.Tokens.info
Palette.MONEY = Config.UI.Tokens.candy
local function stroke(parent: Instance, thickness: number)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Config.UI.Tokens.ink
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end
local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius and UDim.new(0, radius) or UDim.new(1, 0)
	c.Parent = parent
end
-- Normalize server-sent UI copy at the presentation boundary, without changing saved IDs.
function Palette.uiText(text: string): string
	local clean = {}
	for _, code in utf8.codes(text) do
		if
			not (
				code >= 0x1F000 and code <= 0x1FAFF
				or code >= 0x2600 and code <= 0x27FF
				or code == 0xFE0F
				or code == 0x200D
			)
		then
			table.insert(clean, utf8.char(code))
		end
	end
	text = table.concat(clean)
	return (
		text:gsub("a ORANGE", "an Orange")
			:gsub("a Orange", "an Orange")
			:gsub("your base", "your pen")
			:gsub("your Base", "your pen")
			:gsub("YOUR BASE", "YOUR PEN")
			:gsub("PUMPKIN KING RISES! PET %+ LOOT!", "King Fight!")
			:gsub("Blood Moon", "King Fight")
	)
end
function UI.fitText(label, fraction)
	label:SetAttribute("TypeSize", fraction)
	local bounds = label:FindFirstChildOfClass("UITextSizeConstraint")
		or Instance.new("UITextSizeConstraint")
	bounds.Parent = label
	local function fit()
		local h = gui.AbsoluteSize.Y / uiScale.Scale
		bounds.MinTextSize = math.max(
			11,
			math.ceil(11 / uiScale.Scale),
			math.ceil(h * Config.UI.Tokens.type.caption)
		)
		bounds.MaxTextSize = math.max(
			bounds.MinTextSize,
			math.floor(h * (label:GetAttribute("TypeSize") or fraction) * 1.1)
		)
		local outline = label:FindFirstChildOfClass("UIStroke")
		if outline then
			outline.Thickness = math.max(1.5 / uiScale.Scale, h * 0.0028)
		end
	end
	local resize = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	local role = label:GetAttributeChangedSignal("TypeSize"):Connect(fit)
	label.Destroying:Connect(function()
		resize:Disconnect()
		role:Disconnect()
	end)
	fit()
end
local function textLabel(parent: Instance, text: string, color: Color3, font: string?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = fontFace(font or "small")
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = Palette.uiText(text)
	label.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = math.max(1.5, gui.AbsoluteSize.Y * 0.0028)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Color = Config.UI.Tokens.ink
	s.Parent = label
	UI.fitText(label, font == "title" and Config.UI.Tokens.type.title or Config.UI.Tokens.type.hud)
	return label
end
function UI.tween(target, seconds, goals, style, direction)
	local tween = Services.TweenService:Create(
		target,
		TweenInfo.new(
			seconds,
			style or Enum.EasingStyle.Quad,
			direction or Enum.EasingDirection.Out
		),
		goals
	)
	tween:Play()
	return tween
end
Palette.OUTLINE = Config.UI.Tokens.ink
local function chunky(b: GuiButton): (Frame, UIStroke)
	b.AutoButtonColor, b.BackgroundTransparency, b.BorderSizePixel = false, 1, 0
	local lip = Instance.new("Frame")
	lip.Name, lip.Size, lip.ZIndex, lip.Parent = "Lip", UDim2.fromScale(1, 1), b.ZIndex, b
	lip.BorderSizePixel = 0
	corner(lip, 8)
	local face = Instance.new("Frame")
	face.Name, face.Size, face.ZIndex, face.Parent =
		"Face", UDim2.fromScale(1, 0.88), b.ZIndex + 1, b
	face.BorderSizePixel = 0
	corner(face, 8);
	(face:FindFirstChildOfClass("UICorner") :: UICorner).CornerRadius =
		UDim.new(Config.UI.Tokens.corners.button, 0);
	(lip:FindFirstChildOfClass("UICorner") :: UICorner).CornerRadius =
		UDim.new(Config.UI.Tokens.corners.button, 0)
	local outline = stroke(face, 2.5)
	local gradient = Instance.new("UIGradient")
	gradient.Color, gradient.Rotation, gradient.Parent =
		ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8)), 90, face
	local gloss = Instance.new("Frame")
	gloss.Name, gloss.Size, gloss.BackgroundColor3 =
		"Gloss", UDim2.fromScale(1, 0.38), Color3.new(1, 1, 1)
	gloss.BackgroundTransparency, gloss.BorderSizePixel, gloss.ZIndex, gloss.Parent =
		0.82, 0, face.ZIndex + 1, face
	corner(gloss, 8)
	local function sync()
		face.BackgroundColor3 = b.BackgroundColor3
		local tokens = Config.UI.Tokens
		lip.BackgroundColor3 = b.BackgroundColor3 == tokens.go and tokens.goLip
			or b.BackgroundColor3 == tokens.info and tokens.infoLip
			or b.BackgroundColor3 == tokens.stop and tokens.stopLip
			or tokens.offLip
	end
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(sync)
	sync()
	local scale = Instance.new("UIScale")
	scale.Parent = b
	b.MouseEnter:Connect(function()
		UI.tween(scale, 0.12, { Scale = 1.06 }, Enum.EasingStyle.Back)
	end)
	b.MouseLeave:Connect(function()
		UI.tween(scale, 0.20, { Scale = 1 }, Enum.EasingStyle.Back)
		UI.tween(face, 0.20, { Position = UDim2.new() })
	end)
	b.MouseButton1Down:Connect(function()
		UI.tween(scale, 0.06, { Scale = 0.92 })
		UI.tween(face, 0.06, { Position = UDim2.fromScale(0, 0.08) })
	end)
	b.MouseButton1Up:Connect(function()
		UI.tween(scale, 0.20, { Scale = 1 }, Enum.EasingStyle.Back)
		UI.tween(face, 0.20, { Position = UDim2.new() })
	end)
	b.Activated:Connect(function()
		play(Config.Sounds.Click, 1, 0.35)
	end)
	return face, outline
end
local function makeButton(parent: Instance, text: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.FontFace = fontFace("button")
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
	label.FontFace = b.FontFace
	label.TextScaled = true
	label.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 3)
	pad.PaddingBottom = UDim.new(0, 3)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = label
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 2
	textStroke.Color = Palette.OUTLINE
	textStroke.LineJoinMode = Enum.LineJoinMode.Round
	textStroke.Parent = label
	UI.fitText(label, Config.UI.Tokens.type.hud)
	local function mirror()
		label.Text = Palette.uiText(b.Text)
		label.TextColor3 = b.TextColor3
	end
	b:GetPropertyChangedSignal("Text"):Connect(mirror)
	b:GetPropertyChangedSignal("TextColor3"):Connect(mirror)
	mirror()
	return b
end

-- File-table builders keep the client below the top-level register limit.
function Palette.renderModel(parent, source, silhouette, outlined)
	outlined = outlined ~= false and not silhouette
	local live = 0
	for _, object in player.PlayerGui:GetDescendants() do
		if object:IsA("ViewportFrame") then
			live += 1
		end
	end
	if live >= 40 then
		return nil
	end
	UI.views += 1
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency, view.Size = "ModelIcon", 1, UDim2.fromScale(1, 1)
	view.Ambient, view.LightColor, view.LightDirection =
		Color3.fromRGB(200, 200, 210), Color3.new(1, 1, 1), Vector3.new(-1, -1, -2)
	view.ZIndex, view.Parent = parent:IsA("GuiObject") and parent.ZIndex + 2 or 2, parent
	view.ImageColor3 = silhouette and Config.UI.Tokens.ink or Color3.new(1, 1, 1)
	view.Destroying:Connect(function()
		UI.views -= 1
	end)
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = Instance.new("Model")
	local parts = source:GetDescendants()
	if source:IsA("BasePart") then
		table.insert(parts, source)
	end
	for _, part in parts do
		if part:IsA("BasePart") then
			local copy = part:Clone()
			if source:IsA("Model") and source:GetAttribute("FrontFixed") then
				-- Normalize world/held-pet yaw before the shared camera-facing preview pose.
				copy.CFrame = source:GetPivot():ToObjectSpace(part.CFrame)
			end
			for _, child in copy:GetChildren() do
				if not child:IsA("DataModelMesh") and not child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
			copy.Anchored, copy.CanCollide, copy.CanTouch, copy.CanQuery = true, false, false, false
			copy.Parent = model
		end
	end
	model.Parent = world
	local scythe = source:IsA("Tool") or source.Parent and source.Parent.Name == "PatchScytheIcons"
	model:PivotTo(
		scythe and CFrame.Angles(0, math.rad(20), math.rad(-35))
			or CFrame.Angles(
				0,
				math.rad(-25) + (source:GetAttribute("FrontFixed") and math.pi or 0),
				0
			)
	)
	-- Project EVERY part corner after posing. GetBoundingBox can retain a rotated pivot,
	-- and a diagonal fit wastes almost the whole tile on a thin scythe.
	local low, high =
		Vector3.new(math.huge, math.huge, math.huge),
		Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in model:GetChildren() do
		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				for z = -1, 1, 2 do
					local point =
						part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) * 0.5)
					low = Vector3.new(
						math.min(low.X, point.X),
						math.min(low.Y, point.Y),
						math.min(low.Z, point.Z)
					)
					high = Vector3.new(
						math.max(high.X, point.X),
						math.max(high.Y, point.Y),
						math.max(high.Z, point.Z)
					)
				end
			end
		end
	end
	if #model:GetChildren() == 0 then
		view:Destroy()
		return nil
	end
	local size, centre = high - low, (high + low) * 0.5
	local camera = Instance.new("Camera")
	camera.FieldOfView, camera.Parent, view.CurrentCamera = 20, view, camera
	local outline
	if outlined and live + 1 < 40 then
		outline = view:Clone()
		outline.Name, outline.ImageColor3 = "IconOutline", Config.UI.Tokens.ink
		outline.AnchorPoint, outline.Position, outline.Size =
			Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1.10, 1.10)
		outline.ZIndex, outline.Parent = view.ZIndex - 1, parent
		outline.CurrentCamera = outline:FindFirstChildOfClass("Camera")
		UI.views += 1
		outline.Destroying:Connect(function()
			UI.views -= 1
		end)
		view.Destroying:Connect(function()
			outline:Destroy()
		end)
	end
	local function fit()
		low, high =
			Vector3.new(math.huge, math.huge, math.huge),
			Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, part in model:GetChildren() do
			for x = -1, 1, 2 do
				for y = -1, 1, 2 do
					for z = -1, 1, 2 do
						local point =
							part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) * 0.5)
						low = Vector3.new(
							math.min(low.X, point.X),
							math.min(low.Y, point.Y),
							math.min(low.Z, point.Z)
						)
						high = Vector3.new(
							math.max(high.X, point.X),
							math.max(high.Y, point.Y),
							math.max(high.Z, point.Z)
						)
					end
				end
			end
		end
		size, centre = high - low, (high + low) * 0.5
		local aspect = math.max(0.1, view.AbsoluteSize.X / math.max(1, view.AbsoluteSize.Y))
		local distance = math.max(size.X / aspect, size.Y) * 0.5 / math.tan(math.rad(10)) * 1.06
			+ size.Z / 2
		camera.CFrame = CFrame.lookAt(centre + Vector3.new(0, 0, distance), centre)
		if outline then
			outline.CurrentCamera.CFrame = camera.CFrame
			local outlineWorld = outline:FindFirstChildOfClass("WorldModel")
			local outlineModel = outlineWorld and outlineWorld:FindFirstChildOfClass("Model")
			if outlineModel then
				outlineModel:PivotTo(model:GetPivot())
			end
		end
	end
	UI.fitters = UI.fitters or setmetatable({}, { __mode = "k" })
	UI.fitters[view] = fit
	view.Destroying:Connect(function()
		UI.fitters[view] = nil
	end)
	view:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return view
end
-- Small HUD symbols use Frames: readable at phone size and leave viewports for game objects.
function UI.box(parent, name, position, size, color, z)
	local frame = Instance.new("Frame")
	frame.Name, frame.Position, frame.Size = name, position, size
	frame.BackgroundColor3, frame.BorderSizePixel = color, 0
	frame.ZIndex, frame.Parent = z or parent.ZIndex + 1, parent
	return frame
end
function UI.icon(parent, id)
	local t = Config.UI.Tokens
	local root = UI.box(
		parent,
		"Glyph_" .. id,
		UDim2.fromScale(0.1, 0.1),
		UDim2.fromScale(0.8, 0.8),
		t.ink,
		parent.ZIndex + 2
	)
	root.BackgroundTransparency = 1
	root.AnchorPoint, root.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio, aspect.AspectType, aspect.Parent = 1, Enum.AspectType.FitWithinMaxSize, root
	local function piece(x, y, w, h, color, angle)
		local part = UI.box(root, "Part", UDim2.fromScale(x, y), UDim2.fromScale(w, h), color)
		part.Rotation = angle or 0
		return part
	end
	if id == "Candy" then
		root.Size = UDim2.fromScale(1, 1)
		UI.candyGlyph(root)
	elseif id == "Index" then
		corner(piece(0.08, 0.08, 0.84, 0.84, t.info), 4)
		stroke(root:GetChildren()[1], 2)
		piece(0.22, 0.13, 0.65, 0.70, Color3.new(1, 1, 1))
		piece(0.13, 0.08, 0.10, 0.84, t.candy)
		piece(0.37, 0.31, 0.34, 0.08, t.info)
		piece(0.37, 0.51, 0.34, 0.08, t.info)
	elseif id == "Quests" then
		piece(0.19, 0.15, 0.62, 0.70, Color3.fromRGB(255, 237, 186))
		for _, y in { 0.10, 0.78 } do
			corner(piece(0.10, y, 0.80, 0.12, t.candy), 4)
		end
		for _, y in { 0.30, 0.48, 0.66 } do
			piece(0.30, y, 0.40, 0.06, t.goLip)
		end
	elseif id == "Daily" then
		piece(0.12, 0.34, 0.76, 0.60, t.info)
		piece(0.06, 0.29, 0.88, 0.16, t.candy)
		piece(0.43, 0.29, 0.14, 0.65, t.candy)
		piece(0.23, 0.10, 0.30, 0.15, t.candy, 30)
		piece(0.47, 0.10, 0.30, 0.15, t.candy, -30)
	elseif id == "Clock" or id == "Gear" then
		local ring = piece(0.12, 0.12, 0.76, 0.76, Color3.new(1, 1, 1))
		corner(ring)
		corner(piece(0.25, 0.25, 0.50, 0.50, t.well))
		if id == "Clock" then
			piece(0.46, 0.28, 0.09, 0.28, t.candy)
			piece(0.47, 0.47, 0.27, 0.09, t.candy)
		else
			for i = 1, 8 do
				local a = i * math.pi / 4
				piece(
					0.43 + math.cos(a) * 0.40,
					0.43 + math.sin(a) * 0.40,
					0.14,
					0.14,
					Color3.new(1, 1, 1),
					i * 45
				)
			end
		end
	elseif id == "King" then
		piece(0.12, 0.63, 0.76, 0.25, t.candy)
		for _, x in { 0.12, 0.43, 0.74 } do
			piece(x, 0.20, 0.14, 0.55, t.candy)
		end
	elseif id == "Carry" or id == "Sprint" then
		if id == "Carry" then
			piece(0.43, 0.18, 0.10, 0.76, Color3.new(1, 1, 1), -25)
			piece(0.39, 0.10, 0.52, 0.13, t.candy, 15)
		else
			piece(0.25, 0.28, 0.34, 0.10, Color3.new(1, 1, 1), -45)
			piece(0.45, 0.28, 0.34, 0.10, Color3.new(1, 1, 1), 45)
			piece(0.45, 0.35, 0.10, 0.50, Color3.new(1, 1, 1))
		end
	else
		local pumpkin = piece(0.08, 0.35, 0.84, 0.55, t.go)
		corner(pumpkin, 6)
		stroke(pumpkin, 2)
		piece(0.44, 0.14, 0.13, 0.23, t.good)
		piece(0.28, 0.52, 0.12, 0.12, t.ink, 45)
		piece(0.61, 0.52, 0.12, 0.12, t.ink, 45)
		piece(0.38, 0.75, 0.28, 0.06, t.ink)
		if id == "Shop" then
			local handle = piece(0.20, 0.06, 0.60, 0.62, t.goLip)
			handle.BackgroundTransparency = 1
			corner(handle, 7)
			stroke(handle, 3)
		elseif id == "Pets" then
			piece(0.03, 0.25, 0.94, 0.10, t.candy, -12)
		end
	end
	return root
end
function UI.candyGlyph(parent)
	for i = -1, 1 do
		local part = Instance.new("Frame")
		part.BorderSizePixel, part.BackgroundColor3 =
			0, i == 0 and Config.UI.Tokens.candy or Config.UI.Tokens.go
		part.Size, part.Position =
			UDim2.fromScale(i == 0 and 0.48 or 0.24, i == 0 and 0.72 or 0.52),
			UDim2.fromScale(i == 0 and 0.26 or i < 0 and 0.01 or 0.75, i == 0 and 0.14 or 0.24)
		part.Rotation, part.ZIndex, part.Parent = i * 30, parent.ZIndex + 1, parent
	end
end
function Palette.candyIcon(parent, _fitCandy: boolean?)
	return UI.icon(parent, "Candy")
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
	Services.TweenService
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
-- the top, at most 2, each gone after 3.5 s. Rich text, so a key word can be coloured.
local hint
do
	local holder = Instance.new("Frame")
	holder.Name, holder.BackgroundTransparency, holder.AnchorPoint =
		"Toasts", 1, Vector2.new(0.5, 0)
	holder.Position, holder.Size, holder.Parent =
		UDim2.fromScale(0.5, Config.UI.toastY), UDim2.fromScale(0.76, 0.14), gui
	Center.toastHolder = holder
	local rows, count = {}, 0
	function hint(text: string)
		text = Palette.uiText(text)
		local now = os.clock()
		for _, row in rows do
			if row.text == text and now - row.at <= 3 then
				-- Ignore duplicate notices within the three-second window.
				return
			end
		end
		count += 1
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency, frame.Size, frame.Parent = 1, UDim2.fromScale(1, 0.28), holder
		local label = textLabel(frame, text, Color3.new(1, 1, 1))
		label.RichText, label.Position, label.Size =
			true, UDim2.fromScale(0.06, 0), UDim2.fromScale(0.94, 1)
		local icon = Instance.new("Frame")
		icon.BackgroundTransparency, icon.Size, icon.Parent = 1, UDim2.fromScale(0.05, 1), frame
		UI.icon(icon, text:find("%+") and "Candy" or text:lower():find("king") and "King" or "Pets")
		local row = { text = text, at = now, count = 1, frame = frame, label = label, id = count }
		table.insert(rows, row)
		if #rows > 3 then
			table.remove(rows, 1).frame:Destroy()
		end
		for i, entry in rows do
			entry.frame.Position = UDim2.fromScale(0, (i - 1) * 0.32)
		end
		if text:lower():find("stealing") or text:lower():find("unavailable") then
			UI.tween(frame, 0.08, { Rotation = 2 })
			task.delay(0.08, function()
				if frame.Parent then
					UI.tween(frame, 0.12, { Rotation = 0 })
				end
			end)
		end
		task.delay(3.2, function()
			if not frame.Parent then
				return
			end
			UI.tween(label, 0.3, { TextTransparency = 1 })
			local outline = label:FindFirstChildOfClass("UIStroke")
			UI.tween(outline, 0.3, { Transparency = 1 })
			task.delay(0.3, function()
				frame:Destroy()
				local i = table.find(rows, row)
				if i then
					table.remove(rows, i)
				end
				for k, entry in rows do
					entry.frame.Position = UDim2.fromScale(0, (k - 1) * 0.32)
				end
			end)
		end)
	end
end
remotes:WaitForChild("Hint").OnClientEvent:Connect(hint)

-- Event news that used to be big banners: one small toast line ("TITLE · sub").
function Center.purchaseBurst()
	local root = rootPart()
	if root then
		burst(root.Position + Vector3.yAxis * 2, Palette.ORANGE, 18, 8, Palette.SPARKLE, 0.6)
	end
end
local function toast(title: string, sub: string?)
	hint(title .. (sub and sub ~= "" and (" · " .. sub) or ""))
end

-- Bottom right (Steal an Egg): the moon timer to midnight ("🌙 in 1:54", red in its last 10 s; a
-- sun "☀ in 0:32" while the midnight raid runs) and over it the Spooky Hour line ("🦇 Spooky Hour in
-- 6:12", orange "🦇 SPOOKY HOUR! x2 1:12" while it runs). Players past the King gate also see the
-- Blood Moon / King state in the moon line, with a thin bar. On touch screens (jump button
-- bottom right) the stack sits top right instead. The world MeterRing around the Giant Jack
-- still fills. The top centre belongs to the objective banner; the centre stays clear.
Palette.KING_FILL = ColorSequence.new(Config.UI.Tokens.stop, Config.UI.Tokens.go)
do
	local chips = {}
	for i, id in { "Clock", "King" } do
		local chip = Instance.new("Frame")
		chip.Name, chip.BackgroundTransparency, chip.AnchorPoint, chip.Parent =
			id .. "Chip", 0.30, Vector2.new(1, 1), gui
		chip.BackgroundColor3, chip.BorderSizePixel = Config.UI.Tokens.well, 0
		corner(chip)
		local icon = Instance.new("Frame")
		icon.BackgroundTransparency, icon.Size, icon.Parent = 1, UDim2.fromScale(0.16, 0.82), chip
		UI.icon(icon, id)
		local label = textLabel(chip, "", Color3.new(1, 1, 1))
		label.Position, label.Size, label.TextXAlignment =
			UDim2.fromScale(0.18, 0), UDim2.fromScale(0.82, 1), Enum.TextXAlignment.Right
		chips[i] = { frame = chip, label = label }
	end
	local function layout()
		local touch, h = Palette.mobile(), gui.AbsoluteSize.Y / uiScale.Scale
		for i, chip in chips do
			chip.frame.Position = UDim2.fromScale(
				touch and 0.975 or 0.99,
				touch and (i == 1 and 0.055 or 0.11) or (i == 1 and 0.985 or 0.933)
			)
			chip.frame.Size = UDim2.fromOffset(
				touch and gui.AbsoluteSize.X / uiScale.Scale * 0.53 or h * 0.46,
				h * 0.040
			)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Services.UserInputService.LastInputTypeChanged:Connect(layout)
	layout()
	task.spawn(function()
		while gui.Parent do
			local now = workspace:GetServerTimeNow()
			local phase = state:GetAttribute("Phase") or "Day"
			local ends = state:GetAttribute("PhaseEnds") or now
			local nests = math.max(0, (phase == "Day" and ends or ends + Config.DayLength) - now)
			local king = math.max(0, (state:GetAttribute("KingWakesAt") or now) - now)
			chips[1].label.Text = "Nests respawn in " .. clockText(nests)
			chips[1].label.TextColor3 = nests <= 10 and Config.UI.Tokens.good or Color3.new(1, 1, 1)
			chips[2].label.Text = phase == "BloodMoon" and ("King fight " .. clockText(ends - now))
				or ("King in " .. clockText(king))
			chips[2].label.TextColor3 = king < 60 and Config.UI.Tokens.stop or Color3.new(1, 1, 1)
			chips[1].label.TextTransparency = nests <= 10
					and (0.12 + 0.12 * math.sin(os.clock() * 6))
				or 0
			meterRing.Transparency = 1
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
	stats.Position = UDim2.fromScale(0.012, Palette.mobile() and 0.565 or 0.975)
	stats.Size = UDim2.fromScale(Palette.mobile() and 0.48 or 0.28, 0.20)
	stats.Parent = gui
	carryLabel = textLabel(stats, "", Color3.new(1, 1, 1))
	carryLabel.Name = "Carry"
	carryLabel:SetAttribute("TypeSize", 0.040)
	carryLabel.Position = UDim2.fromScale(0, 0)
	carryLabel.Size = UDim2.fromScale(1, 0.15)
	carryLabel.Visible = true
	carryLabel.TextXAlignment = Enum.TextXAlignment.Left
	local icon = Instance.new("TextLabel")
	icon.FontFace = fontFace("small")
	icon.Name = "CandyIcon"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromScale(0, 0.18)
	icon.Size = UDim2.fromScale(0.23, 0.31)
	icon.TextScaled = true
	icon.Text = ""
	Palette.candyIcon(icon, true)
	icon.Parent = stats
	local iconScale = Instance.new("UIScale")
	iconScale.Parent = icon
	-- Candy gold at 5% of the HUD height, with a black stroke.
	candyBig = textLabel(stats, "", Palette.MONEY)
	candyBig.Name = "Money"
	candyBig:SetAttribute("TypeSize", Config.UI.Tokens.type.currency)
	candyBig.Position = UDim2.fromScale(0.25, 0.18)
	candyBig.Size = UDim2.fromScale(0.75, 0.31)
	candyBig.TextScaled = false
	candyBig.FontFace = fontFace("number", "Regular", Config.Fonts.numberStyle)
	local function sizeCandy()
		candyBig.TextSize = math.max(10, gui.AbsoluteSize.Y * 0.055)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeCandy)
	sizeCandy()
	candyBig.TextXAlignment = Enum.TextXAlignment.Left
	local moneyStroke = candyBig:FindFirstChildOfClass("UIStroke") :: UIStroke
	moneyStroke.Thickness = 3.5
	moneyStroke.Color = Color3.new(0, 0, 0)
	incomeLabel = textLabel(stats, "", Palette.MONEY)
	incomeLabel.Name = "Income"
	incomeLabel.Visible = false
	incomeLabel.Size = UDim2.fromScale(1, 0.16)
	incomeLabel.Position = UDim2.fromScale(0, 0.52)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left

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
		local text = "+" .. rateShort(income * mult) .. "/s" .. (mult > 1 and (" x" .. mult) or "")
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
		roll = Services.TweenService:Create(
			shown,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = candyValue.Value }
		)
		roll:Play()
		local up = Services.TweenService:Create(
			iconScale,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = 1.12 }
		)
		up:Play()
		up.Completed:Once(function()
			Services.TweenService
				:Create(
					iconScale,
					TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }
				)
				:Play()
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
			local up = Services.TweenService:Create(
				target,
				TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Scale = size }
			)
			up:Play()
			up.Completed:Once(function()
				Services.TweenService
					:Create(
						target,
						TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Scale = 1 }
					)
					:Play()
			end)
		end
	end
	-- The counter punches and a green "+N" pops over the end of the number, rises and fades.
	-- Three separated lanes above the number, queued gains, no lost totals.
	local tickState = { amount = 0, token = 0 }
	function candyTick(amount: number)
		punch()
		if amount <= 0 then
			return
		end
		tickState.amount += amount
		tickState.token += 1
		local token = tickState.token
		if not tickState.label then
			tickState.label = textLabel(statsFrame, "", Config.UI.Tokens.good)
			tickState.label.Name = "CandyTick"
			tickState.label.Position = UDim2.fromScale(0.22, -0.30)
			tickState.label.Size = UDim2.fromScale(0.78, 0.24)
		end
		tickState.label.Text = "+" .. short(tickState.amount)
		task.delay(0.8, function()
			if token ~= tickState.token then
				return
			end
			tickState.label:Destroy()
			tickState.label, tickState.amount = nil, 0
			candyShower(1)
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
			candy.FontFace = fontFace("small")
			candy.BackgroundTransparency = 1
			candy.AnchorPoint = Vector2.new(0.5, 0.5)
			candy.Size = UDim2.fromOffset(40, 40)
			candy.TextScaled = true
			candy.Text = ""
			UI.candyGlyph(candy)
			candy.Rotation = math.random(-30, 30)
			local a = math.random() * math.pi * 2
			local spread = 40 + math.random() * 70
			candy.Position = UDim2.fromOffset(
				view.X / 2 + math.cos(a) * spread,
				view.Y / 2 + math.sin(a) * spread * 0.6
			)
			candy.Parent = fxGui
			task.delay((i - 1) * 0.05, function()
				local fly = Services.TweenService:Create(
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
	carryLabel.Text = string.format("%d/%d", player:GetAttribute("Carry") or 0, Config.BaseCarry)
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
for _, attr in { "Carry", "CarryValue", "Up_Stack" } do
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
leftBar.Position = UDim2.fromScale(0.012, Palette.mobile() and 0.12 or 0.36)
leftBar.Size = UDim2.fromScale(Palette.mobile() and 0.14 or 0.15, 0.2375)
leftBar.Parent = gui
-- Fixed slots keep the visible face and Activated hit rectangle together, including
-- when Daily is replaced by Teleport. Do not reflow animated UIScale buttons.
local function pill(_text: string, color: Color3, order: number): TextButton
	local name = order == 1 and "Shop"
		or order == 2 and "Index"
		or order == 3 and "Teleport"
		or "Daily"
	local b = makeButton(leftBar, name, color)
	b.Name = name .. "Button"
	b:SetAttribute("PanelTarget", name)
	local icon = Instance.new("Frame")
	icon.Name, icon.BackgroundTransparency, icon.ZIndex, icon.Parent = "Icon", 1, 5, b
	UI.icon(icon, name)
	local function layout()
		local touch = Palette.mobile()
		local h = gui.AbsoluteSize.Y / uiScale.Scale
		b.Position = UDim2.fromOffset(0, (order - 1) * h * (touch and 0.10 or 0.072))
		b.Size = UDim2.fromOffset(h * (touch and 0.09 or 0.17), h * (touch and 0.09 or 0.062))
		b.Text = touch and "" or name
		icon.Position = UDim2.fromScale(touch and 0.11 or 0.03, 0.10)
		icon.Size = UDim2.fromScale(touch and 0.78 or 0.30, 0.74)
		local label = b:FindFirstChild("Label")
		label.Position, label.Size = UDim2.fromScale(0.33, 0), UDim2.fromScale(0.65, 0.88)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Services.UserInputService.LastInputTypeChanged:Connect(layout)
	layout()
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
-- Card colours are centralized in Config.UI.Tokens.
local panelFrames: { Frame } = {}
function UI.closePanel(frame)
	local ticket = (frame:GetAttribute("CloseTicket") or 0) + 1
	frame:SetAttribute("CloseTicket", ticket)
	local scale = frame:FindFirstChildOfClass("UIScale")
	if scale then
		UI.tween(scale, 0.14, { Scale = 0.7 }, nil, Enum.EasingDirection.In)
	end
	local content = frame:FindFirstChild("Content")
	if content then
		UI.tween(content, 0.14, { GroupTransparency = 1 })
	end
	task.delay(0.14, function()
		if frame:GetAttribute("CloseTicket") == ticket then
			frame.Visible = false
		end
	end)
end
function UI.shadow(parent)
	local offset = gui.AbsoluteSize.Y / uiScale.Scale * Config.UI.Tokens.layout.shadow
	local shadow = UI.box(
		parent,
		"Shadow",
		UDim2.fromOffset(offset, offset),
		UDim2.fromScale(1, 1),
		Config.UI.Tokens.ink,
		math.max(1, parent.ZIndex - 1)
	)
	shadow.BackgroundTransparency = 0.55
	corner(shadow, 12)
	return shadow
end
function UI.secret(parent)
	local gradient = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	local keys = {}
	for i, color in Config.UI.Tokens.secret do
		table.insert(
			keys,
			ColorSequenceKeypoint.new((i - 1) / (#Config.UI.Tokens.secret - 1), color)
		)
	end
	parent.BackgroundColor3 = Color3.new(1, 1, 1)
	gradient.Color, gradient.Parent = ColorSequence.new(keys), parent
	local spin = Services.RunService.RenderStepped:Connect(function(dt)
		if parent:IsDescendantOf(gui) then
			gradient.Rotation = (gradient.Rotation + dt * 25) % 360
		end
	end)
	parent.Destroying:Connect(function()
		spin:Disconnect()
	end)
end
function UI.sticker(parent, text, color)
	local ribbon = textLabel(parent, text, color)
	ribbon.FontFace = fontFace("small", "Heavy", "Italic")
	ribbon.Position, ribbon.Size, ribbon.Rotation, ribbon.ZIndex =
		UDim2.fromScale(0.54, 0.10), UDim2.fromScale(0.46, 0.12), 12, parent.ZIndex + 5
	return ribbon
end
local panelDim: TextButton
do
	local dimGui = Instance.new("ScreenGui")
	dimGui.Name = "PatchDim"
	dimGui.ResetOnSpawn = false
	dimGui.IgnoreGuiInset = true
	dimGui.DisplayOrder = 0
	dimGui.Parent = player:WaitForChild("PlayerGui")
	panelDim = Instance.new("TextButton")
	panelDim.FontFace = fontFace("button")
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
		play(Config.Sounds.Click, 1, 0.35)
		for _, f in panelFrames do
			if f.Visible then
				UI.closePanel(f)
			end
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
	leftBar.Visible = true
	statsFrame.Visible = true
	if anyPanelOpen() then
		panelDim.Visible = true
		Services.TweenService
			:Create(panelDim, TweenInfo.new(0.2), { BackgroundTransparency = 0.55 })
			:Play()
	elseif panelDim.Visible then
		local fade = Services.TweenService:Create(
			panelDim,
			TweenInfo.new(0.2),
			{ BackgroundTransparency = 1 }
		)
		fade:Play()
		fade.Completed:Once(function()
			panelDim.Visible = anyPanelOpen()
		end)
	end
end

-- Close control stays inside the gradient header.
local function closeButton(frame: GuiObject): TextButton
	local close = makeButton(frame, "X", Config.UI.Tokens.stop)
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(0.7, 0.3)
	close.Position = UDim2.fromScale(1, 0)
	local function fitClose()
		local side = gui.AbsoluteSize.Y / uiScale.Scale * Config.UI.Tokens.layout.closeSize
		close.Size = UDim2.fromOffset(side, side)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitClose)
	fitClose()
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = close
	close.ZIndex = 14
	for _, d in close:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += 13
		elseif d:IsA("UICorner") then
			d.CornerRadius = UDim.new(0.16, 0)
		end
	end
	return close
end

local function panel(title: string, grid: boolean?): (Frame, ScrollingFrame)
	local frame = Instance.new("Frame")
	frame:SetAttribute("PanelTitle", title)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(Config.UI.panelSize.X, Config.UI.panelSize.Y)
	local function resize()
		local h = gui.AbsoluteSize.Y / uiScale.Scale
		local daily = string.find(title, "Daily") ~= nil
		frame.Size = Palette.mobile() and UDim2.fromScale(0.86, 0.80)
			or UDim2.fromOffset(
				h
					* (
						daily
							and Config.UI.Tokens.layout.dailyHeight * Config.UI.Tokens.layout.dailyAspect
						or Config.UI.Tokens.layout.panelHeight
							* Config.UI.Tokens.layout.panelAspect
					),
				h
					* (
						daily and Config.UI.Tokens.layout.dailyHeight
						or Config.UI.Tokens.layout.panelHeight
					)
			)
	end
	resize()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	Services.UserInputService.LastInputTypeChanged:Connect(resize)
	frame.BackgroundColor3 = Config.UI.Tokens.panel
	frame.Visible = false
	frame.ZIndex = 10
	frame.Parent = gui
	corner(frame, 16);
	(frame:FindFirstChildOfClass("UICorner") :: UICorner).CornerRadius =
		UDim.new(Config.UI.Tokens.corners.panel, 0)
	UI.shadow(frame)
	local content = Instance.new("CanvasGroup")
	content.Name, content.Size, content.BackgroundTransparency, content.ZIndex, content.Parent =
		"Content", UDim2.fromScale(1, 1), 1, 10, frame
	stroke(frame, 3).Color = Config.UI.Tokens.ink
	local kind = string.find(title, "Index") and "Index"
		or (string.find(title, "Haunt") or string.find(title, "Rebirth")) and "Haunt"
		or string.find(title, "Admin") and "Admin"
		or string.find(title, "Daily") and "Daily"
		or "Shop"
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.fromScale(1, string.find(title, "Daily") and 0.17 or 0.148)
	header.BackgroundColor3 = kind == "Index" and Config.UI.Tokens.info or Config.UI.Tokens.go
	header.ZIndex = 11
	header.Parent = content
	corner(header, 12)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8))
	gradient.Rotation = 90
	gradient.Parent = header
	local gloss =
		UI.box(header, "Gloss", UDim2.new(), UDim2.fromScale(1, 0.38), Color3.new(1, 1, 1), 12)
	gloss.BackgroundTransparency = 0.82
	corner(gloss, 12)

	local head = textLabel(
		header,
		string.find(title, "Shop") and "Shop" or string.gsub(title, "^[^%a]+", ""),
		Color3.new(1, 1, 1),
		"title"
	)
	head.Position = UDim2.fromScale(0.05, 0.05)
	head:SetAttribute("TypeSize", Config.UI.Tokens.type.title)
	head.Size = UDim2.fromScale(0.75, 0.8)
	head.ZIndex = 14
	head.TextXAlignment = Enum.TextXAlignment.Left
	if kind == "Index" then
		head.Name, head.Parent = "OverhangTitle", frame
		head.Position, head.Size = UDim2.fromScale(0.05, -0.035), UDim2.fromScale(0.70, 0.13)
	end
	closeButton(frame).Activated:Connect(function()
		UI.closePanel(frame)
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
	list.Parent = content
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 3)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = list
	if grid then
		local layout = Instance.new("UIGridLayout")
		local function fitGrid()
			local columns = Palette.mobile() and gui.AbsoluteSize.X < gui.AbsoluteSize.Y and 2 or 3
			local width = math.max(90, list.AbsoluteSize.X / uiScale.Scale / columns - 12)
			layout.CellSize = UDim2.new(1 / columns, -12, 0, width / 0.78)
		end
		fitGrid()
		list:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitGrid)
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
		if frame.Visible and Center.revealBusy then
			frame.Visible = false
			return
		end
		if frame.Visible then
			frame:SetAttribute("CloseTicket", (frame:GetAttribute("CloseTicket") or 0) + 1)
			for _, child in frame:GetChildren() do
				if
					child:IsA("GuiObject")
					and child ~= content
					and child.Name ~= "Close"
					and child.Name ~= "Shadow"
					and child.Name ~= "OverhangTitle"
				then
					child.Parent = content
				end
			end
			pop.Scale = 0.7
			content.GroupTransparency = 1
			UI.tween(content, 0.12, { GroupTransparency = 0 })
			local order = 0
			for _, child in list:GetChildren() do
				if child:IsA("Frame") then
					order += 1
					local animation = child:FindFirstChildOfClass("UIScale")
						or Instance.new("UIScale")
					animation.Parent, animation.Scale = child, 0.94
					task.delay(math.min(order * 0.018, 0.25), function()
						if child.Parent then
							UI.tween(animation, 0.20, { Scale = 1 }, Enum.EasingStyle.Back)
						end
					end)
				end
			end
			Services.TweenService
				:Create(
					pop,
					TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }
				)
				:Play()
		end
		refreshDim()
	end)
	table.insert(panelFrames, frame)
	return frame, list
end

-- IsAdmin is replicated by the server; every invocation is independently authorized there.
do
	local frame, list = panel("Admin")
	local gear = makeButton(gui, "ADMIN", Color3.fromRGB(138, 138, 138))
	gear.Name = "AdminButton"
	UI.adminButton = gear
	gear.BackgroundColor3 = Color3.fromRGB(138, 138, 138)
	gear.AnchorPoint = Vector2.new(1, 0)
	gear.Position = UDim2.fromScale(0.985, 0.09)
	gear.Size = UDim2.fromOffset(70, 32)
	gear.Parent = gui
	corner(gear, 12)
	local function refresh()
		gear.Visible = player:GetAttribute("IsAdmin") == true
		if not gear.Visible then
			frame.Visible = false
		end
	end
	gear.Activated:Connect(function()
		play(Config.Sounds.Click, 1, 0.35)
		local was = frame.Visible
		for _, f in panelFrames do
			f.Visible = false
		end
		frame.Visible = not was
	end)
	local amount = Instance.new("TextBox")
	amount.Text = tostring(Config.Admin.candy)
	amount.PlaceholderText = "Candy amount"
	amount.FontFace = fontFace("small")
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
			{ "Start King Fight", "king" },
			{ "Start Spooky Hour", "spooky" },
			{ "Start Purge", "purge" },
		}
	do
		local b =
			makeButton(list, entry[1], i == 1 and Color3.fromRGB(219, 39, 48) or Palette.PURPLE)
		b.Size = UDim2.new(1, 0, 0, 48)
		b.LayoutOrder = i == 1 and 99 or i + 1
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
	c.BackgroundColor3 = Config.UI.Tokens.card
	c.Parent = list
	corner(c, 14)
	stroke(c, 2.5).Color = Palette.OUTLINE
	local dot = Instance.new("Frame")
	dot.Position = UDim2.fromOffset(12, 14)
	dot.Size = UDim2.fromOffset(50, 50)
	dot.BackgroundColor3 = color
	dot.Parent = c
	corner(dot)
	stroke(dot, 2.5).Color = Palette.OUTLINE
	local name = textLabel(c, title, Color3.fromRGB(255, 255, 255), "title")
	name.Position = UDim2.fromOffset(74, 6)
	name.Size = UDim2.new(1, -330, 0, 32)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local info = textLabel(c, text, Color3.fromRGB(80, 70, 100), "small")
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
	c.LayoutOrder, c.BackgroundColor3, c.ZIndex, c.Parent = order, color, 12, list
	corner(c, 12)
	stroke(c, 2.5)
	UI.shadow(c)
	local gradient = Instance.new("UIGradient")
	gradient.Color, gradient.Rotation, gradient.Parent =
		ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.48, 0.48, 0.48)), 90, c
	local icon =
		UI.box(c, "Preview", UDim2.fromScale(0.04, 0.12), UDim2.fromScale(0.92, 0.55), color, 13)
	icon.AnchorPoint, icon.Position, icon.BackgroundTransparency =
		Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.12), 1
	-- Compatibility children for the existing scythe layout.
	stroke(icon, 0)
	UI.box(icon, "Frame", UDim2.new(), UDim2.new(), color, 13)
	local lock = textLabel(icon, "", Color3.new(1, 1, 1))
	lock.Size, lock.Visible = UDim2.fromScale(1, 1), false
	local name = textLabel(c, title, Color3.new(1, 1, 1))
	name.Position, name.Size, name.ZIndex =
		UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.13), 16
	name:SetAttribute("TypeSize", Config.UI.Tokens.type.card)
	local info = textLabel(c, text, Color3.new(1, 1, 1))
	info.Position, info.Size, info.ZIndex =
		UDim2.fromScale(0.12, 0.69), UDim2.fromScale(0.76, 0.10), 16
	info.BackgroundColor3, info.BackgroundTransparency = Config.UI.Tokens.well, 0.25
	corner(info, 6)
	local button = makeButton(c, "", Config.UI.Tokens.go)
	button.AnchorPoint, button.Position, button.Size =
		Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.98), UDim2.fromScale(0.94, 0.16)
	button.ZIndex = 16
	button:FindFirstChild("Label"):SetAttribute("TypeSize", Config.UI.Tokens.type.price)
	for _, object in button:GetDescendants() do
		if object:IsA("GuiObject") then
			object.ZIndex += 16
		end
	end
	local tag = textLabel(c, "", Config.UI.Tokens.candy)
	tag.Visible = false
	return {
		frame = c,
		color = color,
		icon = icon,
		info = info,
		button = button,
		lock = lock,
		tag = tag,
	}
end

local function cardState(gc: GridCard, look: string, text: string)
	local owned, locked = look == "owned", look == "locked"
	gc.frame.BackgroundColor3 = gc.color
	gc.icon.BackgroundColor3 = gc.color
	gc.lock.Visible = locked
	gc.info.TextColor3 = Color3.new(1, 1, 1)
	gc.tag.Visible = false
	gc.button.Visible = true
	gc.button.Text = text:gsub("!", ""):gsub(" candy", "")
	local priceIcon = gc.button:FindFirstChild("PriceIcon")
	if not priceIcon then
		priceIcon = Instance.new("Frame")
		priceIcon.Name, priceIcon.BackgroundTransparency, priceIcon.ZIndex =
			"PriceIcon", 1, gc.button.ZIndex + 4
		priceIcon.Position, priceIcon.Size =
			UDim2.fromScale(0.04, 0.18), UDim2.fromScale(0.18, 0.52)
		priceIcon.Parent = gc.button
		UI.candyGlyph(priceIcon)
	end
	priceIcon.Visible = not owned and text:find("%d") ~= nil
	local tick = gc.button:FindFirstChild("EquippedCheck")
	if not tick then
		tick = UI.box(
			gc.button,
			"EquippedCheck",
			UDim2.fromScale(0.06, 0.25),
			UDim2.fromScale(0.14, 0.4),
			Config.UI.Tokens.info,
			36
		)
		tick.BackgroundTransparency = 1
		local shortArm = UI.box(
			tick,
			"Short",
			UDim2.fromScale(0.05, 0.5),
			UDim2.fromScale(0.45, 0.16),
			Color3.new(1, 1, 1),
			37
		)
		shortArm.Rotation = 45
		local longArm = UI.box(
			tick,
			"Long",
			UDim2.fromScale(0.25, 0.35),
			UDim2.fromScale(0.75, 0.16),
			Color3.new(1, 1, 1),
			37
		)
		longArm.Rotation = -45
	end
	tick.Visible = owned and text:find("Equipped") ~= nil
	local label = gc.button:FindFirstChild("Label")
	label.Position = UDim2.fromScale((priceIcon.Visible or tick.Visible) and 0.23 or 0, 0)
	label.Size = UDim2.fromScale((priceIcon.Visible or tick.Visible) and 0.74 or 1, 0.88)
	gc.button.BackgroundColor3 = owned
			and (text:find("Equipped") and Config.UI.Tokens.info or Config.UI.Tokens.off)
		or locked and Config.UI.Tokens.off
		or Config.UI.Tokens.go
	gc.button.TextColor3 = locked and Config.UI.Tokens.stop
		or priceIcon.Visible and Config.UI.Tokens.candy
		or Color3.new(1, 1, 1)
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
			Config.UI.Tokens.rarity[math.min(i, 6)],
			tool.name,
			short(tool.damage)
		)
		gc.info.TextColor3 = Color3.new(1, 1, 1)
		gc.frame.Name = "ScytheCard_" .. tool.id
		gc.lock.Text = ""
		gc.icon.BackgroundTransparency = 1
		gc.icon:FindFirstChildOfClass("UIStroke"):Destroy()
		gc.icon:FindFirstChild("Frame"):Destroy()
		gc.icon.Position = UDim2.fromScale(0.5, 0.12)
		gc.icon.Size = UDim2.fromScale(0.92, 0.55)
		for _, child in gc.frame:GetChildren() do
			if child:IsA("TextLabel") and child ~= gc.tag and child ~= gc.info then
				child.Position = UDim2.fromScale(0.04, 0.01)
				child.Size = UDim2.fromScale(0.92, 0.13)
			end
		end
		gc.info.Position = UDim2.fromScale(0.12, 0.69)
		gc.info.Size = UDim2.fromScale(0.76, 0.10)
		local statIcon = UI.box(
			gc.info,
			"ScytheStat",
			UDim2.fromScale(0.02, 0.06),
			UDim2.fromScale(0.17, 0.82),
			Config.UI.Tokens.card,
			18
		)
		statIcon.BackgroundTransparency = 1
		UI.icon(statIcon, "Carry")
		task.spawn(function()
			local folder = Services.ReplicatedStorage:WaitForChild("PatchScytheIcons", 10)
			local model = folder and folder:WaitForChild(tool.id, 10)
			if model then
				Palette.renderModel(gc.icon, model)
			else
				warn("Missing scythe preview: " .. tool.id)
			end
		end)
		cards[tool.id] = gc
		gc.tag =
			UI.sticker(gc.frame, i == #Config.Tools and "BEST" or "NEXT", Config.UI.Tokens.candy)
		gc.tag.Visible = i == #Config.Tools
		if i == 7 then
			UI.secret(gc.frame)
		end
		local b = gc.button
		b.Size, b.Position = UDim2.fromScale(0.92, 0.16), UDim2.fromScale(0.5, 0.98)
		b.Activated:Connect(function()
			if not tool.cost then
				hint("Only the King Fight MVP gets the " .. tool.name .. "!")
				return
			end
			local ok, message = buyTool:InvokeServer(tool.id)
			if ok then
				play(Config.Sounds.Buy, 1, 0.8)
				Center.purchaseBurst()
				toast(tool.name, "Scythe equipped")
				candyShower(6)
				local scale = gc.frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
				scale.Parent, scale.Scale = gc.frame, 1.08
				UI.tween(scale, 0.20, { Scale = 1 }, Enum.EasingStyle.Back)
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
		local nextId, cheapest = nil, math.huge
		for _, tool in Config.Tools do
			if
				tool.cost
				and not owned[tool.id]
				and tool.id ~= held
				and tool.cost <= candyValue.Value
				and tool.cost < cheapest
			then
				nextId, cheapest = tool.id, tool.cost
			end
		end
		for i, tool in Config.Tools do
			local gc = cards[tool.id]
			if tool.id == held then
				cardState(gc, "owned", "Equipped!")
			elseif owned[tool.id] then
				cardState(gc, "owned", "Owned!")
			elseif not tool.cost then
				cardState(gc, "locked", "MVP DROP")
			else
				local price = short(tool.cost) .. " candy"
				cardState(gc, candyValue.Value >= tool.cost and "buy" or "locked", price)
			end
			gc.tag.Text = i == #Config.Tools and "BEST" or "NEXT"
			gc.tag.Visible = i == #Config.Tools or tool.id == nextId
			if i == 7 then
				gc.frame.BackgroundColor3 = Color3.new(1, 1, 1)
			end
		end
	end
	player:GetAttributeChangedSignal("Tools"):Connect(refreshToolCards)
	player:GetAttributeChangedSignal("Tool"):Connect(refreshToolCards)
end
local upgradeCards: { [string]: GridCard } = {}
local refreshUpgradeCards -- forward: a failed buy shows its reason, then refreshes
-- Only Boots remains in the upgrade shop.
Palette.UPGRADE_ORDER = { "Boots" }
Palette.UPGRADE_COLOR = {
	Boots = Color3.fromRGB(255, 210, 65),
	Stack = Color3.fromRGB(255, 150, 50),
	Lucky = Color3.fromRGB(110, 210, 90),
}
for i, id in Palette.UPGRADE_ORDER do
	local info = Config.Upgrades[id]
	local gc = gridCard(upgradeList, i, Palette.UPGRADE_COLOR[id], info.title, info.text)
	UI.icon(gc.icon, "Sprint")
	upgradeCards[id] = gc
	local b = gc.button
	b.Activated:Connect(function()
		local ok, message = buyUpgrade:InvokeServer(id)
		if ok then
			play(Config.Sounds.Buy, 1, 0.8)
			Center.purchaseBurst()
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
		gc.frame.Visible = not info.cut and (id ~= "Lucky" or unlocked("LuckySwing"))
		gc.info.Text = string.format("Level %d/%d", level, info.max)
		if level >= info.max then
			cardState(gc, "owned", "MAX!")
		else
			local cost = Config.upgradeCost(id, level)
			cardState(gc, candyValue.Value >= cost and "buy" or "locked", "🍬 " .. short(cost))
		end
	end
end
for _, id in Palette.UPGRADE_ORDER do
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

-- Zone collection: lazy previews, one detail card and one server-authoritative reward action.
local indexPanel, indexList = panel("Index")
local IndexUI: { [string]: any } = { cells = {}, zones = {}, count = 0, zone = 1 }
function IndexUI.set(attribute)
	local result = {}
	for key in string.gmatch(player:GetAttribute(attribute) or "", "[^,]+") do
		result[key] = true
	end
	return result
end
function IndexUI.discovered(seed)
	for key in IndexUI.set("Index") do
		if string.match(key, "^([^:]+):") == seed.id then
			return true
		end
	end
	return false
end
function IndexUI.claim(key)
	if IndexUI.busy or IndexUI.count == 0 then
		return
	end
	IndexUI.busy = true
	task.spawn(function()
		local ok, result = pcall(function()
			return remotes:WaitForChild("ClaimIndex"):InvokeServer(key)
		end)
		IndexUI.busy = false
		if ok and result and result.candy and result.candy > 0 then
			toast("Index reward", "+" .. short(result.candy))
			if candyShower then
				candyShower(6)
			end
		end
		IndexUI.refresh()
	end)
end
function IndexUI.rarity(seed)
	for i, rarity in Config.Rarities do
		if rarity.name == Config.Pets[seed.pet].rarity then
			return Config.UI.Tokens.rarity[math.min(i, 6)], rarity.name
		end
	end
	return Config.UI.Tokens.rarity[1], "Common"
end
function IndexUI.preview(seed, host, silhouette)
	local folder = Services.ReplicatedStorage:FindFirstChild("PetPreviews")
	local source = folder and folder:FindFirstChild(seed.pet)
	if source then
		return Palette.renderModel(host, source, silhouette)
	end
	return nil
end
function IndexUI.select(seed)
	IndexUI.selected = seed
	local found = IndexUI.discovered(seed)
	local color, rarity = IndexUI.rarity(seed)
	IndexUI.detailName.Text = found and Config.Pets[seed.pet].display or "Undiscovered"
	IndexUI.detailRarity.Text, IndexUI.detailRarity.TextColor3 = rarity, color
	IndexUI.detailRate.Text = found and ("+" .. rateShort(seed.income) .. "/s") or "Hatch first"
	for _, child in IndexUI.hero:GetChildren() do
		child:Destroy()
	end
	IndexUI.heroView = IndexUI.preview(seed, IndexUI.hero, not found)
	IndexUI.heroAngle = 0
end
function IndexUI.build()
	UI.indexBuilt = true
	for _, cell in IndexUI.cells do
		cell.tile:Destroy()
	end
	table.clear(IndexUI.cells)
	local zone = IndexUI.zones[IndexUI.zone]
	for _, entry in IndexUI.zones do
		if not entry.view then
			local zones = garden:FindFirstChild("Zones")
			local folder = zones and zones:FindFirstChild(entry.id)
			local source = folder and folder:FindFirstChild("HoardPumpkin", true)
			if source then
				for _, child in entry.icon:GetChildren() do
					child:Destroy()
				end
				entry.view = Palette.renderModel(entry.icon, source)
			end
		end
	end
	for i, seed in Config.Seeds do
		if zone.config.weights[seed.id] then
			local color = IndexUI.rarity(seed)
			local tile = makeButton(indexList, "", Config.UI.Tokens.off)
			tile.Name, tile.LayoutOrder, tile.ZIndex = "Pet_" .. seed.pet, i, 13
			for _, child in tile:GetChildren() do
				child:Destroy()
			end
			tile.BackgroundTransparency, tile.BackgroundColor3 = 0, color
			corner(tile, 10)
			stroke(tile, 2.5)
			local host = UI.box(
				tile,
				"Pet",
				UDim2.fromScale(0.04, 0.04),
				UDim2.fromScale(0.92, 0.92),
				color,
				14
			)
			host.BackgroundTransparency = 1
			local view = IndexUI.preview(seed, host, not IndexUI.discovered(seed))
			local unknown = textLabel(tile, "?", Color3.new(1, 1, 1))
			unknown.Size, unknown.ZIndex = UDim2.fromScale(1, 1), 17
			tile.Activated:Connect(function()
				IndexUI.select(seed)
			end)
			IndexUI.cells[seed.pet] = {
				tile = tile,
				host = host,
				view = view,
				unknown = unknown,
				seed = seed,
				color = color,
			}
		end
	end
	if not IndexUI.selected or not zone.config.weights[IndexUI.selected.id] then
		for _, seed in Config.Seeds do
			if zone.config.weights[seed.id] then
				IndexUI.select(seed)
				break
			end
		end
	else
		IndexUI.select(IndexUI.selected)
	end
	IndexUI.refresh()
end
function IndexUI.refresh()
	local claims, milestones = IndexUI.set("IndexClaims"), IndexUI.set("IndexMilestones")
	local total, count, zoneFound, zoneTotal = 0, 0, 0, 0
	local zone = IndexUI.zones[IndexUI.zone]
	for _, seed in Config.Seeds do
		local found = IndexUI.discovered(seed)
		if found then
			total += 1
			if not claims[seed.pet] then
				count += 1
			end
		end
		if zone and zone.config.weights[seed.id] then
			zoneTotal += 1
			if found then
				zoneFound += 1
			end
		end
		local cell = IndexUI.cells[seed.pet]
		if cell then
			cell.tile.BackgroundColor3 = found and cell.color
				or cell.color:Lerp(Config.UI.Tokens.ink, 0.55)
			cell.unknown.Visible = not found
			if not cell.view and indexPanel.Visible then
				cell.view = IndexUI.preview(seed, cell.host, not found)
			end
			if cell.view then
				cell.view.ImageColor3 = found and Color3.new(1, 1, 1) or Config.UI.Tokens.ink
			end
		end
	end
	for _, milestone in Config.IndexRewards.milestones do
		if
			total * 100 >= #Config.Seeds * milestone.percent
			and not milestones[tostring(milestone.percent)]
		then
			count += 1
		end
	end
	IndexUI.count = count
	IndexUI.progress.Text =
		string.format("%s %d/%d", zone and zone.name or "Patch", zoneFound, zoneTotal)
	IndexUI.fill.Size = UDim2.fromScale(zoneFound / math.max(1, zoneTotal), 1)
	IndexUI.global.Text = string.format("Unlocked %d/%d", total, #Config.Seeds)
	IndexUI.globalFill.Size = UDim2.fromScale(total / #Config.Seeds, 1)
	IndexUI.all.Active, IndexUI.all.BackgroundColor3 =
		count > 0, count > 0 and Config.UI.Tokens.go or Config.UI.Tokens.off
	IndexUI.badge.Text, IndexUI.badge.Visible = tostring(count), count > 0
	if IndexUI.hudBadge then
		IndexUI.hudBadge.Text, IndexUI.hudBadge.Visible = "!", count > 0
	end
	for i, entry in IndexUI.zones do
		entry.outline.Color = i == IndexUI.zone and Color3.new(1, 1, 1) or Config.UI.Tokens.ink
	end
end
do
	indexList:FindFirstChildOfClass("UIListLayout"):Destroy()
	indexList.BackgroundColor3, indexList.BackgroundTransparency, indexList.ZIndex =
		Config.UI.Tokens.well, 0, 12
	corner(indexList, 10)
	local layout = Instance.new("UIGridLayout")
	layout.SortOrder, layout.CellPadding, layout.Parent =
		Enum.SortOrder.LayoutOrder, UDim2.fromOffset(6, 6), indexList
	local rail = UI.box(indexPanel, "ZoneRail", UDim2.new(), UDim2.new(), Config.UI.Tokens.well, 12)
	rail.BackgroundTransparency = 1
	for i, entry in
		{
			{ "Zone1", "Patch", "Pets", { "Zone1" } },
			{ "Zone3", "Woods", "Pets", { "Zone3", "Zone4" } },
			{ "Zone5", "Castle", "King", { "Zone5", "Zone6", "Zone7" } },
			{ "Zone2", "Graveyard", "Clock", { "Zone2" } },
		}
	do
		local members = {}
		for _, zoneId in entry[4] do
			for _, seedId in Config.Zones[zoneId].pets do
				members[seedId] = true
			end
		end
		if entry[2] == "Castle" then
			for _, seed in Config.Seeds do
				if seed.pet == "Kinglet" then
					members[seed.id] = true
				end
			end
		end
		local tile = makeButton(rail, entry[2], Config.UI.Tokens.zones[entry[2]])
		tile.ZIndex = 13
		for _, d in tile:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex += 13
			end
		end
		local icon = UI.box(
			tile,
			"ZoneProp",
			UDim2.fromScale(0.15, 0.03),
			UDim2.fromScale(0.70, 0.62),
			Config.UI.Tokens.panel,
			16
		)
		icon.BackgroundTransparency = 1
		UI.icon(icon, entry[3])
		local label = tile:FindFirstChild("Label")
		label.Position, label.Size = UDim2.fromScale(0, 0.65), UDim2.fromScale(1, 0.24)
		IndexUI.zones[i] = {
			tile = tile,
			outline = stroke(tile, 2),
			config = { weights = members },
			name = entry[2],
			id = entry[1],
			icon = icon,
		}
		tile.Activated:Connect(function()
			IndexUI.zone = i
			IndexUI.build()
		end)
	end
	local track =
		UI.box(indexPanel, "ZoneProgress", UDim2.new(), UDim2.new(), Config.UI.Tokens.off, 12)
	corner(track, 6)
	IndexUI.fill = UI.box(track, "Fill", UDim2.new(), UDim2.new(), Config.UI.Tokens.good, 13)
	corner(IndexUI.fill, 6)
	IndexUI.progress = textLabel(track, "", Color3.new(1, 1, 1))
	IndexUI.progress.Size, IndexUI.progress.ZIndex = UDim2.fromScale(0.88, 1), 16
	local gift = UI.box(
		track,
		"GiftPip",
		UDim2.fromScale(0.88, -0.05),
		UDim2.fromScale(0.12, 1.1),
		Config.UI.Tokens.panel,
		17
	)
	gift.BackgroundTransparency = 1
	UI.icon(gift, "Daily")
	local detail = UI.box(indexPanel, "Detail", UDim2.new(), UDim2.new(), Config.UI.Tokens.card, 12)
	corner(detail, 12)
	stroke(detail, 2).Color = Config.UI.Tokens.cardStroke
	IndexUI.hero = UI.box(
		detail,
		"Hero",
		UDim2.fromScale(0.03, 0.01),
		UDim2.fromScale(0.94, 0.55),
		Config.UI.Tokens.card,
		13
	)
	IndexUI.hero.BackgroundTransparency = 1
	IndexUI.detailName = textLabel(detail, "", Color3.new(1, 1, 1))
	IndexUI.detailName.Position, IndexUI.detailName.Size, IndexUI.detailName.ZIndex =
		UDim2.fromScale(0.03, 0.57), UDim2.fromScale(0.94, 0.17), 16
	IndexUI.detailName.TextWrapped = true
	IndexUI.detailRarity = textLabel(detail, "", Config.UI.Tokens.candy)
	IndexUI.detailRarity.Position, IndexUI.detailRarity.Size, IndexUI.detailRarity.ZIndex =
		UDim2.fromScale(0.03, 0.75), UDim2.fromScale(0.94, 0.09), 16
	local detailCandy = UI.box(
		detail,
		"Candy",
		UDim2.fromScale(0.04, 0.87),
		UDim2.fromScale(0.14, 0.10),
		Config.UI.Tokens.candy,
		16
	)
	detailCandy.BackgroundTransparency = 1
	UI.candyGlyph(detailCandy)
	IndexUI.detailRate = textLabel(detail, "", Config.UI.Tokens.good)
	IndexUI.detailRate.Position, IndexUI.detailRate.Size, IndexUI.detailRate.ZIndex =
		UDim2.fromScale(0.20, 0.87), UDim2.fromScale(0.77, 0.10), 16
	local rewards =
		UI.box(indexPanel, "Rewards", UDim2.new(), UDim2.new(), Config.UI.Tokens.well, 12)
	corner(rewards, 10)
	local rewardTitle = textLabel(rewards, "Rewards", Color3.new(1, 1, 1))
	rewardTitle.Size, rewardTitle.ZIndex = UDim2.fromScale(1, 0.30), 16
	IndexUI.all = makeButton(rewards, "CLAIM", Config.UI.Tokens.go)
	IndexUI.all.Position, IndexUI.all.Size, IndexUI.all.ZIndex =
		UDim2.fromScale(0.05, 0.38), UDim2.fromScale(0.90, 0.55), 16
	for _, d in IndexUI.all:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += 16
		end
	end
	IndexUI.all.Activated:Connect(function()
		IndexUI.claim("All")
	end)
	IndexUI.badge = textLabel(IndexUI.all, "", Color3.new(1, 1, 1))
	IndexUI.badge.Position, IndexUI.badge.Size, IndexUI.badge.ZIndex =
		UDim2.fromScale(0.80, -0.12), UDim2.fromScale(0.23, 0.50), 35
	IndexUI.badge.BackgroundColor3, IndexUI.badge.BackgroundTransparency = Config.UI.Tokens.stop, 0
	corner(IndexUI.badge)
	IndexUI.global = textLabel(indexPanel, "", Color3.new(1, 1, 1))
	IndexUI.global.Position, IndexUI.global.Size, IndexUI.global.ZIndex =
		UDim2.fromScale(0.08, 0.91), UDim2.fromScale(0.84, 0.045), 16
	local globalTrack = UI.box(
		indexPanel,
		"GlobalProgress",
		UDim2.fromScale(0.08, 0.966),
		UDim2.fromScale(0.84, 0.009),
		Config.UI.Tokens.off,
		12
	)
	IndexUI.globalFill =
		UI.box(globalTrack, "Fill", UDim2.new(), UDim2.new(), Config.UI.Tokens.good, 13)
	local function fit()
		local portrait = Palette.mobile() and gui.AbsoluteSize.X < gui.AbsoluteSize.Y
		rail.Position, rail.Size =
			UDim2.fromScale(0.025, 0.16),
			UDim2.fromScale(portrait and 0.95 or 0.15, portrait and 0.11 or 0.72)
		for i, entry in IndexUI.zones do
			entry.tile.Position = portrait and UDim2.fromScale((i - 1) * 0.25, 0)
				or UDim2.fromScale(0, (i - 1) * 0.25)
			entry.tile.Size = portrait and UDim2.fromScale(0.235, 1) or UDim2.fromScale(1, 0.235)
		end
		track.Position, track.Size =
			UDim2.fromScale(portrait and 0.025 or 0.20, portrait and 0.29 or 0.16),
			UDim2.fromScale(portrait and 0.95 or 0.48, 0.055)
		indexList.Position, indexList.Size =
			UDim2.fromScale(portrait and 0.025 or 0.20, portrait and 0.365 or 0.24),
			UDim2.fromScale(portrait and 0.54 or 0.48, portrait and 0.525 or 0.65)
		detail.Position, detail.Size =
			UDim2.fromScale(portrait and 0.59 or 0.71, portrait and 0.365 or 0.16),
			UDim2.fromScale(portrait and 0.385 or 0.265, portrait and 0.34 or 0.47)
		rewards.Position, rewards.Size =
			UDim2.fromScale(portrait and 0.59 or 0.71, portrait and 0.73 or 0.67),
			UDim2.fromScale(portrait and 0.385 or 0.265, portrait and 0.16 or 0.22)
		local columns = portrait and 2 or 4
		local width = (indexList.AbsoluteSize.X / uiScale.Scale - 24 - (columns - 1) * 6) / columns
		layout.CellSize = UDim2.fromOffset(math.max(20, width), math.max(20, width * 1.15))
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	indexList:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	Services.UserInputService.LastInputTypeChanged:Connect(fit)
	fit()
	Services.RunService.RenderStepped:Connect(function(dt)
		if indexPanel.Visible and IndexUI.heroView then
			UI.rotatePreview(IndexUI.heroView, dt * math.rad(15))
		end
	end)
end
indexPanel:GetPropertyChangedSignal("Visible"):Connect(function()
	if indexPanel.Visible then
		IndexUI.build()
	end
end)
for _, attribute in { "Index", "IndexClaims", "IndexMilestones", "Loaded" } do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		IndexUI.refresh()
		if indexPanel.Visible and IndexUI.selected then
			IndexUI.select(IndexUI.selected)
		end
	end)
end
IndexUI.refresh()
task.spawn(function()
	local previews = Services.ReplicatedStorage:WaitForChild("PetPreviews")
	previews.ChildAdded:Connect(function()
		if indexPanel.Visible then
			IndexUI.build()
		end
	end)
end)
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
		music.SoundGroup = FarmFX.groups.Music
		music.Parent = Services.SoundService
		music:Play()
		tracks[phase] = music
	end
	local musicOn = true
	local function refreshMusic()
		local phase = state:GetAttribute("Phase") or "Day"
		for name, music in tracks do
			local target = (musicOn and name == phase) and Config.MusicVolume or 0
			Services.TweenService:Create(music, TweenInfo.new(2), { Volume = target }):Play()
		end
	end
	state:GetAttributeChangedSignal("Phase"):Connect(refreshMusic)
	refreshMusic()
	-- Spooky Hour plays the day loop a little faster (the "faster variant" of the hub music).
	local function refreshTempo()
		local fast = state:GetAttribute("SpookyEnds") ~= nil
		for name, music in tracks do
			local speed = (fast and name == "Day") and 1.12 or 1
			Services.TweenService
				:Create(music, TweenInfo.new(1.5), { PlaybackSpeed = speed })
				:Play()
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
function UI.tile(id, color, slot)
	local b = makeButton(gui, "", color)
	b.Name, b.AnchorPoint = id .. "Tile", Vector2.new(1, 0)
	local icon = Instance.new("Frame")
	icon.BackgroundTransparency, icon.Position, icon.Size, icon.ZIndex, icon.Parent =
		1, UDim2.fromScale(0.16, 0.04), UDim2.fromScale(0.68, 0.65), 5, b
	UI.icon(icon, id)
	local caption = textLabel(b, id, Color3.new(1, 1, 1))
	caption:SetAttribute("TypeSize", Config.UI.Tokens.type.caption)
	caption.Position, caption.Size, caption.ZIndex =
		UDim2.fromScale(0, 0.65), UDim2.fromScale(1, 0.25), 7
	local function layout()
		local touch, h = Palette.mobile(), gui.AbsoluteSize.Y / uiScale.Scale
		b.Position = UDim2.fromScale(
			touch and 0.99 or 0.992,
			(touch and 0.30 or 0.36) + (slot - 1) * (touch and 0.10 or 0.104)
		)
		b.Size = UDim2.fromOffset(h * (touch and 0.09 or 0.070), h * (touch and 0.09 or 0.070))
		icon.Position = UDim2.fromScale(touch and 0.16 or 0.11, 0.04)
		icon.Size = UDim2.fromScale(touch and 0.68 or 0.78, touch and 0.62 or 0.78)
		caption.Position = UDim2.fromScale(touch and 0 or -0.35, touch and 0.66 or 1.02)
		caption.Size = UDim2.fromScale(touch and 1 or 1.35, touch and 0.30 or 0.34)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Services.UserInputService.LastInputTypeChanged:Connect(layout)
	layout()
	return b
end
do
	local settings, list = panel("Settings")
	local sound = makeButton(list, "Sound: on", Palette.PURPLE)
	sound.Size = UDim2.new(1, 0, 0, 48)
	sound.Activated:Connect(function()
		sound.Text = toggleSound() and "Sound: on" or "Sound: off"
	end)
	UI.settingsList = list
	if UI.adminButton then
		UI.adminButton.Parent = list
		UI.adminButton.AnchorPoint = Vector2.zero
		UI.adminButton.Size = UDim2.new(1, 0, 0, 48)
		UI.adminButton.LayoutOrder = 10
		UI.adminButton.Position = UDim2.new()
	end
	local top = Instance.new("ScreenGui")
	top.Name, top.ScreenInsets, top.ResetOnSpawn, top.DisplayOrder =
		"TopIcons", Enum.ScreenInsets.TopbarSafeInsets, false, 10
	top.Parent = player:WaitForChild("PlayerGui")
	local gear = makeButton(top, "", Config.UI.Tokens.ink)
	gear.Name, gear.AnchorPoint, gear.Position, gear.Size =
		"SettingsGear", Vector2.new(1, 0), UDim2.new(1, -16, 0, 8), UDim2.fromOffset(36, 36)
	for _, child in gear:GetChildren() do
		if child:IsA("Frame") then
			child.BackgroundTransparency = 0.4
			local round = child:FindFirstChildOfClass("UICorner")
			if round then
				round.CornerRadius = UDim.new(0.5, 0)
			end
		end
	end
	UI.icon(gear, "Gear")
	gear.Activated:Connect(function()
		local open = not settings.Visible
		for _, frame in panelFrames do
			frame.Visible = false
		end
		sound.Text = sfxOn and "Sound: on" or "Sound: off"
		settings.Visible = open
	end)
end

local indexButton = pill("📖 Index", Config.UI.index, 2)
-- Red badge: Index entries found since the Index was last opened.
local indexBadge = pillBadge(indexButton)
IndexUI.hudBadge = indexBadge
IndexUI.refresh()

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
	for name, text in
		{
			Sell = "The Witch buys pumpkins now! Pick some up from your pen and sell them.",
			Brew = "The Magic Cauldrons are open! Brew pumpkins for x2 to x10.",
			King = "Join the King Fight at the throne. Bonk him for candy!",
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
local hauntInfo = textLabel(hauntList, "", Color3.fromRGB(225, 220, 240), "small")
hauntInfo:FindFirstChildOfClass("UIStroke"):Destroy()
hauntInfo.LayoutOrder = 0
hauntInfo.Size = UDim2.new(1, -10, 0, 64)
hauntInfo.TextScaled = false
hauntInfo.TextSize = 17
hauntInfo.TextWrapped = true
hauntInfo.TextXAlignment = Enum.TextXAlignment.Left
local hauntCard, hauntCardText = card(hauntList, 1, Color3.fromRGB(150, 90, 255), "Rebirth", "")
local hauntGo = makeButton(hauntCard, "", Color3.fromRGB(150, 90, 255))
hauntGo.AnchorPoint = Vector2.new(1, 0.5)
hauntGo.Position = UDim2.new(1, -12, 0.5, 0)
hauntGo.Size = UDim2.fromOffset(200, 52)
-- Soul skill tree: a column per branch, three nodes top to bottom joined by short lines.
-- Node states: owned (bright, check), buyable (pulsing outline, cost), locked (dim, lock).
Palette.BRANCH_COLOR = {
	Farmer = Color3.fromRGB(255, 140, 40),
	Witch = Color3.fromRGB(165, 95, 255),
	Hunter = Color3.fromRGB(235, 60, 60),
}
Palette.BRANCH_ICON = { Farmer = "🌱", Witch = "🧪", Hunter = "🔨" }
Palette.DIM_TEXT = Color3.fromRGB(150, 140, 160)
Palette.NODE_H, Palette.LINK_H, Palette.TREE_TOP, Palette.BRANCH_H = 80, 16, 34, 30
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
tree.Size = UDim2.new(
	1,
	-10,
	0,
	Palette.TREE_TOP + Palette.BRANCH_H + 3 * Palette.NODE_H + 2 * Palette.LINK_H + 6
)
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
		play(Config.Sounds.Buy, 1, 0.8)
		Center.purchaseBurst()
		toast(skill.title .. "!", skill.text)
	else
		node.status.Text = tostring(message or "?")
		node.status.TextColor3 = Color3.fromRGB(255, 130, 130)
		node.holdUntil = os.clock() + 1
		task.delay(1.05, refreshTree)
	end
end

for b, branch in Config.SkillBranches do
	local color = Palette.BRANCH_COLOR[branch] or Color3.fromRGB(200, 200, 200)
	local col = Instance.new("Frame")
	col.BackgroundTransparency = 1
	col.Position = UDim2.new((b - 1) / 3, 4, 0, Palette.TREE_TOP)
	col.Size = UDim2.new(1 / 3, -8, 1, -Palette.TREE_TOP)
	col.Parent = tree
	local head = textLabel(
		col,
		(Palette.BRANCH_ICON[branch] or "") .. " " .. string.upper(branch),
		color,
		"title"
	)
	head.Size = UDim2.new(1, 0, 0, Palette.BRANCH_H - 4)
	for tier = 1, 3 do
		local skill = skillAt[branch .. ":" .. tier]
		if not skill then
			continue
		end
		local y = Palette.BRANCH_H + (tier - 1) * (Palette.NODE_H + Palette.LINK_H)
		local link: Frame? = nil
		if tier > 1 then
			local l = Instance.new("Frame")
			l.AnchorPoint = Vector2.new(0.5, 0)
			l.Position = UDim2.new(0.5, 0, 0, y - Palette.LINK_H)
			l.Size = UDim2.fromOffset(6, Palette.LINK_H)
			l.BorderSizePixel = 0
			l.BackgroundColor3 = Color3.fromRGB(70, 60, 80)
			l.Parent = col
			link = l
		end
		local nodeButton = Instance.new("TextButton")
		nodeButton.FontFace = fontFace("button")
		nodeButton.Text = ""
		nodeButton.AutoButtonColor = true
		nodeButton.Position = UDim2.fromOffset(0, y)
		nodeButton.Size = UDim2.new(1, 0, 0, Palette.NODE_H)
		nodeButton.BackgroundColor3 = color
		nodeButton.Parent = col
		corner(nodeButton, 12)
		local _, outline = chunky(nodeButton)
		local title = textLabel(nodeButton, skill.title, Color3.fromRGB(255, 255, 255), "title")
		title.Position = UDim2.fromOffset(6, 4)
		title.Size = UDim2.new(1, -12, 0, 26)
		title.ZIndex = nodeButton.ZIndex + 3
		local info = textLabel(nodeButton, skill.text, Color3.fromRGB(255, 255, 255), "small")
		info.Position = UDim2.fromOffset(6, 32)
		info.Size = UDim2.new(1, -12, 0, 18)
		info.ZIndex = nodeButton.ZIndex + 3
		local status = textLabel(nodeButton, "", Color3.fromRGB(255, 255, 255))
		status.Position = UDim2.fromOffset(6, 53)
		status.Size = UDim2.new(1, -12, 0, 22)
		status.ZIndex = nodeButton.ZIndex + 3
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
			play(Config.Sounds.Click, 1, 0.35)
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
			node.button.BackgroundColor3 = node.color:Lerp(Palette.DARK, 0.55)
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
			node.button.BackgroundColor3 = node.color:Lerp(Palette.DARK, 0.82)
			node.title.Text = "🔒 " .. skill.title
			node.outline.Color = Color3.fromRGB(20, 10, 30)
			node.outline.Thickness = 2.5
			textColor = Palette.DIM_TEXT
			statusText, statusColor = string.format("🔒 %d 👻", skill.cost), Palette.DIM_TEXT
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
Services.RunService.Heartbeat:Connect(function()
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
		text = "Double candy from pets, sales and smashing",
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
		kind = "product",
		name = "CandySmall",
		title = "Candy Bag",
		text = tostring(Config.CandyPackMinutes.CandySmall)
			.. " minutes of your income (minimum 300 candy)",
		color = Color3.fromRGB(255, 150, 210),
	},
	{
		kind = "product",
		name = "CandyBig",
		title = "Candy Chest",
		text = tostring(Config.CandyPackMinutes.CandyBig)
			.. " minutes of your income (minimum 1.2k candy)",
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
		Services.MarketplaceService:PromptGamePassPurchase(player, entry.id)
	else
		Services.MarketplaceService:PromptProductPurchase(player, entry.id)
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
			return Services.MarketplaceService:GetProductInfo(id, infoType)
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
			play(Config.Sounds.Buy, 1, 0.8)
			Center.purchaseBurst()
		end
	end)
end

-- Left pills (Steal an Egg footprint): exactly Shop and Index. Each pill opens one panel at a time
-- (the same pill closes it again). Shop is one panel with tabs (Scythes / Upgrades / Haunt once
-- its gate opens / Robux while any ID is set) and a small speaker (mute) button.
do
	local panels = panelFrames
	local SHOP_TABS = {
		{ name = "Scythes", label = "Scythes", frame = toolPanel },
		{ name = "Upgrades", label = "Upgrades", frame = upgradePanel },
	}
	local TAB_ON, TAB_OFF = Config.UI.Tokens.info, Config.UI.Tokens.off
	local hasRobux = #shopCards > 0
	-- HUD always opens on Scythes.
	local tabButtons: { { button: TextButton, name: string } } = {}

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
		-- Tab colour is set from the actual visible page below.
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
		local list = frame:FindFirstChildWhichIsA("ScrollingFrame", true)
		if list then
			list.Position = UDim2.fromScale(0.025, 0.28)
			list.Size = UDim2.fromScale(0.95, 0.69)
		end
		for _, other in SHOP_TABS do
			local b = makeButton(frame, other.label, TAB_OFF)
			b.Size = UDim2.fromScale(0.20, 0.10)
			corner(b:FindFirstChild("Face"), 24)
			b.Activated:Connect(function()
				openShop(other.name)
			end)
			table.insert(tabButtons, { button = b, name = other.name })
		end
	end
	layoutTabs()
	-- Haunt costs millions: its tab waits for the HauntPillAt gate (lifetime candy).
	player:GetAttributeChangedSignal("Unlock_Haunt"):Connect(layoutTabs)

	local shopButton = pill("🛒 Shop", Config.UI.shop, 1)
	shopButton.Activated:Connect(function()
		openShop(if shopOpen() then nil else "Scythes")
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
		local name = kind == "Upgrades" and "Upgrades" or "Scythes"
		local frame = name == "Scythes" and toolPanel or upgradePanel
		openShop(if frame.Visible then nil else name)
	end)

	indexButton.Activated:Connect(function()
		toggle(indexPanel)
		IndexUI.refresh()
	end)
end

remotes:WaitForChild("IndexNew").OnClientEvent:Connect(function(keys: { string })
	IndexUI.refresh()
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
	if text == "PUMPKIN KING RISES! PET + LOOT!" and not unlocked("King") then
		return
	end
	if string.sub(text, 1, 9) == "THE PURGE" and #Config.Purge.minutes == 0 then
		return
	end
	if string.sub(text, 1, 9) == "THE PURGE" then
		banner(
			text,
			"Best pet protected · Hold E 2s · One steal per victim",
			5,
			Color3.fromRGB(235, 105, 205)
		)
		play(Config.Sounds.Reveal, 1, 0.6)
	elseif text == "PUMPKIN KING RISES! PET + LOOT!" then
		banner(text, nil, 3, Color3.fromRGB(255, 80, 70))
		play(Config.Sounds.Growl, 1, 0.9)
	else
		toast(text)
	end
	play(Config.Sounds.Brew, 0.7, 0.8)
end)

function UI.rotatePreview(view, angle)
	local world = view:FindFirstChildOfClass("WorldModel")
	local model = world and world:FindFirstChildOfClass("Model")
	if not model then
		return
	end
	local cf = model:GetBoundingBox()
	model:PivotTo(
		CFrame.new(cf.Position)
			* CFrame.Angles(0, angle, 0)
			* CFrame.new(-cf.Position)
			* model:GetPivot()
	)
	if UI.fitters and UI.fitters[view] then
		UI.fitters[view]()
	end
end
function UI.hatchConfetti(parent, color, legendary)
	local box = UI.box(
		parent,
		"ConfettiBounds",
		UDim2.fromScale(0.2, 0.16),
		UDim2.fromScale(0.6, 0.6),
		color,
		20
	)
	box.BackgroundTransparency, box.ClipsDescendants = 1, true
	for i = 1, legendary and 40 or 20 do
		local tint = i % 2 == 0 and Color3.new(1, 1, 1) or color
		if legendary and i % 3 == 0 then
			tint = Config.UI.Tokens.candy
		end
		local piece =
			UI.box(box, "Confetti", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(6, 10), tint, 21)
		piece.Rotation = math.random(0, 360)
		UI.tween(piece, 0.65, {
			Position = UDim2.fromScale(math.random(), math.random()),
			Rotation = piece.Rotation + 180,
			BackgroundTransparency = 1,
		})
	end
	task.delay(0.7, function()
		box:Destroy()
	end)
end
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
	blur.Parent = Services.Lighting
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
		local previews = Services.ReplicatedStorage:FindFirstChild("PetPreviews")
		look = look or (previews and previews:FindFirstChild(pet or seed.pet))
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
		_kind: string?,
		pet: string?,
		weight: number?
	)
		local seed = seedById[seedId]
		if not seed then
			return
		end
		Center.acquire()
		local rarity = rarityOf(seed.order)
		local petDef = Config.Pets[pet or seed.pet]
		if petDef then
			for _, r in Config.Rarities do
				if r.name == petDef.rarity then
					rarity = r
					break
				end
			end
		end
		local color = rarity.color
		for i, r in Config.Rarities do
			if r.name == rarity.name then
				color = Config.UI.Tokens.rarity[math.min(i, 6)]
			end
		end
		-- No scene blur while the HUD is visible.
		blur.Size = 0
		flash.BackgroundTransparency = 1
		local catcher = Instance.new("TextButton")
		catcher.Name, catcher.Text, catcher.AutoButtonColor = "Reveal", "", false
		catcher.FontFace = fontFace("button")
		catcher.Size, catcher.BackgroundColor3, catcher.BackgroundTransparency =
			UDim2.fromScale(1, 1), Config.UI.Tokens.ink, 1
		catcher.ZIndex, catcher.Parent = 2, revealGui
		Center.register(catcher)
		-- Keep the world visible during the smaller rare-pet reveal.
		-- World cracking owns the hatch; this side card names rare pets.

		play(Config.Sounds.Reveal, isNew and 1.08 or 1, 0.8)
		local h = revealGui.AbsoluteSize.Y
		local height = math.min(
			h * Config.UI.Tokens.layout.hatchHeight,
			revealGui.AbsoluteSize.X * 0.80 / Config.UI.Tokens.layout.hatchAspect
		)
		local cardFrame = UI.box(
			catcher,
			"HatchCard",
			UDim2.fromScale(0.82, 0.40),
			UDim2.fromOffset(height * Config.UI.Tokens.layout.hatchAspect, height),
			Config.UI.Tokens.panel,
			3
		)
		cardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		corner(cardFrame, 12)
		stroke(cardFrame, 3)
		UI.shadow(cardFrame)
		local inner = UI.box(
			cardFrame,
			"RarityBorder",
			UDim2.fromScale(0.025, 0.02),
			UDim2.fromScale(0.95, 0.96),
			color,
			4
		)
		inner.BackgroundTransparency = 1
		corner(inner, 10)
		stroke(inner, 2).Color = color
		local ribbon = UI.box(
			cardFrame,
			"RarityRibbon",
			UDim2.fromScale(0.02, 0.03),
			UDim2.fromScale(0.96, 0.10),
			color,
			5
		)
		local rarityLabel = textLabel(ribbon, string.upper(rarity.name), Color3.new(1, 1, 1))
		rarityLabel.Size, rarityLabel.ZIndex = UDim2.fromScale(1, 1), 6
		local scale = Instance.new("UIScale")
		scale.Scale, scale.Parent = 0, cardFrame
		UI.tween(scale, 0.18, { Scale = 1.12 }, Enum.EasingStyle.Back)
		task.delay(0.18, function()
			if cardFrame.Parent then
				UI.tween(scale, 0.12, { Scale = 1 })
			end
		end)
		local rays = UI.box(
			cardFrame,
			"Rays",
			UDim2.fromScale(0.5, 0.41),
			UDim2.fromScale(0.82, 0.64),
			color,
			4
		)
		rays.AnchorPoint, rays.BackgroundTransparency = Vector2.new(0.5, 0.5), 1
		for k = 1, 12 do
			local ray =
				UI.box(rays, "Ray", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.035, 1), color, 4)
			ray.AnchorPoint, ray.Rotation, ray.BackgroundTransparency =
				Vector2.new(0.5, 0.5), k * 30, 0.45
			local gradient = Instance.new("UIGradient")
			gradient.Rotation, gradient.Transparency, gradient.Parent =
				90, NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0.25),
					NumberSequenceKeypoint.new(1, 1),
				}), ray
		end
		local host = UI.box(
			cardFrame,
			"PetHero",
			UDim2.fromScale(0.08, 0.15),
			UDim2.fromScale(0.84, 0.52),
			color,
			5
		)
		host.BackgroundTransparency = 1
		local source = pumpkinCopy(seed, mutation, pet)
		local view = Palette.renderModel(host, source)
		source:Destroy()
		local name = textLabel(
			cardFrame,
			(mutation and mutation .. " " or "") .. (petDef and petDef.display or "Pumpkin"),
			Color3.new(1, 1, 1)
		)
		name.Position, name.Size, name.ZIndex, name.TextWrapped =
			UDim2.fromScale(0.04, 0.68), UDim2.fromScale(0.92, 0.12), 8, true
		local income = textLabel(cardFrame, "+" .. rateShort(rate) .. "/s", Config.UI.Tokens.good)
		income.Position, income.Size, income.ZIndex =
			UDim2.fromScale(0.04, 0.81), UDim2.fromScale(0.92, 0.08), 8
		local weightLabel = textLabel(
			cardFrame,
			weight and string.format("%.1f kg", weight) or "Pumpkin hatch",
			Config.UI.Tokens.cardStroke
		)
		weightLabel.Position, weightLabel.Size, weightLabel.ZIndex =
			UDim2.fromScale(0.04, 0.91), UDim2.fromScale(0.92, 0.06), 8
		if isNew then
			UI.sticker(cardFrame, "NEW!", Config.UI.Tokens.good)
		end
		local legendary = rarity.name == "Legendary"
			or rarity.name == "Mythic"
			or rarity.name == "Secret"
		UI.hatchConfetti(catcher, color, legendary)
		local shownAt, closed, previewYaw = os.clock(), false, 0
		local spin = Services.RunService.RenderStepped:Connect(function()
			if view then
				-- A small yaw sway keeps the pet's face toward the +Z camera throughout reveal.
				local yaw = math.sin((os.clock() - shownAt) * 3) * math.rad(8)
				UI.rotatePreview(view, yaw - previewYaw)
				previewYaw = yaw
			end
		end)
		local function close()
			if closed then
				return
			end
			closed = true
			spin:Disconnect()
			local target = UI.petsButton or indexButton
			local position = target.AbsolutePosition + target.AbsoluteSize * 0.5
			UI.tween(
				cardFrame,
				0.22,
				{ Position = UDim2.fromOffset(position.X, position.Y) },
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			)
			UI.tween(scale, 0.22, { Scale = 0.04 })
			UI.tween(catcher, 0.22, { BackgroundTransparency = 1 })
			task.delay(0.22, function()
				catcher:Destroy()
				local pop = target:FindFirstChildOfClass("UIScale")
				if pop then
					pop.Scale = 1.12
					UI.tween(pop, 0.20, { Scale = 1 }, Enum.EasingStyle.Back)
				end
			end)
		end
		catcher.Activated:Connect(close)
		while not closed and os.clock() - shownAt < 2.0 do
			local dt = task.wait(0.05)
			if Center.urgent then
				shownAt += dt
			end
		end
		close()
		task.wait(0.24)
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
		if not seedById[seedId] then
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
		Center.revealBusy = true
		Center.toastHolder.Visible = false
		for _, frame in panelFrames do
			frame.Visible = false
		end
		refreshDim()
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
			Center.revealBusy = false
			Center.toastHolder.Visible = true
			local pending = Center.toasts
			Center.toasts = {}
			for _, text in pending do
				hint(text)
				task.wait(0.4)
			end
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
do
	local lock = pill("LOCK · 60s", Color3.fromRGB(190, 90, 220), 0)
	lock.Name = "PurgeLock"
	lock.LayoutOrder = 4
	lock.Visible = false
	lock.Activated:Connect(function()
		remotes:WaitForChild("Lock"):FireServer()
	end)
	local function refresh()
		local patch = myPatch()
		local active = (state:GetAttribute("PurgeEnds") or 0) > workspace:GetServerTimeNow()
		lock.Visible = #Config.Purge.minutes > 0
			and active
			and patch ~= nil
			and player:GetAttribute("Loaded") == true
		local used = player:GetAttribute("PurgeLockUsed") == state:GetAttribute("PurgeId")
		local left = patch
				and math.max(
					0,
					(patch:GetAttribute("LockedUntil") or 0) - workspace:GetServerTimeNow()
				)
			or 0
		lock.Text = left > 0 and ("LOCKED " .. clockText(left))
			or used and "LOCK USED"
			or "LOCK · 60s"
		lock.Active = not used
		lock.AutoButtonColor = not used
	end
	task.spawn(function()
		while lock.Parent do
			refresh()
			task.wait(0.25)
		end
	end)
end

-- Place (your empty plot, while you carry), Pick up (your filled plot), LOCK (your sign post),
-- Steal (a filled, unprotected plot on someone else's unlocked base).
do
	local function set(prompt: Instance?, on: boolean, objectText: string?)
		if not prompt or not prompt:IsA("ProximityPrompt") then
			return
		end
		local root = rootPart()
		local host = prompt.Parent
		local at = host and host:IsA("Attachment") and host.WorldPosition
			or host and host:IsA("BasePart") and host.Position
		if at then
			on = on and root ~= nil and (at - root.Position).Magnitude <= 60
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
		local pet = pumpkin and pumpkin:GetAttribute("Pet")
		local def = pet and Config.Pets[pet]
		return def and def.display or "Pumpkin"
	end

	-- Prompts of systems behind an unlock gate stay hidden until it opens (the server refuses them
	-- too): Pick up and the Witch (Sell), cauldrons (Brew), Steal and LOCK (PlayerSteal).
	local sellPrompt = market:WaitForChild("Sell"):FindFirstChild("PromptPart")
	local function refreshPrompts()
		local now = workspace:GetServerTimeNow()
		local locksOff = (state:GetAttribute("LocksOff") or 0) > now
		local carrying = (player:GetAttribute("Carry") or 0) > 0
		local canSell, canSteal = unlocked("Sell"), unlocked("PlayerSteal")
		local purge = (state:GetAttribute("PurgeEnds") or 0) > now
		local ownPatch = myPatch()
		canSteal = canSteal
			and purge
			and (player:GetAttribute("PlayTime") or 0) >= Config.Purge.grace
			and not player:GetAttribute("IdleShield")
			and (not ownPatch or (ownPatch:GetAttribute("LockedUntil") or 0) <= now)
		for _, patch in patchFolder:GetChildren() do
			local owner = patch:GetAttribute("Owner") or 0
			local mine = owner == player.UserId
			local locked = not locksOff and (patch:GetAttribute("LockedUntil") or 0) > now
			-- A shielded owner (new farmer) cannot be robbed.
			local ownerPlayer = not mine
					and owner ~= 0
					and Services.Players:GetPlayerByUserId(owner)
				or nil
			local robbable = canSteal
				and ownerPlayer ~= nil
				and unlocked("PlayerSteal", ownerPlayer)
				and (ownerPlayer:GetAttribute("PlayTime") or 0) >= Config.Purge.grace
				and not ownerPlayer:GetAttribute("IdleShield")
				and patch:GetAttribute("PurgeRobbed") ~= state:GetAttribute("PurgeId")
				and not locked
			for _, plot in patch:GetChildren() do
				if plot.Name == "Plot" then
					local active = (plot:GetAttribute("Index") or 1)
						<= (patch:GetAttribute("PenSlots") or Config.Progression.baseSlots)
					local filled = plot:GetAttribute("Filled") == true
					local name = filled and pumpkinName(plot) or nil
					local full = (player:GetAttribute("PenFilled") or 0)
						>= (player:GetAttribute("PenSlots") or Config.Progression.baseSlots)
					local weakest = patch:GetAttribute("SwapWeakestName")
					local placePrompt = plot:FindFirstChild("PlacePrompt")
					if placePrompt and placePrompt:IsA("ProximityPrompt") then
						placePrompt.ActionText = full and "Swap weakest: " .. (weakest or "pet")
							or "Place"
					end
					set(
						placePrompt,
						active
							and mine
							and carrying
							and (
								not filled
								or (
									full
									and weakest ~= nil
									and player:GetAttribute("CarryPet") == true
								)
							),
						full and weakest or "Your plot"
					)
					local p = plot:FindFirstChild("Pumpkin")
					local ready = p
						and p:GetAttribute("Jack") == true
						and not p:GetAttribute("CarveAt")
						and now >= (p:GetAttribute("PickupReadyAt") or 0)
						and not p:GetAttribute("Stashed")
					local prompt = plot:FindFirstChild("PetPrompt", true)
					if prompt and prompt:IsA("ProximityPrompt") then
						prompt.ActionText = mine and "Pick up" or "Steal"
						prompt.HoldDuration = mine and 0.3 or Config.Purge.hold
					end
					-- While carrying, the full-pen Place prompt owns the interaction.
					set(
						prompt,
						active
							and filled
							and ready
							and (player:GetAttribute("Carry") or 0) < Config.BaseCarry
							and not (mine and carrying and full)
							and (
								(mine and canSell)
								or (not mine and robbable and not plot:GetAttribute("Protected"))
							),
						name
					)
				end
			end
			local upgrade = patch:FindFirstChild("UpgradePrompt", true)
			local slots = patch:GetAttribute("PenSlots") or Config.Progression.baseSlots
			local zone = slots < Config.Progression.woodsSlots and "Zone3" or "Zone5"
			local previous = Config.ZoneOrder[(table.find(Config.ZoneOrder, zone) or 1) - 1]
			local cost = Config.Zones[zone].cost
			-- The server publishes the same gate quote used by unlockZone.
			cost = player:GetAttribute("PenUpgradeCost") or cost
			if upgrade and upgrade:IsA("ProximityPrompt") then
				upgrade.ActionText = "Upgrade pen: " .. short(cost)
			end
			set(
				upgrade,
				mine
					and player:GetAttribute("Loaded") == true
					and slots < Config.Progression.castleSlots
					and previous ~= nil
			)
			set(
				patch:FindFirstChild("LockPrompt", true),
				mine
					and not locksOff
					and purge
					and player:GetAttribute("Loaded") == true
					and player:GetAttribute("PurgeLockUsed") ~= state:GetAttribute("PurgeId")
			)
		end
		for _, p in sellPrompt and sellPrompt:GetChildren() or {} do
			if p:IsA("ProximityPrompt") then
				if p.Name == "RebirthPrompt" then
					set(p, unlocked("Haunt"))
				elseif string.sub(p.Name, 1, 10) == "WitchOffer" then
					set(p, unlocked("Witch"))
				else
					p.ActionText = "Sell: "
						.. tostring(player:GetAttribute("CarryValue") or 0)
						.. " candy"
					set(p, canSell and carrying)
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
		marker.MaxDistance = Config.Payoff.petDistance
		marker.Parent = soil
		textLabel(marker, "YOUR PEN", Color3.fromRGB(140, 255, 110)).Size = UDim2.fromScale(1, 1)
	end
	for _, patch in patchFolder:GetChildren() do
		patch:GetAttributeChangedSignal("Owner"):Connect(refreshMarker)
	end
	refreshMarker()
	task.spawn(function()
		while true do
			local root = rootPart()
			local patch = myPatch()
			local soil = patch and patch:FindFirstChild("Soil")
			if marker then
				marker.Enabled = root ~= nil
					and soil ~= nil
					and (root.Position - soil.Position).Magnitude > 60
			end
			task.wait(0.25)
		end
	end)
end

-- Lighting by phase ----------------------------------------------------------------------------

do
	local atmosphere = Services.Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Services.Lighting
	end
	local correction = Services.Lighting:FindFirstChild("PhaseTint") :: ColorCorrectionEffect?
	if not correction then
		correction = Instance.new("ColorCorrectionEffect")
		correction.Name = "PhaseTint"
		correction.Parent = Services.Lighting
	end
	local bloom = Services.Lighting:FindFirstChild("HarvestBloom")
		or Services.Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "HarvestBloom"
		bloom.Parent = Services.Lighting
	end
	local function baseValue(attribute, fallback)
		local value = Services.Lighting:GetAttribute(attribute)
		return value == nil and fallback or value
	end
	local base = {
		lighting = {},
		tint = {},
		atmosphere = {},
		bloom = {},
	}
	for _, key in
		{
			"Ambient",
			"OutdoorAmbient",
			"Brightness",
			"ClockTime",
			"GeographicLatitude",
			"ColorShift_Top",
			"ColorShift_Bottom",
			"ExposureCompensation",
			"ShadowSoftness",
			"EnvironmentDiffuseScale",
			"EnvironmentSpecularScale",
		}
	do
		base.lighting[key] = baseValue("Base" .. key, Services.Lighting[key])
	end
	for _, key in { "TintColor", "Brightness", "Saturation", "Contrast" } do
		base.tint[key] = baseValue("BaseGrade" .. key, correction[key])
	end
	for _, key in { "Color", "Decay", "Density", "Offset", "Haze", "Glare" } do
		base.atmosphere[key] = baseValue("BaseAtmosphere" .. key, atmosphere[key])
	end
	for _, key in { "Intensity", "Size", "Threshold" } do
		base.bloom[key] = baseValue("BaseBloom" .. key, bloom[key])
	end
	-- Midnight retains readable daylight. Events override only their named values;
	-- every transition restores the complete authored base, including grade/haze/bloom.
	local EVENT_LOOK = {
		Purge = {
			lighting = {
				Ambient = base.lighting.Ambient:Lerp(Color3.fromRGB(210, 160, 220), 0.2),
				OutdoorAmbient = base.lighting.OutdoorAmbient:Lerp(
					Color3.fromRGB(230, 175, 215),
					0.2
				),
			},
			tint = {
				TintColor = Color3.fromRGB(255, 235, 252),
				Brightness = 0.025,
				Saturation = 0.1,
				Contrast = 0.025,
			},
			atmosphere = {
				Color = base.atmosphere.Color,
				Decay = base.atmosphere.Decay,
				Density = base.atmosphere.Density,
			},
		},
		Spooky = {
			lighting = {
				Ambient = base.lighting.Ambient:Lerp(Color3.fromRGB(170, 110, 160), 0.25),
				OutdoorAmbient = base.lighting.OutdoorAmbient:Lerp(
					Color3.fromRGB(190, 120, 170),
					0.25
				),
			},
			tint = {
				TintColor = Color3.fromRGB(255, 226, 194),
				Saturation = 0.18,
				Contrast = 0.06,
			},
			atmosphere = {
				Color = Color3.fromRGB(242, 176, 122),
				Decay = Color3.fromRGB(138, 100, 200),
				Density = base.atmosphere.Density,
			},
		},
		BloodMoon = {
			lighting = {
				Ambient = Config.KingNight.look.ambient,
				OutdoorAmbient = Config.KingNight.look.outdoor,
				Brightness = base.lighting.Brightness,
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
		local look = name and EVENT_LOOK[name]
		for key, target in
			{
				lighting = Services.Lighting,
				tint = correction,
				atmosphere = atmosphere,
				bloom = bloom,
			}
		do
			local values = table.clone(base[key])
			for property, value in look and look[key] or {} do
				values[property] = value
			end
			if key == "bloom" and name == "BloodMoon" then
				values.Intensity = 0.4
			end
			Services.TweenService:Create(target, info, values):Play()
		end
	end
	local lastLook: string? = "none"
	local function refreshLook()
		local phase = state:GetAttribute("Phase") or "Day"
		local name = (phase == "BloodMoon" or state:GetAttribute("KingWarning")) and "BloodMoon"
			or state:GetAttribute("PurgeEnds") ~= nil and "Purge"
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
		lastPhase = phase
		if phase == "Midnight" then
			toast("Nests restocked!", "Steal a fresh pumpkin!")
			play(Config.Sounds.Brew, 0.5, 0.8)
		elseif phase == "BloodMoon" and unlocked("King") then
			toast("KING FIGHT!", "Pet + loot! Meet the King at the throne!")
			play(Config.Sounds.Brew, 0.4, 1)
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
		batConn = Services.RunService.RenderStepped:Connect(function()
			local root = rootPart()
			local t = os.clock()
			local z = root and root.Position.Z
				or (state:GetAttribute("SafeLineZ") or Config.SafeLineZ)
				or 150
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
			toast(
				"Spooky Hour is over",
				"See you in "
					.. clockText(
						math.max(
							0,
							(state:GetAttribute("SpookyNext") or workspace:GetServerTimeNow())
								- workspace:GetServerTimeNow()
						)
					)
			)
		end
	end
	state:GetAttributeChangedSignal("SpookyEnds"):Connect(onSpooky)
	state:GetAttributeChangedSignal("PurgeEnds"):Connect(refreshLook)
	onSpooky()
end

-- Scythe ---------------------------------------------------------------------------------------

do
	local bonkEvent = remotes:WaitForChild("Bonk")
	local lastSwing = 0
	-- The idle Grip of each tool (the server's value) and the swing currently playing on it.
	local idleGrip: { [Tool]: CFrame } = setmetatable({}, { __mode = "k" }) :: any

	local HAND = CFrame.Angles(math.rad(-90), 0, 0)
	-- Flat angle channels: right shoulder, elbow, left shoulder, elbow, waist, wrist.
	local IDLE, SWINGS = Config.ScythePose.idle, Config.ScythePose.swings
	local WINDOWS = { { 0.105, 0.255, 0.115 }, { 0.1, 0.26, 0.11 }, { 0.17, 0.34, 0.175 } }
	local chains = setmetatable({}, { __mode = "k" })
	local active = {}
	local function ease(x, kind)
		if kind == "outQuad" then
			return 1 - (1 - x) ^ 2
		end
		if kind == "outCubic" then
			return 1 - (1 - x) ^ 3
		end
		if kind == "outQuart" then
			return 1 - (1 - x) ^ 4
		end
		if kind == "inOutSine" then
			return (1 - math.cos(math.pi * x)) / 2
		end
		if kind == "hold" then
			return 0
		end
		return x
	end
	local gameSettings = UserSettings():GetService("UserGameSettings")
	local function carried(character, owner)
		return (character:GetAttribute("Carry") or 0) > 0
			or (character:GetAttribute("Carrying") or 0) > 0
			or owner ~= nil
				and ((owner:GetAttribute("Carry") or 0) > 0 or (owner:GetAttribute("Carrying") or 0) > 0)
	end
	local function trails(st, on)
		if st.trail then
			st.trail.Enabled = on
		end
		if st.glow then
			local quality = gameSettings.SavedQualityLevel.Value
			st.glow.Enabled = on
				and not Services.UserInputService.TouchEnabled
				and (quality == 0 or quality > 3)
		end
	end
	local function restore(st, skipJoints)
		st.tool.Grip = st.base
		trails(st, false)
		for _, j in st.joints do
			if not skipJoints and j.motor.Parent then
				j.motor.Transform = j.anim
			end
		end
	end
	local function release(tool, skipJoints)
		local st = active[tool]
		if not st then
			return
		end
		active[tool] = nil
		st.swing = nil
		restore(st, skipJoints)
		for _, connection in st.connections do
			connection:Disconnect()
		end
	end
	local function track(tool)
		if active[tool] then
			return active[tool]
		end
		local character = tool.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if
			not humanoid
			or not root
			or humanoid.Health <= 0
			or carried(character, Services.Players:GetPlayerFromCharacter(character))
		then
			return nil
		end
		local st = {
			tool = tool,
			character = character,
			owner = Services.Players:GetPlayerFromCharacter(character),
			humanoid = humanoid,
			root = root,
			base = idleGrip[tool] or tool.Grip,
			pose = table.clone(IDLE),
			w = 0,
			phase = 0,
			m = 0,
			jump = 0,
			equip = 0,
			joints = {},
			connections = {},
			r6 = humanoid.RigType == Enum.HumanoidRigType.R6,
		}
		idleGrip[tool] = st.base
		local names = st.r6 and { ["Right Shoulder"] = 1, ["Left Shoulder"] = 5, RootJoint = 9 }
			or { RightShoulder = 1, RightElbow = 4, LeftShoulder = 5, LeftElbow = 8, Waist = 9 }
		for _, j in character:GetDescendants() do
			if names[j.Name] and (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) then
				if j:IsA("AnimationConstraint") and not j.Attachment0 then
					continue
				end
				local rot = if j:IsA("Motor6D")
					then j.C0.Rotation
					else j.Attachment0.CFrame.Rotation
				table.insert(
					st.joints,
					{ motor = j, index = names[j.Name], rot = rot, anim = j.Transform }
				)
			end
		end
		st.trail, st.glow =
			tool:FindFirstChild("SwingTrail", true), tool:FindFirstChild("SwingGlow", true)
		st.width = st.trail and st.trail.WidthScale
		active[tool] = st
		table.insert(
			st.connections,
			tool.Unequipped:Connect(function()
				release(tool)
			end)
		)
		table.insert(
			st.connections,
			humanoid.Died:Connect(function()
				release(tool)
			end)
		)
		if st.owner then
			table.insert(
				st.connections,
				st.owner.CharacterRemoving:Connect(function(removing)
					if removing == character then
						release(tool)
					end
				end)
			)
		end
		if st.owner == player then
			play(Config.Sounds.Whoosh, 1.25, 0.3)
		end
		return st
	end
	local function swingTool(tool: Tool, localSwing: boolean?)
		local st = track(tool)
		if not st then
			return 1
		end
		st.w = 1
		local now, chain = os.clock(), chains[tool]
		local step = chain and now - chain.at <= Config.Farm.chainWindow and chain.step % 3 + 1 or 1
		chains[tool] = { at = now, step = step }
		local fast = st.owner
			and string.find(st.owner:GetAttribute("Skills") or "", "QuickRoots", 1, true)
		local speed = fast and 1 + Config.SkillSwingBonus or 1
		st.swing = {
			step = step,
			t = 0,
			start = table.clone(st.pose),
			speed = speed,
			localSwing = localSwing,
			impacted = false,
		}
		if st.owner then
			FarmFX.steps[st.owner] = step
		end
		if st.trail then
			local points = {}
			for _, key in st.width.Keypoints do
				table.insert(
					points,
					NumberSequenceKeypoint.new(
						key.Time,
						key.Value * (step == 3 and 1.6 or 1),
						key.Envelope
					)
				)
			end
			st.trail.WidthScale, st.trail.Lifetime =
				NumberSequence.new(points), step == 3 and 0.18 or 0.14
		end
		if localSwing then
			local target = FarmFX.target and FarmFX.target()
			st.swing.target, st.swing.targetAt = target, target and target.Position
			st.swing.wouldBreak = target and FarmFX.breaks and FarmFX.breaks(target)
			FarmFX.step, FarmFX.impactAt = step, now + (step == 3 and 0.24 or 0.17) / speed
			FarmFX.hasImpact, FarmFX.snapshot, FarmFX.arcDrawn = false, target, false
		end
		local swing = st.swing
		task.delay(WINDOWS[step][3] / speed, function()
			if
				active[tool] == st
				and st.swing == swing
				and tool.Parent == st.character
				and st.humanoid.Health > 0
				and not carried(st.character, st.owner)
			then
				play(Config.Sounds.Whoosh, ({ 1, 1.08, 0.85 })[step], localSwing and 0.5 or 0.25)
			end
		end)
		return step
	end
	local function evaluate(st, dt, now)
		st.equip += dt
		local p = table.clone(IDLE)
		local sw = st.swing
		if sw then
			local paused = sw.localSwing and math.clamp(FarmFX.freezeUntil - (now - dt), 0, dt) or 0
			sw.t += (dt - paused) * sw.speed
			local keys = SWINGS[sw.step]
			local prev, at = sw.start, 0
			for _, key in keys do
				if sw.t <= key[1] then
					local f = ease(math.clamp((sw.t - at) / (key[1] - at), 0, 1), key[2])
					for i = 1, #IDLE do
						p[i] = prev[i] + (key[i + 2] - prev[i]) * f
					end
					break
				end
				prev, at = {}, key[1]
				for i = 1, #IDLE do
					prev[i] = key[i + 2]
				end
			end
			if sw.localSwing and FarmFX.hasImpact then
				sw.impacted = true
			end
			if sw.localSwing and not sw.impacted and sw.t >= (sw.step == 3 and 0.24 or 0.17) then
				sw.impacted = true
				local target = FarmFX.target and FarmFX.target()
				if sw.target and not sw.target.Parent then
					target = sw.target
				end
				if target and FarmFX.impact then
					FarmFX.impact(
						target,
						target.Parent and target.Position or sw.targetAt,
						sw.step,
						target == sw.target and sw.wouldBreak
					)
				end
			end
			if sw.localSwing and FarmFX.hasImpact then
				if now < FarmFX.freezeUntil then
					p[12] += math.random() * 4 - 2
				else
					local recoil = math.clamp(1 - (now - FarmFX.freezeUntil) / 0.08, 0, 1)
					p[12] += 8 * recoil
					p[1] -= 4 * recoil
				end
			end
			trails(st, sw.t >= WINDOWS[sw.step][1] and sw.t <= WINDOWS[sw.step][2])
			if sw.t >= keys[#keys][1] then
				st.swing = nil
				trails(st, false)
			end
		else
			if st.equip < 0.28 then
				local x = st.equip / 0.28
				local f = 1 + 2.7 * (x - 1) ^ 3 + 1.7 * (x - 1) ^ 2
				for i = 1, #p do
					p[i] *= f
				end
			end
		end
		local velocity = st.root.AssemblyLinearVelocity
		local v = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		st.m += (math.clamp(v / 16, 0, 1.6) - st.m) * math.min(dt / 0.12, 1)
		st.phase += dt * 9.4 * math.clamp(v / 16, 0.6, 1.6)
		local humState = st.humanoid:GetState()
		local jumping = humState == Enum.HumanoidStateType.Jumping
			or humState == Enum.HumanoidStateType.Freefall
		st.jump += ((jumping and 1 or 0) - st.jump) * math.min(dt / 0.1, 1)
		-- Key zero already includes the previous movement/breathing layer.
		-- Fade fresh offsets in through anticipation so a chained click cannot add them twice.
		local overlay = sw and math.clamp(sw.t / SWINGS[sw.step][1][1], 0, 1) or 1
		local layer = sw and 0.5 * overlay or 1
		local m, bob = st.m * layer, math.sin(st.phase)
		p[9] += 1.5 * math.sin(now * math.pi * 0.6) * overlay - 4 * m
		p[10] += 6 * m * bob
		p[1] += 4 * m * bob + 15 * st.jump * layer
		p[3] += 1.2 * math.sin(now * math.pi * 0.6 + 0.6) * overlay
		p[5] += -14 * m * bob + (60 - IDLE[5]) * st.jump * layer
		p[7] += (-35 - IDLE[7]) * st.jump * layer
		p[8] += 10 * m
		p[12] += -10 * m + 10 * st.jump * layer
		p[14] += 1.5 * math.sin(now * math.pi * 0.6 + 1.2) * overlay
		st.pose = p
	end
	-- Animator evaluates after PreAnimation and before PreSimulation. Write Transform here
	-- before the engine applies Motor6D/AnimationConstraint changes for physics.
	Services.RunService.PreAnimation:Connect(function()
		-- Clear our previous override before Animator evaluates. Untracked joints
		-- must not feed our own pose back into the next frame's blend.
		for _, st in active do
			for _, j in st.joints do
				if j.motor.Parent then
					j.motor.Transform = j.anim
				end
			end
		end
	end)
	Services.RunService.PreSimulation:Connect(function(dt)
		local camera = workspace.CurrentCamera
		for _, owner in Services.Players:GetPlayers() do
			local character = owner.Character
			local tool = character and character:FindFirstChild("Scythe")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if
				tool
				and root
				and camera
				and (root.Position - camera.CFrame.Position).Magnitude <= 80
			then
				pcall(track, tool)
			end
		end
		for tool, st in active do
			local dead = not st.character.Parent
				or st.humanoid.Health <= 0
				or (st.owner and st.owner.Character ~= st.character)
			local carrying = carried(st.character, st.owner)
			local visible = camera and (st.root.Position - camera.CFrame.Position).Magnitude <= 80
			local held = tool.Parent == st.character and not dead and not carrying and visible
			if not held then
				release(tool, carrying and not dead and tool.Parent == st.character)
			else
				st.w = math.clamp(st.w + dt / 0.12, 0, 1)
				evaluate(st, dt, os.clock())
				local p = st.pose
				for _, j in st.joints do
					local i = j.index
					local pitch, yaw, roll = p[i], 0, 0
					if i ~= 4 and i ~= 8 then
						yaw, roll = p[i + 1], p[i + 2]
					end
					if st.r6 then
						if i == 1 or i == 5 then
							pitch += 0.5 * p[i + 3]
						else
							pitch, yaw, roll = pitch * 0.5, yaw * 0.5, 0
						end
					end
					j.anim = j.motor.Transform
					local rotation =
						CFrame.fromEulerAnglesYXZ(math.rad(pitch), math.rad(yaw), math.rad(roll))
					j.motor.Transform = j.anim:Lerp(j.rot:Inverse() * rotation * j.rot, st.w)
				end
				local pitch = p[12] - (st.r6 and 0.5 * p[4] or 0)
				local grip = st.base
					* HAND:Inverse()
					* CFrame.Angles(
						math.rad(pitch * st.w),
						math.rad(p[14] * st.w),
						math.rad(p[13] * st.w)
					)
						:Inverse()
					* HAND
				tool.Grip = grip
			end
		end
	end)
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
		local function attempt()
			if carried(tool.Parent, player) then
				return
			end
			if Center.urgent then
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
			swingTool(tool, true)
			bonkEvent:FireServer()
		end
		FarmFX.attempts = FarmFX.attempts or setmetatable({}, { __mode = "k" })
		FarmFX.attempts[tool] = attempt
		tool.Activated:Connect(function()
			FarmFX.held = true
			attempt()
		end)
		tool.Deactivated:Connect(function()
			FarmFX.held = false
		end)
		tool.Unequipped:Connect(function()
			FarmFX.held = false
			release(tool)
		end)
	end
	Services.RunService.Heartbeat:Connect(function()
		if not FarmFX.held then
			return
		end
		local tool = player.Character and player.Character:FindFirstChild("Scythe")
		local attempt = tool and FarmFX.attempts and FarmFX.attempts[tool]
		if attempt then
			attempt()
		end
	end)
	Services.UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			FarmFX.held = false
		end
	end)
	Services.UserInputService.WindowFocusReleased:Connect(function()
		FarmFX.held = false
	end)
	local function hookCharacter(character: Model)
		FarmFX.held = false
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
			if
				tool
				and who.Character
				and (
						who.Character:GetPivot().Position
						- (
							workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
							or Vector3.zero
						)
					).Magnitude
					<= 60
			then
				swingTool(tool :: Tool)
			end
		end
	end)
end

-- Fixed client pool: only server-confirmed local hits acquire a crescent.
do
	local rigs = {}
	for _ = 1, 3 do
		local part = Instance.new("Part")
		part.Name, part.Size, part.Anchored, part.Transparency =
			"ScytheHitArc", Vector3.new(0.2, 0.2, 0.2), true, 1
		part.CanCollide, part.CanQuery, part.CanTouch, part.Parent = false, false, false, workspace
		local rig = { part = part, attachments = {}, beams = {} }
		for i = 1, 3 do
			local a = Instance.new("Attachment")
			a.Parent = part
			rig.attachments[i] = a
		end
		for i = 1, 2 do
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = rig.attachments[i], rig.attachments[i + 1]
			beam.Segments, beam.FaceCamera, beam.LightEmission, beam.LightInfluence, beam.Brightness =
				12, false, 1, 0, 1.5
			beam.Width0, beam.Width1 = i == 1 and 0.15 or 1, i == 1 and 1 or 0.1
			beam.Enabled, beam.Parent = false, part
			rig.beams[i] = beam
		end
		table.insert(rigs, rig)
	end
	function FarmFX.arc(step)
		if FarmFX.arcDrawn then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local tool = character and character:FindFirstChild("Scythe")
		if not root or not tool then
			return
		end
		local rig
		for _, slot in rigs do
			if not slot.started then
				rig = slot
				break
			end
		end
		if not rig then
			return
		end
		FarmFX.arcDrawn = true
		local def = Config.ScytheStyles[tool:GetAttribute("StyleId") or tool:GetAttribute("ToolId")]
			or Config.ScytheStyles.RustySickle
		rig.started, rig.step = os.clock(), step
		rig.part.CFrame = root.CFrame
			* CFrame.new(0, ({ 1, 0.9, 1.5 })[step], 0)
			* CFrame.Angles(0, 0, math.rad(({ 30, -20, 90 })[step]))
		for _, beam in rig.beams do
			beam.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHex(def.trail[1]))
		end
	end
	Services.RunService.RenderStepped:Connect(function()
		for _, rig in rigs do
			if rig.started then
				local t = os.clock() - rig.started
				if t >= 0.16 then
					rig.started = nil
					for _, beam in rig.beams do
						beam.Enabled = false
					end
				else
					local radius = 4.2 + 0.6 * t / 0.16
					local reverse = rig.step == 2
					for i, a in rig.attachments do
						local phi = math.rad((reverse and -1 or 1) * (2 - i) * 80)
						a.Position = Vector3.new(radius * math.sin(phi), 0, -radius * math.cos(phi))
						a.Axis, a.SecondaryAxis =
							Vector3.new(-math.cos(phi), 0, -math.sin(phi)) * (reverse and -1 or 1),
							Vector3.yAxis
					end
					for i, beam in rig.beams do
						beam.Enabled = i == 1 or t >= 0.035
						beam.CurveSize0, beam.CurveSize1 = 0.485 * radius, 0.485 * radius
						beam.Transparency = NumberSequence.new(0.05 + 0.95 * t / 0.16)
					end
				end
			end
		end
	end)
end
-- Effects ----------------------------------------------------------------------------------------

local combo, comboAt = 0, 0
local function countHit(_at: Vector3)
	local now = os.clock()
	combo = now - comboAt < 2 and combo + 1 or 1
	comboAt = now
	if not UI.comboLabel then
		UI.comboLabel = textLabel(gui, "", Config.UI.Tokens.candy)
		UI.comboLabel.AnchorPoint = Vector2.new(0.5, 0)
		UI.comboLabel.Position = UDim2.fromScale(0.5, 0.19)
		UI.comboLabel.Size = UDim2.fromScale(0.30, 0.03)
	end
	UI.comboLabel.Text = "x" .. combo .. " COMBO"
	UI.comboLabel.Visible = combo >= 3
	local stamp = comboAt
	task.delay(2, function()
		if comboAt == stamp then
			UI.comboLabel.Visible = false
		end
	end)
end
-- A pumpkin went onto a base plot (income = its candy per second there).
remotes
	:WaitForChild("Placed").OnClientEvent
	:Connect(function(who: Player, at: Vector3, income: number)
		burst(
			at + Vector3.new(0, 1, 0),
			Color3.fromRGB(150, 255, 110),
			18,
			12,
			Palette.SPARKLE,
			0.8
		)
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

-- Pet Sim 99 impact timing: predict visuals, reconcile HP from the server, pool farming FX.
-- Candy flies in screen space to the scaled HUD counter; only server pop events show rewards.
do
	local wildFolder = garden:WaitForChild("Wild", 10)
	local hitAt = setmetatable({}, { __mode = "k" })
	local predicted = setmetatable({}, { __mode = "k" })
	local rest = setmetatable({}, { __mode = "k" })
	local squashes, shards, candies, flashes = {}, {}, {}, {}
	local shardNext, flashNext, collectAt, collectStep = 0, 0, -math.huge, 0
	local mobile = Palette.mobile()

	local goldGui = Instance.new("ScreenGui")
	goldGui.Name = "PatchGoldFlash"
	goldGui.ResetOnSpawn = false
	goldGui.IgnoreGuiInset = true
	goldGui.DisplayOrder = UI.screen.DisplayOrder + 1
	goldGui.Parent = player:WaitForChild("PlayerGui")
	local goldWash = Instance.new("Frame")
	goldWash.Name = "GoldenBreakFlash"
	goldWash.Size = UDim2.fromScale(1, 1)
	goldWash.BackgroundColor3 = Color3.fromRGB(255, 220, 60)
	goldWash.BackgroundTransparency, goldWash.BorderSizePixel = 1, 0
	goldWash.ZIndex, goldWash.Parent = 10, goldGui
	local goldUntil = 0
	for i = 1, 24 do
		local part = Instance.new("Part")
		part.Name, part.Size = "PumpkinChunk", Vector3.one * 0.5
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CastShadow, part.Transparency = false, 1
		part.Color = Color3.fromRGB(255, 122, 26)
		part.Parent = workspace
		shards[i] = { part = part }
	end
	for i = 1, 60 do
		local label = Instance.new("Frame")
		label.Name = "FlyingCandy"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Size = UDim2.fromOffset(9, 9)
		label.BorderSizePixel, label.Visible = 0, false
		label.ZIndex, label.Parent = 20, gui
		candies[i] = { label = label }
	end
	for i = 1, 4 do
		local flash = Instance.new("Highlight")
		flash.Name, flash.Enabled = "PumpkinHitFlash", false
		flash.FillColor, flash.OutlineColor = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
		flash.FillTransparency, flash.OutlineTransparency = 0, 1
		flash.DepthMode, flash.Parent = Enum.HighlightDepthMode.Occluded, workspace
		flashes[i] = { flash = flash }
	end
	local function nearby(who: Player?, at: Vector3): boolean
		local camera = workspace.CurrentCamera
		return who == player or (camera ~= nil and (camera.CFrame.Position - at).Magnitude <= 60)
	end
	local function chunks(at: Vector3, count: number)
		for _ = 1, mobile and math.ceil(count / 2) or count do
			shardNext = shardNext % #shards + 1
			local slot = shards[shardNext]
			local angle = math.random() * math.pi * 2
			slot.at, slot.started = at, os.clock()
			slot.velocity =
				Vector3.new(math.cos(angle) * 9, 8 + math.random() * 5, math.sin(angle) * 9)
			slot.part.Transparency = 0
			slot.part.CFrame = CFrame.new(at)
		end
	end
	local function baseline(part: BasePart)
		local r = rest[part]
		if not r then
			r = { size = part.Size, cf = part.CFrame, color = part.Color, stage = 0 }
			rest[part] = r
		end
		return r
	end
	local function crack(part: BasePart, hp: number?, maxHp: number?)
		local r = baseline(part)
		local fraction = (hp or part:GetAttribute("Hp") or 1)
			/ math.max(1, maxHp or part:GetAttribute("MaxHp") or 1)
		r.stage = fraction <= 0.33 and 2 or (fraction <= 0.66 and 1 or 0)
		part.Color = r.color:Lerp(Color3.new(0, 0, 0), r.stage * 0.15)
	end
	local function juice(part: BasePart, step: number, stop: number)
		local r = baseline(part)
		flashNext = flashNext % #flashes + 1
		local slot = flashes[flashNext]
		slot.flash.Adornee, slot.flash.Enabled, slot.ends = part, true, os.clock() + 0.08 + stop
		squashes[part] = { clock = 0, untilAt = os.clock() + stop, step = step }
		part.Size = r.size * Vector3.new(1.08, step == 3 and 0.85 or 0.9, 1.08)
		if r.stage == 2 then
			chunks(r.cf.Position, 2)
		end
	end
	local function currentTarget(): BasePart?
		local root = rootPart()
		if not root then
			return nil
		end
		local look, best, bestDist = root.CFrame.LookVector, nil, math.huge
		for _, part in wildFolder and wildFolder:GetChildren() or {} do
			if part:IsA("BasePart") then
				local r = rest[part]
				local offset = (r and r.cf.Position or part.Position) - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local dist = math.max(0, flat.Magnitude - (r and r.size.X or part.Size.X) / 2)
				local zone = part:GetAttribute("Zone")
				local ownsZone = zone == "Zone1"
					or string.find(
							"," .. (player:GetAttribute("Zones") or "") .. ",",
							"," .. tostring(zone) .. ",",
							1,
							true
						)
						~= nil
				-- The server still validates access, reach, damage and all rewards.
				if
					ownsZone
					and math.abs(offset.Y) < 12
					and dist <= Config.BonkRange
					and dist < bestDist
					and (flat.Magnitude < 0.1 or flat.Unit:Dot(look) > -0.2)
				then
					best, bestDist = part, dist
				end
			end
		end
		return best
	end
	FarmFX.target = currentTarget
	function FarmFX.breaks(part: BasePart): boolean
		local damage = 1
		for _, tool in Config.Tools do
			if tool.id == player:GetAttribute("Tool") then
				damage = tool.damage
				break
			end
		end
		if string.find(player:GetAttribute("Skills") or "", "HeavyMallet", 1, true) then
			damage = math.max(1, math.floor(damage * Config.SkillDamageMult + 0.5))
		end
		return (part:GetAttribute("Hp") or math.huge) <= damage
	end
	function FarmFX.impact(part: BasePart, at: Vector3?, step: number, breaking: boolean?)
		if not at or os.clock() - (predicted[part] or -math.huge) < 0.3 then
			return
		end
		predicted[part], hitAt[part] = os.clock(), os.clock()
		FarmFX.hasImpact = true
		if breaking == nil and part.Parent then
			breaking = FarmFX.breaks(part)
		end
		local stop = step == 3 and 0.13 or (breaking and 0.11 or 0.045)
		FarmFX.freezeUntil = math.max(FarmFX.freezeUntil, os.clock() + stop)
		play(({ Config.Sounds.HitA, Config.Sounds.HitB, Config.Sounds.HitC })[step], 1, 0.55)
		burst(at + Vector3.new(0, 1, 0), Palette.ORANGE, 6, 10, Palette.SPARKLE, 0.5)
		shake((step == 3 and 0.6 or 0.12) * (mobile and 0.6 or 1), step == 3 and 6 or 4)
		if part.Parent then
			juice(part, step, stop)
		end
	end
	local function candyBurst(at: Vector3, count: number)
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local projected = camera:WorldToViewportPoint(at)
		local start = Vector2.new(projected.X, projected.Y) / uiScale.Scale
		local used = 0
		for _, slot in candies do
			if not slot.started then
				used += 1
				slot.started, slot.at = os.clock() + (used - 1) * 0.035, start
				slot.out = start
					+ Vector2.new((math.random() - 0.5) * 130, -45 - math.random() * 45)
				slot.label.BackgroundColor3 = ({
					Color3.fromRGB(255, 90, 170),
					Color3.fromRGB(255, 210, 60),
					Color3.fromRGB(120, 230, 255),
					Color3.fromRGB(150, 255, 110),
					Palette.ORANGE,
				})[(used - 1) % 5 + 1]
				slot.label.Position, slot.label.Visible = UDim2.fromOffset(start.X, start.Y), true
				if used >= (mobile and math.ceil(count / 2) or count) then
					break
				end
			end
		end
		-- Overflow merges into the candy already flying; never allocates another instance.
	end
	Services.RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		goldWash.BackgroundTransparency = goldUntil > now
				and 1 - 0.3 * math.clamp((goldUntil - now) / 0.12, 0, 1)
			or 1
		for part, anim in squashes do
			local r = rest[part]
			if not part.Parent then
				squashes[part] = nil
			else
				local hold = math.max(anim.untilAt, FarmFX.freezeUntil)
				anim.clock += dt - math.clamp(hold - (now - dt), 0, dt)
				local f = math.clamp(anim.clock / 0.18, 0, 1)
				local k = math.sin((1 - f) * math.pi * 0.5)
				part.Size = r.size
					* Vector3.new(
						1 + 0.08 * k,
						1 - (anim.step == 3 and 0.15 or 0.1) * k,
						1 + 0.08 * k
					)
				local wobble = r.stage > 0 and math.sin(f * (r.stage == 2 and 45 or 24)) * (1 - f)
					or 0
				part.CFrame = r.cf
					* CFrame.new(wobble * (r.stage == 2 and 0.25 or 0.12), -r.size.Y * 0.05 * k, 0)
					* CFrame.Angles(0, 0, wobble * 0.12)
				if f >= 1 then
					part.Size, part.CFrame = r.size, r.cf
					squashes[part] = nil
				end
			end
		end
		for _, slot in flashes do
			if slot.ends and now >= slot.ends then
				slot.flash.Enabled, slot.flash.Adornee, slot.ends = false, nil, nil
			end
		end
		for _, slot in shards do
			if slot.started then
				local t = now - slot.started
				slot.part.CFrame = CFrame.new(
					slot.at + slot.velocity * t + Vector3.new(0, -25 * t * t, 0)
				) * CFrame.Angles(t * 8, t * 6, t * 4)
				slot.part.Transparency = math.clamp((t - 0.3) / 0.2, 0, 1)
				if t >= 0.5 then
					slot.started = nil
					slot.part.Transparency = 1
				end
			end
		end
		for _, slot in candies do
			if slot.started then
				local t = math.max(0, now - slot.started)
				local goal = (candyBig.AbsolutePosition + candyBig.AbsoluteSize / 2) / uiScale.Scale
				local p = t < 0.15 and slot.at:Lerp(slot.out, 1 - (1 - t / 0.15) ^ 2)
					or slot.out:Lerp(goal, math.clamp((t - 0.15) / 0.4, 0, 1) ^ 2)
				slot.label.Position = UDim2.fromOffset(p.X, p.Y)
				slot.label.Rotation = t * 540
				if t >= 0.55 then
					slot.started, slot.label.Visible = nil, false
					collectStep = now - collectAt <= 1 and math.min(7, collectStep + 1) or 0
					collectAt = now
					play(Config.Sounds.CandyTick, 2 ^ (collectStep / 12), 0.45)
					candyTick(0)
				end
			end
		end
	end)
	remotes:WaitForChild("WildHit").OnClientEvent:Connect(
		function(
			who: Player,
			at: Vector3,
			damage: number,
			part: BasePart?,
			crit: boolean?,
			hp: number?,
			maxHp: number?
		)
			if not nearby(who, at) then
				return
			end
			local step = who == player and FarmFX.step or (FarmFX.steps[who] or 1)
			local delayFor = who == player and math.max(0, FarmFX.impactAt - os.clock()) or 0
			task.delay(delayFor, function()
				if part and part.Parent then
					crack(part, hp, maxHp)
				end
				if who == player then
					FarmFX.arc(step)
					if part then
						FarmFX.impact(part, at, step, hp == 0)
						hitAt[part] = os.clock()
					end
					damageText(
						at + Vector3.new((math.random() - 0.5) * 2.5, 3, 0),
						damage,
						crit and Palette.ORANGE or Color3.new(1, 1, 1)
					)
					countHit(at)
				else
					burst(at, Palette.ORANGE, 3, 10, Palette.SPARKLE, 0.5)
					play(
						({ Config.Sounds.HitA, Config.Sounds.HitB, Config.Sounds.HitC })[step],
						1,
						0.3
					)
					if part and part.Parent then
						juice(part, step, step == 3 and 0.13 or 0.045)
					end
				end
			end)
		end
	)
	remotes
		:WaitForChild("WildPopped").OnClientEvent
		:Connect(function(at: Vector3, seedId: string, winner: Player?, candy: number?)
			if not nearby(winner, at) then
				return
			end
			local delayFor = winner == player and math.max(0, FarmFX.impactAt - os.clock()) or 0
			task.delay(delayFor, function()
				local seed = seedById[seedId or ""]
				local color = seed and seedColor(seed) or Palette.ORANGE
				if winner == player then
					FarmFX.arc(FarmFX.step)
					if FarmFX.snapshot then
						FarmFX.impact(FarmFX.snapshot, at, FarmFX.step, true)
					end
					FarmFX.hasImpact = true
				end
				burst(at, color, winner == player and 26 or 13, 24, Palette.SPARKLE, 1.1)
				burst(at, Palette.ORANGE, winner == player and 8 or 4, 16, nil, 0.8)
				chunks(at, 6)
				play(Config.Sounds.Break, 1, 0.7)
				if seedId == "Golden" then
					play(Config.Sounds.Reveal, 1.2, 0.4)
					if winner == player then
						goldUntil = os.clock() + 0.12
					end
				end
				if winner == player then
					FarmFX.freezeUntil = math.max(
						FarmFX.freezeUntil,
						os.clock() + (FarmFX.step == 3 and 0.13 or 0.11)
					)
					candyBurst(at + Vector3.new(0, 1, 0), 8)
					floatText(
						at + Vector3.new(0, 4, 0),
						"+" .. short(candy or 0) .. " 🍬",
						color,
						seed and seed.order >= 3
					)
					shake(0.4 * (mobile and 0.6 or 1), 5)
				end
			end)
		end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local target, now = currentTarget(), os.clock()
			for _, part in wildFolder and wildFolder:GetChildren() or {} do
				local bar = part:FindFirstChild("HpBar")
				if bar and bar:IsA("BillboardGui") then
					bar.Enabled = part == target
						or now - (hitAt[part] or -math.huge) < Config.HitBarSeconds
				end
			end
		end
	end)
end
remotes:WaitForChild("Harvested").OnClientEvent:Connect(function(who: Player, at: Vector3)
	burst(at + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 200, 90), 20, 14, Palette.SPARKLE, 0.8)
	burst(at + Vector3.new(0, 1, 0), Color3.fromRGB(255, 130, 40), 12, 11, Palette.SPARKLE, 0.5)
	if who == player then
		play(Config.Sounds.Pick, 1.1, 0.8)
		floatText(at + Vector3.new(0, 3, 0), "+1 🎃", Color3.fromRGB(255, 170, 60))
	end
end)

remotes
	:WaitForChild("Brewed").OnClientEvent
	:Connect(function(who: Player, at: Vector3, results: { any })
		burst(
			at + Vector3.new(0, 2, 0),
			Color3.fromRGB(200, 140, 255),
			40,
			26,
			Palette.SPARKLE,
			1.2
		)
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
		burst(at + Vector3.new(0, 3, 0), Color3.fromRGB(255, 150, 210), 30, 22, Palette.SPARKLE, 1)
		if who == player then
			floatText(
				at + Vector3.new(0, 7, 0),
				"+" .. short(total) .. " 🍬",
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
			"+" .. short(total),
			Color3.fromRGB(255, 170, 60)
		)
	end)

remotes
	:WaitForChild("GhostPopped").OnClientEvent
	:Connect(function(at: Vector3, by: Player?, candy: number)
		if candy > 0 then
			burst(at, Color3.fromRGB(220, 235, 255), 26, 26, Palette.SPARKLE, 1.2)
			-- White poof: a puffy smoke cloud on top of the sparkles.
			burst(at, Color3.fromRGB(255, 255, 255), 18, 9, nil, 3)
			play(Config.Sounds.Bonk, 1.25, 0.9)
			if by == player then
				floatText(
					at + Vector3.new(0, 3, 0),
					"BONK! +" .. short(candy) .. " 🍬",
					Color3.fromRGB(200, 230, 255)
				)
				-- About 0.15 s of shake (7 steps of 0.02 s).
				task.spawn(shake, 0.6, 7)
			end
		elseif by == nil then
			burst(at, Color3.fromRGB(220, 235, 255), 8, 12, Palette.SPARKLE, 0.8)
			burst(at, Color3.fromRGB(255, 255, 255), 6, 6, nil, 1.6)
			play(Config.Sounds.Bonk, 1.4, 0.6)
		end
	end)

remotes:WaitForChild("Stolen").OnClientEvent:Connect(function()
	if Config.Raid.grace < 1e9 then
		hint("Recover your stolen pet!")
	end
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
		burst(at, Color3.fromRGB(255, 120, 60), stunned and 18 or 10, 14, Palette.SPARKLE, 0.9)
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
			Services.TweenService:Create(lane, TweenInfo.new(0.4), { Transparency = 1 }):Play()
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
		Services.TweenService
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
	play(Config.Sounds.HitC, kind == "Slam" and 0.85 or 1, 1)
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
	:Connect(function(kind: string, payouts: { [string]: number }, _mvp: Player?)
		if kind == "results" then
			return
		end
		local mine = kind == "won" and payouts[tostring(player.UserId)] or nil
		if kind ~= "results" and not unlocked("King") and not mine then
			return
		end
		if kind == "won" then
			-- The result strip owns the payout message.
			burst(kingFace.Position, Color3.fromRGB(255, 220, 120), 120, 60, Palette.SPARKLE, 2.4)
			burst(kingFace.Position, Color3.fromRGB(255, 140, 40), 40, 30)
			play(Config.Sounds.Reveal, 1, 0.8)
			task.spawn(shake, 2, 14)
			local camera = workspace.CurrentCamera
			camera.FieldOfView = 90
			Services.TweenService
				:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { FieldOfView = 70 })
				:Play()
		elseif kind == "wake" then
			toast("THE PUMPKIN KING WAKES!", "Everyone bonk him!")
			play(Config.Sounds.Brew, 0.4, 1)
		elseif kind == "swell" then
			for _, who in Services.Players:GetPlayers() do
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
			play(Config.Sounds.Growl, 1, 0.9)
			task.spawn(shake, 1, 8)
		elseif kind == "phase3" then
			toast("THE KING IS ANGRY!", "Faster attacks. Finish him!")
			play(Config.Sounds.Brew, 0.4, 1)
		elseif kind == "escaped" then
			toast(
				"THE KING ESCAPED",
				"Qualifiers receive 25% candy. Next King Fight is on the clock."
			)
		end
	end)

remotes:WaitForChild("RainCollected").OnClientEvent:Connect(function(collector: Player, at: Vector3)
	burst(at, Color3.fromRGB(255, 210, 80), 14, 14, Palette.SPARKLE, 0.8)
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

local ZoneView: { [string]: any } = { progress = {}, owned = {} }
do
	local folders: { [string]: Instance } = {}
	-- X/Z boxes per zone: { minX, maxX, minZ, maxZ, lane? }. On the lane map one box per zone
	-- covers its Z range (ZMin / ZMax attributes, else Config zMin / zMax; lane = true); without a
	-- range each Spawn part's footprint is its own box.
	local boxes: { [string]: { { number } } } = {}
	local wallLook: { [BasePart]: number } = {}

	local function cacheZones()
		local owned = {}
		for id in string.gmatch(player:GetAttribute("Zones") or "", "[^,]+") do
			owned[id] = true
		end
		ZoneView.owned = owned
	end
	local function cacheProgress()
		local ok, data = pcall(
			Services.HttpService.JSONDecode,
			Services.HttpService,
			player:GetAttribute("ZoneProgress") or "{}"
		)
		ZoneView.progress = ok and type(data) == "table" and data or {}
	end
	player:GetAttributeChangedSignal("Zones"):Connect(cacheZones)
	player:GetAttributeChangedSignal("ZoneProgress"):Connect(cacheProgress)
	cacheZones()
	cacheProgress()
	local function ownedSet(): { [string]: boolean }
		return ZoneView.owned
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

	function ZoneView.gateCost(zoneId)
		local before = Config.ZoneOrder[(table.find(Config.ZoneOrder, zoneId) or 1) - 1]
		local d = ZoneView.progress
		local q = d.quests and before and d.quests[before]
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
			local price, discount = ZoneView.gateCost(zoneId)
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
						.. ": "
						.. Config.gateBenefits(zoneId)
					prompt.ObjectText = short(price) .. " candy" .. (discount and " -25%" or "")
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
				gateGui.MaxDistance = 60
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
	zoneLine.Size = UDim2.fromScale(0.50, 0.035)
	zoneLine.BackgroundColor3 = Color3.new(0, 0, 0)
	zoneLine.BackgroundTransparency = 1
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
		zoneText.Text = def and def.title or "Safe Zone"
		zoneText.TextColor3 = def and def.color or Color3.fromRGB(190, 255, 170)
		zoneLine.Visible = true
		zoneLine.BackgroundTransparency = 0.55
		UI.zoneStamp = (UI.zoneStamp or 0) + 1
		local stamp = UI.zoneStamp
		zoneText.TextTransparency, zoneStroke.Transparency = 0, 0
		zonePop.Scale = 0.8
		task.delay(2.5, function()
			if UI.zoneStamp ~= stamp then
				return
			end
			UI.tween(zoneText, 0.4, { TextTransparency = 1 })
			UI.tween(zoneStroke, 0.4, { Transparency = 1 })
			UI.tween(zoneLine, 0.4, { BackgroundTransparency = 1 })
		end)
		Services.TweenService
			:Create(zonePop, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 })
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
	local celebration = { untilAt = 0, income = player:GetAttribute("Income") or 0 }
	player:GetAttributeChangedSignal("Income"):Connect(function()
		local income = player:GetAttribute("Income") or 0
		local gain = income - celebration.income
		celebration.income = income
		if os.clock() < celebration.untilAt and gain > 0 then
			local pen = myPatch()
			local soil = pen and pen:FindFirstChild("Soil")
			if soil then
				floatText(
					soil.Position + Vector3.yAxis * 6,
					"+" .. short(gain) .. "/s!",
					Palette.BUY,
					true
				)
			end
		end
	end)
	player:GetAttributeChangedSignal("Zones"):Connect(function()
		local now = ownedSet()
		if player:GetAttribute("Loaded") then
			for _, zoneId in Config.ZoneOrder do
				local def = Config.Zones[zoneId]
				if def and now[zoneId] and not known[zoneId] and (def.cost or 0) > 0 then
					celebration.untilAt = os.clock() + Config.CarveSeconds + 10
					toast(string.upper(def.title) .. " UNLOCKED!", Config.gateBenefits(zoneId))
					local pen = myPatch()
					local soil = pen and pen:FindFirstChild("Soil")
					if soil then
						burst(
							soil.Position + Vector3.yAxis * 3,
							Palette.ORANGE,
							36,
							14,
							Palette.SPARKLE,
							1
						)
					end
					play(Config.Sounds.Buy, 1, 0.8)
					Center.purchaseBurst()
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
	bar.Size = UDim2.fromScale(Palette.mobile() and 0.74 or 0.46, 0.042)
	UI.objective = bar
	local function fitObjective()
		local touch = Palette.mobile()
		bar.Position = UDim2.fromScale(0.5, touch and 0.19 or Config.UI.objectiveY)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		UI.objectiveVerb = nil
		fitObjective()
	end)
	Services.UserInputService.LastInputTypeChanged:Connect(fitObjective)
	fitObjective()
	-- Only the title has a soft pill; the banner frame leaves world billboards visible.
	bar.BackgroundColor3 = Color3.fromRGB(22, 14, 32)
	bar.BackgroundTransparency = 0.30
	bar.BorderSizePixel = 0
	bar.Parent = gui
	corner(bar, 16)
	local barStroke = stroke(bar, 0)
	barStroke.Color = Color3.fromRGB(10, 5, 16)
	barStroke.Transparency = 0.2
	local title = textLabel(bar, "", Color3.new(1, 1, 1), "title")
	title.BackgroundColor3 = Color3.fromRGB(22, 14, 32)
	title.BackgroundTransparency = 1
	corner(title, 12)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0)
	title.Position = UDim2.fromScale(0.54, 0)
	title.Size = UDim2.fromScale(0.88, 1)
	title.TextScaled = false
	local titlePad = Instance.new("UIPadding")
	titlePad.PaddingLeft = UDim.new(0, 12)
	titlePad.PaddingRight = UDim.new(0, 12)
	titlePad.Parent = title
	local titleStroke = title:FindFirstChildOfClass("UIStroke") :: UIStroke
	titleStroke.Thickness = 3
	titleStroke.Color = Color3.new(0, 0, 0)
	local progress = textLabel(bar, "", Color3.fromRGB(255, 225, 150))
	progress.Position = UDim2.fromScale(0, 0.65)
	progress.Size = UDim2.fromScale(1, 0.35)
	progress.TextColor3 = Color3.new(1, 1, 1)
	progress.TextScaled = false
	progress.Visible = false
	local function sizeObjective()
		title.TextSize = math.max(11, gui.AbsoluteSize.Y * Config.UI.Tokens.type.objective)
		progress.TextSize = math.max(10, gui.AbsoluteSize.Y * 0.024)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeObjective)
	sizeObjective()
	local questToggle = UI.tile("Quests", Config.UI.Tokens.rarity[5], 2)
	UI.questButton = questToggle
	-- Right tile owns its responsive placement.
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
		questToggle.Visible = false
		if anyPanelOpen() then
			questPanel.Visible = false
			return
		end
		local data = ZoneView.progress
		local zones = garden:FindFirstChild("Zones")
		for _, id in Config.ZoneOrder do
			local folder = zones and zones:FindFirstChild(id)
			local z = Config.Zones[id]
			if
				folder
				and root.Position.Z >= (folder:GetAttribute("ZMin") or z.zMin)
				and root.Position.Z < (folder:GetAttribute("ZMax") or z.zMax)
			then
				local q = data.quests and data.quests[id] or {}
				questToggle.Visible = false
				questPanel.AnchorPoint = Vector2.new(1, 0)
				questPanel.Position = UDim2.fromScale(0.67, Palette.mobile() and 0.25 or 0.09)
				questPanel.Size = UDim2.fromScale(Palette.mobile() and 0.48 or 0.28, 0.12)
				questPanel.Visible = (player:GetAttribute("Carry") or 0) == 0
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
		questPanel.Visible = false
		questPanel.Text = "Enter a zone to see its quests"
	end
	local popScale = Instance.new("UIScale")
	popScale.Parent = bar
	local objectiveIcon = Instance.new("Frame")
	objectiveIcon.BackgroundTransparency = 1
	objectiveIcon.Position, objectiveIcon.Size =
		UDim2.fromScale(0.015, 0.1), UDim2.fromScale(0.08, 0.8)
	objectiveIcon.Parent = bar
	UI.icon(objectiveIcon, "Pets")
	title.RichText = true
	title:SetAttribute("TypeSize", Config.UI.Tokens.type.objective)

	local function setObjective(verb: string, sub: string)
		if UI.objectiveVerb ~= verb then
			UI.objectiveVerb = verb
			local textSize =
				math.max(11, gui.AbsoluteSize.Y / uiScale.Scale * Config.UI.Tokens.type.objective)
			local measured = Services.TextService:GetTextSize(
				verb,
				textSize,
				Enum.Font.GothamBold,
				Vector2.new(10000, 10000)
			)
			bar.Size = UDim2.fromOffset(
				math.min(gui.AbsoluteSize.X / uiScale.Scale * 0.80, measured.X + textSize * 2.6),
				textSize * 1.45
			)
			title.Text = verb:gsub("Pumpkin", '<font color="#FF8A1A">Pumpkin</font>')
			popScale.Scale = Palette.mobile() and 1.03 or 1.18
			Services.TweenService
				:Create(popScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 })
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
		ARROWS = 0,
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
		if not UI.guideBeam then
			UI.guideA, UI.guideB = Instance.new("Attachment"), Instance.new("Attachment")
			UI.guideA.Parent, UI.guideB.Parent = workspace.Terrain, workspace.Terrain
			UI.guideBeam = Instance.new("Beam")
			UI.guideBeam.Attachment0, UI.guideBeam.Attachment1 = UI.guideA, UI.guideB
			UI.guideBeam.Width0, UI.guideBeam.Width1 = 0.20, 0.08
			UI.guideBeam.Color = ColorSequence.new(Config.UI.Tokens.go)
			UI.guideBeam.Transparency = NumberSequence.new(0.65)
			UI.guideBeam.FaceCamera, UI.guideBeam.Parent = true, workspace.Terrain
		end
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
		UI.guideBeam.Enabled = on and not anyPanelOpen()
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
		for _, other in Services.Players:GetPlayers() do
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
			UI.guideBeam.Enabled = false
			return
		end
		-- Flat unit vector from you to the target: each arrow's -Z (its tip) points along it. The
		-- chain is drawn even when the target is behind the camera: it then runs toward the lens
		-- and leads the eye round.
		local dir = flat.Unit
		local feet = groundY(root.Position, root.Position.Y - 3)
		UI.guideA.WorldPosition = Vector3.new(root.Position.X, feet + 0.25, root.Position.Z)
		UI.guideB.WorldPosition = UI.guideA.WorldPosition + dir * math.min(dist, 12)
		-- The chain always reaches the target: spacing stretches when it is far away.
		local span = dist - AK.FIRST - AK.RING_R - 1
		local spacing = math.max(AK.SPACING, span / math.max(1, AK.ARROWS - 1))
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
	Services.RunService.RenderStepped:Connect(function()
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
			return Services.HttpService:JSONDecode(raw)
		end)
		ordersData = ok and type(data) == "table" and data or nil
	end
	player:GetAttributeChangedSignal("Orders"):Connect(readOrders)
	readOrders()

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

	-- Carrying toward your base: "Go to your pen!" until you stand on it, then "Place it!".
	local function goHome(root: BasePart, soil: BasePart): string
		local at = soil.CFrame:PointToObjectSpace(root.Position)
		return math.abs(at.X) <= soil.Size.X / 2 + 4
				and math.abs(at.Z) <= soil.Size.Z / 2 + 4
				and "Step into the red ring!"
			or "Bring it to your pen!"
	end

	-- An active King Fight owns the objective; otherwise carry home or choose a progression goal.
	local touredZone = nil
	local function objective(data, root: BasePart, soil: BasePart): (string, string, Vector3?)
		if state:GetAttribute("KingActive") then
			return "Hit the Pumpkin King!", "Follow the arrow to the King", kingFace.Position
		end
		if (player:GetAttribute("Carry") or 0) > 0 then
			local delta = root.Position - soil.Position
			local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
			return goHome(root, soil),
				string.format("%d studs", math.floor(distance + 0.5)),
				soil.Position
		end
		if unlocked("King") and state:GetAttribute("KingWarning") then
			return "Meet the Pumpkin King!", "Follow the arrow to the throne", kingFace.Position
		end
		local zone = zoneTarget(root.Position) or soil.Position
		local arrived = player:GetAttribute("ObjectiveZone")
		local def = arrived and Config.Zones[arrived]
		if def and ZoneView.has(arrived) and touredZone ~= arrived then
			if root.Position.Z < def.zMin + 20 then
				local nest = hoardSpot(arrived)
				return "Explore " .. def.title .. "!",
					"Steal a Pumpkin",
					nest or ZoneView.gate(arrived)
			end
			touredZone = arrived
		end
		if data.tutorial then
			local step = data.step or 1
			if step <= 2 then
				local nest = hoardSpot("Zone1")
				return step == 1 and "Steal a Pumpkin!" or "Place it in your pen!",
					step == 1 and "Hold E at the nest" or "Your pumpkin cracks open in 6 seconds",
					step == 1 and nest or soil.Position
			elseif step == 3 then
				return "Smash pumpkins for 50 candy!", "Swing your scythe", zone
			elseif step == 4 then
				return "Buy the Iron Scythe!",
					short(Config.Tools[2].cost) .. " candy",
					stallPosition("Seeds")
			else
				return "Unlock the Graveyard!", "Hold E at the gate", ZoneView.gate("Zone2")
			end
		end
		local owned = {}
		for id in string.gmatch(player:GetAttribute("Tools") or "", "[^,]+") do
			owned[id] = true
		end
		local rank = 0
		for i, tool in Config.Tools do
			if owned[tool.id] then
				rank = math.max(rank, i)
			end
		end
		for i, tool in Config.Tools do
			if tool.cost and i > rank and not owned[tool.id] and candyValue.Value >= tool.cost then
				return "Buy " .. tool.name .. "!",
					short(tool.cost) .. " candy",
					stallPosition("Seeds")
			end
		end
		local nextZone = ZoneView.nextLocked()
		local nextDef = nextZone and Config.Zones[nextZone]
		local price = nextZone and ZoneView.gateCost(nextZone)
		if nextDef and price and candyValue.Value >= price then
			return "Unlock the " .. nextDef.title .. "!",
				short(price) .. " candy",
				ZoneView.gate(nextZone)
		end
		if
			(player:GetAttribute("PenFilled") or 0)
			< (player:GetAttribute("PenSlots") or Config.Progression.baseSlots)
		then
			local nest, ready = hoardSpot("Zone1")
			if ready then
				return "Steal a Pumpkin!", "Hold E for a pet", nest
			end
		end
		return "Smash pumpkins!",
			nextDef and ("Save " .. short(price) .. " candy for " .. nextDef.title)
				or "Earn candy for your next upgrade",
			zone
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
				setObjective(
					player:GetAttribute("Loaded") and "Returning to your farm..."
						or "Loading your farm...",
					""
				)
				placeArrows(nil)
				continue
			end
			refreshQuests(root)
			local verb, sub, target = objective(data, root, soil)
			bar.Visible = not anyPanelOpen()
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
	run.Position = UDim2.fromScale(0.5, 0.18)
	run.Size = UDim2.fromScale(0.10, 0.055)
	run.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
	run.Visible = false
	run.Parent = gui
	corner(run, 12)
	stroke(run, 2.5).Color = Color3.new(0, 0, 0)
	run.Size = UDim2.fromScale(Palette.mobile() and 0.34 or 0.22, 0.055)
	local runLabel = textLabel(run, "RUN!!", Color3.new(1, 1, 1), "shout")
	runLabel.Position = UDim2.fromOffset(8, 5)
	runLabel.Size = UDim2.new(1, -16, 1, -10)
	local runScale = Instance.new("UIScale")
	runScale.Parent = run

	local drop = makeButton(gui, "DROP", Config.UI.Tokens.stop)
	drop.Parent = gui
	drop.AnchorPoint = Vector2.new(0.5, 0)
	drop.Position = UDim2.fromScale(0.5, 0.80)
	drop.Size = UDim2.fromScale(0.15, 0.055)
	drop.Visible = false
	drop.Activated:Connect(function()
		dropRemote:FireServer()
	end)

	-- Vignette and flash live in their own unscaled ScreenGui so they always cover the screen.
	local alarmGui = Instance.new("ScreenGui")
	alarmGui.Name = "PatchAlarm"
	alarmGui.ResetOnSpawn = false
	alarmGui.IgnoreGuiInset = true
	alarmGui.DisplayOrder = -1
	alarmGui.Parent = player:WaitForChild("PlayerGui")
	local vignette = Instance.new("Frame")
	vignette.BackgroundTransparency = 1
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.Visible = false
	vignette.Parent = alarmGui
	local edges: { Frame } = {}
	for _, e in
		{
			{ Vector2.new(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.08), 90 },
			{ Vector2.new(0, 1), UDim2.fromScale(0, 1), UDim2.fromScale(1, 0.08), -90 },
			{ Vector2.new(0, 0), UDim2.fromScale(0, 0.08), UDim2.fromScale(0.08, 0.84), 0 },
			{ Vector2.new(1, 0), UDim2.fromScale(1, 0.08), UDim2.fromScale(0.08, 0.84), 180 },
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

	local function refresh()
		local safe = not rootPart() or inHub()
		local danger = player:GetAttribute("GuardChasing") == true
			or (player:GetAttribute("CarryStolen") or 0) > 0
		run.Visible = danger and not safe and not anyPanelOpen()
		runLabel.Text = player:GetAttribute("GuardChasing")
				and ("GUARD " .. tostring(player:GetAttribute("GuardGap") or "?") .. " studs - RUN!")
			or "RUN TO YOUR PEN!"
		drop.Visible = (
			(player:GetAttribute("CarryStolen") or 0) > 0
			or (player:GetAttribute("CarryHoard") or 0) > 0
		) and not anyPanelOpen()
		vignette.Visible = danger and not safe and not anyPanelOpen()
	end
	Services.RunService.RenderStepped:Connect(function()
		refresh()
		local wave = 0.5 + 0.5 * math.sin(os.clock() * 6)
		for _, edge in edges do
			edge.BackgroundTransparency = 0.65 + 0.1 * (1 - wave)
		end
		runScale.Scale = 1 + 0.07 * wave
	end)

	remotes:WaitForChild("StealAlarm").OnClientEvent:Connect(function(kind: string, a, b)
		if kind == "stole" then
			hint('You stole a <font color="#FF3B3B">Pumpkin</font>!')
			play(Config.Sounds.Pop, 1, 0.8)
			Center.purchaseBurst()
			task.spawn(shake, 0.5, 6)
		elseif kind == "robbed" then
			hint('⚠ Someone is <font color="#FF3B3B">stealing</font> from your pen!')
			hint(
				string.format(
					"%s took your %s pumpkin. Bonk them to get it back!",
					tostring(a),
					tostring(b)
				)
			)
			play(Config.Sounds.Growl, 1, 0.9)
			for k = 0, 1 do
				task.delay(k * 0.45, function()
					flash.BackgroundTransparency = 0.45
					Services.TweenService
						:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
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
			for _, who in Services.Players:GetPlayers() do
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
		local root = rootPart()
		if not root or (root.Position - p.Position).Magnitude <= 60 or not p.Parent then
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
		bb.MaxDistance = 60
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = fontFace("small")
		label.TextScaled = true
		label.TextColor3 = Palette.MONEY
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
		Services.TweenService
			:Create(pop, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 })
			:Play()
		Services.TweenService
			:Create(
				bb,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ StudsOffsetWorldSpace = bb.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }
			)
			:Play()
		local fade =
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.5)
		Services.TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
		Services.TweenService:Create(outline, fade, { Transparency = 1 }):Play()
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

-- Third slot: Daily before gate 1; claims remain restricted to the hub.
do
	function confetti(parentGui: Instance?)
		local colors = {
			Color3.fromRGB(255, 80, 120),
			Color3.fromRGB(255, 210, 60),
			Color3.fromRGB(90, 220, 255),
			Color3.fromRGB(120, 235, 90),
			Color3.fromRGB(190, 120, 255),
			Color3.fromRGB(255, 150, 50),
		}
		for i = 1, 20 do
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
			local out = Services.TweenService:Create(
				bit,
				TweenInfo.new(up, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.fromScale(x, y),
					Rotation = bit.Rotation + math.random(-180, 180),
				}
			)
			out:Play()
			out.Completed:Once(function()
				Services.TweenService
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

	local frame, list = panel("Daily")
	list:FindFirstChildOfClass("UIListLayout"):Destroy()
	list.AutomaticCanvasSize, list.CanvasSize, list.ScrollingDirection =
		Enum.AutomaticSize.None, UDim2.new(), Enum.ScrollingDirection.X
	list.Position, list.Size, list.ZIndex =
		UDim2.fromScale(0.025, 0.19), UDim2.fromScale(0.95, 0.60), 12
	local daily = UI.tile("Daily", Config.UI.Tokens.info, 3)
	UI.dailyButton = daily
	local tiles, status = {}, nil
	local busy, pending = false, false
	local footer = textLabel(frame, "Loading daily gifts...", Color3.new(1, 1, 1))
	footer.Position, footer.Size, footer.ZIndex =
		UDim2.fromScale(0.14, 0.84), UDim2.fromScale(0.82, 0.09), 16
	local clock = UI.box(
		frame,
		"Clock",
		UDim2.fromScale(0.05, 0.83),
		UDim2.fromScale(0.08, 0.10),
		Config.UI.Tokens.panel,
		16
	)
	clock.BackgroundTransparency = 1
	UI.icon(clock, "Clock")
	local function refresh()
		local allowed = inHub()
			and (player:GetAttribute("Carry") or 0) == 0
			and not player:GetAttribute("GuardChasing")
		local ready = status and status.ready and player:GetAttribute("DailyClaimable") == true
		for day, entry in tiles do
			local claimed = status and day <= status.claimedThrough
			local current = status and day == status.day and not claimed
			entry.tile.BackgroundColor3 = claimed and Config.UI.Tokens.well
				or current and Config.UI.Tokens.card
				or Config.UI.Tokens.off
			entry.icon.BackgroundTransparency = 1
			entry.check.Visible = claimed == true
			entry.claim.Visible, entry.claim.Active =
				current == true, current and ready and allowed and not busy or false
			entry.claim.Text = ready and "CLAIM" or "Wait"
			entry.claim.BackgroundColor3 = ready and Config.UI.Tokens.go or Config.UI.Tokens.off
			entry.outline.Color = current and Color3.new(1, 1, 1)
				or day == Config.DailyMaxStreak and Config.UI.Tokens.candy
				or Config.UI.Tokens.ink
			entry.outline.Transparency = current and (0.12 + 0.12 * math.sin(os.clock() * math.pi))
				or 0
		end
		if status then
			local seconds = math.max(0, status.nextAt - os.time())
			footer.Text = ready and ("Day " .. status.day .. " is ready")
				or string.format(
					"Next in %dh %dm",
					math.floor(seconds / 3600),
					math.floor(seconds % 3600 / 60)
				)
		end
		if not allowed then
			frame.Visible = false
		end
	end
	local function loadStatus()
		if pending then
			return
		end
		pending = true
		task.spawn(function()
			local ok, result = pcall(function()
				return remotes:WaitForChild("DailyStatus"):InvokeServer()
			end)
			pending = false
			if ok and result then
				status = result
			else
				footer.Text = "Daily gifts unavailable"
			end
			refresh()
		end)
	end
	local function claim()
		if busy or not status or not status.ready then
			return
		end
		busy = true
		refresh()
		local ok, claimed = pcall(function()
			return remotes:WaitForChild("ClaimDaily"):InvokeServer()
		end)
		busy = false
		if not ok or not claimed then
			hint("Daily gift is not ready")
		end
		loadStatus()
	end
	for day = 1, Config.DailyMaxStreak do
		local tile = UI.box(list, "Day" .. day, UDim2.new(), UDim2.new(), Config.UI.Tokens.off, 13)
		corner(tile, 8)
		local outline = stroke(tile, 2.5)
		local label = textLabel(tile, "Day " .. day, Color3.new(1, 1, 1))
		label.Size, label.ZIndex = UDim2.fromScale(1, 0.17), 16
		local icon = UI.box(
			tile,
			"Reward",
			UDim2.fromScale(0.10, 0.21),
			UDim2.fromScale(0.80, 0.37),
			Config.UI.Tokens.off,
			15
		)
		icon.BackgroundTransparency = 1
		UI.icon(icon, day == Config.DailyMaxStreak and "Pets" or "Candy")
		local amount = Config.DailyCandy
			* day
			* (day == Config.DailyMaxStreak and Config.DailyLastMult or 1)
		local value = textLabel(tile, short(amount), Config.UI.Tokens.candy)
		value.Position, value.Size, value.ZIndex =
			UDim2.fromScale(0.02, 0.60), UDim2.fromScale(0.96, 0.15), 16
		-- Day 7's pumpkin is presentation only; the existing reward remains candy.
		if day == Config.DailyMaxStreak then
			UI.sticker(tile, "BIG", Config.UI.Tokens.candy)
		end
		local check = UI.box(
			tile,
			"Claimed",
			UDim2.fromScale(0.32, 0.31),
			UDim2.fromScale(0.50, 0.25),
			Config.UI.Tokens.good,
			18
		)
		check.BackgroundTransparency, check.Visible = 1, false
		local shortArm = UI.box(
			check,
			"Short",
			UDim2.fromScale(0, 0.53),
			UDim2.fromScale(0.46, 0.15),
			Config.UI.Tokens.good,
			19
		)
		shortArm.Rotation = 45
		local longArm = UI.box(
			check,
			"Long",
			UDim2.fromScale(0.25, 0.38),
			UDim2.fromScale(0.75, 0.15),
			Config.UI.Tokens.good,
			19
		)
		longArm.Rotation = -45
		local button = makeButton(tile, "CLAIM", Config.UI.Tokens.go)
		button.Position, button.Size, button.ZIndex =
			UDim2.fromScale(0.04, 0.79), UDim2.fromScale(0.92, 0.19), 18
		for _, d in button:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex += 18
			end
		end
		button.Activated:Connect(claim)
		tiles[day] = { tile = tile, icon = icon, check = check, claim = button, outline = outline }
	end
	local function fit()
		local width = list.AbsoluteSize.X / uiScale.Scale
		local cell = math.max(gui.AbsoluteSize.Y / uiScale.Scale * 0.11, (width - 42) / 7.3)
		local x = 0
		for day, entry in tiles do
			local w = cell * (day == Config.DailyMaxStreak and 1.3 or 1)
			entry.tile.Position, entry.tile.Size = UDim2.fromOffset(x, 4), UDim2.new(0, w, 1, -14)
			x += w + 6
		end
		list.CanvasSize = UDim2.fromOffset(x, 0)
	end
	list:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	daily.Activated:Connect(function()
		if
			not inHub()
			or (player:GetAttribute("Carry") or 0) > 0
			or player:GetAttribute("GuardChasing")
		then
			return
		end
		local open = not frame.Visible
		for _, f in panelFrames do
			f.Visible = false
		end
		frame.Visible = open
		if open then
			loadStatus()
		end
	end)
	remotes:WaitForChild("Daily").OnClientEvent:Connect(function(streak, candy)
		if tiles[streak] then
			local entry = tiles[streak]
			entry.check.Visible = true
			local stamp = entry.check:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			stamp.Parent, stamp.Scale = entry.check, 1.6
			UI.tween(stamp, 0.24, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		toast("Daily gift", "+" .. short(candy))
		if candyShower then
			candyShower(6)
		end
		play(Config.Sounds.Coin, 0.9, 1)
		loadStatus()
	end)
	local elapsed = 0
	Services.RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			if frame.Visible then
				refresh()
			end
		end
	end)
	player:GetAttributeChangedSignal("DailyClaimable"):Connect(function()
		if frame.Visible then
			loadStatus()
		end
	end)
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
	Services.TweenService
		:Create(camera, TweenInfo.new(on and 0.2 or 0.3, Enum.EasingStyle.Quad), {
			FieldOfView = on and Config.SprintFov or 70,
		})
		:Play()
end
ContextActionService:BindAction("Sprint", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		setSprint(not sprinting or Services.UserInputService.KeyboardEnabled)
	elseif inputState == Enum.UserInputState.End and Services.UserInputService.KeyboardEnabled then
		setSprint(false)
	end
	return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle("Sprint", "RUN")
ContextActionService:SetPosition("Sprint", UDim2.fromScale(0.64, 0.52))

Services.RunService.Heartbeat:Connect(function()
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
						Palette.SPARKLE,
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
	FarmFX.held = inputState == Enum.UserInputState.Begin
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
	Services.TweenService
		:Create(disc, TweenInfo.new(warn, Enum.EasingStyle.Linear), {
			Size = Vector3.new(0.2, radius * 2, radius * 2),
		})
		:Play()
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
						Services.TweenService
							:Create(
								rock,
								TweenInfo.new(cfg.length / cfg.speed, Enum.EasingStyle.Linear),
								{ Position = rock.Position + c.direction * cfg.length }
							)
							:Play()
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
					conn = Services.RunService.RenderStepped:Connect(function()
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
	fillGradient.Color = Palette.KING_FILL
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
		local shield = state:GetAttribute("KingShield")
		wideText.Text = shield and string.format("SHIELD: bonk %d lanterns", shield)
			or state:GetAttribute("KingStunned") and "WEAK SPOT x2"
			or string.format("King Fight %s/%s", short(hp), short(maxHp))
		fillGradient.Color = Palette.KING_FILL
	end
	for _, attr in { "Phase", "KingHp", "KingMaxHp", "KingShield", "KingShieldMax", "KingStunned" } do
		state:GetAttributeChangedSignal(attr):Connect(refreshHpBar)
	end
	refreshHpBar()

	local shown = false
	Services.RunService.RenderStepped:Connect(function()
		local want = state:GetAttribute("Phase") == "BloodMoon"
			and not kingFace:GetAttribute("VoxelKing")
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
			bb.MaxDistance = Config.Payoff.petDistance
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
	for _, who in Services.Players:GetPlayers() do
		watchPlayer(who)
	end
	Services.Players.PlayerAdded:Connect(watchPlayer)
	Services.Players.PlayerRemoving:Connect(function(who)
		local bb = crowns[who]
		crowns[who] = nil
		if bb then
			bb:Destroy()
		end
	end)
end

Services.UserInputService.InputBegan:Connect(function(input, processed)
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

remotes
	:WaitForChild("GuardianWake").OnClientEvent
	:Connect(function(model: Model?, _full: boolean?, thief: Player?)
		local camera = workspace.CurrentCamera
		if
			model
			and camera
			and (model:GetPivot().Position - camera.CFrame.Position).Magnitude <= 60
		then
			play(Config.Sounds.Growl, 1, 0.9)
		end
		if thief == player then
			shake(0.8, 12)
			hint("The guard woke up! Bring it to your pen!")
		end
	end)

remotes:WaitForChild("Hoard").OnClientEvent:Connect(function(kind: string, _seedId: string?)
	if kind == "grab" then
		hint("Pumpkin grabbed!")
		play(Config.Sounds.Pop, 1, 0.8)
		Center.purchaseBurst()
		-- Wake feedback keeps the player in control of the camera.
	elseif kind == "bonk" then
		hint(
			'<font color="#FF3B3B">DROPPED!</font> Grab your pumpkins before they return to the nest!'
		)
		local root = rootPart()
		if root then
			floatText(
				root.Position + Vector3.new(0, 5, 0),
				"DROPPED!",
				Color3.fromRGB(255, 70, 60),
				true
			)
		end
		play(Config.Sounds.HitC, 0.85, 1)
		task.spawn(shake, 1.6, 12)
	elseif kind == "safe" then
		hint("You got away! The guardian gives up. Place it in your pen!")
	elseif kind == "deliver" then
		hint("You delivered a Pumpkin to your pen!")
		confetti()
		play(Config.Sounds.Reveal, 1, 0.8)
		play(Config.Sounds.Pop, 1, 0.6)
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
		conn = Services.RunService.RenderStepped:Connect(function()
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
					Services.TweenService
						:Create(slab, TweenInfo.new(0.3), { Transparency = 1 })
						:Play()
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
		play(Config.Sounds.Reveal, 1, 0.8)
		screenFlash.BackgroundColor3 = Color3.new(1, 1, 1)
		screenFlash.BackgroundTransparency = 0.92
		Services.TweenService
			:Create(
				screenFlash,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 150, 215) }
			)
			:Play()
		task.spawn(shake, 0.5, 8)
		local camera = workspace.CurrentCamera
		if camera then
			local out = Services.TweenService:Create(
				camera,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ FieldOfView = 85 }
			)
			out:Play()
			out.Completed:Once(function()
				Services.TweenService
					:Create(
						camera,
						TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ FieldOfView = sprinting and Config.SprintFov or 70 }
					)
					:Play()
			end)
		end
	end

	remotes:WaitForChild("Carved").OnClientEvent:Connect(
		function(
			p: BasePart?,
			ownerId: number?,
			pet: string?,
			isNew: boolean?,
			forceReveal: boolean?
		)
			local camera = workspace.CurrentCamera
			if not p or not p.Parent or not camera then
				return
			end
			local seed = seedById[p:GetAttribute("Seed") or ""]
			if (p.Position - camera.CFrame.Position).Magnitude <= Config.Payoff.petDistance then
				local look = p:FindFirstChild("PetLook")
				for _, part in look and look:GetDescendants() or {} do
					if part:IsA("BasePart") then
						local size = part.Size
						local weld = part:FindFirstChild("LookWeld")
						part.Size = size * 0.8
						Services.TweenService
							:Create(
								part,
								TweenInfo.new(0.35, Enum.EasingStyle.Back),
								{ Size = size }
							)
							:Play()
						if weld and weld:IsA("Weld") then
							local base = weld.C0
							weld.C0 = CFrame.new(base.Position * 0.8) * base.Rotation
							Services.TweenService
								:Create(
									weld,
									TweenInfo.new(0.35, Enum.EasingStyle.Back),
									{ C0 = base }
								)
								:Play()
						end
					end
				end
				local flash = Instance.new("Highlight")
				flash.FillColor = Color3.new(1, 1, 1)
				flash.FillTransparency = 0
				flash.OutlineColor = Color3.new(1, 1, 1)
				flash.OutlineTransparency = 0
				flash.DepthMode = Enum.HighlightDepthMode.Occluded
				flash.Parent = p
				Services.TweenService
					:Create(
						flash,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ FillTransparency = 1, OutlineTransparency = 1 }
					)
					:Play()
				task.delay(0.55, function()
					flash:Destroy()
				end)
				burst(
					p.Position + Vector3.new(0, 1, 0),
					Color3.new(1, 1, 1),
					24,
					16,
					Palette.SPARKLE,
					1
				)
				burst(p.Position, Color3.fromRGB(255, 240, 220), 10, 10, nil, 1.4)
				slabs(p, seed and seedColor(seed) or Palette.ORANGE)
				play(Config.Sounds.Pop, 1, 0.6)
			end
			if ownerId ~= player.UserId or not seed then
				return
			end
			local def = pet and Config.Pets and Config.Pets[pet]
			local name = def and def.display or (seed.name .. " Jack")
			local root = rootPart()
			if forceReveal or isNew then
				if
					seed.order >= Config.RevealOrder
					and root
					and (p.Position - root.Position).Magnitude < 80
				then
					ownerHatch()
				end
				-- The data-only server Reveal remote owns the card, even for distant hatches.
			else
				hint("Your pumpkin hatched: " .. name .. "!")
			end
		end
	)
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
	Services.RunService.RenderStepped:Connect(function()
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
			local root = rootPart()
			local now = workspace:GetServerTimeNow()
			for _, pen in patchFolder:GetChildren() do
				for _, plot in pen:GetChildren() do
					local p = plot.Name == "Plot" and plot:FindFirstChild("Pumpkin")
					if
						p
						and p:IsA("BasePart")
						and p:GetAttribute("Jack")
						and p:GetAttribute("Placed")
						and not p:GetAttribute("Stashed")
						and root
						and (Config.roamPoint(p, now) - root.Position).Magnitude
							<= Config.Payoff.petDistance
					then
						table.insert(list, p)
					end
				end
			end
			pets = list
			task.wait(0.5)
		end
	end)
	Services.RunService.RenderStepped:Connect(function()
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
				or math.abs(math.sin(now * 3)) * 0.18
			p.CFrame = CFrame.new(at + Vector3.yAxis * bob)
				* rotation
				* CFrame.Angles(0, 0, math.sin(now * 2.5 + p.Size.Y) * math.rad(3))
			local anchor = p:FindFirstChild("PetPromptAnchor")
			if anchor then
				anchor.Position = Vector3.zero
			end
		end
	end)
end
-- Carry pumpkins use opaque server mesh carriers, with no halo.

-- Soft nest glow and one subtle Epic+ aura, only for nearby objects.
do
	local effects, candidates = {}, {}
	local function watch(d)
		if d:IsA("BasePart") and d:GetAttribute("Seed") then
			candidates[d] = true
		end
	end
	for _, d in garden:GetDescendants() do
		watch(d)
	end
	garden.DescendantAdded:Connect(watch)
	task.spawn(function()
		while true do
			local root = rootPart()
			local keep = {}
			local zones = garden:FindFirstChild("Zones")
			for p in candidates do
				if not p.Parent then
					candidates[p] = nil
					continue
				end
				if
					p:IsA("BasePart")
					and p:GetAttribute("Seed")
					and root
					and (p.Position - root.Position).Magnitude <= Config.Payoff.petDistance
				then
					local def = Config.Pets[p:GetAttribute("Pet") or ""]
					local nest = p.Name == "HoardPumpkin"
						and not p:GetAttribute("Placed")
						and zones
						and p:IsDescendantOf(zones)
					local epic = def
						and (Config.Economy.rarityRanks[def.rarity] or 0) >= 3
						and p:GetAttribute("Placed")
						and p:GetAttribute("Jack")
					if nest or epic then
						keep[p] = true
						if not effects[p] then
							if nest then
								local light = Instance.new("PointLight")
								light.Name = "NestGlow"
								light.Color = Palette.ORANGE
								light.Brightness, light.Range, light.Shadows = 0.6, 7, false
								light.Parent = p
								effects[p] = light
							else
								local aura = Instance.new("ParticleEmitter")
								aura.Name = "RarityAura"
								aura.Texture = Palette.SPARKLE
								local color = Palette.PURPLE
								for _, r in Config.Rarities do
									if r.name == def.rarity then
										color = r.color
									end
								end
								aura.Color = ColorSequence.new(color)
								aura.Rate = Config.Payoff.auraRate
								aura.LightEmission = 0.5
								aura.Size = NumberSequence.new(0.25, 0)
								aura.Lifetime, aura.Speed =
									NumberRange.new(0.6, 1), NumberRange.new(0.2, 0.6)
								aura.Parent = p
								effects[p] = aura
							end
						end
					end
				end
			end
			for p, fx in effects do
				if not keep[p] then
					fx:Destroy()
					effects[p] = nil
				end
			end
			task.wait(0.6)
		end
	end)
end

-- King results and status icons use the existing event/Center queue; entry is the throne ring.
do
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
				bb.MaxDistance = Config.Payoff.petDistance
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
	for _, who in Services.Players:GetPlayers() do
		hook(who)
	end
	Services.Players.PlayerAdded:Connect(hook)
	Services.Players.PlayerRemoving:Connect(function(who)
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
				resultCard.Position = UDim2.fromScale(0.5, 0.25)
				resultCard.Size = UDim2.fromScale(Palette.mobile() and 0.82 or 0.60, 0.12)
				resultCard.BackgroundColor3 = Palette.DARK
				resultCard.Parent = gui
				corner(resultCard, 18)
				Center.register(resultCard)
				local title = textLabel(
					resultCard,
					data.won and "KING FIGHT COMPLETE!" or "King escaped!",
					Color3.fromRGB(255, 214, 80)
				)
				title.Position = UDim2.fromScale(0.05, 0.06)
				title.Size = UDim2.fromScale(0.9, 0.26)
				local loot = {}
				for _, id in data.crates or {} do
					table.insert(loot, seedById[id].name)
				end
				local podium = {}
				for rank, name in data.podium or {} do
					if name ~= "" then
						table.insert(podium, tostring(rank) .. ". " .. name)
					end
				end
				local body = textLabel(
					resultCard,
					string.format(
						"Damage %s | Rank #%d | %d hits | +%s candy",
						short(data.damage),
						data.rank,
						data.hits,
						short(data.candy)
					)
						.. (#loot > 0 and (" | " .. table.concat(loot, " + ")) or "")
						.. (#podium > 0 and ("\n" .. table.concat(podium, "   ")) or ""),
					Color3.new(1, 1, 1)
				)
				body.Position, body.Size = UDim2.fromScale(0.03, 0.36), UDim2.fromScale(0.94, 0.60)
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

-- The existing YOUR BASE billboard is the sole pen marker.

-- Free travel menu and tier-two dash. Only action names leave this client.
do
	local travel, list = panel("Teleport")
	local teleport = makeButton(UI.settingsList, "Teleport", Config.UI.Tokens.info)
	teleport.Size = UDim2.new(1, 0, 0, 48)
	teleport.LayoutOrder = 3
	local pending = false
	teleport.Activated:Connect(function()
		local open = not travel.Visible
		for _, f in panelFrames do
			f.Visible = false
		end
		travel.Visible = open
	end)
	for i, target in { "My Pen", "Zone Gate" } do
		local b = makeButton(list, target, Palette.BUY)
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

	local run = makeButton(gui, "Sprint [Shift]", Config.UI.Tokens.info)
	run.AnchorPoint = Vector2.new(1, 1)
	run.Position = UDim2.fromScale(0.70, 0.60)
	run.Size = UDim2.fromScale(0.16, 0.05)
	UI.sprintButton = run
	run.Visible = Palette.mobile()
	UI.icon(run, "Sprint")
	for _, d in run:GetDescendants() do
		if d:IsA("UICorner") then
			d.CornerRadius = UDim.new(0.5, 0)
		end
	end
	run.Activated:Connect(function()
		setSprint(not sprinting)
		travel.Visible = false
	end)
	local dashPending = false
	local function dash(_, inputState)
		if
			inputState ~= Enum.UserInputState.Begin
			or Services.UserInputService:GetFocusedTextBox()
			or anyPanelOpen()
			or dashPending
		then
			return Enum.ContextActionResult.Pass
		end
		local tier = 1
		for i, tool in Config.Tools do
			if tool.id == player:GetAttribute("Tool") then
				tier = i
			end
		end
		if tier < Config.Dash.tier then
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
	ContextActionService:SetPosition("ScytheDash", UDim2.fromScale(0.62, 0.52))
	Services.RunService.Heartbeat:Connect(function()
		local touch = Palette.mobile()

		local unlockedDash = false
		for i, tool in Config.Tools do
			if tool.id == player:GetAttribute("Tool") then
				unlockedDash = i >= Config.Dash.tier
			end
		end
		teleport.Visible = ZoneView.has("Zone2")
		if not teleport.Visible then
			travel.Visible = false
		end
		local dashButton = ContextActionService:GetButton("ScytheDash")
		if dashButton then
			dashButton.Visible = touch
				and unlockedDash
				and not anyPanelOpen()
				and (player:GetAttribute("CarryHoard") or 0) == 0
				and (player:GetAttribute("CarryStolen") or 0) == 0
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
		indexButton.Visible = true

		local remaining = math.max(
			0,
			math.ceil((player:GetAttribute("TeleportReadyAt") or 0) - workspace:GetServerTimeNow())
		)
		teleport.Text = remaining > 0 and ("Teleport · " .. remaining .. "s") or "Teleport"
	end)
end

-- U1 HUD: only object icons use viewports; transient candy flights use Frame glyphs.
do
	local pets = UI.tile("Pets", Config.UI.Tokens.go, 1)
	UI.petsButton = pets
	local petsBadge = pillBadge(pets)
	local dailyBadge = pillBadge(UI.dailyButton)
	petsBadge.Text, dailyBadge.Text = "!", "!"
	pets.Activated:Connect(function()
		for _, f in panelFrames do
			f.Visible = false
		end
		indexPanel.Visible = true
		IndexUI.refresh()
	end)
	local carryIcon = Instance.new("Frame")
	carryIcon.Name, carryIcon.BackgroundTransparency, carryIcon.Parent = "CarryIcon", 1, statsFrame
	UI.icon(carryIcon, "Carry")
	local boosts = Instance.new("Frame")
	boosts.Name, boosts.BackgroundTransparency, boosts.AnchorPoint, boosts.Parent =
		"BoostTray", 1, Vector2.new(1, 1), gui
	local boostTiles = {}
	for i, spec in Config.UI.boosts do
		local tile = Instance.new("Frame")
		tile.BackgroundColor3, tile.BackgroundTransparency, tile.Parent =
			Config.UI.Tokens.ink, 0.45, boosts
		corner(tile, 6)
		local label = textLabel(tile, spec.label, Config.UI.Tokens.candy)
		label.Size = UDim2.fromScale(1, 0.60)
		local timer = textLabel(tile, "", Color3.new(1, 1, 1))
		timer.Position, timer.Size = UDim2.fromScale(0, 0.63), UDim2.fromScale(1, 0.37)
		boostTiles[i] = { frame = tile, label = label, timer = timer, spec = spec }
	end
	local function layout()
		local touch, h = Palette.mobile(), gui.AbsoluteSize.Y / uiScale.Scale
		leftBar.Position = UDim2.fromScale(0.012, touch and 0.30 or 0.40)
		for _, object in gui:GetDescendants() do
			if object:IsA("UITextSizeConstraint") then
				object.MinTextSize = math.max(11, math.ceil(h * Config.UI.Tokens.type.caption))
				object.MaxTextSize = math.max(
					object.MinTextSize,
					math.floor(
						h
							* (object.Parent.Name == "Money" and Config.UI.Tokens.type.currency or object.Parent:GetAttribute(
								"TypeSize"
							) or Config.UI.Tokens.type.hud)
							* 1.1
					)
				)
			end
		end
		leftBar.Size = UDim2.fromScale(0.25, 0.25)
		statsFrame.AnchorPoint = touch and Vector2.zero or Vector2.new(0, 1)
		statsFrame.Position = UDim2.fromScale(touch and 0.012 or 0.006, touch and 0.06 or 0.985)
		statsFrame.Size = UDim2.fromOffset(
			touch and gui.AbsoluteSize.X / uiScale.Scale * 0.43 or h * 0.44,
			h * 0.105
		)
		local candy = statsFrame:FindFirstChild("CandyIcon")
		candy.Position = UDim2.fromScale(0, touch and 0 or 0.42)
		candy.Size = UDim2.fromOffset(h * 0.055, h * 0.055)
		candyBig.Position, candyBig.Size =
			UDim2.new(0, h * 0.078, touch and 0 or 0.34, 0), UDim2.new(1, -h * 0.078, 0.66, 0)
		candyBig.TextScaled = false
		candyBig.TextSize = h * 0.055;
		(candyBig:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint).MaxTextSize =
			math.max(11, math.floor(h * 0.055))
		carryIcon.Position, carryIcon.Size =
			UDim2.fromScale(0, touch and 0.59 or 0), UDim2.fromOffset(h * 0.04, h * 0.04)
		carryLabel.Position, carryLabel.Size =
			UDim2.fromScale(0.12, touch and 0.59 or 0), UDim2.fromScale(0.24, 0.38)
		carryLabel.BackgroundColor3, carryLabel.BackgroundTransparency = Config.UI.Tokens.well, 0.25
		carryLabel.TextXAlignment = Enum.TextXAlignment.Center
		if not carryLabel:FindFirstChildOfClass("UICorner") then
			corner(carryLabel)
		end
		boosts.Position, boosts.Size =
			UDim2.fromScale(touch and 0.70 or 0.99, touch and 0.19 or 0.89),
			UDim2.fromOffset(h * 0.21, h * 0.055)
		for i, entry in boostTiles do
			entry.frame.Position, entry.frame.Size =
				UDim2.fromOffset((i - 1) * h * 0.065, 0), UDim2.fromOffset(h * 0.055, h * 0.055)
		end
		if UI.sprintButton then
			UI.sprintButton.Visible = touch and not anyPanelOpen()
			UI.sprintButton.Text = ""
			UI.sprintButton.Size = UDim2.fromOffset(h * 0.065, h * 0.065)
			UI.sprintButton.Position = UDim2.fromScale(0.68, 0.59)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Services.UserInputService.LastInputTypeChanged:Connect(layout)
	layout()
	local cachedPen, penAdded, penRemoving
	local penParts = {}
	local function cachePen(pen)
		if pen == cachedPen then
			return
		end
		if penAdded then
			penAdded:Disconnect()
		end
		if penRemoving then
			penRemoving:Disconnect()
		end
		cachedPen = pen
		table.clear(penParts)
		if not pen then
			return
		end
		local function add(object)
			if object:IsA("BasePart") then
				penParts[object] = true
			end
		end
		penAdded = pen.DescendantAdded:Connect(add)
		penRemoving = pen.DescendantRemoving:Connect(function(object)
			penParts[object] = nil
		end)
		for _, object in pen:GetDescendants() do
			add(object)
		end
	end
	local elapsed = 0
	Services.RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.25 then
			return
		end
		elapsed = 0
		local now = workspace:GetServerTimeNow()
		dailyBadge.Visible = player:GetAttribute("DailyClaimable") == true
		-- Roblox's hotbar owns the scythe-name tooltip; it stays out of the carry line.
		for _, container in { player.Character, player:FindFirstChild("Backpack") } do
			for _, object in container and container:GetChildren() or {} do
				if object:IsA("Tool") then
					object.ToolTip = object.Name
				end
			end
		end
		local pen = myPatch()
		cachePen(pen)
		local ready = false
		if pen then
			for object in penParts do
				if
					object:IsA("BasePart")
					and type(object:GetAttribute("CarveAt")) == "number"
					and object:GetAttribute("CarveAt") <= now
					and not object:GetAttribute("Jack")
				then
					ready = true
					break
				end
			end
		end
		petsBadge.Visible = ready
		local active = false
		for _, entry in boostTiles do
			local value = player:GetAttribute(entry.spec.attribute)
			entry.frame.Visible = entry.spec.timed and type(value) == "number" and value > now
				or not entry.spec.timed and value == true
			entry.timer.Text = entry.spec.timed
					and type(value) == "number"
					and clockText(value - now)
				or "Active"
			active = active or entry.frame.Visible
		end
		boosts.Visible = active
		for _, badge in { petsBadge, dailyBadge, indexBadge } do
			badge.Rotation = 0
			badge.TextTransparency = badge.Visible
					and (0.10 + 0.10 * math.sin(os.clock() * math.pi))
				or 0
		end
		if UI.objective and anyPanelOpen() then
			UI.objective.Visible = false
		end
	end)
	-- Giant world labels should not clip into distant HUD corners.
	for _, object in garden:GetDescendants() do
		if object:IsA("BillboardGui") then
			for _, label in object:GetDescendants() do
				if
					label:IsA("TextLabel")
					and (label.Text == "SHOP" or label.Text == "SELL" or label.Text == "UPGRADES")
				then
					object.MaxDistance = 45
					object.Size = UDim2.fromOffset(150, 44)
				end
			end
		end
	end
end

-- Secondary destinations stay accessible without adding HUD chips or Shop tabs.
do
	for i, entry in { { "Rebirth", hauntPanel }, { "Extras", shopPanel } } do
		local button = makeButton(UI.settingsList, entry[1], Config.UI.Tokens.info)
		button.Size, button.LayoutOrder = UDim2.new(1, 0, 0, 48), i + 1
		button.Activated:Connect(function()
			for _, frame in panelFrames do
				frame.Visible = false
			end
			entry[2].Visible = true
		end)
		local function refresh()
			button.Visible = i == 1 and unlocked("Haunt") or i == 2 and #shopCards > 0
		end
		player:GetAttributeChangedSignal("Unlock_Haunt"):Connect(refresh)
		refresh()
	end
end

-- Repair stale subjects on lifecycle/recovery events; Scriptable cameras own cutscenes.
do
	local function restoreCamera()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local camera = workspace.CurrentCamera
		if
			not camera
			or not humanoid
			or humanoid.Health <= 0
			or camera.CameraType == Enum.CameraType.Scriptable
		then
			return
		end
		local subject = camera.CameraSubject
		local broken = not subject
			or not subject.Parent
			or subject:IsA("Humanoid") and subject ~= humanoid
		if broken then
			camera.CameraType, camera.CameraSubject = Enum.CameraType.Custom, humanoid
		end
	end
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		if player.Character == character then
			restoreCamera()
		end
	end)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(restoreCamera)
	player:GetAttributeChangedSignal("CameraReset"):Connect(restoreCamera)
	restoreCamera()
end

-- Fade pet geometry near the camera/avatar; prompts and server outcomes are untouched.
do
	local parts = setmetatable({}, { __mode = "k" })
	local function register(d)
		if d:IsA("BasePart") and d:FindFirstAncestor("PetLook") then
			parts[d] = true
		end
	end
	for _, d in garden:GetDescendants() do
		register(d)
	end
	garden.DescendantAdded:Connect(register)
	local elapsed = 0
	Services.RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.15 then
			return
		end
		elapsed = 0
		local camera, root = workspace.CurrentCamera, rootPart()
		for part in parts do
			if not part.Parent then
				parts[part] = nil
			else
				local close = camera and (part.Position - camera.CFrame.Position).Magnitude < 7
					or root and (part.Position - root.Position).Magnitude < 2.5
				part.LocalTransparencyModifier = close and 0.75 or 0
			end
		end
	end)
end

-- P1: soften only the walls between the avatar and camera, retaining server collision.
do
	local art = garden:FindFirstChild("Art")
	local walls = art and art:FindFirstChild("Walls")
	if walls then
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances =
			Enum.RaycastFilterType.Include, { walls }
		local faded, elapsed = {}, 0
		Services.RunService.RenderStepped:Connect(function(dt)
			elapsed += dt
			if elapsed < 0.1 then
				return
			end
			elapsed = 0
			for part, alpha in faded do
				if part.Parent then
					part.LocalTransparencyModifier = alpha
				end
			end
			table.clear(faded)
			local camera, root = workspace.CurrentCamera, rootPart()
			if not camera or not root then
				return
			end
			local origin = root.Position + Vector3.yAxis * 2
			local direction = camera.CFrame.Position - origin
			for _ = 1, 4 do
				if direction.Magnitude < 0.01 then
					break
				end
				local hit = workspace:Raycast(origin, direction, params)
				if not hit then
					break
				end
				if faded[hit.Instance] == nil then
					faded[hit.Instance] = hit.Instance.LocalTransparencyModifier
				end
				hit.Instance.LocalTransparencyModifier = 0.75
				origin = hit.Position + direction.Unit * 1
				direction = camera.CFrame.Position - origin
			end
		end)
	end
end
