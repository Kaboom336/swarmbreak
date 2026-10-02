--!strict
-- Procedural animation for every enemy rig, run locally so the server sends nothing extra.
-- Reads Motor6Ds by name (see EnemyBuilder) and drives them from the rig's velocity.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimCull = require(ReplicatedStorage.Shared.AnimCull)
local ClientFX = require(script.Parent.ClientFX)

local enemies = workspace:WaitForChild("Enemies")

type Anim = {
	Root: BasePart,
	Motors: { [string]: Motor6D },
	Base: { [string]: CFrame },
	Phase: number,
	Flying: boolean,
	Index: number,
}
local anims: { [Model]: Anim } = {}
local nextEnemyIndex = 0

local function register(model: Instance)
	if not model:IsA("Model") then
		return
	end
	task.defer(function()
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		local motors: { [string]: Motor6D } = {}
		local base: { [string]: CFrame } = {}
		for _, d in model:GetDescendants() do
			if d:IsA("Motor6D") then
				motors[d.Name] = d
				base[d.Name] = d.C0
			end
		end
		nextEnemyIndex += 1
		anims[model] = {
			Root = root,
			Motors = motors,
			Base = base,
			Phase = math.random() * 6,
			Flying = root.Anchored,
			Index = nextEnemyIndex,
		}
	end)
end

enemies.ChildAdded:Connect(register)
for _, m in enemies:GetChildren() do
	register(m)
end
enemies.ChildRemoved:Connect(function(m)
	anims[m :: Model] = nil
end)

local function set(a: Anim, name: string, offset: CFrame)
	local motor = a.Motors[name]
	if motor then
		motor.C0 = a.Base[name] * offset
	end
end

local frame = 0
RunService.Heartbeat:Connect(function(dt)
	frame += 1
	local animationEvery = math.max(1, math.floor(1 / ClientFX.getQualityBudget().Animation + 0.5))
	local t = os.clock()
	local camera = workspace.CurrentCamera
	for model, a in anims do
		if not model.Parent then
			anims[model] = nil
			continue
		end
		if (frame + a.Index) % animationEvery ~= 0 then
			continue
		end
		if camera then
			local _, onScreen = camera:WorldToViewportPoint(a.Root.Position)
			local distance = (camera.CFrame.Position - a.Root.Position).Magnitude
			if not AnimCull.shouldUpdate(distance, onScreen, a.Index, frame) then
				continue
			end
		end
		local speed = a.Root.AssemblyLinearVelocity.Magnitude
		local moving = math.clamp(speed / 12, 0, 1.5)
		a.Phase += dt * animationEvery * (4 + speed * 0.35)
		local p = a.Phase
		local M = a.Motors
		-- bipeds
		local sw = math.sin(p) * math.rad(35) * moving
		set(a, "Hip_L", CFrame.Angles(sw, 0, 0))
		set(a, "Hip_R", CFrame.Angles(-sw, 0, 0))
		set(a, "Shoulder_L", CFrame.Angles(-sw * 0.8 + math.rad(-15), 0, math.rad(8)))
		set(a, "Shoulder_R", CFrame.Angles(sw * 0.8 + math.rad(-15), 0, math.rad(-8)))
		-- head bob and jaw chatter
		set(
			a,
			"Neck",
			CFrame.Angles(
				math.sin(p * 2) * math.rad(6) * moving + math.sin(t * 1.5) * math.rad(3),
				math.sin(t * 0.7) * math.rad(10),
				0
			)
		)
		set(a, "Jaw", CFrame.Angles(math.abs(math.sin(t * 6)) * math.rad(35), 0, 0))
		-- multi-leg walkers (Leg_1..8): alternate pairs
		for i = 1, 8 do
			local name = "Leg_" .. i
			if M[name] then
				local phase = p + (if i % 2 == 0 then math.pi else 0) + (i // 2) * 0.6
				set(a, name, CFrame.Angles(math.sin(phase) * math.rad(30) * moving, 0, 0))
			end
		end
		-- wings: flap
		for i = 1, 4 do
			local name = "Wing_" .. i
			if M[name] then
				local sign = if i % 2 == 1 then 1 else -1
				set(a, name, CFrame.Angles(0, 0, sign * math.sin(t * 9 + i) * math.rad(35)))
			end
		end
	end
end)
