--!strict
-- Authored garden using the project's inspected mesh art. No external insertions.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local GardenScene = {}
local ORIGIN = Vector3.new(20000, 50, 0)
local cached: any = nil
local pumpkinSource: Instance? = nil
local orange = Color3.fromRGB(255, 157, 43)
local cream = Color3.fromRGB(255, 238, 190)
local cyan = Color3.fromRGB(98, 231, 236)
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

local function at(x: number, y: number, z: number): Vector3
	return ORIGIN + Vector3.new(x, y, z)
end

local function source(parent: Instance, name: string): Instance
	local found = parent:FindFirstChild(name, true)
	assert(found, "Inspected garden art missing: " .. name)
	return found
end

local function copyArt(parent: Instance, asset: Instance, name: string, height: number): Model
	assert(allowed[asset.ClassName], "Unsupported art root")
	local clone = asset:Clone()
	-- Scrub the complete clone before any descendant is placed in the DataModel.
	for _, item in clone:GetDescendants() do
		if not allowed[item.ClassName] then
			item:Destroy()
		end
	end
	assert(not clone:IsA("LuaSourceContainer"), "Executable art rejected")
	local model: Model
	if clone:IsA("Model") then
		model = clone
	else
		model = Instance.new("Model")
		clone.Parent = model
	end
	model.Name = name
	local _, bounds = model:GetBoundingBox()
	model:ScaleTo(model:GetScale() * height / math.max(bounds.Y, 0.01))
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable art rejected")
		if item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
		end
	end
	model.Parent = parent
	return model
end

local function place(model: Model, bottom: Vector3, yaw: number?)
	local frame, bounds = model:GetBoundingBox()
	model:PivotTo(
		CFrame.new(bottom + Vector3.new(0, bounds.Y / 2, 0))
			* CFrame.Angles(0, yaw or 0, 0)
			* frame:Inverse()
			* model:GetPivot()
	)
end

local function marker(parent: Instance, name: string, position: Vector3): Part
	local value = Instance.new("Part")
	value.Name = name
	value.Size = Vector3.new(1, 1, 1)
	value.CFrame = CFrame.new(position)
	value.Transparency = 1
	value.Anchored = true
	value.CanCollide = false
	value.CanTouch = false
	value.CanQuery = false
	value.Parent = parent
	return value
end

local function label(parent: BasePart, text: string, color: Color3, width: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "GardenLabel"
	gui.Size = UDim2.fromOffset(width or 230, 56)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 65
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 1)
	title.Font = Enum.Font.FredokaOne
	title.Text = text
	title.TextSize = 22
	title.TextColor3 = color
	title.TextStrokeColor3 = Color3.fromRGB(56, 37, 73)
	title.TextStrokeTransparency = 0.2
	title.Parent = gui
	return title
end

function GardenScene.createPumpkin(parent: Instance, diameter: number): Model
	assert(pumpkinSource, "Build garden before creating pumpkins")
	local model = Instance.new("Model")
	model.Name = "LivingJack"
	model:SetAttribute("BaseDiameter", diameter)
	local root = marker(model, "Root", Vector3.zero)
	model.PrimaryPart = root
	local shell = copyArt(model, pumpkinSource, "RibbedShell", diameter)
	place(shell, Vector3.new(0, -diameter / 2, 0))
	-- Attached seams are deliberately broad enough to read at normal play distance.
	-- Three zig-zag paths expose a warm seed core progressively; they remain FX,
	-- while the actual silhouette, stem and carved face come from the bundled mesh.
	for seam = 1, 3 do
		local angle = (seam - 2) * 1.05
		for segment = 1, 3 do
			local crack = Instance.new("Part")
			crack.Name = "Crack_" .. seam .. "_" .. segment
			crack.Size = Vector3.new(diameter * 0.035, diameter * 0.19, diameter * 0.028)
			local y = (segment - 2) * diameter * 0.16
			local radius = diameter * 0.56 * math.sqrt(math.max(0.2, 1 - (y / (diameter / 2)) ^ 2))
			crack.CFrame = CFrame.new(math.sin(angle) * radius, y, -math.cos(angle) * radius)
				* CFrame.Angles(0, -angle, if segment % 2 == 0 then 0.32 else -0.32)
			crack.Material = Enum.Material.Neon
			crack.Color = cream
			crack.Transparency = 1
			crack.Anchored = true
			crack.CanCollide = false
			crack.CanTouch = false
			crack.CanQuery = false
			crack:SetAttribute("Seam", seam)
			crack.Parent = model
		end
	end
	model.Parent = parent
	return model
end

function GardenScene.setShell(model: Model, remaining: number, maximum: number)
	local exposed = math.clamp(math.ceil((1 - remaining / math.max(1, maximum)) * 3), 0, 3)
	for _, item in model:GetDescendants() do
		local seam = item:GetAttribute("Seam")
		if item:IsA("BasePart") and type(seam) == "number" then
			item.Transparency = if seam <= exposed then 0.08 else 1
		end
	end
	model:SetAttribute("ShellRemaining", remaining)
	model:SetAttribute("ShellMaximum", maximum)
