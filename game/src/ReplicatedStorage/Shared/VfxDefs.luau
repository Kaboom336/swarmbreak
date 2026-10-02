--!strict
-- Pure particle tuning shared by the client renderer and budget tests.

export type Color = { number }
export type Keypoint = {
	Time: number,
	Value: number,
}
export type Definition = {
	Colors: { Color },
	Transparency: { Keypoint },
	Size: { Keypoint },
	Lifetime: { number },
	Speed: { number },
	Spread: { number },
	Acceleration: { number },
	Drag: number,
	LightEmission: number,
	Rate: number,
	EmitCount: number,
	MaxTriggersPerSecond: number,
	PoolSize: number,
}

local VfxDefs = {}

VfxDefs.MaxRate = 100
VfxDefs.EmitBudgetPerSecond = 600 -- placeholder mobile budget
VfxDefs.PlayerHues = {
	{ 40, 220, 210 }, -- station teal
	{ 70, 140, 255 }, -- player weapon blue
}

local Definitions: { [string]: Definition } = {
	HitSpark = {
		Colors = { { 255, 245, 210 }, { 255, 150, 45 } },
		Transparency = {
			{ Time = 0, Value = 1 },
			{ Time = 0.08, Value = 0 },
			{ Time = 1, Value = 1 },
		},
		Size = { { Time = 0, Value = 0.35 }, { Time = 1, Value = 0 } },
		Lifetime = { 0.12, 0.28 },
		Speed = { 12, 24 },
		Spread = { 180, 180 },
		Acceleration = { 0, -30, 0 },
		Drag = 4,
		LightEmission = 1,
		Rate = 0,
		EmitCount = 12,
		MaxTriggersPerSecond = 20,
		PoolSize = 16,
	},
	MuzzleFlash = {
		Colors = { { 255, 255, 230 }, { 255, 185, 70 } },
		Transparency = {
			{ Time = 0, Value = 1 },
			{ Time = 0.05, Value = 0 },
			{ Time = 1, Value = 1 },
		},
		Size = { { Time = 0, Value = 0.55 }, { Time = 1, Value = 0 } },
		Lifetime = { 0.05, 0.1 },
		Speed = { 3, 7 },
		Spread = { 25, 25 },
		Acceleration = { 0, 0, 0 },
		Drag = 2,
		LightEmission = 1,
		Rate = 0,
		EmitCount = 6,
		MaxTriggersPerSecond = 12,
		PoolSize = 10,
	},
	DeathBurst = {
		Colors = { { 210, 90, 255 }, { 105, 35, 150 } },
		Transparency = {
			{ Time = 0, Value = 1 },
			{ Time = 0.1, Value = 0.05 },
			{ Time = 1, Value = 1 },
		},
		Size = { { Time = 0, Value = 0.7 }, { Time = 0.7, Value = 0.35 }, { Time = 1, Value = 0 } },
		Lifetime = { 0.35, 0.7 },
		Speed = { 10, 22 },
		Spread = { 180, 180 },
		Acceleration = { 0, -12, 0 },
		Drag = 2,
		LightEmission = 0.8,
		Rate = 0,
		EmitCount = 24,
		MaxTriggersPerSecond = 3,
		PoolSize = 6,
	},
	SpawnBuildIn = {
		Colors = { { 185, 80, 255 }, { 90, 35, 140 } },
		Transparency = {
			{ Time = 0, Value = 1 },
			{ Time = 0.2, Value = 0.15 },
			{ Time = 1, Value = 1 },
		},
		Size = { { Time = 0, Value = 0.25 }, { Time = 0.5, Value = 0.8 }, { Time = 1, Value = 0 } },
		Lifetime = { 0.5, 0.9 },
		Speed = { 2, 7 },
		Spread = { 20, 180 },
		Acceleration = { 0, 8, 0 },
		Drag = 3,
		LightEmission = 0.8,
		Rate = 0,
		EmitCount = 18,
		MaxTriggersPerSecond = 1,
		PoolSize = 4,
	},
	Telegraph = {
		Colors = { { 255, 105, 35 }, { 255, 190, 55 } },
		Transparency = {
			{ Time = 0, Value = 1 },
			{ Time = 0.15, Value = 0.15 },
			{ Time = 0.8, Value = 0.3 },
			{ Time = 1, Value = 1 },
		},
		Size = { { Time = 0, Value = 0.35 }, { Time = 0.75, Value = 0.7 }, { Time = 1, Value = 0 } },
		Lifetime = { 0.45, 0.65 },
		Speed = { 1, 3 },
		Spread = { 180, 10 },
		Acceleration = { 0, 1, 0 },
		Drag = 2,
		LightEmission = 1,
		Rate = 12,
		EmitCount = 8,
		MaxTriggersPerSecond = 4,
		PoolSize = 8,
	},
	PickupMagnet = {
		Colors = { { 255, 235, 100 }, { 255, 165, 35 } },
		Transparency = {
			{ Time = 0, Value = 1 },
			{ Time = 0.12, Value = 0 },
			{ Time = 1, Value = 1 },
		},
		Size = { { Time = 0, Value = 0.3 }, { Time = 1, Value = 0 } },
		Lifetime = { 0.2, 0.4 },
		Speed = { 8, 16 },
		Spread = { 35, 35 },
		Acceleration = { 0, 4, 0 },
		Drag = 2,
		LightEmission = 0.9,
		Rate = 0,
		EmitCount = 8,
		MaxTriggersPerSecond = 6,
		PoolSize = 8,
	},
	BossWeakPoint = {
		Colors = { { 255, 255, 235 }, { 255, 65, 150 } },
		Transparency = {
			{ Time = 0, Value = 1 },
			{ Time = 0.2, Value = 0.05 },
			{ Time = 0.75, Value = 0.25 },
			{ Time = 1, Value = 1 },
		},
		Size = { { Time = 0, Value = 0.25 }, { Time = 0.5, Value = 0.65 }, { Time = 1, Value = 0 } },
		Lifetime = { 0.4, 0.7 },
		Speed = { 1, 4 },
		Spread = { 180, 180 },
		Acceleration = { 0, 3, 0 },
		Drag = 3,
		LightEmission = 1,
		Rate = 8,
		EmitCount = 12,
		MaxTriggersPerSecond = 2,
		PoolSize = 4,
	},
}

VfxDefs.Definitions = Definitions
VfxDefs.HitSpark = Definitions.HitSpark
VfxDefs.MuzzleFlash = Definitions.MuzzleFlash
VfxDefs.DeathBurst = Definitions.DeathBurst
VfxDefs.SpawnBuildIn = Definitions.SpawnBuildIn
VfxDefs.Telegraph = Definitions.Telegraph
VfxDefs.PickupMagnet = Definitions.PickupMagnet
VfxDefs.BossWeakPoint = Definitions.BossWeakPoint

function VfxDefs.worstCaseEmitsPerSecond(): number
	local total = 0
	for _, definition in Definitions do
		total += definition.Rate + definition.EmitCount * definition.MaxTriggersPerSecond
	end
	return total
end

return VfxDefs
