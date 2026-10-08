-- Tuning for Pumpkin Patch Panic. All values are first guesses to judge on screen.
return {
	StartCandy = 30,
	StartSeeds = { Orange = 9 },
	-- Free seeds when a player has none and cannot afford the cheapest.
	RescueSeeds = 3,
	-- Seed shop buy buttons.
	BuyAmounts = { 1, 10 },

	-- Seeds in shop order. grow = seconds to ripen, sell = base candy before size and magic.
	-- template is a KayKit pumpkin; color (if set) repaints it flat.
	Seeds = {
		{
			id = "Orange",
			name = "Orange",
			cost = 3,
			grow = 15,
			sell = 8,
			template = "pumpkin_orange",
			scale = 1.4,
		},
		{
			id = "Sunny",
			name = "Sunny",
			cost = 15,
			grow = 25,
			sell = 28,
			template = "pumpkin_yellow",
			scale = 1.8,
		},
		{
			id = "Ghost",
			name = "Ghost",
			cost = 150,
			grow = 40,
			sell = 90,
			template = "pumpkin_orange",
			scale = 2,
			color = Color3.fromRGB(232, 236, 246),
		},
		{
			id = "Moon",
			name = "Moon",
			cost = 500,
			grow = 60,
			sell = 260,
			template = "pumpkin_orange",
			scale = 2.2,
			color = Color3.fromRGB(90, 130, 255),
		},
		{
			id = "CandyCorn",
			name = "Candy Corn",
			cost = 1500,
			grow = 80,
			sell = 700,
			template = "pumpkin_orange",
			scale = 2.4,
			color = Color3.fromRGB(255, 120, 200),
		},
		{
			id = "Golden",
			name = "Golden",
			cost = 5000,
			grow = 120,
			sell = 2200,
			template = "pumpkin_orange",
			scale = 2.7,
			color = Color3.fromRGB(255, 200, 60),
		},
		{
			id = "Shadow",
			name = "Shadow",
			cost = 15000,
			grow = 150,
			sell = 9000,
			template = "pumpkin_orange",
			scale = 2.85,
			color = Color3.fromRGB(80, 30, 120),
		},
		{
			id = "Crystal",
			name = "Crystal",
			cost = 60000,
			grow = 200,
			sell = 35000,
			template = "pumpkin_orange",
			scale = 3,
			color = Color3.fromRGB(90, 235, 255),
		},
		{
			id = "Inferno",
			name = "Inferno",
			cost = 250000,
			grow = 260,
			sell = 140000,
			template = "pumpkin_orange",
			scale = 3.1,
			color = Color3.fromRGB(255, 85, 30),
		},
		{
			id = "KingSeed",
			name = "King's Seed",
			cost = 1000000,
			grow = 360,
			sell = 550000,
			template = "pumpkin_orange",
			scale = 3.2,
			color = Color3.fromRGB(255, 244, 200),
		},
	},
	-- Each pumpkin rolls a size; it multiplies the price and the look.
	SizeMin = 0.85,
	SizeMax = 1.4,

	-- Magic Cauldron: every un-brewed pumpkin you carry rolls one of these.
	Mutations = {
		{ id = "Glowing", mult = 2, chance = 0.5, color = Color3.fromRGB(255, 190, 70) },
		{ id = "Ghostly", mult = 3, chance = 0.3, color = Color3.fromRGB(170, 230, 255) },
		{ id = "Candy", mult = 5, chance = 0.15, color = Color3.fromRGB(255, 120, 210) },
		{ id = "Cursed", mult = 10, chance = 0.05, color = Color3.fromRGB(170, 60, 255) },
	},
	-- During the Blood Moon the rare ones are more likely.
	BloodMoonChances = { Glowing = 0.3, Ghostly = 0.3, Candy = 0.25, Cursed = 0.15 },

	BaseCarry = 2,

	-- Movement: faster than Roblox's 16, sprint on Shift / RUN, each carried pumpkin slows you a bit.
	WalkSpeed = 24,
	SprintSpeed = 34,
	SlowPerPumpkin = 1,
	MinCarrySpeed = 20,
	JumpPower = 55,
	SprintFov = 80,
	PadForward = 70,
	PadUp = 60,

	-- Day / midnight cycle (seconds).
	DayLength = 150,
	MidnightLength = 45,

	-- Ghosts come at midnight to steal pumpkins. Bonk them with the mallet.
	GhostBase = 3,
	GhostPerPatch = 1.5,
	GhostMax = 30,
	GhostSpeed = 7,
	GhostHp = 2,
	-- Ghosts get 1 more HP per this many owned patches.
	GhostHpPatches = 4,
	-- A bonk pays max(GhostCandy, GhostCandyShare x B) where B is the bonker's order base,
	-- capped at the value of the pumpkin the ghost went for (never below GhostCandy).
	-- Lantern lackeys have no pumpkin: their bonk is capped at LackeyCandyCap x B instead.
	GhostCandy = 3,
	GhostCandyShare = 0.15,
	LackeyCandyCap = 0.15,

	BonkRange = 11,
	BonkCooldown = 0.35,
	-- A bonk is ignored when the server-side root moved more than this many studs since a bonk
	-- less than BonkTeleportWindow seconds ago (stops teleport farming).
	BonkTeleportStuds = 60,
	BonkTeleportWindow = 0.5,
	-- Most King damage one player can deal per second.
	KingDamagePerSecond = 120, -- generous: the bonk cooldown already limits swings; this only stops scripted spam

	-- Every sale fills the Giant Jack. When full, the Blood Moon rises and the Pumpkin King wakes.
	JackGoal = 400,
	JackPerPlayer = 0.3,
	JackGrowth = 1.25,
	-- The goal is also at least this many times the server's sales in the last minute.
	JackIncomeMult = 4,
	-- Seconds from the end of one Blood Moon (or server start) before the next can rise.
	BloodMoonGap = 360,
	KingBaseHp = 40,
	KingHpPerPlayer = 100,
	-- Extra King HP per point of Mallet power (1 + Mallet level) of everyone in the server.
	KingHpPerMallet = 25,
	KingSeconds = 150,
	KingReach = 14,
	-- Attacks: a red circle warns first; standing inside when it lands knocks you away, dizzy.
	AttackEvery = { 4.5, 3.5, 2.8 },
	SlamWarn = 1.4,
	SlamRadius = 24,
	VolleyWarn = 1.6,
	KingGrace = 1.5,
	KingDizzy = 1,
	-- Phase 2: the King hides in a shield until every Lantern Lackey is bonked, then is stunned.
	LackeyHp = 3,
	StunSeconds = 6,
	KingLastHit = 25,
	FailRefill = 0.5,
	KingBase = 20,
	KingPoolShare = 0.5,
	RainCount = 40,
	RainCandy = 5,
	RainSeconds = 16,

	-- Candy upgrades: cost of level n is base * n ^ CostPower.
	CostPower = 2,
	-- A finished Pumpkin Index row (all 5 finishes of a seed) sells that seed for 10% more.
	IndexRowBonus = 0.1,
	Upgrades = {
		Stack = { title = "Bigger Stack", text = "Carry 1 more pumpkin", base = 40, max = 10 },
		Mallet = { title = "Big Mallet", text = "+1 bonk power", base = 50, max = 10 },
		Growth = { title = "Green Thumb", text = "Pumpkins grow 10% faster", base = 60, max = 8 },
	},

	-- Witch's Orders. B = base sell of the player's best owned or bought seed x OrderValueMult.
	OrderValueMult = 3.5,
	OrderRefresh = 1200,
	RotatingCount = 3,
	-- target tells the client where to point the beam: patch, cauldron, witch, seeds, upgrades, king.
	TutorialOrders = {
		{
			stat = "plant",
			need = 3,
			text = "Plant 3 seeds",
			target = "patch",
			reward = { candy = 10 },
		},
		{
			stat = "harvest",
			need = 2,
			text = "Harvest 2 pumpkins",
			target = "patch",
			reward = { seeds = { Orange = 3 } },
		},
		{
			stat = "brew",
			need = 1,
			text = "Brew at a Magic Cauldron",
			target = "cauldron",
			reward = { candy = 15 },
		},
		{
			stat = "sell",
			need = 1,
			text = "Sell to the Witch",
			target = "witch",
			reward = { candy = 20 },
		},
		{
			stat = "upgrade:Stack",
			need = 1,
			text = "Buy Bigger Stack",
			target = "upgrades",
			reward = { seeds = { Sunny = 5 } },
		},
		{
			stat = "sellSeed:Sunny",
			need = 1,
			text = "Sell a Sunny pumpkin",
			target = "witch",
			reward = { candy = 60 },
		},
		{
			stat = "bonkGhost",
			need = 3,
			text = "Bonk 3 ghosts",
			target = "patch",
			reward = { candy = 100 },
		},
		{
			stat = "kingHit",
			need = 1,
			text = "Hit the Pumpkin King",
			target = "king",
			reward = { seeds = { Ghost = 3 }, title = "Patch Keeper" },
		},
	},
	-- b = reward in multiples of B.
	RotatingOrders = {
		{ stat = "sell", need = 10, text = "Sell 10 pumpkins", target = "witch", b = 3 },
		{ stat = "harvest", need = 20, text = "Harvest 20 pumpkins", target = "patch", b = 3 },
		{
			stat = "brewRare",
			need = 1,
			text = "Brew a Candy or Cursed",
			target = "cauldron",
			b = 2,
		},
		{
			stat = "sellStackOf5",
			need = 1,
			text = "Sell a stack of 5 or more",
			target = "witch",
			b = 3,
		},
		{ stat = "bonkGhost", need = 8, text = "Bonk 8 ghosts", target = "patch", b = 2 },
		{ stat = "rescue", need = 1, text = "Rescue a stolen pumpkin", target = "patch", b = 2 },
		{ stat = "kingDamage", need = 50, text = "Deal 50 King damage", target = "king", b = 4 },
		{
			stat = "newIndex",
			need = 1,
			text = "Find a new Index entry",
			target = "cauldron",
			b = 4,
		},
		{
			stat = "sellMutation:Ghostly",
			need = 3,
			text = "Sell 3 Ghostly pumpkins",
			target = "witch",
			b = 3,
		},
		{
			stat = "sellMutation:Cursed",
			need = 1,
			text = "Sell a Cursed pumpkin",
			target = "witch",
			b = 8,
		},
	},

	-- Haunt (rebirth): cost grows x HauntGrowth per Haunt. Each Haunt adds HauntSellBonus to sell value.
	-- Haunt number n gives n Souls (1st = 1, 2nd = 2, ...).
	HauntCost = 2500000,
	HauntGrowth = 3,
	HauntSellBonus = 0.5,

	-- Soul skill tree: three branches of three tiers. Tier n needs tier n - 1 of the same branch.
	SkillBranches = { "Farmer", "Witch", "Hunter" },
	Skills = {
		{
			id = "QuickRoots",
			branch = "Farmer",
			tier = 1,
			title = "Quick Roots",
			text = "Grow 15% faster",
			cost = 1,
		},
		{
			id = "KeepStack",
			branch = "Farmer",
			tier = 2,
			title = "Keep Stack",
			text = "Keep Stack on Haunt",
			cost = 2,
		},
		{
			id = "BumperCrop",
			branch = "Farmer",
			tier = 3,
			title = "Bumper Crop",
			text = "+20% size and value",
			cost = 3,
		},
		{
			id = "CursedLuck",
			branch = "Witch",
			tier = 1,
			title = "Cursed Luck",
			text = "+3% Cursed brews",
			cost = 1,
		},
		{
			id = "AutoBrew",
			branch = "Witch",
			tier = 2,
			title = "Auto-Brew",
			text = "Brews on harvest",
			cost = 2,
		},
		{
			id = "DoubleBrew",
			branch = "Witch",
			tier = 3,
			title = "Double Brew",
			text = "Brews roll twice",
			cost = 3,
		},
		{
			id = "HeavyMallet",
			branch = "Hunter",
			tier = 1,
			title = "Heavy Mallet",
			text = "+2 bonk power",
			cost = 1,
		},
		{
			id = "GhostBounty",
			branch = "Hunter",
			tier = 2,
			title = "Ghost Bounty",
			text = "x2 ghost candy",
			cost = 2,
		},
		{
			id = "KingSlayer",
			branch = "Hunter",
			tier = 3,
			title = "King Slayer",
			text = "+50% King damage",
			cost = 3,
		},
	},
	-- Skill effect sizes.
	SkillGrowBonus = 0.15,
	SkillSizeBonus = 0.2,
	SkillCursedBonus = 0.03,
	SkillMalletBonus = 2,
	SkillGhostCandyMult = 2,
	SkillKingDamageMult = 1.5,

	-- Daily chest: streak day n gives DailySeeds x n best seeds and DailyCandy x n candy.
	-- The streak runs 1..DailyMaxStreak and then starts over at 1; the last day adds a Cursed token.
	DailySeeds = 3,
	DailyCandy = 100,
	DailyMaxStreak = 7,

	-- Monetization. Paste the real IDs from the Creator Dashboard; an ID of 0 hides that item and
	-- turns its effect off (all 0 hides the SHOP button). Prices are set in the dashboard; the
	-- Robux in the comments are suggestions.
	GamePasses = {
		-- x2 candy from every sale to the Witch. Suggested 199 R$.
		DoubleCandy = 0,
		-- +20% sell value, a "VIP" tag over your head and a gold name. Suggested 249 R$.
		VIP = 0,
		-- Carry 3 more pumpkins. Suggested 99 R$.
		BigStack = 0,
	},
	-- B = the order value unit (best seed's sell x OrderValueMult), so packs grow with the farm.
	Products = {
		-- Candy Bag: CandySmallB x B candy. Suggested 25 R$.
		CandySmall = 0,
		-- Candy Chest: CandyBigB x B candy. Suggested 129 R$.
		CandyBig = 0,
		-- Instantly ripens every growing pumpkin in your patch. Suggested 15 R$.
		InstantGrow = 0,
	},
	DoubleCandyMult = 2,
	VipSellBonus = 0.2,
	BigStackCarry = 3,
	CandySmallB = 30,
	CandyBigB = 200,

	-- Saving: a session lock older than this many seconds counts as free.
	SaveLockSeconds = 120,
	SaveEvery = 60,
	LoadTries = 4,
	-- Global board of lifetime candy (works only in a published game).
	BoardRefresh = 60,

	-- Free Creator Store audio (no scripts possible in audio assets). 0 means silent.
	MusicVolume = 0.3,
	Sounds = {
		Pick = 9113730784,
		Bonk = 9116488438,
		Brew = 99963459517796,
		Coin = 1169806635,
		Whoosh = 9120972321, -- Wood Whoosh (ProSoundEffects)
		-- Free licensed tracks (DistrokidOfficial): day, midnight, boss.
		DayMusic = 115131430600747, -- CandyMenu
		NightMusic = 140677698800750, -- Stasis Basis (loopable)
		BossMusic = 128007000574959, -- Epic Boss Battle
	},
}
