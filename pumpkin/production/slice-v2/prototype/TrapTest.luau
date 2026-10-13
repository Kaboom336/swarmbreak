local Test = {}
-- Shared acceptance cases: live floor/raycast fixture in Studio, scalar terrain
-- fixture under Lune. Accelerated clock proves lifecycle, not 90s wall time.
function Test.exercise(Traps, t, a, states, actorFactory, react)
	local points = {}
	for x = -66, 66, 12 do
		for z = 0, 66, 6 do
			local p = a.origin + Vector3.new(x, 0, -z)
			local floor = t.arenaAPI.floor(a, p)
			if floor and Traps.spot(t, a, floor, floor + Vector3.new(0, 3, 0)) then
				local spaced = true
				for _, other in points do
					if (other - floor).Magnitude < 12 then
						spaced = false
					end
				end
				if spaced then
					table.insert(points, floor)
				end
			end
		end
	end
	assert(#points >= 5, "need five freely selectable legal open-floor points")
	local owners = {}
	local function owner()
		local actor = actorFactory()
		local s = { phase = "Run", run = a, meadowEscapes = 0 }
		states[actor] = s
		table.insert(owners, actor)
		Traps.entry(t, actor, s)
		return actor, s
	end
	local first, s = owner()
	local p, r = points[1], points[1] + Vector3.new(0, 3, 0)
	local function action(stage, now, position, kind)
		return Traps.action(t, first, s, a, r, stage, position or p, now, kind)
	end
	assert(not action("begin", 0), "locked decoy accepted")
	first:SetAttribute("GreyboxDevTrapUnlock", true)
	assert(not action("begin", 15, p, "Sticky"), "Sticky unlocked by dev decoy grant")
	assert(action("begin", 15))
	assert(not action("finish", 15.5), "short hold accepted")
	assert(s.trapCharge and #t.active == 0, "short hold spent charge")
	assert(not action("begin", 16), "cooldown bypassed")
	assert(action("begin", 30))
	assert(action("cancel", 30.2))
	assert(s.trapCharge and not action("begin", 31), "cancel charge/cooldown")
	assert(action("begin", 45))
	assert(action("finish", 46, points[5])) -- Forged finish position must be ignored.
	local trap = t.active[1]
	assert((trap.position - p).Magnitude < 0.01, "client moved held placement")
	assert(not trap.part.CanCollide and not trap.part.CanQuery and not trap.part.CanTouch, "route-blocking trap")
	assert(not s.trapCharge and not action("begin", 61), "one charge/player")
	s.trapCharge = true -- Adversarial corrupted charge cannot bypass active-owner cap.
	assert(not action("begin", 61), "active-owner limit")
	s.trapCharge = false
	a.guardian.CFrame = CFrame.new(p + Vector3.new(0, 5.5, 1))
	a.guardian.Position = p + Vector3.new(0, 5.5, 1)
	Traps.tick(t, 47, states)
	assert(not a.decoy, "triggered before 2s arm")
	a.attack = { fixture = true }
	Traps.tick(t, 48, states)
	assert(not a.decoy and a.attack.fixture, "committed throw cancelled/retargeted")
	a.attack = nil
	Traps.tick(t, 49, states)
	assert(a.decoy and trap.tellEnd == 50.2 and trap.effectEnd == 52.2, "decoy tell/effect duration")
	a.target = first
	react(49, "DecoyTell")
	assert(not a.target, "decoy failed to release player target")
	react(50.3, "Investigate")
	Traps.tick(t, 52.3, states)
	assert(#t.active == 0 and not a.decoy and a.decoyImmuneUntil >= 60.2, "one-shot cleanup/immunity")
	Traps.entry(t, first, s)
	assert(not action("begin", 59), "entry refreshed cooldown")
	s.trapPickedUp = true
	assert(not action("begin", 80), "drop reopens planning")
	s.trapPickedUp = false
	assert(action("begin", 95))
	assert(action("finish", 96))
	Traps.tick(t, 185.9, states)
	assert(#t.active == 1, "early lifetime cleanup")
	Traps.tick(t, 186, states)
	assert(#t.active == 0, "90s lifetime cleanup")
	for i = 1, 4 do
		local actor, state = owner()
		state.meadowEscapes = 3
		assert(Traps.action(t, actor, state, a, points[i] + Vector3.new(0, 3, 0), "begin", points[i], 200))
		assert(Traps.action(t, actor, state, a, points[i] + Vector3.new(0, 3, 0), "finish", nil, 201))
	end
	local fifth, fifthState = owner()
	fifthState.meadowEscapes = 3
	assert(
		not Traps.action(t, fifth, fifthState, a, points[5] + Vector3.new(0, 3, 0), "begin", points[5], 200),
		"fifth island trap"
	)
	assert(fifthState.trapCharge, "limit refusal consumed charge")
	assert(
		not Traps.spot(t, a, points[1] + Vector3.new(0, 2, 0), points[1] + Vector3.new(0, 3, 0)),
		"elevated placement"
	)
	assert(not Traps.spot(t, a, Vector3.new(0 / 0, 0, 0), r), "NaN accepted")
	for _, point in { { 0, 32 }, { 0, -58 }, { -24, -58 }, { -25, -10 }, { -32, -28 }, { 0, -24 }, { 79, 60 } } do
		local position = a.origin + Vector3.new(point[1], 0, -point[2])
		local floor = t.arenaAPI.floor(a, position) or position
		assert(not Traps.spot(t, a, floor, floor + Vector3.new(0, 3, 0)), "protected/only-route placement accepted")
	end
	local departing = t.active[1].owner
	states[departing].phase = "Home"
	Traps.tick(t, 202, states)
	assert(#t.active == 3, "owner exit orphan")
	Traps.remove(t, t.active[1].owner)
	assert(#t.active == 2, "disconnect/reset cleanup")
	Traps.clearIsland(t, a)
	assert(#t.active == 0, "arena expiry cleanup")
	-- Simulate other island managers filling the global server budget. Actual
	-- placement still executes the authoritative cap check before spending.
	for _ = 1, t.config.MaxServer do
		table.insert(t.active, { owner = {}, arena = {}, position = points[1] })
	end
	assert(
		not Traps.action(t, fifth, fifthState, a, points[5] + Vector3.new(0, 3, 0), "begin", points[5], 220),
		"8/server cap"
	)
	assert(fifthState.trapCharge, "server cap consumed charge")
	t.active = {}
	assert(Traps.action(t, fifth, fifthState, a, points[5] + Vector3.new(0, 3, 0), "begin", points[5], 235))
	assert(
		not Traps.action(t, fifth, fifthState, a, points[5] + Vector3.new(20, 3, 0), "finish", nil, 236),
		"finish skipped range revalidation"
	)
	assert(fifthState.trapCharge and #t.active == 0, "invalid finish consumed charge")
	for _, actor in owners do
		states[actor] = nil
	end
	return "decoy reaction; arm/tell/locked throw/immunity; charge/cooldown/caps; lifetime/leave; flat bypass + protected-route rejection"
end
function Test.run(player, _states, api, log)
	local SSS = game:GetService("ServerScriptService")
	local Traps = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxTraps"))
	local Arena = require(SSS:WaitForChild("GreyboxArena"))
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GreyboxConfig"))
	local a = api.arena()
	api.pvpCourt(true)
	local manager = Traps.new(Config, Arena, api.traps.make, api.traps.label)
	local saved = a.guardian.CFrame
	local savedImmunity = a.decoyImmuneUntil
	local actors = {}
	local ok, result = pcall(Test.exercise, Traps, manager, a, {}, function()
		local attributes = {}
		local actor = { UserId = -100 - #actors }
		function actor:GetAttribute(name)
			return attributes[name]
		end
		function actor:SetAttribute(name, value)
			attributes[name] = value
		end
		table.insert(actors, actor)
		return actor
	end, function(now, mode)
		Arena.tick(a, 0.05, now, {}, function()
			return nil
		end, function()
			error("decoy hit a player")
		end, function() end)
		assert(a.mode == mode and not a.attack, "guardian did not react: " .. mode)
	end)
	Traps.clearIsland(manager, a)
	Arena.reset(a)
	a.guardian.CFrame = saved
	a.decoyImmuneUntil = savedImmunity
	api.pvpCourt(false)
	assert(ok, result)
	log("player " .. player.UserId .. ": " .. result .. " (accelerated clock; real Studio floor)")
	return result
end
return Test
