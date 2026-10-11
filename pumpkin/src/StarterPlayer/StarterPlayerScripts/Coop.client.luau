--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
if Config.GameplayMode ~= "Coop" then
	return
end
local Rules = require(Shared:WaitForChild("CoopRules"))
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("CoopAction") :: RemoteEvent
local gui = Instance.new("ScreenGui")
gui.Name = "PumpkinCoop"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local cream = Color3.fromRGB(255, 234, 199)
local function frame(name: string, size: UDim2, position: UDim2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = Color3.fromRGB(34, 25, 45)
	f.BackgroundTransparency = 0.08
	f.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = f
	return f
end
local function label(parent: Instance, text: string, y: number, height: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Size = UDim2.new(1, -24, 0, height)
	item.Position = UDim2.fromOffset(12, y)
	item.BackgroundTransparency = 1
	item.Text = text
	item.TextColor3 = cream
	item.Font = Enum.Font.GothamBold
	item.TextSize = 16
	item.TextWrapped = true
	item.Parent = parent
	return item
end
local function button(
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	fn: () -> ()
): TextButton
	local item = Instance.new("TextButton")
	item.Position = position
	item.Size = size
	item.Text = text
	item.BackgroundColor3 = Color3.fromRGB(200, 92, 36)
	item.TextColor3 = cream
	item.Font = Enum.Font.GothamBold
	item.TextSize = 16
	item.TextWrapped = true
	item.Selectable = true
	item.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = item
	item.Activated:Connect(fn)
	return item
end
local top = frame("Goal", UDim2.new(1, -24, 0, 116), UDim2.fromOffset(12, 12))
local cap = Instance.new("UISizeConstraint")
cap.MaxSize = Vector2.new(650, 116)
cap.Parent = top
local goal = label(top, "Harvest → carry → launch at ghosts", 8, 27)
local stats = label(top, "Loading your farm…", 38, 26)
local message = label(top, "Walk to a pumpkin patch and use Harvest.", 68, 40)
message.Font = Enum.Font.Gotham
message.TextSize = 14
local panel = frame("Controls", UDim2.new(1, -24, 0, 332), UDim2.new(0, 12, 1, -344))
panel.Visible = false
local panelCap = Instance.new("UISizeConstraint")
panelCap.MaxSize = Vector2.new(410, 332)
panelCap.Parent = panel
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 12, 1, -12)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local scale = math.clamp((viewport.Y - 160) / 332, 0.5, 1)
	panelScale.Scale = scale
	panel.Size = UDim2.fromOffset(math.min(410, (viewport.X - 24) / scale), 332)
end
local viewportConnection: RBXScriptConnection? = nil
local function bindCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
	resize()
end
bindCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
local title = label(panel, "Aim your pumpkin", 8, 28)
local launchGroup = Instance.new("Frame")
launchGroup.BackgroundTransparency = 1
launchGroup.Size = UDim2.new(1, 0, 0, 230)
launchGroup.Position = UDim2.fromOffset(0, 43)
launchGroup.Parent = panel
local shopGroup = Instance.new("Frame")
shopGroup.BackgroundTransparency = 1
shopGroup.Size = UDim2.new(1, 0, 0, 230)
shopGroup.Position = UDim2.fromOffset(0, 43)
shopGroup.Parent = panel
local control = table.clone(Rules.DefaultControls)
local values = {}
local function adjust(name: string, amount: number)
	control[name] += amount
	control = Rules.controls(control)
	for key, item in values do
		item.Text = if key == "power"
			then string.format("Power  %d%%", math.floor(control.power * 100 + 0.5))
			else (if key == "yaw" then "Aim  " else "Angle  ") .. control[key] .. "°"
	end
end
for index, entry in { { "yaw", 5 }, { "angle", 5 }, { "power", 0.1 } } do
	local name, step = entry[1], entry[2]
	local y = (index - 1) * 56
	values[name] = label(launchGroup, "", y + 5, 42)
	values[name].Size = UDim2.new(1, -144, 0, 42)
	values[name].Position = UDim2.fromOffset(72, y + 5)
	button(launchGroup, "−", UDim2.fromOffset(12, y), UDim2.fromOffset(48, 48), function()
		adjust(name, -step)
	end)
	button(launchGroup, "+", UDim2.new(1, -60, 0, y), UDim2.fromOffset(48, 48), function()
		adjust(name, step)
	end)
end
adjust("yaw", 0)
local launchButton = button(
	launchGroup,
	"LAUNCH PUMPKIN",
	UDim2.new(0, 12, 0, 176),
	UDim2.new(1, -24, 0, 48),
	function()
		remote:FireServer("launch", control)
		message.Text = "Launching…"
		task.delay(2, function()
			if message.Text == "Launching…" then
				message.Text = "Ready to try again. Launch or close this panel."
			end
			remote:FireServer("snapshot")
		end)
	end
)
local pumpkinButton = button(
	shopGroup,
	"",
	UDim2.fromOffset(12, 12),
	UDim2.new(1, -24, 0, 72),
	function()
		remote:FireServer("upgrade", "pumpkin")
	end
)
button(shopGroup, "", UDim2.fromOffset(12, 100), UDim2.new(1, -24, 0, 72), function()
	remote:FireServer("upgrade", "launcher")
end).Name =
	"LauncherUpgrade"
label(shopGroup, "Ghost hits earn 5 gold. Clear a wave together for a contributor bonus!", 182, 48)
local function close()
	panel.Visible = false
	GuiService.SelectedObject = nil
	remote:FireServer("cancel")
end
button(panel, "Close / keep pumpkin", UDim2.new(0, 12, 1, -49), UDim2.new(1, -24, 0, 40), close)
UserInputService.InputBegan:Connect(function(input, processed)
	if
		panel.Visible
		and (
			input.KeyCode == Enum.KeyCode.ButtonB
			or (input.KeyCode == Enum.KeyCode.Escape and not processed)
		)
	then
		close()
	end
end)
local reducedEffects = false
local sfxVolume = 1
local activeEffects = 0
local lastSound = -100
local launcherAnimations: { [Instance]: any } = {}
local function launchFx(launcher: Instance)
	if reducedEffects or not launcher:IsA("BasePart") or not launcher.Parent then
		return
	end
	local active = launcherAnimations[launcher]
	if active then
		for _, tween in active.tweens do
			tween:Cancel()
		end
		for part, original in active.originals do
			if part.Parent then
				part.CFrame = original
			end
		end
	end
	local record = { originals = {}, tweens = {} }
	launcherAnimations[launcher] = record
	for _, name in { "ThrowingArm", "Cup" } do
		local part = launcher.Parent:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			record.originals[part] = part.CFrame
			local releaseFrame = if name == "Cup"
				then part.CFrame + Vector3.new(0, 3, -2)
				else part.CFrame * CFrame.Angles(math.rad(-50), 0, 0)
			local tween = TweenService:Create(
				part,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = releaseFrame }
			)
			table.insert(record.tweens, tween)
			tween:Play()
		end
	end
	task.delay(0.22, function()
		if launcherAnimations[launcher] ~= record then
			return
		end
		for part, original in record.originals do
			if part.Parent then
				local tween = TweenService:Create(part, TweenInfo.new(0.5), { CFrame = original })
				table.insert(record.tweens, tween)
				tween:Play()
			end
		end
		task.delay(0.55, function()
			if launcherAnimations[launcher] == record then
				launcherAnimations[launcher] = nil
			end
		end)
	end)
