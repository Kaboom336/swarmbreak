-- Client-side feel for Grow the Pumpkin: carry pose, cauldron dunks, slams on the pyramid,
-- tier and giant growth, the awaken reveal, gold rain, the shop, the guide and the HUD.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("GiantConfig"))
local remotes = ReplicatedStorage:WaitForChild("GiantRemotes")
local player = Players.LocalPlayer

local garden = workspace:WaitForChild("Garden")
local pyramid = garden:WaitForChild("Pyramid")
local socketFolder = pyramid:WaitForChild("Sockets")
local fields = garden:WaitForChild("Fields")
local gates = garden:WaitForChild("Gates")
local giant = garden:WaitForChild("Giant") :: BasePart
local giantPlain = garden:WaitForChild("GiantPlain") :: BasePart

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local giantBottom = giant.Position.Y - giant.Size.Y / 2
local giantCenter = Vector3.new(giant.Position.X, 0, giant.Position.Z)
local giantRotation = giant.CFrame - giant.CFrame.Position
local giantLight = giant:FindFirstChildWhichIsA("PointLight", true)

-- Small helpers -----------------------------------------------------------------------------

local function play(id: number, pitch: number?, volume: number?)
	if not id or id == 0 then
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

local function floatText(at: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 48)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 140
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
	local info = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(
		anchor,
		TweenInfo.new(1.4, Enum.EasingStyle.Quad),
		{ CFrame = anchor.CFrame + Vector3.new(0, 6, 0) }
	):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	task.delay(1.5, function()
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

-- Carry pose: both arms raised while holding a pumpkin overhead.
RunService.Stepped:Connect(function()
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if character and (other:GetAttribute("Carrying") or 0) > 0 then
			for _, name in { "RightShoulder", "LeftShoulder", "Right Shoulder", "Left Shoulder" } do
				local joint = character:FindFirstChild(name, true)
				if joint and joint:IsA("Motor6D") then
					local side = string.find(name, "Right") and 1 or -1
					joint.Transform = CFrame.Angles(math.rad(165), 0, math.rad(-12 * side))
				end
			end
		end
	end
end)

-- Screen GUI ----------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "GiantHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function stroke(parent: Instance, thickness: number)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.fromRGB(20, 10, 30)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
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

local function banner(text: string, sub: string?, seconds: number)
	local title = textLabel(gui, text, Color3.fromRGB(255, 214, 80))
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.26)
	title.Size = UDim2.fromScale(0.7, 0)
	title:FindFirstChildOfClass("UIStroke").Thickness = 4
	TweenService:Create(
		title,
		TweenInfo.new(0.35, Enum.EasingStyle.Back),
		{ Size = UDim2.fromScale(0.7, 0.11) }
	):Play()
	local subLabel
	if sub then
		subLabel = textLabel(gui, sub, Color3.fromRGB(255, 255, 255))
		subLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		subLabel.Position = UDim2.fromScale(0.5, 0.36)
		subLabel.Size = UDim2.fromScale(0.55, 0.055)
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
hintLabel.Position = UDim2.new(0.5, 0, 1, -96)
hintLabel.Size = UDim2.fromOffset(620, 34)
hintLabel.Visible = false
local hintToken = 0
local function hint(text: string)
	hintToken += 1
	local token = hintToken
	hintLabel.Text = text
	hintLabel.Visible = true
	task.delay(3, function()
		if token == hintToken then
			hintLabel.Visible = false
		end
	end)
end
remotes:WaitForChild("Hint").OnClientEvent:Connect(hint)

-- Prompts: Quick Hands speeds lift/slam; slam spots show only on the active tier with a magic pumpkin.

ProximityPromptService.PromptShown:Connect(function(prompt)
	local base = prompt:GetAttribute("BaseHold")
	if base == nil then
		base = prompt.HoldDuration
		prompt:SetAttribute("BaseHold", base)
	end
	if prompt.ActionText == "Lift" or prompt.ActionText == "Slam" then
		local level = player:GetAttribute("Up_QuickHands") or 0
		prompt.HoldDuration = base * (1 - 0.25 * level)
	end
end)

