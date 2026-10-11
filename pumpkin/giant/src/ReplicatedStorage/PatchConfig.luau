-- Tuning for Steal a Pumpkin. All values are first guesses to judge on screen.
-- Shared by several entries below (one place to change them).
local SHIELD = 900 -- new-player shield: seconds of a player's total playtime
local HAUNT_COST = 2500000
local HOARD1 = "Ghost" -- the Zone1 Hoard's pumpkin type
local Config = {
	-- Font names stay plain data so offline economy tools can load this module.
	Fonts = {
		-- Zion picked Gotham (2026-10-11): sharp heavy sans like Steal an Egg.
		title = { family = "rbxasset://fonts/families/GothamSSm.json", weight = "Heavy" },
		number = { family = "rbxasset://fonts/families/GothamSSm.json", weight = "Heavy" },
		button = { family = "rbxasset://fonts/families/GothamSSm.json", weight = "Bold" },
		small = { family = "rbxasset://fonts/families/GothamSSm.json", weight = "Bold" },
		shout = "LuckiestGuy",
		numberStyle = "Italic",
	},
	StartCandy = 0,
	UI = {
		panelSize = Vector2.new(0.44, 0.54),
		panelAspect = 1.45,
		objectiveY = 0.012,
		zoneY = 0.08,
		bossY = 0.125,
		actionY = 0.70,
		toastY = 0.765,
		fightY = 0.62,
		scaleMin = 0.75,
		scaleMax = 1.15,
		body = Color3.fromRGB(28, 20, 48),
		ink = Color3.fromRGB(26, 16, 48),
		icons = {
			Shop = "rbxasset://textures/ui/TopBar/inventoryOff.png",
			Teleport = "rbxasset://textures/ui/Settings/MenuBarIcons/HomeTab.png",
			Index = "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTab.png",
			Daily = "rbxasset://textures/ui/PlayerList/StarIcon.png",
			Admin = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
			Haunt = "rbxasset://textures/ui/PlayerList/StarIcon.png",
		},
		boosts = {
			{ attribute = "Pass_DoubleCandy", icon = "Shop", label = "x2" },
			{ attribute = "Pass_VIP", icon = "Daily", label = "VIP" },
			{ attribute = "GuardEffectUntil", icon = "Index", label = "Boost", timed = true },
		},
		headers = {
			Shop = { Color3.fromRGB(255, 179, 71), Color3.fromRGB(255, 122, 0) },
			Index = { Color3.fromRGB(181, 123, 255), Color3.fromRGB(123, 47, 247) },
			Daily = { Color3.fromRGB(141, 248, 22), Color3.fromRGB(107, 241, 3) },
			Haunt = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(192, 16, 26) },
			Admin = { Color3.fromRGB(138, 138, 138), Color3.fromRGB(100, 100, 100) },
		},
	},
	Admin = {
		userId = 405476801,
		interval = 1,
		confirmSeconds = 3,
		candy = 10000,
		maxCandy = 1000000000,
	},
	Plots = {
		domeSegments = 12,
		domeBands = 4,
		domeWidth = 6.5,
		domeTransparency = 0.55,
		domeColor = Color3.fromRGB(207, 239, 255),
		wood = Color3.fromRGB(146, 103, 74),
		rim = Color3.fromRGB(107, 74, 47),
		locked = Color3.fromRGB(140, 140, 148),
		lock = Color3.fromRGB(58, 58, 68),
		gold = Color3.fromRGB(242, 193, 46),
		priceBar = Color3.fromRGB(194, 10, 26),
		lockSize = Vector3.new(1.8, 1.6, 0.8),
		markerHeight = 22,
		wander = 3,
		minPetHeight = 3,
		maxPetHeight = 15,
		readySeconds = 1,
		growthStart = 0.65,
		growthSteps = 4,
		frontZ = 70,
	},

	-- The map (workspace.Garden): one straight lane along +Z centred on X = MapCenterX. The hub
	-- (bases, market, spawn) is Z 0..SafeLineZ; the zones follow in a line, each with ZMin / ZMax
	-- attributes on its folder (the zMin / zMax below are only the fallback). Never hard-code X.
	MapCenterX = 1500,
	SafeLineZ = 150,

	-- Unlock gates (Hit Game Bible: learn at most 5 systems in the first 10 minutes). Seconds of a
	-- player's saved total playtime (player attribute "PlayTime"); the server publishes each gate as
	-- a sticky "Unlock_<Name>" player attribute and clients show / hide by it. PlayerSteal: steal
	-- from other bases, the Lock pill / prompt, ghost raids on your base and their orders (equals
	-- the new-player shield). Sell: the Witch and Pick up on your own plots (also opens when every
	-- plot of your base is full). Brew: cauldron prompts. LuckySwing: the upgrade card. King: the
	-- Blood Moon / King banners, chip and orders (the event still runs for the server).
	-- HauntPillAt: lifetime candy that shows the Haunt pill.
	Unlocks = {
		PlayerSteal = SHIELD,
		Sell = math.huge, -- opens permanently on the first full pen
		Brew = 1800,
		LuckySwing = 1800,
		King = 1800,
		HauntPillAt = 0.5 * HAUNT_COST,
	},

	-- Pumpkin TYPES in rarity order (the table keeps its old name "Seeds" and the old ids so the
	-- Index and saves still work). income = candy per second when placed on a base plot (before
	-- size, brew and Haunt / pass multipliers); hp = health of a wild one in a zone.
	-- template is a KayKit pumpkin; color (if set) repaints it flat; scale = look size.
	-- pet = the Config.Pets entry (and ServerStorage.PetModels model) a placed one hatches into.
	Seeds = {
		{
			id = "Orange",
			pet = "PumpkinPup",
			name = "Orange",
			income = 1,
			hp = 20,
			template = "pumpkin_orange",
			scale = 1.15,
		},
		{
			id = "Sunny",
			pet = "Crow",
			name = "Sunny",
			income = 4,
			hp = 60,
			template = "pumpkin_yellow",
			scale = 1.35,
		},
		{
			id = "Ghost",
			pet = "Ghosty",
			name = "Ghost",
			income = 15,
			hp = 200,
			template = "pumpkin_orange",
			scale = 1.5,
			color = Color3.fromRGB(232, 236, 246),
		},
		{
			id = "Moon",
			pet = "BlackCat",
			name = "Moon",
			income = 60,
			hp = 700,
			template = "pumpkin_orange",
			scale = 1.65,
			color = Color3.fromRGB(90, 130, 255),
		},
		{
			id = "CandyCorn",
			pet = "CandyBat",
			name = "Candy Corn",
			income = 200,
			hp = 2500,
			template = "pumpkin_orange",
			scale = 1.8,
			color = Color3.fromRGB(255, 120, 200),
		},
		{
			id = "Golden",
			pet = "GoldenPup",
			name = "Golden",
			income = 700,
			hp = 9000,
			template = "pumpkin_orange",
			scale = 1.95,
			color = Color3.fromRGB(255, 200, 60),
		},
		{
			id = "Shadow",
			pet = "BonePup",
			name = "Shadow",
			income = 2500,
			hp = 30000,
			template = "pumpkin_orange",
			scale = 2.05,
			color = Color3.fromRGB(80, 30, 120),
		},
		{
			id = "Crystal",
			pet = "FrostOwl",
			name = "Crystal",
			income = 9000,
			hp = 100000,
			template = "pumpkin_orange",
			scale = 2.15,
			color = Color3.fromRGB(90, 235, 255),
		},
		{
			id = "Inferno",
			pet = "LavaSlime",
			name = "Inferno",
			income = 35000,
			hp = 350000,
			template = "pumpkin_orange",
			scale = 2.25,
			color = Color3.fromRGB(255, 85, 30),
		},
		{
			id = "KingSeed",
			pet = "KingCat",
			name = "King's Seed",
			income = 140000,
			hp = 1200000,
			template = "pumpkin_orange",
			scale = 2.35,
			color = Color3.fromRGB(255, 244, 200),
		},
	},
	-- Pets: a pumpkin placed on a base plot hatches into its type's pet (Seeds[n].pet) after the
	-- hatch timer. Rarity height and persisted weight set its size; missing models use living Jacks.
	-- ServerStorage.PetModels.MysteryPumpkin (optional) is the look of Hoard pumpkins.
	Pets = {
		PumpkinPup = { display = "Pumpkin Pup", rarity = "Common" },
		Crow = { display = "Crow", rarity = "Common" },
		Ghosty = { display = "Ghosty", rarity = "Rare" },
		BlackCat = { display = "Black Cat", rarity = "Rare" },
		CandyBat = { display = "Candy Bat", rarity = "Epic" },
		GoldenPup = { display = "Golden Pup", rarity = "Epic" },
		BonePup = { display = "Bone Pup", rarity = "Legendary" },
		FrostOwl = { display = "Frost Owl", rarity = "Legendary" },
		LavaSlime = { display = "Lava Slime", rarity = "Mythic" },
		KingCat = { display = "King Cat", rarity = "Mythic" },
	},
	PetHeight = 5.5,
	PetRareMult = 1.2,
	PetRareOrder = 3,
	PetSizes = {
		Common = { height = 3.5, median = 5 },
		Rare = { height = 5, median = 12 },
		Epic = { height = 7, median = 30 },
		Legendary = { height = 9, median = 75 },
		Mythic = { height = 12, median = 180 },
	},
	Farm = {
		firstSwingSeconds = 1.0, -- about 50 candy/min before travel, including golden rolls
		bigChance = 0.25,
		bigMult = 6,
		goldenOneIn = 40,
		goldenMult = 20,
		critChance = 0.1,
		critMult = 3,
		arcRange = 6,
		arcTargets = 3,
	},
	Fight = {
		seconds = 3,
		base = 0.4,
		tierBonus = 0.15,
		max = 0.9,
		tapInterval = 0.08,
		expectedTaps = 18,
		stun = 3,
		repeatWake = 0.4,
	},
	World2 = {
		text = "🌨 WORLD 2: FROST FIELDS — coming soon",
		color = Color3.fromRGB(130, 225, 255),
	},
	MysteryModel = "MysteryPumpkin",

	-- The Witch pays SellPerIncome seconds of a pumpkin's income for it.
	SellPerIncome = 30,
	FullPenSellSeconds = 300,
	WitchSellSeconds = 300, -- five minutes of income
	-- Each pumpkin rolls a size; it multiplies income, sell value and the look.
	SizeMin = 0.85,
	SizeMax = 1.4,

	-- Zones of wild pumpkins (breakables). Each zone is a folder under workspace.Garden.Zones
	-- holding invisible Parts named "Spawn" and ZMin / ZMax attributes (its stretch of the lane;
	-- zMin / zMax here are the fallback). weights = chance per pumpkin type; max = wild pumpkins
	-- alive at once; cost = candy to open its gate (0 = open from the start). emoji = the
	-- difficulty face on its gate sign (Steal an Egg ladder); color = the zone name line under
	-- the top banner on the HUD (Steal an Egg zone label colours).
	Zones = {
		Zone1 = {
			hoard = { type = HOARD1, guardian = "Scarecrow", guardHeight = 6 },
			color = Color3.fromRGB(255, 179, 71),
			title = "Pumpkin Meadow",
			emoji = "🙂",
			cost = 0,
			max = 40,
			hp = 10,
			candy = 1,
			zMin = 150,
			zMax = 310,
			weights = { Orange = 70, Sunny = 22, Ghost = 7, Moon = 1 },
		},
		Zone2 = {
			hoard = { type = "Moon", guardian = "SkeletonKnight", guardHeight = 9 },
			color = Color3.fromRGB(200, 204, 208),
			title = "Graveyard",
			emoji = "😐",
			cost = 1000,
			max = 40,
			hp = 30,
			candy = 3,
			zMin = 310,
			zMax = 470,
			weights = { Sunny = 50, Ghost = 35, Moon = 13, CandyCorn = 2 },
		},
		Zone3 = {
			hoard = { type = "Golden", guardian = "TreeEnt", guardHeight = 13 },
			color = Color3.fromRGB(155, 234, 58),
			title = "Haunted Woods",
			emoji = "😬",
			cost = 25000,
			max = 40,
			hp = 90,
			candy = 9,
			zMin = 470,
			zMax = 630,
			weights = { Ghost = 45, Moon = 35, CandyCorn = 17, Golden = 3 },
		},
		Zone4 = {
			hoard = { type = "Shadow", guardian = "SwampToad", guardHeight = 16 },
			color = Color3.fromRGB(160, 64, 224),
			title = "Witch Swamp",
			emoji = "😨",
			cost = 400000,
			max = 40,
			hp = 270,
			candy = 27,
			zMin = 630,
			zMax = 790,
			weights = { Moon = 30, CandyCorn = 40, Golden = 25, Shadow = 5 },
		},
		Zone5 = {
			hoard = {
				type = "Crystal",
				guardian = "Vampire",
				parts = "SkeletonKnight",
				guardHeight = 18,
			},
			color = Color3.fromRGB(224, 32, 32),
			title = "Vampire Castle",
			emoji = "😱",
			cost = 2500000,
			max = 40,
			hp = 810,
			candy = 80,
			zMin = 790,
			zMax = 950,
			weights = { CandyCorn = 30, Golden = 40, Shadow = 25, Crystal = 5 },
		},
		Zone6 = {
			hoard = {
				type = "Inferno",
				guardian = "CandyGolem",
				parts = "TreeEnt",
				guardHeight = 20,
			},
			color = Color3.fromRGB(255, 110, 199),
			title = "Candy Kingdom",
			emoji = "😈",
			cost = 17500000,
			max = 40,
			hp = 2400,
			candy = 240,
			zMin = 950,
			zMax = 1110,
			weights = { Golden = 30, Shadow = 40, Crystal = 25, Inferno = 5 },
		},
		Zone7 = {
			hoard = {
				type = "KingSeed",
				guardian = "PumpkinKing",
				parts = "Scarecrow",
				guardHeight = 24,
			},
			color = Color3.fromRGB(240, 208, 32),
			title = "Pumpkin King's Throne",
			emoji = "👹",
			cost = 140000000,
			max = 40,
			hp = 7300,
			candy = 720,
			zMin = 1110,
			zMax = 1270,
			weights = { Shadow = 30, Crystal = 40, Inferno = 25, KingSeed = 5 },
		},
	},
	-- Zones in unlock order (the "next zone" is the first one not unlocked yet).
	ZoneOrder = { "Zone1", "Zone2", "Zone3", "Zone4", "Zone5", "Zone6", "Zone7" },
	-- A player this many studs past a locked zone's ZMin (inside it) is sent back to the spawn.
	ZoneGuardInset = 2,
	-- Each popped wild pumpkin reserves its spot for this many seconds.
	WildRespawn = 8,
	-- HP bars over wild pumpkins show within this many studs, and only on your current target or
	-- on a pumpkin you hit in the last HitBarSeconds. Types from RareNameOrder up (3 = Ghost) also
	-- show their name over the bar.
	WildBarDistance = 40,
	HitBarSeconds = 3,
	RareNameOrder = 3,
	-- Reward reveal (white flash + card): a pumpkin type you never had, a type from RevealOrder up
	-- (3 = Ghost) or a Cursed brew. The card closes after RevealSeconds or on a click.
	RevealOrder = 3,
	RevealSeconds = 2.2,
	RevealFlash = 0.15,
	-- Rarity names by pumpkin type order: a type is the first rarity whose upTo >= its order.
	Rarities = {
		{ name = "Common", upTo = 1, color = Color3.fromRGB(200, 200, 210) },
		{ name = "Uncommon", upTo = 2, color = Color3.fromRGB(90, 220, 90) },
		{ name = "Rare", upTo = 4, color = Color3.fromRGB(60, 160, 255) },
		{ name = "Epic", upTo = 6, color = Color3.fromRGB(180, 90, 255) },
		{ name = "Legendary", upTo = 8, color = Color3.fromRGB(255, 190, 30) },
		{ name = "Mythic", upTo = 10, color = Color3.fromRGB(255, 60, 90) },
	},
	-- Legacy carried farmed pumpkins migrate at their old pop value.
	PopCandySeconds = 3,
	-- How the scythe sits in the hand (studs / degrees), in a character-aligned frame at the hand
	-- (the arm is raised forward while a tool is held): the shaft stands upright with its centre
	-- `up` studs above the hand, pushed `forward` and `right` of it, the top leaning `lean`
	-- degrees forward. The shaft is 5.4 studs, so up = 1.2 puts the blade well above the head.
	ScytheHold = { right = 0, forward = 0, lean = 6, up = 1.2 },
	-- A popped pumpkin that does not fit on the winner's stack lies here this long.
	LooseSeconds = 30,

	-- Hoards: one per zone, a straw nest of HoardCount big pumpkins of the zone's `type` guarded by a
	-- sleeping giant. Holding Steal (HoardHold s) on one wakes it: it chases the thief at
	-- GuardianShare x the thief's speed (never under GuardianMinSpeed; GuardianFirstShare for the
	-- Zone1 guardian on a player's first hoard steal ever) after GuardianWake s. It gives up after
	-- GuardianChaseSeconds, when the thief reaches their own base or leaves the zone's Z range by
	-- more than HoardLeashPad studs (or crosses the hub's safe line), then walks back and sleeps.
	-- Within GuardianCatch studs of its body: BONKED! The Hoard pumpkins fly back to the nest after
	-- HoardReturnDelay s (no candy lost). A nest refills 1 pumpkin every HoardRefill s. Hoard
	-- pumpkins roll size HoardSize and earn (and sell) x HoardMult. The nest sits on the zone's
	-- "Hoard" marker part (fallback: HoardOutward studs from the zone centre toward the +X wall).
	-- The guardian's look is ServerStorage.GuardModels.<guardian> scaled to guardHeight studs;
	-- without that model it is built from parts (kind `parts`, else `guardian`; also scaled).
	Hoards = {}, -- compatibility view filled from Zones below
	HoardCount = 3,
	HoardSize = 1.4,
	HoardMult = 3,
	HoardHold = 1.0,
	HoardRefill = 30,
	HoardReturnDelay = 3,
	HoardOutward = 20,
	HoardLeashPad = 10,
	GuardianShare = 0.9,
	GuardianFirstShare = 0.8,
	GuardianMinSpeed = 14,
	GuardianReturnSpeed = 12,
	GuardianChaseSeconds = 14,
	GuardianWake = 1.2, -- a head start: the thief should get a few steps before the chase
	GuardianCatch = 3.5,
	GuardianRoarPitch = 0.3,
	-- Hatching: a pumpkin placed on a plot hatches for CarveSeconds (types up to CarveFastOrder,
	-- i.e. Orange: CarveFastSeconds), then turns into its pet (see Pets) that idles on the
	-- pedestal; without a pet model it comes alive as a living Jack that hops within JackHop
	-- studs of its plot. It earns the whole time. (The Carve* names are kept from the Jacks.)
	CarveSeconds = 20,
	CarveFastSeconds = 8,
	CarveFastOrder = 1,
	-- During a player's first CarveNewUntil seconds of playtime every type carves in CarveNewSeconds.
	CarveNewSeconds = 8,
	CarveNewUntil = 1800,
	JackHop = 3,

	-- Tools (scythes). Owning is saved; the best owned one is always the one you hold.
	-- cost = nil means it is not sold (Pumpkin King Cleaver: Blood Moon MVP drop).
	StartTool = "RustySickle",
	Tools = {
		{
			id = "RustySickle",
			name = "Rusty Scythe",
			damage = 5,
			cost = 0,
			color = Color3.fromRGB(150, 96, 70),
		},
		{
			id = "WoodenScythe",
			name = "Iron Scythe",
			damage = 15,
			cost = 150,
			color = Color3.fromRGB(196, 150, 96),
		},
		{
			id = "BoneScythe",
			name = "Bone Scythe",
			damage = 40,
			cost = 1200,
			color = Color3.fromRGB(240, 235, 215),
		},
		{
			id = "CursedScythe",
			name = "Witch Scythe",
			damage = 110,
			cost = 9000,
			color = Color3.fromRGB(170, 60, 255),
		},
		{
			id = "MoonScythe",
			name = "Vampire Scythe",
			damage = 300,
			cost = 60000,
			color = Color3.fromRGB(110, 170, 255),
		},
		{
			id = "CandyScythe",
			name = "Candy Scythe",
			damage = 800,
			cost = 400000,
			color = Color3.fromRGB(255, 110, 199),
		},
		{
			id = "PumpkinKingCleaver",
			name = "King Scythe",
			damage = 2200,
			cost = 2500000,
			color = Color3.fromRGB(255, 190, 40),
		},
	},

	-- Stealing and locks. Times are seconds.
	StealHold = 1.0,
	Purge = {
		minutes = { 10, 50 },
		warning = 30,
		seconds = 120,
		grace = 900,
		idle = 45,
		hold = 2,
		returnSeconds = 10,
		lockSeconds = 60,
		defenceCandy = 250,
		bonkRewards = 2,
		survivorSeconds = 90,
		survivorPets = 2,
	},
	-- Legacy share kept for config compatibility; Purge thefts pay victims nothing.
	StealOwnerShare = 0.25,
	-- Players with less total playtime than this cannot be robbed (by players or midnight ghosts).
	NewPlayerShield = SHIELD,
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
	WalkSpeed = 16,
	SprintSpeed = 20,
	SlowPerPumpkin = 1,
	MinCarrySpeed = 10,
	JumpPower = 55,
	SprintFov = 80,
	PadForward = 70,
	PadUp = 60,

	-- Day / midnight cycle (seconds). Midnight keeps the bright day look (ghost raids only).
	DayLength = 150,
	MidnightLength = 45,
	-- Spooky Hour: at :25 and :45 for SpookyLength seconds the world takes an
	-- orange-purple tint, SpookyBats bats circle over the lane (client side) and base income pays
	-- x SpookyMult. Never real night.
	SpookyMinutes = { 25, 45 },
	SpookyEvery = 1800, -- Average cadence for the offline economy model; runtime uses SpookyMinutes.
	SpookyLength = 90,
	SpookyMult = 2,
	SpookyBats = 20,

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
	BonkCooldown = 0.55,
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
		Boots = {
			title = "Boots",
			text = "+2 walk speed (cap 26)",
			max = 5,
			prices = { 750, 7500, 75000, 750000, 7500000 },
		},
		Stack = { title = "Upgrade your Base!", text = "Carry +1", base = 40, max = 10 },
		-- Cut (two ways to buy damage): not sold; its saved level is kept but has no effect.
		Mallet = {
			title = "Sharp Blade",
			text = "+10% swing damage",
			base = 50,
			max = 10,
			cut = true,
		},
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
	RotatingCount = 1,
	-- target tells the client which verb to show in the top objective banner and where the red
	-- ground arrows point: zone (nearest wild pumpkin), patch (your base), place (your base while
	-- carrying, else the zone), steal (another base), cauldron, witch, tools (the tool stall),
	-- upgrades (the upgrade stall), king, gate (the next locked zone's gate), hoard (the Zone1 Hoard
	-- nest). Saved progress counts steps (orders save version 3; older saves are mapped onto these
	-- 5 steps by the server). After the tutorial: the Graveyard gate, then one rotating order at a
	-- time, only from unlocked systems.
	TutorialOrders = {
		{
			stat = "farmCandy",
			need = 30,
			text = "Smash pumpkins!",
			target = "zone",
			reward = { candy = 20 },
		},
		{
			stat = "buyTool",
			need = 1,
			text = "Buy the Iron Scythe!",
			target = "tools",
			reward = {},
		},
		{
			stat = "hoardSteal",
			need = 1,
			text = "Steal a glowing pumpkin!",
			target = "hoard",
			reward = {},
		},
		{ stat = "hatch", need = 1, text = "Place it in your pen!", target = "place", reward = {} },
		{
			stat = "penFilled",
			need = 2,
			reach = true,
			text = "Fill your pen %s",
			target = "hoard",
			reward = { title = "Patch Keeper" },
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
		-- Kept last so saved order ids (R1, R2...) stay the same. Only dealt while the player
		-- still has a locked zone.
		{ stat = "unlockZone", need = 1, text = "Unlock the next zone", target = "gate", b = 3 },
	},

	-- Haunt (rebirth): cost grows x HauntGrowth per Haunt. Each Haunt adds HauntSellBonus to sell
	-- value and income. Haunt number n gives n Souls (1st = 1, 2nd = 2, ...).
	HauntCost = HAUNT_COST,
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

	-- Daily chest: streak day n gives DailyCandy x n candy (the last day x DailyLastMult instead of
	-- the old Cursed token). The streak runs 1..DailyMaxStreak and then starts over at 1. The very
	-- first visit grants day 1 with a toast (no popup); later days open the panel only after the
	-- tutorial.
	DailyCandy = 100,
	DailyMaxStreak = 7,
	DailyLastMult = 2,

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
		-- Guardian wake roar: the Bonk sound played at GuardianRoarPitch until a real roar is picked.
		Roar = 9116488438,
		-- Free licensed tracks (DistrokidOfficial): day, midnight, boss.
		DayMusic = 115131430600747, -- CandyMenu
		NightMusic = 140677698800750, -- Stasis Basis (loopable)
		BossMusic = 128007000574959, -- Epic Boss Battle
	},
}

