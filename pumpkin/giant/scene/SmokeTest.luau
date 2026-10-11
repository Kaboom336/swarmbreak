-- Studio PLAY, SERVER only. Import this file as a ModuleScript; require returns the report.
-- Uses the first player. DESTRUCTIVE: Admin reset saves a fresh profile; Patch has no snapshot/
-- restore hook. Use a disposable Studio tester. No gameplay scripts are changed.
-- Roblox cannot FireServer from a server or enumerate Triggered connections. A temporary client
-- drives the actual remotes/prompts. If require lacks Source-write permission, Claude should use
-- execute_luau's Studio edit privilege to install that driver BEFORE requiring this module:
--   local m = game.ServerStorage:FindFirstChild("SmokeTest")
--   local p = game.Players:GetPlayers()[1]
--   local gui = Instance.new("ScreenGui")
--   gui.Name, gui.ResetOnSpawn = "PumpkinSmokeHarness", false
--   gui.Parent = p:WaitForChild("PlayerGui")
--   local d = Instance.new("LocalScript")
--   d.Name = "PumpkinSmokeDriver"
--   d.Source = assert(m.Source:match("local CLIENT_SOURCE = %[%[(.-)%]%]"))
--   d.Parent = gui
--   return require(m)
-- Allow several minutes: the King has a 300-second natural timeout and no debug end hook.
-- If execute_luau has a short timeout, replace the final line above with:
--   m:SetAttribute("SmokeReport", "RUNNING")
--   task.spawn(function()
--       local ok, report = pcall(require, m)
--       m:SetAttribute("SmokeReport", ok and report or "FAIL runner: " .. tostring(report))
--   end)
-- Then poll m:GetAttribute("SmokeReport") with execute_luau; the module still returns a string.
-- Re-import/clone the ModuleScript for another run (require caches its returned string).

local CLIENT_SOURCE = [[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local bridge = RS:WaitForChild("PumpkinSmokeBridge", 60)
if not bridge then script:Destroy(); return end
local bus = bridge:WaitForChild("Command", 10)
if not bus then script:Destroy(); return end
local remotes = RS:WaitForChild("PatchRemotes", 10)
if not remotes then script:Destroy(); return end
local listening = false
local hits, pops, reward = 0, 0, 0
local connections = {}
table.insert(connections, remotes.WildHit.OnClientEvent:Connect(function(who)
    if listening and who == player then hits += 1 end
end))
table.insert(connections, remotes.WildPopped.OnClientEvent:Connect(function(_, _, who, candy)
    if listening and who == player then pops += 1; reward += candy or 0 end
end))
table.insert(connections, bus.OnClientEvent:Connect(function(id, kind, target, args)
    local result = table.pack(pcall(function()
        if kind == "invoke" then
            return target:InvokeServer(table.unpack(args))
        elseif kind == "prompt" then
            assert(target and target:IsA("ProximityPrompt"), "prompt missing on client")
            -- Same input API used by custom prompt UIs; the engine fires Triggered on server.
            target:InputHoldBegin()
            task.wait(math.max(0.15, target.HoldDuration + 0.1))
            target:InputHoldEnd()
            return true
        elseif kind == "swing" then
            local character = assert(player.Character, "character missing")
            local humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "humanoid missing")
            local backpack = player:FindFirstChildOfClass("Backpack")
            local tool = character:FindFirstChild("Scythe") or backpack and backpack:FindFirstChild("Scythe")
            assert(tool and tool:IsA("Tool"), "Scythe missing")
            if tool.Parent ~= character then humanoid:EquipTool(tool); task.wait(0.1) end
            hits, pops, reward = 0, 0, 0
            listening = true
            remotes.Bonk:FireServer() -- Swing and KingHit are server -> client notifications.
            task.wait(0.35)
            listening = false
            return { hits = hits, pops = pops, reward = reward }
        elseif kind == "stop" then
            for _, connection in connections do connection:Disconnect() end
            task.defer(function() script:Destroy() end)
            return true
        end
        error("unknown smoke command: " .. tostring(kind))
    end))
    if bridge.Parent then bus:FireServer(id, table.unpack(result, 1, result.n)) end
end))
bus:FireServer(0, true, "ready")
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
if not RunService:IsStudio() or not RunService:IsRunning() or not RunService:IsServer() then
	return "FAIL context: require SmokeTest in Studio PLAY on SERVER; no actions taken"
end
if RS:FindFirstChild("PumpkinSmokeBridge") then
	return "FAIL context: another smoke run/bridge exists; no actions taken"
end

local started = os.clock()
local lines, logs = {}, {}
local failures = 0
local logConnection = LogService.MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError or kind == Enum.MessageType.MessageWarning then
		table.insert(logs, { at = os.clock() - started, kind = kind.Name, message = message })
	end
end)
local function oneLine(value)
	return tostring(value):gsub("[\r\n]+", " | ")
