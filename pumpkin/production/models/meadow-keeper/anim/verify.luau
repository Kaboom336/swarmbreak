-- Offline behavioral checks execute the real module with Lune CFrames and service stubs.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local root = "models/meadow-keeper/anim/"
local function signal()
	local s = { callbacks = {} }
	function s:Connect(fn)
		table.insert(self.callbacks, fn)
		return { Disconnect = function() end }
	end
	function s:Fire(...)
		for _, fn in ipairs(self.callbacks) do
			fn(...)
		end
	end
	return s
end
local services = {
	HttpService = {
		JSONDecode = function(_, s)
			return serde.decode("json", s)
		end,
	},
	RunService = { PreSimulation = signal() },
}
local fakeGame = {
	GetService = function(_, n)
		return assert(services[n])
	end,
}
local fakeInstance = {
	new = function()
		local e = signal()
		return {
			Event = e,
			Fire = function(_, ...)
				e:Fire(...)
			end,
			Destroy = function() end,
		}
	end,
}
local function loadModule(name, modules)
	local fn = assert(loadstring(fs.readFile(root .. name .. ".luau"), name))
	local env = setmetatable({
		game = fakeGame,
		Instance = fakeInstance,
		CFrame = CFrame,
		Vector3 = Vector3,
		script = { Parent = { Clips = "Clips", Skeleton = "Skeleton" } },
		require = function(n)
			return modules[n]
		end,
	}, { __index = getfenv() })
	setfenv(fn, env)
	return fn()
end
for _, name in { "Animator", "Rig", "Clips", "Geometry", "Skeleton", "Kinematics", "Demo.client" } do
	assert(loadstring(fs.readFile(root .. name .. ".luau"), name), "Luau compile: " .. name)
end
local Clips = loadModule("Clips", {})
local Animator = loadModule("Animator", { Clips = Clips })
local Skeleton = loadModule("Skeleton", {})
local Kinematics = loadModule("Kinematics", { Skeleton = Skeleton })
local data = serde.decode("json", fs.readFile(root .. "clips.json"))
local function close(a, b)
	return (a.Position - b.Position).Magnitude < 1e-5
		and a.LookVector:Dot(b.LookVector) > 0.99999
		and a.UpVector:Dot(b.UpVector) > 0.99999
end
local clipCount = 0
for name, clip in pairs(data.clips) do
	clipCount += 1
	assert(clip.frames[1].t == 0 and clip.frames[#clip.frames].t == clip.duration)
	for i, frame in ipairs(clip.frames) do
		if i > 1 then
			assert(frame.t > clip.frames[i - 1].t)
		end
		local pose = Animator.sample(name, frame.t)
		for _, joint in ipairs(data.jointOrder) do
			local v = frame.pose[joint]
			assert(#v == 6)
			local expected = CFrame.new(v[1], v[2], v[3])
				* CFrame.Angles(math.rad(v[4]), math.rad(v[5]), math.rad(v[6]))
			assert(close(pose[joint], expected), name .. " keyframe mismatch")
		end
	end
	if clip.loop then
		local first, last = Animator.sample(name, 0), Animator.sample(name, clip.duration)
		for _, joint in ipairs(data.jointOrder) do
			assert(close(first[joint], last[joint]), name .. " loop seam")
		end
	end
end
assert(clipCount == 12)
local rig = { motors = {}, rest = {}, root = { CFrame = CFrame.identity } }
for _, joint in ipairs(data.jointOrder) do
	rig.motors[joint] = {}
	rig.rest[joint] = CFrame.identity
end
function rig:ReleaseCFrame(pose, name)
	return Kinematics.socket(pose, self.root.CFrame, name or "throw")
end
local anim = Animator.new(rig)
local releases, completions = 0, 0
anim.Completed.Event:Connect(function()
	completions += 1
end)
anim.Marker.Event:Connect(function(marker, name, t, late, snap)
	if marker == "Release" then
		releases += 1
		assert(name == "throw" and t == 0.62 and late >= 0)
		assert(close(snap.releaseCFrame, rig:ReleaseCFrame(Animator.sample("throw", 0.62))), "Release snapshot")
	end
end)
anim:Play("throw")
anim:Step(0.61)
assert(releases == 0)
anim:Step(0.09)
assert(releases == 1)
anim:Step(2)
assert(releases == 1 and completions == 1 and anim.stopped)
anim:Play("throw")
anim:Stop()
anim:Step(2)
assert(releases == 1)
anim:Play("throw", { speed = 2 })
anim:Step(0.31)
assert(releases == 2)
anim:Step(1)
assert(completions == 2)
anim:Play("patrol")
anim:Step(4.48)
assert(not anim.stopped and completions == 2)
anim:Play("idle")
anim:Step(0.04)
assert(anim.name == "idle")
anim:Play("throw", {
	onMarker = function(marker)
		if marker == "Release" then
			anim:Play("idle")
		end
	end,
})
anim:Step(0.8)
assert(anim.name == "idle", "Reentrant transition")
anim:Destroy()
for _, name in { "lob", "fan", "throw" } do
	local player = Animator.new(rig)
	local events = 0
	player:Play(name, {
		onMarker = function(marker, clip, t, late, snapshot)
			if marker == "Release" then
				events += 1
				assert(t == 0.62 and clip == name)
				assert(
					close(snapshot.releaseCFrame, Kinematics.socket(Animator.sample(name, t), rig.root.CFrame, name))
				)
			end
		end,
	})
	player:Step(0.619)
	assert(events == 0)
	player:Step(0.4)
	assert(events == 1)
	player:Step(2)
	assert(events == 1 and player.stopped)
	player:Destroy()
end
local package = roblox.deserializeModel(fs.readFile(root .. "MeadowKeeperAnimations.rbxmx"))[1]
local function normalized(source)
	return (string.gsub(source, "\r\n", "\n"))
end
assert(package.Name == "MeadowKeeperAnimations")
assert(package:FindFirstChild("Demo").RunContext.Name == "Client")
for _, name in { "Animator", "Rig", "Clips", "Geometry", "Skeleton", "Kinematics" } do
	assert(
		normalized(package:FindFirstChild(name).Source) == normalized(fs.readFile(root .. name .. ".luau")),
		"Stale packaged module: " .. name
	)
end
assert(normalized(package:FindFirstChild("Demo").Source) == normalized(fs.readFile(root .. "Demo.client.luau")))
print(
	"PASS: 12 clips, every authored CFrame, loop seams, real driver release/hitch/speed/cancel/completion/transition; 7 Luau sources compile"
)
print("PASS: XML package parses; current sources match; demo runs in Client context")
print("UNKNOWN: Studio geometry/render/physics and real-device feel")