Config.RemovedOrders =
	{ sellBrewed = true, sell = true, brewRare = true, sellStackOf5 = true, sellMutation = true }

-- R21 tuning. The offline sim models equal pet rolls, a successful steal every 90s,
-- matching scythes, 50% farming uptime, quest discounts, swaps/sales, stamps and Spooky Hour.
Config.Progression = {
	stampBonus = 0.1,
	roundEpsilon = 1e-8,
	questSmashes = 50,
	questSteals = 1,
	gateDiscount = 0.25,
	baseSlots = 6,
	woodsSlots = 8,
	castleSlots = 10,
	fuseCount = 3,
	fuseWeight = 1.5,
	shinyChance = 0.1,
	shinyIncome = 1.25,
	witchRestock = 300,
	witchOffers = 3,
	witchPriceSeconds = 300,
	witchPriceMult = 1.5,
	goldOneIn = 12,
	goldIncome = 2,
	rebirthCost = 5000000,
	rebirthBonus = 0.25,
	rebirthCap = 10,
	activity = 0.5,
	arrivalMinutes = { 0, 5, 15, 30, 50, 80, 120 },
	promptRange = 14,
	slotSpacing = 8,
	slotRows = 2,
	slotMargin = 3,
}
Config.Raid = {
	grace = 900,
	warning = 30,
	homeRadius = 60,
	idle = 45,
	petAge = 300,
	cooldown = 1200,
	taps = 5,
	hover = 8,
	tapInterval = 0.15,
}
Config.KingNight = {
	height = 28,
	walkSpeed = 10,
	padPause = 3,
	ring = Vector2.new(80, 50),
	windup = 1.2,
	signOffset = Vector3.new(28, 8, 0),
	look = {
		tint = Color3.fromRGB(255, 201, 184),
		brightness = 0,
		saturation = 0.08,
		contrast = 0.02,
		ambient = Color3.fromRGB(130, 130, 170),
		outdoor = Color3.fromRGB(155, 160, 195),
		clock = 17,
		sky = Color3.fromRGB(175, 185, 230),
		decay = Color3.fromRGB(100, 90, 155),
		density = 0.25,
	},
	minutes = { 0, 20, 40 },
	warning = 60,
	hits = 15,
	damageShare = 0.03,
	farmSeconds = 480,
	pity = 10,
	finisherBonus = 0.05,
	consolation = 0.25,
	rarityWeights = { 55, 33, 10, 2 },
	rewardSeeds = { "Ghost", "CandyCorn", "Inferno", "KingletSeed" },
	weakEvery = 20,
	lackeysPerPlayer = 2,
	lackeyMax = 12,
	stagger = 1,
	volleyLength = 60,
	volleyWidth = 6,
	volleySpacing = 14,
	push = 50,
	lift = 40,
	finale = 1.5,
	finaleSpeed = 0.15,
	rain = 3,
	resultsSeconds = 6,
	topCount = 5,
	critChance = 0.1,
	critMult = 3,
}
Config.GuardTwists = {
	soundRange = 120,
	volume = 0.7,
	Zone1 = {
		kind = "Crow",
		cooldown = 8,
		warn = 1.5,
		radius = 6,
		slow = 0.6,
		seconds = 1.5,
		sound = 9113730784,
	},
	Zone2 = {
		kind = "Bone",
		cooldown = 7,
		warn = 1.3,
		length = 40,
		width = 3,
		push = 12,
		slow = 0.6,
		seconds = 1,
		sound = 9116488438,
	},
	Zone3 = {
		kind = "Root",
		cooldown = 8,
		warn = 1.4,
		radius = 8,
		slow = 0,
		seconds = 1.5,
		sound = Config.Sounds.Whoosh,
	},
	Zone4 = {
		kind = "Tongue",
		cooldown = 8,
		warn = 1.2,
		radius = 7,
		predict = 1,
		pull = 10,
		sound = 9120972321,
	},
	Zone5 = {
		kind = "Bat",
		cooldown = 9,
		warn = 1.5,
		radius = 7,
		ahead = 18,
		sound = Config.Sounds.Whoosh,
	},
	Zone6 = {
		kind = "Sticky",
		cooldown = 8,
		warn = 1.2,
		radius = 6,
		puddles = 2,
		spacing = 10,
		lifetime = 6,
		slow = 0.4,
		seconds = 0.25,
		sound = 1169806635,
	},
	Zone7 = {
		kind = "Boulder",
		cooldown = 7,
		warn = 1.5,
		lanes = 3,
		fanAngle = 20,
		slow = 0.6,
		width = 6,
		length = 40,
		speed = 50,
		push = 14,
		seconds = 1,
		sound = Config.Sounds.Bonk,
	},
	first = 3,
	mercy = 1,
	slowCap = 2,
	effectTick = 0.1,
	iconHeight = 4,
}
Config.PetFinishes = { Gold = Color3.fromRGB(255, 200, 60), Shiny = Color3.fromRGB(220, 255, 255) }
Config.KingSkin = { color = Color3.fromRGB(255, 190, 40), shapeTier = 7 }
Config.Progression.rewardCarry = true
Config.Pets.BonePup.rarity = "Rare"
Config.Pets.FrostOwl.rarity = "Epic"
Config.Pets.LavaSlime.rarity = "Legendary"
for _, def in
	{
		{ id = "MothSeed", pet = "Moth", name = "Moth", income = 75, rarity = "Rare" },
		{ id = "ToadSeed", pet = "Toad", name = "Toad", income = 250, rarity = "Epic" },
		{
			id = "GummySeed",
			pet = "GummyBear",
			name = "Gummy Bear",
			income = 3200,
			rarity = "Legendary",
		},
		{
			id = "DragonSeed",
			pet = "PumpkinDragon",
			name = "Pumpkin Dragon",
			income = 12000,
			rarity = "Mythic",
		},
		{
			id = "KingletSeed",
			pet = "Kinglet",
			name = "Pumpkin Kinglet",
			income = 140000,
			rarity = "Mythic",
		},
	}
