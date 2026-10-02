--!strict
-- Per-player run data (coins, kills, run upgrades) on top of the persistent Profile
-- (Gems, shards, owned weapons, evolutions, perks). Arena place only.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Monetization = require(ReplicatedStorage.Shared.Monetization)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)
local ProfileSchema = require(ReplicatedStorage.Shared.ProfileSchema)
local Goals = require(ReplicatedStorage.Shared.Goals)
local WaveRewards = require(ReplicatedStorage.Shared.WaveRewards)
local LevelUp = require(ReplicatedStorage.Shared.LevelUp)
local Daily = require(ReplicatedStorage.Shared.Daily)
local Quests = require(ReplicatedStorage.Shared.Quests)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Kits = require(ReplicatedStorage.Shared.Kits)
local Tutorial = require(ReplicatedStorage.Shared.Tutorial)
local Settings = require(ReplicatedStorage.Shared.Settings)
local Telemetry = require(ReplicatedStorage.Shared.Telemetry)
local Profile = require(script.Parent.Profile)
local WeaponModels = require(script.Parent.WeaponModels)

local StatsChanged = ReplicatedStorage:WaitForChild("Remotes").StatsChanged :: RemoteEvent
local CrateResult = ReplicatedStorage:WaitForChild("Remotes").CrateResult :: RemoteEvent
-- GetOrderedDataStore throws in an unpublished Studio place; fall back to no leaderboard.
local topStoreOk, topStoreResult = pcall(function()
	return DataStoreService:GetOrderedDataStore("SwarmBreak_top_v1")
end)
local topStore: OrderedDataStore? = if topStoreOk then topStoreResult else nil
local rng = Random.new()

export type Run = {
	Coins: number,
	Kills: number,
	ShardsEarned: number, -- shards picked up this run (for the run summary)
	Levels: { [string]: number },
	Passes: { [string]: boolean },
	Boosts: WaveRewards.Boosts, -- wave reward cards picked this run
	Offer: { string }, -- card ids on offer right now ({} when there is nothing to pick)
	OfferRarities: { [string]: string },
	XP: number,
	Level: number,
	PendingLevels: number,
	DailyPopup: Daily.Popup?, -- today's daily reward, once paid; kept for the session so no push loses it
	StartedAt: number,
	Wave: number,
	Active: boolean,
}

-- What the run summary panel shows at the end of a run (sent per player over GameOver).
export type RunSummary = {
	Won: boolean,
	Wave: number,
	Kills: number,
	Coins: number,
	GemsEarned: number,
	Gems: number, -- Gems after this run's payout
	ShardsEarned: number,
	BestWave: number,
	NewBest: boolean,
	Goal: Goals.Goal?,
}

local runs: { [Player]: Run } = {}
local waiting: { [Player]: boolean } = {}
local PlayerData = {}
PlayerData.OnEquipChanged = nil :: ((Player) -> ())?

local function sendTelemetry(plr: Player, name: string, fields: Telemetry.Fields)
	pcall(function()
		local event = Telemetry.build(name, fields)
		AnalyticsService:LogCustomEvent(plr, event.name, nil, event.fields)
	end)
end

local function push(plr: Player)
	local r = runs[plr]
	local p = Profile.get(plr)
	if r then
		StatsChanged:FireClient(plr, {
			Coins = r.Coins,
			Kills = r.Kills,
			Levels = r.Levels,
			Weapons = p.Weapons,
			Equipped = p.Equipped,
			Passes = r.Passes,
			Boosts = r.Boosts,
			Offer = r.Offer,
			OfferRarities = r.OfferRarities,
			XP = r.XP,
			Level = r.Level,
			XPNeeded = LevelUp.requiredXp(r.Level + 1),
			Gems = p.Gems,
			Shards = p.Shards,
			Evolutions = p.Evolutions,
			Perks = p.Perks,
			CratesSinceLegendary = p.CratesSinceLegendary,
			Streak = p.Streak,
			DailyPopup = r.DailyPopup,
			Quests = p.Quests,
			Kit = p.Kit,
			KitsOwned = p.KitsOwned,
			Flags = p.Flags,
			MusicVolume = p.MusicVolume,
			SfxVolume = p.SfxVolume,
			Mute = p.Mute,
			MouseLockEnabled = p.MouseLockEnabled,
		})
	end