local function refreshSockets()
	local magic = player:GetAttribute("CarryMagic") == true
	for _, socket in socketFolder:GetChildren() do
		local active = socket:GetAttribute("Active") == true
		local prompt = socket:FindFirstChildOfClass("ProximityPrompt")
		if prompt and prompt.Enabled ~= (active and magic) then
			prompt.Enabled = active and magic
		end
		local ring = socket:FindFirstChild("Ring") :: BasePart?
		if ring then
			ring.Transparency = active and (magic and 0.15 or 0.6) or 1
		end
		local ghost = socket:FindFirstChild("Ghost") :: BasePart?
		if ghost then
			ghost.Transparency = (active and not socket:FindFirstChild("Placed")) and 0.45 or 1
		end
	end
end
for _, socket in socketFolder:GetChildren() do
	socket:GetAttributeChangedSignal("Active"):Connect(refreshSockets)
	socket.ChildAdded:Connect(function(child)
		if child:IsA("ProximityPrompt") then
			child:GetPropertyChangedSignal("Enabled"):Connect(function()
				task.defer(refreshSockets)
			end)
		end
		task.defer(refreshSockets)
	end)
	socket.ChildRemoved:Connect(function()
		task.defer(refreshSockets)
	end)
end
player:GetAttributeChangedSignal("CarryMagic"):Connect(refreshSockets)
task.defer(refreshSockets)

local lastCarry = 0
player:GetAttributeChangedSignal("Carrying"):Connect(function()
	local now = player:GetAttribute("Carrying") or 0
	if now > lastCarry then
		play(Config.Sounds.Pick, 1, 0.8)
	end
	lastCarry = now
end)

-- Giant growth: one big step per finished tier. ---------------------------------------------

local function widthForStage(stage: number): number
	return Config.GiantWidths[math.clamp(stage + 1, 1, #Config.GiantWidths)]
end
local crown: Folder? = nil
local function setCrown(on: boolean, width: number)
	if crown then
		crown:Destroy()
		crown = nil
	end
	if not on then
		return
	end
	crown = Instance.new("Folder")
	crown.Name = "GiantCrown"
	crown.Parent = workspace
	local top = giantBottom + giant.Size.Y + 0.6
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local f = Instance.new("Part")
		f.Shape = Enum.PartType.Ball
		f.Material = Enum.Material.Neon
		f.Color = Color3.fromRGB(255, 190, 80)
		f.Size = Vector3.new(1.6, 2.4, 1.6)
		f.Anchored = true
		f.CanCollide = false
		f.CastShadow = false
		f.CFrame = CFrame.new(
			giantCenter
				+ Vector3.new(math.cos(a) * width * 0.28, top - 2, math.sin(a) * width * 0.28)
		)
		f.Parent = crown
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 170, 70)
		l.Range = 10
		l.Brightness = 1
		l.Parent = f
	end
end

local function applySize(part: BasePart, width: number)
	part.Size *= width / part.Size.X
	part.CFrame = CFrame.new(giantCenter + Vector3.new(0, giantBottom + part.Size.Y / 2, 0))
		* giantRotation
end

local currentStage = -1
local function showStage(stage: number, animate: boolean)
	local width = widthForStage(stage)
	if animate then
		local fromWidth = giant.Size.X
		local value = Instance.new("NumberValue")
		value.Value = fromWidth
		value.Changed:Connect(function(w)
			applySize(giant, w)
			applySize(giantPlain, w)
		end)
		local squash = TweenService:Create(
			value,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad),
			{ Value = fromWidth * 0.92 }
		)
		squash:Play()
		squash.Completed:Wait()
		local grow = TweenService:Create(
			value,
			TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Value = width }
		)
		grow:Play()
		grow.Completed:Wait()
		value:Destroy()
		burst(giant.Position, Color3.fromRGB(255, 200, 90), 50, 34, SPARKLE, 1.6)
		play(Config.Sounds.Swell, 0.8, 1)
	else
		applySize(giant, width)
		applySize(giantPlain, width)
	end
	if giantLight then
		giantLight.Range = 14 + width
		giantLight.Brightness = stage >= 2 and 3 or 1.4
	end
	local outline = giant:FindFirstChildOfClass("Highlight")
	if outline then
		outline.Enabled = stage >= 2
	end
	setCrown(stage >= 3, width)
	currentStage = stage
