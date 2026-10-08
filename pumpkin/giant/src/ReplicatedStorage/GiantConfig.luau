-- Tuning for Grow the Pumpkin. All values are first guesses to judge on screen.
return {
	-- Field growth: seconds per stage, and the sprout/growing scales before the ripe size roll.
	StageSeconds = { 2, 2 },
	StageScale = { 0.9, 1.5 },
	-- Ripe size roll. `level` is the Strength level needed to lift it; `lb` is its weight.
	Sizes = {
		{ name = "Small", chance = 0.55, scale = 1.9, lb = 10, level = 0 },
		{ name = "Big", chance = 0.3, scale = 2.6, lb = 40, level = 2 },
		{ name = "Huge", chance = 0.12, scale = 3.4, lb = 120, level = 5 },
		{ name = "Colossal", chance = 0.03, scale = 4.2, lb = 300, level = 9 },
	},
	-- Carried pumpkins are drawn no wider than this so the avatar stays visible.
	MaxCarryWidth = 7,
	DroppedLifetime = 90,

	NormalWalkSpeed = 16,
	-- Heavier loads slow you: speed = Normal - lb / SlowPerLb, never below MinCarrySpeed.
	SlowPerLb = 40,
	MinCarrySpeed = 11,

	-- Dunking a pumpkin in a Magic Cauldron gives Strength XP = lb / LbPerXp.
	-- Strength level = floor(sqrt(xp / XpCurve)) plus Grip upgrades.
	LbPerXp = 10,
	XpCurve = 5,

	SlamHold = 1,
	-- Each tier needs this many lb, scaled up by (1 + PlayerScale * (players - 1)).
	TierQuota = { 200, 260, 320, 400 },
	PlayerScale = 0.35,
	-- Gold per slam = lb / LbPerGold * tier * giant number.
	LbPerGold = 10,
	GiantWidths = { 16, 26, 36, 46 },

	-- Awaken pays every helper AwakenBonus + AwakenPerSlam for each slam they made.
	AwakenBonus = 10,
	AwakenPerSlam = 3,
	AwakenSeconds = 8,
	-- Two different players slamming within ComboWindow seconds both get ComboGold.
	ComboWindow = 5,
	ComboGold = 2,
	-- After an awakening, golden pumpkins rain around the pyramid for everyone to grab.
	RainCount = 40,
	RainGold = 3,
	RainSeconds = 16,

	-- Gold upgrades: cost of level n is base * n.
	Upgrades = {
		Grip = { title = "Iron Grip", text = "+1 Strength level", base = 30, max = 5 },
		GreenThumb = {
			title = "Green Thumb",
			text = "Pumpkins grow 20% faster",
			base = 30,
			max = 3,
		},
		QuickHands = {
			title = "Quick Hands",
			text = "Faster pick up and slam",
			base = 20,
			max = 3,
		},
	},

	-- Free Creator Store audio (no scripts possible in audio assets). Not auditioned yet; 0 means silent.
	Sounds = {
		Pick = 9113730784, -- Catch Ball 7 (ProSoundEffects)
		Slam = 9116488438, -- Meaty Thud 2 (ProSoundEffects)
		Swell = 99963459517796, -- Magic Summon SFX
		Coin = 1169806635, -- Coin Collect 2 (Everyedit, free to reuse)
		Music = 1837597930, -- Glass Fantasy (APM Music), looped quietly
	},
}
