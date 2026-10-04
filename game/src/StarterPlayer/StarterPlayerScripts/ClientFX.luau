--!strict
-- Client-side helpers shared by the effect scripts: sounds, camera shake, particles, tracers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local AnimCurves = require(ReplicatedStorage.Shared.AnimCurves)
local EffectCurves = require(ReplicatedStorage.Shared.EffectCurves)
local Feel = require(ReplicatedStorage.Shared.Feel)
local FovStack = require(ReplicatedStorage.Shared.FovStack)
local PoolSize = require(ReplicatedStorage.Shared.PoolSize)
local SoundBudget = require(ReplicatedStorage.Shared.SoundBudget)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Settings = require(ReplicatedStorage.Shared.Settings)
local UiTheme = require(ReplicatedStorage.Shared.UiTheme)
local VfxDefs = require(ReplicatedStorage.Shared.VfxDefs)
local VfxTextures = require(ReplicatedStorage.Shared.VfxTextures)

local ClientFX = {}
local camera = workspace.CurrentCamera
local sfxVolume = Settings.DefaultVolume
local musicVolume = Settings.DefaultVolume
local soundBudget = SoundBudget.new()
-- settings() is plugin-only; game scripts read the player's saved quality instead.
local configuredQuality = UserSettings():GetService("UserGameSettings").SavedQualityLevel
-- SavedQualityLevel is 0 when the player leaves graphics on Automatic.
local qualityLevel = if configuredQuality.Value > 0 then configuredQuality.Value else 5
local lowQuality = qualityLevel <= 3 or UserInputService.TouchEnabled
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
	KillCrunch = true,
	KillGoo = true,
	KillTick = true,
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

type Motion = {
	StartedAt: number,
	Duration: number,
	Update: (number, number) -> (),
	Complete: (() -> ())?,
}
local motions: { Motion } = {}
local fovStack = FovStack.new(70)

local function animate(duration: number, update: (number, number) -> (), complete: (() -> ())?)
	update(0, 0)
	table.insert(motions, {
		StartedAt = os.clock(),
		Duration = math.max(duration, 0.001),
		Update = update,
		Complete = complete,
	})
end

-- All moving pooled world effects share this driver; no effect owns a Heartbeat loop.
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for index = #motions, 1, -1 do
		local motion = motions[index]
		local elapsed = now - motion.StartedAt
		local progress = math.clamp(elapsed / motion.Duration, 0, 1)
		motion.Update(elapsed, progress)
		if progress >= 1 then
			table.remove(motions, index)
			if motion.Complete then
				motion.Complete()
			end
		end
	end
end)

-- Sole FieldOfView writer: Camera.client publishes BaseFov, kicks add on top (K1 review).
RunService:BindToRenderStep("SwarmFov", Enum.RenderPriority.Camera.Value + 3, function()
	local now = os.clock()
	local base = camera:GetAttribute("BaseFov")
	fovStack.Base = if type(base) == "number" then base else 70
	camera.FieldOfView = FovStack.valueAt(fovStack, now)
	FovStack.prune(fovStack, now)
end)

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
	Scale: UIScale,
	RiseTween: Tween?,
	FadeTween: Tween?,
	PopTween: Tween?,
	Token: number,
}

type GooDecalEntry = {
	Part: Part,
	Tween: Tween?,
	Token: number,
}