end
local function check(label, callback)
	local time = os.clock()
	local ok, passed, reason = pcall(callback)
	if not ok then
		reason, passed = passed, false
	end
	if passed ~= true then
		failures += 1
	end
	table.insert(
		lines,
		string.format(
			"%s %s: %s (%.1fs)",
			passed == true and "PASS" or "FAIL",
			label,
			oneLine(reason),
			os.clock() - time
		)
	)
end
local function waitUntil(seconds, predicate)
	local deadline = os.clock() + math.max(0, seconds)
	repeat
		local value = predicate()
		if value then
			return value
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return predicate()
end

local player, Config, garden, remotes, debugHook, state
local bridge, bus, driver, harness, busConnection
local ready, replies, serial = false, {}, 0
local resetAttempted, resetDone, kingStarted = false, false, false
local original, placed, discoveredPet
local function candy()
	local stats = player and player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Candy")
	assert(value and (value:IsA("IntValue") or value:IsA("NumberValue")), "Candy value missing")
	return value.Value
end
local function root()
	local character = player and player.Character
	local part = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	assert(part and humanoid and humanoid.Health > 0, "tester needs a living character")
	return character, part
end
local function move(position, facing)
	local character, part = root()
	character:PivotTo(CFrame.lookAt(position, position + (facing or Vector3.new(0, 0, -1))))
	part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	task.wait(0.25) -- allow the player's client to receive the new position before prompt input
end
local function owns(id)
	return table.find(string.split(player:GetAttribute("Zones") or "", ","), id) ~= nil
end
local function request(kind, target, args, timeout)
	assert(
		ready and bus and bus.Parent,
		"client driver unavailable; use execute_luau bootstrap in file header"
	)
	serial += 1
	local id = serial
	bus:FireClient(player, id, kind, target, args or {})
	local result = waitUntil(timeout or 12, function()
		return replies[id]
	end)
	replies[id] = nil
	assert(result, "client command timed out: " .. kind)
	assert(result[1], "client command failed: " .. tostring(result[2]))
	return table.unpack(result, 2, result.n)
end
local function invoke(name, ...)
	local remote = remotes and remotes:FindFirstChild(name)
	assert(remote and remote:IsA("RemoteFunction"), "missing RemoteFunction " .. name)
	return request("invoke", remote, table.pack(...), name == "Admin" and 35 or 12)
end
local function debugCall(action, amount, typeId)
	assert(debugHook and debugHook:IsA("BindableFunction"), "ServerStorage.PatchDebug missing")
	return debugHook:Invoke(action, player, amount, typeId)
end
local function pen()
	local patches = garden and garden:FindFirstChild("Patches")
	for _, patch in patches and patches:GetChildren() or {} do
		if patch:GetAttribute("Owner") == player.UserId then
			return patch
		end
	end
	error("owner's pen missing")
end
local function penPumpkin()
	for _, item in pen():GetDescendants() do
		if
			item:IsA("BasePart")
			and item:GetAttribute("Owner") == player.UserId
			and item:GetAttribute("Seed")
		then
			return item
		end
	end
	return nil
end
local function wilds()
	local result = {}
	for _, item in garden:GetDescendants() do
		if
			item:IsA("BasePart")
			and item:GetAttribute("Wild") == true
			and item:GetAttribute("Zone") == "Zone1"
		then
			table.insert(result, item)
		end
	end
	return result
