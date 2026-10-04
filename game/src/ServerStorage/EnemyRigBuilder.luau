--!strict
-- Builds the generated Nest rigs from their Rojo JSON modules. Templates are
-- created once at server start; each spawn only clones and uniformly scales one.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EnemyFamilies = require(Shared.EnemyFamilies)
local WaveTable = require(Shared.WaveTable)
local Rigs = Shared:WaitForChild("Rigs")
local EnemyPool = require(script.Parent.EnemyPool)

local EnemyRigBuilder = {}

export type Rig = {
	Model: Model,
	Root: BasePart,
	Torso: BasePart,
	HipHeight: number,
	Humanoid: Humanoid?,
}

local RIG_KEYS = { "Mite", "Runner", "Shooter", "Tank", "Flyer", "Queen" }
local templates: { [string]: Model } = {}
local warned: { [string]: boolean } = {}

local function warnOnce(rigKey: string, reason: any)
	if warned[rigKey] then
		return
	end
	warned[rigKey] = true
	warn(
		string.format("Nest rig %s unavailable; using fallback model: %s", rigKey, tostring(reason))
	)
end

local function vector3(values: { number }): Vector3
	return Vector3.new(values[1], values[2], values[3])
end

local function cframe(values: { number }): CFrame
	return CFrame.new(table.unpack(values))
end

local function assetId(value: string?): number
	return tonumber(if value then value:match("(%d+)$") else nil) or 0
end

local function makePart(definition: any): BasePart
	local built: BasePart
	if definition.ClassName == "MeshPart" then
		assert(assetId(definition.MeshId) > 0, definition.Name .. " has no mesh asset")
		local ok, result =
			pcall(AssetService.CreateMeshPartAsync, AssetService, definition.MeshId, {
				CollisionFidelity = Enum.CollisionFidelity.Default,
				RenderFidelity = Enum.RenderFidelity.Automatic,
			})
		assert(ok and typeof(result) == "Instance" and result:IsA("MeshPart"), result)
		local mesh = result :: MeshPart
		mesh.TextureID = if assetId(definition.TextureID) > 0 then definition.TextureID else ""
		built = mesh
	else
		local plain = Instance.new("Part")
		if definition.Shape then
			plain.Shape = Enum.PartType[definition.Shape]
		end
		built = plain
	end
	built.Name = definition.Name
	built.Size = vector3(definition.Size)
	built.CFrame = cframe(definition.CFrame)
	built.Color = Color3.fromRGB(table.unpack(definition.Color))
	built.Material = Enum.Material[definition.Material]
	built.Transparency = definition.Transparency or 0
	built.Anchored = true
	built.CanCollide = false
	built.CanQuery = true
	built.Massless = true
	built.TopSurface = Enum.SurfaceType.Smooth
	built.BottomSurface = Enum.SurfaceType.Smooth
	return built
end

local function buildTemplate(rigKey: string, definition: any): Model
	assert(definition.PrimaryPart == "Body", "Body must be the primary part")
	local model = Instance.new("Model")
	model.Name = rigKey
	local parts: { [string]: { BasePart } } = {}
	for _, partDefinition in definition.Parts do
		local built = makePart(partDefinition)
		built.Parent = model
		parts[built.Name] = parts[built.Name] or {}
		table.insert(parts[built.Name], built)
	end
	local body = assert(parts.Body and parts.Body[1], "Body is missing")
	model.PrimaryPart = body

	for _, motorDefinition in definition.Motor6Ds do
		local part0 = assert(
			parts[motorDefinition.Part0] and parts[motorDefinition.Part0][1],
			motorDefinition.Part0 .. " is missing"
		)
		local part1 = assert(
			parts[motorDefinition.Part1] and parts[motorDefinition.Part1][1],
			motorDefinition.Part1 .. " is missing"
		)
		local motor = Instance.new("Motor6D")
		motor.Name = motorDefinition.Name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = cframe(motorDefinition.C0)
		motor.C1 = cframe(motorDefinition.C1)
		motor.Parent = part0
	end

	local weldUses: { [string]: number } = {}
	for _, weldDefinition in definition.Welds do
		local part0 = assert(
			parts[weldDefinition.Part0] and parts[weldDefinition.Part0][1],
			weldDefinition.Part0 .. " is missing"
		)
		local use = (weldUses[weldDefinition.Part1] or 0) + 1
		weldUses[weldDefinition.Part1] = use
		local part1 = assert(
			parts[weldDefinition.Part1] and parts[weldDefinition.Part1][use],
			weldDefinition.Part1 .. " is missing"
		)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part0
		weld.Part1 = part1
		weld.Parent = part0
	end

	for name, value in definition.Attributes or {} do
		model:SetAttribute(name, value)
	end
	model:SetAttribute("RigMode", true)
	model:SetAttribute("RigKey", rigKey)
	return model
