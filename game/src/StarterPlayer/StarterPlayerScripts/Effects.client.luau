--!strict
-- Renders every FX event the server broadcasts. All visuals are local, so the server stays cheap.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AnimCurves = require(ReplicatedStorage.Shared.AnimCurves)
local Feel = require(ReplicatedStorage.Shared.Feel)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local player = Players.LocalPlayer
local FX = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FX") :: RemoteEvent
local c3 = ClientFX.c3

local function muzzleOf(shooter: Player): Vector3?
	local char = shooter.Character
	local weapon = char and char:FindFirstChild("Weapon")
	local muzzle = weapon and weapon:FindFirstChild("Muzzle", true) :: Attachment?
	return if muzzle then muzzle.WorldPosition else nil
end

-- Swing the held weapon on any character (visual only).
local function swingWeapon(shooter: Player, slam: boolean)
	local char = shooter.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	local motor = hand and hand:FindFirstChild("GripMotor") :: Motor6D?
	local shoulder = char and char:FindFirstChild("RightUpperArm")
	local shoulderMotor = shoulder and shoulder:FindFirstChild("RightShoulder") :: Motor6D?
	if shoulderMotor then
		local c0 = shoulderMotor.C0
		local up = c0 * CFrame.Angles(math.rad(if slam then -170 else -120), 0, math.rad(20))
		local down = c0 * CFrame.Angles(math.rad(if slam then 30 else -10), 0, math.rad(-40))
		TweenService:Create(shoulderMotor, TweenInfo.new(0.08), { C0 = up }):Play()
		task.delay(0.08, function()
			TweenService:Create(
				shoulderMotor,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ C0 = down }
			):Play()
			task.delay(0.12, function()
				TweenService:Create(shoulderMotor, TweenInfo.new(0.25), { C0 = c0 }):Play()
			end)
		end)
	elseif motor then
		local c0 = motor.C0
		TweenService
			:Create(motor, TweenInfo.new(0.1), { C0 = c0 * CFrame.Angles(math.rad(-90), 0, 0) })
			:Play()
		task.delay(0.15, function()
			TweenService:Create(motor, TweenInfo.new(0.2), { C0 = c0 }):Play()
		end)
	end
end

local handlers: { [string]: (any) -> () } = {}
local queenHazards: { Instance } = {}
local QUEEN_KILL_CAMERA = "SwarmQueenKillCamera"

local function clearQueenHazards()
	for _, hazard in queenHazards do
		hazard:Destroy()
	end
	table.clear(queenHazards)
end

handlers.shot = function(d)
	local color = c3(d.Color)
	local from = muzzleOf(d.Shooter) or d.Origin
	for _, endPos in d.Ends do
		ClientFX.tracer(from, endPos, color, 0.12, Feel.TracerSeconds)
	end
	ClientFX.flash(from, color, 10, Feel.MuzzleFlashSeconds)
	ClientFX.burst(from, color, 6, 0.5, 8, Feel.MuzzleFlashSeconds, true)
	for _, h in d.Hits do
		ClientFX.burst(h, color, 12, 0.35, 18, 0.35, true)
	end
	ClientFX.sound(d.Sound, from)
	if d.Shooter == player then
		ClientFX.shake(0.6 + #d.Ends * 0.15)
	end
end

handlers.swing = function(d)
	local color = c3(d.Color)
	swingWeapon(d.Shooter, d.Slam)
	local at = d.Origin + Vector3.new(0, -2.5, 0)
	if d.Slam then
		ClientFX.ring(at, color, d.Range, 0.35)
		ClientFX.burst(d.Origin, color, 30, 0.8, 22, 0.5, false)
		ClientFX.flash(d.Origin, color, d.Range * 2, 0.25)
		if d.Shooter == player then
			ClientFX.shake(3)
		end
	else
		-- arc: a fan of short tracers sweeping in front
		local dir = d.Dir :: Vector3
		local base = d.Origin + Vector3.new(0, 0.5, 0)
		for i = -2, 2 do
			local a = CFrame.Angles(0, math.rad(i * 18), 0)
			local p = base + (a * dir) * d.Range * 0.9
			ClientFX.tracer(base + (a * dir) * 1.5, p, color, 0.25, 0.14)
		end
		if d.Shooter == player then
			ClientFX.shake(1)
		end
	end
	for _, h in d.Hits do
		ClientFX.burst(h, color, 14, 0.4, 16, 0.35, true)
	end
	ClientFX.sound(d.Sound, d.Origin)
end

local beamParts: { [Player]: BasePart } = {}
local beamLastTick: { [Player]: number } = {}
handlers.beam = function(d)
	local color = c3(d.Color)
	local from = muzzleOf(d.Shooter) or d.Origin
	local to = d.EndPos :: Vector3
	local len = (to - from).Magnitude
	local beam = beamParts[d.Shooter]
	if not beam or not beam.Parent then
		beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.CastShadow = false
		beam.Material = Enum.Material.Neon
		beam.Color = color
		beam.Parent = workspace:FindFirstChild("ClientFX") or workspace
		beamParts[d.Shooter] = beam
	end
	beam.Size = Vector3.new(0.35, 0.35, len)
	beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -len / 2)
	beamLastTick[d.Shooter] = os.clock()
	task.delay(0.25, function()
		-- vanish only if no newer tick arrived
		if os.clock() - (beamLastTick[d.Shooter] or 0) >= 0.24 and beamParts[d.Shooter] == beam then
			beam:Destroy()
			beamParts[d.Shooter] = nil
		end
	end)
	if d.Hit then
		ClientFX.burst(d.Hit, color, 4, 0.3, 10, 0.25, true)
		ClientFX.flash(d.Hit, color, 6, 0.12)
	end
	if math.random() < 0.3 then
		ClientFX.sound(d.Sound, from, 0.2)
	end
