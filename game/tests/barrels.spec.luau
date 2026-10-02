local Barrels = load("Barrels")

test("barrel blast damage falls off with distance", function()
	eq(Barrels.damageAtDistance(0), Barrels.MaxDamage, "center damage")
	assert(
		Barrels.damageAtDistance(Barrels.BlastRadius / 2) < Barrels.MaxDamage,
		"mid-radius damage should fall off"
	)
	assert(
		Barrels.damageAtDistance(Barrels.BlastRadius / 2) > Barrels.MinDamage,
		"mid-radius damage should remain useful"
	)
end)

test("barrel blast includes its edge and excludes targets beyond it", function()
	eq(Barrels.damageAtDistance(Barrels.BlastRadius), Barrels.MinDamage, "edge damage")
	eq(Barrels.damageAtDistance(Barrels.BlastRadius + 0.01), 0, "outside damage")
	assert(Barrels.shouldChain(Barrels.BlastRadius), "edge barrel should chain")
	assert(not Barrels.shouldChain(Barrels.BlastRadius + 0.01), "outside barrel chained")
end)

test("barrel chains have a visible delay", function()
	assert(Barrels.FuseDelay >= 0.2, "direct blast is not telegraphed")
	assert(Barrels.ChainDelay >= 0.2, "chain reaction is not telegraphed")
	assert(
		Barrels.ChainDelay > Barrels.FuseDelay,
		"chain should be slower than a direct detonation"
	)
	assert(Barrels.MaxChainFX > 0, "chain FX cap must allow feedback")
end)

test("barrels never damage players", function()
	eq(Barrels.FriendlyFire, false, "friendly fire")
	eq(Barrels.canDamageTarget(true), false, "player damage")
	eq(Barrels.canDamageTarget(false), true, "enemy damage")
end)

test("barrel state resets between waves", function()
	local state = Barrels.newState()
	state.Health = 0
	state.Spent = true
	state.Queued = true
	Barrels.reset(state)
	eq(state.Health, Barrels.Health, "reset health")
	eq(state.Spent, false, "reset spent")
	eq(state.Queued, false, "reset queued")
end)
