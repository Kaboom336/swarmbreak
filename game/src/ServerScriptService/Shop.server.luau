--!strict
-- Upgrades, weapon equip, game-pass and developer-product purchases.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local PlayerData = require(ServerStorage.PlayerData)
local GameState = require(ServerStorage.GameState)
local Monetization = require(ReplicatedStorage.Shared.Monetization)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local ProfileSchema = require(ReplicatedStorage.Shared.ProfileSchema)
local Kits = require(ReplicatedStorage.Shared.Kits)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyUpgrade = Remotes.BuyUpgrade :: RemoteFunction
local BuyPerk = Remotes.BuyPerk :: RemoteFunction
local ChooseKit = Remotes.ChooseKit :: RemoteFunction
local EquipWeapon = Remotes.EquipWeapon :: RemoteEvent
local Prompt = Remotes.Prompt :: RemoteEvent
local GemCrate = Remotes.GemCrate :: RemoteFunction
local PickReward = Remotes.PickReward :: RemoteFunction
local UpdateSettings = Remotes.UpdateSettings :: RemoteEvent
local Toast = Remotes.Toast :: RemoteEvent
local Evolve = Remotes.Evolve :: RemoteFunction
local FX = Remotes.FX :: RemoteEvent
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)

UpdateSettings.OnServerEvent:Connect(function(plr, changes)
	if typeof(changes) == "table" then
		PlayerData.updateSettings(plr, changes)
	end
end)

local function canRevive(plr: Player): boolean
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		return false
	end
	return GameState.get("Phase") == "fighting"
end

BuyUpgrade.OnServerInvoke = function(plr, name)
	if typeof(name) ~= "string" then
		return false
	end
	return PlayerData.buyUpgrade(plr, name)
end

-- Lobby perks: spend Gems on the next level of a forever perk (from the shop or the run summary).
BuyPerk.OnServerInvoke = function(plr, key)
	if typeof(key) ~= "string" or not ProfileSchema.PerkDefs[key] then
		return false, "Bad request."
	end
	local ok, why = PlayerData.buyPerk(plr, key)
	if ok then
		local def = ProfileSchema.PerkDefs[key]
		local lvl = ProfileSchema.perkLevel(PlayerData.profile(plr), key)
		Toast:FireClient(plr, string.format("%s Lv %d", def.Label, lvl), 3)
	end
	return ok, why
end

-- Kits: buy with Gems on the first choice, then equip immediately.
ChooseKit.OnServerInvoke = function(plr, id)
	if typeof(id) ~= "string" or not Kits.Defs[id] then
		return false, "Bad request."
	end
	if not PlayerData.isLoaded(plr) then
		return false, "Loading..."
	end
	local ok, why = PlayerData.chooseKit(plr, id)
	if ok then
		Toast:FireClient(plr, Kits.Defs[id].Label .. " equipped", 3)
	end
	return ok, why
end

EquipWeapon.OnServerEvent:Connect(function(plr, id)
	if typeof(id) == "string" then
		PlayerData.equip(plr, id)
	end
end)

-- Weapon evolution: spend Gems + shards to take the equipped weapon one tier down an element.
Evolve.OnServerInvoke = function(plr, id, element)
	if typeof(id) ~= "string" or typeof(element) ~= "string" then
		return false, "Bad request."
	end
	if not Evolutions.Elements[element] then
		return false, "Unknown element."
	end
	local ok, why = PlayerData.evolve(plr, id, element)
	if ok then
		local evo = PlayerData.profile(plr).Evolutions[id]
		local def = Weapons.Defs[id]
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root and evo then
			FX:FireAllClients("evolve", {
				Position = (root :: BasePart).Position,
				Color = Evolutions.Elements[element].Color,
				Tier = evo.Tier,
			})
		end
		Toast:FireClient(
			plr,
			string.format(
				"%s -> %s tier %d",
				if def then def.Name else id,
				element,
				if evo then evo.Tier else 1
			),
			4
		)
	end
	return ok, why
end

-- Client asks to be shown a Roblox purchase prompt. Server decides what to prompt.
Prompt.OnServerEvent:Connect(function(plr, kind, key)
	if typeof(kind) ~= "string" or typeof(key) ~= "string" then
		return
	end
	if kind == "pass" then
		local pass = Monetization.GamePasses[key]
		if pass and pass.Id ~= 0 and not PlayerData.hasPass(plr, key) then
			MarketplaceService:PromptGamePassPurchase(plr, pass.Id)
		elseif pass and pass.Id == 0 then
			Toast:FireClient(plr, "Not for sale yet.", 2)
		end
	elseif kind == "product" then
		local prod = Monetization.DeveloperProducts[key]
		if key == "Revive" and not canRevive(plr) then
			Toast:FireClient(plr, "You can only revive while dead during a wave.", 2)
		elseif prod and prod.Id ~= 0 then
			MarketplaceService:PromptProductPurchase(plr, prod.Id)
		elseif prod then
			Toast:FireClient(plr, "Not for sale yet.", 2)
		end
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, purchased)
	if not purchased then
		return
	end
	for key, pass in Monetization.GamePasses do
		if pass.Id == passId then
			PlayerData.onPassPurchased(plr, key)
			Toast:FireClient(plr, pass.Name .. " unlocked!", 3)
		end
	end
end)

-- Gem crate: the free path to a second weapon. Costs Gems (earned in runs), never Legendary.
-- Returns ok, reason like the other Gem purchases.
GemCrate.OnServerInvoke = function(plr)
	if not PlayerData.isLoaded(plr) then
		return false, "Loading..."
	end
	local cost = Weapons.Crates.Gem.Gems or 0
	if not PlayerData.spendGems(plr, cost) then
		return false, string.format("Need %d Gems.", cost)
	end
	PlayerData.openCrate(plr, "Gem")
	return true, ""
end

-- Wave rewards: take one of the three cards offered after a wave clear. Returns ok, reason.
PickReward.OnServerInvoke = function(plr, id)
	if typeof(id) ~= "string" then
		return false, "Bad request."
	end
	return PlayerData.pickReward(plr, id)
end

MarketplaceService.ProcessReceipt = function(receipt)
	local plr = Players:GetPlayerByUserId(receipt.PlayerId)
	if not plr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local key = Monetization.productKeyForId(receipt.ProductId)
	if not key then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local prod = Monetization.DeveloperProducts[key] :: any
	if prod.Coins then
		PlayerData.addCoins(plr, prod.Coins)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif key == "WeaponCrate" then
		PlayerData.openCrate(plr, "Basic")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif key == "EpicCrate" then
		PlayerData.openCrate(plr, "Epic")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif key == "Revive" then
		-- Robux is already taken, so always grant: revive if possible, else coins instead.
		if canRevive(plr) then
			plr:LoadCharacter()
		else
			PlayerData.addCoins(plr, 200)
			Toast:FireClient(plr, "Revive not needed right now: +200 coins instead.", 3)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
