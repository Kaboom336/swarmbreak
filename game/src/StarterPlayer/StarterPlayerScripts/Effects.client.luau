--!strict
-- Renders every FX event the server broadcasts. All visuals are local, so the server stays cheap.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Feel = require(ReplicatedStorage.Shared.Feel)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local ClientFX = require(script.Parent.ClientFX)

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

handlers.shot = function(d)
	local color = c3(d.Color)
	local from = muzzleOf(d.Shooter) or d.Origin
	for _, endPos in d.Ends do
		ClientFX.tracer(from, endPos, color, 0.12, 0.08)
	end
	ClientFX.flash(from, color, 10, 0.08)
	ClientFX.burst(from, color, 6, 0.5, 8, 0.15, true)
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
		ClientFX.shake(5)
		ClientFX.fovKick(12, 0.9)
	end
end

handlers.spawn = function(d)
	local color = c3(d.Color)
	ClientFX.ring(d.Position, color, 6, 0.6)
	ClientFX.burst(d.Position, color, 12, 0.7, 6, 0.6, false)
	ClientFX.sound("EnemySpawn", d.Position, 0.3)
end

handlers.boss = function(d)
	ClientFX.sound("BossRoar")
	ClientFX.sound("BossThunder")
	ClientFX.shake(4)
	ClientFX.ring(d.Position, c3(d.Color), 40, 1.5)
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
handlers.evolve = function(d)
	local color = c3(d.Color)
	for i = 1, d.Tier + 1 do
		task.delay((i - 1) * 0.12, function()
			ClientFX.ring(d.Position + Vector3.new(0, i * 1.5 - 1, 0), color, 4 + i, 0.6)
		end)
	end
	ClientFX.burst(d.Position, color, 30, 0.6, 18, 0.7, true)
	ClientFX.flash(d.Position, color, 20, 0.5)
	ClientFX.sound("Buy", d.Position)
end

FX.OnClientEvent:Connect(function(kind: string, data: any)
	local h = handlers[kind]
	if h then
		h(data)
	end
end)
