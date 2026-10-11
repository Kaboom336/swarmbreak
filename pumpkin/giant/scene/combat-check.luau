-- Offline regression harness runs the actual combat functions, with deterministic clocks/remotes.
-- Does not claim Studio physics, replicated MoveDirection, visuals, or fight duration acceptance.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local V, CF = roblox.Vector3, roblox.CFrame
-- Lune 0.10.5 lookAt faces +Z for a -Z target; Studio faces -Z. Use the engine's
-- horizontal yaw convention for these ground-plane tests, without changing game code.
local groundCF = setmetatable({
	lookAt = function(at, to)
		local d = to - at
		return CF.new(at) * CF.Angles(0, math.atan2(-d.X, -d.Z), 0)
	end,
}, { __index = CF })
local source = fs.readFile("src/ServerScriptService/Patch.server.luau")
local Config = luau.load(fs.readFile("src/ReplicatedStorage/PatchConfig.luau"), {
	environment = { Color3 = roblox.Color3, Vector3 = V, Vector2 = roblox.Vector2 },
	injectGlobals = true,
})()
local function extract(first, last)
	local a = assert(string.find(source, first, 1, true), first)
	local b = assert(string.find(source, last, a + #first, true), last)
	return string.sub(source, a, b - 1)
end
local time, delayed, onWait = 100, {}, nil
local function advance(seconds)
	time += seconds
	if onWait then
		onWait()
	end
	for i = #delayed, 1, -1 do
		if delayed[i].at <= time then
			local fn = table.remove(delayed, i).fn
			fn()
		end
	end
end
local function object(attrs)
	return {
		Parent = true,
		attrs = attrs or {},
		GetAttribute = function(self, key)
			return self.attrs[key]
		end,
		SetAttribute = function(self, key, value)
			self.attrs[key] = value
		end,
	}
end
local king =
	{ counted = {}, phase = 1, active = true, cast = 0, transitionUntil = 0, stunnedUntil = 0 }
local state, Progress = object(), {}
local players, roots, tells, knocks = {}, {}, {}, 0
local root =
	{ Position = V.new(0, 0, -20), AssemblyLinearVelocity = V.zero, CFrame = CF.new(0, 0, -20) }
local victim = object()
players[1], roots[victim], king.counted[victim] = victim, root, 1400
local face = { Position = V.new(0, 14, 0), Size = V.new(28, 28, 28), CFrame = CF.new(0, 14, 0) }
king.faceBase = face.CFrame
local events = {
	telegraphEvent = {
		FireAllClients = function(_, kind, shapes, warn)
			table.insert(tells, { kind = kind, shapes = shapes, warn = warn, at = time })
		end,
	},
	stompEvent = { FireAllClients = function() end },
	kingDoneEvent = { FireAllClients = function() end },
	knockEvent = {
		FireClient = function()
			knocks += 1
		end,
	},
}
local env = {
	Vector3 = V,
	CFrame = groundCF,
	Config = Config,
	king = king,
	kingGround = V.zero,
	kingFace = face,
	state = state,
	Progress = Progress,
	Remotes = events,
	phaseToken = 1,
	os = {
		clock = function()
			return time
		end,
	},
	workspace = {
		GetServerTimeNow = function()
			return time
		end,
	},
	aliveRoot = function(player)
		return player.Character, roots[player]
	end,
	task = {
		wait = advance,
		delay = function(seconds, fn)
			table.insert(delayed, { at = time + seconds, fn = fn })
		end,
	},
	TweenInfo = {
		new = function()
			return {}
		end,
	},
	Enum = { EasingStyle = { Quad = 1 } },
	Services = {
		Players = {
			GetPlayers = function()
				return players
			end,
		},
		TweenService = {
			Create = function(_, target, _, goal)
				return {
					Play = function()
						for k, v in goal do
							target[k] = v
						end
					end,
					Cancel = function() end,
				}
			end,
		},
	},
}
local function load(code)
	return luau.load(code, { environment = env, injectGlobals = true })()
end
load(extract("function Progress.contains", "function Progress.slow"))
Progress.slow = function(player, _, seconds, icon)
	assert(seconds <= 1 and icon == "STAGGER", "King stagger range")
	player:SetAttribute("stagger", seconds)
end
local land = load(
	extract("local function landAttack", "Progress.landAttack = landAttack")
		.. "\nreturn landAttack"
)
Progress.landAttack, env.landAttack = land, land
local count =
	load(extract("local function fightCount", "local function nextCard") .. "\nreturn fightCount")
env.fightCount = count
local card =
	load(extract("local function nextCard", "function Progress.combatCandy") .. "\nreturn nextCard")
for phase, size in { 3, 4, 6 } do
	king.phase = phase
	for _ = 1, 20 do
		local seen = {}
		for _ = 1, size do
			local previous = king.lastAttack
			local kind = card()
			assert(kind ~= previous and not seen[kind], "Deck repeat or missing card")
			seen[kind] = true
		end
	end
end
local attack =
	load(extract("local function attack(token", "local function spawnLackeys") .. "\nreturn attack")
local function cast(kind, phase)
	king.phase, king.attackBusy, king.active, king.transitionUntil = phase, false, true, 0
	king.faceBase, face.CFrame = CF.new(0, 14, 0), CF.new(0, 14, 0)
	victim:SetAttribute("KingGraceUntil", nil)
	tells, knocks = {}, 0
	attack(1, kind)
	assert(#tells == 1 and tells[1].warn >= 1.5, "Single cast and solo warning")
	return tells[1].shapes
end
local stomp = cast("Stomp", 1)
assert(stomp[1].radius == 18 and king.recoveryEnds == time + 2.5, "Stomp and P1 recovery")
root.Position = V.new(0, 0, 0)
cast("Donut", 2)
assert(knocks == 0, "Donut centre must be safe")
root.Position = V.new(0, 0, -15)
cast("Donut", 2)
assert(
	knocks == 1 and victim:GetAttribute("KingGraceUntil") == time + 1.5,
	"Donut annulus and grace"
)
local volley = cast("Volley", 1)
assert(#volley == 3 and volley[1].width == 6 and volley[1].length == 60, "Volley lanes")
local gap = V.new(0, 0, -45)
gap = CF.Angles(0, math.rad(9), 0):VectorToWorldSpace(gap)
for _, lane in volley do
	assert(not Progress.contains(lane, gap), "Volley gap must be safe")
end
root.Position = V.new(0, 0, -20)
local triple = cast("Triple", 3)
assert(#triple == 3 and triple[3].number == 3 and triple[3].delay == 1, "Numbered triple timings")
root.Position = V.new(0, 0, -16)
cast("Triple", 3)
assert(knocks == 1, "Grace prevents overlapping Triple hits inside 1.5s")
root.Position = V.new(0, 0, -20)
local seedfall = cast("Seedfall", 3)
assert(#seedfall == 2, "Solo seedfall count")
for _, circle in seedfall do
	assert(
		(circle.pos - root.Position).Magnitude >= 10 and circle.pos.Magnitude <= 40,
		"Solo seedfall spawn fairness"
	)
end
for _ = 2, 4 do
	local p = object()
	table.insert(players, p)
	king.counted[p], roots[p] = 1000, root
end
king.attackBusy = false
tells = {}
attack(1, "Seedfall")
assert(#tells[1].shapes == 4 and count() == 4, "Four-player scaling")
king.attackBusy, knocks = false, 0
onWait = function()
	king.cast += 1
	king.transitionUntil = time + 2.5
end
attack(1, "Stomp")
onWait = nil
assert(knocks == 0, "Cancelled transition cast cannot land")
king.transitionUntil = time + 2.5
local hit = false
land({ { pos = root.Position, radius = 18 } }, victim, function()
	hit = true
end)
assert(not hit, "Transition blocks even guard effects")
king.transitionUntil = 0
-- Execute the real bonk handler to verify accepted-hit combo, facing and rate limits.
local bonk
events.bonkEvent = { OnServerEvent = {
	Connect = function(_, fn)
		bonk = fn
	end,
} }
events.swingEvent = { FireAllClients = function() end }
local feedback = {}
events.kingHitEvent = {
	FireAllClients = function(_, _, damage, _, chain)
		table.insert(feedback, { damage = damage, chain = chain })
	end,
}
local hum = { Health = 100 }
victim.Character = {
	FindFirstChild = function(_, name)
		return name == "HumanoidRootPart" and root or name == "Scythe" and {}
	end,
	FindFirstChildOfClass = function()
		return hum
	end,
}
king.hp, king.maxHp, king.shield, king.stunnedUntil, king.recoveryEnds = 10000, 10000, false, 0, 0
king.damage, king.hits, king.dps, king.combos = {}, {}, {}, {}
root.Position, root.CFrame = V.new(0, 0, -20), CF.new(0, 0, -20)
env.carrying, env.lastBonk, env.bonkSpot, env.ghosts = {}, {}, {}, {}
env.Helpers = {
	upgradeLevel = function()
		return 0
	end,
}
env.hasSkill, env.swingDamage, env.bestTool =
	function()
		return false
	end, function()
		return 10
	end, function()
		return { order = 1 }
	end
env.Bases, env.Wild = {
	defend = function()
		return false
	end,
}, { hit = function() end }
env.track, env.kingPlayerHp = function() end, function()
	return 10000
end
env.math = setmetatable({
	random = function()
		return 0.9
	end,
}, { __index = math })
load(extract("Remotes.bonkEvent.OnServerEvent:Connect", "-- Day / midnight / Blood Moon"))
for _ = 1, 3 do
	bonk(victim)
	advance(0.55)
end
assert(#feedback == 3 and feedback[3].chain == 3 and feedback[3].damage == 15, "Three-hit finisher")
advance(1.1)
bonk(victim)
assert(feedback[4].chain == 1, "Combo timeout")
king.recoveryEnds, king.stunnedUntil = time + 10, time + 10
advance(0.55)
bonk(victim)
assert(feedback[#feedback].damage == 15, "Recovery x1.5")
env.math.random = function()
	return 0
end
advance(0.55)
bonk(victim)
assert(feedback[#feedback].damage == 30, "Crit plus recovery plus finisher capped x3")
local hits = #feedback
advance(0.55)
king.transitionUntil = time + 2.5
bonk(victim)
assert(#feedback == hits, "Transition King immunity")
king.transitionUntil = 0
advance(0.55)
root.Position, root.CFrame = V.new(0, 0, 20), CF.new(0, 0, 20)
bonk(victim)
assert(#feedback == hits and hum.Health == 100, "Back-face protection; no Health damage")
root.Position, root.CFrame = V.new(0, 0, -20), CF.new(0, 0, -20)
advance(2)
local cooldown = Config.BonkCooldown
Config.BonkCooldown = 0.01
local beforeCap = #feedback
for _ = 1, 5 do
	bonk(victim)
	advance(0.1)
end
assert(#feedback - beforeCap == 4, "Server enforces four accepted swings per second")
Config.BonkCooldown = cooldown
-- Run every actual guard twist at a predicted hit and a sidestep; first steal remains cosmetic.
hum.MoveDirection, hum.WalkSpeed = V.new(0, 0, -1), 16
env.Lane, env.pose, env.carriesFrom = { safeZ = -1000 }, function() end, function()
	return true
end
env.inOwnBase = function()
	return false
end
env.task.spawn = function(fn)
	fn()
end
local guardTells, slows = {}, {}
events.telegraphEvent.FireClient = function(_, _, kind, shapes, warn, _, _, _, meta)
	table.insert(guardTells, { kind = kind, shapes = shapes, warn = warn, meta = meta })
end
Progress.slow = function(_, mult, seconds, icon)
	table.insert(slows, { mult = mult, seconds = seconds, icon = icon })
end
local twist = load(
	extract("local function twist(g, h", "Services.RunService.Heartbeat:Connect")
		.. "\nreturn twist"
)
local function guardCast(zone, dodge, cosmetic, gap)
	victim:SetAttribute("GuardMercyUntil", nil)
	root.Position, root.CFrame, root.AssemblyLinearVelocity =
		V.new(0, 0, -30), CF.new(0, 0, -30), V.new(0, 0, -16)
	guardTells, slows = {}, {}
	local g = {
		zone = zone,
		pos = V.new(0, 0, -30 + (gap or 20)),
		state = "chase",
		chasedAt = time - 4,
		nextTwist = time - 1,
		target = victim,
		cosmetic = cosmetic,
	}
	g.root = { Position = g.pos }
	onWait = function()
		if #guardTells > 0 then
			local shape = guardTells[1].shapes[1]
			root.Position = dodge and V.new(100, 0, -30) or shape.pos
			root.CFrame = CF.new(root.Position)
		end
	end
	twist(g, { top = 0, nest = V.zero, zMin = -1000, zMax = 1000 }, victim, root)
	onWait = nil
	return g
end
for _, zone in Config.ZoneOrder do
	local cfg = Config.GuardTwists[zone]
	guardCast(zone, false, false)
	assert(
		#guardTells > 0 and guardTells[1].warn >= 1.2 and guardTells[1].meta.color == cfg.color,
		zone .. " tell/color"
	)
	assert(
		#slows > 0 and slows[1].mult == cfg.slow and slows[1].seconds == cfg.seconds,
		zone .. " hit effect"
	)
	if zone == "Zone3" then
		assert(victim:GetAttribute("GuardMercyUntil") >= time + 1.8, "Root plus post-root mercy")
	end
	local g = guardCast(zone, true, false)
	assert(#slows == 0 and g.windedUntil == time + 1, zone .. " sidestep winded")
	guardCast(zone, false, true)
	assert(#guardTells > 0 and #slows == 0, zone .. " cosmetic first steal")
	guardCast(zone, false, false, 13)
	assert(#guardTells == 0, zone .. " minimum distance")
	guardCast(zone, false, false, 61)
	assert(#guardTells == 0, zone .. " maximum distance")
end
guardCast("Zone7", false, false)
assert(#guardTells[1].shapes == 2, "Two boulder lanes")
local catch = load(
	extract("local function bonk(g: Guardian", "-- PatchDebug's old fight action")
		.. "\nreturn bonk"
)
victim:SetAttribute("GuardMercyUntil", time + 1)
catch({}, victim, root) -- Would access guard state/drop remotes if mercy failed.
assert(hum.Health == 100, "Guard attacks never change Health")
print(
	"OK: actual King deck/geometry/scaling/grace/transitions/combo cap/facing; seven guard twists, dodge/cosmetic/distance/mercy"
)
