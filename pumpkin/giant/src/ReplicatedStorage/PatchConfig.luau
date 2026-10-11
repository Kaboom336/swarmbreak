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
		button = { family = "rbxasset://fonts/families/GothamSSm.json", weight = "Heavy" },
		small = { family = "rbxasset://fonts/families/GothamSSm.json", weight = "Heavy" },
		shout = { family = "rbxasset://fonts/families/GothamSSm.json", weight = "Heavy" },
		numberStyle = "Italic",
	},
	StartCandy = 0,
	UI = {
		Tokens = {
			go = Color3.fromRGB(255, 138, 26),
			goLip = Color3.fromRGB(138, 62, 0),
			info = Color3.fromRGB(161, 59, 255),
			infoLip = Color3.fromRGB(61, 10, 115),
			good = Color3.fromRGB(92, 255, 31),
			goodLip = Color3.fromRGB(31, 90, 0),
			stop = Color3.fromRGB(255, 59, 59),
			stopLip = Color3.fromRGB(138, 16, 16),
			off = Color3.fromRGB(74, 68, 88),
			offLip = Color3.fromRGB(42, 37, 51),
			panel = Color3.fromRGB(30, 21, 48),
			well = Color3.fromRGB(17, 12, 28),
			card = Color3.fromRGB(46, 38, 64),
			cardStroke = Color3.fromRGB(138, 122, 168),
			candy = Color3.fromRGB(255, 201, 51),
			ink = Color3.new(0, 0, 0),
			rarity = {
				Color3.fromRGB(185, 194, 207),
				Color3.fromRGB(91, 227, 91),
				Color3.fromRGB(53, 168, 255),
				Color3.fromRGB(180, 92, 255),
				Color3.fromRGB(255, 194, 26),
				Color3.fromRGB(255, 77, 109),
			},
			zones = {
				Patch = Color3.fromRGB(255, 138, 26),
				Woods = Color3.fromRGB(63, 185, 80),
				Castle = Color3.fromRGB(161, 59, 255),
				Graveyard = Color3.fromRGB(127, 217, 201),
			},
			type = {
				currency = 0.058,
				title = 0.052,
				hud = 0.030,
				objective = 0.032,
				card = 0.026,
				price = 0.026,
				toast = 0.030,
				badge = 0.022,
				caption = 0.022,
			},
			corners = { button = 0.16, icon = 0.20, card = 0.12, panel = 0.04, chip = 0.5 },
			layout = {
				panelHeight = 0.64,
				panelAspect = 1.45,
				dailyHeight = 0.46,
				dailyAspect = 2.25,
				headerHeight = 0.095,
				closeSize = 0.062,
				hatchHeight = 0.28,
				hatchAspect = 0.78,
				shadow = 0.006,
			},
			secret = {
				Color3.fromRGB(255, 77, 109),
				Color3.fromRGB(255, 194, 26),
				Color3.fromRGB(91, 227, 91),
				Color3.fromRGB(53, 168, 255),
				Color3.fromRGB(180, 92, 255),
				Color3.fromRGB(255, 77, 109),
			},
		},
		panelSize = Vector2.new(0.60, 0.70),
		panelAspect = 1.45,
		objectiveY = 0.012,
		zoneY = 0.075,
		bossY = 0.125,
		actionY = 0.70,
		toastY = 0.10,
		scaleMin = 0.75,
		scaleMax = 1.15,
		body = Color3.fromRGB(30, 21, 48),
		ink = Color3.new(0, 0, 0),
		shop = Color3.fromRGB(255, 138, 26),
		index = Color3.fromRGB(161, 59, 255),
		candy = Color3.fromRGB(255, 201, 51),
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
		minPetHeight = 2.5,
		maxPetHeight = 3.8,
		maxPetWidth = 4.2,
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
	World2 = {
		text = "FROST FIELDS - sealed beyond this adventure",
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
	-- Low right-hand grip: shaft crosses the body toward the opposite shoulder.
	-- Degrees in the neutral hand frame; builder compensates RightGrip's -90 X basis.
	-- The wrap is at -L/4; lean tips behind the shoulder and roll makes it diagonal.
	ScytheHold = { right = 0.05, forward = 0.35, lean = -20, yaw = 0, roll = 38 }, -- up = scaled style.L / 4
	ScytheStyles = {
		RustySickle = {
			L = 6.0,
			bladeRatio = 0.60,
			W = 0.40,
			V = 0.34,
			shaft = "8B5A2B",
			grip = "D9C9A3",
			collar = "5A3A22",
			body = "B5653A",
			edge = "E8A878",
			trail = { "FFFFFF", "FFFFFF" },
			tw = 0.6,
			feature = "tape",
			columns = { { 1, 3 }, { 0, 2 }, { 0, 2 }, { -1, 1 }, { -2, 1 } },
		},
		WoodenScythe = {
			L = 6.1,
			bladeRatio = 0.72,
			W = 0.42,
			V = 0.36,
			shaft = "9C6A3A",
			grip = "3A3F4A",
			collar = "5C6370",
			body = "C9D1DC",
			edge = "FFFFFF",
			shade = "A9B1BE",
			trail = { "E6F0FF", "E6F0FF" },
			tw = 0.7,
			feature = "iron",
			columns = { { 1, 3 }, { 0, 3 }, { 0, 2 }, { -1, 2 }, { -2, 1 }, { -3, 1 } },
		},
		BoneScythe = {
			L = 6.2,
			bladeRatio = 0.80,
			W = 0.45,
			V = 0.38,
			shaft = "FFF6E0",
			grip = "E8DCC0",
			collar = "FFF6E0",
			body = "FFF6E0",
			edge = "BFC4D6",
			shade = "E8DCC0",
			trail = { "FFF6E0", "FFF6E0" },
			tw = 0.8,
			feature = "skull",
			columns = { { 1, 4 }, { 0, 4 }, { 0, 3 }, { -1, 3 }, { -1, 2 }, { -2, 2 }, { -3, 1 } },
		},
		CursedScythe = {
			L = 6.3,
			bladeRatio = 0.85,
			W = 0.46,
			V = 0.40,
			shaft = "3B2160",
			grip = "3B2160",
			collar = "B266FF",
			body = "8A3FFC",
			edge = "D49BFF",
			shade = "6A22D0",
			trail = { "B266FF", "6A22D0" },
			tw = 1,
			feature = "gem",
			light = "B266FF",
			columns = {
				{ 1, 4 },
				{ 0, 4 },
				{ 0, 3 },
				{ -1, 3 },
				{ -1, 2 },
				{ -2, 2 },
				{ -3, 2 },
				{
					-4,
					1,
				},
			},
		},
		MoonScythe = {
			L = 6.4,
			bladeRatio = 0.90,
			W = 0.48,
			V = 0.42,
			shaft = "2A2238",
			grip = "7F1A33",
			collar = "7F1A33",
			body = "C8102E",
			edge = "FF4D6D",
			shade = "2A2238",
			trail = { "FF4D6D", "2A2238" },
			tw = 1.15,
			feature = "batwings",
			light = "FF4D6D",
			columns = {
				{ 1, 4 },
				{ 0, 4 },
				{ 0, 3 },
				{ -1, 3 },
				{ -1, 3 },
				{ -2, 2 },
				{ -3, 2 },
				{
					-4,
					2,
				},
				{
					-5,
					1,
				},
			},
		},
		CandyScythe = {
			L = 6.4,
			bladeRatio = 0.95,
			W = 0.50,
			V = 0.44,
			shaft = "FFFFFF",
			grip = "FFFFFF",
			collar = "FF6EC7",
			body = "FF6EC7",
			edge = "FFFFFF",
			trail = { "FF6EC7", "FFD606", "7CFC3A", "4FC3FF" },
			tw = 1.25,
			feature = "pinwheel",
			light = "FF9AD8",
			columns = {
				{ 1, 5 },
				{ 0, 5 },
				{ 0, 4 },
				{ -1, 4 },
				{ -1, 3 },
				{ -2, 3 },
				{ -3, 2 },
				{
					-4,
					2,
				},
				{
					-5,
					2,
				},
			},
		},
		PumpkinKingCleaver = {
			L = 5.8,
			bladeRatio = 1.0,
			W = 0.55,
			V = 0.46,
			shaft = "4B1F6F",
			grip = "C8102E",
			collar = "FF8A1F",
			body = "FFD606",
			edge = "FFF3A0",
			shade = "E0A800",
			trail = { "FFD606", "FF8A1F" },
			tw = 1.4,
			feature = "kingpumpkin",
			light = "FF9A2E",
			columns = {
				{ 1, 5 },
				{ 0, 5 },
				{ 0, 4 },
				{ -1, 4 },
				{ -1, 4 },
				{ -2, 3 },
				{ -2, 3 },
				{
					-3,
					3,
				},
				{
					-4,
					2,
				},
				{
					-5,
					2,
				},
				{
					-6,
					2,
				},
			},
		},
	},
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
	HoardLeashPad = 80,
	GuardLaunch = { minChase = 3, dropSeconds = 20, pickupGrace = 4, kingSide = 28 },
	GuardianShare = 0.96,
	GuardianFirstShare = 0.8,
	GuardianMinSpeed = 14,
	GuardianReturnSpeed = 12,
	GuardianChaseSeconds = 120,
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
	CarveNewSeconds = 6,
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
			color = Color3.fromRGB(220, 40, 70),
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
		minutes = {},
		warning = 30,
		seconds = 120,
		grace = 1800,
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

	BaseCarry = 3,

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
		Stack = { title = "Upgrade your Base!", text = "Carry +1", base = 40, max = 1, cut = true },
		-- Cut (two ways to buy damage): not sold; its saved level is kept but has no effect.
		Mallet = {
			title = "Sharp Blade",
			text = "+10% swing damage",
			base = 50,
			max = 10,
			cut = true,
		},
		Lucky = {
			cut = true,
			title = "Retired upgrade",
			text = "+5% chance of a rarer pumpkin",
			base = 120,
			max = 5,
		},
	},
	SharpBonus = 0.1,
	LuckyChance = 0.05,

	-- Witch's Orders. Candy rewards pay 30-60 seconds of current pen income.
	OrderIncomeSeconds = 60,
	OrderRefresh = 1200,
	RotatingCount = 1,
	-- target tells the client which verb to show in the top objective banner and where the red
	-- ground arrows point: zone (nearest wild pumpkin), patch (your base), place (your base while
	-- carrying, else the zone), steal (another base), cauldron, witch, tools (the tool stall),
	-- upgrades (the upgrade stall), king, gate (the next locked zone's gate), hoard (the Zone1 Hoard
	-- nest). Saved progress counts steps (orders save version 5; older saves are mapped onto these
	-- 5 steps by the server). After the tutorial: the Graveyard gate, then one rotating order at a
	-- time, only from unlocked systems.
	TutorialOrders = {
		{
			stat = "hoardSteal",
			need = 1,
			text = "Steal a glowing pumpkin!",
			target = "hoard",
			reward = {},
		},
		{ stat = "hatch", need = 1, text = "Place it in your pen!", target = "place", reward = {} },
		{
			stat = "farmCandy",
			need = 50,
			text = "Smash pumpkins for 50 candy!",
			target = "zone",
			b = 3,
		},
		{
			stat = "buyTool",
			need = 1,
			text = "Buy the Iron Scythe!",
			target = "tools",
			reward = {},
		},
		{
			stat = "unlockZone",
			need = 1,
			text = "Unlock the Graveyard!",
			target = "gate",
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
			text = "x2 ghost candy in the Throne zone",
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
		-- x2 candy from smashing, sales and base income. Suggested 199 R$.
		DoubleCandy = 0,
		-- +20% sell value and income, a "VIP" tag over your head and a gold name. Suggested 249 R$.
		VIP = 0,
	},
	-- Candy packs pay minutes of receipt-time pen income, with a small income floor.
	Products = {
		-- Candy Bag: 5 minutes of current pen income. Suggested 25 R$.
		CandySmall = 0,
		-- Candy Chest: 20 minutes of current pen income. Suggested 129 R$.
		CandyBig = 0,
	},
	DoubleCandyMult = 2,
	VipSellBonus = 0.2,

	CandyPackMinutes = { CandySmall = 5, CandyBig = 20 },
	CandyPackIncomeFloor = 1,

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
		Bonk = 71589018126132,
		HitA = 71589018126132,
		HitB = 120939342937662,
		HitC = 85745022889572,
		Break = 85841544161801,
		CandyTick = 4612374807,
		Pop = 109359226723492,
		Growl = 9113980319,
		Reveal = 1840076509,
		Buy = 134810204798705,
		Click = 127036696152728,
		Brew = 99963459517796,
		Coin = 1169806635,
		Whoosh = 9120972321, -- Wood Whoosh (ProSoundEffects)
		-- Legacy roar call sites use the selected creature growl.
		Roar = 9113980319,
		-- Free licensed tracks (DistrokidOfficial): day, midnight, boss.
		DayMusic = 115131430600747, -- CandyMenu
		NightMusic = 140677698800750, -- Stasis Basis (loopable)
		BossMusic = 128007000574959, -- Epic Boss Battle
	},
}

