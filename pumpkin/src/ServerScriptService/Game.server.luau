--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Grow = require(Shared:WaitForChild("Grow"))
local Data = require(ServerStorage:WaitForChild("Data"))
local EconomyService = require(ServerStorage:WaitForChild("EconomyService"))
local Leaderboards = require(ServerStorage:WaitForChild("Leaderboards"))
local PumpkinVisual = require(ServerStorage:WaitForChild("PumpkinVisual"))
local RemotesBuilder = require(ServerStorage:WaitForChild("Remotes"))

local remotes = RemotesBuilder.build()
local growRequest = remotes:FindFirstChild("GrowRequest") :: RemoteEvent
local growEffect = remotes:FindFirstChild("GrowEffect") :: RemoteEvent
local statsChanged = remotes:FindFirstChild("StatsChanged") :: RemoteEvent
local limiter = Grow.newRateLimiter()

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
	if not profile or not limiter:allow(player, os.clock()) then
		return
	end
	growPlayer(player)
end)

EconomyService.init(remotes, syncPlayer, growPlayer)

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(loadPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	limiter:clear(player)
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
