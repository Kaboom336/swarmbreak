-- Runs in Studio AND Lune; store fixtures never touch player/live records.
local Tests = {}
function Tests.run(config, domain, profiles, rules, lootConfig, service, mockStore)
	local now = 1000
	local store = mockStore.new(domain)
	local function session(token)
		return profiles.new(store, config, domain, token, function()
			return now
		end, function() end)
	end
	local a, b = {}, {}
	local r = rules.new(lootConfig)
	local state = rules.actor(r, a)
	rules.actor(r, b).phase = "Run"
	state.phase = "Run"
	local item = rules.spawn(r, {})
	local check = function()
		return true
	end
	assert(rules.begin(r, a, "Steal", nil, 0, check))
	assert(rules.finish(r, a, "Steal", lootConfig.HoldSeconds.Steal, check, function()
		return {}
	end))
	item.rollTier = domain.roll(config, 0.8)
	local firstDeadline = item.escapeDeadline
	state.shield, state.mercy = 0, 0
	assert(rules.drop(r, a, 4, {}))
	assert(rules.begin(r, b, "Grab", nil, 5, check))
	assert(rules.finish(r, b, "Grab", 5 + lootConfig.HoldSeconds.Grab, check, function()
		return {}
	end))
	assert(
		r.actors[b].item == item and item.escapeDeadline == firstDeadline and item.rollTier == 2,
		"handoff reroll"
	)
	local winner = session("winner")
	store.records.future = {data={version=999},revision=0}
	assert(not winner:load("future"), "future save overwritten")
	assert(store.records.future.data.version==999, "rejected save was replaced")
	store.records.malformed = {unexpected=true}
	assert(not winner:load("malformed"), "malformed envelope accepted")
	store.legacy=function() error("legacy read unavailable") end
	assert(not winner:load("migration"), "failed migration created default")
	store.legacy=nil
	assert(winner:load("fixture"))
	assert(not session("rival"):load("fixture"), "session lock not enforced")
	item.securePending = true
	assert(not rules.expire(r, 100), "saving cargo expired")
	store.failAfter = 1
	assert(winner:transaction("fixture", function(data)
		return domain.secure(data, config, item.id, item.rollTier, r.actors[b])
	end))
	assert(rules.secure(r, b, 100))
	assert(rules.place(r, b))
	assert(winner:transaction("fixture", function(data)
		return domain.place(data, item.id, 0, 10, 15)
	end))
	local data = winner.sessions.fixture.data
	domain.tick(data, config, 5)
	assert(data.bank == 0, "unopened cargo earned")
	assert(winner:transaction("fixture", function(nextData)
		return domain.open(nextData, config, item.id)
	end))
	assert(not winner:transaction("fixture", function(nextData)
		return domain.open(nextData, config, item.id)
	end), "duplicate Open")
	data = winner.sessions.fixture.data
	assert(#data.pets == 1 and data.pets[1].tier == 1 and data.discovered.Pup, "first winner Pup")
	domain.tick(data, config, 3)
	assert(data.bank == 3 and data.coins == 0, "real online bank ticks")
	assert(winner:transaction("fixture", domain.collect))
	assert(
		winner.sessions.fixture.data.coins == 3 and winner.sessions.fixture.data.bank == 0,
		"collect bank transfer"
	)
	assert(winner:transaction("fixture", domain.collect))
	assert(winner.sessions.fixture.data.coins == 3, "duplicate Collect minted coins")
	store.failAfter = config.Retries
	local ok = winner:transaction("fixture", function(nextData)
		return domain.secure(nextData, config, "second", 2, {})
	end)
	assert(not ok and not winner:available("fixture"), "unknown write accepted")
	assert(winner:save("fixture", false), "unknown write did not reconcile")
	assert(winner.sessions.fixture.data.pending.tier == 2, "second winner rarity")
	assert(winner:save("fixture", true))
	local restored = session("rejoin")
	local loaded = assert(restored:load("fixture"))
	assert(
		loaded.coins == 3
			and #loaded.pets == 1
			and loaded.pending.id == "second"
			and loaded.discovered.Pup,
		"round trip"
	)
	assert(
		loaded.pets[1].x == 0 and loaded.pets[1].z == 10 and loaded.pets[1].yaw == 15,
		"placement persistence"
	)
	now += config.Lease + 1
	store.active.fixture:EndSession()
	assert(not restored:transaction("fixture", domain.collect), "ended session wrote")
	local stolen = session("new-owner")
	assert(stolen:load("fixture"))
	assert(not restored:save("fixture", false), "old owner overwrote new session")
	assert(
		domain.roll(config, 0) == 1
			and domain.roll(config, 0.70) == 2
			and domain.roll(config, 0.95) == 3,
		"roll boundaries"
	)
	local fourTier = domain.copy(config)
	fourTier.Rarities[4].weight = 1
	assert(domain.roll(fourTier, 0.9999) == 4, "configurable Legendary roll")
	assert(not domain.validate({ version = 999 }, config), "future schema overwritten")
	assert(not domain.place(domain.default(), "invalid", 0 / 0, 0, 0), "nonfinite input")
	local full = domain.default()
	for i = 1, config.MaxPets do
		table.insert(full.pets, { id = tostring(i), tier = 1, x = 0, z = i, yaw = 0 })
	end
	assert(not domain.secure(full, config, "overflow", 1, {}), "capacity overflow")
	-- Exercise the real service adapter: fractional frames, owner/range gates and a yielding save.
	local actor = { UserId = 42, Parent = true, attributes = {} }
	function actor:SetAttribute(key, value)
		self.attributes[key] = value
	end
	local actorState = { phase = "Home", shieldUsed = false, firstHitUsed = false }
	local near = true
	local collected = 0
	local adapter = service.new(config, domain, session("adapter"), {
		center = function()
			return 52, 96
		end,
		state = function(player)
			return player == actor and actorState or nil
		end,
		near = function()
			return near
		end,
		restore = function() end,
		event = {
			FireClient = function(_, player, event, amount)
				assert(player == actor and event == "Collect", "collect recipient")
				collected += amount
			end,
		},
	})
	assert(adapter:load(actor, actorState))
	assert(adapter:canEnter(actor), "fresh profile denied")
	assert(adapter:secure(actor, { id = "adapter-acorn", rollTier = 3 }, actorState))
	assert(not adapter:canEnter(actor), "secured cargo allowed re-entry")
	assert(adapter:place(actor, { id = "adapter-acorn" }, { X = 52, Z = 106 }, 0, 1))
	assert(adapter.profiles:transaction(adapter.keys[actor], function(nextData)
		return domain.open(nextData, config, "adapter-acorn")
	end))
	adapter.holds[actor] = { root = {} }
	near = false
	adapter:tick(0)
	assert(not adapter.holds[actor], "opening hold survived lost range/sight")
	near = true
	adapter:tick(0.5)
	assert(adapter:data(actor).bank == 0, "fractional frame tick")
	adapter:tick(0.5)
	assert(adapter:data(actor).bank == 1, "whole second tick")
	near = false
	adapter:collect(actor, {})
	assert(adapter:data(actor).coins == 0, "remote collect bypassed range")
	near = true
	actorState.phase = "Run"
	adapter:collect(actor, {})
	assert(adapter:data(actor).coins == 0, "arena collected plot")
	actorState.phase = "Home"
	adapter:collect({}, {})
	adapter:collect(actor, {})
	assert(adapter:data(actor).coins == 1 and collected == 1, "owner collect/pop")
	adapter:tick(1)
	store.onWrite = function()
		store.onWrite = nil
		adapter:tick(2)
	end
	adapter:collect(actor, {})
	assert(
		adapter:data(actor).coins == 2 and adapter:data(actor).bank == 2,
		"yielding save erased online ticks"
	)
	assert(adapter:save(actor, true), "adapter release")
	return "acorn handoff -> secure -> Open -> Pup -> Coins -> ProfileStore contract save/load; replay, session fencing, unknown-write, schema, migration, capacity PASS"
end
return Tests