end

for _, rigKey in RIG_KEYS do
	local module = Rigs:WaitForChild(rigKey, 10)
	local ok, result = pcall(function()
		assert(module and module:IsA("ModuleScript"), "rig data missing: " .. rigKey)
		return buildTemplate(rigKey, require(module) :: any)
	end)
	if ok then
		templates[rigKey] = result :: Model
	else
		warnOnce(rigKey, result)
	end
end

local function buildFresh(typeName: string, size: Vector3, cf: CFrame): Rig?
	local rigKey = EnemyFamilies.rigForEnemy("Nest", typeName)
	if not rigKey then
		return nil
	end
	local template = templates[rigKey]
	if not template then
		return nil
	end
	local model = template:Clone()
	local body = model.PrimaryPart
	if not body then
		model:Destroy()
		warnOnce(rigKey, "template lost its Body")
		return nil
	end
	local height = model:GetExtentsSize().Y
	if height <= 0 then
		model:Destroy()
		warnOnce(rigKey, "template has zero height")
		return nil
	end
	model:ScaleTo((EnemyFamilies.rigHeight("Nest", typeName) or size.Y) / height)
	model:PivotTo(cf)
	model.Name = typeName

	-- The root matches the scaled rig, so the hitbox is what the player sees and the
	-- Humanoid keeps the feet on the floor (root bottom sits HipHeight above them).
	local boundsCFrame, bounds = model:GetBoundingBox()
	local hipHeight = 0.4
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(bounds.X, math.max(1, bounds.Y - hipHeight), bounds.Z)
	root.Transparency = 1
	root.CFrame = boundsCFrame * CFrame.new(0, hipHeight / 2, 0)
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end
	local rootWeld = Instance.new("Motor6D")
	rootWeld.Name = "RootWeld"
	rootWeld.Part0 = root
	rootWeld.Part1 = body
	rootWeld.C0 = root.CFrame:ToObjectSpace(body.CFrame)
	rootWeld.C1 = CFrame.new()
	rootWeld.Parent = root

	return { Model = model, Root = root, Torso = body, HipHeight = hipHeight }
end

for _, role in EnemyFamilies.RequiredRoles do
	local typeName = assert(EnemyFamilies.resolve("Nest", role))
	local rigKey = assert(EnemyFamilies.resolveRig("Nest", role))
	-- A rig whose template failed to build keeps the old model; never pool it.
	if not templates[rigKey] then
		continue
	end
	EnemyPool.register(rigKey, function(): Model
		local rig = assert(buildFresh(typeName, Vector3.one, CFrame.new()))
		return rig.Model
	end)
end

-- Wave one is ready before the game loop starts. Later waves refill during intermission.
EnemyPool.refill(WaveTable.Compositions[1], "Nest")

function EnemyRigBuilder.build(typeName: string, _size: Vector3, cf: CFrame): Rig?
	local rigKey = EnemyFamilies.rigForEnemy("Nest", typeName)
	if not rigKey or not templates[rigKey] then
		return nil
	end
	local model = EnemyPool.take(rigKey)
	local root = model:FindFirstChild("HumanoidRootPart")
	local body = model:FindFirstChild("Body")
	if not root or not root:IsA("BasePart") or not body or not body:IsA("BasePart") then
		model:Destroy()
		warnOnce(rigKey, "pooled rig lost its root or Body")
		return nil
	end
	model.Name = typeName
	model:PivotTo(cf)
	return {
		Model = model,
		Root = root,
		Torso = body,
		HipHeight = 0.4,
	}
end

function EnemyRigBuilder.refill(composition: { [string]: number }, familyId: string)
	EnemyPool.refill(composition, familyId)
end

function EnemyRigBuilder.release(model: Model)
	EnemyPool.release(model)
end

return EnemyRigBuilder