Config.Farm.chainWindow = 1.2
Config.SoundMix = { SFX = 0.6, UI = 0.5, Music = 0.35 }

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
	baseSlots = 8,
	woodsSlots = 10,
	castleSlots = 12,
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
	arrivalMinutes = { 0, 3, 10, 18, 30, 48, 75 },
	promptRange = 14,
	slotSpacing = 8,
	slotRows = 3,
	slotMargin = 1,
}
Config.Raid = {
	grace = 1e9,
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
		tint = Color3.fromRGB(255, 242, 232),
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
	farmSeconds = 1800,
	pity = 5,
	finisherBonus = 0.05,
	consolation = 0.25,
	rarityWeights = { 0, 70, 27, 3 },
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
	resultsSeconds = 3,
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
-- Palette keys checked against VoxelModels: Crow k is its body; Toad f is its hat.
Config.PetFaceKeys = { Crow = { "e" }, Toad = { "k" }, Kinglet = { "f" } }
Config.GuardFaceKeys = { TreeEnt = "e", SwampToad = "y", Vampire = "e", PumpkinKing = "f" }
-- Shared keys also paint King vine leaves (below the face) and the Golem nose.
Config.GuardFaceMinHeight = { PumpkinKing = 0.4, CandyGolem = 13 / 19 }
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
-- Small pumpkins take 2-3 normal hits with the recommended zone scythe.
-- Candy remains the audit ladder; damage upgrades reduce time per reward.
Config.Farm.zoneTools = { 1, 3, 4, 5, 6, 7, 7 }
local ladder = {
	{ "Orange", "Sunny", "R20 tutorial" },
	{ "Ghost", "Shadow", "New pets" },
	{ "Moon", "MothSeed", "Pen slots 9-10 + Fuse" },
	{ "Crystal", "ToadSeed", "Witch Merchant" },
	{ "Golden", "CandyCorn", "Pen slots 11-12" },
	{ "Inferno", "GummySeed", "Gold mutation" },
	{ "KingSeed", "DragonSeed", "Rebirth" },
}
for i, zoneId in Config.ZoneOrder do
	local z = Config.Zones[zoneId]
	z.pets = { ladder[i][1], ladder[i][2] }
	z.candy = ({ 8, 80, 250, 1200, 6000, 30000, 150000 })[i]
	z.hp = math.ceil(Config.Tools[Config.Farm.zoneTools[i]].damage * 2.5)
	z.unlock = ladder[i][3]
	z.arrival = Config.Progression.arrivalMinutes[i]
end
Config.Unlocks.King = 600
Config.Badges = { Welcome = 0, FirstSteal = 0, FirstHatch = 0 }
function Config.gateBenefits(zoneId)
	return (zoneId == "Zone3" or zoneId == "Zone5") and "+2 pen slots, new pets" or "new pets"
end
Config.KingHpPerDamage = 120
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
-- Launch audit gate ladder; scene/econ-sim.luau verifies arrivals without changing these targets.
Config.Economy.gateCosts = { 2500, 100000, 900000, 9000000, 80000000, 540000000 }
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
	tier = 3,
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
	penMin = 3,
	penMax = 4.5,
	weightScale = 0.06,
	characterHeight = 6,
	nestRadius = 10,
	nestSlotRadius = 6,
	heights = { Common = 3, Rare = 3.4, Epic = 3.8, Legendary = 4.2, Mythic = 4.5 },
	carry = 4,
}
Config.Payoff = {
	earlySeconds = 600,
	petEggRatio = 0.8,
	petDistance = 80,
	chestSize = 2.6,
	stackSize = 1.8,
	auraRate = 2,
}
Config.PetRoam = { inset = 2, minSpeed = 4, maxSpeed = 6, minIdle = 1, maxIdle = 3, bob = 0.25 }
Config.GuardSpeed = {
	Zone1 = 0.88,
	Zone2 = 0.90,
	Zone3 = 0.92,
	Zone4 = 0.94,
	Zone5 = 0.95,
	Zone6 = 0.96,
	Zone7 = 0.97,
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
-- Candy-only launch Index. Each reward has a share of a 540 income-second budget.
-- The nominal 600-second pet reward is capped: paying it for every pet exceeds that budget.
Config.IndexRowBonus = 0
Config.IndexRewards = {
	petSeconds = 600,
	minimum = 200,
	petBudgetSeconds = 320,
	title = "Pumpkin Collector",
	milestones = {
		{ percent = 25, seconds = 40 },
		{ percent = 50, seconds = 50 },
		{ percent = 75, seconds = 60 },
		{ percent = 100, seconds = 70 },
	},
}
function Config.indexReward(income, seconds, capSeconds)
	income = math.max(1, income)
	return math.floor(
		math.max(Config.IndexRewards.minimum, math.min(income * seconds, income * capSeconds))
	)
end
-- Shared construction and animation data, also used by the Edit-mode ScytheLab.
do
	local function weldTo(handle: BasePart, part: BasePart)
		part.CanCollide = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
	end

	function Config.buildScythe(def): Tool
		local styleId = def.skinStyle or def.id
		local s = Config.ScytheStyles[styleId] or Config.ScytheStyles.RustySickle
		local tier = def.order or table.find(Config.Tools, def) or 1
		local tool = Instance.new("Tool")
		tool.Name, tool.ToolTip, tool.CanBeDropped = "Scythe", def.name, false
		tool:SetAttribute("ToolId", def.id)
		tool:SetAttribute("StyleId", styleId)
		tool:SetAttribute("VisualTier", tier)
		local h = Config.ScytheHold
		local K = 1.15
		tool.Grip = (CFrame.new(h.right, 0, -h.forward) * CFrame.Angles(
			math.rad(-h.lean),
			math.rad(h.yaw),
			math.rad(h.roll)
		) * CFrame.new(0, s.L * K / 4, 0)):Inverse() * CFrame.Angles(math.rad(-90), 0, 0)
		local handle = Instance.new("Part")
		handle.Name, handle.Size = "Handle", Vector3.new(s.W, s.L, s.W)
		handle.Material, handle.Color = Enum.Material.SmoothPlastic, Color3.fromHex(s.shaft)
		handle.CanCollide, handle.CanQuery, handle.CanTouch, handle.Massless =
			false, false, false, true
		handle.Parent = tool
		local count = 1
		local function block(name, size, cf, color, neon)
			local p = Instance.new("Part")
			p.Name, p.Size, p.CFrame, p.Color = name, size, cf, Color3.fromHex(color)
			p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
			p.CanQuery, p.CanTouch, p.Reflectance = false, false, 0
			weldTo(handle, p)
			p.Parent = tool
			count += 1
			return p
		end
		-- Flat voxel paint keeps the spine and ornaments within the geometry budget.
		local function paint(p, color, x, y, w, height, face)
			local gui = Instance.new("SurfaceGui")
			gui.Face, gui.SizingMode, gui.CanvasSize =
				face or Enum.NormalId.Back,
				Enum.SurfaceGuiSizingMode.FixedSize,
				Vector2.new(100, 100)
			gui.LightInfluence, gui.Parent = 1, p
			local f = Instance.new("Frame")
			f.BorderSizePixel, f.BackgroundColor3 = 0, Color3.fromHex(color)
			f.Position, f.Size, f.Parent = UDim2.fromScale(x, y), UDim2.fromScale(w, height), gui
		end
		block(
			"GripWrap",
			Vector3.new(s.W + 0.1, 0.8, s.W + 0.1),
			CFrame.new(0, -s.L / 4, 0),
			s.grip
		)
		local pommel =
			block("Pommel", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, -s.L / 2, 0), s.collar)
		local top = s.L / 2 - (s.W + 0.3) / 2
		local collar = block(
			"Collar",
			Vector3.new(s.W + 0.3, s.W + 0.3, s.W + 0.3),
			CFrame.new(0, top, 0),
			s.collar,
			tier == 4
		)
		-- A tapered crescent canted forward, broadside enough for front/back cameras.
		local B = CFrame.new(s.W / 2, s.L / 2 - 0.1, 0) * CFrame.Angles(0, math.rad(35), 0)
		local root, tip
		local span = s.L * s.bladeRatio
		local function bladePoint(t)
			return Vector3.new(span * t, span * (0.10 * t - 0.48 * t * t), 0)
		end
		for i = 1, #s.columns do
			local t0, t1 = (i - 1) / #s.columns, i / #s.columns
			local a, b = bladePoint(t0), bladePoint(t1)
			local delta = b - a
			local thickness = 0.128 + 1.024 * (1 - t0) ^ 1.2
			local cf = B
				* CFrame.new((a + b) / 2)
				* CFrame.Angles(0, 0, math.atan2(delta.Y, delta.X))
			local body = block(
				"BladeColumn",
				Vector3.new(delta.Magnitude + 0.06, thickness, 0.5),
				cf,
				s.body
			)
			if s.shade then
				for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
					paint(body, s.shade, 0, 0, 1, 0.2, face)
				end
			end
			local edge = cf * CFrame.new(0, -thickness / 2, 0)
			block("Edge", Vector3.new(delta.Magnitude + 0.07, 0.16, 0.56), edge, s.edge, tier >= 4)
			if i == 1 then
				root = cf
			end
			tip = B * CFrame.new(b)
		end
		local function band(y, color, height)
			block(
				"Band",
				Vector3.new(s.W + 0.08, height or 0.2, s.W + 0.08),
				CFrame.new(0, y, 0),
				color
			)
		end
		if s.feature == "tape" then
			band(0.6, s.grip, 0.25)
		elseif s.feature == "iron" then
			band(-1, s.collar)
			band(1, s.collar)
			for _, x in { -0.2, 0.2 } do
				block("Rivet", Vector3.new(0.14, 0.14, 0.14), CFrame.new(x, top, 0.4), "2E323A")
			end
		elseif s.feature == "skull" then
			for i = 1, 4 do
				for _, face in
					{
						Enum.NormalId.Front,
						Enum.NormalId.Back,
						Enum.NormalId.Left,
						Enum.NormalId.Right,
					}
				do
					paint(
						handle,
						i % 2 == 0 and "E8DCC0" or "FFF6E0",
						0,
						(i - 1) / 4,
						1,
						0.22,
						face
					)
				end
			end
			for _, y in { -1.25, 0, 1.25 } do
				band(y, "E8DCC0", 0.22)
			end
			collar.Size = Vector3.new(0.95, 0.95, 0.95)
			for _, x in { -0.2, 0.2 } do
				block(
					"Eye",
					Vector3.new(0.24, 0.24, 0.05),
					CFrame.new(x, top + 0.08, 0.5),
					"2A2238"
				)
			end
			block("Nose", Vector3.new(0.12, 0.12, 0.05), CFrame.new(0, top - 0.15, 0.5), "2A2238")
			block("Jaw", Vector3.new(0.7, 0.2, 0.7), CFrame.new(0, top - 0.55, 0), "E8DCC0")
			block(
				"BoneKnob",
				Vector3.new(0.35, 0.35, 0.35),
				CFrame.new(0, -s.L / 2 - 0.35, 0),
				s.shaft
			)
		elseif s.feature == "gem" then
			collar.Size, collar.CFrame =
				Vector3.new(0.7, 0.7, 0.7),
				CFrame.new(0, top, 0) * CFrame.Angles(0, 0, math.rad(45))
			block("Cradle", Vector3.new(0.9, 0.3, 0.9), CFrame.new(0, top - 0.6, 0), s.shaft)
			for i, offset in
				{
					Vector3.new(0.3, -1.5, 0),
					Vector3.new(0, -0.5, 0.3),
					Vector3.new(-0.3, 0.5, 0),
					Vector3.new(0, 1.5, -0.3),
				}
			do
				block("Spiral" .. i, Vector3.new(0.22, 0.22, 0.22), CFrame.new(offset), s.body)
			end
			pommel.Size, pommel.Material = Vector3.new(0.4, 0.4, 0.4), Enum.Material.Neon
			pommel.CFrame *= CFrame.Angles(0, 0, math.rad(45))
		elseif s.feature == "batwings" then
			for _, sign in { -1, 1 } do
				for i, d in
					{ { 0.5, 0.6, 0.6, 0 }, { 0.45, 0.45, 1, 0.25 }, { 0.4, 0.3, 1.35, 0.45 } }
				do
					local wing = block(
						"BatWing",
						Vector3.new(d[1], d[2], 0.2),
						CFrame.new(sign * d[3], top + d[4], 0),
						s.shaft
					)
					if i == 1 then
						paint(wing, s.grip, 0.25, 0.25, 0.5, 0.5)
					end
				end
				block(
					"Fang",
					Vector3.new(0.12, 0.28, 0.12),
					CFrame.new(sign * 0.2, top - 0.5, 0.45),
					"FFFFFF"
				)
			end
			band(-0.5, "C8102E")
			band(0.5, "C8102E")
			block(
				"RubyTip",
				Vector3.new(0.2, 0.2, 0.2),
				CFrame.new(0, -s.L / 2 - 0.35, 0),
				s.edge,
				true
			)
		elseif s.feature == "pinwheel" then
			for i = 1, 5 do
				band((i - 3) * 1.05, "FF3B5C", 0.4)
			end
			collar.Size = Vector3.new(1.1, 1.1, 0.25)
			for i, size in { 0.75, 0.4 } do
				block(
					"Pinwheel",
					Vector3.new(size, size, 0.25),
					CFrame.new(0, top, 0.15 * i) * CFrame.Angles(0, 0, math.rad(45 * i)),
					i == 1 and "FFFFFF" or s.body
				)
			end
			for i, color in { "FFD606", "7CFC3A", "4FC3FF", "FFFFFF", "8A3FFC" } do
				local point = bladePoint((i + 0.5) / #s.columns)
				block(
					"Sprinkle",
					Vector3.new(0.13, 0.13, 0.13),
					B * CFrame.new(point + Vector3.new(0, 0, 0.245)),
					color
				)
			end
			pommel.Color = Color3.fromHex("FF3B5C")
			for _, sign in { -1, 1 } do
				block(
					"CandyWrap",
					Vector3.new(0.3, 0.3, 0.3),
					CFrame.new(sign * 0.4, -s.L / 2, 0) * CFrame.Angles(0, 0, math.rad(45)),
					"FFFFFF"
				)
			end
		elseif s.feature == "kingpumpkin" then
			collar.Size = Vector3.new(1.15, 1.15, 1.15)
			paint(collar, "E06A00", 0, 0.78, 1, 0.22)
			for _, x in { -0.28, 0.28 } do
				block(
					"KingEye",
					Vector3.new(0.28, 0.28, 0.05),
					CFrame.new(x, top + 0.1, 0.6) * CFrame.Angles(0, 0, math.rad(45)),
					"FFD606",
					true
				)
			end
			block(
				"KingMouth",
				Vector3.new(0.6, 0.18, 0.05),
				CFrame.new(0, top - 0.25, 0.6),
				"FFD606",
				true
			)
			block("Stem", Vector3.new(0.25, 0.4, 0.25), CFrame.new(0, top + 0.75, 0), "3DBA3A")
			block("Crown", Vector3.new(1.25, 0.25, 1.25), CFrame.new(0, top + 1, 0), s.body)
			for _, x in { -0.5, 0.5 } do
				for _, z in { -0.5, 0.5 } do
					block(
						"CrownPoint",
						Vector3.new(0.25, 0.45, 0.25),
						CFrame.new(x, top + 1.3, z),
						s.body
					)
				end
			end
			for i, col in { { 1, 3 }, { 0, 2 }, { -1, 1 } } do
				block(
					"BackSpike",
					Vector3.new(s.V + 0.01, col[2] * s.V, 0.3),
					CFrame.new(
						-s.W / 2 - (i - 0.5) * s.V,
						s.L / 2 - 0.1 + (col[1] - col[2] / 2) * s.V,
						0
					),
					s.body
				)
			end
			pommel.Size = Vector3.new(0.6, 0.6, 0.6)
			paint(pommel, "C8102E", 0.25, 0.25, 0.5, 0.5)
			for _, y in { -1.8, 0, 1.8 } do
				for _, face in
					{
						Enum.NormalId.Front,
						Enum.NormalId.Back,
						Enum.NormalId.Left,
						Enum.NormalId.Right,
					}
				do
					paint(handle, "FFD606", 0, 0.5 - y / s.L, 1, 0.2 / s.L, face)
				end
			end
			local geometry = Instance.new("Model")
			geometry.Name, geometry.Parent = "KingOutline", tool
			for _, part in tool:GetChildren() do
				if part:IsA("BasePart") and part ~= handle then
					part.Parent = geometry
				end
			end
			local outline = Instance.new("Highlight")
			outline.Adornee, outline.FillTransparency, outline.OutlineColor =
				geometry, 1, Color3.fromHex(s.edge)
			outline.OutlineTransparency, outline.DepthMode, outline.Parent =
				0.4, Enum.HighlightDepthMode.Occluded, tool
		end
		assert(count < 40, "Scythe part budget exceeded")
		-- Scale the finished geometry, including nested King ornaments. Rebind welds
		-- afterward so their offsets match the enlarged tool.
		for _, item in tool:GetDescendants() do
			if item:IsA("WeldConstraint") then
				item.Enabled = false
			end
		end
		for _, part in tool:GetDescendants() do
			if part:IsA("BasePart") then
				local offset = handle.CFrame:ToObjectSpace(part.CFrame)
				part.Size *= K
				part.CFrame = handle.CFrame * (CFrame.new(offset.Position * K) * offset.Rotation)
			end
		end
		for _, item in tool:GetDescendants() do
			if item:IsA("WeldConstraint") then
				item.Enabled = true
			end
		end
		local function attachment(name, cf)
			local a = Instance.new("Attachment")
			a.Name, a.CFrame, a.Parent = name, CFrame.new(cf.Position * K) * cf.Rotation, handle
			return a
		end
		local a0, a1 =
			attachment("TrailRoot", root * CFrame.new(-0.15, 0, 0)),
			attachment("TrailTip", tip * CFrame.new(0.25, 0, 0))
		local colors = {}
		for i, color in s.trail do
			table.insert(
				colors,
				ColorSequenceKeypoint.new((i - 1) / (#s.trail - 1), Color3.fromHex(color))
			)
		end
		local function trail(name, start, finish, glow)
			local t = Instance.new("Trail")
			t.Name, t.Attachment0, t.Attachment1 = name, start, finish
			t.Lifetime, t.MinLength, t.FaceCamera = glow and 0.22 or 0.14, 0.02, false
			local ribbonColors = { ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)) }
			for _, key in colors do
				table.insert(
					ribbonColors,
					ColorSequenceKeypoint.new(0.2 + 0.8 * key.Time, key.Value)
				)
			end
			t.Color = ColorSequence.new(glow and colors or ribbonColors)
			t.Transparency = glow and NumberSequence.new(0.6, 1)
				or NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.25, 0.25),
					NumberSequenceKeypoint.new(1, 1),
				})
			t.WidthScale = NumberSequence.new(s.tw, s.tw * (glow and 0.4 or 0.15))
			t.LightEmission, t.LightInfluence, t.Brightness, t.Enabled, t.Parent =
				1, 0, glow and 1 or 1.6, false, handle
		end
		trail("SwingTrail", a0, a1, false)
		if tier >= 4 then
			trail(
				"SwingGlow",
				attachment("GlowRoot", root * CFrame.new(-0.5, 0, 0)),
				attachment("GlowTip", tip * CFrame.new(0.65, 0, 0)),
				true
			)
			local light = Instance.new("PointLight")
			light.Color, light.Brightness, light.Range, light.Parent =
				Color3.fromHex(s.light),
				tier == 7 and 2 or (tier == 6 and 1 or 1.2),
				tier == 7 and 10 or (tier == 4 and 7 or 8),
				collar
			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Color, particles.Rate = ColorSequence.new(colors), tier == 4 and 3 or 4
			if tier == 4 then
				particles.Color = ColorSequence.new(Color3.fromHex("E2C2FF"))
			elseif tier == 5 then
				particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
				particles.Color = ColorSequence.new(Color3.fromHex("7F1A33"))
			end
			particles.Lifetime, particles.Size = NumberRange.new(0.6), NumberSequence.new(0.15, 0)
			particles.LightEmission, particles.Speed, particles.Parent =
				1, NumberRange.new(tier >= 5 and 1 or 0), a1
			if tier == 7 then
				local fire = particles:Clone()
				fire.Texture = "rbxasset://textures/particles/fire_main.dds"
				fire.Color, fire.Rate, fire.Lifetime, fire.Speed, fire.Parent =
					ColorSequence.new(Color3.fromHex("FF8A1F"), Color3.fromHex("FFD606")),
					6,
					NumberRange.new(0.5),
					NumberRange.new(2),
					collar
			end
		end
		return tool
	end
