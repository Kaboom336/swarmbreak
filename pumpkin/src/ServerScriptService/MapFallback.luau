--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Ride = require(Shared:WaitForChild("Ride"))
local VisualRules = require(Shared:WaitForChild("VisualRules"))

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
local YELLOW = Color3.fromRGB(255, 212, 0)
local CYAN = Color3.fromRGB(0, 217, 255)
local QUIET_ORANGE = Color3.fromRGB(183, 75, 21)
local QUIET_PURPLE = Color3.fromRGB(74, 39, 104)

export type ZoneParts = {
	start: BasePart,
	track: Model,
	walls: { BasePart },
	gate: BasePart,
}

local MapFallback = {}
local makePart: (string, Vector3, CFrame, Color3) -> Part
local activeMapLights = 0

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

local function addBandPart(
	parent: Instance,
	name: string,
	size: Vector3,
	frame: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local part = makePart(name, size, frame, color)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.CanTouch = false
	part.Parent = parent
	return part
end

local function buildJackOLantern(parent: Instance, frame: CFrame, scale: number): Model
	local model = Instance.new("Model")
	model.Name = "JackOLantern"
	model.Parent = parent
	addBandPart(
		model,
		"DarkUnderside",
		Vector3.new(7.2, 4.6, 6.2) * scale,
		frame * CFrame.new(0, 2.25 * scale, 0),
		QUIET_ORANGE:Lerp(INK, 0.34),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	for rib = -2, 2 do
		addBandPart(
			model,
			"PumpkinRib",
			Vector3.new(2.6, 5.2, 6.4) * scale,
			frame * CFrame.new(rib * 1.02 * scale, 2.7 * scale, 0),
			if rib % 2 == 0 then ORANGE else Color3.fromRGB(226, 80, 8),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
	end
	addBandPart(
		model,
		"TopHighlight",
		Vector3.new(4.6, 0.34, 4.4) * scale,
		frame * CFrame.new(0, 5.05 * scale, 0),
		Color3.fromRGB(255, 151, 42),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	addBandPart(
		model,
		"Stem",
		Vector3.new(1.1, 2.2, 1.1) * scale,
		frame * CFrame.new(0, 6 * scale, 0) * CFrame.Angles(0, 0, math.rad(-12)),
		Color3.fromRGB(74, 115, 44),
		Enum.Material.Wood
	)
	for index, offset in { Vector3.new(-1.35, 3.15, -3), Vector3.new(1.35, 3.15, -3) } do
		local eye = addBandPart(
			model,
			"FaceGlow_" .. index,
			Vector3.new(1.05, 1.05, 0.18) * scale,
			frame * CFrame.new(offset * scale),
			YELLOW,
			Enum.Material.Neon
		)
		eye.CanCollide = false
	end
	return model
end

local function buildFence(parent: Instance, frame: CFrame, scale: number)
	local model = Instance.new("Model")
	model.Name = "Fence"
	model.Parent = parent
	for x = -1, 1 do
		addBandPart(
			model,
			"FencePost",
			Vector3.new(0.75, 5.8, 0.75) * scale,
			frame * CFrame.new(x * 3.8 * scale, 2.9 * scale, 0),
			Color3.fromRGB(73, 42, 30),
			Enum.Material.WoodPlanks
		)
	end
	for y = 1.8, 4.2, 2.4 do
		addBandPart(
			model,
			"FenceRail",
			Vector3.new(8.2, 0.72, 0.58) * scale,
			frame
				* CFrame.new(0, y * scale, 0)
				* CFrame.Angles(0, 0, math.rad(if y < 3 then -4 else 4)),
			Color3.fromRGB(132, 79, 44),
			Enum.Material.WoodPlanks
		)
	end
	addBandPart(
		model,
		"FenceHighlight",
		Vector3.new(7.7, 0.16, 0.66) * scale,
		frame * CFrame.new(0, 4.58 * scale, -0.05),
		Color3.fromRGB(191, 119, 62),
		Enum.Material.WoodPlanks
	)
end

local function buildGravestone(parent: Instance, frame: CFrame, scale: number)
	local model = Instance.new("Model")
	model.Name = "Gravestone"
	model.Parent = parent
	addBandPart(
		model,
		"GraveShadow",
		Vector3.new(4.8, 5.7, 1.65) * scale,
		frame * CFrame.new(0, 2.85 * scale, 0.25 * scale),
		Color3.fromRGB(48, 47, 66),
		Enum.Material.Slate
	)
	addBandPart(
		model,
		"GraveFace",
		Vector3.new(4.35, 5.35, 0.65) * scale,
		frame * CFrame.new(0, 3.05 * scale, -0.72 * scale),
		Color3.fromRGB(105, 105, 132),
		Enum.Material.Slate
	)
	addBandPart(
		model,
		"GraveHighlight",
		Vector3.new(3.5, 0.25, 0.16) * scale,
		frame * CFrame.new(0, 5.2 * scale, -1.08 * scale),
		Color3.fromRGB(172, 172, 192),
		Enum.Material.SmoothPlastic
	)
	addBandPart(
		model,
		"GraveAccent",
		Vector3.new(0.62, 2.5, 0.2) * scale,
		frame * CFrame.new(0, 3.15 * scale, -1.12 * scale),
		PURPLE,
		Enum.Material.Neon
	).CanCollide =
		false
end

local function buildLampPost(parent: Instance, frame: CFrame, lightEnabled: boolean)
	local model = Instance.new("Model")
	model.Name = "LampPost"
	model.Parent = parent
	addBandPart(
		model,
		"LampBase",
		Vector3.new(2.4, 0.8, 2.4),
		frame * CFrame.new(0, 0.4, 0),
		INK,
		Enum.Material.Metal
	)
	addBandPart(
		model,
		"LampPole",
		Vector3.new(0.7, 9, 0.7),
		frame * CFrame.new(0, 4.9, 0),
		Color3.fromRGB(55, 48, 70),
		Enum.Material.Metal
	)
	local lantern = addBandPart(
		model,
		"LampGlow",
		Vector3.new(2.8, 3.1, 2.8),
		frame * CFrame.new(0, 9.7, 0),
		YELLOW,
		Enum.Material.Neon
	)
	lantern.Transparency = 0.12
	if lightEnabled and activeMapLights < VisualRules.MAX_ACTIVE_MAP_LIGHTS then
		activeMapLights += 1
		local light = Instance.new("PointLight")
		light.Name = "WarmPool"
		light.Color = Color3.fromRGB(255, 178, 88)
		light.Brightness = VisualRules.MAP_LIGHT_BRIGHTNESS
		light.Range = VisualRules.MAP_LIGHT_RANGE
		light.Shadows = false
		light.Parent = lantern
	end
end

local function buildCandyArch(parent: Instance, frame: CFrame, scale: number, name: string?)
	local model = Instance.new("Model")
	model.Name = name or "CandyArch"
	model.Parent = parent
	for side = -1, 1, 2 do
		for level = 0, 4 do
			addBandPart(
				model,
				"CandyStripe",
				Vector3.new(2.5, 2.4, 2.5) * scale,
				frame * CFrame.new(side * 8 * scale, (1.2 + level * 2.3) * scale, 0),
				if level % 2 == 0 then ORANGE else PURPLE,
				Enum.Material.SmoothPlastic,
				Enum.PartType.Ball
			)
		end
	end
	for step = -4, 4 do
		local height = 11 + (4 - math.abs(step)) * 0.75
		addBandPart(
			model,
			"ArchSweet",
			Vector3.new(2.5, 2.5, 2.5) * scale,
			frame * CFrame.new(step * 2 * scale, height * scale, 0),
			if step % 2 == 0 then YELLOW else Color3.fromRGB(255, 94, 181),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
	end
end

local function ensureLobby()
	local previous = workspace:FindFirstChild("PumpkinFallbackLobby")
	if previous then
		previous:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "PumpkinFallbackLobby"
	folder.Parent = workspace
	local firstStart = findPart("ZoneStart_" .. Config.Zones[1].Name)
	local plazaCenter = if firstStart
		then firstStart.Position - firstStart.CFrame.LookVector * 48
		else Vector3.new(-48, TRACK_START_Y, 0)
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if not spawn then
		local floor = makePart(
			"PumpkinLobbyFloor",
			Vector3.new(96, 2, 86),
			CFrame.new(plazaCenter - Vector3.new(0, 1.5, 0)),
			TRACK_TEAL
		)
		floor.Material = Enum.Material.Slate
		floor.Parent = folder

		spawn = Instance.new("SpawnLocation")
		spawn.Name = "PumpkinSpawn"
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Size = Vector3.new(16, 1, 16)
		spawn.Color = LIME
		spawn.Parent = folder
	end
	if firstStart then
		spawn.CFrame = CFrame.lookAt(
			plazaCenter + Vector3.new(0, 0.5, 0),
			firstStart.Position + Vector3.new(0, 4, 0)
		)
	end

	local art = Instance.new("Model")
	art.Name = "CompactPlazaArt"
	art.Parent = folder
	for _, side in { -1, 1 } do
		local cliff = addBandPart(
			art,
			"PlazaCliff",
			Vector3.new(90, 22, 10),
			CFrame.new(plazaCenter + Vector3.new(-4, 8, side * 48)),
			QUIET_PURPLE,
			Enum.Material.Rock
		)
		cliff:SetAttribute("ValueBandCount", VisualRules.REQUIRED_VALUE_BANDS)
		for offset = -36, 36, 18 do
			buildFence(art, CFrame.new(plazaCenter + Vector3.new(offset, 0, side * 41)), 0.8)
		end
	end
	addBandPart(
		art,
		"PlazaBackCliff",
		Vector3.new(10, 25, 96),
		CFrame.new(plazaCenter - Vector3.new(52, -9, 0)),
		QUIET_PURPLE:Lerp(INK, 0.2),
		Enum.Material.Rock
	)
	if firstStart then
		buildCandyArch(
			art,
			CFrame.lookAt(firstStart.Position, firstStart.Position + firstStart.CFrame.LookVector),
			1.15,
			"DominantLandmark_CandyArch"
		)
		buildJackOLantern(
			art,
			CFrame.new(firstStart.Position - firstStart.CFrame.RightVector * 23),
			1.55
		)
		buildLampPost(
			art,
			CFrame.new(firstStart.Position + firstStart.CFrame.RightVector * 22),
			true
		)
	end
	for index, name in { "Leaderboard_Wins", "Leaderboard_Size" } do
		if not findPart(name) then
			local board = makePart(
				name,
				Vector3.new(16, 10, 1),
				CFrame.new(plazaCenter + Vector3.new(-31, 5, (index - 1.5) * 22)),
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

local function buildZoneArt(track: Model, start: BasePart, zone: any, zoneIndex: number)
	local previous = track:FindFirstChild("GeneratedQ4Art")
	if previous then
		previous:Destroy()
	end
	local art = Instance.new("Model")
	art.Name = "GeneratedQ4Art"
	art:SetAttribute("ZoneIdentity", zone.DisplayName)
	art:SetAttribute("ValueBandCount", VisualRules.REQUIRED_VALUE_BANDS)
	art.Parent = track

	local zoneAccent = ({ ORANGE, LIME, CYAN, PURPLE })[zoneIndex] or ORANGE
	local propDistances = { 145, 390, 670, 960, 1_240, 1_500 }
	for propIndex, distance in propDistances do
		local position, tangent, right = pathWorld(start, distance)
		local side = if propIndex % 2 == 0 then -1 else 1
		local frame = CFrame.lookAt(
			position + right * side * 24,
			position + right * side * 24 + tangent,
			Vector3.yAxis
		)
		if zoneIndex == 1 then
			if propIndex % 2 == 0 then
				buildFence(art, frame, 1.15)
			else
				buildJackOLantern(art, frame, 0.9 + propIndex * 0.04)
			end
		elseif zoneIndex == 2 then
			buildFence(art, frame, 1.05)
			local tree = addBandPart(
				art,
				"HauntedTree",
				Vector3.new(3.2, 16, 3.2),
				frame * CFrame.new(0, 8, 2),
				Color3.fromRGB(69, 43, 58),
				Enum.Material.Wood
			)
			tree.CFrame *= CFrame.Angles(0, 0, math.rad(side * 8))
			addBandPart(
				art,
				"TreeGlow",
				Vector3.new(4.4, 4.4, 4.4),
				frame * CFrame.new(0, 14, 1),
				LIME:Lerp(INK, 0.28),
				Enum.Material.SmoothPlastic,
				Enum.PartType.Ball
			)
		elseif zoneIndex == 3 then
			buildGravestone(art, frame, 1.2)
			buildGravestone(art, frame * CFrame.new(side * 5, 0, 3), 0.78)
		else
			buildCandyArch(art, frame, 0.62)
		end
		if propIndex == 1 or propIndex == 4 then
			buildLampPost(art, frame * CFrame.new(side * 7, 0, -4), true)
		end
	end

	local landmarkPosition, landmarkTangent, landmarkRight = pathWorld(start, 820)
	local landmarkFrame = CFrame.lookAt(
		landmarkPosition + landmarkRight * 29,
		landmarkPosition + landmarkRight * 29 + landmarkTangent,
		Vector3.yAxis
	)
	if zoneIndex == 1 then
		local landmark = buildJackOLantern(art, landmarkFrame, 2.3)
		landmark.Name = "DominantLandmark_GiantJack"
	elseif zoneIndex == 2 then
		buildCandyArch(art, landmarkFrame, 1.25, "DominantLandmark_MoonGate")
	elseif zoneIndex == 3 then
		local landmark = Instance.new("Model")
		landmark.Name = "DominantLandmark_Crypt"
		landmark.Parent = art
		buildGravestone(landmark, landmarkFrame, 2.2)
		buildLampPost(landmark, landmarkFrame * CFrame.new(-7, 0, 1), true)
	else
		buildCandyArch(art, landmarkFrame, 1.5, "DominantLandmark_WitchCastleGate")
	end

	local finishPosition, finishTangent = pathWorld(start, Config.RideTrackLength - 35)
	local finishFrame = CFrame.lookAt(finishPosition, finishPosition + finishTangent, Vector3.yAxis)
	buildCandyArch(art, finishFrame, 1.05, "FinishSetPiece_" .. zone.Name)
	if zoneIndex == 1 then
		buildLampPost(art, finishFrame * CFrame.new(-20, 0, 0), true)
	end
	local finishAccent = addBandPart(
		art,
		"FinishSetPiece_Glow",
		Vector3.new(22, 0.22, 5),
		finishFrame * CFrame.new(0, 1.15, 0),
		zoneAccent,
		Enum.Material.Neon
	)
	finishAccent.CanCollide = false
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
	local outline = Instance.new("Highlight")
	outline.Name = "HazardSeparation"
	outline.Adornee = obstacle
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.FillTransparency = 1
	outline.OutlineColor = INK
	outline.OutlineTransparency = 0.18
	outline.Parent = obstacle

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
	buildZoneArt(track, start, zone, zoneIndex)

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
		local stand = findPart(name)
		if not stand then
			stand = makePart(
				name,
				Vector3.new(10, 2, 10),
				CFrame.new(-24, TRACK_START_Y + 1, (index - 1) * ZONE_GAP),
				INK:Lerp(PURPLE, 0.32)
			)
			stand.Parent = workspace
		end
		local previous = stand:FindFirstChild("GeneratedQ4EggVisual")
		if previous then
			previous:Destroy()
		end
		local visual = Instance.new("Model")
		visual.Name = "GeneratedQ4EggVisual"
		visual.Parent = stand
		local eggModel = addBandPart(
			visual,
			"EggModel",
			Vector3.new(6.6, 8.5, 6.6),
			stand.CFrame * CFrame.new(0, 5.1, 0),
			({ ORANGE, PURPLE, Color3.fromRGB(202, 211, 214) })[index] or ORANGE,
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		eggModel.CanCollide = false
		addBandPart(
			visual,
			"EggUnderside",
			Vector3.new(6.8, 1.3, 6.8),
			stand.CFrame * CFrame.new(0, 1.45, 0),
			INK:Lerp(PURPLE, 0.22),
			Enum.Material.Slate,
			Enum.PartType.Cylinder
		)
		local highlight = addBandPart(
			visual,
			"EggHighlight",
			Vector3.new(1.3, 4.8, 0.28),
			stand.CFrame * CFrame.new(-1.55, 6, -3.05) * CFrame.Angles(0, 0, math.rad(-16)),
			Color3.fromRGB(255, 242, 190),
			Enum.Material.Neon
		)
		highlight.CanCollide = false
		local eggOutline = Instance.new("Highlight")
		eggOutline.Name = "EggSeparation"
		eggOutline.Adornee = visual
		eggOutline.DepthMode = Enum.HighlightDepthMode.Occluded
		eggOutline.FillTransparency = 1
		eggOutline.OutlineColor = INK
		eggOutline.OutlineTransparency = 0.08
		eggOutline.Parent = visual
		for rarityIndex, rarityColor in { ORANGE, LIME, CYAN, PURPLE, YELLOW } do
			local preview = addBandPart(
				visual,
				"RarityPreview_" .. rarityIndex,
				Vector3.new(0.9, 0.9, 0.9),
				stand.CFrame * CFrame.new((rarityIndex - 3) * 1.3, 1.35, -4.3),
				rarityColor,
				if rarityIndex >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
				Enum.PartType.Ball
			)
			preview.CanCollide = false
		end
		local badge = Instance.new("BillboardGui")
		badge.Name = "EggCostBadge"
		badge.AlwaysOnTop = true
		badge.MaxDistance = 90
		badge.Size = UDim2.fromOffset(190, 58)
		badge.StudsOffsetWorldSpace = Vector3.new(0, 10.5, 0)
		badge.Adornee = stand
		badge.Parent = stand
		local text = Instance.new("TextLabel")
		text.Name = "CostAndFreeBadge"
		text.BackgroundColor3 = PURPLE
		text.BackgroundTransparency = 0.08
		text.BorderSizePixel = 0
		text.Font = Enum.Font.GothamBlack
		text.Size = UDim2.fromScale(1, 1)
		text.Text = string.format(
			"%s\n%d WINS%s",
			egg.DisplayName,
			egg.Cost,
			if index == 1 then "  |  FIRST FREE" else ""
		)
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextScaled = true
		text.TextStrokeColor3 = INK
		text.TextStrokeTransparency = 0
		text.Parent = badge
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = text
		local stroke = Instance.new("UIStroke")
		stroke.Color = INK
		stroke.Thickness = 3
		stroke.Parent = text
		local prompt = stand:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "HatchPrompt"
			prompt.Parent = stand
		end
		prompt.ActionText = "HATCH"
		prompt.ObjectText = egg.DisplayName
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
	end
end

function MapFallback.build(): { [string]: ZoneParts }
	activeMapLights = 0
	ensureGround()
	ensureEggStands()
	local result = {}
	for zoneIndex, zone in Config.Zones do
		result[zone.Name] = ensureTrack(zone, zoneIndex)
	end
	ensureLobby()
	disableGateCameraQueries()
	return result
end

return MapFallback
