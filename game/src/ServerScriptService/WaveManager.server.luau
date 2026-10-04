--!strict
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Campaign = require(ReplicatedStorage.Shared.Campaign)
local CoreStages = require(ReplicatedStorage.Shared.CoreStages)
local Difficulty = require(ReplicatedStorage.Shared.Difficulty)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local WaveTable = require(ReplicatedStorage.Shared.WaveTable)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local Daily = require(ReplicatedStorage.Shared.Daily)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local SpawnPicker = require(ReplicatedStorage.Shared.SpawnPicker)
local SpawnQueue = require(ReplicatedStorage.Shared.SpawnQueue)
local ArenaLayout = require(ReplicatedStorage.Shared.ArenaLayout)
local BossFight = require(ReplicatedStorage.Shared.BossFight)
local Telemetry = require(ReplicatedStorage.Shared.Telemetry)
local LevelUp = require(ReplicatedStorage.Shared.LevelUp)
local Drops = require(ReplicatedStorage.Shared.Drops)
local Feel = require(ReplicatedStorage.Shared.Feel)
local Onboarding = require(ReplicatedStorage.Shared.Onboarding)
local EnemyAI = require(ServerStorage.EnemyAI)
local PlayerData = require(ServerStorage.PlayerData)
local GameState = require(ServerStorage.GameState)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BossIntro = Remotes.BossIntro :: RemoteEvent
local GameOver = Remotes.GameOver :: RemoteEvent
local PlayAgain = Remotes.PlayAgain :: RemoteEvent
local Toast = Remotes.Toast :: RemoteEvent
local FX = Remotes.FX :: RemoteEvent
local Theme = require(ReplicatedStorage.Shared.Theme)

local arena = workspace:WaitForChild("Arena")
local spawns = arena:WaitForChild("EnemySpawns")
local bossSpawn = arena:WaitForChild("BossSpawn") :: BasePart
local rng = Random.new()

local dropsFolder = Instance.new("Folder")
dropsFolder.Name = "Drops"
dropsFolder.Parent = workspace

local currentWave = 0
local currentDifficultyId: Difficulty.TierName = Difficulty.Default
local currentMap = Campaign.get(Campaign.DefaultId)
local currentStage = CoreStages.get(Campaign.DefaultId, CoreStages.DefaultStage) :: CoreStages.Stage
local runStartedAt = 0
local playAgainRequested = false

type SpawnJob = { Run: () -> () }
local spawnQueue = SpawnQueue.new(4)
RunService.Heartbeat:Connect(function()
	SpawnQueue.drain(spawnQueue, function(job: SpawnJob)
		job.Run()
	end)
end)

local function queueSpawn(run: () -> ())
	SpawnQueue.push(spawnQueue, { Run = run })
end

PlayAgain.OnServerEvent:Connect(function(plr: Player)
	if GameState.get("Phase") == "over" and not PlayerData.isWaiting(plr) then
		playAgainRequested = true
	end
end)

local function protectPlayers()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and not PlayerData.isWaiting(player) then
			local previous = character:FindFirstChild("SpawnProtection")
			if previous then
				previous:Destroy()
			end
			local protection = Instance.new("ForceField")
			protection.Name = "SpawnProtection"
			protection.Visible = false
			protection.Parent = character
			task.delay(Config.SpawnProtectionSeconds, function()
				protection:Destroy()
			end)
		end
	end
end

local function selectedDifficultyId(): Difficulty.TierName
	local selected = GameState.get("Difficulty")
	if type(selected) == "string" and Difficulty.Defs[selected :: Difficulty.TierName] then
		return selected :: Difficulty.TierName
	end
	return Difficulty.Default
end

local function selectedStage()
	local selected = GameState.get("Stage")
	local stageNumber = if type(selected) == "number" then math.floor(selected) else nil
	return CoreStages.get(currentMap.Id, stageNumber)
		or CoreStages.get(currentMap.Id, CoreStages.DefaultStage)
end

local function sendTelemetry(plr: Player, name: string, fields: Telemetry.Fields)
	pcall(function()
		local event = Telemetry.build(name, fields)
		AnalyticsService:LogCustomEvent(plr, event.name, nil, event.fields)
	end)
end

local function todaysMutation(): (string, Mutations.Definition)
	local id = Mutations.forDay(Daily.dayIndex(os.time()))
	return id, Mutations.Defs[id]
end

