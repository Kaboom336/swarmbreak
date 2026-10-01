--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local WaveTable = require(ReplicatedStorage.Shared.WaveTable)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local Daily = require(ReplicatedStorage.Shared.Daily)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local EnemyAI = require(ServerStorage.EnemyAI)
local PlayerData = require(ServerStorage.PlayerData)
local GameState = require(ServerStorage.GameState)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BossIntro = Remotes.BossIntro :: RemoteEvent
local GameOver = Remotes.GameOver :: RemoteEvent
local Toast = Remotes.Toast :: RemoteEvent
local FX = Remotes.FX :: RemoteEvent
local Theme = require(ReplicatedStorage.Shared.Theme)

local arena = workspace:WaitForChild("Arena")
local spawns = arena:WaitForChild("EnemySpawns")
local bossSpawn = arena:WaitForChild("BossSpawn") :: BasePart
local rng = Random.new()

local currentWave = 0

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
	local parts = spawns:GetChildren()
	local p = parts[rng:NextInteger(1, #parts)] :: BasePart
	return p.CFrame + Vector3.new(0, 4, 0)
end

local function spawnEnemy(typeName: string, cf: CFrame?)
	local def = Enemies.Defs[typeName]
	local hs, ds = WaveTable.scaling(currentWave)
	local mutationId = todaysMutation()
	local at = cf or randomSpawnCFrame()
	local accent = (Theme.Enemy[typeName] or Theme.Enemy.Walker).Accent
	FX:FireAllClients(
		if def.Boss then "boss" else "spawn",
		{ Position = at.Position, Color = accent }
	)
	local model = EnemyAI.spawn(typeName, at, hs, ds, mutationId, function(killer: Player?)
		GameState.set("Alive", EnemyAI.aliveCount())
		if killer then
			local coins = Economy.coinsForKill(
				def.Coins,
				PlayerData.hasPass(killer, "DoubleCoins"),
				currentWave
			)
			PlayerData.addCoins(killer, coins)
			PlayerData.addKill(killer, def.Boss == true)
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
	end)
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
	local mutationId = todaysMutation()
	local count =
		math.floor(Mutations.apply({ Spawn = WaveTable.enemyCount(wave) }, mutationId).Spawn + 0.5)
	local weights = Enemies.weightsForWave(wave)
	for _ = 1, count do
		while EnemyAI.aliveCount() >= Config.MaxAlive do
			if not anyPlayersAlive() then
				return false
			end
			task.wait(0.5)
		end
		spawnEnemy(Enemies.pickFromWeights(weights, rng:NextNumber()))
		task.wait(rng:NextNumber(Config.SpawnGapMin, Config.SpawnGapMax))
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
			PlayerData.addCoins(plr, Economy.waveClearBonus(wave))
			if techShard then
				PlayerData.addShard(plr, "Tech", 1)
			end
		end
	end
	if techShard then
		Toast:FireAllClients("Wave " .. wave .. " cleared: +1 Tech shard", 4)
	end
	FX:FireAllClients("sound", { Event = "wave clear" })
	return true
end

local function endRun(won: boolean, reachedWave: number)
	GameState.set("Phase", "over")
	GameState.set("BossName", "")
	-- each player gets their own run summary (Gems earned, next goal) for the results panel
	for _, plr in Players:GetPlayers() do
		if not PlayerData.isWaiting(plr) then
			local summary = PlayerData.endRun(plr, reachedWave, won)
			GameOver:FireClient(plr, summary)
		end
	end
	FX:FireAllClients("sound", { Name = if won then "WaveClear" else "GameOver" })
	EnemyAI.clearAll()
	GameState.set("Alive", 0)
	countdown(Config.RestartDelay)
end

local function gameLoop()
	while true do
		GameState.set("Phase", "idle")
		GameState.set("Wave", 0)
		while #Players:GetPlayers() == 0 do
			task.wait(1)
		end
		for _, plr in Players:GetPlayers() do
			PlayerData.resetRun(plr)
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
				-- pick 1 of 3 reward cards: a slow pick costs shop time, never the wave
				for _, plr in Players:GetPlayers() do
					PlayerData.offerRewards(plr, wave)
				end
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
	local joinedDuringWave = GameState.isWaveActive()
	PlayerData.setWaiting(plr, joinedDuringWave)
	-- Players joining an active wave stay unspawned until its intermission.
	task.wait(1)
	if not joinedDuringWave and not plr.Character then
		plr:LoadCharacter()
	end
	-- joining mid-intermission: roll this wave's reward cards too, so the panel is not
	-- silently missing until the next clear (autoPick covers whoever is present at the end)
	if GameState.get("Phase") == "intermission" and #PlayerData.get(plr).Offer == 0 then
		PlayerData.offerRewards(plr, currentWave)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in Players:GetPlayers() do
	task.spawn(onPlayerAdded, plr)
end

publishMutation()
task.spawn(gameLoop)
