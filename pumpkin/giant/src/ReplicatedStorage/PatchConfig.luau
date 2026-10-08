-- Tuning for Pumpkin Patch Panic. All values are first guesses to judge on screen.
return {
	StartCandy = 30,

	-- Pumpkin TYPES in rarity order (the table keeps its old name "Seeds" and the old ids so the
	-- Index and saves still work). income = candy per second when placed on a base plot (before
	-- size, brew and Haunt / pass multipliers); hp = health of a wild one in a zone.
	-- template is a KayKit pumpkin; color (if set) repaints it flat; scale = look size.
	Seeds = {
		{
			id = "Orange",
			name = "Orange",
			income = 1,
			hp = 20,
			template = "pumpkin_orange",
			scale = 1.4,
		},
		{
			id = "Sunny",
			name = "Sunny",
			income = 4,
			hp = 60,
			template = "pumpkin_yellow",
			scale = 1.8,
		},
		{
			id = "Ghost",
			name = "Ghost",
			income = 15,
			hp = 200,
			template = "pumpkin_orange",
			scale = 2,
			color = Color3.fromRGB(232, 236, 246),
		},
		{
			id = "Moon",
			name = "Moon",
			income = 60,
			hp = 700,
			template = "pumpkin_orange",
			scale = 2.2,
			color = Color3.fromRGB(90, 130, 255),
		},
		{
			id = "CandyCorn",
			name = "Candy Corn",
			income = 200,
			hp = 2500,
			template = "pumpkin_orange",
			scale = 2.4,
			color = Color3.fromRGB(255, 120, 200),
		},
		{
			id = "Golden",
			name = "Golden",
			income = 700,
			hp = 9000,
			template = "pumpkin_orange",
			scale = 2.7,
			color = Color3.fromRGB(255, 200, 60),
		},
		{
			id = "Shadow",
			name = "Shadow",
			income = 2500,
			hp = 30000,
			template = "pumpkin_orange",
			scale = 2.85,
			color = Color3.fromRGB(80, 30, 120),
		},
		{
			id = "Crystal",
			name = "Crystal",
			income = 9000,
			hp = 100000,
			template = "pumpkin_orange",
			scale = 3,
			color = Color3.fromRGB(90, 235, 255),
		},
		{
			id = "Inferno",
			name = "Inferno",
			income = 35000,
			hp = 350000,
			template = "pumpkin_orange",
			scale = 3.1,
			color = Color3.fromRGB(255, 85, 30),
		},
		{
			id = "KingSeed",
			name = "King's Seed",
			income = 140000,
			hp = 1200000,
			template = "pumpkin_orange",
			scale = 3.2,
			color = Color3.fromRGB(255, 244, 200),
		},
	},
	-- The Witch pays SellPerIncome seconds of a pumpkin's income for it.
	SellPerIncome = 30,
	-- Each pumpkin rolls a size; it multiplies income, sell value and the look.
	SizeMin = 0.85,
	SizeMax = 1.4,

	-- Zones of wild pumpkins (breakables). Each zone is a folder under workspace.Garden.Zones
	-- holding invisible Parts named "Spawn". weights = chance per pumpkin type.
	Zones = {
		Zone1 = {
			title = "Pumpkin Meadow",
			max = 45,
			weights = { Orange = 70, Sunny = 22, Ghost = 7, Moon = 1 },
		},
	},
	-- Seconds between respawns (one wild pumpkin each time, while below max).
	WildRespawn = 1.5,
	-- HP bars over wild pumpkins show within this many studs.
	WildBarDistance = 40,
	-- A popped pumpkin that does not fit on the winner's stack lies here this long.
	LooseSeconds = 30,

	-- Tools (scythes). Owning is saved; the best owned one is always the one you hold.
	-- cost = nil means it is not sold (Pumpkin King Cleaver: Blood Moon MVP drop).
	StartTool = "RustySickle",
	Tools = {
		{
			id = "RustySickle",
			name = "Rusty Sickle",
			damage = 5,
			cost = 0,
			color = Color3.fromRGB(150, 96, 70),
		},
		{
			id = "WoodenScythe",
			name = "Wooden Scythe",
			damage = 15,
			cost = 250,
			color = Color3.fromRGB(196, 150, 96),
		},
		{
			id = "BoneScythe",
			name = "Bone Scythe",
			damage = 50,
			cost = 2500,
			color = Color3.fromRGB(240, 235, 215),
		},
		{
			id = "CursedScythe",
			name = "Cursed Scythe",
			damage = 150,
			cost = 25000,
			color = Color3.fromRGB(170, 60, 255),
		},
		{
			id = "MoonScythe",
			name = "Moon Scythe",
			damage = 500,
			cost = 250000,
			color = Color3.fromRGB(110, 170, 255),
		},
		{
			id = "PumpkinKingCleaver",
			name = "Pumpkin King Cleaver",
			damage = 1500,
			color = Color3.fromRGB(255, 190, 40),
		},
	},

	-- Stealing and locks. Times are seconds.
	StealHold = 1.5,
	-- The robbed owner gets this share of the stolen pumpkin's sell value.
	StealOwnerShare = 0.25,
	-- Players newer than this (in this session) cannot be robbed.
	NewPlayerShield = 600,
	-- A victim cannot be robbed again for this long.
	VictimCooldown = 120,
	LockSeconds = 45,
	LockCooldown = 90,
	-- Blood Moon: every lock is off for this long before the Pumpkin King wakes.
	LocksOffSeconds = 120,

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

	-- Ghosts come at midnight to steal pumpkins from bases (locked bases are skipped).
	-- Ghost HP counts swings; each swing does as many hits as the tool's tier (Rusty 1, Wooden 2...).
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
	-- Most King damage one player can deal per second, in swings of their own damage.
	KingSwingsPerSecond = 4,

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
	-- Extra King HP per point of swing damage of everyone in the server.
	KingHpPerDamage = 25,
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
	-- A finished Pumpkin Index row (all 5 finishes of a type) sells that type for 10% more.
	IndexRowBonus = 0.1,
	Upgrades = {
		Stack = { title = "Bigger Stack", text = "Carry 1 more pumpkin", base = 40, max = 10 },
		Mallet = { title = "Sharp Blade", text = "+10% swing damage", base = 50, max = 10 },
		Lucky = {
			title = "Lucky Swing",
			text = "+5% chance of a rarer pumpkin",
			base = 120,
			max = 5,
		},
	},
	SharpBonus = 0.1,
	LuckyChance = 0.05,

	-- Witch's Orders. B = income of the player's best pumpkin type ever found x OrderIncomeSeconds.
	OrderIncomeSeconds = 60,
	OrderRefresh = 1200,
	RotatingCount = 3,
	-- target tells the client where to point the beam: zone (nearest wild pumpkin), patch (your
	-- base), place (your base while carrying, else the zone), steal (another base), cauldron,
	-- witch, tools (the tool stall), upgrades, king.
	TutorialOrders = {
		{
			stat = "smash",
			need = 3,
			text = "Smash 3 pumpkins",
			target = "zone",
			reward = { candy = 25 },
		},
		{
			stat = "place",
			need = 1,
			text = "Place a pumpkin on your base",
			target = "place",
			reward = { candy = 40 },
		},
		{
			stat = "brew",
			need = 1,
			text = "Brew a pumpkin at a Magic Cauldron",
			target = "cauldron",
			reward = { candy = 40 },
		},
		{
			stat = "sell",
			need = 1,
			text = "Sell a pumpkin to the Witch",
			target = "witch",
			reward = { candy = 80 },
		},
		{
			stat = "buyTool",
			need = 1,
			text = "Buy the Wooden Scythe",
			target = "tools",
			reward = { candy = 120 },
		},
		{
			stat = "bonkGhost",
			need = 3,
			text = "Bonk 3 ghosts",
			target = "patch",
			reward = { candy = 150 },
		},
		{
			stat = "lock",
			need = 1,
			text = "Lock your base once",
			target = "patch",
			reward = { candy = 150 },
		},
		{
			stat = "kingHit",
			need = 1,
			text = "Hit the Pumpkin King",
			target = "king",
			reward = { candy = 500, title = "Patch Keeper" },
		},
	},
	-- b = reward in multiples of B. reach = need is a level to reach (not a count); its need is
	-- at least ReachGrowth x the player's level when the order is dealt, and text gets it via %s.
	ReachGrowth = 1.5,
	RotatingOrders = {
		{ stat = "smash", need = 25, text = "Smash 25 pumpkins", target = "zone", b = 3 },
		{
			stat = "income",
			need = 5,
			reach = true,
			text = "Earn %s candy/s",
			target = "patch",
			b = 4,
		},
		{ stat = "steal", need = 1, text = "Steal a pumpkin", target = "steal", b = 3 },
		{ stat = "stopThief", need = 1, text = "Stop a thief", target = "patch", b = 3 },
		{
			stat = "placeType:Ghost",
			need = 1,
			text = "Place a Ghost pumpkin",
			target = "place",
			b = 4,
		},
		{ stat = "sellBrewed", need = 1, text = "Sell a brewed pumpkin", target = "witch", b = 2 },
		{ stat = "sell", need = 10, text = "Sell 10 pumpkins", target = "witch", b = 3 },
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
		{ stat = "kingHit", need = 15, text = "Hit the King 15 times", target = "king", b = 4 },
		{
			stat = "newIndex",
			need = 1,
			text = "Find a new Index entry",
			target = "cauldron",
			b = 4,
		},
		{
			stat = "sellMutation:Cursed",
			need = 1,
			text = "Sell a Cursed pumpkin",
			target = "witch",
			b = 8,
		},
	},

	-- Haunt (rebirth): cost grows x HauntGrowth per Haunt. Each Haunt adds HauntSellBonus to sell
	-- value and income. Haunt number n gives n Souls (1st = 1, 2nd = 2, ...).
	HauntCost = 2500000,
	HauntGrowth = 3,
	HauntSellBonus = 0.5,

	-- Soul skill tree: three branches of three tiers. Tier n needs tier n - 1 of the same branch.
	-- Ids are kept from older saves (QuickRoots = Fast Hands, HeavyMallet = Heavy Swing).
	SkillBranches = { "Farmer", "Witch", "Hunter" },
	Skills = {
		{
			id = "QuickRoots",
			branch = "Farmer",
			tier = 1,
			title = "Fast Hands",
			text = "+15% swing speed",
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
			text = "Brews smashed pumpkins",
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
			title = "Heavy Swing",
			text = "+50% swing damage",
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
	SkillSwingBonus = 0.15,
	SkillSizeBonus = 0.2,
	SkillCursedBonus = 0.03,
	SkillDamageMult = 1.5,
	SkillGhostCandyMult = 2,
	SkillKingDamageMult = 1.5,

	-- Daily chest: streak day n gives DailyCandy x n candy.
	-- The streak runs 1..DailyMaxStreak and then starts over at 1; the last day adds a Cursed token.
	DailyCandy = 100,
	DailyMaxStreak = 7,

	-- Monetization. Paste the real IDs from the Creator Dashboard; an ID of 0 hides that item and
	-- turns its effect off (all 0 hides the SHOP button). Prices are set in the dashboard; the
	-- Robux in the comments are suggestions.
	GamePasses = {
		-- x2 candy from every sale to the Witch and from base income. Suggested 199 R$.
		DoubleCandy = 0,
		-- +20% sell value and income, a "VIP" tag over your head and a gold name. Suggested 249 R$.
		VIP = 0,
		-- Carry 3 more pumpkins. Suggested 99 R$.
		BigStack = 0,
	},
	-- B = the order value unit (best type's income x OrderIncomeSeconds), so packs grow with the farm.
	Products = {
		-- Candy Bag: CandySmallB x B candy. Suggested 25 R$.
		CandySmall = 0,
		-- Candy Chest: CandyBigB x B candy. Suggested 129 R$.
		CandyBig = 0,
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