end
do
	local IDLE = { 12, -8, 6, 15, 4, 0, -6, 12, -3, -8, 0, 0, 0, 0 }
	local SWINGS = {
		{
			{ 0.09, "outQuad", 129, 46, 6, 0, 121, -27, 30, 20, 5, -40, -18, -72, -61, 43 },
			{ 0.115, "linear", 134, 48, 6, 0, 125, -27, 30, 20, 6, -44, -18, -76, -61, 43 },
			{ 0.18, "outCubic", 26, 0, -31, 55, 58, -12, 18, 16, -16, 19, -13, 76, 60, 54 },
			{ 0.25, "outQuad", 33, 29, -32, 52, 34, -2, -27, 24, -13, 45, -12, 56, 61, 47 },
			{ 0.46, "inOutSine", unpack(IDLE) },
		},
		{
			{ 0.09, "outQuad", 101, 33, -19, -2, 90, -2, 4, 44, 9, 39, 17, -123, -4, -20 },
			{ 0.11, "linear", 106, 35, -19, -2, 94, -2, 4, 44, 10, 43, 17, -127, -4, -20 },
			{ 0.18, "outCubic", 27, -13, -32, 2, 48, -21, 30, 7, -20, -21, 1, -107, -60, -30 },
			{ 0.25, "outQuad", -50, 75, 102, 55, 67, -27, 30, 20, -4, -48, -16, -23, 41, 44 },
			{ 0.47, "inOutSine", unpack(IDLE) },
		},
		{
			{ 0.14, "outQuad", 144, -1, -23, 0, 136, -25, 27, 20, 21, -3, -4, -119, -39, 23 },
			{ 0.175, "linear", 150, -1, -23, 0, 141, -25, 27, 20, 23, -3, -4, -123, -39, 23 },
			{ 0.24, "outQuart", 63, 12, -29, 0, 67, -14, 18, 13, -28, -28, 2, -110, -68, 4 },
			{ 0.33, "hold", 56, 12, -25, 0, 62, -11, 23, 11, -31, -29, 10, -105, -69, 9 },
			{ 0.54, "inOutSine", unpack(IDLE) },
		},
	}
	Config.ScythePose = { idle = IDLE, swings = SWINGS }
end
return Config