do
	Config.Pets[def.pet] = { display = def.name, rarity = def.rarity }
	table.insert(Config.Seeds, {
		id = def.id,
		pet = def.pet,
		name = def.name,
		income = def.income,
		hp = 10,
		template = "pumpkin_orange",
		scale = 2,
	})
end
-- Retain legacy IDs; incomes are rebalanced below and older saves receive compensation.
local ladder = {
	{ "Orange", "Sunny", "R20 tutorial" },
	{ "Ghost", "Shadow", "Fuse Machine" },
	{ "Moon", "MothSeed", "Pen slots 7-8" },
	{ "Crystal", "ToadSeed", "Witch Merchant" },
	{ "Golden", "CandyCorn", "Pen slots 9-10" },
	{ "Inferno", "GummySeed", "Gold mutation" },
	{ "KingSeed", "DragonSeed", "Rebirth" },
}
for i, zoneId in Config.ZoneOrder do
	local z = Config.Zones[zoneId]
	z.pets = { ladder[i][1], ladder[i][2] }
	z.unlock = ladder[i][3]
	z.arrival = Config.Progression.arrivalMinutes[i]
end
Config.Unlocks.King = 0
Config.KingHpPerDamage = 30
Config.KingHpPerPlayer = 200
Config.KingSeconds = 300
Config.AttackEvery = { 6, 4.5, 3.5 }
Config.SlamWarn = 1.5
Config.SlamRadius = 14
Config.VolleyWarn = 1.2
Config.LackeyHp = 1
Config.RainSeconds = Config.KingNight.rain