type HighlightEntry = {
	Highlight: Highlight,
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
	emitter.Texture = VfxTextures.asset(definition.Texture)
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
local ringParticlePool = PoolSize.new(8, function()
	return makePoolEntry("TexturedRing", VfxDefs.Telegraph)
end)
local gooParticlePool = PoolSize.new(8, function()
	return makePoolEntry("TexturedGoo", VfxDefs.DeathBurst)
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
	entry.Emitter:Emit(VfxDefs.particleCount(count or definition.EmitCount, lowQuality))
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
type SoundEntry = {
	Holder: Part,
	Sound: Sound,
	Name: string?,
}
local soundPool: PoolSize.Pool<SoundEntry>
soundPool = PoolSize.new(32, function(index): SoundEntry
	local holder = Instance.new("Part")
	holder.Name = "SoundHolder" .. index
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Parent = fxFolder
	local sound = Instance.new("Sound")
	sound.Parent = holder
	local entry: SoundEntry = { Holder = holder, Sound = sound, Name = nil }
	sound.Ended:Connect(function()
		if entry.Name then
			soundBudget = SoundBudget.release(soundBudget, entry.Name, os.clock())
			entry.Name = nil
			PoolSize.release(soundPool, entry)
		end
	end)
	return entry
end)

function ClientFX.sound(name: string, at: Vector3?, pitchJitter: number?)
	local def = (Sounds :: any)[name]
	if not def or not Sounds.isPlayable(def.Id) then
		return
	end
	local allowed
	soundBudget, allowed = SoundBudget.allow(soundBudget, name, priorityForSound(name), os.clock())
	if not allowed then
		return
	end
	local entry = PoolSize.acquire(soundPool)
	if entry.Name then
		entry.Sound:Stop()
		soundBudget = SoundBudget.release(soundBudget, entry.Name, os.clock())
	end
	entry.Name = name
	local s = entry.Sound
	s.SoundId = def.Id
	s.Volume = def.Volume * sfxVolume
	s.PlaybackSpeed = def.Pitch * (1 + (math.random() - 0.5) * (pitchJitter or 0.1))
	s.RollOffMaxDistance = 120
	if at then
		entry.Holder.Position = at
		s.Parent = entry.Holder
	else
		s.Parent = SoundService
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
function ClientFX.fovKick(delta: number, seconds: number)
	FovStack.add(fovStack, delta, seconds, os.clock())
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

local function tracerLayer(
	from: Vector3,
	to: Vector3,
	color: Color3,
	thickness: number,
	life: number
)
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

function ClientFX.tracer(from: Vector3, to: Vector3, color: Color3, thickness: number, life: number)
	-- A darker outer streak and a narrower bright core stay readable against both Mars dust
	-- and the purple Nest silhouettes.
	tracerLayer(from, to, color:Lerp(Color3.new(0, 0, 0), 0.2), thickness, life)
	tracerLayer(from, to, color:Lerp(Color3.new(1, 1, 1), 0.3), thickness * 0.4, life)
end

function ClientFX.hitSpark(at: Vector3, color: Color3, normal: Vector3)
	local direction = if normal.Magnitude > 0.001 then normal.Unit else Vector3.new(0, 0, 1)
	local plane = CFrame.lookAt(at, at + direction)
	local diagonalA = (plane.RightVector + plane.UpVector).Unit * 0.55
	local diagonalB = (plane.RightVector - plane.UpVector).Unit * 0.55
	tracerLayer(at - diagonalA, at + diagonalA, color, 0.12, VfxDefs.HitSeconds)
	tracerLayer(at - diagonalB, at + diagonalB, color, 0.12, VfxDefs.HitSeconds)

	local entry = claimEmitter(customPool, VfxDefs.HitSeconds)
	entry.Holder.CFrame = plane
	local emitter = entry.Emitter
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.18, 0)
	emitter.Lifetime = NumberRange.new(0.08, VfxDefs.HitSeconds)
	emitter.Speed = NumberRange.new(16, 24)
	emitter.SpreadAngle = Vector2.new(8, 8)
	emitter.Acceleration = Vector3.zero
	emitter.Drag = 2
	emitter.LightEmission = 1
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Texture = VfxTextures.asset("spark")
	emitter:Emit(VfxDefs.particleCount(VfxDefs.HitStreakCount, lowQuality))
end

function ClientFX.muzzleStar(at: Vector3, color: Color3, direction: Vector3)
	local normal = if direction.Magnitude > 0.001 then direction.Unit else Vector3.new(0, 0, 1)
	local plane = CFrame.lookAt(at, at + normal)
	local radius = 0.45
	for _, axis in
		{
			plane.RightVector,
			plane.UpVector,
			(plane.RightVector + plane.UpVector).Unit,
		}
	do
		tracerLayer(at - axis * radius, at + axis * radius, color, 0.1, VfxDefs.MuzzleFlashSeconds)
	end
	local entry = claimEmitter(emitterPools.MuzzleFlash, VfxDefs.MuzzleFlashSeconds)
	entry.Holder.CFrame = plane
	entry.Emitter.Color = ColorSequence.new(color)
	entry.Emitter.EmissionDirection = Enum.NormalId.Front
	entry.Emitter:Emit(VfxDefs.particleCount(VfxDefs.MuzzleFlash.EmitCount, lowQuality))
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
	pe.Texture = VfxTextures.asset(if spark then "spark" else "goo")
	pe:Emit(VfxDefs.particleCount(count, lowQuality))
end

function ClientFX.dust(at: Vector3, count: number)
	local life = 0.45
	local entry = claimEmitter(customPool, life)
	local emitter = entry.Emitter
	entry.Holder.Position = at
	emitter.Color = ColorSequence.new(Color3.fromRGB(188, 174, 145), Color3.fromRGB(92, 82, 68))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 1.8),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.25, life)
	emitter.Speed = NumberRange.new(3, 8)
	emitter.SpreadAngle = Vector2.new(70, 25)
	emitter.Drag = 5
	emitter.Acceleration = Vector3.new(0, 3, 0)
	emitter.LightEmission = 0
	emitter.Rate = 0
	emitter.Texture = VfxTextures.asset("smoke")
	emitter:Emit(count)
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
		billboard.Size = UDim2.fromOffset(160, 60)
		billboard.AlwaysOnTop = true
		billboard.Enabled = false
		billboard.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = if UiTheme.Font.Number == "FredokaOne"
			then Enum.Font.FredokaOne
			else Enum.Font.GothamBold
		label.TextStrokeTransparency = 0.3
		label.Parent = billboard
		local popScale = Instance.new("UIScale")
		popScale.Name = "PopScale"
		popScale.Parent = label
		return {
			Anchor = anchor,
			Billboard = billboard,
			Label = label,
			Scale = popScale,
			RiseTween = nil,
			FadeTween = nil,
			PopTween = nil,
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
	rise: number,
	critical: boolean?
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
	if entry.PopTween then
		entry.PopTween:Cancel()
	end
	entry.Anchor.Position = at
	entry.Billboard.StudsOffset = Vector3.zero
	entry.Billboard.Enabled = true
	entry.Label.Text = text
	entry.Label.TextColor3 = color
	entry.Label.TextSize = if critical
		then Feel.DamageNumberCritPixels
		else Feel.DamageNumberNormalPixels
	entry.Label.TextTransparency = 0
	entry.Label.TextStrokeTransparency = 0.3
	entry.Scale.Scale = math.min(1, scale)
	entry.PopTween = TweenService:Create(
		entry.Scale,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = Feel.DamageNumberPopScale }
	)
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
	entry.PopTween:Play()
	task.delay(life, function()
		if entry.Token == token then
			entry.Billboard.Enabled = false
			PoolSize.release(damageNumberPool, entry)
		end
	end)
