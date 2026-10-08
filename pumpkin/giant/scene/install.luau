game.ReplicatedStorage.GiantConfig.Source = [==[-- Tuning for the Feed the Giant slice. All values are first guesses to judge on screen.
return {
	-- Patch growth: seconds spent at each stage before the next one.
	StageSeconds = { 4, 6 },
	-- Model scale per stage: sprout, growing, ripe.
	StageScale = { 0.9, 1.6, 2.4 },

	CarryWalkSpeed = 11,
	NormalWalkSpeed = 16,

	-- Hold time on a socket to smash the carried pumpkin in.
	SmashHold = 0.8,

	-- The giant swells by GiantStep of its base size per filled socket; a full ring awakens it.
	GiantStep = 0.05,
	GoldPerFeed = 5,
	AwakenBonus = 25,
	AwakenSeconds = 7,

	-- Free Creator Store audio (no scripts possible in audio assets). Not auditioned yet; 0 means silent.
	Sounds = {
		Pick = 9113730784, -- Catch Ball 7 (ProSoundEffects)
		Slam = 9116488438, -- Meaty Thud 2 (ProSoundEffects)
		Swell = 99963459517796, -- Magic Summon SFX
		Coin = 1169806635, -- Coin Collect 2 (Everyedit, free to reuse)
	},
}
]==]
game.ServerScriptService.Feed.Source = [==[-- Feed the Giant: pumpkins grow on plots, players carry ripe ones to the altar and
-- smash them into a socket around the giant. The carved pumpkin stays in its socket,
-- its seeds pour into the giant, and a full ring awakens the giant. Clients play the motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("GiantConfig"))

local garden = workspace:WaitForChild("Garden")
local patch = garden:WaitForChild("Patch")
local giant = garden:WaitForChild("Giant")
local socketFolder = garden:WaitForChild("Sockets")
local templates = ServerStorage:WaitForChild("KitTemplates")

local dropped = Instance.new("Folder")
dropped.Name = "Dropped"
dropped.Parent = garden

local remotes = Instance.new("Folder")
remotes.Name = "GiantRemotes"
remotes.Parent = ReplicatedStorage
local placedEvent = Instance.new("RemoteEvent")
placedEvent.Name = "Placed"
placedEvent.Parent = remotes
local awakenEvent = Instance.new("RemoteEvent")
awakenEvent.Name = "Awaken"
awakenEvent.Parent = remotes

giant:SetAttribute("Level", 0)

local carrying: { [Player]: BasePart } = {}
local helpers: { [Player]: number } = {}
local awakening = false

local function addGold(player: Player, amount: number)
	local stats = player:FindFirstChild("leaderstats")
	local gold = stats and stats:FindFirstChild("Gold") :: IntValue?
	if gold then
		gold.Value += amount
	end
end

local function setupLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Parent = stats
	stats.Parent = player
end

local function setWalkSpeed(player: Player, speed: number)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

-- Give a resting pumpkin a "Pick up" prompt; picking it up welds it overhead.
local function makePickable(pumpkin: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = "Ripe pumpkin"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pumpkin

	prompt.Triggered:Connect(function(player)
		if pumpkin:GetAttribute("Taken") or carrying[player] then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return
		end
		pumpkin:SetAttribute("Taken", true)
		prompt:Destroy()
		pumpkin.Anchored = false
		pumpkin.Massless = true
		pumpkin.CFrame = root.CFrame * CFrame.new(0, 2.6 + pumpkin.Size.Y / 2, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = pumpkin
		weld.Parent = pumpkin
		pumpkin:SetNetworkOwner(player)
		humanoid.WalkSpeed = Config.CarryWalkSpeed
		carrying[player] = pumpkin
		player:SetAttribute("Carrying", true)
	end)
end

local function growPlot(plot: BasePart)
	-- The first crop starts ripe so a new player can act within seconds.
	local firstRipe = plot:GetAttribute("StartRipe") == true
	while plot.Parent do
		local pumpkin = templates.pumpkin_orange:Clone()
		local baseSize = pumpkin.Size
		pumpkin.Anchored = true
		pumpkin.CanCollide = false
		pumpkin.Parent = patch
		local function place(stage: number)
			pumpkin.Size = baseSize * Config.StageScale[stage]
			pumpkin.CFrame = plot.CFrame * CFrame.new(0, pumpkin.Size.Y / 2, 0)
		end
		if not firstRipe then
			for stage = 1, #Config.StageSeconds do
				place(stage)
				task.wait(Config.StageSeconds[stage])
			end
		end
		firstRipe = false
		place(#Config.StageScale)
		makePickable(pumpkin)

		while not pumpkin:GetAttribute("Taken") and pumpkin.Parent do
			task.wait(0.5)
		end
		task.wait(1.5)
	end
end

local function clearSockets()
	for _, socket in socketFolder:GetChildren() do
		local placed = socket:FindFirstChild("Placed")
		if placed then
			placed:Destroy()
		end
		socket:SetAttribute("Filled", false)
	end
end

local function awaken()
	awakening = true
	local paid = {}
	for player in helpers do
		if player.Parent then
			addGold(player, Config.AwakenBonus)
			table.insert(paid, player)
		end
	end
	awakenEvent:FireAllClients(paid)
	task.wait(Config.AwakenSeconds)
	helpers = {}
	clearSockets()
	giant:SetAttribute("Level", 0)
	awakening = false
end

local function smashInto(socket: BasePart, player: Player)
	local pumpkin = carrying[player]
	if not pumpkin or awakening or socket:GetAttribute("Filled") then
		return
	end
	carrying[player] = nil
	player:SetAttribute("Carrying", false)
	socket:SetAttribute("Filled", true)
	setWalkSpeed(player, Config.NormalWalkSpeed)

	-- Glide the carried pumpkin down into the socket, facing out from the giant.
	local from = pumpkin.CFrame
	local size = pumpkin.Size
	pumpkin:Destroy()
	local outward = (socket.Position - giant.Position) * Vector3.new(1, 0, 1)
	local jack = templates.Jack:Clone()
	jack.Name = "Placed"
	jack.Anchored = true
	jack.CanCollide = false
	jack.Size = jack.Size * (size.X / jack.Size.X)
	local rest = CFrame.lookAt(socket.Position, socket.Position + outward) * CFrame.new(0, jack.Size.Y / 2, 0)
	jack.CFrame = from
	jack.Parent = socket
	TweenService:Create(jack, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = rest }):Play()
	placedEvent:FireAllClients(player, socket, from, rest, size)

	helpers[player] = (helpers[player] or 0) + 1
	addGold(player, Config.GoldPerFeed)
	task.delay(0.9, function()
		local level = math.min((giant:GetAttribute("Level") :: number) + 1, #socketFolder:GetChildren())
		giant:SetAttribute("Level", level)
		if level >= #socketFolder:GetChildren() and not awakening then
			task.wait(0.8)
			awaken()
		end
	end)
end

-- A carried pumpkin falls to the ground where its carrier stopped, ready to pick up again.
local function dropCarry(player: Player)
	local pumpkin = carrying[player]
	carrying[player] = nil
	player:SetAttribute("Carrying", false)
	if not pumpkin or not pumpkin.Parent then
		return
	end
	local at = pumpkin.Position
	for _, d in pumpkin:GetChildren() do
		if d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	pumpkin.Anchored = true
	pumpkin.CFrame = CFrame.new(at.X, pumpkin.Size.Y / 2, at.Z)
	pumpkin:SetAttribute("Taken", nil)
	pumpkin.Parent = dropped
	makePickable(pumpkin)
end

local function watchCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		dropCarry(player)
	end)
end

Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	player.CharacterRemoving:Connect(function()
		dropCarry(player)
	end)
end)
for _, player in Players:GetPlayers() do
	setupLeaderstats(player)
	if player.Character then
		watchCharacter(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	player.CharacterRemoving:Connect(function()
		dropCarry(player)
	end)
end
Players.PlayerRemoving:Connect(function(player)
	dropCarry(player)
	helpers[player] = nil
end)

for _, socket in socketFolder:GetChildren() do
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Smash in"
	prompt.ObjectText = "Empty socket"
	prompt.HoldDuration = Config.SmashHold
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	-- The server never toggles this again; each client hides it unless its player is carrying.
	prompt.Parent = socket
	prompt.Triggered:Connect(function(player)
		smashInto(socket, player)
	end)
end

for _, plot in patch:GetChildren() do
	if plot:IsA("BasePart") and plot.Name == "Plot" then
		task.spawn(growPlot, plot)
	end
end
]==]
game.StarterPlayer.StarterPlayerScripts.Giant.Source = [==[-- Client-side feel for Feed the Giant: carry pose, socket prompts, smash + seed pour,
-- giant swell, the awaken reveal and the gold counter.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("GiantConfig"))
local remotes = ReplicatedStorage:WaitForChild("GiantRemotes")
local player = Players.LocalPlayer

local garden = workspace:WaitForChild("Garden")
local giant = garden:WaitForChild("Giant") :: BasePart
local socketFolder = garden:WaitForChild("Sockets")
local giantBase = giant.Size
local giantBaseCFrame = giant.CFrame
local giantLight = giant:FindFirstChildWhichIsA("PointLight", true)

local function play(id: number, pitch: number?, volume: number?)
	if id == 0 then
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

local function burst(at: Vector3, color: Color3, count: number, speed: number, texture: string?, size: number?)
	local holder = Instance.new("Attachment")
	holder.WorldPosition = at
	holder.Parent = workspace.Terrain
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture or "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color)
	local s = size or 2
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s), NumberSequenceKeypoint.new(1, s * 2.5) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
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

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

-- Carry pose: both arms raised while holding a pumpkin overhead.
RunService.Stepped:Connect(function()
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if character and other:GetAttribute("Carrying") then
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

-- Socket prompts, ghost pumpkins and the ring glow only show while you carry a pumpkin.
local ghostTemplate = ReplicatedStorage:WaitForChild("GhostJack") :: BasePart
local function setGhost(socket: BasePart, show: boolean)
	local ghost = socket:FindFirstChild("Ghost")
	if show and not ghost then
		ghost = ghostTemplate:Clone()
		ghost.Name = "Ghost"
		ghost.Anchored = true
		ghost.CanCollide = false
		ghost.CanQuery = false
		ghost.Material = Enum.Material.ForceField
		ghost.Color = Color3.fromRGB(255, 170, 60)
		ghost.Transparency = 0.35
		local outward = (socket.Position - giant.Position) * Vector3.new(1, 0, 1)
		ghost.CFrame = CFrame.lookAt(socket.Position, socket.Position + outward) * CFrame.new(0, ghost.Size.Y / 2, 0)
		ghost.Parent = socket
	elseif not show and ghost then
		ghost:Destroy()
	end
end

local function refreshPrompts()
	local carrying = player:GetAttribute("Carrying") == true
	for _, socket in socketFolder:GetChildren() do
		local open = carrying and not socket:GetAttribute("Filled")
		local prompt = socket:FindFirstChildOfClass("ProximityPrompt")
		if prompt and prompt.Enabled ~= open then
			prompt.Enabled = open
		end
		local ring = socket:FindFirstChild("Ring") :: BasePart?
		if ring then
			ring.Transparency = open and 0.45 or 1
		end
		setGhost(socket, open)
	end
end

-- Placed jack-o'-lanterns light up; when a ring clears they pop.
local function lightJack(jack: Instance)
	if jack:IsA("BasePart") and not jack:FindFirstChild("Face") then
		local face = Instance.new("PointLight")
		face.Name = "Face"
		face.Color = Color3.fromRGB(255, 150, 50)
		face.Range = 10
		face.Brightness = 0
		face.Parent = jack
		TweenService:Create(face, TweenInfo.new(0.5), { Brightness = 1.8 }):Play()
	end
end

player:GetAttributeChangedSignal("Carrying"):Connect(function()
	if player:GetAttribute("Carrying") then
		play(Config.Sounds.Pick, 1, 0.8)
	end
	refreshPrompts()
end)
for _, socket in socketFolder:GetChildren() do
	socket:GetAttributeChangedSignal("Filled"):Connect(refreshPrompts)
	socket.ChildAdded:Connect(function(child)
		if child.Name == "Placed" then
			lightJack(child)
		elseif child:IsA("ProximityPrompt") then
			child:GetPropertyChangedSignal("Enabled"):Connect(function()
				task.defer(refreshPrompts)
			end)
			task.defer(refreshPrompts)
		end
	end)
	socket.ChildRemoved:Connect(function(child)
		if child.Name == "Placed" and child:IsA("BasePart") then
			burst(child.Position, Color3.fromRGB(255, 200, 90), 16, 18, SPARKLE, 1)
		end
	end)
	local existing = socket:FindFirstChild("Placed")
	if existing then
		lightJack(existing)
	end
	local prompt = socket:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
			task.defer(refreshPrompts)
		end)
	end
end
task.defer(refreshPrompts)

-- Giant swell: squash down, then spring up to the new size.
local function setGiantSize(size: Vector3)
	giant.Size = size
	giant.CFrame = giantBaseCFrame * CFrame.new(0, (size.Y - giantBase.Y) / 2, 0)
end

local currentLevel = 0
local function swellTo(level: number)
	local growing = level > currentLevel
	currentLevel = level
	local target = giantBase * (1 + Config.GiantStep * level)
	local value = Instance.new("Vector3Value")
	value.Value = giant.Size
	value.Changed:Connect(setGiantSize)
	if growing then
		local squash = Vector3.new(target.X * 1.08, target.Y * 0.86, target.Z * 1.08)
		local down = TweenService:Create(value, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = squash })
		down:Play()
		down.Completed:Wait()
		play(Config.Sounds.Swell, 1 - level * 0.03, 1)
	end
	local up = TweenService:Create(value, TweenInfo.new(growing and 0.42 or 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = target })
	up:Play()
	up.Completed:Once(function()
		value:Destroy()
	end)
	if giantLight then
		giantLight.Range = 16 + level * 2
		giantLight.Brightness = 3.5
		TweenService:Create(giantLight, TweenInfo.new(0.6), { Brightness = 1.6 + level * 0.15 }):Play()
	end