end
PlayerData.push = push

function PlayerData.get(plr: Player): Run
	local r = runs[plr]
	if not r then
		local levels = {}
		for _, name in Config.UpgradeOrder do
			levels[name] = 0
		end
		r = {
			Coins = 0,
			Kills = 0,
			ShardsEarned = 0,
			Levels = levels,
			Passes = {},
			Boosts = WaveRewards.newBoosts(),
			Offer = {},
			OfferRarities = {},
			XP = 0,
			Level = 0,
			PendingLevels = 0,
			DailyPopup = nil,
			StartedAt = 0,
			Wave = 0,
			Active = false,
		}
		runs[plr] = r
	end
	return r
end

function PlayerData.setWaiting(plr: Player, value: boolean)
	waiting[plr] = if value then true else nil
	plr:SetAttribute("WaitingForIntermission", value)
end

function PlayerData.isWaiting(plr: Player): boolean
	return waiting[plr] == true
end

function PlayerData.setRunCoins(plr: Player, coins: number)
	PlayerData.get(plr).Coins = coins
	push(plr)
end

function PlayerData.profile(plr: Player): ProfileSchema.Profile
	return Profile.get(plr)
end

-- True once the saved profile is in (before that, Profile.get hands out a blank default).
function PlayerData.isLoaded(plr: Player): boolean
	return Profile.isLoaded(plr)
end

-- For callers that change the profile directly (flags), so the next autosave writes it.
function PlayerData.markDirty(plr: Player)
	Profile.markDirty(plr)
end

function PlayerData.updateSettings(plr: Player, changes: any)
	if not Profile.isLoaded(plr) then
		return
	end
	Settings.apply(Profile.get(plr), changes)
	Profile.markDirty(plr)
	push(plr)
end

function PlayerData.completeTutorial(plr: Player, stepId: string)
	local p = Profile.get(plr)
	local key = Tutorial.flagKey(stepId)
	if p.Flags[key] then
		return
	end
	local flags = Tutorial.complete(p.Flags, stepId)
	if flags[key] ~= true then
		return
	end
	p.Flags = flags
	Profile.markDirty(plr)
	push(plr)
end

-- ---------- coins / kills ----------
function PlayerData.addCoins(plr: Player, n: number)
	local r = PlayerData.get(plr)
	local mutationId = Mutations.forDay(Daily.dayIndex(os.time()))
	local coinAmount = Mutations.apply({ Coin = n }, mutationId).Coin
	local bonus = 1
		+ ProfileSchema.perkValue(Profile.get(plr), "CoinBonus") / 100
		+ r.Boosts.CoinMult
	r.Coins += math.floor(coinAmount * bonus + 0.5)
	push(plr)
end

local function progressQuest(plr: Player, stat: string, amount: number)
	local p = Profile.get(plr)
	p.Quests = Quests.evaluate(p.Quests, os.time(), plr.UserId)
	p.Quests = Quests.progress(p.Quests, stat, amount)
	-- Completed quests pay out at once (no claim button yet).
	for _, id in p.Quests.Ids do
		local gems
		p.Quests, gems = Quests.claim(p.Quests, id)
		p.Gems += gems
	end
	Profile.markDirty(plr)
end

function PlayerData.addKill(plr: Player, boss: boolean?, enemyType: string?)
	local r = PlayerData.get(plr)
	r.Kills += 1
	local newLevel, newXp, levelsGained =
		LevelUp.advance(r.Level, r.XP, LevelUp.xpForKill(enemyType or "Walker"))
	r.Level = newLevel
	r.XP = newXp
	r.PendingLevels += levelsGained
	local p = Profile.get(plr)
	local weapon = Weapons.Defs[p.Equipped] or Weapons.Defs.Starter
	local _, _, _, _, healOnKill = Kits.mods(p.Kit, weapon.Kind)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and healOnKill > 0 then
		hum.Health = math.min(hum.MaxHealth, hum.Health + healOnKill)
	end
	progressQuest(plr, "Kills", 1)
	if boss then
		progressQuest(plr, "BossKills", 1)
	end
	if #r.Offer == 0 and r.PendingLevels > 0 then
		PlayerData.offerLevelReward(plr)
	end
	push(plr)