end

local hitFlashPool = PoolSize.new(16, function(index): HighlightEntry
	local highlight = Instance.new("Highlight")
	highlight.Name = "HitFlash" .. index
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.Parent = fxFolder
	return { Highlight = highlight, Token = 0 }
end)

function ClientFX.hitFlash(target: Model, life: number)
	local entry = PoolSize.acquire(hitFlashPool)
	entry.Token += 1
	local token = entry.Token
	entry.Highlight.Adornee = target
	entry.Highlight.FillTransparency = 0
	task.delay(life, function()
		if entry.Token == token then
			entry.Highlight.FillTransparency = 1
			entry.Highlight.Adornee = nil
			PoolSize.release(hitFlashPool, entry)
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
	local texture = VfxTextures.asset("goo")
	if texture ~= "" then
		local particle = claimEmitter(gooParticlePool, life)
		particle.Holder.Position = at
		particle.Emitter.Texture = texture
		particle.Emitter.Color = ColorSequence.new(color)
		particle.Emitter.Size = NumberSequence.new(radius * 2)
		particle.Emitter.Speed = NumberRange.new(0)
		particle.Emitter.Acceleration = Vector3.zero
		particle.Emitter:Emit(1)
		return
	end
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

type LightEntry = { Holder: Part, Light: PointLight, Token: number }
local lightPool = PoolSize.new(12, function(index): LightEntry
	local holder = Instance.new("Part")
	holder.Name = "Flash" .. index
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Parent = fxFolder
	local light = Instance.new("PointLight")
	light.Enabled = false
	light.Parent = holder
	return { Holder = holder, Light = light, Token = 0 }
end)

function ClientFX.flash(at: Vector3, color: Color3, range: number, life: number)
	local entry = PoolSize.acquire(lightPool)
	entry.Token += 1
	local token = entry.Token
	entry.Holder.Position = at
	entry.Light.Color = color
	entry.Light.Range = math.min(range, 12)
	entry.Light.Brightness = 1.5
	entry.Light.Enabled = true
	animate(life, function(_, progress)
		if entry.Token == token then
			entry.Light.Brightness = 1.5 * (1 - EffectCurves.quadOut(progress))
		end
	end, function()
		if entry.Token == token then
			entry.Light.Enabled = false
			PoolSize.release(lightPool, entry)
		end
	end)
end

type PartEntry = { Part: Part, Token: number }
local ringPool = PoolSize.new(16, function(index): PartEntry
	local ring = Instance.new("Part")
	ring.Name = "Ring" .. index
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.SmoothPlastic
	ring.Transparency = 1
	ring.Parent = fxFolder
	return { Part = ring, Token = 0 }
end)

function ClientFX.ring(at: Vector3, color: Color3, radius: number, life: number)
	local texture = VfxTextures.asset("ring")
	if texture ~= "" then
		local entry = claimEmitter(ringParticlePool, life)
		entry.Holder.Position = at
		entry.Emitter.Texture = texture
		entry.Emitter.Size = NumberSequence.new(radius * 2)
		entry.Emitter:Emit(1)
		return
	end
	local entry = PoolSize.acquire(ringPool)
	entry.Token += 1
	local token = entry.Token
	local ring = entry.Part
	ring.Color = color
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0
	animate(life, function(_, progress)
		if entry.Token == token then
			local eased = EffectCurves.quadOut(progress)
			ring.Size = Vector3.new(0.2, 1 + (radius * 2 - 1) * eased, 1 + (radius * 2 - 1) * eased)
			ring.Transparency = eased
		end
	end, function()
		if entry.Token == token then
			ring.Transparency = 1
			PoolSize.release(ringPool, entry)
		end
	end)
end

local gemPool = PoolSize.new(16, function(index): PartEntry
	local gem = Instance.new("Part")
	gem.Name = "XPGemPop" .. index
	gem.Shape = Enum.PartType.Ball
	gem.Size = Vector3.new(0.45, 0.7, 0.45)
	gem.Anchored = true
	gem.CanCollide = false
	gem.CanQuery = false
	gem.CanTouch = false
	gem.CastShadow = false
	gem.Material = Enum.Material.Neon
	gem.Transparency = 1
	gem.Parent = fxFolder
	return { Part = gem, Token = 0 }
end)

function ClientFX.gemPop(position: Vector3, color: Color3)
	local entry = PoolSize.acquire(gemPool)
	entry.Token += 1
	local token = entry.Token
	local gem = entry.Part
	gem.Color = color
	gem.Transparency = 0
	animate(AnimCurves.GemPopDuration, function(elapsed)
		if entry.Token == token then
			local pose = AnimCurves.gemPop(elapsed)
			gem.CFrame = CFrame.new(position + Vector3.new(0, pose.BounceHeight, 0))
				* CFrame.Angles(0, math.rad(pose.SpinDegrees), math.rad(45))
		end
	end, function()
		if entry.Token == token then
			gem.Transparency = 1
			PoolSize.release(gemPool, entry)
		end
	end)
end

local ghostPool = PoolSize.new(12, function(index): PartEntry
	local ghost = Instance.new("Part")
	ghost.Name = "DeathGhost" .. index
	ghost.Shape = Enum.PartType.Ball
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.CastShadow = false
	ghost.Material = Enum.Material.SmoothPlastic
	ghost.Transparency = 1
	ghost.Parent = fxFolder
	return { Part = ghost, Token = 0 }
end)

function ClientFX.deathGhost(model: Model, color: Color3)
	local entry = PoolSize.acquire(ghostPool)
	entry.Token += 1
	local token = entry.Token
	local ghost = entry.Part
	local pivot = model:GetPivot()
	local bounds = model:GetExtentsSize()
	ghost.Size = Vector3.new(math.max(1, bounds.X), math.max(1, bounds.Y), math.max(1, bounds.Z))
	ghost.Color = color
	ghost.Transparency = 0.25
	local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	local away = if root and root:IsA("BasePart")
		then (pivot.Position - root.Position) * Vector3.new(1, 0, 1)
		else pivot.LookVector * Vector3.new(1, 0, 1)
	local direction = if away.Magnitude > 0.01 then away.Unit else Vector3.new(0, 0, 1)
	local life = AnimCurves.DeathSquashDuration + 0.45
	animate(life, function(_, progress)
		if entry.Token == token then
			local eased = EffectCurves.exponentialOut(progress)
			ghost.CFrame = pivot
				+ direction * Feel.GhostKnockbackStuds * eased
				- Vector3.new(0, bounds.Y * 0.35 * eased, 0)
			ghost.Transparency = 0.25 + 0.75 * eased
		end
	end, function()
		if entry.Token == token then
			ghost.Transparency = 1
			PoolSize.release(ghostPool, entry)
		end
	end)
end

function ClientFX.hitstop(target: Model, elite: boolean)
	local duration = (if elite then Feel.Events.EliteKill.FreezeMs else Feel.Events.Kill.FreezeMs)
		/ 1000
	local untilTime = os.clock() + duration
	target:SetAttribute("ClientHitstopUntil", untilTime)
	localPlayer:SetAttribute("WeaponHitstopUntil", untilTime)
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
