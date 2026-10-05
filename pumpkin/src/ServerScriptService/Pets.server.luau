--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HatchEntitlements = require(Shared:WaitForChild("HatchEntitlements"))
local PetIndex = require(Shared:WaitForChild("PetIndex"))
local Pets = require(Shared:WaitForChild("Pets"))
local Data = require(ServerStorage:WaitForChild("Data"))
local RemotesBuilder = require(ServerStorage:WaitForChild("Remotes"))

local remotes = RemotesBuilder.build()
local petAction = remotes:WaitForChild("PetAction") :: RemoteEvent
local petState = remotes:WaitForChild("PetState") :: RemoteEvent
local hatchReveal = remotes:WaitForChild("HatchReveal") :: RemoteEvent

local followerRoot = workspace:FindFirstChild("PetFollowers")
if not followerRoot then
	followerRoot = Instance.new("Folder")
	followerRoot.Name = "PetFollowers"
	followerRoot.Parent = workspace
end
local petModels = ServerStorage:FindFirstChild("PetModels")
local randomSource = function(): number
	return math.random()
end
local promptConnections: { [ProximityPrompt]: RBXScriptConnection } = {}
local lastPetAction: { [Player]: number } = {}

local function zoneRequiredWins(zoneName: string): number
	for _, zone in Config.Zones do
		if zone.Name == zoneName then
			return zone.RequiredWins
		end
	end
	return math.huge -- unknown zone: never hatchable
end

local RARITY_COLORS = {
	Common = Color3.fromRGB(255, 151, 55),
	Uncommon = Color3.fromRGB(153, 255, 74),
	Rare = Color3.fromRGB(69, 176, 255),
	Epic = Color3.fromRGB(182, 82, 255),
	Legendary = Color3.fromRGB(255, 226, 64),
}

local function equipSlots(profile: any): number
	return Config.BasePetEquipSlots + if profile.ExtraPetEquip then Config.ExtraPetEquipSlots else 0
end

local function sendState(player: Player, message: string?)
	local profile = Data.get(player)
	if not profile then
		return
	end
	player:SetAttribute("PetMultiplier", Pets.multiplierSum(profile.Pets, profile.EquippedPetIds))
	player:SetAttribute("IndexMultiplier", PetIndex.sizeMultiplier(profile.DiscoveredPets))
	player:SetAttribute("FreeCandyHatch", not profile.FreeCandyHatchUsed)
	player:SetAttribute("FreeSpookyHatches", profile.FreeSpookyHatches)
	petState:FireClient(player, {
		pets = profile.Pets,
		equippedPetIds = profile.EquippedPetIds,
		capacity = Pets.inventoryCap(profile.ExpandedPetStorage),
		equipSlots = equipSlots(profile),
		discoveredPets = profile.DiscoveredPets,
		message = message,
	})
end

local function syncWins(player: Player, profile: any)
	player:SetAttribute("Wins", profile.Wins)
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = if leaderstats then leaderstats:FindFirstChild("Wins") else nil
	if wins and wins:IsA("IntValue") then
		wins.Value = math.floor(profile.Wins)
	end
	local statsChanged = remotes:FindFirstChild("StatsChanged")
	if statsChanged and statsChanged:IsA("RemoteEvent") then
		statsChanged:FireClient(player, profile.Size, profile.Wins)
	end
end

local function clearFollowers(player: Player)
	local existing = followerRoot:FindFirstChild(tostring(player.UserId))
	if existing then
		existing:Destroy()
	end
end

