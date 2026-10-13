-- Reference silhouettes made only from native Parts. Collision remains authored.
local Scene = {}
local function lookAt(eye, target)
	local forward = (target - eye).Unit
	local right = forward:Cross(Vector3.yAxis).Unit
	return CFrame.fromMatrix(eye, right, right:Cross(forward).Unit, -forward)
end
local grass = Color3.fromRGB(111, 158, 85)
local rock = Color3.fromRGB(113, 122, 137)
local stone = Color3.fromRGB(180, 173, 157)
local wood = Color3.fromRGB(136, 96, 61)
local cyan = Color3.fromRGB(65, 220, 240)
local function cosmetic(p)
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p:SetAttribute("SurfaceRole", "Scenery")
	return p
end
function Scene.underside(parent, origin, width, depth, make)
	-- Broad strata with staggered cliff columns and a tapered hanging core.
	for i, scale in { 1, 0.88, 0.64, 0.36 } do
		local h = i == 1 and 12 or 14
		local p = make(
			parent,
			"FloatingRockStratum" .. i,
			Vector3.new(width * scale, h, depth * scale),
			origin + Vector3.new(0, -10 - (i - 1) * 13, 0),
			rock
		)
		p.Material = Enum.Material.Slate
		p:SetAttribute("SurfaceRole", "Underside")
	end
	for i = 0, 15 do
		local angle = i * math.pi / 8
		local x, z = math.cos(angle) * (width / 2 - 7), math.sin(angle) * (depth / 2 - 7)
		local h = 18 + i % 4 * 5
		local p =
			make(parent, "HangingCliff" .. i, Vector3.new(16, h, 16), origin + Vector3.new(x, -h / 2 - 5, z), rock)
		p.Material = Enum.Material.Slate
		p:SetAttribute("SurfaceRole", "Underside")
	end
end
function Scene.lantern(parent, position, make)
	cosmetic(make(parent, "LanternPost", Vector3.new(0.8, 6, 0.8), position + Vector3.new(0, 3, 0), wood))
	cosmetic(make(parent, "LanternCap", Vector3.new(2.8, 0.5, 2.8), position + Vector3.new(0, 6.8, 0), wood))
	local lamp = cosmetic(
		make(
			parent,
			"LanternLight",
			Vector3.new(1.7, 2, 1.7),
			position + Vector3.new(0, 5.6, 0),
			Color3.fromRGB(255, 218, 113)
		)
	)
	lamp.Material = Enum.Material.Neon
end
function Scene.tree(parent, position, make, size)
	size = size or 1
	cosmetic(make(parent, "TreeTrunk", Vector3.new(3, 14, 3) * size, position + Vector3.new(0, 7, 0) * size, wood))
	for i, d in { { 0, 17, 0, 13 }, { -4, 15, 0, 9 }, { 4, 16, 1, 9 }, { 0, 23, 0, 8 } } do
		local p = cosmetic(
			make(
				parent,
				"BlockCanopy" .. i,
				Vector3.new(d[4], 8, d[4]) * size,
				position + Vector3.new(d[1], d[2], d[3]) * size,
				grass
			)
		)
		p.Material = Enum.Material.Grass
	end
end
function Scene.portal(parent, position, radius, make, locked)
	-- Arch segments leave a real opening. The cyan disc is never a collision wall.
	for i = 0, 11 do
		local angle = i * math.pi / 11
		local p = cosmetic(
			make(
				parent,
				"PortalArchStone" .. i,
				Vector3.new(radius * 0.43, radius * 0.32, 3),
				position + Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0),
				rock
			)
		)
		p.CFrame *= CFrame.Angles(0, 0, angle + math.pi / 2)
	end
	for _, side in { -1, 1 } do
		cosmetic(
			make(
				parent,
				"PortalFoot",
				Vector3.new(3, radius, 3),
				position + Vector3.new(side * radius, -radius / 2, 0),
				rock
			)
		)
	end
	local disc = cosmetic(
		make(
			parent,
			locked and "LockedPortalDisc" or "CyanPortalDisc",
			Vector3.new(0.3, radius * 1.65, radius * 1.65),
			position,
			locked and Color3.fromRGB(88, 101, 126) or cyan
		)
	)
	disc.Shape = Enum.PartType.Cylinder
	disc.CFrame = CFrame.new(position) * CFrame.Angles(0, math.pi / 2, 0)
	disc.Material = locked and Enum.Material.SmoothPlastic or Enum.Material.Neon
	return disc
