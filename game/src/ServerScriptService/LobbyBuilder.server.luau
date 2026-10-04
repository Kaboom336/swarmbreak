--!strict
-- Builds a compact staging lobby beside the arena and sends charged parties into the run.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Lobby = require(shared:WaitForChild("Lobby"))
local Campaign = require(shared:WaitForChild("Campaign"))
local CoreStages = require(shared:WaitForChild("CoreStages"))
local Difficulty = require(shared:WaitForChild("Difficulty"))
local Places = require(shared:WaitForChild("Places"))
local Weapons = require(shared:WaitForChild("Weapons"))
local Kits = require(shared:WaitForChild("Kits"))
local Quests = require(shared:WaitForChild("Quests"))
local Theme = require(shared:WaitForChild("Theme"))
local UiTheme = require(shared:WaitForChild("UiTheme"))
local PlayerData = require(ServerStorage:WaitForChild("PlayerData"))
local GameState = require(ServerStorage:WaitForChild("GameState"))

local arena = workspace:WaitForChild("Arena")
local arenaSpawn = arena:WaitForChild("PlayerSpawn") :: SpawnLocation
local origin = Vector3.new(Places.LobbyOrigin.x, Places.LobbyOrigin.y, Places.LobbyOrigin.z)

local lobby = Instance.new("Folder")
lobby.Name = "Lobby"
lobby.Parent = workspace

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	partColor: Color3,
	material: Enum.Material
): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.Size = size
	item.Position = position
	item.Color = partColor
	local oversizedNeon = material == Enum.Material.Neon and math.max(size.X, size.Y, size.Z) > 1.5
	item.Material = if oversizedNeon then Enum.Material.SmoothPlastic else material
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	if oversizedNeon then
		local light = Instance.new("PointLight")
		light.Color = partColor
		light.Range = 10
		light.Brightness = 1.2
		light.Parent = item
	end
	return item
end

local floor = makePart(
	lobby,
	"Floor",
	Vector3.new(60, 2, 60),
	origin,
	color(Theme.Floor),
	Enum.Material.SmoothPlastic
)
floor.CanCollide = true

local lobbySpawn = Instance.new("SpawnLocation")
lobbySpawn.Name = "LobbySpawn"
lobbySpawn.Anchored = true
lobbySpawn.CanCollide = false
lobbySpawn.Neutral = true
lobbySpawn.Duration = 0
lobbySpawn.Size = Vector3.new(8, 1, 8)
lobbySpawn.Position = origin + Vector3.new(20, 1.5, 0)
lobbySpawn.Transparency = 0.35
lobbySpawn.Color = color(Theme.NeonTeal)
lobbySpawn.Material = Enum.Material.SmoothPlastic
lobbySpawn.Parent = lobby
local lobbySpawnLight = Instance.new("PointLight")
lobbySpawnLight.Color = lobbySpawn.Color
lobbySpawnLight.Range = 10
lobbySpawnLight.Brightness = 1.2
lobbySpawnLight.Parent = lobbySpawn

local function addBoard(name: string, title: string, body: string, offset: Vector3): Part
	local board = makePart(
		lobby,
		name,
		Vector3.new(16, 11, 1),
		origin + offset,
		color(Theme.MetalDark),
		Enum.Material.SmoothPlastic
	)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = if UiTheme.Font.Body == "GothamBold"
		then Enum.Font.GothamBold
		else Enum.Font.FredokaOne
	label.Text = title .. "\n\n" .. body
	label.TextColor3 = color(UiTheme.Colors.Text)
	label.TextSize = 22
	label.TextWrapped = true
	label.Parent = gui
	return board
end

local weaponNames = {}
for id, definition in Weapons.Defs do
	table.insert(weaponNames, definition.Name .. " [" .. id .. "]")
end
table.sort(weaponNames)
local kitNames = {}
for _, id in Kits.Order do
	local kit = Kits.Defs[id]
	local weapon = Weapons.Defs[kit.StartWeapon]
	table.insert(
		kitNames,
		string.format(
			"%s — %s — %s — %s",
			kit.Label,
			kit.Blurb,
			weapon.Name,
			kit.Signature.Label
		)
	)