local function publishMutation()
	local id, mutation = todaysMutation()
	GameState.set("MutationId", id)
	GameState.set("MutationLabel", mutation.Label)
	GameState.set("MutationBlurb", mutation.Blurb)
	workspace.Gravity = mutation.Gravity
end

local function spawnPortalCFrames(count: number): { CFrame }
	local playerPositions = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			table.insert(playerPositions, { x = root.Position.X, z = root.Position.Z })
		end
	end
	local playerZones = ArenaLayout.playerZones(playerPositions)

	local parts: { BasePart } = {}
	local portalPositions = {}
	for _, child in spawns:GetChildren() do
		local firstWave = child:GetAttribute("FirstWave")
		local lastWave = child:GetAttribute("LastWave")
		local zoneId = child:GetAttribute("ZoneId")
		if
			child:IsA("BasePart")
			and ArenaLayout.gateOpen(
				if type(firstWave) == "number" then firstWave else nil,
				if type(lastWave) == "number" then lastWave else nil,
				if type(zoneId) == "string" then zoneId else nil,
				currentWave,
				playerZones
			)
		then
			table.insert(parts, child)
			table.insert(portalPositions, { x = child.Position.X, z = child.Position.Z })
		end
	end

	local selected: { CFrame } = {}
	local firstIndex = SpawnPicker.pick(portalPositions, playerPositions, rng:NextNumber())
	table.insert(selected, parts[firstIndex].CFrame + Vector3.new(0, 4, 0))
	table.remove(parts, firstIndex)
	if count > 1 and #parts > 0 then
		local second = parts[rng:NextInteger(1, #parts)]
		table.insert(selected, second.CFrame + Vector3.new(0, 4, 0))
	end
	return selected
end

local function randomSpawnCFrame(): CFrame
	return spawnPortalCFrames(1)[1]
end

local function awardDrop(plr: Player, kind: string, value: number)
	if not PlayerData.get(plr).Active then
		return -- the run ended; a stray gem must not feed the next run
	end
	if kind == "XP" then
		PlayerData.addXp(plr, value)
	else
		PlayerData.addCoins(plr, value)
	end
end

local function makeDrop(plr: Player, position: Vector3, kind: string, value: number, index: number)
	local angle = index * 2.4
	local part = Instance.new("Part")
	part.Name = kind .. "Drop"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Position = position + Vector3.new(math.cos(angle) * 1.5, 1.2, math.sin(angle) * 1.5)
	if kind == "XP" then
		part.Color = Color3.fromRGB(45, 230, 195)
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(0.7, 0.9, 0.7)
	else
		part.Color = Color3.fromRGB(255, 205, 55)
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.25, 0.8, 0.8)
		part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, 0, math.rad(90))
	end
	part.Parent = dropsFolder

	task.spawn(function()
		local expiresAt = os.clock() + Drops.AutoCollectSeconds
		while part.Parent do
			if plr.Parent ~= Players then
				part:Destroy()
				return
			end
			local fallback = os.clock() >= expiresAt
			if fallback then
				if part.Parent and plr.Parent == Players then
					awardDrop(plr, kind, value)
					part:Destroy()
				end
				return
			end
			-- Only the killer collects their own drops, within their Magnet card radius.
			local collector: Player? = nil
			local collectorRoot: BasePart? = nil
			local ownerRoot = plr.Character
				and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local radius = math.max(Feel.GemMagnetRadius, PlayerData.magnetRadius(plr))
			if
				ownerRoot
				and PlayerData.get(plr).Active
				and (ownerRoot.Position - part.Position).Magnitude <= radius
			then
				collector = plr
				collectorRoot = ownerRoot
			end
			if collector and collectorRoot then
				local tween = TweenService:Create(
					part,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = collectorRoot.Position }
				)
				tween:Play()
				tween.Completed:Wait()
				if part.Parent and collector.Parent == Players then
					awardDrop(collector, kind, value)
					part:Destroy()
				end
				return
			end
			task.wait(0.05)
		end
	end)
end

local function spawnDrops(plr: Player, position: Vector3, enemyType: string, coins: number)
	local index = 0
	for _, value in Drops.gemsForKill(enemyType) do
		index += 1
		makeDrop(plr, position, "XP", value, index)
	end
	makeDrop(plr, position, "Coin", coins, index + 1)
end