end

function GardenScene.setCrop(crop: BasePart, diameter: number, visible: boolean)
	local body = crop:FindFirstChild("LivingJack")
	if not body then
		body = GardenScene.createPumpkin(crop, math.max(0.4, diameter))
	end
	assert(body:IsA("Model"), "Crop art must be a model")
	local base = body:GetAttribute("BaseDiameter")
	body:ScaleTo(math.max(0.05, diameter / base))
	body:PivotTo(crop.CFrame + Vector3.new(0, diameter / 2, 0))
	for _, item in body:GetDescendants() do
		if item:IsA("BasePart") and item.Name ~= "Root" and not item:GetAttribute("Seam") then
			item.Transparency = if visible then 0 else 1
		end
	end
end

function GardenScene.createPlot(userId: number, slot: number): any
	assert(cached, "Build garden before creating plots")
	local row = math.floor((slot - 1) / 8)
	local column = (slot - 1) % 8
	local x, z = -84 + column * 24, 26 + row * 18
	-- Additional rows extend ground, rather than losing the ninth/33rd player.
	Workspace.Terrain:FillBlock(
		CFrame.new(at(x, -8, z)),
		Vector3.new(24, 16, 20),
		Enum.Material.Grass
	)
	local plot = Instance.new("Model")
	plot.Name = "Vines_" .. userId
	plot:SetAttribute("OwnerUserId", userId)
	plot.Parent = cached.model
	Workspace.Terrain:FillBall(at(x - 5, -2.5, z), 4, Enum.Material.Ground)
	Workspace.Terrain:FillBall(at(x + 5, -2.5, z), 4, Enum.Material.Ground)
	local crops = {}
	for index, offset in { -5, 5 } do
		local crop = marker(plot, "Crop_" .. index, at(x + offset, 1.5, z))
		crop:SetAttribute("OwnerUserId", userId)
		crop:SetAttribute("CropIndex", index)
		table.insert(crops, crop)
	end
	local owner = marker(plot, "OwnerLabel", at(x, 1, z + 4))
	label(owner, "YOUR VINES", cream, 180)
	return { model = plot, spawn = CFrame.lookAt(at(x, 5, z + 7), at(x, 5, z - 20)), crops = crops }
end

function GardenScene.setGhost(target: BasePart, visible: boolean)
	for _, item in target:GetDescendants() do
		if item:IsA("BasePart") then
			if item:GetAttribute("ArtTransparency") == nil then
				item:SetAttribute("ArtTransparency", item.Transparency)
			end
			item.Transparency = if visible then item:GetAttribute("ArtTransparency") else 1
		elseif item:IsA("PointLight") then
			item.Enabled = visible
		end
	end
	target:SetAttribute("GhostAlive", visible)
end

function GardenScene.setShrine(progress: number, goal: number)
	if not cached then
		return
	end
	local fraction = math.clamp(progress / math.max(goal, 1), 0, 1)
	for index, lantern in cached.lanterns do
		lantern.Material = if fraction >= index / #cached.lanterns
			then Enum.Material.Neon
			else Enum.Material.SmoothPlastic
		local light = lantern:FindFirstChild("ShrineGlow")
		if light and light:IsA("PointLight") then
			light.Enabled = fraction >= index / #cached.lanterns
		end
		for _, item in lantern:GetDescendants() do
			if item:IsA("BasePart") then
				item.Material = if fraction >= index / #cached.lanterns
					then Enum.Material.Neon
					else Enum.Material.SmoothPlastic
			end
		end
	end
	cached.shrineTitle.Text = if fraction >= 1
		then "LANTERNS AWAKENED!"
		else "LIGHT THE GARDEN  " .. progress .. "/" .. goal
end

