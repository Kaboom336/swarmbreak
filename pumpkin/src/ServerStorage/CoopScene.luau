--!strict
-- Authored cooperative arena. Art is copied only from inspected, bundled assets.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local CoopScene = {}
local ORIGIN = Vector3.new(10000, 50, 0)
local cached: any = nil
local allowed = {
	Model = true,
	Folder = true,
	MeshPart = true,
	Part = true,
	WedgePart = true,
	SpecialMesh = true,
	SurfaceAppearance = true,
	Texture = true,
	Decal = true,
	PointLight = true,
}
local orange = Color3.fromRGB(255, 150, 43)
local cream = Color3.fromRGB(255, 235, 173)
local wood = Color3.fromRGB(105, 61, 44)
local plum = Color3.fromRGB(75, 57, 104)

local function position(x: number, y: number, z: number): Vector3
	return ORIGIN + Vector3.new(x, y, z)
end

local function safeCopy(source: Instance): Instance
	assert(allowed[source.ClassName], "Unsupported art root: " .. source.ClassName)
	local copy = source:Clone()
	-- Nothing is parented into the DataModel until the complete clone has been scrubbed.
	for _, descendant in copy:GetDescendants() do
		if not allowed[descendant.ClassName] then
			descendant:Destroy()
		end
	end
	for _, descendant in copy:GetDescendants() do
		assert(not descendant:IsA("LuaSourceContainer"), "Executable art rejected")
	end
	return copy
end

local function template(parent: Instance, name: string): Instance
	local found = parent:FindFirstChild(name, true)
	assert(found, "Bundled art missing: " .. name)
	return found
end

local function art(
	parent: Instance,
	source: Instance,
	name: string,
	at: Vector3,
	height: number,
	yaw: number?
): Model
	local model: Model
	local copy = safeCopy(source)
	if copy:IsA("Model") then
		model = copy
	else
		model = Instance.new("Model")
		copy.Parent = model
	end
	model.Name = name
	local _, bounds = model:GetBoundingBox()
	model:ScaleTo(model:GetScale() * height / bounds.Y)
	local frame, scaled = model:GetBoundingBox()
	local destination = CFrame.new(at + Vector3.new(0, scaled.Y / 2, 0))
		* CFrame.Angles(0, yaw or 0, 0)
	model:PivotTo(destination * frame:Inverse() * model:GetPivot())
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
	model.Parent = parent
	return model
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	frame: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local value = Instance.new("Part")
	value.Name = name
	value.Size = size
	value.CFrame = frame
	value.Color = color
	value.Material = material or Enum.Material.SmoothPlastic
	value.Anchored = true
	value.TopSurface = Enum.SurfaceType.Smooth
	value.BottomSurface = Enum.SurfaceType.Smooth
	value.Parent = parent
	return value
end

local function sign(
	parent: Instance,
	name: string,
	title: string,
	at: Vector3,
	width: number,
	subtitle: string?
): BasePart
	local board = part(parent, name, Vector3.new(width, 4.3, 0.65), CFrame.new(at), plum)
	board.CanCollide = false
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(width * 70, 300)
		gui.LightInfluence = 0
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Name = if name == "ProgressBoard" then "ProgressText" else "Title"
		label.Size = UDim2.fromScale(0.94, if subtitle then 0.64 else 0.92)
		label.Position = UDim2.fromScale(0.03, 0.04)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.Text = title
		label.TextColor3 = cream
		label.TextScaled = true
		label.Parent = gui
		if subtitle then
			local line = label:Clone()
			line.Name = "Subtitle"
			line.Text = subtitle
			line.Size = UDim2.fromScale(0.94, 0.23)
			line.Position = UDim2.fromScale(0.03, 0.72)
			line.TextColor3 = orange
			line.Parent = gui
		end
	end
	for _, offset in { -width * 0.38, width * 0.38 } do
		part(
			parent,
			name .. "Post",
			Vector3.new(0.8, at.Y - ORIGIN.Y - 2.15, 0.8),
			CFrame.new(at.X + offset, ORIGIN.Y + (at.Y - ORIGIN.Y - 2.15) / 2, at.Z),
			wood,
			Enum.Material.Wood
		)
	end
	return board