end
local function hitFx(position: Vector3, owner: number)
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - position).Magnitude > 350 or activeEffects >= 6 then
		return
	end
	activeEffects += 1
	local anchor = Instance.new("Part")
	anchor.Name = "GhostGoldBurst"
	anchor.Size = Vector3.one * 0.1
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Position = position
	anchor.Parent = workspace
	local badge = Instance.new("BillboardGui")
	badge.Size = UDim2.fromOffset(130, 48)
	badge.StudsOffset = Vector3.new(0, 3, 0)
	badge.AlwaysOnTop = true
	badge.Parent = anchor
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = if owner == player.UserId then "+5 GOLD" else "GHOST HIT!"
	text.TextColor3 = Color3.fromRGB(255, 219, 90)
	text.TextStrokeTransparency = 0.25
	text.Font = Enum.Font.GothamBlack
	text.TextSize = 22
	text.Parent = badge
	TweenService:Create(anchor, TweenInfo.new(1), { Position = position + Vector3.new(0, 4, 0) })
		:Play()
	TweenService
		:Create(text, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 })
		:Play()
	if not reducedEffects then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(185, 230, 215))
		emitter.Lifetime = NumberRange.new(0.35, 0.65)
		emitter.Speed = NumberRange.new(4, 9)
		emitter.Rate = 0
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 5),
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Parent = anchor
		emitter:Emit(8)
		for index = 1, 6 do
			local piece = Instance.new("Part")
			piece.Size = Vector3.one * 0.45
			piece.Color = Color3.fromRGB(248, 143, 32)
			piece.Anchored = true
			piece.CanCollide = false
			piece.CanTouch = false
			piece.CanQuery = false
			piece.Position = position
			piece.Parent = workspace
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = Config.PumpkinMeshId
			mesh.TextureId = Config.PumpkinTextureId
			mesh.Scale = Vector3.one * 0.12
			mesh.Parent = piece
			local angle = index * math.pi / 3
			TweenService:Create(piece, TweenInfo.new(0.65), {
				Position = position
					+ Vector3.new(math.cos(angle) * 4, 2 + index % 2, math.sin(angle) * 4),
				Transparency = 1,
			}):Play()
			Debris:AddItem(piece, 0.7)
		end
	end
	if sfxVolume > 0 and os.clock() - lastSound > 0.08 then
		lastSound = os.clock()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.35 * sfxVolume
		sound.RollOffMaxDistance = 100
		sound.Parent = anchor
		sound:Play()
	end
	Debris:AddItem(anchor, 1.1)
	task.delay(1.1, function()
		activeEffects -= 1
	end)
