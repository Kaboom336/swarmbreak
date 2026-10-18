-- Local copy of the heists Config/Rules separation; no cross-slice dependencies.
local C = {
	StartCash = 600, SpawnInterval = 3, LaneSpeed = 10, DeliverySpeed = 14,
	PlotCount = 8, PedestalCount = 10, StartUnlocked = 4,
	UnlockCosts = {100, 1500, 5000, 25000, 62500, 156250},
	LockDuration = 60, LockCooldown = 60, PvPPurchases = 3,
	StealHold = 2, InteractionDistance = 12, CarrySpeed = 10,
	WalkSpeed = 16, SpeedPerLevel = 2, UpgradeBaseCost = 100, MaxUpgrade = 10,
	OfflineCap = 3600, SaveInterval = 45, LeaseSeconds = 180,
	LaneStart = -120, LaneEnd = 120,
	Rarities = {
		{name="Common", weight=65, color={60,220,60}},
		{name="Rare", weight=23, color={11,117,240}},
		{name="Epic", weight=9, color={180,76,255}},
		{name="Legendary", weight=2.7, color={255,210,30}},
		{name="Mythic", weight=0.3, color={224,16,16}},
	},
	Mutations = {
		{name="Normal", weight=96, multiplier=1},
		{name="Gold", weight=3, multiplier=1.5, color={240,192,32}},
		{name="Diamond", weight=1, multiplier=2, color={70,225,255}},
	},
	Earners = {},
}
local names = {
	{"Copper Compass", "Dusty Doubloon", "Pearl Pouch", "Silver Chalice", "Coral Crown"},
	{"Sapphire Scarab", "Ruby Locket", "Jade Idol", "Sunken Sceptre", "Amber Astrolabe"},
	{"Amethyst Anchor", "Royal Reliquary", "Moonstone Mask", "Opal Obelisk", "Pirate Prism"},
	{"Sun Emperor Crown", "Phoenix Goblet", "Dragon Hoard", "Celestial Chest", "Golden Galleon"},
	{"Kraken Heart", "Atlantis Throne", "Eternal Pearl", "Starfall Vault", "Worldbreaker Gem"},
}
local rates = {{5,7,9,10,12}, {15,25,30,40,55}, {75,100,125,150,175},
	{200,300,450,600,900}, {1200,1800,2500,4000,6000}}
for tier, group in names do
	for i, name in group do
		local id = #C.Earners + 1
		C.Earners[id] = {id=id, name=name, rarity=tier, rate=rates[tier][i], payback=100+tier*20}
	end
end
return C
