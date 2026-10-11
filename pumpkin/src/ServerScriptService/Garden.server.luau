--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
if Config.GameplayMode ~= "Garden" then
	return
end
local Rules = require(Shared:WaitForChild("GardenRules"))
local Scene = require(ServerStorage:WaitForChild("GardenScene"))
local scene = Scene.build()
-- Establish terrain and spawn before Data's Studio probe can yield.
local Data = require(ServerStorage:WaitForChild("Data"))
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "GardenAction", ReplicatedStorage
local states: { [Player]: any } = {}
local saves: { [Player]: boolean } = {}
local loading: { [Player]: boolean } = {}
local limits: { [Player]: number } = {}
local occupied: { [number]: boolean } = {}
local cooldowns: { [BasePart]: number } = {}
local bursts: { any } = {}
local joinedPlayers: { [Player]: boolean } = {}
local sessionEnded: { [Player]: boolean } = {}
local deathHooks: { [Model]: boolean } = setmetatable({}, { __mode = "k" })
local orphans: { [Player]: number } = {}
local closing, shrine, clock = false, 0, 0
local function alive(player: Player): BasePart?
	local char = player.Character
	local h = if char then char:FindFirstChildOfClass("Humanoid") else nil
	local r = if char then char:FindFirstChild("HumanoidRootPart") else nil
	return if h and h.Health > 0 and r and r:IsA("BasePart") then r else nil
end
local function near(player: Player, position: Vector3, radius: number): boolean
	local r = alive(player)
	return r ~= nil and (r.Position - position).Magnitude <= radius
end
local function snapshot(player: Player, message: string?)
	local p, s = Data.get(player), states[player]
	if not p or not s or not player.Parent then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	local gold = if stats then stats:FindFirstChild("Gold") else nil
	if gold and gold:IsA("IntValue") then
		gold.Value = p.Gold
	end
	remote:FireClient(player, "state", {
		gold = p.Gold,
		rank = p.PumpkinRank,
		mode = s.mode,
		charges = s.charges or 0,
		maximum = s.maximum or 0,
		shrine = shrine,
		goal = Rules.ShrineGoal,
		message = message,
		reducedEffects = p.ReducedEffects,
		sfxVolume = p.SFXVolume,
	})
end
local function broadcast(message: string?)
	for p in states do
		snapshot(p, message)
	end
end
local function clear(player: Player)
	for i = #bursts, 1, -1 do
		if bursts[i].owner == player.UserId then
			table.remove(bursts, i)
		end
	end
	local s = states[player]
	if not s then
		return
	end
	if s.pumpkin then
		s.pumpkin:Destroy()
	end
	s.pumpkin = nil
	s.mode = "harvest"
	s.charges = 0
end
local function movement(player: Player): boolean
	local s, root = states[player], alive(player)
	if not s or not root or not s.trusted then
		return false
	end
	local position, now = root.Position, os.clock()
	local previous = s.trusted
	local maximumZ = 80
	for _, state in states do
		maximumZ = math.max(maximumZ, state.plot.spawn.Position.Z - scene.arenaCenter.Z + 30)
	end
	local bounds = {
		minX = scene.arenaCenter.X - 110,
		maxX = scene.arenaCenter.X + 110,
		minZ = scene.arenaCenter.Z - 120,
		maxZ = scene.arenaCenter.Z + maximumZ,
		floorY = scene.arenaCenter.Y,
	}
	local safe, budget = Rules.movement(
		{ x = previous.X, y = previous.Y, z = previous.Z, budget = s.travelBudget },
		{ x = position.X, y = position.Y, z = position.Z },
		now - (s.sampleAt or now),
		bounds
	)
	if not safe then
		clear(player)
		root.CFrame = CFrame.new(previous)
		s.sampleAt = now
		snapshot(player, "Magic paused after an unexpected jump. Harvest again.")
		return false
	end
	s.trusted, s.sampleAt = position, now
	s.travelBudget = budget
	return true