end
local function onStageChanged(animate: boolean)
	local stage = pyramid:GetAttribute("Stage") or 0
	if stage ~= currentStage then
		task.spawn(showStage, stage, animate and stage > currentStage)
	end
end
pyramid:GetAttributeChangedSignal("Stage"):Connect(function()
	onStageChanged(true)
end)
onStageChanged(false)

-- Placed jacks glow, including ones placed before you joined.
local function lightJack(jack: Instance)
	if jack:IsA("BasePart") and jack.Name == "Placed" and not jack:FindFirstChild("Face") then
		local face = Instance.new("PointLight")
		face.Name = "Face"
		face.Color = Color3.fromRGB(255, 150, 50)
		face.Range = 10
		face.Brightness = 1.6
		face.Parent = jack
	end
end
for _, socket in socketFolder:GetChildren() do
	local existing = socket:FindFirstChild("Placed")
	if existing then
		lightJack(existing)
	end
	socket.ChildAdded:Connect(lightJack)
end

-- Cauldron dunk ---------------------------------------------------------------------------------

remotes
	:WaitForChild("Dunked").OnClientEvent
	:Connect(function(who: Player, at: Vector3, xp: number, levelUp: boolean)
		burst(at + Vector3.new(0, 6, 0), Color3.fromRGB(140, 255, 100), 30, 22, SPARKLE, 1.2)
		burst(at + Vector3.new(0, 4, 0), Color3.fromRGB(90, 200, 70), 14, 12)
		if who == player then
			local root = player.Character
				and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			floatText(
				(root and root.Position or at) + Vector3.new(0, 9, 0),
				"MAGIC! +" .. xp .. " STRENGTH",
				Color3.fromRGB(150, 255, 110)
			)
			play(Config.Sounds.Swell, 1.4, 0.7)
			if levelUp then
				if root then
					burst(root.Position, Color3.fromRGB(255, 150, 40), 50, 26, SPARKLE, 1.6)
					burst(root.Position, Color3.fromRGB(255, 90, 30), 18, 12)
				end
				banner(
					"STRENGTH LEVEL UP!",
					"You are now Strength " .. (player:GetAttribute("Level") or 0),
					2.4
				)
				play(Config.Sounds.Swell, 1.2, 1)
			end
		end
	end)

-- Slam ------------------------------------------------------------------------------------------

local function shockwave(at: Vector3, radius: number)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 170, 60)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(at + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService
		:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.2, radius * 2, radius * 2),
			Transparency = 1,
		})
		:Play()
	task.delay(0.5, function()
		ring:Destroy()
	end)
end

remotes
	:WaitForChild("Slammed").OnClientEvent
	:Connect(function(who: Player, socket: BasePart, from: Vector3, lb: number, gold: number)
		if not socket then
			return
		end
		local target = socket.Position
		local template = ReplicatedStorage:FindFirstChild("FeedVisual")
		if template then
			local visual = template:Clone() :: BasePart
			visual.Anchored = true
			visual.CanCollide = false
			visual.CFrame = CFrame.new(from)
			visual.Parent = workspace
			local slamDown = TweenService:Create(
				visual,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					CFrame = CFrame.new(target + Vector3.new(0, 1.5, 0)),
				}
			)
			slamDown:Play()
			slamDown.Completed:Wait()
			visual:Destroy()
		end
		shockwave(target, 6 + math.min(lb / 20, 10))
		burst(target + Vector3.new(0, 1, 0), Color3.fromRGB(255, 150, 40), 16, 20, SPARKLE, 0.9)
		burst(target, Color3.fromRGB(150, 120, 100), 10, 12)
		play(Config.Sounds.Slam, 0.85 + math.random() * 0.15, 1)
		floatText(target + Vector3.new(0, 5, 0), "+" .. lb .. " lb", Color3.fromRGB(255, 255, 255))
		if who == player then
			floatText(
				target + Vector3.new(0, 8, 0),
				"+" .. gold .. " GOLD",
				Color3.fromRGB(255, 214, 80)
			)
			play(Config.Sounds.Coin, 1.05 + math.random() * 0.1, 0.6)
			task.spawn(shake, 0.6 + math.min(lb / 100, 1.2), 8)
		end
	end)