-- All world themes, farm tuning and nest inhabitants live in Zones.
for _, id in Config.ZoneOrder do
	Config.Hoards[id] = Config.Zones[id].hoard
end

-- Preserve the first gate and calibrate later ones against a transparent active-player model.
-- These are arrival hypotheses, not measured retention/playtest data. The offline model
-- reads these same tables; server and client use the resulting gate costs.
Config.Economy = {
	saveVersion = 2,
	kingletMult = 1.5,
	updateBonusSeconds = 1800,
	legacyIncome = {},
	rarityRanks = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 },
	sim = {
		stealSeconds = 90,
		penZ = 70, -- model assumption, never a teleport target
		travelBudget = 45, -- part of the old 90s cycle replaced with measured lane distance
		durationMinutes = 180,
		tolerance = 0.25,
		crateMinutes = { 20, 40 },
	},
	nestIncome = {
		Orange = 1,
		Sunny = 4,
		Ghost = 15,
		Shadow = 18,
		Moon = 60,
		MothSeed = 75,
		Crystal = 200,
		ToadSeed = 250,
		Golden = 700,
		CandyCorn = 900,
		Inferno = 2500,
		GummySeed = 3200,
		KingSeed = 9000,
		DragonSeed = 12000,
		KingletSeed = 18000,
	},
	roundTo = 1000,
}
-- Legacy pet IDs remain unchanged and loadable; future zone economy is tuned here.
Config.Economy.nestIncome.KingletSeed = Config.Economy.kingletMult
	* math.max(Config.Economy.nestIncome.KingSeed, Config.Economy.nestIncome.DragonSeed)
