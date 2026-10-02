--!strict
-- Pure definitions for environmental and reward effects.

export type Color = { number }
export type EffectDefinition = {
	Kind: "Decal" | "Burst",
	Colors: { Color },
	Lifetime: number,
	FadeOutSeconds: number,
	MaxLive: number?,
	EmitCount: number?,
	Triggers: { string }?,
	Motion: string?,
}

local VfxDefs = {}

VfxDefs.MaxLiveDecals = 24 -- placeholder; tune against the mobile frame budget

VfxDefs.Goo = {
	Kind = "Decal",
	Colors = {
		{ 25, 190, 165 },
		{ 95, 205, 80 },
	},
	Lifetime = 5,
	FadeOutSeconds = 1.5,
	MaxLive = VfxDefs.MaxLiveDecals,
} :: EffectDefinition

VfxDefs.Crack = {
	Kind = "Decal",
	Colors = {
		{ 65, 70, 70 },
	},
	Lifetime = 4,
	FadeOutSeconds = 1,
	MaxLive = VfxDefs.MaxLiveDecals,
	Triggers = { "BossSlam", "BigBugLanding" },
} :: EffectDefinition

VfxDefs.Debris = {
	Kind = "Burst",
	Colors = {
		{ 100, 105, 100 },
	},
	Lifetime = 1.25,
	FadeOutSeconds = 0.5,
	EmitCount = 12, -- placeholder
	Triggers = { "BossSlam", "BigBugLanding" },
} :: EffectDefinition

VfxDefs.CoinBurst = {
	Kind = "Burst",
	Colors = {
		{ 240, 220, 60 },
	},
	Lifetime = 1,
	FadeOutSeconds = 0.25,
	EmitCount = 8, -- placeholder
	Motion = "FlyToPlayer",
} :: EffectDefinition

return VfxDefs