end
local function swingDelay()
	-- Wait beyond both cooldown and the teleport-farm window; never bypass rate limiting.
	return math.max(Config.BonkCooldown, Config.Farm.firstSwingSeconds, Config.BonkTeleportWindow)
		+ 0.15
end

check("1 loaded/save/candy", function()
	player = waitUntil(20, function()
		return Players:GetPlayers()[1]
	end)
	assert(player, "no player after 20s")
	assert(
		waitUntil(30, function()
			return player:GetAttribute("Loaded") == true
				and player.Character
				and player.Character:FindFirstChild("HumanoidRootPart")
		end),
		"Loaded/character timeout after 30s"
	)
	Config = require(assert(RS:FindFirstChild("PatchConfig"), "PatchConfig missing"))
	garden = assert(workspace:FindFirstChild("Garden"), "Garden missing")
	remotes = assert(RS:FindFirstChild("PatchRemotes"), "PatchRemotes missing")
	state = assert(RS:FindFirstChild("PatchState"), "PatchState missing")
	debugHook = SS:FindFirstChild("PatchDebug")
	local _, part = root()
	original = {
		candy = candy(),
		zones = player:GetAttribute("Zones"),
		carry = player:GetAttribute("Carry"),
		position = part.CFrame,
	}
	return true,
		string.format(
			"%s Loaded=true candy=%s zones=%s; Loaded is applyData success, raw save private",
			player.Name,
			original.candy,
			tostring(original.zones)
		)
end)

check("driver", function()
	assert(player and remotes, "loading prerequisite failed")
	bridge = Instance.new("Folder")
	bridge.Name, bridge.Parent = "PumpkinSmokeBridge", RS
	bus = Instance.new("RemoteEvent")
	bus.Name, bus.Parent = "Command", bridge
	busConnection = bus.OnServerEvent:Connect(function(who, id, ...)
		if who ~= player or type(id) ~= "number" then
			return
		end
		if id == 0 then
			ready = true
		elseif id == serial then
			replies[id] = table.pack(...)
		end
	end)
	local gui = assert(player:FindFirstChild("PlayerGui"), "PlayerGui unavailable")
	harness = gui:FindFirstChild("PumpkinSmokeHarness")
	if not harness then
		harness = Instance.new("ScreenGui")
		harness.Name, harness.ResetOnSpawn = "PumpkinSmokeHarness", false
		harness.Parent = gui
	end
	assert(
		harness:IsA("ScreenGui") and not harness.ResetOnSpawn,
		"driver ScreenGui must survive Admin reset"
	)
	driver = harness:FindFirstChild("PumpkinSmokeDriver")
	if not driver then
		driver = Instance.new("LocalScript")
		driver.Name = "PumpkinSmokeDriver"
		local ok, err = pcall(function()
			driver.Source = CLIENT_SOURCE
		end)
		assert(
			ok,
			"Source-write denied; preinstall driver with execute_luau bootstrap: " .. tostring(err)
		)
		driver.Parent = harness
	end
	assert(
		waitUntil(15, function()
			return ready
		end),
		"client driver did not handshake in 15s"
	)
	return true,
		"temporary client calls real Bonk/Admin/claims and prompt input; no connection introspection"
end)

check("2 fresh reset", function()
	assert(ready and original, "driver/loading prerequisite failed; no reset attempted")
	assert(state:GetAttribute("KingActive") ~= true, "existing King fight; reset refused")
	resetAttempted = true
	local ok = debugHook and debugCall("reset") -- current PatchDebug returns nil: reset is Admin-only
	local reason = "PatchDebug reset"
	if ok ~= true then
		ok, reason = invoke("Admin", "reset")
	end
	assert(ok == true, "reset rejected: " .. tostring(reason))
	resetDone = true
	assert(
		waitUntil(20, function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			return humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart")
		end),
		"reset respawn timeout"
	)
	local fresh = candy() == Config.StartCandy
		and (player:GetAttribute("Carry") or -1) == 0
		and player:GetAttribute("Zones") == "Zone1"
		and penPumpkin() == nil
	return fresh,
		string.format(
			"%s candy=%s expected=%s carry=%s zones=%s penFilled=%s; original candy=%s zones=%s",
			tostring(reason),
			candy(),
			Config.StartCandy,
			tostring(player:GetAttribute("Carry")),
			tostring(player:GetAttribute("Zones")),
			tostring(player:GetAttribute("PenFilled")),
			original.candy,
			tostring(original.zones)
		)
end)