end

function PlayerData.addMeleeDamage(plr: Player, amount: number)
	progressQuest(plr, "MeleeDamage", amount)
	push(plr)
end

function PlayerData.hasPass(plr: Player, key: string): boolean
	return PlayerData.get(plr).Passes[key] == true
end

-- ---------- persistent rewards ----------
function PlayerData.addGems(plr: Player, n: number)
	local p = Profile.get(plr)
	p.Gems += n
	Profile.markDirty(plr)
	push(plr)
end

function PlayerData.addShard(plr: Player, element: string, n: number)
	local p = Profile.get(plr)
	if p.Shards[element] == nil then
		return
	end
	p.Shards[element] += n
	PlayerData.get(plr).ShardsEarned += n
	Profile.markDirty(plr)
	push(plr)
end

-- Spend Gems (forever). False and nothing spent when the player has too few.
function PlayerData.spendGems(plr: Player, n: number): boolean
	local p = Profile.get(plr)
	if p.Gems < n then
		return false
	end
	p.Gems -= n
	Profile.markDirty(plr)
	push(plr)
	return true
end

-- ---------- weapons ----------
-- The equipped weapon with this run's reward boosts folded in (range, pellets/orbs, swing).
function PlayerData.equippedWeapon(plr: Player): Weapons.WeaponDef
	local p = Profile.get(plr)
	local def = Weapons.Defs[p.Equipped] or Weapons.Defs.Starter
	local weapon = WaveRewards.weaponWith(PlayerData.get(plr).Boosts, def)
	if weapon.Kind == "Orbital" then
		local _, _, _, orbsAdd = Kits.mods(p.Kit, weapon.Kind)
		weapon.Pellets += orbsAdd
	end
	return weapon
end

function PlayerData.equippedEvo(plr: Player): Evolutions.WeaponEvo?
	local p = Profile.get(plr)
	return p.Evolutions[p.Equipped]
end

function PlayerData.ownsWeapon(plr: Player, id: string): boolean
	return table.find(Profile.get(plr).Weapons, id) ~= nil
end

function PlayerData.grantWeapon(plr: Player, id: string): boolean
	if not Weapons.Defs[id] then
		return false
	end
	local p = Profile.get(plr)
	if table.find(p.Weapons, id) then
		return false -- duplicate
	end
	table.insert(p.Weapons, id)
	Profile.markDirty(plr)
	push(plr)
	return true
end