for _, seed in Config.Seeds do
	Config.Economy.legacyIncome[seed.id] = seed.income
	seed.income = Config.Economy.nestIncome[seed.id] or seed.income
end
-- Calibrated by scene/econ-sim.luau; keep the R20 first gate at 1,000.
Config.Economy.gateCosts = { 1000, 318000, 3064000, 18507000, 138275000, 785290000 }
for i, cost in Config.Economy.gateCosts do
	Config.Zones[Config.ZoneOrder[i + 1]].cost = cost
end
function Config.Economy.crateSeed(zoneIndex, tier, pick)
	if tier == 4 then
		return Config.KingNight.rewardSeeds[4]
	end
	local pets = Config.Zones[Config.ZoneOrder[zoneIndex]].pets
	if tier == 2 or tier == 3 then
		local current = Config.Economy.rarityRanks[Config.Pets[Config.Seeds[1].pet].rarity]
		for _, seed in Config.Seeds do
			if seed.id == pets[pick] then
				current = Config.Economy.rarityRanks[Config.Pets[seed.pet].rarity]
			end
		end
		for i = zoneIndex + 1, #Config.ZoneOrder do
			local candidates = Config.Zones[Config.ZoneOrder[i]].pets
			for _, seed in Config.Seeds do
				if
					seed.id == candidates[pick]
					and Config.Economy.rarityRanks[Config.Pets[seed.pet].rarity] == current + 1
				then
					return seed.id
				end
			end
		end
	end
	return pets[pick]
