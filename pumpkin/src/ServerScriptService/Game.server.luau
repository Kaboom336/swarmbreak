--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FriendBoost = require(Shared:WaitForChild("FriendBoost"))
local Grow = require(Shared:WaitForChild("Grow"))
local Roll = require(Shared:WaitForChild("Roll"))
local Data = require(ServerStorage:WaitForChild("Data"))
local EconomyService = require(ServerStorage:WaitForChild("EconomyService"))
local Leaderboards = require(ServerStorage:WaitForChild("Leaderboards"))
local PumpkinVisual = require(ServerStorage:WaitForChild("PumpkinVisual"))
local RemotesBuilder = require(ServerStorage:WaitForChild("Remotes"))
local MapFallback = require(script.Parent:WaitForChild("MapFallback"))

local remotes = RemotesBuilder.build()
local growRequest = remotes:FindFirstChild("GrowRequest") :: RemoteEvent
local growEffect = remotes:FindFirstChild("GrowEffect") :: RemoteEvent
local statsChanged = remotes:FindFirstChild("StatsChanged") :: RemoteEvent
local rollPlayback = remotes:FindFirstChild("RollPlayback") :: RemoteEvent
local limiter = Grow.newRateLimiter()
local rolling: { [Player]: boolean } = {}
local zoneParts = MapFallback.build()
local friendsByPlayer: { [Player]: { [Player]: boolean } } = {}

local function updateFriendBoost(player: Player)
	local count = 0
	for _, isFriend in friendsByPlayer[player] or {} do
		if isFriend then
			count += 1
		end
	end
	player:SetAttribute("FriendBoost", FriendBoost.boost(count))
end

local function refreshFriendships(player: Player)
	friendsByPlayer[player] = friendsByPlayer[player] or {}
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(player.IsFriendsWith, player, other.UserId)
			local cached = ok and isFriend
			friendsByPlayer[player][other] = cached
			friendsByPlayer[other] = friendsByPlayer[other] or {}
			friendsByPlayer[other][player] = cached
			updateFriendBoost(other)
		end
	end
	updateFriendBoost(player)
end

local function removeFriendships(player: Player)
	friendsByPlayer[player] = nil
	for other, cache in friendsByPlayer do
		cache[player] = nil
		updateFriendBoost(other)
	end
end

local function equippedPetMultipliers(profile: any): { number }
	local equipped = {}
	for _, petId in profile.EquippedPetIds do
		equipped[petId] = true
	end
	local multipliers = {}
	for _, pet in profile.Pets do
		if equipped[pet.id] then
			table.insert(multipliers, pet.multiplier)
		end
	end
	return multipliers
end

local function syncPlayer(player: Player, profile: any)
	player:SetAttribute("Size", profile.Size)
	player:SetAttribute("Wins", profile.Wins)
	player:SetAttribute("TotalWins", profile.TotalWins)
	player:SetAttribute("TutorialDone", profile.TutorialDone)
	player:SetAttribute("Rebirths", profile.Rebirths)
	local equippedMultipliers = equippedPetMultipliers(profile)
	local petMultiplier = if #equippedMultipliers > 0 then 0 else 1
	for _, multiplier in equippedMultipliers do
		petMultiplier += multiplier
	end
	player:SetAttribute("PetMultiplier", petMultiplier)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local wins = leaderstats:FindFirstChild("Wins") :: IntValue?
		local rebirths = leaderstats:FindFirstChild("Rebirths") :: IntValue?
		if wins then
			wins.Value = math.floor(profile.Wins)
		end
		if rebirths then
			rebirths.Value = profile.Rebirths
		end
	end
	statsChanged:FireClient(player, profile.Size, profile.Wins)
end

