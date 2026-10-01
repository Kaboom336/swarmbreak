--!strict
-- Client-side helpers shared by the effect scripts: sounds, camera shake, particles, tracers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Settings = require(ReplicatedStorage.Shared.Settings)

local ClientFX = {}
local camera = workspace.CurrentCamera
local sfxVolume = Settings.DefaultVolume
local musicVolume = Settings.DefaultVolume

local music = Instance.new("Sound")
music.Name = "Music"
music.SoundId = Sounds.Music.Id
music.Volume = Sounds.Music.Volume * musicVolume
music.PlaybackSpeed = Sounds.Music.Pitch
music.Looped = true
music.Parent = SoundService
if music.SoundId ~= "" then
	music:Play()
end

local fxFolder = Instance.new("Folder")
fxFolder.Name = "ClientFX"
fxFolder.Parent = workspace

function ClientFX.c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

function ClientFX.setMusicVolume(value: any)
	musicVolume = Settings.clamp(value)
	music.Volume = Sounds.Music.Volume * musicVolume
end

function ClientFX.setSfxVolume(value: any)
	sfxVolume = Settings.clamp(value)
end

-- ---------- sounds ----------
function ClientFX.sound(name: string, at: Vector3?, pitchJitter: number?)
	local def = (Sounds :: any)[name]
	if not def or def.Id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = def.Id
	s.Volume = def.Volume * sfxVolume
	s.PlaybackSpeed = def.Pitch * (1 + (math.random() - 0.5) * (pitchJitter or 0.1))
	s.RollOffMaxDistance = 120
	if at then
		local holder = Instance.new("Part")
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanQuery = false
		holder.Transparency = 1
		holder.Size = Vector3.one * 0.2
		holder.Position = at
		holder.Parent = fxFolder
		s.Parent = holder
		Debris:AddItem(holder, 4)
	else
		s.Parent = SoundService
		Debris:AddItem(s, 4)
	end
	s:Play()
end

-- ---------- camera shake ----------
local shake = 0
local shakeDecay = 6
RunService:BindToRenderStep("SwarmShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if shake <= 0.001 or camera.CameraType == Enum.CameraType.Scriptable then
		shake = math.max(0, shake - dt * 4)
		return
	end
	local mag = shake
	camera.CFrame = camera.CFrame
		* CFrame.Angles(
			math.rad((math.random() - 0.5) * mag),
			math.rad((math.random() - 0.5) * mag),
			0
		)
	shake = math.max(0, shake - dt * shakeDecay * mag)
end)
function ClientFX.shake(amount: number)
	shake = math.min(shake + amount, 6)
end

-- ---------- FOV kick ----------
local baseFov = 70
local fovTween: Tween? = nil
function ClientFX.fovKick(delta: number, seconds: number)
	if fovTween then
		fovTween:Cancel()
	end
	camera.FieldOfView = baseFov + delta
	fovTween = TweenService:Create(
		camera,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = baseFov }
	)
	fovTween:Play()
end

-- ---------- world primitives ----------
function ClientFX.tracer(from: Vector3, to: Vector3, color: Color3, thickness: number, life: number)
	local len = (to - from).Magnitude
	if len < 0.5 then
		return
	end
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Size = Vector3.new(thickness, thickness, len)
	beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -len / 2)
	beam.Parent = fxFolder
	TweenService
		:Create(
			beam,
			TweenInfo.new(life),
			{ Transparency = 1, Size = Vector3.new(0.02, 0.02, len) }
		)
		:Play()
	Debris:AddItem(beam, life)
end

function ClientFX.burst(
	at: Vector3,
	color: Color3,
	count: number,
	size: number,
	speed: number,
	life: number,
	spark: boolean
)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = at
	holder.Parent = fxFolder
	local att = Instance.new("Attachment")
	att.Parent = holder
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color, color:Lerp(Color3.new(0, 0, 0), 0.5))
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new(0.1, 1)
	pe.Lifetime = NumberRange.new(life * 0.6, life)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = if spark then 4 else 1
	pe.Acceleration = if spark then Vector3.new(0, -30, 0) else Vector3.new(0, 4, 0)
	pe.LightEmission = 1
	pe.Rate = 0
	pe.Parent = att
	pe:Emit(count)
	Debris:AddItem(holder, life + 0.5)
end

function ClientFX.flash(at: Vector3, color: Color3, range: number, life: number)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = at
	holder.Parent = fxFolder
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 4
	light.Parent = holder
	TweenService:Create(light, TweenInfo.new(life), { Brightness = 0 }):Play()
	Debris:AddItem(holder, life)
end

function ClientFX.ring(at: Vector3, color: Color3, radius: number, life: number)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = fxFolder
	TweenService
		:Create(ring, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.2, radius * 2, radius * 2),
			Transparency = 1,
		})
		:Play()
	Debris:AddItem(ring, life)
end

return ClientFX
