--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Challenges = require(Shared:WaitForChild("Challenges"))
local Codes = require(Shared:WaitForChild("Codes"))
local Config = require(Shared:WaitForChild("Config"))
local Daily = require(Shared:WaitForChild("Daily"))
local GiftSchedule = require(Shared:WaitForChild("GiftSchedule"))
local Monetization = require(Shared:WaitForChild("Monetization"))
local Pets = require(Shared:WaitForChild("Pets"))
local Rebirth = require(Shared:WaitForChild("Rebirth"))
local ReceiptLedger = require(Shared:WaitForChild("ReceiptLedger"))
local StarterPack = require(Shared:WaitForChild("StarterPack"))
local Data = require(script.Parent.Data)
local PumpkinVisual = require(script.Parent.PumpkinVisual)

local PASS_FIELDS = {
	DoubleSize = "DoubleSize",
	AutoClick = "AutoClick",
	DoubleWins = "DoubleWins",
	ExtraPetEquip = "ExtraPetEquip",
	VIP = "VIP",
	FastTripleHatch = "FastTripleHatch",
	AutoHatch = "AutoHatch",
	DoubleLuck = "DoubleLuck",
}

local passNameById: { [number]: string } = {}
local productNameById: { [number]: string } = {}
for name, offer in Monetization.GamePasses do
	if offer.Id > 0 then
		passNameById[offer.Id] = name
	end
end
for name, offer in Monetization.DeveloperProducts do
	if offer.Id > 0 then
		productNameById[offer.Id] = name
	end
end

local EconomyService = {}
local economyState: RemoteEvent? = nil
local syncStats: ((Player, any) -> ())? = nil
local autoGrow: ((Player) -> ())? = nil
local sessionJoinedAt: { [Player]: number } = {}

local function refreshChallenges(profile: any, now: number)
	local daily = Challenges.daily(now)
	if profile.DailyChallengeId ~= daily.id then
		profile.DailyChallengeId = daily.id
		profile.DailyChallengeProgress = 0
		profile.DailyChallengeClaimed = false
	end
	local weekly = Challenges.weekly(now)
	if profile.WeeklyChallengeId ~= weekly.id then
		profile.WeeklyChallengeId = weekly.id
		profile.WeeklyChallengeProgress = 0
		profile.WeeklyChallengeClaimed = false
	end
	return daily, weekly
end

local function stateFor(player: Player, profile: any): any
	local dailyChallenge, weeklyChallenge = refreshChallenges(profile, os.time())
	local nextDaily = Daily.nextStreak(profile.DailyLastClaimDay, profile.DailyStreak, os.time())
	local joinedAt = sessionJoinedAt[player] or os.time()
	local sessionSeconds = GiftSchedule.sessionSeconds(joinedAt, os.time())
	local nextGiftIndex, nextGiftSeconds =
		GiftSchedule.nextGift(sessionSeconds, profile.PlaytimeGiftClaims)
	return {
		Rebirths = profile.Rebirths,
		RebirthCost = Rebirth.cost(profile.Rebirths),
		DailyStreak = profile.DailyStreak,
		DailyClaimable = nextDaily.claimable,
		RedeemedCodes = profile.RedeemedCodes,
		LuckyUntil = profile.LuckyUntil,
		StarterGiftClaimed = profile.StarterGiftClaimed,
		PlaytimeGiftClaims = profile.PlaytimeGiftClaims,
		SessionSeconds = sessionSeconds,
		NextGiftIndex = nextGiftIndex,
		NextGiftSeconds = nextGiftSeconds,
		GiftClaimable = #GiftSchedule.claimableIndices(
				sessionSeconds,
				profile.PlaytimeGiftClaims
			) > 0,
		StarterPackPurchased = profile.StarterPackPurchased,
		StarterPackOfferEndsAt = profile.StarterPackOfferEndsAt,
		SFXVolume = profile.SFXVolume,
		MusicVolume = profile.MusicVolume,
		ReducedEffects = profile.ReducedEffects,
		FreeDoubleWinsUntil = profile.FreeDoubleWinsUntil,
		DailyChallenge = dailyChallenge,
		DailyChallengeProgress = profile.DailyChallengeProgress,
		DailyChallengeClaimed = profile.DailyChallengeClaimed,
		WeeklyChallenge = weeklyChallenge,
		WeeklyChallengeProgress = profile.WeeklyChallengeProgress,
		WeeklyChallengeClaimed = profile.WeeklyChallengeClaimed,
	}