-- Tier complete and awakening -------------------------------------------------------------------

local awakeningActive = false
local TIER_TEXT = { "The giant gets a face!", "The giant lights up!", "The giant wears a crown!" }
remotes:WaitForChild("TierDone").OnClientEvent:Connect(function(tier: number)
	banner("TIER " .. tier .. " COMPLETE!", TIER_TEXT[tier], 2.5)
	local camera = workspace.CurrentCamera
	if camera.CameraType ~= Enum.CameraType.Custom then
		return
	end
	local saved = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local focus = giantCenter + Vector3.new(0, giantBottom + 10, 0)
	local front = giantCenter + Vector3.new(0, giantBottom + 4, 80)
	TweenService:Create(
		camera,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine),
		{ CFrame = CFrame.lookAt(front, focus) }
	):Play()
	task.wait(1.9)
	if awakeningActive then
		return -- the awakening owns the camera now
	end
	TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Sine), { CFrame = saved })
		:Play()
	task.wait(0.4)
	camera.CameraType = Enum.CameraType.Custom
end)

remotes
	:WaitForChild("Awaken").OnClientEvent
	:Connect(function(_paid: { Player }, payouts: { [string]: number }?)
		awakeningActive = true
		local camera = workspace.CurrentCamera
		local focus = giantCenter + Vector3.new(0, giantBottom + giant.Size.Y * 0.5, 0)
		local front = giantCenter + Vector3.new(0, giantBottom + 8, 85)
		camera.CameraType = Enum.CameraType.Scriptable
		TweenService
			:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				CFrame = CFrame.lookAt(front, focus),
			})
			:Play()
		local base = giant.CFrame
		for i = 1, 16 do
			giant.CFrame = base
				* CFrame.new((math.random() - 0.5) * 0.08 * i, 0, (math.random() - 0.5) * 0.08 * i)
			if giantLight then
				giantLight.Brightness = 2 + i * 0.3
			end
			task.wait(0.05)
		end
		play(Config.Sounds.Swell, 0.6, 1)
		TweenService
			:Create(giant, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = base * CFrame.new(0, 10, 0) * CFrame.Angles(0, math.pi, 0),
			})
			:Play()
		task.wait(1)
		local goldTemplate = ReplicatedStorage:FindFirstChild("GiantGold")
		local form = (goldTemplate and goldTemplate:Clone() or giant:Clone()) :: BasePart
		form.Anchored = true
		form.CanCollide = false
		form.Size *= giant.Size.X / form.Size.X
		form.CFrame = giant.CFrame * CFrame.Angles(0, math.pi, 0)
		form.Parent = workspace
		local formLight = Instance.new("PointLight")
		formLight.Color = Color3.fromRGB(255, 220, 140)
		formLight.Range = 40
		formLight.Brightness = 2
		formLight.Parent = form
		giant.LocalTransparencyModifier = 1
		burst(form.Position, Color3.fromRGB(255, 240, 180), 80, 50, SPARKLE, 2)
		play(Config.Sounds.Coin, 0.8, 1)
		local bonus = payouts and payouts[tostring(player.UserId)]
		banner(
			"THE GIANT AWAKENS!",
			bonus and ("+" .. bonus .. " GOLD for helping!") or "Help build the next one!",
			Config.AwakenSeconds - 3
		)
		TweenService
			:Create(form, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				CFrame = form.CFrame * CFrame.Angles(0, math.pi * 2 - 0.01, 0),
			})
			:Play()
		task.wait(Config.AwakenSeconds - 3)
		burst(form.Position, Color3.fromRGB(255, 220, 140), 50, 34, SPARKLE, 1.4)
		form:Destroy()
		giant.LocalTransparencyModifier = 0
		giant.CFrame = base
		camera.CameraType = Enum.CameraType.Custom
		awakeningActive = false
		banner("GOLDEN PUMPKINS!", "Grab them before they vanish!", 3)
	end)

