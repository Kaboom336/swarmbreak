-- Pumpkin Patch Panic: every player gets a patch. Plant seeds, harvest a stack of pumpkins,
-- brew them in a Magic Cauldron for a random multiplier, sell them to the Witch for candy.
-- At midnight ghosts drift out to steal pumpkins; bonk them with the mallet. Every sale fills
-- the Giant Jack; when it is full the Blood Moon rises and everyone fights the Pumpkin King.
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

local loose = Instance.new("Folder")
loose.Name = "Loose"
loose.Parent = garden
local ghostFolder = Instance.new("Folder")
ghostFolder.Name = "Ghosts"
ghostFolder.Parent = garden

local state = Instance.new("Configuration")
state.Name = "PatchState"
state.Parent = ReplicatedStorage

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
		plantedEvent = remote("Planted"),
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
		selectEvent = remote("SelectSeed"),
		orderDoneEvent = remote("OrderDone"),
		dailyEvent = remote("Daily"),
		autoReplantEvent = remote("AutoReplant"),
		buySeedFunction = remote("BuySeed", "RemoteFunction") :: RemoteFunction,
		buyUpgradeFunction = remote("BuyUpgrade", "RemoteFunction") :: RemoteFunction,
		hauntFunction = remote("Haunt", "RemoteFunction") :: RemoteFunction,
		buySkillFunction = remote("BuySkill", "RemoteFunction") :: RemoteFunction,
		shopFunction = remote("Shop", "RemoteFunction") :: RemoteFunction,
	}
end

local seedById = {}
local cheapestCost = math.huge
for i, seed in Config.Seeds do
	seed.order = i
	seedById[seed.id] = seed
	cheapestCost = math.min(cheapestCost, seed.cost)
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

local function seedCount(player: Player, id: string): number
	return player:GetAttribute("Seed_" .. id) or 0
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

-- Bonk power: 1 + Big Mallet level, +2 with Heavy Mallet.
local function malletPower(player: Player): number
	return 1
		+ upgradeLevel(player, "Mallet")
		+ (hasSkill(player, "HeavyMallet") and Config.SkillMalletBonus or 0)
end

-- Seeds a player has bought at least once (start seeds count).
local unlocked: { [Player]: { [string]: boolean } } = {}
local function startUnlocked(): { [string]: boolean }
	local found = {}
	for id in Config.StartSeeds do
		found[id] = true
	end
	return found
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

-- Best seed owned right now or ever bought.
local function bestSeed(player: Player)
	local best = bestUnlocked(player)
	for _, seed in Config.Seeds do
		if seed.order > best.order and seedCount(player, seed.id) > 0 then
			best = seed
		end
	end
	return best
end

-- B: the value unit for order rewards and ghost bonks.
local function orderBase(player: Player): number
	return bestSeed(player).sell * Config.OrderValueMult
end

local function short(n: number): string
	if n >= 1e6 then
		return (string.gsub(string.format("%.1fM", n / 1e6), "%.0M", "M"))
	elseif n >= 1e4 then
		return (string.gsub(string.format("%.1fk", n / 1e3), "%.0k", "k"))
	end
	return tostring(math.floor(n))
end

local function rescueSeeds(player: Player)
	if not isLoaded(player) then
		return
	end
	for _, seed in Config.Seeds do
		if seedCount(player, seed.id) > 0 then
			return
		end
	end
	local candy = candyValue(player)
	if candy and candy.Value < cheapestCost then
		player:SetAttribute("Seed_Orange", Config.RescueSeeds)
		player:SetAttribute("Selected", "Orange")
		Remotes.hintEvent:FireClient(
			player,
			string.format(
				"The Witch gave you %d free Orange seeds. Plant them!",
				Config.RescueSeeds
			)
		)
	end
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
	for id, n in reward.seeds or {} do
		local seed = seedById[id]
		if seed then
			table.insert(parts, string.format("%d %s seeds", n, seed.name))
		end
	end
	if reward.title then
		table.insert(parts, string.format('the "%s" title', reward.title))
	end
	return table.concat(parts, " + ")
end

local function makeOrder(id: string, base: number?): Order?
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
	return {
		id = id,
		stat = def.stat,
		need = def.need,
		have = 0,
		text = def.text,
		target = def.target,
		reward = reward,
		done = false,
	}
end

