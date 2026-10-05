--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Ride = require(Shared:WaitForChild("Ride"))

local TRACK_WIDTH = 34
local TRACK_START_Y = 620
local TRACK_SEGMENT_LENGTH = 50
local TRACK_WALL_HEIGHT = 14
local ZONE_GAP = 110
local ORANGE = Color3.fromRGB(255, 107, 0)
local PURPLE = Color3.fromRGB(139, 44, 255)
local LIME = Color3.fromRGB(183, 255, 26)
local MAGENTA = Color3.fromRGB(255, 45, 149)
local INK = Color3.fromRGB(23, 18, 37)
local QUIET_GRASS = Color3.fromRGB(76, 142, 67)
local TRACK_TEAL = Color3.fromRGB(21, 82, 88)

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
		existing.Color = QUIET_GRASS
		existing.Material = Enum.Material.Grass
		return
	end
	local scenery = Instance.new("Folder")
	scenery.Name = "FallbackGroundScenery"
	scenery.Parent = workspace

	local ground = makePart(
		"Ground",
		Vector3.new(2000, 8, 2000),
		CFrame.new(250, 0, (#Config.Zones - 1) * ZONE_GAP * 0.5),
		QUIET_GRASS
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
			if index % 3 == 0 then Color3.fromRGB(186, 151, 54) else Color3.fromRGB(181, 77, 42)
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
			CFrame.new(-35, TRACK_START_Y - 1.5, (#Config.Zones - 1) * ZONE_GAP * 0.5),
			TRACK_TEAL
		)
		floor.Material = Enum.Material.Slate
		floor.Parent = folder

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PumpkinSpawn"
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Size = Vector3.new(16, 1, 16)
		spawn.Position = Vector3.new(-55, TRACK_START_Y, 0)
		spawn.Color = LIME
		spawn.Parent = folder
	end
	for index, name in { "Leaderboard_Wins", "Leaderboard_Size" } do
		if not findPart(name) then
			local board = makePart(
				name,
				Vector3.new(16, 10, 1),
				CFrame.new(-45, TRACK_START_Y + 5, (index - 1.5) * 22),
				PURPLE:Lerp(INK, 0.35)
			)
			board.Parent = folder
		end
	end
end

local function pathWorld(start: BasePart, distance: number): (Vector3, Vector3, Vector3, number)
	local sample = Ride.pathSample(distance)
	local horizontal = Vector3.new(start.CFrame.LookVector.X, 0, start.CFrame.LookVector.Z).Unit
	local right = Vector3.new(-horizontal.Z, 0, horizontal.X)
	local position = start.Position
		+ horizontal * sample.forward
		+ Vector3.yAxis * sample.height
		+ right * sample.lateral
	local tangent = (
		horizontal * sample.forwardTangent
		+ Vector3.yAxis * sample.heightTangent
		+ right * sample.lateralTangent
	).Unit
	local pathRight = tangent:Cross(Vector3.yAxis)
	if pathRight.Magnitude < 1e-4 then
		pathRight = right
	else
		pathRight = pathRight.Unit
	end
	return position, tangent, pathRight, sample.bank
end

local function buildObstacle(track: Model, start: BasePart, wave: any, lane: number)
	local center, tangent, right, bank = pathWorld(start, wave.distance)
	local position = center + right * (lane * Config.RideLaneStuds) + Vector3.new(0, 2.1, 0)
	local obstacle: Part
	if wave.kind == "RollingLog" then
		obstacle = makePart(
			string.format("Obstacle_%d_RollingLog_%d", wave.id, lane),
			Vector3.new(2.8, 8, 2.8),
			CFrame.lookAt(position, position + tangent, Vector3.yAxis)
				* CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(111, 59, 34)
		)
		obstacle.Shape = Enum.PartType.Cylinder
		obstacle.Material = Enum.Material.Wood
	elseif wave.kind == "Tombstone" then
		obstacle = makePart(
			string.format("Obstacle_%d_Tombstone_%d", wave.id, lane),
			Vector3.new(5, 7, 2),
			CFrame.lookAt(position + Vector3.new(0, 1.2, 0), position + tangent, Vector3.yAxis),
			Color3.fromRGB(91, 91, 116)
		)
		obstacle.Material = Enum.Material.Slate
	else
		obstacle = makePart(
			string.format("Obstacle_%d_LowFence_%d", wave.id, lane),
			Vector3.new(8, 3.5, 1.4),
			CFrame.lookAt(position, position + tangent, Vector3.yAxis),
			Color3.fromRGB(246, 142, 49)
		)
		obstacle.Material = Enum.Material.WoodPlanks
	end
	obstacle.CanCollide = false
	obstacle.CanTouch = false
	obstacle:SetAttribute("WaveId", wave.id)
	obstacle:SetAttribute("Lane", lane)
	obstacle:SetAttribute("Bank", bank)
	obstacle.Parent = track

	local warning = makePart(
		string.format("ObstacleWarning_%d_%d", wave.id, lane),
		Vector3.new(7, 0.16, Config.RideTopSpeed * Config.RideObstacleReactionSeconds),
		CFrame.lookAt(
			position
				- tangent * (Config.RideTopSpeed * Config.RideObstacleReactionSeconds * 0.5)
				- Vector3.new(0, 2, 0),
			position,
			Vector3.yAxis
		),
		MAGENTA
	)
	warning.Material = Enum.Material.Neon
	warning.Transparency = 0.35
	warning.CanCollide = false
	warning.CanTouch = false
	warning.CanQuery = false
	warning.Parent = track
end

local function buildSafeLaneMarker(track: Model, start: BasePart, wave: any)
	local center, tangent, right = pathWorld(start, wave.distance)
	local position = center
		+ right * (wave.freeLane * Config.RideLaneStuds)
		+ Vector3.new(0, 1.15, 0)
	for side = -1, 1, 2 do
		local chevron = Instance.new("WedgePart")
		chevron.Name = string.format("SafeLane_%d_%d", wave.id, side)
		chevron.Anchored = true
		chevron.CanCollide = false
		chevron.CanQuery = false
		chevron.CanTouch = false
		chevron.Color = LIME
		chevron.Material = Enum.Material.Neon
		chevron.Size = Vector3.new(3.2, 0.18, 5)
		chevron.CFrame = CFrame.lookAt(position + right * side * 1.5, position + tangent)
			* CFrame.Angles(0, side * math.rad(28), 0)
		chevron.Transparency = 0.2
		chevron.Parent = track
	end
end

local function buildChute(track: Model, start: BasePart, rideSeed: number)
	local segmentCount = math.ceil(Config.RideTrackLength / TRACK_SEGMENT_LENGTH)
	for segmentIndex = 1, segmentCount do
		local fromDistance = (segmentIndex - 1) * TRACK_SEGMENT_LENGTH
		local toDistance = math.min(Config.RideTrackLength, segmentIndex * TRACK_SEGMENT_LENGTH)
		local from = pathWorld(start, fromDistance)
		local to = pathWorld(start, toDistance)
		local midpoint, tangent, right, bank = pathWorld(start, (fromDistance + toDistance) * 0.5)
		local length = (to - from).Magnitude + 0.5
		local frame = CFrame.lookAt(midpoint, midpoint + tangent, Vector3.yAxis)
			* CFrame.Angles(0, 0, bank)
		local floor = makePart(
			"ChuteFloor_" .. segmentIndex,
			Vector3.new(TRACK_WIDTH, 2, length),
			frame,
			TRACK_TEAL
		)
		floor.Material = Enum.Material.Slate
		floor.Parent = track

		local canyon = segmentIndex >= 9 and segmentIndex <= 15
		local wallHeight = if canyon then 24 else TRACK_WALL_HEIGHT
		for _, side in { -1, 1 } do
			local wall = makePart(
				string.format("ChuteWall_%d_%d", segmentIndex, side),
				Vector3.new(2.5, wallHeight, length),
				frame
					+ right * (side * (TRACK_WIDTH * 0.5 + 1.25))
					+ Vector3.new(0, wallHeight * 0.5, 0),
				if canyon then PURPLE:Lerp(INK, 0.62) else PURPLE:Lerp(INK, 0.72)
			)
			wall.Material = if canyon then Enum.Material.Rock else Enum.Material.Slate
			wall.Parent = track
		end

		if segmentIndex >= 18 and segmentIndex <= 21 then
			local roof = makePart(
				"TunnelRoof_" .. segmentIndex,
				Vector3.new(TRACK_WIDTH + 5, 2.5, length),
				frame + Vector3.new(0, 13, 0),
				INK:Lerp(PURPLE, 0.16)
			)
			roof.Material = Enum.Material.Rock
			roof.Parent = track
		end
	end

	for _, wave in Ride.obstacleLayout(rideSeed) do
		for _, lane in wave.lanes do
			buildObstacle(track, start, wave, lane)
		end
		buildSafeLaneMarker(track, start, wave)
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
			CFrame.lookAt(Vector3.new(0, TRACK_START_Y, z), Vector3.new(1, TRACK_START_Y, z)),
			ORANGE
		)
		start.Material = Enum.Material.Neon
		start.Parent = workspace
	end
	local rideSeed = 4_001 + zoneIndex * 997
	start:SetAttribute("RideSeed", rideSeed)

	local trackName = "Track_" .. zone.Name
	local foundTrack = findModel(trackName)
	local track: Model
	if foundTrack and foundTrack:IsA("Model") then
		track = foundTrack
	else
		track = Instance.new("Model")
		track.Name = trackName
		track.Parent = workspace
	end

	local previousChute = track:FindFirstChild("GeneratedQ4Chute")
	if previousChute then
		previousChute:Destroy()
	end
	-- The mounted map already contains its original shallow road. Retire only legacy
	-- surface/rail pieces so it cannot remain visible beneath the authoritative Q4 path;
	-- themed walls and props stay intact for the later model pass.
	for _, descendant in track:GetDescendants() do
		if descendant:IsA("BasePart") and not string.match(descendant.Name, "^Wall_%d+$") then
			local name = string.lower(descendant.Name)
			if
				string.find(name, "floor", 1, true)
				or string.find(name, "road", 1, true)
				or string.find(name, "stripe", 1, true)
				or string.find(name, "rail", 1, true)
			then
				descendant.Transparency = 1
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
			end
		end
	end
	local chute = Instance.new("Model")
	chute.Name = "GeneratedQ4Chute"
	chute.Parent = track
	buildChute(chute, start, rideSeed)

	local walls = {}
	for wallIndex = 1, Config.FallbackWallCount do
		local wallName = "Wall_" .. wallIndex
		local existing = track:FindFirstChild(wallName, true)
		local wall = if existing and existing:IsA("BasePart") then existing else nil
		local position, tangent = pathWorld(start, wallIndex * Config.WallSpacing)
		if not wall then
			wall = makePart(
				wallName,
				Vector3.new(TRACK_WIDTH, 15, 3),
				CFrame.lookAt(position + Vector3.new(0, 7, 0), position + tangent),
				if wallIndex % 2 == 0 then PURPLE else ORANGE
			)
			wall:SetAttribute(
				"Health",
				Config.WallBaseHealth * Config.WallHealthGrowth ^ (wallIndex - 1)
			)
			wall.Parent = track
		else
			wall.CFrame =
				CFrame.lookAt(position + Vector3.new(0, wall.Size.Y * 0.5, 0), position + tangent)
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
			LIME
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
				CFrame.new(-24, TRACK_START_Y + 1, (index - 1) * ZONE_GAP),
				PURPLE
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
