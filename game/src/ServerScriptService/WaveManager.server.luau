--!strict
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Difficulty = require(ReplicatedStorage.Shared.Difficulty)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local WaveTable = require(ReplicatedStorage.Shared.WaveTable)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local Daily = require(ReplicatedStorage.Shared.Daily)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local SpawnPicker = require(ReplicatedStorage.Shared.SpawnPicker)
local Telemetry = require(ReplicatedStorage.Shared.Telemetry)
local LevelUp = require(ReplicatedStorage.Shared.LevelUp)
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

local currentWave = 0
local currentDifficultyId: Difficulty.TierName = Difficulty.Default
local runStartedAt = 0
local playAgainRequested = false

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

local function randomSpawnCFrame(): CFrame
	local parts: { BasePart } = {}
	local portalPositions = {}
	for _, child in spawns:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(parts, child)
			table.insert(portalPositions, { x = child.Position.X, z = child.Position.Z })
		end
	end

	local playerPositions = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			table.insert(playerPositions, { x = root.Position.X, z = root.Position.Z })
		end
	end

	local p = parts[SpawnPicker.pick(portalPositions, playerPositions, rng:NextNumber())]
	return p.CFrame + Vector3.new(0, 4, 0)
end

local function spawnEnemy(typeName: string, cf: CFrame?)
	local def = Enemies.Defs[typeName]
	local hs, ds = WaveTable.scaling(currentWave)
	local scaled = Difficulty.apply({ Health = hs, Damage = ds }, currentDifficultyId)
	local healthScale = scaled.Health :: number
	local damageScale = scaled.Damage :: number
	-- Keep the onboarding wave predictable even when a daily difficulty mutation is active.
	local mutationId = if currentWave == 1 then "" else todaysMutation()
	local at = cf or randomSpawnCFrame()
	local accent = (Theme.Enemy[typeName] or Theme.Enemy.Walker).Accent
	FX:FireAllClients(
		if def.Boss then "boss" else "spawn",
		{ Position = at.Position, Color = accent }
	)
	local model = EnemyAI.spawn(
		typeName,
		at,
		healthScale,
		damageScale,
		mutationId,
		function(killer: Player?)
			GameState.set("Alive", EnemyAI.aliveCount())
			if killer then
				local coins = Difficulty.scaleReward(
					Economy.coinsForKill(
						def.Coins,
						PlayerData.hasPass(killer, "DoubleCoins"),
						currentWave
					),
					currentDifficultyId
				)
				PlayerData.addCoins(killer, coins)
				PlayerData.addKill(killer, def.Boss == true, typeName)
			end
			if def.Boss then
				-- bosses drop a shard of their element to everyone alive at the kill
				local element = Evolutions.BossShards[typeName]
				if element then
					for _, plr in Players:GetPlayers() do
						if
							not PlayerData.isWaiting(plr) and PlayerData.addShard(plr, element, 1)
						then
							Toast:FireClient(
								plr,
								typeName .. " down! +1 " .. element .. " shard",
								4
							)
						end
					end
				end
				-- the first boss a player ever sees fall pays a free Gem crate: the way to a
				-- second weapon without Robux. Once per profile, so only once it has loaded.
				for _, plr in Players:GetPlayers() do
					local p = PlayerData.profile(plr)
					if
						not PlayerData.isWaiting(plr)
						and PlayerData.isLoaded(plr)
						and PlayerData.participated(plr)
						and not p.Flags.FirstBossCrate
					then
						p.Flags.FirstBossCrate = true
						PlayerData.markDirty(plr)
						PlayerData.openCrate(plr, "Gem")
						Toast:FireClient(plr, "First boss down: free weapon crate!", 4)
					end
				end
			end
		end
	)
	GameState.set("Alive", EnemyAI.aliveCount())
	return model
end

EnemyAI.OnSummon = function(typeName: string, cf: CFrame)
	if EnemyAI.aliveCount() < Config.MaxAlive then
		spawnEnemy(typeName, cf)
	end
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
		if PlayerData.isWaiting(plr) then
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
	hum.HealthChanged:Connect(function(h)
		GameState.set("BossHealth", math.max(h, 0))
	end)
	hum.Died:Connect(function()
		GameState.set("BossName", "")
	end)