-- ---------- crates ----------
-- Open one crate (Weapons.Crates key) that is already paid for: roll a rarity (Robux crates
-- also move the pity counter), pick a weapon of that rarity, grant it, and pay Gems back for
-- a duplicate. The client hears about it over CrateResult. Shop and WaveManager both call this.
function PlayerData.openCrate(
	plr: Player,
	crateKey: string,
	revealContext: string?,
	usePity: boolean?
)
	local crate = Weapons.Crates[crateKey]
	if not crate then
		return
	end
	PlayerData.completeTutorial(plr, "Crate")
	progressQuest(plr, "Crates", 1)
	local p = Profile.get(plr)
	local rarity = Weapons.rollRarity(rng:NextNumber(), crate.Odds)
	if crate.Pity or usePity then
		rarity = Weapons.applyPity(rarity, p.CratesSinceLegendary)
		p.CratesSinceLegendary = Weapons.nextPityCount(rarity, p.CratesSinceLegendary)
		Profile.markDirty(plr)
	end
	local ids = Weapons.idsOfRarity(rarity)
	local id = ids[rng:NextInteger(1, #ids)]
	local isNew = PlayerData.grantWeapon(plr, id)
	local gemsBack = 0
	if not isNew then
		gemsBack = Weapons.DuplicateGems[rarity]
		PlayerData.addGems(plr, gemsBack)
	end
	CrateResult:FireClient(plr, id, rarity, isNew, gemsBack, crateKey, revealContext)
	sendTelemetry(plr, "CrateOpened", {
		crate = crateKey,
		rarity = rarity,
		weapon = id,
		result = if isNew then "new" else "duplicate",
	})
end

local function attachWeapon(plr: Player)
	local p = Profile.get(plr)
	if plr.Character then
		WeaponModels.attach(plr.Character, p.Equipped, p.Evolutions[p.Equipped])
	end
end

function PlayerData.equip(plr: Player, id: string): boolean
	if not PlayerData.ownsWeapon(plr, id) then
		return false
	end
	local p = Profile.get(plr)
	p.Equipped = id
	Profile.markDirty(plr)
	attachWeapon(plr)
	PlayerData.applyStats(plr)
	if PlayerData.OnEquipChanged then
		PlayerData.OnEquipChanged(plr)
	end
	push(plr)
	return true
end

-- Evolve a weapon one tier down an element. Returns ok, reason.
function PlayerData.evolve(plr: Player, id: string, element: string): (boolean, string)
	if not PlayerData.ownsWeapon(plr, id) then
		return false, "You don't own that weapon."
	end
	local p = Profile.get(plr)
	local current = p.Evolutions[id]
	local ok, why, tier = Evolutions.canBuy(current, element, p.Gems, p.Shards[element] or 0)
	if not ok or not tier then
		return false, why
	end
	p.Gems -= tier.GemsCost
	p.Shards[element] -= tier.ShardsCost
	p.Evolutions[id] = { Element = element, Tier = tier.Tier }
	Profile.markDirty(plr)
	if p.Equipped == id then
		attachWeapon(plr)
		PlayerData.applyStats(plr)
		if PlayerData.OnEquipChanged then
			PlayerData.OnEquipChanged(plr)
		end
	end
	push(plr)
	return true, ""
end

-- ---------- multipliers used by combat ----------
function PlayerData.damageMultiplier(plr: Player): number
	local r = PlayerData.get(plr)
	local p = Profile.get(plr)
	local weapon = Weapons.Defs[p.Equipped] or Weapons.Defs.Starter
	local evoDmg = Evolutions.multipliers(PlayerData.equippedEvo(plr))
	local kitDmg = Kits.mods(p.Kit, weapon.Kind)
	local base = Upgrades.valueAt("Damage", r.Levels.Damage)
		* evoDmg
		* (1 + r.Boosts.DamageMult)
		* kitDmg
	local mutationId = Mutations.forDay(Daily.dayIndex(os.time()))
	return Mutations.apply({ PlayerDamage = base }, mutationId).PlayerDamage
end

function PlayerData.fireRateMultiplier(plr: Player): number
	local r = PlayerData.get(plr)
	local _, evoRate = Evolutions.multipliers(PlayerData.equippedEvo(plr))
	return Upgrades.valueAt("FireRate", r.Levels.FireRate) * evoRate * (1 + r.Boosts.FireRateMult)
end

function PlayerData.activeEffects(plr: Player): { string }
	return Evolutions.effects(PlayerData.equippedEvo(plr))
end

function PlayerData.hasEffect(plr: Player, key: string): boolean
	return table.find(PlayerData.activeEffects(plr), key) ~= nil
end

-- ---------- character stats ----------
-- Max HP from the run's upgrades, the forever perk and this run's reward cards.
local function maxHealthFor(plr: Player): number
	local r = PlayerData.get(plr)
	local p = Profile.get(plr)
	local weapon = Weapons.Defs[p.Equipped] or Weapons.Defs.Starter
	local _, kitMaxHealth = Kits.mods(p.Kit, weapon.Kind)
	return Upgrades.valueAt("MaxHealth", r.Levels.MaxHealth)
		+ ProfileSchema.perkValue(p, "MaxHealth")
		+ r.Boosts.MaxHealth
		+ kitMaxHealth
end

local function applyStats(plr: Player)
	local r = PlayerData.get(plr)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		local p = Profile.get(plr)
		local weapon = Weapons.Defs[p.Equipped] or Weapons.Defs.Starter
		local _, _, kitSpeed = Kits.mods(p.Kit, weapon.Kind)
		local speed = Upgrades.valueAt("Speed", r.Levels.Speed) + r.Boosts.Speed + kitSpeed
		if PlayerData.hasEffect(plr, "Haste") then
			speed *= 1 + Evolutions.Effects.Haste.Value
		end
		hum.WalkSpeed = speed
		local maxHp = maxHealthFor(plr)
		local ratio = hum.Health / math.max(hum.MaxHealth, 1)
		hum.MaxHealth = maxHp
		hum.Health = math.max(hum.Health, maxHp * ratio)
	end
	local charges = if r.Passes.ExtraDash then Config.Dash.ExtraDashCharges else Config.Dash.Charges
	plr:SetAttribute("DashCharges", charges)
	-- Movement.client scales Config.Dash.Cooldown by this (the Fast Dash card)
	plr:SetAttribute("DashCooldownMult", 1 - r.Boosts.DashCooldown)
end
PlayerData.applyStats = applyStats

function PlayerData.buyUpgrade(plr: Player, name: string): boolean
	local r = PlayerData.get(plr)
	local level = r.Levels[name]
	if level == nil then
		return false
	end
	local ok, newCoins = Upgrades.tryBuy(name, level, r.Coins)
	if not ok then
		return false
	end
	r.Coins = newCoins
	r.Levels[name] = level + 1
	PlayerData.completeTutorial(plr, "Upgrade")
	if name == "MaxHealth" then
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = maxHealthFor(plr)
			hum.Health = hum.MaxHealth
		end
	else
		applyStats(plr)
	end
	push(plr)
	return true
end

-- Buy the next level of a lobby perk with Gems (forever). Returns ok, reason.
function PlayerData.buyPerk(plr: Player, key: string): (boolean, string)
	local p = Profile.get(plr)
	local ok, why = ProfileSchema.canBuyPerk(p, key)
	if not ok then
		return false, why
	end
	local cost = ProfileSchema.perkCost(p, key) or 0
	p.Gems -= cost
	p.Perks[key] = ProfileSchema.perkLevel(p, key) + 1
	Profile.markDirty(plr)
	applyStats(plr) -- a Max HP perk raises the character's max HP right away
	push(plr)
	return true, ""
end

-- Buy a permanent kit when needed, then equip it. Returns ok, reason.
function PlayerData.chooseKit(plr: Player, id: string): (boolean, string)
	local p = Profile.get(plr)
	if not Kits.Defs[id] then
		return false, "Unknown kit."
	end
	if not Kits.isUnlocked(p, id) then
		local _, ok, why = Kits.unlock(p, id)
		if not ok then
			return false, why
		end
	end
	p.Kit = id
	Profile.markDirty(plr)
	applyStats(plr)
	if PlayerData.OnEquipChanged then
		PlayerData.OnEquipChanged(plr)
	end
	push(plr)
	return true, ""
end

-- ---------- level-up rewards (pick 1 of 3 after earning enough kill XP) ----------
function PlayerData.offerLevelReward(plr: Player)
	local r = PlayerData.get(plr)
	if #r.Offer > 0 or r.PendingLevels <= 0 then
		return
	end
	local offer = LevelUp.offer(
		r.Level,
		r.Boosts.Stacks,
		PlayerData.equippedWeapon(plr).Kind,
		{ rng:NextNumber(), rng:NextNumber(), rng:NextNumber() },
		{ rng:NextNumber(), rng:NextNumber(), rng:NextNumber() }
	)
	r.Offer = {}
	r.OfferRarities = {}
	for _, card in offer do
		table.insert(r.Offer, card.Id)
		r.OfferRarities[card.Id] = card.Rarity
	end
	r.PendingLevels -= 1
	push(plr)
end

-- Take one of the offered cards. Returns ok, reason.
function PlayerData.pickReward(plr: Player, id: string): (boolean, string)
	local r = PlayerData.get(plr)
	if #r.Offer == 0 then
		return false, "No reward offered."
	end
	if not table.find(r.Offer, id) then
		return false, "Not in your offer."
	end
	local _, healNow = WaveRewards.apply(r.Boosts, id)
	r.Offer = {}
	r.OfferRarities = {}
	PlayerData.completeTutorial(plr, "Pick")
	progressQuest(plr, "WaveRewards", 1)
	applyStats(plr)
	if healNow then
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = hum.MaxHealth
		end
	end
	if WaveRewards.Defs[id].Kind == "Weapon" and PlayerData.OnEquipChanged then
		PlayerData.OnEquipChanged(plr) -- rebuilds the orbit for Extra Orb
	end
	PlayerData.offerLevelReward(plr)
	sendTelemetry(plr, "CardPicked", {
		wave = r.Wave,
		card = id,
		seconds = os.clock() - r.StartedAt,
	})
	push(plr)
	return true, ""
end

-- Intermission over: resolve every queued level so nobody loses earned picks.
function PlayerData.autoPick(plr: Player)
	local r = PlayerData.get(plr)
	while #r.Offer > 0 do
		PlayerData.pickReward(plr, r.Offer[1])
	end
end

-- New run: coins, levels and reward boosts reset; profile persists.
function PlayerData.resetRun(plr: Player)
	local r = PlayerData.get(plr)
	local p = Profile.get(plr)
	PlayerData.setWaiting(plr, false)
	r.Coins = ProfileSchema.perkValue(p, "StartCoins") + (if r.Passes.StarterPack then 300 else 0)
	r.Kills = 0
	r.ShardsEarned = 0
	for name in r.Levels do
		r.Levels[name] = 0
	end
	r.Boosts = WaveRewards.newBoosts()
	r.Offer = {}
	r.OfferRarities = {}
	r.XP = 0
	r.Level = 0
	r.PendingLevels = 0
	r.StartedAt = os.clock()
	r.Wave = 0
	r.Active = true
	applyStats(plr) -- a survivor keeps their character, so last run's stats go now
	push(plr)
end

function PlayerData.setRunWave(plr: Player, wave: number)
	PlayerData.get(plr).Wave = wave
end

-- End of run: gems, best wave, leaderboard. Returns the summary the results panel shows.
function PlayerData.endRun(plr: Player, wave: number, won: boolean): RunSummary
	local r = PlayerData.get(plr)
	local p = Profile.get(plr)
	local previousBest = p.BestWave
	-- gemsForRun before Runs counts this one; the Lucky card adds its share on top
	local gemsEarned =
		math.floor(Evolutions.gemsForRun(wave, won, p.Runs) * (1 + r.Boosts.GemMult) + 0.5)
	p.Runs += 1
	p.BestWave = math.max(p.BestWave, wave)
	p.Gems += gemsEarned
	progressQuest(plr, "Wave", wave)
	progressQuest(plr, "Runs", 1)
	for _, other in Players:GetPlayers() do
		if other ~= plr then
			local ok, isFriend = pcall(plr.IsFriendsWith, plr, other.UserId)
			if ok and isFriend then
				progressQuest(plr, "FriendRuns", 1)
				break
			end
		end
	end
	Profile.markDirty(plr)
	sendTelemetry(plr, "RunEnd", {
		result = if won then "won" else "lost",
		wave = wave,
		kills = r.Kills,
		coins = r.Coins,
		gems = gemsEarned,
		seconds = os.clock() - r.StartedAt,
	})
	r.Active = false
	local ls = plr:FindFirstChild("leaderstats")
	local best = ls and ls:FindFirstChild("Best Wave") :: IntValue?
	if best and wave > best.Value then
		best.Value = wave
	end
	task.spawn(function()
		local store = topStore
		if not store then
			return
		end
		pcall(function()
			store:UpdateAsync(tostring(plr.UserId), function(old)
				return math.max(old or 0, wave)
			end)
		end)
	end)
	push(plr)
	return {
		Won = won,
		Wave = wave,
		Kills = r.Kills,
		Coins = r.Coins,
		GemsEarned = gemsEarned,
		Gems = p.Gems,
		ShardsEarned = r.ShardsEarned,
		BestWave = p.BestWave,
		NewBest = wave > previousBest,
		Goal = Goals.next(p),
	}
end

function PlayerData.topWaves(n: number): { { Name: string, Wave: number } }
	local out = {}
	local store = topStore
	if not store then
		return out
	end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, n)
	end)
	if not ok then
		return out
	end
	for _, entry in pages:GetCurrentPage() do
		local userId = tonumber(entry.key)
		local name = "?"
		if userId then
			local okName, n2 = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			if okName then
				name = n2
			end
		end
		table.insert(out, { Name = name, Wave = entry.value })
	end
	return out