local function makePlaceholder(pet: Pets.Pet): Model
	local color = RARITY_COLORS[pet.rarity] or RARITY_COLORS.Common
	local model = Instance.new("Model")
	model.Name = pet.name
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.2, 1.8, 2)
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = model
	model.PrimaryPart = body

	for index, x in { -0.42, 0.42 } do
		local eye = Instance.new("Part")
		eye.Name = "Eye" .. index
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.32, 0.42, 0.24)
		eye.Color = Color3.fromRGB(24, 28, 38)
		eye.Material = Enum.Material.SmoothPlastic
		eye.CFrame = body.CFrame * CFrame.new(x, 0.18, -0.92)
		eye.Parent = model

		local ear = Instance.new("WedgePart")
		ear.Name = "Ear" .. index
		ear.Size = Vector3.new(0.55, 0.8, 0.55)
		ear.Color = color:Lerp(Color3.new(1, 1, 1), 0.12)
		ear.Material = Enum.Material.SmoothPlastic
		ear.CFrame = body.CFrame * CFrame.new(x * 1.45, 1, 0) * CFrame.Angles(0, math.pi, 0)
		ear.Parent = model
	end
	if pet.rarity == "Legendary" then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "LegendarySparkle"
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		sparkle.Lifetime = NumberRange.new(0.5, 0.9)
		sparkle.Rate = 8
		sparkle.Speed = NumberRange.new(0.3, 0.7)
		sparkle.Parent = body
	end
	return model
end

local function prepareFollower(instance: Instance, slot: number, pet: Pets.Pet)
	instance.Name = pet.id
	instance:SetAttribute("Slot", slot)
	instance:SetAttribute("PetName", pet.name)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		instance.CanQuery = false
		instance.CanTouch = false
	end
	if pet.rarity == "Legendary" then
		local emitter = instance:FindFirstChild("LegendarySparkle", true)
		if not emitter then
			local host = if instance:IsA("BasePart")
				then instance
				else instance:FindFirstChildWhichIsA("BasePart", true)
			if host then
				emitter = Instance.new("ParticleEmitter")
				emitter.Name = "LegendarySparkle"
				emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				emitter.Rate = 8
				emitter.Parent = host
			end
		end
	end
end