function GardenScene.build(): any
	if cached and cached.model.Parent then
		return cached
	end
	-- Dedicated garden builds keep historical source art private instead of
	-- displaying the old roll map in Workspace. Retain legacy project support.
	local map = ServerStorage:FindFirstChild("GardenArtSource")
		or Workspace:FindFirstChild("PumpkinMap")
	assert(map, "Garden art source missing; build garden.project.json or default.project.json")
	local patch = map:WaitForChild("Zone_PumpkinPatch")
	local pets = ServerStorage:WaitForChild("PetModels")
	pumpkinSource = source(patch, "JackOLantern")
	local autumn = source(map:WaitForChild("Trees"), "AutumnTree")
	local dead = source(map:WaitForChild("Zone_HauntedForest"), "DeadTree")
	local grave = source(map:WaitForChild("Zone_Graveyard"), "Gravestone")
	local scene = Instance.new("Model")
	scene.Name = "MagicGarden"
	scene.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	scene.Parent = Workspace
	local terrain = Workspace.Terrain
	terrain:FillBlock(CFrame.new(at(0, -12, 4)), Vector3.new(230, 24, 270), Enum.Material.Grass)
	-- Rolling grass banks provide depth without blocking the central outing.
	for _, x in { -112, 112 } do
		for index = 1, 6 do
			terrain:FillBall(at(x, -3, -110 + index * 37), 18, Enum.Material.Grass)
		end
	end
	for index = 1, 9 do
		local z = -100 + index * 14
		terrain:FillBall(at(math.sin(index * 0.65) * 9, -4.5, z), 8, Enum.Material.Ground)
	end
	local function prop(
		asset: Instance,
		name: string,
		x: number,
		z: number,
		height: number,
		yaw: number?
	): Model
		local model = copyArt(scene, asset, name, height)
		place(model, at(x, 1, z), yaw)
		return model
	end
	for index, tuple in { { -103, 6 }, { 103, 6 }, { -105, 58 }, { 105, 58 } } do
		prop(autumn, "AutumnCanopy_" .. index, tuple[1], tuple[2], 21, index)
	end
	for index, tuple in
		{ { -65, -23 }, { 66, -26 }, { -65, -69 }, { 65, -76 }, { -35, -112 }, { 35, -112 } }
	do
		prop(dead, "CrookedLanternTree_" .. index, tuple[1], tuple[2], 17, index * 0.9)
		prop(pumpkinSource, "PathJack_" .. index, tuple[1] * 0.84, tuple[2] + 4, 2.2, math.pi)
	end
	local targets = {}
	for row = 1, 3 do
		for column = 1, 6 do
			local x, z = -40 + (column - 1) * 16, -20 - (row - 1) * 33
			local target = marker(scene, "Ghost_" .. (#targets + 1), at(x, 3.8, z))
			target:SetAttribute("TargetId", #targets + 1)
			target:SetAttribute("GhostAlive", true)
			local model = copyArt(
				target,
				source(pets, if column % 2 == 0 then "Gummy Ghost" else "Misty Ghost"),
				"GhostArt",
				3.8
			)
			place(model, at(x, 2, z), math.pi)
			for _, item in model:GetDescendants() do
				if item:IsA("BasePart") then
					TweenService:Create(
						item,
						TweenInfo.new(
							1.8 + column * 0.08,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut,
							-1,
							true
						),
						{ CFrame = item.CFrame + Vector3.new(0, 0.65, 0) }
					):Play()
				end
			end
			if row > 1 and column % 2 == 0 then
				prop(grave, "GhostHome", x + 4, z + 3, 2.4, column)
			end
			table.insert(targets, target)
		end
	end
	local shop = marker(scene, "GrowBiggerShop", at(-24, 3, 3))
	prop(source(patch, "Scarecrow"), "GrowthKeeper", -30, 5, 7.2, math.pi)
	prop(pumpkinSource, "SmallDisplay", -22, 5, 2.5, math.pi)
	prop(pumpkinSource, "BigDisplay", -17, 5, 4.5, math.pi)
	label(shop, "GROW BIGGER", orange)
	local shrine = marker(scene, "LanternShrine", at(24, 3, 3))
	prop(pumpkinSource, "ShrineHero", 24, 8, 6.2, math.pi)
	local lanterns = {}
	for index = 1, 8 do
		local angle = math.pi * (index - 1) / 7
		local model = prop(
			pumpkinSource,
			"ShrineLantern_" .. index,
			24 + math.cos(angle) * 10,
			8 + math.sin(angle) * 8,
			1.8,
			angle
		)
		local root = model:FindFirstChildWhichIsA("BasePart", true)
		assert(root, "Shrine mesh missing")
		local light = Instance.new("PointLight")
		light.Name = "ShrineGlow"
		light.Color = orange
		light.Range = 10
		light.Brightness = 1.2
		light.Enabled = false
		light.Parent = root
		table.insert(lanterns, root)
	end
	local shrineTitle = label(shrine, "LIGHT THE GARDEN", cyan, 320)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GardenSpawn"
	spawn.Size = Vector3.new(6, 0.2, 6)
	spawn.CFrame = CFrame.new(at(0, 1, 15))
	spawn.Transparency = 1
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = scene
	Lighting.ClockTime = 16.8
	Lighting.Brightness = 2.8
	Lighting.Ambient = Color3.fromRGB(144, 129, 168)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 175, 196)
	Lighting.ExposureCompensation = 0.15
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("BloomEffect") then
			effect.Intensity = 0.13
			effect.Threshold = 1.8
		elseif effect:IsA("Atmosphere") then
			effect.Density = 0.16
			effect.Haze = 0.6
			effect.Color = Color3.fromRGB(211, 200, 236)
		end
	end
	cached = {
		model = scene,
		spawn = CFrame.lookAt(at(0, 5, 15), at(0, 5, -30)),
		shop = shop,
		shrine = shrine,
		targets = targets,
		arenaCenter = at(0, 0, -48),
		arenaRadius = 96,
		lanterns = lanterns,
		shrineTitle = shrineTitle,
	}
	return cached
end

return GardenScene
