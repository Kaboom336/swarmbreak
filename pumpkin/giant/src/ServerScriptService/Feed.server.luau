-- Grow the Pumpkin: pumpkins grow in four fields. A player lifts one (heavier ones need
-- more Strength), carries it through a Magic Cauldron gate (which turns it magic and grants
-- Strength XP), climbs the Pumpkin Pyramid and slams it into a glowing spot on the tier being
-- built. Each tier's lb quota lifts the giant on top; the last tier awakens it.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("GiantConfig"))

local garden = workspace:WaitForChild("Garden")
local fields = garden:WaitForChild("Fields")
local pyramid = garden:WaitForChild("Pyramid")
local socketFolder = pyramid:WaitForChild("Sockets")
local gates = garden:WaitForChild("Gates")
local giant = garden:WaitForChild("Giant") :: BasePart
local giantPlain = garden:WaitForChild("GiantPlain") :: BasePart
local templates = ServerStorage:WaitForChild("KitTemplates")

local dropped = Instance.new("Folder")
dropped.Name = "Dropped"
dropped.Parent = garden

local remotes = Instance.new("Folder")
remotes.Name = "GiantRemotes"
remotes.Parent = ReplicatedStorage
local function remote(name: string, class: string?)
	local r = Instance.new(class or "RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local slammedEvent = remote("Slammed")
local dunkedEvent = remote("Dunked")
local tierEvent = remote("TierDone")
local awakenEvent = remote("Awaken")
local hintEvent = remote("Hint")
local shopEvent = remote("OpenShop")
local comboEvent = remote("Combo")
local rainEvent = remote("RainCollected")
local buyFunction = remote("Buy", "RemoteFunction") :: RemoteFunction

local sockets = socketFolder:GetChildren()
local tierCount = 0
for _, socket in sockets do
	tierCount = math.max(tierCount, socket:GetAttribute("Tier"))
end

local carrying: { [Player]: BasePart } = {}
local helpers: { [Player]: number } = {}
local lastSlammer: Player? = nil
local lastSlamTime = 0
local awakening = false

-- Helpers ---------------------------------------------------------------------------------

local function upgradeLevel(player: Player, id: string): number
	return player:GetAttribute("Up_" .. id) or 0
end

local function goldValue(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Gold") :: IntValue?
end

local function addGold(player: Player, amount: number)
	local gold = goldValue(player)
	if gold then
		gold.Value += amount
	end
end

local function refreshLevel(player: Player)
	local xp = player:GetAttribute("StrengthXP") or 0
	local level = math.floor(math.sqrt(xp / Config.XpCurve)) + upgradeLevel(player, "Grip")
	player:SetAttribute("Level", level)
end

local function refreshSpeed(player: Player)
	local pumpkin = carrying[player]
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local lb = pumpkin and pumpkin:GetAttribute("Lb") or 0
		humanoid.WalkSpeed =
			math.max(Config.MinCarrySpeed, Config.NormalWalkSpeed - lb / Config.SlowPerLb)
	end
	player:SetAttribute("Carrying", pumpkin and 1 or 0)
	player:SetAttribute("CarryLb", pumpkin and pumpkin:GetAttribute("Lb") or 0)
	player:SetAttribute("CarryMagic", pumpkin and pumpkin:GetAttribute("Magic") or false)
end

local function playerScale(): number
	return 1 + Config.PlayerScale * math.max(#Players:GetPlayers() - 1, 0)
end

local function setActiveTier(tier: number)
	pyramid:SetAttribute("ActiveTier", tier)
	pyramid:SetAttribute("TierLb", 0)
	local quota = math.floor((Config.TierQuota[tier] or 400) * playerScale())
	pyramid:SetAttribute("TierQuota", quota)
	for _, socket in sockets do
		socket:SetAttribute("Active", socket:GetAttribute("Tier") == tier)
	end
end

local function setGiantStage(stage: number)
	pyramid:SetAttribute("Stage", stage)
	giantPlain.Transparency = stage == 0 and 0 or 1
	giant.Transparency = stage == 0 and 1 or 0
end

local function setTierCandles(tier: number, lit: boolean)
	for _, m in pyramid:GetChildren() do
		if m.Name == "TierCandle" .. tier then
			local flame = m:FindFirstChild("Flame", true)
			if flame then
				flame.Transparency = lit and 0 or 1
				local light = flame:FindFirstChildOfClass("PointLight")
				if light then
					light.Enabled = lit
				end
			end
		end
	end
end

-- Saving (works once the place is published with API access; otherwise pcall keeps it silent) -

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("GrowThePumpkin_v2")
end)
local loaded: { [Player]: boolean } = {}

local function loadPlayer(player: Player)
	if not store then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	if ok and type(data) == "table" and player.Parent then
		local gold = goldValue(player)
		if gold and type(data.gold) == "number" then
			gold.Value = data.gold
		end
		if type(data.xp) == "number" then
			player:SetAttribute("StrengthXP", data.xp)
		end
		if type(data.upgrades) == "table" then
			for id in Config.Upgrades do
				if type(data.upgrades[id]) == "number" then
					player:SetAttribute("Up_" .. id, data.upgrades[id])
				end
			end
		end
	end
	loaded[player] = ok
end

local function savePlayer(player: Player)
	if not store or not loaded[player] then
		return
	end
	local upgrades = {}
	for id in Config.Upgrades do
		upgrades[id] = upgradeLevel(player, id)
	end
	local gold = goldValue(player)
	local data = {
		gold = gold and gold.Value or 0,
		xp = player:GetAttribute("StrengthXP") or 0,
		upgrades = upgrades,
	}
	pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
end

-- Fields ----------------------------------------------------------------------------------

local function rollSize()
	local r = math.random()
	for _, size in Config.Sizes do
		if r <= size.chance then
			return size
		end
		r -= size.chance
	end
	return Config.Sizes[1]
end

local function makePickable(pumpkin: BasePart)
	local need = pumpkin:GetAttribute("NeedLevel") or 0
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lift"
	prompt.ObjectText = string.format(
		"%s pumpkin · %d lb",
		pumpkin:GetAttribute("SizeName") or "Ripe",
		pumpkin:GetAttribute("Lb") or 10
	)
	if need > 0 then
		prompt.ObjectText ..= " · Strength " .. need
	end
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pumpkin

	prompt.Triggered:Connect(function(player)
		if pumpkin:GetAttribute("Taken") or awakening or carrying[player] then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return
		end
		if (player:GetAttribute("Level") or 0) < need then
			hintEvent:FireClient(
				player,
				"Too heavy! You need Strength " .. need .. ". Dunk more pumpkins to get stronger."
			)
			return
		end
		pumpkin:SetAttribute("Taken", true)
		prompt:Destroy()
		pumpkin.Anchored = false
		pumpkin.Massless = true
		pumpkin.CanCollide = false
		pumpkin.CanQuery = false
		if pumpkin.Size.X > Config.MaxCarryWidth then
			pumpkin.Size *= Config.MaxCarryWidth / pumpkin.Size.X
		end
		pumpkin.CFrame = root.CFrame * CFrame.new(0, 2.8 + pumpkin.Size.Y / 2, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = pumpkin
		weld.Parent = pumpkin
		pumpkin.Parent = character
		pumpkin:SetNetworkOwner(player)
		carrying[player] = pumpkin
		refreshSpeed(player)
	end)
end

local function plotGrowthSpeed(): number
	local best = 0
	for _, player in Players:GetPlayers() do
		best = math.max(best, upgradeLevel(player, "GreenThumb"))
	end
	return 1 - 0.2 * best
end

local function growPlot(plot: BasePart, field: Instance)
	local firstRipe = true
	while plot.Parent do
		local pumpkin = templates.pumpkin_orange:Clone()
		local baseSize = pumpkin.Size
		local size = rollSize()
		pumpkin:SetAttribute("Lb", size.lb)
		pumpkin:SetAttribute("SizeName", size.name)
		pumpkin:SetAttribute("NeedLevel", size.level)
		pumpkin.Anchored = true
		pumpkin.CanCollide = false
		pumpkin.Parent = field
		local function place(scale: number)
			pumpkin.Size = baseSize * scale
			pumpkin.CFrame = plot.CFrame * CFrame.new(0, pumpkin.Size.Y / 2, 0)
		end
		if not firstRipe then
			for stage = 1, #Config.StageSeconds do
				place(Config.StageScale[stage])
				task.wait(Config.StageSeconds[stage] * plotGrowthSpeed())
			end
		end
		firstRipe = false
		place(size.scale)
		makePickable(pumpkin)
		while not pumpkin:GetAttribute("Taken") and pumpkin.Parent do
			task.wait(0.5)
		end
		task.wait(1)
	end
end

-- Cauldron gates: walking a pumpkin under the arch turns it magic and gives Strength XP. ----

local gateZones = {}
for _, gate in gates:GetChildren() do
	local zone = gate:FindFirstChild("Zone")
	local brew = gate:FindFirstChild("Brew")
	if zone then
		table.insert(gateZones, { zone = zone, brew = brew })
	end
end

local function inside(part: BasePart, point: Vector3): boolean
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	return math.abs(localPoint.X) <= half.X
		and math.abs(localPoint.Y) <= half.Y + 4
		and math.abs(localPoint.Z) <= half.Z
end

local function dunk(player: Player, pumpkin: BasePart, brew: BasePart?)
	pumpkin:SetAttribute("Magic", true)
	local glow = Instance.new("PointLight")
	glow.Name = "MagicGlow"
	glow.Color = Color3.fromRGB(150, 255, 110)
	glow.Range = 12
	glow.Brightness = 2
	glow.Parent = pumpkin
	local before = player:GetAttribute("Level") or 0
	local xp = (pumpkin:GetAttribute("Lb") or 10) / Config.LbPerXp
	player:SetAttribute("StrengthXP", (player:GetAttribute("StrengthXP") or 0) + xp)
	refreshLevel(player)
	refreshSpeed(player)
	dunkedEvent:FireAllClients(
		player,
		brew and brew.Position or pumpkin.Position,
		xp,
		(player:GetAttribute("Level") or 0) > before
	)
end

task.spawn(function()
	while true do
		task.wait(0.15)
		for player, pumpkin in carrying do
			if pumpkin.Parent and not pumpkin:GetAttribute("Magic") then
				local root = player.Character
					and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					for _, gate in gateZones do
						if inside(gate.zone, root.Position) then
							dunk(player, pumpkin, gate.brew)
							break
						end
					end
				end
			end
		end
	end
end)

-- Slamming into the pyramid ---------------------------------------------------------------

local function resetPyramid()
	for _, socket in sockets do
		local placed = socket:FindFirstChild("Placed")
		if placed then
			placed:Destroy()
		end
		socket:SetAttribute("Lb", 0)
	end
	for t = 1, tierCount do
		setTierCandles(t, false)
	end
	pyramid:SetAttribute("GiantNumber", (pyramid:GetAttribute("GiantNumber") or 1) + 1)
	setGiantStage(0)
	setActiveTier(1)
	helpers = {}
end

local function rainGold()
	local template = templates.pumpkin_orange
	for _ = 1, Config.RainCount do
		local a = math.random() * math.pi * 2
		local r = 60 + math.random() * 50
		local drop = template:Clone()
		drop.Name = "RainPumpkin"
		drop.TextureID = "" -- show the gold colour instead of the orange texture
		drop.Color = Color3.fromRGB(255, 200, 60)
		drop.Material = Enum.Material.SmoothPlastic
		drop.Anchored = false
		drop.CanCollide = true
		drop.Size = drop.Size * (3.5 / drop.Size.X)
		drop.CFrame = CFrame.new(math.cos(a) * r, 60 + math.random() * 25, math.sin(a) * r)
		drop.Parent = dropped
		local taken = false
		drop.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if taken or not player then
				return
			end
			taken = true
			addGold(player, Config.RainGold * (pyramid:GetAttribute("GiantNumber") or 1))
			rainEvent:FireAllClients(player, drop.Position)
			drop:Destroy()
		end)
		task.delay(Config.RainSeconds, function()
			if drop.Parent then
				drop:Destroy()
			end
		end)
		task.wait(0.04)
	end
end

local function awaken()
	awakening = true
	local paid = {}
	local payouts = {}
	for player, count in helpers do
		if player.Parent then
			local bonus = (Config.AwakenBonus + Config.AwakenPerSlam * count)
				* (pyramid:GetAttribute("GiantNumber") or 1)
			addGold(player, bonus)
			table.insert(paid, player)
			payouts[tostring(player.UserId)] = bonus -- string keys survive the remote
		end
	end
	awakenEvent:FireAllClients(paid, payouts)
	task.wait(Config.AwakenSeconds)
	resetPyramid()
	awakening = false
	rainGold()
end

local function completeTier(tier: number)
	setTierCandles(tier, true)
	if tier < tierCount then
		setGiantStage(tier)
		setActiveTier(tier + 1)
		tierEvent:FireAllClients(tier)
	else
		pyramid:SetAttribute("ActiveTier", 0)
		for _, socket in sockets do
			socket:SetAttribute("Active", false)
		end
		task.delay(0.8, awaken)
	end
end

local function slam(player: Player, socket: BasePart)
	local pumpkin = carrying[player]
	if awakening or not socket:GetAttribute("Active") then
		return
	end
	if not pumpkin then
		hintEvent:FireClient(player, "Bring a pumpkin from the fields first!")
		return
	end
	if not pumpkin:GetAttribute("Magic") then
		hintEvent:FireClient(player, "Carry it through a Magic Cauldron first!")
		return
	end
	carrying[player] = nil
	local lb = pumpkin:GetAttribute("Lb") or 10
	local from = pumpkin.Position
	pumpkin:Destroy()
	refreshSpeed(player)

	-- The socket's jack-o'-lantern swells with every pound slammed into it.
	local socketLb = (socket:GetAttribute("Lb") or 0) + lb
	socket:SetAttribute("Lb", socketLb)
	local jack = socket:FindFirstChild("Placed") :: BasePart?
	if not jack then
		jack = templates.Jack:Clone()
		jack.Name = "Placed"
		jack.Anchored = true
		jack.CanCollide = false
		jack.Parent = socket
	end
	local width = socket.Size.X * (0.7 + math.min(socketLb / 160, 1) * 0.7)
	jack.Size = jack.Size * (width / jack.Size.X)
	jack.CFrame = socket.CFrame * CFrame.new(0, jack.Size.Y / 2, 0)

	local tier = socket:GetAttribute("Tier")
	local giantNumber = pyramid:GetAttribute("GiantNumber") or 1
	local gold = math.max(1, math.floor(lb / Config.LbPerGold)) * tier * giantNumber
	addGold(player, gold)
	helpers[player] = (helpers[player] or 0) + 1
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Slams.Value += 1
	end
	slammedEvent:FireAllClients(player, socket, from, lb, gold)

	local now = os.clock()
	if
		lastSlammer
		and lastSlammer ~= player
		and lastSlammer.Parent
		and now - lastSlamTime <= Config.ComboWindow
	then
		addGold(player, Config.ComboGold)
		addGold(lastSlammer, Config.ComboGold)
		comboEvent:FireAllClients(lastSlammer, player)
	end
	lastSlammer = player
	lastSlamTime = now

	local tierLb = (pyramid:GetAttribute("TierLb") or 0) + lb
	pyramid:SetAttribute("TierLb", tierLb)
	if tierLb >= (pyramid:GetAttribute("TierQuota") or 0) then
		completeTier(tier)
	end
end

for _, socket in sockets do
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Slam"
	prompt.ObjectText = "Pumpkin Pyramid"
	prompt.HoldDuration = Config.SlamHold
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	-- Clients show this only on the active tier while carrying.
	prompt.Parent = socket
	prompt.Triggered:Connect(function(player)
		slam(player, socket)
	end)
end

-- Studio-only test hook: slam `count` pumpkins of `lb` as `player` without walking.
if RunService:IsStudio() then
	local debugSlam = Instance.new("BindableFunction")
	debugSlam.Name = "DebugSlam"
	debugSlam.OnInvoke = function(player: Player, lb: number, count: number)
		for _ = 1, count do
			local tier = pyramid:GetAttribute("ActiveTier") or 0
			if tier == 0 then
				break
			end
			local candidates = {}
			for _, socket in sockets do
				if socket:GetAttribute("Active") then
					table.insert(candidates, socket)
				end
			end
			local pumpkin = templates.pumpkin_orange:Clone()
			pumpkin:SetAttribute("Lb", lb)
			pumpkin:SetAttribute("Magic", true)
			pumpkin.Parent = workspace
			carrying[player] = pumpkin
			slam(player, candidates[math.random(1, #candidates)])
			task.wait(0.1)
		end
		return pyramid:GetAttribute("TierLb")
	end
	debugSlam.Parent = ServerStorage
end

-- Shop --------------------------------------------------------------------------------------

local shopPrompt = Instance.new("ProximityPrompt")
shopPrompt.ActionText = "Open shop"
shopPrompt.ObjectText = "Upgrades"
shopPrompt.HoldDuration = 0
shopPrompt.MaxActivationDistance = 12
shopPrompt.RequiresLineOfSight = false
shopPrompt.Parent = garden:WaitForChild("UpgradeBoard")
shopPrompt.Triggered:Connect(function(player)
	shopEvent:FireClient(player)
end)

buyFunction.OnServerInvoke = function(player: Player, id: string)
	local info = Config.Upgrades[id]
	if not info then
		return false, "Unknown upgrade"
	end
	local level = upgradeLevel(player, id)
	if level >= info.max then
		return false, "Maxed"
	end
	local cost = info.base * (level + 1)
	local gold = goldValue(player)
	if not gold or gold.Value < cost then
		return false, "Need " .. cost .. " gold"
	end
	gold.Value -= cost
	player:SetAttribute("Up_" .. id, level + 1)
	refreshLevel(player)
	return true, "Bought"
end

-- Players -----------------------------------------------------------------------------------

local function dropCarried(player: Player)
	local pumpkin = carrying[player]
	carrying[player] = nil
	if pumpkin and pumpkin.Parent then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Terrain, pyramid }
		local at = pumpkin.Position
		local hit = workspace:Raycast(at + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), params)
		local weld = pumpkin:FindFirstChildOfClass("WeldConstraint")
		if weld then
			weld:Destroy()
		end
		pumpkin.Anchored = true
		pumpkin.CFrame = CFrame.new(at.X, (hit and hit.Position.Y or 0) + pumpkin.Size.Y / 2, at.Z)
		pumpkin:SetAttribute("Taken", nil)
		pumpkin.CanQuery = true
		pumpkin.Parent = dropped
		makePickable(pumpkin)
		task.delay(Config.DroppedLifetime, function()
			if pumpkin.Parent == dropped and not pumpkin:GetAttribute("Taken") then
				pumpkin:Destroy()
			end
		end)
	end
	if player.Parent then
		refreshSpeed(player)
	end
end

local function setupPlayer(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Parent = stats
	local slams = Instance.new("IntValue")
	slams.Name = "Slams"
	slams.Parent = stats
	stats.Parent = player
	player:SetAttribute("StrengthXP", 0)
	loadPlayer(player)
	refreshLevel(player)
	refreshSpeed(player)
	-- A new player raises the quota of the tier being built.
	local tier = pyramid:GetAttribute("ActiveTier") or 1
	if tier > 0 then
		pyramid:SetAttribute(
			"TierQuota",
			math.floor((Config.TierQuota[tier] or 400) * playerScale())
		)
	end
end

local function onPlayer(player: Player)
	setupPlayer(player)
	local function watch(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			dropCarried(player)
		end)
		task.defer(refreshSpeed, player)
	end
	if player.Character then
		watch(player.Character)
	end
	player.CharacterAdded:Connect(watch)
	player.CharacterRemoving:Connect(function()
		dropCarried(player)
	end)
end

pyramid:SetAttribute("GiantNumber", 1)
setGiantStage(0)
setActiveTier(1)

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	loaded[player] = nil
	dropCarried(player)
	helpers[player] = nil
end)

for _, field in fields:GetChildren() do
	for _, plot in field:GetChildren() do
		if plot:IsA("BasePart") and plot.Name == "Plot" then
			task.spawn(growPlot, plot, field)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			savePlayer(player)
		end
	end
end)
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		savePlayer(player)
	end
end)
