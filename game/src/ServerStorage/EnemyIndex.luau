--!strict
-- Shared server-side index of live enemy roots.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpatialHash = require(ReplicatedStorage.Shared.SpatialHash)

local CELL_SIZE = 16
local hash = SpatialHash.new(CELL_SIZE)

type Tracked = {
	root: BasePart,
	connection: RBXScriptConnection,
}

local tracked: { [Model]: Tracked } = {}
local maximumRootRadius = 0
local EnemyIndex = {}

local function positionOf(root: BasePart): SpatialHash.Position
	local position = root.Position
	return { x = position.X, y = position.Y, z = position.Z }
end

local function rootRadius(root: BasePart): number
	return root.Size.Magnitude / 2
end

function EnemyIndex.add(model: Model, root: BasePart)
	EnemyIndex.remove(model)
	hash:insert(model, positionOf(root))
	maximumRootRadius = math.max(maximumRootRadius, rootRadius(root))
	tracked[model] = {
		root = root,
		connection = root:GetPropertyChangedSignal("CFrame"):Connect(function()
			if tracked[model] then
				hash:move(model, positionOf(root))
			end
		end),
	}
end

function EnemyIndex.move(model: Model)
	local entry = tracked[model]
	if entry then
		hash:move(model, positionOf(entry.root))
	end
end

function EnemyIndex.remove(model: Model)
	local entry = tracked[model]
	if entry then
		entry.connection:Disconnect()
		tracked[model] = nil
	end
	hash:remove(model)
end

function EnemyIndex.clear()
	for model in tracked do
		EnemyIndex.remove(model)
	end
	maximumRootRadius = 0
end

function EnemyIndex.maximumRootRadius(): number
	return maximumRootRadius
end

function EnemyIndex.queryRadius(position: Vector3, radius: number): { Model }
	return hash:queryRadius({ x = position.X, y = position.Y, z = position.Z }, radius)
end

-- One maintenance pass keeps physics-driven roots current even when CFrame signals coalesce.
RunService.Heartbeat:Connect(function()
	for model, entry in tracked do
		if model.Parent and entry.root.Parent then
			hash:move(model, positionOf(entry.root))
		else
			EnemyIndex.remove(model)
		end
	end
end)

return EnemyIndex