end

-- ---------- passes ----------
local function loadPasses(plr: Player)
	local r = PlayerData.get(plr)
	for key, id in Monetization.passIds() do
		if id ~= 0 then
			local ok, owns =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, id)
			r.Passes[key] = ok and owns == true
		end
	end
	if r.Passes.StarterPack then
		PlayerData.grantWeapon(plr, "Scatter")
	end
end

function PlayerData.onPassPurchased(plr: Player, key: string)
	local r = PlayerData.get(plr)
	r.Passes[key] = true
	if key == "StarterPack" then
		PlayerData.grantWeapon(plr, "Scatter")
		PlayerData.addCoins(plr, 300)
	end
	applyStats(plr)
	push(plr)
end

-- ---------- daily reward ----------
-- Pay today's login streak slot (Shared/Daily) the moment the profile is in, before the first
-- push, so the Gems already show in the HUD. The popup rides on StatsChanged for the whole
-- session (no remote of its own), so the client cannot miss it by listening late; it shows once.
local function claimDaily(plr: Player)
	local p = Profile.get(plr)
	local d = Daily.evaluate(p.LastClaimDay, p.Streak, os.time())
	if not d.Claimable then
		return
	end
	local evo = p.Evolutions[p.Equipped]
	local element: string? = if evo then evo.Element else nil
	local reward = Daily.reward(d.Slot, element)
	p.Gems += reward.Gems
	local shard = reward.Shard
	if shard and p.Shards[shard] ~= nil then
		p.Shards[shard] += 1
	end
	p.LastClaimDay = d.Today
	p.Streak = d.NewStreak
	Profile.markDirty(plr)
	PlayerData.get(plr).DailyPopup = {
		Slot = d.Slot,
		Streak = d.NewStreak,
		Text = Daily.rewardText(reward),
		NextText = Daily.rewardText(Daily.reward(Daily.nextSlot(d.Slot), element)),
	}
	if reward.Crate then
		PlayerData.openCrate(plr, reward.Crate) -- the free crate on slot 7, rolled like a bought one
	end
