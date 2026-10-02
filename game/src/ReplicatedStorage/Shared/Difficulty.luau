--!strict
-- Pure difficulty-tier data and scaling. Callers provide completed tiers explicitly.

export type TierName = "Normal" | "Hard" | "Nightmare"

export type Definition = {
	Id: TierName,
	Name: string,
	HealthMultiplier: number,
	DamageMultiplier: number,
	SpawnRateMultiplier: number,
	RewardMultiplier: number,
	UnlockAfter: TierName?,
}

export type CompletedTiers = { [string]: boolean }

export type Stats = {
	Health: number?,
	Damage: number?,
	SpawnDelay: number?,
	Reward: number?,
}

local Difficulty = {}

local function definition(fields: Definition): Definition
	return fields
end

Difficulty.Defs = {
	Normal = definition({
		Id = "Normal",
		Name = "Normal",
		HealthMultiplier = 1,
		DamageMultiplier = 1,
		SpawnRateMultiplier = 1,
		RewardMultiplier = 1,
		UnlockAfter = nil,
	}),
	Hard = definition({
		Id = "Hard",
		Name = "Hard",
		HealthMultiplier = 1.5,
		DamageMultiplier = 1.25,
		SpawnRateMultiplier = 1.15,
		RewardMultiplier = 1.5,
		UnlockAfter = "Normal",
	}),
	Nightmare = definition({
		Id = "Nightmare",
		Name = "Nightmare",
		HealthMultiplier = 2.25,
		DamageMultiplier = 1.5,
		SpawnRateMultiplier = 1.3,
		RewardMultiplier = 2,
		UnlockAfter = "Hard",
	}),
} :: { [TierName]: Definition }

Difficulty.Order = { "Normal", "Hard", "Nightmare" } :: { TierName }
Difficulty.Default = "Normal" :: TierName

function Difficulty.isUnlocked(id: string, completed: CompletedTiers): boolean
	local tier = Difficulty.Defs[id :: TierName]
	if not tier then
		return false
	end
	return tier.UnlockAfter == nil or completed[tier.UnlockAfter] == true
end

-- Returns nil for unknown or locked tiers so callers cannot accidentally select them.
function Difficulty.select(id: string, completed: CompletedTiers): Definition?
	if not Difficulty.isUnlocked(id, completed) then
		return nil
	end
	return Difficulty.Defs[id :: TierName]
end

function Difficulty.scaleReward(baseReward: number, id: TierName): number
	return math.floor(baseReward * Difficulty.Defs[id].RewardMultiplier + 0.5)
end

-- Spawn-rate scaling shortens the delay between spawns rather than changing wave size.
function Difficulty.apply(base: Stats, id: TierName): Stats
	local tier = Difficulty.Defs[id]
	local result = table.clone(base)
	if result.Health ~= nil then
		result.Health *= tier.HealthMultiplier
	end
	if result.Damage ~= nil then
		result.Damage *= tier.DamageMultiplier
	end
	if result.SpawnDelay ~= nil then
		result.SpawnDelay /= tier.SpawnRateMultiplier
	end
	if result.Reward ~= nil then
		result.Reward = Difficulty.scaleReward(result.Reward, id)
	end
	return result
end

return Difficulty
