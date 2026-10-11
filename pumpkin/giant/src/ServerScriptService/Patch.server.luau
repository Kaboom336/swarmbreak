local Services: { [string]: any } = {}
local Helpers: { [string]: any } = {}
local Lookup: { [string]: any } = {}
-- Steal a Pumpkin: swing your scythe at wild pumpkins in the zones until they pop, carry them
-- on your head and place them on your base, where they hatch into pets that earn candy every
-- second. The map is one straight lane along +Z (Config.MapCenterX): the hub with the bases and
-- the market, then Zone1..Zone7, each with a Hoard nest and its guardian. Brew them
-- in a Magic Cauldron for a multiplier, sell them to the Witch, steal from other bases (and lock
-- yours). At midnight ghosts raid the bases. Every sale fills the Giant Jack; when it is full the
-- Blood Moon turns every lock off for a while, then everyone fights the Pumpkin King.
-- New players meet only the core loop (smash, place, Hoard steal, Shop, zone gates): stealing,
-- locks and ghost raids open after the new-player shield, Sell / Brew / King / retired upgrades after
-- about 30 minutes and Haunt at half its cost (Config.Unlocks, see Unlock below).
Services.AnalyticsService = game:GetService("AnalyticsService")
Services.DataStoreService = game:GetService("DataStoreService")
Services.HttpService = game:GetService("HttpService")
Services.MarketplaceService = game:GetService("MarketplaceService")
Services.Players = game:GetService("Players")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.RunService = game:GetService("RunService")
Services.ServerStorage = game:GetService("ServerStorage")
Services.StarterPack = game:GetService("StarterPack")
Services.TweenService = game:GetService("TweenService")

local Config = require(Services.ReplicatedStorage:WaitForChild("PatchConfig"))
Helpers.warned = {}
function Helpers.warnOnce(key, message)
	if not Helpers.warned[key] then
		Helpers.warned[key] = true
		warn("[Patch] " .. message)
	end
end
function Helpers.savedHatchSize(value)
	if type(value) ~= "table" then
		return nil
	end
	local x, y, z = tonumber(value[1]), tonumber(value[2]), tonumber(value[3])
	if x and y and z and x > 0 and y > 0 and z > 0 and x < 10000 and y < 10000 and z < 10000 then
		return Vector3.new(x, y, z)
	end
	return nil
end
-- Read-only, sanitized assets for client ViewportFrames; never expose ServerStorage itself.
do
	-- Correct the existing place's templates before any previews or gameplay clones are made.
	for _, name in { "PetModels", "GuardModels" } do
		local folder = Services.ServerStorage:FindFirstChild(name)
		for _, model in folder and folder:GetChildren() or {} do
			if model:IsA("Model") then
				Config.fixModelFront(model)
			end
		end
	end
	local previews = Instance.new("Folder")
	previews.Name = "PetPreviews"
	local models = Services.ServerStorage:FindFirstChild("PetModels")
	if not models then
		models = Instance.new("Folder")
		models.Name = "PetModels"
		models.Parent = Services.ServerStorage
	end
	local fallback = models:FindFirstChild("PumpkinPup")
	if
		not (
			fallback
			and fallback:IsA("Model")
			and fallback:FindFirstChildWhichIsA("BasePart", true)
		)
	then
		if fallback then
			fallback:Destroy()
		end
		Helpers.warnOnce(
			"PumpkinPup",
			"PumpkinPup missing or empty; using a simple placeholder pet"
		)
		fallback = Instance.new("Model")
		fallback.Name = "PumpkinPup"
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(3, 3, 3)
		body.Color = Color3.fromRGB(255, 132, 20)
		body.Anchored = true
		body.CanCollide, body.CanTouch, body.CanQuery = false, false, false
		body.Parent = fallback
		fallback.Parent = models
	end
	for pet in Config.Pets do
		local model = models:FindFirstChild(pet)
		if
			not model
			or not model:IsA("Model")
			or not model:FindFirstChildWhichIsA("BasePart", true)
		then
			if model then
				model:Destroy()
			end
			local clone = fallback:Clone()
			if not clone then
				continue
			end
			clone.Name = pet
			clone.Parent = models
			Helpers.warnOnce(pet, "Missing pet asset; using PumpkinPup: " .. pet)
		end
	end
	for pet in Config.Pets do
		local source = models:FindFirstChild(pet)
		if source and source:IsA("Model") and source.Archivable then
			local clone = source:Clone()
			for _, item in clone:GetDescendants() do
				if
					item:IsA("LuaSourceContainer")
					or item:IsA("Sound")
					or item:IsA("ParticleEmitter")
					or item:IsA("Trail")
					or item:IsA("Beam")
				then
					item:Destroy()
				elseif item:IsA("BasePart") then
					item.Anchored = true
					item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
				end
			end
			clone.Parent = previews
		end
	end
	previews.Parent = Services.ReplicatedStorage
end
function Helpers.fontFace(role: string): Font
	local spec = Config.Fonts[role]
	if type(spec) == "table" then
		return Font.new(spec.family, Enum.FontWeight[spec.weight or "Regular"])
	end
	return Font.fromEnum(Enum.Font[spec])
end

local garden = workspace:WaitForChild("Garden")
local patchFolder = garden:WaitForChild("Patches")
local cauldronFolder = garden:WaitForChild("Cauldrons")
local market = garden:WaitForChild("Market")
local spawnFolder = garden:WaitForChild("GhostSpawns")
local giantJack = market:WaitForChild("GiantJack") :: BasePart
local kingFace = market:WaitForChild("KingFace") :: BasePart
-- ThroneKing is the centrepiece; GiantJack stays only as an event position anchor.
if not (market:FindFirstChild("ThroneKing", true) or garden:FindFirstChild("ThroneKing", true)) then
	Helpers.warnOnce("ThroneKing", "ThroneKing centrepiece missing; skipping throne decoration")
end
do
	local statue = garden:FindFirstChild("ThroneKing", true)
	if statue and statue:IsA("Model") then
		Config.fixModelFront(statue) -- Honors Launch2ForwardFixed; never double-turn the v2/v3 statue.
		local spawn = garden:FindFirstChild("SpawnLocation")
		local at = statue:GetPivot().Position
		local target = spawn and spawn:IsA("BasePart") and spawn.Position
			or Vector3.new(1500, at.Y, 130)
		target = Vector3.new(target.X, at.Y, target.Z)
		if statue:GetAttribute("FrontFixed") and (target - at).Magnitude > 0.01 then
			statue:PivotTo(CFrame.lookAt(at, target))
		end
	end
end
giantJack.Transparency = 1
giantJack.CanCollide, giantJack.CanTouch, giantJack.CanQuery = false, false, false
local kit = Services.ServerStorage:WaitForChild("KitSource")
do
	local function capBillboard(item)
		if item:IsA("BillboardGui") then
			item.MaxDistance = item.MaxDistance > 0
					and math.min(item.MaxDistance, Config.Payoff.petDistance)
				or Config.Payoff.petDistance
		end
	end
	for _, item in garden:GetDescendants() do
		capBillboard(item)
	end
	garden.DescendantAdded:Connect(function(item)
		if item:IsA("BillboardGui") then
			task.defer(capBillboard, item)
		end
	end)
end

-- The straight-lane map: the X of its centre line, the hub's safe line and each zone's Z range
-- (folder attributes ZMin / ZMax, else Config.Zones[id].zMin / zMax).
local Lane: { [string]: any } = { x = Config.MapCenterX or 0, safeZ = Config.SafeLineZ or 150 }
function Lane.zone(zoneId: string): { zMin: number, zMax: number, center: Vector3 }?
	local def = Config.Zones[zoneId]
	if not def then
		return nil
	end
	local zones = garden:FindFirstChild("Zones")
	local folder = zones and zones:FindFirstChild(zoneId)
	local a = folder and folder:GetAttribute("ZMin") or def.zMin
	local b = folder and folder:GetAttribute("ZMax") or def.zMax
	if type(a) ~= "number" or type(b) ~= "number" then
		return nil
	end
	local zMin, zMax = math.min(a, b), math.max(a, b)
	return { zMin = zMin, zMax = zMax, center = Vector3.new(Lane.x, 0, (zMin + zMax) / 2) }
end

local loose = Instance.new("Folder")
loose.Name = "Loose"
loose.Parent = garden
local ghostFolder = Instance.new("Folder")
ghostFolder.Name = "Ghosts"
ghostFolder.Parent = garden

local state = Instance.new("Configuration")
state.Name = "PatchState"
state.Parent = Services.ReplicatedStorage

-- Spooky Hour (replaces the old dark Midnight look): at Config.SpookyMinutes for
-- Config.SpookyLength seconds base income pays x Config.SpookyMult. State "SpookyEnds" = its end
-- (server time, nil when off), "SpookyNext" = the next start. Clients tint the world and fly bats.
local Spooky: { [string]: any } = {}
local Purge: { [string]: any } = {
	id = 0,
	victims = {},
	locks = {},
	holds = {},
	participants = {},
	losses = {},
	transit = {},
	bonks = {},
}
function Purge.active(): boolean
	return (state:GetAttribute("PurgeEnds") or 0) > workspace:GetServerTimeNow()
end
function Purge.immune(player): boolean
	return (player:GetAttribute("PlayTime") or 0) < Config.Purge.grace
		or workspace:GetServerTimeNow() - (player:GetAttribute("LastActiveAt") or 0)
			>= Config.Purge.idle
end
do
	local function nextSpooky(t)
		local hour = math.floor(t / 3600) * 3600
		for _, minute in Config.SpookyMinutes do
			local at = hour + minute * 60
			if at > t then
				return at
			end
		end
		return hour + 3600 + Config.SpookyMinutes[1] * 60
	end
	local nextAt = nextSpooky(workspace:GetServerTimeNow())
	state:SetAttribute("SpookyNext", nextAt)
	function Spooky.active(): boolean
		return (state:GetAttribute("SpookyEnds") or 0) > workspace:GetServerTimeNow()
	end
	function Spooky.mult(): number
		return Spooky.active() and (Config.SpookyMult or 2) or 1
	end
	function Spooky.start()
		local t = workspace:GetServerTimeNow()
		if
			Purge.active()
			or state:GetAttribute("PurgeWarning")
			or state:GetAttribute("KingActive")
			or state:GetAttribute("KingWarning")
			or state:GetAttribute("Phase") == "BloodMoon"
			or (state:GetAttribute("LocksOff") or 0) > t
			or (state:GetAttribute("KingWakesAt") or math.huge) <= t + Config.SpookyLength
			or (state:GetAttribute("PurgeNext") or math.huge)
				<= t + Config.SpookyLength + Config.Purge.warning
		then
			nextAt = nextSpooky(t)
			state:SetAttribute("SpookyNext", nextAt)
			return false
		end
		state:SetAttribute("SpookyEnds", t + (Config.SpookyLength or 90))
		nextAt = nextSpooky(t)
		state:SetAttribute("SpookyNext", nextAt)
	end
	-- Every second (main loop).
	function Spooky.tick()
		local t = workspace:GetServerTimeNow()
		local ends = state:GetAttribute("SpookyEnds")
		if type(ends) == "number" and t >= ends then
			state:SetAttribute("SpookyEnds", nil)
		end
		if t >= nextAt then
			Spooky.start()
		end
	end
end

-- Remote events and functions, created in this order under ReplicatedStorage.PatchRemotes.
local Remotes
do
	local remotes = Instance.new("Folder")
	remotes.Name = "PatchRemotes"
	remotes.Parent = Services.ReplicatedStorage
	local function remote(name: string, class: string?)
		local r = Instance.new(class or "RemoteEvent")
		r.Name = name
		r.Parent = remotes
		return r
	end
	Remotes = {
		adminFunction = remote("Admin", "RemoteFunction") :: RemoteFunction,
		teleportFunction = remote("Teleport", "RemoteFunction") :: RemoteFunction,
		dashFunction = remote("Dash", "RemoteFunction") :: RemoteFunction,
		sprintEvent = remote("Sprint"),
		dailyClaimFunction = remote("ClaimDaily", "RemoteFunction") :: RemoteFunction,
		dailyStatusFunction = remote("DailyStatus", "RemoteFunction") :: RemoteFunction,
		hintEvent = remote("Hint"),
		placedEvent = remote("Placed"),
		harvestedEvent = remote("Harvested"),
		brewedEvent = remote("Brewed"),
		soldEvent = remote("Sold"),
		ghostPopEvent = remote("GhostPopped"),
		stolenEvent = remote("Stolen"),
		bonkEvent = remote("Bonk"),
		swingEvent = remote("Swing"),
		kingHitEvent = remote("KingHit"),
		kingJoinEvent = remote("KingJoin"),
		stompEvent = remote("Stomp"),
		telegraphEvent = remote("Telegraph"),
		knockEvent = remote("Knock"),
		indexEvent = remote("IndexNew"),
		indexClaimFunction = remote("ClaimIndex", "RemoteFunction"),
		announceEvent = remote("Announce"),
		kingDoneEvent = remote("KingDone"),
		rainEvent = remote("RainCollected"),
		shopEvent = remote("OpenShop"),
		orderDoneEvent = remote("OrderDone"),
		dailyEvent = remote("Daily"),
		wildHitEvent = remote("WildHit"),
		wildPopEvent = remote("WildPopped"),
		lockEvent = remote("Lock"),
		-- Client -> server: drop the whole carried stack as loose pickups.
		dropEvent = remote("Drop"),
		-- Server -> client: "stole" (to the thief) / "robbed" (to the base owner).
		stealAlarmEvent = remote("StealAlarm"),
		-- Server -> client: reward reveal card (seedId, mutation?, isNew, candy per second).
		revealEvent = remote("Reveal"),
		-- Server -> one client: Hoard drama ("grab" / "bonk" / "safe" / "deliver", seedId).
		hoardEvent = remote("Hoard"),
		wakeEvent = remote("GuardianWake"),
		-- Server -> all clients: a placed pumpkin finished hatching (pumpkin, ownerId, pet name?,
		-- isNew = the owner's first hatch of that type).
		carvedEvent = remote("Carved"),
		buyToolFunction = remote("BuyTool", "RemoteFunction") :: RemoteFunction,
		buyUpgradeFunction = remote("BuyUpgrade", "RemoteFunction") :: RemoteFunction,
		hauntFunction = remote("Haunt", "RemoteFunction") :: RemoteFunction,
		buySkillFunction = remote("BuySkill", "RemoteFunction") :: RemoteFunction,
		shopFunction = remote("Shop", "RemoteFunction") :: RemoteFunction,
	}
end

-- Pumpkin types (Config.Seeds keeps its old name and ids).
Lookup.seedById = {}
for i, seed in Config.Seeds do
	seed.order = i
	Lookup.seedById[seed.id] = seed
end
Lookup.toolById = {}
for i, tool in Config.Tools do
	tool.order = i
	Lookup.toolById[tool.id] = tool
end
Lookup.mutationById = {}
for _, m in Config.Mutations do
	Lookup.mutationById[m.id] = m
end
Lookup.skillById = {}
Lookup.skillAt = {} -- "Branch:tier" -> skill
for _, skill in Config.Skills do
	Lookup.skillById[skill.id] = skill
	Lookup.skillAt[skill.branch .. ":" .. skill.tier] = skill
end

-- Player data ------------------------------------------------------------------------------

function Helpers.upgradeLevel(player: Player, id: string): number
	return player:GetAttribute("Up_" .. id) or 0
end

function Helpers.candyValue(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Candy") :: IntValue?
end

local Progress: { [string]: any } = { data = {}, pending = {}, effects = {}, draining = {} }
local lifetime: { [Player]: number } = {}
function Progress.candyMult(player)
	return 1
		+ Config.Progression.stampBonus * (player:GetAttribute("ZoneStamps") or 0)
		+ Config.Progression.rebirthBonus * (player:GetAttribute("Rebirths") or 0)
end
local function addCandy(
	player: Player,
	amount: number,
	alreadyBoosted: boolean?,
	exact: boolean?
): number
	local candy = Helpers.candyValue(player)
	if candy then
		local d = Progress.data[player]
		local boosted = amount * (alreadyBoosted and 1 or Progress.candyMult(player))
			+ (not exact and d and d.candyFraction or 0)
		amount = math.floor(boosted + Config.Progression.roundEpsilon)
		if d and not exact then
			d.candyFraction = math.max(0, boosted - amount)
		end
		candy.Value += amount
		if amount > 0 then
			lifetime[player] = (lifetime[player] or 0) + amount
		end
		return amount
	end
	return 0
end

-- Game passes the player owns, cached in "Pass_<Name>" attributes (see Monetization below).
function Helpers.hasPass(player: Player, name: string): boolean
	return player:GetAttribute("Pass_" .. name) == true
end

function Helpers.carryCapacity(_player: Player): number
	return Config.BaseCarry
end

function Helpers.isLoaded(player: Player): boolean
	return player:GetAttribute("Loaded") == true
end

-- Unlock gates (Config.Unlocks): sticky "Unlock_<Name>" player attributes, set by Unlock.refresh
-- (defined with the bases below) from the saved total playtime ("PlayTime"), lifetime candy and a
-- full base. Clients show / hide by the same attributes; the server checks them here.
-- Haunt is the HauntPillAt gate (lifetime candy); the others are playtime gates.
local Unlock: { [string]: any } = {
	NAMES = { "PlayerSteal", "Sell", "Brew", "LuckySwing", "King", "Haunt" },
}
function Unlock.badge(player, name)
	local id = Config.Badges[name] or 0
	if id == 0 or player:GetAttribute("Badge_" .. name) then
		return
	end
	player:SetAttribute("Badge_" .. name, true)
	task.spawn(function()
		local ok, awarded = pcall(function()
			return game:GetService("BadgeService"):AwardBadge(player.UserId, id)
		end)
		if (not ok or not awarded) and player.Parent then
			player:SetAttribute("Badge_" .. name, nil)
		end
	end)
end
function Unlock.has(player: Player?, name: string): boolean
	return player ~= nil and player:GetAttribute("Unlock_" .. name) == true
end

-- Haunts add to sell value; VIP and Double Candy multiply on top.
function Helpers.sellMult(player: Player): number
	return (1 + Config.HauntSellBonus * (player:GetAttribute("Haunts") or 0))
		* (Helpers.hasPass(player, "VIP") and 1 + Config.VipSellBonus or 1)
		* (Helpers.hasPass(player, "DoubleCandy") and Config.DoubleCandyMult or 1)
end

-- Soul skills a player owns; mirrored to the "Skills" attribute as a comma list.
local skillsOf: { [Player]: { [string]: boolean } } = {}
local function hasSkill(player: Player?, id: string): boolean
	local owned = player and skillsOf[player]
	return owned ~= nil and owned[id] == true
end

local function publishSkills(player: Player)
	local list = {}
	for _, skill in Config.Skills do
		if hasSkill(player, skill.id) then
			table.insert(list, skill.id)
		end
	end
	player:SetAttribute("Skills", table.concat(list, ","))
end

-- Tools a player owns, mirrored to the "Tools" attribute as a comma list. The best owned tool
-- is the one they hold (its id is in the "Tool" attribute).
local toolsOf: { [Player]: { [string]: boolean } } = {}
local function bestTool(player: Player)
	local best = Lookup.toolById[Config.StartTool]
	for id in toolsOf[player] or {} do
		local tool = Lookup.toolById[id]
		if tool and tool.damage > best.damage then
			best = tool
		end
	end
	return best
end

local function publishTools(player: Player)
	local list = {}
	for _, tool in Config.Tools do
		if (toolsOf[player] or {})[tool.id] then
			table.insert(list, tool.id)
		end
	end
	player:SetAttribute("Tools", table.concat(list, ","))
	player:SetAttribute("Tool", bestTool(player).id)
end

-- Zones a player has unlocked (Zone1 is always open), mirrored to the "Zones" attribute as a
-- comma list in Config.ZoneOrder order. Saved as "zones"; a Haunt resets it to Zone1.
local zonesOf: { [Player]: { [string]: boolean } } = {}
local function hasZone(player: Player, zoneId: string): boolean
	local def = Config.Zones[zoneId]
	if def and (def.cost or 0) <= 0 then
		return true
	end
	local owned = zonesOf[player]
	return owned ~= nil and owned[zoneId] == true
end

local function publishZones(player: Player)
	local list = {}
	for _, zoneId in Config.ZoneOrder do
		if hasZone(player, zoneId) then
			table.insert(list, zoneId)
		end
	end
	player:SetAttribute("Zones", table.concat(list, ","))
end

-- The first zone in unlock order the player does not have yet (nil when all are open).
local function nextLockedZone(player: Player): string?
	for _, zoneId in Config.ZoneOrder do
		if Config.Zones[zoneId] and not hasZone(player, zoneId) then
			return zoneId
		end
	end
	return nil
end

-- Swing damage on wild pumpkins and the King: tool damage x Heavy Swing. Sharp Blade (Mallet) is
-- cut: its saved level is kept but ignored.
local function swingDamage(player: Player): number
	local heavy = hasSkill(player, "HeavyMallet") and Config.SkillDamageMult or 1
	return math.max(1, math.floor(bestTool(player).damage * heavy + 0.5))
end

-- Pumpkin types a player has found at least once (Orange counts from the start).
local unlocked: { [Player]: { [string]: boolean } } = {}
local function startUnlocked(): { [string]: boolean }
	return { Orange = true }
end

-- B: the value unit for order rewards and ghost bonks.
local function orderBase(player: Player): number
	return math.max(1, player:GetAttribute("Income") or 0) * Config.OrderIncomeSeconds
end

-- Short numbers: 950, 1.2k, 34.5k, 340k, 3.4M, 1.2B (rounded down so 999.96k never shows 1000k).
function Helpers.short(n: number): string
	for _, unit in { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "k" } } do
		if n >= unit[1] then
			local v = n / unit[1]
			local text = v >= 100 and tostring(math.floor(v))
				or (string.gsub(string.format("%.1f", math.floor(v * 10) / 10), "%.0$", ""))
			return text .. unit[2]
		end
	end
	return tostring(math.floor(n))
end

-- Candy per second: one decimal below 10.
function Helpers.rateText(n: number): string
	if n < 10 then
		return (string.gsub(string.format("%.1f", n), "%.0$", ""))
	end
	return Helpers.short(n)
end

-- Pumpkin Index: every seed x finish a player has sold, kept as "Seed:Finish" keys.
local FINISHES = { "Plain", "Glowing", "Ghostly", "Candy", "Cursed" }
local indexOf: { [Player]: { [string]: boolean } } = {}
Helpers.Index = { claims = {}, milestones = {} }
function Helpers.Index.discovered(player, seed)
	for key in indexOf[player] or {} do
		if string.match(key, "^([^:]+):") == seed.id then
			return true
		end
	end
	return false
end
function Helpers.Index.publish(player)
	for attribute, data in
		{ IndexClaims = Helpers.Index.claims, IndexMilestones = Helpers.Index.milestones }
	do
		local keys = {}
		for key, value in data[player] or {} do
			if value == true then
				table.insert(keys, key)
			end
		end
		player:SetAttribute(attribute, table.concat(keys, ","))
	end
end
function Helpers.Index.load(player, data)
	for field, target in
		{ IndexClaims = Helpers.Index.claims, IndexMilestones = Helpers.Index.milestones }
	do
		target[player] = {}
		if type(data[field]) == "table" then
			for key, value in data[field] do
				if type(key) == "string" and value == true then
					target[player][key] = true
				end
			end
		end
	end
	Helpers.Index.publish(player)
end

local function publishIndex(player: Player)
	local keys = {}
	for key in indexOf[player] or {} do
		table.insert(keys, key)
	end
	player:SetAttribute("Index", table.concat(keys, ","))
end

local function rowDone(player: Player, seedId: string): boolean
	local found = indexOf[player]
	if not found then
		return false
	end
	for _, finish in FINISHES do
		if not found[seedId .. ":" .. finish] then
			return false
		end
	end
	return true
end

-- Witch's Orders -----------------------------------------------------------------------------
-- 8 tutorial orders in sequence, then RotatingCount random orders that refresh every
-- OrderRefresh seconds. Progress counts from when an order becomes active.

type Order = {
	id: string,
	stat: string,
	need: number,
	have: number,
	text: string,
	target: string,
	reward: { [string]: any },
	done: boolean,
}
type Orders = {
	tut: number,
	list: { Order },
	refreshAt: number,
	counters: { [string]: number },
}
local orders: { [Player]: Orders } = {}
local TUTORIAL_COUNT = #Config.TutorialOrders

local function rewardText(reward: { [string]: any }): string
	local parts = {}
	if reward.candy then
		table.insert(parts, Helpers.short(reward.candy) .. " candy")
	end
	if reward.title then
		table.insert(parts, string.format('the "%s" title', reward.title))
	end
	return table.concat(parts, " + ")
end

-- level: the player's current level for "reach" orders (their need grows with it).
local function makeOrder(id: string, base: number?, level: number?): Order?
	local kind, n = string.match(id, "^([TR])(%d+)$")
	local i = tonumber(n)
	if not kind or not i then
		return nil
	end
	local def = (kind == "T" and Config.TutorialOrders or Config.RotatingOrders)[i]
	if not def then
		return nil
	end
	local reward = def.reward
		or {
			candy = math.max(
				1,
				math.floor(math.clamp((def.b or 3) / 4, 0.5, 1) * (base or 1) + 0.5)
			),
		}
	local need = def.need
	local text = def.text
	if def.reach and kind == "R" then
		need = math.max(need, math.ceil((level or 0) * Config.ReachGrowth))
		text = string.format(def.text, Helpers.short(need))
	end
	return {
		id = id,
		stat = def.stat,
		need = need,
		have = 0,
		text = string.find(text, "%s", 1, true) and string.format(text, Helpers.short(need))
			or text,
		target = def.target,
		reward = reward,
		done = false,
	}
end

-- Rotating orders are only dealt once their system is unlocked (stat -> Config.Unlocks name).
local ORDER_UNLOCK = {
	steal = "PlayerSteal",
	stopThief = "PlayerSteal",
	rescue = "PlayerSteal",
	bonkGhost = "PlayerSteal",
	sell = "Sell",
	sellStackOf5 = "Sell",
	newIndex = "Sell",
	sellBrewed = "Brew",
	brewRare = "Brew",
	["sellMutation:Cursed"] = "Brew",
	kingHit = "King",
}

-- Live targets filter new deals only, including solo servers.
-- Only retire accepted orders when their permanent/session target is gone.
function Progress.orderExpired(player, def)
	return (def.target == "king" and not state:GetAttribute("KingActive"))
		or (Config.Raid.grace >= 1e9 and (def.stat == "bonkGhost" or def.stat == "rescue"))
		or (def.target == "gate" and nextLockedZone(player) == nil)
		or ((def.stat == "steal" or def.stat == "stopThief") and not Purge.active())
end

function Progress.orderLive(player, def)
	if Config.Raid.grace >= 1e9 and (def.stat == "bonkGhost" or def.stat == "rescue") then
		return false
	end
	if def.target == "gate" then
		return nextLockedZone(player) ~= nil
	end
	if def.target == "king" then
		return state:GetAttribute("KingActive") == true and (state:GetAttribute("KingHp") or 0) > 0
	end
	if def.target == "tools" or def.target == "upgrades" or def.target == "witch" then
		local name = def.target == "tools" and "Seeds"
			or def.target == "witch" and "Sell"
			or "Upgrades"
		return market:FindFirstChild(name) ~= nil
	end
	if def.target == "cauldron" then
		return Unlock.has(player, "Brew") and #cauldronFolder:GetChildren() > 0
	end
	if def.stat == "bonkGhost" or def.stat == "rescue" then
		for _, ghost in ghostFolder:GetChildren() do
			if def.stat == "bonkGhost" or ghost:GetAttribute("StashOwner") == player.UserId then
				return true
			end
		end
		return false
	end
	if def.stat == "steal" or def.stat == "stopThief" then
		if not Purge.active() or Purge.immune(player) then
			return false
		end
		for _, other in Services.Players:GetPlayers() do
			if other ~= player and Unlock.has(other, "PlayerSteal") then
				if def.stat == "stopThief" then
					if
						(other:GetAttribute("CarryStolen") or 0) > 0
						and string.find(
							other:GetAttribute("StealingFrom") or "",
							"," .. player.UserId .. ",",
							1,
							true
						)
					then
						return true
					end
				else
					if Purge.immune(other) or Purge.victims[other.UserId] then
						continue
					end
					for _, pen in patchFolder:GetChildren() do
						if
							pen:GetAttribute("Owner") == other.UserId
							and (pen:GetAttribute("LockedUntil") or 0) <= workspace:GetServerTimeNow()
							and (pen:GetAttribute("RobbedUntil") or 0)
								<= workspace:GetServerTimeNow()
						then
							for _, plot in pen:GetChildren() do
								if
									plot.Name == "Plot"
									and plot:GetAttribute("Filled")
									and not plot:GetAttribute("Protected")
								then
									return true
								end
							end
						end
					end
				end
			end
		end
		return false
	end
	if def.target == "hoard" or def.target == "place" then
		local zones = garden:FindFirstChild("Zones")
		local zone = zones and zones:FindFirstChild("Zone1")
		local hoard = zone and zone:FindFirstChild("Hoard")
		for _, p in hoard and hoard:GetChildren() or {} do
			if
				p:IsA("BasePart")
				and p.Name == "HoardPumpkin"
				and p:FindFirstChild("StealPrompt")
			then
				return true
			end
		end
		return false
	end
	return true
end

local function nextOrders(player: Player)
	local o = orders[player]
	-- Tutorial steps the player already did some other way are skipped (a better scythe owned,
	-- the stack already upgraded), so an old save can never get stuck on them.
	while o.tut <= TUTORIAL_COUNT do
		local stat = Config.TutorialOrders[o.tut].stat
		if
			(stat == "buyTool" and bestTool(player).order >= 2)
			or (stat == "penFilled" and (player:GetAttribute("PenFilled") or 0) >= 2)
			or (stat == "hatch" and (player:GetAttribute("PenHatched") or 0) >= 1)
			or (stat == "hoardSteal" and (o.counters.hoardSteal or 0) >= 1)
			or (stat == "unlockZone" and hasZone(player, "Zone2"))
		then
			o.tut += 1
		else
			break
		end
	end
	if o.tut <= TUTORIAL_COUNT then
		o.list = { makeOrder("T" .. o.tut, orderBase(player)) :: Order }
		return
	end
	-- Right after the tutorial: the first gated zone (the Graveyard) is the only goal.
	local firstGate = nil
	for _, zoneId in Config.ZoneOrder do
		local def = Config.Zones[zoneId]
		if def and (def.cost or 0) > 0 then
			firstGate = zoneId
			break
		end
	end
	if firstGate and not hasZone(player, firstGate) then
		for i, def in Config.RotatingOrders do
			if def.stat == "unlockZone" then
				o.list = { makeOrder("R" .. i, orderBase(player)) :: Order }
				o.refreshAt = os.time() + Config.OrderRefresh
				return
			end
		end
	end
	-- Skip orders the player cannot finish right now.
	local indexFull = false
	do
		local n = 0
		for key in indexOf[player] or {} do
			local seedId, finish = string.match(key, "^([^:]+):(.+)$")
			if seedId and Lookup.seedById[seedId] and table.find(FINISHES, finish) then
				n += 1
			end
		end
		indexFull = n >= #Config.Seeds * #FINISHES
	end
	local pool = {}
	for i, def in Config.RotatingOrders do
		local gate = ORDER_UNLOCK[def.stat]
		local impossible = not Progress.orderLive(player, def)
			or Config.RemovedOrders[string.match(def.stat, "^[^:]+") or def.stat] == true
			or (def.stat == "sellStackOf5" and Helpers.carryCapacity(player) < 5)
			or (def.stat == "newIndex" and indexFull)
			or (def.stat == "unlockZone" and nextLockedZone(player) == nil)
			or (gate ~= nil and not Unlock.has(player, gate))
		if not impossible then
			table.insert(pool, i)
		end
	end
	local base = orderBase(player)
	local level = player:GetAttribute("Income") or 0
	o.list = {}
	for _ = 1, math.min(Config.RotatingCount, #pool) do
		local i = table.remove(pool, math.random(#pool))
		table.insert(o.list, makeOrder("R" .. i, base, level) :: Order)
	end
	o.refreshAt = os.time() + Config.OrderRefresh
end

local function publishOrders(player: Player)
	local o = orders[player]
	if not o then
		return
	end
	player:SetAttribute("LearningFarm", o.tut == 3)
	local list = {}
	for _, order in o.list do
		table.insert(list, {
			text = order.stat == "penFilled" and (order.text .. "/" .. (player:GetAttribute(
				"PenSlots"
			) or Config.Progression.baseSlots)) or order.text,
			stat = order.stat,
			have = math.min(order.have, order.need),
			need = order.need,
			done = order.done,
			target = order.target,
			reward = rewardText(order.reward),
		})
	end
	player:SetAttribute(
		"Orders",
		Services.HttpService:JSONEncode({
			tutorial = o.tut <= TUTORIAL_COUNT,
			step = o.tut,
			steps = TUTORIAL_COUNT,
			refreshAt = o.refreshAt,
			list = list,
		})
	)
end

local function grantReward(player: Player, reward: { [string]: any })
	if reward.candy then
		addCandy(player, reward.candy, true)
	end
	if reward.title then
		player:SetAttribute("Title", reward.title)
	end
end

-- Analytics: the onboarding funnel. Each step is logged once per player; steps already logged
-- are kept in the save ("onboard").
local ONBOARD_STEPS = {
	"Joined",
	"First smash",
	"First place",
	"First brew",
	"First sale",
	"First upgrade",
	"First King hit",
	"First Haunt",
}
local ONBOARD_STAT = { smash = 2, place = 3, brew = 4, sell = 5, upgrade = 6, kingHit = 7 }
local onboardOf: { [Player]: { [number]: boolean } } = {}

local function onboard(player: Player, step: number)
	local done = onboardOf[player]
	if not done or done[step] or not Helpers.isLoaded(player) then
		return
	end
	done[step] = true
	pcall(function()
		Services.AnalyticsService:LogOnboardingFunnelStepEvent(player, step, ONBOARD_STEPS[step])
	end)
end

-- reach = amount is a level (orders keep the highest seen) instead of a count to add.
local function track(player: Player?, stat: string, amount: number?, reach: boolean?)
	local o = player and orders[player]
	if not player or not o or not Helpers.isLoaded(player) then
		return
	end
	local step = ONBOARD_STAT[stat]
	if stat == "hoardSteal" or stat == "steal" then
		Unlock.badge(player, "FirstSteal")
	elseif stat == "hatch" then
		Unlock.badge(player, "FirstHatch")
	end
	if step then
		onboard(player, step)
	end
	local n = amount or 1
	if reach then
		o.counters[stat] = math.max(o.counters[stat] or 0, n)
	else
		o.counters[stat] = (o.counters[stat] or 0) + n
	end
	local changed, finished = false, false
	for _, order in o.list do
		if not order.done and order.stat == stat and (not reach or n > order.have) then
			order.have = reach and n or order.have + n
			changed = true
			if order.have >= order.need then
				order.done = true
				finished = true
				grantReward(player, order.reward)
				Remotes.orderDoneEvent:FireClient(player, order.text, rewardText(order.reward))
			end
		end
	end
	if finished and o.tut <= TUTORIAL_COUNT then
		o.tut += 1
		nextOrders(player)
	elseif finished then
		-- One rotating order at a time: the next one is dealt as soon as this one is done.
		local open = false
		for _, order in o.list do
			open = open or not order.done
		end
		if not open then
			nextOrders(player)
		end
	end
	if changed then
		publishOrders(player)
	end
end

local function loadOrders(player: Player, saved: any)
	local o: Orders = { tut = 1, list = {}, refreshAt = 0, counters = {} }
	orders[player] = o
	-- Older saves count steps of the old tutorials: version 1 (8 steps, before the Hoard step) is
	-- shifted onto version 2 (9 steps: smash, hoard, place, brew, sell, tool, ghosts, lock, King),
	-- then version 3 maps onto R20 (farm candy, Iron, steal, hatch, fill two).
	-- Completed tutorials stay complete; migrated saves get freshly dealt orders.
	local shifted = false
	if type(saved) == "table" then
		if type(saved.tut) == "number" then
			local tut = math.max(1, math.floor(saved.tut))
			if saved.v ~= 3 and saved.v ~= 4 and saved.v ~= 5 then
				if saved.v ~= 2 and tut >= 2 then
					tut += 1
				end
				-- Old (version 2) step -> new step; 10+ = the old tutorial was finished.
				local V2_TO_V3 = { 1, 2, 2, 4, 4, 4, 5, 5, 5 }
				tut = V2_TO_V3[tut] or TUTORIAL_COUNT + 1
				-- Re-deal: old rotating lists may hold orders of systems that are locked now.
				shifted = true
			end
			if saved.v ~= 4 and saved.v ~= 5 then
				local V3_TO_V4 = { 1, 3, 3, 2, 5 }
				tut = V3_TO_V4[tut] or TUTORIAL_COUNT + 1
				shifted = true
			end
			if saved.v ~= 5 then
				local map = { 3, 4, 1, 2, 5 }
				tut = map[tut] or TUTORIAL_COUNT + 1
				shifted = true
			end
			o.tut = math.clamp(tut, 1, TUTORIAL_COUNT + 1)
		end
		if type(saved.refreshAt) == "number" then
			o.refreshAt = saved.refreshAt
		end
		if type(saved.counters) == "table" then
			for stat, n in saved.counters do
				if type(stat) == "string" and type(n) == "number" then
					o.counters[stat] = n
				end
			end
		end
		if type(saved.list) == "table" and not shifted then
			for _, s in saved.list do
				local order = type(s) == "table" and type(s.id) == "string" and makeOrder(s.id)
				if order then
					order.have = tonumber(s.have) or 0
					order.done = s.done == true
					local def = Config.RotatingOrders[tonumber(string.sub(s.id, 2)) or 0]
					if
						string.sub(s.id, 1, 1) == "R"
						and def
						and def.reach
						and type(s.need) == "number"
					then
						order.need = s.need
						order.text = string.format(def.text, Helpers.short(s.need))
					end
					if
						string.sub(s.id, 1, 1) == "R"
						and type(s.reward) == "table"
						and type(s.reward.candy) == "number"
					then
						order.reward = { candy = s.reward.candy }
					end
					table.insert(o.list, order)
				end
			end
		end
	end
	local stale
	if o.tut <= TUTORIAL_COUNT then
		stale = not (o.list[1] and o.list[1].id == "T" .. o.tut)
	else
		stale = #o.list == 0 or os.time() >= o.refreshAt
		for _, order in o.list do
			if
				Progress.orderExpired(player, order)
				or Config.RemovedOrders[string.match(order.stat, "^[^:]+") or order.stat]
			then
				stale = true
			end
		end
	end
	if stale then
		nextOrders(player)
	end
end

local function saveOrders(player: Player): any
	local o = orders[player]
	if not o then
		return nil
	end
	local list = {}
	for _, order in o.list do
		table.insert(list, {
			id = order.id,
			have = order.have,
			done = order.done,
			need = order.need,
			reward = string.sub(order.id, 1, 1) == "R" and order.reward or nil,
		})
	end
	return { v = 5, tut = o.tut, refreshAt = o.refreshAt, counters = o.counters, list = list }
end

-- Saving -------------------------------------------------------------------------------------
-- UpdateAsync with a session lock so a server hop cannot load stale data or overwrite newer
-- data. Everything is in pcall: in unpublished Studio the store is turned off and play goes on.

local store = nil
pcall(function()
	store = Services.DataStoreService:GetDataStore("PumpkinPatchPanic_v1")
end)
local boardStore = nil
pcall(function()
	boardStore = Services.DataStoreService:GetOrderedDataStore("LifetimeCandy")
end)
local loaded: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}
local released: { [Player]: boolean } = {}
-- UserIds whose last-of-session save is still being written; a rejoin waits for it.
local releasing: { [number]: boolean } = {}
-- DataStore writes in progress; BindToClose waits for all of them.
local inFlight = 0
local dailyOf: { [Player]: { day: number, streak: number } } = {}
-- PurchaseIds of developer products already granted (newest last, at most RECEIPTS_KEPT).
local receiptsOf: { [Player]: { string } } = {}
local RECEIPTS_KEPT = 50

-- Bases: placed pumpkins, income, stealing and locks. Its functions are filled in further down
-- (the save code below calls Bases.collect and Bases.restore).
-- carvedOf[player] = pumpkin types that player has hatched (first hatch reveals; saved "carved").
local Bases: { [string]: any } = { left = {}, carvedOf = {} }
-- Hoards and their guardians (one per zone). Filled in further down; Bases and the Drop / Haunt
-- code call Hoards.giveBack and Hoards.look.
local Hoards: { [string]: any } = {}

local loadPlayer, applyData, savePlayer, releaseLock -- defined in the block below
do
	local function dataKey(player: Player): string
		return "player_" .. player.UserId
	end

	local function lockFree(lock: any): boolean
		return type(lock) ~= "table"
			or lock.jobId == game.JobId
			or type(lock.time) ~= "number"
			or os.time() - lock.time > Config.SaveLockSeconds
	end

	-- Returns "ok" with the data (nil for a new player), "locked" or "error".
	local function readData(player: Player): (string, any)
		local locked = false
		local ok, result = pcall(function()
			return store:UpdateAsync(dataKey(player), function(old)
				locked = false
				local data = type(old) == "table" and old or {}
				if not lockFree(data.lock) then
					locked = true
					return nil
				end
				data.lock = { jobId = game.JobId, time = os.time() }
				return data
			end)
		end)
		if not ok then
			return "error", result
		elseif locked then
			return "locked", nil
		end
		return "ok", result
	end

	-- Returns (true, data) when the player may play; data is nil when nothing is saved.
	function loadPlayer(player: Player): (boolean, any, string?)
		if not store then
			return true, nil
		end
		-- A quick rejoin to this same server must not read data its own last save is still writing.
		local waited = os.clock()
		while releasing[player.UserId] and player.Parent and os.clock() - waited < 30 do
			task.wait(0.2)
		end
		local status, data = "error", nil
		for attempt = 1, Config.LoadTries do
			status, data = readData(player)
			if status == "ok" or not player.Parent then
				break
			end
			if status == "error" and Services.RunService:IsStudio() then
				warn("[Patch] DataStore unavailable, progress will not save in this session:", data)
				store = nil
				return true, nil
			end
			task.wait(2 ^ (attempt - 1))
		end
		if status ~= "ok" then
			return false, nil, status
		end
		loaded[player] = true
		return true, data
	end

	function applyData(player: Player, data: { [string]: any })
		Progress.load(player, data.progression)
		local candy = Helpers.candyValue(player)
		if candy and type(data.candy) == "number" then
			candy.Value = data.candy
		end
		local stats = player:FindFirstChild("leaderstats")
		local kings = stats and stats:FindFirstChild("Kings") :: IntValue?
		if kings and type(data.kings) == "number" then
			kings.Value = data.kings
		end
		-- Old saves also have "seeds" (from seed planting): ignored.
		local tools = toolsOf[player] or { [Config.StartTool] = true }
		toolsOf[player] = tools
		if type(data.tools) == "table" then
			for _, id in data.tools do
				if type(id) == "string" and Lookup.toolById[id] then
					tools[id] = true
				end
			end
		end
		publishTools(player)
		local zones = zonesOf[player] or {}
		zonesOf[player] = zones
		if type(data.zones) == "table" then
			for _, id in data.zones do
				if type(id) == "string" and Config.Zones[id] then
					zones[id] = true
				end
			end
		end
		publishZones(player)
		Progress.arrive(player)
		if type(data.placed) == "table" then
			Bases.restore(player, data.placed)
		end
		if type(data.index) == "table" then
			local found = indexOf[player] or {}
			for _, key in data.index do
				if type(key) == "string" then
					found[key] = true
				end
			end
			indexOf[player] = found
			publishIndex(player)
		end
		Helpers.Index.load(player, data)
		if type(data.upgrades) == "table" then
			for id in Config.Upgrades do
				if type(data.upgrades[id]) == "number" then
					player:SetAttribute(
						"Up_" .. id,
						math.clamp(math.floor(data.upgrades[id]), 0, Config.Upgrades[id].max)
					)
				end
			end
		end
		if type(data.lifetime) == "number" then
			lifetime[player] = data.lifetime
		end
		-- "found" = pumpkin types found. Old saves' "unlocked" (seeds bought) is ignored.
		if type(data.found) == "table" then
			local found = unlocked[player] or startUnlocked()
			for _, id in data.found do
				if type(id) == "string" and Lookup.seedById[id] then
					found[id] = true
				end
			end
			unlocked[player] = found
		end
		for key, attr in { haunts = "Haunts", souls = "Souls", cursedTokens = "CursedTokens" } do
			if type(data[key]) == "number" then
				player:SetAttribute(attr, data[key])
			end
		end
		local owned = skillsOf[player] or {}
		skillsOf[player] = owned
		if type(data.skills) == "table" then
			for _, id in data.skills do
				if type(id) == "string" and Lookup.skillById[id] then
					owned[id] = true
				end
			end
		end
		-- Saves from the old Soul shop: carry bought items over to their skills.
		if type(data.soulItems) == "table" then
			for oldId, newId in
				{ KeepStack = "KeepStack", AutoBrew = "AutoBrew", Cursed = "CursedLuck" }
			do
				local level = data.soulItems[oldId]
				if type(level) == "number" and level > 0 then
					owned[newId] = true
				end
			end
		end
		publishSkills(player)
		if type(data.title) == "string" then
			player:SetAttribute("Title", data.title)
		end
		player:SetAttribute("FirstSmashCandy", data.firstSmashCandy == true)
		player:SetAttribute("FirstGrabPets", data.firstGrabPets == true)
		if data.firstHoard == true then
			player:SetAttribute("FirstHoardDone", true)
		end
		-- Total playtime (unlock gates, the new-player shield) and sticky unlocks.
		if type(data.playTime) == "number" then
			player:SetAttribute("PlayTime", math.max(0, math.floor(data.playTime)))
		end
		if type(data.unlocks) == "table" then
			for _, name in data.unlocks do
				if type(name) == "string" and table.find(Unlock.NAMES, name) then
					player:SetAttribute("Unlock_" .. name, true)
				end
			end
		end
		local carved = Bases.carvedOf[player] or {}
		Bases.carvedOf[player] = carved
		if type(data.carved) == "table" then
			for _, id in data.carved do
				if type(id) == "string" and Lookup.seedById[id] then
					carved[id] = true
					Progress.own(player, id)
				end
			end
		end
		if
			type(data.daily) == "table"
			and type(data.daily.day) == "number"
			and type(data.daily.streak) == "number"
		then
			dailyOf[player] = { day = data.daily.day, streak = data.daily.streak }
		end
		local receipts = {}
		if type(data.purchases) == "table" then
			for _, id in data.purchases do
				if type(id) == "string" then
					table.insert(receipts, id)
				end
			end
		end
		while #receipts > RECEIPTS_KEPT do
			table.remove(receipts, 1)
		end
		receiptsOf[player] = receipts
		-- Saves from before onboarding analytics count as already onboarded.
		local steps = {}
		if type(data.onboard) == "table" then
			for _, step in data.onboard do
				if type(step) == "number" then
					steps[step] = true
				end
			end
		elseif type(data.candy) == "number" then
			for step in ONBOARD_STEPS do
				steps[step] = true
			end
		end
		onboardOf[player] = steps
		-- Saves from before Witch's Orders skip the tutorial (a maxed Stack could never finish it).
		local savedOrders = data.orders
		if savedOrders == nil and type(data.candy) == "number" then
			savedOrders = { v = 3, tut = TUTORIAL_COUNT + 1 }
		end
		loadOrders(player, savedOrders)
		Bases.restoreCarry(player, data.carrying or data.carry)
		local migrated = 0
		for _, entry in
			type(data.carrying or data.carry) == "table" and (data.carrying or data.carry) or {}
		do
			local seed = type(entry) == "table"
				and Lookup.seedById[entry.s or entry.seed or entry.Seed]
			if
				seed
				and entry.h ~= true
				and entry.hoard ~= true
				and entry.j ~= true
				and entry.jack ~= true
			then
				migrated += math.max(1, math.floor(seed.income * Config.PopCandySeconds))
			end
		end
		if migrated > 0 then
			addCandy(player, migrated)
			Remotes.hintEvent:FireClient(player, "Your farmed pumpkins became candy!")
		end
		for _, zoneId in Config.ZoneOrder do
			if type(data.wakes) == "table" and data.wakes[zoneId] == true then
				player:SetAttribute("Wake_" .. zoneId, true)
			end
		end
		Progress.updateBonus(player, data)
	end

	local function snapshot(player: Player): { [string]: any }
		local candy = Helpers.candyValue(player)
		assert(candy, "no leaderstats")
		local tools, upgrades, skills = {}, {}, {}
		for id in toolsOf[player] or {} do
			table.insert(tools, id)
		end
		for id in Config.Upgrades do
			upgrades[id] = Helpers.upgradeLevel(player, id)
		end
		for _, skill in Config.Skills do
			if hasSkill(player, skill.id) then
				table.insert(skills, skill.id)
			end
		end
		local index, unlockedList = {}, {}
		for key in indexOf[player] or {} do
			table.insert(index, key)
		end
		for id in unlocked[player] or {} do
			table.insert(unlockedList, id)
		end
		local onboardList, zoneList = {}, {}
		for step in onboardOf[player] or {} do
			table.insert(onboardList, step)
		end
		for _, zoneId in Config.ZoneOrder do
			if hasZone(player, zoneId) then
				table.insert(zoneList, zoneId)
			end
		end
		local stats = player:FindFirstChild("leaderstats")
		local kings = stats and stats:FindFirstChild("Kings") :: IntValue?
		local carvedList, unlockList, wakes = {}, {}, {}
		for _, zoneId in Config.ZoneOrder do
			wakes[zoneId] = player:GetAttribute("Wake_" .. zoneId) == true
		end
		for id in Bases.carvedOf[player] or {} do
			table.insert(carvedList, id)
		end
		for _, name in Unlock.NAMES do
			if Unlock.has(player, name) then
				table.insert(unlockList, name)
			end
		end
		return {
			progression = Progress.data[player] and Services.HttpService:JSONDecode(
				Services.HttpService:JSONEncode(Progress.data[player])
			),
			saveVersion = Config.Economy.saveVersion,
			playTime = player:GetAttribute("PlayTime") or 0,
			unlocks = unlockList,
			firstHoard = player:GetAttribute("FirstHoardDone") == true,
			wakes = wakes,
			firstSmashCandy = player:GetAttribute("FirstSmashCandy") == true,
			firstGrabPets = player:GetAttribute("FirstGrabPets") == true,
			carved = carvedList,
			candy = candy.Value,
			kings = kings and kings.Value or 0,
			tools = tools,
			zones = zoneList,
			placed = Bases.collect(player),
			carrying = Bases.collectCarry(player),
			upgrades = upgrades,
			index = index,
			IndexClaims = table.clone(Helpers.Index.claims[player] or {}),
			IndexMilestones = table.clone(Helpers.Index.milestones[player] or {}),
			lifetime = math.floor(lifetime[player] or 0),
			found = unlockedList,
			haunts = player:GetAttribute("Haunts") or 0,
			souls = player:GetAttribute("Souls") or 0,
			cursedTokens = player:GetAttribute("CursedTokens") or 0,
			skills = skills,
			title = player:GetAttribute("Title"),
			daily = dailyOf[player],
			orders = saveOrders(player),
			purchases = table.clone(receiptsOf[player] or {}),
			onboard = onboardList,
		}
	end

	-- release = this is the last save of the session (leaving or shutdown): free the lock.
	-- Returns true when the data was written.
	function savePlayer(player: Player, release: boolean?): boolean
		if not store or not loaded[player] or released[player] then
			return false
		end
		while saving[player] do
			task.wait(0.2)
		end
		if not store or not loaded[player] or released[player] then
			return false
		end
		local ok, data = pcall(snapshot, player)
		if not ok then
			warn("[Patch] Could not build save for", player.Name, data)
			return false
		end
		saving[player] = true
		inFlight += 1
		local userId = player.UserId
		if release then
			released[player] = true
			releasing[userId] = true
		end
		data.lock = if release then nil else { jobId = game.JobId, time = os.time() }
		-- The last save of a session is the one that matters most: retry it.
		local tries = release and 3 or 1
		local saved, err = false, nil
		-- False when the lock belonged to another server and nothing was written.
		local wrote = false
		for attempt = 1, tries do
			saved, err = pcall(function()
				store:UpdateAsync(dataKey(player), function(old)
					if type(old) == "table" and not lockFree(old.lock) then
						-- Another server owns this player now; never overwrite its newer data.
						wrote = false
						return nil
					end
					wrote = true
					return data
				end)
			end)
			if saved then
				break
			elseif attempt < tries then
				task.wait(attempt)
			end
		end
		if not saved then
			warn("[Patch] Save failed for", player.Name, err)
		end
		if boardStore and data.lifetime > 0 then
			pcall(function()
				boardStore:SetAsync(tostring(userId), data.lifetime)
			end)
		end
		if release then
			releasing[userId] = nil
		end
		inFlight -= 1
		saving[player] = nil
		return saved and wrote
	end

	-- A player left while loading: give the lock back without touching their data.
	function releaseLock(player: Player)
		if not store then
			return
		end
		pcall(function()
			store:UpdateAsync(dataKey(player), function(old)
				if
					type(old) ~= "table"
					or type(old.lock) ~= "table"
					or old.lock.jobId ~= game.JobId
				then
					return nil
				end
				old.lock = nil
				return old
			end)
		end)
	end
end

-- Pumpkins ----------------------------------------------------------------------------------

local seedTemplate
do
	local templateCache = {}
	function seedTemplate(seed): MeshPart
		local cached = templateCache[seed.id]
		if cached then
			return cached
		end
		local body = nil
		local volume = 0
		for _, candidate in kit[seed.template]:GetDescendants() do
			if candidate:IsA("MeshPart") then
				local v = candidate.Size.X * candidate.Size.Y * candidate.Size.Z
				if v > volume then
					body, volume = candidate, v
				end
			end
		end
		assert(body, "Missing pumpkin body mesh: " .. seed.template)
		local mesh = body:Clone()
		mesh.Anchored = true
		mesh.CanCollide = false
		mesh.CanTouch = false
		if seed.color then
			mesh.TextureID = ""
			mesh.Material = Enum.Material.SmoothPlastic
			mesh.Color = seed.color
		end
		templateCache[seed.id] = mesh
		return mesh
	end
end

local function makePumpkin(seedId: string, sizeMult: number): MeshPart
	local seed = Lookup.seedById[seedId]
	local pumpkin = seedTemplate(seed):Clone()
	pumpkin.Name = "Pumpkin"
	pumpkin.Size *= seed.scale * sizeMult / (pumpkin.Size.X / 2.5)
	pumpkin:SetAttribute("Seed", seedId)
	pumpkin:SetAttribute("SizeMult", sizeMult)
	return pumpkin
end

-- Candy per second of a placed pumpkin before the owner's Haunt / pass multipliers. Hoard
-- pumpkins (attribute Hoard) earn x Config.HoardMult.
local function incomeOf(pumpkin: Instance): number
	local seed = Lookup.seedById[pumpkin:GetAttribute("Seed")]
	local mutation = Lookup.mutationById[pumpkin:GetAttribute("Mutation") or ""]
	return (seed and seed.income or 1)
		* (pumpkin:GetAttribute("SizeMult") or 1)
		* (mutation and mutation.mult or 1)
		* (pumpkin:GetAttribute("Hoard") == true and Config.HoardMult or 1)
		* (pumpkin:GetAttribute("Gold") and Config.Progression.goldIncome or 1)
		* (pumpkin:GetAttribute("Shiny") and Config.Progression.shinyIncome or 1)
end

-- What the Witch pays (before the seller's multipliers): SellPerIncome seconds of income.
local function pumpkinValue(pumpkin: Instance, seconds: number?): number
	if pumpkin:GetAttribute("Bought") then
		seconds = Config.SellPerIncome
	end
	return math.max(1, math.floor(incomeOf(pumpkin) * (seconds or Config.SellPerIncome) + 0.5))
end

-- Reward reveal: a white flash and a card on the gainer's screen for a pumpkin type they never had
-- (no Index entry and not found before; checked before the gain), a rare type (Config.RevealOrder
-- up) or a Cursed brew. Reveal.isNew must run before stackPumpkin marks the type found.
local Reveal: { [string]: any } = {}
do
	-- Types already revealed as new this session (weak keys: gone with the Player).
	local seenOf: { [Player]: { [string]: boolean } } = setmetatable({}, { __mode = "k" }) :: any

	function Reveal.isNew(player: Player, seedId: string): boolean
		local seen = seenOf[player]
		if seen and seen[seedId] then
			return false
		end
		-- Orange is in every fresh "found" set, so only the Index can say it was had before.
		local found = unlocked[player]
		if seedId ~= Config.Seeds[1].id and found and found[seedId] then
			return false
		end
		local prefix = seedId .. ":"
		for key in indexOf[player] or {} do
			if string.sub(key, 1, #prefix) == prefix then
				return false
			end
		end
		return true
	end

	-- kind: "jack" (first carve of a type) or "hoard" (a Hoard pumpkin delivered) always shows.
	function Reveal.send(player: Player, pumpkin: Instance, isNew: boolean, kind: string?)
		local seed = Lookup.seedById[pumpkin:GetAttribute("Seed") or ""]
		if not seed or not player.Parent then
			return
		end
		local mutation = pumpkin:GetAttribute("Mutation")
		if seed.order < Config.RevealOrder and mutation ~= "Cursed" then
			return
		end
		local seen = seenOf[player] or {}
		seenOf[player] = seen
		seen[seed.id] = true
		local rate = math.floor(
			incomeOf(pumpkin) * Helpers.sellMult(player) * Progress.candyMult(player) * 10 + 0.5
		) / 10
		-- The pet it hatched into (if any): the card shows the pet and its name.
		local pet = pumpkin:GetAttribute("Pet")
		Remotes.revealEvent:FireClient(
			player,
			seed.id,
			mutation,
			isNew,
			rate,
			kind,
			pet,
			pumpkin:GetAttribute("WeightKg")
		)
	end
end

local brewPumpkin, applyMutationLook
do
	-- No PointLight here: 24 players x a full stack of lit pumpkins is too heavy on mobile.
	function applyMutationLook(pumpkin: BasePart, mutationId: string)
		local mutation = Lookup.mutationById[mutationId]
		if not mutation then
			return
		end
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "MagicSparkle"
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(mutation.color)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new(0.5, 0)
		sparkle.Lifetime = NumberRange.new(0.6, 1.1)
		sparkle.Rate = 8
		sparkle.Speed = NumberRange.new(1, 2)
		sparkle.Parent = pumpkin
		if mutationId == "Ghostly" then
			-- A pet / mystery look (child Model "PetLook") fades instead of its invisible carrier.
			local look = pumpkin:FindFirstChild("PetLook")
			for _, d in look and look:GetDescendants() or {} do
				if d:IsA("BasePart") and d.Transparency < 1 then
					d.Transparency = math.max(d.Transparency, 0.45)
				end
			end
			if not look then
				pumpkin.Transparency = 0.45
			end
		elseif mutationId == "Cursed" then
			local fire = Instance.new("Fire")
			fire.Color = Color3.fromRGB(150, 50, 255)
			fire.SecondaryColor = Color3.fromRGB(60, 0, 120)
			fire.Size = 3
			fire.Heat = 3
			fire.Parent = pumpkin
		end
	end

	local function rollMutation(extraCursed: number): string
		local bloodMoon = state:GetAttribute("Phase") == "BloodMoon"
		local chances = {}
		for _, m in Config.Mutations do
			local chance = bloodMoon and (Config.BloodMoonChances[m.id] or m.chance) or m.chance
			if m.id == "Cursed" then
				chance += extraCursed
			elseif m.id == "Glowing" then
				chance -= extraCursed
			end
			table.insert(chances, { id = m.id, chance = chance })
		end
		local r = math.random()
		for _, c in chances do
			if r <= c.chance then
				return c.id
			end
			r -= c.chance
		end
		return chances[1].id
	end

	-- Brew one carried pumpkin. A Cursed token (daily day 7) makes the next cauldron brew Cursed;
	-- Auto-Brew passes useToken = false so tokens are never spent on harvest.
	-- Cursed Luck adds Cursed chance; Double Brew rolls twice and keeps the better finish.
	function brewPumpkin(player: Player, pumpkin: BasePart, useToken: boolean): string
		local id
		local tokens = player:GetAttribute("CursedTokens") or 0
		if useToken and tokens > 0 then
			id = "Cursed"
			player:SetAttribute("CursedTokens", tokens - 1)
		else
			local extra = hasSkill(player, "CursedLuck") and Config.SkillCursedBonus or 0
			id = rollMutation(extra)
			if hasSkill(player, "DoubleBrew") then
				local again = rollMutation(extra)
				if Lookup.mutationById[again].mult > Lookup.mutationById[id].mult then
					id = again
				end
			end
		end
		pumpkin:SetAttribute("Mutation", id)
		applyMutationLook(pumpkin, id)
		if id == "Candy" or id == "Cursed" then
			track(player, "brewRare", 1)
		end
		return id
	end
end

-- Patches (bases) -----------------------------------------------------------------------------

local patchOf: { [Player]: Model } = {}
-- The pumpkin placed on each plot (nil when the plot is empty).
type PlotState = { pumpkin: BasePart? }
local plotState: { [BasePart]: PlotState } = {}

local function setOwnerSign(patch: Model, text: string, color: Color3)
	local post = patch:FindFirstChild("SignPost")
	local sign = post and post:FindFirstChild("OwnerSign", true)
	local label = sign and sign:FindFirstChild("Label", true) :: TextLabel?
	if label then
		local bb = label:FindFirstAncestorWhichIsA("BillboardGui")
		if bb then
			bb.MaxDistance = 100
			if not bb:GetAttribute("R20Small") then
				bb:SetAttribute("R20Small", true)
				bb.Size = UDim2.new(
					bb.Size.X.Scale * 0.65,
					bb.Size.X.Offset * 0.65,
					bb.Size.Y.Scale * 0.65,
					bb.Size.Y.Offset * 0.65
				)
			end
		end
		label.Text = text
		label.Visible = text ~= ""
		if sign:IsA("BillboardGui") or sign:IsA("SurfaceGui") then
			sign.Enabled = text ~= ""
		end
		label.TextColor3 = color
	end
end

local carrying: { [Player]: { BasePart } } = {}
-- Exact server quote, including Index bonuses and explicit sale rounding.
function Helpers.sellQuote(player: Player): number
	local total = 0
	for _, p in carrying[player] or {} do
		if p.Parent then
			local bonus = rowDone(player, p:GetAttribute("Seed")) and (1 + Config.IndexRowBonus)
				or 1
			total += pumpkinValue(p, Config.WitchSellSeconds) * bonus
		end
	end
	total = math.floor(total * Helpers.sellMult(player) + 0.5)
	return math.floor(total * Progress.candyMult(player) + 0.5)
end
local function refreshCarry(player: Player)
	if Bases.drainCarry and Progress.pending[player] and not Progress.draining[player] then
		task.defer(Bases.drainCarry, player)
	end
	local stack = carrying[player] or {}
	player:SetAttribute("Carry", #stack)
	local top = stack[#stack]
	player:SetAttribute(
		"CarryPet",
		top ~= nil and (top:GetAttribute("Hoard") == true or top:GetAttribute("Jack") == true)
	)
	player:SetAttribute("CarryValue", Helpers.sellQuote(player))
	player:SetAttribute(
		"CarryTopValue",
		#stack > 0
				and math.floor(
					pumpkinValue(stack[#stack], Config.FullPenSellSeconds)
							* Helpers.sellMult(player)
							* Progress.candyMult(player)
						+ 0.5
				)
			or 0
	)
	local brewed, stolen, hoard = 0, 0, 0
	local from: { [number]: boolean } = {}
	for _, p in stack do
		if p:GetAttribute("Mutation") then
			brewed += 1
		end
		-- Fresh from a Hoard nest (not delivered yet): RUN!! and the guardian chase.
		if p:GetAttribute("HoardZone") then
			hoard += 1
		end
		local ownerId = p:GetAttribute("StolenFrom")
		if type(ownerId) == "number" and ownerId ~= player.UserId then
			stolen += 1
			from[ownerId] = true
		end
	end
	player:SetAttribute("CarryBrewed", brewed)
	-- Stolen pumpkins carried (RUN!! / Drop on the thief's screen) and from whom: ",id1,id2,"
	-- so each robbed owner's client can highlight the thief.
	player:SetAttribute("CarryStolen", stolen)
	player:SetAttribute("CarryHoard", hoard)
	local ids = {}
	for id in from do
		table.insert(ids, tostring(id))
	end
	player:SetAttribute("StealingFrom", #ids > 0 and ("," .. table.concat(ids, ",") .. ",") or nil)
end

-- The player's character and root, only while the humanoid is alive.
local function aliveRoot(player: Player): (Model?, BasePart?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return character, root
end

-- Removes prompts, welds and billboards (income tag, HP bar) from a pumpkin that changes hands.
local function stripPumpkin(pumpkin: BasePart)
	for _, child in pumpkin:GetChildren() do
		if
			child:IsA("ProximityPrompt")
			or child:IsA("WeldConstraint")
			or child:IsA("BillboardGui")
		then
			child:Destroy()
		end
	end
end

-- Model looks (ServerStorage.PetModels: hatched pets only). The pumpkin
-- part stays the carrier (its attributes, prompts, tags and welds work as before) but turns
-- invisible and takes the size of a clone of the model (child Model "PetLook", Welds inside its
-- parts), so plots, stacks, drops and ghosts fit the look. Attribute "Look" = "Folder/Name" (to
-- rebuild it after a resize), "BaseSize" = the pumpkin's own size (to go back to a pumpkin).
local Looks: { [string]: any } = {}
-- Reuse the mesh carrier and its ribs; add dark grooves and a readable carved face.
-- Decorations are welded, non-colliding and disappear with their pumpkin.
function Looks.wild(p: BasePart, seed)
	local rank = table.find(Config.Seeds, seed) or 1
	local width = 3 + math.min(rank - 1, 10) * 0.5
	if seed.id == "KingSeed" then
		width = 8
	end
	local mult = p:GetAttribute("SizeMult") or 1
	p.Size *= width * mult / p.Size.X
	local base = seed.color
		or (seed.id == "Sunny" and Color3.fromRGB(255, 181, 32))
		or Color3.fromRGB(242, 140, 27)
	local function piece(name, size, offset, color, shape)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Color = name, size, color
		part.Shape = shape or Enum.PartType.Ball
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Massless = true
		part.CFrame = p.CFrame * offset
		local weld = Instance.new("Weld")
		weld.Part0, weld.Part1, weld.C0 = p, part, offset
		weld.Parent = part
		part.Parent = p
		return part
	end
	-- Narrow darker lobes follow the existing round silhouette instead of flattening it.
	for i = 1, 8 do
		local angle = i * math.pi / 4
		piece(
			"PumpkinRib",
			Vector3.new(p.Size.X * 0.16, p.Size.Y * 0.82, p.Size.Z * 0.16),
			CFrame.new(
				math.cos(angle) * p.Size.X * 0.43,
				-p.Size.Y * 0.04,
				math.sin(angle) * p.Size.Z * 0.43
			),
			base:Lerp(Color3.new(0, 0, 0), 0.24)
		)
	end
	for _, x in { -0.17, 0.17 } do
		piece(
			"CarvedEye",
			Vector3.new(p.Size.X * 0.14, p.Size.Y * 0.16, p.Size.Z * 0.06),
			CFrame.new(x * p.Size.X, p.Size.Y * 0.09, -p.Size.Z * 0.46),
			Color3.fromRGB(32, 18, 42)
		)
	end
	piece(
		"CarvedMouth",
		Vector3.new(p.Size.X * 0.28, p.Size.Y * 0.1, p.Size.Z * 0.06),
		CFrame.new(0, -p.Size.Y * 0.16, -p.Size.Z * 0.47),
		Color3.fromRGB(32, 18, 42)
	)
end
do
	local function source(folder: string, name: string?): Model?
		local holder = Services.ServerStorage:FindFirstChild(folder)
		local m = holder and name and holder:FindFirstChild(name)
		if m and m:IsA("Model") then
			Config.fixModelFront(m)
		end
		return if m and m:IsA("Model") then m else nil
	end
	Looks.source = source

	-- Re-seats the carrier so its bottom stays where it was, at a new size (yaw kept).
	local function reseat(p: BasePart, size: Vector3)
		local bottom = p.Position.Y - p.Size.Y / 2
		local cf = p.CFrame
		p.Size = size
		p.CFrame = CFrame.new(cf.X, bottom + size.Y / 2, cf.Z) * cf.Rotation
		for name, extra in { IncomeTag = 1.2, CarveTag = 2.6 } do
			local tag = p:FindFirstChild(name)
			if tag and tag:IsA("BillboardGui") then
				tag.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + extra, 0)
			end
		end
	end

	-- Back to the plain pumpkin look (no model).
	function Looks.clear(p: BasePart)
		local old = p:FindFirstChild("PetLook")
		if old then
			old:Destroy()
		end
		local base = p:GetAttribute("BaseSize")
		if typeof(base) == "Vector3" then
			reseat(p, base)
		end
		p:SetAttribute("Look", nil)
		p:SetAttribute("Pet", nil)
		p.Transparency = p:GetAttribute("Mutation") == "Ghostly" and 0.45 or 0
	end

	-- Puts a clone of ServerStorage.<folder>.<name> on the carrier, height studs tall, standing
	-- where the carrier's bottom is and facing its front (-Z). glow = a PointLight in the look.
	-- Replaces an older look; false (nothing changed) when the model is missing or empty.
	function Looks.attach(p: BasePart, folder: string, name: string?, height: number, glow: Color3?)
		local m: Model? = nil
		local ok, attached = pcall(function()
			local src = source(folder, name)
			if not src then
				return false
			end
			m = src:Clone()
			if not m then
				return false
			end
			for _, d in m:GetDescendants() do
				if
					d:IsA("LuaSourceContainer")
					or d:IsA("Humanoid")
					or d:IsA("ProximityPrompt")
					or d:IsA("ClickDetector")
					or d:IsA("Sound")
				then
					d:Destroy()
				end
			end
			local _, size = m:GetBoundingBox()
			if size.Y <= 0.01 then
				m:Destroy()
				return false
			end
			m:ScaleTo(m:GetScale() * height / size.Y)
			local boxCf, box = m:GetBoundingBox()
			local old = p:FindFirstChild("PetLook")
			if old then
				old:Destroy()
			end
			for _, child in p:GetChildren() do
				if child.Name == "JackPart" then
					child:Destroy()
				end
			end
			if p:GetAttribute("BaseSize") == nil then
				p:SetAttribute("BaseSize", p.Size)
			end
			reseat(p, box)
			m:PivotTo(p.CFrame * boxCf:ToObjectSpace(m:GetPivot()))
			local ghostly = p:GetAttribute("Mutation") == "Ghostly"
			local first: BasePart? = nil
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					first = first or d
					d.Anchored = false
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
					d.Massless = true
					if ghostly and d.Transparency < 1 then
						d.Transparency = math.max(d.Transparency, 0.45)
					end
					-- A Weld (fixed C0) rather than a WeldConstraint: it holds even when the carrier
					-- is moved before it is in the workspace.
					local weld = Instance.new("Weld")
					weld.Name = "LookWeld"
					weld.Part0 = p
					weld.Part1 = d
					weld.C0 = p.CFrame:ToObjectSpace(d.CFrame)
					weld.Parent = d
				end
			end
			if glow and first then
				local light = Instance.new("PointLight")
				light.Name = "LookGlow"
				light.Color = glow
				light.Range = 10
				light.Brightness = 1.4
				light.Shadows = false
				light.Parent = first
			end
			m.Name = "PetLook"
			m.Parent = p
			p.Transparency = 1
			p:SetAttribute("Look", folder .. "/" .. (name :: string))
			return true
		end)
		if not ok or not attached then
			if m then
				m:Destroy()
			end
			Helpers.warnOnce(name or folder, "Pet look failed; using fallback: " .. tostring(name))
			return false
		end
		return true
	end

	-- Rebuilds the look at the carrier's current height (after it was scaled).
	function Looks.refit(p: BasePart)
		local look = p:GetAttribute("Look")
		local folder, name = string.match(type(look) == "string" and look or "", "^([^/]+)/(.+)$")
		if folder and name then
			local glow = p:FindFirstChild("LookGlow", true) :: PointLight?
			Looks.attach(p, folder, name, p.Size.Y, glow and glow.Color)
		end
	end

	function Looks.rollGold(player, p)
		if p and p:GetAttribute("GoldRolled") then
			return p:GetAttribute("Gold") == true
		end
		local gold = player ~= nil
			and hasZone(player, "Zone6")
			and math.random(Config.Progression.goldOneIn) == 1
		if p then
			p:SetAttribute("GoldRolled", true)
			p:SetAttribute("Gold", gold or nil)
		end
		return gold
	end
	-- Hatches a placed pumpkin into its type's pet (Config.Seeds[n].pet). False (and the
	-- pumpkin unchanged) when that pet has no model in ServerStorage.PetModels.
	function Looks.isFacePart(part: BasePart, pet: string?): boolean
		local keys = Config.PetFaceKeys[pet or ""]
		if keys and #part.Name == 1 then
			return table.find(keys, part.Name) ~= nil
		end
		return part:GetAttribute("FacePart") == true or part.Name == "Eye" or part.Name == "Face"
	end
	function Looks.hatch(p: BasePart, seed): boolean
		local pet = seed and seed.pet
		local modelName = pet == "Kinglet" and not source("PetModels", "Kinglet") and "KingCat"
			or pet
		local def = pet and Config.Pets[pet]
		local size = Config.PetSizes[def and def.rarity or "Common"] or Config.PetSizes.Common
		local kg = p:GetAttribute("WeightKg")
		if type(kg) ~= "number" or kg ~= kg or kg <= 0 or kg == math.huge then
			kg = math.floor(size.median * math.exp((math.random() - 0.5) * 3.2) * 10 + 0.5) / 10
			p:SetAttribute("WeightKg", kg)
		end
		local height = math.clamp(
			size.height * math.clamp((kg / size.median) ^ 0.2, 0.9, 1.25),
			Config.Plots.minPetHeight,
			Config.Plots.maxPetHeight
		)
		local visual = source("PetModels", modelName) or source("PetModels", "PumpkinPup")
		if visual then
			local _, box = visual:GetBoundingBox()
			if box.Y > 0 then
				height = math.min(
					height,
					(size.width or Config.Plots.maxPetWidth) * box.Y / math.max(box.X, box.Z, 0.01)
				)
			end
		end
		-- Weight controls income; the pet visual must fit a pen slot.
		p:SetAttribute("PetHeight", height)
		p:SetAttribute("Pet", pet)
		if not Looks.attach(p, "PetModels", modelName, height) then
			if not Looks.attach(p, "PetModels", "PumpkinPup", height) then
				Looks.clear(p)
				reseat(p, Vector3.new(height, height, height))
				p:SetAttribute("Pet", pet)
			end
		end
		p:SetAttribute("Pet", pet)
		local finish = p:GetAttribute("Gold") and Config.PetFinishes.Gold
			or p:GetAttribute("Shiny") and Config.PetFinishes.Shiny
		if finish then
			local look = p:FindFirstChild("PetLook")
			for _, part in look and look:GetDescendants() or {} do
				if part:IsA("BasePart") and not Looks.isFacePart(part, pet) then
					part.Color = part.Color:Lerp(finish, 0.6)
					part.Material = Enum.Material.SmoothPlastic
					part.Reflectance = p:GetAttribute("Gold") and 0.22 or 0.12
				end
			end
		end
		for _, tag in p:GetChildren() do
			if tag:IsA("BillboardGui") then
				Config.Presentation.billboard(tag)
			end
		end
		return true
	end
end

-- Puts a pumpkin on top of the player's head stack (no capacity check here).
local function stackPumpkin(player: Player, pumpkin: BasePart): boolean
	local character, root = aliveRoot(player)
	if not character or not root then
		return false
	end
	local stack = carrying[player]
	if not stack then
		stack = {}
		carrying[player] = stack
	end
	stripPumpkin(pumpkin)
	if Hoards.cancelDrop then
		Hoards.cancelDrop(pumpkin)
	end
	pumpkin:SetAttribute("LooseToken", (pumpkin:GetAttribute("LooseToken") or 0) + 1)
	pumpkin:SetAttribute("GuardDropUntil", nil)
	Looks.clear(pumpkin)
	for _, child in pumpkin:GetDescendants() do
		if
			child:IsA("ParticleEmitter")
			or child:IsA("Light")
			or child.Name == "JackPart"
			or child:IsA("BillboardGui")
		then
			child:Destroy()
		end
	end
	pumpkin.Transparency = 0
	pumpkin.Material = Enum.Material.SmoothPlastic
	local tier = table.find(Config.Seeds, Lookup.seedById[pumpkin:GetAttribute("Seed")]) or 1
	local carrySize = 1.9 + math.min(1, (tier - 1) / 9) * 0.9
	pumpkin.Size *= carrySize / math.max(pumpkin.Size.X, pumpkin.Size.Y, pumpkin.Size.Z)
	local offset = #stack == 0 and Vector3.new(0, 0.4, 1.4)
		or Vector3.new(0, 3.4 + (#stack - 1) * 2.9, 0)
	pumpkin:SetAttribute("Placed", nil)
	pumpkin.Anchored = false
	pumpkin.Massless = true
	pumpkin.CanCollide = false
	pumpkin.CanQuery = false
	pumpkin.CFrame = root.CFrame * CFrame.new(offset)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = pumpkin
	weld.Parent = pumpkin
	pumpkin.Parent = character
	table.insert(stack, pumpkin)
	local found = unlocked[player]
	local seedId = pumpkin:GetAttribute("Seed")
	if found and type(seedId) == "string" then
		found[seedId] = true
	end
	refreshCarry(player)
	return true
end

-- Loose pumpkins (ghost drops, or a popped pumpkin that did not fit): anyone can pick them up.
-- rescued = it came from a ghost (counts for "Rescue" orders). groundY skips the raycast.
function Bases.safeLanding(pos: Vector3, checkClearance: boolean?): Vector3?
	-- Authored collision floors include the hub, pens, market and zone lanes.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local floors = table.clone(Helpers.playFloors or { workspace.Terrain })
	local ground = garden:FindFirstChild("Ground")
	if ground then
		table.insert(floors, ground)
	end
	for _, pen in patchFolder:GetChildren() do
		local soil = pen:FindFirstChild("Soil")
		if soil then
			table.insert(floors, soil)
		end
	end
	params.FilterDescendantsInstances = floors
	params.RespectCanCollide = true
	local floor = workspace:Raycast(
		pos + Vector3.yAxis * Config.Teleport.rayHeight,
		-Vector3.yAxis * Config.Teleport.rayDepth,
		params
	)
	if not floor then
		return nil
	end
	local landing = floor.Position + Vector3.yAxis * Config.Teleport.height
	-- Pen/shop travel keeps its authored X/Z destination and only corrects the floor height.
	if not checkClearance then
		return landing
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	for _, player in Services.Players:GetPlayers() do
		if player.Character then
			table.insert(floors, player.Character)
		end
	end
	overlap.FilterDescendantsInstances = floors
	overlap.RespectCanCollide = true
	for _, obstacle in
		workspace:GetPartBoundsInBox(CFrame.new(landing), Vector3.new(4, 5, 4), overlap)
	do
		if obstacle.CanCollide then
			return nil
		end
	end
	return landing
end
local function dropLoose(
	pumpkin: BasePart,
	at: Vector3,
	seconds: number?,
	rescued: boolean?,
	groundY: number?
)
	stripPumpkin(pumpkin)
	local token = (pumpkin:GetAttribute("LooseToken") or 0) + 1
	pumpkin:SetAttribute("LooseToken", token)
	pumpkin.Anchored = true
	pumpkin.CanQuery = true
	local y = groundY
	if not y then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		local floors: { Instance } = { workspace.Terrain, patchFolder, market }
		local ground = garden:FindFirstChild("Ground")
		if ground then
			table.insert(floors, ground)
		end
		params.FilterDescendantsInstances = floors
		local hit = workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), params)
		y = hit and hit.Position.Y or at.Y - 4
	end
	pumpkin.CFrame = CFrame.new(at.X, (y :: number) + pumpkin.Size.Y / 2, at.Z)
	pumpkin.Parent = loose
	local function pickLoose(player)
		if pumpkin.Parent ~= loose then
			return
		end
		local _, root = aliveRoot(player)
		if
			not Helpers.isLoaded(player)
			or not root
			or Vector3.new(
				root.Position.X - pumpkin.Position.X,
				0,
				root.Position.Z - pumpkin.Position.Z
			).Magnitude > 4.5
			or math.abs(root.Position.Y - pumpkin.Position.Y) > pumpkin.Size.Y / 2 + 5
		then
			return
		end
		local theft = Purge.transit[pumpkin]
		if theft and player ~= theft.owner and player ~= theft.thief then
			return
		end
		if #(carrying[player] or {}) >= Helpers.carryCapacity(player) then
			Remotes.hintEvent:FireClient(player, "Your hands are full!")
			return
		end
		-- A dropped stolen pumpkin picked up by its owner is just theirs again.
		if pumpkin:GetAttribute("StolenFrom") == player.UserId then
			Purge.transit[pumpkin] = nil
			pumpkin:SetAttribute("StolenFrom", nil)
		end
		-- stackPumpkin removes the prompt itself; on failure the prompt stays usable.
		if stackPumpkin(player, pumpkin) then
			if pumpkin:GetAttribute("HoardZone") and Hoards.wakeLoose then
				Hoards.wakeLoose(player, pumpkin)
			end
			Remotes.harvestedEvent:FireAllClients(player, pumpkin.Position)
			if rescued then
				track(player, "rescue", 1)
			end
		end
	end
	task.spawn(function()
		while pumpkin.Parent == loose and pumpkin:GetAttribute("LooseToken") == token do
			for _, player in Services.Players:GetPlayers() do
				pickLoose(player)
			end
			task.wait(0.15)
		end
	end)
	task.delay(seconds or 60, function()
		if pumpkin.Parent == loose and pumpkin:GetAttribute("LooseToken") == token then
			pumpkin:Destroy()
		end
	end)
end

do
	local function now(): number
		return workspace:GetServerTimeNow()
	end

	local function hint(player: Player, text: string)
		Remotes.hintEvent:FireClient(player, text)
	end

	-- Blood Moon: while state.LocksOff (an end time) is in the future, no base can be locked.
	function Bases.locksOff(): boolean
		return (state:GetAttribute("LocksOff") or 0) > now()
	end

	function Bases.isLocked(patch: Instance): boolean
		return not Bases.locksOff() and (patch:GetAttribute("LockedUntil") or 0) > now()
	end

	-- Plots of a patch in Index order (1-6 on the lane map's pens).
	local function plotsOf(patch: Instance): { BasePart }
		local list = {}
		for _, plot in patch:GetChildren() do
			if
				plot.Name == "Plot"
				and plot:IsA("BasePart")
				and (plot:GetAttribute("Index") or 1)
					<= (patch:GetAttribute("PenSlots") or Config.Progression.baseSlots)
			then
				table.insert(list, plot)
			end
		end
		table.sort(list, function(a, b)
			return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0)
		end)
		return list
	end

	Bases.plots = plotsOf

	local function plotKey(plot: BasePart, i: number): string
		return tostring(plot:GetAttribute("Index") or i)
	end

	-- Income tags, the shield on the single best plot (it cannot be stolen) and the owner's
	-- "Income" attribute (candy per second with their Haunt / pass multipliers).
	function Bases.rims(patch)
		for _, rim in patch:GetDescendants() do
			if rim.Name == "DiscRim" and rim:IsA("BasePart") then
				local plot = rim.Parent
				local pumpkin = plot:FindFirstChild("Pumpkin")
				local def = pumpkin and Config.Pets[pumpkin:GetAttribute("Pet") or ""]
				local color = nil
				for k, rarity in Config.Rarities do
					if def and def.rarity ~= "Common" and rarity.name == def.rarity then
						color = Config.UI.Tokens.rarity[k]
					end
				end
				rim.Color = plot:GetAttribute("SlotLocked") and Config.Plots.gold
					or color
					or Config.Plots.rim
				rim.Material = color and Enum.Material.Neon or Enum.Material.Wood
			end
		end
	end

	function Bases.slotLook(patch, slots, previousSlots)
		Bases.layout(patch)
		for _, plot in patch:GetChildren() do
			if plot.Name ~= "Plot" or not plot:IsA("BasePart") then
				continue
			end
			local locked = (plot:GetAttribute("Index") or 1) > slots
			local index = plot:GetAttribute("Index") or 1
			plot:SetAttribute("SlotLocked", locked)
			plot.Transparency = 0
			plot.Color = locked and Config.Plots.locked or Config.Plots.wood
			plot.Material = locked and Enum.Material.Concrete or Enum.Material.Wood
			local lock = plot:FindFirstChild("SlotLock")
			if locked and not lock then
				lock = Instance.new("Model")
				lock.Name = "SlotLock"
				lock.Parent = plot
				local cf = CFrame.new(plot.Position + Vector3.new(0, plot.Size.X / 2 + 1, 0))
				local function piece(name, size, offset, color)
					local part = Instance.new("Part")
					part.Name = name
					part.Anchored = true
					part.CanCollide = false
					part.CanTouch = false
					part.CanQuery = false
					part.Size = size
					part.CFrame = cf * CFrame.new(offset)
					part.Color = color
					part.Parent = lock
					return part
				end
				local block =
					piece("Padlock", Config.Plots.lockSize, Vector3.zero, Config.Plots.lock)
				for _, entry in
					{
						{ Vector3.new(0.35, 1.4, 0.35), Vector3.new(-0.8, 1.6, 0) },
						{ Vector3.new(0.35, 1.4, 0.35), Vector3.new(0.8, 1.6, 0) },
						{ Vector3.new(1.95, 0.35, 0.35), Vector3.new(0, 2.3, 0) },
					}
				do
					piece("Shackle", entry[1], entry[2], Color3.fromRGB(200, 204, 214))
				end
				piece(
					"Keyhole",
					Vector3.new(0.35, 0.55, 0.08),
					Vector3.new(0, -0.1, -0.54),
					Color3.fromRGB(43, 43, 43)
				)
				local bb = Instance.new("BillboardGui")
				bb.Name = "Price"
				bb.Size = UDim2.fromOffset(140, 32)
				bb.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
				bb.MaxDistance = 20
				bb.LightInfluence = 0
				bb.Parent = block
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundColor3 = Config.Plots.priceBar
				label.TextColor3 = Color3.new(1, 1, 1)
				label.FontFace = Helpers.fontFace("title")
				label.TextScaled = false
				local zone = (plot:GetAttribute("Index") or 1) <= Config.Progression.woodsSlots
						and "Zone3"
					or "Zone5"
				label.Text = utf8.char(128274)
					.. " "
					.. utf8.char(127852)
					.. " "
					.. Helpers.short(Config.Zones[zone].cost)
				label.Parent = bb
			elseif not locked and lock then
				lock:Destroy()
			end
			if locked and lock then
				lock.Padlock.Price.Enabled = index == slots + 1
			end
			if previousSlots and index > previousSlots and not locked then
				local puff = Instance.new("ParticleEmitter")
				puff.Texture = "rbxasset://textures/particles/smoke_main.dds"
				puff.Rate = 0
				puff.Lifetime = NumberRange.new(0.4, 0.7)
				puff.Speed = NumberRange.new(3, 6)
				puff.SpreadAngle = Vector2.new(180, 180)
				puff.Size = NumberSequence.new(2, 0)
				puff.Parent = plot
				puff:Emit(20)
				task.delay(1, function()
					puff:Destroy()
				end)
			end
		end
		local post = patch:FindFirstChild("SignPost")
		local holder = post
			and (post:IsA("BasePart") and post or post:FindFirstChildWhichIsA("BasePart", true))
		if holder then
			local old = holder:FindFirstChild("PenUpgrade")
			if old then
				old:Destroy()
			end
			local prompt = holder:FindFirstChild("UpgradePrompt")
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.Name = "UpgradePrompt"
				prompt.HoldDuration = 0.6
				prompt.MaxActivationDistance = 12
				prompt.RequiresLineOfSight = false
				prompt.UIOffset = Vector2.new(0, 48)
				prompt.Parent = holder
				prompt.Triggered:Connect(function(player)
					local _, root = aliveRoot(player)
					if not root or (root.Position - holder.Position).Magnitude > 14 then
						return
					end
					if patchOf[player] ~= patch or not Bases.unlockZone then
						return
					end
					local count = patch:GetAttribute("PenSlots") or Config.Progression.baseSlots
					if count >= Config.Progression.castleSlots then
						return
					end
					Bases.unlockZone(
						player,
						count < Config.Progression.woodsSlots and "Zone3" or "Zone5"
					)
				end)
			end
			local zone = slots < Config.Progression.woodsSlots and "Zone3" or "Zone5"
			prompt.ActionText = "Upgrade pen: " .. Helpers.short(Config.Zones[zone].cost)
			prompt.ObjectText = Config.Zones[zone].title .. " - +2 slots"
		end

		Bases.rims(patch)
	end

	function Bases.weakest(patch: Instance): BasePart?
		local weakest, rate = nil, math.huge
		for _, plot in plotsOf(patch) do
			local p = plotState[plot].pumpkin
			if p and incomeOf(p) < rate then
				weakest, rate = plot, incomeOf(p)
			end
		end
		return weakest
	end

	function Bases.refresh(patch: Instance?)
		if not patch then
			return
		end
		local owner = Services.Players:GetPlayerByUserId(patch:GetAttribute("Owner") or 0)
		if
			owner
			and Bases.drainCarry
			and Progress.pending[owner]
			and not Progress.draining[owner]
		then
			task.defer(Bases.drainCarry, owner)
		end
		Bases.rims(patch)
		local weakest = Bases.weakest(patch)
		local weakestPet = weakest and plotState[weakest].pumpkin
		local weakestSeed = weakestPet and Lookup.seedById[weakestPet:GetAttribute("Seed") or ""]
		local weakestDef = weakestSeed and Config.Pets[weakestSeed.pet]
		patch:SetAttribute("SwapWeakestName", weakestDef and weakestDef.display or nil)
		if owner then
			local slots = patch:GetAttribute("PenSlots") or Config.Progression.baseSlots
			local zone = slots < Config.Progression.woodsSlots and "Zone3" or "Zone5"
			local previous = Config.ZoneOrder[(table.find(Config.ZoneOrder, zone) or 1) - 1]
			owner:SetAttribute(
				"PenUpgradeCost",
				math.floor(
					Config.Zones[zone].cost
						* (
							previous
								and Progress.complete(owner, previous)
								and (1 - Config.Progression.gateDiscount)
							or 1
						)
				)
			)
		end
		local mult = owner and Helpers.sellMult(owner) * Progress.candyMult(owner) or 1
		local plots = plotsOf(patch)
		local best, bestIncome, total, filled, hatched = nil, -1, 0, 0, 0
		for _, plot in plots do
			local p = plotState[plot] and plotState[plot].pumpkin
			if p then
				filled += 1
				if p:GetAttribute("Jack") then
					hatched += 1
				end
				local income = p:GetAttribute("Stashed") and 0 or incomeOf(p)
				total += income * mult
				if incomeOf(p) > bestIncome then
					best, bestIncome = plot, incomeOf(p)
				end
			end
		end
		for _, plot in plots do
			local p = plotState[plot] and plotState[plot].pumpkin
			local protected = plot == best
			if plot:GetAttribute("Filled") ~= (p ~= nil) then
				plot:SetAttribute("Filled", p ~= nil)
			end
			if plot:GetAttribute("Protected") ~= (protected or nil) then
				plot:SetAttribute("Protected", protected or nil)
			end
			-- "Rate" (candy per second with the owner's multipliers) drives the owner's green
			-- "+X" income pops on the client.
			if p then
				local rate = p:GetAttribute("Stashed") and 0
					or math.floor(incomeOf(p) * mult * 10 + 0.5) / 10
				if p:GetAttribute("Rate") ~= rate then
					p:SetAttribute("Rate", rate)
				end
			end
			local tag = p and p:FindFirstChild("IncomeTag")
			local label = tag and tag:FindFirstChild("Label") :: TextLabel?
			if p and label then
				local seed = Lookup.seedById[p:GetAttribute("Seed") or ""]
				local pet = seed and Config.Pets[seed.pet]
				local text = (pet and pet.display or "Pumpkin")
					.. "\n$"
					.. Helpers.rateText(incomeOf(p) * mult)
					.. "/s"
				for _, rarity in Config.Rarities do
					if pet and rarity.name == pet.rarity then
						label.TextColor3 = rarity.color
					end
				end
				tag.Enabled = p:GetAttribute("Jack") == true
				if p:GetAttribute("Stashed") then
					text = "STASHED | Return home"
				end
				if label.Text ~= text then
					label.Text = text
				end
			end
		end
		if owner then
			owner:SetAttribute("PenSlots", #plots)
			owner:SetAttribute("PenFilled", filled)
			owner:SetAttribute("PenHatched", hatched)
			if #plots > 0 and filled == #plots then
				owner:SetAttribute("Unlock_Sell", true)
			end
			local rounded = math.floor(total * 10 + 0.5) / 10
			if owner:GetAttribute("Income") ~= rounded then
				owner:SetAttribute("Income", rounded)
			end
		end
	end

	local function incomeTag(pumpkin: BasePart)
		local bb = Instance.new("BillboardGui")
		-- Kept small: the owner sees a green "+X" pop over each pumpkin every second instead.
		bb.Name = "IncomeTag"
		bb.Size = UDim2.fromOffset(150, 38)
		bb.StudsOffsetWorldSpace = Vector3.new(0, pumpkin.Size.Y / 2 + 1.2, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 25
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Helpers.fontFace("title")
		label.TextScaled = false
		label.TextColor3 = Color3.fromRGB(150, 255, 110)
		label.Text = ""
		label.Parent = bb
		local outline = Instance.new("UIStroke")
		outline.Thickness = 2
		outline.Color = Color3.fromRGB(30, 12, 40)
		outline.Parent = label
		bb.Parent = pumpkin
	end

	local function hatchText(seconds: number): string
		return string.format("Mystery Pumpkin\n%d:%02d", math.floor(seconds / 60), seconds % 60)
	end

	-- "Hatching 0:20" over a placed pumpkin until it hatches (Bases.tick updates the text).
	local function carveTag(pumpkin: BasePart, seconds: number)
		local dome = Instance.new("Model")
		dome.Name = "HatchDome"
		dome.Parent = pumpkin
		local origin = pumpkin.Position - Vector3.yAxis * pumpkin.Size.Y / 2
		local radius = math.max(Config.Plots.domeWidth, pumpkin.Size.X, pumpkin.Size.Z) / 2
		for band = 1, Config.Plots.domeBands do
			local lo = (band - 1) / Config.Plots.domeBands * math.pi / 2
			local hi = band / Config.Plots.domeBands * math.pi / 2
			local latitude = (lo + hi) / 2
			for segment = 1, Config.Plots.domeSegments do
				local angle = segment / Config.Plots.domeSegments * math.pi * 2
				local normal = Vector3.new(
					math.cos(angle) * math.cos(latitude),
					math.sin(latitude),
					math.sin(angle) * math.cos(latitude)
				)
				local glass = Instance.new("Part")
				glass.Name = "Glass"
				glass.Anchored = true
				glass.Size = Vector3.new(
					2 * radius * math.cos(lo) * math.sin(math.pi / Config.Plots.domeSegments),
					2 * radius * math.sin((hi - lo) / 2),
					0.04
				)
				glass.CFrame =
					CFrame.lookAt(origin + normal * radius, origin + normal * (radius + 1))
				glass.Material = Enum.Material.Glass
				glass.Color = Config.Plots.domeColor
				glass.Transparency = Config.Plots.domeTransparency
				glass.CanCollide = false
				glass.CanQuery = false
				glass.CanTouch = false
				glass.Massless = true
				glass.Parent = dome
			end
		end
		local sparkle = Instance.new("Sparkles")
		sparkle.Name = "HatchSparkles"
		sparkle.SparkleColor = Config.Plots.domeColor
		sparkle.Parent = pumpkin
		local bb = Instance.new("BillboardGui")
		bb.Name = "CarveTag"
		bb.Size = UDim2.fromOffset(180, 60)
		bb.StudsOffsetWorldSpace = Vector3.new(0, pumpkin.Size.Y / 2 + 2.6, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 60
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Helpers.fontFace("title")
		label.TextScaled = false
		label.TextColor3 = Color3.fromRGB(255, 200, 120)
		label.Text = hatchText(seconds)
		label.Parent = bb
		local outline = Instance.new("UIStroke")
		outline.Thickness = 2
		outline.Color = Color3.fromRGB(30, 12, 40)
		outline.Parent = label
		bb.Parent = pumpkin
	end

	-- Hatched: the pumpkin turns into its type's pet (ServerStorage.PetModels, facing the lane's
	-- centre line), with validated voxel assets. "Jack" = hatched (kept name, saves and
	-- moves use it); JackHome = where clients idle / hop it on its plot.
	local function becomeAlive(pumpkin: BasePart)
		local plot = pumpkin.Parent
		if plot and plot:GetAttribute("BaseSize") then
			plot.Size = plot:GetAttribute("BaseSize")
		end
		local seed = Lookup.seedById[pumpkin:GetAttribute("Seed") or ""]
		if Looks.hatch(pumpkin, seed) then
			local pos = pumpkin.Position
			if math.abs(Lane.x - pos.X) > 1 then
				pumpkin.CFrame = CFrame.lookAt(pos, Vector3.new(Lane.x, pos.Y, pos.Z))
			end
		end
		pumpkin:SetAttribute("PickupReadyAt", now() + Config.GuardLaunch.pickupGrace)
		pumpkin:SetAttribute("JackHome", pumpkin.CFrame)
		pumpkin:SetAttribute("Jack", true)
		pumpkin:SetAttribute("RoamFrom", pumpkin.Position)
		pumpkin:SetAttribute("RoamTo", pumpkin.Position)
		pumpkin:SetAttribute("RoamStart", now())
		pumpkin:SetAttribute("RoamEnd", now())
		local anchor = Instance.new("Attachment")
		anchor.Name = "PetPromptAnchor"
		anchor.Parent = pumpkin
		for _, name in { "PetPrompt" } do
			local prompt = pumpkin.Parent and pumpkin.Parent:FindFirstChild(name, true)
			if prompt then
				prompt.Parent = anchor
			end
		end
	end

	-- The pumpkin hatches into its pet. Clients play the hatch: everyone near sees the
	-- shell burst; the owner gets the flash, camera punch and the reveal card (built on the client
	-- from the pumpkin's attributes). isNew = the first time its owner hatches this type.
	local function carve(pumpkin: BasePart, forceReveal: boolean?)
		pumpkin:SetAttribute("ForceReveal", nil)
		pumpkin:SetAttribute("CarveAt", nil)
		for _, attr in { "GrowthSize", "GrowthStartAt", "GrowthDuration", "GrowthStep" } do
			pumpkin:SetAttribute(attr, nil)
		end
		for _, name in { "HatchDome", "HatchSparkles", "MysteryTag", "HoardSparkle" } do
			local item = pumpkin:FindFirstChild(name)
			if item then
				item:Destroy()
			end
		end
		local tag = pumpkin:FindFirstChild("CarveTag")
		if tag then
			tag:Destroy()
		end
		pumpkin:SetAttribute("HatchSize", pumpkin.Size)
		local hatchOwner = Services.Players:GetPlayerByUserId(pumpkin:GetAttribute("Owner") or 0)
		Looks.rollGold(hatchOwner, pumpkin)
		becomeAlive(pumpkin)
		local ownerId = pumpkin:GetAttribute("Owner") or 0
		local owner = Services.Players:GetPlayerByUserId(ownerId)
		local seedId = pumpkin:GetAttribute("Seed")
		local isNew = false
		if owner and type(seedId) == "string" then
			local carved = Bases.carvedOf[owner] or {}
			Bases.carvedOf[owner] = carved
			if not carved[seedId] then
				carved[seedId] = true
				isNew = true
			end
		end
		Bases.refresh(pumpkin.Parent and pumpkin.Parent.Parent)
		Remotes.carvedEvent:FireAllClients(
			pumpkin,
			ownerId,
			pumpkin:GetAttribute("Pet"),
			isNew,
			forceReveal
				or (
					owner ~= nil
					and (owner:GetAttribute("PlayTime") or 0) < Config.Payoff.earlySeconds
				)
		)
		if owner then
			-- A data-only Reveal remote also works when the owner is too far away to receive the pet instance.
			if
				forceReveal
				or isNew
				or (owner:GetAttribute("PlayTime") or 0) < Config.Payoff.earlySeconds
			then
				Reveal.send(owner, pumpkin, isNew, "jack")
			end
			Progress.own(owner, seedId)
			track(owner, "hatch", 1)
			track(owner, "penFilled", owner:GetAttribute("PenFilled") or 0, true)
		end
	end

	-- Puts a new pumpkin on an empty plot, sized to fit it. Returns it (nil when not possible).
	-- extra.hoard = a Hoard pumpkin (x HoardMult); extra.jack = already hatched (no hatching).
	function Bases.put(
		plot: BasePart,
		seedId: string,
		sizeMult: number,
		mutation: string?,
		ownerId: number,
		extra: { hoard: boolean?, jack: boolean?, weight: number?, hatchSize: Vector3? }?
	): BasePart?
		local s = plotState[plot]
		if not s or s.pumpkin or not Lookup.seedById[seedId] then
			return nil
		end
		local pumpkin = makePumpkin(seedId, sizeMult)
		local petSize = Config.PetSizes[Config.Pets[Lookup.seedById[seedId].pet].rarity]
		local kg = extra and extra.weight
		if type(kg) ~= "number" or kg ~= kg or kg <= 0 or kg == math.huge then
			kg = math.floor(petSize.median * math.exp((math.random() - 0.5) * 3.2) * 10 + 0.5) / 10
		end
		pumpkin:SetAttribute("WeightKg", kg)
		do
			local rarity = Config.Pets[Lookup.seedById[seedId].pet].rarity
			-- Rarity sets the median silhouette; the quarter-power weight term adds size.
			local height = math.clamp(
				Config.MysterySizes.heights[rarity]
					+ Config.MysterySizes.weightScale
						* Config.MysterySizes.characterHeight
						* (kg ^ 0.25 - petSize.median ^ 0.25),
				Config.MysterySizes.penMin,
				Config.MysterySizes.penMax
			)
			pumpkin.Size *= math.min(
				height / pumpkin.Size.Y,
				5.5 / math.max(pumpkin.Size.X, pumpkin.Size.Z)
			)
		end
		-- Reconstruct the full pen egg even for old saves and already-hatched carried pets.
		pumpkin:SetAttribute("HatchSize", pumpkin.Size)
		if extra and typeof(extra.hatchSize) == "Vector3" then
			pumpkin:SetAttribute("HatchSize", extra.hatchSize)
		end
		pumpkin.CFrame = CFrame.new(plot.Position + Vector3.new(0, 0.15 + pumpkin.Size.Y / 2, 0))
			* CFrame.Angles(0, math.random() * math.pi * 2, 0)
		pumpkin:SetAttribute("Owner", ownerId)
		pumpkin:SetAttribute("PlacedAt", extra and extra.placedAt or now())
		for key, attr in
			{
				gold = "Gold",
				shiny = "Shiny",
				boss = "Boss",
				bought = "Bought",
				placedAt = "PlacedAt",
				goldRolled = "GoldRolled",
			}
		do
			if extra and extra[key] ~= nil then
				pumpkin:SetAttribute(attr, extra[key])
			end
		end
		if extra and extra.jack and extra.goldRolled == nil then
			pumpkin:SetAttribute("GoldRolled", true)
		end
		if
			extra
			and type(extra.weight) == "number"
			and extra.weight > 0
			and extra.weight < math.huge
		then
			pumpkin:SetAttribute("WeightKg", extra.weight)
		end
		pumpkin:SetAttribute("Placed", true)
		if mutation and Lookup.mutationById[mutation] then
			pumpkin:SetAttribute("Mutation", mutation)
			applyMutationLook(pumpkin, mutation)
		end
		if extra and extra.hoard then
			pumpkin:SetAttribute("Hoard", true)
			Hoards.look(pumpkin, extra.jack == true)
		end
		pumpkin.Parent = plot
		plot.Size = plot:GetAttribute("BaseSize") or plot.Size
		incomeTag(pumpkin)
		if extra and extra.jack then
			becomeAlive(pumpkin)
		else
			-- New players (first CarveNewUntil s of playtime): every type hatches fast.
			local owner = Services.Players:GetPlayerByUserId(ownerId)
			local newbie = owner ~= nil
				and (owner:GetAttribute("PlayTime") or 0) < Config.CarveNewUntil
			local seconds = newbie and Config.CarveNewSeconds
				or Lookup.seedById[seedId].order <= Config.CarveFastOrder and Config.CarveFastSeconds
				or Config.CarveSeconds
			Hoards.look(pumpkin)
			local question = pumpkin:FindFirstChild("MysteryTag")
			if question then
				question:Destroy()
			end
			local final = pumpkin.Size
			pumpkin:SetAttribute("GrowthSize", final)
			pumpkin:SetAttribute("GrowthStartAt", now())
			pumpkin:SetAttribute("GrowthDuration", seconds)
			pumpkin:SetAttribute("GrowthStep", 0)
			pumpkin.Size = final * Config.Plots.growthStart
			pumpkin.CFrame -= Vector3.yAxis * (final.Y - pumpkin.Size.Y) / 2
			Looks.refit(pumpkin)
			pumpkin:SetAttribute("CarveAt", now() + seconds)
			carveTag(pumpkin, seconds)
		end
		pumpkin.Parent = plot
		s.pumpkin = pumpkin
		return pumpkin
	end

	-- What Bases.put needs to rebuild a pumpkin that is moving (hoard bonus, already a Jack).
	function Bases.extraOf(
		p: Instance
	): { hoard: boolean?, jack: boolean?, weight: number?, hatchSize: Vector3? }
		return {
			hoard = p:GetAttribute("Hoard") == true,
			jack = p:GetAttribute("Jack") == true,
			weight = p:GetAttribute("WeightKg"),
			hatchSize = p:GetAttribute("HatchSize"),
			gold = p:GetAttribute("Gold"),
			shiny = p:GetAttribute("Shiny"),
			boss = p:GetAttribute("Boss"),
			bought = p:GetAttribute("Bought"),
			placedAt = p:GetAttribute("PlacedAt"),
			goldRolled = p:GetAttribute("GoldRolled"),
		}
	end

	-- Takes the pumpkin off a plot without destroying it (pick up, steal, ghost grab).
	function Bases.take(plot: BasePart): BasePart?
		local s = plotState[plot]
		local p = s and s.pumpkin
		if not s or not p or p:GetAttribute("Stashed") then
			return nil
		end
		s.pumpkin = nil
		plot.Size = plot:GetAttribute("BaseSize") or plot.Size
		for _, name in { "PetPrompt" } do
			local prompt = p:FindFirstChild(name, true)
			if prompt then
				prompt.Parent = plot
			end
		end
		p:SetAttribute("Placed", nil)
		-- Off the plot: no more idling (clients) or hatching (a re-placed one hatches again).
		p:SetAttribute("JackHome", nil)
		p:SetAttribute("CarveAt", nil)
		for _, attr in { "GrowthSize", "GrowthStartAt", "GrowthDuration", "GrowthStep" } do
			p:SetAttribute(attr, nil)
		end
		for _, name in { "IncomeTag", "CarveTag", "HatchDome", "HatchSparkles" } do
			local tag = p:FindFirstChild(name)
			if tag then
				tag:Destroy()
			end
		end
		Bases.refresh(plot.Parent)
		return p
	end

	-- Client motion follows server-authored waypoints; reach never uses client CFrames.
	function Bases.petReach(player, plot)
		local _, root = aliveRoot(player)
		local p = plotState[plot] and plotState[plot].pumpkin
		if not root or not p then
			return false
		end
		local at = Config.roamPoint(p, now())
		local base = at - Vector3.yAxis * (p.Size.Y / 2)
		local delta = root.Position - base
		return Vector3.new(delta.X, 0, delta.Z).Magnitude <= 11 and math.abs(delta.Y) <= 6
	end

	-- Every plot of the patch holds a pumpkin (opens the Witch early).
	function Bases.full(patch: Instance?): boolean
		if not patch then
			return false
		end
		local plots = plotsOf(patch)
		for _, plot in plots do
			if not (plotState[plot] and plotState[plot].pumpkin) then
				return false
			end
		end
		return #plots > 0
	end

	local function firstEmptyPlot(patch: Instance?): BasePart?
		if not patch then
			return nil
		end
		for _, plot in plotsOf(patch) do
			if plotState[plot] and not plotState[plot].pumpkin then
				return plot
			end
		end
		return nil
	end

	Bases.empty = firstEmptyPlot

	-- Re-welds a stack from the bottom after a pumpkin was pulled out of the middle.
	local function restack(player: Player)
		local _, root = aliveRoot(player)
		local stack = carrying[player] or {}
		if not root then
			return
		end
		for i, p in stack do
			for _, child in p:GetChildren() do
				if child:IsA("WeldConstraint") then
					child:Destroy()
				end
			end
			p.Size *= (i == 1 and Config.Payoff.chestSize or Config.Payoff.stackSize) / math.max(
				p.Size.X,
				p.Size.Y,
				p.Size.Z
			)
			p.CFrame = root.CFrame
				* CFrame.new(
					i == 1 and Vector3.new(0, 0.6, -1.8)
						or Vector3.new(0, 3.2 + (i - 2) * Config.Payoff.stackSize, 0)
				)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
	Bases.restack = restack

	-- A stolen pumpkin goes home: the owner's first empty plot, else their stack, else the ground.
	local function giveBack(owner: Player, p: BasePart, at: Vector3)
		Purge.transit[p] = nil
		p:SetAttribute("StolenFrom", nil)
		local plot = firstEmptyPlot(patchOf[owner])
		if plot then
			local seedId = p:GetAttribute("Seed")
			Bases.put(
				plot,
				seedId,
				p:GetAttribute("SizeMult") or 1,
				p:GetAttribute("Mutation"),
				owner.UserId,
				Bases.extraOf(p)
			)
			p:Destroy()
			Bases.refresh(plot.Parent)
			Remotes.placedEvent:FireAllClients(owner, plot.Position, 0)
		elseif
			#(carrying[owner] or {}) >= Helpers.carryCapacity(owner) or not stackPumpkin(owner, p)
		then
			dropLoose(p, at, Config.LooseSeconds, true)
		end
	end

	Bases.giveBack = giveBack

	-- Base pumpkins of a player for the save: { ["plot index"] = { s = type, z = size, m = brew } }.
	-- After the patch is released (leaving), the copy taken just before is used.
	function Bases.collect(player: Player): { [string]: any }?
		local patch = patchOf[player]
		if not patch then
			return Bases.left[player]
		end
		local out = {}
		for i, plot in plotsOf(patch) do
			local p = plotState[plot] and plotState[plot].pumpkin
			if p then
				local egg = p:GetAttribute("HatchSize") or p:GetAttribute("GrowthSize")
				out[plotKey(plot, i)] = {
					s = p:GetAttribute("Seed"),
					z = p:GetAttribute("SizeMult") or 1,
					m = p:GetAttribute("Mutation"),
					h = p:GetAttribute("Hoard") == true or nil,
					w = p:GetAttribute("WeightKg"),
					g = p:GetAttribute("Gold"),
					y = p:GetAttribute("Shiny"),
					b = p:GetAttribute("Boss"),
					u = p:GetAttribute("Bought"),
					a = p:GetAttribute("PlacedAt"),
					r = p:GetAttribute("GoldRolled"),
					e = typeof(egg) == "Vector3" and { egg.X, egg.Y, egg.Z } or nil,
				}
			end
		end
		return out
	end

	function Bases.restore(player: Player, saved: { [string]: any })
		local patch = patchOf[player]
		if not patch then
			return
		end
		-- Old saves had 9 plots per base, the lane map's pens have 6: pumpkins saved on plots that
		-- no longer exist are paid out at their sell value instead.
		local keys: { [string]: boolean } = {}
		for i, plot in plotsOf(patch) do
			keys[plotKey(plot, i)] = true
		end
		local refund = 0
		for key, entry in saved do
			local seed = type(entry) == "table" and Lookup.seedById[entry.s]
			if not keys[tostring(key)] and seed then
				local mutation = Lookup.mutationById[type(entry.m) == "string" and entry.m or ""]
				local income = seed.income
					* math.clamp(tonumber(entry.z) or 1, 0.1, 5)
					* (mutation and mutation.mult or 1)
					* (entry.h == true and Config.HoardMult or 1)
				refund += math.max(1, math.floor(income * Config.SellPerIncome + 0.5))
			end
		end
		if refund > 0 then
			refund = math.floor(refund * Helpers.sellMult(player) + 0.5)
			local candy = Helpers.candyValue(player)
			if candy then
				candy.Value += refund
			end
			hint(
				player,
				string.format("Your base got smaller, you got %s candy", Helpers.short(refund))
			)
		end
		for i, plot in plotsOf(patch) do
			local entry = saved[plotKey(plot, i)]
			if
				type(entry) == "table"
				and type(entry.s) == "string"
				and Lookup.seedById[entry.s]
				and plotState[plot]
				and not plotState[plot].pumpkin
			then
				local size = math.clamp(tonumber(entry.z) or 1, 0.1, 5)
				local mutation = if type(entry.m) == "string" then entry.m else nil
				-- Saved pumpkins were placed before: they come back hatched.
				Bases.put(plot, entry.s, size, mutation, player.UserId, {
					hoard = entry.h == true,
					jack = true,
					weight = tonumber(entry.w),
					hatchSize = Helpers.savedHatchSize(entry.e),
					gold = entry.g,
					shiny = entry.y,
					boss = entry.b,
					bought = entry.u == true or entry.b == true,
					placedAt = entry.a,
					goldRolled = entry.r,
				})
			end
		end
		for _, plot in plotsOf(patch) do
			local p = plotState[plot].pumpkin
			if p and p:GetAttribute("Jack") then
				Progress.own(player, p:GetAttribute("Seed"))
			end
		end
		Bases.refresh(patch)
	end

	-- Place the top carried pumpkin on one of your empty plots (it keeps type, size and brew).
	local function place(player: Player, plot: BasePart, delivery: boolean?)
		local _, root = aliveRoot(player)
		if not root or (not delivery and (root.Position - plot.Position).Magnitude > 11) then
			return
		end
		local patch = plot.Parent
		if not delivery and patchOf[player] == patch and Bases.full(patch) then
			Bases.fullChoice(player, true)
			return
		end
		if
			patchOf[player] ~= patch
			or (plot:GetAttribute("Index") or 1) > (patch:GetAttribute("PenSlots") or Config.Progression.baseSlots)
			or not plotState[plot]
			or plotState[plot].pumpkin
		then
			return
		end
		if not Helpers.isLoaded(player) then
			hint(player, "Loading your farm...")
			return
		end
		local stack = carrying[player] or {}
		local top = stack[#stack]
		if not top then
			hint(player, "Steal a glowing nest pumpkin, then place it here.")
			return
		end
		local seedId = top:GetAttribute("Seed")
		local finish = top:GetAttribute("Mutation") or "Plain"
		if type(seedId) ~= "string" or not Lookup.seedById[seedId] then
			return
		end
		if not Purge.deliveryReady(player, top) then
			return
		end
		table.remove(stack)
		local stolen = top:GetAttribute("StolenFrom")
		-- Fresh from a Hoard nest: delivery confetti; reveal waits for hatch.
		local fromHoard = top:GetAttribute("HoardZone") ~= nil
		local placed = Bases.put(
			plot,
			seedId,
			top:GetAttribute("SizeMult") or 1,
			top:GetAttribute("Mutation"),
			player.UserId,
			Bases.extraOf(top)
		)
		top:Destroy()
		refreshCarry(player)
		Bases.refresh(patch)
		if placed then
			-- Placing a new kind fills the Index too (selling unlocks later).
			local found = indexOf[player] or {}
			indexOf[player] = found
			local key = seedId .. ":" .. finish
			if not found[key] then
				found[key] = true
				publishIndex(player)
			end
			Remotes.placedEvent:FireAllClients(
				player,
				plot.Position,
				incomeOf(placed) * Helpers.sellMult(player)
			)
			if fromHoard then
				Remotes.hoardEvent:FireClient(player, "deliver", seedId)
				-- The hatch owns the pet reveal; delivery only celebrates the steal.
			end
		end
		track(player, "place", 1)
		track(player, "penFilled", player:GetAttribute("PenFilled") or 0, true)
		track(player, "placeType:" .. seedId, 1)
		if stolen then
			hint(player, "It's yours now! Stolen pumpkins on your base earn for you.")
		end
	end

	Bases.place = place
	task.spawn(function()
		while true do
			for player, patch in patchOf do
				local _, root = aliveRoot(player)
				local soil = patch:FindFirstChild("Soil")
				if root and soil and soil:IsA("BasePart") and #(carrying[player] or {}) > 0 then
					local at = soil.CFrame:PointToObjectSpace(root.Position)
					if
						math.abs(at.X) <= soil.Size.X / 2
						and math.abs(at.Z) <= soil.Size.Z / 2
						and math.abs(at.Y) < 9
					then
						for _, plot in plotsOf(patch) do
							if
								plotState[plot]
								and not plotState[plot].pumpkin
								and #(carrying[player] or {}) > 0
							then
								place(player, plot, true)
							end
						end
					end
				end
			end
			task.wait(0.2)
		end
	end)

	-- Full-pen choices use the existing take/place/value flow.
	function Bases.fullChoice(player: Player, swap: boolean)
		local patch = patchOf[player]
		local stack = carrying[player] or {}
		local top = stack[#stack]
		local _, root = aliveRoot(player)
		local soil = patch and patch:FindFirstChild("Soil")
		if
			not Helpers.isLoaded(player)
			or not top
			or not soil
			or not root
			or not Bases.full(patch)
		then
			return
		end
		local localPos = soil.CFrame:PointToObjectSpace(root.Position)
		if
			math.abs(localPos.X) > soil.Size.X / 2 + 4
			or math.abs(localPos.Z) > soil.Size.Z / 2 + 4
		then
			return
		end
		if top:GetAttribute("Hoard") ~= true and top:GetAttribute("Jack") ~= true then
			return
		end
		if not Purge.deliveryReady(player, top) then
			return
		end
		if swap then
			local weakest = Bases.weakest(patch)
			if not weakest then
				return
			end
			local pet = plotState[weakest].pumpkin
			if
				not pet
				or pet:GetAttribute("Stashed")
				or pet:GetAttribute("CarveAt")
				or now() < (pet:GetAttribute("PickupReadyAt") or 0)
				or incomeOf(top) <= incomeOf(pet)
			then
				hint(player, "Pen full: sell or upgrade")
				return
			end
			local sold = Bases.take(weakest)
			if not sold then
				return
			end
			local bonus = rowDone(player, sold:GetAttribute("Seed")) and (1 + Config.IndexRowBonus)
				or 1
			local value = math.floor(
				pumpkinValue(sold, Config.WitchSellSeconds) * bonus * Helpers.sellMult(player) + 0.5
			)
			sold:Destroy()
			value = addCandy(player, value)
			track(player, "sell", 1)
			place(player, weakest, true)
			local placed = plotState[weakest].pumpkin
			if placed then
				placed:SetAttribute("PickupReadyAt", now() + Config.GuardLaunch.pickupGrace)
				if not placed:GetAttribute("Jack") then
					placed:SetAttribute("ForceReveal", true)
				else
					Remotes.carvedEvent:FireAllClients(
						placed,
						player.UserId,
						placed:GetAttribute("Pet"),
						false,
						true
					)
				end
			end
			hint(player, "Swapped weakest pet! +" .. Helpers.short(value) .. " 🍬")
		end
	end
	function Bases.fillPens(player: Player)
		local patch = patchOf[player]
		if not patch then
			return 0
		end
		local n = 0
		for _, plot in plotsOf(patch) do
			if not plotState[plot].pumpkin then
				Bases.put(
					plot,
					Config.Hoards.Zone1.type,
					Config.HoardSize,
					nil,
					player.UserId,
					{ hoard = true, jack = true }
				)
				n += 1
			end
		end
		Bases.refresh(patch)
		Unlock.refresh(player)
		return n
	end
	local function pickUp(player: Player, plot: BasePart)
		local occupant = plotState[plot] and plotState[plot].pumpkin
		if
			not occupant
			or occupant:GetAttribute("CarveAt")
			or now() < (occupant:GetAttribute("PickupReadyAt") or 0)
		then
			return
		end
		if not Bases.petReach(player, plot) then
			return
		end
		if patchOf[player] ~= plot.Parent or not plotState[plot] or not plotState[plot].pumpkin then
			return
		end
		if not aliveRoot(player) then
			return
		end
		-- Picking up only feeds selling / brewing: locked until the Witch opens.
		if not Unlock.has(player, "Sell") then
			return
		end
		if #(carrying[player] or {}) >= Helpers.carryCapacity(player) then
			hint(player, "Your hands are full! Place, brew or sell what you carry first.")
			return
		end
		local p = Bases.take(plot)
		if p and stackPumpkin(player, p) then
			Remotes.harvestedEvent:FireAllClients(player, plot.Position)
		elseif p then
			p:Destroy()
		end
	end

	local function steal(thief: Player, plot: BasePart)
		local hold = Purge.holds[thief]
		Purge.holds[thief] = nil
		thief:SetAttribute("PurgeStealing", nil)
		local occupant = plotState[plot] and plotState[plot].pumpkin
		if
			not occupant
			or occupant:GetAttribute("CarveAt")
			or now() < (occupant:GetAttribute("PickupReadyAt") or 0)
		then
			return
		end
		if
			not Purge.active()
			or Purge.immune(thief)
			or not hold
			or hold.plot ~= plot
			or hold.id ~= Purge.id
			or now() - hold.at < Config.Purge.hold
		then
			return
		end
		if not Bases.petReach(thief, plot) then
			return
		end
		local patch = plot.Parent :: Instance
		local ownerId = patch:GetAttribute("Owner") or 0
		local owner = Services.Players:GetPlayerByUserId(ownerId)
		local s = plotState[plot]
		if
			not s
			or not s.pumpkin
			or s.pumpkin:GetAttribute("Stashed")
			or not owner
			or ownerId == thief.UserId
		then
			return
		end
		if not Helpers.isLoaded(thief) or not aliveRoot(thief) then
			return
		end
		local t = now()
		if not Unlock.has(thief, "PlayerSteal") then
			-- The prompt is hidden on the client until then; this is the server-side check.
			return
		elseif plot:GetAttribute("Protected") then
			hint(thief, "🛡 Their best pumpkin is protected. Try another one!")
		elseif Bases.isLocked(patch) then
			hint(thief, "🔒 This base is locked!")
		elseif patchOf[thief] and Bases.isLocked(patchOf[thief]) then
			hint(thief, "You can't steal while your own base is locked.")
		elseif Purge.immune(owner) or not Unlock.has(owner, "PlayerSteal") then
			hint(thief, owner.DisplayName .. " is shielded while new or AFK.")
		elseif Purge.victims[ownerId] then
			hint(thief, owner.DisplayName .. " was already robbed this Purge.")
		elseif #(carrying[thief] or {}) >= Helpers.carryCapacity(thief) then
			hint(thief, "Your hands are full!")
		else
			local p = Bases.take(plot) :: BasePart
			p:SetAttribute("StolenFrom", ownerId)
			if not stackPumpkin(thief, p) then
				giveBack(owner, p, plot.Position)
				return
			end
			Purge.victims[ownerId] = true
			patch:SetAttribute("PurgeRobbed", Purge.id)
			patch:SetAttribute("RobbedUntil", state:GetAttribute("PurgeEnds"))
			Purge.transit[p] = {
				owner = owner,
				thief = thief,
				untilAt = t + Config.Purge.returnSeconds,
				id = Purge.id,
				losses = Purge.losses,
			}
			local seed = Lookup.seedById[p:GetAttribute("Seed") or ""]
			local name = seed and seed.name or "a"
			-- The owner's client shows the alarm (toast, red flash, highlighted thief); the thief's
			-- shows "You stole a PUMPKIN!" plus RUN!!, the red vignette and the Drop button.
			Remotes.stealAlarmEvent:FireClient(owner, "robbed", thief.DisplayName, name, 0)
			Remotes.stealAlarmEvent:FireClient(thief, "stole", name)
			Remotes.harvestedEvent:FireAllClients(thief, plot.Position)
			track(thief, "steal", 1)
		end
	end

	-- The owner's swing reached a thief carrying their pumpkins: those go back home.
	function Bases.defend(owner: Player, root: BasePart): boolean
		local got = false
		for _, thief in Services.Players:GetPlayers() do
			local stack = carrying[thief]
			local _, thiefRoot = aliveRoot(thief)
			if
				thief ~= owner
				and stack
				and thiefRoot
				and (thiefRoot.Position - root.Position).Magnitude <= Config.BonkRange + 2
			then
				local back = 0
				local rewardId = nil
				for i = #stack, 1, -1 do
					local p = stack[i]
					if
						Purge.transit[p]
						and (now() >= Purge.transit[p].untilAt or Purge.inside(thief))
					then
						Purge.settle(p)
					end
					if p:GetAttribute("StolenFrom") == owner.UserId then
						local theft = Purge.transit[p]
						if theft then
							rewardId = theft.id
						end
						table.remove(stack, i)
						giveBack(owner, p, thiefRoot.Position)
						back += 1
					end
				end
				-- Dropping the pet cannot remove the owner's bonk recovery window.
				for p, entry in Purge.transit do
					if entry.owner == owner and entry.thief == thief and p.Parent == loose then
						if now() >= entry.untilAt then
							Purge.settle(p)
						else
							rewardId = entry.id
							giveBack(owner, p, thiefRoot.Position)
							back += 1
						end
					end
				end
				if back > 0 then
					got = true
					restack(thief)
					refreshCarry(thief)
					hint(
						thief,
						"💥 " .. owner.DisplayName .. " bonked you and took their pumpkin back!"
					)
					hint(owner, "💥 You got your pumpkin back!")
					Remotes.ghostPopEvent:FireAllClients(thiefRoot.Position, nil, 0)
					track(owner, "stopThief", 1)
					if rewardId then
						Purge.reward(owner, rewardId)
					end
				end
			end
		end
		return got
	end

	-- A thief died: their stolen pumpkins go home and Hoard pumpkins fly back to their nest (others
	-- are lost as before).
	function Bases.dropStolen(player: Player, at: Vector3)
		for _, p in carrying[player] or {} do
			local owner = Services.Players:GetPlayerByUserId(p:GetAttribute("StolenFrom") or 0)
			if p:GetAttribute("HoardZone") then
				Hoards.giveBack(p, at)
			elseif owner and owner ~= player then
				giveBack(owner, p, at)
			else
				p:Destroy()
			end
		end
		carrying[player] = {}
	end

	-- Lock wall: a translucent purple box around the patch with a countdown.
	local function setWall(patch: Instance, on: boolean)
		local wall = patch:FindFirstChild("LockWall") :: BasePart?
		if not on then
			if wall then
				wall:Destroy()
			end
			return
		end
		if wall then
			return
		end
		local soil = patch:FindFirstChild("Soil") :: BasePart?
		if not soil then
			return
		end
		local center, size = soil.CFrame, soil.Size + Vector3.new(4, 0, 4)
		if patch:IsA("Model") then
			local cf, box = patch:GetBoundingBox()
			center, size = cf, box + Vector3.new(2, 0, 2)
		end
		local w = Instance.new("Part")
		w.Name = "LockWall"
		w.Anchored = true
		w.CanCollide = false
		w.CanQuery = false
		w.CanTouch = false
		w.CastShadow = false
		w.Material = Enum.Material.ForceField
		w.Color = Color3.fromRGB(170, 80, 255)
		w.Transparency = 0.2
		w.Size = Vector3.new(size.X, 12, size.Z)
		w.CFrame = CFrame.new(center.Position.X, soil.Position.Y + 6, center.Position.Z)
			* center.Rotation
		local bb = Instance.new("BillboardGui")
		bb.Name = "LockTimer"
		bb.Size = UDim2.fromOffset(200, 44)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.MaxDistance = 60
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Helpers.fontFace("title")
		label.TextScaled = false
		label.TextColor3 = Color3.fromRGB(220, 170, 255)
		label.Text = "🔒 LOCKED"
		label.Parent = bb
		local outline = Instance.new("UIStroke")
		outline.Thickness = 2.5
		outline.Color = Color3.fromRGB(30, 12, 40)
		outline.Parent = label
		bb.Parent = w
		w.Parent = patch
	end

	function Bases.lock(player: Player)
		local patch = patchOf[player]
		if not patch or not Helpers.isLoaded(player) then
			return
		end
		local t = now()
		if not Purge.active() or Purge.locks[player.UserId] then
			return
		end
		if Bases.locksOff() then
			hint(player, "🩸 Blood Moon! Every lock is off right now.")
			return
		end
		player:SetAttribute("PurgeLockUsed", Purge.id)
		Purge.locks[player.UserId] = true
		patch:SetAttribute("LockedUntil", t + Config.Purge.lockSeconds)
		patch:SetAttribute("LockCooldownUntil", state:GetAttribute("PurgeEnds"))
		setWall(patch, true)
		hint(player, string.format("🔒 Base locked for %d seconds!", Config.Purge.lockSeconds))
		track(player, "lock", 1)
	end

	-- Blood Moon start: every lock is removed (cooldowns stay).
	function Bases.clearLocks()
		for _, patch in patchFolder:GetChildren() do
			patch:SetAttribute("LockedUntil", nil)
			setWall(patch, false)
		end
	end

	-- Empties a patch: placed pumpkins are destroyed and the lock is removed.
	function Bases.clear(patch: Instance)
		if Progress.recoverStashes then
			Progress.recoverStashes(patch)
		end
		for _, plot in plotsOf(patch) do
			local p = Bases.take(plot)
			if p then
				p:Destroy()
			end
		end
		patch:SetAttribute("LockedUntil", nil)
		patch:SetAttribute("LockCooldownUntil", nil)
		setWall(patch, false)
		Bases.refresh(patch)
	end

	-- Every second: lock countdowns, then base income for each loaded player.
	local carry: { [Player]: number } = {}
	Bases.incomeCarry = carry
	function Bases.tick()
		local t = now()
		for _, patch in patchFolder:GetChildren() do
			local untilAt = patch:GetAttribute("LockedUntil")
			if untilAt and (t >= untilAt or Bases.locksOff()) then
				patch:SetAttribute("LockedUntil", nil)
				untilAt = nil
			end
			local locked = Bases.isLocked(patch)
			setWall(patch, locked)
			if locked then
				local wall = patch:FindFirstChild("LockWall")
				local timer = wall and wall:FindFirstChild("LockTimer")
				local label = timer and timer:FindFirstChild("Label") :: TextLabel?
				if label then
					local owner =
						Services.Players:GetPlayerByUserId(patch:GetAttribute("Owner") or 0)
					label.Text = Purge.active()
							and owner
							and Purge.immune(owner)
							and ((owner:GetAttribute("PlayTime") or 0) < Config.Purge.grace and "NEW FARMER SHIELD" or "AFK AUTO-LOCK")
						or string.format("🔒 LOCKED %ds", math.ceil((untilAt or t) - t))
				end
			end
		end
		-- Hatching countdowns; a finished one hatches.
		for _, s in plotState do
			local p = s.pumpkin
			local carveAt = p and p:GetAttribute("CarveAt")
			if p and type(carveAt) == "number" then
				local final = p:GetAttribute("GrowthSize")
				if typeof(final) == "Vector3" then
					local fraction = math.clamp(
						(t - (p:GetAttribute("GrowthStartAt") or t))
							/ math.max(p:GetAttribute("GrowthDuration") or 1, 1),
						0,
						1
					)
					local step = math.floor(fraction * Config.Plots.growthSteps)
					if step ~= p:GetAttribute("GrowthStep") then
						local size = final
							* (
								Config.Plots.growthStart
								+ (1 - Config.Plots.growthStart)
									* step
									/ Config.Plots.growthSteps
							)
						p.CFrame += Vector3.yAxis * (size.Y - p.Size.Y) / 2
						p.Size = size
						Looks.refit(p)
						p:SetAttribute("GrowthStep", step)
					end
				end
				if t >= carveAt + Config.Plots.readySeconds then
					local ok, err = pcall(carve, p, p:GetAttribute("ForceReveal") == true)
					if not ok then
						warn("[Patch] Hatch failed:", err)
					end
				else
					local tag = p:FindFirstChild("CarveTag")
					local label = tag and tag:FindFirstChild("Label") :: TextLabel?
					local left = math.ceil(carveAt - t)
					if label then
						label.Text = left <= 0 and "Mystery Pumpkin\nREADY!" or hatchText(left)
						label.TextColor3 = left <= 0 and Color3.fromRGB(68, 255, 47)
							or Config.Plots.domeColor
					end
				end
			end
		end
		for player, patch in patchOf do
			if player.Parent and Helpers.isLoaded(player) then
				Bases.refresh(patch)
				refreshCarry(player)
				local income = player:GetAttribute("Income") or 0
				-- Spooky Hour pays x SpookyMult (orders still count the plain income).
				local total = (carry[player] or 0) + income * Spooky.mult()
				local whole = math.floor(total)
				carry[player] = total - whole
				if whole > 0 then
					addCandy(player, whole, true)
				end
				track(player, "income", math.floor(income), true)
			end
		end
	end

	local nextRoamUpdate = 0
	Services.RunService.Heartbeat:Connect(function()
		-- Waypoints and prompt anchors need at most 5 Hz; clients interpolate the pets.
		local t = now()
		if t < nextRoamUpdate then
			return
		end
		nextRoamUpdate = t + 0.2
		for plot, s in plotState do
			local p = s.pumpkin
			local soil = plot.Parent and plot.Parent:FindFirstChild("Soil")
			if
				p
				and p:GetAttribute("Jack")
				and not p:GetAttribute("Stashed")
				and soil
				and t >= (p:GetAttribute("RoamNext") or 0)
			then
				local from = Config.roamPoint(p, t)
				local cfg = Config.PetRoam
				local wander = (p:GetAttribute("PetHeight") or 0) > 5.5 and 2 or Config.Plots.wander
				local x = math.min(wander, math.max(0, plot.Size.Y / 2 - 0.5))
				local z = math.min(wander, math.max(0, plot.Size.Z / 2 - 0.5))
				local goal = plot.Position
					+ soil.CFrame:VectorToWorldSpace(
						Vector3.new((math.random() * 2 - 1) * x, 0, (math.random() * 2 - 1) * z)
					)
					+ Vector3.yAxis * (0.15 + p.Size.Y / 2)
				local duration = (goal - from).Magnitude
					/ (cfg.minSpeed + math.random() * (cfg.maxSpeed - cfg.minSpeed))
				p:SetAttribute("RoamFrom", from)
				p:SetAttribute("RoamTo", goal)
				p:SetAttribute("RoamStart", t)
				p:SetAttribute("RoamEnd", t + duration)
				p:SetAttribute(
					"RoamNext",
					t + duration + cfg.minIdle + math.random() * (cfg.maxIdle - cfg.minIdle)
				)
			end
		end
		for _, s in plotState do
			local p = s.pumpkin
			local anchor = p and p:FindFirstChild("PetPromptAnchor")
			if anchor then
				anchor.WorldPosition = Config.roamPoint(p, t)
			end
		end
	end)

	-- Prompts on every plot and sign post, enabled on the server (it only accepts enabled ones);
	-- each client hides the ones that do not apply to it (Place / Pick up on its own base, Steal
	-- on other unlocked bases). The handlers check every rule again.
	local function makePrompt(parent: Instance, name: string, action: string, hold: number)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = name
		prompt.ActionText = action
		prompt.ObjectText = ""
		prompt.HoldDuration = hold
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = true
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
		prompt.Parent = parent
		if name == "PetPrompt" then
			prompt.HoldDuration = Config.Purge.hold
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.PromptButtonHoldBegan:Connect(function(player)
				if
					Purge.active()
					and patchOf[player] ~= parent.Parent
					and not Purge.immune(player)
					and Helpers.isLoaded(player)
					and Bases.petReach(player, parent)
				then
					Purge.holds[player] = { plot = parent, at = now(), id = Purge.id }
					player:SetAttribute("PurgeStealing", true)
				end
			end)
			prompt.PromptButtonHoldEnded:Connect(function(player)
				local pendingHold = Purge.holds[player]
				task.delay(0.1, function()
					if pendingHold and Purge.holds[player] == pendingHold then
						Purge.holds[player] = nil
						player:SetAttribute("PurgeStealing", nil)
					end
				end)
			end)
		end
		return prompt
	end
	Bases.setupPlot = function(plot)
		plot:SetAttribute("BaseSize", plot:GetAttribute("BaseSize") or plot.Size)
		plotState[plot] = { pumpkin = nil }
		makePrompt(plot, "PlacePrompt", "Place", 0.2).Triggered:Connect(function(player)
			place(player, plot)
		end)
		makePrompt(plot, "PetPrompt", "Pick up", Config.Purge.hold).Triggered:Connect(
			function(player)
				if patchOf[player] == plot.Parent then
					pickUp(player, plot)
				else
					steal(player, plot)
				end
			end
		)
	end
	for _, patch in patchFolder:GetChildren() do
		setOwnerSign(patch, "", Color3.fromRGB(255, 230, 200))
		for _, plot in patch:GetChildren() do
			if plot.Name ~= "Plot" or not plot:IsA("BasePart") then
				continue
			end
			plot:SetAttribute("BaseSize", plot:GetAttribute("BaseSize") or plot.Size)
			plotState[plot] = { pumpkin = nil }
			for _, child in plot:GetChildren() do
				if child:IsA("ProximityPrompt") then
					child:Destroy()
				end
			end
			makePrompt(plot, "PlacePrompt", "Place", 0.2).Triggered:Connect(function(player)
				place(player, plot)
			end)
			makePrompt(plot, "PetPrompt", "Pick up", Config.Purge.hold).Triggered:Connect(
				function(player)
					if patchOf[player] == plot.Parent then
						pickUp(player, plot)
					else
						steal(player, plot)
					end
				end
			)
		end
		for _, name in { "SwapPrompt", "SellCarryPrompt" } do
			local oldPrompt = patch:FindFirstChild(name, true)
			if oldPrompt then
				oldPrompt:Destroy()
			end
		end
		local post = patch:FindFirstChild("SignPost")
		local holder: Instance? = post
		if post and not post:IsA("BasePart") then
			holder = post:FindFirstChildWhichIsA("BasePart", true)
		end
		holder = holder or patch:FindFirstChild("Soil")
		if holder then
			local lockPrompt = makePrompt(holder, "LockPrompt", "Lock pen", 0.3)
			lockPrompt.ObjectText = "Your pen"
			lockPrompt.UIOffset = Vector2.new(0, -48)
			lockPrompt.MaxActivationDistance = 12
			lockPrompt.Triggered:Connect(function(player)
				if patchOf[player] == patch then
					Bases.lock(player)
				end
			end)
		end
	end
end

-- Sets the unlock flags a player has reached (every second while loaded, and on load). Flags never
-- turn off again; reset (the Studio "playtime" debug action) recomputes them from scratch.
function Unlock.refresh(player: Player, reset: boolean?)
	Progress.arrive(player)
	local gates = Config.Unlocks
	local played = player:GetAttribute("PlayTime") or 0
	for _, name in Unlock.NAMES do
		if name == "King" and played < gates.King then
			player:SetAttribute("Unlock_King", nil)
			continue
		end
		if not reset and Unlock.has(player, name) then
			continue
		end
		local on
		if name == "Haunt" then
			on = hasZone(player, "Zone7") and Progress.complete(player, "Zone7")
		else
			on = played >= (gates[name] or 0) or (name == "Sell" and Bases.full(patchOf[player]))
		end
		if reset and not on then
			player:SetAttribute("Unlock_" .. name, nil)
		elseif on and not Unlock.has(player, name) then
			player:SetAttribute("Unlock_" .. name, true)
		end
	end
end

-- Build every pen before ownership/locks, using the same fixed grid at 8/10/12 capacity.
function Bases.layout(patch)
	if patch:GetAttribute("SlotGeometry") == Config.Progression.castleSlots then
		return
	end
	local soil = patch:FindFirstChild("Soil")
	-- Bases.plots filters out locked slots; layout must include EVERY authored disc.
	local plots = {}
	for _, plot in patch:GetChildren() do
		if plot.Name == "Plot" and plot:IsA("BasePart") then
			table.insert(plots, plot)
		end
	end
	table.sort(plots, function(a, b)
		return (a:GetAttribute("Index") or 1) < (b:GetAttribute("Index") or 1)
	end)
	if not soil or not soil:IsA("BasePart") or not plots[1] then
		return
	end
	-- Project the actual model bounds into the soil's frame (including rotated pens).
	local boxCF, boxSize = patch:GetBoundingBox()
	local lo, hi =
		Vector3.new(math.huge, math.huge, math.huge),
		Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, x in { -0.5, 0.5 } do
		for _, y in { -0.5, 0.5 } do
			for _, z in { -0.5, 0.5 } do
				local v = soil.CFrame:PointToObjectSpace(
					boxCF:PointToWorldSpace(boxSize * Vector3.new(x, y, z))
				)
				lo, hi = lo:Min(v), hi:Max(v)
			end
		end
	end
	lo = lo:Max(-soil.Size / 2)
	hi = hi:Min(soil.Size / 2)
	-- Fence posts define the inner envelope; signs/decor must not widen the planting area.
	local fenceLo, fenceHi, posts =
		Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge), 0
	for _, part in patch:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Post" then
			local v = soil.CFrame:PointToObjectSpace(part.Position)
			fenceLo, fenceHi, posts = fenceLo:Min(v), fenceHi:Max(v), posts + 1
		end
	end
	if posts >= 4 and fenceHi.X > fenceLo.X and fenceHi.Z > fenceLo.Z then
		lo = Vector3.new(math.max(lo.X, fenceLo.X + 0.5), lo.Y, math.max(lo.Z, fenceLo.Z + 0.5))
		hi = Vector3.new(math.min(hi.X, fenceHi.X - 0.5), hi.Y, math.min(hi.Z, fenceHi.Z - 0.5))
	end
	-- Rebuild locked decorations on the same grid as wooden discs.
	for _, item in patch:GetDescendants() do
		if item.Name == "SlotLock" or item.Name == "LockedDisc" then
			item:Destroy()
		end
	end
	-- Lobby rims are independent anchored parts at the old positions; rebuild as plot children.
	for _, rim in patch:GetDescendants() do
		if rim.Name == "DiscRim" then
			rim:Destroy()
		end
	end
	for i = #plots + 1, Config.Progression.castleSlots do
		local p = plots[1]:Clone()
		p:ClearAllChildren()
		p:SetAttribute("Index", i)
		p:SetAttribute("Filled", false)
		p:SetAttribute("Protected", false)
		p.Parent = patch
		Bases.setupPlot(p)
		table.insert(plots, p)
	end
	local rows = Config.Progression.slotRows
	local columns = math.ceil(#plots / rows)
	local width, depth = math.max(0.1, hi.X - lo.X), math.max(0.1, hi.Z - lo.Z)
	local margin = math.min(Config.Progression.slotMargin, math.min(width, depth) * 0.05)
	width, depth = width - margin * 2, depth - margin * 2
	local diameter = math.min(7.4, width / columns * 0.9, depth / rows * 0.9)
	local stepX = (width - diameter) / math.max(1, columns - 1)
	local stepZ = (depth - diameter) / math.max(1, rows - 1)
	local center = (lo + hi) / 2
	local height = soil.CFrame:PointToObjectSpace(plots[1].Position).Y
	for i, plot in plots do
		plot:SetAttribute("Index", i)
		local old = plot.CFrame
		local target = CFrame.new(
			soil.CFrame:PointToWorldSpace(
				Vector3.new(
					center.X + (math.floor((i - 1) / rows) - (columns - 1) / 2) * stepX,
					height,
					center.Z + ((i - 1) % rows - (rows - 1) / 2) * stepZ
				)
			)
		) * old.Rotation
		local lock = plot:FindFirstChild("SlotLock")
		if lock then
			lock:Destroy()
		end
		local delta = target * old:Inverse()
		for _, decoration in plot:GetDescendants() do
			if decoration:IsA("BasePart") and decoration.Anchored then
				decoration.CFrame = delta * decoration.CFrame
			end
		end
		plot.CFrame = target
		plot.Size = Vector3.new(plot.Size.X, diameter * 6.6 / 7.4, diameter * 6.6 / 7.4)
		plot:SetAttribute("BaseSize", plot.Size)
		local rim = Instance.new("Part")
		rim.Name = "DiscRim"
		rim.Shape = Enum.PartType.Cylinder
		rim.Size = Vector3.new(0.5, diameter, diameter)
		rim.CFrame = target - soil.CFrame.UpVector * 0.15
		rim.Color = Config.Plots.rim
		rim.Material = Enum.Material.Wood
		rim.Anchored = true
		rim.CanCollide = false
		rim.CanTouch = false
		rim.CanQuery = false
		rim.Parent = plot
	end
	patch:SetAttribute("SlotGeometry", Config.Progression.castleSlots)
end

for _, patch in patchFolder:GetChildren() do
	Bases.layout(patch)
	Bases.slotLook(patch, Config.Progression.baseSlots)
end

local claimPatch
do
	-- The pens' fill order: their Order attribute (1..8), pens without one last (by name).
	function claimPatch(player: Player): boolean
		local best, bestOrder = nil, math.huge
		for _, patch in patchFolder:GetChildren() do
			if (patch:GetAttribute("Owner") or 0) == 0 and patch:FindFirstChild("Soil") then
				local order = tonumber(patch:GetAttribute("Order")) or 1000
				if
					order < bestOrder
					or (order == bestOrder and best and patch.Name < (best :: Instance).Name)
				then
					best, bestOrder = patch, order
				end
			end
		end
		if not best then
			return false
		end
		best:SetAttribute("Owner", player.UserId)
		patchOf[player] = best
		player:SetAttribute("PatchId", best:GetAttribute("Id"))
		setOwnerSign(best, player.DisplayName .. "'s Pen", Color3.fromRGB(255, 200, 90))
		return true
	end
end

local function releasePatch(player: Player)
	local patch = patchOf[player]
	patchOf[player] = nil
	if not patch then
		return
	end
	Bases.clear(patch)
	patch:SetAttribute("Owner", 0)
	patch:SetAttribute("SlotLookOwner", nil)
	patch:SetAttribute("PenSlots", Config.Progression.baseSlots)
	patch:SetAttribute("RaidPending", nil)
	setOwnerSign(patch, "", Color3.fromRGB(255, 230, 200))
end

local function ownedPatchCount(): number
	local n = 0
	for _, patch in patchFolder:GetChildren() do
		if (patch:GetAttribute("Owner") or 0) ~= 0 then
			n += 1
		end
	end
	return n
end

-- Wild pumpkins: breakables in the zones. Swing at them until they pop. -----------------------

local Wild: { [string]: any } = {}
do
	type WildState = {
		part: BasePart,
		hp: number,
		maxHp: number,
		size: Vector3,
		sizeMult: number,
		spawn: BasePart,
		zone: string,
		damage: { [Player]: number },
		last: Player?,
		tween: Tween?,
	}
	local folder = Instance.new("Folder")
	folder.Name = "Wild"
	folder.Parent = garden
	local alive: { [BasePart]: WildState } = {}
	-- Wild pumpkins alive per zone.
	local count: { [string]: number } = {}
	local taken: { [BasePart]: boolean } = {}
	-- Spawn parts per zone, found by the spawner task below (it waits for the zones).
	local spawns: { [string]: { BasePart } } = {}

	-- A small PS99-style bar (60x8 track, white number at its right). It starts hidden: each
	-- client shows it only on its current target and on pumpkins it hit in the last few seconds.
	-- Only rare types (Ghost or better) get a name over the bar, in the type's colour.
	local function hpBar(part: BasePart, seed)
		local rare = seed.order >= Config.RareNameOrder
		local bb = Instance.new("BillboardGui")
		bb.Name = "HpBar"
		bb.Size = UDim2.fromOffset(200, rare and 76 or 36)
		bb.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + 1.4, 0)
		bb.LightInfluence = 0
		bb.AlwaysOnTop = true
		bb.MaxDistance = Config.WildBarDistance
		bb.Enabled = false
		if rare then
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Size = UDim2.new(1, 0, 0, 32)
			name.TextSize = 28
			name.FontFace = Helpers.fontFace("title")
			name.TextScaled = false
			name.TextColor3 = seed.color or Color3.fromRGB(255, 190, 90)
			name.Text = seed.name
			name.Parent = bb
			local nameStroke = Instance.new("UIStroke")
			nameStroke.Thickness = 2
			nameStroke.Color = Color3.fromRGB(30, 12, 40)
			nameStroke.Parent = name
		end
		local back = Instance.new("Frame")
		back.Name = "Back"
		back.AnchorPoint = Vector2.new(0, 1)
		back.Position = UDim2.new(0, 4, 1, -3)
		back.Size = UDim2.fromOffset(90, 12)
		back.BackgroundColor3 = Color3.fromRGB(34, 22, 48)
		back.BorderSizePixel = 0
		back.Parent = bb
		local backCorner = Instance.new("UICorner")
		backCorner.CornerRadius = UDim.new(1, 0)
		backCorner.Parent = back
		local backStroke = Instance.new("UIStroke")
		backStroke.Thickness = 2
		backStroke.Color = Color3.fromRGB(20, 10, 30)
		backStroke.Parent = back
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(110, 230, 80)
		fill.BorderSizePixel = 0
		fill.Parent = back
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill
		local hp = Instance.new("TextLabel")
		hp.Name = "Hp"
		hp.BackgroundTransparency = 1
		hp.AnchorPoint = Vector2.new(1, 1)
		hp.Position = UDim2.fromScale(1, 1)
		hp.Size = UDim2.fromOffset(104, 32)
		hp.TextSize = 28
		hp.FontFace = Helpers.fontFace("title")
		hp.TextScaled = false
		hp.TextXAlignment = Enum.TextXAlignment.Left
		hp.TextColor3 = Color3.new(1, 1, 1)
		hp.Text = Helpers.short(part:GetAttribute("Hp") or seed.hp)
		hp.Parent = bb
		local hpStroke = Instance.new("UIStroke")
		hpStroke.Thickness = 1.5
		hpStroke.Color = Color3.fromRGB(20, 10, 30)
		hpStroke.Parent = hp
		bb.Parent = part
	end

	local function setBar(w: WildState)
		local bb = w.part:FindFirstChild("HpBar")
		local back = bb and bb:FindFirstChild("Back")
		local fill = back and back:FindFirstChild("Fill") :: Frame?
		local label = bb and bb:FindFirstChild("Hp") :: TextLabel?
		local fraction = math.clamp(w.hp / w.maxHp, 0, 1)
		if fill then
			fill.Size = UDim2.fromScale(fraction, 1)
			-- Green to yellow while healthy, red under 30%.
			fill.BackgroundColor3 = fraction < 0.3 and Color3.fromRGB(235, 40, 40)
				or Color3.fromRGB(255, 210, 60)
					:Lerp(Color3.fromRGB(110, 230, 80), (fraction - 0.3) / 0.7)
		end
		if label then
			label.Text = Helpers.short(math.max(0, w.hp))
		end
		w.part:SetAttribute("Hp", math.max(0, w.hp))
	end

	function Wild.spawnOne(zoneId: string): boolean
		local zoneDef = Config.Zones[zoneId]
		if not zoneDef or (count[zoneId] or 0) >= zoneDef.max then
			return false
		end
		local free = {}
		-- Spawn spots under a Hoard nest or its guardian (HoardNear) stay empty.
		for _, sp in spawns[zoneId] or {} do
			if not taken[sp] and not sp:GetAttribute("HoardNear") then
				table.insert(free, sp)
			end
		end
		if #free == 0 then
			return false
		end
		local sp = free[math.random(#free)]
		local golden = math.random(Config.Farm.goldenOneIn) == 1
		local big = math.random() < Config.Farm.bigChance
		local id = "Orange"
		if golden then
			id = "Golden"
		else
			-- Cosmetic roll: zone HP, rewards and bonus golden odds stay independent.
			local total = 0
			for kind, weight in zoneDef.weights do
				if kind ~= "Golden" and Lookup.seedById[kind] then
					total += weight
				end
			end
			local roll = math.random() * total
			for kind, weight in zoneDef.weights do
				if kind ~= "Golden" and Lookup.seedById[kind] then
					roll -= weight
					if roll <= 0 then
						id = kind
						break
					end
				end
			end
		end
		local seed = Lookup.seedById[id]
		local hp = math.ceil(zoneDef.hp * (big and Config.Farm.bigMult or 1))
		local reward = zoneDef.candy
			* (big and Config.Farm.bigMult or 1)
			* (golden and Config.Farm.goldenMult or 1)
		local sizeMult = big and 2 or 1
		local part = makePumpkin(id, sizeMult)
		part.Name = "WildPumpkin"
		part.Size *= Vector3.new(1, 0.95 + math.random() * 0.13, 1)
		Looks.wild(part, seed)
		local groundY = sp.Position.Y - sp.Size.Y / 2
		part.CFrame = CFrame.new(sp.Position.X, groundY + part.Size.Y / 2, sp.Position.Z)
			* CFrame.Angles(0, math.random() * math.pi * 2, 0)
		part:SetAttribute("Wild", true)
		part:SetAttribute("Zone", zoneId)
		part:SetAttribute("Hp", hp)
		part:SetAttribute("MaxHp", hp)
		part:SetAttribute("CandyReward", reward)
		part:SetAttribute("Golden", golden)
		if golden then
			local sparkle = Instance.new("Sparkles")
			sparkle.SparkleColor = Color3.fromRGB(255, 220, 60)
			sparkle.Parent = part
		end
		hpBar(part, seed)
		part.Parent = folder
		taken[sp] = true
		count[zoneId] = (count[zoneId] or 0) + 1
		alive[part] = {
			part = part,
			hp = hp,
			maxHp = hp,
			size = part.Size,
			sizeMult = sizeMult,
			spawn = sp,
			zone = zoneId,
			damage = {},
			last = nil,
			tween = nil,
		}
		setBar(alive[part])
		return true
	end

	-- Removes wild pumpkins within radius studs (X/Z) of pos (a Hoard was built there).
	function Wild.clearNear(pos: Vector3, radius: number)
		for part, w in alive do
			local flat = Vector3.new(part.Position.X - pos.X, 0, part.Position.Z - pos.Z)
			if flat.Magnitude <= radius then
				alive[part] = nil
				count[w.zone] = math.max(0, (count[w.zone] or 1) - 1)
				taken[w.spawn] = nil
				if w.tween then
					w.tween:Cancel()
				end
				part:Destroy()
			end
		end
	end

	-- Fills every zone up to its max right away; returns how many were added.
	function Wild.fill(): number
		local n = 0
		for _, zoneId in Config.ZoneOrder do
			while Wild.spawnOne(zoneId) do
				n += 1
			end
		end
		return n
	end

	-- A popped pumpkin goes to whoever dealt the most damage (the last hitter wins ties).
	local function pop(w: WildState, chain: number?, chainIndex: number?)
		local part = w.part
		alive[part] = nil
		count[w.zone] = math.max(0, (count[w.zone] or 1) - 1)
		task.delay(Config.WildRespawn, function()
			taken[w.spawn] = nil
			Wild.spawnOne(w.zone)
		end)
		if w.tween then
			w.tween:Cancel()
		end
		local winner = w.last
		local most = winner and w.damage[winner] or 0
		for p, d in w.damage do
			if p.Parent and d > most then
				winner, most = p, d
			end
		end
		if winner and not winner.Parent then
			winner = nil
		end
		local at = part.Position
		local seedId = part:GetAttribute("Seed")
		local seed = Lookup.seedById[seedId]
		-- The winner also gets a little candy (the burst that flies into their counter).
		local candy = 0
		if winner and seed then
			candy = part:GetAttribute("CandyReward") or 1
			candy = addCandy(
				winner,
				candy
					* (1 + math.min(
						Config.Farm.chainBonusCap,
						math.max(0, (chain or 1) - 1) * Config.Farm.chainBonus
					))
					* (Helpers.hasPass(winner, "DoubleCandy") and Config.DoubleCandyMult or 1)
			)
		end
		Remotes.wildPopEvent:FireAllClients(at, seedId, winner, candy, chain or 1, chainIndex or 1)
		part:Destroy()
		if not winner then
			return
		end
		Progress.quest(winner, w.zone, "smash", 1)
		track(winner, "smash", 1)
		track(winner, "farmCandy", candy)
		if winner:GetAttribute("FirstSmashCandy") ~= true then
			winner:SetAttribute("FirstSmashCandy", true)
			Remotes.hintEvent:FireClient(winner, "Smash = CANDY!")
		end
	end

	-- The server selects a bounded forward arc, independent of scythe tier.
	function Wild.hit(player: Player, root: BasePart): boolean
		local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if look.Magnitude < 0.01 then
			return false
		end
		look = look.Unit
		local targets = {}
		local lockedZone = nil
		for part, w in alive do
			local offset = part.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if
				math.abs(offset.Y) < 12
				and flat.Magnitude <= Config.Farm.arcRange
				and (
					flat.Magnitude < 0.1
					or flat.Unit:Dot(look) >= math.cos(math.rad(Config.Farm.arcDegrees / 2))
				)
			then
				if hasZone(player, w.zone) then
					table.insert(targets, w)
				else
					lockedZone = w.zone
				end
			end
		end
		table.sort(targets, function(a, b)
			return (a.part.Position - root.Position).Magnitude
				< (b.part.Position - root.Position).Magnitude
		end)
		while #targets > Config.Farm.maxTargets do
			table.remove(targets)
		end
		if #targets == 0 then
			if lockedZone then
				Remotes.hintEvent:FireClient(player, "Unlock the zone at its gate first!")
			end
			return false
		end
		local chain = #targets
		local spread =
			math.min(1, (bestTool(player).order >= 3 and Config.Farm.arcTargets or 1) / chain)
		for chainIndex, w in targets do
			local crit = math.random() < Config.Farm.critChance
			local damage = swingDamage(player) * spread * (crit and Config.Farm.critMult or 1)
			w.damage[player] = (w.damage[player] or 0) + math.min(damage, w.hp)
			w.last = player
			w.hp -= damage
			Remotes.wildHitEvent:FireAllClients(
				player,
				w.part.Position,
				damage,
				w.part,
				crit,
				math.max(0, w.hp),
				w.maxHp
			)
			if w.hp <= 0 then
				pop(w, chain, chainIndex)
			else
				setBar(w)
			end
		end
		return true
	end

	-- Studio debug: N pumpkins of a type straight onto a player's stack (no capacity check).
	function Wild.give(player: Player, n: number, seedId: string?): number
		local id = seedId and Lookup.seedById[seedId] and seedId or Config.Seeds[1].id
		local given = 0
		for _ = 1, n do
			local size = Config.SizeMin + math.random() * (Config.SizeMax - Config.SizeMin)
			local pumpkin = makePumpkin(id, size)
			pumpkin:SetAttribute("Hoard", true)
			Hoards.look(pumpkin)
			if stackPumpkin(player, pumpkin) then
				given += 1
			else
				pumpkin:Destroy()
				break
			end
		end
		return given
	end

	task.spawn(function()
		local zones = garden:WaitForChild("Zones", 10)
		if not zones then
			warn("[Patch] workspace.Garden.Zones is missing: no wild pumpkins")
			return
		end
		for _, zoneId in Config.ZoneOrder do
			local zone = zones:FindFirstChild(zoneId)
			local list = {}
			for _, d in zone and zone:GetDescendants() or {} do
				if d:IsA("BasePart") and d.Name == "Spawn" then
					table.insert(list, d)
				end
			end
			if #list == 0 then
				warn("[Patch] No Spawn parts in workspace.Garden.Zones." .. zoneId)
			end
			if #list > 0 and #list < 60 then
				local originals = table.clone(list)
				for i = #list + 1, 80 do
					local source = originals[(i - 1) % #originals + 1]
					local point = source:Clone()
					point:ClearAllChildren()
					local half = source.Size / 2
					for _ = 1, 100 do
						point.Position = source.CFrame:PointToWorldSpace(
							Vector3.new(
								(math.random() * 2 - 1) * math.max(half.X - 4, 8),
								0,
								(math.random() * 2 - 1) * math.max(half.Z - 4, 8)
							)
						)
						local clear = true
						for _, other in list do
							if (other.Position - point.Position).Magnitude < 4 then
								clear = false
								break
							end
						end
						if clear then
							break
						end
					end
					point.Size = Vector3.new(1, source.Size.Y, 1)
					point.Transparency = 1
					point.CanCollide = false
					point.CanTouch = false
					point.CanQuery = false
					point.Parent = zone
					table.insert(list, point)
				end
			end
			spawns[zoneId] = list
		end
		-- Population starts after nest exclusions have been marked by Hoards.
	end)
end

-- Zone gates: Zone2-7 each have a GateWall (solid on the server; each client opens the walls of
-- zones it has unlocked), an unlock prompt on the wall and a sign over it. ----------------------

local guardZones -- defined in the block below
do
	local function unlockZone(player: Player, zoneId: string)
		local def = Config.Zones[zoneId]
		if not def then
			return
		end
		if not Helpers.isLoaded(player) then
			Remotes.hintEvent:FireClient(player, "Loading your farm...")
			return
		end
		if hasZone(player, zoneId) then
			Remotes.hintEvent:FireClient(player, "The " .. def.title .. " is already open for you!")
			return
		end
		local candy = Helpers.candyValue(player)
		local previous = Config.ZoneOrder[(table.find(Config.ZoneOrder, zoneId) or 1) - 1]
		if not previous or not hasZone(player, previous) then
			Remotes.hintEvent:FireClient(player, "Gate unlock failed: open the previous zone first")
			return
		end
		local cost = math.floor(
			(def.cost or 0)
				* (
					Progress.complete(player, previous)
						and (1 - Config.Progression.gateDiscount)
					or 1
				)
		)
		if not candy or candy.Value < cost then
			Remotes.hintEvent:FireClient(
				player,
				string.format(
					"You need %s 🍬 to unlock the %s. Place pumpkins on your base to earn more!",
					Helpers.short(cost),
					def.title
				)
			)
			return
		end
		candy.Value -= cost
		local owned = zonesOf[player] or {}
		zonesOf[player] = owned
		owned[zoneId] = true
		publishZones(player)
		Progress.arrive(player)
		player:SetAttribute("ObjectiveZone", zoneId)
		Remotes.hintEvent:FireClient(player, "🔓 The " .. def.title .. " is open! Go smash!")
		track(player, "unlockZone", 1)
	end
	Bases.unlockZone = unlockZone

	-- Gate sign (Steal an Egg / Pet Sim 99 style): the zone name with its difficulty emoji in big
	-- white stroked letters and a yellow price pill ("🍬 1k") under it. Each client turns the pill
	-- green "UNLOCKED ✅" for zones it owns. Only readable up close (MaxDistance 80).
	local function gateSign(sign: BasePart, def)
		local old = sign:FindFirstChild("GateGui")
		if old then
			old:Destroy()
		end
		local ink = Color3.fromHex("3B2766")
		local bb = Instance.new("BillboardGui")
		bb.Name = "GateGui"
		bb.Size = UDim2.fromOffset(300, 120)
		bb.LightInfluence = 0
		bb.MaxDistance = 60
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromScale(1, 0.56)
		title.FontFace = Helpers.fontFace("title")
		title.TextScaled = false
		title.TextColor3 = def.color
		title.Text = def.title
		title.Parent = bb
		local titleStroke = Instance.new("UIStroke")
		titleStroke.Thickness = 4
		titleStroke.Color = ink
		titleStroke.Parent = title
		local pill = Instance.new("Frame")
		pill.Name = "Pill"
		pill.AnchorPoint = Vector2.new(0.5, 1)
		pill.Position = UDim2.new(0.5, 0, 1, -4)
		pill.Size = UDim2.fromOffset(180, 42)
		pill.BackgroundColor3 = Color3.fromHex("FFC83D")
		pill.Parent = bb
		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(1, 0)
		pillCorner.Parent = pill
		local pillStroke = Instance.new("UIStroke")
		pillStroke.Thickness = 3
		pillStroke.Color = ink
		pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pillStroke.Parent = pill
		local cost = Instance.new("TextLabel")
		cost.Name = "Cost"
		cost.BackgroundTransparency = 1
		cost.Position = UDim2.fromOffset(10, 5)
		cost.Size = UDim2.new(1, -20, 1, -10)
		cost.FontFace = Helpers.fontFace("title")
		cost.TextScaled = false
		cost.TextColor3 = Color3.fromHex("FFF8EC")
		cost.Text = "🍬 " .. Helpers.short(def.cost or 0)
		cost.Parent = pill
		local costStroke = Instance.new("UIStroke")
		costStroke.Thickness = 2.5
		costStroke.Color = ink
		costStroke.Parent = cost
		bb.Parent = sign
	end

	task.spawn(function()
		local zones = garden:WaitForChild("Zones", 10)
		if not zones then
			return
		end
		for _, zoneId in Config.ZoneOrder do
			local def = Config.Zones[zoneId]
			local zone = zones:FindFirstChild(zoneId)
			if not def or (def.cost or 0) <= 0 or not zone then
				continue
			end
			local wall = zone:FindFirstChild("GateWall")
			if wall and wall:IsA("BasePart") then
				wall.CanCollide = true
				for _, child in wall:GetChildren() do
					if child:IsA("ProximityPrompt") then
						child:Destroy()
					end
				end
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "UnlockPrompt"
				prompt.ActionText = "Unlock " .. def.title .. ": " .. Config.gateBenefits(zoneId)
				prompt.ObjectText = Helpers.short(def.cost) .. " candy"
				prompt.HoldDuration = 0.6
				prompt.KeyboardKeyCode = Enum.KeyCode.E
				prompt.MaxActivationDistance = 14
				prompt.RequiresLineOfSight = true
				prompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
				prompt.Parent = wall
				prompt.HoldDuration = 0
				prompt.Triggered:Connect(function(player)
					local _, root = aliveRoot(player)
					if
						root
						and (root.Position - wall.Position).Magnitude
							<= prompt.MaxActivationDistance
					then
						unlockZone(player, zoneId)
					end
				end)
			end
			local sign = zone:FindFirstChild("GateSign")
			if sign and sign:IsA("BasePart") then
				gateSign(sign, def)
			end
		end
	end)

	-- Where a player is sent back to from a locked zone: the market spawn.
	local function marketSpawn(): CFrame
		local spawn = garden:FindFirstChildOfClass("SpawnLocation")
			or workspace:FindFirstChildOfClass("SpawnLocation")
		if spawn then
			return spawn.CFrame + Vector3.new(0, 4, 0)
		end
		-- No spawn: the middle of the hub, near its far end from the safe line.
		local plaza = market:FindFirstChild("Plaza") :: BasePart?
		local y = plaza and plaza.Position.Y or 0
		return CFrame.new(Lane.x, y + 6, Lane.safeZ * 0.8)
	end

	-- Safety net (every second): a player inside the Z range of a zone they have not unlocked
	-- (over or around the gate wall) goes back to the spawn.
	function guardZones()
		local inset = Config.ZoneGuardInset or 2
		local ranges = {}
		for _, zoneId in Config.ZoneOrder do
			local def = Config.Zones[zoneId]
			local z = def and (def.cost or 0) > 0 and Lane.zone(zoneId)
			if z then
				ranges[zoneId] = z
			end
		end
		for _, player in Services.Players:GetPlayers() do
			local character, root = aliveRoot(player)
			if not character or not root or not Helpers.isLoaded(player) then
				continue
			end
			local at = root.Position.Z
			for zoneId, z in ranges do
				local def = Config.Zones[zoneId]
				if not hasZone(player, zoneId) then
					if at >= z.zMin + inset and at <= z.zMax then
						character:PivotTo(marketSpawn())
						Remotes.hintEvent:FireClient(
							player,
							string.format(
								"🔒 The %s is locked! Unlock it at its gate for %s 🍬.",
								def.title,
								Helpers.short(def.cost or 0)
							)
						)
						break
					end
				end
			end
		end
	end
end

-- P1: no unimplemented World 2 teaser at the end of the playable trail.

-- Hoards and Guardians ------------------------------------------------------------------------
-- Each zone (Config.Hoards) gets a straw nest of big Hoard pumpkins in its zone folder, guarded
-- by a sleeping giant (ServerStorage.GuardModels.<guardian> scaled to the zone's
-- guardHeight, else built from studded parts) welded to an invisible anchored root that the
-- server moves every Heartbeat (no Humanoid). Stealing a pumpkin wakes it: red "!", a roar,
-- then a chase. It bonks the thief within reach (their pumpkins drop for recovery) or
-- gives up at the thief's base, when the thief leaves the zone's Z range (+ HoardLeashPad) or
-- crosses the hub's safe line, or after GuardianChaseSeconds, then walks home and sleeps again.
-- Nests refill one pumpkin every HoardRefill seconds.

do
	type Guardian = {
		zone: string,
		model: Model,
		root: BasePart,
		eyes: { [BasePart]: Color3 },
		sleepTag: BillboardGui,
		alertTag: BillboardGui,
		reach: number,
		home: Vector3,
		homeLook: Vector3,
		pos: Vector3,
		look: Vector3,
		state: string, -- "sleep" | "wake" | "chase" | "return"
		target: Player?,
		wokeAt: number,
		chaseEnd: number,
		share: number,
		seen: number,
		walk: number,
	}
	type Hoard = {
		zone: string,
		model: Model,
		nest: Vector3,
		top: number,
		slots: { [number]: BasePart? },
		pending: number,
		nextRefill: number,
		-- The chase leash: the zone's Z range.
		zMin: number,
		zMax: number,
		guard: Guardian,
	}
	local hoards: { [string]: Hoard } = {}
	local guardDrops = {}
	function Hoards.cancelDrop(p: BasePart)
		local drop = guardDrops[p]
		if drop then
			drop.hoard.pending -= 1
			guardDrops[p] = nil
		end
	end
	function Hoards.targets(player)
		for _, h in hoards do
			if h.guard.target == player then
				return true
			end
		end
		return false
	end
	local NEST_R, SLOT_R = Config.MysterySizes.nestRadius, Config.MysterySizes.nestSlotRadius
	local V, C = Vector3.new, Color3.fromRGB
	local INK = C(26, 18, 24)

	-- Blocky "lego" guardians, about 3x a player's height. Each part: { shape ("B" block, "S"
	-- ball), size, centre (studs over the ground, -Z = front), colour, name ("Eye" lights up red
	-- when awake), roll in radians }. reach = how far the body sticks out in front.
	local GUARDIANS: { [string]: { height: number, reach: number, parts: { { any } } } } = {
		Scarecrow = {
			height = 17.5,
			reach = 2.5,
			parts = {
				{ "B", V(1.6, 5, 1.6), V(-1.1, 2.5, 0), C(60, 100, 190) },
				{ "B", V(1.6, 5, 1.6), V(1.1, 2.5, 0), C(60, 100, 190) },
				{ "B", V(5, 5, 3), V(0, 7.5, 0), C(210, 40, 40) },
				{ "B", V(5.1, 0.6, 3.1), V(0, 6.6, 0), C(90, 20, 25) },
				{ "B", V(5.1, 0.6, 3.1), V(0, 8.4, 0), C(90, 20, 25) },
				{ "B", V(0.6, 5.1, 3.1), V(0, 7.5, 0), C(90, 20, 25) },
				{ "B", V(3.6, 1.5, 1.5), V(-4.3, 9.2, 0), C(210, 40, 40) },
				{ "B", V(3.6, 1.5, 1.5), V(4.3, 9.2, 0), C(210, 40, 40) },
				{ "B", V(1.2, 1.2, 1.2), V(-6.6, 9.2, 0), C(240, 200, 70) },
				{ "B", V(1.2, 1.2, 1.2), V(6.6, 9.2, 0), C(240, 200, 70) },
				{ "B", V(3, 0.8, 2.6), V(0, 10.4, 0), C(240, 200, 70) },
				{ "S", V(4.6, 4.6, 4.6), V(0, 12.9, 0), C(255, 140, 30) },
				{ "B", V(0.9, 0.9, 0.3), V(-0.9, 13.4, -2.2), INK, "Eye" },
				{ "B", V(0.9, 0.9, 0.3), V(0.9, 13.4, -2.2), INK, "Eye" },
				{ "B", V(2.2, 0.5, 0.3), V(0, 12.1, -2.15), INK },
				{ "B", V(6, 0.4, 6), V(0, 15.1, 0), C(110, 70, 40) },
				{ "B", V(3.2, 2.2, 3.2), V(0, 16.4, 0), C(110, 70, 40) },
			},
		},
		SkeletonKnight = {
			height = 17.4,
			reach = 2,
			parts = {
				{ "B", V(1, 5, 1), V(-1, 2.8, 0), C(240, 236, 220) },
				{ "B", V(1, 5, 1), V(1, 2.8, 0), C(240, 236, 220) },
				{ "B", V(1.6, 0.6, 2.2), V(-1, 0.3, -0.3), C(150, 155, 170) },
				{ "B", V(1.6, 0.6, 2.2), V(1, 0.3, -0.3), C(150, 155, 170) },
				{ "B", V(3.6, 1.1, 2), V(0, 5.8, 0), C(240, 236, 220) },
				{ "B", V(1, 4, 1), V(0, 8, 0.4), C(240, 236, 220) },
				{ "B", V(4, 0.5, 2.4), V(0, 7.2, 0), C(240, 236, 220) },
				{ "B", V(4.4, 0.5, 2.6), V(0, 8.3, 0), C(240, 236, 220) },
				{ "B", V(4.6, 0.5, 2.7), V(0, 9.4, 0), C(240, 236, 220) },
				{ "B", V(2.2, 1.2, 2.2), V(-2.9, 10.4, 0), C(150, 155, 170) },
				{ "B", V(2.2, 1.2, 2.2), V(2.9, 10.4, 0), C(150, 155, 170) },
				{ "B", V(0.9, 4.2, 0.9), V(-3, 7.8, 0), C(240, 236, 220) },
				{ "B", V(0.9, 4.2, 0.9), V(3, 7.8, -0.4), C(240, 236, 220) },
				{ "B", V(0.4, 7, 1), V(3, 9.5, -1.4), C(190, 195, 210) },
				{ "B", V(3.4, 3.2, 3.2), V(0, 12.6, 0), C(240, 236, 220) },
				{ "B", V(2.6, 0.9, 2.6), V(0, 10.6, -0.2), C(240, 236, 220) },
				{ "B", V(0.8, 0.8, 0.2), V(-0.8, 12.8, -1.65), INK, "Eye" },
				{ "B", V(0.8, 0.8, 0.2), V(0.8, 12.8, -1.65), INK, "Eye" },
				{ "B", V(3.8, 1.4, 3.8), V(0, 14.7, 0), C(90, 95, 110) },
				{ "B", V(0.6, 2, 2.6), V(0, 16.4, 0.3), C(200, 30, 40) },
			},
		},
		TreeEnt = {
			height = 18.9,
			reach = 3,
			parts = {
				{ "B", V(2, 4, 2.2), V(-1.5, 2, 0), C(85, 55, 32) },
				{ "B", V(2, 4, 2.2), V(1.5, 2, 0), C(85, 55, 32) },
				{ "B", V(4.6, 8, 3.6), V(0, 8, 0), C(120, 78, 45) },
				{ "B", V(4.2, 1.3, 1.3), V(-4, 10.5, 0), C(120, 78, 45), nil, -0.45 },
				{ "B", V(4.2, 1.3, 1.3), V(4, 10.5, 0), C(120, 78, 45), nil, 0.45 },
				{ "B", V(2.4, 2.4, 2.4), V(-6.2, 11.6, 0), C(70, 170, 60) },
				{ "B", V(2.4, 2.4, 2.4), V(6.2, 11.6, 0), C(70, 170, 60) },
				{ "B", V(1, 1, 0.3), V(-1, 10.6, -1.9), INK, "Eye" },
				{ "B", V(1, 1, 0.3), V(1, 10.6, -1.9), INK, "Eye" },
				{ "B", V(3.4, 0.5, 0.4), V(0, 11.5, -1.95), C(85, 55, 32) },
				{ "B", V(2.2, 0.5, 0.3), V(0, 8.6, -1.9), INK },
				{ "B", V(8, 4, 7), V(0, 14, 0), C(70, 170, 60) },
				{ "B", V(5.5, 3, 5), V(0, 17.4, 0), C(110, 200, 80) },
				{ "B", V(3, 3, 3), V(-4, 13.2, 1), C(110, 200, 80) },
				{ "B", V(3, 3, 3), V(4, 13.2, 1), C(110, 200, 80) },
			},
		},
		SwampToad = {
			height = 13.2,
			reach = 4.5,
			parts = {
				{ "B", V(9, 6, 8), V(0, 4.5, 0.5), C(80, 170, 60) },
				{ "B", V(6.5, 4, 0.4), V(0, 4, -3.6), C(200, 220, 120) },
				{ "B", V(8.5, 3, 7), V(0, 8.8, -0.6), C(80, 170, 60) },
				{ "B", V(7, 0.4, 0.3), V(0, 7.7, -4.15), C(50, 120, 40) },
				{ "B", V(2.6, 2.4, 2.6), V(-2.8, 11.3, -2.2), C(80, 170, 60) },
				{ "B", V(2.6, 2.4, 2.6), V(2.8, 11.3, -2.2), C(80, 170, 60) },
				{ "B", V(2, 2, 0.4), V(-2.8, 11.5, -3.6), C(255, 220, 40), "Eye" },
				{ "B", V(2, 2, 0.4), V(2.8, 11.5, -3.6), C(255, 220, 40), "Eye" },
				{ "B", V(0.6, 1.4, 0.3), V(-2.8, 11.5, -3.85), INK },
				{ "B", V(0.6, 1.4, 0.3), V(2.8, 11.5, -3.85), INK },
				{ "B", V(1.8, 3.6, 1.8), V(-3.6, 1.8, -3), C(50, 120, 40) },
				{ "B", V(1.8, 3.6, 1.8), V(3.6, 1.8, -3), C(50, 120, 40) },
				{ "B", V(3, 2.4, 4.4), V(-5, 1.2, 2), C(80, 170, 60) },
				{ "B", V(3, 2.4, 4.4), V(5, 1.2, 2), C(80, 170, 60) },
				{ "B", V(1.6, 0.3, 1.6), V(-2.2, 10.45, 1.8), C(50, 120, 40) },
				{ "B", V(4, 0.3, 4), V(1.2, 10.45, 1), C(100, 50, 160) },
				{ "B", V(2.2, 2.6, 2.2), V(1.2, 11.9, 1), C(100, 50, 160) },
			},
		},
	}

	-- Ground under the guardian: a short ray near its last height (players are skipped), so it
	-- follows slopes but never climbs onto props more than 4 studs up or down.
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local function refreshRayFilter()
		local skip = {}
		for _, p in Services.Players:GetPlayers() do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		rayParams.FilterDescendantsInstances = skip
	end
	local function groundAt(x: number, z: number, nearY: number): number
		local hit = workspace:Raycast(V(x, nearY + 6, z), V(0, -14, 0), rayParams)
		if hit and math.abs(hit.Position.Y - nearY) <= 4 then
			return hit.Position.Y
		end
		return nearY
	end

	local function tag(
		root: BasePart,
		name: string,
		text: string,
		color: Color3,
		size: UDim2,
		y: number
	)
		local bb = Instance.new("BillboardGui")
		bb.Name = name
		-- Scale sizes are studs, so the letters stay big in the world.
		bb.Size = size
		bb.StudsOffsetWorldSpace = V(0, y, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 60
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Helpers.fontFace("title")
		label.TextScaled = false
		label.TextColor3 = color
		label.Text = text
		label.Parent = bb
		local outline = Instance.new("UIStroke")
		outline.Thickness = 4
		outline.Color = C(15, 10, 30)
		outline.Parent = label
		bb.Parent = root
		return bb
	end

	-- A clone of ServerStorage.GuardModels.<name> scaled to height studs, standing at home (front
	-- -Z = home's front) with every part welded to root. Returns its eyes (parts named "Eye",
	-- optional) and its reach, or nil when there is no such model.
	local function guardLook(
		name: string?,
		height: number,
		home: CFrame,
		root: BasePart,
		model: Model
	): ({ [BasePart]: Color3 }?, number)
		local src = Looks.source("GuardModels", name)
		if not src then
			return nil, 0
		end
		local look = src:Clone()
		for _, d in look:GetDescendants() do
			if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") or d:IsA("ProximityPrompt") then
				d:Destroy()
			end
		end
		local _, size = look:GetBoundingBox()
		if size.Y <= 0.01 then
			look:Destroy()
			return nil, 0
		end
		look:ScaleTo(look:GetScale() * height / size.Y)
		local boxCf, box = look:GetBoundingBox()
		look:PivotTo(home * CFrame.new(0, box.Y / 2, 0) * boxCf:ToObjectSpace(look:GetPivot()))
		local eyes: { [BasePart]: Color3 } = {}
		for _, d in look:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.Massless = true
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = d
				weld.Parent = d
				if
					d.Name == "Eye"
					or (
						d.Name == (Config.GuardFaceKeys[name] or "k")
						and (
							not Config.GuardFaceMinHeight[name]
							or home:PointToObjectSpace(d.Position).Y / box.Y
								> Config.GuardFaceMinHeight[name]
						)
					)
				then
					eyes[d] = d.Color
				end
			end
		end
		look.Name = "Look"
		look.Parent = model
		return eyes, math.clamp(box.Z / 2, 1.5, 6)
	end

	-- Builds a guardian standing at home (a ground-level CFrame facing the nest). hoardDef =
	-- the zone's Config.Hoards entry (guardian = GuardModels name, parts = part-built kind).
	local function buildGuardian(zoneId: string, hoardDef, home: CFrame): Guardian
		local kind = hoardDef.guardian or "Scarecrow"
		local def = GUARDIANS[hoardDef.parts or kind] or GUARDIANS[kind] or GUARDIANS.Scarecrow
		local height = hoardDef.guardHeight or def.height
		local model = Instance.new("Model")
		model.Name = "Guardian"
		model:SetAttribute("Kind", kind)
		local root = Instance.new("Part")
		root.Name = "Root"
		root.Size = Vector3.one
		root.Transparency = 1
		root.Anchored = true
		root.CanCollide = false
		root.CanQuery = false
		root.CanTouch = false
		root.CFrame = home * CFrame.new(0, 0.5, 0)
		root.Parent = model
		local modelEyes, modelReach = guardLook(kind, height, home, root, model)
		local eyes: { [BasePart]: Color3 } = modelEyes or {}
		-- No model: the part-built kind, scaled to the zone's height.
		local k = height / def.height
		for _, d in modelEyes and {} or def.parts do
			local p = Instance.new("Part")
			if d[1] == "S" then
				p.Shape = Enum.PartType.Ball
			end
			p.Name = d[5] or "Block"
			p.Size = d[2] * k
			-- Classic plastic brick: studs on top, inlets under.
			p.Material = Enum.Material.Plastic
			p.TopSurface = Enum.SurfaceType.Studs
			p.BottomSurface = Enum.SurfaceType.Inlet
			p.Color = d[4]
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CFrame = home * CFrame.new(d[3] * k) * CFrame.Angles(0, 0, d[6] or 0)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
			p.Parent = model
			if d[5] == "Eye" then
				eyes[p] = d[4]
			end
		end
		-- Root is 0.5 over the ground, so the tags float about 2.5 studs over the head.
		local t = math.clamp(height / 17, 0.6, 1.4)
		local sleepTag = tag(
			root,
			"SleepTag",
			"Z z Z",
			C(80, 230, 255),
			UDim2.fromScale(9 * t, 4.5 * t),
			height + 2
		)
		local alertTag =
			tag(root, "AlertTag", "!", C(255, 45, 45), UDim2.fromScale(4 * t, 6 * t), height + 3)
		alertTag.Enabled = false
		model.PrimaryPart = root
		local pos = home.Position
		local look = home.LookVector
		return {
			zone = zoneId,
			model = model,
			root = root,
			eyes = eyes,
			sleepTag = sleepTag,
			alertTag = alertTag,
			reach = modelEyes and modelReach or def.reach * k,
			home = pos,
			homeLook = look,
			pos = pos,
			look = look,
			state = "sleep",
			target = nil,
			wokeAt = 0,
			chaseEnd = 0,
			share = Config.GuardianShare,
			seen = 0,
			walk = 0,
		}
	end

	-- Moves the root: asleep it slumps forward a little; walking it waddles and bobs.
	local function pose(g: Guardian)
		local cf = CFrame.lookAt(g.pos, g.pos + g.look)
		if g.twist and os.clock() < (g.warnUntil or 0) then
			local elapsed = os.clock() - (g.warnStarted or os.clock())
			local lunge = math.clamp(1 - (g.warnUntil - os.clock()) / 0.2, 0, 1)
			cf *= CFrame.new(0, 0, -2 * lunge) * CFrame.Angles(
				math.rad(-15) * math.min(elapsed / 0.5, 1) + math.rad(30) * lunge,
				0,
				0
			)
		elseif g.state == "sleep" then
			cf *= CFrame.Angles(math.rad(-7), 0, 0)
		else
			cf *= CFrame.new(0, math.abs(math.sin(g.walk)) * 0.35, 0) * CFrame.Angles(
				0,
				0,
				math.rad(5) * math.sin(g.walk)
			)
		end
		g.root.CFrame = cf * CFrame.new(0, 0.5, 0)
	end

	local function setAwake(g: Guardian, on: boolean)
		g.sleepTag.Enabled = not on
		g.alertTag.Enabled = on
		for eye, color in g.eyes do
			eye.Material = on and Enum.Material.Neon or Enum.Material.Plastic
			eye.Color = on and C(255, 40, 30) or color
		end
	end

	local function step(g: Guardian, dir: Vector3, length: number, dt: number)
		local p = g.pos + dir * length
		g.pos = V(p.X, groundAt(p.X, p.Z, g.pos.Y), p.Z)
		g.look = dir
		g.walk += dt * 9
		pose(g)
	end

	-- Does the player carry a Hoard pumpkin from this zone's nest?
	local function carriesFrom(player: Player?, zoneId: string): boolean
		for _, p in player and carrying[player] or {} do
			if p:GetAttribute("HoardZone") == zoneId then
				return true
			end
		end
		return false
	end

	local function inOwnBase(player: Player, pos: Vector3): boolean
		local patch = patchOf[player]
		local soil = patch and patch:FindFirstChild("Soil") :: BasePart?
		if not soil then
			return false
		end
		local flat = V(pos.X - soil.Position.X, 0, pos.Z - soil.Position.Z)
		return flat.Magnitude <= math.max(soil.Size.X, soil.Size.Z) / 2 + 4
	end

	local giveUp
	local function wake(g: Guardian, player: Player)
		-- Already after this thief, or busy with another one who still has the loot.
		if
			(g.state == "wake" or g.state == "chase")
			and (g.target == player or carriesFrom(g.target, g.zone))
		then
			return
		end
		if g.target and g.target ~= player then
			giveUp(g, false)
		end
		g.cosmetic = player:GetAttribute("FirstHoardDone") ~= true
		player:SetAttribute("FirstHoardDone", true)
		local full = player:GetAttribute("Wake_" .. g.zone) ~= true
		player:SetAttribute("Wake_" .. g.zone, true)
		g.model:SetAttribute("WakeSeconds", Config.GuardianWake)
		Remotes.wakeEvent:FireAllClients(g.model, full, player)
		g.share = g.cosmetic and math.min(Config.GuardianFirstShare, Config.GuardSpeed[g.zone])
			or Config.GuardSpeed[g.zone]
		g.state = "wake"
		g.debugTarget = false
		g.chasedAt = nil
		g.target = player
		g.wokeAt = os.clock()
		g.nextTwist = os.clock() + Config.GuardTwists.first
		g.twist = nil
		g.chaseEnd = os.clock() + Config.GuardianChaseSeconds
		g.seen = 0
		setAwake(g, true)
	end

	-- escaped = the thief got away with the loot (base, zone edge or time).
	giveUp = function(g: Guardian, escaped: boolean)
		local thief = g.target
		g.target = nil
		if thief then
			local chasing = false
			for _, h in hoards do
				if h.guard.target == thief and h.guard.state == "chase" then
					chasing = true
				end
			end
			thief:SetAttribute("GuardChasing", chasing or nil)
			if not chasing then
				thief:SetAttribute("GuardGap", nil)
			end
		end
		g.twist = nil
		g.state = "return"
		g.alertTag.Enabled = false
		if escaped and g.chasedAt and thief and thief.Parent and carriesFrom(thief, g.zone) then
			Remotes.hoardEvent:FireClient(thief, "safe")
		end
	end

	-- Mystery eggs reuse one opaque MeshPart; the glowing question replaces 168 voxel parts
	-- and their welds per egg. Hatched pets own their client rarity aura.
	function Hoards.look(p: BasePart, hatched: boolean?)
		if hatched or p:GetAttribute("Jack") == true then
			return
		end
		if not hatched and p:GetAttribute("Jack") ~= true and not p:FindFirstChild("PetLook") then
			p.Transparency = 0
			p.Material = Enum.Material.SmoothPlastic
			if not p:FindFirstChild("MysteryTag") then
				local question = Instance.new("BillboardGui")
				question.Name = "MysteryTag"
				question.Size = UDim2.fromOffset(36, 42)
				question.StudsOffsetWorldSpace = Vector3.yAxis * (p.Size.Y / 2 + 0.8)
				question.MaxDistance = 60
				question.LightInfluence = 0
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.Text = "?"
				label.TextColor3 = C(255, 227, 128)
				label.TextStrokeTransparency = 0.3
				label.TextScaled = false
				label.FontFace = Helpers.fontFace("title")
				label.Parent = question
				question.Parent = p
			end
		end
		if p:FindFirstChild("HoardSparkle") then
			return
		end
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "HoardSparkle"
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(C(255, 215, 80))
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new(0.6, 0)
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Rate = 6
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.Parent = p
	end

	local function newPumpkin(h: Hoard): BasePart
		local pets = Config.Zones[h.zone].pets
		local p = makePumpkin(pets[math.random(#pets)], Config.HoardSize)
		p.Name = "HoardPumpkin"
		local range = Config.MysterySizes.nest[table.find(Config.ZoneOrder, h.zone) or 1]
		p.Size *= (range[1] + math.random() * (range[2] - range[1])) / p.Size.Y
		p:SetAttribute("Hoard", true)
		p:SetAttribute("HoardZone", h.zone)
		Hoards.look(p)
		return p
	end

	local function slotCFrame(h: Hoard, i: number, p: BasePart): CFrame
		local a = (i - 1) / Config.HoardCount * math.pi * 2
		return CFrame.new(
			h.nest.X + math.cos(a) * SLOT_R,
			h.top + p.Size.Y / 2 - 0.3,
			h.nest.Z + math.sin(a) * SLOT_R
		) * CFrame.Angles(0, a, 0)
	end

	local function freeSlot(h: Hoard): number?
		for i = 1, Config.HoardCount do
			if not h.slots[i] then
				return i
			end
		end
		return nil
	end

	local function bonk(g: Guardian, thief: Player, thiefRoot: BasePart)
		if
			workspace:GetServerTimeNow() < (thief:GetAttribute("GuardMercyUntil") or 0)
			or workspace:GetServerTimeNow() < (state:GetAttribute("KingTransitionUntil") or 0)
		then
			return
		end
		local stack = carrying[thief] or {}
		for i = #stack, 1, -1 do
			local p = stack[i]
			if p:GetAttribute("HoardZone") ~= g.zone then
				continue
			end
			table.remove(stack, i)
			local expires = workspace:GetServerTimeNow() + Config.GuardLaunch.dropSeconds
			p:SetAttribute("GuardDropUntil", expires)
			dropLoose(
				p,
				thiefRoot.Position + V((i % 3 - 1) * 3, 0, 3),
				Config.GuardLaunch.dropSeconds + 1
			)
			local drop = { hoard = hoards[g.zone], token = p:GetAttribute("LooseToken") }
			guardDrops[p] = drop
			drop.hoard.pending += 1
			task.delay(Config.GuardLaunch.dropSeconds, function()
				if guardDrops[p] ~= drop then
					return
				end
				if p.Parent == loose and p:GetAttribute("LooseToken") == drop.token then
					Hoards.giveBack(p, p.Position, true)
				else
					Hoards.cancelDrop(p)
				end
			end)
		end
		refreshCarry(thief)
		Remotes.hoardEvent:FireClient(thief, "bonk")
		Remotes.ghostPopEvent:FireAllClients(thiefRoot.Position, nil, 0)
		giveUp(g, false)
	end

	-- PatchDebug's old fight action now exercises the normal wake/chase.
	function Hoards.debugFight(player: Player)
		local h = hoards.Zone1
		if not h or not aliveRoot(player) then
			return false
		end
		wake(h.guard, player)
		if h.guard.target == player then
			h.guard.debugTarget = true
			return true
		end
		return false
	end
	function Hoards.cancelFight(player)
		for _, h in hoards do
			if h.guard.target == player then
				giveUp(h.guard, false)
			end
		end
	end
	Services.Players.PlayerRemoving:Connect(Hoards.cancelFight)
	local seat -- forward: grab and seat refer to each other through the prompt

	function Hoards.wakeLoose(player, p)
		local h = hoards[p:GetAttribute("HoardZone")]
		if h then
			wake(h.guard, player)
		end
	end

	function Hoards.inReach(root: BasePart, p: BasePart): boolean
		local delta = p.Position - root.Position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		if
			math.abs(delta.Y) >= 8
			or flat.Magnitude > 9
			or (flat.Magnitude >= 0.1 and flat.Unit:Dot(root.CFrame.LookVector) < 0.57)
		then
			return false
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { root.Parent, p }
		return workspace:Raycast(root.Position, delta, params) == nil
	end

	local function grab(h: Hoard, p: BasePart, player: Player)
		local i = nil
		for k = 1, Config.HoardCount do
			if h.slots[k] == p then
				i = k
			end
		end
		if not i or p.Parent ~= h.model then
			return
		end
		if not Helpers.isLoaded(player) then
			Remotes.hintEvent:FireClient(player, "Loading your farm...")
			return
		end
		if not hasZone(player, h.zone) or not aliveRoot(player) then
			return
		end
		if #(carrying[player] or {}) >= Helpers.carryCapacity(player) then
			Remotes.hintEvent:FireClient(
				player,
				"Your hands are full! Place what you carry on your base first."
			)
			return
		end
		local _, root = aliveRoot(player)
		if not root or not Hoards.inReach(root, p) then
			return
		end
		local at = p.Position
		h.slots[i] = nil
		if not stackPumpkin(player, p) then
			h.slots[i] = p
			return
		end
		Remotes.harvestedEvent:FireAllClients(player, at)
		Remotes.hoardEvent:FireClient(player, "grab", p:GetAttribute("Seed"))
		if player:GetAttribute("FirstGrabPets") ~= true then
			player:SetAttribute("FirstGrabPets", true)
			Remotes.hintEvent:FireClient(player, "Steal = PETS!")
		end
		Progress.quest(player, h.zone, "steal", 1)
		track(player, "hoardSteal", 1)
		wake(h.guard, player)
	end

	-- Swing and tap share the same server checks.
	function Hoards.swing(player: Player, root: BasePart): boolean
		local nearest, nest, distance = nil, nil, math.huge
		for _, h in hoards do
			if not hasZone(player, h.zone) then
				continue
			end
			for _, p in h.slots do
				local d = (p.Position - root.Position).Magnitude
				if d < distance and Hoards.inReach(root, p) then
					nearest, nest, distance = p, h, d
				end
			end
		end
		if not nearest then
			return false
		end
		grab(nest, nearest, player)
		return nearest.Parent ~= nest.model
	end

	function seat(h: Hoard, i: number, p: BasePart)
		h.slots[i] = p
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = slotCFrame(h, i, p)
		p.Parent = h.model
		local seed = Lookup.seedById[p:GetAttribute("Seed") or ""]
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealPrompt"
		prompt.ActionText = "Steal"
		prompt.ObjectText = (seed and seed.name or "") .. " pumpkin · Hoard"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = true
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
		prompt.Parent = p
		prompt.Triggered:Connect(function(player)
			grab(h, p, player)
		end)
	end

	-- A Hoard pumpkin leaves a player (bonk, drop, death, Haunt): HoardReturnDelay seconds later a
	-- new one arcs from there back into a free slot of its nest.
	function Hoards.giveBack(p: BasePart, at: Vector3, immediate: boolean?)
		Hoards.cancelDrop(p)
		local h = hoards[p:GetAttribute("HoardZone") or ""]
		p:Destroy()
		if not h then
			return
		end
		h.pending += 1
		task.delay(immediate and 0 or Config.HoardReturnDelay, function()
			h.pending -= 1
			local i = freeSlot(h)
			if not i then
				return
			end
			local np = newPumpkin(h)
			np.Anchored = true
			np.CanCollide = false
			local from = at + V(0, 2, 0)
			np.CFrame = CFrame.new(from)
			np.Parent = h.model
			-- Reserved while it flies (no prompt yet, so nobody can take it mid-air).
			h.slots[i] = np
			local goal = slotCFrame(h, i, np)
			local started = os.clock()
			while np.Parent == h.model and os.clock() - started < 1.2 do
				local f = (os.clock() - started) / 1.2
				np.CFrame =
					CFrame.new(from:Lerp(goal.Position, f) + V(0, math.sin(f * math.pi) * 14, 0))
				task.wait()
			end
			if np.Parent == h.model and h.slots[i] == np then
				seat(h, i, np)
				Remotes.harvestedEvent:FireAllClients(nil, np.Position)
			end
		end)
	end

	-- Every second (main loop): one pumpkin back every HoardRefill seconds while a nest is short.
	function Hoards.tick()
		local t = os.clock()
		for _, h in hoards do
			local filled = 0
			for i = 1, Config.HoardCount do
				if h.slots[i] then
					filled += 1
				end
			end
			if filled + h.pending >= Config.HoardCount then
				h.nextRefill = t + Config.HoardRefill
			elseif t >= h.nextRefill then
				local i = freeSlot(h)
				if i then
					local p = newPumpkin(h)
					seat(h, i, p)
					Remotes.harvestedEvent:FireAllClients(nil, p.Position)
				end
				h.nextRefill = t + Config.HoardRefill
			end
		end
	end

	-- Midnight reset: every nest is filled up at once (Steal an Egg "ALL EGG RESET!").
	function Hoards.refillAll()
		for _, h in hoards do
			local available = Config.HoardCount - h.pending
			for _, p in h.slots do
				if p then
					available -= 1
				end
			end
			for i = 1, Config.HoardCount do
				if not h.slots[i] and available > 0 then
					local p = newPumpkin(h)
					seat(h, i, p)
					available -= 1
					Remotes.harvestedEvent:FireAllClients(nil, p.Position)
				end
			end
			h.nextRefill = os.clock() + Config.HoardRefill
		end
	end

	local function twist(g, h, player, root)
		local cfg = Config.GuardTwists[g.zone]
		if
			not cfg
			or g.twist
			or os.clock() < (g.nextTwist or math.huge)
			or g.state ~= "chase"
			or os.clock() - (g.chasedAt or os.clock()) < Config.GuardTwists.minChase
			or (root.Position - g.pos).Magnitude < Config.GuardTwists.minDist
			or (root.Position - g.pos).Magnitude > Config.GuardTwists.maxDist
			or os.clock() < (g.windedUntil or 0)
			or workspace:GetServerTimeNow() < (player:GetAttribute("GuardMercyUntil") or 0)
		then
			return
		end
		local token = {}
		g.twist = token
		g.warnStarted = os.clock()
		g.warnUntil = os.clock() + cfg.warn
		g.nextTwist = os.clock() + cfg.cooldown
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local direction = hum and hum.MoveDirection or Vector3.zero
		local velocity =
			Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
		local motion = direction.Magnitude > 0.1 and direction * (hum and hum.WalkSpeed or 16)
			or velocity
		if direction.Magnitude < 0.1 and velocity.Magnitude > 1 then
			direction = velocity.Unit
		end
		if direction.Magnitude < 0.1 then
			direction = root.CFrame.LookVector
		end
		direction = Vector3.new(direction.X, 0, direction.Z).Unit
		local pos = Vector3.new(root.Position.X, h.top, root.Position.Z)
		local shapes = {}
		if cfg.kind == "Bone" or cfg.kind == "Boulder" then
			local origin = Vector3.new(g.pos.X, h.top, g.pos.Z)
			local aim = Vector3.new(pos.X - origin.X, 0, pos.Z - origin.Z)
			aim = aim.Magnitude > 0.1 and aim.Unit or direction
			for i = 1, cfg.lanes or 1 do
				local angle = cfg.kind == "Boulder"
						and (i == 1 and -1 or 1) * math.rad(cfg.fanAngle)
					or 0
				local dir = CFrame.Angles(0, angle, 0):VectorToWorldSpace(aim)
				local at = origin + dir * cfg.length / 2
				table.insert(shapes, {
					pos = at,
					cf = CFrame.lookAt(at, at + dir),
					width = cfg.width,
					length = cfg.length,
					origin = origin,
					direction = dir,
				})
			end
		else
			if cfg.predict then
				pos += motion * cfg.predict
			end
			if cfg.ahead then
				pos += direction * cfg.ahead
			end
			for i = 1, cfg.puddles or 1 do
				table.insert(
					shapes,
					{ pos = pos + direction * ((i - 1) * (cfg.spacing or 0)), radius = cfg.radius }
				)
			end
		end
		-- Each nearby client plays its own short effect, separate from the wake roar.
		for _, nearby in Services.Players:GetPlayers() do
			local _, nearbyRoot = aliveRoot(nearby)
			if
				nearbyRoot
				and (nearbyRoot.Position - g.pos).Magnitude <= Config.GuardTwists.soundRange
			then
				Remotes.telegraphEvent:FireClient(
					nearby,
					"Guard:" .. cfg.kind,
					shapes,
					cfg.warn,
					cfg.sound,
					cfg.lifetime,
					cfg.pitch,
					{ victim = player, origin = g.root.Position, color = cfg.color }
				)
			end
		end
		task.spawn(function()
			task.wait(cfg.warn)
			local hit = false
			local function valid()
				return g.twist == token
					and g.target == player
					and g.state == "chase"
					and carriesFrom(player, g.zone)
					and player.Parent
					and aliveRoot(player)
					and not g.cosmetic
			end
			local function effect(victim, r)
				if
					r.Position.Z < Lane.safeZ
					or inOwnBase(victim, r.Position)
					or (
						cfg.kind ~= "Sticky"
						and workspace:GetServerTimeNow()
							< (victim:GetAttribute("GuardMercyUntil") or 0)
					)
				then
					return
				end
				victim:SetAttribute(
					"GuardMercyUntil",
					workspace:GetServerTimeNow() + Config.GuardTwists.mercy
				)
				hit = true
				if cfg.kind == "Root" then
					victim:SetAttribute(
						"GuardMercyUntil",
						workspace:GetServerTimeNow() + cfg.seconds + Config.GuardTwists.mercy
					)
				elseif cfg.kind == "Crow" then
					Remotes.stompEvent:FireAllClients(
						"GuardCrow",
						{ { pos = r.Position, radius = 6 } }
					)
				end
				if cfg.slow then
					Progress.slow(victim, cfg.slow, cfg.seconds, cfg.slow == 0 and "ROOT" or "SLOW")
				end
				if cfg.push then
					local out = Vector3.new(r.Position.X - g.pos.X, 0, r.Position.Z - g.pos.Z)
					out = out.Magnitude > 0.1 and out.Unit or direction
					local at = r.Position + out * cfg.push
					if at.Z >= Lane.safeZ then
						r.CFrame += out * cfg.push
					end
					if cfg.kind == "Boulder" then
						Progress.slow(victim, cfg.slow, cfg.seconds, "DIZZY")
					end
				elseif cfg.pull then
					local to = Vector3.new(h.nest.X - r.Position.X, 0, h.nest.Z - r.Position.Z)
					if to.Magnitude > 0.1 then
						r.CFrame += to.Unit * math.min(cfg.pull, to.Magnitude)
					end
				end
			end
			if valid() then
				if cfg.kind == "Bat" then
					local at = shapes[1].pos
					if
						(at - g.pos).Magnitude <= 24
						and at.Z >= math.max(Lane.safeZ, h.zMin)
						and at.Z <= h.zMax
					then
						g.pos = Vector3.new(at.X, g.pos.Y, at.Z)
						pose(g)
						Remotes.stompEvent:FireAllClients("GuardBat", shapes)
					end
					Progress.landAttack(shapes, player, effect)
				elseif cfg.kind == "Sticky" then
					local ends = os.clock() + cfg.lifetime
					while valid() and os.clock() < ends do
						Progress.landAttack(shapes, player, effect)
						task.wait(Config.GuardTwists.effectTick)
					end
				elseif cfg.kind == "Boulder" then
					local travelled = 0
					while valid() and travelled < cfg.length do
						local moving = {}
						for _, lane in shapes do
							local at = lane.origin + lane.direction * travelled
							table.insert(moving, {
								pos = at,
								cf = CFrame.lookAt(at, at + lane.direction),
								width = cfg.width,
								length = cfg.width,
							})
						end
						Progress.landAttack(moving, player, effect)
						travelled += cfg.speed * Config.GuardTwists.effectTick
						task.wait(Config.GuardTwists.effectTick)
					end
				else
					Progress.landAttack(shapes, player, effect)
				end
			end
			if g.twist == token then
				g.twist = nil
				if not hit then
					g.windedUntil = os.clock() + 1
				end
				pose(g)
			end
		end)
	end
	Services.RunService.Heartbeat:Connect(function(dt)
		local busy = false
		for _, h in hoards do
			if h.guard.state ~= "sleep" then
				busy = true
				break
			end
		end
		if not busy then
			return
		end
		refreshRayFilter()
		local now = os.clock()
		for _, h in hoards do
			local g = h.guard
			if
				workspace:GetAttribute("PatchDebug") == true
				and (g.loggedState ~= g.state or workspace:GetAttribute("WatchGuard") == true)
			then
				print(
					"[Patch Guardian]",
					g.zone,
					now,
					g.state,
					g.target and g.target.UserId,
					g.pos.Z,
					h.zMin,
					h.zMax
				)
				g.loggedState = g.state
			end
			if g.state == "wake" or g.state == "chase" then
				local thief = g.target
				local thiefRoot: BasePart? = nil
				if thief and thief.Parent then
					local _, r = aliveRoot(thief)
					thiefRoot = r
				end
				if
					not thief
					or not thiefRoot
					or (not g.debugTarget and not carriesFrom(thief, h.zone))
				then
					giveUp(g, false)
				else
					local at = thiefRoot.Position
					thief:SetAttribute("GuardGap", math.floor((at - g.pos).Magnitude))
					if
						(g.state == "chase" and now - g.chasedAt >= Config.GuardLaunch.minChase)
						and (now >= g.chaseEnd or inOwnBase(thief, at) or at.Z < Lane.safeZ)
					then
						giveUp(g, true)
					else
						if
							g.state == "chase"
							and at.Z >= Lane.safeZ
							and not inOwnBase(thief, at)
						then
							twist(g, h, thief, thiefRoot)
						end
						local to = V(at.X - g.pos.X, 0, at.Z - g.pos.Z)
						if to.Magnitude > 0.1 then
							g.look = to.Unit
						end
						if g.twist or now < (g.windedUntil or 0) then
							pose(g)
						elseif g.state == "wake" then
							-- A short grace while it gets up and roars.
							if
								now - g.wokeAt
								>= (g.model:GetAttribute("WakeSeconds") or Config.GuardianWake)
							then
								g.state = "chase"
								g.chasedAt = now
								g.chaseEnd = now + Config.GuardianChaseSeconds
								thief:SetAttribute("GuardChasing", true)
							end
							pose(g)
						elseif
							to.Magnitude <= Config.GuardianCatch + g.reach
							and not g.cosmetic
							and now - g.chasedAt >= Config.GuardLaunch.minChase
							and at.Z >= Lane.safeZ
							and not inOwnBase(thief, at)
						then
							bonk(g, thief, thiefRoot)
						else
							local top = Config.walkSpeed(Helpers.upgradeLevel(thief, "Boots"))
								* (
									thief:GetAttribute("Sprinting")
										and Config.Movement.sprintMult
									or 1
								)
							local running = math.max(
								Config.MinCarrySpeed,
								top - #(carrying[thief] or {}) * Config.SlowPerPumpkin
							)
							local velocity = thiefRoot.AssemblyLinearVelocity
							local observed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
							local speed = g.share
								* math.max(running, math.min(observed, running * 1.25 + 6))
							step(
								g,
								to.Magnitude > 0.1 and to.Unit or g.look,
								math.min(speed * dt, to.Magnitude),
								dt
							)
						end
					end
				end
			end
			if g.state == "return" then
				local to = V(g.home.X - g.pos.X, 0, g.home.Z - g.pos.Z)
				if to.Magnitude <= 0.6 then
					g.pos = g.home
					g.look = g.homeLook
					g.state = "sleep"
					setAwake(g, false)
					pose(g)
				else
					step(g, to.Unit, math.min(Config.GuardianReturnSpeed * dt, to.Magnitude), dt)
				end
			end
		end
	end)

	local function buildHoard(zoneId: string, zone: Instance, def: { [string]: any })
		local spawns: { BasePart } = {}
		for _, d in zone:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Spawn" then
				table.insert(spawns, d)
			end
		end
		local lane = Lane.zone(zoneId)
		local center: Vector3? = lane and lane.center
		local spot: Vector3? = nil
		local marker = zone:FindFirstChild("Hoard")
		if marker and (marker:IsA("Model") or marker:IsA("BasePart")) then
			-- The map's Hoard marker (the nest cluster centre) picks the spot.
			spot = (marker :: PVInstance):GetPivot().Position
			marker:Destroy()
		elseif center then
			-- No marker: the zone centre, HoardOutward studs toward the +X wall.
			spot = center + V(Config.HoardOutward, 0, 0)
		elseif spawns[1] then
			spot = spawns[1].Position
		end
		if not spot then
			warn("[Patch] No spot for the Hoard in " .. zoneId)
			return
		end
		-- Ground: the bottom of the nearest Spawn part (spawns sit on the zone floor), else a
		-- long ray; then a short ray refines it.
		refreshRayFilter()
		local groundY: number? = nil
		local nearest = math.huge
		for _, sp in spawns do
			local d = V(sp.Position.X - spot.X, 0, sp.Position.Z - spot.Z).Magnitude
			if d < nearest then
				nearest, groundY = d, sp.Position.Y - sp.Size.Y / 2
			end
		end
		if not groundY then
			local hit = workspace:Raycast(V(spot.X, 300, spot.Z), V(0, -600, 0), rayParams)
			groundY = hit and hit.Position.Y or 0
		end
		local y = groundAt(spot.X, spot.Z, groundY :: number)
		local nest = V(spot.X, y, spot.Z)

		local model = Instance.new("Model")
		model.Name = "Hoard"
		model:SetAttribute("Zone", zoneId)
		-- Straw nest: a dark woven ring, a lighter straw fill and chunky sticks on the rim.
		local function disc(name: string, diameter: number, height: number, color: Color3): Part
			local p = Instance.new("Part")
			p.Name = name
			p.Shape = Enum.PartType.Cylinder
			p.Size = V(height, diameter, diameter)
			p.CFrame = CFrame.new(nest + V(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
			p.Material = Enum.Material.Plastic
			p.Color = color
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Parent = model
			return p
		end
		local base = disc("Nest", NEST_R * 2, 1.6, C(125, 82, 38))
		disc("Straw", NEST_R * 2 - 2.2, 1.75, C(214, 172, 80))
		for k = 1, 8 do
			local a = k / 8 * math.pi * 2 + math.random() * 0.3
			local stick = Instance.new("Part")
			stick.Name = "Straw"
			stick.Size = V(0.4, 0.4, 3.2)
			stick.Material = Enum.Material.Plastic
			stick.Color = k % 2 == 0 and C(190, 140, 60) or C(235, 195, 95)
			stick.Anchored = true
			stick.CanCollide = false
			stick.CanQuery = false
			stick.CanTouch = false
			stick.CFrame = CFrame.new(
				nest + V(math.cos(a) * (NEST_R - 0.6), 1.55, math.sin(a) * (NEST_R - 0.6))
			) * CFrame.Angles(
				0,
				-a + (math.random() - 0.5) * 0.8,
				math.rad(math.random(-15, 15))
			)
			stick.Parent = model
		end
		local light = Instance.new("PointLight")
		light.Color = C(255, 200, 80)
		light.Range = 14
		light.Brightness = 1.5
		light.Shadows = false
		light.Parent = base
		tag(base, "HoardSign", "🐾 PETS", C(255, 214, 80), UDim2.fromScale(9, 2.2), 7)

		-- The guardian sleeps beside the nest on the lane's centre side (toward the hub when the
		-- nest is on the centre line), facing it; bigger guardians stand a little farther off.
		local dx = Lane.x - nest.X
		local dir = math.abs(dx) > 4 and V(math.sign(dx), 0, 0) or V(0, 0, -1)
		local side = nest + dir * (9 + (def.guardHeight or 17) * 0.15)
		local homePos = V(side.X, groundAt(side.X, side.Z, y), side.Z)
		local toNest = V(nest.X - homePos.X, 0, nest.Z - homePos.Z).Unit
		local guard = buildGuardian(zoneId, def, CFrame.lookAt(homePos, homePos + toNest))
		guard.model.Parent = model

		-- Leash: the zone's Z range (checked with Config.HoardLeashPad in the chase).
		local zMin = lane and lane.zMin or nest.Z - 80
		local zMax = lane and lane.zMax or nest.Z + 80

		-- No wild pumpkins under the nest or the guardian.
		for _, sp in spawns do
			local p = sp.Position
			if
				V(p.X - nest.X, 0, p.Z - nest.Z).Magnitude <= 9
				or V(p.X - homePos.X, 0, p.Z - homePos.Z).Magnitude <= 9
			then
				sp:SetAttribute("HoardNear", true)
			end
		end
		Wild.clearNear(nest, 9)
		Wild.clearNear(homePos, 9)

		local h: Hoard = {
			zone = zoneId,
			model = model,
			nest = nest,
			top = y + 1.75,
			slots = {},
			pending = 0,
			nextRefill = os.clock() + Config.HoardRefill,
			zMin = zMin,
			zMax = zMax,
			guard = guard,
		}
		for i = 1, Config.HoardCount do
			seat(h, i, newPumpkin(h))
		end
		model.Parent = zone
		hoards[zoneId] = h
		-- Slump into the sleeping pose only now: welds hold their build-time offsets once the
		-- model is in the workspace.
		pose(guard)
	end

	task.spawn(function()
		local zones = garden:WaitForChild("Zones", 10)
		if not zones then
			return
		end
		for _, zoneId in Config.ZoneOrder do
			local def = Config.Hoards and Config.Hoards[zoneId]
			local zone = zones:FindFirstChild(zoneId)
			if def and zone and Lookup.seedById[def.type] then
				local ok, err = pcall(buildHoard, zoneId, zone, def)
				if not ok then
					warn("[Patch] Could not build the Hoard in " .. zoneId .. ":", err)
				end
			end
		end
		task.defer(Wild.fill)
	end)
end

-- Cauldrons and the Witch ---------------------------------------------------------------------

for _, cauldron in cauldronFolder:GetChildren() do
	local pot = cauldron:FindFirstChild("Pot") :: BasePart
	local brew = cauldron:FindFirstChild("Brew") :: BasePart
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Brew"
	prompt.ObjectText = "Magic Cauldron"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = pot
	prompt.Triggered:Connect(function(player)
		-- Brewing opens later (Config.Unlocks.Brew); the client hides the prompt until then.
		if not Unlock.has(player, "Brew") then
			return
		end
		local stack = carrying[player] or {}
		local results = {}
		for _, pumpkin in stack do
			if not pumpkin:GetAttribute("Mutation") then
				local id = brewPumpkin(player, pumpkin, true)
				table.insert(results, { id = id, value = pumpkinValue(pumpkin) })
				if id == "Cursed" then
					Reveal.send(player, pumpkin, false)
				end
			end
		end
		if #stack == 0 then
			Remotes.hintEvent:FireClient(
				player,
				"Steal a glowing pumpkin first, then brew it here."
			)
			return
		elseif #results == 0 then
			Remotes.hintEvent:FireClient(
				player,
				"These are already magic! Place them on your base or sell them to the Witch."
			)
			return
		end
		refreshCarry(player)
		Remotes.brewedEvent:FireAllClients(player, brew.Position, results)
		track(player, "brew", 1)
	end)
end

-- Giant Jack: goal = max(scaled base, JackIncomeMult x sales in the last minute). The Blood
-- Moon waits at least BloodMoonGap seconds after the last one (and after server start).
local incomeLog: { { t: number, amount: number } } = {}

local jackGoal
do
	local function recentIncome(): number
		local now = os.clock()
		local sum = 0
		for i = #incomeLog, 1, -1 do
			local entry = incomeLog[i]
			if now - entry.t > 60 then
				table.remove(incomeLog, i)
			else
				sum += entry.amount
			end
		end
		return sum
	end

	-- Farmers are counted by owned patches: a leaving player's patch is released at the start of
	-- PlayerRemoving (they are still in GetPlayers then), and kicked "server full" players own none.
	function jackGoal(): number
		local base = state:GetAttribute("JackBase") or Config.JackGoal
		local scaled =
			math.floor(base * (1 + Config.JackPerPlayer * math.max(ownedPatchCount() - 1, 0)))
		return math.max(scaled, math.floor(Config.JackIncomeMult * recentIncome()))
	end
end

local function setKingWakes()
	local now = workspace:GetServerTimeNow()
	local hour = math.floor(now / 3600) * 3600
	local nextTime = hour + 3600
	for _, minute in Config.KingNight.minutes do
		local at = hour + minute * 60
		if at > now then
			nextTime = math.min(nextTime, at)
		end
	end
	state:SetAttribute("KingWakesAt", nextTime)
end

state:SetAttribute("JackBase", Config.JackGoal)
state:SetAttribute("JackCandy", 0)
state:SetAttribute("JackGoal", jackGoal())
setKingWakes()

local startBloodMoon -- forward

local function recomputeJack()
	local goal = jackGoal()
	state:SetAttribute("JackGoal", goal)
	if state:GetAttribute("Phase") == "BloodMoon" then
		return
	end
	local filled = math.min(state:GetAttribute("JackCandy") or 0, goal)
	state:SetAttribute("JackCandy", filled)
	-- King Night is clock-scheduled.
end

local sellStall = market:WaitForChild("Sell")
do
	local promptPart = sellStall:FindFirstChild("PromptPart") :: BasePart
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Sell"
	prompt.ObjectText = "Witch"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart
	prompt.Triggered:Connect(function(player)
		if not Helpers.isLoaded(player) then
			Remotes.hintEvent:FireClient(player, "Loading your farm...")
			return
		end
		-- The Witch opens later (Config.Unlocks.Sell); the client hides the prompt until then.
		if not Unlock.has(player, "Sell") then
			return
		end
		local stack = carrying[player] or {}
		if #stack == 0 then
			Remotes.hintEvent:FireClient(player, "Pick up a pet from your pen to sell it here.")
			return
		end
		for _, p in stack do
			if not Purge.deliveryReady(player, p) then
				return
			end
		end
		local total, count, raw = Helpers.sellQuote(player), 0, 0
		local found = indexOf[player] or {}
		indexOf[player] = found
		local news = {}
		local bySeed, byMutation = {}, {}
		local brewed = 0
		for _, pumpkin in stack do
			if pumpkin.Parent then
				local seedId = pumpkin:GetAttribute("Seed")
				local finish = pumpkin:GetAttribute("Mutation") or "Plain"
				-- Quote computed before Index changes or destruction.
				local key = seedId .. ":" .. finish
				if not found[key] then
					found[key] = true
					table.insert(news, key)
				end
				if finish == "Cursed" then
					Remotes.announceEvent:FireAllClients(
						string.format(
							"%s sold a CURSED %s pumpkin!",
							player.DisplayName,
							Lookup.seedById[seedId].name
						)
					)
				end
				if not pumpkin:GetAttribute("Mutation") then
					raw += 1
				else
					brewed += 1
				end
				bySeed[seedId] = (bySeed[seedId] or 0) + 1
				byMutation[finish] = (byMutation[finish] or 0) + 1
				count += 1
				pumpkin:Destroy()
			end
		end
		carrying[player] = {}
		refreshCarry(player)
		total = addCandy(player, total, true, true)
		table.insert(incomeLog, { t = os.clock(), amount = total })
		Remotes.soldEvent:FireAllClients(player, promptPart.Position, total, count, raw)
		if #news > 0 then
			publishIndex(player)
			Remotes.indexEvent:FireClient(player, news)
		end
		if state:GetAttribute("Phase") ~= "BloodMoon" then
			state:SetAttribute("JackCandy", (state:GetAttribute("JackCandy") or 0) + total)
		end
		recomputeJack()
		track(player, "sell", count)
		for seedId, n in bySeed do
			track(player, "sellSeed:" .. seedId, n)
		end
		for finish, n in byMutation do
			track(player, "sellMutation:" .. finish, n)
		end
		if count >= 5 then
			track(player, "sellStackOf5", 1)
		end
		if #news > 0 then
			track(player, "newIndex", #news)
		end
		if brewed > 0 then
			track(player, "sellBrewed", brewed)
		end
	end)
end

-- The old Seeds stall is the tool shop now: its prompt and signs are renamed here. Both stalls
-- open the one Shop panel, on its Scythes or Upgrades tab.
for _, kind in { "Seeds", "Upgrades" } do
	local stall = market:WaitForChild(kind)
	local tools = kind == "Seeds"
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop"
	prompt.ObjectText = tools and "Scythes" or "Upgrades"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = stall:FindFirstChild("PromptPart")
	prompt.Triggered:Connect(function(player)
		Remotes.shopEvent:FireClient(player, tools and "Tools" or "Upgrades")
	end)
	-- Both stalls read SHOP: one shop, two tabs.
	for _, d in stall:GetDescendants() do
		if d:IsA("TextLabel") then
			local up = string.upper(d.Text)
			if string.find(up, "SEED") or string.find(up, "TOOLS") then
				d.Text = "🛒 SHOP"
			end
		end
	end
end

-- Stall title billboards ("Sign" BillboardGuis on the stall anchors named Sign*) are 20 %
-- smaller, so the left HUD pills never cover their text. Once per billboard (attribute guard).
do
	local function shrinkSign(d: Instance)
		if
			d:IsA("BillboardGui")
			and d.Name == "Sign"
			and d.Parent
			and string.sub(d.Parent.Name, 1, 4) == "Sign"
			and not d:GetAttribute("Shrunk")
		then
			d:SetAttribute("Shrunk", true)
			local s = d.Size
			d.Size = UDim2.new(s.X.Scale * 0.8, s.X.Offset * 0.8, s.Y.Scale * 0.8, s.Y.Offset * 0.8)
		end
	end
	for _, d in market:GetDescendants() do
		shrinkSign(d)
	end
	market.DescendantAdded:Connect(shrinkSign)
end

local giveTool -- defined with the scythe builder below

Remotes.buyToolFunction.OnServerInvoke = function(player: Player, id: unknown)
	local tool = type(id) == "string" and Lookup.toolById[id]
	if not tool or not tool.cost then
		return false, "?"
	end
	if not Helpers.isLoaded(player) then
		return false, "Loading"
	end
	local owned = toolsOf[player]
	if not owned then
		return false, "Loading"
	elseif owned[tool.id] then
		return false, "Owned"
	elseif tool.damage <= bestTool(player).damage then
		return false, "Have better"
	end
	local candy = Helpers.candyValue(player)
	if not candy or candy.Value < tool.cost then
		return false, "Need " .. Helpers.short(tool.cost)
	end
	candy.Value -= tool.cost
	owned[tool.id] = true
	publishTools(player)
	giveTool(player)
	track(player, "buyTool", 1)
	return true
end

Remotes.buyUpgradeFunction.OnServerInvoke = function(player: Player, id: unknown)
	local info = type(id) == "string" and Config.Upgrades[id]
	if not info or info.cut then
		return false, "?"
	end
	if id == "Lucky" and not Unlock.has(player, "LuckySwing") then
		return false, "Locked"
	end
	if not Helpers.isLoaded(player) then
		return false, "Loading"
	end
	local level = Helpers.upgradeLevel(player, id :: string)
	if level >= info.max then
		return false, "MAX"
	end
	local cost = Config.upgradeCost(id, level)
	local candy = Helpers.candyValue(player)
	if not candy or candy.Value < cost then
		return false, "Need " .. Helpers.short(cost)
	end
	candy.Value -= cost
	player:SetAttribute("Up_" .. (id :: string), level + 1)
	if id == "Stack" then
		refreshCarry(player)
	end
	track(player, "upgrade", 1)
	track(player, "upgrade:" .. (id :: string), 1)
	return true
end

Remotes.lockEvent.OnServerEvent:Connect(function(player)
	Bases.lock(player)
end)

-- Drop button: only nest/stolen items leave the stack (stolen ones keep their
-- owner, so the owner picking them up gets them back for free).
Remotes.dropEvent.OnServerEvent:Connect(function(player)
	local stack = carrying[player]
	local character, root = aliveRoot(player)
	if not stack or #stack == 0 or not character or not root then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, loose, ghostFolder }
	params.RespectCanCollide = true
	for i = #stack, 1, -1 do
		local p = stack[i]
		if not p:GetAttribute("HoardZone") and not p:GetAttribute("StolenFrom") then
			continue
		end
		local a = i / #stack * math.pi * 2
		table.remove(stack, i)
		local at = root.Position + Vector3.new(math.cos(a) * 3.5, 0, math.sin(a) * 3.5)
		if p:GetAttribute("HoardZone") then
			-- A dropped Hoard pumpkin flies back to its nest.
			Hoards.giveBack(p, at)
		else
			local hit = workspace:Raycast(at + Vector3.new(0, 3, 0), Vector3.new(0, -40, 0), params)
			dropLoose(
				p,
				at,
				Config.LooseSeconds,
				false,
				hit and hit.Position.Y or root.Position.Y - 3
			)
		end
	end
	refreshCarry(player)
end)

-- Haunt (rebirth) and the Soul skill tree -----------------------------------------------------

do
	Remotes.hauntFunction.OnServerInvoke = function(player: Player)
		return Progress.rebirth(player)
	end
end

Remotes.buySkillFunction.OnServerInvoke = function(player: Player, id: unknown)
	local skill = type(id) == "string" and Lookup.skillById[id]
	if not skill then
		return false, "?"
	end
	if not Helpers.isLoaded(player) then
		return false, "Loading"
	end
	if hasSkill(player, skill.id) then
		return false, "Owned"
	end
	local before = Lookup.skillAt[skill.branch .. ":" .. (skill.tier - 1)]
	if before and not hasSkill(player, before.id) then
		return false, "Locked"
	end
	local souls = player:GetAttribute("Souls") or 0
	if souls < skill.cost then
		return false, "Need " .. skill.cost
	end
	local owned = skillsOf[player] or {}
	skillsOf[player] = owned
	owned[skill.id] = true
	player:SetAttribute("Souls", souls - skill.cost)
	publishSkills(player)
	return true
end

-- Ghosts ---------------------------------------------------------------------------------------

type Ghost = {
	model: Model,
	root: BasePart,
	hp: number,
	target: BasePart?,
	plot: BasePart?,
	carried: BasePart?,
	home: Vector3,
	fleeing: boolean,
	bob: number,
	lackey: boolean?,
	-- Value of the pumpkin this ghost went for: caps its bonk bounty.
	bait: number?,
}
local ghosts: { Ghost } = {}

-- Ghost light, trail and wisp, on the root Part named Body.
local function dressGhost(body: BasePart, lackey: boolean?)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = body
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -2.5, 0)
	a1.Parent = body
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.6
	trail.Color =
		ColorSequence.new(lackey and Color3.fromRGB(255, 170, 80) or Color3.fromRGB(200, 220, 255))
	trail.Transparency = NumberSequence.new(0.6, 1)
	trail.LightEmission = 0.6
	trail.Parent = body
	local light = Instance.new("PointLight")
	light.Color = lackey and Color3.fromRGB(255, 160, 60) or Color3.fromRGB(207, 232, 255)
	light.Range = lackey and 12 or 8
	light.Brightness = 1.6
	light.Shadows = false
	light.Parent = body
	local wisp = Instance.new("ParticleEmitter")
	wisp.Texture = "rbxasset://textures/particles/smoke_main.dds"
	wisp.Color = ColorSequence.new(Color3.fromRGB(210, 230, 255))
	wisp.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	wisp.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3) })
	wisp.Lifetime = NumberRange.new(0.8, 1.2)
	wisp.Rate = 10
	wisp.Speed = NumberRange.new(0.5, 1)
	wisp.Parent = body
end

-- The free ghost mesh (ServerStorage.PolishAssets.GhostMesh), scaled to about 5.5 studs tall and
-- welded to an invisible anchored root named Body that the ghost loop moves each frame.
-- Returns nil when the asset is missing so the ball ghost below is used instead.
local function buildMeshGhost(at: Vector3, lackey: boolean?): (Model?, BasePart?)
	local assets = Services.ServerStorage:FindFirstChild("PolishAssets")
	local source = assets and assets:FindFirstChild("GhostMesh")
	if not source or not source:IsA("Model") then
		return nil, nil
	end
	local mesh = source:Clone()
	for _, d in mesh:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local _, size = mesh:GetBoundingBox()
	if size.Y <= 0 then
		mesh:Destroy()
		return nil, nil
	end
	mesh:ScaleTo(mesh:GetScale() * 5.5 / size.Y)
	local center, scaled = mesh:GetBoundingBox()
	mesh:PivotTo(mesh:GetPivot() + (at - center.Position))
	local model = Instance.new("Model")
	model.Name = "Ghost"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(math.max(scaled.X, 2), scaled.Y, math.max(scaled.Z, 2))
	body.Transparency = 1
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.CastShadow = false
	body.CFrame = CFrame.new(at)
	body.Parent = model
	local orange = Color3.fromRGB(255, 150, 50)
	-- Normal ghosts are tinted white (blocky style pass). A textured mesh ignores Color, so the
	-- texture of bright parts is dropped too, but only when the eyes are their own dark parts (else
	-- the eyes live in the texture and it is kept).
	local white = Color3.fromRGB(245, 247, 255)
	local darkParts = false
	for _, d in mesh:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local _, _, v = d.Color:ToHSV()
			darkParts = darkParts or v <= 0.3
		end
	end
	for _, d in mesh:GetDescendants() do
		if d:IsA("BasePart") and not lackey then
			local _, _, v = d.Color:ToHSV()
			if v > 0.3 then
				d.Color = white
				if darkParts and d:IsA("MeshPart") then
					d.TextureID = ""
					local look = d:FindFirstChildOfClass("SurfaceAppearance")
					if look then
						look:Destroy()
					end
				end
			end
		end
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			d.CastShadow = false
			if d.Transparency < 1 then
				d.Transparency = math.max(d.Transparency, 0.15)
			end
			-- Lackeys are tinted orange (dark details such as eyes stay dark).
			local _, _, v = d.Color:ToHSV()
			if lackey and v > 0.3 then
				d.Color = orange
			end
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = d
			weld.Parent = d
		end
	end
	mesh.Name = "Mesh"
	mesh.Parent = model
	if lackey then
		-- A textured mesh ignores Color, so an orange fill makes lackeys read as orange anyway.
		-- At most 9 lackeys exist (normal ghosts are cleared in a Blood Moon): well under the
		-- Highlight limit.
		local tint = Instance.new("Highlight")
		tint.FillColor = orange
		tint.FillTransparency = 0.45
		tint.OutlineColor = Color3.fromRGB(255, 200, 120)
		tint.OutlineTransparency = 0.5
		tint.DepthMode = Enum.HighlightDepthMode.Occluded
		tint.Parent = model
	end
	dressGhost(body, lackey)
	model.PrimaryPart = body
	model.Parent = ghostFolder
	return model, body
end

local function buildGhost(at: Vector3, lackey: boolean?): (Model, BasePart)
	local meshModel, meshRoot = buildMeshGhost(at, lackey)
	if meshModel and meshRoot then
		return meshModel, meshRoot
	end
	-- Blocky "lego" ghost: a white block body with a stepped top, stubby arms, a ragged hem of
	-- three blocks and black square eyes and mouth on the front (-Z). Lackeys are orange.
	local model = Instance.new("Model")
	model.Name = "Ghost"
	local tint = lackey and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(245, 247, 255)
	local hemTint = lackey and Color3.fromRGB(255, 170, 80) or Color3.fromRGB(228, 234, 252)
	local ink = Color3.fromRGB(20, 16, 30)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.8, 4, 3.4)
	body.Material = Enum.Material.Plastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.Color = tint
	body.Transparency = 0.06
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CFrame = CFrame.new(at)
	body.Parent = model
	local function attach(
		name: string,
		size: Vector3,
		offset: CFrame,
		color: Color3,
		transparency: number
	)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Color = color
		p.Transparency = transparency
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CFrame = body.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = p
		weld.Parent = p
		p.Parent = model
	end
	-- Stepped top: reads as a rounded head from a distance.
	attach("Top", Vector3.new(3.2, 0.8, 2.8), CFrame.new(0, 2.4, 0), tint, 0.06)
	attach("Cap", Vector3.new(2.2, 0.6, 1.8), CFrame.new(0, 3.1, 0), tint, 0.06)
	for side = -1, 1, 2 do
		attach(
			"Arm",
			Vector3.new(1, 1.7, 1),
			CFrame.new(side * 2.3, 0.3, -0.2) * CFrame.Angles(0, 0, math.rad(side * 28)),
			tint,
			0.06
		)
		attach("Eye", Vector3.new(0.8, 0.9, 0.2), CFrame.new(side * 0.8, 0.7, -1.72), ink, 0)
	end
	attach("Mouth", Vector3.new(1.1, 0.5, 0.2), CFrame.new(0, -0.4, -1.72), ink, 0)
	for k = -1, 1 do
		attach(
			"Hem",
			Vector3.new(1.2, k == 0 and 1.6 or 1.1, 3),
			CFrame.new(k * 1.25, k == 0 and -2.6 or -2.35, 0.1),
			hemTint,
			0.2
		)
	end
	dressGhost(body, lackey)
	model.PrimaryPart = body
	model.Parent = ghostFolder
	return model, body
end

local spawnGhost
do
	-- Ghosts go for pumpkins placed on bases that are not locked and whose owner is past the
	-- new-player shield (a ghost must never empty a new farmer's base).
	function Progress.raidEligible(owner, patch, reserved)
		if not owner or not Helpers.isLoaded(owner) or Bases.isLocked(patch) then
			return false
		end
		for _, plot in Bases.plots(patch) do
			local pet = plotState[plot] and plotState[plot].pumpkin
			if pet and pet:GetAttribute("Stashed") then
				return false
			end
		end
		local d = Progress.data[owner]
		local _, root = aliveRoot(owner)
		if not d or not root or (owner:GetAttribute("PlayTime") or 0) < Config.Raid.grace then
			return false
		end
		local soil = patch:FindFirstChild("Soil")
		if not soil or (root.Position - soil.Position).Magnitude <= Config.Raid.homeRadius then
			return false
		end
		if
			workspace:GetServerTimeNow()
				- (owner:GetAttribute("LastActiveAt") or workspace:GetServerTimeNow())
			>= Config.Raid.idle
		then
			return false
		end
		return reserved
			or (
				not patch:GetAttribute("RaidPending")
				and os.time() - d.raidAt >= Config.Raid.cooldown
			)
	end
	local function stealTargets(allowed): { BasePart }
		local list = {}
		for owner, patch in patchOf do
			if (not allowed or allowed[owner]) and Progress.raidEligible(owner, patch) then
				local lowest, rank, rate = nil, math.huge, math.huge
				for _, plot in Bases.plots(patch) do
					local p = plotState[plot].pumpkin
					local seed = p and Lookup.seedById[p:GetAttribute("Seed")]
					local rarity = seed and Config.Pets[seed.pet].rarity
					local order = rarity == "Common" and 1 or rarity == "Rare" and 2 or math.huge
					if
						p
						and p:GetAttribute("Jack")
						and not p:GetAttribute("Targeted")
						and not p:GetAttribute("Stashed")
						and workspace:GetServerTimeNow() - (p:GetAttribute("PlacedAt") or workspace:GetServerTimeNow()) >= Config.Raid.petAge
						and (order < rank or (order == rank and incomeOf(p) < rate))
					then
						lowest, rank, rate = plot, order, incomeOf(p)
					end
				end
				if lowest and rank < math.huge then
					table.insert(list, lowest)
				end
			end
		end
		return list
	end

	local spawnPoints = {}
	for _, s in spawnFolder:GetChildren() do
		table.insert(spawnPoints, (s :: BasePart).Position)
	end

	function spawnGhost(allowed): boolean
		local targets = stealTargets(allowed)
		if #targets == 0 then
			return false
		end
		local plot = targets[math.random(#targets)]
		local pumpkin = plotState[plot].pumpkin :: BasePart
		pumpkin:SetAttribute("Targeted", true)
		plot.Parent:SetAttribute("RaidPending", true)
		local owner = Services.Players:GetPlayerByUserId(plot.Parent:GetAttribute("Owner") or 0)
		if owner and Progress.data[owner] then
			Progress.data[owner].raidAt = os.time()
		end
		local best, bestDist = spawnPoints[1], math.huge
		for _, p in spawnPoints do
			local d = (p - plot.Position).Magnitude
			if d < bestDist then
				best, bestDist = p, d
			end
		end
		local home = best + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
		local model, root = buildGhost(home)
		table.insert(ghosts, {
			model = model,
			root = root,
			hp = Config.Raid.taps,
			target = pumpkin,
			plot = plot,
			carried = nil,
			home = home,
			fleeing = false,
			bob = math.random() * 6,
			bait = pumpkinValue(pumpkin),
			purgeId = Purge.active() and Purge.id or nil,
		})
		return true
	end
end

local function removeGhost(ghost: Ghost)
	if ghost.plot and ghost.plot.Parent then
		ghost.plot.Parent:SetAttribute("RaidPending", nil)
	end
	if ghost.target and ghost.target.Parent then
		ghost.target:SetAttribute("Targeted", nil)
	end
	local i = table.find(ghosts, ghost)
	if i then
		table.remove(ghosts, i)
	end
	if ghost.target and ghost.target.Parent then
		ghost.target:SetAttribute("Targeted", nil)
	end
	ghost.model:Destroy()
end

local popGhost
do
	-- Stealing ghosts pay at most the value of the pumpkin they went for (so cheap Orange bait
	-- cannot farm B-sized bounties); lantern lackeys pay at most LackeyCandyCap x B.
	local function ghostCandy(player: Player, ghost: Ghost): number
		local b = orderBase(player)
		local candy = math.max(Config.GhostCandy, math.floor(Config.GhostCandyShare * b))
		if hasSkill(player, "GhostBounty") then
			candy *= Config.SkillGhostCandyMult
		end
		local cap = if ghost.lackey
			then math.floor(Config.LackeyCandyCap * b)
			else ghost.bait or Config.GhostCandy
		return math.max(Config.GhostCandy, math.min(candy, cap))
	end

	function popGhost(ghost: Ghost, by: Player?)
		local at = ghost.root.Position
		if ghost.carried and ghost.carried.Parent then
			if ghost.stash then
				ghost.carried:SetAttribute("Stashed", nil)
				ghost.carried.CFrame = ghost.savedCF
				ghost.carried:SetAttribute("JackHome", ghost.savedCF)
				ghost.carried:SetAttribute("RoamNext", 0)
				local owner =
					Services.Players:GetPlayerByUserId(ghost.carried:GetAttribute("Owner") or 0)
				if owner and owner.Parent then
					track(owner, "rescue", 1)
					Remotes.hintEvent:FireClient(owner, "Your pet is back!")
				end
				Bases.refresh(ghost.plot.Parent)
			else
				dropLoose(ghost.carried, at, 60, true)
			end
		end
		ghost.carried = nil
		removeGhost(ghost)
		local candy = 0
		if by then
			candy = ghost.purgeId and Purge.reward(by, ghost.purgeId)
				or addCandy(by, ghostCandy(by, ghost))
			track(by, "bonkGhost", 1)
		end
		Remotes.ghostPopEvent:FireAllClients(at, by, candy)
	end
end

Services.RunService.Heartbeat:Connect(function(dt)
	for i = #ghosts, 1, -1 do
		local ghost = ghosts[i]
		if not ghost.model.Parent then
			table.remove(ghosts, i)
			continue
		end
		if ghost.stash then
			local p = ghost.carried
			if not p or not p.Parent then
				removeGhost(ghost)
				continue
			end
			ghost.bob += dt
			ghost.root.CFrame = CFrame.new(
				Vector3.new(
					ghost.savedCF.Position.X,
					ghost.plot.Position.Y,
					ghost.savedCF.Position.Z
				) + Vector3.new(0, Config.Raid.hover + math.sin(ghost.bob), 0)
			)
			p.CFrame = ghost.root.CFrame * CFrame.new(0, p.Size.Y / 2 + 2, 0)
			continue
		end
		if ghost.lackey then
			ghost.bob += dt * 2
			ghost.root.CFrame = CFrame.new(
				ghost.home + Vector3.new(0, math.sin(ghost.bob) * 1.2, 0)
			) * CFrame.Angles(0, ghost.bob * 0.5, 0)
			continue
		end
		local pos = ghost.root.Position
		local goal: Vector3
		if ghost.fleeing then
			goal = ghost.home + Vector3.new(0, 8, 0)
		else
			local target = ghost.target
			local s = ghost.plot and plotState[ghost.plot]
			if
				not target
				or not target.Parent
				or not s
				or s.pumpkin ~= target
				or not Progress.raidEligible(
					Services.Players:GetPlayerByUserId(
						(ghost.plot :: BasePart).Parent:GetAttribute("Owner") or 0
					),
					(ghost.plot :: BasePart).Parent,
					true
				)
			then
				-- The pumpkin was picked up first (or the base got locked): drift home.
				ghost.fleeing = true
				ghost.target = nil
				continue
			end
			goal = Config.roamPoint(target, workspace:GetServerTimeNow())
				+ Vector3.new(0, target.Size.Y / 2 + 2.4, 0)
		end
		local flatGoal = Vector3.new(goal.X, 0, goal.Z)
		local flatPos = Vector3.new(pos.X, 0, pos.Z)
		local toGoal = goal - pos
		local speed = Config.GhostSpeed * (ghost.fleeing and 1.25 or 1)
		if toGoal.Magnitude < 1.2 then
			if ghost.fleeing then
				if ghost.carried then
					local owner =
						Services.Players:GetPlayerByUserId(ghost.carried:GetAttribute("Owner") or 0)
					if owner then
						Remotes.stolenEvent:FireClient(owner, pos)
					end
				end
				removeGhost(ghost)
			else
				-- Grab the pumpkin off the plot.
				local plot = ghost.plot :: BasePart
				local pumpkin = ghost.target :: BasePart
				pumpkin:SetAttribute("Targeted", nil)
				pumpkin:SetAttribute("Stashed", true)
				local grabbedAt = Config.roamPoint(pumpkin, workspace:GetServerTimeNow())
				ghost.savedCF = CFrame.new(grabbedAt) * pumpkin.CFrame.Rotation
				pumpkin.CFrame = ghost.savedCF
				pumpkin:SetAttribute("JackHome", nil)
				pumpkin:SetAttribute("RoamFrom", grabbedAt)
				pumpkin:SetAttribute("RoamTo", grabbedAt)
				pumpkin:SetAttribute("RoamStart", workspace:GetServerTimeNow())
				pumpkin:SetAttribute("RoamEnd", workspace:GetServerTimeNow())
				ghost.carried = pumpkin
				ghost.target = nil
				ghost.stash = true
				ghost.model.Name = "Stash Ghost"
				ghost.root.CanQuery = true
				ghost.model:SetAttribute("StashOwner", pumpkin:GetAttribute("Owner"))
				plot.Parent:SetAttribute("RaidPending", nil)
				local click = Instance.new("ClickDetector")
				click.MaxActivationDistance = Config.Raid.homeRadius
				click.Parent = ghost.root
				local function recoverTap(player)
					local _, root = aliveRoot(player)
					if
						player.UserId ~= pumpkin:GetAttribute("Owner")
						or not root
						or (root.Position - ghost.root.Position).Magnitude
							> Config.Raid.homeRadius
					then
						return
					end
					if os.clock() - (ghost.lastTap or 0) < Config.Raid.tapInterval then
						return
					end
					ghost.lastTap = os.clock()
					ghost.hp -= 1
					ghost.model:SetAttribute("StashTapsLeft", ghost.hp)
					local prompt = ghost.root:FindFirstChild("StashPrompt")
					if prompt then
						prompt.ActionText = "Tap to recover (" .. ghost.hp .. ")"
					end
					if ghost.hp <= 0 and ghost.model.Parent then
						popGhost(ghost, player)
					end
				end
				click.MouseClick:Connect(recoverTap)
				local rescue = Instance.new("ProximityPrompt")
				rescue.Name = "StashPrompt"
				rescue.ActionText = "Tap to recover (" .. Config.Raid.taps .. ")"
				rescue.ObjectText = "Stash Ghost"
				rescue.HoldDuration = 0
				rescue.MaxActivationDistance = Config.Raid.homeRadius
				rescue.RequiresLineOfSight = false
				rescue.Parent = ghost.root
				rescue.Triggered:Connect(recoverTap)
				Bases.refresh(plot.Parent)
				local owner = Services.Players:GetPlayerByUserId(pumpkin:GetAttribute("Owner") or 0)
				if owner then
					Remotes.hintEvent:FireClient(
						owner,
						"Stash Ghost! Return and tap 5 times to recover your pet"
					)
				end
			end
			continue
		end
		local step = toGoal.Unit * math.min(speed * dt, toGoal.Magnitude)
		local nextPos = pos + step
		ghost.bob += dt * 3
		local look = (flatGoal - flatPos).Magnitude > 0.1 and (flatGoal - flatPos).Unit
			or Vector3.new(0, 0, -1)
		ghost.root.CFrame = CFrame.lookAt(nextPos, nextPos + look)
			* CFrame.new(0, math.sin(ghost.bob) * 0.04, 0)
	end
end)

-- The scythe ------------------------------------------------------------------------------------
-- Every player holds one Tool named "Scythe", built for their best owned tool (blade color by
-- tier). The bonk remote checks for it; the server works out the damage.

do
	local buildScythe = Config.buildScythe
	-- Read-only icon templates reuse the exact held-tool builder; no client purchase authority.
	do
		local icons = Instance.new("Folder")
		icons.Name = "PatchScytheIcons"
		for _, def in Config.Tools do
			local ok, tool = pcall(buildScythe, def)
			if not ok then
				warn("Scythe preview failed for " .. def.id .. ": " .. tostring(tool))
				continue
			end
			tool.Name = def.id
			for _, child in tool:GetDescendants() do
				if child:IsA("BasePart") then
					child.Anchored = true
					child.CanCollide, child.CanTouch, child.CanQuery = false, false, false
				elseif child:IsA("Trail") or child:IsA("WeldConstraint") then
					child:Destroy()
				end
			end
			tool.Parent = icons
		end
		icons.Parent = Services.ReplicatedStorage
	end

	for _, name in { "Mallet", "Scythe" } do
		local old = Services.StarterPack:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	-- Makes sure the player has exactly one Scythe, built for their best owned tool. A held tool
	-- that gets replaced is re-equipped; equip = also put it in the hands (on spawn).
	function giveTool(player: Player, equip: boolean?)
		local def = bestTool(player)
		player:SetAttribute("Tool", def.id)
		local backpack = player:FindFirstChildOfClass("Backpack")
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local keep: Tool? = nil
		local wasHeld = false
		for _, container in { character, backpack } do
			for _, child in container and container:GetChildren() or {} do
				if child:IsA("Tool") and (child.Name == "Scythe" or child.Name == "Mallet") then
					if
						not keep
						and child:GetAttribute("ToolId") == def.id
						and (child:GetAttribute("CleaverSkin") == true)
							== (player:GetAttribute("CleaverSkin") == true)
					then
						keep = child
					else
						wasHeld = wasHeld or child.Parent == character
						child:Destroy()
					end
				end
			end
		end
		local tool = keep
		if not tool then
			if not backpack then
				return
			end
			local visual = table.clone(def)
			if player:GetAttribute("CleaverSkin") then
				visual.order = Config.KingSkin.shapeTier
				visual.skinStyle =
					Config.Tools[math.clamp(Config.KingSkin.shapeTier, 1, #Config.Tools)].id
				visual.color = Config.KingSkin.color
				visual.name = "Pumpkin King Cleaver skin"
			end
			tool = buildScythe(visual)
			tool.Parent = backpack
		end
		tool:SetAttribute("CleaverSkin", player:GetAttribute("CleaverSkin") == true)
		local holding = character and character:FindFirstChildOfClass("Tool")
		if
			(wasHeld or (equip and not holding))
			and tool.Parent ~= character
			and humanoid
			and humanoid.Health > 0
		then
			humanoid:EquipTool(tool)
		end
	end
end

-- King state lives here so bonks can reach it.
local king = {
	active = false,
	hp = 0,
	maxHp = 0,
	damage = {} :: { [Player]: number },
	hits = {} :: { [Player]: number },
	faceBase = kingFace.CFrame,
	homeBase = kingFace.CFrame,
	homeCollide = kingFace.CanCollide,
	pad = 0,
	moving = false,
	attackBusy = false,
	plantedUntil = 0,
	phase = 1,
	shield = false,
	stunnedUntil = 0,
	transitionUntil = 0,
	cast = 0,
	combos = {},
	lastHitter = nil :: Player?,
	faceSize = nil :: Vector3?,
	-- Payout pool, frozen when the Blood Moon starts.
	pool = 0,
	-- HP each player added to the fight (removed again if they leave).
	counted = {} :: { [Player]: number },
	-- Per-player damage this second: { t = window start, d = damage }.
	dps = {} :: { [Player]: { t: number, d: number } },
}

local function kingPlayerHp(player: Player): number
	return Config.KingHpPerPlayer + Config.KingHpPerDamage * swingDamage(player)
end

local function publishKingHp()
	state:SetAttribute("KingMaxHp", king.maxHp)
	state:SetAttribute("KingHp", king.hp)
end

-- A player joined mid-fight: the King grows by their share.
local function kingAddPlayer(player: Player)
	if not king.active or king.counted[player] then
		return
	end
	local add = kingPlayerHp(player)
	king.counted[player] = add
	king.maxHp += add
	king.hp += add
	publishKingHp()
end

-- A player left mid-fight: shrink by their share, but never below the damage already dealt.
local function kingDropPlayer(player: Player)
	local add = king.counted[player]
	king.counted[player] = nil
	king.dps[player] = nil
	king.combos[player] = nil
	if not add or not king.active then
		return
	end
	local dealt = king.maxHp - king.hp
	king.maxHp = math.max(king.maxHp - add, dealt + 1)
	king.hp = king.maxHp - dealt
	publishKingHp()
end
local kingGround = Vector3.new(
	kingFace.Position.X,
	market:WaitForChild("Plaza").Position.Y + 1,
	kingFace.Position.Z
)

king.groundHome = kingGround
local lastBonk: { [Player]: number } = {}
local bonkSpot: { [Player]: { pos: Vector3, t: number } } = {}
local defeatKing -- forward
local lackeyPopped -- forward

local function publishTopDamage()
	local list = {}
	for player, d in king.damage do
		if player.Parent then
			table.insert(list, { name = player.DisplayName, d = d })
		end
	end
	table.sort(list, function(a, b)
		return a.d > b.d
	end)
	local parts = {}
	for i = 1, math.min(Config.KingNight.topCount, #list) do
		table.insert(parts, list[i].name .. "  " .. list[i].d)
	end
	state:SetAttribute("KingTop", table.concat(parts, "\n"))
end

-- One swing hits the first of: a thief carrying your pumpkins, a ghost, the King, a wild pumpkin.
Remotes.bonkEvent.OnServerEvent:Connect(function(player)
	if #(carrying[player] or {}) > 0 then
		return
	end
	local now = os.clock()
	player:SetAttribute("LastActiveAt", workspace:GetServerTimeNow())
	-- Fast Hands swings faster; a little slack for network jitter.
	local cooldown = (
		player:GetAttribute("LearningFarm") and Config.Farm.firstSwingSeconds or Config.BonkCooldown
	) / (hasSkill(player, "QuickRoots") and 1 + Config.SkillSwingBonus or 1)
	if now - (lastBonk[player] or 0) < cooldown * 0.9 then
		return
	end
	lastBonk[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tool = character and character:FindFirstChild("Scythe")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not tool or not humanoid or humanoid.Health <= 0 then
		return
	end
	-- Cheap anti-teleport-farm: a big jump between two quick bonks voids the second one.
	local prev = bonkSpot[player]
	bonkSpot[player] = { pos = root.Position, t = now }
	if
		prev
		and now - prev.t < Config.BonkTeleportWindow
		and (root.Position - prev.pos).Magnitude > Config.BonkTeleportStuds
	then
		return
	end
	Remotes.swingEvent:FireAllClients(player)
	if Bases.defend(player, root) then
		return
	end
	-- Ghosts count swings: each swing does as many hits as the tool's tier.
	local hits = bestTool(player).order
	-- Hit the nearest ghost in reach (a little forgiving in front of the player).
	local best, bestDist = nil, math.huge
	local look = root.CFrame.LookVector
	for _, ghost in ghosts do
		if ghost.stash then
			continue
		end
		local offset = ghost.root.Position - root.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		local dist = flat.Magnitude
		if math.abs(offset.Y) < 12 then
			local facing = dist < 1 or flat.Unit:Dot(look) > -0.2
			local reach = Config.BonkRange + (facing and 2 or 0)
			if dist <= reach and dist < bestDist then
				best, bestDist = ghost, dist
			end
		end
	end
	if best then
		if best.stash and best.model:GetAttribute("StashOwner") ~= player.UserId then
			return
		end
		best.hp -= best.stash and 1 or hits
		if best.hp <= 0 then
			local wasLackey = best.lackey
			popGhost(best, player)
			if wasLackey then
				lackeyPopped()
			end
		else
			Remotes.ghostPopEvent:FireAllClients(best.root.Position, nil, 0)
		end
		return
	end
	if king.active and not king.shield and now >= king.transitionUntil then
		local flat = Vector3.new(
			kingFace.Position.X - root.Position.X,
			0,
			kingFace.Position.Z - root.Position.Z
		)
		local facing = Vector3.new(king.faceBase.LookVector.X, 0, king.faceBase.LookVector.Z)
		if
			flat.Magnitude - kingFace.Size.X / 2 <= Config.BonkRange
			and (flat.Magnitude < 6 or (-flat.Unit):Dot(facing) >= 0)
		then
			local stunned = os.clock() < king.stunnedUntil
			local crit = math.random() < Config.KingNight.critChance
			local chain = king.combos[player]
			local step = chain and now - chain.t <= Config.KingNight.combo.window and chain.n + 1
				or 1
			local recovering = (king.recoveryEnds or 0) > now
			local mult = (stunned and (recovering and Config.KingNight.recoverMult or 2) or 1)
				* (step == 3 and Config.KingNight.combo.finisher or 1)
				* (crit and Config.KingNight.critMult or 1)
			local dealt = swingDamage(player) * math.min(mult, 3)
			if hasSkill(player, "KingSlayer") then
				dealt = math.floor(dealt * Config.SkillKingDamageMult + 0.5)
			end
			-- At most KingSwingsPerSecond swings' worth per player in each one-second window.
			local window = king.dps[player]
			if not window or now - window.t >= 1 then
				window = { t = now, d = 0, swings = 0 }
				king.dps[player] = window
			end
			if (window.swings or 0) >= Config.KingSwingsPerSecond then
				return
			end
			dealt = math.min(dealt, king.hp)
			if dealt <= 0 then
				return
			end
			window.d += dealt
			window.swings = (window.swings or 0) + 1
			king.combos[player] = { t = now, n = step == 3 and 0 or step }
			king.hp = math.max(0, king.hp - dealt)
			king.damage[player] = (king.damage[player] or 0) + dealt
			king.hits[player] = (king.hits[player] or 0) + 1
			king.lastHitter = player
			state:SetAttribute("KingHp", king.hp)
			player:SetAttribute("KingDamage", king.damage[player])
			Remotes.kingHitEvent:FireAllClients(player, dealt, crit, step, recovering)
			track(player, "kingHit", 1)
			track(player, "kingDamage", dealt)
			if king.hp <= 0 then
				defeatKing()
			end
			return
		end
	end
	if not Wild.hit(player, root) then
		Hoards.swing(player, root)
	end
end)

-- Day / midnight / Blood Moon -------------------------------------------------------------------

local function setPhase(phase: string, seconds: number)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("PhaseEnds", workspace:GetServerTimeNow() + seconds)
end

function Progress.shiftStash(plot, delta)
	for _, g in ghosts do
		if g.stash and g.plot == plot then
			g.savedCF += delta
		end
	end
end
function Progress.recoverStashes(patch)
	for i = #ghosts, 1, -1 do
		local g = ghosts[i]
		if g.stash and g.plot and g.plot.Parent == patch then
			popGhost(g, nil)
		end
	end
end
local function clearGhosts()
	for i = #ghosts, 1, -1 do
		if ghosts[i].lackey then
			popGhost(ghosts[i], nil)
		end
	end
end

function Helpers.releaseRainCandy(slot)
	slot.active = false
	slot.body.CanTouch, slot.body.CanCollide, slot.body.Anchored = false, false, true
	slot.body.AssemblyLinearVelocity, slot.body.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	slot.model.Parent = nil
end
-- Bounded pool built once; a slot's generation makes delayed expiry safe after reuse.
Helpers.rainCandies = {}
for _ = 1, Config.RainCount do
	local model = Config.makeWrappedCandy()
	local slot = { model = model, body = model.PrimaryPart, active = false, generation = 0 }
	table.insert(Helpers.rainCandies, slot)
	slot.body.Touched:Connect(function(hit)
		local player = Services.Players:GetPlayerFromCharacter(hit.Parent)
		local root = nil
		if player then
			local _, liveRoot = aliveRoot(player)
			root = liveRoot
		end
		if
			not slot.active
			or not player
			or not Helpers.isLoaded(player)
			or not root
			or (root.Position - slot.body.Position).Magnitude > 7
		then
			return
		end
		local at = slot.body.Position
		Helpers.releaseRainCandy(slot)
		addCandy(player, Config.RainCandy)
		Remotes.rainEvent:FireAllClients(player, at)
	end)
end
local function rainCandy()
	for _ = 1, Config.RainCount do
		local slot
		for _, candidate in Helpers.rainCandies do
			if not candidate.active then
				slot = candidate
				break
			end
		end
		if not slot then
			task.wait(Config.KingNight.rain / Config.RainCount)
			continue
		end
		local a = math.random() * math.pi * 2
		local r = 10 + math.random() * 26
		slot.generation += 1
		local generation = slot.generation
		slot.active = true
		-- Around the Giant Jack (the King's spot in the hub).
		slot.model:PivotTo(
			CFrame.new(
				giantJack.Position.X + math.cos(a) * r,
				giantJack.Position.Y + 20 + math.random() * 20,
				giantJack.Position.Z + math.sin(a) * r
			) * CFrame.Angles(0, a, math.rad(15))
		)
		slot.model.Parent = loose
		slot.body.CanCollide, slot.body.CanTouch, slot.body.Anchored = true, true, false
		slot.body:SetNetworkOwner(nil)
		task.delay(Config.RainSeconds, function()
			if slot.active and slot.generation == generation then
				Helpers.releaseRainCandy(slot)
			end
		end)
		task.wait(Config.KingNight.rain / Config.RainCount)
	end
end

local phaseToken = 0
local runDay -- forward

local function endBloodMoon(refill: number)
	king.active = false
	king.finalizing = false
	if king.motionTween then
		king.motionTween:Cancel()
	end
	state:SetAttribute("KingActive", false)
	king.shield = false
	giantJack.Transparency = 1
	giantJack.CanCollide = false
	kingFace.Transparency = 1
	kingFace.Size = king.faceSize or kingFace.Size
	king.faceBase = king.homeBase
	kingFace.CFrame = king.homeBase
	kingFace.CanCollide = king.homeCollide
	kingGround = king.groundHome
	king.moving = false
	state:SetAttribute("KingWalking", false)
	king.attackBusy = false
	state:SetAttribute("KingHp", nil)
	state:SetAttribute("KingMaxHp", nil)
	state:SetAttribute("KingPhase", nil)
	state:SetAttribute("KingShield", nil)
	state:SetAttribute("KingStunned", nil)
	state:SetAttribute("KingRecoverUntil", nil)
	state:SetAttribute("KingTransitionUntil", nil)
	state:SetAttribute("KingTop", nil)
	state:SetAttribute("LocksOff", nil)
	setKingWakes()
	local goal = jackGoal()
	state:SetAttribute("JackGoal", goal)
	state:SetAttribute("JackCandy", math.floor(goal * refill))
	task.spawn(runDay)
end

function defeatKing()
	if not king.active then
		return
	end
	king.active = false
	king.finalizing = true
	if king.motionTween then
		king.motionTween:Cancel()
	end
	state:SetAttribute("KingWalking", false)
	state:SetAttribute("KingActive", false)
	phaseToken += 1
	-- Finale: the King swells, then bursts.
	for player in king.damage do
		if player.Parent then
			Progress.slow(player, 0, Config.KingNight.finale, "")
		end
	end
	Remotes.kingDoneEvent:FireAllClients("swell", {})
	local grow = Services.TweenService:Create(
		kingFace,
		TweenInfo.new(Config.KingNight.finale, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = kingFace.Size * 1.4,
		}
	)
	grow:Play()
	grow.Completed:Wait()
	king.finalizing = false
	local payouts, mvp = Progress.kingRewards(true)
	Remotes.kingDoneEvent:FireAllClients("won", payouts, mvp)
	state:SetAttribute(
		"JackBase",
		math.floor((state:GetAttribute("JackBase") or Config.JackGoal) * Config.JackGrowth)
	)
	kingFace.Transparency = 1
	task.spawn(rainCandy)
	task.wait(Config.KingNight.rain)
	endBloodMoon(0)
end

do
	-- Telegraphed attacks: clients draw the red circles; the server checks who is inside when they land.
	local function landAttack(shapes, victim, effect)
		if king.active and os.clock() < king.transitionUntil then
			return
		end
		for _, player in victim and { victim } or Services.Players:GetPlayers() do
			local _, root = aliveRoot(player)
			if root then
				for _, shape in shapes do
					if Progress.contains(shape, root.Position) then
						if effect then
							effect(player, root)
						else
							local delta = Vector3.new(
								root.Position.X - shape.pos.X,
								0,
								root.Position.Z - shape.pos.Z
							)
							local out = delta.Magnitude > 0.1 and delta.Unit or Vector3.zAxis
							root.AssemblyLinearVelocity = out * Config.KingNight.push
								+ Vector3.yAxis * Config.KingNight.lift
							Progress.slow(player, 0, Config.KingNight.stagger, "STAGGER")
							Remotes.knockEvent:FireClient(player, root.AssemblyLinearVelocity, 0)
						end
						break
					end
				end
			end
		end
	end
	Progress.landAttack = landAttack

	local function walkKing(dt)
		if
			king.phase == 1
			or king.attackBusy
			or os.clock() < king.stunnedUntil
			or os.clock() < king.transitionUntil
			or (king.recoverUntil or 0) > os.clock()
		then
			return
		end
		if not king.moving and os.clock() >= king.plantedUntil then
			if king.pad == 0 then
				king.stepDownAt = os.clock()
			end
			king.pad = king.pad % 4 + 1
			local ring = Config.KingNight.ring
			local pads = {
				Vector3.new(-ring.X / 2, 0, 0),
				Vector3.new(0, 0, -ring.Y / 2),
				Vector3.new(ring.X / 2, 0, 0),
				Vector3.new(0, 0, ring.Y / 2),
			}
			king.destination = king.groundHome + pads[king.pad]
			king.moving = true
		end
		if king.moving then
			local delta = king.destination - kingGround
			local distance = math.min(delta.Magnitude, Config.KingNight.walkSpeed * dt)
			if delta.Magnitude > 0.001 then
				kingGround += delta.Unit * distance
			end
			local direction = delta.Magnitude > 0.001 and delta.Unit or king.faceBase.LookVector
			local groundedAt = kingGround + Vector3.yAxis * (kingFace.Size.Y / 2 - 1)
			local grounded = CFrame.lookAt(groundedAt, groundedAt + direction)
			local drop = math.clamp((os.clock() - (king.stepDownAt or 0)) / 0.6, 0, 1)
			local raised = king.eventBase + (kingGround - king.groundHome)
			king.faceBase = raised:Lerp(grounded, drop)
			kingFace.CFrame = king.faceBase
			if delta.Magnitude <= distance + 0.001 then
				king.moving = false
				king.plantedUntil = os.clock() + Config.KingNight.padPause
			end
		end
		state:SetAttribute("KingWalking", king.moving)
	end

	Services.RunService.Heartbeat:Connect(function(dt)
		if king.active then
			walkKing(dt)
		end
	end)

	local function fightCount()
		local n = 0
		for player in king.counted do
			if player.Parent then
				n += 1
			end
		end
		return math.clamp(n, 1, 12)
	end

	local function nextCard()
		if king.deckPhase ~= king.phase or not king.deck or #king.deck == 0 then
			king.deckPhase = king.phase
			king.deck = king.phase == 1 and { "Stomp", "Sweep", "Volley" }
				or king.phase == 2 and { "Stomp", "Sweep", "Volley", "Donut" }
				or { "Sweep", "Volley", "Seedfall", "Donut", "Triple", "Stomp" }
			for i = #king.deck, 2, -1 do
				local j = math.random(i)
				king.deck[i], king.deck[j] = king.deck[j], king.deck[i]
			end
			if king.deck[#king.deck] == king.lastAttack then
				king.deck[1], king.deck[#king.deck] = king.deck[#king.deck], king.deck[1]
			end
		end
		local kind = table.remove(king.deck)
		king.lastAttack = kind
		return kind
	end

	function Progress.combatCandy(count, value)
		for i = 1, count do
			local a = i / count * math.pi * 2
			local at = kingGround + Vector3.new(math.cos(a) * 25, 1.5, math.sin(a) * 25)
			local model = Instance.new("Model")
			model.Name = "KingCandyCorn"
			local body
			for j, color in
				{ Color3.fromRGB(255, 210, 50), Color3.fromRGB(255, 145, 40), Color3.new(1, 1, 1) }
			do
				local part = Instance.new("WedgePart")
				part.Size = Vector3.new(1.8 - j * 0.35, 0.65, 1.5 - j * 0.25)
				part.Position = at + Vector3.yAxis * (j - 1) * 0.6
				part.Color, part.Material = color, Enum.Material.Neon
				part.Anchored, part.CanCollide, part.CanQuery = true, false, false
				part.Parent = model
				if j == 1 then
					body = part
				end
			end
			model.Parent = loose
			local collected = false
			body.Touched:Connect(function(other)
				local player = Services.Players:GetPlayerFromCharacter(other.Parent)
				if collected or not player or not Helpers.isLoaded(player) then
					return
				end
				collected = true
				addCandy(player, value)
				Remotes.rainEvent:FireAllClients(player, at)
				model:Destroy()
			end)
			task.delay(20, function()
				model:Destroy()
			end)
		end
	end

	function Progress.kingTransition()
		if king.motionTween then
			king.motionTween:Cancel()
		end
		king.cast += 1 -- Invalidate a cast even if its delayed landing is already queued.
		king.attackBusy = false
		king.transitionUntil = os.clock() + Config.KingNight.transition
		state:SetAttribute("KingWalking", false)
		king.recoveryEnds = 0
		state:SetAttribute("KingRecoverUntil", nil)
		state:SetAttribute(
			"KingTransitionUntil",
			workspace:GetServerTimeNow() + Config.KingNight.transition
		)
		for _, player in Services.Players:GetPlayers() do
			player:SetAttribute(
				"KingGraceUntil",
				workspace:GetServerTimeNow() + Config.KingNight.transition
			)
		end
		kingFace.CFrame = king.faceBase
		local player = king.lastHitter or Services.Players:GetPlayers()[1]
		Progress.combatCandy(
			12,
			player and math.max(1, math.floor(Progress.bossCandy(player) * 0.01)) or 1
		)
	end

	local function attack(token: number, kind: string)
		if king.attackBusy or os.clock() < king.transitionUntil then
			return
		end
		king.attackBusy = true
		state:SetAttribute("KingWalking", false)
		king.cast += 1
		local cast, phase, base = king.cast, king.phase, king.faceBase
		local n = fightCount()
		local targets, nearest, distance = {}, nil, math.huge
		for player in king.counted do
			local _, root = aliveRoot(player)
			if root then
				table.insert(targets, root)
				local d = (root.Position - kingGround).Magnitude
				if d < distance then
					nearest, distance = root, d
				end
			end
		end
		local target = kind == "Volley" and #targets > 0 and targets[math.random(#targets)]
			or nearest
		local aim = target and target.Position - kingGround or base.LookVector
		aim = Vector3.new(aim.X, 0, aim.Z)
		aim = aim.Magnitude > 0.01 and aim.Unit or Vector3.zAxis
		if kind == "Sweep" or kind == "Volley" or kind == "Triple" then
			base = CFrame.lookAt(base.Position, base.Position + aim)
			king.faceBase, kingFace.CFrame = base, base
		end
		local shapes = {}
		local warns =
			{ Stomp = 1.5, Sweep = 1.2, Volley = 1.5, Donut = 1.4, Seedfall = 1.4, Triple = 1.3 }
		local warn = warns[kind] + (n == 1 and Config.KingNight.soloExtraWarn or 0)
		local function lane(dir, width, length, start)
			local at = kingGround + dir * (start + length / 2)
			table.insert(
				shapes,
				{ pos = at, cf = CFrame.lookAt(at, at + dir), width = width, length = length }
			)
		end
		if kind == "Stomp" or kind == "Donut" then
			table.insert(shapes, {
				pos = kingGround,
				radius = kind == "Stomp" and 18 or 22,
				inner = kind == "Donut" and 10 or nil,
			})
		elseif kind == "Sweep" then
			lane(aim, 22, 34, kingFace.Size.X / 2)
		elseif kind == "Volley" then
			for i = -1, 1 do
				lane(CFrame.Angles(0, math.rad(i * 18), 0):VectorToWorldSpace(aim), 6, 60, 0)
			end
		elseif kind == "Triple" then
			for i, d in { 10, 22, 34 } do
				table.insert(
					shapes,
					{ pos = kingGround + aim * d, radius = 9, number = i, delay = (i - 1) * 0.5 }
				)
			end
		else
			local count = n == 1 and 2 or math.min(2 + math.floor(n / 2), 8)
			for i = 1, count do
				local at
				if i == 1 and target and n > 1 then
					at = target.Position + target.AssemblyLinearVelocity * 0.8
					local flat = Vector3.new(at.X - kingGround.X, 0, at.Z - kingGround.Z)
					if flat.Magnitude > 40 then
						at = kingGround + flat.Unit * 40
					end
				else
					for _ = 1, 64 do
						local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * 40
						at = kingGround + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
						if
							n > 1
							or not target
							or (at - Vector3.new(target.Position.X, at.Y, target.Position.Z)).Magnitude
								>= 10
						then
							break
						end
					end
				end
				if n == 1 and target then
					local spawn = Vector3.new(target.Position.X, kingGround.Y, target.Position.Z)
					if (at - spawn).Magnitude < 10 then
						local away = kingGround - spawn
						at = kingGround + (away.Magnitude > 0.01 and away.Unit or aim) * 40
					end
				end
				table.insert(shapes, {
					pos = Vector3.new(at.X, kingGround.Y, at.Z),
					radius = 6,
					delay = (i - 1) * 0.15,
				})
			end
		end
		local function valid()
			return king.active
				and token == phaseToken
				and cast == king.cast
				and phase == king.phase
				and os.clock() >= king.transitionUntil
		end
		local effects = {
			Stomp = { 50, 40, 1 },
			Sweep = { 50, 0, 1 },
			Volley = { 40, 30, 0.8 },
			Donut = { 45, 35, 1 },
			Seedfall = { 30, 25, 0.6 },
			Triple = { 45, 35, 1 },
		}
		local function hit(victim, root)
			local now = workspace:GetServerTimeNow()
			if not valid() or now < (victim:GetAttribute("KingGraceUntil") or 0) then
				return
			end
			victim:SetAttribute("KingGraceUntil", now + Config.KingNight.grace)
			local out =
				Vector3.new(root.Position.X - kingGround.X, 0, root.Position.Z - kingGround.Z)
			out = kind == "Sweep" and Vector3.new(-aim.Z, 0, aim.X)
				or (out.Magnitude > 0.01 and out.Unit or aim)
			local e = effects[kind]
			root.AssemblyLinearVelocity = out * e[1] + Vector3.yAxis * e[2]
			Progress.slow(victim, 0, e[3], "STAGGER")
			Remotes.knockEvent:FireClient(victim, root.AssemblyLinearVelocity, 0)
		end
		Remotes.telegraphEvent:FireAllClients(kind, shapes, warn)
		local pose = kind == "Sweep" and CFrame.Angles(0, math.rad(-35), 0)
			or kind == "Volley" and CFrame.Angles(math.rad(15), 0, 0)
			or CFrame.new(0, kind == "Stomp" and 7 or kind == "Donut" and 4 or 0, 0)
		local windup = Services.TweenService:Create(
			kingFace,
			TweenInfo.new(kind == "Stomp" and 0.25 or kind == "Sweep" and 1 or 1.2),
			{ CFrame = base * pose }
		)
		windup:Play()
		king.motionTween = windup
		task.wait(warn - 0.2)
		if not valid() then
			windup:Cancel()
			return
		end
		local slam = Services.TweenService:Create(
			kingFace,
			TweenInfo.new(kind == "Sweep" and 0.2 or 0.15),
			{ CFrame = kind == "Sweep" and base * CFrame.Angles(0, math.rad(35), 0) or base }
		)
		slam:Play()
		king.motionTween = slam
		task.wait(0.2)
		for i, shape in shapes do
			if i > 1 and (kind == "Triple" or kind == "Seedfall") then
				task.wait(kind == "Triple" and 0.5 or 0.15)
			end
			if not valid() then
				slam:Cancel()
				return
			end
			Remotes.stompEvent:FireAllClients(kind, { shape })
			landAttack({ shape }, nil, hit)
			if kind == "Triple" and i < 3 then
				king.motionTween = Services.TweenService:Create(
					kingFace,
					TweenInfo.new(0.2),
					{ CFrame = base * CFrame.new(0, 3, 0) }
				)
				king.motionTween:Play()
				task.delay(0.25, function()
					if valid() then
						king.motionTween = Services.TweenService:Create(
							kingFace,
							TweenInfo.new(0.15),
							{ CFrame = base }
						)
						king.motionTween:Play()
					end
				end)
			end
		end
		if valid() then
			kingFace.CFrame = base
			if kind == "Stomp" or kind == "Sweep" or kind == "Donut" or kind == "Triple" then
				king.recoveryEnds = os.clock() + Config.KingNight.recover[phase]
				king.stunnedUntil = math.max(king.stunnedUntil, king.recoveryEnds)
				state:SetAttribute(
					"KingRecoverUntil",
					workspace:GetServerTimeNow() + Config.KingNight.recover[phase]
				)
				Remotes.kingDoneEvent:FireAllClients("recover", {})
			end
			king.attackBusy = false
		end
	end
	local function spawnLackeys(count: number)
		for i = 1, count do
			local a = i / count * math.pi * 2
			local at = kingGround + Vector3.new(math.cos(a) * 32, 6, math.sin(a) * 32)
			local model, root = buildGhost(at, true)
			table.insert(ghosts, {
				model = model,
				root = root,
				hp = 2,
				target = nil,
				plot = nil,
				carried = nil,
				home = at,
				fleeing = false,
				bob = math.random() * 6,
				lackey = true,
			})
		end
	end

	local function lackeysLeft(): number
		local n = 0
		for _, g in ghosts do
			if g.lackey then
				n += 1
			end
		end
		return n
	end

	function lackeyPopped()
		if not king.shield then
			return
		end
		local left = lackeysLeft()
		state:SetAttribute("KingShield", left)
		if left == 0 then
			king.shield = false
			king.cast += 1
			king.attackBusy = false
			if king.motionTween then
				king.motionTween:Cancel()
			end
			king.recoveryEnds = 0
			state:SetAttribute("KingRecoverUntil", nil)
			king.stunnedUntil = os.clock() + Config.StunSeconds
			local player = king.lastHitter or Services.Players:GetPlayers()[1]
			Progress.combatCandy(
				12,
				player and math.max(1, math.floor(Progress.bossCandy(player) * 0.01)) or 1
			)
			state:SetAttribute("KingShield", nil)
			state:SetAttribute("KingStunned", true)
			Remotes.kingDoneEvent:FireAllClients("stun", {})
			king.motionTween = Services.TweenService:Create(
				kingFace,
				TweenInfo.new(0.5, Enum.EasingStyle.Bounce),
				{
					CFrame = king.faceBase
						* CFrame.new(0, -2, 0)
						* CFrame.Angles(math.rad(25), 0, math.rad(12)),
				}
			)
			king.motionTween:Play()
			local token, deadline = phaseToken, king.stunnedUntil
			task.delay(Config.StunSeconds, function()
				if token ~= phaseToken or not king.active or king.stunnedUntil ~= deadline then
					return
				end
				state:SetAttribute("KingStunned", nil)
				if king.active then
					king.recoverUntil = os.clock() + 0.4
					king.motionTween = Services.TweenService:Create(
						kingFace,
						TweenInfo.new(0.4),
						{ CFrame = king.faceBase }
					)
					king.motionTween:Play()
				end
			end)
		end
	end

	-- First every lock is off for LocksOffSeconds (state "LocksOff" = its end time), then the
	-- Pumpkin King wakes. skipWindow (Studio debug) wakes him at once.
	function startBloodMoon(_skipWindow: boolean?)
		if
			state:GetAttribute("Phase") == "BloodMoon"
			or Purge.active()
			or state:GetAttribute("PurgeWarning")
			or Spooky.active()
		then
			return
		end
		phaseToken += 1
		local token = phaseToken
		clearGhosts()

		state:SetAttribute("LocksOff", nil)
		state:SetAttribute("KingWarning", nil)
		Remotes.kingDoneEvent:FireAllClients("wake", {})
		king.counted = {}
		king.dps = {}
		king.combos = {}
		king.deck = nil
		king.lastAttack = nil
		king.cast += 1
		king.transitionUntil = 0
		king.recoveryEnds = 0
		state:SetAttribute("KingRecoverUntil", nil)
		king.maxHp = Config.KingBaseHp
		for _, player in Services.Players:GetPlayers() do
			local add = kingPlayerHp(player)
			king.counted[player] = add
			king.maxHp += add
		end
		king.hp = king.maxHp
		king.pool = 0
		king.damage = {}
		king.hits = {}
		king.active = true
		state:SetAttribute("KingActive", true)
		king.phase = 1
		king.shield = false
		king.stunnedUntil = 0
		king.recoverUntil = 0
		king.lastHitter = nil
		king.faceSize = king.faceSize or kingFace.Size
		kingFace.Size = king.faceSize * (Config.KingNight.height / king.faceSize.Y)
		king.faceBase = king.homeBase + Vector3.yAxis * ((kingFace.Size.Y - king.faceSize.Y) / 2)
		-- Move relative to the scaled plinth pose throughout this event.
		king.eventBase = king.faceBase
		kingGround = king.groundHome
		kingFace.CFrame = king.faceBase
		kingFace.CanCollide = false
		king.moving = false
		king.attackBusy = false
		king.pad = 0
		king.plantedUntil = os.clock() + Config.KingNight.padPause
		state:SetAttribute("KingWalking", false)
		for _, player in Services.Players:GetPlayers() do
			player:SetAttribute("MVP", nil)
			player:SetAttribute("KingDamage", 0)
		end
		state:SetAttribute("KingMaxHp", king.maxHp)
		state:SetAttribute("KingHp", king.hp)
		state:SetAttribute("KingPhase", 1)
		state:SetAttribute("KingTop", "")
		setPhase("BloodMoon", Config.KingSeconds)
		giantJack.Transparency = 1
		giantJack.CanCollide = false
		kingFace.Transparency = kingFace:GetAttribute("VoxelKing") and 1 or 0
		task.spawn(function()
			local started = os.clock()
			local lastTop = 0
			local nextAttack = os.clock() + 4
			local nextWeak = math.huge
			while
				king.active
				and token == phaseToken
				and os.clock() - started < Config.KingSeconds
			do
				task.wait(0.2)
				if os.clock() - lastTop > 1 then
					lastTop = os.clock()
					publishTopDamage()
				end
				local fraction = king.hp / king.maxHp
				if (king.recoveryEnds or 0) > 0 and os.clock() >= king.recoveryEnds then
					king.recoveryEnds = 0
					state:SetAttribute("KingRecoverUntil", nil)
				end
				if king.phase == 1 and fraction <= Config.KingNight.phaseAt[1] then
					king.phase = 2
					Progress.kingTransition()
					king.shield = true
					state:SetAttribute("KingPhase", 2)
					local count = math.clamp(2 * fightCount(), 2, 8)
					spawnLackeys(count)
					state:SetAttribute("KingShield", count)
					state:SetAttribute("KingShieldMax", count)
					Remotes.kingDoneEvent:FireAllClients("phase2", {})
				elseif
					king.phase == 2
					and not king.shield
					and fraction <= Config.KingNight.phaseAt[2]
				then
					king.phase = 3
					Progress.kingTransition()
					nextWeak = os.clock() + Config.KingNight.weakEvery
					state:SetAttribute("KingPhase", 3)
					Remotes.kingDoneEvent:FireAllClients("phase3", {})
				end
				if
					king.phase == 3
					and os.clock() >= nextWeak
					and not king.attackBusy
					and os.clock() >= king.transitionUntil
				then
					king.recoveryEnds = 0
					state:SetAttribute("KingRecoverUntil", nil)
					king.stunnedUntil = os.clock() + 5
					state:SetAttribute("KingStunned", true)
					nextWeak = os.clock() + Config.KingNight.weakEvery
					local deadline = king.stunnedUntil
					task.delay(5, function()
						if token == phaseToken and king.stunnedUntil == deadline then
							state:SetAttribute("KingStunned", nil)
						end
					end)
				end
				if
					not king.attackBusy
					and os.clock() >= nextAttack
					and os.clock() >= king.stunnedUntil
					and os.clock() >= king.transitionUntil
				then
					local kind = nextCard()
					task.spawn(attack, token, kind)
					local scale = math.max(0.5, 1 / (1 + 0.1 * (fightCount() - 1)))
					nextAttack = os.clock()
						+ Config.KingNight.attackEvery[king.phase]
							* scale
							* (fraction <= 0.1 and 0.85 or 1)
				end
			end
			if king.active and token == phaseToken then
				king.active = false
				state:SetAttribute("KingActive", false)
				Progress.kingRewards(false)
				Remotes.kingDoneEvent:FireAllClients("escaped", {})
				clearGhosts()
				task.wait(3)
				endBloodMoon(Config.FailRefill)
			end
		end)
	end
end

function runDay()
	phaseToken += 1
	local token = phaseToken
	setPhase("Day", Config.DayLength)
	task.wait(Config.DayLength)
	if token ~= phaseToken then
		return
	end
	Progress.raidCheck()
	setPhase("Midnight", Config.MidnightLength)
	pcall(Hoards.refillAll)
	task.wait(Config.MidnightLength)
	if token ~= phaseToken then
		return
	end
	clearGhosts()
	runDay()
end

-- Daily chest --------------------------------------------------------------------------------

-- Runs on join and from the 5 s loop (players online across UTC midnight). The streak cycles
-- 1..DailyMaxStreak and starts over; the last day pays x DailyLastMult (the Cursed token is cut).
-- The very first claim ever is only a toast (no popup on the first visit); later claims open the
-- panel once the tutorial is done, else they are toasts too.
local function claimDaily(player: Player, claim: boolean?)
	if not Helpers.isLoaded(player) then
		return
	end
	local o = orders[player]
	if o and o.tut <= TUTORIAL_COUNT then
		return
	end
	local today = math.floor(os.time() / 86400)
	local first = dailyOf[player] == nil
	local last = dailyOf[player] or { day = 0, streak = 0 }
	if last.day >= today then
		player:SetAttribute("DailyClaimable", false)
		return false
	end
	player:SetAttribute("DailyClaimable", true)
	if not claim then
		return false
	end
	player:SetAttribute("DailyClaimable", false)
	local streak = if last.day == today - 1
		then math.max(0, math.floor(last.streak)) % Config.DailyMaxStreak + 1
		else 1
	dailyOf[player] = { day = today, streak = streak }
	local candy = Config.DailyCandy
		* streak
		* (streak == Config.DailyMaxStreak and Config.DailyLastMult or 1)
	addCandy(player, candy)
	local panel = not first and o ~= nil and o.tut > TUTORIAL_COUNT
	Remotes.dailyEvent:FireClient(player, streak, candy, false, panel and "panel" or "toast")
	return true
end
-- Read-only UI remote: saved daily state stays private; claims still use claimDaily.
Remotes.dailyStatusFunction.OnServerInvoke = function(player)
	if not Helpers.isLoaded(player) then
		return nil
	end
	local today = math.floor(os.time() / 86400)
	local last = dailyOf[player] or { day = 0, streak = 0 }
	local ready = player:GetAttribute("DailyClaimable") == true
	local current = last.day >= today and last.streak
		or last.day == today - 1 and last.streak % Config.DailyMaxStreak + 1
		or 1
	return {
		day = current,
		claimedThrough = last.day >= today and last.streak or current > 1 and current - 1 or 0,
		ready = ready,
		nextAt = (today + 1) * 86400,
	}
end
Remotes.dailyClaimFunction.OnServerInvoke = function(player)
	return claimDaily(player, true) == true
end

-- Global board: lifetime candy, top 10 (needs a published game). -----------------------------

local refreshBoard
do
	local boardRows: { TextLabel } = {}
	do
		local board = market:FindFirstChild("LifetimeBoard") :: BasePart?
		if not board then
			-- Stand it in the hub beside the Upgrades stall (on its outer side), facing the lane.
			local stall = market:FindFirstChild("Upgrades")
			local plaza = market:FindFirstChild("Plaza") :: BasePart?
			local at = stall and stall:GetPivot().Position
				or Vector3.new(Lane.x + 30, 0, Lane.safeZ * 0.5)
			local y = plaza and plaza.Position.Y + 1 or at.Y
			local out = at.X >= Lane.x and 1 or -1
			local pos = Vector3.new(at.X + out * 9, y + 6, at.Z + 12)
			local p = Instance.new("Part")
			p.Name = "LifetimeBoard"
			p.Anchored = true
			p.CanCollide = false
			p.Material = Enum.Material.Wood
			p.Color = Color3.fromRGB(60, 38, 26)
			p.Size = Vector3.new(10, 10, 0.6)
			p.CFrame = CFrame.lookAt(pos, Vector3.new(Lane.x, pos.Y, pos.Z))
			p.Parent = market
			board = p
		end
		local oldGui = board:FindFirstChild("BoardGui")
		if oldGui then
			oldGui:Destroy()
		end
		local surface = Instance.new("SurfaceGui")
		surface.Name = "BoardGui"
		surface.Face = Enum.NormalId.Front
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 40
		surface.LightInfluence = 0
		surface.Parent = board
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = surface
		local function row(order: number, text: string, color: Color3, height: number): TextLabel
			local label = Instance.new("TextLabel")
			label.LayoutOrder = order
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, 0, height, 0)
			label.FontFace = Helpers.fontFace("title")
			label.TextScaled = false
			label.TextColor3 = color
			label.Text = text
			label.Parent = surface
			return label
		end
		row(0, "🎃 STEAL A PUMPKIN · TOP 10", Color3.fromRGB(255, 214, 80), 0.14)
		for i = 1, 10 do
			table.insert(boardRows, row(i, "", Color3.fromRGB(255, 240, 220), 0.086))
		end
	end

	local nameCache: { [number]: string } = {}
	local function nameOf(userId: number): string
		if nameCache[userId] then
			return nameCache[userId]
		end
		local ok, name = pcall(function()
			return Services.Players:GetNameFromUserIdAsync(userId)
		end)
		local result = ok and name or ("Farmer " .. userId)
		nameCache[userId] = result
		return result
	end

	function refreshBoard()
		if not boardStore then
			boardRows[1].Text = "Board opens in the live game"
			return
		end
		local ok, page = pcall(function()
			return boardStore:GetSortedAsync(false, 10):GetCurrentPage()
		end)
		if not ok then
			boardRows[1].Text = "Board opens in the live game"
			return
		end
		for i, label in boardRows do
			local entry = page[i]
			if entry then
				local userId = tonumber(entry.key) or 0
				label.Text =
					string.format("%d. %s  %s", i, nameOf(userId), Helpers.short(entry.value))
			else
				label.Text = ""
			end
		end
	end
end

-- Monetization ---------------------------------------------------------------------------------
-- Game passes and developer products from Config.GamePasses / Config.Products. An ID of 0 turns
-- that item off (the client hides it). Pass ownership is cached in "Pass_<Name>" attributes.

local shopFunnelOf: { [Player]: { id: string, step: number, at: number } } = {}
local refreshVipTag, checkPasses -- defined in the block below
do
	local passById: { [number]: string } = {}
	for name, id in Config.GamePasses do
		if id ~= 0 then
			passById[id] = name
		end
	end
	local productById: { [number]: string } = {}
	for name, id in Config.Products do
		if id ~= 0 then
			productById[id] = name
		end
	end

	-- Shop funnel (analytics): 1 opened the shop, 2 saw a purchase prompt, 3 bought something.
	-- A session starts when the shop opens; each step is logged at most once per session.
	local SHOP_STEPS = { "Opened shop", "Purchase prompt", "Purchased" }
	local function shopFunnel(player: Player, step: number)
		local session = shopFunnelOf[player]
		if step == 1 then
			if session and os.clock() - session.at < 2 then
				return
			end
			session = { id = Services.HttpService:GenerateGUID(false), step = 0, at = os.clock() }
			shopFunnelOf[player] = session
		end
		if not session or step <= session.step then
			return
		end
		session.step = step
		local id = session.id
		pcall(function()
			Services.AnalyticsService:LogFunnelStepEvent(player, "Shop", id, step, SHOP_STEPS[step])
		end)
	end

	-- VIP: a "VIP" tag and a gold name over the head (replaces the default name).
	local VIP_GOLD = Color3.fromRGB(255, 205, 60)
	function refreshVipTag(player: Player)
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not head or not humanoid then
			return
		end
		local tag = head:FindFirstChild("VipTag")
		if not Helpers.hasPass(player, "VIP") then
			if tag then
				tag:Destroy()
			end
			return
		end
		if tag then
			return
		end
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		local bb = Instance.new("BillboardGui")
		bb.Name = "VipTag"
		bb.Size = UDim2.fromOffset(200, 56)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 60
		for i, text in { "⭐ VIP", player.DisplayName } do
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromScale(0, i == 1 and 0 or 0.42)
			label.Size = UDim2.fromScale(1, i == 1 and 0.42 or 0.58)
			label.FontFace = Helpers.fontFace("title")
			label.TextScaled = false
			label.TextColor3 = VIP_GOLD
			label.Text = text
			label.Parent = bb
			local outline = Instance.new("UIStroke")
			outline.Thickness = 2
			outline.Color = Color3.fromRGB(60, 36, 0)
			outline.Parent = label
		end
		bb.Parent = head
	end

	local function grantPass(player: Player, name: string)
		if Helpers.hasPass(player, name) then
			return
		end
		player:SetAttribute("Pass_" .. name, true)
		-- Carry size, sell value and base income all read the pass attributes.
		refreshCarry(player)
		refreshVipTag(player)
		Bases.refresh(patchOf[player])
	end

	-- Runs after Loaded. A failed check just leaves the pass off for this session.
	function checkPasses(player: Player)
		for name, id in Config.GamePasses do
			if id ~= 0 and player.Parent then
				local ok, owns = pcall(function()
					return Services.MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
				end)
				if ok and owns then
					grantPass(player, name)
				end
			end
		end
	end

	Services.MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player, passId, purchased)
			local name = passById[passId]
			if purchased and name and player.Parent then
				grantPass(player, name)
				shopFunnel(player, 3)
			end
		end
	)

	-- Receipt-time server income determines candy packs; quotes are estimates.
	local function productCandy(player: Player, name: string): number
		Bases.refresh(patchOf[player])
		local income = math.max(Config.CandyPackIncomeFloor, player:GetAttribute("Income") or 0)
		return math.floor(Config.CandyPackMinutes[name] * 60 * income + 0.5)
	end

	-- Gives the product and returns the thank-you hint. Errors on an unknown product.
	local function grantProduct(player: Player, name: string): string
		if name == "CandySmall" or name == "CandyBig" then
			local candy = Helpers.candyValue(player)
			assert(candy, "no leaderstats")
			local amount = productCandy(player, name)
			-- Straight to the balance: bought candy stays off the lifetime board.
			candy.Value += amount
			return string.format("Thank you! +%s candy", Helpers.short(amount))
		end
		error("unknown product " .. name)
	end

	-- Idempotent: granted PurchaseIds live in the save, and PurchaseGranted is returned only once
	-- the grant (with its PurchaseId) is saved. Anything else is retried later by Roblox.
	Services.MarketplaceService.ProcessReceipt = function(receipt)
		local player = Services.Players:GetPlayerByUserId(receipt.PlayerId)
		local name = productById[receipt.ProductId]
		local done = player and receiptsOf[player]
		if not player or not name or not done or not Helpers.isLoaded(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		-- Already in the list: granted before (maybe its save failed); only the save is retried.
		if not table.find(done, receipt.PurchaseId) then
			local ok, message = pcall(grantProduct, player, name)
			if not ok then
				warn("[Patch] Could not grant", name, "to", player.Name, message)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			table.insert(done, receipt.PurchaseId)
			while #done > RECEIPTS_KEPT do
				table.remove(done, 1)
			end
			Remotes.hintEvent:FireClient(player, message)
			shopFunnel(player, 3)
		end
		-- No store (unpublished Studio): nothing to save, so the grant stands.
		if store and not savePlayer(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- "open" logs the funnel and returns the candy each candy product would give right now.
	Remotes.shopFunction.OnServerInvoke = function(player: Player, action: unknown)
		if action == "open" then
			shopFunnel(player, 1)
			return {
				CandySmall = productCandy(player, "CandySmall"),
				CandyBig = productCandy(player, "CandyBig"),
			}
		elseif action == "prompt" then
			shopFunnel(player, 2)
		end
		return nil
	end
end

-- Progression extends the pen, carry stack, Index and Haunt RPC.
do
	function Progress.load(player, saved)
		local d = type(saved) == "table" and saved or {}
		Progress.data[player] = {
			owned = type(d.owned) == "table" and d.owned or {},
			stamps = type(d.stamps) == "table" and d.stamps or {},
			quests = type(d.quests) == "table" and d.quests or {},
			slots = math.clamp(
				tonumber(d.slots) or Config.Progression.baseSlots,
				Config.Progression.baseSlots,
				Config.Progression.castleSlots
			),
			rebirths = math.clamp(tonumber(d.rebirths) or 0, 0, Config.Progression.rebirthCap),
			crates = math.max(0, tonumber(d.crates) or 0),
			cleaver = d.cleaver == true,
			raidAt = tonumber(d.raidAt) or 0,
			candyFraction = tonumber(d.candyFraction) or 0,
		}
		player:SetAttribute("Rebirths", Progress.data[player].rebirths)
		player:SetAttribute("CleaverSkin", d.cleaver == true)
		Progress.arrive(player)
	end
	function Progress.rarityRank(id)
		local seed = Lookup.seedById[id]
		return seed and Config.Economy.rarityRanks[Config.Pets[seed.pet].rarity] or 0
	end
	function Progress.updateBonus(player, saved)
		if (tonumber(saved.saveVersion) or 0) >= Config.Economy.saveVersion then
			return
		end
		local bonus = 0
		for _, entry in type(saved.placed) == "table" and saved.placed or {} do
			local seed = type(entry) == "table" and Lookup.seedById[entry.s]
			local old = seed and Config.Economy.legacyIncome[seed.id]
			if old then
				local mutation = Lookup.mutationById[entry.m or ""]
				bonus += math.max(0, old - seed.income) * math.clamp(tonumber(entry.z) or 1, 0.1, 5) * (entry.h and Config.HoardMult or 1) * (mutation and mutation.mult or 1) * (entry.g and Config.Progression.goldIncome or 1) * (entry.y and Config.Progression.shinyIncome or 1)
			end
		end
		bonus = math.floor(
			bonus
					* Config.Economy.updateBonusSeconds
					* Helpers.sellMult(player)
					* Progress.candyMult(player)
				+ 0.5
		)
		if bonus > 0 then
			local candy = Helpers.candyValue(player)
			candy.Value += bonus
			Remotes.hintEvent:FireClient(
				player,
				"Update bonus: +" .. Helpers.short(bonus) .. " candy"
			)
		end
	end
	function Progress.complete(player, zone)
		local d = Progress.data[player]
		local q = d and zone and d.quests[zone]
		return q ~= nil
			and (q.smash or 0) >= Config.Progression.questSmashes
			and (q.steal or 0) >= Config.Progression.questSteals
			and q.own == true
	end
	function Progress.publish(player)
		local d = Progress.data[player]
		if not d then
			return
		end
		local count = 0
		for _, id in Config.ZoneOrder do
			if d.stamps[id] then
				count += 1
			end
		end
		player:SetAttribute("ZoneStamps", count)
		player:SetAttribute("KingCrates", d.crates)
		player:SetAttribute(
			"ZoneProgress",
			Services.HttpService:JSONEncode({
				quests = d.quests,
				stamps = d.stamps,
				owned = d.owned,
			})
		)
	end
	function Progress.quest(player, zone, kind, amount)
		local d = Progress.data[player]
		if not d or not Config.Zones[zone] or not hasZone(player, zone) then
			return
		end
		local was = Progress.complete(player, zone)
		local q = d.quests[zone] or { smash = 0, steal = 0, own = false }
		d.quests[zone] = q
		if kind == "own" then
			q.own = true
		else
			local cap = kind == "smash" and Config.Progression.questSmashes
				or Config.Progression.questSteals
			q[kind] = math.min(cap, (q[kind] or 0) + (amount or 1))
		end
		Progress.publish(player)
		if not was and Progress.complete(player, zone) then
			Remotes.announceEvent:FireClient(
				player,
				zone == "Zone7" and "Zone quest complete! Rebirth unlocked"
					or "Zone quest complete! Next gate 25% off"
			)
		end
	end
	function Progress.own(player, seedId)
		local d = Progress.data[player]
		if not d or not Lookup.seedById[seedId] then
			return
		end
		d.owned[seedId] = true
		for _, id in Config.ZoneOrder do
			local pets = Config.Zones[id].pets
			if table.find(pets, seedId) then
				Progress.quest(player, id, "own")
			end
			if d.owned[pets[1]] and d.owned[pets[2]] then
				d.stamps[id] = true
			end
		end
		Progress.publish(player)
	end
	function Progress.arrive(player)
		local d = Progress.data[player]
		if not d then
			return
		end
		local ownedPatch = patchOf[player]
		local previousSlots = ownedPatch
				and ownedPatch:GetAttribute("SlotLookOwner") == player.UserId
				and ownedPatch:GetAttribute("PenSlots")
			or nil
		if hasZone(player, "Zone3") then
			d.slots = math.max(d.slots, Config.Progression.woodsSlots)
		end
		if hasZone(player, "Zone5") then
			d.slots = math.max(d.slots, Config.Progression.castleSlots)
		end
		local patch = patchOf[player]
		if patch then
			Bases.layout(patch)
			Bases.slotLook(
				patch,
				d.slots,
				previousSlots and d.slots > previousSlots and previousSlots or nil
			)
			patch:SetAttribute("SlotLookOwner", player.UserId)
			patch:SetAttribute("PenSlots", d.slots)
			player:SetAttribute("PenSlots", d.slots)
		end
		player:SetAttribute("Unlock_Fuse", hasZone(player, "Zone3"))
		player:SetAttribute("Unlock_Witch", hasZone(player, "Zone4"))
		player:SetAttribute(
			"Unlock_Haunt",
			hasZone(player, "Zone7") and Progress.complete(player, "Zone7")
		)
		for _, id in Config.ZoneOrder do
			local pets = Config.Zones[id].pets
			local q = d.quests[id]
			if
				hasZone(player, id)
				and (d.owned[pets[1]] or d.owned[pets[2]])
				and not (q and q.own)
			then
				Progress.quest(player, id, "own")
			end
		end
		Progress.publish(player)
		if Bases.drainCarry and Progress.pending[player] then
			task.defer(Bases.drainCarry, player)
		end
	end
	function Bases.carryEntry(p)
		local egg = p:GetAttribute("HatchSize")
		return {
			s = p:GetAttribute("Seed"),
			z = p:GetAttribute("SizeMult"),
			m = p:GetAttribute("Mutation"),
			h = p:GetAttribute("Hoard"),
			j = p:GetAttribute("Jack"),
			w = p:GetAttribute("WeightKg"),
			e = typeof(egg) == "Vector3" and { egg.X, egg.Y, egg.Z } or nil,
			g = p:GetAttribute("Gold"),
			y = p:GetAttribute("Shiny"),
			b = p:GetAttribute("Boss"),
			u = p:GetAttribute("Bought"),
			a = p:GetAttribute("PlacedAt"),
			r = p:GetAttribute("GoldRolled"),
		}
	end
	function Bases.collectCarry(player)
		local entries = table.clone(Progress.pending[player] or {})
		for _, p in carrying[player] or {} do
			if
				p.Parent
				and not p:GetAttribute("HoardZone")
				and (not p:GetAttribute("StolenFrom") or not Services.Players:GetPlayerByUserId(
					p:GetAttribute("StolenFrom")
				) or p:GetAttribute("StolenFrom") == player.UserId)
				and (p:GetAttribute("Jack") or p:GetAttribute("Hoard"))
			then
				table.insert(entries, Bases.carryEntry(p))
			end
		end
		return entries
	end
	function Bases.restoreCarry(player, entries)
		Progress.pending[player] = {}
		for _, e in type(entries) == "table" and entries or {} do
			local id = type(e) == "table" and (e.s or e.seed or e.Seed)
			if
				id
				and Lookup.seedById[id]
				and (e.h == true or e.j == true or e.hoard == true or e.jack == true)
			then
				table.insert(Progress.pending[player], {
					s = id,
					z = tonumber(e.z or e.size) or 1,
					m = e.m or e.mutation,
					h = e.h == true or e.hoard == true,
					j = e.j == true or e.jack == true,
					w = tonumber(e.w or e.weight),
					e = e.e,
					g = e.g == true,
					y = e.y == true,
					b = e.b == true,
					u = e.u == true or e.b == true,
					a = tonumber(e.a),
					r = e.r == true,
				})
			end
		end
		task.defer(Bases.drainCarry, player)
	end
	function Bases.drainCarry(player)
		if not aliveRoot(player) or Progress.draining[player] or not Progress.pending[player] then
			return
		end
		if
			not Bases.empty(patchOf[player])
			and #(carrying[player] or {}) >= Helpers.carryCapacity(player)
		then
			return
		end
		Progress.draining[player] = true
		local entries = Progress.pending[player]
		Progress.pending[player] = nil
		local delivered = 0
		for _, e in entries or {} do
			local p = makePumpkin(e.s, tonumber(e.z) or 1)
			p:SetAttribute("Hoard", e.h == true)
			p:SetAttribute("Jack", e.j == true)
			p:SetAttribute("WeightKg", e.w)
			p:SetAttribute("HatchSize", Helpers.savedHatchSize(e.e))
			p:SetAttribute("Gold", e.g)
			p:SetAttribute("Shiny", e.y)
			p:SetAttribute("Boss", e.b)
			p:SetAttribute("Bought", e.u == true or e.b == true)
			p:SetAttribute("PlacedAt", e.a)
			p:SetAttribute("GoldRolled", e.r)
			if e.m and Lookup.mutationById[e.m] then
				p:SetAttribute("Mutation", e.m)
				applyMutationLook(p, e.m)
			end
			if e.j then
				Looks.hatch(p, Lookup.seedById[e.s])
			else
				Hoards.look(p)
			end
			local plot = Bases.empty(patchOf[player])
			if plot then
				Bases.put(plot, e.s, tonumber(e.z) or 1, e.m, player.UserId, Bases.extraOf(p))
				p:Destroy()
				delivered += 1
			elseif not stackPumpkin(player, p) then
				p:Destroy()
				Progress.pending[player] = Progress.pending[player] or {}
				table.insert(Progress.pending[player], e)
			else
				delivered += 1
			end
		end
		Bases.refresh(patchOf[player])
		refreshCarry(player)
		Progress.draining[player] = nil
		if delivered > 0 then
			Remotes.hintEvent:FireClient(player, "Pending pets delivered: " .. delivered)
		end
	end
	function Bases.leaveCarry(player, at)
		Progress.pending[player] = Bases.collectCarry(player)
		for _, p in carrying[player] or {} do
			local victim = Services.Players:GetPlayerByUserId(p:GetAttribute("StolenFrom") or 0)
			if p:GetAttribute("HoardZone") then
				Hoards.giveBack(p, at)
			elseif victim and victim ~= player then
				Bases.giveBack(victim, p, at)
			else
				p:Destroy()
			end
		end
		carrying[player] = {}
	end
	function Progress.rebirth(player)
		local d = Progress.data[player]
		local candy = Helpers.candyValue(player)
		if
			not Helpers.isLoaded(player)
			or not d
			or not hasZone(player, "Zone7")
			or not Progress.complete(player, "Zone7")
		then
			return false, "Finish the Throne quest"
		end
		if d.rebirths >= Config.Progression.rebirthCap then
			return false, "MAX"
		end
		local legendary = false
		for _, plot in Bases.plots(patchOf[player]) do
			local p = plotState[plot].pumpkin
			local seed = p and Lookup.seedById[p:GetAttribute("Seed")]
			if seed and Progress.rarityRank(seed.id) >= Config.Economy.rarityRanks.Legendary then
				legendary = true
			end
		end
		if not legendary then
			return false, "Own a Legendary pet"
		end
		if not candy or candy.Value < Config.Progression.rebirthCost then
			return false, "Need 5M candy"
		end
		candy.Value = Config.StartCandy
		d.candyFraction = 0
		d.rebirths += 1
		player:SetAttribute("Rebirths", d.rebirths)
		toolsOf[player] = { [Config.StartTool] = true }
		publishTools(player)
		giveTool(player, true)
		zonesOf[player] = {}
		publishZones(player)
		d.quests = {}
		-- Pets, pen and stamps survive; quests start again on the new ladder.
		Progress.arrive(player)
		Bases.refresh(patchOf[player])
		Remotes.hintEvent:FireClient(player, "Rebirth! +25% candy")
		return true
	end
	function Progress.fuse(player)
		if not Helpers.isLoaded(player) or not hasZone(player, "Zone3") then
			return false
		end
		local groups = {}
		for _, plot in Bases.plots(patchOf[player]) do
			local p = plotState[plot].pumpkin
			if p and p:GetAttribute("Jack") and not p:GetAttribute("Stashed") then
				local id = p:GetAttribute("Seed")
				groups[id] = groups[id] or {}
				table.insert(groups[id], plot)
			end
		end
		for id, plots in groups do
			if #plots >= Config.Progression.fuseCount then
				local best = plots[1]
				for _, plot in plots do
					if
						(plotState[plot].pumpkin:GetAttribute("WeightKg") or 0)
						> (plotState[best].pumpkin:GetAttribute("WeightKg") or 0)
					then
						best = plot
					end
				end
				local p = plotState[best].pumpkin
				local extra = Bases.extraOf(p)
				extra.weight = (
					extra.weight
					or Config.PetSizes[Config.Pets[Lookup.seedById[id].pet].rarity].median
				) * Config.Progression.fuseWeight
				extra.shiny = extra.shiny or math.random() < Config.Progression.shinyChance
				local size, mutation = p:GetAttribute("SizeMult") or 1, p:GetAttribute("Mutation")
				local used = 0
				for _, plot in plots do
					if plot == best or used < Config.Progression.fuseCount - 1 then
						if plot ~= best then
							used += 1
						end
						Bases.take(plot):Destroy()
					end
				end
				local fused = Bases.put(best, id, size, mutation, player.UserId, extra)
				Bases.refresh(patchOf[player])
				Reveal.send(player, fused, false, "jack")
				Remotes.hintEvent:FireClient(
					player,
					extra.shiny and "SHINY fusion! Weight x1.5" or "Fused! Weight x1.5"
				)
				return true
			end
		end
		Remotes.hintEvent:FireClient(player, "Place 3 of the same pet to fuse")
		return false
	end
	Progress.witch = {}
	Progress.raidWarnings = {}
	function Progress.raidCheck()
		if Config.Raid.grace >= 1e9 or Purge.active() or state:GetAttribute("PurgeWarning") then
			return 0
		end
		local warned = {}
		local count = 0
		for player, patch in patchOf do
			if Progress.raidEligible(player, patch) and not Progress.raidWarnings[player] then
				warned[player] = true
				count += 1
				Progress.raidWarnings[player] = true
			end
		end
		if count > 0 then
			task.delay(Config.Raid.warning, function()
				if not Purge.active() and not state:GetAttribute("PurgeWarning") then
					for _ = 1, count do
						if not spawnGhost(warned) then
							break
						end
					end
				end
				for player in warned do
					Progress.raidWarnings[player] = nil
				end
			end)
		end
		return count
	end
	function Progress.restock()
		Progress.witch = {}
		Progress.witchStock = {}
		for i = 1, Config.Progression.witchOffers do
			local zone = Config.ZoneOrder[math.random(4, 7)]
			local id = Config.Zones[zone].pets[math.random(2)]
			local delivered = makePumpkin(id, Config.HoardSize)
			delivered:SetAttribute("Hoard", true)
			Progress.witch[i] = {
				seed = id,
				zone = zone,
				price = math.floor(
					pumpkinValue(delivered, Config.Progression.witchPriceSeconds)
							* Config.Progression.witchPriceMult
						+ 0.5
				),
			}
			delivered:Destroy()
		end
		state:SetAttribute("WitchOffers", Services.HttpService:JSONEncode(Progress.witch))
		state:SetAttribute(
			"WitchRestockAt",
			workspace:GetServerTimeNow() + Config.Progression.witchRestock
		)
	end
	function Progress.buyWitch(player, slot)
		local offer = Progress.witch[slot]
		local stock = Progress.witchStock[player.UserId] or {}
		if stock[slot] then
			Remotes.hintEvent:FireClient(player, "Sold out for you! Wait for restock")
			return
		end
		local candy = Helpers.candyValue(player)
		if
			not Helpers.isLoaded(player)
			or not hasZone(player, "Zone4")
			or not offer
			or not hasZone(player, offer.zone)
			or not candy
			or candy.Value < offer.price
		then
			Remotes.hintEvent:FireClient(player, "Unlock the pet's zone and bring enough candy")
			return
		end
		local plot = Bases.empty(patchOf[player])
		if not plot then
			Remotes.hintEvent:FireClient(player, "Make room in your pen first")
			return
		end
		candy.Value -= offer.price
		stock[slot] = true
		Progress.witchStock[player.UserId] = stock
		Bases.put(
			plot,
			offer.seed,
			Config.HoardSize,
			nil,
			player.UserId,
			{ hoard = true, bought = true }
		)
		Bases.refresh(patchOf[player])
	end
	local pot = cauldronFolder:FindFirstChildWhichIsA("Model")
	local fusePart = pot and pot:FindFirstChild("Pot") or cauldronFolder:FindFirstChild("Pot", true)
	local function prompt(part, name, action, handler)
		if not part or not part:IsA("BasePart") then
			return
		end
		local p = Instance.new("ProximityPrompt")
		p.Name = name
		p.ActionText = action
		p.HoldDuration = 0.3
		p.MaxActivationDistance = Config.Progression.promptRange
		p.RequiresLineOfSight = false
		p.Parent = part
		p.Triggered:Connect(function(player)
			local _, root = aliveRoot(player)
			if
				root
				and (root.Position - part.Position).Magnitude
					<= Config.Progression.promptRange + 2
			then
				handler(player)
			end
		end)
		return p
	end
	local fusePrompt = prompt(fusePart, "FusePrompt", "Fuse 3 same pets", Progress.fuse)
	if fusePrompt then
		fusePrompt.KeyboardKeyCode = Enum.KeyCode.F
		fusePrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
		fusePrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	end
	for i = 1, Config.Progression.witchOffers do
		local p = prompt(
			market.Sell:FindFirstChild("PromptPart"),
			"WitchOffer" .. i,
			"Witch offer",
			function(player)
				Progress.buyWitch(player, i)
			end
		)
		if p then
			p.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
			p.KeyboardKeyCode = ({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C })[i]
			state:GetAttributeChangedSignal("WitchOffers"):Connect(function()
				local offer = Progress.witch[i]
				p.ActionText = Lookup.seedById[offer.seed].name
					.. " ("
					.. Helpers.short(offer.price)
					.. " candy)"
			end)
		end
	end
	Progress.restock()
end

do
	function Progress.contains(shape, pos)
		if math.abs(pos.Y - shape.pos.Y) > 8 then
			return false
		end
		if shape.cf then
			local v = shape.cf:PointToObjectSpace(pos)
			return math.abs(v.X) <= shape.width / 2 and math.abs(v.Z) <= shape.length / 2
		end
		local radius = Vector3.new(pos.X - shape.pos.X, 0, pos.Z - shape.pos.Z).Magnitude
		return radius <= shape.radius and radius >= (shape.inner or 0)
	end
	function Progress.slow(player, mult, seconds, icon)
		seconds = math.min(seconds, Config.GuardTwists.slowCap)
		local untilAt = workspace:GetServerTimeNow() + seconds
		if
			(player:GetAttribute("GuardEffectUntil") or 0) > untilAt
			and (player:GetAttribute("WalkSpeedMultiplier") or 1) <= mult
		then
			return
		end
		player:SetAttribute("WalkSpeedMultiplier", mult)
		player:SetAttribute("GuardEffectUntil", untilAt)
		player:SetAttribute("GuardEffectIcon", icon)
		local character = player.Character
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = Config.walkSpeed(Helpers.upgradeLevel(player, "Boots")) * mult
		end
		task.delay(seconds, function()
			if player.Parent and player:GetAttribute("GuardEffectUntil") == untilAt then
				player:SetAttribute("WalkSpeedMultiplier", 1)
				player:SetAttribute("GuardEffectIcon", nil)
				local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if h then
					h.WalkSpeed = Config.walkSpeed(Helpers.upgradeLevel(player, "Boots"))
				end
			end
		end)
	end
	function Progress.bossCandy(player)
		local zone = Config.Zones.Zone1
		for _, id in Config.ZoneOrder do
			if hasZone(player, id) then
				zone = Config.Zones[id]
			end
		end
		local damage = bestTool(player).damage
		local swings = math.max(
			1,
			math.ceil(
				zone.hp / (damage * (1 + Config.Farm.critChance * (Config.Farm.critMult - 1)))
			)
		)
		return math.floor(
			Config.KingNight.farmSeconds * zone.candy / (swings * Config.BonkCooldown)
		)
	end
	function Progress.bossCrate(player, finisher)
		local d = Progress.data[player]
		if not d then
			return nil
		end
		d.crates += 1
		local cfg = Config.KingNight
		local tier = 1
		local zoneIndex = 1
		for i, id in Config.ZoneOrder do
			if hasZone(player, id) then
				zoneIndex = i
			end
		end
		local kinglet = cfg.rarityWeights[4] / 100 + (finisher and cfg.finisherBonus or 0)
		if d.crates % cfg.pity == 0 or math.random() < kinglet then
			tier = 4
		else
			local value = math.random()
				* (cfg.rarityWeights[1] + cfg.rarityWeights[2] + cfg.rarityWeights[3])
			for i = 1, 3 do
				value -= cfg.rarityWeights[i]
				if cfg.rarityWeights[i] > 0 and value <= 0 then
					tier = i
					break
				end
			end
		end
		local seed = Config.Economy.crateSeed(zoneIndex, tier, math.random(2))
		local isNew = Reveal.isNew(player, seed)
		local gold = Looks.rollGold(player, nil)
		local plot = Bases.empty(patchOf[player])
		local p
		if plot then
			p = Bases.put(plot, seed, Config.HoardSize, nil, player.UserId, {
				hoard = true,
				jack = true,
				boss = true,
				bought = true,
				gold = gold,
				goldRolled = true,
			})
		else
			p = makePumpkin(seed, Config.HoardSize)
			p:SetAttribute("Hoard", true)
			p:SetAttribute("Jack", true)
			p:SetAttribute("Boss", true)
			p:SetAttribute("Bought", true)
			p:SetAttribute("Gold", gold)
			p:SetAttribute("GoldRolled", true)
			Looks.hatch(p, Lookup.seedById[seed])
			if not stackPumpkin(player, p) then
				Progress.pending[player] = Progress.pending[player] or {}
				table.insert(Progress.pending[player], {
					s = seed,
					z = Config.HoardSize,
					h = true,
					j = true,
					b = true,
					u = true,
					g = gold,
					r = true,
					w = p:GetAttribute("WeightKg"),
				})
				p:Destroy()
				p = nil
			end
			Remotes.hintEvent:FireClient(
				player,
				"Boss pumpkin delivered! Pens full: place to swap your weakest pet, or visit the Witch"
			)
		end
		Progress.own(player, seed)
		local found = indexOf[player] or {}
		indexOf[player] = found
		found[seed .. ":Plain"] = true
		publishIndex(player)
		unlocked[player] = unlocked[player] or startUnlocked()
		unlocked[player][seed] = true
		if p then
			p.Name = "BossPumpkin"
			Reveal.send(player, p, isNew, "jack")
		end
		Bases.refresh(patchOf[player])
		refreshCarry(player)
		return seed
	end
	function Progress.kingRewards(won)
		local list = {}
		for player, damage in king.damage do
			if player.Parent and Helpers.isLoaded(player) then
				table.insert(list, { player = player, damage = damage })
			end
		end
		table.sort(list, function(a, b)
			return a.damage > b.damage
		end)
		local podium = {}
		for i = 1, math.min(3, #list) do
			table.insert(podium, list[i].player.DisplayName)
		end
		local payouts = {}
		local mvp = won and list[1] and list[1].player or nil
		for rank, entry in list do
			local player = entry.player
			local qualified = (king.hits[player] or 0) >= Config.KingNight.hits
				or entry.damage >= king.maxHp * Config.KingNight.damageShare
			local amount = qualified
					and math.floor(
						Progress.bossCandy(player) * (won and 1 or Config.KingNight.consolation)
					)
				or 0
			local before = Helpers.candyValue(player).Value
			addCandy(player, amount)
			amount = Helpers.candyValue(player).Value - before
			payouts[tostring(player.UserId)] = amount
			local crates = {}
			if won and qualified then
				table.insert(crates, Progress.bossCrate(player, player == king.lastHitter))
				if rank <= 3 then
					table.insert(crates, Progress.bossCrate(player, player == king.lastHitter))
				end
				local stats = player:FindFirstChild("leaderstats")
				if stats and stats:FindFirstChild("Kings") then
					stats.Kings.Value += 1
				end
			end
			Remotes.kingDoneEvent:FireClient(player, "results", {
				damage = entry.damage,
				hits = king.hits[player] or 0,
				rank = rank,
				candy = amount,
				crates = crates,
				podium = podium,
				won = won,
				qualified = qualified,
				pity = Config.KingNight.pity - Progress.data[player].crates % Config.KingNight.pity,
			})
		end
		if mvp and Progress.data[mvp] then
			Progress.data[mvp].cleaver = true
			mvp:SetAttribute("CleaverSkin", true)
			giveTool(mvp, true)
		end
		for _, p in Services.Players:GetPlayers() do
			p:SetAttribute("MVP", p == mvp)
		end
		return payouts, mvp
	end

	local holder = Instance.new("Part")
	holder.Name = "KingJoinRing"
	holder.Size = Vector3.one
	holder.Anchored = true
	holder.Transparency = 1
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.CFrame = CFrame.new(king.groundHome + Vector3.new(0, 0.2, 24))
		* CFrame.Angles(math.pi / 2, 0, 0)
	holder.Parent = market
	local ring = Instance.new("CylinderHandleAdornment")
	ring.Adornee = holder
	ring.Radius = 6
	ring.InnerRadius = 5.3
	ring.Height = 0.2
	ring.Color3 = Color3.fromRGB(255, 205, 40)
	ring.Transparency = 0.1
	ring.Parent = holder
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "KingJoinPrompt"
	prompt.ActionText = "Join King Fight"
	prompt.ObjectText = "Pumpkin King throne"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = holder
	local function refreshEntry()
		local open = state:GetAttribute("KingActive") == true
			or state:GetAttribute("KingWarning") == true
		prompt.Enabled = open
		ring.Visible = open
	end
	state:GetAttributeChangedSignal("KingWarning"):Connect(refreshEntry)
	state:GetAttributeChangedSignal("KingActive"):Connect(refreshEntry)
	refreshEntry()
	local function joinKing(player)
		local _, root = aliveRoot(player)
		if
			not Helpers.isLoaded(player)
			or not root
			or not prompt.Enabled
			or (root.Position - holder.Position).Magnitude > prompt.MaxActivationDistance + 2
		then
			return
		end
		if not Unlock.has(player, "King") then
			Remotes.hintEvent:FireClient(player, "King Fight unlocks after 10 minutes of play")
			return
		end
		if #(carrying[player] or {}) > 0 or Hoards.targets(player) then
			Remotes.hintEvent:FireClient(player, "Put down your pets and escape the guardian first")
			return
		end
		kingAddPlayer(player)
		Remotes.hintEvent:FireClient(
			player,
			king.active and "King Fight: bonk the King with your scythe!"
				or "King Fight starts soon: wait by the throne!"
		)
	end
	prompt.Triggered:Connect(joinKing)
	Remotes.kingJoinEvent.OnServerEvent:Connect(joinKing)
	function Progress.kingClock()
		local at = state:GetAttribute("KingWakesAt") or 0
		local now = workspace:GetServerTimeNow()
		if
			king.active
			or Purge.active()
			or state:GetAttribute("PurgeWarning")
			or Spooky.active()
		then
			return
		end
		if now >= at then
			setKingWakes()
			task.spawn(startBloodMoon, true)
		elseif at - now <= Config.KingNight.warning and not state:GetAttribute("KingWarning") then
			state:SetAttribute("KingWarning", true)
			Remotes.announceEvent:FireAllClients("PUMPKIN KING RISES! PET + LOOT!")
		end
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "KingLoot"
	bb.Size = UDim2.fromOffset(440, 150)
	bb.StudsOffsetWorldSpace = Config.KingNight.signOffset
	bb.MaxDistance = 60
	bb.Parent = market.Plaza
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(30, 12, 40)
	label.TextColor3 = Color3.fromRGB(255, 214, 80)
	label.FontFace = Helpers.fontFace("title")
	label.TextScaled = false
	label.Parent = bb
	task.spawn(function()
		while label.Parent do
			local fighting = state:GetAttribute("KingActive") == true
			local ends = state:GetAttribute(fighting and "PhaseEnds" or "KingWakesAt")
				or workspace:GetServerTimeNow()
			local left = math.max(0, math.ceil(ends - workspace:GetServerTimeNow()))
			label.Text = string.format(
				"PUMPKIN KING\n%s %dm %02ds\nHold E at the throne | Scythe hits earn pets + candy",
				fighting and "Fight ends in" or "Arrives in",
				math.floor(left / 60),
				left % 60
			)
			task.wait(0.5)
		end
	end)
	label.Parent = bb
end

-- Players --------------------------------------------------------------------------------------

local function cleanupPlayer(player: Player)
	releasePatch(player)
	carrying[player] = nil
	Progress.data[player] = nil
	Progress.raidWarnings[player] = nil
	Progress.pending[player] = nil
	Progress.draining[player] = nil
	Progress.effects[player] = nil
	loaded[player] = nil
	saving[player] = nil
	released[player] = nil
	indexOf[player] = nil
	Helpers.Index.claims[player], Helpers.Index.milestones[player] = nil, nil
	lastBonk[player] = nil
	bonkSpot[player] = nil
	kingDropPlayer(player)
	king.damage[player] = nil
	orders[player] = nil
	unlocked[player] = nil
	lifetime[player] = nil
	dailyOf[player] = nil
	skillsOf[player] = nil
	receiptsOf[player] = nil
	onboardOf[player] = nil
	shopFunnelOf[player] = nil
	toolsOf[player] = nil
	zonesOf[player] = nil
	Bases.left[player] = nil
	Bases.incomeCarry[player] = nil
	Bases.carvedOf[player] = nil
end

local function onCharacter(player: Player, character: Model)
	carrying[player] = {}
	refreshCarry(player)
	player:SetAttribute("GuardEffectUntil", nil)
	player:SetAttribute("WalkSpeedMultiplier", 1)
	player:SetAttribute("GuardEffectIcon", nil)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	if character:WaitForChild("HumanoidRootPart", 10) then
		Bases.drainCarry(player)
	end
	humanoid.Died:Connect(function()
		-- Stolen pumpkins go back to their owners; the rest are lost.
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		Bases.dropStolen(player, root and root.Position or Vector3.zero)
		refreshCarry(player)
	end)
	-- The scythe: after the new Backpack exists (it is rebuilt on every spawn).
	task.delay(0.3, function()
		if player.Parent and player.Character == character then
			giveTool(player, true)
		end
	end)
	if character:WaitForChild("Head", 10) then
		refreshVipTag(player)
	end
end

local function onPlayerAdded(player: Player)
	player:SetAttribute(
		"IsAdmin",
		player.UserId == Config.Admin.userId or Services.RunService:IsStudio()
	)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local candy = Instance.new("IntValue")
	candy.Name = "Candy"
	candy.Value = Config.StartCandy
	candy.Parent = stats
	local kings = Instance.new("IntValue")
	kings.Name = "Kings"
	kings.Parent = stats
	player:SetAttribute("Carry", 0)
	player:SetAttribute("Income", 0)
	-- Session start; "PlayTime" (saved total seconds played) drives the unlock gates and the
	-- new-player shield, "SessionTime" counts this session only.
	player:SetAttribute("JoinedAt", workspace:GetServerTimeNow())
	player:SetAttribute("PlayTime", 0)
	player:SetAttribute("SessionTime", 0)
	player:SetAttribute("LastActiveAt", workspace:GetServerTimeNow())
	for id in Config.Upgrades do
		player:SetAttribute("Up_" .. id, 0)
	end
	unlocked[player] = startUnlocked()
	skillsOf[player] = {}
	publishSkills(player)
	toolsOf[player] = { [Config.StartTool] = true }
	publishTools(player)
	zonesOf[player] = {}
	publishZones(player)

	-- Patch and character hookup first: the load below yields.
	if not claimPatch(player) then
		Remotes.hintEvent:FireClient(
			player,
			"Server full of farmers! Sending you to another server..."
		)
		task.delay(5, function()
			if player.Parent then
				player:Kick("Server full of farmers. Please join another server!")
			end
		end)
		return
	end
	recomputeJack()
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end

	local ok, data, status = loadPlayer(player)
	if not player.Parent then
		if loaded[player] then
			releaseLock(player)
		end
		cleanupPlayer(player)
		return
	end
	if not ok then
		player:Kick(
			status == "locked"
					and "Your farm is still saving on another server. Please rejoin in a moment!"
				or "We couldn't load your farm. Please rejoin in a minute!"
		)
		return
	end
	local applied, err = pcall(applyData, player, type(data) == "table" and data or {})
	if not applied then
		-- Never save over data we could not read.
		warn("[Patch] Bad save data for", player.Name, err)
		if loaded[player] then
			loaded[player] = nil
			releaseLock(player)
		end
		player:Kick("We couldn't load your farm. Please rejoin in a minute!")
		return
	end
	publishOrders(player)
	refreshCarry(player)
	giveTool(player, true)
	Bases.refresh(patchOf[player])
	-- Unlock flags before Loaded, so clients never announce a gate a returning player already had.
	Unlock.refresh(player)
	player:SetAttribute("Loaded", true)
	Unlock.badge(player, "Welcome")
	onboard(player, 1)
	kingAddPlayer(player)
	claimDaily(player)
	checkPasses(player)
end

Services.Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Services.Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Services.Players.PlayerRemoving:Connect(function(player)
	-- Return unresolved Purge thefts before the victim's save is collected.
	for p, entry in Purge.transit do
		if entry.owner == player and p.Parent then
			local stack = carrying[entry.thief] or {}
			local i = table.find(stack, p)
			if i then
				table.remove(stack, i)
			end
			if Bases.empty(patchOf[player]) then
				Bases.giveBack(player, p, p.Position)
			else
				Progress.pending[player] = Progress.pending[player] or {}
				table.insert(Progress.pending[player], Bases.carryEntry(p))
				Purge.transit[p] = nil
				p:Destroy()
			end
			Bases.restack(entry.thief)
			refreshCarry(entry.thief)
		end
	end
	Purge.holds[player] = nil
	-- Stolen pumpkins go home; the base is copied for the save before the patch is released.
	local _, root = aliveRoot(player)
	Bases.leaveCarry(player, root and root.Position or Vector3.zero)
	Bases.left[player] = Bases.collect(player)
	releasePatch(player)
	-- Rescale now: the save below yields for a while.
	kingDropPlayer(player)
	recomputeJack()
	savePlayer(player, true)
	cleanupPlayer(player)
	recomputeJack()
end)

game:BindToClose(function()
	local pending = 0
	for _, player in Services.Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			pcall(savePlayer, player, true)
			pending -= 1
		end)
	end
	-- inFlight also covers PlayerRemoving saves that started before shutdown.
	local started = os.clock()
	while (pending > 0 or inFlight > 0) and os.clock() - started < 25 do
		task.wait(0.1)
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.SaveEvery)
		for _, player in Services.Players:GetPlayers() do
			task.spawn(savePlayer, player)
		end
	end
end)

-- Jack goal and cadence, base income and lock timers, plus rotating order refresh.
task.spawn(function()
	local seconds = 0
	while true do
		task.wait(1)
		seconds += 1
		Progress.kingClock()
		if seconds % Config.Progression.witchRestock == 0 then
			Progress.restock()
		end
		if seconds % Config.WildRespawn == 0 then
			Wild.fill()
		end
		recomputeJack()
		local ok, err = pcall(Bases.tick)
		if not ok then
			warn("[Patch] Base tick failed:", err)
		end
		local guarded, guardErr = pcall(guardZones)
		if not guarded then
			warn("[Patch] Zone guard failed:", guardErr)
		end
		local refilled, hoardErr = pcall(Hoards.tick)
		if not refilled then
			warn("[Patch] Hoard refill failed:", hoardErr)
		end
		local spookyOk, spookyErr = pcall(Spooky.tick)
		if not spookyOk then
			warn("[Patch] Spooky Hour tick failed:", spookyErr)
		end
		local purgeOk, purgeErr = pcall(Purge.tick)
		if not purgeOk then
			warn("[Patch] Purge tick failed:", purgeErr)
		end
		-- Playtime (session and saved total) and the unlock gates it opens.
		for _, player in Services.Players:GetPlayers() do
			if Helpers.isLoaded(player) then
				local _, root = aliveRoot(player)
				if root then
					local last = Progress.effects[player]
					if not last or (root.Position - last).Magnitude > 0.5 then
						player:SetAttribute("LastActiveAt", workspace:GetServerTimeNow())
					end
					Progress.effects[player] = root.Position
				end
				player:SetAttribute(
					"IdleShield",
					workspace:GetServerTimeNow() - (player:GetAttribute("LastActiveAt") or 0)
						>= Config.Raid.idle
				)
				player:SetAttribute("PlayTime", (player:GetAttribute("PlayTime") or 0) + 1)
				player:SetAttribute("SessionTime", (player:GetAttribute("SessionTime") or 0) + 1)
				local unlockedOk, unlockErr = pcall(Unlock.refresh, player)
				if not unlockedOk then
					warn("[Patch] Unlock refresh failed:", unlockErr)
				end
			end
		end
		if seconds % 5 == 0 then
			for _, player in Services.Players:GetPlayers() do
				claimDaily(player)
			end
			for player, o in orders do
				if
					player.Parent
					and Helpers.isLoaded(player)
					and o.tut > TUTORIAL_COUNT
					and (
						os.time() >= o.refreshAt
						or (o.list[1] and Progress.orderExpired(player, o.list[1]))
					)
				then
					nextOrders(player)
					publishOrders(player)
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		pcall(refreshBoard)
		task.wait(Config.BoardRefresh)
	end
end)

-- Portraits and initial disc locks follow ownership without changing the map contract.
do
	function Purge.inside(player): boolean
		local patch = patchOf[player]
		local soil = patch and patch:FindFirstChild("Soil")
		local _, root = aliveRoot(player)
		if not soil or not root then
			return false
		end
		local at = soil.CFrame:PointToObjectSpace(root.Position)
		return math.abs(at.X) <= soil.Size.X / 2
			and math.abs(at.Z) <= soil.Size.Z / 2
			and math.abs(at.Y) <= 12
	end
	function Purge.rewardAmount(player): number
		return Config.Purge.defenceCandy
			* (table.find(Config.ZoneOrder, Purge.bestZone(player)) or 1)
	end
	function Purge.bestZone(player): string
		for i = #Config.ZoneOrder, 1, -1 do
			if hasZone(player, Config.ZoneOrder[i]) then
				return Config.ZoneOrder[i]
			end
		end
		return Config.ZoneOrder[1]
	end
	function Purge.reward(player, id)
		local counts = Purge.bonks[id or Purge.id]
		if not counts or (counts[player.UserId] or 0) >= Config.Purge.bonkRewards then
			return 0
		end
		counts[player.UserId] = (counts[player.UserId] or 0) + 1
		return addCandy(player, Purge.rewardAmount(player), true)
	end
	function Purge.settle(p)
		local entry = Purge.transit[p]
		if not entry then
			return
		end
		-- A thief who left it on the ground never completed the theft.
		if p.Parent == loose then
			if Bases.empty(patchOf[entry.owner]) then
				Bases.giveBack(entry.owner, p, p.Position)
			else
				-- A refilled pen must not turn the refund into an unrestricted loose pet.
				Progress.pending[entry.owner] = Progress.pending[entry.owner] or {}
				table.insert(Progress.pending[entry.owner], Bases.carryEntry(p))
				Purge.transit[p] = nil
				p:Destroy()
			end
			return
		end
		entry.losses[entry.owner.UserId] = true
		Purge.transit[p] = nil
		if p.Parent then
			p:SetAttribute("StolenFrom", nil)
			p:SetAttribute("Owner", entry.thief.UserId)
		end
		refreshCarry(entry.thief)
	end
	function Purge.deliveryReady(player, p): boolean
		local entry = Purge.transit[p]
		if not entry then
			return true
		end
		if workspace:GetServerTimeNow() >= entry.untilAt or Purge.inside(player) then
			Purge.settle(p)
			return true
		end
		Remotes.hintEvent:FireClient(
			player,
			"Reach your pen before placing or selling the stolen pet!"
		)
		return false
	end
	local function nextSlot(t)
		if #Config.Purge.minutes == 0 then
			return nil
		end
		local hour = math.floor(t / 3600) * 3600
		for _, minute in Config.Purge.minutes do
			if hour + minute * 60 > t then
				return hour + minute * 60
			end
		end
		return hour + 3600 + Config.Purge.minutes[1] * 60
	end
	state:SetAttribute("PurgeNext", nextSlot(workspace:GetServerTimeNow()))
	local function blocked()
		return king.active
			or state:GetAttribute("Phase") == "BloodMoon"
			or Spooky.active()
			or (state:GetAttribute("LocksOff") or 0) > workspace:GetServerTimeNow()
	end
	function Purge.penEligible(player): boolean
		local patch = patchOf[player]
		if not patch then
			return false
		end
		local pets, unprotected = 0, 0
		for _, plot in Bases.plots(patch) do
			local pet = plotState[plot] and plotState[plot].pumpkin
			if pet and pet:GetAttribute("Jack") then
				pets += 1
				if not plot:GetAttribute("Protected") and not pet:GetAttribute("Stashed") then
					unprotected += 1
				end
			end
		end
		return pets >= Config.Purge.survivorPets and unprotected > 0
	end
	function Purge.observe(player, patch, t)
		if
			not Helpers.isLoaded(player)
			or (player:GetAttribute("PlayTime") or 0) < Config.Purge.grace
		then
			return
		end
		local _, root = aliveRoot(player)
		local entry = Purge.participants[player]
		if not entry then
			entry = { seconds = 0, moved = false, at = t, position = root and root.Position }
			Purge.participants[player] = entry
		end
		if root and entry.position and (root.Position - entry.position).Magnitude > 0.5 then
			entry.moved = true
		end
		-- Count only observed time with a live, stealable pen; no catch-up credit after a stall.
		if
			root
			and not Purge.immune(player)
			and not Bases.isLocked(patch)
			and Purge.penEligible(player)
		then
			entry.seconds += math.clamp(t - entry.at, 0, 2)
		end
		entry.at, entry.position = t, root and root.Position
	end
	function Purge.start()
		if #Config.Purge.minutes == 0 then
			return false, "Purge disabled at launch"
		end
		if Purge.active() then
			return false, "Purge already active"
		end
		if blocked() then
			return false, "Wait for King Night / Spooky Hour to finish"
		end
		Purge.id += 1
		Purge.bonks[Purge.id] = {}
		Purge.bonks[Purge.id - 2] = nil
		Purge.victims, Purge.locks, Purge.holds, Purge.participants, Purge.losses =
			{}, {}, {}, {}, {}
		state:SetAttribute("PurgeId", Purge.id)
		state:SetAttribute("PurgeWarning", nil)
		state:SetAttribute("PurgeEnds", workspace:GetServerTimeNow() + Config.Purge.seconds)
		state:SetAttribute("PurgeNext", nextSlot(workspace:GetServerTimeNow()))
		for player, patch in patchOf do
			if Helpers.isLoaded(player) then
				Purge.observe(player, patch, workspace:GetServerTimeNow())
				patch:SetAttribute("PurgeRobbed", nil)
				player:SetAttribute("PurgeLockUsed", nil)
				-- One attempt per base, with the existing age, rarity, distance and cooldown rules.
				spawnGhost({ [player] = true })
			end
		end
		Remotes.announceEvent:FireAllClients("THE PURGE! Lock, steal or defend for 2 minutes")
		return true
	end
	local function finish()
		local participants, losses, id = Purge.participants, Purge.losses, Purge.id
		for player, entry in participants do
			entry.eligible = entry.moved
				and entry.seconds >= Config.Purge.survivorSeconds
				and not Purge.immune(player)
		end
		state:SetAttribute("PurgeEnds", nil)
		for player in Purge.holds do
			player:SetAttribute("PurgeStealing", nil)
		end
		Purge.holds = {}
		for i = #ghosts, 1, -1 do
			local ghost = ghosts[i]
			if ghost.purgeId == id then
				if ghost.stash then
					local owner = Services.Players:GetPlayerByUserId(
						ghost.model:GetAttribute("StashOwner") or 0
					)
					if owner then
						losses[owner.UserId] = true
					end
				else
					removeGhost(ghost)
				end
			end
		end
		-- Last-second steals retain their full bonk window before the survivor award is decided.
		task.delay(Config.Purge.returnSeconds + 0.1, function()
			for p, entry in Purge.transit do
				if entry.id == id then
					Purge.settle(p)
				end
			end
			for player, entry in participants do
				if
					entry.eligible
					and player.Parent
					and Helpers.isLoaded(player)
					and not losses[player.UserId]
					and Purge.penEligible(player)
				then
					local zone = Config.Zones[Purge.bestZone(player)]
					Progress.pending[player] = Progress.pending[player] or {}
					table.insert(Progress.pending[player], {
						s = zone.pets[math.random(#zone.pets)],
						z = Config.HoardSize,
						h = true,
						j = false,
					})
					Bases.drainCarry(player)
					Remotes.announceEvent:FireClient(player, "Purge Survivor")
				end
			end
		end)
	end
	function Purge.tick()
		if #Config.Purge.minutes == 0 and not Purge.active() then
			state:SetAttribute("PurgeWarning", nil)
			return
		end
		local t = workspace:GetServerTimeNow()
		local ends = state:GetAttribute("PurgeEnds")
		if ends then
			for player, patch in patchOf do
				if Helpers.isLoaded(player) then
					Purge.observe(player, patch, math.min(t, ends))
					if Purge.locks[player.UserId] then
						player:SetAttribute("PurgeLockUsed", Purge.id)
					end
				end
			end
			if t >= ends then
				finish()
			end
			return
		end
		local at = state:GetAttribute("PurgeNext")
		if blocked() then
			state:SetAttribute("PurgeWarning", nil)
			if t >= at then
				state:SetAttribute("PurgeNext", nextSlot(t))
			end
		elseif t >= at then
			Purge.start()
		elseif at - t <= Config.Purge.warning and not state:GetAttribute("PurgeWarning") then
			state:SetAttribute("PurgeWarning", at)
			Remotes.announceEvent:FireAllClients("THE PURGE IN 30 SECONDS! Lock or defend your pen")
		end
	end
	Services.RunService.Heartbeat:Connect(function()
		local t = workspace:GetServerTimeNow()
		for player, hold in Purge.holds do
			if
				not Purge.active()
				or Purge.immune(player)
				or not Bases.petReach(player, hold.plot)
				or t - hold.at > Config.Purge.hold + 2
			then
				Purge.holds[player] = nil
				player:SetAttribute("PurgeStealing", nil)
			end
		end
		for p, entry in Purge.transit do
			if
				not p.Parent
				or t >= entry.untilAt
				or (p.Parent == entry.thief.Character and Purge.inside(entry.thief))
			then
				Purge.settle(p)
			end
		end
	end)
end

do
	for _, patch in patchFolder:GetChildren() do
		local old = patch:FindFirstChild("OwnerPortrait", true)
		if old then
			old:Destroy()
		end
		patch:GetAttributeChangedSignal("Owner"):Connect(function()
			if (patch:GetAttribute("Owner") or 0) == 0 then
				Bases.slotLook(patch, Config.Progression.baseSlots)
			end
		end)
	end
end

-- Authored and runtime world billboards share the distance budget.
do
	local function cap(d)
		if d:IsA("BillboardGui") then
			local limit = d.Name == "OwnerSign" and 100 or 60
			d.MaxDistance = d.MaxDistance == 0 and limit or math.min(d.MaxDistance, limit)
		end
	end
	for _, d in garden:GetDescendants() do
		cap(d)
	end
	garden.DescendantAdded:Connect(cap)
end

-- Studio-only test hooks ------------------------------------------------------------------------

do
	Bases.debugAction = function(action: string, player: Player?, amount: number?, typeId: string?)
		if action == "purge" then
			return Purge.start()
		elseif action == "midnight" then
			phaseToken += 1
			local token = phaseToken
			setPhase("Midnight", Config.MidnightLength)
			Hoards.refillAll()
			Progress.raidCheck()
			task.delay(Config.MidnightLength, function()
				if token == phaseToken then
					runDay()
				end
			end)
			return #ghosts
		elseif action == "bloodmoon" then
			state:SetAttribute("JackCandy", jackGoal())
			task.spawn(startBloodMoon)
			return true
		elseif action == "zone" and player then
			for i = 1, math.clamp(math.floor(amount or 1), 1, #Config.ZoneOrder) do
				zonesOf[player][Config.ZoneOrder[i]] = true
			end
			publishZones(player)
			Progress.arrive(player)
			return true
		elseif action == "raid" then
			return Progress.raidCheck()
		elseif action == "rebirth" and player then
			return Progress.rebirth(player)
		elseif action == "fight" and player then
			return Hoards.debugFight(player)
		elseif action == "fillpens" and player then
			return Bases.fillPens(player)
		elseif action == "candy" and player then
			addCandy(player, amount or 100)
			return true
		elseif action == "spawnwild" then
			-- Fill the zone with wild pumpkins now.
			return Wild.fill()
		elseif action == "give" and player then
			-- Put N wild pumpkins of a type (4th argument, default Orange) on the player's stack.
			return Wild.give(player, amount or 1, typeId)
		elseif action == "king" or action == "kingnight" then
			-- Blood Moon without the locks-off window: the King wakes at once.
			state:SetAttribute("JackCandy", jackGoal())
			task.spawn(startBloodMoon, true)
			return true
		elseif action == "unshield" then
			-- End the new-farmer steal shield for one player (or everyone) to test stealing.
			for _, p in player and { player } or Services.Players:GetPlayers() do
				local played = p:GetAttribute("PlayTime") or 0
				p:SetAttribute("PlayTime", math.max(played, Config.NewPlayerShield))
				Unlock.refresh(p)
			end
			return true
		elseif action == "playtime" and player then
			-- Set a player's total playtime to N seconds and recompute their unlocks from scratch
			-- (e.g. 0 = brand-new, 900 = shield over, 1800 = Witch, cauldrons, retired upgrades).
			player:SetAttribute("PlayTime", math.max(0, math.floor(amount or 0)))
			Unlock.refresh(player, true)
			return player:GetAttribute("PlayTime")
		elseif action == "lock" and player then
			Bases.lock(player)
			return patchOf[player] and patchOf[player]:GetAttribute("LockedUntil")
		elseif action == "ghosts" then
			return #ghosts
		elseif action == "spooky" then
			-- Start a Spooky Hour now; the next one stays on the :25 / :45 schedule.
			Spooky.start()
			return state:GetAttribute("SpookyEnds")
		end
		return nil
	end
	if Services.RunService:IsStudio() then
		local debugFunction = Instance.new("BindableFunction")
		debugFunction.Name = "PatchDebug"
		debugFunction.Parent = Services.ServerStorage
		debugFunction.OnInvoke = Bases.debugAction
	end
	local calls = {}
	local busy = {}
	Remotes.adminFunction.OnServerInvoke = function(player, action, amount)
		if
			not (player.UserId == Config.Admin.userId or Services.RunService:IsStudio())
			or player:GetAttribute("IsAdmin") ~= true
			or not Helpers.isLoaded(player)
		then
			return false, "Admin only"
		end
		local t = os.clock()
		if busy[player] or t - (calls[player] or -math.huge) < Config.Admin.interval then
			return false, "Wait one second"
		end
		calls[player] = t
		if action == "candy" then
			if
				amount ~= nil
				and (type(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge)
			then
				return false, "Invalid amount"
			end
			return Bases.debugAction(
				"candy",
				player,
				math.clamp(math.floor(amount or Config.Admin.candy), 1, Config.Admin.maxCandy)
			)
		elseif action == "zone" then
			return Bases.debugAction("zone", player, #Config.ZoneOrder)
		elseif action == "king" or action == "spooky" or action == "purge" then
			return Bases.debugAction(action, player)
		elseif action ~= "reset" then
			return false, "Unknown action"
		end
		busy[player] = true
		local ok, saved = pcall(function()
			local patch = patchOf[player]
			Hoards.cancelFight(player)
			Progress.pending[player] = nil
			if patch then
				Bases.clear(patch)
			end
			Bases.dropStolen(player, patch and patch.Soil.Position or Vector3.zero)
			for _, p in carrying[player] or {} do
				p:Destroy()
			end
			carrying[player] = {}
			Progress.pending[player] = nil
			refreshCarry(player)
			toolsOf[player] = { [Config.StartTool] = true }
			zonesOf[player] = {}
			indexOf[player] = {}
			Helpers.Index.load(player, {})
			unlocked[player] = startUnlocked()
			skillsOf[player] = {}
			lifetime[player] = 0
			dailyOf[player] = nil
			player:SetAttribute("DailyClaimable", false)
			Bases.carvedOf[player] = {}
			Bases.incomeCarry[player] = nil
			Bases.left[player] = nil
			for id in Config.Upgrades do
				player:SetAttribute("Up_" .. id, 0)
			end
			for _, attr in { "Haunts", "Souls", "CursedTokens", "PlayTime", "LifetimeCandy" } do
				player:SetAttribute(attr, 0)
			end
			for _, attr in { "FirstHoardDone", "FirstSmashCandy", "FirstGrabPets" } do
				player:SetAttribute(attr, false)
			end
			for _, id in Config.ZoneOrder do
				player:SetAttribute("Wake_" .. id, nil)
			end
			player:SetAttribute("Title", nil)
			player:SetAttribute("Tool", Config.StartTool)
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				stats.Candy.Value = Config.StartCandy
				stats.Kings.Value = 0
			end
			applyData(player, { purchases = receiptsOf[player] })
			publishIndex(player)
			Unlock.refresh(player, true)
			local wrote = savePlayer(player)
			player:LoadCharacterAsync()
			return wrote
		end)
		busy[player] = nil
		if not ok then
			warn("[Patch] Admin reset failed:", saved)
			return false, "Reset failed; check server output"
		end
		return true, saved and "Progress reset and saved" or "Progress reset; save unavailable"
	end
	Services.Players.PlayerRemoving:Connect(function(player)
		calls[player] = nil
		busy[player] = nil
	end)
end

task.spawn(runDay)

-- R24 movement requests contain only an action; positions and restrictions come from the server.
do
	local clocks = setmetatable({}, { __mode = "k" })
	local function movementBlocked(player, teleport)
		if player:GetAttribute("PurgeStealing") then
			return true
		end
		if not teleport and state:GetAttribute("PurgeEnds") then
			return true
		end
		if teleport and Hoards.targets(player) then
			return true
		end
		for _, p in carrying[player] or {} do
			if p:GetAttribute("HoardZone") or p:GetAttribute("StolenFrom") then
				return true
			end
		end
		return (player:GetAttribute("GuardEffectUntil") or 0) > workspace:GetServerTimeNow()
			and (player:GetAttribute("WalkSpeedMultiplier") or 1) == 0
	end
	local function request(player, action, cooldown)
		if not Helpers.isLoaded(player) then
			return nil, "Loading"
		end
		local character, root = aliveRoot(player)
		if not root then
			return nil, "Respawn first"
		end
		local c = clocks[player] or {}
		clocks[player] = c
		local t = workspace:GetServerTimeNow()
		if t < (c.attempt or 0) then
			return nil, "Wait a moment"
		end
		c.attempt = t + Config.Movement.requestInterval
		if t < (c[action] or 0) then
			return nil, "Cooldown"
		end
		return { character = character, root = root, clock = c, time = t, cooldown = cooldown }
	end
	Remotes.sprintEvent.OnServerEvent:Connect(function(player, on)
		if type(on) == "boolean" and Helpers.isLoaded(player) then
			player:SetAttribute("Sprinting", on)
		end
	end)
	Remotes.teleportFunction.OnServerInvoke = function(player, target)
		if not hasZone(player, "Zone2") then
			return false, "Unlock the first gate to teleport"
		end
		if target ~= "My Pen" and target ~= "Zone Gate" and target ~= "Shop" then
			return false, "Unknown target"
		end
		local r, why = request(player, "teleport", Config.Teleport.cooldown)
		if not r then
			return false, why
		end
		if movementBlocked(player, true) then
			return false, "Escape or finish carrying first"
		end
		local part, offset
		if target == "My Pen" then
			local pen = patchOf[player]
			part = pen and pen:FindFirstChild("Soil")
		elseif target == "Shop" then
			local shop = market:FindFirstChild("Seeds")
			part = shop and shop:FindFirstChild("PromptPart", true)
		else
			local zones = garden:FindFirstChild("Zones")
			for _, id in Config.ZoneOrder do
				if hasZone(player, id) then
					local zone = zones and zones:FindFirstChild(id)
					part = zone
						and (
							zone:FindFirstChild("GateWall", true)
							or zone:FindFirstChild("Spawn", true)
						)
				end
			end
			offset = Vector3.new(0, 0, Config.Teleport.standOff)
		end
		if not part or not part:IsA("BasePart") then
			return false, "Target missing from map"
		end
		local pos = part.Position + (offset or Vector3.zero)
		pos = Bases.findLanding(pos)
		if not pos then
			return false, "No safe landing"
		end
		r.clock.teleport = r.time + r.cooldown
		player:SetAttribute("TeleportReadyAt", r.clock.teleport)
		r.character:PivotTo(CFrame.new(pos) * r.root.CFrame.Rotation)
		r.root.AssemblyAngularVelocity = Vector3.zero
		player:SetAttribute("CameraReset", workspace:GetServerTimeNow())
		r.root.AssemblyLinearVelocity = Vector3.zero
		return true
	end
	Remotes.dashFunction.OnServerInvoke = function(player)
		local r, why = request(player, "dash", Config.Dash.cooldown)
		if not r then
			return false, why
		end
		if bestTool(player).order < Config.Dash.tier then
			return false, "Requires Iron Scythe"
		end
		if movementBlocked(player, false) then
			return false, "Dash blocked while carrying or fighting"
		end
		local forward = r.root.CFrame.LookVector * Vector3.new(1, 0, 1)
		if forward.Magnitude < 0.01 then
			return false, "No direction"
		end
		forward = forward.Unit
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { r.character, loose, ghostFolder }
		params.RespectCanCollide = true
		local ignore = { r.character, loose, ghostFolder }
		local zones = garden:FindFirstChild("Zones")
		for _, id in Config.ZoneOrder do
			local zone = zones and zones:FindFirstChild(id)
			local wall = zone and zone:FindFirstChild("GateWall", true)
			if wall and hasZone(player, id) then
				table.insert(ignore, wall)
			end
		end
		params.FilterDescendantsInstances = ignore
		local distance = Config.Dash.distance
		-- Sweep the body volume, then raycast its centre. Never cross a wall or locked gate.
		local hit = workspace:Blockcast(
			r.root.CFrame + Vector3.yAxis * Config.Dash.bodyLift,
			Config.Dash.bodySize,
			forward * distance,
			params
		)
		local ray = workspace:Raycast(r.root.Position, forward * distance, params)
		if hit then
			distance = math.min(distance, math.max(0, hit.Distance - Config.Dash.clearance))
		end
		if ray then
			distance = math.min(distance, math.max(0, ray.Distance - Config.Dash.clearance))
		end
		if distance <= 0 then
			return false, "Wall ahead"
		end
		r.clock.dash = r.time + r.cooldown
		player:SetAttribute("DashReadyAt", r.clock.dash)
		r.character:PivotTo(r.character:GetPivot() + forward * distance)
		r.root.AssemblyLinearVelocity = Vector3.zero
		return true
	end
	-- The client predicts this for responsiveness; the server owns the allowed speed.
	Services.RunService.Heartbeat:Connect(function()
		for _, player in Services.Players:GetPlayers() do
			local character = player.Character
			local hum = character and character:FindFirstChildOfClass("Humanoid")
			if hum and Helpers.isLoaded(player) then
				local speed = Config.walkSpeed(Helpers.upgradeLevel(player, "Boots"))
					* (player:GetAttribute("Sprinting") and Config.Movement.sprintMult or 1)
				speed = math.max(
					Config.MinCarrySpeed,
					speed - #(carrying[player] or {}) * Config.SlowPerPumpkin
				)
				if
					(player:GetAttribute("GuardEffectUntil") or 0) > workspace:GetServerTimeNow()
				then
					speed *= player:GetAttribute("WalkSpeedMultiplier") or 1
				end
				hum.WalkSpeed = speed
			end
		end
	end)
end

-- No yields between validation, dedupe and payout; save candy and flags together.
Remotes.indexClaimFunction.OnServerInvoke = function(player, request)
	if
		not Helpers.isLoaded(player)
		or not Helpers.candyValue(player)
		or type(request) ~= "string"
	then
		return { candy = 0 }
	end
	Helpers.Index.claims[player] = Helpers.Index.claims[player] or {}
	Helpers.Index.milestones[player] = Helpers.Index.milestones[player] or {}
	local claims, milestones = Helpers.Index.claims[player], Helpers.Index.milestones[player]
	local total, reward, count = 0, 0, 0
	local income = math.max(1, player:GetAttribute("Income") or 0)
	for _, seed in Config.Seeds do
		if Helpers.Index.discovered(player, seed) then
			total += 1
			if (request == "All" or request == seed.pet) and not claims[seed.pet] then
				claims[seed.pet] = true
				reward += Config.indexReward(
					income,
					Config.IndexRewards.petSeconds,
					Config.IndexRewards.petBudgetSeconds / #Config.Seeds
				)
				count += 1
			end
		end
	end
	for _, milestone in Config.IndexRewards.milestones do
		local key = tostring(milestone.percent)
		if
			(request == "All" or request == "Milestone:" .. key)
			and total * 100 >= #Config.Seeds * milestone.percent
			and not milestones[key]
		then
			milestones[key] = true
			reward += Config.indexReward(income, milestone.seconds, milestone.seconds)
			count += 1
			if milestone.percent == 100 then
				player:SetAttribute("Title", Config.IndexRewards.title)
			end
		end
	end
	if count > 0 then
		addCandy(player, reward, true)
		Helpers.Index.publish(player)
		task.defer(function()
			savePlayer(player)
		end)
	end
	return { candy = reward, count = count }
end

-- Rescue below the map or beyond its outer box, never while supported by a valid floor.
do
	local lo = Vector3.new(Lane.x - 170, -2, -70)
	local hi = Vector3.new(Lane.x + 170, 0, Lane.safeZ)
	for _, id in Config.ZoneOrder do
		local zone = Lane.zone(id)
		if zone then
			lo = lo:Min(Vector3.new(Lane.x - 60, -2, zone.zMin))
			hi = hi:Max(Vector3.new(Lane.x + 60, 0, zone.zMax))
		end
	end
	local floors, pending = { workspace.Terrain }, {}
	local ground = garden:FindFirstChild("Ground")
	for _, part in garden:GetDescendants() do
		-- Includes Ground, pen Soil, market/throne, lanes, ramps and platforms.
		if
			part:IsA("BasePart")
			and part.Anchored
			and part.CanCollide
			and (
				part.Name == "Soil"
				or ground and (part == ground or part:IsDescendantOf(ground))
				or part.Name:lower():find("floor", 1, true)
				or part.Name == "Plaza"
				or part.CFrame.UpVector.Y > 0.5
					and part.Size.X >= 4
					and part.Size.Z >= 4
					and part.Size.Y <= math.max(part.Size.X, part.Size.Z) / 2
			)
		then
			table.insert(floors, part)
			local low, high = Vector3.one * math.huge, Vector3.one * -math.huge
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local at =
							part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2)
						low, high = low:Min(at), high:Max(at)
					end
				end
			end
			if
				part.Name == "Soil" and part:IsDescendantOf(patchFolder)
				or part:IsDescendantOf(market)
					and (part.Name == "Plaza" or part.Name:lower():find("floor", 1, true))
			then
				lo, hi = lo:Min(low), hi:Max(high)
			end
			table.insert(pending, { lo = low, hi = high })
		end
	end
	-- Only adjoining floors enlarge the shell; disconnected stray Ground parts cannot inflate it.
	local changed = true
	while changed do
		changed = false
		for index = #pending, 1, -1 do
			local region = pending[index]
			if
				region.hi.X >= lo.X - 12
				and region.lo.X <= hi.X + 12
				and region.hi.Z >= lo.Z - 12
				and region.lo.Z <= hi.Z + 12
			then
				lo, hi = lo:Min(region.lo), hi:Max(region.hi)
				table.remove(pending, index)
				changed = true
			end
		end
	end
	Helpers.playFloors = floors
	local margin = 20 -- eight studs to the safety wall, then twelve studs of rescue grace.
	function Helpers.inPlayArea(at)
		return at.Y >= lo.Y - 18
			and at.X >= lo.X - margin
			and at.X <= hi.X + margin
			and at.Z >= lo.Z - margin
			and at.Z <= hi.Z + margin
	end
	local floorParams = RaycastParams.new()
	floorParams.FilterType = Enum.RaycastFilterType.Include
	-- Query the whole Garden so small, rotated or later-added walkable surfaces are protected too.
	floorParams.FilterDescendantsInstances = { garden, workspace.Terrain }
	floorParams.RespectCanCollide = true
	local function supported(root, humanoid)
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			return true
		end
		local distance = humanoid.HipHeight + root.Size.Y / 2 + 2
		local hit = workspace:Raycast(root.Position, -Vector3.yAxis * distance, floorParams)
		return hit ~= nil and hit.Normal.Y > 0.4
	end
	function Bases.findLanding(pos)
		for _, offset in
			{
				Vector3.zero,
				Vector3.new(6, 0, 0),
				Vector3.new(-6, 0, 0),
				Vector3.new(0, 0, 6),
				Vector3.new(0, 0, -6),
				Vector3.new(12, 0, 0),
				Vector3.new(-12, 0, 0),
			}
		do
			local at = pos + offset
			if Helpers.inPlayArea(at) then
				local landing = Bases.safeLanding(at, true)
				if landing and Helpers.inPlayArea(landing) then
					return landing
				end
			end
		end
		return nil
	end
	function Helpers.recover(player, character, root)
		local spawn = garden:FindFirstChildOfClass("SpawnLocation")
			or workspace:FindFirstChildOfClass("SpawnLocation")
		local at = spawn and spawn.Position or Vector3.new(Lane.x, 0, Lane.safeZ - 20)
		local landing = Bases.findLanding(at)
		if not landing then
			warn("Play-area rescue has no safe hub landing for " .. player.Name)
			return
		end
		Bases.dropStolen(player, landing)
		refreshCarry(player)
		character:PivotTo(CFrame.new(landing))
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
			humanoid.PlatformStand = false
		end
		player:SetAttribute("CameraReset", workspace:GetServerTimeNow())
		Remotes.hintEvent:FireClient(player, "Back in the hub - rescued from the map edge")
	end
	local shell = Instance.new("Folder")
	shell.Name, shell.Parent = "PlayAreaSafety", garden
	local function barrier(name, size, at)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Position = name, size, at
		part.Anchored, part.Transparency = true, 1
		part.CanCollide, part.CanQuery, part.CanTouch = true, true, false
		part.Parent = shell
	end
	local mid, size = (lo + hi) / 2, hi - lo
	barrier("West", Vector3.new(2, 110, size.Z + 20), Vector3.new(lo.X - 8, mid.Y + 35, mid.Z))
	barrier("East", Vector3.new(2, 110, size.Z + 20), Vector3.new(hi.X + 8, mid.Y + 35, mid.Z))
	barrier("South", Vector3.new(size.X + 20, 110, 2), Vector3.new(mid.X, mid.Y + 35, lo.Z - 8))
	barrier("North", Vector3.new(size.X + 20, 110, 2), Vector3.new(mid.X, mid.Y + 35, hi.Z + 8))
	barrier("Roof", Vector3.new(size.X + 20, 2, size.Z + 20), Vector3.new(mid.X, hi.Y + 100, mid.Z))
	local elapsed = 0
	local outsideSince = setmetatable({}, { __mode = "k" })
	local checkedSpawn = setmetatable({}, { __mode = "k" })
	Services.RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.25 then
			return
		end
		elapsed = 0
		local now = workspace:GetServerTimeNow()
		for _, player in Services.Players:GetPlayers() do
			local character, root = aliveRoot(player)
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if character and root and humanoid and Helpers.isLoaded(player) then
				local inside = Helpers.inPlayArea(root.Position)
				if not checkedSpawn[character] then
					checkedSpawn[character] = true
					if not inside then
						warn("Character spawned outside play bounds: " .. player.Name)
					end
				end
				if inside or supported(root, humanoid) then
					outsideSince[character] = nil
				else
					outsideSince[character] = outsideSince[character] or now
					if root.Position.Y < lo.Y - 18 or now - outsideSince[character] >= 1.5 then
						outsideSince[character] = now
						Helpers.recover(player, character, root)
					end
				end
			end
		end
	end)
end

-- P1: use the throne's voxel King; KingFace remains an invisible server hit anchor.
do
	local guards = Services.ServerStorage:FindFirstChild("GuardModels")
	local statue = garden:FindFirstChild("ThroneKing", true)
	local source = guards and guards:FindFirstChild("PumpkinKing") or statue
	if source and source:IsA("Model") and source:FindFirstChildWhichIsA("BasePart", true) then
		local body = source:Clone()
		body.Name = "FightPumpkinKing"
		for _, d in body:GetDescendants() do
			if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") or d:IsA("ProximityPrompt") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
			end
		end
		local _, box = body:GetBoundingBox()
		body:ScaleTo(body:GetScale() * Config.KingNight.height / math.max(box.Y, 0.01))
		local cf = body:GetBoundingBox()
		local offset = cf:ToObjectSpace(body:GetPivot())
		body.Parent = market
		kingFace:SetAttribute("VoxelKing", true)
		local visible, statueParts = {}, {}
		for _, d in body:GetDescendants() do
			if d:IsA("BasePart") then
				visible[d] = d.Transparency
				d.Transparency = 1
			end
		end
		for _, d in statue and statue:GetDescendants() or {} do
			if d:IsA("BasePart") then
				statueParts[d] = d.Transparency
			end
		end
		local previous = false
		local baseScale, baseHeight = body:GetScale(), Config.KingNight.height
		Services.RunService.Heartbeat:Connect(function()
			local active = king.active or king.finalizing == true
			kingFace.Transparency = 1
			kingFace.CanCollide = false
			if active then
				local scale = baseScale * kingFace.Size.Y / baseHeight
				body:SetAttribute("CombatScale", scale)
				body:ScaleTo(scale)
				local walking = state:GetAttribute("KingWalking")
				local stride = walking and math.sin(os.clock() * 7) or 0
				body:PivotTo(
					CFrame.new(kingFace.Position + Vector3.yAxis * math.abs(stride) * 0.35)
						* kingFace.CFrame.Rotation
						* CFrame.Angles(0, 0, math.rad(2) * stride)
						* offset
				)
			end
			if active ~= previous or not body:GetAttribute("Initialized") then
				previous = active
				body:SetAttribute("Initialized", true)
				for part, alpha in visible do
					part.Transparency = active and alpha or 1
				end
				for part, alpha in statueParts do
					part.Transparency = active and 1 or alpha
				end
			end
		end)
	else
		Helpers.warnOnce(
			"FightPumpkinKing",
			"Voxel PumpkinKing missing: restore GuardModels.PumpkinKing before launch"
		)
	end
end

-- L1 runtime presentation; scene files and saved payloads remain unchanged.
do
	local presentation = Config.Presentation
	local billboards = setmetatable({}, { __mode = "k" })
	local function decorate(item)
		if not item.Parent then
			return
		end
		if item:IsA("BillboardGui") then
			billboards[item] = true
			presentation.billboard(item)
		end
		presentation.text(item, 1080)
	end
	for _, item in garden:GetDescendants() do
		decorate(item)
	end
	garden.DescendantAdded:Connect(function(item)
		task.defer(decorate, item)
	end)
	task.spawn(function()
		while true do
			for item in billboards do
				if item.Parent then
					presentation.billboard(item)
				else
					billboards[item] = nil
				end
			end
			task.wait(1)
		end
	end)
end
