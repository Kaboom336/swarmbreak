local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Config = require("./GreyboxConfig")
local Layout = require("./Layout")
local Rules = require("./LootRules")
local Placement = require("./Placement")
for _, name in fs.readDir(".") do
	if string.sub(name, -5) == ".luau" then
		for level = 0, 2 do
			luau.compile(fs.readFile(name), { optimizationLevel = level, debugLevel = 2 })
		end
		print("COMPILE PASS " .. name .. " O0/O1/O2")
	end
end
Layout.selfTest(Config, print)
-- Execute the production placement adapter with raycasts/visuals mocked.
local function placementTest()
	local roblox = require("@lune/roblox")
	local v = roblox.Vector3
	local source = fs.readFile("Greybox.server.luau")
	local from = assert(source:find("local function placeItem(", 1, true))
	local finish = assert(source:find("\nfor i = 1, 8 do", from, true))
	for slot = 1, 8 do
		local cx, cz = Placement.center(slot)
		local actor, other = {}, {}
		local rules = Rules.new(Config)
		local s = Rules.actor(rules, actor)
		s.slot = slot
		local pen = { count = 0, occupied = {}, base = roblox.Instance.new("Part") }
		local position = v.new(cx - 5.25, 0.2, cz + 10.5)
		local r = { Position = position + v.new(0, 3, 0) }
		local missingFloor = false
		local place = luau.load(source:sub(from, finish - 1) .. "\nreturn placeItem", {
			environment = {
				Config = Config,
				Placement = Placement,
				Rules = Rules,
				rules = rules,
				states = rules.actors,
				pens = { [slot] = pen },
				Vector3 = v,
				Enum = roblox.Enum,
				typeof = typeof,
				RaycastParams = {
					new = function()
						return {}
					end,
				},
				workspace = {
					Raycast = function(_, origin)
						return not missingFloor and { Position = v.new(origin.X, 0.2, origin.Z) } or nil
					end,
				},
				root = function(a)
					return a == actor and r or nil
				end,
				visual = function(item)
					item.visual = roblox.Instance.new("Part")
				end,
				goal = function() end,
				publish = function() end,
			},
		})()
		local function secured()
			local item = Rules.spawn(rules, position)
			item.state, item.holder = "Secured", actor
			rules.active, s.item = nil, item
			return item
		end
		local item = secured()
		local function reject(point, angle, reason)
			local ok, why = place(actor, slot, point, angle)
			assert(not ok and (not reason or why == reason), "invalid Place accepted/wrong reason: " .. tostring(why))
			assert(s.item == item and item.state == "Secured" and pen.count == #pen.occupied, "refusal consumed cargo")
		end
		assert(not place(other, slot, position, 15), "foreign owner placed")
		reject(nil, 0, "placement required")
		reject(v.new(0 / 0, 0.2, cz), 0, "invalid placement")
		reject(v.new(cx, 0 / 0, cz + 10), 0, "floor/range")
		reject(position, math.huge, "invalid placement")
		reject(v.new(cx + 40, 0.2, cz), 15, "out of bounds")
		reject(v.new(cx + 26, 0.2, cz + 10), 45, "out of bounds")
		reject(v.new(cx + (cx < 0 and 22 or -22), 0.2, cz), 0, "keep entrance clear")
		reject(v.new(position.X, 4, position.Z), 15, "floor/range")
		r.Position = position + v.new(0, 30, 0)
		reject(position, 15, "floor/range")
		r.Position = position + v.new(0, 3, 0)
		missingFloor = true
		reject(position, 15, "plot floor")
		missingFloor = false
		assert(place(actor, slot, position, 15), "free placement failed")
		assert(item.position == position + v.new(0, 1.5, 0) and item.rotation == 15, "free transform lost")
		assert(
			item.visual:GetAttribute("PlacementX") == position.X and item.visual:GetAttribute("PenSlot") == slot,
			"preview footprint missing"
		)
		assert(not place(actor, slot, position, 15), "duplicate Place")
		item = secured()
		reject(position, 15, "overlap")
		reject(position + v.new(5, 0, 0), 15, "overlap")
		for dz = -14, 14, 7 do
			for dx = -22, 22, 7 do
				local p = v.new(cx + dx, 0.2, cz + dz)
				if #pen.occupied < 8 and Placement.validate(Config, slot, p.X, p.Z, 15, pen.occupied) then
					r.Position = p + v.new(0, 3, 0)
					assert(place(actor, slot, p, 15), "legal capacity placement rejected")
					item = secured()
				end
			end
		end
		assert(pen.count == 8 and #pen.occupied == 8, "eight active pets do not fit")
		reject(position, 15, "active pet limit")
		Rules.audit(rules)
	end
	print(
		"PASS production free Place across eight plots: chosen transform, owner/types/finite/floor/range/bounds/rotation/gate/overlap/capacity/replay; refusals retain cargo"
	)
end
placementTest()
local invalid = Layout.assemble(Config, 101, true)
invalid.pieces[3].x = 0
assert(not pcall(Layout.validate, Config, invalid), "overlap accepted")
invalid = Layout.assemble(Config, 101, true)
invalid.ramps[1].b.y = 30
assert(not pcall(Layout.validate, Config, invalid), "steep ramp accepted")
-- Exact server-clock ties, holder-independent deadline, and production visual cleanup.
local function deadlineTest()
	local function setup()
		local r = Rules.new(Config)
		local a, b = {}, {}
		local sa, sb = Rules.actor(r, a), Rules.actor(r, b)
		sa.phase, sb.phase = "Run", "Run"
		local item = Rules.spawn(r, { x = 0, y = 8, z = 32 })
		local function legal()
			return true
		end
		local function floor()
			return { x = 0, y = 0, z = 8 }
		end
		assert(not Rules.expire(r, 1000), "pre-steal countdown")
		assert(Rules.begin(r, a, "Steal", nil, 1000, legal))
		assert(Rules.finish(r, a, "Steal", 1002, legal, floor))
		assert(item.escapeDeadline == 1062, "deadline not exactly sixty")
		return r, a, b, sa, sb, item, legal, floor
	end
	local r, a, _, sa, _, item = setup()
	assert(Rules.secure(r, a, item.escapeDeadline - 0.001), "before-deadline portal blocked")
	assert(not Rules.expire(r, 2000) and sa.item == item and item.state == "Secured", "secured cargo expired")
	assert(sa.completed == 1, "missing secure")
	Rules.audit(r)

	local b, sb, legal, floor
	r, a, b, sa, sb, item, legal, floor = setup()
	local deadline = item.escapeDeadline
	assert(Rules.drop(r, a, 1015, floor()))
	assert(Rules.begin(r, b, "Grab", nil, 1016, legal))
	assert(Rules.finish(r, b, "Grab", 1016.5, legal, floor))
	assert(item.escapeDeadline == deadline and item.holder == b, "handoff refreshed deadline")
	assert(not Rules.expire(r, deadline - 0.001), "early expiry")
	assert(not Rules.secure(r, b, deadline), "exact tie awarded")
	local expired, retired = Rules.expire(r, deadline)
	assert(expired and retired == item and item.state == "Retired", "carried expiry missing")
	assert(not sa.item and not sb.item and not item.holder and not r.active, "orphan holder")
	assert(sa.completed == 0 and sb.completed == 0, "expiry award")
	assert(r.respawnAt == deadline + 3 and not Rules.expire(r, deadline + 1), "refill clock/reset")
	assert(not Rules.place(r, b) and not Rules.begin(r, b, "Grab", nil, deadline, legal), "retired ID usable")
	Rules.audit(r)
	local replacement = Rules.spawn(r, floor())
	assert(replacement.id ~= item.id and replacement.state == "Nest" and not replacement.escapeDeadline, "new ID/clock")
	Rules.audit(r)

	r, a, b, sa, sb, item, legal, floor = setup()
	deadline = item.escapeDeadline
	assert(Rules.drop(r, a, deadline - 1, floor()))
	assert(Rules.begin(r, a, "Grab", nil, deadline - 0.4, legal))
	assert(Rules.begin(r, b, "Grab", nil, deadline - 0.4, legal))
	assert(not Rules.finish(r, a, "Grab", deadline, legal, floor), "expiry finish won tie")
	assert(Rules.expire(r, deadline))
	assert(
		not sa.hold and not sb.hold and not sa.item and not sb.item and item.state == "Retired",
		"dropped expiry stale hold"
	)
	assert(not Rules.finish(r, b, "Grab", deadline + 0.1, legal, floor), "stale finish duplicated")
	Rules.audit(r)

	-- Execute the actual Retired visual branch: destroy weld and physical item.
	local roblox = require("@lune/roblox")
	local world = roblox.Instance.new("Folder")
	local p = roblox.Instance.new("Part")
	p.Parent = world
	local weld = roblox.Instance.new("WeldConstraint")
	weld.Parent = p
	item.visual, item.weld = p, weld
	local source = fs.readFile("Greybox.server.luau")
	local startAt = assert(string.find(source, "local function visual(item)", 1, true))
	local endAt = assert(string.find(source, "local function conservation()", startAt, true))
	local visual = luau.load(string.sub(source, startAt, endAt - 1) .. "\nreturn visual", {
		environment = { world = world, states = {}, publish = function() end },
	})()
	visual(item)
	assert(not item.visual and not item.weld and #world:GetChildren() == 0, "production expiry physical orphan")
	print(
		"PASS deadline: first Steal +60; handoff unchanged; before/exact/after ties; carried/dropped expiry; holds cleared; no award; +3 refill/new ID; production weld/visual cleanup"
	)
end
deadlineTest()
-- Execute the actual scene assembly and inspect its physical cover and chunk tree.
local function constructionTest()
	local roblox = require("@lune/roblox")
	local scene = luau.load(fs.readFile("Scene.luau"), {
		environment = {
			game = {
				GetService = function()
					return {
						WaitForChild = function(_, name)
							return name
						end,
					}
				end,
			},
			require = function(name)
				assert(name == "GreyboxLayout", "unexpected scene dependency")
				return Layout
			end,
			Instance = roblox.Instance,
			Vector2 = roblox.Vector2,
			NumberRange = roblox.NumberRange,
			NumberSequence = roblox.NumberSequence,
			NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
			ColorSequence = roblox.ColorSequence,
			Vector3 = roblox.Vector3,
			CFrame = roblox.CFrame,
			Color3 = roblox.Color3,
			Enum = roblox.Enum,
		},
	})()
	local arenaModule = luau.load(fs.readFile("Arena.luau"), {
		environment = {
			Instance = roblox.Instance,
			Vector3 = roblox.Vector3,
			CFrame = roblox.CFrame,
			Color3 = roblox.Color3,
			Enum = roblox.Enum,
			RaycastParams = {
				new = function()
					return {}
				end,
			},
			game = {
				GetService = function()
					return {
						WaitForChild = function(_, name)
							return name
						end,
					}
				end,
			},
			require = function(name)
				if name == "GreyboxConfig" then
					return Config
				end
				if name == "GreyboxLayout" then
					return Layout
				end
				if name == "GreyboxScene" then
					return scene
				end
				error(name)
			end,
		},
	})()
	local world = roblox.Instance.new("Folder")
	local function make(parent, name, size, position, color)
		local p = roblox.Instance.new("Part")
		p.Name, p.Size, p.Position, p.CFrame = name, size, position, roblox.CFrame.new(position)
		p.Anchored, p.Color, p.Parent = true, color or roblox.Color3.new(0.5, 0.5, 0.5), parent
		return p
	end
	local layout = Layout.assemble(Config, 101, true)
	local arena = arenaModule.build(world, layout, make, function()
		return {}
	end)
	local cliffCount, bridgeCount, fillCount = 0, 0, 0
	for _, p in arena.model:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "MeadowCliffFace" or p.Name == "MeadowEdgeVoxel" or p.Name:find("MeadowBridge") then
				assert(not p.CanCollide and not p.CanQuery and not p.CanTouch, "new scenery blocks gameplay")
				if p.Name == "MeadowCliffFace" then
					cliffCount += 1
				elseif p.Name == "MeadowBridgePlank" then
					bridgeCount += 1
					assert(p.Size.Z == 12, "bridge route width")
				end
			elseif p.Name:find("Voxel") and p:GetAttribute("SurfaceRole") == "Floor" then
				fillCount += 1
				assert(p.CanCollide and p.Size.Z == 12, "hill fill must be solid and respect ramp width")
			end
		end
	end
	assert(cliffCount > 0 and bridgeCount == 16 and fillCount > 0, "missing raised Meadow geometry")
	for name, top in { MountainSummit = 18, GroveHillSummit = 14, CampTerrace = 8 } do
		local p = assert(arena.model:FindFirstChild(name, true), "missing raised landmark " .. name)
		assert(p.CanCollide and p.Position.Y + p.Size.Y / 2 == arena.origin.Y + top, "landmark surface height")
	end
	print("PASS built Meadow: solid voxel ramp fill, slate cliff faces, 12-wide wood decks; new scenery nonblocking")
	assert(not arena.model:FindFirstChild("I09") and not arena.model:FindFirstChild("I10"), "hide chunks remain")
	assert(#arena.obstacles == 6, "ordinary cover lost")
	for _, p in arena.model:GetDescendants() do
		assert(not p.Name:find("Hide") and not p.Name:find("Log"), "hide scene remains")
	end
	for _, pair in { { "CutbackRockA", "CutbackRockB" }, { "CutbackRockC", "CutbackRockD" } } do
		local a, b = arena.model:FindFirstChild(pair[1]), arena.model:FindFirstChild(pair[2])
		assert(a and b and a.CanCollide and b.CanCollide, "cover not solid")
		assert(
			math.abs(a.Position.Z - b.Position.Z) - (a.Size.Z + b.Size.Z) / 2 >= 12,
			"cutback passage narrower than twelve"
		)
	end
	-- Expiry cancels an in-flight attack and invalidates asynchronous navigation.
	local attack = {}
	for _, name in { "disc", "fill", "rock", "outline" } do
		attack[name] = roblox.Instance.new("Part")
		attack[name].Parent = arena.model
	end
	arena.attack, arena.target, arena.searchAt = attack, {}, roblox.Vector3.zero
	arena.mode, arena.points, arena.pathVersion = "Chase", { {} }, 5
	arenaModule.reset(arena)
	assert(
		not arena.attack and not arena.target and not arena.searchAt and arena.mode == "Guard",
		"expiry guardian reset"
	)
	assert(#arena.points == 0 and arena.pathVersion == 6, "stale path after expiry")
	for _, p in attack do
		assert(p.Parent == nil, "orphan attack visual")
	end
	scene.home(world, make, function()
		return {}
	end)
	-- Sample the built home's real floor transforms, including its round pad.
	local v = roblox.Vector3
	local home = world:FindFirstChild("HomeFloatingIsland")
	assert(home.HomeGrass.Size == v.new(216, 4, 320), "home envelope")
	for slot = 1, 8 do
		local cx, cz = Placement.center(slot)
		local plot = roblox.Instance.new("Folder")
		plot.Parent = world
		scene.pen(plot, cx, cz, make)
		local gateRails = 0
		for _, p in plot:GetChildren() do
			assert(p.Name ~= "PetPad", "fixed pads remain")
			if p.Name == "PenRail" then
				assert(p.Size.X == 64 and math.abs(p.Position.Z - cz) == 24, "plot rails")
			elseif p.Name == "PenBackRail" then
				assert(p.Size.Z == 48 and math.abs(p.Position.X - cx) == 32, "plot depth")
			elseif p.Name == "PenGateRail" then
				gateRails += 1
				assert(math.abs(p.Position.Z - cz) - p.Size.Z / 2 == 6, "twelve-wide gate")
			end
		end
		assert(gateRails == 4, "inward gate missing")
	end
	local function homeFloor(x, z)
		local best = -math.huge
		for _, p in home:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("SurfaceRole") == "Floor" then
				if p.Shape == roblox.Enum.PartType.Cylinder then
					local c = p.CFrame.Position
					if (x - c.X) ^ 2 + (z - c.Z) ^ 2 <= (p.Size.Y / 2) ^ 2 then
						best = math.max(best, c.Y + p.Size.X / 2)
					end
				else
					local top = p.CFrame * v.new(0, p.Size.Y / 2, 0)
					local n = p.CFrame.UpVector
					local y = top.Y - ((x - top.X) * n.X + (z - top.Z) * n.Z) / n.Y
					local localPoint = p.CFrame:PointToObjectSpace(v.new(x, y, z))
					if math.abs(localPoint.X) <= p.Size.X / 2 and math.abs(localPoint.Z) <= p.Size.Z / 2 then
						best = math.max(best, y)
					end
				end
			end
		end
		return best
	end
	local runner = fs.readFile("LoopTest.luau")
	local from = assert(runner:find("local function homeEntryPoints(", 1, true))
	local finish = assert(runner:find("local function homePoints(", from, true))
	local entry = luau.load(runner:sub(from, finish - 1) .. "\nreturn homeEntryPoints", {
		environment = {
			Config = Config,
			at = function(_, x, y, z)
				return v.new(x, y + 3, z)
			end,
		},
	})()
	for slot = 1, 8 do
		local side = slot <= 4 and -1 or 1
		local _, z = Placement.center(slot)
		local points = entry({ marker = { Position = v.new(side * 20, 1.5, z + 8) } })
		local previous = v.new(side * 15, 3, z + 8)
		for _, point in points do
			local p = point.position
			assert(math.abs(homeFloor(p.X, p.Z) - (p.Y - 3)) < 0.7, "home waypoint height")
			for dx = -3, 3, 0.5 do
				for dz = -3, 3, 0.5 do
					if dx * dx + dz * dz <= 9 then
						assert(math.abs(homeFloor(p.X + dx, p.Z + dz) - (p.Y - 3)) <= 1.5, "home waypoint clearance")
					end
				end
			end
			local samples = math.ceil((p - previous).Magnitude * 2)
			local last = homeFloor(previous.X, previous.Z)
			for i = 1, samples do
				local q = previous:Lerp(p, i / samples)
				local y = homeFloor(q.X, q.Z)
				assert(math.abs(y - last) <= 0.65, "home entry hits raised platform side")
				last = y
			end
			previous = p
		end
	end
	print(
		"PASS all eight pen-to-home-portal routes: built floor heights, 3-stud waypoint clearance, sampled ramp continuity"
	)
	scene.skyIslands(world, make)
	scene.surroundings(world, arena.origin, make)
	local count = 0
	for _, p in world.DistantSurroundings:GetDescendants() do
		if p:IsA("BasePart") then
			count += 1
		end
	end
	assert(count == 44, "new scenery part budget changed")
	for _, p in world:GetDescendants() do
		if
			p:IsA("BasePart")
			and (p:GetAttribute("SurfaceRole") == "Scenery" or p:GetAttribute("SurfaceRole") == "Underside")
		then
			assert(
				p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch,
				"decoration blocks physics/queries: " .. p.Name
			)
		end
	end
	for _, name in { "Crystal Cave", "Frost Peak", "Volcano", "Ocean" } do
		local vista = assert(world:FindFirstChild(name .. "Vista"), "existing vista lost")
		for _, p in vista:GetDescendants() do
			if p:IsA("BasePart") then
				assert(not p.CanCollide and not p.CanQuery, "old vista blocks queries")
			end
		end
	end
	assert(world.VolcanoVista.LavaFall.Material == roblox.Enum.Material.Neon, "lava glow lost")
	local lighting = roblox.Instance.new("Lighting")
	scene.environment(lighting, false)
	local homeColor = lighting.GreyboxAtmosphere.Color
	scene.environment(lighting, true)
	assert(lighting.GreyboxSunRays.Enabled and math.abs(lighting.ClockTime - 14.2) < 0.001, "Meadow preset missing")
	assert(lighting.GreyboxAtmosphere.Color ~= homeColor, "presets identical")
	scene.environment(lighting, false)
	assert(
		not lighting.GreyboxSunRays.Enabled and lighting.ClockTime == 12 and #lighting:GetChildren() == 2,
		"Home preset reset/duplicate effects"
	)
	local volume, emitter = scene.pollen(world)
	assert(not volume.CanQuery and not volume.CanCollide and volume.Anchored, "weather volume obstructs")
	assert(not emitter.Enabled and emitter.Rate * emitter.Lifetime.Max <= 18, "weather particle budget")
	volume:Destroy()
	print(
		"PASS surroundings: 44 new decor parts; all vistas/undersides nonblocking; Home/Meadow/Home presets reuse effects; pollen <=18"
	)
	scene.captureCams(world, true, arena.origin)
	assert(world:FindFirstChild("CaptureCameras"), "capture cameras lost")
	assert(#world.CaptureCameras:GetChildren() == 4, "surroundings cameras missing")
	scene.captureCams(world, false, arena.origin)
	assert(not world:FindFirstChild("CaptureCameras"), "capture cleanup")
	print(
		"PASS production scene construction: no hide chunks/scenery; six hard covers; twelve-stud cutbacks; guardian attack/path cleanup; home/vistas/capture cameras"
	)
end
constructionTest()
-- Scalar server transition tests are distinct from Roblox physics evidence.
local function rulesTest()
	local r = Rules.new(Config)
	local a, b, c = {}, {}, {}
	local sa, sb, sc = Rules.actor(r, a), Rules.actor(r, b), Rules.actor(r, c)
	sa.phase, sb.phase, sc.phase = "Run", "Run", "Run"
	local position = { x = 0, y = 8, z = 32 }
	local item = Rules.spawn(r, position)
	local function legal()
		return true
	end
	local function floor()
		return position
	end
	assert(Rules.begin(r, a, "Steal", nil, 0, legal))
	assert(Rules.begin(r, b, "Steal", nil, 0, legal))
	assert(not Rules.finish(r, a, "Steal", 0.99, legal, floor), "short hold")
	assert(Rules.finish(r, a, "Steal", 2, legal, floor))
	assert(not Rules.finish(r, b, "Steal", 2, legal, floor), "simultaneous nest duplicate")
	assert(not Rules.begin(r, b, "Bump", a, 2, legal), "shield/mercy bypass")
	assert(Rules.hit(r, a, "Guardian", 5.1, floor()))
	assert(not sa.item and item.state == "Dropped", "hard guardian must drop first cargo hit")
	assert(Rules.begin(r, a, "Grab", nil, 6, legal))
	assert(Rules.finish(r, a, "Grab", 6.41, legal, floor))
	assert(not Rules.hit(r, a, "Guardian", 6.5, floor()), "airborne mercy bypass")
	assert(Rules.begin(r, b, "Bump", a, 15, legal))
	assert(Rules.finish(r, b, "Bump", 15.41, legal, floor))
	assert(item.state == "Dropped" and not sa.item and not sb.item, "direct carrier theft")
	assert(not Rules.begin(r, b, "Grab", nil, 15.7, legal), "settle precharge")
	assert(Rules.begin(r, b, "Grab", nil, 16.02, legal))
	assert(Rules.begin(r, c, "Grab", nil, 16.02, legal))
	assert(Rules.finish(r, b, "Grab", 16.43, legal, floor))
	assert(not Rules.finish(r, c, "Grab", 16.43, legal, floor), "simultaneous Grab duplicate")
	assert(item.id == "arena1:1" and item.firstPickup == 2, "identity/timestamp reroll")
	assert(sb.item == item and not sa.item and not sc.item, "handoff holder")
	Rules.audit(r)
	assert(not Rules.hit(r, b, "Pvp", 17, floor()), "cross-source mercy")
	assert(Rules.begin(r, c, "Bump", b, 20, legal))
	sc.hold = nil -- Cancelled attempt still cools down.
	assert(not Rules.begin(r, c, "Bump", b, 20.5, legal), "cancelled Bump cooldown")
	assert(Rules.secure(r, b, 19))
	assert(sb.completed == 1 and sa.completed == 0 and item.state == "Secured" and item.firstPup, "winner finalization")
	assert(Rules.place(r, b))
	assert(not Rules.place(r, b), "duplicate placement")
	Rules.audit(r)
	local nextItem = Rules.spawn(r, position)
	assert(nextItem.id ~= item.id, "respawn identity")
	sa.phase = "Run"
	assert(Rules.begin(r, a, "Steal", nil, 20, legal))
	assert(Rules.finish(r, a, "Steal", 22, legal, floor))
	assert(sa.shield == 14 and sa.shieldUsed, "shield reset farming")
	assert(Rules.hit(r, a, "Guardian", 25, floor()) and nextItem.state == "Dropped", "first-hit reset farming")
	assert(Rules.begin(r, b, "Grab", nil, 26, legal) == false, "home arena bypass")
	Rules.retire(r)
	Rules.audit(r)
	-- Intentionally corrupt state: audit must detect duplication/loss.
	sb.item = item
	assert(not pcall(Rules.audit, r), "audit missed duplicate holder")
	sb.item = nil
	nextItem.state = "Carried"
	nextItem.holder = c
	assert(not pcall(Rules.audit, r), "audit missed loss")
end
rulesTest()
print(
	"PASS contested nest/Grab; Bump/drop/settle; cooldown; shared mercy; reset protections; winner-only secure/place; conservation rejects loss/duplication"
)
-- Execute the production server eligibility adapter, with only roots/sight/floor mocked.
-- This checks real PvP rules and range code, not Humanoid movement or replication.
local function pvpLogicTest()
	local vector = require("@lune/roblox").Vector3
	local r, player, dummy, rival = Rules.new(Config), {}, {}, {}
	local s, ds, rs = Rules.actor(r, player), Rules.actor(r, dummy), Rules.actor(r, rival)
	local arena, otherArena = {}, {}
	for _, actorState in { s, ds, rs } do
		actorState.phase, actorState.run = "Run", arena
	end
	local roots = {
		[player] = { Position = vector.new(-62, 3, -56) },
		[dummy] = { Position = vector.new(0, 7, 32) },
		[rival] = { Position = vector.new(-62, 3, -56) },
	}
	local visible = true
	local source = fs.readFile("Greybox.server.luau")
	local beginAt = assert(string.find(source, "local function check(actor, action, target, item)", 1, true))
	local endAt = assert(string.find(source, "local function bumpTarget", beginAt, true))
	local check = luau.load(string.sub(source, beginAt, endAt - 1) .. "\nreturn check", {
		debugName = "production PvP eligibility",
		environment = {
			Vector3 = vector,
			arena = arena,
			states = r.actors,
			root = function(actor)
				return roots[actor]
			end,
			Arena = {
				safe = function(_, p)
					return Layout.protected(p.X, -p.Z)
				end,
				sight = function()
					return visible
				end,
			},
		},
	})()
	local item = Rules.spawn(r, vector.new(0, 4, 32))
	local function floor()
		return vector.new(-64, 0, -56)
	end
	assert(Rules.begin(r, dummy, "Steal", nil, 0, check))
	assert(Rules.finish(r, dummy, "Steal", 2.05, check, floor))
	local timestamp = item.firstPickup
	Rules.audit(r)
	roots[dummy].Position = vector.new(-64, 3, -56)
	assert(not Rules.begin(r, player, "Bump", dummy, 2, check), "PvP shield bypass")
	assert(check(player, "Bump", dummy, item), "live court range refused")
	roots[player].Position = vector.new(-59, 3, -56)
	assert(not check(player, "Bump", dummy, item), "live 4-stud range bypass")
	roots[player].Position = vector.new(-64, 6.1, -56)
	assert(not check(player, "Bump", dummy, item), "live vertical range bypass")
	roots[player].Position = vector.new(-62, 3, -56)
	visible = false
	assert(not check(player, "Bump", dummy, item), "live sight bypass")
	visible = true
	ds.run = otherArena
	assert(not check(player, "Bump", dummy, item), "live arena bypass")
	ds.run = arena
	roots[dummy].Position = vector.new(0, 3, 56)
	assert(not check(player, "Bump", dummy, item), "live safe victim bypass")
	roots[dummy].Position = vector.new(-64, 3, -56)
	assert(Rules.hit(r, dummy, "Guardian", 13.1, floor()))
	assert(Rules.begin(r, dummy, "Grab", nil, 14, check))
	assert(Rules.finish(r, dummy, "Grab", 14.45, check, floor))
	assert(not Rules.begin(r, player, "Bump", dummy, 14, check), "PvP mercy bypass")
	assert(Rules.begin(r, player, "Bump", dummy, 17.5, check))
	roots[player].Position = vector.new(-59, 3, -56)
	assert(not Rules.finish(r, player, "Bump", 17.95, check, floor), "range not rechecked on finish")
	roots[player].Position = vector.new(-62, 3, -56)
	assert(Rules.begin(r, player, "Bump", dummy, 19.6, check))
	assert(Rules.finish(r, player, "Bump", 20.05, check, floor))
	assert(item.state == "Dropped" and not ds.item and not s.item, "PvP direct grant/loss")
	assert(not Rules.begin(r, player, "Grab", nil, 20.64, check), "PvP settle precharge")
	assert(Rules.begin(r, player, "Grab", nil, 20.68, check))
	assert(Rules.begin(r, rival, "Grab", nil, 20.68, check))
	assert(Rules.finish(r, player, "Grab", 21.13, check, floor))
	assert(not Rules.finish(r, rival, "Grab", 21.13, check, floor), "PvP contested duplicate")
	assert(not Rules.finish(r, player, "Grab", 21.13, check, floor), "PvP replay accepted")
	assert(s.item == item and item.holder == player and item.firstPickup == timestamp, "PvP identity/holder")
	Rules.audit(r)
	assert(Rules.secure(r, player, 22))
	assert(not Rules.secure(r, player, 22), "PvP duplicate secure")
	assert(Rules.place(r, player) and not Rules.place(r, player), "PvP placement replay")
	assert(s.completed == 1 and ds.completed == 0 and item.state == "Placed", "PvP winner award")
	Rules.audit(r)
end
pvpLogicTest()
print(
	"PASS offline PvP production range/sight/height/arena/safe adapter; shield/mercy; hold revalidation; Bump/drop/settle/contested Grab/secure/place; same ID/time"
)
-- Height sampling against the actual generated ramps/boxes, at 0.5-stud steps.
local function height(l, x, z)
	local value = 0
	for _, g in l.gullies do
		if math.abs(x - g.x) < g.w / 2 and math.abs(z - g.z) < g.d / 2 then
			value = -3
		end
	end
	for _, b in l.solids do
		if b.role == "Floor" and math.abs(x - b.x) <= b.w / 2 and math.abs(z - b.z) <= b.d / 2 then
			value = math.max(value, b.y + b.h / 2)
		end
	end
	for _, r in l.ramps do
		local dx, dz = r.b.x - r.a.x, r.b.z - r.a.z
		local length = math.sqrt(dx * dx + dz * dz)
		local along = ((x - r.a.x) * dx + (z - r.a.z) * dz) / (length * length)
		local across = math.abs((x - r.a.x) * dz - (z - r.a.z) * dx) / length
		if along >= 0 and along <= 1 and across <= r.width / 2 then
			value = math.max(value, r.a.y + (r.b.y - r.a.y) * along)
		end
	end
	return value
end
-- Execute Arena.tick/attack with real Roblox value types and authored scalar
-- terrain. Navigation is frozen so targeting cannot rely on a successful path.
-- This is state-machine evidence, not live raycast/navmesh/physics evidence.
local function guardianLogicTest(seed)
	local roblox = require("@lune/roblox")
	local v, instance = roblox.Vector3, roblox.Instance
	local function map(x, y, z)
		return v.new(x, y, -z)
	end
	local layout = Layout.assemble(Config, seed, false)
	local floorPart = instance.new("Part")
	floorPart:SetAttribute("SurfaceRole", "Floor")
	local blocked = false
	local transitions = {}
	local function raycast(_, from, direction)
		if direction == map(0, -70, 0) then
			return {
				Position = v.new(from.X, height(layout, from.X, -from.Z), from.Z),
				Normal = v.yAxis,
				Instance = floorPart,
			}
		end
		if blocked then
			return { Instance = floorPart }
		end
		local samples = math.ceil(direction.Magnitude * 4)
		for i = 0, samples do
			local p = from + direction * (i / math.max(1, samples))
			if p.Y <= height(layout, p.X, -p.Z) then
				return { Instance = floorPart }
			end
			for _, b in layout.solids do
				if
					b.role == "Cover"
					and math.abs(p.X - b.x) <= b.w / 2
					and math.abs(-p.Z - b.z) <= b.d / 2
					and math.abs(p.Y - b.y) <= b.h / 2
				then
					return { Instance = floorPart }
				end
			end
		end
		return nil
	end
	local function loadArena(source)
		return luau.load(source, {
			debugName = "production guardian state machine",
			environment = {
				game = {
					GetService = function(_, name)
						return name == "ReplicatedStorage"
								and {
									WaitForChild = function(_, module)
										return module
									end,
								}
							or {}
					end,
				},
				require = function(module)
					return module == "GreyboxConfig" and Config or Layout
				end,
				Vector3 = v,
				CFrame = roblox.CFrame,
				Color3 = roblox.Color3,
				Instance = instance,
				Enum = roblox.Enum,
				workspace = {
					Raycast = raycast,
					Spherecast = function()
						return nil
					end,
					Blockcast = function()
						return nil
					end,
				},
				task = { spawn = function() end }, -- Freeze pathfinding/movement, not targeting.
				print = function(message)
					table.insert(transitions, message)
				end,
			},
		})()
	end
	local source = fs.readFile("Arena.luau")
	local arenaCode = loadArena(source)
	local dropArena = { origin = v.zero, layout = layout }
	for _, position in { map(-24, 6, -16), map(-10, 3, -10), map(79, 3, 79), map(95, -20, -28), map(-32, -20, -28) } do
		local floor = arenaCode.dropSocket(dropArena, position)
		assert(floor and not Layout.protected(floor.X, -floor.Z, 3), "drop missing/on safe apron")
		assert(math.abs(floor.X) <= 77 and math.abs(floor.Z) <= 77, "drop off island/edge")
		for ix = -6, 6 do
			for iz = -6, 6 do
				if ix * ix + iz * iz <= 36 then
					local x, z = floor.X + ix * 0.5, -floor.Z + iz * 0.5
					assert(math.abs(height(layout, x, z) - floor.Y) <= 2.15, "drop clearance cliff/wall")
					for _, b in layout.solids do
						assert(
							b.role ~= "Cover"
								or math.abs(x - b.x) > b.w / 2
								or math.abs(z - b.z) > b.d / 2
								or b.y + b.h / 2 <= floor.Y,
							"drop inside cover"
						)
					end
				end
			end
		end
		local minDistance = math.huge
		for i, candidate in dropArena.dropPoints do
			-- Resolve every candidate to independently verify global nearest choice.
			arenaCode.dropSocket(dropArena, map(candidate.x, candidate.y + 3, candidate.z))
			local valid = dropArena.dropFloors[i]
			if valid then
				minDistance = math.min(minDistance, (valid + map(0, 3, 0) - position).Magnitude)
			end
		end
		assert(
			math.abs((floor + map(0, 3, 0) - position).Magnitude - minDistance) < 0.01,
			"drop not nearest safe route spot"
		)
	end
	assert(
		arenaCode.outside(dropArena, map(95, 3, 0)) and arenaCode.outside(dropArena, map(0, -20, 0)),
		"fall detection"
	)
	assert(not arenaCode.outside(dropArena, map(-24, 6, -16)), "on-island cliff treated as fall")
	print(
		"PASS production drop projection: reported JumpLanding cliff, cover, edge and off-island falls; 3-stud clearance; nearest safe route spot seed="
			.. seed
	)
	local actor, rival = {}, {}
	local function scenario(code, options)
		transitions = {}
		blocked = options.blocked or false
		-- Lune instances do not derive Position when CFrame changes like Studio.
		local guard = setmetatable({
			CFrame = roblox.CFrame.new(options.guard or map(8, 13.5, 32)),
			Size = map(4, 11, 4),
		}, {
			__index = function(part, key)
				return key == "Position" and part.CFrame.Position or nil
			end,
		})
		local model = instance.new("Model")
		local a = {
			guardian = guard,
			arm = instance.new("Part"),
			model = model,
			warning = {},
			origin = v.zero,
			mode = options.mode or "Patrol",
			untilTime = 0,
			nextThrow = options.cooldown or 0,
			nextPath = 0,
			points = {},
			index = 1,
			patrol = 1,
			chaseTicks = 0,
			throws = 0,
			impacts = 0,
			chaseDistance = 0,
			targetSince = -10,
			lastSeen = map(0, 16 / 3 + 3.45, 8),
			searchAt = map(0, 16 / 3 + 3.45, 8),
		}
		local s = {
			phase = options.phase or "Run",
			item = {},
			mercy = options.mercy or 0,
		}
		if options.empty then
			s.item = nil
		end
		local actors = { [actor] = s }
		local roots = { [actor] = { Position = options.position or map(0, 16 / 3 + 3.45, 8) } }
		if options.rival then
			actors[rival], roots[rival] = { phase = "Run", mercy = 0 }, { Position = map(8, 7, 28) }
			a.target = rival
		end
		local function root(who)
			return roots[who]
		end
		if options.waypoint then
			a.points, a.index = { { Position = options.waypoint } }, 1
		end
		for i = 0, math.floor((options.seconds or 3) / 0.05) do
			local now = i * 0.05
			local before = guard.Position
			if options.walkReturn and a.mode == "Return" then
				a.points, a.index = { { Position = guard.Position.Z > -15.5 and map(0, 8, 16) or map(8, 8, 32) } }, 1
			end
			if options.revealAt and now >= options.revealAt then
				blocked = false
			end
			code.tick(a, 0.05, now, actors, root, function()
				error("unexpected offline hit")
			end, function() end)
			if options.walkReturn then
				assert(
					(guard.Position - before).Magnitude <= Config.GuardianReturnSpeed * 0.05 / math.cos(math.rad(35)),
					"return teleported"
				)
			end
			if a.attack then
				return a
			end
		end
		return a
	end
	for _, guard in { map(8, 13.5, 32), map(0, 13.5, 32), map(0, 13.5, 32) } do
		for _, x in { -0.5, 0, 2 } do
			for _, mode in { "Patrol", "Search" } do
				local a = scenario(arenaCode, { guard = guard, position = map(x, 16 / 3 + 3.45, 8), mode = mode })
				assert(
					a.attack and a.attack.disc and a.attack.actor == actor and a.attack.start <= 3,
					"carrier lane acquisition/throw >3s"
				)
				assert(
					a.attack.start >= Config.WarningSeconds and a.nextThrow == a.attack.start + Config.ThrowCooldown,
					"warning/cooldown changed"
				)
			end
		end
	end
	local oldSource, replaced = string.gsub(source, "distance <= range", "distance <= 24", 1)
	assert(replaced == 1, "old detection regression substitution missing")
	assert(
		not scenario(loadArena(oldSource), { seconds = 8 }).attack,
		"old 24-stud acquisition must reproduce missing throw"
	)
	assert(scenario(arenaCode, { rival = true, mode = "Chase" }).attack.actor == actor, "carrier preference lost")
	assert(
		scenario(arenaCode, { blocked = true, revealAt = 0.5, mode = "Search" }).attack.start <= 3,
		"visible reacquisition delayed"
	)
	for _, options in
		{
			{ empty = true },
			{ blocked = true },
			{ phase = "Home" },
			{ position = map(0, 3.45, -40) },
			{ position = map(80, 3.45, 8) },
			{ mercy = 4 },
			{ cooldown = 4 },
		}
	do
		assert(not scenario(arenaCode, options).attack, "guardian bypassed aggro/sight/phase/safe/range/mercy/cooldown")
	end
	local cooldown = scenario(arenaCode, { cooldown = 4, seconds = 8 })
	assert(
		cooldown.attack and cooldown.attack.disc and cooldown.attack.start >= 4 and cooldown.attack.start <= 8,
		"spent cooldown failed to reopen"
	)
	local poke = scenario(arenaCode, { guard = map(0, 16 / 3 + 5.5, 8) })
	assert(poke.attack and poke.attack.close and not poke.attack.disc, "close poke changed")
	for _, position in { map(-0.4, 16 / 3 + 3.45, 8), map(2.7, 16 / 3 + 3.45, 8) } do
		local hill =
			scenario(arenaCode, { guard = map(-44.3, 14, 5.9), position = position, cooldown = 4, seconds = 8 })
		assert(not hill.attack and hill.mode == "Return", "frozen navigation must keep walking return")
		assert((hill.guardian.Position - map(-44.3, 14, 5.9)).Magnitude < 0.1, "early return teleport")
		local logs = table.concat(transitions, "\n")
		assert(
			string.find(logs, "state=Return", 1, true) and not string.find(logs, "recovery poof", 1, true),
			"missing guardian transition logs"
		)
	end
	local stuck = scenario(arenaCode, { guard = map(0, 16 / 3 + 5.5, 8), blocked = true, seconds = 5 })
	assert(
		stuck.mode == "Return" and (stuck.guardian.Position - map(0, 16 / 3 + 5.5, 8)).Magnitude < 0.1,
		"failed path teleported early"
	)
	assert((stuck.pathVersion or 0) >= 1, "failed path recovery did not invalidate paths")
	local departure = scenario(arenaCode, { guard = map(0, 16 / 3 + 5.5, 8), blocked = true, seconds = 22.5 })
	assert(departure.recoveryStarted and departure.poof, "missing visible departure after long stall")
	assert((departure.guardian.Position - map(0, 16 / 3 + 5.5, 8)).Magnitude < 0.1, "poof must precede relocation")
	local recovered = scenario(arenaCode, { guard = map(0, 16 / 3 + 5.5, 8), blocked = true, seconds = 23.5 })
	assert((recovered.guardian.Position - map(8, 13.5, 32)).Magnitude < 0.1 and recovered.poof, "missing arrival poof")
	local walking = scenario(arenaCode, { guard = map(0, 5.5, 0), blocked = true, seconds = 7, walkReturn = true })
	assert(walking.mode == "Guard" and not walking.poof, "moving guardian must walk home without recovery")
	local leash =
		scenario(arenaCode, { guard = map(8, 5.5, 0.5), waypoint = map(8, 0, -4), blocked = true, seconds = 5 })
	assert(leash.mode == "Return" and not leash.poof, "blocked leash return teleported early")
	local slope = scenario(arenaCode, { guard = map(0, 13.5, 23), position = map(0, 16 / 3 + 3.45, 8) })
	assert(slope.attack and slope.attack.disc, "slope throw failed")
	local cover = { role = "Cover", x = 0, y = 2.6, z = 14, w = 10, h = 5.2, d = 2 }
	table.insert(layout.solids, cover)
	assert(scenario(arenaCode, { guard = map(0, 13.5, 32) }).attack, "low cover top blocked upper-body sight")
	cover.y, cover.h = 10, 20
	assert(not scenario(arenaCode, { guard = map(0, 13.5, 32) }).attack, "tall cover wall bypassed")
	table.remove(layout.solids)
	blocked = false
	local trapEnvironment = { Vector3 = v, CFrame = roblox.CFrame, Color3 = roblox.Color3, Enum = roblox.Enum }
	local Traps = luau.load(fs.readFile("Traps.luau"), { environment = trapEnvironment })()
	local TrapTest = luau.load(fs.readFile("TrapTest.luau"), { environment = trapEnvironment })()
	local trapArena = scenario(arenaCode, { phase = "Home", seconds = 0 })
	trapArena.layout = layout
	local manager = Traps.new(Config, arenaCode, function(parent, name, size, position, color)
		local p = instance.new("Part")
		p.Name, p.Size, p.Position, p.Color, p.Anchored, p.Parent = name, size, position, color, true, parent
		return p
	end, function()
		return {}
	end)
	local detail = TrapTest.exercise(Traps, manager, trapArena, {}, function()
		local attributes = {}
		local trapOwner = { UserId = -1 }
		function trapOwner:GetAttribute(key)
			return attributes[key]
		end
		function trapOwner:SetAttribute(key, value)
			attributes[key] = value
		end
		return trapOwner
	end, function(now, mode)
		arenaCode.tick(trapArena, 0.05, now, {}, function()
			return nil
		end, function()
			error("decoy player hit")
		end, function() end)
		assert(trapArena.mode == mode and not trapArena.attack, "guardian decoy reaction " .. mode)
	end)
	print("PASS GreyboxTrapTest seed=" .. seed .. ": " .. detail .. "; scalar geometry, mocked navigation")
	print(
		"PASS production guardian seed="
			.. seed
			.. ": frozen return stays put through 8s; recovery only after 20s stationary + visible departure/arrival poofs; moving return reaches Guard with bounded steps; terrace/slope throws; targeting rules preserved. Mock navigation; live Studio UNKNOWN."
	)
end
for _, seed in { 101, 202, 303 } do
	guardianLogicTest(seed)
end
-- Match the live preflight's radius/slope envelope using the scalar collision recipe.
-- This cannot replace Studio raycasts or Humanoid physics.
local function standable(l, p, edge)
	local center = height(l, p.x, p.z)
	assert(
		math.abs(center - p.y) < 0.7,
		"waypoint Y mismatch "
			.. tostring(p.name)
			.. " at "
			.. p.x
			.. ","
			.. p.z
			.. " expected="
			.. p.y
			.. " floor="
			.. center
	)
	for ix = -6, 6 do
		for iz = -6, 6 do
			if ix * ix + iz * iz <= 36 then
				local x, z = p.x + ix * 0.5, p.z + iz * 0.5
				local rise = height(l, x, z) - center
				assert(rise <= 2.15 and (edge or rise >= -2.15), "waypoint cliff/wall " .. tostring(p.name))
				for _, b in l.solids do
					if b.role == "Cover" then
						assert(
							math.abs(x - b.x) > b.w / 2 or math.abs(z - b.z) > b.d / 2 or b.y + b.h / 2 <= center,
							"waypoint clearance cover " .. b.name
						)
					end
				end
			end
		end
	end
end
-- Exercise the live movement runner's return branch, including the old failure.
local function automaticReturnTest()
	local roblox = require("@lune/roblox")
	local v = roblox.Vector3
	local source = fs.readFile("LoopTest.luau")
	local startAt = assert(string.find(source, "local function driver(", 1, true))
	local endAt = assert(string.find(source, "local function act(", startAt, true))
	local function scenario(automatic, invalidReturn, nearGoal, jump)
		local actor = { Character = {} }
		local cargo = { id = "regression:1", state = "Carried", holder = actor, escapeDeadline = 60 }
		local s = { phase = "Run", run = 1, item = cargo }
		local root = { Position = v.new(-42, 79, -304), SetNetworkOwner = function() end }
		if nearGoal then
			root.Position = v.new(-35.85, 79.45, -304)
		end
		local humanoid = { Health = 100, FloorMaterial = "Ground", Move = function() end, MoveTo = function() end }
		local driver = luau.load(string.sub(source, startAt, endAt - 1) .. "\nreturn driver", {
			environment = {
				Vector3 = v,
				Enum = { Material = { Air = "Air" } },
				os = {
					clock = function()
						return 10
					end,
				},
				task = {
					wait = function()
						assert(not nearGoal, "near-goal movement still required")
						-- Production home() clears run and teleports after Rules.secure().
						s.phase, s.run = "Home", nil
						cargo.state, cargo.securedAt = "Secured", invalidReturn == "late" and 60 or 10
						if invalidReturn == "lost" then
							s.item = nil
						end
						root.Position = v.new(0, 4, 84)
					end,
				},
			},
		})()
		local walk = driver(actor, { [actor] = s }, {
			root = function()
				return root, humanoid
			end,
			audit = function() end,
		}, function() end, function(p)
			return p
		end)
		return pcall(walk, v.new(-34, 79, -304), "west apron crossing", jump, automatic)
	end
	assert(scenario(false, nil, true), "reported 1.94-stud walk arrival rejected")
	assert(not scenario(false, nil, true, true), "jump accepted without takeoff/landing")
	assert(scenario(true), "legal automatic secure rejected")
	local ok, why = scenario(false)
	assert(not ok and string.find(why, "unexpected arena reset/return", 1, true), "old return failure not reproduced")
	assert(not scenario(true, "lost"), "return accepted lost cargo")
	assert(not scenario(true, "late"), "return accepted deadline tie")
	local winner = Layout.pvpRoutes().Winner
	for i = 1, #winner - 1 do
		assert(not Layout.protected(winner[i].x, winner[i].z), "winner approach enters apron")
	end
	local last = winner[#winner]
	assert(last.kind == "Return" and Layout.protected(last.x, last.z), "winner missing expected boundary return")
	assert(not Layout.protected(-38.01, -56) and Layout.protected(-38, -56), "west return boundary")
	assert(Layout.protected(-26, -56), "reported winner goal must trigger legal return")
	print(
		"PASS live driver legal automatic return; old unexpected-return reproduced; lost/late cargo rejected; west apron X=-38"
	)
end
automaticReturnTest()
-- Run the shared driver against momentum, plane crossings and watchdog traces.
local function waypointArrivalTest()
	local v = require("@lune/roblox").Vector3
	local source = fs.readFile("LoopTest.luau")
	local first = assert(source:find("local function driver(", 1, true))
	local last = assert(source:find("local function act(", first, true))
	local function scenario(start, goal, trace, options)
		options = options or {}
		local actor, time, waits, commands, stops = { Character = {} }, 0, 0, {}, 0
		local root = { Position = start, SetNetworkOwner = function() end }
		local h = {
			Health = 100,
			FloorMaterial = "Ground",
			Move = function()
				stops += 1
			end,
			MoveTo = function(_, p)
				table.insert(commands, { goal = p, time = time })
			end,
			ChangeState = function() end,
		}
		local driver = luau.load(source:sub(first, last - 1) .. "\nreturn driver", {
			environment = {
				Vector3 = v,
				SSS = { SetAttribute = function() end },
				Enum = { Material = { Air = "Air" }, HumanoidStateType = { Jumping = "Jumping" } },
				os = {
					clock = function()
						return time
					end,
				},
				task = {
					wait = function()
						waits += 1
						time += options.tick or 0.03
						local p, material = trace(waits)
						root.Position, h.FloorMaterial = p, material or "Ground"
					end,
				},
			},
		})()
		local walk = driver(actor, { [actor] = { phase = "Run", run = 1 } }, {
			root = function()
				return root, h
			end,
			audit = function() end,
		}, function() end, function(p)
			return p
		end)
		local ok, why =
			pcall(walk, goal, "arrival regression", options.jump, false, nil, nil, options.edge, nil, options.line)
		if ok and options.nextGoal then
			assert(walk(options.nextGoal, "next segment"), "next segment rejected")
		end
		return ok, why, waits, commands, stops, time
	end
	local goal = v.new(-57.1, 3, 33.5)
	for _, p in { v.new(-58.44, 3, 34.24), v.new(-57.94, 3, 31.92), v.new(-55.89, 3, 33.22), v.new(-55.72, 3, 35.17) } do
		for _, edge in { false, true } do
			local ok, _, waits, _, stops = scenario(p, goal, function()
				error("reported orbit should arrive before waiting")
			end, { edge = edge })
			assert(ok and waits == 0 and stops == 0, "reported orbit arrival rejected or momentum stopped")
		end
	end
	local ok, _, waits, commands, stops = scenario(v.new(0, 3, 0), v.new(10, 3, 0), function(i)
		return v.new(i == 1 and 14 or 24, 3, 4)
	end, { nextGoal = v.new(20, 3, 0) })
	assert(ok and waits == 2 and #commands == 2 and stops == 0, "passed goal / immediate next segment failed")
	assert(commands[2].time == 0.03, "next MoveTo delayed after arrival")
	ok, _, waits, commands, stops = scenario(v.new(0, 3, 0), v.new(10, 3, 0), function(i)
		return v.new(i == 1 and 9 or 10.2, 3, 2)
	end, { line = true, edge = true })
	assert(
		ok and waits == 2 and #commands == 1 and commands[1].goal.X == 13 and stops == 0,
		"run-up braked before line"
	)
	ok, _, waits, commands = scenario(v.new(10, 3, 0), v.new(10, 3, 0), function()
		error("already on run-up line should not wait")
	end, { line = true })
	assert(ok and waits == 0 and #commands == 0, "zero-length run-up stalled")
	local jumpReason
	ok, jumpReason, waits, commands = scenario(v.new(0, 3, 0), v.new(10, 3, 0), function(i)
		return v.new(14, 3, 4), i == 1 and "Air" or "Ground"
	end, { jump = true })
	assert(
		ok and waits == 2 and #commands == 1,
		"jump must observe airborne then grounded landing beyond goal: " .. tostring(jumpReason)
	)
	-- Along-route progress continues even while lateral drift increases point distance.
	ok, _, waits, commands = scenario(v.new(0, 3, 0), v.new(10, 3, 0), function(i)
		return v.new(i, 3, i * 5)
	end, { tick = 1 })
	assert(ok and waits == 10 and #commands == 1, "watchdog still measures distance to goal")
	local why, time
	ok, why, _, commands, _, time = scenario(v.new(0, 3, 0), v.new(20, 3, 0), function(i)
		return v.new(1, 3, i % 2 == 0 and 4 or -4)
	end, { tick = 1 })
	assert(
		not ok and why:find("stuck >8s", 1, true) and time == 10 and #commands == 1,
		"lateral orbit bypassed stuck detector"
	)
	print(
		"PASS shared waypoint arrival: four reported orbit positions; edge/walk/overshoot/jump/run-up line; immediate next MoveTo without stops; one command per segment; route-progress watchdog rejects lateral orbit. Mock physics."
	)
end
waypointArrivalTest()
local function loopInterruptionTest()
	local v = require("@lune/roblox").Vector3
	local source = fs.readFile("LoopTest.luau")
	local first = assert(source:find("local function driver(", 1, true))
	local last = assert(source:find("local function act(", first, true))
	local function interrupted(event, jump, duringReadiness)
		local actor = { Character = {} }
		local item = { id = "interrupt:1", state = "Carried", holder = actor, escapeDeadline = 60 }
		local state = { phase = "Run", run = 1, item = item, slowUntil = 0 }
		if event == "home" then
			state.phase, state.run, item.state, item.securedAt = "Home", nil, "Secured", 5
		end
		local time, waits, jumped = 10, 0, false
		local root = { Position = v.new(0, 3, 0), SetNetworkOwner = function() end }
		local humanoid = {
			Health = 100,
			FloorMaterial = duringReadiness and "Air" or "Ground",
			Move = function() end,
			MoveTo = function() end,
			ChangeState = function()
				jumped = true
			end,
		}
		local driver = luau.load(source:sub(first, last - 1) .. "\nreturn driver", {
			environment = {
				Vector3 = v,
				Enum = { Material = { Air = "Air" }, HumanoidStateType = { Jumping = "Jumping" } },
				os = {
					clock = function()
						return time
					end,
				},
				task = {
					wait = function()
						waits += 1
						assert(waits == 1, "event did not interrupt current step")
						time += 0.03
						if event == "drop" then
							state.item, item.state, item.holder = nil, "Dropped", nil
							state.slowUntil = time + 2
						elseif event == "stumble" then
							state.slowUntil = time + 2
						elseif event == "expiry" then
							time = 60
						elseif event == "home" then
							root.Position = v.new(20, 3, 0)
						else
							state.phase, state.run = "Home", nil
							item.state, item.securedAt = "Secured", time
						end
					end,
				},
			},
		})()
		local walk = driver(actor, { [actor] = state }, {
			root = function()
				return root, humanoid
			end,
			audit = function() end,
		}, function() end, function(p)
			return p
		end, { item = item })
		local reached, reason = walk(v.new(20, 3, 0), "interrupted step", jump, false, jump and v.new(10, 3, 0))
		assert(reached == (event == "secure" or event == "home"), "incorrect legal event outcome")
		if event == "home" then
			assert(waits == 1, "secured Home walk falsely completed without moving")
		elseif event ~= "secure" then
			assert(reason == event and not jumped, "jump/event race")
		end
	end
	for _, event in { "drop", "stumble", "expiry" } do
		interrupted(event, false, false)
		interrupted(event, true, false)
		interrupted(event, true, true)
	end
	interrupted("secure", false, false)
	interrupted("home", false, false)
	first = assert(source:find("local function recover(", 1, true))
	last = assert(source:find("-- Live production expiry:", first, true))
	local actor, time, item =
		{}, 10, { id = "recover:1", state = "Dropped", escapeDeadline = 60, firstPickup = 0, settle = 11 }
	local s = { phase = "Run", slowUntil = 12 }
	local states, rules = { [actor] = s }, { active = item }
	local walks, holds = 0, 0
	local api = {
		root = function()
			return nil, { Move = function() end }
		end,
		audit = function() end,
		rules = rules,
		holdAction = function(_, _, stage)
			assert(time >= 12, "Grab began during stumble")
			holds += 1
			if stage == "finish" then
				if holds == 2 then
					return false, "missing/short hold"
				end
				s.item, item.state = item, "Carried"
			end
			return true
		end,
	}
	local recover = luau.load(source:sub(first, last - 1) .. "\nreturn recover", {
		environment = {
			Config = Config,
			Vector3 = v,
			os = {
				clock = function()
					return time
				end,
			},
			task = {
				wait = function(seconds)
					time += math.max(seconds, 0.03)
				end,
			},
			recoveryPoint = function()
				return v.zero
			end,
		},
	})()
	local function walk()
		assert(time >= 12, "recovery walked during stumble")
		walks += 1
		return true
	end
	assert(recover(api, actor, states, walk, item, function() end, nil), "same-item recovery failed")
	assert(
		walks == 2 and holds == 4 and item.firstPickup == 0 and item.escapeDeadline == 60,
		"recovery changed identity/clock"
	)
	s.item, item.state, s.slowUntil, time = nil, "Dropped", 70, 59.99
	local recovered, reason = recover(api, actor, states, walk, item, function() end, nil)
	assert(not recovered and reason == "expiry" and walks == 2, "expiry during stumble attempted recovery")
	assert(not source:find("nearestRoute", 1, true), "recovery still selects fixed route nodes")
	first = assert(source:find("local function expiryExitSteps(", 1, true))
	last = assert(source:find("local function expiryTest(", first, true))
	local exit = luau.load(source:sub(first, last - 1) .. "\nreturn expiryExitSteps")()
	for seed = 1, 50 do
		local layout = Layout.assemble(Config, seed, false)
		local previous
		for _, p in exit() do
			standable(layout, p)
			if previous then
				local n = math.ceil(math.sqrt((p.x - previous.x) ^ 2 + (p.z - previous.z) ^ 2) * 2)
				for i = 0, n do
					local t = i / n
					local x, z = previous.x + (p.x - previous.x) * t, previous.z + (p.z - previous.z) * t
					assert(
						math.abs(height(layout, x, z) - (previous.y + (p.y - previous.y) * t)) < 0.7,
						"expiry exit leaves continuous ramp/floor"
					)
				end
			end
			previous = p
		end
	end
	print(
		"PASS loop driver walk/jump/readiness drop/stumble/expiry interruptions; legal secure at any step; stumble wait/retry/original clock; no nearest-node recovery"
	)
	print("PASS shared empty expiry exit across 50 seeds: supported terrace, ramp descent and reachable cyan boundary")
end
loopInterruptionTest()
-- Run the shared return completion code against phase/range/conservation races.
local function portalReturnTest()
	local v = require("@lune/roblox").Vector3
	local source = fs.readFile("LoopTest.luau")
	local first = assert(source:find("local function returnPortal(", 1, true))
	local last = assert(source:find("local function expiryTest(", first, true))
	local finish = luau.load(source:sub(first, last - 1) .. "\nreturn returnPortal", {
		environment = {
			Vector3 = v,
			act = function(api, actor, name)
				assert(api[name](actor), "illegal return")
			end,
		},
	})()
	for _, mode in { "manual", "automatic", "already-home", "empty", "out-of-range", "lost", "late", "drop" } do
		local actor, calls, paths, audits, inRange = {}, 0, 0, 0, false
		local item = { id = "portal:1", state = "Carried", escapeDeadline = 60, holder = nil }
		item.holder = actor
		local s = { phase = "Run", run = 1, item = mode ~= "empty" and item or nil }
		local function secure()
			s.phase, s.run = "Home", nil
			item.state, item.securedAt = "Secured", mode == "late" and 60 or 10
			if mode == "lost" then
				s.item = nil
			end
		end
		if mode == "already-home" then
			secure()
		end
		local api = {
			arena = function()
				return { dock = { Position = v.new(-24, 80, -302) } }
			end,
			floor = function(p)
				return p - v.new(0, 4, 0)
			end,
			returnInRange = function()
				return inRange
			end,
			returnRun = function()
				assert(s.phase == "Run" and inRange, "phase/range bypass")
				calls += 1
				secure()
				return true
			end,
			audit = function()
				audits += 1
			end,
		}
		local ok, result, reason = pcall(
			finish,
			actor,
			{ [actor] = s },
			api,
			function() end,
			function(goal, _, automatic)
				paths += 1
				assert(goal == v.new(-24, 79, -302), "did not pathfind to actual portal floor")
				assert(automatic == (mode ~= "empty"), "empty return waits for cargo auto-secure")
				if mode == "drop" then
					return false, "drop"
				end
				inRange = mode ~= "out-of-range"
				if mode == "automatic" or mode == "lost" or mode == "late" then
					secure()
				end
				return true
			end,
			mode ~= "empty" and item or nil
		)
		if mode == "out-of-range" or mode == "lost" or mode == "late" then
			assert(not ok and calls == 0, "invalid return accepted")
		elseif mode == "drop" then
			assert(
				ok and not result and reason == "drop" and calls == 0 and audits == 0,
				"drop did not interrupt return"
			)
		else
			assert(ok and result and audits == 1, "legal return failed: " .. tostring(result))
			assert(calls == ((mode == "manual" or mode == "empty") and 1 or 0), "duplicate/missing return action")
			assert(paths == (mode == "already-home" and 0 or 1), "path after automatic Home")
		end
	end
	print(
		"PASS shared portal return: live portal path, Run/range guard, automatic/already-Home conservation, empty return, drop retry, lost/late rejection. Navigation mocked."
	)
end
portalReturnTest()
-- Exercise real recovery follower code with deterministic navmesh/event traces.
local function pathRecoveryTest()
	local roblox = require("@lune/roblox")
	local v, source = roblox.Vector3, fs.readFile("LoopTest.luau")
	local first = assert(source:find("local function driver(", 1, true))
	local last = assert(source:find("local function act(", first, true))
	for _, mode in { "blocked", "stalled", "jump", "no-path" } do
		local actor, time, computes, cleaned, jumps = { Character = {} }, 0, 0, 0, 0
		local starts, blocked, target, airTicks = {}, nil, nil, 0
		local root = { Position = v.new(-60.74, 3.45, 0), SetNetworkOwner = function() end }
		local goal = root.Position + v.new(12, 0, 0)
		local h = { Health = 100, FloorMaterial = roblox.Enum.Material.Grass, Move = function() end }
		h.MoveTo = function(_, p)
			target = p
		end
		h.ChangeState = function()
			jumps += 1
			airTicks = 2
			h.FloorMaterial = roblox.Enum.Material.Air
		end
		local service = {
			CreatePath = function(_, options)
				assert(
					options.AgentRadius == 2
						and options.AgentHeight == 5
						and options.AgentCanJump
						and options.WaypointSpacing == 4
						and options.Costs.JumpGully == 20,
					"path recovery agent/cost mismatch"
				)
				return {
					Status = roblox.Enum.PathStatus.Success,
					ComputeAsync = function(self, start)
						computes += 1
						table.insert(starts, start)
						if mode == "no-path" and computes == 1 then
							self.Status = roblox.Enum.PathStatus.NoPath
						end
					end,
					GetWaypoints = function()
						return {
							{ Position = root.Position - v.new(0, 3, 0) },
							{
								Position = goal - v.new(0, 3, 0),
								Action = mode == "jump" and roblox.Enum.PathWaypointAction.Jump
									or roblox.Enum.PathWaypointAction.Walk,
							},
						}
					end,
					Blocked = {
						Connect = function(_, callback)
							blocked = callback
							return {
								Disconnect = function()
									blocked = nil
								end,
							}
						end,
					},
					Destroy = function()
						cleaned += 1
					end,
				}
			end,
		}
		local driver = luau.load(source:sub(first, last - 1) .. "\nreturn driver", {
			environment = {
				Vector3 = v,
				Enum = roblox.Enum,
				SSS = { SetAttribute = function() end },
				game = {
					GetService = function()
						return service
					end,
				},
				os = {
					clock = function()
						return time
					end,
				},
				task = {
					wait = function()
						time += 0.1
						if mode == "blocked" and computes == 1 and blocked then
							root.Position += v.new(1, 0, 0)
							blocked(2)
						elseif target and not (mode == "stalled" and computes == 1) then
							root.Position = target
						end
						if airTicks > 0 then
							airTicks -= 1
							h.FloorMaterial = airTicks == 0 and roblox.Enum.Material.Grass or roblox.Enum.Material.Air
						end
					end,
				},
			},
		})()
		local _, _, _, navigate = driver(actor, { [actor] = { phase = "Run", run = 1 } }, {
			root = function()
				return root, h
			end,
			audit = function() end,
		}, function() end, function()
			error("computed waypoints used authored validator")
		end)
		assert(navigate(goal, mode), "path follower failed " .. mode)
		assert(cleaned == computes and blocked == nil, "path/connection leaked")
		assert(computes == (mode == "jump" and 1 or 2), "missing recompute " .. mode)
		if mode == "blocked" then
			assert(starts[2] ~= starts[1], "recompute ignored live root")
		end
		if mode == "stalled" then
			assert(time >= 3 and time < 4, "stall recompute missed 3s")
		end
		if mode == "jump" then
			assert(jumps == 1, "Jump waypoint not executed")
		end
	end
	print(
		"PASS recovery path agent/costs; live-start Blocked and 3s stall recompute; Jump actions; NoPath retry; cleanup. Navmesh/physics mocked."
	)
end
pathRecoveryTest()
local function loopBatchTest()
	local source = fs.readFile("Greybox.server.luau")
	local first = assert(source:find('local runs = SSS:GetAttribute("GreyboxLoopTestRuns")', 1, true))
	local last = assert(source:find("\n\t\tend)", first, true))
	local function scenario(failAt, runs)
		local attributes, calls = { GreyboxLoopTestRuns = runs }, 0
		local batch = luau.load(source:sub(first, last - 1), {
			environment = {
				SSS = {
					GetAttribute = function(_, name)
						return attributes[name]
					end,
					SetAttribute = function(_, name, value)
						attributes[name] = value
					end,
				},
				log = function() end,
				runner = {
					run = function()
						calls += 1
						assert(calls ~= failAt, "injected harness error")
						return "conserved", calls == 2 and "expiry" or "placed"
					end,
				},
			},
		})
		local ok, result = pcall(batch)
		return ok, result, attributes, calls
	end
	local ok, result, attributes, calls = scenario(nil, nil)
	assert(ok and calls == 3 and result == "3/3 passed; 1 legal expiries; 2 placed", "default batch outcome")
	assert(attributes.GreyboxLoopTestPassCount == 3 and attributes.GreyboxLoopTestExpiryCount == 1, "batch counts")
	ok, result, attributes, calls = scenario(3, 3)
	assert(not ok and calls == 3 and attributes.GreyboxLoopTestPassCount == 2, "partial batch incorrectly passed")
	assert(result:find("2/3 passed; loop 3 harness error", 1, true), "partial batch lost error/count")
	assert(not scenario(nil, 2), "fewer than three loops could unlock PASS")
	print(
		"PASS default 3-loop batch: conserved expiry counts as legal loss; 2/3 harness failure rejected; minimum 3 runs"
	)
end
loopBatchTest()
local function loopExpiryOutcomeTest()
	local v = require("@lune/roblox").Vector3
	local source = fs.readFile("LoopTest.luau")
	local first = assert(source:find("local function verifyExpiry(", 1, true))
	local last = assert(source:find("local function expiryExitSteps(", first, true))
	local function scenario(orphan)
		local actor, time = {}, 59.99
		local rules = Rules.new(Config)
		local s = Rules.actor(rules, actor)
		s.phase, s.slot = "Run", 1
		local item = Rules.spawn(rules, v.zero)
		item.state, item.holder, item.firstPickup, item.escapeDeadline = "Carried", actor, 0, 60
		s.item, s.hold = item, { item = item }
		local world = {
			GetAttribute = function()
				return rules.active and rules.active.escapeDeadline
			end,
		}
		local api = {
			rules = rules,
			audit = function()
				Rules.audit(rules)
			end,
			placeItem = function()
				return false
			end,
			holdAction = function()
				return false
			end,
		}
		local verify = luau.load(source:sub(first, last - 1) .. "\nreturn verifyExpiry", {
			environment = {
				Config = Config,
				os = {
					clock = function()
						return time
					end,
				},
				task = {
					wait = function(seconds)
						time += seconds
						Rules.expire(rules, time)
						if orphan then
							item.weld = true
						end
						if not rules.active and time >= rules.respawnAt then
							Rules.spawn(rules, v.zero)
						end
					end,
				},
				workspace = {
					GetDescendants = function()
						return {
							{
								IsA = function()
									return true
								end,
								GetAttribute = function()
									return rules.active and rules.active.id
								end,
							},
						}
					end,
				},
			},
		})()
		local replacement = verify(actor, rules.actors, { { count = 0 } }, world, api, function() end, item, 0, 0)
		assert(
			replacement.id ~= item.id and not replacement.escapeDeadline and not s.hold,
			"expiry stale identity/hold"
		)
	end
	assert(pcall(scenario, false), "legal live expiry outcome rejected")
	assert(not pcall(scenario, true), "expiry orphan weld incorrectly passed")
	print(
		"PASS loop expiry outcome: clean loss/no award; new Nest ID without deadline; exact physical conservation; orphan rejected"
	)
end
loopExpiryOutcomeTest()
local function retestRound3()
	local roblox = require("@lune/roblox")
	local v = roblox.Vector3
	local now, fallen, poofs = 10, true, 0
	local source = fs.readFile("Greybox.server.luau")
	local first = assert(string.find(source, "local function presentDrop(", 1, true))
	local last = assert(string.find(source, "local function expireLoot(", first, true))
	local present, recover =
		luau.load(string.sub(source, first, last - 1) .. "\nreturn presentDrop, recoverFallenLoot", {
			environment = {
				Config = Config,
				Vector3 = v,
				Enum = roblox.Enum,
				world = {},
				root = function()
					return { Position = v.zero }
				end,
				Arena = {
					outside = function()
						return fallen
					end,
				},
				os = {
					clock = function()
						return now
					end,
				},
				visual = function(item)
					item.visual = { Transparency = item.recoverAt and 1 or 0 }
				end,
				part = function()
					poofs += 1
					return {}
				end,
				TweenInfo = {
					new = function()
						return {}
					end,
				},
				TweenService = {
					Create = function()
						return { Play = function() end }
					end,
				},
				Debris = { AddItem = function() end },
			},
		})()
	local r, actor = Rules.new(Config), {}
	local s = Rules.actor(r, actor)
	s.phase = "Run"
	local item = Rules.spawn(r, v.zero)
	local function legal()
		return true
	end
	assert(Rules.begin(r, actor, "Steal", nil, 0, legal))
	assert(Rules.finish(r, actor, "Steal", 2, legal))
	local id, deadline = item.id, item.escapeDeadline
	assert(Rules.drop(r, actor, now, v.zero))
	present(item, actor)
	assert(item.recoverAt == 11 and item.visual.Transparency == 1 and not item.bounceAt, "fall must hide for 1s")
	now = 10.99
	recover(item, now)
	assert(poofs == 0 and item.visual.Transparency == 1, "early fall recovery")
	assert(not Rules.begin(r, actor, "Grab", nil, now, legal), "hidden treasure grabbed")
	now = 11
	recover(item, now)
	assert(poofs == 1 and item.visual.Transparency == 0 and item.bounceAt == 11, "missing 1s respawn/poof")
	recover(item, now)
	assert(poofs == 1 and item.id == id and item.escapeDeadline == deadline, "duplicate poof/deadline refresh")
	assert(not Rules.begin(r, actor, "Grab", nil, now, legal), "recovery skipped settle")
	assert(Rules.begin(r, actor, "Grab", nil, item.settle, legal), "recovered treasure unavailable")
	fallen = false
	present(item, actor)
	assert(not item.recoverAt and item.visual.Transparency == 0, "ordinary drop delayed")

	source = fs.readFile("LoopTest.luau")
	first = assert(string.find(source, "local function closeToDummy(", 1, true))
	last = assert(string.find(source, "local function recover(", first, true))
	local close = luau.load(string.sub(source, first, last - 1) .. "\nreturn closeToDummy", {
		environment = { Vector3 = v, os = {
			clock = function()
				return now
			end,
		} },
	})()
	local player, dummy = {}, {}
	local pr, dr = { Position = v.new(-59.85, 3.44, 56.20) }, { Position = v.new(-65.36, 3, 54.63) }
	local walks = 0
	local api = {
		root = function(who)
			return who == player and pr or dr
		end,
		floor = function(p)
			return v.new(p.X, 0, p.Z)
		end,
	}
	close(api, function(target)
		walks += 1
		pr.Position = target
		if walks == 1 then
			dr.Position += v.new(-4, 0, 0) -- Movement after the first live snapshot.
		end
	end, player, dummy)
	assert(walks == 2 and (pr.Position - dr.Position).Magnitude <= 3, "failed to follow live displaced dummy")
	print(
		"PASS production 1s hidden fall recovery/poof/settle with original ID/deadline; reported PvP root separation and moving-dummy recheck"
	)
end
retestRound3()
local function gullyRetest()
	local roblox = require("@lune/roblox")
	local v = roblox.Vector3
	local l = Layout.assemble(Config, 101, true)
	for _, ramp in l.ramps do
		if ramp.name == "RecoveryWest" or ramp.name == "RecoveryEast" then
			local previous = -3
			for i = 0, 100 do
				local t = i / 100
				local x = ramp.a.x + (ramp.b.x - ramp.a.x) * t
				local y = height(l, x, ramp.a.z)
				assert(y >= previous and y - previous < 0.7, "gully escape has a wall/seam")
				previous = y
			end
			assert(previous == 0, "gully escape does not join bank")
		end
	end
	-- Conservative center trajectory at default gravity, without avatar edge overlap.
	for _, p in Layout.loopCarrySteps(l) do
		if p.takeoff then
			local edge = p.takeoff
			local dx, dz = p.x - edge.x, p.z - edge.z
			local distance = math.sqrt(dx * dx + dz * dz)
			local landing
			for _, b in l.solids do
				if b.role == "Floor" and math.abs(p.x - b.x) <= b.w / 2 and math.abs(p.z - b.z) <= b.d / 2 then
					if not landing or b.y + b.h / 2 > landing.y + landing.h / 2 then
						landing = b
					end
				end
			end
			assert(landing, "missing jump landing")
			local required = 0
			while required <= distance do
				local x, z = edge.x + dx / distance * required, edge.z + dz / distance * required
				if math.abs(x - landing.x) <= landing.w / 2 and math.abs(z - landing.z) <= landing.d / 2 then
					break
				end
				required += 0.01
			end
			local gravity = 196.2
			local velocity = math.sqrt(2 * gravity * Config.CarryJumpHeight)
			local flight = (velocity + math.sqrt(velocity ^ 2 - 2 * gravity * (p.y - edge.y))) / gravity
			local range = flight * Config.CarrySpeed
			assert(range - required >= 0.75, "carrying jump has insufficient landing margin")
			print(
				string.format(
					"CARRY JUMP %s required=%.2f range=%.2f margin=%.2f (default gravity, inferred)",
					p.name,
					required,
					range,
					range - required
				)
			)
		end
	end
	local source = fs.readFile("LoopTest.luau")
	local first = assert(source:find("local function driver(", 1, true))
	local last = assert(source:find("local function act(", first, true))
	local actor, time, direction, jumped, pathOptions = { Character = {} }, 0, v.zero, false, nil
	local root = { Position = v.new(-43, 4, -34), SetNetworkOwner = function() end }
	local h = {
		Health = 100,
		FloorMaterial = "Ground",
		Move = function(_, d)
			direction = d
		end,
		MoveTo = function(_, p)
			direction = (p - root.Position).Unit
		end,
		ChangeState = function()
			assert(root.Position.X >= -39.95 and root.Position.X < -39.3, "jump before/after takeoff marker")
			jumped = true
		end,
	}
	local driver = luau.load(source:sub(first, last - 1) .. "\nreturn driver", {
		environment = {
			Vector3 = v,
			Enum = {
				Material = { Air = "Air" },
				HumanoidStateType = { Jumping = "Jumping" },
				PathStatus = { Success = "Success" },
			},
			game = {
				GetService = function()
					return {
						CreatePath = function(_, options)
							pathOptions = options
							return {
								Status = "Success",
								Blocked = {
									Connect = function()
										return { Disconnect = function() end }
									end,
								},
								Destroy = function() end,
								ComputeAsync = function() end,
								GetWaypoints = function()
									return {}
								end,
							}
						end,
					}
				end,
			},
			os = {
				clock = function()
					return time
				end,
			},
			task = {
				wait = function()
					time += 0.03
					root.Position += direction * Config.CarrySpeed * 0.03
					if jumped then
						root.Position = v.new(root.Position.X, 0.45, root.Position.Z)
					end
				end,
			},
		},
	})()
	local walk, _, _, navigate = driver(actor, { [actor] = { phase = "Run", run = 1 } }, {
		root = function()
			return root, h
		end,
		audit = function() end,
	}, function() end, function(p)
		return p
	end)
	local reached, reason =
		walk(v.new(-31, 5, -34), "reported four-stud miss", true, false, v.new(-39.8, 4, -34), v.new(-46.4, 4, -34))
	assert(not reached and reason == "missed jump" and jumped and time < 8, "missed jump waited for stuck timeout")
	assert(navigate(root.Position, "live recovery"), "live recovery rejected")
	assert(
		pathOptions.AgentCanJump
			and pathOptions.AgentRadius == 2
			and pathOptions.AgentHeight == 5
			and pathOptions.WaypointSpacing == 4
			and pathOptions.Costs.JumpGully == 20,
		"recovery agent/cost mismatch"
	)
	local server = fs.readFile("Greybox.server.luau")
	first = assert(server:find("\t\tif Arena.outside(arena, r.Position) then", 1, true))
	last = assert(server:find("\t\tif s.item and Arena.safe", first, true))
	for _, carrying in { false, true } do
		for _, recorded in { false, true } do
			local item = { id = "void:1", firstPickup = 0, escapeDeadline = 60 }
			local state = { item = carrying and item or nil, lastSafe = recorded and v.new(-43, 80, -326) or nil }
			local pivot, drops = nil, 0
			local fallenRoot = { Position = v.new(-35.5, 60, -326), AssemblyLinearVelocity = v.new(0, -80, 0) }
			local fallenActor = { Character = {
				PivotTo = function(_, cf)
					pivot = cf.Position
				end,
			} }
			luau.load("for _ = 1, 1 do\n" .. server:sub(first, last - 1) .. "\nend", {
				environment = {
					s = state,
					r = fallenRoot,
					actor = fallenActor,
					arena = {},
					Vector3 = v,
					CFrame = roblox.CFrame,
					Arena = {
						outside = function()
							return true
						end,
						position = function(_, x, y, z)
							return v.new(x, 76 + y, -360 - z)
						end,
					},
					drop = function()
						assert(not pivot, "fall drop must precede player recovery")
						drops += 1
						state.item = nil
					end,
				},
			})()
			assert(pivot == (state.lastSafe or v.new(0, 79, -302)), "void fall did not restore last safe spot")
			assert(drops == (carrying and 1 or 0), "void fall changed treasure drop rules")
			assert(
				fallenRoot.AssemblyLinearVelocity == v.zero and fallenRoot.AssemblyAngularVelocity == v.zero,
				"fall velocity retained"
			)
			assert(
				item.id == "void:1" and item.firstPickup == 0 and item.escapeDeadline == 60,
				"fall refreshed treasure identity/clock"
			)
		end
	end
	print(
		"PASS production driver straight run-up/edge launch; reported Y0.45 miss caught before 8s; live path recovery; both bank ramps continuous; void recovery with/without cargo and last safe spot. Movement/navigation mocked."
	)
end
gullyRetest()
for seed = 1, 50 do
	local l = Layout.assemble(Config, seed, false)
	for _, p in Layout.referencePoints(l) do
		standable(l, p)
	end
	for _, p in Layout.dodgePoints() do
		standable(l, p)
	end
	assert(not pcall(standable, l, { x = 0, y = 0, z = 8 }), "old dodge Y mismatch not reproduced")
	local routes = table.clone(l.routes)
	for i, route in l.crossLinks do
		routes["CrossLink" .. i] = route
	end
	for i, route in Layout.hillPaths(l) do
		routes["SummitPath" .. i] = route
	end
	local carry = { { x = 0, y = 8, z = 32, kind = "Walk" } }
	for _, p in Layout.loopCarrySteps(l) do
		standable(l, p)
		if p.kind == "Jump" then
			local edge = assert(p.takeoff, "missing live takeoff edge")
			local start = assert(p.runup, "missing straight run-up")
			standable(l, start, true)
			standable(l, edge, true)
			assert(math.abs(height(l, edge.x, edge.z) - edge.y) < 0.1, "takeoff not on authored floor")
			local runup = math.sqrt((edge.x - start.x) ^ 2 + (edge.z - start.z) ^ 2)
			assert(runup >= 6.5, "jump run-up shorter than six studs plus arrival tolerance")
			local dx, dz = p.x - edge.x, p.z - edge.z
			assert(math.abs((edge.x - start.x) * dz - (edge.z - start.z) * dx) < 0.001, "crooked run-up")
			table.insert(carry, start)
			-- Check the grounded lead-in separately; only the airborne segment may skip cliffs.
			table.insert(carry, { x = edge.x, y = edge.y, z = edge.z, kind = "Walk" })
		end
		table.insert(carry, p)
	end
	routes.CarryingLoop = carry
	for name, route in Layout.pvpRoutes() do
		routes["PvP" .. name] = route
		for _, p in route do
			standable(l, p)
		end
	end
	for _, p in l.routes.Quick do
		standable(l, p)
	end
	for name, route in routes do
		for i = 2, #route do
			local a, b = route[i - 1], route[i]
			local count = math.ceil(math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2) * 2)
			local last = height(l, a.x, a.z)
			for n = 0, count do
				local t = n / count
				local x, z = a.x + (b.x - a.x) * t, a.z + (b.z - a.z) * t
				assert(
					math.abs(x) < Config.IslandSize / 2 - 1 and math.abs(z) < Config.IslandSize / 2 - 1,
					"route envelope " .. name
				)
				local y = height(l, x, z)
				assert(
					math.abs(y - last) <= 0.65 or b.kind == "Jump" or (b.kind == "Recovery" and y <= last),
					"walk route cliff/gully seed=" .. seed .. " " .. name .. " step=" .. i .. " x=" .. x .. " z=" .. z
				)
				assert(
					b.kind == "Jump" or b.kind == "Recovery" or math.abs(y - (a.y + (b.y - a.y) * t)) < 0.7,
					"route disagrees with actual floor " .. name .. " step=" .. i
				)
				for _, box in l.solids do
					if box.role == "Cover" then
						assert(
							math.abs(x - box.x) >= box.w / 2 + 1.5
								or math.abs(z - box.z) >= box.d / 2 + 1.5
								or y >= box.y + box.h / 2,
							"route hits cover " .. name .. " step=" .. i
						)
					end
				end
				last = y
			end
		end
	end
	for _, g in l.gullies do
		assert(g.w >= 24 and g.d >= 24, "recovery volume")
	end
end
local first = Layout.assemble(Config, 101, true)
print("PASS both disc-dodge destinations across 50 seeds; old Y0 at Z8 rejected; CampSouthRamp Y=16/3")
for _, p in
	{
		{ x = -10, y = 0, z = -10 }, -- inside cover
		{ x = -15, y = 0, z = -10 }, -- less than 3 studs from cover
		{ x = -31, y = 0, z = -34 }, -- wrong gully/stone height
	}
do
	assert(not pcall(standable, first, p), "bad waypoint accepted")
end
local carry = { { x = 0, y = 8, z = 32 } }
for _, p in Layout.loopCarrySteps(first) do
	table.insert(carry, p)
end
print(string.format("MEASURE simplified nest-to-cyan route %.2f studs", Layout.length(carry)))
print("PASS 50-seed solo/PvP waypoint 3-stud clearance; bad waypoint negatives; PvP court/pacing/mercy/exit paths")
for name, route in first.routes do
	print(
		string.format(
			"MEASURE route %s %.2f studs (authored points; excludes pad approach)",
			name,
			Layout.length(route)
		)
	)
end
print(
	"PASS 50-seed actual 3D walking-floor, cliff, cover-clearance checks; same segments reversible. Live jump/navmesh UNKNOWN."
)
if fs.isFile("guardian-greybox.rbxl") then
	local roblox = require("@lune/roblox")
	local place = roblox.deserializePlace(fs.readFile("guardian-greybox.rbxl"))
	for _, map in
		{
			{ "ServerScriptService", "Greybox", "Greybox.server.luau" },
			{ "ServerScriptService", "GreyboxLoopTestRunner", "LoopTest.luau" },
			{ "ServerScriptService", "GreyboxArena", "Arena.luau" },
			{ "ReplicatedStorage", "GreyboxTraps", "Traps.luau" },
			{ "ServerScriptService", "GreyboxTrapTestRunner", "TrapTest.luau" },
			{ "ReplicatedStorage", "GreyboxConfig", "GreyboxConfig.luau" },
			{ "ReplicatedStorage", "GreyboxLayout", "Layout.luau" },
			{ "ReplicatedStorage", "GreyboxScene", "Scene.luau" },
			{ "ReplicatedStorage", "GreyboxLootRules", "LootRules.luau" },
			{ "ReplicatedStorage", "GreyboxPlacement", "Placement.luau" },
		}
	do
		local node = place:FindFirstChild(map[1]):FindFirstChild(map[2])
		assert(node and node.Source == fs.readFile(map[3]), "built source mismatch " .. map[3])
	end
	assert(
		place.StarterPlayer.StarterPlayerScripts.Greybox.Source == fs.readFile("Greybox.client.luau"),
		"client source mismatch"
	)
	local sss = place.ServerScriptService
	assert(
		sss:GetAttribute("GreyboxLoopTestRuns") == 3
			and sss:GetAttribute("GreyboxLoopTestPassCount") == 0
			and sss:GetAttribute("GreyboxLoopTestExpiryCount") == 0,
		"batch defaults/results fabricated"
	)
	for _, mode in { "GreyboxLoopTest", "GreyboxPvpTest", "GreyboxTrapTest" } do
		assert(
			sss:GetAttribute(mode) == false
				and sss:GetAttribute(mode .. "Success") == false
				and sss:GetAttribute(mode .. "Result") == "NOT RUN",
			"fabricated runtime result"
		)
	end
	print("PASS built binary sources; loop/PvP/trap runtime gates NOT RUN")
end
