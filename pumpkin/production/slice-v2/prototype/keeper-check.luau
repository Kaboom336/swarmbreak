local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local V, C = roblox.Vector3, roblox.CFrame
local root = "../../models/meadow-keeper/anim/"
local modules = {}
local function loadModule(_name, path)
	return luau.load(fs.readFile(path), {
		environment = {
			game = {
				GetService = function(_, service)
					if service == "HttpService" then
						return {
							JSONDecode = function(_, value)
								return serde.decode("json", value)
							end,
						}
					end
					return {}
				end,
			},
			script = {
				Parent = {
					Animator = "Animator",
					Clips = "Clips",
					Geometry = "Geometry",
					Skeleton = "Skeleton",
					Kinematics = "Kinematics",
				},
			},
			require = function(module)
				return assert(modules[module], module)
			end,
			Vector3 = V,
			CFrame = C,
		},
	})()
end
for _, name in { "Geometry", "Skeleton", "Kinematics", "Clips", "Animator" } do
	for level = 0, 2 do
		luau.compile(fs.readFile(root .. name .. ".luau"), { optimizationLevel = level })
	end
	modules[name] = loadModule(name, root .. name .. ".luau")
end
local Pose = loadModule("Pose", "KeeperPose.luau")
local sourceGeometry = serde.decode("json", fs.readFile(root .. "throw-geometry.json"))
local function same(a, b)
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for key, value in pairs(a) do
		if not same(value, b[key]) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end
