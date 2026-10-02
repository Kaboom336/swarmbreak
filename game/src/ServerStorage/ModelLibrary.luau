--!strict

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ModelAssets = require(ReplicatedStorage.Shared.ModelAssets)
local ModelParts = require(ReplicatedStorage.Shared.ModelParts)

local ModelLibrary = {}
local loaded = false
local loading = false

local function cacheFolder(): Folder
	local existing = ServerStorage:FindFirstChild("ModelCache")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "ModelCache"
	folder.Parent = ServerStorage
	return folder
end

local function prepare(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
			if ModelParts.isGlow(descendant.Name) then
				descendant.Material = Enum.Material.Neon
			end
		end
	end
end

function ModelLibrary.preload()
	if loaded then
		return
	end
	if loading then
		repeat
			task.wait()
		until not loading
		return
	end
	loading = true
	local cache = cacheFolder()
	for key, assetId in ModelAssets do
		if not cache:FindFirstChild(key) then
			local ok, container = pcall(function()
				return InsertService:LoadAsset(assetId)
			end)
			if ok then
				local asset = (container :: Model):FindFirstChildWhichIsA("Model")
				if not asset then
					-- FBX imports can land as loose MeshParts; wrap them so rig part names survive.
					local wrapper = Instance.new("Model")
					for _, child in (container :: Model):GetChildren() do
						child.Parent = wrapper
					end
					asset = if #wrapper:GetChildren() > 0 then wrapper else nil
				end
				if not asset then
					warn(
						string.format(
							"Model %s (%d) loaded empty; using part fallback",
							key,
							assetId
						)
					)
				end
				if asset then
					prepare(asset)
					asset.Name = key
					asset.Parent = cache
				end
				(container :: Model):Destroy()
			else
				warn(
					string.format(
						"Could not load model %s (%d): %s",
						key,
						assetId,
						tostring(container)
					)
				)
			end
		end
	end
	loaded = true
	loading = false
end

function ModelLibrary.get(key: string): Model?
	ModelLibrary.preload()
	local cached = cacheFolder():FindFirstChild(key)
	if cached and cached:IsA("Model") then
		return cached:Clone()
	end
	return nil
end

return ModelLibrary
