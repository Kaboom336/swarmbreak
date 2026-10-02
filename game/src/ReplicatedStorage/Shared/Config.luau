--!strict
-- Game-wide tunables. Pure data: no Roblox globals, so tests can require it.
local Config = {
	-- seconds the run-over screen waits for Play again before restarting anyway
	PlayAgainTimeout = 30,
	NormalWaves = 15,
	BossEvery = 5,
	IntermissionSeconds = 12,
	WaveStartDelay = 3,
	BossIntroSeconds = 4,
	MaxAlive = 30,
	SpawnGapMin = 0.5,
	SpawnGapMax = 1.2,
<<<<<<< HEAD
	SpawnProtectionSeconds = 2,
	RestartDelay = 15, -- the run summary panel stays up this long

=======
>>>>>>> w12
	-- Infinite mode: every wave past NormalWaves scales enemies by this much (compounding).
	InfiniteHealthScale = 1.08,
	InfiniteDamageScale = 1.04,
	InfiniteCountPerWave = 2,

	StartHealth = 150,
	CoinsBaseMultiplier = 1,
	DoubleCoinsMultiplier = 2,

	Dash = {
		Speed = 90,
		Duration = 0.18,
		Cooldown = 1.2,
		Charges = 1,
		ExtraDashCharges = 2, -- with the ExtraDash game pass
	},
	DoubleJump = {
		Power = 45,
	},

	Upgrades = {
		Damage = {
			Label = "Damage",
			Base = 1.0,
			PerLevel = 0.15,
			BaseCost = 25,
			CostGrowth = 1.35,
			MaxLevel = 12,
		},
		Speed = {
			Label = "Speed",
			Base = 20,
			PerLevel = 1.5,
			BaseCost = 30,
			CostGrowth = 1.4,
			MaxLevel = 6,
		},
		MaxHealth = {
			Label = "Max HP",
			Base = 150,
			PerLevel = 20,
			BaseCost = 30,
			CostGrowth = 1.35,
			MaxLevel = 10,
		},
		FireRate = {
			Label = "Fire rate",
			Base = 1.0,
			PerLevel = 0.08,
			BaseCost = 35,
			CostGrowth = 1.4,
			MaxLevel = 8,
		},
	},
	UpgradeOrder = { "Damage", "FireRate", "Speed", "MaxHealth" },
}
return Config