end
local function valid(player: Player): boolean
	if not closing and player.Parent == Players and states[player] and not Data.get(player) then
		if not sessionEnded[player] then
			sessionEnded[player] = true
			clear(player)
			player:Kick("Your data session changed. Please rejoin to continue safely.")
		end
		return false
	end
	return not closing
		and player.Parent == Players
		and states[player] ~= nil
		and Data.get(player) ~= nil
end
local function allowed(player: Player): boolean
	if not valid(player) or not movement(player) then
		return false
	end
	local now = os.clock()
	if now - (limits[player] or -100) < 0.15 then
		return false
	end
	limits[player] = now
	return true
end
local function reward(player: Player, amount: number)
	if not valid(player) or not alive(player) then
		return
	end
	local p = Data.get(player)
	p.Gold = math.min(1e9, p.Gold + amount)
	Data.markDirty(player)
end
local function save(player: Player, release: boolean): boolean
	while saves[player] do
		task.wait()
	end
	saves[player] = true
	local ok = if release then Data.release(player) else Data.save(player)
	saves[player] = nil
	if release and not ok then
		orphans[player] = orphans[player] or 0
		warn("Final garden save failed; retained profile queued for bounded retries", player.UserId)
	elseif release then
		orphans[player] = nil
	end
	return ok
end
local function ghost(target: BasePart, contributors: { Player }): boolean
	if closing or os.clock() < (cooldowns[target] or 0) then
		return false
	end
	local active: { Player } = {}
	for _, p in contributors do
		if
			valid(p)
			and alive(p)
			and movement(p)
			and (states[p].trusted - scene.arenaCenter).Magnitude <= scene.arenaRadius + 15
		then
			table.insert(active, p)
		end
	end
	if #active == 0 then
		return false
	end
	cooldowns[target] = os.clock() + Rules.GhostRespawn
	Scene.setGhost(target, false)
	for _, p in active do
		reward(p, Rules.GhostGold)
	end
	shrine += 1
	Scene.setShrine(shrine, Rules.ShrineGoal)
	remote:FireAllClients(
		"fx",
		{ kind = "ghost", position = target.Position, owner = active[1].UserId }
	)
	return true
end
local function burst(player: Player)
	local s = states[player]
	if not valid(player) or not movement(player) or not s or s.mode ~= "guide" or not s.pumpkin then
		return
	end
	local position = s.position
	local diameter = s.diameter
	clear(player)
	local now = os.clock()
	local current =
		{ owner = player.UserId, player = player, position = position, time = now, used = false }
	local partner = nil
	for i = #bursts, 1, -1 do
		local old = bursts[i]
		if not old then
			continue
		end
		if now - old.time > Rules.ChainSeconds then
			table.remove(bursts, i)
		elseif
			valid(old.player)
			and alive(old.player)
			and movement(old.player)
			and Rules.chain(old, {
				owner = current.owner,
				time = now,
				distance = (old.position - position).Magnitude,
			})
		then
			partner = old
			old.used = true
			current.used = true
			break
		end
	end
	local count = 0
	for _, target in scene.targets do
		if count >= 3 then
			break
		end
		if (target.Position - position).Magnitude <= diameter + 6 and ghost(target, { player }) then
			count += 1
		end
	end
	if partner then
		local countChain = 0
		for _, target in scene.targets do
			if countChain >= 3 then
				break
			end
			if
				Rules.segmentDistance(
						target.Position.X,
						target.Position.Z,
						partner.position.X,
						partner.position.Z,
						position.X,
						position.Z
					)
					<= 8
				and ghost(target, { player, partner.player })
			then
				countChain += 1
			end
		end
		remote:FireAllClients(
			"fx",
			{ kind = "chain", position = position, other = partner.position, owner = player.UserId }
		)
		broadcast("CHAIN SPELL! Two seedbursts joined. Extra ghosts credit both friends.")
	end
	table.insert(bursts, current)
	remote:FireAllClients(
		"fx",
		{ kind = "burst", position = position, diameter = diameter, owner = player.UserId }
	)
	snapshot(player, "Seedburst! Your vines have been growing — harvest again.")
	broadcast()
