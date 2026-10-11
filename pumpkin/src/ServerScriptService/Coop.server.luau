--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
if Config.GameplayMode ~= "Coop" then
	return
end
local Rules = require(Shared:WaitForChild("CoopRules"))
local Data = require(ServerStorage:WaitForChild("Data"))
local scene = require(ServerStorage:WaitForChild("CoopScene")).build()
local remote = Instance.new("RemoteEvent")
remote.Name = "CoopAction"
remote.Parent = ReplicatedStorage
local wave = Rules.newWave(#scene.targets)
local carries: { [Player]: BasePart } = {}
local offers: { [Player]: BasePart } = {}
local flights: { [Player]: any } = {}
local limits: { [Player]: number } = {}
local patchReady: { [BasePart]: number } = {}
local resetAt: number? = nil
local closing = false
local originals: { [BasePart]: number } = {}
for id, target in scene.targets do
	target:SetAttribute("TargetId", id)
	for _, item in { target, unpack(target:GetDescendants()) } do
		if item:IsA("BasePart") then
			originals[item] = item.Transparency
		end
	end
end
local function alive(player: Player): BasePart?
	local char = player.Character
	local humanoid = if char then char:FindFirstChildOfClass("Humanoid") else nil
	local root = if char then char:FindFirstChild("HumanoidRootPart") else nil
	return if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then root else nil
end
local function near(player: Player, part: BasePart): boolean
	local root = alive(player)
	return root ~= nil and (root.Position - part.Position).Magnitude <= 16
end
local function allowed(player: Player): boolean
	local now = os.clock()
	if now - (limits[player] or -100) < 0.15 then
		return false
	end
	limits[player] = now
	return Data.get(player) ~= nil and not closing
end
local function snapshot(player: Player, message: string?, panel: string?)
	local p = Data.get(player)
	if not p then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local gold = if leaderstats then leaderstats:FindFirstChild("Gold") else nil
	if gold and gold:IsA("IntValue") then
		gold.Value = p.Gold
	end
	remote:FireClient(player, "state", {
		gold = p.Gold,
		pumpkinRank = p.PumpkinRank,
		launcherRank = p.LauncherRank,
		reducedEffects = p.ReducedEffects,
		sfxVolume = p.SFXVolume,
		carrying = carries[player] ~= nil,
		flying = flights[player] ~= nil,
		wave = wave.number,
		remaining = wave.remaining,
		count = wave.count,
		message = message,
		panel = panel,
	})
end
local function broadcast(message: string?)
	for _, player in Players:GetPlayers() do
		snapshot(player, message)
	end
	-- Useful replicated progress for world signs and joiners.
	scene.progress:SetAttribute("Wave", wave.number)
	scene.progress:SetAttribute("Remaining", wave.remaining)
	for _, descendant in scene.progress:GetDescendants() do
		if descendant:IsA("TextLabel") and descendant.Name == "ProgressText" then
			descendant.Text = "WAVE " .. wave.number .. " • " .. wave.remaining .. " GHOSTS"
		end
	end
end
local function clearCarry(player: Player)
	if carries[player] then
		carries[player]:Destroy()
	end
	carries[player] = nil
end
local function clearFlight(player: Player)
	local flight = flights[player]
	if flight then
		flight.part:Destroy()
	end
	flights[player] = nil
end
local function pumpkin(diameter: number): BasePart
	local part = Instance.new("Part")
	part.Name = "CoopPumpkin"
	part.Color = Color3.fromRGB(240, 118, 30)
	part.Size = Vector3.one * diameter
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Massless = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId, mesh.TextureId = Config.PumpkinMeshId, Config.PumpkinTextureId
	mesh.Scale = Vector3.one * diameter * Config.PumpkinMeshScale
	mesh.Parent = part
	part.Parent = workspace
	return part
end
local function showGhost(target: BasePart, visible: boolean)
	target:SetAttribute("GhostAlive", visible)
	for _, item in { target, unpack(target:GetDescendants()) } do
		if item:IsA("BasePart") then
			item.Transparency = if visible then originals[item] or 0 else 1
		end
		if item:IsA("ParticleEmitter") or item:IsA("PointLight") then
			item.Enabled = visible
		end
	end
end
local function prompt(part: BasePart, action: string, object: string, callback: (Player) -> ())
	local p = Instance.new("ProximityPrompt")
	p.ActionText, p.ObjectText = action, object
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.HoldDuration = 0.15
	p.Parent = part
	p.Triggered:Connect(function(player)
		if allowed(player) and near(player, part) then
			callback(player)
		end
	end)
end
for _, patch in scene.patches do
	prompt(patch, "Harvest", "Pumpkin patch", function(player)
		if carries[player] then
			snapshot(player, "You already have a pumpkin. Take it to a launcher.")
			return
		end
		if flights[player] then
			snapshot(player, "Your pumpkin is still flying!")
			return
		end
		if os.clock() < (patchReady[patch] or 0) then
			snapshot(player, "Growing… try another patch.")
			return
		end
		local root = alive(player)
		local p = Data.get(player)
		if not root or not p then
			return
		end
		patchReady[patch] = os.clock() + 2
		local diameter = Rules.diameter(p.PumpkinRank)
		local carry = pumpkin(diameter)
		carry.CFrame = root.CFrame * CFrame.new(0, 0.5, -(2 + diameter / 2))
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = root, carry
		weld.Parent = carry
		carries[player] = carry
		snapshot(player, "Pumpkin harvested! Carry it to a catapult.")
	end)
end
for _, launcher in scene.launchers do
	prompt(launcher, "Aim pumpkin", "Cooperative catapult", function(player)
		if not carries[player] then
			snapshot(player, "Harvest a pumpkin first.")
			return
		end
		offers[player] = launcher
		snapshot(player, "Aim for the ghost crowd. Adjust your shot!", "launcher")
	end)
end
prompt(scene.shop, "Upgrade", "Gold workshop", function(player)
	snapshot(player, "Spend ghost gold on bigger pumpkins or stronger launches.", "shop")
end)
local function hit(player: Player, id: number)
	if closing then
		return
	end
	if not Rules.hit(wave, id, player.UserId) then
		return
	end
	showGhost(scene.targets[id], false)
	remote:FireAllClients("hitFx", { position = scene.targets[id].Position, owner = player.UserId })
	local p = Data.get(player)
	if p then
		p.Gold += 5
		Data.markDirty(player)
	end
	if wave.remaining == 0 then
		for userId, bonus in Rules.bonus(wave) do
			local contributor = Players:GetPlayerByUserId(userId)
			local profile = if contributor then Data.get(contributor) else nil
			if profile and contributor then
				profile.Gold += bonus
				Data.markDirty(contributor)
			end
		end
		resetAt = os.clock() + 3
		broadcast("Wave cleared together! Contributors earned +15 gold.")
	else
		broadcast(player.DisplayName .. " hit a ghost! +5 gold")
	end
end
remote.OnServerEvent:Connect(function(player, action, payload)
	if not allowed(player) then
		return
	end
	if action == "snapshot" then
		snapshot(player)
		return
	end
	if action == "cancel" then
		offers[player] = nil
		snapshot(player)
		return
	end
	if action == "upgrade" then
		if not near(player, scene.shop) then
			snapshot(player, "Walk to the workshop to upgrade.")
			return
		end
		local p = Data.get(player)
		if not p then
			return
		end
		local ok, message = Rules.upgrade(p, payload)
		if ok then
			Data.markDirty(player)
			if carries[player] and payload == "pumpkin" then
				local carry = carries[player]
				local size = Rules.diameter(p.PumpkinRank)
				carry.Size = Vector3.one * size
				local mesh = carry:FindFirstChildOfClass("SpecialMesh")
				if mesh then
					mesh.Scale = Vector3.one * size * Config.PumpkinMeshScale
				end
			end
		end
		snapshot(player, message)
		return
	end
	if action ~= "launch" then
		return
	end
	local control = Rules.controls(payload)
	local launcher, carry = offers[player], carries[player]
	if not control then
		snapshot(player, "Invalid launch controls.")
		return
	end
	if not launcher or not near(player, launcher) or not carry or flights[player] then
		offers[player] = nil
		snapshot(player, "Bring a pumpkin to a catapult again.", "close")
		return
	end
	if resetAt then
		snapshot(player, "New ghost wave arriving…")
		return
	end
	local p = Data.get(player)
	if not p then
		return
	end
	local direction = (launcher.CFrame * CFrame.Angles(0, math.rad(control.yaw), 0)).LookVector
	direction = Vector3.new(direction.X, 0, direction.Z).Unit
	local origin = launcher.Position + Vector3.yAxis * 5 + direction * 4
	local angle = math.rad(control.angle)
	local speed = (75 + p.LauncherRank * 7) * control.power
	local velocity = (direction * math.cos(angle) + Vector3.yAxis * math.sin(angle)) * speed
	clearCarry(player)
	offers[player] = nil
	local projectile = pumpkin(Rules.diameter(p.PumpkinRank))
	projectile.Anchored = true
	projectile.Position = origin
	flights[player] = {
		part = projectile,
		origin = origin,
		velocity = velocity,
		elapsed = 0,
		last = origin,
		wave = wave.number,
		hits = 0,
	}
	remote:FireAllClients("launchFx", { launcher = launcher, position = origin })
	snapshot(player, "Pumpkin away!", "close")
end)
RunService.Heartbeat:Connect(function(dt)
	if closing then
		return
	end
	for player, flight in flights do
		flight.elapsed += dt
		local t = flight.elapsed
		local position = flight.origin
			+ flight.velocity * t
			- Vector3.yAxis * (0.5 * Rules.Gravity * t * t)
		local exclude: { Instance } = {}
		for _, target in scene.targets do
			table.insert(exclude, target)
		end
		for _, other in Players:GetPlayers() do
			if other.Character then
				table.insert(exclude, other.Character)
			end
		end
		for _, part in carries do
			table.insert(exclude, part)
		end
		for _, shot in flights do
			table.insert(exclude, shot.part)
		end
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = exclude
		rayParams.RespectCanCollide = true
		local groundHit = workspace:Raycast(flight.last, position - flight.last, rayParams)
		if groundHit then
			position = groundHit.Position
		end
		if flight.wave == wave.number and not resetAt then
			for id, target in scene.targets do
				if not wave.hits[id] then
					local a, b, p = flight.last, position, target.Position
					local radius = math.max(target.Size.X, target.Size.Y, target.Size.Z) / 2
						+ flight.part.Size.X / 2
						+ 1.5
					if
						Rules.segmentDistance(p.X, p.Y, p.Z, a.X, a.Y, a.Z, b.X, b.Y, b.Z) <= radius
					then
						flight.hits += 1
						hit(player, id)
					end
				end
			end
		end
		flight.part.CFrame = CFrame.new(position) * CFrame.Angles(t * 3, t, 0)
		flight.last = position
		if t >= 6 or groundHit or position.Y < scene.spawn.Position.Y - 100 then
			local hits = flight.hits
			clearFlight(player)
			snapshot(
				player,
				if hits > 0
					then "Hit " .. hits .. " ghosts! Harvest another pumpkin."
					else "Missed! Try less power or adjust your angle."
			)
		end
	end
	if resetAt and os.clock() >= resetAt then
		-- Old shots cannot damage the next wave.
		for player in flights do
			clearFlight(player)
		end
		wave = Rules.newWave(#scene.targets, wave.number + 1)
		resetAt = nil
		for _, target in scene.targets do
			showGhost(target, true)
		end
		broadcast("A new ghost crowd appeared. Work together!")
	end
end)
local function character(player: Player, char: Model)
	clearCarry(player)
	clearFlight(player)
	offers[player] = nil
	local root = char:WaitForChild("HumanoidRootPart", 10)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if root and player.Character == char then
		char:PivotTo(scene.spawn)
	end
	if humanoid then
		humanoid.Died:Connect(function()
			clearCarry(player)
			clearFlight(player)
			offers[player] = nil
			snapshot(player, "Harvest another pumpkin after respawning.", "close")
		end)
	end
	snapshot(player)
end
local function joined(player: Player)
	player.CharacterAdded:Connect(function(char)
		character(player, char)
	end)
	if player.Character then
		task.spawn(character, player, player.Character)
	end
	local p, err = Data.load(player)
	if not p then
		player:Kick(err or "Data unavailable")
		return
	end
	if not player.Parent or closing then
		Data.release(player)
		return
	end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = p.Gold
	gold.Parent = stats
	snapshot(player, "Harvest a pumpkin, launch at ghosts, and upgrade together!")
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
	clearCarry(player)
	clearFlight(player)
	offers[player] = nil
	limits[player] = nil
	Rules.depart(wave, player.UserId)
	Data.release(player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(joined, player)
end
for _, target in scene.targets do
	showGhost(target, true)
end
broadcast()
task.spawn(function()
	while not closing do
		task.wait(Config.AutosaveSeconds)
		if not closing then
			Data.saveAll()
		end
	end
end)
game:BindToClose(function()
	closing = true
	-- Freeze all reward-producing simulation before any datastore operation yields.
	for player in flights do
		clearFlight(player)
	end
	for player in carries do
		clearCarry(player)
	end
	table.clear(offers)
	resetAt = nil
	Data.saveAll(true)
end)
