--!strict
-- Enemy spawning and chase / ranged AI. One Heartbeat loop for all enemies.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local EnemyTells = require(ReplicatedStorage.Shared.EnemyTells)
local Fit = require(ReplicatedStorage.Shared.Fit)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local SwarmlingStep = require(ReplicatedStorage.Shared.SwarmlingStep)
local Theme = require(ReplicatedStorage.Shared.Theme)
local EnemyBuilder = require(script.Parent.EnemyBuilder)
local EnemyIndex = require(script.Parent.EnemyIndex)
local FxRouter = require(script.Parent.FxRouter)

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
	OnDeath: (Player?, Vector3) -> (),
	LastHitBy: Player?,
}

local live: { [Model]: Live } = {}
type SwarmLive = {
	Model: Model,
	Root: BasePart,
	Def: EnemyDef,
	Speed: number,
	Damage: number,
	AttackCooldown: number,
	OnDeath: (Player?, Vector3) -> (),
	LastHitBy: Player?,
}
local swarm: { [Model]: SwarmLive } = {}
local EnemyAI = {}
EnemyAI.OnSummon = nil :: ((string, CFrame) -> ())?

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function playerFromRoot(root: BasePart): Player?
	local character = root.Parent
	return if character and character:IsA("Model")
		then Players:GetPlayerFromCharacter(character)
		else nil
end

local function nearestPlayerRoot(pos: Vector3): (BasePart?, number)
	local best: BasePart? = nil
	local bestDist = math.huge
	for _, plr in Players:GetPlayers() do
		if
			plr:GetAttribute("InArena") == false
			or plr:GetAttribute("WaitingForIntermission") == true
		then
			continue -- in the lobby or queued for the next intermission
		end
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

local function eligiblePlayerRoots(): { BasePart }
	local roots = {}
	for _, plr in Players:GetPlayers() do
		if
			plr:GetAttribute("InArena") == false
			or plr:GetAttribute("WaitingForIntermission") == true
		then
			continue
		end
		local character = plr.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			table.insert(roots, root)
		end
	end
	return roots
end