local function firstPackSpawnCFrame(): CFrame?
	for _, player in Players:GetPlayers() do
		if PlayerData.isWaiting(player) then
			continue
		end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
			if look.Magnitude < 0.01 then
				look = Vector3.new(0, 0, -1)
			else
				look = look.Unit
			end
			local right = Vector3.new(-look.Z, 0, look.X)
			local angle = math.rad(rng:NextNumber(-10, 10))
			local distance = Onboarding.firstSpawnDistance(rng:NextNumber())
			local direction = look * math.cos(angle) + right * math.sin(angle)
			local height = 4
			local horizontalDistance = math.sqrt(distance * distance - height * height)
			local position = root.Position
				+ direction * horizontalDistance
				+ Vector3.new(0, height, 0)
			-- Keep the pack inside the walls when the player stands near an edge.
			local limit = 72
			position = Vector3.new(
				math.clamp(position.X, -limit, limit),
				position.Y,
				math.clamp(position.Z, -limit, limit)
			)
			return CFrame.lookAt(position, root.Position)
		end
	end
	return nil
end

local function spawnEnemy(typeName: string, cf: CFrame?, active: boolean?)
	local def = Enemies.Defs[typeName]
	local hs, ds = WaveTable.scaling(currentWave)
	hs *= currentStage.HealthScale
	ds *= currentStage.DamageScale
	local scaled = Difficulty.apply({ Health = hs, Damage = ds }, currentDifficultyId)
	local healthScale = (scaled.Health :: number) * WaveTable.bossHealthBonus(typeName, currentWave)
	local damageScale = scaled.Damage :: number
	-- Keep the onboarding wave predictable even when a daily difficulty mutation is active.
	local mutationId = if currentWave == 1 then "" else todaysMutation()
	local at = cf or randomSpawnCFrame()
	local accent = (Theme.Enemy[typeName] or Theme.Enemy.Walker).Accent
	FX:FireAllClients(
		if def.Boss then "boss" else "spawn",
		{ Position = at.Position, Color = accent }
	)
	local model: Model
	model = EnemyAI.spawn(
		typeName,
		at,
		healthScale,
		damageScale,
		mutationId,
		function(killer: Player?, deathPosition: Vector3)
			GameState.set("Alive", EnemyAI.aliveCount())
			if killer and Players:GetPlayerByUserId(killer.UserId) == killer then
				local coins = Difficulty.scaleReward(
					Economy.coinsForKill(
						def.Coins,
						PlayerData.hasPass(killer, "DoubleCoins"),
						currentWave
					),
					currentDifficultyId
				)
				PlayerData.addKill(killer, def.Boss == true)
				spawnDrops(killer, deathPosition, typeName, coins)
				PlayerData.awardAssists(model, killer, coins, def.Boss == true)
			else
				PlayerData.clearDamageCredit(model)
			end
			if def.Boss then
				-- bosses drop a shard of their element to everyone alive at the kill
				local element = Evolutions.BossShards[typeName]
				if element then
					for _, plr in Players:GetPlayers() do
						if not PlayerData.isWaiting(plr) then
							PlayerData.addShard(plr, element, 1)
						end
					end
					Toast:FireAllClients(typeName .. " down! +1 " .. element .. " shard", 4)
				end
				-- the first boss a player ever sees fall pays a free Gem crate: the way to a
				-- second weapon without Robux. Once per profile, so only once it has loaded.
				for _, plr in Players:GetPlayers() do
					local p = PlayerData.profile(plr)
					if
						not PlayerData.isWaiting(plr)
						and PlayerData.isLoaded(plr)
						and not p.Flags.FirstBossCrate
					then
						p.Flags.FirstBossCrate = true
						PlayerData.markDirty(plr)
						PlayerData.openCrate(plr, "Gem")
						Toast:FireClient(plr, "First boss down: free weapon crate!", 4)
					end
				end
			end
		end,
		active
	)
	GameState.set("Alive", EnemyAI.aliveCount())
	return model
end

EnemyAI.OnSummon = function(typeName: string, cf: CFrame)
	if EnemyAI.aliveCount() < Config.MaxAlive then
		queueSpawn(function()
			spawnEnemy(typeName, cf)
		end)
	end
end

local queenEncounterToken = 0

local function playerZoneSet(): { [string]: boolean }
	local positions = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			table.insert(positions, { x = root.Position.X, z = root.Position.Z })
		end
	end
	return ArenaLayout.playerZones(positions)
end

