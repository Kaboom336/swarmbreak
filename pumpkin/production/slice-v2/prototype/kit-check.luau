-- Execute real kit with Lune instances; physics/floor/sight mocked explicitly.
local fs, luau, R = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local V, C = R.Vector3, R.CFrame
local obstruction
local wall
local world = {
	Blockcast = function()
		return wall
	end,
	Spherecast = function()
		return obstruction
	end,
}
local Kit = luau.load(fs.readFile("KeeperAttacks.luau"), {
	environment = {
		Instance = R.Instance,
		Vector3 = V,
		CFrame = C,
		Color3 = R.Color3,
		Enum = R.Enum,
		workspace = world,
	},
})()
local safe, sight, noFloor = false, true, false
local api = {
	floor = function(_, p)
		return not noFloor and V.new(p.X, 0, p.Z) or nil
	end,
	safe = function()
		return safe
	end,
	sight = function()
		return sight
	end,
}
local pose = {
	release = function(guard)
		return guard.CFrame * C.new(6, 0, -3)
	end,
}
local function fixture()
	local guard = setmetatable({ CFrame = C.new(0, 5.5, 0), Size = V.new(4, 11, 4) }, {
		__index = function(self, k)
			if k == "Position" then
				return self.CFrame.Position
			end
		end,
	})
	return { guardian = guard, model = R.Instance.new("Model"), warning = {}, throws = 0, impacts = 0 }
end
local a = fixture()
local one, two, three = {}, {}, {}
local roots = {
	[one] = { Position = V.new(0, 3, -30) },
	[two] = { Position = V.new(4, 3, -30) },
	[three] = {
		Position = V.new(0, 3, -9),
	},
}
local actors = { [one] = { phase = "Run" }, [two] = { phase = "Run" }, [three] = { phase = "Run" } }
local function root(actor)
	return roots[actor]
end
local hits = {}
local accepted = true
local function hit(actor)
	hits[actor] = (hits[actor] or 0) + 1
	return accepted
