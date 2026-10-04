--!strict
-- Owns ready Nest rigs in ServerStorage and restores runtime-mutated state on return.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EnemyFamilies = require(Shared.EnemyFamilies)
local EnemyPoolLogic = require(Shared.EnemyPoolLogic)

type Snapshot = {
	Parts: { [BasePart]: { Transparency: number, Color: Color3, CanCollide: boolean } },
	Motors: { [Motor6D]: { C0: CFrame, C1: CFrame } },
}

local folder = Instance.new("Folder")
folder.Name = "EnemyPool"
folder.Parent = ServerStorage

local factories: { [string]: () -> Model } = {}
local snapshots: { [Model]: Snapshot } = {}

local function prepare(model: Model): Model
	local snapshot: Snapshot = { Parts = {}, Motors = {} }
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			snapshot.Parts[descendant] = {
				Transparency = descendant.Transparency,
				Color = descendant.Color,
				CanCollide = descendant.CanCollide,
			}
		elseif descendant:IsA("Motor6D") then
			snapshot.Motors[descendant] = { C0 = descendant.C0, C1 = descendant.C1 }
		end
	end
	snapshots[model] = snapshot
	return model
end

local pool = EnemyPoolLogic.new(function(rigKey: string): Model
	local factory = assert(factories[rigKey], "no enemy pool factory for " .. rigKey)
	return prepare(factory())
end)

local EnemyPool = {}

function EnemyPool.register(rigKey: string, factory: () -> Model)
	factories[rigKey] = factory
end

function EnemyPool.take(rigKey: string): Model
	local model = EnemyPoolLogic.take(pool, rigKey)
	model.Parent = nil
	return model
end

function EnemyPool.refill(composition: { [string]: number }, familyId: string)
	local targets = EnemyPoolLogic.targetsForComposition(composition, function(role)
		return EnemyFamilies.resolveRig(familyId, role)
	end)
	EnemyPoolLogic.setTargets(pool, targets)
	EnemyPoolLogic.trim(pool, function(model)
		snapshots[model] = nil
		model:Destroy()
	end)
	EnemyPoolLogic.refill(pool)
	for _, ready in pool.Ready do
		for _, model in ready do
			model.Parent = folder
		end
	end
end

function EnemyPool.release(model: Model)
	local rigKey = model:GetAttribute("RigKey")
	local snapshot = snapshots[model]
	if type(rigKey) ~= "string" or not snapshot then
		model:Destroy()
		return
	end
	for part, state in snapshot.Parts do
		if part.Parent then
			part.Transparency = state.Transparency
			part.Color = state.Color
			part.CanCollide = state.CanCollide
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	for motor, state in snapshot.Motors do
		if motor.Parent then
			motor.C0 = state.C0
			motor.C1 = state.C1
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
	model:SetAttribute("LastHitBy", 0)
	if EnemyPoolLogic.give(pool, rigKey, model) then
		model.Parent = folder
	else
		snapshots[model] = nil
		model:Destroy()
	end
end

return EnemyPool
