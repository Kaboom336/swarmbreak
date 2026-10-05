--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FriendBoost = require(Shared:WaitForChild("FriendBoost"))
local Grow = require(Shared:WaitForChild("Grow"))
local PetIndex = require(Shared:WaitForChild("PetIndex"))
local Ride = require(Shared:WaitForChild("Ride"))
local RideSurface = require(Shared:WaitForChild("RideSurface"))
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
local rollControl = remotes:FindFirstChild("RollControl") :: RemoteEvent
local limiter = Grow.newRateLimiter()
local rolling: { [Player]: boolean } = {}
local zoneParts = MapFallback.build()
local friendsByPlayer: { [Player]: { [Player]: boolean } } = {}
local rideStates: { [Player]: any } = {}
local controlWindows: { [Player]: { startedAt: number, count: number } } = {}
local nextRideToken = 0

local function allowRideControl(player: Player, now: number): boolean
	local window = controlWindows[player]
	if not window or now - window.startedAt >= 1 then
		controlWindows[player] = { startedAt = now, count = 1 }
		return true
	end
	if window.count >= Config.RideRemotePerSecond then
		return false
	end
	window.count += 1
	return true
end

local function createRidePumpkin(player: Player, size: number, start: BasePart): (Part, Seat?, any)
	local diameter = Config.PumpkinBaseDiameter * Grow.pumpkinScale(size)
	local pumpkin = Instance.new("Part")
	pumpkin.Name = "RollingPumpkin_" .. player.UserId
	pumpkin.Shape = Enum.PartType.Ball
	pumpkin.Anchored = true
	pumpkin.CanCollide = false
	pumpkin.CanQuery = false
	pumpkin.CanTouch = false
	pumpkin.Color = Color3.fromRGB(255, 116, 25)
	pumpkin.Material = Enum.Material.SmoothPlastic
	pumpkin.Transparency = 0.28
	pumpkin.Size = Vector3.new(diameter, diameter * 0.82, diameter)
	pumpkin.CFrame = CFrame.new(start.Position + Vector3.new(0, diameter * 0.5 + 1, 0))

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = Config.PumpkinMeshId
	mesh.TextureId = Config.PumpkinTextureId
	mesh.Scale = Vector3.new(diameter, diameter * 0.82, diameter) * Config.PumpkinMeshScale
	mesh.Parent = pumpkin
	pumpkin.Parent = workspace

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		return pumpkin, nil, nil
	end
	local rider = {
		humanoid = humanoid,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
		autoRotate = humanoid.AutoRotate,
		jumpingEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping),
		transparencies = {},
		restored = false,
	}
	humanoid.Jump = false
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			rider.transparencies[descendant] = descendant.Transparency
			local readable = descendant.Name == "Head"
				or descendant.Name == "UpperTorso"
				or descendant.Name == "Torso"
			descendant.Transparency = if readable then descendant.Transparency else 1
		end
	end
	local seat = Instance.new("Seat")
	seat.Name = "RideSeat"
	seat.Anchored = false
	seat.CanCollide = false
	seat.CanQuery = false
	seat.CanTouch = false
	seat.Massless = true
	seat.Transparency = 1
	seat.Size = Vector3.new(2, 1, 2)
	seat.CFrame = pumpkin.CFrame - Vector3.new(0, math.min(0.6, diameter * 0.08), 0)
	seat.Parent = pumpkin
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = pumpkin
	weld.Part1 = seat
	weld.Parent = seat
	seat:Sit(humanoid)
	return pumpkin, seat, rider
end

local function restoreRider(rider: any)
	if not rider or rider.restored then
		return
	end
	rider.restored = true
	local humanoid = rider.humanoid
	if humanoid and humanoid.Parent then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, rider.jumpingEnabled)
		humanoid.JumpPower = rider.jumpPower
		humanoid.JumpHeight = rider.jumpHeight
		humanoid.AutoRotate = rider.autoRotate
		humanoid.Sit = false
	end
	for part, transparency in rider.transparencies do
		if part.Parent then
			part.Transparency = transparency
		end
	end