end
local function floor(parent, name, size, position, make, color)
	local p = make(parent, name, size, position, color or stone)
	p:SetAttribute("SurfaceRole", "Floor")
	return p
end
function Scene.home(parent, make, label)
	local home = Instance.new("Model")
	home.Name, home.Parent = "HomeFloatingIsland", parent
	floor(home, "HomeGrass", Vector3.new(216, 4, 320), Vector3.new(0, -2, 0), make, grass).Material =
		Enum.Material.Grass
	Scene.underside(home, Vector3.zero, 216, 320, make)
	cosmetic(make(home, "CentralStonePath", Vector3.new(40, 0.08, 280), Vector3.new(0, 0.04, 0), stone))
	-- Broad walking ramp into the cyan arch, as in home v2.
	local start, finish = Vector3.new(0, 0, 38), Vector3.new(0, 3, 21)
	local approach =
		floor(home, "MeadowApproachRamp", Vector3.new(26, 1, (finish - start).Magnitude), (start + finish) / 2, make)
	approach.CFrame = lookAt((start + finish) / 2, finish) * CFrame.new(0, -0.5, 0)
	floor(home, "MeadowStepLanding", Vector3.new(26, 3, 8), Vector3.new(0, 1.5, 18), make)
	local pad = floor(home, "RoundMeadowPlatform", Vector3.new(3, 32, 32), Vector3.new(0, 1.5, 0), make)
	pad.Shape = Enum.PartType.Cylinder
	pad.CFrame = CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.pi / 2)
	Scene.portal(home, Vector3.new(0, 13, 0), 10, make, false)
	local action = cosmetic(make(home, "HomePortal", Vector3.new(1, 1, 1), Vector3.new(0, 5, 8), cyan))
	action.Transparency = 1
	label(action, "Meadow / Enter Meadow")
	floor(home, "LockedPortalTerrace", Vector3.new(144, 6, 30), Vector3.new(0, 3, -144), make, grass)
	for i = 1, 6 do
		floor(
			home,
			"TerraceStep" .. i,
			Vector3.new(24, 3 + i * 0.5, 3),
			Vector3.new(0, 1.5 + i * 0.25, -98.5 - i * 3),
			make
		)
	end
	floor(home, "TerraceLanding", Vector3.new(24, 6, 14), Vector3.new(0, 3, -123), make)
	for i, name in { "Crystal Cave", "Frost Peak", "Volcano", "Ocean" } do
		local x = -54 + (i - 1) * 36
		local locked = Scene.portal(home, Vector3.new(x, 12, -146), 6, make, true)
		locked:SetAttribute("Destination", name)
		label(locked, name .. " / LOCKED")
	end
	for _, z in { -96, -32, 32, 96 } do
		for _, x in { -17, 17 } do
			Scene.lantern(home, Vector3.new(x, 0, z), make)
		end
	end
	-- Open stall: columns, counter, pitched roof and striped awning.
	for _, x in { -14, 14 } do
		for _, z in { 135, 154 } do
			cosmetic(make(home, "ShopPost", Vector3.new(2, 12, 2), Vector3.new(x, 6, z), wood))
		end
	end
	cosmetic(make(home, "ShopCounter", Vector3.new(28, 4, 5), Vector3.new(0, 2, 136), wood))
	for _, side in { -1, 1 } do
		local roof = cosmetic(make(home, "ShopRoof", Vector3.new(17, 1.2, 24), Vector3.new(side * 7.5, 13, 145), wood))
		roof.CFrame *= CFrame.Angles(0, 0, -side * math.rad(18))
	end
	for i = 0, 6 do
		cosmetic(
			make(
				home,
				"ShopAwning",
				Vector3.new(4, 0.6, 7),
				Vector3.new(-12 + i * 4, 9, 139),
				i % 2 == 0 and grass or Color3.fromRGB(230, 225, 200)
			)
		)
	end
	label(
		cosmetic(make(home, "ShopSign", Vector3.new(26, 3, 1), Vector3.new(0, 11, 140), wood)),
		"Steal a Treasure / Shop"
	)
	for _, x in { -67, 67 } do
		Scene.tree(home, Vector3.new(x, 6, -150), make, 1.15)
	end
	return action
