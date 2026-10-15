local config = {
	ItemName = "LOOT", -- The only display-name source.
	RecipeVersion = 7,
	HomeSpawnZ = 16,
	HomePortalApproachZ = 8,
	HomeAisleX = 16.5, -- 3-stud waypoint radius clears |x|=20; player lane also clears terrace stairs.
	PlotWidth = 64,
	PlotDepth = 48,
	PlotInset = 4,
	PetFootprint = 4,
	PetSpacing = 2,
	MaxActivePets = 8,
	PetsWander = false, -- Owner decision pending; false keeps the chosen position + idle bounce.
	MeadowX = 0,
	MeadowHeight = 76,
	MeadowZ = -360,
	SessionSeed = 20261012,
	Capacity = 8,
	IslandSize = 160,
	WalkSpeed = 16,
	CarrySpeed = 13.5,
	JumpHeight = 7.2,
	CarryJumpHeight = 7.2,
	WarningSeconds = 1,
	MercySeconds = 3,
	SlowSeconds = 0.6,
	CatchRadius = 3.5,
	ThrowSeconds = 0.9,
	ThrowCooldown = 2.5,
	ThrowRadius = 4,
	GuardianSpeed = 14.5,
	GuardianBurstSpeed = 15,
	GuardianBurstSeconds = 0.7,
	GuardianBurstCooldown = 4,
	GuardianReturnSpeed = 14.5,
	GuardianDetectRange = 24,
	GuardianThrowRange = 56,
	GuardianThrowMinRange = 10,
	GuardianLeadSeconds = 0.65,
	GuardianLeadMaxStuds = 9,
	GuardianLeashRadius = 110,
	GuardianStuckSeconds = 2,
	GuardianReturnSeconds = 20, -- Continuous lack of movement before visible recovery.
	GuardianGuardOffset = { x = 8, y = 8, z = 32 },
	GuardianDroppedGuardRadius = 24,
	GuardianGuardArrival = 3,
	GuardianTargetLockSeconds = 2,
	GuardianSearchSeconds = 2,
	GuardianPathRefreshSeconds = 0.7,
	GuardianProgressStuds = 0.75,
	GuardianPokeVertical = 3,
	GuardianImpactHeight = 5,
	GuardianKnockback = 5,
	GuardianFirstHitRetains = false,
	StumbleSpeed = 5,
	TestHoldRetries = 5,
	TestRecoverRetries = 5,
	ShieldSeconds = 12,
	SettleSeconds = 0.6,
	EscapeSeconds = 60,
	Traps = {
		UnlockEscapes = 3,
		Radius = 3,
		ClearRadius = 9, -- 6-stud patch + 6-stud bypass on each side.
		Range = 8,
		PlacementSeconds = 1,
		ArmSeconds = 2,
		Cooldown = 15,
		Lifetime = 90,
		MaxPerPlayer = 1,
		MaxPerIsland = 4,
		MaxServer = 8,
		Spacing = 12,
		ProtectedMargin = 19,
		MaxSlope = 10,
		Decoy = { TriggerRange = 6, TellSeconds = 1.2, EffectSeconds = 2, ImmunitySeconds = 8 },
		Sticky = { Locked = true, Island = "Crystal", SlowFraction = 0.25, Seconds = 1, MercySeconds = 3 },
	},
	RespawnSeconds = 3,
	BumpCooldown = 2,
	HoldSeconds = { Steal = 2, Bump = 0.4, Grab = 0.4, Trap = 1 },
	Pieces = {
		I01 = { width = 32, depth = 24 },
		I02 = { width = 40, depth = 40 },
		I03 = { width = 40, depth = 40, height = 14 },
		I04 = { width = 40, depth = 40, height = 18 },
		I06 = { width = 32, depth = 24 },
		I08 = { width = 32, depth = 32 },
		I11 = { width = 36, depth = 32 }, -- Two 12 decks + 10 gap need at least 34.
	},
}
if workspace and workspace:GetAttribute("UseMeadowV4") == true then
	config.MeadowV4 = true
	config.ItemName = "Golden Acorn"
	config.IslandSize = 352
	config.GuardianLeashRadius = 330
	config.GuardianGuardOffset = { x = -7, y = 48, z = 99 }
	config.Nest = { x = 0, y = 48, z = 96 }
	config.EntryZ = -136
end
config.Nest = config.Nest or { x = 0, y = 8, z = 32 }
config.EntryZ = config.EntryZ or -58
return config