check("2 run candy", function()
	assert(resetDone, "fresh reset prerequisite failed")
	local budget = 0
	for i = 2, 7 do
		budget += Config.Zones["Zone" .. i].cost or 0
	end
	local before = candy()
	assert(debugCall("candy", budget + 10000) == true, "PatchDebug candy rejected")
	return candy() >= before + budget + 10000,
		string.format(
			"before=%s after=%s grant=%s gateBudget=%s",
			before,
			candy(),
			budget + 10000,
			budget
		)
end)

check("3 Zone1 nest steal", function()
	assert(resetDone, "fresh reset prerequisite failed")
	local zones = assert(garden:FindFirstChild("Zones"), "Zones missing")
	local zone = assert(zones:FindFirstChild("Zone1"), "Zone1 missing")
	local prompt = waitUntil(10, function()
		return zone:FindFirstChild("StealPrompt", true)
	end)
	assert(prompt and prompt.Parent:IsA("BasePart"), "Zone1 StealPrompt/nest pumpkin missing")
	local pumpkin = prompt.Parent
	local before = player:GetAttribute("Carry") or 0
	local at = pumpkin.Position + Vector3.new(0, 3, 5)
	move(at, Vector3.new(0, 0, -1))
	request("prompt", prompt)
	local increased = waitUntil(3, function()
		return (player:GetAttribute("Carry") or 0) > before
	end)
	return increased == true,
		string.format(
			"real StealPrompt Carry=%s->%s seed=%s parent=%s",
			before,
			tostring(player:GetAttribute("Carry")),
			tostring(pumpkin:GetAttribute("Seed")),
			pumpkin.Parent and pumpkin.Parent:GetFullName() or "destroyed"
		)
end)

check("4 automatic delivery/hatch/pet", function()
	assert(resetDone, "fresh reset prerequisite failed")
	assert((player:GetAttribute("Carry") or 0) > 0, "no stolen pumpkin carried")
	local soil = assert(pen():FindFirstChild("Soil"), "owner pen Soil missing")
	move(soil.Position + Vector3.yAxis * (soil.Size.Y / 2 + 3))
	placed = waitUntil(8, penPumpkin)
	assert(placed, "no automatic placement in 8s; Carry=" .. tostring(player:GetAttribute("Carry")))
	local carveAt, jack = placed:GetAttribute("CarveAt"), placed:GetAttribute("Jack")
	assert(
		type(carveAt) == "number" and jack ~= true,
		"placed but no live hatch start; CarveAt="
			.. tostring(carveAt)
			.. " Jack="
			.. tostring(jack)
	)
	local remaining = math.max(0, carveAt - workspace:GetServerTimeNow())
	assert(
		remaining
			<= math.max(Config.CarveSeconds, Config.CarveFastSeconds, Config.CarveNewSeconds)
				+ 5,
		"invalid hatch deadline=" .. remaining
	)
	local hatched = waitUntil(remaining + 5, function()
		return placed.Parent
			and placed:GetAttribute("Jack") == true
			and placed:FindFirstChild("PetLook")
	end)
	local seedId = placed:GetAttribute("Seed")
	for _, seed in Config.Seeds do
		if seed.id == seedId then
			discoveredPet = seed.pet
		end
	end
	return hatched ~= nil
		and hatched ~= false
		and player:GetAttribute("Carry") == 0
		and placed:IsDescendantOf(pen()),
		string.format(
			"Carry=%s CarveAt=%.2f waited<=%.1fs Jack=%s PetLook=%s pet=%s penFilled=%s",
			tostring(player:GetAttribute("Carry")),
			carveAt,
			remaining + 5,
			tostring(placed:GetAttribute("Jack")),
			tostring(placed:FindFirstChild("PetLook") ~= nil),
			tostring(discoveredPet),
			tostring(player:GetAttribute("PenFilled"))
		)
end)