local function startQueenPhaseTwo(model: Model, humanoid: Humanoid)
	queenEncounterToken += 1
	local token = queenEncounterToken
	local zone = ArenaLayout.zoneForWave(Config.NormalWaves)
	local pools = BossFight.gooPools(ArenaLayout.floorRects(zone), ArenaLayout.ZoneSpawns)
	FX:FireAllClients("queenPhase", { Position = model:GetPivot().Position, Pools = pools })

	-- The server owns damage, while clients render the teal outlined pools locally.
	task.spawn(function()
		while queenEncounterToken == token and humanoid.Health > 0 and model.Parent do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if not root or not root:IsA("BasePart") then
					continue
				end
				for _, pool in pools do
					local dx = root.Position.X - pool.x
					local dz = root.Position.Z - pool.z
					if dx * dx + dz * dz <= pool.Radius * pool.Radius then
						PlayerData.takeEnemyDamage(
							player,
							PlayerData.incomingDamage(player, BossFight.GooDamagePerSecond * 0.5)
						)
						break
					end
				end
			end
		end
	end)

	-- Adds enter only through the two named, currently-open Hive Core gates.
	task.spawn(function()
		while queenEncounterToken == token and humanoid.Health > 0 and model.Parent do
			task.wait(BossFight.AddEverySeconds)
			if queenEncounterToken ~= token or humanoid.Health <= 0 or not model.Parent then
				break
			end
			local occupiedZones = playerZoneSet()
			for _, gateName in BossFight.AddGateNames do
				if not BossFight.canAdd(EnemyAI.aliveCount(), Config.MaxAlive) then
					break
				end
				local gate = spawns:FindFirstChild(gateName)
				if not gate or not gate:IsA("BasePart") then
					continue
				end
				local firstWave = gate:GetAttribute("FirstWave")
				local lastWave = gate:GetAttribute("LastWave")
				local zoneId = gate:GetAttribute("ZoneId")
				if
					ArenaLayout.gateOpen(
						if type(firstWave) == "number" then firstWave else nil,
						if type(lastWave) == "number" then lastWave else nil,
						if type(zoneId) == "string" then zoneId else nil,
						currentWave,
						occupiedZones
					)
				then
					spawnEnemy("Runner", gate.CFrame + Vector3.new(0, 4, 0))
				end
			end
		end
	end)
end

local function anyPlayersAlive(): boolean
	for _, plr in Players:GetPlayers() do
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not PlayerData.isWaiting(plr) and hum and hum.Health > 0 then
			return true
		end
	end
	return false
end

local function admitWaitingPlayers()
	local aliveCoins = {}
	for _, plr in Players:GetPlayers() do
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not PlayerData.isWaiting(plr) and hum and hum.Health > 0 then
			table.insert(aliveCoins, PlayerData.get(plr).Coins)
		end
	end
	local catchUpCoins = Economy.catchUpCoins(aliveCoins)
	for _, plr in Players:GetPlayers() do
		-- Lobby players wait until they launch from the Start Here pad (InArena).
		if PlayerData.isWaiting(plr) and plr:GetAttribute("InArena") == true then
			PlayerData.setRunCoins(plr, catchUpCoins)
			PlayerData.setWaiting(plr, false)
			plr:LoadCharacter()
		end
	end
end

local function respawnAll()
	for _, plr in Players:GetPlayers() do
		if PlayerData.isWaiting(plr) then
			continue
		end
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			plr:LoadCharacter()
		end
	end
end

local function countdown(seconds: number)
	local t = seconds
	while t > 0 do
		GameState.set("TimeLeft", t)
		task.wait(1)
		t -= 1
	end
	GameState.set("TimeLeft", 0)
end

local function trackBoss(model: Model)
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	GameState.set("BossName", model.Name)
	GameState.set("BossMaxHealth", hum.MaxHealth)
	GameState.set("BossHealth", hum.Health)
	local phaseTwoStarted = false
	hum.HealthChanged:Connect(function(h)
		GameState.set("BossHealth", math.max(h, 0))
		if
			not phaseTwoStarted
			and model:GetAttribute("TypeName") == "Queen"
			and BossFight.phaseForHealth(h, hum.MaxHealth) == 2
		then
			phaseTwoStarted = true
			startQueenPhaseTwo(model, hum)
		end
	end)
	hum.Died:Connect(function()
		if model:GetAttribute("TypeName") == "Queen" then
			queenEncounterToken += 1
			FX:FireAllClients("queenKill", { Position = model:GetPivot().Position })
			Toast:FireAllClients("MARS CORE CLEARED", 4)
		end
		GameState.set("BossName", "")
		-- 0 tells the HUD to go back to the wave-progress bar.
		GameState.set("BossMaxHealth", 0)
		GameState.set("BossHealth", 0)
	end)
end