end
for i, id in Config.ZoneOrder do
	Config.GuardTwists[id].pitch = 0.7 + i * 0.12
end
-- R24: shared movement/size rules; visual sizes never change income.
Config.Movement = { sprintMult = 1.25, bootStep = 2, cap = 26, requestInterval = 0.1 }
Config.Dash = {
	tier = 2,
	distance = 16,
	cooldown = 5,
	clearance = 2,
	bodySize = Vector3.new(4, 3.5, 3),
	bodyLift = 1,
	mobile = Vector2.new(0.70, 0.78),
}
Config.Teleport = { cooldown = 10, height = 4, standOff = 8, rayHeight = 60, rayDepth = 200 }
Config.MysterySizes = {
	nest = { { 3, 4 }, { 3.5, 4.5 }, { 4, 5 }, { 4.5, 5.5 }, { 5, 6 }, { 5.5, 7 }, { 6, 7.5 } },
	penMin = 15,
	penMax = 40,
	weightScale = 0.6,
	characterHeight = 6,
	nestRadius = 10,
	nestSlotRadius = 6,
	heights = { Common = 15, Rare = 20, Epic = 26, Legendary = 33, Mythic = 40 },
	carry = 4,
}
Config.PetRoam = { inset = 2, minSpeed = 4, maxSpeed = 6, minIdle = 1, maxIdle = 3, bob = 0.25 }
Config.GuardSpeed = {
	Zone1 = 0.70,
	Zone2 = 0.75,
	Zone3 = 0.80,
	Zone4 = 0.85,
	Zone5 = 0.90,
	Zone6 = 0.93,
	Zone7 = 0.95,
}
function Config.walkSpeed(level)
	return math.min(
		Config.Movement.cap,
		Config.WalkSpeed
			+ math.clamp(level or 0, 0, Config.Upgrades.Boots.max) * Config.Movement.bootStep
	)
end
function Config.upgradeCost(id, level)
	local info = Config.Upgrades[id]
	return info.prices and info.prices[level + 1]
		or math.floor(info.base * (level + 1) ^ Config.CostPower)
end
function Config.roamPoint(p, time)
	local home = p:GetAttribute("JackHome")
	local from = p:GetAttribute("RoamFrom") or (home and home.Position) or p.Position
	local goal = p:GetAttribute("RoamTo") or from
	local start = p:GetAttribute("RoamStart") or time
	local finish = p:GetAttribute("RoamEnd") or start
	return from:Lerp(goal, math.clamp((time - start) / math.max(0.001, finish - start), 0, 1))
end
return Config