local function nextOrders(player: Player)
	local o = orders[player]
	if o.tut <= TUTORIAL_COUNT then
		o.list = { makeOrder("T" .. o.tut) :: Order }
		return
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
		local impossible = (def.stat == "sellStackOf5" and carryCapacity(player) < 5)
			or (def.stat == "newIndex" and indexFull)
		if not impossible then
			table.insert(pool, i)
		end
	end
	local base = orderBase(player)
	o.list = {}
	for _ = 1, math.min(Config.RotatingCount, #pool) do
		local i = table.remove(pool, math.random(#pool))
		table.insert(o.list, makeOrder("R" .. i, base) :: Order)
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
	for id, n in reward.seeds or {} do
		if seedById[id] then
			player:SetAttribute("Seed_" .. id, seedCount(player, id) + n)
			player:SetAttribute("Selected", id)
		end
	end
	if reward.title then
		player:SetAttribute("Title", reward.title)
	end
end

-- Analytics: the onboarding funnel. Each step is logged once per player; steps already logged
-- are kept in the save ("onboard").
local ONBOARD_STEPS = {
	"Joined",
	"First plant",
	"First harvest",
	"First brew",
	"First sale",
	"First upgrade",
	"First King hit",
	"First Haunt",
}
local ONBOARD_STAT = { plant = 2, harvest = 3, brew = 4, sell = 5, upgrade = 6, kingHit = 7 }
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

local function track(player: Player?, stat: string, amount: number?)
	local o = player and orders[player]
	if not player or not o or not isLoaded(player) then
		return
	end
	local step = ONBOARD_STAT[stat]
	if step then
		onboard(player, step)
	end
	local n = amount or 1
	o.counters[stat] = (o.counters[stat] or 0) + n
	local changed, finished = false, false
	for _, order in o.list do
		if not order.done and order.stat == stat then
			order.have += n
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
	end
	if changed then
		publishOrders(player)
	end
end

local function loadOrders(player: Player, saved: any)
	local o: Orders = { tut = 1, list = {}, refreshAt = 0, counters = {} }
	orders[player] = o
	if type(saved) == "table" then
		if type(saved.tut) == "number" then
			o.tut = math.clamp(math.floor(saved.tut), 1, TUTORIAL_COUNT + 1)
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
		if type(saved.list) == "table" then
			for _, s in saved.list do
				local order = type(s) == "table" and type(s.id) == "string" and makeOrder(s.id)
				if order then
					order.have = tonumber(s.have) or 0
					order.done = s.done == true
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
			reward = string.sub(order.id, 1, 1) == "R" and order.reward or nil,
		})
	end
	return { tut = o.tut, refreshAt = o.refreshAt, counters = o.counters, list = list }
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
		if type(data.seeds) == "table" then
			for id in seedById do
				if type(data.seeds[id]) == "number" then
					player:SetAttribute("Seed_" .. id, data.seeds[id])
				end
			end
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
		if type(data.unlocked) == "table" then
			local found = unlocked[player] or startUnlocked()
			for _, id in data.unlocked do
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
		if type(data.autoReplant) == "boolean" then
			player:SetAttribute("AutoReplant", data.autoReplant)
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
			savedOrders = { tut = TUTORIAL_COUNT + 1 }
		end
		loadOrders(player, savedOrders)
	end

	local function snapshot(player: Player): { [string]: any }
		local candy = candyValue(player)
		assert(candy, "no leaderstats")
		local seeds, upgrades, skills = {}, {}, {}
		for id in seedById do
			seeds[id] = seedCount(player, id)
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
		local onboardList = {}
		for step in onboardOf[player] or {} do
			table.insert(onboardList, step)
		end
		local stats = player:FindFirstChild("leaderstats")
		local kings = stats and stats:FindFirstChild("Kings") :: IntValue?
		return {
			candy = candy.Value,
			kings = kings and kings.Value or 0,
			seeds = seeds,
			upgrades = upgrades,
			index = index,
			lifetime = math.floor(lifetime[player] or 0),
			unlocked = unlockedList,
			haunts = player:GetAttribute("Haunts") or 0,
			souls = player:GetAttribute("Souls") or 0,
			cursedTokens = player:GetAttribute("CursedTokens") or 0,
			skills = skills,
			title = player:GetAttribute("Title"),
			autoReplant = player:GetAttribute("AutoReplant") == true,
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

local function pumpkinValue(pumpkin: Instance): number
	local seed = seedById[pumpkin:GetAttribute("Seed")]
	local mutation = mutationById[pumpkin:GetAttribute("Mutation") or ""]
	local value = seed.sell
		* (pumpkin:GetAttribute("SizeMult") or 1)
		* (mutation and mutation.mult or 1)
	return math.max(1, math.floor(value + 0.5))
end

local brewPumpkin
do
	-- No PointLight here: 24 players x a full stack of lit pumpkins is too heavy on mobile.
	local function applyMutationLook(pumpkin: BasePart, mutationId: string)
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
			pumpkin.Transparency = 0.45
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

-- Patches -----------------------------------------------------------------------------------

local patchOf: { [Player]: Model } = {}
-- ripenNow (set while a pumpkin grows) ripens it at once; false when it is stale or already ripe.
type PlotState = {
	pumpkin: BasePart?,
	ripe: boolean,
	token: number,
	ripenNow: (() -> boolean)?,
}
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

local makePlantPrompt -- forward
local plantSeed -- forward

local function clearPlot(plot: BasePart)
	local s = plotState[plot]
	s.token += 1
	if s.pumpkin and s.pumpkin.Parent then
		s.pumpkin:Destroy()
	end
	s.pumpkin = nil
	s.ripe = false
	for _, child in plot:GetChildren() do
		if child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
	makePlantPrompt(plot)
end

-- Green Thumb (10% per level) and Quick Roots add up; never below 10% of the base time.
local function growthTime(player: Player?, seed): number
	local level = player and upgradeLevel(player, "Growth") or 0
	local faster = 0.1 * level + (hasSkill(player, "QuickRoots") and Config.SkillGrowBonus or 0)
	return seed.grow * math.max(0.1, 1 - faster)
end

local function setPumpkinScale(
	pumpkin: BasePart,
	plot: BasePart,
	full: Vector3,
	fraction: number,
	animate: boolean
)
	local size = full * fraction
	local cf = CFrame.new(plot.Position + Vector3.new(0, 0.15 + size.Y / 2, 0))
		* CFrame.Angles(0, pumpkin:GetAttribute("Yaw") or 0, 0)
	if animate then
		TweenService
			:Create(
				pumpkin,
				TweenInfo.new(0.35, Enum.EasingStyle.Back),
				{ Size = size, CFrame = cf }
			)
			:Play()
	else
		pumpkin.Size = size
		pumpkin.CFrame = cf
	end
end

local function makeHarvestPrompt(plot: BasePart, pumpkin: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Harvest"
	prompt.ObjectText = string.format("%s pumpkin", seedById[pumpkin:GetAttribute("Seed")].name)
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = plot
	return prompt
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
	local brewed = 0
	for _, p in stack do
		if p:GetAttribute("Mutation") then
			brewed += 1
		end
	end
	player:SetAttribute("CarryBrewed", brewed)
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
	if pumpkin.Size.X > 2.6 then
		pumpkin.Size *= 2.6 / pumpkin.Size.X
	end
	for _, child in pumpkin:GetChildren() do
		if child:IsA("ProximityPrompt") or child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end
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
	refreshCarry(player)
	return true
end

local function growPlot(plot: BasePart, owner: Player, seedId: string)
	local s = plotState[plot]
	s.token += 1
	local token = s.token
	local seed = seedById[seedId]
	local sizeMult = Config.SizeMin + math.random() * (Config.SizeMax - Config.SizeMin)
	if hasSkill(owner, "BumperCrop") then
		sizeMult *= 1 + Config.SkillSizeBonus
	end
	local pumpkin = makePumpkin(seedId, sizeMult)
	pumpkin:SetAttribute("Yaw", math.random() * math.pi * 2)
	local full = pumpkin.Size
	local total = growthTime(owner, seed)
	pumpkin:SetAttribute("PlantedAt", workspace:GetServerTimeNow())
	pumpkin:SetAttribute("GrowTime", total)
	pumpkin:SetAttribute("Owner", owner.UserId)
	setPumpkinScale(pumpkin, plot, full, 0.2, false)
	pumpkin.Parent = plot
	s.pumpkin = pumpkin
	s.ripe = false
	Remotes.plantedEvent:FireAllClients(owner, plot.Position)
	local ripened = false
	local function ripen()
		if ripened then
			return
		end
		ripened = true
		s.ripe = true
		pumpkin:SetAttribute("Ripe", true)
		local prompt = makeHarvestPrompt(plot, pumpkin)
		prompt.Triggered:Connect(function(player)
			if
				s.token ~= token
				or not s.ripe
				or player.UserId ~= (plot.Parent:GetAttribute("Owner") or 0)
			then
				return
			end
			-- Dead players keep the pumpkin on the plot (stackPumpkin would fail and destroy it).
			if not aliveRoot(player) then
				return
			end
			if #(carrying[player] or {}) >= carryCapacity(player) then
				Remotes.hintEvent:FireClient(
					player,
					"Your hands are full! Brew them in a cauldron or sell them to the Witch."
				)
				return
			end
			s.token += 1
			s.pumpkin = nil
			s.ripe = false
			prompt:Destroy()
			pumpkin:SetAttribute("Ripe", nil)
			pumpkin:SetAttribute("PlantedAt", nil)
			if stackPumpkin(player, pumpkin) then
				Remotes.harvestedEvent:FireAllClients(player, plot.Position)
				track(player, "harvest", 1)
				if hasSkill(player, "AutoBrew") then
					local id = brewPumpkin(player, pumpkin, false)
					refreshCarry(player)
					Remotes.brewedEvent:FireAllClients(
						player,
						plot.Position,
						{ { id = id, value = pumpkinValue(pumpkin) } }
					)
					track(player, "brew", 1)
				end
			else
				pumpkin:Destroy()
			end
			makePlantPrompt(plot)
			if player:GetAttribute("AutoReplant") then
				local id = player:GetAttribute("Selected")
				if id and seedById[id] and seedCount(player, id) > 0 then
					plantSeed(plot, player, id)
				end
			end
		end)
	end
	-- Instant Grow: skip the rest of the wait. The grow loop below sees ripened and stops.
	s.ripenNow = function(): boolean
		if s.token ~= token or ripened or pumpkin.Parent ~= plot then
			return false
		end
		setPumpkinScale(pumpkin, plot, full, 1, true)
		ripen()
		return true
	end
	task.spawn(function()
		for _, fraction in { 0.45, 0.7, 1 } do
			task.wait(total / 3)
			if s.token ~= token or ripened or not pumpkin.Parent or pumpkin.Parent ~= plot then
				return
			end
			setPumpkinScale(pumpkin, plot, full, fraction, true)
		end
		ripen()
	end)
end

function plantSeed(plot: BasePart, player: Player, id: string): boolean
	if plotState[plot].pumpkin or seedCount(player, id) <= 0 then
		return false
	end
	player:SetAttribute("Seed_" .. id, seedCount(player, id) - 1)
	for _, child in plot:GetChildren() do
		if child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
	growPlot(plot, player, id)
	track(player, "plant", 1)
	return true
end

do
	local function cheapestOwned(player: Player): string?
		local best = nil
		for _, seed in Config.Seeds do
			if seedCount(player, seed.id) > 0 and (not best or seed.cost < best.cost) then
				best = seed
			end
		end
		return best and best.id
	end

	function makePlantPrompt(plot: BasePart)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PlantPrompt"
		prompt.ActionText = "Plant"
		prompt.ObjectText = "Seed"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = plot
		prompt.Triggered:Connect(function(player)
			local patch = plot.Parent
			if player.UserId ~= (patch:GetAttribute("Owner") or 0) or plotState[plot].pumpkin then
				return
			end
			if not isLoaded(player) then
				Remotes.hintEvent:FireClient(player, "Loading your farm...")
				return
			end
			local id = player:GetAttribute("Selected")
			if not id or seedCount(player, id) <= 0 then
				id = cheapestOwned(player)
			end
			if not id then
				Remotes.hintEvent:FireClient(
					player,
					"No seeds left! Buy more at the SEEDS stall in the market."
				)
				rescueSeeds(player)
				return
			end
			plantSeed(plot, player, id)
			rescueSeeds(player)
		end)
	end
end

for _, patch in patchFolder:GetChildren() do
	for _, plot in patch:GetChildren() do
		if plot.Name == "Plot" then
			plotState[plot] = { pumpkin = nil, ripe = false, token = 0 }
			makePlantPrompt(plot)
		end
	end
end

local claimPatch
do
	local function patchCenter(patch: Model): Vector3
		local soil = patch:FindFirstChild("Soil") :: BasePart
		return soil.Position
	end

	function claimPatch(player: Player): boolean
		-- Fill fields evenly: pick the free patch in the field with the fewest owners.
		local counts = {}
		for _, patch in patchFolder:GetChildren() do
			local center = patchCenter(patch)
			local key = (center.X > 0 and "E" or "W") .. (center.Z > 0 and "S" or "N")
			counts[key] = (counts[key] or 0) + ((patch:GetAttribute("Owner") or 0) ~= 0 and 1 or 0)
		end
		local best, bestScore = nil, math.huge
		for _, patch in patchFolder:GetChildren() do
			if (patch:GetAttribute("Owner") or 0) == 0 then
				local center = patchCenter(patch)
				local key = (center.X > 0 and "E" or "W") .. (center.Z > 0 and "S" or "N")
				local score = counts[key] * 1000 + center.Magnitude
				if score < bestScore then
					best, bestScore = patch, score
				end
			end
		end
		if not best then
			return false
		end
		best:SetAttribute("Owner", player.UserId)
		patchOf[player] = best
		player:SetAttribute("PatchId", best:GetAttribute("Id"))
		setOwnerSign(best, player.DisplayName .. "'s patch", Color3.fromRGB(255, 200, 90))
		return true
	end
end

local function clearPatch(patch: Model)
	for _, plot in patch:GetChildren() do
		if plot.Name == "Plot" then
			clearPlot(plot)
		end
	end
end

local function releasePatch(player: Player)
	local patch = patchOf[player]
	patchOf[player] = nil
	if not patch then
		return
	end
	clearPatch(patch)
	patch:SetAttribute("Owner", 0)
	setOwnerSign(patch, "Free patch", Color3.fromRGB(255, 230, 200))
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
		local stack = carrying[player] or {}
		local results = {}
		for _, pumpkin in stack do
			if not pumpkin:GetAttribute("Mutation") then
				local id = brewPumpkin(player, pumpkin, true)
				table.insert(results, { id = id, value = pumpkinValue(pumpkin) })
			end
		end
		if #stack == 0 then
			Remotes.hintEvent:FireClient(
				player,
				"Harvest pumpkins from your patch first, then brew them here."
			)
			return
		elseif #results == 0 then
			Remotes.hintEvent:FireClient(
				player,
				"These are already magic! Sell them to the Witch in the market."
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
		local stack = carrying[player] or {}
		if #stack == 0 then
			Remotes.hintEvent:FireClient(
				player,
				"Bring pumpkins from your patch. Brew them first for more candy!"
			)
			return
		end
		local total, count, raw = 0, 0, 0
		local found = indexOf[player] or {}
		indexOf[player] = found
		local news = {}
		local bySeed, byMutation = {}, {}
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
		rescueSeeds(player)
	end)
end

for _, kind in { "Seeds", "Upgrades" } do
	local stall = market:WaitForChild(kind)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = kind == "Seeds" and "Buy seeds" or "Upgrades"
	prompt.ObjectText = kind == "Seeds" and "Seed stall" or "Upgrade stall"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = stall:FindFirstChild("PromptPart")
	prompt.Triggered:Connect(function(player)
		Remotes.shopEvent:FireClient(player, kind)
	end)
end

Remotes.buySeedFunction.OnServerInvoke = function(player: Player, id: unknown, amount: unknown)
	local seed = type(id) == "string" and seedById[id]
	if not seed or type(amount) ~= "number" or not table.find(Config.BuyAmounts, amount) then
		return false, "?"
	end
	if not isLoaded(player) then
		return false, "Loading"
	end
	local candy = candyValue(player)
	local cost = seed.cost * amount
	if not candy or candy.Value < cost then
		return false, "Need " .. short(cost)
	end
	candy.Value -= cost
	player:SetAttribute("Seed_" .. seed.id, seedCount(player, seed.id) + amount)
	player:SetAttribute("Selected", seed.id)
	local found = unlocked[player] or startUnlocked()
	found[seed.id] = true
	unlocked[player] = found
	return true
end

Remotes.buyUpgradeFunction.OnServerInvoke = function(player: Player, id: unknown)
	local info = type(id) == "string" and Config.Upgrades[id]
	if not info then
		return false, "?"
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

Remotes.selectEvent.OnServerEvent:Connect(function(player, id)
	if type(id) == "string" and seedById[id] then
		player:SetAttribute("Selected", id)
	end
end)

Remotes.autoReplantEvent.OnServerEvent:Connect(function(player, on)
	if type(on) == "boolean" then
		player:SetAttribute("AutoReplant", on)
	end
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
		for _, seed in Config.Seeds do
			player:SetAttribute("Seed_" .. seed.id, Config.StartSeeds[seed.id] or 0)
		end
		player:SetAttribute("Selected", "Orange")
		for id in Config.Upgrades do
			if not (id == "Stack" and hasSkill(player, "KeepStack")) then
				player:SetAttribute("Up_" .. id, 0)
			end
		end
		unlocked[player] = startUnlocked()
		for _, p in carrying[player] or {} do
			p:Destroy()
		end
		carrying[player] = {}
		local patch = patchOf[player]
		if patch then
			clearPatch(patch)
		end
		-- Haunt number n pays n Souls.
		local haunts = (player:GetAttribute("Haunts") or 0) + 1
		player:SetAttribute("Haunts", haunts)
		player:SetAttribute("Souls", (player:GetAttribute("Souls") or 0) + haunts)
		refreshCarry(player)
		-- Rotating rewards were priced from the pre-Haunt best seed; re-deal them at the new value so
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

-- Loose pumpkins (dropped by popped ghosts): anyone can pick them up. ---------------------------

local function dropLoose(pumpkin: BasePart, at: Vector3)
	for _, child in pumpkin:GetChildren() do
		if child:IsA("WeldConstraint") or child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
	pumpkin.Anchored = true
	pumpkin.CanQuery = true
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain, patchFolder, market }
	local hit = workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), params)
	local y = hit and hit.Position.Y or at.Y - 4
	pumpkin.CFrame = CFrame.new(at.X, y + pumpkin.Size.Y / 2, at.Z)
	pumpkin.Parent = loose
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = "Rescued pumpkin"
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
		-- stackPumpkin removes the prompt itself; on failure the prompt stays usable.
		if stackPumpkin(player, pumpkin) then
			Remotes.harvestedEvent:FireAllClients(player, pumpkin.Position)
			track(player, "rescue", 1)
		end
	end)
	task.delay(60, function()
		if pumpkin.Parent == loose then
			pumpkin:Destroy()
		end
	end)
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

