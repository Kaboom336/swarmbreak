--!strict
local EnemyPoolLogic = load("EnemyPoolLogic")
local SpawnQueue = load("SpawnQueue")

test("enemy pool returns the same fake instance", function()
	local created = 0
	local pool = EnemyPoolLogic.new(function(rigKey)
		created += 1
		return { Id = created, RigKey = rigKey }
	end)
	EnemyPoolLogic.setTargets(pool, { Mite = 1 })
	EnemyPoolLogic.refill(pool)

	local first = EnemyPoolLogic.take(pool, "Mite")
	eq(created, 1, "prefill creates one fake")
	assert(EnemyPoolLogic.give(pool, "Mite", first), "returned fake fits target")
	eq(EnemyPoolLogic.take(pool, "Mite"), first, "take reuses the returned fake")
	eq(created, 1, "reuse does not call the factory")
end)

test("enemy pool refill targets come from capped role counts", function()
	local targets = EnemyPoolLogic.targetsForComposition({
		Swarmer = 16,
		Runner = 9,
		Shooter = 8,
		Boss = 1,
	}, function(role)
		return ({ Swarmer = "Mite", Runner = "Runner", Shooter = "Shooter" })[role]
	end)

	eq(targets.Mite, 12, "Swarmer pool is capped")
	eq(targets.Runner, 9, "Runner count comes from the wave")
	eq(targets.Shooter, 8, "Shooter count comes from the wave")
	eq(targets.Boss, nil, "roles without a Nest rig are not pooled")

	local created = {}
	local pool = EnemyPoolLogic.new(function(rigKey)
		created[rigKey] = (created[rigKey] or 0) + 1
		return { RigKey = rigKey }
	end)
	EnemyPoolLogic.setTargets(pool, targets)
	EnemyPoolLogic.refill(pool)
	eq(created.Mite, 12, "refill creates capped Swarmers")
	eq(created.Runner, 9, "refill creates the next wave's Runners")
	eq(created.Shooter, 8, "refill creates the next wave's Shooters")
end)

test("spawn queue drains no more than four jobs per frame", function()
	local queue = SpawnQueue.new(4)
	local spawned = {}
	for id = 1, 9 do
		SpawnQueue.push(queue, id)
	end

	eq(
		SpawnQueue.drain(queue, function(id)
			table.insert(spawned, id)
		end),
		4,
		"first frame count"
	)
	eq(#spawned, 4, "four spawned on first frame")
	eq(SpawnQueue.count(queue), 5, "remainder stays queued")
	eq(
		SpawnQueue.drain(queue, function(id)
			table.insert(spawned, id)
		end),
		4,
		"second frame count"
	)
	eq(
		SpawnQueue.drain(queue, function(id)
			table.insert(spawned, id)
		end),
		1,
		"third frame count"
	)
	for id, value in spawned do
		eq(value, id, "queue preserves order")
	end
end)
