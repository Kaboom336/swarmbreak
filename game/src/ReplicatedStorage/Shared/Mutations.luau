--!strict
-- One global mutation per UTC day. Pure: callers pass the UTC day index.

export type Definition = {
	Id: string,
	Label: string,
	Blurb: string,
	EnemySpeedMult: number,
	EnemyHealthMult: number,
	PlayerDamageMult: number,
	BossScale: number,
	CoinMult: number,
	Gravity: number,
	SpawnMult: number,
}

export type Stats = { [string]: number }

local Mutations = {}

local NORMAL_GRAVITY = 196.2

local function definition(fields: Definition): Definition
	return fields
end

Mutations.Defs = {
	FastSwarm = definition({
		Id = "FastSwarm",
		Label = "Fast Swarm",
		Blurb = "Enemies move 30% faster.",
		EnemySpeedMult = 1.3,
		EnemyHealthMult = 1,
		PlayerDamageMult = 1,
		BossScale = 1,
		CoinMult = 1,
		Gravity = NORMAL_GRAVITY,
		SpawnMult = 1,
	}),
	Armored = definition({
		Id = "Armored",
		Label = "Armored",
		Blurb = "Enemies have 50% more health.",
		EnemySpeedMult = 1,
		EnemyHealthMult = 1.5,
		PlayerDamageMult = 1,
		BossScale = 1,
		CoinMult = 1,
		Gravity = NORMAL_GRAVITY,
		SpawnMult = 1,
	}),
	GlassCannon = definition({
		Id = "GlassCannon",
		Label = "Glass Cannon",
		Blurb = "Players deal 50% more damage, but enemies have 25% less health.",
		EnemySpeedMult = 1,
		EnemyHealthMult = 0.75,
		PlayerDamageMult = 1.5,
		BossScale = 1,
		CoinMult = 1,
		Gravity = NORMAL_GRAVITY,
		SpawnMult = 1,
	}),
	BigBosses = definition({
		Id = "BigBosses",
		Label = "Big Bosses",
		Blurb = "Bosses are 50% larger.",
		EnemySpeedMult = 1,
		EnemyHealthMult = 1,
		PlayerDamageMult = 1,
		BossScale = 1.5,
		CoinMult = 1,
		Gravity = NORMAL_GRAVITY,
		SpawnMult = 1,
	}),
	DoubleCoins = definition({
		Id = "DoubleCoins",
		Label = "Double Coins",
		Blurb = "All Coin awards are doubled.",
		EnemySpeedMult = 1,
		EnemyHealthMult = 1,
		PlayerDamageMult = 1,
		BossScale = 1,
		CoinMult = 2,
		Gravity = NORMAL_GRAVITY,
		SpawnMult = 1,
	}),
	LowGravity = definition({
		Id = "LowGravity",
		Label = "Low Gravity",
		Blurb = "Gravity is reduced for everyone.",
		EnemySpeedMult = 1,
		EnemyHealthMult = 1,
		PlayerDamageMult = 1,
		BossScale = 1,
		CoinMult = 1,
		Gravity = 110,
		SpawnMult = 1,
	}),
	SwarmX2 = definition({
		Id = "SwarmX2",
		Label = "Swarm x2",
		Blurb = "Twice as many enemies arrive each wave.",
		EnemySpeedMult = 1,
		EnemyHealthMult = 1,
		PlayerDamageMult = 1,
		BossScale = 1,
		CoinMult = 1,
		Gravity = NORMAL_GRAVITY,
		SpawnMult = 2,
	}),
} :: { [string]: Definition }

Mutations.Order = {
	"FastSwarm",
	"Armored",
	"GlassCannon",
	"BigBosses",
	"DoubleCoins",
	"LowGravity",
	"SwarmX2",
}

-- The order forms a cycle, which makes the choice deterministic and guarantees that two
-- consecutive days never have the same mutation.
function Mutations.forDay(dayIndex: number): string
	return Mutations.Order[(math.floor(dayIndex) % #Mutations.Order) + 1]
end

-- Fold a mutation into a copy of a runtime stats table. Unknown ids still return a copy.
function Mutations.apply(base: Stats, id: string): Stats
	local result = table.clone(base)
	local mutation = Mutations.Defs[id]
	if not mutation then
		return result
	end

	if result.EnemySpeed ~= nil then
		result.EnemySpeed *= mutation.EnemySpeedMult
	end
	if result.EnemySpeedMult ~= nil then
		result.EnemySpeedMult *= mutation.EnemySpeedMult
	end
	if result.EnemyHealth ~= nil then
		result.EnemyHealth *= mutation.EnemyHealthMult
	end
	if result.EnemyHealthMult ~= nil then
		result.EnemyHealthMult *= mutation.EnemyHealthMult
	end
	if result.PlayerDamage ~= nil then
		result.PlayerDamage *= mutation.PlayerDamageMult
	end
	if result.PlayerDamageMult ~= nil then
		result.PlayerDamageMult *= mutation.PlayerDamageMult
	end
	if result.BossScale ~= nil then
		result.BossScale *= mutation.BossScale
	end
	if result.Coin ~= nil then
		result.Coin *= mutation.CoinMult
	end
	if result.Coins ~= nil then
		result.Coins *= mutation.CoinMult
	end
	if result.CoinMult ~= nil then
		result.CoinMult *= mutation.CoinMult
	end
	if result.Gravity ~= nil then
		result.Gravity = mutation.Gravity
	end
	if result.Spawn ~= nil then
		result.Spawn *= mutation.SpawnMult
	end
	if result.Spawns ~= nil then
		result.Spawns *= mutation.SpawnMult
	end
	if result.SpawnMult ~= nil then
		result.SpawnMult *= mutation.SpawnMult
	end

	return result
end

return Mutations
