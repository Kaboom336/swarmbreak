--!strict
-- Procedural locomotion and combat animation for every enemy rig.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimCull = require(ReplicatedStorage.Shared.AnimCull)
local EnemyAnimCurves = require(ReplicatedStorage.Shared.EnemyAnimCurves)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local FX = remotes:WaitForChild("FX") :: RemoteEvent
local enemies = workspace:WaitForChild("Enemies")

type Anim = {
	Root: BasePart,
	Humanoid: Humanoid,
	Motors: { [string]: Motor6D },
	Base: { [string]: CFrame },
	Phase: number,
	Index: number,
	LastHealth: number,
	HitStarted: number?,
	AttackStarted: number?,
	AttackWindup: number,
	HitFlash: HitFlash?,
}
type HitFlash = {
	Highlight: Highlight,
	FillColor: Color3,
	FillTransparency: number,
	OutlineColor: Color3,
	OutlineTransparency: number,
	Token: number,
}
local anims: { [Model]: Anim } = {}
local nextEnemyIndex = 0

local function motorMap(model: Model): ({ [string]: Motor6D }, { [string]: CFrame })
	local motors: { [string]: Motor6D } = {}
	local base: { [string]: CFrame } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") then
			motors[descendant.Name] = descendant
			base[descendant.Name] = descendant.C0
		end
	end
	return motors, base
end

local function gooBurst(root: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Name = "GooBurst"
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(35, 220, 190), Color3.fromRGB(65, 255, 130))
	emitter.LightEmission = 0.6
	emitter.Lifetime = NumberRange.new(0.3, 0.55)
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = attachment
	emitter:Emit(28)
	task.delay(0.7, function()
		attachment:Destroy()
	end)
end

local function playDeath(model: Model, anim: Anim)
	local ghost = model:Clone()
	ghost.Name = model.Name .. "_Death"
	local ghostRoot = ghost:FindFirstChild("HumanoidRootPart")
	if not ghostRoot or not ghostRoot:IsA("BasePart") then
		ghost:Destroy()
		return
	end

	local transparencies: { [BasePart]: number } = {}
	for _, descendant in ghost:GetDescendants() do
		if descendant:IsA("Humanoid") or descendant:IsA("BillboardGui") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = descendant == ghostRoot
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.Massless = true
			transparencies[descendant] = descendant.Transparency
		end
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
		end
	end

	ghost.Parent = workspace
	local motors, base = motorMap(ghost)
	local startPivot = ghost:GetPivot()
	local drop = math.max(1, anim.Root.Size.Y * 0.3)
	gooBurst(ghostRoot)
	task.spawn(function()
		local started = os.clock()
		while ghost.Parent do
			local elapsed = os.clock() - started
			if elapsed >= EnemyAnimCurves.DeathDuration then
				break
			end
			local collapse =
				EnemyAnimCurves.deathCollapse(elapsed / EnemyAnimCurves.DeathCollapseDuration)
			local dissolve = EnemyAnimCurves.deathDissolve(
				(elapsed - EnemyAnimCurves.DeathCollapseDuration)
					/ EnemyAnimCurves.DeathDissolveDuration
			)
			ghost:PivotTo(
				startPivot
					* CFrame.new(0, -drop * collapse, 0)
					* CFrame.Angles(math.rad(70) * collapse, 0, 0)
			)
			for name, motor in motors do
				local index = tonumber(name:match("(%d+)$"))
				local side = if name:sub(-1) == "L" or (index and index % 2 == 1) then -1 else 1
				motor.C0 = base[name]
					* CFrame.Angles(math.rad(55) * collapse, 0, side * math.rad(25) * collapse)
			end
			for part, transparency in transparencies do
				part.Transparency = transparency + (1 - transparency) * dissolve
			end
			RunService.Heartbeat:Wait()
		end
		ghost:Destroy()
	end)
end

local function flashHit(model: Model, anim: Anim)
	local highlight = model:FindFirstChild("EnemyOutline")
	if not highlight or not highlight:IsA("Highlight") then
		return
	end

	local flash = anim.HitFlash
	if not flash or flash.Highlight ~= highlight then
		flash = {
			Highlight = highlight,
			FillColor = highlight.FillColor,
			FillTransparency = highlight.FillTransparency,
			OutlineColor = highlight.OutlineColor,
			OutlineTransparency = highlight.OutlineTransparency,
			Token = 0,
		}
		anim.HitFlash = flash
	end
	flash.Token += 1
	local token = flash.Token
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.15
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0
	task.delay(EnemyAnimCurves.HitDuration, function()
		if anim.HitFlash ~= flash or flash.Token ~= token then
			return
		end
		if highlight.Parent then
			highlight.FillColor = flash.FillColor
			highlight.FillTransparency = flash.FillTransparency
			highlight.OutlineColor = flash.OutlineColor
			highlight.OutlineTransparency = flash.OutlineTransparency
		end
		anim.HitFlash = nil
	end)
end