end
local function harvest(player: Player, crop: BasePart?)
	local s, p = states[player], Data.get(player)
	if not valid(player) or not s or not p or s.mode ~= "harvest" or not alive(player) then
		return
	end
	local chosen = nil
	local closest = math.huge
	for index, marker in s.plot.crops do
		if (crop == nil or marker == crop) and near(player, marker.Position, 12) then
			local age = os.clock() - s.grown[index]
			local distance = (alive(player).Position - marker.Position).Magnitude
			if age >= Rules.SmallSeconds and distance < closest then
				chosen = index
				closest = distance
			end
		end
	end
	if not chosen then
		snapshot(player, "Walk to your glowing vine. Small pumpkins are ready in 8 seconds.")
		return
	end
	local age = os.clock() - s.grown[chosen]
	s.diameter = Rules.harvestDiameter(age, p.PumpkinRank)
	s.maximum = Rules.charges(s.diameter)
	s.charges = s.maximum
	s.grown[chosen] = os.clock()
	s.pumpkin = Scene.createPumpkin(scene.model, s.diameter)
	s.mode = "cast"
	Scene.setCrop(s.plot.crops[chosen], 0.7, true)
	remote:FireAllClients(
		"fx",
		{ kind = "harvest", position = s.plot.crops[chosen].Position, owner = player.UserId }
	)
	snapshot(player, "Cast to wake your pumpkin. Then walk toward the ghosts!")
end
local function context(player: Player)
	if not valid(player) then
		return
	end
	local s = states[player]
	local root = alive(player)
	if not root then
		return
	end
	if s.mode == "harvest" then
		harvest(player, nil)
	elseif s.mode == "cast" then
		s.mode = "guide"
		s.position = root.Position + root.CFrame.LookVector * (3 + s.diameter / 2)
		s.lastContact = 0
		remote:FireAllClients("fx", { kind = "cast", position = s.position, owner = player.UserId })
		snapshot(player, "Walk through ghosts. Recall brings your pumpkin beside you.")
	elseif s.mode == "guide" then
		s.position = root.Position + root.CFrame.LookVector * (3 + s.diameter / 2)
		snapshot(player, "Pumpkin recalled — walk toward the next ghost.")
	end
end
local function prompt(part: BasePart, text: string, callback: (Player) -> ())
	local item = Instance.new("ProximityPrompt")
	item.ActionText, item.ObjectText = text, "Magic garden"
	item.MaxActivationDistance = 10
	item.KeyboardKeyCode = Enum.KeyCode.F
	item.GamepadKeyCode = Enum.KeyCode.ButtonB
	item.RequiresLineOfSight = false
	item.HoldDuration = 0.1
	item.Parent = part
	item.Triggered:Connect(function(player)
		if allowed(player) and near(player, part.Position, 12) then
			callback(player)
		end
	end)
