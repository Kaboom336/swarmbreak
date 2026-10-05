--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Codes = require(Shared:WaitForChild("Codes"))
local Config = require(Shared:WaitForChild("Config"))
local Daily = require(Shared:WaitForChild("Daily"))
local Monetization = require(Shared:WaitForChild("Monetization"))
local Rebirth = require(Shared:WaitForChild("Rebirth"))
local ReceiptLedger = require(Shared:WaitForChild("ReceiptLedger"))
local Data = require(script.Parent.Data)

local PASS_FIELDS = {
	DoubleSize = "DoubleSize",
	AutoClick = "AutoClick",
	DoubleWins = "DoubleWins",
	ExtraPetEquip = "ExtraPetEquip",
	VIP = "VIP",
	FastTripleHatch = "FastTripleHatch",
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

local function stateFor(profile: any): any
	local nextDaily = Daily.nextStreak(profile.DailyLastClaimDay, profile.DailyStreak, os.time())
	return {
		Rebirths = profile.Rebirths,
		RebirthCost = Rebirth.cost(profile.Rebirths),
		DailyStreak = profile.DailyStreak,
		DailyClaimable = nextDaily.claimable,
		RedeemedCodes = profile.RedeemedCodes,
		LuckyUntil = profile.LuckyUntil,
	}
end

local function publish(player: Player, profile: any)
	player:SetAttribute("DoubleSize", profile.DoubleSize)
	player:SetAttribute("AutoClick", profile.AutoClick)
	player:SetAttribute("DoubleWins", profile.DoubleWins)
	player:SetAttribute("ExtraPetEquip", profile.ExtraPetEquip)
	player:SetAttribute("FastTripleHatch", profile.FastTripleHatch)
	player:SetAttribute("LuckyUntil", profile.LuckyUntil)
	player:SetAttribute("VIP", profile.VIP)
	if economyState then
		economyState:FireClient(player, stateFor(profile))
	end
	if syncStats then
		syncStats(player, profile)
	end
end

local function addWins(profile: any, amount: number)
	profile.Wins += amount
	profile.TotalWins += amount
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

function EconomyService.init(remotes: Folder, statsSync: (Player, any) -> (), grow: (Player) -> ())
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
			return { Ok = true, State = stateFor(profile) }
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
		end

		if ok then
			Data.markDirty(player)
			publish(player, profile)
		end
		return { Ok = ok, Message = message, State = stateFor(profile) }
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			local passName = passNameById[passId]
			if passName then
				refreshPass(player, passName, passId)
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
				return grantProduct(profile, productName)
			end
		)
		if not completed then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		Data.markDirty(player)
		publish(player, profile)
		if not Data.save(player, false) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return EconomyService