end

local function publish(player: Player, profile: any)
	player:SetAttribute("FreeCandyHatch", not profile.FreeCandyHatchUsed)
	player:SetAttribute("FreeSpookyHatches", profile.FreeSpookyHatches)
	player:SetAttribute("DoubleSize", profile.DoubleSize)
	player:SetAttribute("AutoClick", profile.AutoClick)
	player:SetAttribute("DoubleWins", profile.DoubleWins)
	player:SetAttribute("ExtraPetEquip", profile.ExtraPetEquip)
	player:SetAttribute("FastTripleHatch", profile.FastTripleHatch)
	player:SetAttribute("LuckyUntil", profile.LuckyUntil)
	player:SetAttribute("VIP", profile.VIP)
	player:SetAttribute("AutoHatch", profile.AutoHatch)
	player:SetAttribute("DoubleLuck", profile.DoubleLuck)
	player:SetAttribute("StarterPackOfferEndsAt", profile.StarterPackOfferEndsAt)
	player:SetAttribute("StarterPackPurchased", profile.StarterPackPurchased)
	player:SetAttribute("SFXVolume", profile.SFXVolume)
	player:SetAttribute("MusicVolume", profile.MusicVolume)
	player:SetAttribute("SFXEnabled", profile.SFXVolume > 0)
	player:SetAttribute("ReducedEffects", profile.ReducedEffects)
	player:SetAttribute("FreeDoubleWinsUntil", profile.FreeDoubleWinsUntil)
	if economyState then
		economyState:FireClient(player, stateFor(player, profile))
	end
	if syncStats then
		syncStats(player, profile)
	end
	-- Rebirth and Size Boost change Size outside the grow and roll paths
	PumpkinVisual.update(player.Character, profile.Size)
end

local function addWins(profile: any, amount: number)
	profile.Wins += amount
	profile.TotalWins += amount
end

local function grantGift(profile: any, gift: any)
	if gift.Kind == "Wins" then
		addWins(profile, gift.Amount)
	elseif gift.Kind == "Size" then
		profile.Size += gift.Amount
		profile.BiggestPumpkin = math.max(profile.BiggestPumpkin, profile.Size)
	elseif gift.Kind == "LuckyPotion" then
		profile.LuckyUntil = math.max(os.time(), profile.LuckyUntil)
			+ Config.LuckyPotionSeconds * gift.Amount
	elseif gift.Kind == "SpookyHatch" then
		profile.FreeSpookyHatches += gift.Amount
	end
end

local function grantStarterPack(profile: any): boolean
	local pet = Pets.roll("CandyEgg", function()
		return 0
	end)
	-- Paid: always grant, even past the inventory cap, or the receipt stays pending forever
	if not pet then
		addWins(profile, Config.StarterPackWins)
		profile.LuckyUntil = math.max(os.time(), profile.LuckyUntil)
			+ Config.LuckyPotionSeconds * Config.StarterPackLuckyPotions
		return true
	end
	local epic = Pets.findEgg("CandyEgg").Pets.Epic
	pet.id = HttpService:GenerateGUID(false)
	pet.name = epic.Name
	pet.rarity = "Epic"
	pet.multiplier = epic.Multiplier
	table.insert(profile.Pets, pet)
	profile.DiscoveredPets[pet.name] = true
	addWins(profile, Config.StarterPackWins)
	profile.LuckyUntil = math.max(os.time(), profile.LuckyUntil)
		+ Config.LuckyPotionSeconds * Config.StarterPackLuckyPotions
	return true