-- Returns true if the wave was cleared, false on team wipe.
local function runWave(wave: number): boolean
	currentWave = wave
	GameState.set("BossMaxHealth", 0) -- a boss removed without dying must not stick to later waves
	publishMutation()
	GameState.set("Wave", wave)
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			PlayerData.setRunWave(plr, wave)
			sendTelemetry(plr, "WaveReached", {
				wave = wave,
				seconds = os.clock() - runStartedAt,
			})
		end
	end
	GameState.set("Phase", "starting")
	if wave ~= 1 then
		FX:FireAllClients("sound", { Name = "WaveStart" })
	end
	countdown(if wave == 1 then Onboarding.CountdownSeconds else Config.WaveStartDelay)

	local bossName = if wave == currentStage.Waves then currentStage.Boss else nil

	workspace:SetAttribute("WaveStartedAt", workspace:GetServerTimeNow()) -- HUD wave clock
	GameState.set("Phase", "fighting")
	protectPlayers()
	local composition = WaveTable.Compositions[wave]
	if not composition then
		composition = {}
		local mutationId = todaysMutation()
		local count = math.floor(
			Mutations.apply({ Spawn = WaveTable.enemyCount(wave) }, mutationId).Spawn + 0.5
		)
		local weights = Enemies.weightsForWave(wave)
		for _ = 1, count do
			local enemyName = Enemies.pickFromWeights(weights, rng:NextNumber())
			composition[enemyName] = (composition[enemyName] or 0) + 1
		end
		if bossName then
			composition[bossName] = (composition[bossName] or 0) + 1
		end
	else
		composition = WaveTable.resolveStageComposition(
			composition,
			currentStage.Family,
			currentStage.Boss,
			wave == currentStage.Waves
		)
	end

	if bossName then
		local spot = ArenaLayout.bossSpawnForWave(wave)
		local bossAt = CFrame.new(spot.x, bossSpawn.Position.Y + 6, spot.z)
		composition[bossName] = math.max(0, (composition[bossName] or 1) - 1)
		if composition[bossName] == 0 then
			composition[bossName] = nil
		end
		-- 28929ca: a boss spawn error killed gameLoop and froze the run on wave 15.
		local spawned, model = pcall(spawnEnemy, bossName, bossAt, false)
		if spawned and model then
			trackBoss(model)
			BossIntro:FireAllClients(
				Enemies.Defs[bossName].Name,
				Config.BossIntroSeconds,
				bossAt.Position
			)
			task.wait(Config.BossIntroSeconds)
			EnemyAI.setActive(model, true)
			-- Protection from the wave start ran out during the intro; give it again as the boss wakes.
			protectPlayers()
		else
			warn("Boss " .. bossName .. " failed to spawn: " .. tostring(model))
		end
	end

	for packIndex, pack in WaveTable.packs(composition) do
		while not WaveTable.packFits(EnemyAI.aliveCount(), pack.Size, Config.MaxAlive) do
			if not anyPlayersAlive() then
				return false
			end
			task.wait(0.5)
		end
		local onboardingPack = wave == 1 and packIndex == 1
		local onboardingSpawn = if onboardingPack then firstPackSpawnCFrame() else nil
		local portals = if onboardingSpawn
			then { onboardingSpawn }
			else spawnPortalCFrames(pack.PortalCount)
		local portalIndex = 1
		local pendingSpawns = 0
		for enemyName, amount in pack.Composition do
			for _ = 1, amount do
				local at = if Enemies.Defs[enemyName].Boss
					then bossSpawn.CFrame + Vector3.new(0, 6, 0)
					else if onboardingPack
						then firstPackSpawnCFrame() or portals[1]
						else portals[portalIndex] * CFrame.new(
							rng:NextNumber(-4, 4),
							0,
							rng:NextNumber(-4, 4)
						)
				pendingSpawns += 1
				queueSpawn(function()
					local model = spawnEnemy(enemyName, at)
					if Enemies.Defs[enemyName].Boss then
						trackBoss(model)
					end
					pendingSpawns -= 1
				end)
				portalIndex = portalIndex % #portals + 1
			end
		end
		while pendingSpawns > 0 do
			RunService.Heartbeat:Wait()
		end
		local spawnDelay = Difficulty.apply(
			{ SpawnDelay = rng:NextNumber(Config.SpawnGapMin, Config.SpawnGapMax) },
			currentDifficultyId
		).SpawnDelay :: number
		task.wait(spawnDelay)
		if not anyPlayersAlive() then
			return false
		end
	end
	while EnemyAI.aliveCount() > 0 do
		if not anyPlayersAlive() then
			return false
		end
		task.wait(0.4)
		GameState.set("Alive", EnemyAI.aliveCount()) -- the watchdog can drop enemies that never died
	end
	local techShard = wave % Evolutions.TechShardEveryWaves == 0
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			PlayerData.addCoins(
				plr,
				Difficulty.scaleReward(Economy.waveClearBonus(wave), currentDifficultyId)
			)
			if techShard then
				PlayerData.addShard(plr, "Tech", 1)
			end
		end
	end
	if techShard then
		Toast:FireAllClients("Wave " .. wave .. " cleared: +1 Tech shard", 4)
	end
	local nextComposition = WaveTable.Compositions[wave + 1]
	if nextComposition then
		-- The delay lets the last client death ghost finish before its rig rejoins the pool.
		task.delay(1.2, function()
			EnemyAI.refillPool(nextComposition, currentMap.Family)
		end)
	end
	FX:FireAllClients("sound", { Event = "wave clear" })
	return true