end

handlers.spit = function(d)
	local color = c3(d.Color)
	ClientFX.tracer(d.From, d.To, color, 0.3, 0.15)
	ClientFX.burst(d.To, color, 10, 0.5, 8, 0.4, false)
	ClientFX.sound("EnemySpawn", d.From, 0.4)
end

handlers.death = function(d)
	local color = c3(Feel.deathBurstColor(d.EnemyType, d.Color))
	local n = if d.Boss then 90 else 22
	ClientFX.burst(
		d.Position,
		color,
		n,
		if d.Boss then 1.4 else 0.6,
		if d.Boss then 45 else 18,
		if d.Boss then 1.2 else 0.6,
		false
	)
	ClientFX.flash(d.Position, color, if d.Boss then 60 else 12, if d.Boss then 0.8 else 0.25)
	ClientFX.ring(
		d.Position - Vector3.new(0, d.Size * 0.4, 0),
		color,
		if d.Boss then 30 else d.Size,
		if d.Boss then 0.8 else 0.4
	)
	if d.Boss then
		ClientFX.sound("Explosion", d.Position)
	end
	if d.Boss then
		ClientFX.fovKick(12, 0.9)
	end
end

handlers.spawn = function(d)
	local color = c3(d.Color)
	ClientFX.ring(d.Position, color, 6, 0.6)
	ClientFX.burst(d.Position, color, 12, 0.7, 6, 0.6, false)
	ClientFX.sound("EnemySpawn", d.Position, 0.3)
end

handlers.tell = function(d)
	local color = c3(d.GlowColor)
	if d.GlowPulse and d.Model and d.Model.Parent then
		ClientFX.glowPulse(d.Model, color, d.Duration)
	end
	ClientFX.sound(d.Sound, d.Position)
	if d.GroundPosition then
		ClientFX.groundCircle(d.GroundPosition, c3(Theme.Telegraph), d.Radius, d.Duration)
	end
end

handlers.boss = function(d)
	ClientFX.sound("BossRoar")
	ClientFX.sound("BossThunder")
	ClientFX.ring(d.Position, c3(d.Color), 40, 1.5)
end

handlers.queenTell = function(d)
	local telegraph = c3(Theme.Telegraph)
	if d.Model and d.Model.Parent then
		ClientFX.glowPulse(d.Model, telegraph, d.Duration)
	end
	ClientFX.sound("BossRoar", d.Origin, 0.45)
	local groundY = d.Target.Y - 3
	local originGround = Vector3.new(d.Origin.X, groundY, d.Origin.Z)
	if d.Shape == "Arc" then
		local previous = originGround + (CFrame.Angles(0, math.rad(-100), 0) * d.Direction) * 22
		for step = 1, 10 do
			local angle = -100 + step * 20
			local point = originGround + (CFrame.Angles(0, math.rad(angle), 0) * d.Direction) * 22
			ClientFX.tracer(previous, point, telegraph, 2, d.Duration)
			previous = point
		end
	elseif d.Shape == "ThreeCircles" then
		for _, position in d.Circles do
			ClientFX.groundCircle(position - Vector3.new(0, 3, 0), telegraph, 7, d.Duration)
		end
	else
		ClientFX.tracer(
			originGround,
			Vector3.new(d.Target.X, groundY, d.Target.Z),
			telegraph,
			8,
			d.Duration
		)
	end
