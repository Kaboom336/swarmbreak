local fs, rb, luau, serde = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/serde")
local policies = require("./meadow-v4/PolicyTests")
local ravine, tunnel = require("./meadow-v4/RavinePolicy"), require("./meadow-v4/TunnelPolicy")
print("PASS " .. policies.RavineTest(ravine))
print("PASS " .. policies.TunnelTest(ravine, tunnel))
local core = require("./core/Tests")
print(core.run(require("./core/Config"), require("./core/Domain"), require("./core/Profiles"),
	require("../slice-v2/prototype/LootRules"), require("../slice-v2/prototype/GreyboxConfig"), require("./core/Service"), require("./core/MockStore")))
-- Exercise coordinator against fake asynchronous attributes, failures and timeout clock.
local source = fs.readFile("slice-v2/prototype/StudioPass.luau")
local function scenario(failed, expiries, reject, timeout)
	local clock, resets, starts, cancelled = 0, 0, {}, false
	local listeners, attrs = {}, {GreyboxLoopTestExpiryCount = expiries or 0, GreyboxLoopTestPassCount = 3}
	local server = {}
	function server:GetAttribute(k) return attrs[k] end
	function server:GetAttributeChangedSignal(k)
		listeners[k] = listeners[k] or {}
		return {Connect = function(_, fn) table.insert(listeners[k], fn) end}
	end
	function server:SetAttribute(k, v)
		local changed = attrs[k] ~= v
		attrs[k] = v
		if changed then for _, fn in listeners[k] or {} do fn() end end
	end
	for _, name in {"GreyboxSelfTest", "CoreLoopTest"} do
		server:GetAttributeChangedSignal(name):Connect(function()
			if attrs[name] then
				server:SetAttribute(name .. "Result", "PASS: mock")
				server:SetAttribute(name .. "Success", true)
				server:SetAttribute(name, false)
			end
		end)
	end
	local replicated = {MeadowV4 = {PolicyTests = policies, RavinePolicy = ravine, TunnelPolicy = tunnel}}
	local services = {ServerScriptService = server, ReplicatedStorage = replicated,
		HttpService = {JSONEncode = function(_, v) return serde.encode("json", v) end},
		RunService = {Heartbeat = {Connect = function() end}}}
	local chunk = luau.load(source, {environment = {
		game = {GetService = function(_, k) return services[k] end},
		Instance = {new = function() return {SetAttribute = function(self, k, v) self[k] = v end, GetAttribute = function(self, k) return self[k] end} end},
		require = function(v) return v end,
		os = {clock = function() return clock end},
		task = {spawn = function(fn) fn() end, wait = function(dt) clock += dt end, cancel = function() cancelled = true end},
		print = function() end,
	}})
	chunk().attach({
		prepare = function() assert(not reject, "fresh session required") end,
		reset = function() resets += 1 end,
		keeperState = function() return "Guard" end,
		start = function(name)
			table.insert(starts, name)
			if timeout == name then return coroutine.create(function() end) end
			server:SetAttribute(name .. "Success", failed ~= name)
			server:SetAttribute(name .. "Result", failed == name and "FAIL: injected" or "PASS: mock")
		end,
	})
	server:SetAttribute("StudioPassAll", true)
	local result = serde.decode("json", attrs.StudioPassResult)
	assert(attrs.StudioPassAll == false and attrs.StudioPassBusy == false, "flags clear")
	if reject then assert(result.status == "FAIL" and #result.tests == 0 and resets == 0, "preflight refuses safely")
	else
		assert(#result.tests == 8 and resets == 9 and #starts == 4, "eight sequential tests, nine resets")
		assert(starts[1] == "DropSampleTest" and starts[2] == "GreyboxLoopTest" and starts[3] == "GreyboxPvpTest" and starts[4] == "GreyboxTrapTest", "live sample before legacy order")
		assert(result.tests[1].name == "GreyboxSelfTest" and result.tests[8].name == "TunnelTest", "full order")
		assert(result.status == ((failed or expiries == 3 or timeout) and "FAIL" or "PASS"), "aggregate result")
		for _, row in result.tests do assert(type(row.seconds) == "number" and row.seconds >= 0, "timings recorded") end
	end
	if timeout then assert(cancelled, "timeout cancels active thread") end
	-- Repeat invocation must replace summary and never retain the previous run rows.
	server:SetAttribute("StudioPassAll", true)
	assert(#serde.decode("json", attrs.StudioPassResult).tests == (reject and 0 or 8), "repeat replaces rows")
end
scenario()
scenario("GreyboxPvpTest")
scenario("DropSampleTest")
scenario(nil, 3)
scenario(nil, nil, true)
scenario(nil, nil, false, "GreyboxPvpTest")
print("PASS coordinator order/reset/timing, failure continuation, all-expiry refusal, preflight, timeout/cancel and repeat")
-- Execute the actual production reset body, not just a mock reset counter.
local serverSource = fs.readFile("slice-v2/prototype/Greybox.server.luau")
local resetStart = assert(serverSource:find("\tlocal baseline\n", 1, true), "reset source start")
local resetEnd = assert(serverSource:find('\n\trequire(SSS:WaitForChild("StudioPass"))', resetStart, true), "reset source end")
local actor = {Parent = true, UserId = 1, attrs = {GreyboxReady = true}}
function actor:GetAttribute(k) return self.attrs[k] end
function actor:SetAttribute(k, v) self.attrs[k] = v end
local state = {phase = "Home", slot = 1, shieldUsed = false, counter = 0}
local states = {[actor] = state}
local pens = {{count = 0, occupied = {}}}
local arena = {guardian = {}, tunnel = {disconnect = function() end}}
local rules, retired, detached, attached = {items = {}, serial = 0}, 0, false, false
arena.tunnel.disconnect = function() detached = true end
arena.attachTunnel = function() attached = true end
local rootPart = {SetNetworkOwnershipAuto = function() end}
local hum = {Health = 100, Move = function() end}
local env = {
	RunService = {IsStudio = function() return true end},
	SSS = {GetAttribute = function() return false end, SetAttribute = function() end},
	core = {profiles = {store = {volatile = true}}, data = function() return {pets = {}} end},
	Players = {GetPlayers = function() return {actor} end}, states = states, pens = pens,
	arena = arena, rules = rules, traps = {}, lastAction = {[actor] = 10},
	Arena = {reset = function() end, position = function(_, x, y, z) return rb.Vector3.new(x,y,z) end},
	Traps = {clearIsland = function() end, remove = function() end},
	Rules = {spawn = function(r) r.active = {state = "Nest"}; return r.active end},
	visual = function(item) if item.state == "Retired" then retired += 1 end end,
	root = function() return rootPart, hum end, home = function() end, refreshLoot = function() end,
	conservation = function() end, nestPosition = function() return rb.Vector3.zero end,
	Config = {GuardianGuardOffset = {x = 0, y = 48, z = 96}},
	Vector3 = rb.Vector3, CFrame = rb.CFrame,
}
local fixture = luau.load(serverSource:sub(resetStart, resetEnd - 1) .. "\nreturn {prepare=preparePass,reset=resetPass}", {environment = env})()
fixture.prepare()
state.phase, state.item, state.shieldUsed, state.counter = "Run", {}, true, 99
rules.items = {{state = "Carried", holder = actor}, {state = "Placed"}}
pens[1].count, pens[1].occupied = 3, {{}}
arena.idle, arena.hasEntrants = true, true
fixture.reset()
assert(state.phase == "Home" and state.item == nil and not state.shieldUsed and state.counter == 0, "actual actor restored")
assert(pens[1].count == 0 and #pens[1].occupied == 0 and retired == 2, "actual fixtures retired")
assert(not arena.idle and not arena.hasEntrants and detached and attached, "actual map reuse and tunnel lifecycle")
assert(rootPart.AssemblyLinearVelocity == rb.Vector3.zero and rules.active.state == "Nest", "actual physical/loot reset")
env.core.profiles.store.volatile = false
assert(not pcall(fixture.prepare), "real store refused even with false attribute")
print("PASS actual production reset: actor/shield/plots/loot/velocity, map reuse, tunnel reattach and real-store refusal")
if require("@lune/process").args[1] == "coordinator-only" then return end
local old = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.pre-studioprep.rbxl"))
local new = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.rbxl"))
local allowed = {
	["ServerScriptService.Greybox"] = true, ["ServerScriptService.StudioPass"] = true,
	["ReplicatedStorage.MeadowV4.PolicyTests"] = true,
	["StarterPlayer.StarterPlayerScripts.StudioPass"] = true,
}
local oldSources, newSources = {}, {}
local function inventory(place, out)
	for _, node in place:GetDescendants() do
		if node:IsA("LuaSourceContainer") then
			out[node:GetFullName()] = node.Source
			for level = 0, 2 do luau.compile(node.Source, {optimizationLevel = level}) end
		end
	end
end
inventory(old, oldSources); inventory(new, newSources)
local preserved = 0
for path, bytes in oldSources do
	if not allowed[path] then assert(newSources[path] == bytes, "protected Source " .. path); preserved += 1 end
end
for path in newSources do assert(oldSources[path] or allowed[path], "unexpected new source " .. path) end
for _, name in {"Workspace", "Lighting"} do
	assert(rb.serializeModel({old[name]}) == rb.serializeModel({new[name]}), "protected hierarchy/properties " .. name)
end
for _, name in {"GreyboxLoopTestRunner", "GreyboxTrapTestRunner", "CoreLoopTestRunner", "GreyboxArena"} do
	assert(old.ServerScriptService[name].Source == new.ServerScriptService[name].Source, "runner/AI preservation")
end
assert(new.ServerScriptService.Greybox.Source:gsub("\r\n", "\n") == fs.readFile("slice-v2/prototype/Greybox.server.luau"):gsub("\r\n", "\n"), "Greybox mount parity")
assert(new.ServerScriptService.StudioPass.Source == source, "coordinator mount parity")
assert(new.StarterPlayer.StarterPlayerScripts.StudioPass.Source == fs.readFile("slice-v2/prototype/StudioPass.client.luau"), "client mount parity")
assert(new.ReplicatedStorage.MeadowV4.PolicyTests.Source == fs.readFile("prototype/meadow-v4/PolicyTests.luau"), "policy mount parity")
assert(fs.readFile("prototype/guardian-greybox.rbxl") == fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"), "canonical byte equality")
print("PASS " .. preserved .. " protected sources, scene/lighting byte parity, four mounts, all O0/O1/O2 and canonical equality")
local scene = serde.decode("json", fs.readFile("prototype/meadow-v4/scene.json"))
local function count(t) local n = 0; for _ in t or {} do n += 1 end; return n end
print("CHECK cluster metadata: r5=" .. count(scene.r5.clusters) .. "; r6=" .. count(scene.r6 and scene.r6.clusters) .. "; Round6 reference=57; visual count UNKNOWN")
print("Studio runtime / screenshots / durable QA reconnect UNKNOWN")