end
prompt(scene.shop, "Grow bigger • 60 gold", function(player)
	local ok, message = Rules.upgrade(Data.get(player))
	if ok then
		Data.markDirty(player)
	end
	snapshot(player, message)
end)
remote.OnServerEvent:Connect(function(player, action)
	if type(action) ~= "string" or not valid(player) then
		return
	end
	if not allowed(player) then
		return
	end
	if action == "snapshot" then
		snapshot(player)
	elseif action == "context" then
		context(player)
	elseif action == "burst" and alive(player) then
		burst(player)
	elseif action == "upgrade" and near(player, scene.shop.Position, 12) then
		local ok, message = Rules.upgrade(Data.get(player))
		if ok then
			Data.markDirty(player)
		end
		snapshot(player, message)
	end
end)
RunService.Heartbeat:Connect(function(dt)
	if closing then
		return
	end
	clock += dt
	local updateCrops = clock >= 0.25
	if updateCrops then
		clock = 0
	end
	for player, s in states do
		local root = alive(player)
		if not valid(player) then
			clear(player)
			continue
		end
		if updateCrops then
			local p = Data.get(player)
			for index, crop in s.plot.crops do
				local age = os.clock() - s.grown[index]
				local diameter, ready = Rules.crop(age, p.PumpkinRank)
				Scene.setCrop(crop, diameter, true)
				crop:SetAttribute("Ready", ready)
				local status = crop:FindFirstChild("CropStatus")
				local label = if status then status:FindFirstChild("CropText") else nil
				if label and label:IsA("TextLabel") then
					label.Text = if not ready
						then "GROWING • " .. math.ceil(Rules.SmallSeconds - age) .. "s"
						elseif
							p.PumpkinRank >= 1 and age < Rules.BigSeconds
						then "READY • BIG IN " .. math.ceil(Rules.BigSeconds - age) .. "s"
						elseif diameter >= Rules.BigDiameter then "BIG • READY"
						else "SMALL • READY"
				end
				crop:SetAttribute(
					"Size",
					if diameter >= Rules.BigDiameter - 0.05 then "BIG" else "SMALL"
				)
			end
		end
		if not root or not movement(player) then
			continue
		end
		if s.mode == "cast" and s.pumpkin then
			s.pumpkin:PivotTo(
				root.CFrame * CFrame.new(0, s.diameter / 2 - 1.5, -(2 + s.diameter / 2))
			)
		elseif s.mode == "guide" and s.pumpkin then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local heading = if humanoid.MoveDirection.Magnitude > 0.1
				then humanoid.MoveDirection
				else root.CFrame.LookVector
			heading = Vector3.new(heading.X, 0, heading.Z)
			if heading.Magnitude < 0.1 then
				heading = Vector3.new(0, 0, -1)
			else
				heading = heading.Unit
			end
			local desired = root.Position + heading * (3 + s.diameter / 2)
			desired = Vector3.new(desired.X, scene.arenaCenter.Y + 1.5 + s.diameter / 2, desired.Z)
			if (desired - scene.arenaCenter).Magnitude > scene.arenaRadius + 80 then
				desired = root.Position + Vector3.new(0, -1, -4)
			end
			local old = s.position
			s.position = old:Lerp(desired, 1 - math.exp(-dt * 8))
			s.pumpkin:PivotTo(
				CFrame.new(s.position)
					* CFrame.Angles(
						0,
						math.atan2(-heading.X, -heading.Z),
						math.sin(os.clock() * 6) * 0.06
					)
			)
			if os.clock() - (s.lastContact or 0) >= 0.55 then
				for _, target in scene.targets do
					local distance = Rules.segmentDistance(
						target.Position.X,
						target.Position.Z,
						old.X,
						old.Z,
						s.position.X,
						s.position.Z
					)
					if
						math.abs(target.Position.Y - s.position.Y) < 9
						and distance <= s.diameter / 2 + 2.4
						and ghost(target, { player })
					then
						s.charges -= 1
						s.lastContact = os.clock()
						Scene.setShell(s.pumpkin, s.charges, s.maximum)
						snapshot(player, "Ghost freed! +5 gold")
						if s.charges <= 0 then
							burst(player)
						end
						break
					end
				end
			end
		end
	end
	for target, time in cooldowns do
		if os.clock() >= time then
			Scene.setGhost(target, true)
			cooldowns[target] = nil
		end
	end
end)
local function character(player: Player, char: Model)
	if player.Character ~= char then
		return
	end
	clear(player)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if root and player.Character == char and player.Parent == Players then
		local s = states[player]
		char:PivotTo(if s then s.plot.spawn else scene.spawn)
		if s then
			s.trusted = (root :: BasePart).Position
			s.sampleAt = os.clock()
		end
	end
	local h = char:FindFirstChildOfClass("Humanoid")
	if h and not deathHooks[char] then
		deathHooks[char] = true
		h.Died:Connect(function()
			if player.Character == char then
				clear(player)
				snapshot(player, "Harvest a fresh pumpkin after respawning.")
			end
		end)
	end
	snapshot(player)