end

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
	player:SetAttribute("IndexMultiplier", PetIndex.sizeMultiplier(profile.DiscoveredPets))
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
		indexBonus = PetIndex.sizeMultiplier(profile.DiscoveredPets) - 1,
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
	-- Re-measure once the avatar's parts have loaded, so the pumpkin isn't sized from a half-built rig
	if not player:HasAppearanceLoaded() then
		local loaded = false
		local connection = player.CharacterAppearanceLoaded:Connect(function()
			loaded = true
		end)
		local deadline = os.clock() + 8
		while not loaded and os.clock() < deadline and character.Parent do
			task.wait(0.25)
		end
		connection:Disconnect()
	end
	local current = Data.get(player)
	if current and player.Character == character then
		PumpkinVisual.update(character, current.Size)
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
	player:SetAttribute("Rolling", false)
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

rollControl.OnServerEvent:Connect(function(player: Player, action: any, token: any, value: any)
	local now = workspace:GetServerTimeNow()
	if not allowRideControl(player, now) then
		return
	end
	local state = rideStates[player]
	if not state or token ~= state.token then
		return
	end
	if action == "Steer" then
		if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
			return
		end
		state.lane = math.clamp(value, -1, 1)
	elseif action == "Pickup" then
		if type(value) ~= "number" or value % 1 ~= 0 then
			return
		end
		local target = state.layout[value]
		local relative = state.pumpkin.Position - state.startPosition
		local worldLane = relative:Dot(state.right) / Config.RideLaneStuds
		local accepted = Ride.validatePickup(
			target,
			now - state.startedAt,
			state.physicalDuration,
			worldLane,
			state.claimed,
			state.claimedCount
		)
		if not accepted then
			return
		end
		state.claimed[value] = true
		state.claimedCount += 1
		table.insert(state.kinds, target.kind)
		if target.kind == "SpeedPad" then
			state.speedBoostUntil = now + Config.RideSpeedPadSeconds
		end
		rollControl:FireClient(player, "PickupAccepted", token, value, target.kind)
	end
end)