end

local function grantProduct(profile: any, productName: string): boolean
	if productName == "LuckyPotion" then
		profile.LuckyUntil = math.max(os.time(), profile.LuckyUntil) + Config.LuckyPotionSeconds
	elseif productName == "SizeBoost" then
		profile.Size += Config.SizeBoostAmount
		profile.BiggestPumpkin = math.max(profile.BiggestPumpkin, profile.Size)
	elseif productName == "WinPack" then
		addWins(profile, Config.WinPackAmount)
	elseif productName == "SkipWall" then
		profile.SkipWalls += 1
	else
		return false
	end
	return true
end

local function refreshPass(player: Player, passName: string, passId: number)
	local profile = Data.get(player)
	local field = PASS_FIELDS[passName]
	if not profile or not field or passId <= 0 then
		return
	end
	local ok, owns =
		pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
	if ok and owns then
		profile[field] = true
		Data.markDirty(player)
		publish(player, profile)
	end
end

function EconomyService.playerLoaded(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	sessionJoinedAt[player] = os.time()
	publish(player, profile)
	for passName, offer in Monetization.GamePasses do
		if offer.Id > 0 then
			task.spawn(refreshPass, player, passName, offer.Id)
		end
	end

	task.spawn(function()
		while player.Parent == Players do
			task.wait(Config.AutoClickInterval)
			local current = Data.get(player)
			if current and current.AutoClick and autoGrow then
				autoGrow(player)
			end
		end
	end)
end

function EconomyService.recordChallenge(player: Player, kind: string, amount: number?)
	local profile = Data.get(player)
	if not profile then
		return
	end
	local daily, weekly = refreshChallenges(profile, os.time())
	local changed = false
	local dailyProgress, dailyComplete =
		Challenges.advance(daily, profile.DailyChallengeProgress, kind, amount)
	if dailyProgress ~= profile.DailyChallengeProgress then
		profile.DailyChallengeProgress = dailyProgress
		changed = true
	end
	if dailyComplete and not profile.DailyChallengeClaimed then
		profile.DailyChallengeClaimed = true
		addWins(profile, daily.rewardWins)
		player:SetAttribute("LastChallengeReward", daily.rewardWins)
		changed = true
	end
	local weeklyProgress, weeklyComplete =
		Challenges.advance(weekly, profile.WeeklyChallengeProgress, kind, amount)
	if weeklyProgress ~= profile.WeeklyChallengeProgress then
		profile.WeeklyChallengeProgress = weeklyProgress
		changed = true
	end
	if weeklyComplete and not profile.WeeklyChallengeClaimed then
		profile.WeeklyChallengeClaimed = true
		addWins(profile, weekly.rewardWins)
		player:SetAttribute("LastChallengeReward", weekly.rewardWins)
		changed = true
	end
	if changed then
		Data.markDirty(player)
		publish(player, profile)
	end
end

function EconomyService.init(remotes: Folder, statsSync: (Player, any) -> (), grow: (Player) -> ())
	ReplicatedStorage:SetAttribute("UnconfiguredOfferCount", #Monetization.validationErrors())
	economyState = remotes:FindFirstChild("EconomyState") :: RemoteEvent
	syncStats = statsSync
	autoGrow = grow
	local economyRequest = remotes:FindFirstChild("EconomyRequest") :: RemoteFunction

	economyRequest.OnServerInvoke = function(player: Player, action: string, value: any): any
		local profile = Data.get(player)
		if not profile then
			return { Ok = false, Message = "Profile is still loading." }
		end

		local ok = false
		local message = "Unknown request."
		if action == "GetState" then
			return { Ok = true, State = stateFor(player, profile) }
		elseif action == "Rebirth" then
			if Rebirth.canAfford(profile.Wins, profile.Rebirths) then
				profile.Wins = 0
				profile.TotalWins = 0
				profile.Size = 0
				profile.Rebirths += 1
				ok = true
				message = "Rebirth complete! Your Size multiplier grew."
			else
				message = "You need more Wins to rebirth."
			end
		elseif action == "ClaimDaily" then
			local result =
				Daily.nextStreak(profile.DailyLastClaimDay, profile.DailyStreak, os.time())
			if result.claimable then
				profile.DailyStreak = result.streak
				profile.DailyLastClaimDay = result.day
				local reward = Config.DailyRewards[result.streak]
				addWins(profile, reward)
				ok = true
				message = string.format("Day %d claimed: +%d Wins!", result.streak, reward)
			else
				message = "Today's reward is already claimed."
			end
		elseif action == "RedeemCode" and type(value) == "string" then
			local redeemed, reward, reason =
				Codes.redeem(profile.RedeemedCodes, Config.Codes, value)
			if redeemed then
				if reward.Kind == "Wins" then
					addWins(profile, reward.Amount)
				elseif reward.Kind == "LuckyPotion" then
					profile.LuckyUntil = math.max(os.time(), profile.LuckyUntil)
						+ Config.LuckyPotionSeconds
				end
				ok = true
				message = "Code redeemed!"
			elseif reason == "USED" then
				message = "You already used that code."
			else
				message = "That code is not valid."
			end
		elseif action == "ClaimStarterGift" then
			if not profile.StarterGiftClaimed then
				profile.StarterGiftClaimed = true
				addWins(profile, Config.StarterGiftWins)
				profile.LuckyUntil = math.max(os.time(), profile.LuckyUntil)
					+ Config.StarterLuckyPotionSeconds
				ok = true
				message = "Starter gift claimed: +50 Wins and Lucky Potion!"
			else
				message = "Your starter gift is already claimed."
			end
		elseif action == "ClaimPlaytimeGift" and type(value) == "number" then
			local sessionSeconds =
				GiftSchedule.sessionSeconds(sessionJoinedAt[player] or os.time(), os.time())
			local claimed, gift =
				GiftSchedule.claim(math.floor(value), sessionSeconds, profile.PlaytimeGiftClaims)
			if claimed and gift then
				grantGift(profile, gift)
				ok = true
				message = "Playtime gift claimed!"
			else
				message = "That gift is not ready yet."
			end
		elseif action == "SetSettings" and type(value) == "table" then
			profile.SFXVolume = math.clamp(tonumber(value.SFXVolume) or profile.SFXVolume, 0, 1)
			profile.MusicVolume =
				math.clamp(tonumber(value.MusicVolume) or profile.MusicVolume, 0, 1)
			profile.ReducedEffects = value.ReducedEffects == true
			ok = true
			message = "Settings saved."
		end

		if ok then
			Data.markDirty(player)
			publish(player, profile)
		end
		return { Ok = ok, Message = message, State = stateFor(player, profile) }
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			local passName = passNameById[passId]
			local profile = Data.get(player)
			local field = PASS_FIELDS[passName or ""]
			if profile and field then
				-- Trust the purchase event; UserOwnsGamePassAsync can lag right after buying
				profile[field] = true
				Data.markDirty(player)
				publish(player, profile)
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		local productName = productNameById[receiptInfo.ProductId]
		local profile = if player then Data.get(player) else nil
		if not player or not profile or not productName then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local completed = ReceiptLedger.process(
			profile.Receipts,
			tostring(receiptInfo.PurchaseId),
			function()
				if productName == "StarterPack" then
					local processed, granted = StarterPack.purchase(
						profile.StarterPackPurchased,
						function()
							return grantStarterPack(profile)
						end
					)
					if granted then
						profile.StarterPackPurchased = true
					end
					return processed
				end
				return grantProduct(profile, productName)
			end
		)
		if not completed then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		Data.markDirty(player)
		publish(player, profile)
		player:SetAttribute("LastShopDelivery", productName)
		player:SetAttribute("LastShopDeliveryAt", os.time())
		if not Data.save(player, false) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

function EconomyService.playerRemoving(player: Player)
	sessionJoinedAt[player] = nil
end

return EconomyService