check("5 scythe multi-hit/candy", function()
	assert(resetDone, "fresh reset prerequisite failed")
	assert(
		(player:GetAttribute("Carry") or 0) == 0,
		"Bonk blocked by Carry=" .. tostring(player:GetAttribute("Carry"))
	)
	debugCall("spawnwild")
	local pumpkins = wilds()
	local bestAt, bestLook, bestCount = nil, nil, 0
	-- Search actual field geometry. Do not move pumpkins, fake HP, or fabricate extra targets.
	for _, candidate in pumpkins do
		for angle = 0, 330, 30 do
			local look = Vector3.new(math.cos(math.rad(angle)), 0, math.sin(math.rad(angle)))
			local at = candidate.Position - look * (Config.Farm.arcRange * 0.45) + Vector3.yAxis * 2
			local count = 0
			for _, item in pumpkins do
				local delta = item.Position - at
				local flat = delta * Vector3.new(1, 0, 1)
				if
					math.abs(delta.Y) < 12
					and flat.Magnitude <= Config.Farm.arcRange
					and (
						flat.Magnitude < 0.1
						or flat.Unit:Dot(look) >= math.cos(math.rad(Config.Farm.arcDegrees / 2))
					)
				then
					count += 1
				end
			end
			if count > bestCount then
				bestAt, bestLook, bestCount = at, look, count
			end
		end
	end
	assert(
		bestAt and bestCount >= 2,
		"field has no multi-hit arc; pumpkins=" .. #pumpkins .. " bestTargets=" .. bestCount
	)
	move(bestAt, bestLook)
	task.wait(swingDelay())
	local before, maxChanged, maxHits, pops, reward, swings = candy(), 0, 0, 0, 0, 0
	local deadline = os.clock() + 45
	repeat
		local hp = {}
		for _, item in wilds() do
			hp[item] = item:GetAttribute("Hp")
		end
		local observed = request("swing")
		swings += 1
		local changed = 0
		for item, old in hp do
			if not item.Parent or (item:GetAttribute("Hp") or old) < old then
				changed += 1
			end
		end
		maxChanged = math.max(maxChanged, changed)
		maxHits = math.max(maxHits, observed.hits)
		pops += observed.pops
		reward += observed.reward
		if maxChanged > 1 and maxHits > 1 and pops > 0 and reward > 0 and candy() > before then
			break
		end
		task.wait(swingDelay())
	until os.clock() >= deadline
	return maxChanged > 1 and maxHits > 1 and pops > 0 and reward > 0 and candy() > before,
		string.format(
			"Bonk swings=%d targets=%d maxHPChanges/swing=%d maxWildHit/swing=%d pops=%d popCandy=%s candy=%s->%s (income may also accrue)",
			swings,
			bestCount,
			maxChanged,
			maxHits,
			pops,
			reward,
			before,
			candy()
		)
end)

for i = 2, 7 do
	local id = "Zone" .. i
	check("6 " .. id .. " gate", function()
		assert(resetDone, "fresh reset prerequisite failed")
		local zone = assert(garden.Zones:FindFirstChild(id), id .. " missing")
		local wall = assert(zone:FindFirstChild("GateWall"), id .. " GateWall missing")
		local prompt = assert(wall:FindFirstChild("UnlockPrompt"), id .. " UnlockPrompt missing")
		assert(not owns(id), "already owned before prompt; unlock was not tested")
		local before = candy()
		local zoneMin = zone:GetAttribute("ZMin") or Config.Zones[id].zMin
		local zoneMax = zone:GetAttribute("ZMax") or Config.Zones[id].zMax
		move(wall.Position + Vector3.new(0, 0, -5), Vector3.zAxis)
		request("prompt", prompt)
		assert(
			waitUntil(3, function()
				return owns(id)
			end),
			string.format(
				"unlock failed Zones=%s candy=%s->%s cost=%s",
				tostring(player:GetAttribute("Zones")),
				before,
				candy(),
				Config.Zones[id].cost
			)
		)
		local insideZ = math.min(
			math.max(zoneMin, zoneMax) - 3,
			math.min(zoneMin, zoneMax) + (Config.ZoneGuardInset or 2) + 6
		)
		local at = Vector3.new(Config.MapCenterX or wall.Position.X, wall.Position.Y + 2, insideZ)
		move(at, Vector3.zAxis)
		task.wait(2.2) -- guardZones runs every second; ownership must prevent the hub kick
		local _, part = root()
		local remains = part.Position.Z >= math.min(zoneMin, zoneMax)
			and part.Position.Z <= math.max(zoneMin, zoneMax)
		return remains and owns(id),
			string.format(
				"owned=%s candy=%s->%s serverZ=%.1f range=[%.1f,%.1f] guardAllows=%s wall.CanCollide=%s (client opens wall; physical client passage untested)",
				tostring(owns(id)),
				before,
				candy(),
				part.Position.Z,
				zoneMin,
				zoneMax,
				tostring(remains),
				tostring(wall.CanCollide)
			)
	end)