local function beginRoll(player: Player, zone: any, parts: any)
	local profile = Data.get(player)
	if rolling[player] or not profile or profile.Size <= 0 then
		return
	end
	if not Roll.isZoneUnlocked(profile.TotalWins, zone) then
		return
	end

	rolling[player] = true
	player:SetAttribute("Rolling", true)
	player:SetAttribute("CurrentZone", zone.Name)
	local rolledSize = profile.Size
	local result = Roll.simulate(rolledSize, zone, #parts.walls)
	local duration = Roll.duration(result.distance, rolledSize, result.bonusWalls)
	local physicalDuration = Ride.physicalDuration(rolledSize)
	local bonusDuration = Ride.bonusDuration(result.bonusWalls)
	local bonusDistance = result.bonusWalls * Config.WallSpacing
	local physicalDistance = math.max(0, result.distance - bonusDistance)
	nextRideToken += 1
	local token = nextRideToken
	local seed = player.UserId * 1_009 + token * 7_919
	local startedAt = workspace:GetServerTimeNow() + Config.RideLatchSeconds
	local pumpkin, seat, rider = createRidePumpkin(player, rolledSize, parts.start)
	local direction = parts.start.CFrame.LookVector.Unit
	local horizontal = Vector3.new(direction.X, 0, direction.Z).Unit
	local right = Vector3.new(-horizontal.Z, 0, horizontal.X)
	local petMultipliers = equippedPetMultipliers(profile)
	local petMultiplier = if #petMultipliers > 0 then 0 else 1
	for _, multiplier in petMultipliers do
		petMultiplier += multiplier
	end
	local winMultipliers = {
		petMultiplier,
		1 + profile.Rebirths * Config.RebirthSizeBonus,
		if profile.DoubleWins then 2 else 1,
		if profile.VIP then 1.5 else 1,
	}
	local state = {
		token = token,
		seed = seed,
		startedAt = startedAt,
		duration = duration,
		physicalDuration = physicalDuration,
		bonusDuration = bonusDuration,
		physicalDistance = physicalDistance,
		bonusDistance = bonusDistance,
		distance = result.distance,
		lane = 0,
		layout = Ride.layout(seed, physicalDuration),
		claimed = {},
		claimedCount = 0,
		kinds = {},
		pumpkin = pumpkin,
		seat = seat,
		rider = rider,
		baseWins = result.wins,
		winMultipliers = winMultipliers,
		speedBoostUntil = 0,
		speedBonusElapsed = 0,
		startPosition = parts.start.Position,
		direction = direction,
		horizontal = horizontal,
		right = right,
		surfaces = RideSurface.collect(parts.track),
	}
	rideStates[player] = state
	if rider then
		state.deathConnection = rider.humanoid.Died:Connect(function()
			if rideStates[player] == state then
				rideStates[player] = nil
				rolling[player] = nil
				player:SetAttribute("Rolling", false)
			end
		end)
	end
	-- Credit the guaranteed wins in the same step that consumes Size, so leaving or a shutdown mid-ride
	-- loses nothing; only the ride pickups are settled when the ride completes.
	local guaranteedWins = Ride.finalWins(result.wins, {}, winMultipliers)
	state.guaranteedWins = guaranteedWins
	profile.Size = 0
	profile.Wins += guaranteedWins
	profile.TotalWins += guaranteedWins
	-- Only a paying roll finishes onboarding, so a too-early roll keeps the tutorial
	if result.wins > 0 and not profile.TutorialDone then
		profile.TutorialDone = true
		player:SetAttribute("TutorialDone", true)
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
		duration,
		#parts.walls,
		result.bonusWalls,
		token,
		seed,
		startedAt
	)

	task.spawn(function()
		local radius = pumpkin.Size.X * 0.5
		local lastUpdate = workspace:GetServerTimeNow()
		while rideStates[player] == state do
			local now = workspace:GetServerTimeNow()
			local deltaTime = math.max(0, now - lastUpdate)
			lastUpdate = now
			if now < state.speedBoostUntil then
				state.speedBonusElapsed += deltaTime * (Config.RideSpeedPadMultiplier - 1)
			end
			local elapsed = now - startedAt + state.speedBonusElapsed
			local traveled = Ride.distanceAtTime(
				elapsed,
				physicalDuration,
				physicalDistance,
				bonusDuration,
				bonusDistance
			)
			local nominalPosition = parts.start.Position
				+ direction * traveled
				+ right * (state.lane * Config.RideLaneStuds)
			local position, normal, tangent =
				RideSurface.sample(state.surfaces, nominalPosition, radius, direction)
			pumpkin.CFrame = CFrame.lookAt(position, position + tangent, normal)
				* CFrame.Angles(Ride.axleRotation(traveled, radius), 0, 0)
			if seat and rider and seat.Occupant ~= rider.humanoid and rider.humanoid.Health > 0 then
				seat:Sit(rider.humanoid)
			end
			if traveled >= result.distance then
				break
			end
			RunService.Heartbeat:Wait()
		end

		if rideStates[player] ~= state then
			restoreRider(state.rider)
			if state.deathConnection then
				state.deathConnection:Disconnect()
			end
			if pumpkin.Parent then
				pumpkin:Destroy()
			end
			return
		end
		local finalWins = Ride.finalWins(result.wins, state.kinds, state.winMultipliers)
		local current = Data.get(player)
		local pickupWins = math.max(0, finalWins - state.guaranteedWins)
		if current and pickupWins > 0 then
			current.Wins += pickupWins
			current.TotalWins += pickupWins
			Data.markDirty(player)
		end
		rideStates[player] = nil
		if state.deathConnection then
			state.deathConnection:Disconnect()
		end
		restoreRider(state.rider)
		if seat then
			seat:Destroy()
		end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			local returnDirection = Vector3.new(
				parts.start.CFrame.LookVector.X,
				0,
				parts.start.CFrame.LookVector.Z
			).Unit
			local returnPosition = parts.start.Position
				+ returnDirection * 20
				+ Vector3.new(0, 4, 0)
			root.CFrame = CFrame.lookAt(returnPosition, returnPosition + returnDirection)
		end
		rollControl:FireClient(player, "Complete", token, finalWins, state.claimedCount)
		local fade = TweenService:Create(pumpkin, TweenInfo.new(0.3), { Transparency = 1 })
		fade:Play()
		fade.Completed:Connect(function()
			if pumpkin.Parent then
				pumpkin:Destroy()
			end
		end)
		player:SetAttribute("Rolling", false)
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
	EconomyService.playerRemoving(player)
	removeFriendships(player)
	limiter:clear(player)
	rolling[player] = nil
	controlWindows[player] = nil
	local ride = rideStates[player]
	if ride then
		restoreRider(ride.rider)
		if ride.deathConnection then
			ride.deathConnection:Disconnect()
		end
	end
	if ride and ride.pumpkin and ride.pumpkin.Parent then
		ride.pumpkin:Destroy()
	end
	rideStates[player] = nil

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