local function buildGhost(at: Vector3, lackey: boolean?): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = "Ghost"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(4.4, 4.4, 4.4)
	body.Material = Enum.Material.SmoothPlastic
	body.Color = lackey and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(240, 244, 255)
	body.Transparency = 0.12
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CFrame = CFrame.new(at)
	body.Parent = model
	local function attach(
		name: string,
		shape: Enum.PartType,
		size: Vector3,
		offset: CFrame,
		color: Color3,
		transparency: number
	)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = shape
		p.Size = size
		p.Material = Enum.Material.SmoothPlastic
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
	attach(
		"Tail",
		Enum.PartType.Ball,
		Vector3.new(3.2, 3.6, 3.2),
		CFrame.new(0, -2, 0.3),
		Color3.fromRGB(230, 236, 255),
		0.3
	)
	attach(
		"TailTip",
		Enum.PartType.Ball,
		Vector3.new(1.8, 2.4, 1.8),
		CFrame.new(0, -3.6, 0.8),
		Color3.fromRGB(220, 230, 255),
		0.5
	)
	attach(
		"EyeL",
		Enum.PartType.Ball,
		Vector3.new(0.8, 1.1, 0.5),
		CFrame.new(-0.75, 0.5, -2),
		Color3.fromRGB(20, 16, 30),
		0
	)
	attach(
		"EyeR",
		Enum.PartType.Ball,
		Vector3.new(0.8, 1.1, 0.5),
		CFrame.new(0.75, 0.5, -2),
		Color3.fromRGB(20, 16, 30),
		0
	)
	attach(
		"Mouth",
		Enum.PartType.Ball,
		Vector3.new(0.9, 0.7, 0.4),
		CFrame.new(0, -0.6, -2),
		Color3.fromRGB(20, 16, 30),
		0
	)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		attach(
			"Skirt",
			Enum.PartType.Ball,
			Vector3.new(1.5, 1.8, 1.5),
			CFrame.new(math.cos(a) * 1.3, -3.2, math.sin(a) * 1.3 + 0.3),
			lackey and Color3.fromRGB(255, 170, 80) or Color3.fromRGB(225, 232, 255),
			0.35
		)
	end
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
	light.Color = lackey and Color3.fromRGB(255, 160, 60) or Color3.fromRGB(150, 200, 255)
	light.Range = 12
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
	model.PrimaryPart = body
	model.Parent = ghostFolder
	return model, body
