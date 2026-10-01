--!strict
-- Enemy spawning and chase / ranged AI. One Heartbeat loop for all enemies.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Theme = require(ReplicatedStorage.Shared.Theme)
local EnemyBuilder = require(script.Parent.EnemyBuilder)
local FX = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FX") :: RemoteEvent

type EnemyDef = Enemies.EnemyDef

local folder = Instance.new("Folder")
folder.Name = "Enemies"
folder.Parent = workspace

type Live = {
	Model: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Def: EnemyDef,
	Speed: number,
	Damage: number,
	AttackCooldown: number,
	SummonCooldown: number,
	OnDeath: (Player?) -> (),
	LastHitBy: Player?,
}

local live: { [Model]: Live } = {}
local EnemyAI = {}
EnemyAI.OnSummon = nil :: ((string, CFrame) -> ())?

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function nearestPlayerRoot(pos: Vector3): (BasePart?, number)
	local best: BasePart? = nil
	local bestDist = math.huge
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hum and root and hum.Health > 0 then
			local d = (root.Position - pos).Magnitude
			if d < bestDist then
				best = root
				bestDist = d
			end
		end
	end
	return best, bestDist
end

local function makeHealthBar(root: BasePart, hum: Humanoid, boss: boolean)
	if boss then
		return -- boss HP goes on the HUD
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(4, 0, 0.4, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, root.Size.Y / 2 + 1.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	back.BorderSizePixel = 0
	back.Parent = bb
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	fill.BorderSizePixel = 0
	fill.Parent = back
	hum.HealthChanged:Connect(function(h)
		fill.Size = UDim2.fromScale(math.clamp(h / hum.MaxHealth, 0, 1), 1)
	end)
	bb.Parent = root
end

local function rangedShot(e: Live, target: BasePart)
	local from = e.Root.Position + Vector3.new(0, e.Root.Size.Y / 4, 0)
	local to = target.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { e.Model, folder }
	local hit = workspace:Raycast(from, to - from, params)
	if not hit or not hit.Instance:IsDescendantOf(target.Parent :: Instance) then
		return -- no line of sight
	end
	local typeName = e.Model:GetAttribute("TypeName") :: string
	local accent = (Theme.Enemy[typeName] or Theme.Enemy.Walker).Accent
	FX:FireAllClients("spit", { From = from, To = to, Color = accent })
	local hum = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:TakeDamage(e.Damage)
	end
end

-- Ground enemies path around towers and walls; re-plan every 0.4 s, jump when stuck.
local function groundMover(e: Live)
	local hum = e.Humanoid
	local def = e.Def
	local path = PathfindingService:CreatePath({
		AgentRadius = math.max(e.Root.Size.X, e.Root.Size.Z) / 2,
		AgentHeight = e.Root.Size.Y,
		AgentCanJump = true,
		WaypointSpacing = 6,
	})
	local lastPos = e.Root.Position
	local stuckTime = 0
	while hum.Health > 0 and e.Model.Parent do
		-- Nature poison: slowed while SlowUntil (set by CombatEffects) is in the future
		local slowUntil = (e.Model:GetAttribute("SlowUntil") :: number?) or 0
		hum.WalkSpeed = if os.clock() < slowUntil then e.Speed * 0.7 else e.Speed
		local target, dist = nearestPlayerRoot(e.Root.Position)
		if target then
			if def.Ranged and dist < (def.Range or 40) * 0.8 then
				hum:MoveTo(e.Root.Position) -- hold position and shoot
			elseif dist < 10 then
				hum:MoveTo(target.Position) -- close: go straight
			else
				local ok = pcall(path.ComputeAsync, path, e.Root.Position, target.Position)
				local waypoints = if ok and path.Status == Enum.PathStatus.Success
					then path:GetWaypoints()
					else nil
				if waypoints and #waypoints >= 2 then
					local wp = waypoints[2]
					if wp.Action == Enum.PathWaypointAction.Jump then
						hum.Jump = true
					end
					hum:MoveTo(wp.Position)
				else
					hum:MoveTo(target.Position)
				end
			end
		end
		-- stuck detection: barely moved while trying to move -> jump
		local moved = (e.Root.Position - lastPos).Magnitude
		lastPos = e.Root.Position
		if moved < 0.5 and target and dist > 6 then
			stuckTime += 0.4
			if stuckTime > 1.2 then
				hum.Jump = true
				stuckTime = 0
			end
		else
			stuckTime = 0
		end
		task.wait(0.4)
	end
end

function EnemyAI.spawn(
	typeName: string,
	cf: CFrame,
	healthScale: number,
	damageScale: number,
	mutationId: string,
	onDeath: (Player?) -> ()
): Model
	local def = Enemies.Defs[typeName]
	local stats = Mutations.apply({
		EnemySpeed = def.Speed,
		EnemyHealth = def.Health * healthScale,
		BossScale = 1,
	}, mutationId)
	local size = v3(def.Size) * (if def.Boss then stats.BossScale else 1)
	local rig = EnemyBuilder.build(typeName, size, cf)
	local model = rig.Model
	local root = rig.Root
	root.Anchored = def.Flying
	root.CanCollide = not def.Flying

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = rig.HipHeight
	hum.MaxHealth = math.floor(stats.EnemyHealth + 0.5)
	hum.Health = hum.MaxHealth
	hum.WalkSpeed = stats.EnemySpeed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.AutoRotate = true
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.Parent = model

	model:SetAttribute("Boss", def.Boss == true)
	model:SetAttribute("TypeName", typeName)
	model:SetAttribute("LastHitBy", 0)
	makeHealthBar(root, hum, def.Boss == true)
	model.Parent = folder
	if not def.Flying then
		root:SetNetworkOwner(nil) -- server simulates enemies
	end

	local e: Live = {
		Model = model,
		Root = root,
		Humanoid = hum,
		Def = def,
		Speed = stats.EnemySpeed,
		Damage = math.floor(def.Damage * damageScale + 0.5),
		AttackCooldown = 1,
		SummonCooldown = def.SummonEvery or 0,
		OnDeath = onDeath,
		LastHitBy = nil,
	}
	live[model] = e
	if not def.Flying then
		task.spawn(groundMover, e)
	end

	model:GetAttributeChangedSignal("LastHitBy"):Connect(function()
		local id = model:GetAttribute("LastHitBy") :: number
		e.LastHitBy = Players:GetPlayerByUserId(id)
	end)

	hum.Died:Connect(function()
		live[model] = nil
		onDeath(e.LastHitBy)
		local accent = (Theme.Enemy[typeName] or Theme.Enemy.Walker).Accent
		FX:FireAllClients("death", {
			Position = root.Position,
			Size = size.Magnitude,
			Color = accent,
			Boss = def.Boss == true,
		})
		-- let the pieces fly for a moment, then remove
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p ~= root then
				p.Anchored = false
				p.CanCollide = true
				p.Massless = false
				p.AssemblyLinearVelocity = (p.Position - root.Position).Unit * 25
					+ Vector3.new(0, 20, 0)
			end
		end
		for _, m in model:GetDescendants() do
			if m:IsA("Motor6D") or m:IsA("WeldConstraint") then
				m:Destroy()
			end
		end
		task.delay(1.2, function()
			model:Destroy()
		end)
	end)
	return model
end

function EnemyAI.aliveCount(): number
	local n = 0
	for _ in live do
		n += 1
	end
	return n
end

function EnemyAI.clearAll()
	live = {}
	folder:ClearAllChildren()
end

RunService.Heartbeat:Connect(function(dt)
	for model, e in live do
		if e.Humanoid.Health <= 0 or not model.Parent then
			continue
		end
		local target, dist = nearestPlayerRoot(e.Root.Position)
		if not target then
			continue
		end
		local def = e.Def
		local flat = (target.Position - e.Root.Position) * Vector3.new(1, 0, 1)
		local horizontalDist = flat.Magnitude
		if def.Flying then
			local hover = if def.Ranged then math.min((def.Range or 40) * 0.25, 14) else 3
			local goal = target.Position + Vector3.new(0, hover, 0)
			local dir = goal - e.Root.Position
			if dir.Magnitude > 1 then
				local slowUntil = (e.Model:GetAttribute("SlowUntil") :: number?) or 0
				local speed = if os.clock() < slowUntil then e.Speed * 0.7 else e.Speed
				local step = math.min(speed * dt, dir.Magnitude)
				e.Root.CFrame = CFrame.lookAt(e.Root.Position + dir.Unit * step, target.Position)
			end
		end

		e.AttackCooldown -= dt
		if e.AttackCooldown <= 0 then
			if def.Ranged then
				if dist <= (def.Range or 40) then
					e.AttackCooldown = def.AttackCooldown or 2
					rangedShot(e, target)
				end
			elseif horizontalDist < (e.Root.Size.Magnitude / 2 + 3) then
				e.AttackCooldown = 1
				local hum = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(e.Damage)
				end
			end
		end

		if def.Summons and def.SummonEvery then
			e.SummonCooldown -= dt
			if e.SummonCooldown <= 0 then
				e.SummonCooldown = def.SummonEvery
				local onSummon = EnemyAI.OnSummon
				if onSummon then
					-- deferred: never insert into `live` while iterating it
					task.defer(
						onSummon,
						def.Summons,
						e.Root.CFrame * CFrame.new(0, 0, e.Root.Size.Z)
					)
				end
			end
		end
	end
end)

return EnemyAI
