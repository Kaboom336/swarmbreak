--!strict
-- IDs come from the Creator Dashboard after Zion creates the passes and products.
-- 0 = not created yet. The server never prompts for an id of 0.
-- See ../../MONETIZATION-SETUP.md for the exact list to create.
local Monetization = {
	GamePasses = {
		DoubleCoins = { Id = 0, Name = "2x Gold" },
		ExtraDash = { Id = 0, Name = "Extra Dash" },
		QuickCrate = { Id = 0, Name = "Quick Crate", Price = 0 }, -- placeholder
		LuckyCrate = { Id = 0, Name = "Lucky Crate", Price = 0 }, -- placeholder
		VIP = { Id = 0, Name = "VIP", Price = 0 }, -- placeholder
		StarterPack = {
			Id = 0,
			Name = "Starter Pack (Shotgun + 300 Gold)",
			Price = 0, -- placeholder
		},
	},
	DeveloperProducts = {
		Coins500 = { Id = 0, Name = "500 Gold", Coins = 500 },
		Coins1500 = { Id = 0, Name = "1,500 Gold", Coins = 1500 },
		Revive = { Id = 0, Name = "Revive" },
		WeaponCrate = { Id = 0, Name = "Weapon Crate" },
		EpicCrate = { Id = 0, Name = "Epic Crate" },
		DoubleRunRewards = {
			Id = 0,
			Name = "Double Run Rewards",
			Price = 0, -- placeholder
		},
	},
}

function Monetization.passIds(): { [string]: number }
	local out = {}
	for key, p in Monetization.GamePasses do
		out[key] = p.Id
	end
	return out
end

function Monetization.productKeyForId(id: number): string?
	if id == 0 then
		return nil
	end
	for key, p in Monetization.DeveloperProducts do
		if p.Id == id then
			return key
		end
	end
	return nil
end

return Monetization