end

handlers.queenAttack = function(d)
	local goo = c3(Theme.Goo)
	if d.Shape == "ThreeCircles" then
		for _, position in d.Circles do
			ClientFX.burst(position, goo, 18, 0.5, 12, 0.35, false)
		end
	else
		ClientFX.burst(d.Target, goo, 24, 0.6, 18, 0.4, false)
	end
end

handlers.queenPhase = function(d)
	clearQueenHazards()
	ClientFX.sound("BossRoar", d.Position)
	local parent = workspace:FindFirstChild("ClientFX") or workspace
	for index, pool in d.Pools do
		local hazard = Instance.new("Part")
		hazard.Name = "QueenGoo_" .. index
		hazard.Anchored = true
		hazard.CanCollide = false
		hazard.CanQuery = false
		hazard.CanTouch = false
		hazard.CastShadow = false
		hazard.Shape = Enum.PartType.Cylinder
		hazard.Size = Vector3.new(0.15, pool.Radius * 2, pool.Radius * 2)
		hazard.CFrame = CFrame.new(pool.x, 1.1, pool.z) * CFrame.Angles(0, 0, math.pi / 2)
		hazard.Color = c3(Theme.Goo)
		hazard.Material = Enum.Material.Glass
		hazard.Transparency = 0.3
		hazard.Parent = parent
		local outline = Instance.new("SelectionBox")
		outline.Name = "TelegraphOutline"
		outline.Adornee = hazard
		outline.Color3 = c3(Theme.Telegraph)
		outline.LineThickness = 0.05
		outline.SurfaceTransparency = 1
		outline.Parent = hazard
		table.insert(queenHazards, hazard)
	end
end

handlers.queenEnd = function(_d)
	clearQueenHazards()
end