end
assert(Kit.choose(a, one, 0, { [one] = actors[one] }, root) == "fan", "medium solo selects fan")
assert(Kit.choose(a, one, 0, actors, root) == "lob", "group preference")
assert(Kit.choose(a, three, 0, actors, root) == "slam", "close slam")
safe = true
assert(not Kit.begin(a, one, roots[one].Position, 0, "lob", api, pose), "safe start refused")
safe = false
noFloor = true
assert(not Kit.begin(a, one, roots[one].Position, 0, "lob", api, pose), "no floor start refused")
noFloor = false
assert(Kit.begin(a, one, roots[one].Position, 10, "lob", api, pose))
local t = a.attack
Kit.step(a, 10.619, actors, root, hit, api, pose)
assert(#t.projectiles == 0, "no early lob")
Kit.step(a, 10.620001, actors, root, hit, api, pose)
assert(#t.projectiles == 1, "one lob release")
Kit.step(a, 10.8, actors, root, hit, api, pose)
assert(#t.projectiles == 1, "no duplicate lob")
assert(t.projectiles[1].part.Size.X == 8 and t.duration - t.release >= 0.6, "large projectile / fair tell")
Kit.step(a, 11.520001, actors, root, hit, api, pose)
assert(not a.attack and hits[one] == 1 and hits[two] == 1 and not hits[three], "splash group envelope")
assert(a.keeperCelebrateUntil and t.projectiles[1].part.Parent == nil, "accepted celebration / cleanup")
assert(a.nextThrow == 15.5 and Kit.choose(a, one, 15.5, actors, root) == nil, "per-kind cooldown")
-- Cover at landing is NOT floor even if within four studs of the destination.
for _, role in ipairs({ "HardCover", "Floor" }) do
	a = fixture()
	hits = {}
	accepted = false
	local surface = R.Instance.new("Part")
	surface:SetAttribute("SurfaceRole", role)
	obstruction = { Position = V.new(0, 0, -30), Normal = V.yAxis, Instance = surface }
	assert(Kit.begin(a, one, roots[one].Position, 20, "lob", api, pose))
	Kit.step(a, 21.6, actors, root, hit, api, pose)
	assert((hits[one] or 0) == (role == "Floor" and 1 or 0), "landing cover classification")
	assert(not a.keeperCelebrateUntil, "refused hit celebration")
end
obstruction = nil
accepted = true
-- Fan collision sweeps across the target on a hitch; never hits twice.
a = fixture()
hits = {}
assert(Kit.begin(a, one, roots[one].Position, 30, "fan", api, pose))
roots[one].Position = V.new(0, 3, -20)
t = a.attack
Kit.step(a, 31.2, { [one] = actors[one] }, root, hit, api, pose)
assert(#t.projectiles == 3 and hits[one] == 1, "fan swept hit")
Kit.step(a, 31.320001, { [one] = actors[one] }, root, hit, api, pose)
assert(hits[one] == 1, "fan no double hit")
roots[one].Position = V.new(0, 3, -30)
-- Safe-zone and sight refusal at impact, not merely aim lock.
for _, gate in ipairs({ "safe", "sight" }) do
	a = fixture()
	hits = {}
	assert(Kit.begin(a, one, roots[one].Position, 40, "lob", api, pose))
	if gate == "safe" then
		safe = true
	else
		sight = false
	end
	Kit.step(a, 42, actors, root, hit, api, pose)
	assert(next(hits) == nil, "impact gate refusal")
	safe = false
	sight = true
end
-- A jump clears the expanding rim; grounded thieves are caught once.
a = fixture()
hits = {}
roots[one].Position = V.new(0, 3, -10)
roots[two].Position = V.new(4, 7, -10)
assert(Kit.begin(a, one, roots[one].Position, 50, "slam", api, pose))
Kit.step(a, 50.79, actors, root, hit, api, pose)
assert(next(hits) == nil, "no pre-land hit")
Kit.step(a, 51.25, actors, root, hit, api, pose)
assert(hits[one] == 1 and not hits[two], "grounded catch / airborne escape")
Kit.step(a, 51.5, actors, root, hit, api, pose)
assert(hits[one] == 1, "slam no double hit")
Kit.clear(a)
assert(not a.attack, "clear attack state")
-- Reset helper removes tells and pending projectile phase entirely.
a = fixture()
roots[one].Position = V.new(0, 3, -30)
assert(Kit.begin(a, one, roots[one].Position, 60, "lob", api, pose))
t = a.attack
Kit.clear(a)
for _, p in ipairs(t.parts) do
	assert(p.Parent == nil, "clear tell parts")
end
-- Scalar 20Hz carrier fixtures: straight run can be caught; early reversal escapes.
local speed = require("./GreyboxConfig").CarrySpeed
for _, kind in ipairs({ "fan", "lob" }) do
	for _, reverse in ipairs({ false, true }) do
		a = fixture()
		hits = {}
		local initial = V.new(0, 3, -24)
		local seconds = kind == "fan" and Kit.Tuning.FanLeadSeconds or Kit.Tuning.LobLeadSeconds
		local maximum = kind == "fan" and Kit.Tuning.FanLeadMax or Kit.Tuning.LobLeadMax
		local lead = math.min(speed * seconds, maximum)
		roots[one].Position = initial
		assert(Kit.begin(a, one, initial + V.new(0, 0, -lead), 70, kind, api, pose), "moving fixture begins")
		for i = 1, 40 do
			local elapsed = i * 0.05
			local travel = reverse and elapsed > 0.3 and speed * (0.6 - elapsed) or speed * elapsed
			roots[one].Position = initial + V.new(0, 0, -travel)
			if a.attack then
				Kit.step(a, 70 + elapsed, { [one] = actors[one] }, root, hit, api, pose)
			end
		end
		assert((hits[one] or 0) == (reverse and 0 or 1), kind .. " straight-run catch / early-reversal escape")
	end
end
print(
	"PASS real kit: situation selection/cooldown, no early/duplicate release, group splash, swept fan/hitch, landing cover classification, jumpable rim, once/victim, shield refusal, impact safe/sight, cleanup"
)
print("UNKNOWN: live physics, device readability, human 60s hit-rate balance")
-- Dash: no early move, swept contact on hitches, wall stun, safety/leash, reset.
a = fixture()
hits = {}
accepted = true
safe = false
sight = true
noFloor = false
obstruction = nil
roots[one].Position = V.new(0, 3, -18)
local events = {}
api.fx = function(_, name)
	table.insert(events, name)
end
assert(Kit.begin(a, one, roots[one].Position, 100, "dash", api, pose))
local origin = a.guardian.Position
Kit.step(a, 100.499, actors, root, hit, api, pose)
assert(a.guardian.Position == origin, "dash plants during .5s tell")
Kit.step(a, 100.9, actors, root, hit, api, pose)
assert((a.guardian.Position - origin).Magnitude > 19 and hits[one] == 1, "dash swept hit across hitch")
wall = { Position = V.new(0, 5, -21) }
Kit.step(a, 100.95, actors, root, hit, api, pose)
assert(not a.attack and math.abs(a.keeperStunUntil - 102.5) < 1e-5, "wall stops dash; full 1.55s stun")
assert(
	table.find(events, "dashWindup")
		and table.find(events, "dashRelease")
		and table.find(events, "PlayerHit")
		and table.find(events, "WallStun"),
	"effect hooks"
)
wall = nil
a = fixture()
hits = {}
events = {}
assert(Kit.begin(a, one, roots[one].Position, 110, "dash", api, pose))
safe = true
Kit.step(a, 110.7, actors, root, hit, api, pose)
safe = false
assert(not a.attack and not a.keeperStunUntil and not hits[one], "safe dash boundary has no damage/stun")
a = fixture()
assert(Kit.begin(a, one, roots[one].Position, 120, "dash", api, pose))
api.dashLegal = function()
	return false
end
Kit.step(a, 120.7, actors, root, hit, api, pose)
assert(not a.attack and a.guardian.Position == origin, "dash stays within leash")
api.dashLegal = nil
a = fixture()
assert(Kit.begin(a, one, roots[one].Position, 130, "dash", api, pose))
local pending = a.attack
Kit.clear(a)
assert(not a.attack and pending.parts[1].Parent == nil, "dash reset removes lane")
print(
	"PASS dash: .5s planted tell, swept hitch contact once, wall stop + 1.55s stun, effect hooks, safety, leash, reset"
)