end
local lastState = 0
remote.OnClientEvent:Connect(function(action, state)
	if action == "hitFx" and type(state) == "table" and typeof(state.position) == "Vector3" then
		hitFx(state.position, state.owner)
		return
	end
	if action == "launchFx" and type(state) == "table" and typeof(state.launcher) == "Instance" then
		launchFx(state.launcher)
		return
	end
	if action ~= "state" or type(state) ~= "table" then
		return
	end
	lastState = os.clock()
	reducedEffects = state.reducedEffects == true
	sfxVolume = math.clamp(tonumber(state.sfxVolume) or 1, 0, 1)
	goal.Text = "Wave "
		.. state.wave
		.. " • "
		.. state.remaining
		.. "/"
		.. state.count
		.. " ghosts left"
	stats.Text = state.gold
		.. " gold  •  "
		.. (
			if state.flying
				then "Pumpkin flying"
				elseif state.carrying then "Carrying a pumpkin"
				else "Harvest a pumpkin"
		)
	if state.message then
		message.Text = state.message
	end
	pumpkinButton.Text = if state.pumpkinRank >= Rules.MaxRank
		then "Pumpkin fully upgraded"
		else "Bigger pumpkin • "
			.. Rules.cost(state.pumpkinRank)
			.. " gold\nRank "
			.. state.pumpkinRank
			.. " → "
			.. (state.pumpkinRank + 1)
	local launcherButton = shopGroup:FindFirstChild("LauncherUpgrade") :: TextButton
	launcherButton.Text = if state.launcherRank >= Rules.MaxRank
		then "Launcher fully upgraded"
		else "Stronger launcher • "
			.. Rules.cost(state.launcherRank)
			.. " gold\nRank "
			.. state.launcherRank
			.. " → "
			.. (state.launcherRank + 1)
	if state.panel == "close" or state.flying or not state.carrying and launchGroup.Visible then
		panel.Visible = false
	end
	if state.panel == "launcher" or state.panel == "shop" then
		panel.Visible = true
		launchGroup.Visible = state.panel == "launcher"
		shopGroup.Visible = state.panel == "shop"
		title.Text = if launchGroup.Visible then "Aim your pumpkin" else "Gold workshop"
		GuiService.SelectedObject = if launchGroup.Visible then launchButton else pumpkinButton
	end
end)
-- Snapshot request is repeatable and recovers from load races / missed initial state.
task.spawn(function()
	for _ = 1, 15 do
		remote:FireServer("snapshot")
		task.wait(1)
		if lastState > 0 then
			break
		end
	end
	if lastState == 0 then
		message.Text = "Still loading. Rejoin if this message persists."
	end
end)
player.CharacterAdded:Connect(function()
	panel.Visible = false
	GuiService.SelectedObject = nil
	remote:FireServer("snapshot")
end)