remotes:WaitForChild("Combo").OnClientEvent:Connect(function(first: Player, second: Player)
	for _, who in { first, second } do
		local root = who.Character and who.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			floatText(
				root.Position + Vector3.new(0, 7, 0),
				"TEAM COMBO! +" .. Config.ComboGold,
				Color3.fromRGB(110, 210, 255)
			)
		end
	end
	if first == player or second == player then
		play(Config.Sounds.Coin, 1.25, 0.8)
	end
end)

remotes:WaitForChild("RainCollected").OnClientEvent:Connect(function(collector: Player, at: Vector3)
	burst(at, Color3.fromRGB(255, 210, 80), 14, 14, SPARKLE, 0.8)
	if collector == player then
		floatText(at + Vector3.new(0, 3, 0), "GOLD!", Color3.fromRGB(255, 214, 80))
		play(Config.Sounds.Coin, 1.1 + math.random() * 0.2, 0.6)
	end
end)

if Config.Sounds.Music and Config.Sounds.Music ~= 0 then
	local music = Instance.new("Sound")
	music.Name = "Music"
	music.SoundId = "rbxassetid://" .. Config.Sounds.Music
	music.Looped = true
	music.Volume = 0.25
	music.Parent = SoundService
	music:Play()
end

-- HUD: goal bar on top, big stats on the left. ----------------------------------------------

local goalFrame = Instance.new("Frame")
goalFrame.AnchorPoint = Vector2.new(0.5, 0)
goalFrame.Position = UDim2.new(0.5, 0, 0, 48)
goalFrame.Size = UDim2.fromOffset(460, 46)
goalFrame.BackgroundColor3 = Color3.fromRGB(34, 22, 48)
goalFrame.BackgroundTransparency = 0.1
goalFrame.Parent = gui
Instance.new("UICorner", goalFrame).CornerRadius = UDim.new(1, 0)
stroke(goalFrame, 3)
local goalFill = Instance.new("Frame")
goalFill.Size = UDim2.fromScale(0, 1)
goalFill.BackgroundColor3 = Color3.fromRGB(255, 150, 40)
goalFill.Parent = goalFrame
Instance.new("UICorner", goalFill).CornerRadius = UDim.new(1, 0)
local goalText = textLabel(goalFrame, "", Color3.fromRGB(255, 255, 255))
goalText.Size = UDim2.fromScale(1, 1)
goalText.ZIndex = 2
local goalPad = Instance.new("UIPadding")
goalPad.PaddingTop = UDim.new(0, 7)
goalPad.PaddingBottom = UDim.new(0, 7)
goalPad.Parent = goalText
local function refreshGoal()
	local tier = pyramid:GetAttribute("ActiveTier") or 1
	local lb = pyramid:GetAttribute("TierLb") or 0
	local quota = math.max(pyramid:GetAttribute("TierQuota") or 1, 1)
	if tier == 0 then
		goalText.Text = "🎃 THE GIANT AWAKENS!"
		goalFill.Size = UDim2.fromScale(1, 1)
		return
	end
	goalText.Text = string.format(
		"🎃 GIANT #%d · TIER %d   %d / %d lb",
		pyramid:GetAttribute("GiantNumber") or 1,
		tier,
		lb,
		quota
	)
	TweenService:Create(goalFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(math.clamp(lb / quota, 0.04, 1), 1),
	}):Play()
end
for _, attr in { "ActiveTier", "TierLb", "TierQuota", "GiantNumber" } do
	pyramid:GetAttributeChangedSignal(attr):Connect(refreshGoal)
end
refreshGoal()