end
local function joined(player: Player)
	if joinedPlayers[player] then
		return
	end
	joinedPlayers[player] = true
	loading[player] = true
	player.CharacterAdded:Connect(function(char)
		task.spawn(character, player, char)
	end)
	if player.Character then
		task.spawn(character, player, player.Character)
	end
	local profile, err = Data.load(player)
	loading[player] = nil
	if not profile then
		if player.Parent then
			player:Kick(err or "Data unavailable")
		end
		return
	end
	if closing or player.Parent ~= Players then
		save(player, true)
		return
	end
	local slot = 1
	while occupied[slot] do
		slot += 1
	end
	occupied[slot] = true
	local plot = Scene.createPlot(player.UserId, slot)
	for _, item in plot.model:GetDescendants() do
		if item:IsA("TextLabel") and item.Name == "Title" then
			item.Text = player.DisplayName .. "'s vines"
		end
	end
	states[player] = {
		plot = plot,
		slot = slot,
		mode = "harvest",
		grown = { os.clock() - Rules.SmallSeconds, os.clock() },
		charges = 0,
		trusted = plot.spawn.Position,
		sampleAt = os.clock(),
	}
	for _, crop in plot.crops do
		crop:SetAttribute("OwnerUserId", player.UserId)
		local status = Instance.new("BillboardGui")
		status.Name = "CropStatus"
		status.Size = UDim2.fromOffset(160, 28)
		status.StudsOffset = Vector3.new(0, 4, 0)
		status.MaxDistance = 35
		status.Parent = crop
		local label = Instance.new("TextLabel")
		label.Name = "CropText"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 235, 173)
		label.TextStrokeTransparency = 0.25
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Text = "GROWING"
		label.Parent = status
	end
	local stats = Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	local gold = Instance.new("IntValue")
	gold.Name, gold.Value, gold.Parent = "Gold", profile.Gold, stats
	if player.Character then
		task.spawn(character, player, player.Character)
	end
	snapshot(player, "Pick your ready pumpkin → cast → walk through ghosts!")
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
	sessionEnded[player] = nil
	joinedPlayers[player] = nil
	clear(player)
	local s = states[player]
	states[player] = nil
	limits[player] = nil
	if s then
		occupied[s.slot] = nil
		s.plot.model:Destroy()
	end
	for i = #bursts, 1, -1 do
		if bursts[i].owner == player.UserId then
			table.remove(bursts, i)
		end
	end
	if not loading[player] then
		save(player, true)
	end
end)
for _, player in Players:GetPlayers() do
	task.spawn(joined, player)
end
Scene.setShrine(0, Rules.ShrineGoal)
task.spawn(function()
	while not closing do
		task.wait(Config.AutosaveSeconds)
		if not closing then
			for player in states do
				task.spawn(function()
					if valid(player) then
						save(player, false)
					end
				end)
			end
		end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(5)
		if closing then
			break
		end
		for player, attempt in orphans do
			if attempt < 3 and not saves[player] then
				orphans[player] = attempt + 1
				task.spawn(save, player, true)
			elseif attempt == 3 then
				warn(
					"Garden final save retries exhausted; profile retained, progress may not persist",
					player.UserId
				)
				orphans[player] = 4
			end
		end
	end
end)
game:BindToClose(function()
	closing = true
	table.clear(bursts)
	for player in states do
		clear(player)
	end
	local pending = 0
	for player in orphans do
		pending += 1
		task.spawn(function()
			save(player, true)
			pending -= 1
		end)
	end
	for player in states do
		pending += 1
		task.spawn(function()
			save(player, true)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while os.clock() < deadline and (pending > 0 or next(loading) ~= nil or next(saves) ~= nil) do
		task.wait(0.05)
	end
	if pending > 0 or next(loading) ~= nil or next(saves) ~= nil or next(orphans) ~= nil then
		warn("Garden shutdown saving incomplete; unsaved progress may be lost.")
	end
end)
