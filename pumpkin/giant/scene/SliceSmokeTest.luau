-- Studio PLAY, SERVER only. Import as a ModuleScript; require returns the report.
-- Uses exactly one disposable tester. No Admin reset, grants, teleports or game-source edits.
-- Set module attribute Mode="smoke" (default) for automated walking/real actions;
-- Mode="pacing" observes a HUMAN fresh route, never sends gameplay commands.
-- CONTRACT T1/T3 must provide (PROPOSED names where briefs did not freeze spelling):
--   player.QAProfile=true, SaveNamespace="SliceQA:"..uniqueRunId, SpawnAt=server time
--     of initial living spawn; fresh isolated profile selected BEFORE load, never reset here.
--   Config.SliceMode=true. These metadata are server-authored attestations; builders must
--     actually use that namespace. A QA boolean alone cannot prove backend isolation.
--   shell.State="Carried"/"Seated"/"Waiting"/"Hatched" (T1 state names), shell.CarveAt
--     is server hatch deadline only while Waiting; Seated has no deadline/income.
--   own-pen ProximityPrompt named HatchPrompt (brief's explicit E Hatch interaction).
--   PatchRemotes.Hatched(shell, ownerId, petName, isNew) as named in slice brief;
--     existing Carved must be renamed/aliased by builders, NOT silently substituted here.
--   Retain inspected PatchRemotes: Bonk(), WildPopped(pos,seedId,who,candy,chain,index),
--     GuardianWake(model,full,who), Reveal(seedId,mutation,isNew,rate,kind,pet,weight),
--     BuyTool("WoodenScythe"); Reveal rate is candy/s, emitted even for first Common Pup.
--     Pet ID is "PumpkinPup" (display "Pumpkin Pup"), preserving inspected legacy config.
--   Retain Loaded/Carry/Income/PenHatched/Tool/Tools/Zones; leaderstats.Candy;
--     Garden/Patches (Owner), Soil, Zones/Zone1 with StealPrompt, Wild/Zone/Hp roots;
--     Zones/Zone2/GateWall/UnlockPrompt, Config.SafeLineZ, MapCenterX, Farm.arcRange,
--     BonkCooldown, BonkTeleportWindow, Farm.firstSwingSeconds, CarveNewSeconds.
--   First break=1, first Pup=Common/+1/s, no other earnings during10s income observation.
-- No additional game remotes/attributes are guessed at runtime. Missing contracts FAIL.
-- Bootstrap if Source-write is denied in require (same convention as SmokeTest):
--   local m = game.ServerStorage.SliceSmokeTest
--   local p = game.Players:GetPlayers()[1]
--   local gui = Instance.new("ScreenGui")
--   gui.Name, gui.ResetOnSpawn = "PumpkinSliceHarness", false
--   gui.Parent = p:WaitForChild("PlayerGui")
--   local d = Instance.new("LocalScript")
--   d.Name = "PumpkinSliceDriver"
--   d.Source = assert(m.Source:match("local CLIENT_SOURCE = %[%[(.-)%]%]"))
--   d.Parent = gui
--   task.spawn(function()
--       local ok, report = pcall(require, m)
--       m:SetAttribute("SmokeReport", ok and report or "FAIL runner: " .. tostring(report))
--   end)
-- Poll SmokeReport, clone/reimport module between runs (require caches).
-- Smoke may take ~20min earning150+1000 naturally at1/s; not onboarding pacing proof.
-- Pacing: install before spawn/within2s, don't act until handshake. Run human first steal,
-- explicit Hatch and income. Observer stops at120s or first income; misses fail individually.
-- This solo route does not replace T6 multiplayer/save/security/visual/gate-passage checks.

local CLIENT_SOURCE = [[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Pathfinding = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local p = Players.LocalPlayer
local bridge = RS:WaitForChild("PumpkinSliceBridge", 60)
if not bridge then script.Parent:Destroy(); return end
local bus = bridge:WaitForChild("Command", 10)
local remotes = RS:WaitForChild("PatchRemotes", 10)
if not bus or not remotes then script.Parent:Destroy(); return end
local alive, busy = true, false
local connections = {}
local function send(kind, ...)
    if alive and bridge.Parent then bus:FireServer(0, kind, ...) end
end
for _, name in {"WildPopped", "GuardianWake", "Hatched", "Reveal"} do
    local remote = remotes:FindFirstChild(name)
    if not remote or not remote:IsA("RemoteEvent") then
        send("contract", "PatchRemotes." .. name .. " RemoteEvent missing")
    else
        table.insert(connections, remote.OnClientEvent:Connect(function(...)
            send("event", name, workspace:GetServerTimeNow(), ...)
        end))
    end
end
table.insert(connections, LogService.MessageOut:Connect(function(message, kind)
    if kind == Enum.MessageType.MessageError or kind == Enum.MessageType.MessageWarning then
        send("log", kind.Name, message)
    end
end))
local function stop()
    alive = false
    for _, c in connections do c:Disconnect() end
    if bridge:GetAttribute("Mode") == "smoke" then
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then h:Move(Vector3.zero); h:MoveTo(p.Character:GetPivot().Position) end
    end
end
table.insert(connections, bridge.AncestryChanged:Connect(function()
    if not bridge.Parent then stop(); script.Parent:Destroy() end
end))
table.insert(connections, bus.OnClientEvent:Connect(function(id, kind, target, args)
    if busy then bus:FireServer(id, false, "driver busy"); return end
    busy = true
    local result = table.pack(pcall(function()
        if kind == "stop" then stop(); return true end
        assert(bridge:GetAttribute("Mode") == "smoke", "pacing refuses gameplay commands")
        if kind == "walk" then
            local character = assert(p.Character, "character missing")
            local h = assert(character:FindFirstChildOfClass("Humanoid"), "Humanoid missing")
            local root = assert(character:FindFirstChild("HumanoidRootPart"), "root missing")
            local path = Pathfinding:CreatePath({AgentRadius=2, AgentHeight=5.5, AgentCanJump=true})
            path:ComputeAsync(root.Position, target)
            assert(path.Status == Enum.PathStatus.Success, "no walking path to " .. tostring(target))
            local expires = os.clock() + args[1]
            for _, waypoint in path:GetWaypoints() do
                assert(alive and character == p.Character and h.Health > 0, "walk interrupted/death")
                if waypoint.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
                h:MoveTo(waypoint.Position)
                local leg = math.min(expires, os.clock() + 7)
                repeat RunService.Heartbeat:Wait()
                until not alive or h.Health <= 0 or os.clock() >= leg
                    or ((root.Position-waypoint.Position)*Vector3.new(1,0,1)).Magnitude < 2.5
                assert(alive and h.Health > 0 and os.clock() < leg, "walk blocked/timed out")
            end
            return root.Position
        elseif kind == "prompt" then
            assert(target and target:IsA("ProximityPrompt") and target.Enabled, "prompt absent/disabled")
            target:InputHoldBegin()
            task.wait(math.max(0.15, target.HoldDuration + 0.15))
            target:InputHoldEnd()
            return true
        elseif kind == "swing" then
            local character = assert(p.Character, "character missing")
            local h = assert(character:FindFirstChildOfClass("Humanoid"), "Humanoid missing")
            local backpack = p:FindFirstChildOfClass("Backpack")
            local tool = character:FindFirstChild("Scythe") or backpack and backpack:FindFirstChild("Scythe")
            assert(tool and tool:IsA("Tool"), "Scythe tool missing")
            if tool.Parent ~= character then h:EquipTool(tool); task.wait(0.1) end
            -- Turn physically; never write CFrame/PivotTo or change walkspeed.
            h:Move(args[1]); task.wait(0.1); h:Move(Vector3.zero)
            remotes.Bonk:FireServer()
            return true
        elseif kind == "invoke" then
            assert(target:IsA("RemoteFunction"), "expected RemoteFunction")
            return target:InvokeServer(table.unpack(args, 1, args.n or #args))
        end
        error("unknown command " .. tostring(kind))
    end))
    busy = false
    if bridge.Parent then bus:FireServer(id, table.unpack(result, 1, result.n)) end
end))
-- Repeated handshake prevents early bootstrap event loss. Self-clean even if runner dies.
task.spawn(function()
    local untilAt = os.clock() + 1500
    while alive and bridge.Parent and os.clock() < untilAt do
        send("ready"); task.wait(0.5)
    end
    stop(); script.Parent:Destroy()
end)
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
if not RunService:IsStudio() or not RunService:IsRunning() or not RunService:IsServer() then
	return "FAIL context: Studio PLAY SERVER required; no actions taken"
end
if RS:FindFirstChild("PumpkinSliceBridge") then
	return "FAIL context: another slice harness exists; no actions taken"
end
local mode = script:GetAttribute("Mode") or "smoke"
if mode ~= "smoke" and mode ~= "pacing" then
	return "FAIL context: Mode must be smoke or pacing; no actions taken"
end
local started = os.clock()
local lines, events, logs, connections, candyChanges = {}, {}, {}, {}, {}
local failures, serial = 0, 0
local ready, replies, contractErrors = false, {}, {}
local player, config, garden, remotes, pen, placed, bridge, bus, harness, driver
local function flat(v)
	return v * Vector3.new(1, 0, 1)
end
local function waitUntil(seconds, predicate)
	local deadline = os.clock() + seconds
	repeat
		local value = predicate()
		if value then
			return value
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return predicate()
end
local function cleanText(v)
	return tostring(v):gsub("[\r\n]+", " | ")
end
local function step(label, callback)
	local at = os.clock()
	local ok, result = pcall(callback)
	if not ok then
		failures += 1
	end
	table.insert(
		lines,
		string.format(
			"%s %s +%.2fs duration=%.2fs: %s",
			ok and "PASS" or "FAIL",
			label,
			at - started,
			os.clock() - at,
			cleanText(result)
		)
	)
	if not ok then
		error("STOP dependent steps: " .. label, 0)
	end
	return result
end
local function mustWait(seconds, predicate, reason)
	return assert(waitUntil(seconds, predicate), reason .. " (timeout " .. seconds .. "s)")
end
local function candy()
	local stats = assert(player:FindFirstChild("leaderstats"), "leaderstats missing")
	local c = assert(stats:FindFirstChild("Candy"), "Candy missing")
	return c.Value
end
local function root()
	local c = assert(player.Character, "character missing")
	local h = assert(c:FindFirstChildOfClass("Humanoid"), "Humanoid missing")
	assert(h.Health > 0, "tester died; run invalid")
	return assert(c:FindFirstChild("HumanoidRootPart"), "root missing")
end
local function has(attribute, id)
	return table.find(string.split(player:GetAttribute(attribute) or "", ","), id) ~= nil
end
local function shell()
	for _, item in pen:GetDescendants() do
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
local function latest(name, predicate, since)
	for _, event in events do
		if event.name == name and event.at >= (since or 0) and predicate(event.args) then
			return event
		end
	end
	return nil
end
local function request(kind, target, args, timeout)
	assert(mode == "smoke" or kind == "stop", "pacing forbids driving actions")
	serial += 1
	local id = serial
	bus:FireClient(player, id, kind, target, args or {})
	local reply = mustWait(timeout or 12, function()
		return replies[id]
	end, "client command " .. kind)
	replies[id] = nil
	assert(reply[1], "client " .. kind .. ": " .. tostring(reply[2]))
	return table.unpack(reply, 2, reply.n)
end
local function walk(position, seconds)
	request("walk", position, { seconds or 45 }, (seconds or 45) + 5)
	assert(flat(root().Position - position).Magnitude <= 4, "walk finished outside target range")
end
local function promptPosition(prompt)
	local parent = prompt.Parent
	if parent:IsA("Attachment") then
		return parent.WorldPosition
	end
	assert(parent:IsA("BasePart"), "prompt needs part/attachment parent")
	return parent.Position
end
local function earnTo(amount, seconds)
	local before, at = candy(), os.clock()
	mustWait(seconds, function()
		assert(player:GetAttribute("Income") == 1, "unexpected income/multiplier while earning")
		root()
		return candy() >= amount
	end, "earned Candy below " .. amount)
	return string.format(
		"natural income Candy=%s->%s waited=%.2fs; no grant",
		before,
		candy(),
		os.clock() - at
	)
end
local function spentSince(at)
	local spent = 0
	for _, change in candyChanges do
		if change.at >= at and change.delta < 0 then
			spent -= change.delta
		end
	end
	return spent
end

local runOK, runError = pcall(function()
	step("1 fresh spawn / isolation", function()
		assert(
			#Players:GetPlayers() == 1,
			"use exactly one disposable tester; multiplayer belongs to T6"
		)
		player = Players:GetPlayers()[1]
		local gui = player:FindFirstChildOfClass("PlayerGui")
		harness = gui and gui:FindFirstChild("PumpkinSliceHarness")
		driver = harness and harness:FindFirstChild("PumpkinSliceDriver")
		-- Fail CLOSED before installing a bridge or executing any gameplay action.
		assert(
			player:GetAttribute("QAProfile") == true,
			"CONTRACT QAProfile=true missing; no reset attempted"
		)
		local namespace = player:GetAttribute("SaveNamespace")
		assert(
			type(namespace) == "string" and namespace:match("^SliceQA:.+"),
			"CONTRACT isolated SliceQA:<uniqueRunId> namespace missing"
		)
		config = require(assert(RS:FindFirstChild("PatchConfig"), "PatchConfig missing"))
		assert(config.SliceMode == true, "CONTRACT Config.SliceMode=true missing")
		mustWait(20, function()
			return player:GetAttribute("Loaded") == true
		end, "Loaded")
		root()
		assert(
			candy() == 0 and player:GetAttribute("Carry") == 0,
			"save is not fresh Candy0/Carry0"
		)
		assert(
			player:GetAttribute("Income") == 0 and player:GetAttribute("PenHatched") == 0,
			"fresh save has earners"
		)
		assert(
			player:GetAttribute("Tool") == "RustySickle" and player:GetAttribute("Zones") == "Zone1",
			"fresh tool/zones mismatch"
		)
		garden = assert(workspace:FindFirstChild("Garden"), "Garden missing")
		local patches = assert(garden:FindFirstChild("Patches"), "Patches missing")
		assert(#patches:GetChildren() == 8, "expected eight pens")
		for _, p in patches:GetChildren() do
			if p:GetAttribute("Owner") == player.UserId then
				assert(not pen, "multiple owned pens")
				pen = p
			end
		end
		assert(pen and not shell(), "fresh owned pen missing/not empty")
		local previousCandy = candy()
		table.insert(
			connections,
			player.leaderstats.Candy.Changed:Connect(function(value)
				local item = shell()
				table.insert(candyChanges, {
					at = workspace:GetServerTimeNow(),
					delta = value - previousCandy,
					hatched = item and item:GetAttribute("State") == "Hatched",
					income = player:GetAttribute("Income"),
				})
				previousCandy = value
			end)
		)
		remotes = assert(RS:FindFirstChild("PatchRemotes"), "PatchRemotes missing")
		for name, class in
			{
				Bonk = "RemoteEvent",
				WildPopped = "RemoteEvent",
				GuardianWake = "RemoteEvent",
				Hatched = "RemoteEvent",
				Reveal = "RemoteEvent",
				BuyTool = "RemoteFunction",
			}
		do
			local r = remotes:FindFirstChild(name)
			assert(
				r and r:IsA(class),
				"CONTRACT PatchRemotes." .. name .. " " .. class .. " missing"
			)
		end
		local spawnAt = player:GetAttribute("SpawnAt")
		assert(
			type(spawnAt) == "number" and spawnAt <= workspace:GetServerTimeNow(),
			"CONTRACT SpawnAt server timestamp missing/invalid"
		)
		if mode == "pacing" then
			assert(
				workspace:GetServerTimeNow() - spawnAt <= 2,
				"pacing installed late (>2s after spawn); restart fresh, never rebase clock"
			)
		end
		return "fresh isolated profile="
			.. namespace
			.. "; Rusty/Candy0/empty pen; join-popup VISUAL UNKNOWN"
	end)
	step("2 client observer handshake", function()
		bridge = Instance.new("Folder")
		bridge.Name = "PumpkinSliceBridge"
		bridge:SetAttribute("Mode", mode)
		bus = Instance.new("RemoteEvent")
		bus.Name, bus.Parent = "Command", bridge
		table.insert(
			connections,
			bus.OnServerEvent:Connect(function(who, id, ...)
				if who ~= player then
					return
				end
				local args = table.pack(...)
				if id ~= 0 then
					replies[id] = args
					return
				end
				if args[1] == "ready" then
					ready = true
				elseif args[1] == "contract" then
					table.insert(contractErrors, args[2])
				elseif args[1] == "log" then
					table.insert(
						logs,
						"CLIENT " .. cleanText(args[2]) .. ": " .. cleanText(args[3])
					)
				elseif args[1] == "event" then
					local payload = table.pack(table.unpack(args, 4, args.n))
					table.insert(events, { name = args[2], at = args[3], args = payload })
				end
			end)
		)
		table.insert(
			connections,
			LogService.MessageOut:Connect(function(message, kind)
				if
					kind == Enum.MessageType.MessageError
					or kind == Enum.MessageType.MessageWarning
				then
					table.insert(logs, "SERVER " .. kind.Name .. ": " .. cleanText(message))
				end
			end)
		)
		bridge.Parent = RS
		local gui = assert(player:FindFirstChildOfClass("PlayerGui"), "PlayerGui missing")
		harness = gui:FindFirstChild("PumpkinSliceHarness")
		if not harness then
			harness = Instance.new("ScreenGui")
			harness.Name, harness.ResetOnSpawn, harness.Parent = "PumpkinSliceHarness", false, gui
		end
		assert(
			harness:IsA("ScreenGui") and not harness.ResetOnSpawn,
			"harness must survive respawn"
		)
		driver = harness:FindFirstChild("PumpkinSliceDriver")
		if not driver then
			driver = Instance.new("LocalScript")
			driver.Name = "PumpkinSliceDriver"
			local ok, err = pcall(function()
				driver.Source = CLIENT_SOURCE
			end)
			assert(ok, "Source-write denied; use header bootstrap: " .. tostring(err))
			driver.Parent = harness
		end
		mustWait(mode == "pacing" and 2 or 15, function()
			return ready
		end, "client handshake")
		assert(#contractErrors == 0, table.concat(contractErrors, "; "))
		assert(candy() == 0, "reward occurred before observer ready; invalid fresh run")
		return "client event/log observer ready; mode=" .. mode
	end)
	if mode == "pacing" then
		local spawnAt = player:GetAttribute("SpawnAt")
		local rewardAt, earnerAt, hatchedAt
		local remaining = math.max(0, spawnAt + 120 - workspace:GetServerTimeNow())
		waitUntil(remaining, function()
			root()
			local pop = latest("WildPopped", function(a)
				return a[3] == player and type(a[4]) == "number" and a[4] > 0
			end)
			if not rewardAt and pop and candy() > 0 then
				rewardAt = pop.at
			end
			local hatch = latest("Hatched", function(a)
				return a[2] == player.UserId
			end)
			if hatch then
				hatchedAt = hatch.at
			end
			-- Observe actual server Candy changes; client hatch receipt can arrive after its first tick.
			if hatchedAt and not earnerAt then
				for _, change in candyChanges do
					if change.hatched and change.income == 1 and change.delta == 1 then
						earnerAt = change.at
						break
					end
				end
			end
			return rewardAt ~= nil and earnerAt ~= nil
		end)
		for _, metric in
			{ { "first reward", rewardAt, 30 }, { "first earner tick", earnerAt, 120 } }
		do
			local elapsed = metric[2] and metric[2] - spawnAt
			local passed = elapsed ~= nil and elapsed < metric[3]
			if not passed then
				failures += 1
			end
			table.insert(
				lines,
				string.format(
					"%s pacing %s: %s; strict limit<%ss; no grants/teleports/automated input",
					passed and "PASS" or "FAIL",
					metric[1],
					elapsed and string.format("%.3fs", elapsed) or "not observed by120s",
					metric[3]
				)
			)
		end
		table.insert(
			lines,
			"Human pace observer; reward requires WildPopped + Candy increase; earner requires Hatched + Income1 + later Candy increase. Do not smash/buy/claim between hatch and first income tick."
		)
		return
	end
	step("3 walk to wild / smash Candy", function()
		local target, distance
		for _, item in garden:GetDescendants() do
			if
				item:IsA("BasePart")
				and item:GetAttribute("Wild") == true
				and item:GetAttribute("Zone") == "Zone1"
			then
				local d = flat(item.Position - root().Position).Magnitude
				if not distance or d < distance then
					target, distance = item, d
				end
			end
		end
		assert(target, "no Zone1 wild target")
		local targetPosition = target.Position
		local hp = target:GetAttribute("Hp")
		assert(type(hp) == "number" and hp == 13, "wild Hp must be13")
		local at = target.Position - Vector3.zAxis * math.min(3, config.Farm.arcRange * 0.5)
		walk(at)
		local before, time = candy(), workspace:GetServerTimeNow()
		local damaged = false
		local delay = math.max(
			config.BonkCooldown,
			config.BonkTeleportWindow,
			config.Farm.firstSwingSeconds
		) + 0.15
		for _ = 1, 8 do
			local direction = flat(target.Position - root().Position)
			assert(direction.Magnitude > 0, "standing inside wild root")
			request("swing", nil, { direction.Unit })
			task.wait(delay)
			if target.Parent and (target:GetAttribute("Hp") or hp) < hp then
				damaged = true
			end
			if
				latest("WildPopped", function(a)
					return typeof(a[1]) == "Vector3"
						and (a[1] - targetPosition).Magnitude < 0.5
						and a[3] == player
				end, time)
			then
				break
			end
		end
		local pop = latest("WildPopped", function(a)
			return typeof(a[1]) == "Vector3"
				and (a[1] - targetPosition).Magnitude < 0.5
				and a[3] == player
		end, time)
		assert(damaged, "Bonk never reduced target Hp before break")
		assert(pop and pop.args[4] == 1, "first break WildPopped reward not exactly1")
		assert(
			candy() > before and player:GetAttribute("Carry") == 0,
			"Candy absent or smash stole nest"
		)
		return string.format("HP13 damaged; target reward1; Candy%s->%s Carry0", before, candy())
	end)
	step("4 walk to nest / held steal / wake", function()
		local zone = assert(garden.Zones:FindFirstChild("Zone1"), "Zone1 missing")
		local prompt = mustWait(10, function()
			return zone:FindFirstChild("StealPrompt", true)
		end, "StealPrompt")
		assert(prompt.HoldDuration == 1, "steal HoldDuration must be1s")
		walk(promptPosition(prompt) - Vector3.zAxis * 3)
		local time = workspace:GetServerTimeNow()
		request("prompt", prompt)
		mustWait(4, function()
			return player:GetAttribute("Carry") == 1
		end, "Carry did not become1")
		mustWait(4, function()
			return latest("GuardianWake", function(a)
				return a[3] == player
			end, time)
		end, "Scarecrow GuardianWake missing")
		return "real1s StealPrompt; Carry1 and GuardianWake received; no candy/item grants"
	end)
	step("5 walk south across HOME", function()
		local before = candy()
		walk(Vector3.new(config.MapCenterX, root().Position.Y, config.SafeLineZ - 5))
		assert(root().Position.Z < config.SafeLineZ, "did not cross south HOME")
		assert(player:GetAttribute("Carry") == 1 and candy() == before, "escape lost shell/Candy")
		return string.format(
			"serverZ=%.2f HOME=%.2f Carry1 Candy%s",
			root().Position.Z,
			config.SafeLineZ,
			candy()
		)
	end)
	step("6 walk to own pen / place stays Seated", function()
		local soil = assert(pen:FindFirstChild("Soil"), "own pen Soil missing")
		walk(soil.Position + Vector3.yAxis * (soil.Size.Y / 2 + 3))
		placed = mustWait(8, shell, "automatic owned-pen placement absent")
		assert(
			placed:IsDescendantOf(pen) and player:GetAttribute("Carry") == 0,
			"wrong pen or carry not consumed"
		)
		assert(
			placed:GetAttribute("State") == "Seated" and placed:GetAttribute("CarveAt") == nil,
			"CONTRACT Seated absent or auto-hatch started"
		)
		task.wait(1.1)
		assert(
			player:GetAttribute("Income") == 0 and placed:GetAttribute("State") == "Seated",
			"placement auto-hatched/earned before Hatch"
		)
		return "own pen; Carry0; Seated without deadline or income for1.1s"
	end)
	local hatchStart, deadline
	step("7 explicit Hatch interaction", function()
		local prompt =
			assert(pen:FindFirstChild("HatchPrompt", true), "CONTRACT HatchPrompt missing")
		walk(promptPosition(prompt) - Vector3.zAxis * 2)
		hatchStart = workspace:GetServerTimeNow()
		request("prompt", prompt)
		mustWait(3, function()
			return placed:GetAttribute("State") == "Waiting"
		end, "explicit Hatch did not start Waiting")
		deadline = placed:GetAttribute("CarveAt")
		assert(type(deadline) == "number", "Waiting lacks server CarveAt")
		assert(config.CarveNewSeconds == 6, "fresh hatch policy must be6s")
		assert(math.abs(deadline - hatchStart - 6) < 1, "fresh hatch deadline deviates from6s")
		assert(player:GetAttribute("Income") == 0, "income during pending hatch")
		return string.format("Waiting; deadline=%.3f requestedAt=%.3f", deadline, hatchStart)
	end)
	step("8 hatch completion / Reveal", function()
		local untilAt = deadline + 5
		mustWait(math.max(0, untilAt - workspace:GetServerTimeNow()), function()
			if placed:GetAttribute("State") == "Waiting" then
				assert(player:GetAttribute("Income") == 0, "income during Waiting")
			end
			return placed:GetAttribute("State") == "Hatched" and placed:FindFirstChild("PetLook")
		end, "Hatched/PetLook absent")
		local hatch = mustWait(3, function()
			return latest("Hatched", function(a)
				return a[1] == placed and a[2] == player.UserId
			end, hatchStart)
		end, "Hatched event missing")
		local reveal = mustWait(3, function()
			return latest("Reveal", function(a)
				return a[6] == "PumpkinPup" and a[4] == 1
			end, hatchStart)
		end, "Reveal first Pup/+1 missing")
		assert(hatch.at >= deadline - 0.1, "Hatched fired before deadline")
		assert(
			placed:GetAttribute("Pet") == "PumpkinPup" and player:GetAttribute("PenHatched") == 1,
			"first outcome not one Pup"
		)
		mustWait(1.1, function()
			return player:GetAttribute("Income") == 1
		end, "first pet rate not1/s")
		return string.format(
			"Hatched+PetLook+Reveal; Pup1/s; hatch=%.3f reveal=%.3f; six visual beats/Common token UNKNOWN",
			hatch.at,
			reveal.at
		)
	end)
	step("9 pet earns Candy over10s", function()
		local before, at, ticks = candy(), workspace:GetServerTimeNow(), 0
		local stats = player.leaderstats.Candy
		local connection = stats.Changed:Connect(function()
			ticks += 1
		end)
		table.insert(connections, connection)
		task.wait(10)
		connection:Disconnect()
		local elapsed, delta = workspace:GetServerTimeNow() - at, candy() - before
		assert(
			player:GetAttribute("Income") == 1 and player:GetAttribute("PenHatched") == 1,
			"earner count/rate changed"
		)
		assert(
			math.abs(delta - elapsed) <= 1.1 and ticks >= 9 and ticks <= 11,
			"income mismatch: delta=" .. delta .. " ticks=" .. ticks .. " elapsed=" .. elapsed
		)
		return string.format(
			"Candy%s->%s delta%s in%.3fs ticks%d (one-second boundary tolerance)",
			before,
			candy(),
			delta,
			elapsed,
			ticks
		)
	end)
	step("10 earn / buy Iron scythe", function()
		local earned = earnTo(150, 160)
		assert(not has("Tools", "WoodenScythe"), "Iron already owned")
		local before, at = candy(), workspace:GetServerTimeNow()
		local ok, reason = request("invoke", remotes.BuyTool, table.pack("WoodenScythe"))
		assert(ok == true, "BuyTool rejected: " .. tostring(reason))
		mustWait(3, function()
			return has("Tools", "WoodenScythe") and player:GetAttribute("Tool") == "WoodenScythe"
		end, "Iron ownership/equip absent")
		task.wait(0.1)
		local net, debit = before - candy(), spentSince(at)
		assert(debit == 150, "Iron observed debit not exactly150: " .. debit)
		return earned
			.. string.format(
				"; BuyTool Iron net debit%s actual debit%s; UI click/grip/damage checks T6",
				net,
				debit
			)
	end)
	step("11 earn / buy Graveyard gate", function()
		local earned = earnTo(1000, 1020)
		assert(not has("Zones", "Zone2"), "Graveyard already owned")
		local gate = assert(garden.Zones.Zone2:FindFirstChild("GateWall"), "GateWall missing")
		local prompt = assert(gate:FindFirstChild("UnlockPrompt"), "UnlockPrompt missing")
		walk(promptPosition(prompt) - Vector3.zAxis * 5, 60)
		local before, at = candy(), workspace:GetServerTimeNow()
		request("prompt", prompt)
		mustWait(4, function()
			return has("Zones", "Zone2")
		end, "Graveyard unlock flag absent")
		task.wait(0.1)
		local net, debit = before - candy(), spentSince(at)
		assert(debit == 1000, "gate observed debit not exactly1000: " .. debit)
		return earned
			.. string.format(
				"; real UnlockPrompt Zone2 owned net debit%s actual debit%s; physical client passage UNKNOWN",
				net,
				debit
			)
	end)
end)

if not runOK then
	if failures == 0 then
		failures = 1
	end
	table.insert(lines, "FAIL runner: " .. cleanText(runError))
end
-- Unconditional cleanup. No snapshot restore needed: original profiles never touched.
if ready and bus and bus.Parent then
	pcall(request, "stop", nil, nil, 2)
end
if driver then
	driver:Destroy()
end
if harness then
	harness:Destroy()
end
for _, connection in connections do
	connection:Disconnect()
end
if bridge then
	bridge:Destroy()
end
if #logs > 0 then
	failures += 1
end
table.insert(
	lines,
	string.format(
		"%s client/server logs: %d warnings/errors during observer window (pre-handshake history UNKNOWN)",
		#logs == 0 and "PASS" or "FAIL",
		#logs
	)
)
for _, log in logs do
	table.insert(lines, log)
end
table.insert(
	lines,
	"CLEANUP temporary driver/GUI/bridge/listeners removed; QA progress retained; no reset/restore/save deletion. No grants or teleports."
)
table.insert(
	lines,
	1,
	string.format(
		"PUMPKIN SLICE %s mode=%s failures=%d elapsed=%.2fs tester=%s",
		failures == 0 and "PASS" or "FAIL",
		mode,
		failures,
		os.clock() - started,
		player and player.Name or "none"
	)
)
return table.concat(lines, "\n")
