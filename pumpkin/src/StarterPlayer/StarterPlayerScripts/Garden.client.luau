--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("GardenLayout"))
if Config.GameplayMode ~= "Garden" then
	return
end
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("GardenAction") :: RemoteEvent
local gui = Instance.new("ScreenGui")
gui.Name = "PumpkinGarden"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local canvas = Instance.new("Frame")
canvas.Name = "SafeCanvas"
canvas.BackgroundTransparency = 1
canvas.Size = UDim2.fromScale(1, 1)
canvas.Parent = gui
local function text(
	parent: Instance,
	name: string,
	content: string,
	size: UDim2,
	position: UDim2
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, content
	label.Size, label.Position = size, position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 241, 209)
	label.TextSize = 17
	label.TextWrapped = true
	label.Parent = parent
	return label
end
local panel = Instance.new("Frame")
panel.Size = UDim2.new(1, -24, 0, 100)
panel.Position = UDim2.fromOffset(12, 12)
panel.BackgroundColor3 = Color3.fromRGB(35, 26, 54)
panel.BackgroundTransparency = 0.12
panel.Parent = canvas
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(460, 100)
constraint.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = panel
local stats =
	text(panel, "Gold", "Loading your garden…", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 6))
local goal = text(
	panel,
	"Shrine",
	"Pick → cast → free ghosts",
	UDim2.new(1, -24, 0, 24),
	UDim2.fromOffset(12, 33)
)
local hint = text(
	panel,
	"Hint",
	"Walk to your ready pumpkin",
	UDim2.new(1, -24, 0, 34),
	UDim2.fromOffset(12, 60)
)
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
local function button(content: string, position: UDim2, callback: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(145, 56)
	b.Position = position
	b.AnchorPoint = Vector2.new(0.5, 1)
	b.Text = content
	b.TextSize = 17
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.fromRGB(255, 246, 220)
	b.BackgroundColor3 = Color3.fromRGB(200, 86, 29)
	b.Parent = canvas
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = b
	b.Activated:Connect(callback)
	return b
end
local main = button("HARVEST • E", UDim2.new(0.5, 0, 1, -80), function()
	remote:FireServer("context")
end)
local burst = button("BURST • Q", UDim2.new(0.5, 0, 1, -134), function()
	remote:FireServer("burst")
end)
burst.Visible = false
local function resize()
	local size = canvas.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return
	end
	local layout = Layout.calculate(size.X, size.Y)
	for name, item in { hud = panel, main = main, burst = burst } do
		local rect = layout[name]
		item.AnchorPoint = Vector2.zero
		item.Position = UDim2.fromOffset(rect.x, rect.y)
		item.Size = UDim2.fromOffset(rect.width, rect.height)
	end
end
canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
local currentMode = "harvest"
local function inputLabels()
	local input = UserInputService:GetLastInputType()
	local gamepad = tostring(input):find("Gamepad") ~= nil
	local touch = input == Enum.UserInputType.Touch
	local suffix = if touch then "" elseif gamepad then " • X" else " • E"
	main.Text = (
		if currentMode == "cast"
			then "CAST"
			elseif currentMode == "guide" then "RECALL"
			else "HARVEST"
	) .. suffix
	burst.Text = "BURST" .. (if touch then "" elseif gamepad then " • Y" else " • Q")
end
UserInputService.LastInputTypeChanged:Connect(inputLabels)
inputLabels()
ContextActionService:BindAction("GardenContext", function(_, state)
	if state == Enum.UserInputState.Begin then
		remote:FireServer("context")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("GardenBurst", function(_, state)
	if state == Enum.UserInputState.Begin then
		remote:FireServer("burst")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonY)
local reduced, volume = false, 1
local active, lastSound = 0, 0
local shakeUntil = 0
local previousShake = CFrame.identity
local shakeCamera: Camera? = nil
RunService:BindToRenderStep("GardenImpact", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if shakeCamera ~= camera then
		previousShake = CFrame.identity
		shakeCamera = camera
	end
	local remaining = if reduced then 0 else math.clamp((shakeUntil - os.clock()) / 0.22, 0, 1)
	local amount = math.sin(os.clock() * 83) * remaining
	local offset = CFrame.new(amount * 0.035, amount * 0.02, 0)
		* CFrame.Angles(0, 0, amount * 0.004)
	-- Apply a delta and restore the last offset, including static/custom cameras.
	camera.CFrame = camera.CFrame * previousShake:Inverse() * offset
	previousShake = offset
end)
local function fx(data: any)
	if typeof(data.position) ~= "Vector3" or active >= 14 then
		return
	end
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - data.position).Magnitude > 120 then
		return
	end
	active += 1
	local color = if data.kind == "ghost"
		then Color3.fromRGB(255, 212, 71)
		elseif data.kind == "chain" then Color3.fromRGB(105, 244, 243)
		else Color3.fromRGB(206, 137, 255)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.Position = data.position
	anchor.Parent = workspace
	if not reduced then
		if data.kind == "cast" then
			-- One short rune precedes the converging seed pose.
			for i = 1, 12 do
				local angle = i / 12 * math.pi * 2
				local a = data.position
					+ Vector3.new(math.cos(angle) * 3, -1.5, math.sin(angle) * 3)
				local b = data.position
					+ Vector3.new(
						math.cos(angle + math.pi / 6) * 3,
						-1.5,
						math.sin(angle + math.pi / 6) * 3
					)
				local rune = Instance.new("Part")
				rune.Anchored, rune.CanCollide, rune.CanTouch, rune.CanQuery =
					true, false, false, false
				rune.Material, rune.Color = Enum.Material.Neon, color
				rune.Size = Vector3.new(0.12, 0.12, (a - b).Magnitude)
				rune.CFrame = CFrame.lookAt((a + b) / 2, b)
				rune.Parent = workspace
				TweenService:Create(rune, TweenInfo.new(0.55), { Transparency = 1 }):Play()
				Debris:AddItem(rune, 0.65)
			end
		end
		if data.kind == "burst" then
			for i = 1, 7 do
				local angle = i / 7 * math.pi * 2
				local offset = Vector3.new(math.cos(angle) * 5, 1 + i % 2, math.sin(angle) * 5)
				for layer = 1, 2 do
					local rind = Instance.new("WedgePart")
					rind.Anchored, rind.CanCollide, rind.CanTouch, rind.CanQuery =
						true, false, false, false
					rind.Color = if layer == 1
						then Color3.fromRGB(242, 106, 24)
						else Color3.fromRGB(255, 220, 142)
					rind.Size = if layer == 1
						then Vector3.new(0.8, 0.28, 0.9)
						else Vector3.new(0.64, 0.1, 0.75)
					local inner = Vector3.new(0, if layer == 1 then 0 else 0.17, 0)
					rind.CFrame = CFrame.new(data.position + inner) * CFrame.Angles(0, angle, 0)
					rind.Parent = workspace
					TweenService:Create(
						rind,
						TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							CFrame = CFrame.new(data.position + offset + inner)
								* CFrame.Angles(angle, angle * 2, 1),
							Transparency = 1,
						}
					):Play()
					Debris:AddItem(rind, 0.7)
				end
			end
			if data.owner == player.UserId then
				shakeUntil = os.clock() + 0.22
			end
		end
		local n = if data.kind == "ghost" then 4 else 6
		for i = 1, n do
			local seed = Instance.new("Part")
			seed.Shape = Enum.PartType.Ball
			seed.Anchored, seed.CanCollide, seed.CanTouch, seed.CanQuery = true, false, false, false
			seed.Material = Enum.Material.Neon
			seed.Color = if data.kind == "cast" then color else Color3.fromRGB(255, 211, 64)
			seed.Size = Vector3.new(0.18, 0.42, 0.18)
			local angle = i / n * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 3, 0.7, math.sin(angle) * 3)
			seed.Position = if data.kind == "cast" then data.position + offset else data.position
			seed.Parent = workspace
			local destination = if data.kind == "cast"
				then data.position
				elseif data.kind == "ghost" then data.position + offset * 0.5 + Vector3.yAxis * 2
				else data.position + offset
			TweenService:Create(
				seed,
				TweenInfo.new(
					0.5,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out,
					0,
					false,
					if data.kind == "cast" then 0.12 else 0
				),
				{
					Position = destination,
					Transparency = 1,
				}
			):Play()
			Debris:AddItem(seed, 0.7)
		end
		if data.kind == "chain" and typeof(data.other) == "Vector3" then
			local a, b = Instance.new("Attachment"), Instance.new("Attachment")
			a.WorldPosition = data.position
			a.Parent = workspace.Terrain
			b.WorldPosition = data.other
			b.Parent = workspace.Terrain
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = a, b
			beam.Color = ColorSequence.new(color)
			beam.Width0, beam.Width1 = 1.1, 1.1
			beam.FaceCamera = true
			beam.CurveSize0, beam.CurveSize1 = 7, -7
			beam.Parent = anchor
			Debris:AddItem(a, 0.7)
			Debris:AddItem(b, 0.7)
		end
	end
	if volume > 0 and os.clock() - lastSound > 0.12 then
		lastSound = os.clock()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.PlaybackSpeed = if data.kind == "burst"
			then 0.65
			elseif data.kind == "harvest" then 1.4
			else 1
		sound.Volume = 0.28 * volume
		sound.RollOffMaxDistance = 100
		sound.Parent = anchor
		sound:Play()
	end
	Debris:AddItem(anchor, 0.85)
	task.delay(0.9, function()
		active -= 1
	end)
end
local received = false
remote.OnClientEvent:Connect(function(action, data)
	if type(data) ~= "table" then
		return
	end
	if action == "fx" then
		fx(data)
		return
	end
	if action ~= "state" then
		return
	end
	received = true
	reduced = data.reducedEffects == true
	volume = math.clamp(tonumber(data.sfxVolume) or 1, 0, 1)
	stats.Text = tostring(data.gold)
		.. " GOLD  •  "
		.. (if data.rank >= 1 then "BIG VINES" else "SMALL VINES")
	goal.Text = "Village lantern: "
		.. math.min(data.shrine, data.goal)
		.. " / "
		.. data.goal
		.. (
			if data.mode == "guide"
				then "  •  " .. data.charges .. " / " .. data.maximum .. " magic"
				else ""
		)
	currentMode = data.mode
	inputLabels()
	burst.Visible = data.mode == "guide"
	if data.message then
		hint.Text = data.message
	end
end)
task.spawn(function()
	for _ = 1, 20 do
		remote:FireServer("snapshot")
		task.wait(1)
		if received then
			break
		end
	end
	if not received then
		hint.Text = "Your garden is still loading. Rejoin if needed."
	end
end)
