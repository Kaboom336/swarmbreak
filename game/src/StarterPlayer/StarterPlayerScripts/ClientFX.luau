--!strict
-- Client-side helpers shared by the effect scripts: sounds, camera shake, particles, tracers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Feel = require(ReplicatedStorage.Shared.Feel)
local PoolSize = require(ReplicatedStorage.Shared.PoolSize)
local SoundBudget = require(ReplicatedStorage.Shared.SoundBudget)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Settings = require(ReplicatedStorage.Shared.Settings)
local VfxDefs = require(ReplicatedStorage.Shared.VfxDefs)

local ClientFX = {}
local camera = workspace.CurrentCamera
local sfxVolume = Settings.DefaultVolume
local musicVolume = Settings.DefaultVolume
local soundBudget = SoundBudget.new()
-- settings() is plugin-only; game scripts read the player's saved quality instead.
local configuredQuality = UserSettings():GetService("UserGameSettings").SavedQualityLevel
-- SavedQualityLevel is 0 when the player leaves graphics on Automatic.
local qualityLevel = if configuredQuality.Value > 0 then configuredQuality.Value else 5
local effectPoolSizes = PoolSize.forQuality(qualityLevel)

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
music.Looped = true
music.Parent = SoundService
local musicTrack = Sounds.musicFor(false)

-- Swap between the calm lobby loop and the fight loop when the player enters or leaves the arena.
local function playMusicFor(inArena: boolean)
	local track = Sounds.musicFor(inArena)
	if music.SoundId == track.Id and music.IsPlaying then
		return
	end
	musicTrack = track
	music:Stop()
	music.SoundId = track.Id
	music.Volume = track.Volume * musicVolume
	music.PlaybackSpeed = track.Pitch
	if track.Id ~= "" then
		music:Play()
	end
end

local localPlayer = game:GetService("Players").LocalPlayer
playMusicFor(localPlayer:GetAttribute("InArena") == true)
localPlayer:GetAttributeChangedSignal("InArena"):Connect(function()
	playMusicFor(localPlayer:GetAttribute("InArena") == true)
end)

local fxFolder = Instance.new("Folder")
fxFolder.Name = "ClientFX"
fxFolder.Parent = workspace

type PoolEntry = {
	Holder: Part,
	Emitter: ParticleEmitter,
	Token: number,
}

type TracerEntry = {
	Part: Part,
	Tween: Tween?,
	Token: number,
}

type DamageNumberEntry = {
	Anchor: Part,
	Billboard: BillboardGui,
	Label: TextLabel,
	RiseTween: Tween?,
	FadeTween: Tween?,
	Token: number,
}

type GooDecalEntry = {
	Part: Part,
	Tween: Tween?,
	Token: number,
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
	return { Holder = holder, Emitter = emitter, Token = 0 }
end

local emitterPools: { [string]: PoolSize.Pool<PoolEntry> } = {}
for name, definition in VfxDefs.Definitions do
	emitterPools[name] = PoolSize.new(definition.PoolSize, function()
		return makePoolEntry(name, definition)
	end)
end

local customPool = PoolSize.new(effectPoolSizes.HitSparks, function()
	return makePoolEntry("CustomBurst", VfxDefs.HitSpark)
end)

local function claimEmitter(pool: PoolSize.Pool<PoolEntry>, lifetime: number): PoolEntry
	local entry = PoolSize.acquire(pool)
	entry.Token += 1
	local token = entry.Token
	task.delay(lifetime, function()
		if entry.Token == token then
			PoolSize.release(pool, entry)
		end
	end)
	return entry
end

function ClientFX.emit(name: string, at: Vector3, count: number?)
	local definition = VfxDefs.Definitions[name]
	local pool = emitterPools[name]
	if not definition or not pool then
		warn("Unknown VFX definition: " .. name)
		return
	end
	local lifetime = definition.Lifetime[2]
	local entry = claimEmitter(pool, lifetime)
	entry.Holder.Position = at
	entry.Emitter:Emit(count or definition.EmitCount)
end

function ClientFX.c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

function ClientFX.setMusicVolume(value: any)
	musicVolume = Settings.clamp(value)
	music.Volume = musicTrack.Volume * musicVolume
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

function ClientFX.shakeFor(event: Feel.EventName, setting: Feel.ShakeSetting)
	ClientFX.shake(Feel.shakeFor(event, setting))
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
local tracerPool = PoolSize.new(effectPoolSizes.Tracers, function(index): TracerEntry
	local part = Instance.new("Part")
	part.Name = "Tracer" .. index
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Transparency = 1
	part.Parent = fxFolder
	return { Part = part, Tween = nil, Token = 0 }
end)

function ClientFX.tracer(from: Vector3, to: Vector3, color: Color3, thickness: number, life: number)
	local len = (to - from).Magnitude
	if len < 0.5 then
		return
	end
	local entry = PoolSize.acquire(tracerPool)
	entry.Token += 1
	local token = entry.Token
	if entry.Tween then
		entry.Tween:Cancel()
	end
	local beam = entry.Part
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0
	beam.Size = Vector3.new(thickness, thickness, len)
	beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -len / 2)
	entry.Tween = TweenService:Create(
		beam,
		TweenInfo.new(life),
		{ Transparency = 1, Size = Vector3.new(0.02, 0.02, len) }
	)
	entry.Tween:Play()
	task.delay(life, function()
		if entry.Token == token then
			beam.Transparency = 1
			PoolSize.release(tracerPool, entry)
		end
	end)
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
	local entry = claimEmitter(customPool, life)
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
	pe:Emit(count)