end
function Scene.pen(parent, x, z, make)
	-- Open plot, twelve-wide inward gate, no earning pads.
	for _, dz in { -24, 24 } do
		for _, y in { 1.4, 3.4 } do
			cosmetic(make(parent, "PenRail", Vector3.new(64, 0.8, 0.8), Vector3.new(x, y, z + dz), wood))
		end
		for dx = -32, 32, 16 do
			cosmetic(make(parent, "PenPost", Vector3.new(1.4, 4.5, 1.4), Vector3.new(x + dx, 2.25, z + dz), wood))
		end
	end
	local back = x + (x < 0 and -32 or 32)
	for _, y in { 1.4, 3.4 } do
		cosmetic(make(parent, "PenBackRail", Vector3.new(0.8, 0.8, 48), Vector3.new(back, y, z), wood))
	end
	local front = x + (x < 0 and 32 or -32)
	for _, side in { -1, 1 } do
		for _, y in { 1.4, 3.4 } do
			cosmetic(make(parent, "PenGateRail", Vector3.new(0.8, 0.8, 18), Vector3.new(front, y, z + side * 15), wood))
		end
	end
	cosmetic(make(parent, "PenAccessPath", Vector3.new(32, 0.06, 8), Vector3.new(x < 0 and -36 or 36, 0.23, z), stone))
end
function Scene.meadow(parent, origin, layout, make)
	Scene.underside(parent, origin, 160, 160, make)
	local function map(x, y, z)
		return Vector3.new(x, y, -z)
	end
	-- Paths expose the three escape choices and the two shared cross-links.
	local paths = {}
	for name, route in layout.routes do
		table.insert(paths, { route = route, width = name == "Quick" and 16 or 12 })
	end
	for _, route in layout.crossLinks do
		table.insert(paths, { route = route, width = 12 })
	end
	for _, ramp in layout.ramps do
		table.insert(paths, { route = { ramp.a, ramp.b }, width = ramp.width })
	end
	for _, path in paths do
		for i = 2, #path.route do
			local a, b = path.route[i - 1], path.route[i]
			local start, finish = map(a.x, a.y, a.z), map(b.x, b.y, b.z)
			local p = cosmetic(
				make(
					parent,
					"MeadowStonePath",
					Vector3.new(path.width, 0.06, (finish - start).Magnitude),
					origin + (start + finish) / 2,
					stone
				)
			)
			p.CFrame = lookAt(origin + (start + finish) / 2, origin + finish) * CFrame.new(0, 0.04, 0)
		end
	end
	for _, p in parent:GetDescendants() do
		if p:IsA("BasePart") then
			if
				p.Name:find("Mountain")
				or p.Name:find("GroveHill")
				or p.Name == "CampTerrace"
				or p.Name == "IslandGround"
			then
				p.Color, p.Material = grass, Enum.Material.Grass
			end
		end
	end
	-- Explicit twelve-wide ground bypass south of the optional stone chain.
	cosmetic(make(parent, "StoneWalkingBypass", Vector3.new(44, 0.06, 12), origin + map(-32, 0.04, -46), stone))
	for _, d in
		{
			{ -68, 0, 60 },
			{ -62, 0, -66 },
			{ 65, 0, -64 },
			{ 68, 0, 42 },
			{ -54, 10, 12 },
			{
				40,
				8,
				12,
			},
		}
	do
		Scene.tree(parent, origin + map(d[1], d[2], d[3]), make, 0.8)
	end
	for _, d in
		{
			{ -18, 0, -46 },
			{ 18, 0, -46 },
			{ -18, 0, -22 },
			{ 18, 0, -22 },
			{ -16, 4, 46 },
			{
				16,
				4,
				46,
			},
		}
	do
		Scene.lantern(parent, origin + map(d[1], d[2], d[3]), make)
	end
	Scene.portal(parent, origin + map(-24, 9, -58), 9, make, false)