local column = Instance.new("Frame")
column.BackgroundTransparency = 1
column.Position = UDim2.new(0, 14, 0.32, 0)
column.Size = UDim2.fromOffset(220, 240)
column.Parent = gui
local columnLayout = Instance.new("UIListLayout")
columnLayout.Padding = UDim.new(0, 8)
columnLayout.Parent = column
local function statRow(icon: string, color: Color3): (TextLabel, TextLabel)
	local row = Instance.new("Frame")
	row.Size = UDim2.fromOffset(220, 64)
	row.BackgroundColor3 = Color3.fromRGB(34, 22, 48)
	row.BackgroundTransparency = 0.2
	row.Parent = column
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
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
local goldBig, goldSmall = statRow("💰", Color3.fromRGB(255, 212, 60))
local strengthBig, strengthSmall = statRow("💪", Color3.fromRGB(255, 160, 80))
local giantsBig, giantsSmall = statRow("🎃", Color3.fromRGB(255, 140, 40))

local goldValue = player:WaitForChild("leaderstats"):WaitForChild("Gold") :: IntValue
local function refreshGold(pop: boolean)
	goldBig.Text = tostring(goldValue.Value)
	goldSmall.Text = "Gold"
	if pop then
		goldBig.TextColor3 = Color3.fromRGB(255, 255, 200)
		TweenService
			:Create(goldBig, TweenInfo.new(0.4), { TextColor3 = Color3.fromRGB(255, 212, 60) })
			:Play()
	end
end
local function heaviestLift(level: number): string
	local best = Config.Sizes[1].name
	for _, size in Config.Sizes do
		if level >= size.level then
			best = size.name
		end
	end
	return best
end
local function refreshStrength()
	local level = player:GetAttribute("Level") or 0
	strengthBig.Text = "Strength " .. level
	local nextSize
	for _, size in Config.Sizes do
		if size.level > level then
			nextSize = size
			break
		end
	end
	if nextSize then
		strengthSmall.Text = string.format(
			"Lifts %s · %s at %d",
			heaviestLift(level),
			nextSize.name,
			nextSize.level
		)
	else
		strengthSmall.Text = "Lifts anything!"
	end
end
local function refreshGiants()
	giantsBig.Text = tostring((pyramid:GetAttribute("GiantNumber") or 1) - 1)
	giantsSmall.Text = "Giants awakened"
end
goldValue.Changed:Connect(function()
	refreshGold(true)
end)
player:GetAttributeChangedSignal("Level"):Connect(refreshStrength)
pyramid:GetAttributeChangedSignal("GiantNumber"):Connect(refreshGiants)
refreshGold(false)
refreshStrength()
refreshGiants()

-- Shop panel ------------------------------------------------------------------------------------

local buy = remotes:WaitForChild("Buy") :: RemoteFunction
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.55)
panel.Size = UDim2.fromOffset(620, 380)
panel.BackgroundColor3 = Color3.fromRGB(36, 24, 50)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
stroke(panel, 4)
local panelTitle = textLabel(panel, "UPGRADES", Color3.fromRGB(255, 255, 255))
panelTitle.Position = UDim2.fromOffset(20, 10)
panelTitle.Size = UDim2.new(1, -100, 0, 50)
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -12, 0, 12)
close.Size = UDim2.fromOffset(48, 48)
close.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
close.Font = Enum.Font.FredokaOne
close.TextScaled = true
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Text = "X"
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 10)
stroke(close, 2.5)
close.Activated:Connect(function()
	panel.Visible = false
end)
remotes:WaitForChild("OpenShop").OnClientEvent:Connect(function()
	panel.Visible = not panel.Visible
end)

local cards = Instance.new("Frame")
cards.BackgroundTransparency = 1
cards.Position = UDim2.fromOffset(16, 72)
cards.Size = UDim2.new(1, -32, 1, -88)
cards.Parent = panel
local cardsLayout = Instance.new("UIListLayout")
cardsLayout.Padding = UDim.new(0, 10)
cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
cardsLayout.Parent = cards