local function makeHealthBar(model: Model, root: BasePart, hum: Humanoid, boss: boolean)
	if boss then
		return -- boss HP goes on the HUD
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(4, 0, 0.4, 0)
	local head = model:FindFirstChild("Head", true)
	local adornee = if head and head:IsA("BasePart") then head else root
	bb.Adornee = adornee
	bb.StudsOffsetWorldSpace = Vector3.new(0, adornee.Size.Y / 2 + 1, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Enabled = false
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
	local damaged = false
	hum.HealthChanged:Connect(function(h)
		if h < hum.MaxHealth then
			damaged = true
		end
		bb.Enabled = damaged and h > 0
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
	local targetPlayer = playerFromRoot(target)
	FxRouter.emit("spit", from, { From = from, To = to, Color = accent }, targetPlayer)
	local hum = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:TakeDamage(e.Damage)
	end
end

local function queueAttack(e: Live, target: BasePart, radius: number, attack: (Vector3) -> ())
	local typeName = e.Model:GetAttribute("TypeName") :: string
	local tell = EnemyTells.Defs[typeName]
	local impactPosition = target.Position
	local timeline = EnemyTells.attackTimeline(tell, os.clock())
	FxRouter.emit("tell", e.Root.Position, {
		Model = e.Model,
		Position = e.Root.Position,
		Sound = tell.SoundKey,
		GlowPulse = tell.GlowPulse,
		GlowColor = tell.GlowColor,
		Duration = timeline.DamageAt - timeline.TellStartsAt,
		GroundPosition = if timeline.ShowGroundCircle
			then impactPosition - Vector3.new(0, 3, 0)
			else nil,
		Radius = radius,
	}, playerFromRoot(target))

	local function landAttack()
		if e.Humanoid.Health > 0 and e.Model.Parent and target.Parent then
			attack(impactPosition)
		end
	end
	local delaySeconds = math.max(0, timeline.DamageAt - os.clock())
	if delaySeconds == 0 then
		landAttack()
	else
		task.delay(delaySeconds, landAttack)
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

local function spawnSwarmling(
	typeName: string,
	cf: CFrame,
	healthScale: number,
	damageScale: number,
	mutationId: string,
	onDeath: (Player?, Vector3) -> ()
): Model
	local def = Enemies.Defs[typeName]
	local stats = Mutations.apply({
		EnemySpeed = def.Speed,
		EnemyHealth = def.Health * healthScale,
		BossScale = 1,
	}, mutationId)
	local fittedSize = Fit.sizeForRelativeHeight(def.Size, def.Scale, 5)
	local rig = EnemyBuilder.build(typeName, v3(fittedSize), cf)
	local model = rig.Model
	local root = rig.Root
	local health = math.floor(stats.EnemyHealth + 0.5)
	root.Anchored = true
	root.CanCollide = false
	model:SetAttribute("Boss", false)
	model:SetAttribute("NoHumanoid", true)
	model:SetAttribute("TypeName", typeName)
	model:SetAttribute("Health", health)
	model:SetAttribute("MaxHealth", health)
	model:SetAttribute("LastHitBy", 0)
	model.Parent = folder

	local enemy: SwarmLive = {
		Model = model,
		Root = root,
		Def = def,
		Speed = stats.EnemySpeed,
		Damage = math.floor(def.Damage * damageScale + 0.5),
		AttackCooldown = 0,
		OnDeath = onDeath,
		LastHitBy = nil,
	}
	swarm[model] = enemy
	EnemyIndex.add(model, root)
	model:GetAttributeChangedSignal("LastHitBy"):Connect(function()
		local id = model:GetAttribute("LastHitBy") :: number
		enemy.LastHitBy = Players:GetPlayerByUserId(id)
	end)
	return model
end

function EnemyAI.spawn(
	typeName: string,
	cf: CFrame,
	healthScale: number,
	damageScale: number,
	mutationId: string,
	onDeath: (Player?, Vector3) -> ()
): Model
	local def = Enemies.Defs[typeName]
	if def.NoHumanoid then
		return spawnSwarmling(typeName, cf, healthScale, damageScale, mutationId, onDeath)
	end
	local stats = Mutations.apply({
		EnemySpeed = def.Speed,
		EnemyHealth = def.Health * healthScale,
		BossScale = 1,
	}, mutationId)
	local fittedSize = Fit.sizeForRelativeHeight(def.Size, def.Scale, 5)
	local size = v3(fittedSize) * (if def.Boss then stats.BossScale else 1)
	local rig = EnemyBuilder.build(typeName, size, cf)
	local model = rig.Model
	local root = rig.Root
	root.Anchored = def.Flying
	root.CanCollide = not def.Flying

	local hum = rig.Humanoid or Instance.new("Humanoid")
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
	makeHealthBar(model, root, hum, def.Boss == true)
	model.Parent = folder
	EnemyBuilder.startLocomotion(rig)
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
	EnemyIndex.add(model, root)
	if not def.Flying then
		task.spawn(groundMover, e)
	end

	model:GetAttributeChangedSignal("LastHitBy"):Connect(function()
		local id = model:GetAttribute("LastHitBy") :: number
		e.LastHitBy = Players:GetPlayerByUserId(id)
	end)

	hum.Died:Connect(function()
		live[model] = nil
		EnemyIndex.remove(model)
		onDeath(e.LastHitBy, root.Position)
		local accent = (Theme.Enemy[typeName] or Theme.Enemy.Walker).Accent
		FxRouter.emit("death", root.Position, {
			Position = root.Position,
			Size = size.Magnitude,
			Color = accent,
			EnemyType = typeName,
			Boss = def.Boss == true,
		}, e.LastHitBy)
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
	for _ in swarm do
		n += 1
	end
	return n
end

function EnemyAI.regularAliveCount(): number
	local count = 0
	for _ in live do
		count += 1
	end
	return count
end

function EnemyAI.swarmlingAliveCount(): number
	local count = 0
	for _ in swarm do
		count += 1
	end
	return count
end

function EnemyAI.damageNoHumanoid(model: Model, damage: number): (boolean, boolean)
	local enemy = swarm[model]
	if not enemy or damage <= 0 or damage ~= damage then
		return false, false
	end
	local health = (model:GetAttribute("Health") :: number?) or 0
	if health <= 0 then
		return false, false
	end
	local remaining = math.max(0, health - damage)
	model:SetAttribute("Health", remaining)
	if remaining > 0 then
		return true, false
	end

	swarm[model] = nil
	EnemyIndex.remove(model)
	local lastHitById = (model:GetAttribute("LastHitBy") :: number?) or 0
	local lastHitBy = Players:GetPlayerByUserId(lastHitById) or enemy.LastHitBy
	enemy.OnDeath(lastHitBy, enemy.Root.Position)
	local accent = (Theme.Enemy.Swarmling).Accent
	FxRouter.emit("death", enemy.Root.Position, {
		Position = enemy.Root.Position,
		Size = enemy.Root.Size.Magnitude,
		Color = accent,
		EnemyType = "Swarmling",
		Boss = false,
	}, lastHitBy)
	model:SetAttribute("Dead", true)
	task.delay(0.6, function()
		model:Destroy()
	end)
	return true, true
end

function EnemyAI.clearAll()
	live = {}
	swarm = {}
	EnemyIndex.clear()
	folder:ClearAllChildren()
end

local function queueSwarmlingAttack(enemy: SwarmLive, target: BasePart)
	local tell = EnemyTells.Defs.Swarmling
	local radius = enemy.Root.Size.Magnitude / 2 + 3
	FxRouter.emit("tell", enemy.Root.Position, {
		Model = enemy.Model,
		Position = enemy.Root.Position,
		Sound = tell.SoundKey,
		GlowPulse = tell.GlowPulse,
		GlowColor = tell.GlowColor,
		Duration = tell.Windup,
		Radius = radius,
	}, playerFromRoot(target))
	task.delay(tell.Windup, function()
		if ((enemy.Model:GetAttribute("Health") :: number?) or 0) <= 0 or not target.Parent then
			return
		end
		local distance = ((target.Position - enemy.Root.Position) * Vector3.new(1, 0, 1)).Magnitude
		local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and distance <= radius + 1 then
			humanoid:TakeDamage(enemy.Damage)
		end
	end)
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
			local typeName = e.Model:GetAttribute("TypeName") :: string
			if def.Ranged then
				if dist <= (def.Range or 40) then
					e.AttackCooldown = def.AttackCooldown or 2
					local tellRadius = if def.Boss then 10 else 6
					queueAttack(e, target, tellRadius, function(impactPosition)
						if EnemyTells.Defs[typeName].GroundAoeCircle then
							local moved = (target.Position - impactPosition) * Vector3.new(1, 0, 1)
							if moved.Magnitude <= tellRadius then
								rangedShot(e, target)
							end
						else
							rangedShot(e, target)
						end
					end)
				end
			elseif horizontalDist < (e.Root.Size.Magnitude / 2 + 3) then
				e.AttackCooldown = 1
				local function hitTarget(_impactPosition: Vector3?)
					local currentDistance = ((target.Position - e.Root.Position) * Vector3.new(
						1,
						0,
						1
					)).Magnitude
					local hum = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
					if hum and currentDistance < (e.Root.Size.Magnitude / 2 + 4) then
						hum:TakeDamage(e.Damage)
					end
				end
				queueAttack(e, target, if def.Boss then 10 else 6, hitTarget)
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

	local playerRoots = eligiblePlayerRoots()
	if #playerRoots == 0 then
		return
	end
	local targets = table.create(#playerRoots)
	for _, root in playerRoots do
		table.insert(targets, { x = root.Position.X, y = root.Position.Y, z = root.Position.Z })
	end
	local units = {}
	local roots = {}
	local entries = {}
	for model, enemy in swarm do
		if model.Parent and ((model:GetAttribute("Health") :: number?) or 0) > 0 then
			local slowUntil = (model:GetAttribute("SlowUntil") :: number?) or 0
			local speed = if os.clock() < slowUntil then enemy.Speed * 0.7 else enemy.Speed
			table.insert(units, {
				Position = {
					x = enemy.Root.Position.X,
					y = enemy.Root.Position.Y,
					z = enemy.Root.Position.Z,
				},
				Speed = speed,
			})
			table.insert(roots, enemy.Root)
			table.insert(entries, enemy)
		end
	end
	local transforms = SwarmlingStep.step(units, targets, dt)
	local cframes = table.create(#transforms)
	for index, transform in transforms do
		local position = Vector3.new(transform.x, transform.y, transform.z)
		local look = Vector3.new(transform.lookX, 0, transform.lookZ)
		table.insert(cframes, CFrame.lookAt(position, position + look))

		local enemy = entries[index]
		enemy.AttackCooldown -= dt
		local target, distance = nearestPlayerRoot(position)
		if
			target
			and distance <= enemy.Root.Size.Magnitude / 2 + 3
			and enemy.AttackCooldown <= 0
		then
			enemy.AttackCooldown = 1
			queueSwarmlingAttack(enemy, target)
		end
	end
	if #roots > 0 then
		workspace:BulkMoveTo(roots, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)

return EnemyAI
