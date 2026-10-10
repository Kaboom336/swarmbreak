-- Steal a Pumpkin: swing your scythe at wild pumpkins in the zones until they pop, carry them
-- on your head and place them on your base, where they hatch into pets that earn candy every
-- second. The map is one straight lane along +Z (Config.MapCenterX): the hub with the bases and
-- the market, then Zone1..Zone7, each with a Hoard nest and its guardian. Brew them
-- in a Magic Cauldron for a multiplier, sell them to the Witch, steal from other bases (and lock
-- yours). At midnight ghosts raid the bases. Every sale fills the Giant Jack; when it is full the
-- Blood Moon turns every lock off for a while, then everyone fights the Pumpkin King.
-- New players meet only the core loop (smash, place, Hoard steal, Shop, zone gates): stealing,
-- locks and ghost raids open after the new-player shield, Sell / Brew / King / Lucky Swing after
-- about 30 minutes and Haunt at half its cost (Config.Unlocks, see Unlock below).
local AnalyticsService = game:GetService("AnalyticsService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("PatchConfig"))

local garden = workspace:WaitForChild("Garden")
local patchFolder = garden:WaitForChild("Patches")
local cauldronFolder = garden:WaitForChild("Cauldrons")
local market = garden:WaitForChild("Market")
local spawnFolder = garden:WaitForChild("GhostSpawns")
local giantJack = market:WaitForChild("GiantJack") :: BasePart
local kingFace = market:WaitForChild("KingFace") :: BasePart
local kit = ServerStorage:WaitForChild("KitSource")

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
state.Parent = ReplicatedStorage

-- Spooky Hour (replaces the old dark Midnight look): every Config.SpookyEvery seconds for
-- Config.SpookyLength seconds base income pays x Config.SpookyMult. State "SpookyEnds" = its end
-- (server time, nil when off), "SpookyNext" = the next start. Clients tint the world and fly bats.
local Spooky: { [string]: any } = {}
do
	local nextAt = workspace:GetServerTimeNow() + (Config.SpookyEvery or 600)
	state:SetAttribute("SpookyNext", nextAt)
	function Spooky.active(): boolean
		return (state:GetAttribute("SpookyEnds") or 0) > workspace:GetServerTimeNow()
	end
	function Spooky.mult(): number
		return Spooky.active() and (Config.SpookyMult or 2) or 1
	end
	function Spooky.start()
		local t = workspace:GetServerTimeNow()
		state:SetAttribute("SpookyEnds", t + (Config.SpookyLength or 90))
		nextAt = t + (Config.SpookyEvery or 600)
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
	remotes.Parent = ReplicatedStorage
	local function remote(name: string, class: string?)
		local r = Instance.new(class or "RemoteEvent")
		r.Name = name
		r.Parent = remotes
		return r
	end
	Remotes = {
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
		stompEvent = remote("Stomp"),
		telegraphEvent = remote("Telegraph"),
		knockEvent = remote("Knock"),
		indexEvent = remote("IndexNew"),
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
local seedById = {}
for i, seed in Config.Seeds do
	seed.order = i
	seedById[seed.id] = seed
end
local toolById = {}
for i, tool in Config.Tools do
	tool.order = i
	toolById[tool.id] = tool
end
local mutationById = {}
for _, m in Config.Mutations do
	mutationById[m.id] = m
end
local skillById = {}
local skillAt: { [string]: any } = {} -- "Branch:tier" -> skill
for _, skill in Config.Skills do
	skillById[skill.id] = skill
	skillAt[skill.branch .. ":" .. skill.tier] = skill
end

-- Player data ------------------------------------------------------------------------------

local function upgradeLevel(player: Player, id: string): number
	return player:GetAttribute("Up_" .. id) or 0
end

local function candyValue(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Candy") :: IntValue?
end

local lifetime: { [Player]: number } = {}
local function addCandy(player: Player, amount: number)
	local candy = candyValue(player)
	if candy then
		candy.Value += amount
		if amount > 0 then
			lifetime[player] = (lifetime[player] or 0) + amount
		end
	end
end

-- Game passes the player owns, cached in "Pass_<Name>" attributes (see Monetization below).
local function hasPass(player: Player, name: string): boolean
	return player:GetAttribute("Pass_" .. name) == true
end

local function carryCapacity(player: Player): number
	return Config.BaseCarry
		+ upgradeLevel(player, "Stack")
		+ (hasPass(player, "BigStack") and Config.BigStackCarry or 0)
end

local function isLoaded(player: Player): boolean
	return player:GetAttribute("Loaded") == true
end

-- Unlock gates (Config.Unlocks): sticky "Unlock_<Name>" player attributes, set by Unlock.refresh
-- (defined with the bases below) from the saved total playtime ("PlayTime"), lifetime candy and a
-- full base. Clients show / hide by the same attributes; the server checks them here.
-- Haunt is the HauntPillAt gate (lifetime candy); the others are playtime gates.
local Unlock: { [string]: any } = {
	NAMES = { "PlayerSteal", "Sell", "Brew", "LuckySwing", "King", "Haunt" },
}
function Unlock.has(player: Player?, name: string): boolean
	return player ~= nil and player:GetAttribute("Unlock_" .. name) == true
end

-- Haunts add to sell value; VIP and Double Candy multiply on top.
local function sellMult(player: Player): number
	return (1 + Config.HauntSellBonus * (player:GetAttribute("Haunts") or 0))
		* (hasPass(player, "VIP") and 1 + Config.VipSellBonus or 1)
		* (hasPass(player, "DoubleCandy") and Config.DoubleCandyMult or 1)
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
	local best = toolById[Config.StartTool]
	for id in toolsOf[player] or {} do
		local tool = toolById[id]
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

local function bestUnlocked(player: Player)
	local best = Config.Seeds[1]
	for id in unlocked[player] or {} do
		local seed = seedById[id]
		if seed and seed.order > best.order then
			best = seed
		end
	end
	return best
end

-- B: the value unit for order rewards and ghost bonks.
local function orderBase(player: Player): number
	return bestUnlocked(player).income * Config.OrderIncomeSeconds
end

-- Short numbers: 950, 1.2k, 34.5k, 340k, 3.4M, 1.2B (rounded down so 999.96k never shows 1000k).
local function short(n: number): string
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
local function rateText(n: number): string
	if n < 10 then
		return (string.gsub(string.format("%.1f", n), "%.0$", ""))
	end
	return short(n)
end

-- Pumpkin Index: every seed x finish a player has sold, kept as "Seed:Finish" keys.
local FINISHES = { "Plain", "Glowing", "Ghostly", "Candy", "Cursed" }
local indexOf: { [Player]: { [string]: boolean } } = {}

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
		table.insert(parts, short(reward.candy) .. " candy")
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
	local reward = def.reward or { candy = math.max(1, math.floor(def.b * (base or 1) + 0.5)) }
	local need = def.need
	local text = def.text
	if def.reach then
		need = math.max(need, math.ceil((level or 0) * Config.ReachGrowth))
		text = string.format(def.text, short(need))
	end
	return {
		id = id,
		stat = def.stat,
		need = need,
		have = 0,
		text = text,
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

local function nextOrders(player: Player)
	local o = orders[player]
	-- Tutorial steps the player already did some other way are skipped (a better scythe owned,
	-- the stack already upgraded), so an old save can never get stuck on them.
	while o.tut <= TUTORIAL_COUNT do
		local stat = Config.TutorialOrders[o.tut].stat
		if
			(stat == "buyTool" and bestTool(player).order >= 2)
			or (stat == "upgrade:Stack" and upgradeLevel(player, "Stack") >= 1)
		then
			o.tut += 1
		else
			break
		end
	end
	if o.tut <= TUTORIAL_COUNT then
		o.list = { makeOrder("T" .. o.tut) :: Order }
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
			if seedId and seedById[seedId] and table.find(FINISHES, finish) then
				n += 1
			end
		end
		indexFull = n >= #Config.Seeds * #FINISHES
	end
	local pool = {}
	for i, def in Config.RotatingOrders do
		local gate = ORDER_UNLOCK[def.stat]
		local impossible = (def.stat == "sellStackOf5" and carryCapacity(player) < 5)
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
	local list = {}
	for _, order in o.list do
		table.insert(list, {
			text = order.text,
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
		HttpService:JSONEncode({
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
		addCandy(player, reward.candy)
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
	if not done or done[step] or not isLoaded(player) then
		return
	end
	done[step] = true
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, ONBOARD_STEPS[step])
	end)
end

-- reach = amount is a level (orders keep the highest seen) instead of a count to add.
local function track(player: Player?, stat: string, amount: number?, reach: boolean?)
	local o = player and orders[player]
	if not player or not o or not isLoaded(player) then
		return
	end
	local step = ONBOARD_STAT[stat]
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
	-- which is mapped onto today's 5 steps (smash, place, hoard, tool, stack). A mapped save gets
	-- freshly dealt orders.
	local shifted = false
	if type(saved) == "table" then
		if type(saved.tut) == "number" then
			local tut = math.max(1, math.floor(saved.tut))
			if saved.v ~= 3 then
				if saved.v ~= 2 and tut >= 2 then
					tut += 1
				end
				-- Old (version 2) step -> new step; 10+ = the old tutorial was finished.
				local V2_TO_V3 = { 1, 2, 2, 4, 4, 4, 5, 5, 5 }
				tut = V2_TO_V3[tut] or TUTORIAL_COUNT + 1
				-- Re-deal: old rotating lists may hold orders of systems that are locked now.
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
						order.text = string.format(def.text, short(s.need))
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
	return { v = 3, tut = o.tut, refreshAt = o.refreshAt, counters = o.counters, list = list }
end

-- Saving -------------------------------------------------------------------------------------
-- UpdateAsync with a session lock so a server hop cannot load stale data or overwrite newer
-- data. Everything is in pcall: in unpublished Studio the store is turned off and play goes on.

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("PumpkinPatchPanic_v1")
end)
local boardStore = nil
pcall(function()
	boardStore = DataStoreService:GetOrderedDataStore("LifetimeCandy")
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
			if status == "error" and RunService:IsStudio() then
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
		local candy = candyValue(player)
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
				if type(id) == "string" and toolById[id] then
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
		if type(data.upgrades) == "table" then
			for id in Config.Upgrades do
				if type(data.upgrades[id]) == "number" then
					player:SetAttribute("Up_" .. id, data.upgrades[id])
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
				if type(id) == "string" and seedById[id] then
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
				if type(id) == "string" and skillById[id] then
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
				if type(id) == "string" and seedById[id] then
					carved[id] = true
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
	end

	local function snapshot(player: Player): { [string]: any }
		local candy = candyValue(player)
		assert(candy, "no leaderstats")
		local tools, upgrades, skills = {}, {}, {}
		for id in toolsOf[player] or {} do
			table.insert(tools, id)
		end
		for id in Config.Upgrades do
			upgrades[id] = upgradeLevel(player, id)
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
		local carvedList, unlockList = {}, {}
		for id in Bases.carvedOf[player] or {} do
			table.insert(carvedList, id)
		end
		for _, name in Unlock.NAMES do
			if Unlock.has(player, name) then
				table.insert(unlockList, name)
			end
		end
		return {
			playTime = player:GetAttribute("PlayTime") or 0,
			unlocks = unlockList,
			firstHoard = player:GetAttribute("FirstHoardDone") == true,
			carved = carvedList,
			candy = candy.Value,
			kings = kings and kings.Value or 0,
			tools = tools,
			zones = zoneList,
			placed = Bases.collect(player),
			upgrades = upgrades,
			index = index,
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
		local mesh = kit[seed.template]:FindFirstChildWhichIsA("MeshPart", true):Clone()
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
	local seed = seedById[seedId]
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
	local seed = seedById[pumpkin:GetAttribute("Seed")]
	local mutation = mutationById[pumpkin:GetAttribute("Mutation") or ""]
	return (seed and seed.income or 1)
		* (pumpkin:GetAttribute("SizeMult") or 1)
		* (mutation and mutation.mult or 1)
		* (pumpkin:GetAttribute("Hoard") == true and Config.HoardMult or 1)
end

-- What the Witch pays (before the seller's multipliers): SellPerIncome seconds of income.
local function pumpkinValue(pumpkin: Instance): number
	return math.max(1, math.floor(incomeOf(pumpkin) * Config.SellPerIncome + 0.5))
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
		local seed = seedById[pumpkin:GetAttribute("Seed") or ""]
		if not seed or not player.Parent then
			return
		end
		local mutation = pumpkin:GetAttribute("Mutation")
		if not kind and not isNew and seed.order < Config.RevealOrder and mutation ~= "Cursed" then
			return
		end
		local seen = seenOf[player] or {}
		seenOf[player] = seen
		seen[seed.id] = true
		local rate = math.floor(incomeOf(pumpkin) * sellMult(player) * 10 + 0.5) / 10
		-- The pet it hatched into (if any): the card shows the pet and its name.
		local pet = pumpkin:GetAttribute("Pet")
		Remotes.revealEvent:FireClient(player, seed.id, mutation, isNew, rate, kind, pet)
	end
end

local brewPumpkin, applyMutationLook
do
	-- No PointLight here: 24 players x a full stack of lit pumpkins is too heavy on mobile.
	function applyMutationLook(pumpkin: BasePart, mutationId: string)
		local mutation = mutationById[mutationId]
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
				if mutationById[again].mult > mutationById[id].mult then
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
	local sign = post and post:FindFirstChild("OwnerSign")
	local label = sign and sign:FindFirstChild("Label") :: TextLabel?
	if label then
		label.Text = text
		label.TextColor3 = color
	end
end

local carrying: { [Player]: { BasePart } } = {}
local function refreshCarry(player: Player)
	local stack = carrying[player] or {}
	player:SetAttribute("Carry", #stack)
	local value = 0
	for _, p in stack do
		value += pumpkinValue(p)
	end
	player:SetAttribute("CarryValue", math.floor(value * sellMult(player) + 0.5))
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

-- Living Jack look (blocky "lego" style): two black ball eyes and a V mouth of two wedges on the
-- pumpkin's front (-Z), and two blocky legs with feet under it, all "JackPart"s welded to the
-- pumpkin (their welds sit inside them, so stripPumpkin keeps them). Old JackParts are rebuilt
-- (after a resize). lift = raise the pumpkin so the legs stand where its bottom was.
local function dressJack(pumpkin: BasePart, lift: boolean?)
	for _, child in pumpkin:GetChildren() do
		if child.Name == "JackPart" then
			child:Destroy()
		end
	end
	local s = pumpkin.Size
	local legH = s.Y * 0.3
	if lift then
		pumpkin.CFrame += Vector3.new(0, legH, 0)
	end
	local base = pumpkin.CFrame
	local black = Color3.fromRGB(26, 16, 22)
	local function jackPart(p: BasePart, size: Vector3, offset: CFrame, color: Color3)
		p.Name = "JackPart"
		p.Size = size
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.CFrame = base * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = pumpkin
		weld.Part1 = p
		weld.Parent = p
		p.Parent = pumpkin
	end
	local eye = s.X * 0.2
	for side = -1, 1, 2 do
		local ball = Instance.new("Part")
		ball.Shape = Enum.PartType.Ball
		jackPart(
			ball,
			Vector3.one * eye,
			CFrame.new(side * s.X * 0.19, s.Y * 0.12, -s.Z * 0.42),
			black
		)
	end
	-- Mouth: two right-triangle wedges meeting in a V. A wedge's triangle lies in its local Y/Z
	-- plane with the right angle at (y -h/2, z +d/2); local X (thickness) points out of the face,
	-- local Y points down and local Z points away from the centre line, so each right angle sits
	-- at the top centre and the two hypotenuses form the V.
	local w, h, t = s.X * 0.46, s.Y * 0.2, s.Z * 0.1
	for side = -1, 1, 2 do
		jackPart(
			Instance.new("WedgePart"),
			Vector3.new(t, h, w / 2),
			CFrame.fromMatrix(
				Vector3.new(side * w / 4, -s.Y * 0.1, -s.Z * 0.43),
				Vector3.new(0, 0, -side),
				Vector3.new(0, -1, 0)
			),
			black
		)
	end
	local leg = Color3.fromRGB(70, 110, 45)
	for side = -1, 1, 2 do
		jackPart(
			Instance.new("Part"),
			Vector3.new(s.X * 0.2, legH + s.Y * 0.2, s.Z * 0.2),
			CFrame.new(side * s.X * 0.2, -s.Y / 2 - legH / 2 + s.Y * 0.1, 0),
			leg
		)
		jackPart(
			Instance.new("Part"),
			Vector3.new(s.X * 0.26, s.Y * 0.08, s.Z * 0.34),
			CFrame.new(side * s.X * 0.2, -s.Y / 2 - legH + s.Y * 0.04, -s.Z * 0.06),
			leg:Lerp(Color3.new(0, 0, 0), 0.3)
		)
	end
end

-- Model looks (ServerStorage.PetModels: hatched pets and the Hoard's MysteryPumpkin). The pumpkin
-- part stays the carrier (its attributes, prompts, tags and welds work as before) but turns
-- invisible and takes the size of a clone of the model (child Model "PetLook", Welds inside its
-- parts), so plots, stacks, drops and ghosts fit the look. Attribute "Look" = "Folder/Name" (to
-- rebuild it after a resize), "BaseSize" = the pumpkin's own size (to go back to a pumpkin).
local Looks: { [string]: any } = {}
do
	local function source(folder: string, name: string?): Model?
		local holder = ServerStorage:FindFirstChild(folder)
		local m = holder and name and holder:FindFirstChild(name)
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
		local src = source(folder, name)
		if not src then
			return false
		end
		local m = src:Clone()
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

	-- Hatches a placed pumpkin into its type's pet (Config.Seeds[n].pet). False (and the
	-- pumpkin unchanged) when that pet has no model in ServerStorage.PetModels.
	function Looks.hatch(p: BasePart, seed): boolean
		local pet = seed and seed.pet
		local rare = seed and seed.order >= Config.PetRareOrder
		if
			not Looks.attach(
				p,
				"PetModels",
				pet,
				Config.PetHeight * (rare and Config.PetRareMult or 1)
			)
		then
			return false
		end
		p:SetAttribute("Pet", pet)
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
	local height = 3
	for _, p in stack do
		height += p.Size.Y
	end
	stripPumpkin(pumpkin)
	-- A model look (pet, mystery pumpkin) may be taller than wide: its biggest side counts.
	local hasLook = pumpkin:FindFirstChild("PetLook") ~= nil
	local big = hasLook and math.max(pumpkin.Size.X, pumpkin.Size.Y) or pumpkin.Size.X
	if big > 2.6 then
		pumpkin.Size *= 2.6 / big
		if hasLook then
			Looks.refit(pumpkin)
		elseif pumpkin:GetAttribute("Jack") == true then
			-- A carried Jack keeps its face and legs, rebuilt for the smaller size.
			dressJack(pumpkin)
		end
	end
	pumpkin:SetAttribute("Placed", nil)
	pumpkin.Anchored = false
	pumpkin.Massless = true
	pumpkin.CanCollide = false
	pumpkin.CanQuery = false
	pumpkin.CFrame = root.CFrame * CFrame.new(0, height + pumpkin.Size.Y / 2, 0)
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
local function dropLoose(
	pumpkin: BasePart,
	at: Vector3,
	seconds: number?,
	rescued: boolean?,
	groundY: number?
)
	stripPumpkin(pumpkin)
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
	local seed = seedById[pumpkin:GetAttribute("Seed") or ""]
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = rescued and "Rescued pumpkin" or ((seed and seed.name or "") .. " pumpkin")
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = pumpkin
	prompt.Triggered:Connect(function(player)
		if pumpkin.Parent ~= loose then
			return
		end
		if #(carrying[player] or {}) >= carryCapacity(player) then
			Remotes.hintEvent:FireClient(player, "Your hands are full!")
			return
		end
		-- A dropped stolen pumpkin picked up by its owner is just theirs again.
		if pumpkin:GetAttribute("StolenFrom") == player.UserId then
			pumpkin:SetAttribute("StolenFrom", nil)
		end
		-- stackPumpkin removes the prompt itself; on failure the prompt stays usable.
		if stackPumpkin(player, pumpkin) then
			Remotes.harvestedEvent:FireAllClients(player, pumpkin.Position)
			if rescued then
				track(player, "rescue", 1)
			end
		end
	end)
	task.delay(seconds or 60, function()
		if pumpkin.Parent == loose then
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
			if plot.Name == "Plot" and plot:IsA("BasePart") then
				table.insert(list, plot)
			end
		end
		table.sort(list, function(a, b)
			return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0)
		end)
		return list
	end

	local function plotKey(plot: BasePart, i: number): string
		return tostring(plot:GetAttribute("Index") or i)
	end

	-- Income tags, the shield on the single best plot (it cannot be stolen) and the owner's
	-- "Income" attribute (candy per second with their Haunt / pass multipliers).
	function Bases.refresh(patch: Instance?)
		if not patch then
			return
		end
		local owner = Players:GetPlayerByUserId(patch:GetAttribute("Owner") or 0)
		local mult = owner and sellMult(owner) or 1
		local plots = plotsOf(patch)
		local best, bestIncome, total = nil, -1, 0
		for _, plot in plots do
			local p = plotState[plot] and plotState[plot].pumpkin
			if p then
				local income = incomeOf(p)
				total += income * mult
				if income > bestIncome then
					best, bestIncome = plot, income
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
				local rate = math.floor(incomeOf(p) * mult * 10 + 0.5) / 10
				if p:GetAttribute("Rate") ~= rate then
					p:SetAttribute("Rate", rate)
				end
			end
			local tag = p and p:FindFirstChild("IncomeTag")
			local label = tag and tag:FindFirstChild("Label") :: TextLabel?
			if p and label then
				local text = (protected and "🛡 " or "")
					.. "+"
					.. rateText(incomeOf(p) * mult)
					.. "/s"
				if label.Text ~= text then
					label.Text = text
				end
			end
		end
		if owner then
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
		bb.Size = UDim2.fromOffset(84, 22)
		bb.StudsOffsetWorldSpace = Vector3.new(0, pumpkin.Size.Y / 2 + 1.2, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 45
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
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
		return string.format("Hatching %d:%02d", math.floor(seconds / 60), seconds % 60)
	end

	-- "Hatching 0:20" over a placed pumpkin until it hatches (Bases.tick updates the text).
	local function carveTag(pumpkin: BasePart, seconds: number)
		local bb = Instance.new("BillboardGui")
		bb.Name = "CarveTag"
		bb.Size = UDim2.fromOffset(150, 30)
		bb.StudsOffsetWorldSpace = Vector3.new(0, pumpkin.Size.Y / 2 + 2.6, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 60
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
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
	-- centre line), else a living Jack (face and legs). "Jack" = hatched (kept name, saves and
	-- moves use it); JackHome = where clients idle / hop it on its plot.
	local function becomeAlive(pumpkin: BasePart)
		local seed = seedById[pumpkin:GetAttribute("Seed") or ""]
		if Looks.hatch(pumpkin, seed) then
			local pos = pumpkin.Position
			if math.abs(Lane.x - pos.X) > 1 then
				pumpkin.CFrame = CFrame.lookAt(pos, Vector3.new(Lane.x, pos.Y, pos.Z))
			end
		else
			if pumpkin:FindFirstChild("PetLook") then
				Looks.clear(pumpkin)
			end
			dressJack(pumpkin, true)
		end
		pumpkin:SetAttribute("JackHome", pumpkin.CFrame)
		pumpkin:SetAttribute("Jack", true)
	end

	-- The pumpkin hatches into its pet (or Jack). Clients play the hatch: everyone near sees the
	-- shell burst; the owner gets the flash, camera punch and the reveal card (built on the client
	-- from the pumpkin's attributes). isNew = the first time its owner hatches this type.
	local function carve(pumpkin: BasePart)
		pumpkin:SetAttribute("CarveAt", nil)
		local tag = pumpkin:FindFirstChild("CarveTag")
		if tag then
			tag:Destroy()
		end
		becomeAlive(pumpkin)
		local ownerId = pumpkin:GetAttribute("Owner") or 0
		local owner = Players:GetPlayerByUserId(ownerId)
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
		Remotes.carvedEvent:FireAllClients(pumpkin, ownerId, pumpkin:GetAttribute("Pet"), isNew)
	end

	-- Puts a new pumpkin on an empty plot, sized to fit it. Returns it (nil when not possible).
	-- extra.hoard = a Hoard pumpkin (x HoardMult); extra.jack = already hatched (no hatching).
	function Bases.put(
		plot: BasePart,
		seedId: string,
		sizeMult: number,
		mutation: string?,
		ownerId: number,
		extra: { hoard: boolean?, jack: boolean? }?
	): BasePart?
		local s = plotState[plot]
		if not s or s.pumpkin or not seedById[seedId] then
			return nil
		end
		local pumpkin = makePumpkin(seedId, sizeMult)
		-- Plots are flat cylinders lying on their side: the thin axis is X, the disc is Y x Z.
		local fit = math.min(plot.Size.Y, plot.Size.Z) * 0.95
		if pumpkin.Size.X > fit then
			pumpkin.Size *= fit / pumpkin.Size.X
		end
		pumpkin.CFrame = CFrame.new(plot.Position + Vector3.new(0, 0.15 + pumpkin.Size.Y / 2, 0))
			* CFrame.Angles(0, math.random() * math.pi * 2, 0)
		pumpkin:SetAttribute("Owner", ownerId)
		pumpkin:SetAttribute("Placed", true)
		if mutation and mutationById[mutation] then
			pumpkin:SetAttribute("Mutation", mutation)
			applyMutationLook(pumpkin, mutation)
		end
		if extra and extra.hoard then
			pumpkin:SetAttribute("Hoard", true)
			Hoards.look(pumpkin, extra.jack == true)
		end
		incomeTag(pumpkin)
		if extra and extra.jack then
			becomeAlive(pumpkin)
		else
			-- New players (first CarveNewUntil s of playtime): every type hatches fast.
			local owner = Players:GetPlayerByUserId(ownerId)
			local newbie = owner ~= nil
				and (owner:GetAttribute("PlayTime") or 0) < Config.CarveNewUntil
			local seconds = newbie and Config.CarveNewSeconds
				or seedById[seedId].order <= Config.CarveFastOrder and Config.CarveFastSeconds
				or Config.CarveSeconds
			pumpkin:SetAttribute("CarveAt", now() + seconds)
			carveTag(pumpkin, seconds)
		end
		pumpkin.Parent = plot
		s.pumpkin = pumpkin
		return pumpkin
	end

	-- What Bases.put needs to rebuild a pumpkin that is moving (hoard bonus, already a Jack).
	function Bases.extraOf(p: Instance): { hoard: boolean?, jack: boolean? }
		return { hoard = p:GetAttribute("Hoard") == true, jack = p:GetAttribute("Jack") == true }
	end

	-- Takes the pumpkin off a plot without destroying it (pick up, steal, ghost grab).
	function Bases.take(plot: BasePart): BasePart?
		local s = plotState[plot]
		local p = s and s.pumpkin
		if not s or not p then
			return nil
		end
		s.pumpkin = nil
		p:SetAttribute("Placed", nil)
		-- Off the plot: no more idling (clients) or hatching (a re-placed one hatches again).
		p:SetAttribute("JackHome", nil)
		p:SetAttribute("CarveAt", nil)
		for _, name in { "IncomeTag", "CarveTag" } do
			local tag = p:FindFirstChild(name)
			if tag then
				tag:Destroy()
			end
		end
		Bases.refresh(plot.Parent)
		return p
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

	-- Re-welds a stack from the bottom after a pumpkin was pulled out of the middle.
	local function restack(player: Player)
		local _, root = aliveRoot(player)
		local stack = carrying[player] or {}
		if not root then
			return
		end
		local height = 3
		for _, p in stack do
			for _, child in p:GetChildren() do
				if child:IsA("WeldConstraint") then
					child:Destroy()
				end
			end
			p.CFrame = root.CFrame * CFrame.new(0, height + p.Size.Y / 2, 0)
			height += p.Size.Y
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
	Bases.restack = restack

	-- A stolen pumpkin goes home: the owner's first empty plot, else their stack, else the ground.
	local function giveBack(owner: Player, p: BasePart, at: Vector3)
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
		elseif #(carrying[owner] or {}) >= carryCapacity(owner) or not stackPumpkin(owner, p) then
			dropLoose(p, at, Config.LooseSeconds, true)
		end
	end

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
				out[plotKey(plot, i)] = {
					s = p:GetAttribute("Seed"),
					z = p:GetAttribute("SizeMult") or 1,
					m = p:GetAttribute("Mutation"),
					h = p:GetAttribute("Hoard") == true or nil,
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
			local seed = type(entry) == "table" and seedById[entry.s]
			if not keys[tostring(key)] and seed then
				local mutation = mutationById[type(entry.m) == "string" and entry.m or ""]
				local income = seed.income
					* math.clamp(tonumber(entry.z) or 1, 0.1, 5)
					* (mutation and mutation.mult or 1)
					* (entry.h == true and Config.HoardMult or 1)
				refund += math.max(1, math.floor(income * Config.SellPerIncome + 0.5))
			end
		end
		if refund > 0 then
			refund = math.floor(refund * sellMult(player) + 0.5)
			local candy = candyValue(player)
			if candy then
				candy.Value += refund
			end
			hint(player, string.format("Your base got smaller, you got %s candy", short(refund)))
		end
		for i, plot in plotsOf(patch) do
			local entry = saved[plotKey(plot, i)]
			if
				type(entry) == "table"
				and type(entry.s) == "string"
				and seedById[entry.s]
				and plotState[plot]
				and not plotState[plot].pumpkin
			then
				local size = math.clamp(tonumber(entry.z) or 1, 0.1, 5)
				local mutation = if type(entry.m) == "string" then entry.m else nil
				-- Saved pumpkins were placed before: they come back hatched.
				Bases.put(
					plot,
					entry.s,
					size,
					mutation,
					player.UserId,
					{ hoard = entry.h == true, jack = true }
				)
			end
		end
		Bases.refresh(patch)
	end

	-- Place the top carried pumpkin on one of your empty plots (it keeps type, size and brew).
	local function place(player: Player, plot: BasePart)
		local patch = plot.Parent
		if patchOf[player] ~= patch or not plotState[plot] or plotState[plot].pumpkin then
			return
		end
		if not isLoaded(player) then
			hint(player, "Loading your farm...")
			return
		end
		local stack = carrying[player] or {}
		local top = stack[#stack]
		if not top then
			hint(player, "Smash wild pumpkins in the Pumpkin Meadow, then place them here.")
			return
		end
		local seedId = top:GetAttribute("Seed")
		if type(seedId) ~= "string" or not seedById[seedId] then
			return
		end
		table.remove(stack)
		local stolen = top:GetAttribute("StolenFrom")
		-- Fresh from a Hoard nest: delivered! (confetti and a reveal card)
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
			local key = seedId .. ":" .. (top:GetAttribute("Mutation") or "Plain")
			if not found[key] then
				found[key] = true
				publishIndex(player)
			end
			Remotes.placedEvent:FireAllClients(
				player,
				plot.Position,
				incomeOf(placed) * sellMult(player)
			)
			if fromHoard then
				Remotes.hoardEvent:FireClient(player, "deliver", seedId)
				Reveal.send(player, placed, false, "hoard")
			end
		end
		track(player, "place", 1)
		track(player, "placeType:" .. seedId, 1)
		if stolen then
			hint(player, "It's yours now! Stolen pumpkins on your base earn for you.")
		end
	end

	local function pickUp(player: Player, plot: BasePart)
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
		if #(carrying[player] or {}) >= carryCapacity(player) then
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

	-- Victim UserId -> server time of their last robbery.
	local robbedAt: { [number]: number } = {}

	local function steal(thief: Player, plot: BasePart)
		local patch = plot.Parent :: Instance
		local ownerId = patch:GetAttribute("Owner") or 0
		local owner = Players:GetPlayerByUserId(ownerId)
		local s = plotState[plot]
		if not s or not s.pumpkin or not owner or ownerId == thief.UserId then
			return
		end
		if not isLoaded(thief) or not aliveRoot(thief) then
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
		elseif not Unlock.has(owner, "PlayerSteal") then
			-- New-player shield: under Config.NewPlayerShield seconds of total playtime.
			hint(thief, owner.DisplayName .. " is a new farmer and shielded for now.")
		elseif t - (robbedAt[ownerId] or -math.huge) < Config.VictimCooldown then
			hint(thief, owner.DisplayName .. " was robbed a moment ago. Try again later.")
		elseif #(carrying[thief] or {}) >= carryCapacity(thief) then
			hint(thief, "Your hands are full!")
		else
			local p = Bases.take(plot) :: BasePart
			p:SetAttribute("StolenFrom", ownerId)
			if not stackPumpkin(thief, p) then
				giveBack(owner, p, plot.Position)
				return
			end
			robbedAt[ownerId] = t
			local seed = seedById[p:GetAttribute("Seed") or ""]
			local name = seed and seed.name or "a"
			local share = math.floor(pumpkinValue(p) * Config.StealOwnerShare + 0.5)
			addCandy(owner, share)
			-- The owner's client shows the alarm (toast, red flash, highlighted thief); the thief's
			-- shows "You stole a PUMPKIN!" plus RUN!!, the red vignette and the Drop button.
			Remotes.stealAlarmEvent:FireClient(owner, "robbed", thief.DisplayName, name, share)
			Remotes.stealAlarmEvent:FireClient(thief, "stole", name)
			Remotes.harvestedEvent:FireAllClients(thief, plot.Position)
			track(thief, "steal", 1)
		end
	end

	-- The owner's swing reached a thief carrying their pumpkins: those go back home.
	function Bases.defend(owner: Player, root: BasePart): boolean
		local got = false
		for _, thief in Players:GetPlayers() do
			local stack = carrying[thief]
			local _, thiefRoot = aliveRoot(thief)
			if
				thief ~= owner
				and stack
				and thiefRoot
				and (thiefRoot.Position - root.Position).Magnitude <= Config.BonkRange + 2
			then
				local back = 0
				for i = #stack, 1, -1 do
					local p = stack[i]
					if p:GetAttribute("StolenFrom") == owner.UserId then
						table.remove(stack, i)
						giveBack(owner, p, thiefRoot.Position)
						back += 1
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
				end
			end
		end
		return got
	end

	-- A thief died: their stolen pumpkins go home and Hoard pumpkins fly back to their nest (others
	-- are lost as before).
	function Bases.dropStolen(player: Player, at: Vector3)
		for _, p in carrying[player] or {} do
			local owner = Players:GetPlayerByUserId(p:GetAttribute("StolenFrom") or 0)
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
		bb.MaxDistance = 140
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
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
		if not patch or not isLoaded(player) or not Unlock.has(player, "PlayerSteal") then
			-- Nobody can raid a shielded base, so the lock opens with the shield's end.
			return
		end
		local t = now()
		if Bases.locksOff() then
			hint(player, "🩸 Blood Moon! Every lock is off right now.")
			return
		end
		local ready = patch:GetAttribute("LockCooldownUntil") or 0
		if t < ready then
			hint(player, string.format("Your lock recharges in %ds.", math.ceil(ready - t)))
			return
		end
		patch:SetAttribute("LockedUntil", t + Config.LockSeconds)
		patch:SetAttribute("LockCooldownUntil", t + Config.LockCooldown)
		setWall(patch, true)
		hint(player, string.format("🔒 Base locked for %d seconds!", Config.LockSeconds))
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
				setWall(patch, false)
			elseif untilAt then
				setWall(patch, true)
				local wall = patch:FindFirstChild("LockWall")
				local timer = wall and wall:FindFirstChild("LockTimer")
				local label = timer and timer:FindFirstChild("Label") :: TextLabel?
				if label then
					label.Text = string.format("🔒 LOCKED %ds", math.ceil(untilAt - t))
				end
			end
		end
		-- Hatching countdowns; a finished one hatches.
		for _, s in plotState do
			local p = s.pumpkin
			local carveAt = p and p:GetAttribute("CarveAt")
			if p and type(carveAt) == "number" then
				if t >= carveAt then
					local ok, err = pcall(carve, p)
					if not ok then
						warn("[Patch] Hatch failed:", err)
					end
				else
					local tag = p:FindFirstChild("CarveTag")
					local label = tag and tag:FindFirstChild("Label") :: TextLabel?
					local left = math.ceil(carveAt - t)
					if label then
						label.Text = hatchText(left)
					end
				end
			end
		end
		for player, patch in patchOf do
			if player.Parent and isLoaded(player) then
				Bases.refresh(patch)
				local income = player:GetAttribute("Income") or 0
				-- Spooky Hour pays x SpookyMult (orders still count the plain income).
				local total = (carry[player] or 0) + income * Spooky.mult()
				local whole = math.floor(total)
				carry[player] = total - whole
				if whole > 0 then
					addCandy(player, whole)
				end
				track(player, "income", math.floor(income), true)
			end
		end
	end

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
		prompt.RequiresLineOfSight = false
		prompt.Parent = parent
		return prompt
	end
	for _, patch in patchFolder:GetChildren() do
		for _, plot in plotsOf(patch) do
			plotState[plot] = { pumpkin = nil }
			for _, child in plot:GetChildren() do
				if child:IsA("ProximityPrompt") then
					child:Destroy()
				end
			end
			makePrompt(plot, "PlacePrompt", "Place", 0.2).Triggered:Connect(function(player)
				place(player, plot)
			end)
			makePrompt(plot, "PickupPrompt", "Pick up", 0.3).Triggered:Connect(function(player)
				pickUp(player, plot)
			end)
			makePrompt(plot, "StealPrompt", "Steal", Config.StealHold).Triggered:Connect(
				function(player)
					steal(player, plot)
				end
			)
		end
		local post = patch:FindFirstChild("SignPost")
		local holder: Instance? = post
		if post and not post:IsA("BasePart") then
			holder = post:FindFirstChildWhichIsA("BasePart", true)
		end
		holder = holder or patch:FindFirstChild("Soil")
		if holder then
			local lockPrompt = makePrompt(holder, "LockPrompt", "LOCK", 0.3)
			lockPrompt.ObjectText = "Your base"
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
	local gates = Config.Unlocks
	local played = player:GetAttribute("PlayTime") or 0
	for _, name in Unlock.NAMES do
		if not reset and Unlock.has(player, name) then
			continue
		end
		local on
		if name == "Haunt" then
			on = (lifetime[player] or 0) >= gates.HauntPillAt
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
		setOwnerSign(best, player.DisplayName .. "'s base", Color3.fromRGB(255, 200, 90))
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
	setOwnerSign(patch, "Free base", Color3.fromRGB(255, 230, 200))
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

	local function rollType(weights: { [string]: number }): string
		local total = 0
		for _, seed in Config.Seeds do
			total += weights[seed.id] or 0
		end
		local r = math.random() * total
		for _, seed in Config.Seeds do
			local w = weights[seed.id] or 0
			if w > 0 then
				if r <= w then
					return seed.id
				end
				r -= w
			end
		end
		return Config.Seeds[1].id
	end

	-- A small PS99-style bar (60x8 track, white number at its right). It starts hidden: each
	-- client shows it only on its current target and on pumpkins it hit in the last few seconds.
	-- Only rare types (Ghost or better) get a name over the bar, in the type's colour.
	local function hpBar(part: BasePart, seed)
		local rare = seed.order >= Config.RareNameOrder
		local bb = Instance.new("BillboardGui")
		bb.Name = "HpBar"
		bb.Size = UDim2.fromOffset(96, rare and 32 or 14)
		bb.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + 1.4, 0)
		bb.LightInfluence = 0
		bb.AlwaysOnTop = true
		bb.MaxDistance = Config.WildBarDistance
		bb.Enabled = false
		if rare then
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Size = UDim2.new(1, 0, 0, 16)
			name.Font = Enum.Font.FredokaOne
			name.TextScaled = true
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
		back.Size = UDim2.fromOffset(60, 8)
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
		hp.Size = UDim2.fromOffset(28, 14)
		hp.Font = Enum.Font.FredokaOne
		hp.TextScaled = true
		hp.TextXAlignment = Enum.TextXAlignment.Left
		hp.TextColor3 = Color3.new(1, 1, 1)
		hp.Text = short(seed.hp)
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
			label.Text = short(math.max(0, w.hp))
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
		local id = rollType(zoneDef.weights)
		local seed = seedById[id]
		local sizeMult = Config.SizeMin + math.random() * (Config.SizeMax - Config.SizeMin)
		local part = makePumpkin(id, sizeMult)
		part.Name = "WildPumpkin"
		local groundY = sp.Position.Y - sp.Size.Y / 2
		part.CFrame = CFrame.new(sp.Position.X, groundY + part.Size.Y / 2, sp.Position.Z)
			* CFrame.Angles(0, math.random() * math.pi * 2, 0)
		part:SetAttribute("Wild", true)
		part:SetAttribute("Zone", zoneId)
		part:SetAttribute("Hp", seed.hp)
		part:SetAttribute("MaxHp", seed.hp)
		hpBar(part, seed)
		part.Parent = folder
		taken[sp] = true
		count[zoneId] = (count[zoneId] or 0) + 1
		alive[part] = {
			part = part,
			hp = seed.hp,
			maxHp = seed.hp,
			size = part.Size,
			sizeMult = sizeMult,
			spawn = sp,
			zone = zoneId,
			damage = {},
			last = nil,
			tween = nil,
		}
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
	local function pop(w: WildState)
		local part = w.part
		alive[part] = nil
		count[w.zone] = math.max(0, (count[w.zone] or 1) - 1)
		taken[w.spawn] = nil
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
		local seed = seedById[seedId]
		-- The winner also gets a little candy (the burst that flies into their counter).
		local candy = 0
		if winner and seed then
			candy = math.max(1, math.floor(seed.income * Config.PopCandySeconds + 0.5))
			addCandy(winner, candy)
		end
		Remotes.wildPopEvent:FireAllClients(at, seedId, winner, candy)
		part:Destroy()
		if not winner then
			return
		end
		-- Lucky Swing: a chance of one rarity higher.
		local luck = Config.LuckyChance * upgradeLevel(winner, "Lucky")
		if seed and Config.Seeds[seed.order + 1] and math.random() < luck then
			seedId = Config.Seeds[seed.order + 1].id
		end
		local sizeMult = w.sizeMult
			* (hasSkill(winner, "BumperCrop") and 1 + Config.SkillSizeBonus or 1)
		local pumpkin = makePumpkin(seedId, sizeMult)
		local isNew = Reveal.isNew(winner, seedId)
		track(winner, "smash", 1)
		if #(carrying[winner] or {}) < carryCapacity(winner) and stackPumpkin(winner, pumpkin) then
			if hasSkill(winner, "AutoBrew") then
				local id = brewPumpkin(winner, pumpkin, false)
				refreshCarry(winner)
				Remotes.brewedEvent:FireAllClients(
					winner,
					at,
					{ { id = id, value = pumpkinValue(pumpkin) } }
				)
				track(winner, "brew", 1)
			end
		else
			dropLoose(
				pumpkin,
				at,
				Config.LooseSeconds,
				false,
				w.spawn.Position.Y - w.spawn.Size.Y / 2
			)
			Remotes.hintEvent:FireClient(
				winner,
				"Your hands are full! It's on the ground: place what you carry on your base first."
			)
		end
		Reveal.send(winner, pumpkin, isNew)
	end

	-- Swing at the nearest wild pumpkin in front of root (BonkRange from its side).
	function Wild.hit(player: Player, root: BasePart): boolean
		local look = root.CFrame.LookVector
		local best, bestDist = nil, math.huge
		-- A pumpkin in reach that sits in a zone this player has not unlocked (refused).
		local lockedZone: string? = nil
		for part, w in alive do
			local offset = part.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			local dist = math.max(0, flat.Magnitude - part.Size.X / 2)
			if math.abs(offset.Y) < 12 and dist <= Config.BonkRange and dist < bestDist then
				if flat.Magnitude < 3 or flat.Unit:Dot(look) > -0.2 then
					if hasZone(player, w.zone) then
						best, bestDist = w, dist
					else
						lockedZone = w.zone
					end
				end
			end
		end
		if not best then
			if lockedZone then
				local def = Config.Zones[lockedZone]
				Remotes.hintEvent:FireClient(
					player,
					string.format(
						"🔒 Unlock the %s at its gate first!",
						def and def.title or "zone"
					)
				)
			end
			return false
		end
		local damage = swingDamage(player)
		best.damage[player] = (best.damage[player] or 0) + math.min(damage, best.hp)
		best.last = player
		best.hp -= damage
		-- Clients do the juice (flash, squash, damage number, bar) on the part they are sent; the
		-- server no longer tweens Size, so nothing replicated fights the local squash.
		Remotes.wildHitEvent:FireAllClients(player, best.part.Position, damage, best.part)
		if best.hp <= 0 then
			pop(best)
		else
			setBar(best)
		end
		return true
	end

	-- Studio debug: N pumpkins of a type straight onto a player's stack (no capacity check).
	function Wild.give(player: Player, n: number, seedId: string?): number
		local id = seedId and seedById[seedId] and seedId or Config.Seeds[1].id
		local given = 0
		for _ = 1, n do
			local size = Config.SizeMin + math.random() * (Config.SizeMax - Config.SizeMin)
			local pumpkin = makePumpkin(id, size)
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
			spawns[zoneId] = list
		end
		Wild.fill()
		-- One wild pumpkin per zone per respawn tick (while that zone is below its max).
		while true do
			task.wait(Config.WildRespawn)
			for _, zoneId in Config.ZoneOrder do
				Wild.spawnOne(zoneId)
			end
		end
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
		if not isLoaded(player) then
			Remotes.hintEvent:FireClient(player, "Loading your farm...")
			return
		end
		if hasZone(player, zoneId) then
			Remotes.hintEvent:FireClient(player, "The " .. def.title .. " is already open for you!")
			return
		end
		local candy = candyValue(player)
		local cost = def.cost or 0
		if not candy or candy.Value < cost then
			Remotes.hintEvent:FireClient(
				player,
				string.format(
					"You need %s 🍬 to unlock the %s. Place pumpkins on your base to earn more!",
					short(cost),
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
		Remotes.hintEvent:FireClient(player, "🔓 The " .. def.title .. " is open! Go smash!")
		track(player, "unlockZone", 1)
	end

	-- Gate sign (Steal an Egg / Pet Sim 99 style): the zone name with its difficulty emoji in big
	-- white stroked letters and a yellow price pill ("🍬 1k") under it. Each client turns the pill
	-- green "UNLOCKED ✅" for zones it owns. Only readable up close (MaxDistance 80).
	local function gateSign(sign: BasePart, def)
		local old = sign:FindFirstChild("GateGui")
		if old then
			old:Destroy()
		end
		local ink = Color3.fromRGB(26, 15, 46)
		local bb = Instance.new("BillboardGui")
		bb.Name = "GateGui"
		bb.Size = UDim2.fromOffset(300, 120)
		bb.LightInfluence = 0
		bb.MaxDistance = 80
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromScale(1, 0.56)
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Text = def.title .. (def.emoji and (" " .. def.emoji) or "")
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
		pill.BackgroundColor3 = Color3.fromRGB(255, 205, 40)
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
		cost.Font = Enum.Font.FredokaOne
		cost.TextScaled = true
		cost.TextColor3 = Color3.new(1, 1, 1)
		cost.Text = "🍬 " .. short(def.cost or 0)
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
				prompt.ActionText = string.format("Unlock %s (%s 🍬)", def.title, short(def.cost))
				prompt.ObjectText = "Zone gate"
				prompt.HoldDuration = 0.4
				prompt.MaxActivationDistance = 14
				prompt.RequiresLineOfSight = false
				prompt.Parent = wall
				prompt.Triggered:Connect(function(player)
					unlockZone(player, zoneId)
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
		for _, player in Players:GetPlayers() do
			local character, root = aliveRoot(player)
			if not character or not root or not isLoaded(player) then
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
								short(def.cost or 0)
							)
						)
						break
					end
				end
			end
		end
	end
end

-- Hoards and Guardians ------------------------------------------------------------------------
-- Each zone (Config.Hoards) gets a straw nest of big Hoard pumpkins in its zone folder, guarded
-- by a sleeping giant (ServerStorage.GuardModels.<guardian> scaled to the zone's
-- guardHeight, else built from studded parts) welded to an invisible anchored root that the
-- server moves every Heartbeat (no Humanoid). Stealing a pumpkin wakes it: red "!", a roar,
-- then a chase. It bonks the thief within reach (their Hoard pumpkins fly back to the nest) or
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
		roar: Sound?,
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
	local NEST_R, SLOT_R, SLOT_FIT = 4.8, 2.3, 3.2
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
		for _, p in Players:GetPlayers() do
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
		bb.MaxDistance = 220
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
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
				if d.Name == "Eye" then
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
		local roar: Sound? = nil
		if (Config.Sounds.Roar or 0) ~= 0 then
			local s = Instance.new("Sound")
			s.Name = "Roar"
			s.SoundId = "rbxassetid://" .. Config.Sounds.Roar
			s.PlaybackSpeed = Config.GuardianRoarPitch
			s.Volume = 1
			s.RollOffMaxDistance = 160
			s.Parent = root
			roar = s
		end
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
			roar = roar,
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
		if g.state == "sleep" then
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

	local function wake(g: Guardian, player: Player)
		local first = g.zone == "Zone1" and player:GetAttribute("FirstHoardDone") ~= true
		player:SetAttribute("FirstHoardDone", true)
		-- Already after this thief, or busy with another one who still has the loot.
		if
			(g.state == "wake" or g.state == "chase")
			and (g.target == player or carriesFrom(g.target, g.zone))
		then
			return
		end
		g.share = first and Config.GuardianFirstShare or Config.GuardianShare
		g.state = "wake"
		g.target = player
		g.wokeAt = os.clock()
		g.chaseEnd = os.clock() + Config.GuardianChaseSeconds
		g.seen = 0
		setAwake(g, true)
		if g.roar then
			g.roar:Play()
		end
	end

	-- escaped = the thief got away with the loot (base, zone edge or time).
	local function giveUp(g: Guardian, escaped: boolean)
		local thief = g.target
		g.target = nil
		g.state = "return"
		g.alertTag.Enabled = false
		if escaped and thief and thief.Parent and carriesFrom(thief, g.zone) then
			Remotes.hoardEvent:FireClient(thief, "safe")
		end
	end

	-- Hoard pumpkins sparkle gold (in the nest, carried and placed). Until they hatch they wear
	-- the glowing ServerStorage.PetModels.MysteryPumpkin look when it exists (hatched = true
	-- skips it: the pet replaces it at once).
	function Hoards.look(p: BasePart, hatched: boolean?)
		if not hatched and p:GetAttribute("Jack") ~= true and not p:FindFirstChild("PetLook") then
			Looks.attach(p, "PetModels", Config.MysteryModel, p.Size.Y, C(255, 170, 70))
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
		local p = makePumpkin(Config.Hoards[h.zone].type, Config.HoardSize)
		p.Name = "HoardPumpkin"
		-- Smaller to fit the nest; income uses the SizeMult attribute, not the look.
		if p.Size.X > SLOT_FIT then
			p.Size *= SLOT_FIT / p.Size.X
		end
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
		-- Every fresh Hoard pumpkin the thief carries goes back (each to its own nest).
		local stack = carrying[thief] or {}
		for i = #stack, 1, -1 do
			local p = stack[i]
			if p:GetAttribute("HoardZone") then
				table.remove(stack, i)
				Hoards.giveBack(p, thiefRoot.Position)
			end
		end
		Bases.restack(thief)
		refreshCarry(thief)
		local away = V(thiefRoot.Position.X - g.pos.X, 0, thiefRoot.Position.Z - g.pos.Z)
		away = away.Magnitude > 0.1 and away.Unit or g.look
		Remotes.knockEvent:FireClient(thief, away * 45 + V(0, 30, 0), 0.5)
		Remotes.hoardEvent:FireClient(thief, "bonk")
		Remotes.ghostPopEvent:FireAllClients(thiefRoot.Position, nil, 0)
		giveUp(g, false)
	end

	local seat -- forward: grab and seat refer to each other through the prompt

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
		if not isLoaded(player) then
			Remotes.hintEvent:FireClient(player, "Loading your farm...")
			return
		end
		if not hasZone(player, h.zone) or not aliveRoot(player) then
			return
		end
		if #(carrying[player] or {}) >= carryCapacity(player) then
			Remotes.hintEvent:FireClient(
				player,
				"Your hands are full! Place what you carry on your base first."
			)
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
		track(player, "hoardSteal", 1)
		wake(h.guard, player)
	end

	function seat(h: Hoard, i: number, p: BasePart)
		h.slots[i] = p
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = slotCFrame(h, i, p)
		p.Parent = h.model
		local seed = seedById[p:GetAttribute("Seed") or ""]
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealPrompt"
		prompt.ActionText = "Steal"
		prompt.ObjectText = (seed and seed.name or "") .. " pumpkin · Hoard"
		prompt.HoldDuration = Config.HoardHold
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = p
		prompt.Triggered:Connect(function(player)
			grab(h, p, player)
		end)
	end

	-- A Hoard pumpkin leaves a player (bonk, drop, death, Haunt): HoardReturnDelay seconds later a
	-- new one arcs from there back into a free slot of its nest.
	function Hoards.giveBack(p: BasePart, at: Vector3)
		local h = hoards[p:GetAttribute("HoardZone") or ""]
		p:Destroy()
		if not h then
			return
		end
		h.pending += 1
		task.delay(Config.HoardReturnDelay, function()
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
			for i = 1, Config.HoardCount do
				if not h.slots[i] then
					local p = newPumpkin(h)
					seat(h, i, p)
					Remotes.harvestedEvent:FireAllClients(nil, p.Position)
				end
			end
			h.nextRefill = os.clock() + Config.HoardRefill
		end
	end

	RunService.Heartbeat:Connect(function(dt)
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
			if g.state == "wake" or g.state == "chase" then
				local thief = g.target
				local thiefRoot: BasePart? = nil
				if thief and thief.Parent then
					local _, r = aliveRoot(thief)
					thiefRoot = r
				end
				if not thief or not thiefRoot or not carriesFrom(thief, h.zone) then
					giveUp(g, false)
				else
					local at = thiefRoot.Position
					local pad = Config.HoardLeashPad or 10
					if
						now >= g.chaseEnd
						or inOwnBase(thief, at)
						or at.Z < h.zMin - pad
						or at.Z > h.zMax + pad
						or at.Z < Lane.safeZ
					then
						giveUp(g, true)
					else
						local to = V(at.X - g.pos.X, 0, at.Z - g.pos.Z)
						if to.Magnitude > 0.1 then
							g.look = to.Unit
						end
						if g.state == "wake" then
							-- A short grace while it gets up and roars.
							if now - g.wokeAt >= Config.GuardianWake then
								g.state = "chase"
							end
							pose(g)
						elseif to.Magnitude <= Config.GuardianCatch + g.reach then
							bonk(g, thief, thiefRoot)
						else
							-- Share of the thief's speed: their walk speed with the carry slow-down,
							-- or what they really move at (sprinting) if that is more.
							local carried = #(carrying[thief] or {})
							local walk = math.max(
								Config.MinCarrySpeed,
								Config.WalkSpeed - carried * Config.SlowPerPumpkin
							)
							local v = thiefRoot.AssemblyLinearVelocity
							local moving =
								math.min(V(v.X, 0, v.Z).Magnitude, Config.SprintSpeed + 6)
							g.seen += (moving - g.seen) * math.min(1, dt * 4)
							local speed =
								math.max(Config.GuardianMinSpeed, g.share * math.max(walk, g.seen))
							step(g, to.Unit, math.min(speed * dt, to.Magnitude), dt)
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
		tag(base, "HoardSign", "⭐ HOARD ⭐", C(255, 214, 80), UDim2.fromScale(9, 2.2), 7)

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
			if def and zone and seedById[def.type] then
				local ok, err = pcall(buildHoard, zoneId, zone, def)
				if not ok then
					warn("[Patch] Could not build the Hoard in " .. zoneId .. ":", err)
				end
			end
		end
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
				"Smash wild pumpkins in the Pumpkin Meadow first, then brew them here."
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
local lastBloodMoonAt = os.clock()

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
	lastBloodMoonAt = os.clock()
	state:SetAttribute("KingWakesAt", workspace:GetServerTimeNow() + Config.BloodMoonGap)
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
	if filled >= goal and os.clock() - lastBloodMoonAt >= Config.BloodMoonGap then
		task.defer(startBloodMoon)
	end
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
		if not isLoaded(player) then
			Remotes.hintEvent:FireClient(player, "Loading your farm...")
			return
		end
		-- The Witch opens later (Config.Unlocks.Sell); the client hides the prompt until then.
		if not Unlock.has(player, "Sell") then
			return
		end
		local stack = carrying[player] or {}
		if #stack == 0 then
			Remotes.hintEvent:FireClient(
				player,
				"Smash wild pumpkins and bring them here. Brew them first for more candy!"
			)
			return
		end
		local total, count, raw = 0, 0, 0
		local found = indexOf[player] or {}
		indexOf[player] = found
		local news = {}
		local bySeed, byMutation = {}, {}
		local brewed = 0
		for _, pumpkin in stack do
			if pumpkin.Parent then
				local seedId = pumpkin:GetAttribute("Seed")
				local finish = pumpkin:GetAttribute("Mutation") or "Plain"
				local bonus = rowDone(player, seedId) and (1 + Config.IndexRowBonus) or 1
				total += pumpkinValue(pumpkin) * bonus
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
							seedById[seedId].name
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
		total = math.floor(total * sellMult(player) + 0.5)
		carrying[player] = {}
		refreshCarry(player)
		addCandy(player, total)
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
	local tool = type(id) == "string" and toolById[id]
	if not tool or not tool.cost then
		return false, "?"
	end
	if not isLoaded(player) then
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
	local candy = candyValue(player)
	if not candy or candy.Value < tool.cost then
		return false, "Need " .. short(tool.cost)
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
	if not isLoaded(player) then
		return false, "Loading"
	end
	local level = upgradeLevel(player, id :: string)
	if level >= info.max then
		return false, "MAX"
	end
	local cost = math.floor(info.base * (level + 1) ^ Config.CostPower)
	local candy = candyValue(player)
	if not candy or candy.Value < cost then
		return false, "Need " .. short(cost)
	end
	candy.Value -= cost
	player:SetAttribute("Up_" .. (id :: string), level + 1)
	track(player, "upgrade", 1)
	track(player, "upgrade:" .. (id :: string), 1)
	return true
end

Remotes.lockEvent.OnServerEvent:Connect(function(player)
	Bases.lock(player)
end)

-- Drop button: the whole stack lands around the player as loose pickups (stolen ones keep their
-- owner, so the owner picking them up gets them back for free).
Remotes.dropEvent.OnServerEvent:Connect(function(player)
	local stack = carrying[player]
	local character, root = aliveRoot(player)
	if not stack or #stack == 0 or not character or not root then
		return
	end
	carrying[player] = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, loose, ghostFolder }
	params.RespectCanCollide = true
	for i, p in stack do
		local a = i / #stack * math.pi * 2
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
	local function hauntCost(player: Player): number
		return math.floor(
			Config.HauntCost * Config.HauntGrowth ^ (player:GetAttribute("Haunts") or 0)
		)
	end

	Remotes.hauntFunction.OnServerInvoke = function(player: Player)
		if not isLoaded(player) then
			return false, "Loading"
		end
		local candy = candyValue(player)
		local cost = hauntCost(player)
		if not candy or candy.Value < cost then
			return false, "Need " .. short(cost)
		end
		candy.Value = Config.StartCandy
		for id in Config.Upgrades do
			if not (id == "Stack" and hasSkill(player, "KeepStack")) then
				player:SetAttribute("Up_" .. id, 0)
			end
		end
		unlocked[player] = startUnlocked()
		-- Zones close again (only the free Pumpkin Meadow stays open).
		zonesOf[player] = {}
		publishZones(player)
		for _, p in carrying[player] or {} do
			if p:GetAttribute("HoardZone") then
				Hoards.giveBack(p, p.Position)
			else
				p:Destroy()
			end
		end
		carrying[player] = {}
		-- Tools are kept; base pumpkins are cleared.
		local patch = patchOf[player]
		if patch then
			Bases.clear(patch)
		end
		Bases.incomeCarry[player] = nil
		-- Haunt number n pays n Souls.
		local haunts = (player:GetAttribute("Haunts") or 0) + 1
		player:SetAttribute("Haunts", haunts)
		player:SetAttribute("Souls", (player:GetAttribute("Souls") or 0) + haunts)
		refreshCarry(player)
		-- Rotating rewards were priced from the pre-Haunt best type; re-deal them at the new value so
		-- cheap orders saved up for after a Haunt cannot pay it back.
		local o = orders[player]
		if o and o.tut > TUTORIAL_COUNT then
			nextOrders(player)
			publishOrders(player)
		end
		Remotes.announceEvent:FireAllClients(
			string.format("%s HAUNTED! Haunt #%d", player.DisplayName, haunts)
		)
		onboard(player, 8)
		return true
	end
end

Remotes.buySkillFunction.OnServerInvoke = function(player: Player, id: unknown)
	local skill = type(id) == "string" and skillById[id]
	if not skill then
		return false, "?"
	end
	if not isLoaded(player) then
		return false, "Loading"
	end
	if hasSkill(player, skill.id) then
		return false, "Owned"
	end
	local before = skillAt[skill.branch .. ":" .. (skill.tier - 1)]
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
	local assets = ServerStorage:FindFirstChild("PolishAssets")
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
	local function stealTargets(): { BasePart }
		local list = {}
		for plot, s in plotState do
			local patch = plot.Parent
			local owner = patch and Players:GetPlayerByUserId(patch:GetAttribute("Owner") or 0)
				or nil
			if
				s.pumpkin
				and s.pumpkin.Parent == plot
				and not s.pumpkin:GetAttribute("Targeted")
				and not Bases.isLocked(plot.Parent)
				and Unlock.has(owner, "PlayerSteal")
			then
				table.insert(list, plot)
			end
		end
		return list
	end

	local spawnPoints = {}
	for _, s in spawnFolder:GetChildren() do
		table.insert(spawnPoints, (s :: BasePart).Position)
	end

	function spawnGhost(): boolean
		local targets = stealTargets()
		if #targets == 0 then
			return false
		end
		local plot = targets[math.random(#targets)]
		local pumpkin = plotState[plot].pumpkin :: BasePart
		pumpkin:SetAttribute("Targeted", true)
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
			hp = Config.GhostHp + math.floor(ownedPatchCount() / Config.GhostHpPatches),
			target = pumpkin,
			plot = plot,
			carried = nil,
			home = home,
			fleeing = false,
			bob = math.random() * 6,
			bait = pumpkinValue(pumpkin),
		})
		return true
	end
end

local function removeGhost(ghost: Ghost)
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
			dropLoose(ghost.carried, at, 60, true)
		end
		ghost.carried = nil
		removeGhost(ghost)
		local candy = 0
		if by then
			candy = ghostCandy(by, ghost)
			addCandy(by, candy)
			track(by, "bonkGhost", 1)
		end
		Remotes.ghostPopEvent:FireAllClients(at, by, candy)
	end
end

RunService.Heartbeat:Connect(function(dt)
	for i = #ghosts, 1, -1 do
		local ghost = ghosts[i]
		if not ghost.model.Parent then
			table.remove(ghosts, i)
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
				or Bases.isLocked((ghost.plot :: BasePart).Parent)
			then
				-- The pumpkin was picked up first (or the base got locked): drift home.
				ghost.fleeing = true
				ghost.target = nil
				continue
			end
			goal = target.Position + Vector3.new(0, target.Size.Y / 2 + 2.4, 0)
		end
		local flatGoal = Vector3.new(goal.X, 0, goal.Z)
		local flatPos = Vector3.new(pos.X, 0, pos.Z)
		local toGoal = goal - pos
		local speed = Config.GhostSpeed * (ghost.fleeing and 1.25 or 1)
		if toGoal.Magnitude < 1.2 then
			if ghost.fleeing then
				if ghost.carried then
					local owner =
						Players:GetPlayerByUserId(ghost.carried:GetAttribute("Owner") or 0)
					if owner then
						Remotes.stolenEvent:FireClient(owner, pos)
					end
				end
				removeGhost(ghost)
			else
				-- Grab the pumpkin off the plot.
				local plot = ghost.plot :: BasePart
				local pumpkin = ghost.target :: BasePart
				Bases.take(plot)
				pumpkin:SetAttribute("Targeted", nil)
				pumpkin.Anchored = false
				pumpkin.Massless = true
				pumpkin.CanQuery = false
				stripPumpkin(pumpkin)
				pumpkin.CFrame = ghost.root.CFrame * CFrame.new(0, -3.4 - pumpkin.Size.Y / 2, 0)
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = ghost.root
				weld.Part1 = pumpkin
				weld.Parent = pumpkin
				pumpkin.Parent = ghost.model
				ghost.carried = pumpkin
				ghost.target = nil
				ghost.fleeing = true
				local owner = Players:GetPlayerByUserId(pumpkin:GetAttribute("Owner") or 0)
				if owner then
					Remotes.hintEvent:FireClient(
						owner,
						"👻 A ghost grabbed your pumpkin! Bonk it to get it back!"
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
	local function weldTo(handle: BasePart, part: BasePart)
		part.CanCollide = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
	end

	local function buildScythe(def): Tool
		local tool = Instance.new("Tool")
		tool.Name = "Scythe"
		tool.ToolTip = def.name
		tool.CanBeDropped = false
		-- Held upright like a reaper's scythe: the shaft stands vertical in the right hand, most of
		-- it above the hand, so the blade at the top clears the head and reads over the shoulder
		-- from the chase camera; the blade sweeps out to the right and forward and hooks down.
		-- Roblox welds the handle at hand * C0 * Grip:Inverse(), where C0 (R6 RightGrip / R15
		-- RightGripAttachment) is the hand turned -90 on X. While a tool is held the default
		-- animation raises the arm straight forward, which turns the arm +90 on X, so
		-- hand * C0 is a frame aligned with the character (X right, Y up, -Z forward) at the
		-- hand. Grip = hold:Inverse() therefore puts the handle at `hold` in that upright frame:
		-- `up` studs above the hand, top leaning `lean` degrees forward.
		local h = Config.ScytheHold
		local hold = CFrame.new(h.right, 0, -h.forward)
			* CFrame.Angles(math.rad(-h.lean), 0, 0)
			* CFrame.new(0, h.up, 0)
		tool.Grip = hold:Inverse()
		tool:SetAttribute("ToolId", def.id)
		local k = 1 + 0.06 * (def.order - 1)
		local SHAFT = 5.4
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.32, SHAFT, 0.32)
		handle.Material = Enum.Material.Wood
		handle.Color = Color3.fromRGB(62, 40, 26)
		handle.Transparency = 0
		handle.CanCollide = false
		handle.CanQuery = false
		handle.CanTouch = true
		handle.Parent = tool
		local function metalPart(
			name: string,
			size: Vector3,
			cf: CFrame,
			color: Color3,
			neon: boolean?
		)
			local p = Instance.new("Part")
			p.Name = name
			p.Size = size
			p.Material = neon and Enum.Material.Neon or Enum.Material.Metal
			p.Color = color
			p.CanQuery = false
			p.CFrame = cf
			weldTo(handle, p)
			p.Parent = tool
			return p
		end
		local top = handle.CFrame * CFrame.new(0, SHAFT / 2 - 0.15, 0)
		-- Collar at the top and a cap at the foot in the tool's tier colour, plus a small grip
		-- peg sticking out of the shaft (a real scythe's second handle).
		metalPart("Collar", Vector3.new(0.58, 0.5, 0.58), top, def.color)
		metalPart(
			"Pommel",
			Vector3.new(0.46, 0.36, 0.46),
			handle.CFrame * CFrame.new(0, -SHAFT / 2, 0),
			def.color
		)
		local peg = metalPart(
			"Peg",
			Vector3.new(0.22, 0.22, 0.9),
			handle.CFrame * CFrame.new(0, SHAFT * 0.12, -0.45),
			Color3.fromRGB(62, 40, 26)
		)
		peg.Material = Enum.Material.Wood
		-- The blade: a silver arc of flat segments in a plane through the shaft, starting at the
		-- top and swept 40 degrees forward from the right (so its broad face shows from behind),
		-- curving from level to hooked down. Each segment has a darker cutting edge along its
		-- lower (inner) side; tier 4+ blades get a neon edge in the tier colour.
		-- Steel: Metal material, cool silver, a touch of reflectance; the edge is darker steel.
		local SILVER = Color3.fromRGB(200, 205, 215)
		local edgeColor = def.order >= 4 and def.color or Color3.fromRGB(70, 74, 86)
		local bladeFrame = top * CFrame.new(0, -0.05, 0) * CFrame.Angles(0, math.rad(40), 0)
		local segments = {
			{ len = 1.1, angle = 10, width = 0.78 },
			{ len = 1.0, angle = -4, width = 0.72 },
			{ len = 0.95, angle = -22, width = 0.62 },
			{ len = 0.85, angle = -42, width = 0.5 },
			{ len = 0.7, angle = -64, width = 0.36 },
		}
		local at = Vector3.new(0.1, 0, 0)
		local root: CFrame? = nil
		local tip = bladeFrame
		for i, seg in segments do
			local len, width = seg.len * k, seg.width * k
			local a = math.rad(seg.angle)
			local dir = Vector3.new(math.cos(a), math.sin(a), 0)
			local center = at + dir * (len / 2)
			local cf = bladeFrame * CFrame.new(center) * CFrame.Angles(0, 0, a)
			local head = metalPart("Head", Vector3.new(len + 0.06, width, 0.14), cf, SILVER)
			head.Material = Enum.Material.Metal
			head.Reflectance = 0.15
			local edge = metalPart(
				"Edge",
				Vector3.new(len + 0.06, 0.13 * k, 0.17),
				cf * CFrame.new(0, -width / 2, 0),
				edgeColor,
				def.order >= 4
			)
			if def.order < 4 then
				edge.Reflectance = 0.1
			end
			if i == 1 then
				root = cf
			end
			at += dir * len
			tip = bladeFrame * CFrame.new(at)
		end
		-- Swing trail: a white ribbon from the blade root to its tip. Off until a client swings.
		local a0 = Instance.new("Attachment")
		a0.Name = "TrailRoot"
		a0.CFrame = handle.CFrame:ToObjectSpace(root or top)
		a0.Parent = handle
		local a1 = Instance.new("Attachment")
		a1.Name = "TrailTip"
		a1.CFrame = handle.CFrame:ToObjectSpace(tip)
		a1.Parent = handle
		local trail = Instance.new("Trail")
		trail.Name = "SwingTrail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.2
		trail.MinLength = 0.05
		trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.WidthScale = NumberSequence.new(1, 0.35)
		trail.LightEmission = 0.7
		trail.Enabled = false
		trail.Parent = handle
		return tool
	end

	for _, name in { "Mallet", "Scythe" } do
		local old = StarterPack:FindFirstChild(name)
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
					if not keep and child:GetAttribute("ToolId") == def.id then
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
			tool = buildScythe(def)
			tool.Parent = backpack
		end
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

-- Grants a tool (the King's MVP drop) and puts the best one in the player's hands.
local function grantTool(player: Player, id: string): boolean
	local owned = toolsOf[player]
	if not owned or owned[id] or not toolById[id] then
		return false
	end
	owned[id] = true
	publishTools(player)
	giveTool(player)
	return true
end

-- King state lives here so bonks can reach it.
local king = {
	active = false,
	hp = 0,
	maxHp = 0,
	damage = {} :: { [Player]: number },
	faceBase = kingFace.CFrame,
	phase = 1,
	shield = false,
	stunnedUntil = 0,
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
	for i = 1, math.min(3, #list) do
		table.insert(parts, list[i].name .. "  " .. list[i].d)
	end
	state:SetAttribute("KingTop", table.concat(parts, "\n"))
end

-- One swing hits the first of: a thief carrying your pumpkins, a ghost, the King, a wild pumpkin.
Remotes.bonkEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	-- Fast Hands swings faster; a little slack for network jitter.
	local cooldown = Config.BonkCooldown
		/ (hasSkill(player, "QuickRoots") and 1 + Config.SkillSwingBonus or 1)
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
		best.hp -= hits
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
	if king.active and not king.shield then
		local flat = Vector3.new(
			kingFace.Position.X - root.Position.X,
			0,
			kingFace.Position.Z - root.Position.Z
		)
		if flat.Magnitude - kingFace.Size.X / 2 <= Config.KingReach then
			local stunned = os.clock() < king.stunnedUntil
			local dealt = swingDamage(player) * (stunned and 2 or 1)
			if hasSkill(player, "KingSlayer") then
				dealt = math.floor(dealt * Config.SkillKingDamageMult + 0.5)
			end
			-- At most KingSwingsPerSecond swings' worth per player in each one-second window.
			local window = king.dps[player]
			if not window or now - window.t >= 1 then
				window = { t = now, d = 0 }
				king.dps[player] = window
			end
			dealt = math.min(dealt, dealt * Config.KingSwingsPerSecond - window.d)
			if dealt <= 0 then
				return
			end
			window.d += dealt
			king.hp = math.max(0, king.hp - dealt)
			king.damage[player] = (king.damage[player] or 0) + dealt
			king.lastHitter = player
			state:SetAttribute("KingHp", king.hp)
			Remotes.kingHitEvent:FireAllClients(player, dealt, stunned)
			track(player, "kingHit", 1)
			track(player, "kingDamage", dealt)
			if king.hp <= 0 then
				defeatKing()
			end
			return
		end
	end
	Wild.hit(player, root)
end)

-- Day / midnight / Blood Moon -------------------------------------------------------------------

local function setPhase(phase: string, seconds: number)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("PhaseEnds", workspace:GetServerTimeNow() + seconds)
end

local function clearGhosts()
	for i = #ghosts, 1, -1 do
		popGhost(ghosts[i], nil)
	end
end

local function rainCandy()
	local template = seedTemplate(seedById.Golden)
	for _ = 1, Config.RainCount do
		local a = math.random() * math.pi * 2
		local r = 10 + math.random() * 26
		local drop = template:Clone()
		drop.Name = "RainPumpkin"
		drop.Size *= 1.4 / (drop.Size.X / 2.5)
		drop.Anchored = false
		drop.CanCollide = true
		drop.CanTouch = true
		-- Around the Giant Jack (the King's spot in the hub).
		drop.CFrame = CFrame.new(
			giantJack.Position.X + math.cos(a) * r,
			giantJack.Position.Y + 20 + math.random() * 20,
			giantJack.Position.Z + math.sin(a) * r
		)
		drop.Parent = loose
		local taken = false
		drop.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if taken or not player then
				return
			end
			taken = true
			addCandy(player, Config.RainCandy)
			Remotes.rainEvent:FireAllClients(player, drop.Position)
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

local phaseToken = 0
local runDay -- forward

local function endBloodMoon(refill: number)
	king.active = false
	king.shield = false
	giantJack.Transparency = 0
	giantJack.CanCollide = true
	kingFace.Transparency = 1
	kingFace.Size = king.faceSize or kingFace.Size
	kingFace.CFrame = king.faceBase
	state:SetAttribute("KingHp", nil)
	state:SetAttribute("KingMaxHp", nil)
	state:SetAttribute("KingPhase", nil)
	state:SetAttribute("KingShield", nil)
	state:SetAttribute("KingStunned", nil)
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
	phaseToken += 1
	-- Finale: the King swells, then bursts.
	Remotes.kingDoneEvent:FireAllClients("swell", {})
	local grow = TweenService:Create(
		kingFace,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = kingFace.Size * 1.4,
		}
	)
	grow:Play()
	grow.Completed:Wait()
	-- Frozen at startBloodMoon: sales during the fight cannot inflate the payout.
	local pool = king.pool
	local total = 0
	for _, d in king.damage do
		total += d
	end
	local payouts = {}
	local mvp, mvpDamage = nil, 0
	for player, d in king.damage do
		if player.Parent then
			local amount = Config.KingBase + math.floor(pool * d / math.max(total, 1))
			if player == king.lastHitter then
				amount += Config.KingLastHit
			end
			addCandy(player, amount)
			payouts[tostring(player.UserId)] = amount
			local kings = player:FindFirstChild("leaderstats")
				and player.leaderstats:FindFirstChild("Kings") :: IntValue?
			if kings then
				kings.Value += 1
			end
			if d > mvpDamage then
				mvp, mvpDamage = player, d
			end
		end
	end
	for _, player in Players:GetPlayers() do
		player:SetAttribute("MVP", player == mvp)
	end
	Remotes.kingDoneEvent:FireAllClients("won", payouts, mvp)
	-- The MVP gets the Pumpkin King Cleaver (once).
	if mvp and grantTool(mvp, "PumpkinKingCleaver") then
		Remotes.announceEvent:FireAllClients(mvp.DisplayName .. " got the PUMPKIN KING CLEAVER!")
	end
	state:SetAttribute(
		"JackBase",
		math.floor((state:GetAttribute("JackBase") or Config.JackGoal) * Config.JackGrowth)
	)
	kingFace.Transparency = 1
	task.wait(2)
	endBloodMoon(0)
	rainCandy()
end

do
	-- Telegraphed attacks: clients draw the red circles; the server checks who is inside when they land.
	local function landAttack(circles: { { pos: Vector3, radius: number } })
		for _, player in Players:GetPlayers() do
			local root = player.Character
				and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				for _, c in circles do
					local flat =
						Vector3.new(root.Position.X - c.pos.X, 0, root.Position.Z - c.pos.Z)
					if
						flat.Magnitude <= c.radius - Config.KingGrace
						and root.Position.Y - c.pos.Y < 8
					then
						local out = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
						Remotes.knockEvent:FireClient(
							player,
							out * 50 + Vector3.new(0, 40, 0),
							Config.KingDizzy
						)
						break
					end
				end
			end
		end
	end

	local function attack(token: number, kind: string)
		local circles = {}
		local warn
		if kind == "Slam" then
			warn = Config.SlamWarn
			table.insert(circles, { pos = kingGround, radius = Config.SlamRadius })
		else
			warn = Config.VolleyWarn
			local players = Players:GetPlayers()
			local n = 0
			for _, player in players do
				local root = player.Character
					and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local near = root
					and Vector3.new(
							root.Position.X - kingFace.Position.X,
							0,
							root.Position.Z - kingFace.Position.Z
						).Magnitude
						< 80
				if root and near and n < 10 then
					n += 1
					table.insert(circles, {
						pos = Vector3.new(root.Position.X, kingGround.Y, root.Position.Z),
						radius = 7,
					})
				end
			end
			for _ = 1, 2 do
				local a = math.random() * math.pi * 2
				local r = 14 + math.random() * 22
				table.insert(circles, {
					pos = kingGround + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r),
					radius = 7,
				})
			end
		end
		Remotes.telegraphEvent:FireAllClients(kind, circles, warn)
		task.wait(warn)
		if token ~= phaseToken or not king.active then
			return
		end
		if kind == "Slam" then
			local up = TweenService:Create(
				kingFace,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					CFrame = king.faceBase * CFrame.new(0, 7, 0),
				}
			)
			up:Play()
			up.Completed:Wait()
			local down = TweenService:Create(
				kingFace,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					CFrame = king.faceBase,
				}
			)
			down:Play()
			down.Completed:Wait()
		end
		Remotes.stompEvent:FireAllClients(kind, circles)
		landAttack(circles)
	end

	local function spawnLackeys(count: number)
		local cauldrons = cauldronFolder:GetChildren()
		for i = 1, count do
			local pot = cauldrons[(i - 1) % #cauldrons + 1]:FindFirstChild("Pot") :: BasePart
			local a = math.random() * math.pi * 2
			local at = pot.Position + Vector3.new(math.cos(a) * 9, 6, math.sin(a) * 9)
			local model, root = buildGhost(at, true)
			table.insert(ghosts, {
				model = model,
				root = root,
				hp = Config.LackeyHp,
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
			king.stunnedUntil = os.clock() + Config.StunSeconds
			state:SetAttribute("KingShield", nil)
			state:SetAttribute("KingStunned", true)
			Remotes.kingDoneEvent:FireAllClients("stun", {})
			TweenService:Create(kingFace, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {
				CFrame = king.faceBase
					* CFrame.new(0, -2, 0)
					* CFrame.Angles(math.rad(25), 0, math.rad(12)),
			}):Play()
			task.delay(Config.StunSeconds, function()
				state:SetAttribute("KingStunned", nil)
				if king.active then
					TweenService:Create(kingFace, TweenInfo.new(0.4), { CFrame = king.faceBase })
						:Play()
				end
			end)
		end
	end

	-- First every lock is off for LocksOffSeconds (state "LocksOff" = its end time), then the
	-- Pumpkin King wakes. skipWindow (Studio debug) wakes him at once.
	function startBloodMoon(skipWindow: boolean?)
		if state:GetAttribute("Phase") == "BloodMoon" then
			return
		end
		phaseToken += 1
		local token = phaseToken
		clearGhosts()
		if not skipWindow then
			-- LocksOff first: clients read it when the phase changes.
			state:SetAttribute("LocksOff", workspace:GetServerTimeNow() + Config.LocksOffSeconds)
			setPhase("BloodMoon", Config.LocksOffSeconds + Config.KingSeconds)
			Bases.clearLocks()
			task.wait(Config.LocksOffSeconds)
			if token ~= phaseToken then
				return
			end
		end
		state:SetAttribute("LocksOff", nil)
		Remotes.kingDoneEvent:FireAllClients("wake", {})
		local players = #Players:GetPlayers()
		king.counted = {}
		king.dps = {}
		king.maxHp = Config.KingBaseHp
		for _, player in Players:GetPlayers() do
			local add = kingPlayerHp(player)
			king.counted[player] = add
			king.maxHp += add
		end
		king.hp = king.maxHp
		king.pool = math.floor(jackGoal() * Config.KingPoolShare)
		king.damage = {}
		king.active = true
		king.phase = 1
		king.shield = false
		king.stunnedUntil = 0
		king.lastHitter = nil
		king.faceSize = king.faceSize or kingFace.Size
		kingFace.Size = king.faceSize
		kingFace.CFrame = king.faceBase
		for _, player in Players:GetPlayers() do
			player:SetAttribute("MVP", nil)
		end
		state:SetAttribute("KingMaxHp", king.maxHp)
		state:SetAttribute("KingHp", king.hp)
		state:SetAttribute("KingPhase", 1)
		state:SetAttribute("KingTop", "")
		setPhase("BloodMoon", Config.KingSeconds)
		giantJack.Transparency = 1
		giantJack.CanCollide = false
		kingFace.Transparency = 0
		task.spawn(function()
			local started = os.clock()
			local lastTop = 0
			local nextAttack = os.clock() + 4
			local turn = 0
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
				if king.phase == 1 and fraction <= 0.66 then
					king.phase = 2
					king.shield = true
					state:SetAttribute("KingPhase", 2)
					local count = math.min(9, 3 + math.floor(players / 4))
					spawnLackeys(count)
					state:SetAttribute("KingShield", count)
					Remotes.kingDoneEvent:FireAllClients("phase2", {})
				elseif king.phase == 2 and not king.shield and fraction <= 0.33 then
					king.phase = 3
					state:SetAttribute("KingPhase", 3)
					Remotes.kingDoneEvent:FireAllClients("phase3", {})
				end
				if os.clock() >= nextAttack and os.clock() >= king.stunnedUntil then
					turn += 1
					local kind = (turn % 2 == 1) and "Slam" or "Volley"
					task.spawn(attack, token, kind)
					nextAttack = os.clock() + Config.AttackEvery[king.phase] + 2
				end
			end
			if king.active and token == phaseToken then
				king.active = false
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
	setPhase("Midnight", Config.MidnightLength)
	pcall(Hoards.refillAll)
	local wanted = math.min(
		Config.GhostMax,
		math.floor(Config.GhostBase + Config.GhostPerPatch * ownedPatchCount())
	)
	local spawned = 0
	local started = os.clock()
	while token == phaseToken and os.clock() - started < Config.MidnightLength do
		if spawned < wanted and os.clock() - started < Config.MidnightLength * 0.6 then
			if spawnGhost() then
				spawned += 1
			end
		end
		task.wait(0.8)
	end
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
local function claimDaily(player: Player)
	if not isLoaded(player) then
		return
	end
	local today = math.floor(os.time() / 86400)
	local first = dailyOf[player] == nil
	local last = dailyOf[player] or { day = 0, streak = 0 }
	if last.day >= today then
		return
	end
	local streak = if last.day == today - 1
		then math.max(0, math.floor(last.streak)) % Config.DailyMaxStreak + 1
		else 1
	dailyOf[player] = { day = today, streak = streak }
	local candy = Config.DailyCandy
		* streak
		* (streak == Config.DailyMaxStreak and Config.DailyLastMult or 1)
	addCandy(player, candy)
	local o = orders[player]
	local panel = not first and o ~= nil and o.tut > TUTORIAL_COUNT
	Remotes.dailyEvent:FireClient(player, streak, candy, false, panel and "panel" or "toast")
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
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
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
			return Players:GetNameFromUserIdAsync(userId)
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
				label.Text = string.format("%d. %s  %s", i, nameOf(userId), short(entry.value))
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
			session = { id = HttpService:GenerateGUID(false), step = 0, at = os.clock() }
			shopFunnelOf[player] = session
		end
		if not session or step <= session.step then
			return
		end
		session.step = step
		local id = session.id
		pcall(function()
			AnalyticsService:LogFunnelStepEvent(player, "Shop", id, step, SHOP_STEPS[step])
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
		if not hasPass(player, "VIP") then
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
		bb.MaxDistance = 90
		for i, text in { "⭐ VIP", player.DisplayName } do
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromScale(0, i == 1 and 0 or 0.42)
			label.Size = UDim2.fromScale(1, i == 1 and 0.42 or 0.58)
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
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
		if hasPass(player, name) then
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
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
				end)
				if ok and owns then
					grantPass(player, name)
				end
			end
		end
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local name = passById[passId]
		if purchased and name and player.Parent then
			grantPass(player, name)
			shopFunnel(player, 3)
		end
	end)

	-- Candy products pay a multiple of B (orderBase), so they stay worth it as the farm grows.
	local function productCandy(player: Player, name: string): number
		local mult = name == "CandyBig" and Config.CandyBigB or Config.CandySmallB
		return math.floor(mult * orderBase(player) + 0.5)
	end

	-- Gives the product and returns the thank-you hint. Errors on an unknown product.
	local function grantProduct(player: Player, name: string): string
		if name == "CandySmall" or name == "CandyBig" then
			local candy = candyValue(player)
			assert(candy, "no leaderstats")
			local amount = productCandy(player, name)
			-- Straight to the balance: bought candy stays off the lifetime board.
			candy.Value += amount
			return string.format("Thank you! +%s candy", short(amount))
		end
		error("unknown product " .. name)
	end

	-- Idempotent: granted PurchaseIds live in the save, and PurchaseGranted is returned only once
	-- the grant (with its PurchaseId) is saved. Anything else is retried later by Roblox.
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local name = productById[receipt.ProductId]
		local done = player and receiptsOf[player]
		if not player or not name or not done or not isLoaded(player) then
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

-- Players --------------------------------------------------------------------------------------

local function cleanupPlayer(player: Player)
	releasePatch(player)
	carrying[player] = nil
	loaded[player] = nil
	saving[player] = nil
	released[player] = nil
	indexOf[player] = nil
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
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
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
	onboard(player, 1)
	kingAddPlayer(player)
	claimDaily(player)
	checkPasses(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	-- Stolen pumpkins go home; the base is copied for the save before the patch is released.
	local _, root = aliveRoot(player)
	Bases.dropStolen(player, root and root.Position or Vector3.zero)
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
	for _, player in Players:GetPlayers() do
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
		for _, player in Players:GetPlayers() do
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
		-- Playtime (session and saved total) and the unlock gates it opens.
		for _, player in Players:GetPlayers() do
			if isLoaded(player) then
				player:SetAttribute("PlayTime", (player:GetAttribute("PlayTime") or 0) + 1)
				player:SetAttribute("SessionTime", (player:GetAttribute("SessionTime") or 0) + 1)
				local unlockedOk, unlockErr = pcall(Unlock.refresh, player)
				if not unlockedOk then
					warn("[Patch] Unlock refresh failed:", unlockErr)
				end
			end
		end
		if seconds % 5 == 0 then
			for _, player in Players:GetPlayers() do
				claimDaily(player)
			end
			for player, o in orders do
				if
					player.Parent
					and isLoaded(player)
					and o.tut > TUTORIAL_COUNT
					and os.time() >= o.refreshAt
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

-- Studio-only test hooks ------------------------------------------------------------------------

if RunService:IsStudio() then
	local debugFunction = Instance.new("BindableFunction")
	debugFunction.Name = "PatchDebug"
	debugFunction.Parent = ServerStorage
	debugFunction.OnInvoke = function(
		action: string,
		player: Player?,
		amount: number?,
		typeId: string?
	)
		if action == "midnight" then
			phaseToken += 1
			local token = phaseToken
			setPhase("Midnight", Config.MidnightLength)
			pcall(Hoards.refillAll)
			task.spawn(function()
				local wanted = math.min(
					Config.GhostMax,
					math.floor(Config.GhostBase + Config.GhostPerPatch * ownedPatchCount())
				)
				for _ = 1, wanted do
					if token ~= phaseToken then
						return
					end
					spawnGhost()
					task.wait(0.5)
				end
				task.wait(Config.MidnightLength - wanted * 0.5)
				if token == phaseToken then
					clearGhosts()
					runDay()
				end
			end)
			return #ghosts
		elseif action == "bloodmoon" then
			state:SetAttribute("JackCandy", jackGoal())
			task.spawn(startBloodMoon)
			return true
		elseif action == "candy" and player then
			addCandy(player, amount or 100)
			return true
		elseif action == "spawnwild" then
			-- Fill the zone with wild pumpkins now.
			return Wild.fill()
		elseif action == "give" and player then
			-- Put N wild pumpkins of a type (4th argument, default Orange) on the player's stack.
			return Wild.give(player, amount or 1, typeId)
		elseif action == "king" then
			-- Blood Moon without the locks-off window: the King wakes at once.
			state:SetAttribute("JackCandy", jackGoal())
			task.spawn(startBloodMoon, true)
			return true
		elseif action == "unshield" then
			-- End the new-farmer steal shield for one player (or everyone) to test stealing.
			for _, p in player and { player } or Players:GetPlayers() do
				local played = p:GetAttribute("PlayTime") or 0
				p:SetAttribute("PlayTime", math.max(played, Config.NewPlayerShield))
				Unlock.refresh(p)
			end
			return true
		elseif action == "playtime" and player then
			-- Set a player's total playtime to N seconds and recompute their unlocks from scratch
			-- (e.g. 0 = brand-new, 600 = shield over, 1800 = Witch, cauldrons, King, Lucky Swing).
			player:SetAttribute("PlayTime", math.max(0, math.floor(amount or 0)))
			Unlock.refresh(player, true)
			return player:GetAttribute("PlayTime")
		elseif action == "lock" and player then
			Bases.lock(player)
			return patchOf[player] and patchOf[player]:GetAttribute("LockedUntil")
		elseif action == "ghosts" then
			return #ghosts
		elseif action == "spooky" then
			-- Start a Spooky Hour now (the next one comes SpookyEvery seconds later).
			Spooky.start()
			return state:GetAttribute("SpookyEnds")
		end
		return nil
	end
end

task.spawn(runDay)
