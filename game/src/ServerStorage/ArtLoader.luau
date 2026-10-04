--!strict
-- Builds checked-in art manifests with runtime-safe APIs. Mesh failures are isolated so
-- one unavailable asset never prevents the rest of the arena from loading.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Art = Shared:WaitForChild("Art")

local ArtLoader = {}
local warned: { [string]: boolean } = {}

local function warnMeshOnce(meshId: string, reason: any)
	if warned[meshId] then
		return
	end
	warned[meshId] = true
	warn(
		string.format("Landing Pad mesh %s unavailable; skipping it: %s", meshId, tostring(reason))
	)
end

local function vector3(values: { number }): Vector3
	return Vector3.new(values[1], values[2], values[3])
end

local function cframe(values: { number }): CFrame
	return CFrame.new(table.unpack(values))
end

local function color3(values: { number }): Color3
	return Color3.fromRGB(values[1], values[2], values[3])
end

local function makeMesh(
	definition: any,
	meshCache: { [string]: MeshPart },
	failedMeshes: { [string]: boolean }
): MeshPart?
	local meshId = definition.MeshId
	if type(meshId) ~= "string" or meshId == "" then
		warnMeshOnce(tostring(meshId), definition.Name .. " has no MeshId")
		return nil
	end
	if failedMeshes[meshId] then
		return nil
	end
	local template = meshCache[meshId]
	if not template then
		local ok, result = pcall(AssetService.CreateMeshPartAsync, AssetService, meshId, {
			CollisionFidelity = Enum.CollisionFidelity.Default,
			RenderFidelity = Enum.RenderFidelity.Automatic,
		})
		if not ok or typeof(result) ~= "Instance" or not result:IsA("MeshPart") then
			failedMeshes[meshId] = true
			warnMeshOnce(meshId, result)
			return nil
		end
		template = result :: MeshPart
		meshCache[meshId] = template
	end
	return template:Clone()
end

local function makePart(definition: any, meshCache, failedMeshes): BasePart?
	local built: BasePart?
	if definition.ClassName == "MeshPart" then
		built = makeMesh(definition, meshCache, failedMeshes)
	else
		local plain = Instance.new("Part")
		if definition.Shape then
			plain.Shape = Enum.PartType[definition.Shape]
		end
		built = plain
	end
	if not built then
		return nil
	end

	built.Name = definition.Name
	built.Size = vector3(definition.Size)
	built.CFrame = cframe(definition.CFrame)
	built.Color = color3(definition.Color)
	built.Material = Enum.Material[definition.Material]
	built.Transparency = definition.Transparency
	built.CanCollide = definition.CanCollide
	built.Anchored = true
	built.CastShadow = definition.CastShadow
	built.TopSurface = Enum.SurfaceType.Smooth
	built.BottomSurface = Enum.SurfaceType.Smooth
	local combatGeometry = definition.Kind == "Floor"
		or definition.Kind == "Wall"
		or definition.Kind == "Cover"
	built.CanQuery = combatGeometry
	if not combatGeometry then
		built.CanTouch = false
	end
	if built:IsA("MeshPart") then
		built.TextureID = definition.TextureID or ""
	end

	if definition.SurfaceAppearance then
		local appearance = Instance.new("SurfaceAppearance")
		appearance.ColorMap = definition.SurfaceAppearance.ColorMap or ""
		appearance.Parent = built
	end
	for _, lightDefinition in definition.Lights or {} do
		local light: Light?
		if lightDefinition.ClassName == "PointLight" then
			light = Instance.new("PointLight")
		elseif lightDefinition.ClassName == "SpotLight" then
			light = Instance.new("SpotLight")
		elseif lightDefinition.ClassName == "SurfaceLight" then
			light = Instance.new("SurfaceLight")
		end
		if light then
			light.Color = color3(lightDefinition.Color)
			light.Brightness = lightDefinition.Brightness
			light.Range = lightDefinition.Range
			light.Shadows = lightDefinition.Shadows
			if light:IsA("SpotLight") or light:IsA("SurfaceLight") then
				light.Angle = lightDefinition.Angle
				light.Face = Enum.NormalId[lightDefinition.Face]
			end
			light.Parent = built
		end
	end
	return built
end

function ArtLoader.loadLandingPad(arena: Instance): Model?
	local artFolder = arena:FindFirstChild("Art")
	if not artFolder then
		artFolder = Instance.new("Folder")
		artFolder.Name = "Art"
		artFolder.Parent = arena
	end
	local existing = artFolder:FindFirstChild("LandingPad")
	if existing and existing:IsA("Model") and existing:GetAttribute("Loaded") then
		return existing
	end

	local source = Art:WaitForChild("LandingPad", 10)
	if not source or not source:IsA("ModuleScript") then
		warn("Landing Pad art manifest is missing; keeping primitive arena art")
		return nil
	end
	local ok, manifest = pcall(require, source)
	if not ok or type(manifest) ~= "table" or type(manifest.Parts) ~= "table" then
		warn(
			"Landing Pad art manifest failed to load; keeping primitive arena art: "
				.. tostring(manifest)
		)
		return nil
	end

	local model = Instance.new("Model")
	model.Name = "LandingPad"
	local meshCache: { [string]: MeshPart } = {}
	local failedMeshes: { [string]: boolean } = {}
	for index, definition in manifest.Parts do
		local built = makePart(definition, meshCache, failedMeshes)
		if built then
			built.Parent = model
		end
		if index % 50 == 0 then
			task.wait()
		end
	end
	for _, template in meshCache do
		template:Destroy()
	end
	model:SetAttribute("Loaded", true)
	model.Parent = artFolder
	return model
end

return ArtLoader