local function register(model: Instance)
	if not model:IsA("Model") then
		return
	end
	task.defer(function()
		local root = model:FindFirstChild("HumanoidRootPart")
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid then
			return
		end
		local motors, base = motorMap(model)
		nextEnemyIndex += 1
		local anim: Anim = {
			Root = root,
			Humanoid = humanoid,
			Motors = motors,
			Base = base,
			Phase = math.random() * 6,
			Index = nextEnemyIndex,
			LastHealth = humanoid.Health,
			HitStarted = nil,
			AttackStarted = nil,
			AttackWindup = 0,
			HitFlash = nil,
		}
		anims[model] = anim
		humanoid.HealthChanged:Connect(function(health)
			if health < anim.LastHealth and health > 0 then
				anim.HitStarted = os.clock()
				flashHit(model, anim)
			end
			anim.LastHealth = health
		end)
		humanoid.Died:Connect(function()
			anims[model] = nil
			playDeath(model, anim)
		end)
	end)
end

enemies.ChildAdded:Connect(register)
for _, model in enemies:GetChildren() do
	register(model)
end
enemies.ChildRemoved:Connect(function(model)
	anims[model :: Model] = nil
end)

FX.OnClientEvent:Connect(function(kind: string, data: any)
	if kind ~= "tell" or typeof(data) ~= "table" then
		return
	end
	local model = data.Model
	local anim = if typeof(model) == "Instance" then anims[model :: Model] else nil
	if anim then
		anim.AttackStarted = os.clock()
		anim.AttackWindup = EnemyAnimCurves.attackWindup(tonumber(data.Duration) or 0)
	end
end)

local function set(anim: Anim, name: string, offset: CFrame)
	local motor = anim.Motors[name]
	if motor then
		motor.C0 = anim.Base[name] * offset
	end
end

local frame = 0
RunService.Heartbeat:Connect(function(dt)
	frame += 1
	local now = os.clock()
	local camera = workspace.CurrentCamera
	for model, anim in anims do
		if not model.Parent then
			anims[model] = nil
			continue
		end
		if camera then
			local _, onScreen = camera:WorldToViewportPoint(anim.Root.Position)
			local distance = (camera.CFrame.Position - anim.Root.Position).Magnitude
			if not AnimCull.shouldUpdate(distance, onScreen, anim.Index, frame) then
				continue
			end
		end

		local speed = anim.Root.AssemblyLinearVelocity.Magnitude
		local moving = math.clamp(speed / 12, 0, 1.5)
		anim.Phase = EnemyAnimCurves.walkPhase(anim.Phase, speed, dt)
		local phase = anim.Phase
		local windup, lunge = 0, 0
		if anim.AttackStarted then
			windup, lunge = EnemyAnimCurves.attackPose(now - anim.AttackStarted, anim.AttackWindup)
			if
				now - anim.AttackStarted
				> anim.AttackWindup + EnemyAnimCurves.AttackLungeDuration
			then
				anim.AttackStarted = nil
			end
		end
		local squash = 0
		if anim.HitStarted then
			local hitElapsed = now - anim.HitStarted
			squash = EnemyAnimCurves.hitSquash(hitElapsed / EnemyAnimCurves.HitDuration)
			if hitElapsed >= EnemyAnimCurves.HitDuration then
				anim.HitStarted = nil
			end
		end
		local attackPitch = math.rad(-30) * windup + math.rad(48) * lunge
		local compress = CFrame.new(0, -anim.Root.Size.Y * 0.04 * squash, 0)

		local swing = math.sin(phase) * math.rad(35) * moving
		set(anim, "Hip_L", compress * CFrame.Angles(swing + attackPitch * 0.25, 0, 0))
		set(anim, "Hip_R", compress * CFrame.Angles(-swing + attackPitch * 0.25, 0, 0))
		set(
			anim,
			"Shoulder_L",
			compress * CFrame.Angles(-swing * 0.8 + math.rad(-15) + attackPitch, 0, math.rad(8))
		)
		set(
			anim,
			"Shoulder_R",
			compress * CFrame.Angles(swing * 0.8 + math.rad(-15) + attackPitch, 0, math.rad(-8))
		)
		set(
			anim,
			"Neck",
			compress
				* CFrame.Angles(
					math.sin(phase * 2) * math.rad(6) * moving
						+ math.sin(now * 1.5) * math.rad(3)
						- attackPitch * 0.4,
					math.sin(now * 0.7) * math.rad(10),
					0
				)
		)
		set(anim, "Jaw", CFrame.Angles(math.abs(math.sin(now * 6)) * math.rad(35), 0, 0))

		for index = 1, 8 do
			local name = "Leg_" .. index
			if anim.Motors[name] then
				local legPhase = phase
					+ (if index % 2 == 0 then math.pi else 0)
					+ (index // 2) * 0.6
				set(
					anim,
					name,
					compress
						* CFrame.Angles(
							math.sin(legPhase) * math.rad(30) * moving + attackPitch * 0.35,
							0,
							0
						)
				)
			end
		end
		for index = 1, 4 do
			local name = "Wing_" .. index
			if anim.Motors[name] then
				local sign = if index % 2 == 1 then 1 else -1
				set(
					anim,
					name,
					CFrame.Angles(
						attackPitch * 0.25,
						0,
						sign * math.sin(now * 9 + index) * math.rad(35)
					)
				)
			end
		end
	end
end)
