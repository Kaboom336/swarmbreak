--!strict
-- Client-side helpers shared by the effect scripts: sounds, camera shake, particles, tracers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Feel = require(ReplicatedStorage.Shared.Feel)
local SoundBudget = require(ReplicatedStorage.Shared.SoundBudget)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Settings = require(ReplicatedStorage.Shared.Settings)
local VfxDefs = require(ReplicatedStorage.Shared.VfxDefs)

local ClientFX = {}
local camera = workspace.CurrentCamera
local sfxVolume = Settings.DefaultVolume
local musicVolume = Settings.DefaultVolume
local muted = Settings.DefaultMute
local reduceMotion = Settings.DefaultReduceMotion
local soundBudget = SoundBudget.new()
local shake = 0
local shakeDecay = 6
local baseFov = 70
local fovTween: Tween? = nil

local p0Sounds = {
	Hurt = true,
	WaveStart = true,
	WaveClear = true,
	BossRoar = true,
	BossThunder = true,
	GameOver = true,
}
local p1Sounds = {
	ShotPistol = true,
	ShotSmg = true,
	ShotShotgun = true,
	ShotRifle = true,
	ShotEnergy = true,
	ShotCannon = true,
	Swing = true,
	Slam = true,
	Orb = true,
	Beam = true,
}
local p2Sounds = {
	Hit = true,
	Kill = true,
	Explosion = true,
}

local function priorityForSound(name: string): SoundBudget.Priority
	if p0Sounds[name] then
		return SoundBudget.P0
	elseif p1Sounds[name] then
		return SoundBudget.P1
	elseif p2Sounds[name] then
		return SoundBudget.P2
	end
	return SoundBudget.P3
end

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

type PoolEntry = {
	Holder: Part,
	Emitter: ParticleEmitter,
	AvailableAt: number,
}

local function numberSequence(keypoints: { VfxDefs.Keypoint }): NumberSequence
	local values = {}
	for _, keypoint in keypoints do
		table.insert(values, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value))
	end
	return NumberSequence.new(values)
end

local function colorSequence(colors: { VfxDefs.Color }): ColorSequence
	local values = {}
	local last = #colors
	for index, color in colors do
		table.insert(
			values,
			ColorSequenceKeypoint.new(
				(index - 1) / math.max(1, last - 1),
				Color3.fromRGB(color[1], color[2], color[3])
			)
		)
	end
	return ColorSequence.new(values)
end

local function applyDefinition(emitter: ParticleEmitter, definition: VfxDefs.Definition)
	emitter.Enabled = false
	emitter.Color = colorSequence(definition.Colors)
	emitter.Transparency = numberSequence(definition.Transparency)
	emitter.Size = numberSequence(definition.Size)
	emitter.Lifetime = NumberRange.new(definition.Lifetime[1], definition.Lifetime[2])
	emitter.Speed = NumberRange.new(definition.Speed[1], definition.Speed[2])
	emitter.SpreadAngle = Vector2.new(definition.Spread[1], definition.Spread[2])
	emitter.Acceleration = Vector3.new(
		definition.Acceleration[1],
		definition.Acceleration[2],
		definition.Acceleration[3]
	)
	emitter.Drag = definition.Drag
	emitter.LightEmission = definition.LightEmission
	emitter.Rate = definition.Rate
	emitter.LockedToPart = false
end

local function makePoolEntry(name: string, definition: VfxDefs.Definition): PoolEntry
	local holder = Instance.new("Part")
	holder.Name = name .. "Emitter"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Parent = fxFolder
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	applyDefinition(emitter, definition)
	emitter.Parent = holder
	return { Holder = holder, Emitter = emitter, AvailableAt = 0 }
end

local emitterPools: { [string]: { PoolEntry } } = {}
for name, definition in VfxDefs.Definitions do
	local pool = {}
	for _ = 1, definition.PoolSize do
		table.insert(pool, makePoolEntry(name, definition))
	end
	emitterPools[name] = pool
end

local customPool = {}
for _ = 1, 16 do
	table.insert(customPool, makePoolEntry("CustomBurst", VfxDefs.HitSpark))
end

local function claim(pool: { PoolEntry }): PoolEntry
	local now = os.clock()
	local earliest = pool[1]
	for _, entry in pool do
		if entry.AvailableAt <= now then
			return entry
		end
		if entry.AvailableAt < earliest.AvailableAt then
			earliest = entry
		end
	end
	return earliest
end

function ClientFX.emit(name: string, at: Vector3, count: number?)
	local definition = VfxDefs.Definitions[name]
	local pool = emitterPools[name]
	if not definition or not pool then
		warn("Unknown VFX definition: " .. name)
		return
	end
	local entry = claim(pool)
	entry.Holder.Position = at
	entry.AvailableAt = os.clock() + definition.Lifetime[2]
	entry.Emitter:Emit(count or definition.EmitCount)
end

function ClientFX.c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

function ClientFX.setMusicVolume(value: any)
	musicVolume = Settings.clamp(value)
	music.Volume = if muted then 0 else Sounds.Music.Volume * musicVolume
end

function ClientFX.setSfxVolume(value: any)
	sfxVolume = Settings.clamp(value)
end

function ClientFX.setMuted(value: any)
	muted = value == true
	music.Volume = if muted then 0 else Sounds.Music.Volume * musicVolume
end

function ClientFX.setReduceMotion(value: any)
	reduceMotion = value == true
	if reduceMotion then
		shake = 0
		if fovTween then
			fovTween:Cancel()
			fovTween = nil
		end
		camera.FieldOfView = baseFov
	end
end

-- ---------- sounds ----------
function ClientFX.sound(name: string, at: Vector3?, pitchJitter: number?)
	if muted then
		return
	end
	local def = (Sounds :: any)[name]
	if not def or def.Id == "" then
		return
	end
	local allowed
	soundBudget, allowed = SoundBudget.allow(soundBudget, name, priorityForSound(name), os.clock())
	if not allowed then
		return
	end
	local s = Instance.new("Sound")
	s.Ended:Once(function()
		soundBudget = SoundBudget.release(soundBudget, name, os.clock())
	end)
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
	if reduceMotion then
		return
	end
	shake = math.min(shake + amount, 6)
end

function ClientFX.shakeFor(event: Feel.EventName, setting: Feel.ShakeSetting)
	ClientFX.shake(Feel.shakeFor(event, setting))
end

-- ---------- FOV kick ----------
function ClientFX.fovKick(delta: number, seconds: number)
	if reduceMotion then
		return
	end
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
	local entry = claim(customPool)
	local pe = entry.Emitter
	entry.Holder.Position = at
	pe.Color = ColorSequence.new(color, color:Lerp(Color3.new(0, 0, 0), 0.5))
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.08, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(life * 0.6, life)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = if spark then 4 else 1
	pe.Acceleration = if spark then Vector3.new(0, -30, 0) else Vector3.new(0, 4, 0)
	pe.LightEmission = 1
	pe.Rate = 0
	entry.AvailableAt = os.clock() + life
	pe:Emit(count)
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