end

local spawnGhost
do
	-- Ghosts go for ripe pumpkins; growing ones only when no ripe ones are left.
	local function stealTargets(): { BasePart }
		local ripe, growing = {}, {}
		for plot, s in plotState do
			if
				s.pumpkin
				and s.pumpkin.Parent == plot
				and not s.pumpkin:GetAttribute("Targeted")
			then
				table.insert(s.ripe and ripe or growing, plot)
			end
		end
		return #ripe > 0 and ripe or growing
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
			dropLoose(ghost.carried, at)
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

local clearPlotKeep -- forward

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
			if not target or not target.Parent or not s or s.pumpkin ~= target then
				-- The pumpkin was harvested first: give up and drift home.
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
				clearPlotKeep(plot)
				pumpkin.Anchored = false
				pumpkin.Massless = true
				pumpkin.CanQuery = false
				for _, child in pumpkin:GetChildren() do
					if child:IsA("ProximityPrompt") then
						child:Destroy()
					end
				end
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

-- clearPlotKeep: empty a plot without destroying the pumpkin (the ghost takes it).
function clearPlotKeep(plot: BasePart)
	local s = plotState[plot]
	s.token += 1
	s.pumpkin = nil
	s.ripe = false
	for _, child in plot:GetChildren() do
		if child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
	makePlantPrompt(plot)