end

local function valleyHeight(z: number): number
	return math.min(0, (z + 18) * 0.065)
end

function CoopScene.build(): any
	if cached and cached.model.Parent then
		return cached
	end
	local map = Workspace:WaitForChild("PumpkinMap")
	local pets = ServerStorage:WaitForChild("PetModels")
	local pumpkinArt = template(map:WaitForChild("Zone_PumpkinPatch"), "Pumpkin")
	local jackArt = template(map:WaitForChild("Zone_PumpkinPatch"), "JackOLantern")
	local scarecrowArt = template(map:WaitForChild("Zone_PumpkinPatch"), "Scarecrow")
	local lampArt = template(map:WaitForChild("Zone_PumpkinPatch"), "LampPost")
	local treeArt = template(map:WaitForChild("Zone_HauntedForest"), "DeadTree")
	local autumnArt = template(map:WaitForChild("Trees"), "AutumnTree")
	local graveArt = template(map:WaitForChild("Zone_Graveyard"), "Gravestone")
	local ghostArt = { template(pets, "Gummy Ghost"), template(pets, "Misty Ghost") }
	local previous = Workspace:FindFirstChild("CoopScene")
	if previous then
		assert(previous:GetAttribute("PumpkinCoopOwned") == true, "CoopScene name already occupied")
		previous:Destroy()
	end
	local scene = Instance.new("Model")
	scene.Name = "CoopScene"
	scene:SetAttribute("PumpkinCoopOwned", true)
	scene.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	scene.Parent = Workspace

	-- Smooth terrain is a continuous walkable valley, not an exposed platform in a void.
	local terrain = Workspace.Terrain
	terrain:FillBlock(
		CFrame.new(position(0, -22, -60)),
		Vector3.new(230, 34, 300),
		Enum.Material.Grass
	)
	terrain:FillBlock(
		CFrame.new(position(0, -12, -74)) * CFrame.Angles(math.rad(-3.72), 0, 0),
		Vector3.new(185, 16, 240),
		Enum.Material.Grass
	)
	terrain:FillBlock(
		CFrame.new(position(0, -5, 23)),
		Vector3.new(155, 10, 82),
		Enum.Material.Grass
	)
	for _, x in { -95, 95 } do
		for index = 1, 6 do
			local z = 50 - index * 35
			terrain:FillBall(
				position(x, -5 + valleyHeight(z), z),
				24 + index % 3 * 4,
				Enum.Material.Grass
			)
		end
	end
	-- Thin dirt beds and curved gravel plaza read as farming surfaces, beneath the mesh art.
	local plaza = part(
		scene,
		"HarvestPlaza",
		Vector3.new(0.35, 40, 40),
		CFrame.new(position(0, 0.2, 17)) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(186, 159, 115),
		Enum.Material.Sand
	)
	plaza.Shape = Enum.PartType.Cylinder
	part(
		scene,
		"LaunchTerrace",
		Vector3.new(70, 0.45, 20),
		CFrame.new(position(0, 0.25, -8)),
		Color3.fromRGB(151, 129, 100),
		Enum.Material.Cobblestone
	)
	local patches = {}
	for row = 1, 3 do
		for column = 1, 3 do
			local x, z = -23 + column * 8, 15 + row * 8
			part(
				scene,
				"SoilBed",
				Vector3.new(6.8, 0.4, 6.8),
				CFrame.new(position(x, 0.25, z)),
				Color3.fromRGB(92, 60, 46),
				Enum.Material.Ground
			)
			local model =
				art(scene, pumpkinArt, "HarvestPumpkin", position(x, 0.55, z), 3.6, column * 0.35)
			local root = model:FindFirstChildWhichIsA("BasePart", true)
			assert(root, "Inspected pumpkin mesh missing")
			root.Name = "Patch_" .. tostring(#patches + 1)
			root:SetAttribute("PatchId", #patches + 1)
			table.insert(patches, root)
		end
	end
	art(scene, scarecrowArt, "PatchKeeper", position(-22, 0, 31), 8, math.pi)
	sign(
		scene,
		"PatchSign",
		"PUMPKIN PATCH",
		position(-4, 9, 43),
		26,
		"PICK  •  CARRY  •  LAUNCH"
	)

	local launchers = {}
	for index, x in { -18, 0, 18 } do
		local mechanism = Instance.new("Model")
		mechanism.Name = "Catapult_" .. index
		mechanism.Parent = scene
		local root = part(
			mechanism,
			"Launcher_" .. index,
			Vector3.new(5.8, 1.1, 7.4),
			CFrame.new(position(x, 1.1, -8)),
			wood,
			Enum.Material.WoodPlanks
		)
		-- The root is the gameplay launch position; the timber chassis sits below it.
		root.CFrame = CFrame.new(position(x, 4, -10))
		root.Transparency = 1
		root.CanCollide = false
		part(
			mechanism,
			"Chassis",
			Vector3.new(5.8, 1.1, 7.4),
			CFrame.new(position(x, 1.05, -8)),
			wood,
			Enum.Material.WoodPlanks
		)
		for _, side in { -2.65, 2.65 } do
			part(
				mechanism,
				"AFrame",
				Vector3.new(0.7, 5, 0.8),
				CFrame.new(position(x + side, 3, -8)) * CFrame.Angles(math.rad(-18), 0, 0),
				wood,
				Enum.Material.Wood
			)
			for _, z in { -5.7, -10.3 } do
				local wheel = part(
					mechanism,
					"Wheel",
					Vector3.new(0.7, 2.7, 2.7),
					CFrame.new(position(x + side, 1.1, z)),
					Color3.fromRGB(70, 47, 46),
					Enum.Material.Wood
				)
				wheel.Shape = Enum.PartType.Cylinder
			end
		end
		local axle = part(
			mechanism,
			"Axle",
			Vector3.new(6.7, 0.7, 0.7),
			CFrame.new(position(x, 4.15, -8)),
			Color3.fromRGB(171, 145, 92),
			Enum.Material.Metal
		)
		axle.Shape = Enum.PartType.Cylinder
		part(
			mechanism,
			"ThrowingArm",
			Vector3.new(1, 0.7, 8),
			CFrame.new(position(x, 4.1, -7)) * CFrame.Angles(math.rad(-22), 0, 0),
			Color3.fromRGB(178, 110, 52),
			Enum.Material.Wood
		)
		part(
			mechanism,
			"Cup",
			Vector3.new(2.8, 0.5, 2.8),
			CFrame.new(position(x, 5.5, -3.6)),
			Color3.fromRGB(223, 167, 83),
			Enum.Material.Wood
		)
		art(mechanism, jackArt, "PumpkinEmblem", position(x, 1.2, -4), 2.3)
		root:SetAttribute("LauncherId", index)
		table.insert(launchers, root)
	end
	sign(
		scene,
		"CatapultSign",
		"CATAPULT",
		position(0, 11, -19),
		23,
		"LOAD WITH FRIENDS • AIM AT GHOSTS"
	)

	local targets = {}
	for row, z in { -60, -90, -120, -145 } do
		local lanes = if row == 4 then { -22, 0, 22 } else { -27, -9, 9, 27 }
		for lane, x in lanes do
			local size = 6.5 + row * 0.5
			local model = art(
				scene,
				ghostArt[(lane + row) % 2 + 1],
				"GhostArt",
				position(x, valleyHeight(z) + 7 - size / 2, z),
				size,
				math.pi
			)
			local body = model:FindFirstChildWhichIsA("BasePart", true)
			assert(body and body:IsA("MeshPart"), "Inspected ghost mesh missing")
			body.Parent = scene
			body.Name = "GhostTarget_" .. tostring(#targets + 1)
			body:SetAttribute("TargetId", #targets + 1)
			body:SetAttribute("GhostAlive", true)
			body.CanQuery = true
			model:Destroy()
			table.insert(targets, body)
			art(
				scene,
				graveArt,
				"GhostGrave",
				position(x + 4.2, valleyHeight(z), z + 2),
				3.4,
				math.pi
			)
		end
	end

	-- Warm patch framing opens onto a cooler, sparse haunted valley; sightlines stay clear.
	for index, tuple in
		{
			{ -46, 42, 19 },
			{ 49, 40, 22 },
			{ -55, 11, 23 },
			{ 54, 4, 20 },
		}
	do
		art(
			scene,
			autumnArt,
			"AutumnCanopy_" .. index,
			position(tuple[1], 0, tuple[2]),
			tuple[3],
			index * 1.1
		)
	end
	for index = 1, 14 do
		local z = -32 - math.floor((index - 1) / 2) * 21
		local x = if index % 2 == 0 then 61 + index % 3 * 4 else -61 - index % 3 * 4
		art(
			scene,
			treeArt,
			"HauntedTree_" .. index,
			position(x, valleyHeight(z), z),
			17 + index % 4 * 2,
			index * 0.8
		)
		art(
			scene,
			jackArt,
			"PathLantern_" .. index,
			position(x * 0.83, valleyHeight(z), z + 4),
			2.3,
			math.pi
		)
	end
	for _, tuple in { { -36, 28 }, { 38, 28 }, { -38, -8 }, { 38, -8 } } do
		art(scene, lampArt, "PlazaLamp", position(tuple[1], 0, tuple[2]), 9)
	end
	art(scene, jackArt, "HarvestHero", position(-33, 0, 41), 8.5, math.pi)
	art(scene, pumpkinArt, "HeroCompanion", position(-40, 0, 37), 4.5)

	local shop = part(
		scene,
		"UpgradeShop",
		Vector3.new(9, 1.3, 6),
		CFrame.new(position(31, 1.8, 21)),
		wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { 27, 35 } do
		for _, z in { 19, 23 } do
			part(
				scene,
				"CounterLeg",
				Vector3.new(0.8, 1.5, 0.8),
				CFrame.new(position(x, 0.75, z)),
				wood,
				Enum.Material.Wood
			)
		end
		part(
			scene,
			"MarketPost",
			Vector3.new(0.7, 8, 0.7),
			CFrame.new(position(x, 4, 23)),
			wood,
			Enum.Material.Wood
		)
	end
	part(
		scene,
		"MarketCanopy",
		Vector3.new(11, 0.6, 8),
		CFrame.new(position(31, 8.3, 22)) * CFrame.Angles(0, 0, math.rad(-4)),
		orange,
		Enum.Material.Fabric
	)
	art(scene, jackArt, "ShopDisplay", position(28, 2.5, 20), 2.1, math.pi)
	sign(
		scene,
		"UpgradeSign",
		"UPGRADES",
		position(31, 11, 25),
		17,
		"BIGGER PUMPKINS • MORE POWER"
	)
	local progress = sign(
		scene,
		"ProgressBoard",
		"GHOST WAVE",
		position(33, 9, 2),
		22,
		"CLEAR THE VALLEY TOGETHER"
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CoopSpawn"
	spawn.Size = Vector3.new(8, 0.3, 8)
	spawn.CFrame = CFrame.new(position(8, 0.5, 25))
	spawn.Transparency = 1
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = scene
	-- Invisible owned boundary keeps the complete walkable valley contained.
	for _, tuple in
		{ { -108, -60, 1, 300 }, { 108, -60, 1, 300 }, { 0, 88, 216, 1 }, { 0, -208, 216, 1 } }
	do
		local boundary = part(
			scene,
			"ValleyBoundary",
			Vector3.new(tuple[3], 80, tuple[4]),
			CFrame.new(position(tuple[1], 15, tuple[2])),
			plum
		)
		boundary.Transparency = 1
	end
	Lighting.ClockTime = 17.2
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(143, 127, 165)
	Lighting.OutdoorAmbient = Color3.fromRGB(162, 171, 186)
	Lighting.ExposureCompensation = 0.1
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("BloomEffect") then
			effect.Intensity = 0.12
			effect.Threshold = 2.2
		elseif effect:IsA("Atmosphere") then
			effect.Density = 0.18
			effect.Haze = 0.7
			effect.Color = Color3.fromRGB(190, 204, 238)
		end
	end
	cached = {
		model = scene,
		spawn = CFrame.new(position(8, 4, 25)),
		patches = patches,
		launchers = launchers,
		targets = targets,
		shop = shop,
		progress = progress,
	}
	return cached
end

return CoopScene