local ICONS = { Grip = "💪", GreenThumb = "🌱", QuickHands = "✋" }
local ORDER = { "Grip", "GreenThumb", "QuickHands" }
local cardParts = {}
local function refreshCards()
	for id, parts in cardParts do
		local info = Config.Upgrades[id]
		local level = player:GetAttribute("Up_" .. id) or 0
		local cost = info.base * (level + 1)
		parts.level.Text = string.rep("●", level) .. string.rep("○", info.max - level)
		if level >= info.max then
			parts.button.Text = "MAX"
			parts.button.BackgroundColor3 = Color3.fromRGB(110, 100, 120)
		else
			parts.button.Text = cost .. " 💰"
			parts.button.BackgroundColor3 = goldValue.Value >= cost and Color3.fromRGB(60, 190, 70)
				or Color3.fromRGB(120, 110, 90)
		end
	end
end
for i, id in ORDER do
	local info = Config.Upgrades[id]
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 86)
	card.LayoutOrder = i
	card.BackgroundColor3 = Color3.fromRGB(226, 196, 150)
	card.Parent = cards
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	stroke(card, 2.5)
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(8, 8)
	icon.Size = UDim2.fromOffset(70, 70)
	icon.TextScaled = true
	icon.Text = ICONS[id] or "⭐"
	icon.Parent = card
	local name = textLabel(card, info.title, Color3.fromRGB(255, 255, 255))
	name.Position = UDim2.fromOffset(86, 6)
	name.Size = UDim2.new(1, -260, 0, 34)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local effect = textLabel(card, info.text, Color3.fromRGB(70, 44, 30), Enum.Font.GothamBold)
	effect:FindFirstChildOfClass("UIStroke"):Destroy()
	effect.Position = UDim2.fromOffset(86, 42)
	effect.Size = UDim2.new(1, -260, 0, 22)
	effect.TextXAlignment = Enum.TextXAlignment.Left
	local level = textLabel(card, "", Color3.fromRGB(255, 170, 40))
	level.Position = UDim2.fromOffset(86, 62)
	level.Size = UDim2.new(1, -260, 0, 20)
	level.TextXAlignment = Enum.TextXAlignment.Left
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -12, 0.5, 0)
	button.Size = UDim2.fromOffset(150, 56)
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = card
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
	stroke(button, 2.5)
	local buttonPad = Instance.new("UIPadding")
	buttonPad.PaddingTop = UDim.new(0, 8)
	buttonPad.PaddingBottom = UDim.new(0, 8)
	buttonPad.Parent = button
	cardParts[id] = { button = button, level = level }
	button.Activated:Connect(function()
		local ok, message = buy:InvokeServer(id)
		if ok then
			play(Config.Sounds.Coin, 0.9, 0.8)
			banner(info.title .. "!", info.text, 1.6)
		else
			button.Text = message
			task.delay(1, refreshCards)
		end
		refreshCards()
	end)
	player:GetAttributeChangedSignal("Up_" .. id):Connect(refreshCards)
end
goldValue.Changed:Connect(refreshCards)
refreshCards()

-- First-session guide: lift -> dunk -> slam, with glowing ground arrows and a Skip button. ------

local function nearest(points: { Vector3 }, from: Vector3): Vector3
	local best, bestDist = points[1], math.huge
	for _, p in points do
		local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
		if d < bestDist then
			best, bestDist = p, d
		end
	end
	return best
end
local fieldCenters, gateCenters = {}, {}
for _, field in fields:GetChildren() do
	local sum, n = Vector3.zero, 0
	for _, plot in field:GetChildren() do
		if plot.Name == "Plot" then
			sum += plot.Position
			n += 1
		end
	end
	if n > 0 then
		table.insert(fieldCenters, sum / n)
	end
end
for _, gate in gates:GetChildren() do
	local zone = gate:FindFirstChild("Zone")
	if zone then
		table.insert(gateCenters, zone.Position)
	end
end