end

local function endRun(won: boolean, reachedWave: number)
	playAgainRequested = false
	queenEncounterToken += 1
	FX:FireAllClients("queenEnd", {})
	GameState.set("BossName", "")
	GameState.set("Phase", "chest")
	-- Every surviving participant sees the existing Gem crate open. The run version uses the
	-- shared pity counter even though Gem crates bought in the shop do not.
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			PlayerData.openCrate(plr, LevelUp.ChestCrate, "RunEnd", true)
		end
	end
	task.wait(LevelUp.ChestRevealSeconds)
	GameState.set("Phase", "over")
	-- each player gets their own run summary (Gems earned, next goal) for the results panel
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			local summary = PlayerData.endRun(
				plr,
				reachedWave,
				won,
				currentMap.Id,
				currentDifficultyId,
				currentStage.Id
			)
			GameOver:FireClient(plr, summary)
		end
	end
	FX:FireAllClients("sound", { Name = if won then "WaveClear" else "GameOver" })
	EnemyAI.clearAll()
	GameState.set("Alive", 0)
	GameState.set("TimeLeft", 0)
	-- Wait for a Play again press; fall back to a restart so an idle server never stalls.
	local overSince = os.clock()
	while
		not playAgainRequested
		and #Players:GetPlayers() > 0
		and os.clock() - overSince < Config.PlayAgainTimeout
	do
		task.wait(0.1)
	end
end

local function anyPlayerInRun(): boolean
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			return true
		end
	end
	return false
end

local function gameLoop()
	while true do
		GameState.set("Phase", "idle")
		GameState.set("Wave", 0)
		-- A run starts once a party launches from the lobby's Start Here pad.
		while not anyPlayerInRun() do
			task.wait(0.25)
		end
		runStartedAt = os.clock()
		currentMap = Campaign.get(GameState.get("MapId"))
		currentDifficultyId = selectedDifficultyId()
		currentStage = selectedStage() :: CoreStages.Stage
		GameState.set("Difficulty", currentDifficultyId)
		GameState.set("Stage", currentStage.Id)
		local playerCount = 0
		for _, plr in Players:GetPlayers() do
			if PlayerData.isWaiting(plr) then
				continue
			end
			playerCount += 1
			PlayerData.resetRun(plr)
			local profile = PlayerData.profile(plr)
			sendTelemetry(plr, "RunStart", {
				players = playerCount,
				weapon = profile.Equipped,
				kit = profile.Kit,
			})
		end
		respawnAll()

		local wave = 0
		local alive = true
		while alive and wave < currentStage.Waves do
			wave += 1
			alive = runWave(wave)
			if alive then
				if wave == currentStage.Waves then
					break
				end
				GameState.set("Phase", "intermission")
				admitWaitingPlayers()
				respawnAll()
				countdown(Config.IntermissionSeconds)
				for _, plr in Players:GetPlayers() do
					PlayerData.autoPick(plr)
				end
			end
		end
		endRun(alive and wave == currentStage.Waves, wave)
	end
end

local function onPlayerAdded(plr: Player)
	-- Everyone starts in the lobby, out of the run, until the Start Here pad launches them.
	PlayerData.setWaiting(plr, true)
	task.wait(1)
	if not plr.Character then
		plr:LoadCharacter()
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in Players:GetPlayers() do
	task.spawn(onPlayerAdded, plr)
end

publishMutation()
task.spawn(gameLoop)