end

local damageNumberPool = PoolSize.new(
	effectPoolSizes.DamageNumbers,
	function(index): DamageNumberEntry
		local anchor = Instance.new("Part")
		anchor.Name = "DamageNumber" .. index
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Parent = fxFolder
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(80, 30)
		billboard.AlwaysOnTop = true
		billboard.Enabled = false
		billboard.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextStrokeTransparency = 0.3
		label.Parent = billboard
		return {
			Anchor = anchor,
			Billboard = billboard,
			Label = label,
			RiseTween = nil,
			FadeTween = nil,
			Token = 0,
		}
	end
)

function ClientFX.damageNumber(
	at: Vector3,
	text: string,
	color: Color3,
	scale: number,
	life: number,
	rise: number
)
	local entry = PoolSize.acquire(damageNumberPool)
	entry.Token += 1
	local token = entry.Token
	if entry.RiseTween then
		entry.RiseTween:Cancel()
	end
	if entry.FadeTween then
		entry.FadeTween:Cancel()
	end
	entry.Anchor.Position = at
	entry.Billboard.StudsOffset = Vector3.zero
	entry.Billboard.Enabled = true
	entry.Label.Text = text
	entry.Label.TextColor3 = color
	entry.Label.TextSize = math.round(18 * scale)
	entry.Label.TextTransparency = 0
	entry.Label.TextStrokeTransparency = 0.3
	entry.RiseTween = TweenService:Create(
		entry.Billboard,
		TweenInfo.new(life, Enum.EasingStyle.Quad),
		{ StudsOffset = Vector3.new(0, rise, 0) }
	)
	entry.FadeTween = TweenService:Create(entry.Label, TweenInfo.new(life), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	entry.RiseTween:Play()
	entry.FadeTween:Play()
	task.delay(life, function()
		if entry.Token == token then
			entry.Billboard.Enabled = false
			PoolSize.release(damageNumberPool, entry)
		end
	end)
end

local gooDecalPool = PoolSize.new(effectPoolSizes.GooDecals, function(index): GooDecalEntry
	local part = Instance.new("Part")
	part.Name = "GooDecal" .. index
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 1
	part.Parent = fxFolder
	return { Part = part, Tween = nil, Token = 0 }
end)

function ClientFX.gooDecal(at: Vector3, color: Color3, radius: number, life: number)
	local entry = PoolSize.acquire(gooDecalPool)
	entry.Token += 1
	local token = entry.Token
	if entry.Tween then
		entry.Tween:Cancel()
	end
	local decal = entry.Part
	decal.Color = color
	decal.Size = Vector3.new(0.04, radius * 2, radius * 2)
	decal.CFrame = CFrame.new(at + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, 0, math.rad(90))
	decal.Transparency = 0.35
	entry.Tween = TweenService:Create(decal, TweenInfo.new(life), { Transparency = 1 })
	entry.Tween:Play()
	task.delay(life, function()
		if entry.Token == token then
			decal.Transparency = 1
			PoolSize.release(gooDecalPool, entry)
		end
	end)
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

function ClientFX.glowPulse(model: Model, color: Color3, duration: number)
	local glow = Instance.new("Highlight")
	glow.Name = "AttackTell"
	glow.Adornee = model
	glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	glow.FillColor = color
	glow.FillTransparency = 0.35
	glow.OutlineColor = color
	glow.OutlineTransparency = 0
	glow.Parent = fxFolder
	local life = math.max(duration, 0.1)
	TweenService:Create(glow, TweenInfo.new(life), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()
	Debris:AddItem(glow, life)
end

function ClientFX.groundCircle(at: Vector3, color: Color3, radius: number, duration: number)
	local circle = Instance.new("Part")
	circle.Name = "AttackTellCircle"
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(0.08, radius * 2, radius * 2)
	circle.CFrame = CFrame.new(at + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	circle.Anchored = true
	circle.CanCollide = false
	circle.CanQuery = false
	circle.CanTouch = false
	circle.CastShadow = false
	circle.Material = Enum.Material.Neon
	circle.Color = color
	circle.Transparency = 0.45
	circle.Parent = fxFolder
	local life = math.max(duration, 0.1)
	TweenService
		:Create(circle, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Transparency = 0.8,
			Size = Vector3.new(0.08, radius * 2.15, radius * 2.15),
		})
		:Play()
	Debris:AddItem(circle, life)
end

return ClientFX