end

local function evaluateQuests(plr: Player)
	local p = Profile.get(plr)
	p.Quests = Quests.evaluate(p.Quests, os.time(), plr.UserId)
	Profile.markDirty(plr)
end

local function setupLeaderstats(plr: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local best = Instance.new("IntValue")
	best.Name = "Best Wave"
	best.Value = Profile.get(plr).BestWave
	best.Parent = ls
	ls.Parent = plr
end

Profile.OnLoaded = function(plr: Player)
	setupLeaderstats(plr)
	loadPasses(plr)
	claimDaily(plr)
	evaluateQuests(plr)
	applyStats(plr)
	attachWeapon(plr)
	push(plr)
end

local function onPlayerAdded(plr: Player)
	PlayerData.get(plr)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		hum.MaxHealth = maxHealthFor(plr)
		hum.Health = hum.MaxHealth
		applyStats(plr)
		attachWeapon(plr)
		push(plr)
	end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in Players:GetPlayers() do
	task.spawn(onPlayerAdded, plr)
end

Players.PlayerRemoving:Connect(function(plr)
	local r = runs[plr]
	if r and r.Active then
		sendTelemetry(plr, "QuitMidRun", {
			wave = r.Wave,
			seconds = os.clock() - r.StartedAt,
		})
	end
	runs[plr] = nil
	waiting[plr] = nil
end)

return PlayerData
