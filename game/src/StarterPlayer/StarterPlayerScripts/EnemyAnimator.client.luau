--!strict
-- Procedural locomotion and combat animation for every enemy rig.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AnimCull = require(ReplicatedStorage.Shared.AnimCull)
local AnimCurves = require(ReplicatedStorage.Shared.AnimCurves)
local EnemyAnimCurves = require(ReplicatedStorage.Shared.EnemyAnimCurves)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local FX = remotes:WaitForChild("FX") :: RemoteEvent
local enemies = workspace:WaitForChild("Enemies")

type Anim = {
	Root: BasePart,
	Humanoid: Humanoid,
	TypeName: string,
	Motors: { [string]: Motor6D },
	Base: { [string]: CFrame },
	Phase: number,
	Index: number,
	LastHealth: number,
	HitStarted: number?,
	AttackStarted: number?,
	AttackWindup: number,
	HitFlash: HitFlash?,
	RigMode: boolean,
	Eyes: { BasePart },
	EyeColors: { [BasePart]: Color3 },
	Sac: BasePart?,
	SacSize: Vector3?,
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

local function rigParts(model: Model): ({ BasePart }, { [BasePart]: Color3 }, BasePart?)
	local eyes = {}
	local colors = {}
	local sac = nil
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant.Name == "Eye_Glow" then
				table.insert(eyes, descendant)
				colors[descendant] = descendant.Color
			elseif descendant.Name == "Sac" then
				sac = descendant
			end
		end
	end
	return eyes, colors, sac
end

local function targetYaw(root: BasePart): number
	local nearestPosition = nil
	local nearestDistance = math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local target = character and character:FindFirstChild("HumanoidRootPart")
		if target and target:IsA("BasePart") then
			local distance = (target.Position - root.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestPosition = target.Position
			end
		end
	end
	if not nearestPosition then
		return 0
	end
	local localTarget = root.CFrame:PointToObjectSpace(nearestPosition)
	return math.clamp(math.atan2(-localTarget.X, -localTarget.Z), math.rad(-20), math.rad(20))
end

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

local function playDeath(model: Model, anim: Anim)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
		end
	end
	local goo = Color3.fromRGB(Theme.Goo[1], Theme.Goo[2], Theme.Goo[3])
	ClientFX.deathGhost(model, goo)
	ClientFX.emit("DeathBurst", anim.Root.Position, 28)
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
	task.delay(AnimCurves.HitFlashDuration, function()
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
		local rigMode = model:GetAttribute("RigMode") == true
		local eyes, eyeColors, sac = rigParts(model)
		nextEnemyIndex += 1
		local anim: Anim = {
			Root = root,
			Humanoid = humanoid,
			TypeName = (model:GetAttribute("TypeName") :: string?) or "Walker",
			Motors = motors,
			Base = base,
			Phase = math.random() * 6,
			Index = nextEnemyIndex,
			LastHealth = humanoid.Health,
			HitStarted = nil,
			AttackStarted = nil,
			AttackWindup = 0,
			HitFlash = nil,
			RigMode = rigMode,
			Eyes = eyes,
			EyeColors = eyeColors,
			Sac = sac,
			SacSize = if sac then sac.Size else nil,
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
			for _, eye in anim.Eyes do
				eye.Color = anim.EyeColors[eye]:Lerp(Color3.new(0, 0, 0), 0.6)
			end
			task.defer(function()
				local freezeUntil = model:GetAttribute("ClientHitstopUntil") or os.clock()
				task.delay(math.max(0, freezeUntil - os.clock()), function()
					anims[model] = nil
					if model.Parent then
						playDeath(model, anim)
					end
				end)
			end)
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
		if (model:GetAttribute("ClientHitstopUntil") or 0) > now then
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
		local profile = AnimCurves.enemyWalkProfileFor(anim.TypeName)
		anim.Phase = AnimCurves.enemyWalkPhase(anim.Phase, speed, dt, anim.TypeName)
		local phase = anim.Phase
		local windup, lunge = 0, 0
		if anim.AttackStarted then
			local attack = AnimCurves.enemyAttackAt(now - anim.AttackStarted, anim.AttackWindup)
			windup, lunge = attack.Pull, attack.Lunge
			if
				now - anim.AttackStarted
				> anim.AttackWindup
					+ AnimCurves.AttackStrikeDuration
					+ AnimCurves.AttackRecoveryDuration
			then
				anim.AttackStarted = nil
			end
		end
		local squash = 0
		local flinchDegrees = 0
		if anim.HitStarted then
			local hitElapsed = now - anim.HitStarted
			squash = AnimCurves.enemyHitSquash(hitElapsed / EnemyAnimCurves.HitDuration)
			flinchDegrees = AnimCurves.enemyHitFlinch(hitElapsed / EnemyAnimCurves.HitDuration)
			if hitElapsed >= EnemyAnimCurves.HitDuration then
				anim.HitStarted = nil
			end
		end
		local attackPitch = math.rad(-30) * windup + math.rad(48) * lunge + math.rad(flinchDegrees)
		local breathing = if anim.Humanoid.MoveDirection.Magnitude <= 0.05
			then AnimCurves.idleBreath(now)
			else math.sin(phase * 2) * 0.02 * profile.BobScale * moving
		local compress =
			CFrame.new(0, anim.Root.Size.Y * breathing - anim.Root.Size.Y * 0.04 * squash, 0)

		local swing = math.sin(phase) * math.rad(profile.SwingDegrees) * moving
		if anim.RigMode then
			local rootMotion = CFrame.new(
				0,
				if anim.TypeName == "Flyer" then math.sin(now * math.pi * 2) * 0.5 else 0,
				windup * 0.6 - lunge * 1.2
			)
			set(anim, "RootWeld", rootMotion)
			for index = 1, 8 do
				local name = "Hip_" .. index
				if anim.Motors[name] then
					local legPhase = phase + EnemyAnimCurves.rigGaitPhase(index)
					local liftDegrees = math.clamp(profile.SwingDegrees, 20, 30)
					local lift = math.sin(legPhase) * math.rad(liftDegrees) * moving
					set(anim, name, CFrame.Angles(lift + attackPitch * 0.25, 0, 0))
				end
			end
			local neckBob = math.sin(phase * 2) * math.rad(6) * moving
			set(anim, "Neck", CFrame.Angles(neckBob - attackPitch * 0.4, targetYaw(anim.Root), 0))
			local flap = math.sin(now * math.pi * 2 * 14) * math.rad(35)
			set(anim, "WingJoint_L", CFrame.Angles(flap, 0, 0))
			set(anim, "WingJoint_R", CFrame.Angles(-flap, 0, 0))
			if anim.Sac and anim.SacSize then
				anim.Sac.Size = anim.SacSize * (1 + math.sin(windup * math.pi) * 0.25)
			end
			for _, eye in anim.Eyes do
				local baseColor = anim.EyeColors[eye]
				eye.Color = baseColor:Lerp(Color3.new(1, 1, 1), windup * 0.35)
			end
		end
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
							math.sin(legPhase) * math.rad(profile.SwingDegrees * (30 / 35)) * moving
								+ attackPitch * 0.35,
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
