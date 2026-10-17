-- Execute mounted raid code with a real built map; collision probes are offline
-- native-part vertical rays. Live swept physics/input are RaidSliceTest's job.
local fs, rb, luau, serde =
	require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/serde")
local p = rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"))
local V, C = rb.Vector3, rb.CFrame
local clock, cache = 100, {}
local fakeWS = {
	GetServerTimeNow = function()
		return clock
	end,
}
local function load(n)
	if cache[n] then
		return cache[n]
	end
	local env = {
		script = n,
		require = load,
		warn = warn,
		workspace = fakeWS,
		Vector3 = V,
		Vector2 = rb.Vector2,
		CFrame = C,
		Color3 = rb.Color3,
		Enum = rb.Enum,
		Instance = rb.Instance,
		UDim2 = rb.UDim2,
		NumberSequence = rb.NumberSequence,
		ColorSequence = rb.ColorSequence,
		game = {
			GetService = function(_, s)
				if s == "ReplicatedStorage" then
					return p.ReplicatedStorage
				elseif s == "RunService" then
					return {}
				elseif s == "Workspace" then
					return p.Workspace
				else
					return {
						JSONDecode = function(_, v)
							return serde.decode("json", v)
						end,
					}
				end
			end,
		},
	}
	cache[n] = luau.load(n.Source, { environment = env })()
	return cache[n]
end
local map
local physicsCache = "treasure/raid-physics-cache.rbxm"
if fs.isFile(physicsCache) and require("@lune/process").args[1] ~= "fresh" then
	map = rb.deserializeModel(fs.readFile(physicsCache))[1]
	load(p.ReplicatedStorage.MeadowV4.RaidSlice).build(map, V.zero)
else
	map = load(p.ReplicatedStorage.MeadowV4.Builder).build(p.Workspace, V.zero)
	local physics = rb.Instance.new("Model")
	physics.Name = "RaidOfflinePhysics"
	for _, q in map:GetDescendants() do
		if q:IsA("BasePart") and q.CanCollide and q.CanQuery and not q:GetAttribute("RaidVaultWall") then
			local copy = q:Clone()
			for _, child in copy:GetChildren() do
				child:Destroy()
			end
			copy.Parent = physics
		end
	end
	fs.writeFile(physicsCache, rb.serializeModel({ physics }))
end
local ray = require("../prototype/meadow-v4/OfflineRay").new(map)
local R = load(p.ReplicatedStorage.MeadowV4.RaidSlice)
local api = {
	floor = function(_, q)
		local h = ray(q + V.new(0, 12, 0), V.new(0, -90, 0))
		return h and h.Instance:GetAttribute("SurfaceRole") == "Floor" and h.Normal.Y > 0.8 and h.Position
			or nil
	end,
	safe = function()
		return false
	end,
}
if require("@lune/process").args[1] == "probe" then
	for z = 96, 112, 2 do
		local row = { tostring(z) }
		for x = -110, -76, 2 do
			local q = V.new(x, 0, z)
			local floor = api.floor(nil, q + V.new(0, 3, 0))
			local head = ray(q + V.new(0, 7, 0), V.new(0, -6.5, 0))
			table.insert(row, x .. ":" .. (floor and not head and string.format("%.2f", floor.Y) or "X"))
		end
		print(table.concat(row, " "))
	end
	return
end
for i, lane in R.Lanes do
	for j = 0, 32 do
		for _, offset in { V.zero, V.new(0, 0, 2.5), V.new(0, 0, -2.5) } do
			local q = lane[1]:Lerp(lane[2], j / 32) + offset
			local floor = api.floor(nil, q + V.new(0, 3, 0))
			assert(floor and math.abs(floor.Y) < 0.6, "lane " .. i .. " bad floor " .. tostring(q))
			local head = ray(q + V.new(0, 7, 0), V.new(0, -6.5, 0))
			assert(not head, "lane body blocked " .. tostring(q))
		end
	end
end
for i = 1, #R.Bypass - 1 do
	for j = 0, 32 do
		local q = R.Bypass[i]:Lerp(R.Bypass[i + 1], j / 32)
		assert(api.floor(nil, q + V.new(0, 3, 0)), "bypass missing floor")
		assert(not ray(q + V.new(0, 7, 0), V.new(0, -6.5, 0)), "bypass blocked")
	end
end
for _, edge in R.Connectors do
	for j = 0, 32 do
		local q = edge[1]:Lerp(edge[2], j / 32)
		local h = ray(q + V.new(0, 15, 0), V.new(0, -90, 0))
		assert(
			api.floor(nil, q + V.new(0, 3, 0)),
			"fork connection missing floor " .. tostring(q) .. " / " .. (h and h.Instance.Name or "none")
		)
		assert(not ray(q + V.new(0, 7, 0), V.new(0, -6.5, 0)), "fork connection blocked " .. tostring(q))
	end
