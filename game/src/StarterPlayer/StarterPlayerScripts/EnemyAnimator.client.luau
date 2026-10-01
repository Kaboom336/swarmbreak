--!strict
-- Procedural animation for every enemy rig, run locally so the server sends nothing extra.
-- Reads Motor6Ds by name (see EnemyBuilder) and drives them from the rig's velocity.
local RunService = game:GetService("RunService")

local enemies = workspace:WaitForChild("Enemies")

type Anim = {
	Root: BasePart,
	Motors: { [string]: Motor6D },
	Base: { [string]: CFrame },
	Phase: number,
	Flying: boolean,
}
local anims: { [Model]: Anim } = {}

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
		anims[model] = {
			Root = root,
			Motors = motors,
			Base = base,
			Phase = math.random() * 6,
			Flying = root.Anchored,
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

RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for model, a in anims do
		if not model.Parent then
			anims[model] = nil
			continue
		end
		local speed = a.Root.AssemblyLinearVelocity.Magnitude
		local moving = math.clamp(speed / 12, 0, 1.5)
		a.Phase += dt * (4 + speed * 0.35)
		local p = a.Phase
		local M, B = a.Motors, a.Base
		local function set(name: string, offset: CFrame)
			local m = M[name]
			if m then
				m.C0 = B[name] * offset
			end
		end
		-- bipeds
		local sw = math.sin(p) * math.rad(35) * moving
		set("Hip_L", CFrame.Angles(sw, 0, 0))
		set("Hip_R", CFrame.Angles(-sw, 0, 0))
		set("Shoulder_L", CFrame.Angles(-sw * 0.8 + math.rad(-15), 0, math.rad(8)))
		set("Shoulder_R", CFrame.Angles(sw * 0.8 + math.rad(-15), 0, math.rad(-8)))
		-- head bob and jaw chatter
		set(
			"Neck",
			CFrame.Angles(
				math.sin(p * 2) * math.rad(6) * moving + math.sin(t * 1.5) * math.rad(3),
				math.sin(t * 0.7) * math.rad(10),
				0
			)
		)
		set("Jaw", CFrame.Angles(math.abs(math.sin(t * 6)) * math.rad(35), 0, 0))
		-- multi-leg walkers (Leg_1..8): alternate pairs
		for i = 1, 8 do
			local name = "Leg_" .. i
			if M[name] then
				local phase = p + (if i % 2 == 0 then math.pi else 0) + (i // 2) * 0.6
				set(name, CFrame.Angles(math.sin(phase) * math.rad(30) * moving, 0, 0))
			end
		end
		-- wings: flap
		for i = 1, 4 do
			local name = "Wing_" .. i
			if M[name] then
				local sign = if i % 2 == 1 then 1 else -1
				set(name, CFrame.Angles(0, 0, sign * math.sin(t * 9 + i) * math.rad(35)))
			end
		end
	end
end)
