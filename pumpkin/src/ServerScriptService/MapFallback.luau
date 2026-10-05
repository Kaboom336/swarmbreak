--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local TRACK_WIDTH = 34
local TRACK_SLOPE = 0.06
local ZONE_GAP = 110

export type ZoneParts = {
	start: BasePart,
	track: Model,
	walls: { BasePart },
	gate: BasePart,
}

local MapFallback = {}
local makePart: (string, Vector3, CFrame, Color3) -> Part

local function ensureGround()
	local existing = workspace:FindFirstChild("Ground", true)
	if existing and existing:IsA("BasePart") then
		return
	end
	local scenery = Instance.new("Folder")
	scenery.Name = "FallbackGroundScenery"
	scenery.Parent = workspace

	local ground = makePart(
		"Ground",
		Vector3.new(2000, 8, 2000),
		CFrame.new(250, 0, (#Config.Zones - 1) * ZONE_GAP * 0.5),
		Color3.fromRGB(91, 168, 62)
	)
	ground.Material = Enum.Material.Grass
	ground.Parent = scenery

	for index = 1, 28 do
		local side = if index % 2 == 0 then -1 else 1
		local z = -220 + index * 25
		local x = if side < 0 then -80 - (index % 4) * 18 else 630 + (index % 4) * 18
		local trunk = makePart(
			"TreeTrunk_" .. index,
			Vector3.new(3, 14, 3),
			CFrame.new(x, 15, z),
			Color3.fromRGB(104, 63, 35)
		)
		trunk.Material = Enum.Material.Wood
		trunk.Parent = scenery
		local crown = makePart(
			"TreeCrown_" .. index,
			Vector3.new(13, 13, 13),
			CFrame.new(x, 25, z),
			if index % 3 == 0 then Color3.fromRGB(255, 190, 45) else Color3.fromRGB(235, 94, 36)
		)
		crown.Shape = Enum.PartType.Ball
		crown.Parent = scenery
	end
end

local function findPart(name: string): BasePart?
	local named = workspace:FindFirstChild(name, true)
	if named and named:IsA("BasePart") then
		return named
	end
	for _, tagged in CollectionService:GetTagged(name) do
		if tagged:IsA("BasePart") then
			return tagged
		end
	end
	return nil
end

local function findModel(name: string): Model?
	local named = workspace:FindFirstChild(name, true)
	if named and named:IsA("Model") then
		return named
	end
	for _, tagged in CollectionService:GetTagged(name) do
		if tagged:IsA("Model") then
			return tagged
		end
	end
	return nil
end

makePart = function(name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function ensureLobby()
	local folder = workspace:FindFirstChild("PumpkinFallbackLobby")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PumpkinFallbackLobby"
		folder.Parent = workspace
	end
	if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
		local floor = makePart(
			"PumpkinLobbyFloor",
			Vector3.new(80, 2, #Config.Zones * ZONE_GAP),
			CFrame.new(-35, 36.5, (#Config.Zones - 1) * ZONE_GAP * 0.5),
			Color3.fromRGB(22, 70, 74)
		)
		floor.Material = Enum.Material.Slate
		floor.Parent = folder

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PumpkinSpawn"
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Size = Vector3.new(16, 1, 16)
		spawn.Position = Vector3.new(-55, 38, 0)
		spawn.Color = Color3.fromRGB(167, 255, 61)
		spawn.Parent = folder
	end
	for index, name in { "Leaderboard_Wins", "Leaderboard_Size" } do
		if not findPart(name) then
			local board = makePart(
				name,
				Vector3.new(16, 10, 1),
				CFrame.new(-45, 43, (index - 1.5) * 22),
				Color3.fromRGB(83, 42, 145)
			)
			board.Parent = folder
		end
	end
end

local function ensureTrack(zone: any, zoneIndex: number): ZoneParts
	local z = (zoneIndex - 1) * ZONE_GAP
	local startName = "ZoneStart_" .. zone.Name
	local start = findPart(startName)
	if not start then
		start = makePart(
			startName,
			Vector3.new(20, 1, 20),
			CFrame.lookAt(Vector3.new(0, 38, z), Vector3.new(1, 38 - TRACK_SLOPE, z)),
			Color3.fromRGB(255, 116, 25)
		)
		start.Material = Enum.Material.Neon
		start.Parent = workspace
	end

	local trackName = "Track_" .. zone.Name
	local foundTrack = findModel(trackName)
	local track: Model
	local createdTrack = false
	if foundTrack and foundTrack:IsA("Model") then
		track = foundTrack
	else
		track = Instance.new("Model")
		track.Name = trackName
		track.Parent = workspace
		createdTrack = true
	end

	local direction =
		Vector3.new(start.CFrame.LookVector.X, -TRACK_SLOPE, start.CFrame.LookVector.Z).Unit
	local length = (Config.FallbackWallCount + 1) * Config.WallSpacing
	if createdTrack then
		local midpoint = start.Position + direction * (length * 0.5)
		local floor = makePart(
			"FallbackFloor",
			Vector3.new(TRACK_WIDTH, 2, length),
			CFrame.lookAt(midpoint, midpoint + direction),
			Color3.fromRGB(27, 91, 89)
		)
		floor.Material = Enum.Material.Slate
		floor.Parent = track
	end

	local walls = {}
	for wallIndex = 1, Config.FallbackWallCount do
		local wallName = "Wall_" .. wallIndex
		local existing = track:FindFirstChild(wallName, true)
		local wall = if existing and existing:IsA("BasePart") then existing else nil
		if not wall then
			local position = start.Position + direction * (wallIndex * Config.WallSpacing)
			wall = makePart(
				wallName,
				Vector3.new(TRACK_WIDTH, 15, 3),
				CFrame.lookAt(position + Vector3.new(0, 7, 0), position + direction),
				if wallIndex % 2 == 0
					then Color3.fromRGB(151, 64, 255)
					else Color3.fromRGB(255, 116, 25)
			)
			wall:SetAttribute(
				"Health",
				Config.WallBaseHealth * Config.WallHealthGrowth ^ (wallIndex - 1)
			)
			wall.Parent = track
		end
		table.insert(walls, wall)
	end
	local nextWallIndex = Config.FallbackWallCount + 1
	while true do
		local extra = track:FindFirstChild("Wall_" .. nextWallIndex, true)
		if not extra or not extra:IsA("BasePart") then
			break
		end
		table.insert(walls, extra)
		nextWallIndex += 1
	end

	local gateName = "ZoneGate_" .. zone.Name
	local gate = findPart(gateName)
	if not gate then
		gate = makePart(
			gateName,
			Vector3.new(TRACK_WIDTH + 8, 18, 2),
			start.CFrame - start.CFrame.LookVector * 20 + Vector3.new(0, 9, 0),
			Color3.fromRGB(167, 255, 61)
		)
		gate.Material = Enum.Material.ForceField
		gate.Transparency = if zone.RequiredWins == 0 then 1 else 0.25
		gate.CanCollide = false
		gate.Parent = workspace
	end
	gate.CanQuery = false

	return { start = start, track = track, walls = walls, gate = gate }
end

local function disableGateCameraQueries()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("BasePart") then
			local name = string.lower(descendant.Name)
			if
				name == "gatesign"
				or name == "gatearch"
				or name == "gatepillar"
				or name == "arch"
			then
				descendant.CanQuery = false
			end
		end
	end
end

local function ensureEggStands()
	for index, egg in Config.Eggs do
		local name = "Egg_" .. egg.Name
		if not findPart(name) then
			local stand = makePart(
				name,
				Vector3.new(8, 2, 8),
				CFrame.new(-24, 39, (index - 1) * ZONE_GAP),
				Color3.fromRGB(151, 64, 255)
			)
			stand.Parent = workspace
		end
	end
end

function MapFallback.build(): { [string]: ZoneParts }
	ensureGround()
	ensureLobby()
	ensureEggStands()
	local result = {}
	for zoneIndex, zone in Config.Zones do
		result[zone.Name] = ensureTrack(zone, zoneIndex)
	end
	disableGateCameraQueries()
	return result
end

return MapFallback
