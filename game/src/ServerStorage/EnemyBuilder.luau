--!strict
-- Builds enemy rigs from parts and Motor6Ds (no uploaded meshes, so nothing to license).
-- Motor names are what EnemyAnimator.client animates: Hip_L/R, Shoulder_L/R, Neck, Wing_1..n, Leg_1..n, Jaw.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local Fit = require(ReplicatedStorage.Shared.Fit)
local HumanoidEnemies = require(ReplicatedStorage.Shared.HumanoidEnemies)
local ModelKey = require(ReplicatedStorage.Shared.ModelKey)
local ModelParts = require(ReplicatedStorage.Shared.ModelParts)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ModelLibrary = require(ServerStorage.ModelLibrary)

local EnemyBuilder = {}

export type Rig = {
	Model: Model,
	Root: BasePart,
	Torso: BasePart,
	HipHeight: number,
	Humanoid: Humanoid?,
}

local function c3(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function part(
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.CanCollide = false
	p.CanQuery = true
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	return p
end

-- Motor6D joint: child hangs off parent at offset (parent space), rotating about the joint.
local function joint(
	name: string,
	parent: BasePart,
	child: BasePart,
	parentOffset: CFrame,
	childOffset: CFrame
): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = parent
	m.Part1 = child
	m.C0 = parentOffset
	m.C1 = childOffset
	m.Parent = parent
	child.CFrame = parent.CFrame * parentOffset * childOffset:Inverse()
	return m
end

local function weld(parent: BasePart, child: BasePart, offset: CFrame)
	child.CFrame = parent.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = parent
	w.Part1 = child
	w.Parent = parent
end

local function eyes(head: BasePart, accent: Color3, count: number, y: number)
	local w = head.Size.X
	for i = 1, count do
		local x = if count == 1 then 0 else (-w * 0.28 + (i - 1) * (w * 0.56) / (count - 1))
		local e = part(
			"Eye",
			Vector3.new(w * 0.14, w * 0.14, 0.1),
			accent,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		e.Size = Vector3.new(w * 0.14, w * 0.14, w * 0.14)
		e.Parent = head.Parent
		weld(head, e, CFrame.new(x, y, -head.Size.Z / 2))
	end
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 6
	light.Brightness = 1.2
	light.Parent = head
end

local function glow(p: BasePart, color: Color3, size: number)
	local a = Instance.new("Attachment")
	a.Parent = p
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color)
	pe.Size = NumberSequence.new(size, 0)
	pe.Transparency = NumberSequence.new(0.4, 1)
	pe.Lifetime = NumberRange.new(0.6, 1.1)
	pe.Rate = 12
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Parent = a
end

local function isAccessoryPart(name: string): boolean
	return name == "Head"
		or ModelParts.isGlow(name)
		or name:find("Spike", 1, true) ~= nil
		or name:find("Crown", 1, true) ~= nil
end

local function attachImportedAccessories(
	model: Model,
	typeName: string,
	targetHeight: number,
	cf: CFrame,
	body: Color3,
	accent: Color3
)
	local source = ModelLibrary.get(ModelKey.make("enemies", typeName))
	if not source then
		return
	end
	local sourceHeight = source:GetExtentsSize().Y
	if sourceHeight > 0 then
		source:ScaleTo(targetHeight / sourceHeight)
	end
	source:PivotTo(cf)
	local head = model:FindFirstChild("Head") :: BasePart?
	local torso = model:FindFirstChild("UpperTorso") :: BasePart?
	for _, descendant in source:GetDescendants() do
		if descendant:IsA("BasePart") and isAccessoryPart(descendant.Name) then
			local target = if descendant.Name == "Head" or descendant.Name:find("Eye", 1, true)
				then head
				else torso
			if target then
				local originalName = descendant.Name
				descendant.Color = if ModelParts.isGlow(originalName) then accent else body
				descendant.CanCollide = false
				descendant.Massless = true
				local accessory = Instance.new("Accessory")
				accessory.Name = originalName
				descendant.Name = "Handle"
				descendant.Parent = accessory
				local accessoryWeld = Instance.new("Weld")
				accessoryWeld.Name = "AccessoryWeld"
				accessoryWeld.Part0 = target
				accessoryWeld.Part1 = descendant
				accessoryWeld.C0 = target.CFrame:ToObjectSpace(descendant.CFrame)
				accessoryWeld.Parent = descendant
				accessory.Parent = model
			end
		end
	end
	source:Destroy()
end

local function animationTrack(animator: Animator, id: string): AnimationTrack
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local track = animator:LoadAnimation(animation)
	animation:Destroy()
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement
	return track
end

local function startR15Locomotion(humanoid: Humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local walk = animationTrack(animator, HumanoidEnemies.Animations.Walk)
	local run = animationTrack(animator, HumanoidEnemies.Animations.Run)
	humanoid.Running:Connect(function(speed)
		if speed <= 0.05 then
			walk:Stop(0.15)
			run:Stop(0.15)
		elseif speed >= humanoid.WalkSpeed * 0.75 then
			walk:Stop(0.15)
			if not run.IsPlaying then
				run:Play(0.15)
			end
			run:AdjustSpeed(speed / 16)
		else
			run:Stop(0.15)
			if not walk.IsPlaying then
				walk:Play(0.15)
			end
			walk:AdjustSpeed(speed / 8)
		end
	end)
end

local function buildHumanoidTemplate(typeName: string, size: Vector3, cf: CFrame): Rig?
	local def = HumanoidEnemies.Defs[typeName]
	if not def then
		return nil
	end
	local description = Instance.new("HumanoidDescription")
	for property, value in def.Description do
		description[property] = value
	end
	local body = c3(def.BodyColor)
	description.HeadColor = body
	description.LeftArmColor = body
	description.LeftLegColor = body
	description.RightArmColor = body
	description.RightLegColor = body
	description.TorsoColor = body
	local ok, generated = pcall(
		Players.CreateHumanoidModelFromDescription,
		Players,
		description,
		Enum.HumanoidRigType.R15
	)
	description:Destroy()
	if not ok then
		warn(string.format("Could not create R15 enemy %s: %s", typeName, tostring(generated)))
		return nil
	end
	local model = generated :: Model
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local torso = model:FindFirstChild("UpperTorso") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not torso or not humanoid then
		model:Destroy()
		return nil
	end
	local generatedHeight = model:GetExtentsSize().Y
	if generatedHeight > 0 then
		model:ScaleTo(size.Y / generatedHeight)
	end
	model.Name = typeName
	model:PivotTo(cf)
	model.PrimaryPart = root
	model:SetAttribute("HumanoidEnemy", true)
	local palette = Theme.Enemy[typeName] or Theme.Enemy.Walker
	attachImportedAccessories(model, typeName, size.Y, cf, body, c3(palette.Accent))
	return {
		Model = model,
		Root = root,
		Torso = torso,
		HipHeight = humanoid.HipHeight,
		Humanoid = humanoid,
	}
end

-- Players:CreateHumanoidModelFromDescription is slow, so each type is built once and cloned.
local humanoidTemplates: { [string]: Model } = {}

local function buildHumanoid(typeName: string, size: Vector3, cf: CFrame): Rig?
	if not HumanoidEnemies.Defs[typeName] then
		return nil
	end
	local template = humanoidTemplates[typeName]
	if not template then
		local built = buildHumanoidTemplate(typeName, size, CFrame.new())
		if not built then
			return nil
		end
		template = built.Model
		humanoidTemplates[typeName] = template
	end
	local model = template:Clone()
	model:PivotTo(cf)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local torso = model:FindFirstChild("UpperTorso") :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	return {
		Model = model,
		Root = root,
		Torso = torso,
		HipHeight = humanoid.HipHeight,
		Humanoid = humanoid,
	}
end

-- ---------- rigs ----------
-- Every builder gets (model, root, s = scale, body, accent) and returns HipHeight in studs.

local function buildWalker(
	model: Model,
	root: BasePart,
	s: number,
	body: Color3,
	accent: Color3
): number
	local torso = part("Torso", Vector3.new(2.6, 2.4, 1.4) * s, body)
	torso.Parent = model
	weld(root, torso, CFrame.new(0, 0.3 * s, 0))
	local head = part("Head", Vector3.new(1.3, 1.2, 1.3) * s, body)
	head.Parent = model
	joint("Neck", torso, head, CFrame.new(0, 1.2 * s, 0), CFrame.new(0, -0.6 * s, 0))
	eyes(head, accent, 2, 0.1 * s)
	-- spikes on the back
	for i = -1, 1 do
		local sp = part(
			"Spike",
			Vector3.new(0.4, 0.9, 0.4) * s,
			accent,
			Enum.Material.Neon,
			Enum.PartType.Wedge
		)
		sp.Parent = model
		weld(
			torso,
			sp,
			CFrame.new(i * 0.8 * s, 1.4 * s, 0.4 * s) * CFrame.Angles(math.rad(-30), 0, 0)
		)
	end
	for _, side in { { "L", -1 }, { "R", 1 } } do
		local sign = side[2] :: number
		local arm = part("Arm_" .. side[1], Vector3.new(0.8, 2.2, 0.8) * s, body)
		arm.Parent = model
		joint(
			"Shoulder_" .. side[1],
			torso,
			arm,
			CFrame.new(sign * 1.7 * s, 0.9 * s, 0),
			CFrame.new(0, 1.0 * s, 0)
		)
		local claw = part(
			"Claw",
			Vector3.new(0.5, 0.6, 0.5) * s,
			accent,
			Enum.Material.Neon,
			Enum.PartType.Wedge
		)
		claw.Parent = model
		weld(arm, claw, CFrame.new(0, -1.3 * s, 0) * CFrame.Angles(math.rad(180), 0, 0))
		local leg = part("Leg_" .. side[1], Vector3.new(0.9, 2.2, 0.9) * s, body)
		leg.Parent = model
		joint(
			"Hip_" .. side[1],
			torso,
			leg,
			CFrame.new(sign * 0.7 * s, -1.2 * s, 0),
			CFrame.new(0, 1.0 * s, 0)
		)
	end
	return 2.3 * s + 0.3 * s
end

local function buildRunner(
	model: Model,
	root: BasePart,
	s: number,
	body: Color3,
	accent: Color3
): number
	local torso = part("Torso", Vector3.new(1.4, 1.0, 2.6) * s, body)
	torso.Parent = model
	weld(root, torso, CFrame.new(0, 0, 0))
	local head = part("Head", Vector3.new(1.1, 0.9, 1.2) * s, body)
	head.Parent = model
	joint("Neck", torso, head, CFrame.new(0, 0.1 * s, -1.5 * s), CFrame.new(0, 0, 0.5 * s))
	eyes(head, accent, 4, 0.1 * s)
	local jaw = part("Jaw", Vector3.new(0.9, 0.25, 0.9) * s, accent, Enum.Material.Neon)
	jaw.Parent = model
	joint("Jaw", head, jaw, CFrame.new(0, -0.45 * s, -0.2 * s), CFrame.new(0, 0, 0.4 * s))
	-- four long legs
	local n = 0
	for _, z in { -0.8, 0.8 } do
		for _, sign in { -1, 1 } do
			n += 1
			local leg = part("Leg_" .. n, Vector3.new(0.3, 2.4, 0.3) * s, body)
			leg.Parent = model
			joint(
				"Leg_" .. n,
				torso,
				leg,
				CFrame.new(sign * 0.8 * s, -0.3 * s, z * s)
					* CFrame.Angles(0, 0, sign * math.rad(25)),
				CFrame.new(0, 1.1 * s, 0)
			)
		end
	end
	return 2.2 * s
end

local function buildFlyer(
	model: Model,
	root: BasePart,
	s: number,
	body: Color3,
	accent: Color3,
	wings: number
): number
	local torso = part(
		"Torso",
		Vector3.new(2.2, 1.6, 2.2) * s,
		body,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	torso.Size = Vector3.new(2, 2, 2) * s
	torso.Parent = model
	weld(root, torso, CFrame.new())
	local core =
		part("Core", Vector3.new(0.9, 0.9, 0.9) * s, accent, Enum.Material.Neon, Enum.PartType.Ball)
	core.Parent = model
	weld(torso, core, CFrame.new(0, -0.3 * s, -0.7 * s))
	glow(core, accent, 0.6 * s)
	eyes(torso, accent, 1, 0.3 * s)
	for i = 1, wings do
		local sign = if i % 2 == 1 then -1 else 1
		local zo = if wings > 2 then (if i <= 2 then -0.5 else 0.5) else 0
		local wing = part(
			"Wing_" .. i,
			Vector3.new(2.6, 0.12, 1.4) * s,
			body,
			Enum.Material.SmoothPlastic,
			Enum.PartType.Wedge
		)
		wing.Transparency = 0.15
		wing.Parent = model
		joint(
			"Wing_" .. i,
			torso,
			wing,
			CFrame.new(sign * 1.0 * s, 0.4 * s, zo * s),
			CFrame.new(-sign * 1.3 * s, 0, 0)
		)
	end
	-- tendrils
	for i = 1, 3 do
		local t = part(
			"Tendril",
			Vector3.new(0.18, 1.6, 0.18) * s,
			accent,
			Enum.Material.Neon,
			Enum.PartType.Cylinder
		)
		t.Size = Vector3.new(1.6, 0.18, 0.18) * s
		t.Parent = model
		weld(
			torso,
			t,
			CFrame.new((i - 2) * 0.5 * s, -1.6 * s, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
	end
	return 0
end

local function buildTank(
	model: Model,
	root: BasePart,
	s: number,
	body: Color3,
	accent: Color3,
	legs: number
): number
	local torso = part("Torso", Vector3.new(3.4, 1.8, 4.2) * s, body)
	torso.Parent = model
	weld(root, torso, CFrame.new(0, 0.2 * s, 0))
	local shell = part("Shell", Vector3.new(3.8, 2.2, 4.6) * s, body, Enum.Material.SmoothPlastic)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = shell
	shell.Parent = model
	weld(torso, shell, CFrame.new(0, 0.6 * s, 0))
	-- glowing seams
	for i = -1, 1 do
		local seam = part("Seam", Vector3.new(0.15, 0.15, 4.0) * s, accent, Enum.Material.Neon)
		seam.Parent = model
		weld(shell, seam, CFrame.new(i * 1.1 * s, 1.05 * s, 0))
	end
	local head = part("Head", Vector3.new(1.6, 1.2, 1.4) * s, body)
	head.Parent = model
	joint("Neck", torso, head, CFrame.new(0, -0.1 * s, -2.3 * s), CFrame.new(0, 0, 0.6 * s))
	eyes(head, accent, 2, 0.1 * s)
	local horn = part(
		"Horn",
		Vector3.new(0.5, 1.4, 0.5) * s,
		accent,
		Enum.Material.Neon,
		Enum.PartType.Wedge
	)
	horn.Parent = model
	weld(head, horn, CFrame.new(0, 0.9 * s, -0.2 * s) * CFrame.Angles(math.rad(-20), 0, 0))
	local perSide = math.floor(legs / 2)
	local n = 0
	for i = 1, perSide do
		local z = -1.5 + (i - 1) * (3 / math.max(perSide - 1, 1))
		for _, sign in { -1, 1 } do
			n += 1
			local leg = part("Leg_" .. n, Vector3.new(0.5, 1.6, 0.5) * s, body)
			leg.Parent = model
			joint(
				"Leg_" .. n,
				torso,
				leg,
				CFrame.new(sign * 1.8 * s, -0.7 * s, z * s)
					* CFrame.Angles(0, 0, sign * math.rad(30)),
				CFrame.new(0, 0.7 * s, 0)
			)
		end
	end
	return 1.7 * s + 0.2 * s
end

local function buildSpitter(
	model: Model,
	root: BasePart,
	s: number,
	body: Color3,
	accent: Color3
): number
	local hip = buildWalker(model, root, s * 0.9, body, accent)
	local head = model:FindFirstChild("Head") :: BasePart
	-- big glowing maw replaces the eyes' look
	local maw = part("Maw", Vector3.new(0.9, 0.5, 0.6) * s, accent, Enum.Material.Neon)
	maw.Parent = model
	joint("Jaw", head, maw, CFrame.new(0, -0.5 * s, -0.4 * s), CFrame.new(0, 0.25 * s, 0))
	-- acid sacs on the back
	local torso = model:FindFirstChild("Torso") :: BasePart
	for i = 1, 3 do
		local sac = part(
			"Sac",
			Vector3.new(0.8, 0.8, 0.8) * s,
			accent,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		sac.Transparency = 0.2
		sac.Parent = model
		weld(torso, sac, CFrame.new((i - 2) * 0.7 * s, 0.4 * s + (i % 2) * 0.4 * s, 0.9 * s))
	end
	glow(torso, accent, 0.5 * s)
	return hip
end

-- Boss dressing shared by all bosses: crown spikes, aura, ground light.
local function bossDressing(model: Model, torso: BasePart, s: number, accent: Color3)
	for i = 0, 5 do
		local ang = i * math.pi / 3
		local sp = part(
			"Crown",
			Vector3.new(0.35, 1.4, 0.35) * s,
			accent,
			Enum.Material.Neon,
			Enum.PartType.Wedge
		)
		sp.Parent = model
		weld(
			torso,
			sp,
			CFrame.new(math.cos(ang) * 1.3 * s, torso.Size.Y / 2 + 0.6 * s, math.sin(ang) * 1.3 * s)
				* CFrame.Angles(0, -ang, math.rad(15))
		)
	end
	glow(torso, accent, 1.6 * s)
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 30 * s
	light.Brightness = 2
	light.Parent = torso
end

local function findPart(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

local REQUIRED_LIMBS: { [string]: { string } } = {
	Walker = { "Arm_L", "Arm_R", "Leg_L", "Leg_R" },
	Runner = { "Leg_1", "Leg_2", "Leg_3", "Leg_4" },
	Spitter = { "Leg_1", "Leg_2" },
	Flyer = { "Wing_1", "Wing_2" },
	Tank = { "Leg_1", "Leg_2", "Leg_3", "Leg_4", "Leg_5", "Leg_6" },
	Brute = { "Arm_L", "Arm_R", "Leg_L", "Leg_R" },
	Queen = { "Leg_1", "Leg_2", "Leg_3", "Leg_4", "Leg_5", "Leg_6", "Leg_7", "Leg_8" },
	Warden = { "Wing_1", "Wing_2", "Wing_3", "Wing_4" },
}

local function hasRequiredLimbs(model: Model, typeName: string): boolean
	for _, name in REQUIRED_LIMBS[typeName] or {} do
		if not findPart(model, name) then
			return false
		end
	end
	return true
end

local function buildImported(typeName: string, size: Vector3, cf: CFrame): Rig?
	local model = ModelLibrary.get(ModelKey.make("enemies", typeName))
	if not model then
		return nil
	end
	local torso = findPart(model, "Torso")
	if not torso or not hasRequiredLimbs(model, typeName) then
		model:Destroy()
		return nil
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		end
	end

	local bounds = model:GetExtentsSize()
	local fitted = Fit.sizeForRelativeHeight({ bounds.X, bounds.Y, bounds.Z }, size.Y, 1)
	model:ScaleTo(
		Fit.capWidth(fitted[2] / bounds.Y, bounds.X, bounds.Z, Enemies.Defs[typeName].MaxWidth)
	)
	model:PivotTo(cf)
	local boundsCFrame, scaledBounds = model:GetBoundingBox()
	model.Name = typeName
	local palette = Theme.Enemy[typeName] or Theme.Enemy.Walker
	local body = c3(palette.Body)
	local accent = c3(palette.Accent)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = if ModelParts.isGlow(descendant.Name) then accent else body
		end
	end

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	-- Root bottom sits HipHeight above the feet so the Humanoid keeps the feet on the floor.
	local importedHip = 0.4
	root.Size =
		Vector3.new(scaledBounds.X, math.max(1, scaledBounds.Y - importedHip), scaledBounds.Z)
	root.Transparency = 1
	root.CFrame = boundsCFrame * CFrame.new(0, importedHip / 2, 0)
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root
	weld(root, torso, root.CFrame:ToObjectSpace(torso.CFrame))

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root and descendant ~= torso then
			local motorName = ModelParts.motorFor(descendant.Name)
			if motorName then
				local parentName = ModelParts.parentFor(descendant.Name)
				local parent = if parentName then findPart(model, parentName) else nil
				parent = parent or torso
				joint(
					motorName,
					parent,
					descendant,
					parent.CFrame:ToObjectSpace(descendant.CFrame),
					CFrame.new()
				)
			else
				local constraint = Instance.new("WeldConstraint")
				constraint.Part0 = torso
				constraint.Part1 = descendant
				constraint.Parent = torso
			end
		end
	end

	return { Model = model, Root = root, Torso = torso, HipHeight = importedHip }
end

function EnemyBuilder.build(typeName: string, size: Vector3, cf: CFrame): Rig
	local humanoid = buildHumanoid(typeName, size, cf)
	if humanoid then
		return humanoid
	end
	local imported = buildImported(typeName, size, cf)
	if imported then
		return imported
	end
	local palette = Theme.Enemy[typeName] or Theme.Enemy.Walker
	local body = c3(palette.Body)
	local accent = c3(palette.Accent)
	local model = Instance.new("Model")
	model.Name = typeName

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = size
	root.Transparency = 1
	root.CFrame = cf
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root

	local hip = 0
	if typeName == "Runner" then
		hip = buildRunner(model, root, size.Y / 4, body, accent)
	elseif typeName == "Flyer" then
		hip = buildFlyer(model, root, size.Y / 2, body, accent, 2)
	elseif typeName == "Tank" then
		hip = buildTank(model, root, size.Y / 7, body, accent, 6)
	elseif typeName == "Spitter" then
		hip = buildSpitter(model, root, size.Y / 4.5, body, accent)
	elseif typeName == "Brute" then
		hip = buildWalker(model, root, size.Y / 5, body, accent)
		bossDressing(model, model:FindFirstChild("Torso") :: BasePart, size.Y / 5, accent)
	elseif typeName == "Queen" then
		hip = buildTank(model, root, size.Y / 7, body, accent, 8)
		bossDressing(model, model:FindFirstChild("Shell") :: BasePart, size.Y / 7, accent)
	elseif typeName == "Warden" then
		hip = buildFlyer(model, root, size.Y / 2, body, accent, 4)
		bossDressing(model, model:FindFirstChild("Torso") :: BasePart, size.Y / 2, accent)
	else
		hip = buildWalker(model, root, size.Y / 5, body, accent)
	end

	local torso = model:FindFirstChild("Torso") :: BasePart
	-- Size the invisible root so its bottom sits just above the lowest part (the feet) and let the
	-- Humanoid hold that bottom HIP studs off the ground. Parts stay where the builders put them.
	local minY = math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then
			minY = math.min(minY, p.Position.Y - p.Size.Y / 2)
		end
	end
	local HIP = 0.4
	local halfHeight = math.max(0.5, root.Position.Y - minY - HIP)
	root.Size = Vector3.new(root.Size.X, halfHeight * 2, root.Size.Z)
	hip = HIP
	return { Model = model, Root = root, Torso = torso, HipHeight = hip }
end

function EnemyBuilder.startLocomotion(rig: Rig)
	if rig.Humanoid then
		startR15Locomotion(rig.Humanoid)
	end
end

return EnemyBuilder