end

local startLevel = giant:GetAttribute("Level")
if typeof(startLevel) == "number" and startLevel > 0 then
	task.spawn(swellTo, startLevel)
end

giant:GetAttributeChangedSignal("Level"):Connect(function()
	local level = giant:GetAttribute("Level") :: number
	if level ~= currentLevel then
		task.spawn(swellTo, level)
	end
end)

-- Seeds pour out of the smashed pumpkin and stream into the giant's open top.
local function pourSeeds(from: Vector3, count: number)
	for i = 1, count do
		local seed = Instance.new("Part")
		seed.Shape = Enum.PartType.Ball
		seed.Material = Enum.Material.Neon
		seed.Color = Color3.fromRGB(255, 226, 120)
		seed.Size = Vector3.new(0.6, 0.6, 0.6)
		seed.Anchored = true
		seed.CanCollide = false
		seed.CastShadow = false
		seed.CFrame = CFrame.new(from)
		seed.Parent = workspace
		local top = giant.Position + Vector3.new(0, giant.Size.Y * 0.42, 0)
		local side = (math.random() - 0.5) * 6
		local peak = (from + top) / 2 + Vector3.new(side, 7 + math.random() * 3, side)
		local t = Instance.new("NumberValue")
		t.Changed:Connect(function(a)
			seed.CFrame = CFrame.new((1 - a) ^ 2 * from + 2 * (1 - a) * a * peak + a ^ 2 * top)
		end)
		local tween = TweenService:Create(t, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = 1 })
		tween:Play()
		tween.Completed:Once(function()
			seed:Destroy()
			t:Destroy()
		end)
		task.wait(0.05)
	end