end

-- The mallet -------------------------------------------------------------------------------------

do
	local function buildMallet(): Tool
		local tool = Instance.new("Tool")
		tool.Name = "Mallet"
		tool.ToolTip = "Bonk ghosts!"
		tool.CanBeDropped = false
		tool.Grip = CFrame.new(0, -1.4, 0) * CFrame.Angles(0, 0, 0)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.5, 4.2, 0.5)
		handle.Material = Enum.Material.Wood
		handle.Color = Color3.fromRGB(120, 78, 46)
		handle.CanCollide = false
		handle.Parent = tool
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Cylinder
		head.Size = Vector3.new(2.8, 1.9, 1.9)
		head.Material = Enum.Material.Wood
		head.Color = Color3.fromRGB(150, 96, 56)
		head.CanCollide = false
		head.Massless = true
		head.CFrame = handle.CFrame * CFrame.new(0, 2.2, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = head
		weld.Parent = head
		head.Parent = tool
		for _, x in { -1.45, 1.45 } do
			local band = Instance.new("Part")
			band.Name = "Band"
			band.Shape = Enum.PartType.Cylinder
			band.Size = Vector3.new(0.3, 2.05, 2.05)
			band.Material = Enum.Material.Metal
			band.Color = Color3.fromRGB(70, 66, 80)
			band.CanCollide = false
			band.Massless = true
			band.CFrame = head.CFrame * CFrame.new(x, 0, 0)
			local w = Instance.new("WeldConstraint")
			w.Part0 = head
			w.Part1 = band
			w.Parent = band
			band.Parent = tool
		end
		return tool
	end
	local malletTemplate = buildMallet()
	local old = StarterPack:FindFirstChild("Mallet")
	if old then
		old:Destroy()
	end
	malletTemplate.Parent = StarterPack
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
	return Config.KingHpPerPlayer + Config.KingHpPerMallet * malletPower(player)
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

Remotes.bonkEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now - (lastBonk[player] or 0) < Config.BonkCooldown then
		return
	end
	lastBonk[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tool = character and character:FindFirstChild("Mallet")
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
	local power = malletPower(player)
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
		best.hp -= power
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
			local dealt = power * (stunned and 2 or 1)
			if hasSkill(player, "KingSlayer") then
				dealt = math.floor(dealt * Config.SkillKingDamageMult + 0.5)
			end
			-- At most KingDamagePerSecond per player in each one-second window.
			local window = king.dps[player]
			if not window or now - window.t >= 1 then
				window = { t = now, d = 0 }
				king.dps[player] = window
			end
			dealt = math.min(dealt, Config.KingDamagePerSecond - window.d)
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
		end
	end
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
		drop.CFrame = CFrame.new(
			math.cos(a) * r,
			giantJack.Position.Y + 20 + math.random() * 20,
			math.sin(a) * r
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
				if
					root
					and (Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude < 80
					and n < 10
				then
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

	function startBloodMoon()
		if state:GetAttribute("Phase") == "BloodMoon" then
			return
		end
		phaseToken += 1
		local token = phaseToken
		clearGhosts()
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
-- 1..DailyMaxStreak and starts over, so the Cursed token comes once per cycle.
local function claimDaily(player: Player)
	if not isLoaded(player) then
		return
	end
	local today = math.floor(os.time() / 86400)
	local last = dailyOf[player] or { day = 0, streak = 0 }
	if last.day >= today then
		return
	end
	local streak = if last.day == today - 1
		then math.max(0, math.floor(last.streak)) % Config.DailyMaxStreak + 1
		else 1
	dailyOf[player] = { day = today, streak = streak }
	local seed = bestUnlocked(player)
	local seeds = Config.DailySeeds * streak
	local candy = Config.DailyCandy * streak
	player:SetAttribute("Seed_" .. seed.id, seedCount(player, seed.id) + seeds)
	addCandy(player, candy)
	local token = streak == Config.DailyMaxStreak
	if token then
		player:SetAttribute("CursedTokens", (player:GetAttribute("CursedTokens") or 0) + 1)
	end
	Remotes.dailyEvent:FireClient(player, streak, seed.name, seeds, candy, token)
end

-- Global board: lifetime candy, top 10 (needs a published game). -----------------------------

local refreshBoard
do
	local boardRows: { TextLabel } = {}
	do
		local board = market:FindFirstChild("LifetimeBoard") :: BasePart?
		if not board then
			-- Stand it at the plaza edge beside the Upgrades stall, facing the Giant Jack.
			local stall = market:FindFirstChild("Upgrades")
			local plaza = market:FindFirstChild("Plaza") :: BasePart?
			local at = stall and stall:GetPivot().Position or Vector3.new(-27, 0, 0)
			local y = plaza and plaza.Position.Y + 1 or at.Y
			local angle = math.atan2(at.Z, at.X) - math.rad(22.5)
			local r = Vector3.new(at.X, 0, at.Z).Magnitude + 9
			local pos = Vector3.new(math.cos(angle) * r, y + 6, math.sin(angle) * r)
			local p = Instance.new("Part")
			p.Name = "LifetimeBoard"
			p.Anchored = true
			p.CanCollide = false
			p.Material = Enum.Material.Wood
			p.Color = Color3.fromRGB(60, 38, 26)
			p.Size = Vector3.new(10, 10, 0.6)
			p.CFrame = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
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
		row(0, "🍬 TOP FARMERS", Color3.fromRGB(255, 214, 80), 0.14)
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
		-- Carry size and sell value both read the pass attributes.
		refreshCarry(player)
		refreshVipTag(player)
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
		elseif name == "InstantGrow" then
			local n = 0
			local patch = patchOf[player]
			for _, plot in patch and patch:GetChildren() or {} do
				local s = plotState[plot]
				if s and s.ripenNow and s.ripenNow() then
					n += 1
				end
			end
			return string.format("Thank you! %d pumpkin%s ripened", n, n == 1 and "" or "s")
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
end

local function onCharacter(player: Player, character: Model)
	carrying[player] = {}
	refreshCarry(player)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		for _, p in carrying[player] or {} do
			p:Destroy()
		end
		carrying[player] = {}
		refreshCarry(player)
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
	for id, n in Config.StartSeeds do
		player:SetAttribute("Seed_" .. id, n)
	end
	player:SetAttribute("Selected", "Orange")
	player:SetAttribute("Carry", 0)
	for id in Config.Upgrades do
		player:SetAttribute("Up_" .. id, 0)
	end
	unlocked[player] = startUnlocked()
	skillsOf[player] = {}
	publishSkills(player)

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
	player:SetAttribute("Loaded", true)
	onboard(player, 1)
	kingAddPlayer(player)
	claimDaily(player)
	rescueSeeds(player)
	checkPasses(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
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

-- Jack goal and cadence, plus rotating order refresh.
task.spawn(function()
	local seconds = 0
	while true do
		task.wait(1)
		seconds += 1
		recomputeJack()
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
	debugFunction.OnInvoke = function(action: string, player: Player?, amount: number?)
		if action == "midnight" then
			phaseToken += 1
			local token = phaseToken
			setPhase("Midnight", Config.MidnightLength)
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
		elseif action == "ripe" and player then
			-- Plant and instantly ripen every empty plot in the player's patch.
			local patch = patchOf[player]
			for _, plot in patch and patch:GetChildren() or {} do
				if plot.Name == "Plot" and not plotState[plot].pumpkin then
					local prompt = plot:FindFirstChild("PlantPrompt")
					if prompt then
						prompt:Destroy()
					end
					local saved = seedById.Orange.grow
					seedById.Orange.grow = 0.3
					growPlot(plot, player, "Orange")
					seedById.Orange.grow = saved
				end
			end
			return true
		elseif action == "ghosts" then
			return #ghosts
		end
		return nil
	end
end

task.spawn(runDay)