end

check("7 King damage/phase", function()
	assert(resetDone and ready, "reset/driver prerequisite failed")
	assert(state:GetAttribute("KingActive") ~= true, "existing fight; will not take ownership")
	assert(debugCall("king") == true, "PatchDebug king rejected")
	assert(
		waitUntil(5, function()
			return state:GetAttribute("KingActive") == true
		end),
		"King did not start (Spooky/Purge/BloodMoon may block)"
	)
	kingStarted = true
	local hpBefore, phaseBefore = state:GetAttribute("KingHp"), state:GetAttribute("KingPhase")
	local errorBefore = #logs
	local face = assert(garden.Market:FindFirstChild("KingFace"), "KingFace missing")
	local deadline = os.clock() + Config.KingSeconds + 5
	local swings, lowestHp, highestPhase = 0, hpBefore, phaseBefore
	while state:GetAttribute("KingActive") == true and os.clock() < deadline do
		local phase = state:GetAttribute("KingPhase") or 0
		highestPhase = math.max(highestPhase, phase)
		if highestPhase > phaseBefore then
			break
		end
		-- Follow the front of the moving King. Its real handler checks flat range and facing.
		local look = face.CFrame.LookVector * Vector3.new(1, 0, 1)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local plaza = garden.Market:FindFirstChild("Plaza")
		local pos = face.Position + look * (face.Size.X / 2 + 3)
		pos = Vector3.new(pos.X, plaza.Position.Y + plaza.Size.Y / 2 + 3, pos.Z)
		move(pos, -look)
		task.wait(swingDelay())
		request("swing")
		swings += 1
		lowestHp = math.min(lowestHp, state:GetAttribute("KingHp") or lowestHp)
	end
	local errors = 0
	for index = errorBefore + 1, #logs do
		if logs[index].kind == "MessageError" then
			errors += 1
		end
	end
	return lowestHp < hpBefore and highestPhase > phaseBefore and errors == 0,
		string.format(
			"Bonk swings=%d HP=%s->%s phase=%s->%s errors=%d KingDamage=%s",
			swings,
			hpBefore,
			lowestHp,
			phaseBefore,
			highestPhase,
			errors,
			tostring(player:GetAttribute("KingDamage"))
		)
end)

check("7 King end", function()
	assert(state, "PatchState unavailable")
	if not kingStarted then
		return false, "test did not start a King fight"
	end
	-- No end hook in PatchDebug. Escape the attack ring and let the real event timeout clean up.
	local soil = pen():FindFirstChild("Soil")
	move(soil.Position + Vector3.yAxis * (soil.Size.Y / 2 + 3))
	local ended = waitUntil(Config.KingSeconds + 15, function()
		return state:GetAttribute("KingActive") ~= true
			and state:GetAttribute("Phase") ~= "BloodMoon"
			and state:GetAttribute("KingHp") == nil
	end)
	return ended == true,
		string.format(
			"natural timeout (no end hook) active=%s phase=%s hp=%s",
			tostring(state:GetAttribute("KingActive")),
			tostring(state:GetAttribute("Phase")),
			tostring(state:GetAttribute("KingHp"))
		)
end)