end

remotes:WaitForChild("Placed").OnClientEvent:Connect(function(placer: Player, socket: BasePart, _from: CFrame, rest: CFrame, size: Vector3)
	task.wait(0.35)
	play(Config.Sounds.Slam, 0.85 + math.random() * 0.1, 1)
	burst(rest.Position, Color3.fromRGB(140, 110, 90), 14, 14)
	burst(rest.Position + Vector3.new(0, size.Y * 0.4, 0), Color3.fromRGB(255, 140, 40), 10, 20, SPARKLE, 0.8)
	if placer == player then
		local camera = workspace.CurrentCamera
		for i = 1, 5 do
			camera.CFrame *= CFrame.new((math.random() - 0.5) * 0.4, (math.random() - 0.5) * 0.4, 0)
			task.wait(0.02 + i * 0.005)
		end
		play(Config.Sounds.Coin, 1.1, 0.7)
	end
	pourSeeds(rest.Position + Vector3.new(0, size.Y * 0.6, 0), 10)
end)

-- Banner text for the awaken reveal.
local gui = Instance.new("ScreenGui")
gui.Name = "GiantHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function chunkyLabel(text: string, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.TextScaled = true
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(30, 12, 40)
	stroke.Parent = label
	return label
end

remotes:WaitForChild("Awaken").OnClientEvent:Connect(function(paid: { Player })
	local gold = ReplicatedStorage:FindFirstChild("GiantGold")
	local form = (gold and gold:Clone() or giant:Clone()) :: BasePart
	form.Anchored = true
	form.CanCollide = false
	form.Size = giant.Size
	form.CFrame = giant.CFrame
	form.Transparency = 1
	form.Parent = workspace

	-- 1. Gather: the giant shakes and glows brighter.
	for i = 1, 14 do
		giant.CFrame = giantBaseCFrame * CFrame.new(0, (giant.Size.Y - giantBase.Y) / 2, 0)
			* CFrame.new((math.random() - 0.5) * 0.4 * i / 7, 0, (math.random() - 0.5) * 0.4 * i / 7)
		if giantLight then
			giantLight.Brightness = 2 + i * 0.4
		end
		task.wait(0.05)
	end
	play(Config.Sounds.Swell, 0.6, 1)

	-- 2. Rise and spin, then a flash swaps it into its golden form.
	local rise = giant.CFrame * CFrame.new(0, 6, 0)
	TweenService:Create(giant, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = rise * CFrame.Angles(0, math.pi, 0) }):Play()
	task.wait(0.9)
	burst(giant.Position, Color3.fromRGB(255, 240, 180), 60, 40, SPARKLE, 1.6)
	burst(giant.Position, Color3.fromRGB(255, 200, 90), 30, 28, SPARKLE, 3)
	giant.Transparency = 1
	form.CFrame = giant.CFrame * CFrame.Angles(0, math.pi, 0)
	form.Transparency = 0
	local formLight = Instance.new("PointLight")
	formLight.Color = Color3.fromRGB(255, 220, 120)
	formLight.Range = 40
	formLight.Brightness = 4
	formLight.Parent = form
	play(Config.Sounds.Coin, 0.8, 1)

	local title = chunkyLabel("THE GIANT AWAKENS!", Color3.fromRGB(255, 214, 80))
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.28)
	title.Size = UDim2.fromScale(0.7, 0.12)
	title.Parent = gui
	local mine = table.find(paid, player) ~= nil
	local reward = chunkyLabel(mine and ("+" .. Config.AwakenBonus .. " GOLD for helping!") or "Help next time for gold!", Color3.fromRGB(255, 255, 255))
	reward.AnchorPoint = Vector2.new(0.5, 0.5)
	reward.Position = UDim2.fromScale(0.5, 0.38)
	reward.Size = UDim2.fromScale(0.5, 0.06)
	reward.Parent = gui

	-- 3. Hold the golden giant, slowly turning.
	local spin = TweenService:Create(form, TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = form.CFrame * CFrame.Angles(0, math.pi * 2 - 0.01, 0) })
	spin:Play()
	task.wait(Config.AwakenSeconds - 3)

	-- 4. Settle back to a sleeping small giant for the next round.
	title:Destroy()
	reward:Destroy()
	burst(form.Position, Color3.fromRGB(255, 220, 140), 40, 30, SPARKLE, 1.2)
	form:Destroy()
	giant.Transparency = 0
	setGiantSize(giant.Size)
	if giantLight then
		giantLight.Brightness = 1.6
	end
end)

-- Gold counter.
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 52)
label.Size = UDim2.fromOffset(190, 48)
label.BackgroundColor3 = Color3.fromRGB(40, 24, 60)
label.BackgroundTransparency = 0.15
label.Font = Enum.Font.FredokaOne
label.TextColor3 = Color3.fromRGB(255, 212, 60)
label.TextScaled = true
label.Parent = gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(20, 10, 30)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = label
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)
pad.Parent = label

local goldValue = player:WaitForChild("leaderstats"):WaitForChild("Gold") :: IntValue
local function refresh()
	label.Text = goldValue.Value .. " GOLD"
	label.Size = UDim2.fromOffset(210, 56)
	TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(190, 48) }):Play()
end
goldValue.Changed:Connect(refresh)
label.Text = goldValue.Value .. " GOLD"
]==]
return "installed"