local arrows: Folder? = nil
local function drawArrows(from: Vector3, to: Vector3)
	if arrows then
		arrows:Destroy()
	end
	arrows = Instance.new("Folder")
	arrows.Name = "GuideArrows"
	arrows.Parent = workspace
	local flatFrom = Vector3.new(from.X, 0, from.Z)
	local flatTo = Vector3.new(to.X, 0, to.Z)
	local dist = (flatTo - flatFrom).Magnitude
	if dist < 1 then
		return
	end
	local count = math.max(2, math.floor(dist / 8))
	for i = 1, count do
		local p = flatFrom:Lerp(flatTo, (i - 0.5) / count) + Vector3.new(0, 0.6, 0)
		local arrow = Instance.new("WedgePart")
		arrow.Anchored = true
		arrow.CanCollide = false
		arrow.CanQuery = false
		arrow.CastShadow = false
		arrow.Material = Enum.Material.Neon
		arrow.Color = Color3.fromRGB(110, 255, 90)
		arrow.Size = Vector3.new(3.4, 0.3, 2.6)
		arrow.CFrame = CFrame.lookAt(p, p + (flatTo - flatFrom).Unit) * CFrame.Angles(0, math.pi, 0)
		arrow.Transparency = 0.2
		arrow.Parent = arrows
		TweenService:Create(
			arrow,
			TweenInfo.new(
				0.6,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true,
				i * 0.08
			),
			{
				Transparency = 0.75,
			}
		):Play()
	end
end

local guide = Instance.new("Frame")
guide.AnchorPoint = Vector2.new(0.5, 1)
guide.Position = UDim2.new(0.5, 0, 1, -24)
guide.Size = UDim2.fromOffset(600, 54)
guide.BackgroundColor3 = Color3.fromRGB(34, 22, 48)
guide.BackgroundTransparency = 0.1
guide.Parent = gui
Instance.new("UICorner", guide).CornerRadius = UDim.new(1, 0)
stroke(guide, 3)
local guideText = textLabel(guide, "", Color3.fromRGB(150, 255, 110))
guideText.Position = UDim2.fromOffset(24, 8)
guideText.Size = UDim2.new(1, -140, 1, -16)
local skip = Instance.new("TextButton")
skip.AnchorPoint = Vector2.new(1, 0.5)
skip.Position = UDim2.new(1, -10, 0.5, 0)
skip.Size = UDim2.fromOffset(96, 38)
skip.BackgroundColor3 = Color3.fromRGB(90, 80, 110)
skip.Font = Enum.Font.FredokaOne
skip.TextScaled = true
skip.TextColor3 = Color3.fromRGB(255, 255, 255)
skip.Text = "Skip"
skip.Parent = guide
Instance.new("UICorner", skip).CornerRadius = UDim.new(1, 0)

local step = 1
local function rootPosition(): Vector3
	local root = player.Character
		and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position or Vector3.new(0, 0, 104)
end
local function showStep()
	local here = rootPosition()
	if step == 1 then
		guideText.Text = "1. Lift a pumpkin in a field (E)"
		drawArrows(here, nearest(fieldCenters, here))
	elseif step == 2 then
		guideText.Text = "2. Carry it through a Magic Cauldron"
		drawArrows(here, nearest(gateCenters, here))
	elseif step == 3 then
		guideText.Text = "3. Climb the pyramid and SLAM it on a glowing spot"
		local gate = nearest(gateCenters, here)
		drawArrows(here, gate:Lerp(giantCenter, 0.3))
	else
		guide.Visible = false
		if arrows then
			arrows:Destroy()
			arrows = nil
		end
	end
end
skip.Activated:Connect(function()
	step = 4
	showStep()
end)
player:GetAttributeChangedSignal("Carrying"):Connect(function()
	if step == 1 and (player:GetAttribute("Carrying") or 0) > 0 then
		step = 2
		showStep()
	end
end)
player:GetAttributeChangedSignal("CarryMagic"):Connect(function()
	if step == 2 and player:GetAttribute("CarryMagic") then
		step = 3
		showStep()
	end
end)
local slamsStat = player:WaitForChild("leaderstats"):WaitForChild("Slams") :: IntValue
slamsStat.Changed:Connect(function()
	if step <= 3 then
		step = 4
		showStep()
		banner("NICE SLAM!", "Fill the tier to grow the Giant", 2.2)
	end
end)
task.defer(showStep)