check("8 Index claim", function()
	assert(resetDone and discoveredPet, "no pet discovered by delivery/hatch")
	local before = candy()
	local result = invoke("ClaimIndex", discoveredPet)
	assert(type(result) == "table", "ClaimIndex returned " .. tostring(result))
	local after = candy()
	local duplicate = invoke("ClaimIndex", discoveredPet)
	local flags = player:GetAttribute("IndexClaims") or ""
	local claimed = table.find(string.split(flags, ","), discoveredPet) ~= nil
	return result.count == 1
		and (result.candy or 0) > 0
		and after >= before + result.candy
		and claimed
		and duplicate.count == 0
		and duplicate.candy == 0,
		string.format(
			"pet=%s count=%s reward=%s candy=%s->%s claimFlag=%s duplicateReward=%s",
			discoveredPet,
			tostring(result.count),
			tostring(result.candy),
			before,
			after,
			tostring(claimed),
			tostring(duplicate.candy)
		)
end)

check("8 Daily claim", function()
	assert(resetDone, "fresh reset prerequisite failed")
	local status = invoke("DailyStatus")
	assert(type(status) == "table", "DailyStatus unavailable")
	local before = candy()
	local result = invoke("ClaimDaily")
	if status.ready ~= true then
		return result == false,
			string.format(
				"unavailable: ready=%s claimedThrough=%s Tutorial=%s; server rejected=%s candy=%s->%s",
				tostring(status.ready),
				tostring(status.claimedThrough),
				tostring(player:GetAttribute("Tutorial")),
				tostring(result == false),
				before,
				candy()
			)
	end
	local after = candy()
	local duplicate = invoke("ClaimDaily")
	return result == true
		and after > before
		and player:GetAttribute("DailyClaimable") == false
		and duplicate == false,
		string.format(
			"claimed=%s day=%s candy=%s->%s duplicate=%s DailyClaimable=%s",
			tostring(result),
			tostring(status.day),
			before,
			after,
			tostring(duplicate),
			tostring(player:GetAttribute("DailyClaimable"))
		)
end)

check("cleanup/save", function()
	if ready then
		request("stop", nil, nil, 3)
	end
	if driver then
		driver:Destroy()
	end
	if original and player and player.Character then
		local character, part = root()
		character:PivotTo(original.position)
		part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	end
	return true,
		resetDone
				and "SAVE RESET: original profile NOT restored; Patch exposes no snapshot/restore; Admin reset writes data"
			or resetAttempted and "reset attempted; original profile may have changed; no restore hook"
			or "no reset attempted; original profile not restored/modified by test actions"
end)
-- Unconditional resource cleanup, even if the cleanup step's character/driver operation failed.
if driver then
	driver:Destroy()
end
if harness then
	harness:Destroy()
end
if busConnection then
	busConnection:Disconnect()
end
if bridge then
	bridge:Destroy()
end
task.wait(0.3)
logConnection:Disconnect()
local errors, warnings = 0, 0
for _, entry in logs do
	if entry.kind == "MessageError" then
		errors += 1
	else
		warnings += 1
	end
end
check("9 server logs", function()
	return errors == 0 and warnings == 0,
		string.format(
			"errors=%d warnings=%d (server MessageOut during run; client output/history excluded)",
			errors,
			warnings
		)
end)
for _, entry in logs do
	table.insert(
		lines,
		string.format("LOG +%.1fs %s: %s", entry.at, entry.kind, oneLine(entry.message))
	)
end
table.insert(
	lines,
	1,
	string.format(
		"PUMPKIN SMOKE %s | failures=%d | %.1fs | tester=%s",
		failures == 0 and "PASS" or "FAIL",
		failures,
		os.clock() - started,
		player and player.Name or "none"
	)
)
table.insert(
	lines,
	resetDone and "SAVE RESET; ORIGINAL NOT RESTORED (no supported hook)."
		or resetAttempted and "SAVE STATUS UNKNOWN: reset attempted; no supported restore hook."
		or "SAVE: reset not attempted."
)
return table.concat(lines, "\n")