end
print("PASS authored lane full widths and walking bypass floors/headroom")
local a = {
	origin = V.zero,
	v4 = map,
	model = rb.Instance.new("Model"),
	guardian = rb.Instance.new("Part"),
	warning = {},
	nextThrow = 0,
}
local actor, other = {}, {}
local roots = { [actor] = { Position = V.new(-94, 3, 40) }, [other] = { Position = V.new(-96, 3, 58) } }
local states =
	{ [actor] = { run = a, phase = "Run", mercy = 0 }, [other] = { run = a, phase = "Run", mercy = 0 } }
local loot = { id = "raid-fixture", state = "Carried", holder = actor }
local hits = {}
local charges = {}
local function root(who)
	return roots[who]
end
local function hit(who)
	hits[who] = (hits[who] or 0) + 1
	states[who].mercy = clock + 3
	return true
end
local function step(dt)
	clock += dt
	local busy = R.tick(a, dt, clock, states, root, hit, api, loot)
	assert(not (a.attack and a.raidBusy), "overlapping commitment")
	return busy
end
assert(step(0.05) and a.raid and #a.raid.units == 2, "pair not deployed")
local c = a.raid.commit
R.ready(a, actor, c.serial, clock)
R.ready(a, other, c.serial, clock)
roots[actor].Position = V.new(-94, 3, 48)
while a.raid and a.raid.index == 1 do
	local r = a.raid
	if r.commit and clock - r.commit.start < 1.2 then
		assert(not r.model:GetAttribute("Charging"), "short tell")
	end
	if r.model:GetAttribute("Charging") then
		charges[r.index] = true
		assert(clock - r.commit.start >= 1.2)
	end
	step(0.05)
end
assert(hits[actor] == 1 and not hits[other], "committed lane hit / other lane miss")
local second = a.raid.commit
R.ready(a, other, second.serial, clock)
-- Late observer is never eligible during this commitment.
roots[actor].Position = V.new(-94, 3, 58)
while a.raid do
	step(0.05)
end
assert(hits[other] == 1 and hits[actor] == 1, "second lane / mercy / complete warning")
assert(not a.model:FindFirstChild("RaidSquad"), "despawn leaked")
assert(not step(0.05), "same cargo redeployed after retirement")
-- Combat, tunnel and reset arbitration use the actual production state machine.
a.raidItem = nil
a.attack = {}
assert(not step(0.05), "Guardian overlap")
a.attack = nil
roots[actor].Position = V.new(-76, 3, 70)
assert(not step(0.05), "tunnel entrant overlap")
roots[actor].Position = V.new(-94, 3, 40)
clock += 3
assert(step(0.05))
R.clear(a)
assert(not a.raid and not a.raidBusy, "reset cleanup")
-- Intent, location, landing and cooldown negative cases, using production policy.
local wall = V.new(-98, 3.12, 49)
local intent = V.zAxis
local clear = {
	vaultClear = function()
		return true
	end,
}
assert(not R.vaultTarget(a, wall, intent, false, clock, nil, clear), "auto vault")
assert(not R.vaultTarget(a, wall + V.new(8, 0, 0), intent, true, clock, nil, clear), "unmarked vault")
assert(not R.vaultTarget(a, wall, -intent, true, clock, nil, clear), "backward vault")
assert(not R.vaultTarget(a, wall, intent, true, clock, clock, clear), "cooldown ignored")
assert(not R.vaultTarget(a, wall, intent, true, clock, nil, {
	vaultClear = function()
		return false
	end,
}), "blocked landing")
local target = assert(R.vaultTarget(a, wall, intent, true, clock, nil, clear))
assert((target - wall).Magnitude == 8 and R.vaultPoint(wall, target, 1) == target, "bounded vault endpoint")
local walk = 0
for i = 1, #R.Bypass - 1 do
	walk += (R.Bypass[i + 1] - R.Bypass[i]).Magnitude
end
assert(R.Tuning.VaultSeconds < walk / 13.5, "vault slower than walk")
local before = rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.pre-raid1.rbxl"))
for _, n in before:GetDescendants() do
	if n:IsA("LuaSourceContainer") then
		local path = {}
		local cursor = n
		while cursor.Parent do
			table.insert(path, 1, cursor.Name)
			cursor = cursor.Parent
		end
		local cur = p
		for _, name in path do
			cur = cur:FindFirstChild(name)
			assert(cur, "missing original source")
		end
		local allowed =
			{ Greybox = true, GreyboxArena = true, StudioPass = true, Builder = true, GreyboxTraps = true }
		if not allowed[n.Name] then
			assert(cur.Source == n.Source, "unrelated source changed " .. n:GetFullName())
		end
	end
end
fs.writeFile(
	"treasure/RAID-CONTRACTS.json",
	serde.encode("json", {
		status = "PASS",
		artifact_sha256 = serde.hash("sha256", fs.readFile("slice-v2/prototype/guardian-greybox.rbxl")),
		lanes_and_bypass = true,
		tell_minimum = true,
		coordinator = true,
		other_lane_miss = true,
		committed_hit = true,
		late_warning_and_mercy = true,
		despawn = true,
		vault_intent_location_landing_cooldown = true,
		live_physics_and_devices = "UNKNOWN; run RaidSliceTest in Studio",
	}, true)
)
print(
	"PASS raid lifecycle, tells, lane hit/miss, shared reservation, warning, vault policy and unrelated sources"
)