end
function Scene.skyIslands(parent, make)
	for _, d in
		{
			{ "Crystal Cave", 190, 120, -280, 70 },
			{ "Frost Peak", -230, 188, -480, 82 },
			{ "Volcano", 360, 260, -600, 94 },
			{ "Ocean", 260, 44, -220, 78 },
		}
	do
		local model = Instance.new("Model")
		model.Name, model.Parent = d[1] .. "Vista", parent
		model:SetAttribute("SceneryOnly", true)
		model:SetAttribute("IslandHeight", d[3])
		local o = Vector3.new(d[2], d[3], d[4])
		floor(model, "FloatingGrassCap", Vector3.new(d[5], 4, d[5]), o - Vector3.new(0, 2, 0), make, grass)
		Scene.underside(model, o, d[5], d[5], make)
		for i = 1, 3 do
			local size = d[5] * (0.65 - i * 0.12)
			cosmetic(make(model, "IslandPeak" .. i, Vector3.new(size, 12, size), o + Vector3.new(0, i * 10, 5), rock))
		end
		if d[1] == "Frost Peak" then
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") and (p.Name:find("Peak") or p.Name == "FloatingGrassCap") then
					p.Color = Color3.fromRGB(230, 242, 250)
				end
			end
		elseif d[1] == "Crystal Cave" then
			for _, dx in { -16, 0, 16 } do
				local crystal = cosmetic(
					make(
						model,
						"CrystalSpire",
						Vector3.new(7, 22 + math.abs(dx), 7),
						o + Vector3.new(dx, 15, -5),
						Color3.fromRGB(155, 85, 235)
					)
				)
				crystal.Material = Enum.Material.Neon
			end
		elseif d[1] == "Volcano" then
			cosmetic(
				make(
					model,
					"LavaFall",
					Vector3.new(8, 66, 3),
					o + Vector3.new(0, -10, -d[5] / 2),
					Color3.fromRGB(255, 110, 25)
				)
			).Material =
				Enum.Material.Neon
		else
			cosmetic(make(model, "OceanLagoon", Vector3.new(38, 0.1, 38), o + Vector3.new(0, 0.1, 0), cyan))
		end
		Scene.tree(model, o + Vector3.new(-20, 0, -10), make, 0.8)
	end
end
function Scene.captureCams(parent, enabled, meadowOrigin)
	local existing = parent:FindFirstChild("CaptureCameras")
	if existing then
		existing:Destroy()
	end
	if not enabled then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "CaptureCameras", parent
	for _, d in
		{
			{
				"HomeReferenceCamera",
				Vector3.new(0, 150, 260),
				Vector3.new(0, 4, 0),
				55,
				"home-island.png",
			},
			{
				"MeadowReferenceCamera",
				meadowOrigin + Vector3.new(0, 64, 132),
				meadowOrigin + Vector3.new(0, 4, -10),
				58,
				"meadow-island.png",
			},
		}
	do
		local p = Instance.new("Part")
		p.Name, p.Size, p.Anchored = d[1], Vector3.new(1, 1, 1), true
		p.CFrame, p.Transparency = lookAt(d[2], d[3]), 1
		p.CanCollide, p.CanQuery, p.CanTouch, p.Parent = false, false, false, folder
		p:SetAttribute("Reference", d[5])
		p:SetAttribute("FieldOfView", d[4])
		p:SetAttribute("LookTarget", d[3])
		local camera = Instance.new("Camera")
		camera.Name, camera.CFrame, camera.FieldOfView, camera.Parent = "Camera", p.CFrame, d[4], p
	end
end
return Scene