end

-- Returns true if the wave was cleared, false on team wipe.
local function runWave(wave: number): boolean
	currentWave = wave
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
	FX:FireAllClients("sound", { Name = "WaveStart" })
	countdown(Config.WaveStartDelay)

	local bossName = Enemies.bossForWave(wave)
	if bossName then
		BossIntro:FireAllClients(Enemies.Defs[bossName].Name, Config.BossIntroSeconds)
		task.wait(Config.BossIntroSeconds)
		trackBoss(spawnEnemy(bossName, bossSpawn.CFrame + Vector3.new(0, 6, 0)))
	end

	GameState.set("Phase", "fighting")
	protectPlayers()
	local mutationId = todaysMutation()
	local count = if wave == 1
		then WaveTable.enemyCount(wave)
		else math.floor(
			Mutations.apply({ Spawn = WaveTable.enemyCount(wave) }, mutationId).Spawn + 0.5
		)
	local weights = Enemies.weightsForWave(wave)
	local waveOneSpawn = if wave == 1 then randomSpawnCFrame() else nil
	for _ = 1, count do
		while EnemyAI.aliveCount() >= Config.MaxAlive do
			if not anyPlayersAlive() then
				return false
			end
			task.wait(0.5)
		end
		local at = if waveOneSpawn
			then waveOneSpawn * CFrame.new(rng:NextNumber(-10, 10), 0, rng:NextNumber(-10, 10))
			else nil
		spawnEnemy(Enemies.pickFromWeights(weights, rng:NextNumber()), at)
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
	end
	local techShard = wave % Evolutions.TechShardEveryWaves == 0
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			PlayerData.addCoins(
				plr,
				Difficulty.scaleReward(Economy.waveClearBonus(wave), currentDifficultyId)
			)
			if techShard then
				if PlayerData.addShard(plr, "Tech", 1) then
					Toast:FireClient(plr, "Wave " .. wave .. " cleared: +1 Tech shard", 4)
				end
			end
		end
	end
	FX:FireAllClients("sound", { Event = "wave clear" })
	return true
end

local function endRun(won: boolean, reachedWave: number)
	playAgainRequested = false
	GameState.set("BossName", "")
	GameState.set("Phase", "chest")
	-- Every surviving participant sees the existing Gem crate open. The run version uses the
	-- shared pity counter even though Gem crates bought in the shop do not.
	local rewarded: { [Player]: boolean } = {}
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) and PlayerData.participated(plr) then
			rewarded[plr] = true
			PlayerData.openCrate(plr, LevelUp.ChestCrate, "RunEnd", true)
		end
	end
	task.wait(LevelUp.ChestRevealSeconds)
	GameState.set("Phase", "over")
	-- each player gets their own run summary (Gems earned, next goal) for the results panel
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			local summary = PlayerData.endRun(plr, reachedWave, won, rewarded[plr] == true)
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

local function gameLoop()
	while true do
		GameState.set("Phase", "idle")
		GameState.set("Wave", 0)
		while #Players:GetPlayers() == 0 do
			task.wait(1)
		end
		runStartedAt = os.clock()
		currentDifficultyId = selectedDifficultyId()
		GameState.set("Difficulty", currentDifficultyId)
		local playerCount = #Players:GetPlayers()
		for _, plr in Players:GetPlayers() do
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
		while alive do
			wave += 1
			alive = runWave(wave)
			if alive then
				if WaveTable.isFinalNormalWave(wave) then
					Toast:FireAllClients("Normal mode cleared! Infinite mode begins.", 5)
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
		endRun(wave > Config.NormalWaves, wave)
	end
end

local function onPlayerAdded(plr: Player)
	local phase = GameState.get("Phase")
	local joinedDuringWave = GameState.isWaveActive()
	PlayerData.setWaiting(plr, joinedDuringWave)
	if phase == "intermission" then
		PlayerData.startLateRun(plr)
	end
	-- Players joining an active wave stay unspawned until its intermission.
	task.wait(1)
	if not joinedDuringWave and not plr.Character then
		plr:LoadCharacter()
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in Players:GetPlayers() do
	task.spawn(onPlayerAdded, plr)
end

publishMutation()
task.spawn(gameLoop)
