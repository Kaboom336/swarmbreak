-- Tuning for Steal a Pumpkin. All values are first guesses to judge on screen.
-- Shared by several entries below (one place to change them).
local SHIELD = 600 -- new-player shield: seconds of a player's total playtime
local HAUNT_COST = 2500000
local HOARD1 = "Ghost" -- the Zone1 Hoard's pumpkin type
local GUARD1 = "Scarecrow" -- the Zone1 Hoard's guardian (the tutorial text names it)
return {
	StartCandy = 30,

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
		Sell = 1800,
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
	-- hatch timer. The look is ServerStorage.PetModels.<name> scaled to PetHeight studs tall (x
	-- PetRareMult from type order PetRareOrder up); a missing model keeps the old living-Jack look.
	-- ServerStorage.PetModels.MysteryPumpkin (optional) is the look of Hoard pumpkins.
	Pets = {
		PumpkinPup = { display = "Pumpkin Pup", rarity = "Common" },
		Crow = { display = "Crow", rarity = "Uncommon" },
		Ghosty = { display = "Ghosty", rarity = "Rare" },
		BlackCat = { display = "Black Cat", rarity = "Rare" },
		CandyBat = { display = "Candy Bat", rarity = "Epic" },
		GoldenPup = { display = "Golden Pup", rarity = "Epic" },
		BonePup = { display = "Bone Pup", rarity = "Legendary" },
		FrostOwl = { display = "Frost Owl", rarity = "Legendary" },
		LavaSlime = { display = "Lava Slime", rarity = "Mythic" },
		KingCat = { display = "King Cat", rarity = "Mythic" },
	},
	PetHeight = 3.5,
	PetRareMult = 1.2,
	PetRareOrder = 3,
	MysteryModel = "MysteryPumpkin",

	-- The Witch pays SellPerIncome seconds of a pumpkin's income for it.
	SellPerIncome = 30,
	-- Each pumpkin rolls a size; it multiplies income, sell value and the look.
	SizeMin = 0.85,
	SizeMax = 1.4,

	-- Zones of wild pumpkins (breakables). Each zone is a folder under workspace.Garden.Zones
	-- holding invisible Parts named "Spawn" and ZMin / ZMax attributes (its stretch of the lane;
	-- zMin / zMax here are the fallback). weights = chance per pumpkin type; max = wild pumpkins
	-- alive at once; cost = candy to open its gate (0 = open from the start). emoji = the
	-- difficulty face on its gate sign (Steal an Egg ladder).
	Zones = {
		Zone1 = {
			title = "Pumpkin Meadow",
			emoji = "🙂",
			cost = 0,
			max = 45,
			zMin = 150,
			zMax = 310,
			weights = { Orange = 70, Sunny = 22, Ghost = 7, Moon = 1 },
		},
		Zone2 = {
			title = "Graveyard",
			emoji = "😐",
			cost = 1000,
			max = 20,
			zMin = 310,
			zMax = 470,
			weights = { Sunny = 50, Ghost = 35, Moon = 13, CandyCorn = 2 },
		},
		Zone3 = {
			title = "Haunted Woods",
			emoji = "😬",
			cost = 25000,
			max = 20,
			zMin = 470,
			zMax = 630,
			weights = { Ghost = 45, Moon = 35, CandyCorn = 17, Golden = 3 },
		},
		Zone4 = {
			title = "Witch Swamp",
			emoji = "😨",
			cost = 400000,
			max = 20,
			zMin = 630,
			zMax = 790,
			weights = { Moon = 30, CandyCorn = 40, Golden = 25, Shadow = 5 },
		},
		Zone5 = {
			title = "Vampire Castle",
			emoji = "😱",
			cost = 2500000,
			max = 20,
			zMin = 790,
			zMax = 950,
			weights = { CandyCorn = 30, Golden = 40, Shadow = 25, Crystal = 5 },
		},
		Zone6 = {
			title = "Candy Kingdom",
			emoji = "😈",
			cost = 17500000,
			max = 20,
			zMin = 950,
			zMax = 1110,
			weights = { Golden = 30, Shadow = 40, Crystal = 25, Inferno = 5 },
		},
		Zone7 = {
			title = "Pumpkin King's Throne",
			emoji = "👹",
			cost = 140000000,
			max = 20,
			zMin = 1110,
			zMax = 1270,
			weights = { Shadow = 30, Crystal = 40, Inferno = 25, KingSeed = 5 },
		},
	},
	-- Zones in unlock order (the "next zone" is the first one not unlocked yet).
	ZoneOrder = { "Zone1", "Zone2", "Zone3", "Zone4", "Zone5", "Zone6", "Zone7" },
	-- A player this many studs past a locked zone's ZMin (inside it) is sent back to the spawn.
	ZoneGuardInset = 2,
	-- Seconds between respawns (one wild pumpkin each time, while below max).
	WildRespawn = 1.5,
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
	-- A popped wild pumpkin also pays its smasher this many seconds of the type's income in candy
	-- (the candy burst that flies into the counter).
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
	Hoards = {
		Zone1 = { type = HOARD1, guardian = GUARD1, guardHeight = 6 },
		Zone2 = { type = "Moon", guardian = "SkeletonKnight", guardHeight = 9 },
		Zone3 = { type = "Golden", guardian = "TreeEnt", guardHeight = 13 },
		Zone4 = { type = "Shadow", guardian = "SwampToad", guardHeight = 16 },
		Zone5 = {
			type = "Crystal",
			guardian = "Vampire",
			parts = "SkeletonKnight",
			guardHeight = 18,
		},
		Zone6 = { type = "Inferno", guardian = "CandyGolem", parts = "TreeEnt", guardHeight = 20 },
		Zone7 = {
			type = "KingSeed",
			guardian = "PumpkinKing",
			parts = "Scarecrow",
			guardHeight = 24,
		},
	},
	HoardCount = 3,
	HoardSize = 1.4,
	HoardMult = 3,
	HoardHold = 1.5,
	HoardRefill = 30,
	HoardReturnDelay = 3,
	HoardOutward = 20,
	HoardLeashPad = 10,
	GuardianShare = 0.9,
	GuardianFirstShare = 0.8,
	GuardianMinSpeed = 14,
	GuardianReturnSpeed = 12,
	GuardianChaseSeconds = 14,
	GuardianWake = 1.8, -- a head start: the thief should get a few steps before the chase
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
			stat = "smash",
			need = 1,
			text = "Smash a pumpkin",
			target = "zone",
			reward = { candy = 25 },
		},
		{
			stat = "place",
			need = 1,
			text = "Place it on your base",
			target = "place",
			reward = { candy = 40 },
		},
		{
			stat = "hoardSteal",
			need = 1,
			text = "Steal a pumpkin from the " .. GUARD1 .. "!",
			target = "hoard",
			reward = { candy = 60 },
		},
		{
			stat = "buyTool",
			need = 1,
			text = "Buy the Wooden Scythe",
			target = "tools",
			reward = { candy = 120 },
		},
		{
			stat = "upgrade:Stack",
			need = 1,
			text = "Upgrade your Base: Carry +1",
			target = "upgrades",
			reward = { candy = 150, title = "Patch Keeper" },
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