local function syncFollowers(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	clearFollowers(player)
	local folder = Instance.new("Folder")
	folder.Name = tostring(player.UserId)
	folder.Parent = followerRoot

	local byId = {}
	for _, pet in profile.Pets do
		byId[pet.id] = pet
	end
	for slot, petId in profile.EquippedPetIds do
		local pet = byId[petId]
		if pet then
			local template = if petModels then petModels:FindFirstChild(pet.name) else nil
			local follower = if template then template:Clone() else makePlaceholder(pet)
			prepareFollower(follower, slot, pet)
			follower.Parent = folder
		end
	end
end

local function hatch(player: Player, eggName: string)
	local profile = Data.get(player)
	local egg = Pets.findEgg(eggName)
	if not profile or not egg then
		return
	end
	if (profile.TotalWins or 0) < zoneRequiredWins(egg.Zone) then
		sendState(player, "Unlock this zone first!") -- T3 review: zone gate
		return
	end
	local count = if profile.FastTripleHatch then 3 else 1
	if not Pets.canAdd(profile.Pets, count, profile.ExpandedPetStorage) then
		sendState(player, "Your pet inventory is full!")
		return
	end
	local totalCost, entitlementState = HatchEntitlements.cost(eggName, count, egg.Cost, {
		freeCandyUsed = profile.FreeCandyHatchUsed,
		freeSpookyHatches = profile.FreeSpookyHatches,
	})
	if profile.Wins < totalCost then
		sendState(player, string.format("You need %d Wins!", totalCost))
		return
	end

	local luck = if profile.LuckyUntil > os.time() then Config.LuckyPotionMultiplier else 1
	if profile.DoubleLuck then
		luck *= 2
	end
	local results = {}
	for _ = 1, count do
		local pet = Pets.roll(eggName, randomSource, luck)
		if pet then
			pet.id = HttpService:GenerateGUID(false)
			table.insert(profile.Pets, pet)
			profile.DiscoveredPets[pet.name] = true
			table.insert(results, pet)
		end
	end
	if #results == 0 then
		return
	end
	profile.Wins -= totalCost
	profile.FreeCandyHatchUsed = entitlementState.freeCandyUsed
	profile.FreeSpookyHatches = entitlementState.freeSpookyHatches
	if profile.StarterPackOfferEndsAt == 0 then
		profile.StarterPackOfferEndsAt = os.time() + Config.StarterPackOfferSeconds
		player:SetAttribute("StarterPackOfferEndsAt", profile.StarterPackOfferEndsAt)
	end
	Data.markDirty(player)
	syncWins(player, profile)
	sendState(player)
	hatchReveal:FireClient(player, egg.DisplayName, results)
end

petAction.OnServerEvent:Connect(function(player: Player, action: any, petId: any)
	local profile = Data.get(player)
	if not profile or type(action) ~= "string" then
		return
	end
	local now = os.clock()
	if now - (lastPetAction[player] or 0) < 0.2 then
		return -- T3 review: rate limit
	end
	lastPetAction[player] = now
	if action == "Sync" then
		sendState(player)
		return
	elseif action == "EquipBest" then
		profile.EquippedPetIds = Pets.equipBest(profile.Pets, equipSlots(profile))
	elseif action == "Delete" and type(petId) == "string" then
		local pets, equipped, deleted = Pets.delete(profile.Pets, profile.EquippedPetIds, petId)
		if not deleted then
			return
		end
		profile.Pets = pets
		profile.EquippedPetIds = equipped
	else
		return
	end
	Data.markDirty(player)
	syncFollowers(player)
	sendState(player)
end)

local function eggNameFrom(instance: Instance): string?
	local current: Instance? = instance
	while current and current ~= workspace do
		local eggName = current.Name:match("^Egg_(.+)$")
		if eggName and Pets.findEgg(eggName) then
			return eggName
		end
		current = current.Parent
	end
	return nil
end

local function attachPrompt(instance: Instance)
	local eggName = eggNameFrom(instance)
	if not eggName then
		return
	end
	-- One prompt per egg stand: always resolve to the stand root's primary part (T3 review).
	local eggRoot: Instance = if instance.Name == "Egg_" .. eggName
		then instance
		else instance:FindFirstAncestor("Egg_" .. eggName) or instance
	local stand: BasePart? = if eggRoot:IsA("BasePart")
		then eggRoot
		elseif eggRoot:IsA("Model") and eggRoot.PrimaryPart then eggRoot.PrimaryPart
		else eggRoot:FindFirstChildWhichIsA("BasePart", true)
	if not stand then
		return
	end
	local prompt = stand:FindFirstChild("HatchPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HatchPrompt"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.15
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = stand
	end
	if not prompt:IsA("ProximityPrompt") or promptConnections[prompt] then
		return
	end
	local egg = Pets.findEgg(eggName)
	prompt.ActionText = string.format("Hatch - %d Wins", egg.Cost)
	prompt.ObjectText = egg.DisplayName
	prompt:SetAttribute("EggName", eggName)
	prompt:SetAttribute("Cost", egg.Cost)
	promptConnections[prompt] = prompt.Triggered:Connect(function(player)
		hatch(player, eggName)
	end)
end

for _, descendant in workspace:GetDescendants() do
	attachPrompt(descendant)
end
workspace.DescendantAdded:Connect(attachPrompt)

local function initializePlayer(player: Player)
	local deadline = os.clock() + 30
	while player.Parent == Players and not Data.get(player) and os.clock() < deadline do
		task.wait(0.1)
	end
	if Data.get(player) then
		syncFollowers(player)
		sendState(player)
		task.spawn(function()
			while player.Parent == Players do
				task.wait(Config.AutoHatchInterval)
				local profile = Data.get(player)
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if profile and profile.AutoHatch and root and root:IsA("BasePart") then
					local nearestName = nil
					local nearestDistance = Config.AutoHatchDistance
					for _, egg in Config.Eggs do
						local eggRoot = workspace:FindFirstChild("Egg_" .. egg.Name, true)
						local stand = if eggRoot and eggRoot:IsA("BasePart")
							then eggRoot
							elseif
								eggRoot
								and eggRoot:IsA("Model")
								and eggRoot.PrimaryPart
							then eggRoot.PrimaryPart
							elseif eggRoot then eggRoot:FindFirstChildWhichIsA(
								"BasePart",
								true
							)
							else nil
						if stand then
							local distance = (stand.Position - root.Position).Magnitude
							if distance <= nearestDistance then
								nearestDistance = distance
								nearestName = egg.Name
							end
						end
					end
					if nearestName then
						hatch(player, nearestName)
					end
				end
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(initializePlayer, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(initializePlayer, player)
end
Players.PlayerRemoving:Connect(function(player)
	lastPetAction[player] = nil
	clearFollowers(player)
end)