assert(same(sourceGeometry, modules.Geometry), "Articulated geometry differs from render JSON")
local names, vertices, triangles = {}, 0, 0
for _, section in ipairs(sourceGeometry) do
	names[section.rig_part] = true
	vertices += #section.vertices
	triangles += #section.triangles
	for _, tri in ipairs(section.triangles) do
		for _, index in ipairs(tri) do
			assert(index >= 0 and index < #section.vertices, "triangle index bounds")
		end
	end
end
local count = 0
for _ in pairs(names) do
	count += 1
end
assert(count == 15, "visual rig part count; pelvis is the additional virtual joint")
print(
	"PASS articulated JSON parity; 15 visual parts / "
		.. #sourceGeometry
		.. " material sections / "
		.. vertices
		.. " vertices / "
		.. triangles
		.. " triangles"
)
local Config, Layout = require("./GreyboxConfig"), require("./Layout")
local attributes = {}
local guard = setmetatable({
	CFrame = C.new(0, 5.5, 0),
	Size = V.new(4, 11, 4),
	SetAttribute = function(_, key, value)
		attributes[key] = value
	end,
}, {
	__index = function(self, key)
		if key == "Position" then
			return self.CFrame.Position
		end
	end,
})
local model = roblox.Instance.new("Model")
local a = {
	guardian = guard,
	arm = roblox.Instance.new("Part"),
	model = model,
	warning = {},
	origin = V.zero,
	mode = "Chase",
	untilTime = 0,
	nextThrow = 0,
	nextPath = 0,
	points = {},
	index = 1,
	patrol = 1,
	chaseTicks = 0,
	chaseDistance = 0,
	throws = 0,
	impacts = 0,
	keeper = true,
	targetSince = 0,
}
local actor = {}
a.target = actor
local actorRoot = { Position = V.new(0, 3, -24), AssemblyLinearVelocity = V.zero }
local world = {
	Raycast = function(_, origin, direction)
		if direction.Y == -70 then
			return {
				Position = V.new(origin.X, 0, origin.Z),
				Normal = V.yAxis,
				Instance = {
					GetAttribute = function()
						return "Floor"
					end,
				},
			}
		end
		return nil
	end,
	Spherecast = function()
		return nil
	end,
	Blockcast = function()
		return nil
	end,
}
local Kit = luau.load(fs.readFile("KeeperAttacks.luau"), {
	environment = {
		Instance = roblox.Instance,
		Vector3 = V,
		CFrame = C,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
		workspace = world,
	},
})()
local arena = luau.load(fs.readFile("Arena.luau"), {
	environment = {
		game = {
			GetService = function()
				return {
					WaitForChild = function(_, name)
						if name == "MeadowKeeper" then
							return {
								FindFirstChild = function()
									return nil
								end,
								WaitForChild = function(_, child)
									return child == "Attacks" and "KeeperAttacks" or "KeeperPose"
								end,
							}
						end
						return name
					end,
				}
			end,
		},
		require = function(name)
			if name == "GreyboxConfig" then
				return Config
			end
			if name == "KeeperPose" then
				return Pose
			end
			if name == "KeeperAttacks" then
				return Kit
			end
			return Layout
		end,
		Instance = roblox.Instance,
		Vector3 = V,
		CFrame = C,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
		workspace = world,
		task = { spawn = function() end },
		print = function() end,
	},
})()
local hits = 0
local hitAccepted = true
local function step(now)
	arena.tick(a, 0.01, now, { [actor] = { phase = "Run", item = {}, mercy = 0 } }, function()
		return actorRoot
	end, function()
		hits += 1
		return hitAccepted
	end, function() end)
end
step(10)
assert(a.attack and #a.attack.projectiles == 0 and attributes.KeeperClip == "fan", "fan begins without projectile")
local attack = a.attack
step(10.619)
assert(#attack.projectiles == 0, "projectile before Release")
step(10.620001)
assert(
	#attack.projectiles == 3
		and (attack.projectiles[1].from - Pose.release(guard, "fan", 0.62).Position).Magnitude < 1e-5,
	"shared exact socket"
)
assert(math.abs(model:GetAttribute("KeeperReleaseAt") - 10.62) < 1e-6, "release clock")
local rock = attack.projectiles[1].part
step(10.8)
assert(attack.projectiles[1].part == rock and #attack.projectiles == 3 and a.throws == 1, "duplicate Release")
step(11.320001)
assert(
	not a.attack and hits == 1 and rock.Parent == nil and attributes.KeeperClip == "celebrate",
	"hit/cleanup/celebrate"
)
assert(math.abs(model:GetAttribute("LastImpactDelay") - 1.320001) < 1e-5, "fan impact clock")
arena.reset(a)
assert(attributes.KeeperClip == "idle" and attributes.KeeperElapsed == 0, "reset idle")
a.mode = "Chase"
a.target = actor
step(20)
local cancelled = assert(a.attack, "cancel fixture attack")
arena.reset(a)
step(20.7)
assert(#cancelled.projectiles == 0, "cancelled attack releases")
for mode, clip in pairs({
	Guard = "idle",
	Patrol = "patrol",
	Warn = "warn",
	Chase = "chase",
	Return = "return",
	Stun = "stun",
	Celebrate = "celebrate",
	DecoyTell = "warn",
	Investigate = "idle",
}) do
	arena.reset(a)
	a.mode = mode
	a.untilTime = 100
	a.nextThrow = 100
	if mode == "DecoyTell" or mode == "Investigate" then
		a.decoy = { tellEnd = mode == "DecoyTell" and 100 or 0, position = V.new(12, 0, -24) }
	end
	-- No actor acquisition during visual mapping checks.
	arena.tick(a, 0.01, 30, {}, function()
		return nil
	end, function() end, function() end)
	assert(attributes.KeeperClip == clip, mode .. " clip mapping: " .. tostring(attributes.KeeperClip))
end
print(
	"PASS real Arena: no early acorns; three on one .620 Release; exact shared socket; 1.320 fan deadline; hit/celebrate; reset cancels; state mapping"
)
arena.reset(a)
a.mode, a.target, hitAccepted = "Chase", actor, false
step(40)
assert(a.attack and not a.attack.close, "refused-hit throw fixture")
step(40.621)
step(41.321)
assert(not a.keeperCelebrateUntil, "refused hit must not celebrate")
print("PASS shield/mercy refusal cannot start celebrate")

-- Actual isolated demo's retained throw uses a 1.4-stud sphere and its
-- authored 10*t-22*t*t / 24*t illustration. Production uses Kit fan/lob,
-- whose legal envelopes are separately checked by keeper-clearance.luau.
guard.CFrame, guard.Size = C.new(0, 5.5, 0), V.new(4, 11, 4)
local pivots = {}
for _, section in ipairs(modules.Geometry) do
	pivots[section.rig_part] = V.new(table.unpack(section.pivot))
end
local minimum = math.huge
do
	do
		for i = 0, 100 do
			local seconds = .8 * i / 100
			local time = 0.620 + seconds
			local pose = modules.Animator.sample("throw", time)
			local hatFrame = modules.Kinematics.world(pose, Pose.ground(guard)).Hat
			local from = Pose.release(guard).Position
			local point = from + Pose.ground(guard):VectorToWorldSpace(V.new(0,10*seconds-22*seconds*seconds,24*seconds))
			local localPoint = hatFrame:PointToObjectSpace(point)
			for _, section in ipairs(modules.Geometry) do
				if section.rig_part == "Hat" then
					local low, high = V.new(math.huge, math.huge, math.huge), V.new(-math.huge, -math.huge, -math.huge)
					for _, vertex in ipairs(section.vertices) do
						local v = V.new(table.unpack(vertex)) - pivots.Hat
						low = low:Min(v)
						high = high:Max(v)
					end
					local nearest = V.new(
						math.clamp(localPoint.X, low.X, high.X),
						math.clamp(localPoint.Y, low.Y, high.Y),
						math.clamp(localPoint.Z, low.Z, high.Z)
					)
					minimum = math.min(minimum, (localPoint - nearest).Magnitude)
				end
			end
		end
	end
end
print("CHECK demo throw/hat conservative minimum / sphere radius:", minimum, .7)
assert(minimum > .7, "isolated demo throw arc intersects wide hat envelope")
print("PASS actual isolated demo throw arc clears animated hat with its .7-stud sphere")
if fs.isFile("guardian-greybox.rbxl") then
	local place = roblox.deserializePlace(fs.readFile("guardian-greybox.rbxl"))
	local folder = place.ReplicatedStorage:FindFirstChild("MeadowKeeper")
	assert(folder, "Keeper modules missing from built place")
	for _, name in { "Animator", "Rig", "Clips", "Geometry", "Skeleton", "Kinematics" } do
		assert(
			folder:FindFirstChild(name).Source == fs.readFile(root .. name .. ".luau"),
			"built Keeper module parity: " .. name
		)
	end
	assert(folder.Pose.Source == fs.readFile("KeeperPose.luau"), "built Pose parity")
	assert(folder.Attacks.Source == fs.readFile("KeeperAttacks.luau"), "built Attacks parity")
	assert(folder.Effects.Source == fs.readFile("KeeperEffects.luau"), "built Effects parity")
	assert(folder.Projectiles.Source == fs.readFile("KeeperProjectiles.luau"), "built Projectiles parity")
	assert(folder.FXEvent.ClassName == "RemoteEvent", "effect event mounted")
	assert(
		place.StarterPlayer.StarterPlayerScripts.MeadowKeeper.Source == fs.readFile("Keeper.client.luau"),
		"built Keeper client parity"
	)
	assert(not folder:FindFirstChild("Demo"), "isolated animation demo leaked into game")
	print(
		"PASS built Keeper: four approved modules + Pose + Attacks + Effects + Projectiles + client parity; FXEvent mounted; isolated demo excluded"
	)
end