end
local selectionBoard = addBoard(
	"WeaponAndKitBoard",
	Lobby.Boards.WeaponAndKit,
	"Weapons: " .. table.concat(weaponNames, ", ") .. "\nKits:\n" .. table.concat(kitNames, "\n"),
	Vector3.new(-18, 6.5, -28)
)

local function addPrompt(name: string, actionText: string, offset: Vector2): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = actionText
	prompt.ObjectText = Lobby.Boards.WeaponAndKit
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.UIOffset = offset
	prompt.Parent = selectionBoard
	return prompt
end

local weaponPrompt = addPrompt("SelectWeapon", "Next owned weapon", Vector2.new(0, -28))
weaponPrompt.Triggered:Connect(function(player)
	if not PlayerData.isLoaded(player) then
		return
	end
	local profile = PlayerData.profile(player)
	if #profile.Weapons == 0 then
		return
	end
	local current = table.find(profile.Weapons, profile.Equipped) or 0
	local nextIndex = current % #profile.Weapons + 1
	PlayerData.equip(player, profile.Weapons[nextIndex])
end)

local kitPrompt = addPrompt("SelectKit", "Next owned kit", Vector2.new(0, 28))
kitPrompt.Triggered:Connect(function(player)
	if not PlayerData.isLoaded(player) then
		return
	end
	local profile = PlayerData.profile(player)
	local current = table.find(Kits.Order, profile.Kit) or 0
	for offset = 1, #Kits.Order do
		local id = Kits.Order[(current + offset - 1) % #Kits.Order + 1]
		if Kits.isUnlocked(profile, id) then
			PlayerData.chooseKit(player, id)
			return
		end
	end
end)

local questNames = {}
for index = 1, math.min(3, #Quests.Order) do
	table.insert(questNames, Quests.Defs[Quests.Order[index]].Text)
end
addBoard(
	"DailyQuestsBoard",
	Lobby.Boards.DailyQuests,
	table.concat(questNames, "\n"),
	Vector3.new(0, 6.5, -28)
)

local shopLines = {}
for _, item in Lobby.ShopItems do
	table.insert(shopLines, string.format("%s - %d", item.Name, item.Price))
end
addBoard("ShopBoard", Lobby.Boards.Shop, table.concat(shopLines, "\n"), Vector3.new(18, 6.5, -28))

local mapLines = {}
for index, map in Campaign.All do
	local previous = Campaign.All[index - 1]
	table.insert(
		mapLines,
		map.Name
			.. if map.Id == Campaign.DefaultId
				then " - READY"
				else " - [PADLOCK] Clear " .. previous.Name .. " on Normal / coming soon"
	)
end
local mapBoard =
	addBoard("MapBoard", Lobby.Boards.Map, table.concat(mapLines, "\n"), Vector3.new(-18, 6.5, -15))
local mapPrompt = Instance.new("ProximityPrompt")
mapPrompt.Name = "SelectMap"
mapPrompt.ActionText = "Next available map"
mapPrompt.ObjectText = Lobby.Boards.Map
mapPrompt.HoldDuration = 0
mapPrompt.MaxActivationDistance = 12
mapPrompt.Parent = mapBoard
mapPrompt.Triggered:Connect(function(player)
	if not PlayerData.isLoaded(player) then
		return
	end
	local profile = PlayerData.profile(player)
	local currentId = player:GetAttribute("SelectedMapId")
	local currentIndex = 0
	for index, map in Campaign.All do
		if map.Id == currentId then
			currentIndex = index
		end
	end
	for offset = 1, #Campaign.All do
		local map = Campaign.All[(currentIndex + offset - 1) % #Campaign.All + 1]
		if Lobby.canSelectMap(profile, map.Id) then
			player:SetAttribute("SelectedMapId", map.Id)
			player:SetAttribute("SelectedDifficulty", Difficulty.Default)
			player:SetAttribute("SelectedStage", CoreStages.DefaultStage)
			return
		end
	end
end)

local difficultyBoard = addBoard(
	"DifficultyBoard",
	Lobby.Boards.Difficulty,
	"Normal\nHard - Clear Normal\nNightmare - Clear Hard",
	Vector3.new(0, 6.5, -15)
)
local difficultyPrompt = Instance.new("ProximityPrompt")
difficultyPrompt.Name = "SelectDifficulty"
difficultyPrompt.ActionText = "Next unlocked tier"
difficultyPrompt.ObjectText = Lobby.Boards.Difficulty
difficultyPrompt.HoldDuration = 0
difficultyPrompt.MaxActivationDistance = 12
difficultyPrompt.Parent = difficultyBoard
difficultyPrompt.Triggered:Connect(function(player)
	if not PlayerData.isLoaded(player) then
		return
	end
	local profile = PlayerData.profile(player)
	local mapId = player:GetAttribute("SelectedMapId")
	local current = player:GetAttribute("SelectedDifficulty")
	local currentIndex = table.find(Difficulty.Order, current) or 0
	for offset = 1, #Difficulty.Order do
		local tier = Difficulty.Order[(currentIndex + offset - 1) % #Difficulty.Order + 1]
		if Lobby.canSelectDifficulty(profile, mapId, tier) then
			player:SetAttribute("SelectedDifficulty", tier)
			player:SetAttribute("SelectedStage", CoreStages.DefaultStage)
			return
		end
	end
end)

local stageLines = {}
for _, stage in CoreStages.forCore(Campaign.DefaultId) do
	table.insert(stageLines, string.format("%d. %s - %d waves", stage.Id, stage.Name, stage.Waves))
end
local stageBoard = addBoard(
	"StageBoard",
	Lobby.Boards.Stage,
	table.concat(stageLines, "\n"),
	Vector3.new(18, 6.5, -15)
)
local stagePrompt = Instance.new("ProximityPrompt")
stagePrompt.Name = "SelectStage"
stagePrompt.ActionText = "Next unlocked stage"
stagePrompt.ObjectText = Lobby.Boards.Stage
stagePrompt.HoldDuration = 0
stagePrompt.MaxActivationDistance = 12
stagePrompt.Parent = stageBoard
stagePrompt.Triggered:Connect(function(player)
	if not PlayerData.isLoaded(player) then
		return
	end
	local profile = PlayerData.profile(player)
	local coreId = player:GetAttribute("SelectedMapId")
	local difficulty = player:GetAttribute("SelectedDifficulty")
	local current = player:GetAttribute("SelectedStage")
	local stages = CoreStages.forCore(coreId)
	local currentIndex = if type(current) == "number" then math.floor(current) else 0
	for offset = 1, #stages do
		local stageNumber = (currentIndex + offset - 1) % #stages + 1
		if Lobby.canSelectStage(profile, coreId, difficulty, stageNumber) then
			player:SetAttribute("SelectedStage", stageNumber)
			return
		end
	end
end)

local teleportRing = Instance.new("Model")
teleportRing.Name = "TeleportRing"
teleportRing.Parent = lobby
local ringCenter = origin + Vector3.new(-8, 1.1, 7)
for index = 0, 11 do
	local angle = index * math.pi / 6
	local segment = makePart(
		teleportRing,
		"RingSegment",
		Vector3.new(2.5, 0.25, 0.65),
		ringCenter + Vector3.new(math.cos(angle) * 6, 0, math.sin(angle) * 6),
		color(Theme.NeonTeal),
		Enum.Material.Neon
	)
	segment.CFrame = CFrame.new(segment.Position) * CFrame.Angles(0, math.pi / 2 - angle, 0)
	segment.CanCollide = false
	segment.CanQuery = false
end

local startPad = makePart(
	teleportRing,
	"StartHere",
	Vector3.new(10, 0.4, 10),
	ringCenter,
	color(Theme.NeonPurple),
	Enum.Material.Neon
)
startPad.CanCollide = false
startPad.Transparency = 0.2

local billboard = Instance.new("BillboardGui")
billboard.Name = "Label"
billboard.Size = UDim2.fromOffset(250, 70)
billboard.StudsOffset = Vector3.new(0, 9, 0) -- clears the player at the default camera
billboard.AlwaysOnTop = false -- AlwaysOnTop drew it over the arena fight
billboard.MaxDistance = 80
billboard.Parent = startPad
local startText = Instance.new("TextLabel")
startText.Name = "Text"
startText.BackgroundTransparency = 1
startText.Size = UDim2.fromScale(1, 1)
startText.Font = if UiTheme.Font.Title == "FredokaOne"
	then Enum.Font.FredokaOne
	else Enum.Font.GothamBold
startText.Text = string.format("START HERE\nStand for %d seconds", Lobby.StartPadSeconds)
startText.TextColor3 = color(UiTheme.Colors.Text)
startText.TextScaled = true
startText.Parent = billboard

local enteredAt: { [Player]: number } = {}

local function isOnPad(player: Player): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local localPosition = startPad.CFrame:PointToObjectSpace(root.Position)
	return math.abs(localPosition.X) <= startPad.Size.X / 2
		and math.abs(localPosition.Z) <= startPad.Size.Z / 2
		and localPosition.Y >= 0
		and localPosition.Y <= 7
end

local function sendParty(userIds: { number }, partyNumber: number)
	local spacing = 4
	-- Between runs the party starts the next run; mid-run it joins at the next intermission
	-- (WaveManager admits waiting InArena players with catch-up coins).
	local phase = GameState.get("Phase")
	local joinNow = phase == "idle" or phase == "over"
	local leader = Players:GetPlayerByUserId(userIds[1])
	if joinNow and leader then
		local map = Campaign.get(leader:GetAttribute("SelectedMapId") :: string?)
		local profile = PlayerData.profile(leader)
		local selectedTier = leader:GetAttribute("SelectedDifficulty")
		local tier = if type(selectedTier) == "string"
				and Lobby.canSelectDifficulty(profile, map.Id, selectedTier)
			then selectedTier
			else Difficulty.Default
		GameState.set("MapId", map.Id)
		GameState.set("MapName", map.Name)
		local selectedStage = leader:GetAttribute("SelectedStage")
		local stageNumber = if type(selectedStage) == "number" then math.floor(selectedStage) else 1
		if not Lobby.canSelectStage(profile, map.Id, tier, stageNumber) then
			stageNumber = CoreStages.DefaultStage
		end
		GameState.set("Stage", stageNumber)
		GameState.set("Difficulty", tier)
	end
	for index, userId in userIds do
		local player = Players:GetPlayerByUserId(userId)
		if player and isOnPad(player) then
			player:SetAttribute("LobbyParty", partyNumber)
			player:SetAttribute("InArena", true)
			player.RespawnLocation = arenaSpawn
			if not joinNow then
				continue
			end
			PlayerData.setWaiting(player, false)
			local character = player.Character
			if character then
				local x = (index - (#userIds + 1) / 2) * spacing
				character:PivotTo(
					CFrame.new(
						Places.ArenaArrival.x + x,
						Places.ArenaArrival.y,
						Places.ArenaArrival.z
					)
				)
			end
		end
	end
end

local function stagePlayer(player: Player)
	player:SetAttribute("SelectedMapId", Campaign.DefaultId)
	player:SetAttribute("SelectedDifficulty", Difficulty.Default)
	player:SetAttribute("SelectedStage", CoreStages.DefaultStage)
	player:SetAttribute("InArena", false)
	player.RespawnLocation = lobbySpawn
	player.CharacterAdded:Connect(function(character)
		if player:GetAttribute("InArena") ~= true then
			character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 3, 0))
		end
	end)
	if player.Character then
		player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 3, 0))
	end
end

Players.PlayerAdded:Connect(stagePlayer)
Players.PlayerRemoving:Connect(function(player)
	enteredAt[player] = nil
end)
for _, player in Players:GetPlayers() do
	stagePlayer(player)
end

local nextPartyNumber = 0
while true do
	local now = os.clock()
	local readyUserIds = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InArena") ~= true and isOnPad(player) then
			local since = enteredAt[player]
			if not since then
				enteredAt[player] = now
			elseif Lobby.isPadReady(since, now) then
				table.insert(readyUserIds, player.UserId)
			end
		else
			enteredAt[player] = nil
		end
	end
	-- Pad countdown: show the time left for whoever has stood on it longest.
	local earliest: number? = nil
	for _, since in enteredAt do
		if not earliest or since < earliest then
			earliest = since
		end
	end
	startText.Text = if earliest
		then string.format(
			"LAUNCH IN %d",
			math.max(1, math.ceil(Lobby.StartPadSeconds - (now - earliest)))
		)
		else string.format("START HERE\nStand for %d seconds", Lobby.StartPadSeconds)
	for _, party in Lobby.groupParties(readyUserIds) do
		nextPartyNumber += 1
		sendParty(party, nextPartyNumber)
	end
	task.wait(0.1)
end