handlers.queenKill = function(d)
	clearQueenHazards()
	local position = d.Position :: Vector3
	local goo = c3(Theme.Goo)
	ClientFX.burst(position, goo, 90, 1.5, 48, Feel.BossKillSlowMoSeconds, false)
	ClientFX.burst(position + Vector3.new(0, 6, 0), c3(Theme.Loot), 45, 1, 36, 0.6, false)
	ClientFX.sound("Explosion", position)

	local playerGui = player:WaitForChild("PlayerGui")
	-- A TextLabel only renders inside a ScreenGui.
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "CoreClearedGui"
	bannerGui.IgnoreGuiInset = true
	bannerGui.DisplayOrder = 60
	bannerGui.ResetOnSpawn = false
	bannerGui.Parent = playerGui
	local banner = Instance.new("TextLabel")
	banner.Name = "CoreCleared"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.35)
	banner.Size = UDim2.fromOffset(720, 100)
	banner.BackgroundTransparency = 1
	banner.Font = UiKit.Fonts.Banner
	banner.Text = "MARS CORE CLEARED"
	banner.TextColor3 = c3(Theme.Loot)
	banner.TextSize = 64
	banner.TextStrokeTransparency = 0
	banner.Parent = bannerGui
	-- Hold long enough to read, then fade (the slow-mo itself is only 0.6 s).
	task.delay(2.5, function()
		TweenService:Create(
			banner,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()
	end)
	task.delay(3.4, function()
		bannerGui:Destroy()
	end)

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	RunService:UnbindFromRenderStep(QUEEN_KILL_CAMERA)
	local startedAt = os.clock()
	local startOffset = camera.CFrame.Position - position
	local radius = math.max(18, (startOffset * Vector3.new(1, 0, 1)).Magnitude)
	local height = math.max(8, startOffset.Y)
	local angle = math.atan2(startOffset.Z, startOffset.X)
	workspace:SetAttribute("ClientTimeScale", Feel.BossKillSlowMoScale)
	camera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep(QUEEN_KILL_CAMERA, Enum.RenderPriority.Camera.Value + 1, function()
		local elapsed = os.clock() - startedAt
		local alpha = math.clamp(elapsed / Feel.BossKillSlowMoSeconds, 0, 1)
		local orbit = angle + alpha * math.pi * 0.8
		local cameraPosition = position
			+ Vector3.new(math.cos(orbit) * radius, height, math.sin(orbit) * radius)
		camera.CFrame = CFrame.lookAt(cameraPosition, position + Vector3.new(0, 5, 0))
		if alpha >= 1 then
			RunService:UnbindFromRenderStep(QUEEN_KILL_CAMERA)
			workspace:SetAttribute("ClientTimeScale", 1)
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

handlers.sound = function(d)
	local soundName = if d.Event then SfxMap.forEvent(d.Event) else d.Name
	if soundName then
		ClientFX.sound(soundName, d.Position)
	end
end

-- Evolution effects (Arc / Chain): a bright thread between the enemies it jumped through.
handlers.chain = function(d)
	local color = c3(d.Color)
	local points: { Vector3 } = d.Points
	for i = 1, #points - 1 do
		ClientFX.tracer(points[i], points[i + 1], color, 0.2, 0.22)
		ClientFX.burst(points[i + 1], color, 8, 0.3, 12, 0.3, true)
	end
	ClientFX.flash(points[1], color, 8, 0.1)
	ClientFX.sound("Hit", points[1], 0.5)
end

-- Dark pull on a kill: an imploding ring.
handlers.pull = function(d)
	local color = c3(d.Color)
	ClientFX.ring(d.Position, color, d.Radius, 0.45)
	ClientFX.burst(d.Position, color, 16, 0.4, 14, 0.5, false)
	ClientFX.flash(d.Position, color, d.Radius, 0.3)
end

-- Weapon evolved in the shop: a column of rings in the element's color.
local EVOLVE_CAMERA_BINDING = "SwarmBreakEvolutionCamera"
local evolveToken = 0

local function localEvolutionCinematic(d, color: Color3)
	evolveToken += 1
	local token = evolveToken
	RunService:UnbindFromRenderStep(EVOLVE_CAMERA_BINDING)
	local camera = workspace.CurrentCamera
	local startCFrame = if camera then camera.CFrame else nil
	local startedAt = os.clock()
	if camera and startCFrame then
		RunService:BindToRenderStep(
			EVOLVE_CAMERA_BINDING,
			Enum.RenderPriority.Camera.Value + 3,
			function()
				if token ~= evolveToken or not camera.Parent then
					RunService:UnbindFromRenderStep(EVOLVE_CAMERA_BINDING)
					return
				end
				local elapsed = os.clock() - startedAt
				local slowElapsed = AnimCurves.slowMoElapsed(elapsed)
				if slowElapsed >= AnimCurves.SlowMoSeconds then
					RunService:UnbindFromRenderStep(EVOLVE_CAMERA_BINDING)
					return
				end
				local push = AnimCurves.evolutionEnvelope(slowElapsed) * 2.5
				local position = startCFrame.Position + startCFrame.LookVector * push
				camera.CFrame = CFrame.lookAt(position, d.Position + Vector3.new(0, 1.5, 0))
			end
		)
	end

	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild("Hud", 2)
	if hud and hud:IsA("ScreenGui") then
		local previous = hud:FindFirstChild("EvolveBanner")
		if previous then
			previous:Destroy()
		end
		local banner = UiKit.Banner(hud, "EvolveBanner", "EVOLVED: " .. tostring(d.Name))
		banner.TextTransparency = 1
		banner.TextStrokeTransparency = 1
		TweenService:Create(banner, TweenInfo.new(0.1), {
			TextTransparency = 0,
			TextStrokeTransparency = 0.2,
		}):Play()
		task.delay((AnimCurves.SlowMoSeconds - 0.15) / AnimCurves.SlowMoScale, function()
			if banner.Parent then
				local fade = TweenService:Create(banner, TweenInfo.new(0.15), {
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				})
				fade:Play()
				fade.Completed:Once(function()
					banner:Destroy()
				end)
			end
		end)
	end
	ClientFX.flash(d.Position, color, 24, AnimCurves.SlowMoSeconds / AnimCurves.SlowMoScale)
end

handlers.evolve = function(d)
	local color = c3(d.Color)
	local isLocal = d.Player == player
	for i = 1, d.Tier + 1 do
		task.delay(AnimCurves.evolutionRingDelay(i, d.Tier + 1), function()
			ClientFX.ring(
				d.Position + Vector3.new(0, i * 1.5 - 1, 0),
				color,
				4 + i,
				if isLocal then 0.9 else 0.6
			)
		end)
	end
	ClientFX.burst(d.Position, color, 30, 0.6, 18, if isLocal then 1.05 else 0.7, true)
	ClientFX.flash(d.Position, color, 20, 0.5)
	ClientFX.sound("Buy", d.Position)
	if isLocal then
		localEvolutionCinematic(d, color)
	end
end

FX.OnClientEvent:Connect(function(kind: string, data: any)
	local h = handlers[kind]
	if h then
		h(data)
	end
end)