local function growPlayer(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end

	local amount = Grow.amount({
		rebirths = profile.Rebirths,
		petMultipliers = equippedPetMultipliers(profile),
		doubleSize = profile.DoubleSize,
		vip = profile.VIP,
		friendBoost = (player:GetAttribute("FriendBoost") :: number?) or 0,
	})
	profile.Size += amount
	profile.BiggestPumpkin = math.max(profile.BiggestPumpkin, profile.Size)
	Data.markDirty(player)
	PumpkinVisual.update(player.Character, profile.Size)
	syncPlayer(player, profile)
	growEffect:FireClient(player, amount, profile.Size)
end

local function makeLeaderstats(player: Player, profile: any)
	local old = player:FindFirstChild("leaderstats")
	if old then
		old:Destroy()
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = math.floor(profile.Wins)
	wins.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = profile.Rebirths
	rebirths.Parent = leaderstats
end

local function setupCharacter(player: Player, character: Model)
	local profile = Data.get(player)
	if profile then
		PumpkinVisual.attach(character, profile.Size)
	end
end

local function loadPlayer(player: Player)
	local profile, loadError = Data.load(player)
	if not profile then
		player:Kick(loadError or "Your data could not be loaded. Please rejoin.")
		return
	end
	if player.Parent ~= Players then
		Data.release(player)
		return
	end

	makeLeaderstats(player, profile)
	refreshFriendships(player)
	syncPlayer(player, profile)
	EconomyService.playerLoaded(player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

growRequest.OnServerEvent:Connect(function(player: Player)
	local profile = Data.get(player)
	if rolling[player] or not profile or not limiter:allow(player, os.clock()) then
		return
	end
	growPlayer(player)
end)

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

local function beginRoll(player: Player, zone: any, parts: any)
	local profile = Data.get(player)
	if rolling[player] or not profile or profile.Size <= 0 then
		return
	end
	if not Roll.isZoneUnlocked(profile.TotalWins, zone) then
		return
	end

	rolling[player] = true
	player:SetAttribute("CurrentZone", zone.Name)
	local rolledSize = profile.Size
	local result = Roll.simulate(rolledSize, zone, #parts.walls)
	local duration = Roll.duration(result.distance, rolledSize)
	-- Credit wins in the same step that consumes Size, so leaving mid-playback loses nothing (T2 review).
	profile.Size = 0
	profile.Wins += result.wins
	profile.TotalWins += result.wins
	if result.wins > 0 then
		profile.TutorialDone = true
	end
	Data.markDirty(player)
	PumpkinVisual.update(player.Character, 0)
	player:SetAttribute("Size", 0) -- Wins show on the HUD when the playback ends
	rollPlayback:FireAllClients(
		player.UserId,
		zone.Name,
		rolledSize,
		result.wallsBroken,
		result.distance,
		result.wins,
		duration
	)

	task.delay(duration, function()
		local current = Data.get(player)
		if current then
			syncPlayer(player, current)
		end
		task.delay(Config.RollCooldownSeconds, function()
			rolling[player] = nil
		end)
	end)
end

for _, zone in Config.Zones do
	local parts = zoneParts[zone.Name]
	parts.start.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player then
			beginRoll(player, zone, parts)
		end
	end)
	if zone.RequiredWins > 0 then
		parts.gate.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			local profile = if player then Data.get(player) else nil
			if player and profile and not Roll.isZoneUnlocked(profile.TotalWins, zone) then
				local root = player.Character
					and player.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					root.CFrame = parts.gate.CFrame - parts.gate.CFrame.LookVector * 8
				end
			end
		end)
	end
end

EconomyService.init(remotes, syncPlayer, growPlayer)

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(loadPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	removeFriendships(player)
	limiter:clear(player)
	rolling[player] = nil

	local profile = Data.get(player)
	if profile then
		Leaderboards.record(player, profile)
	end
	Data.release(player)
end)

game:BindToClose(function()
	Data.saveAll(true)
end)

task.spawn(function()
	while true do
		task.wait(Config.AutosaveSeconds)
		for player in Players:GetPlayers() do
			local profile = Data.get(player)
			if profile then
				Leaderboards.record(player, profile)
			end
		end
		Data.saveAll(false)
		Leaderboards.refresh()
	end
end)

task.spawn(Leaderboards.refresh)
