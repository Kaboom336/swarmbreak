--!strict
-- Sends positional FX only to nearby players and suppresses duplicate sends.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FxAudience = require(ReplicatedStorage.Shared.FxAudience)
local FX = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FX") :: RemoteEvent

local FxRouter = {}
local sentBuckets: { [string]: number } = {}
local sendsSinceCleanup = 0

local function point3(position: Vector3): FxAudience.Point3
	return { x = position.X, y = position.Y, z = position.Z }
end

local function immutableCopy(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end

	local copies = seen or {}
	if copies[value] then
		return copies[value]
	end

	local copy = {}
	copies[value] = copy
	for key, child in value do
		copy[key] = immutableCopy(child, copies)
	end
	return table.freeze(copy)
end

local function sourceDiscriminator(sourcePlayer: Player?): string
	return if sourcePlayer then tostring(sourcePlayer.UserId) else ""
end

local function payloadFingerprint(value: any, active: { [any]: boolean }?): string
	if type(value) ~= "table" then
		return type(value) .. ":" .. tostring(value)
	end

	local visiting = active or {}
	if visiting[value] then
		return "cycle"
	end
	visiting[value] = true

	local parts = {}
	for key, child in value do
		table.insert(
			parts,
			payloadFingerprint(key, visiting) .. "=" .. payloadFingerprint(child, visiting)
		)
	end
	table.sort(parts)
	visiting[value] = nil
	return "{" .. table.concat(parts, ",") .. "}"
end

local function alreadySent(key: string, bucket: number): boolean
	if sentBuckets[key] == bucket then
		return true
	end
	sentBuckets[key] = bucket
	sendsSinceCleanup += 1
	if sendsSinceCleanup >= 128 then
		sendsSinceCleanup = 0
		for oldKey, oldBucket in sentBuckets do
			if oldBucket < bucket - 1 then
				sentBuckets[oldKey] = nil
			end
		end
	end
	return false
end

function FxRouter.emit(
	effectName: string,
	origin: Vector3,
	payload: { [any]: any },
	sourcePlayer: Player?
): number
	if sourcePlayer and sourcePlayer.Parent ~= Players then
		sourcePlayer = nil
	end
	local radius = FxAudience.radiusFor(effectName)
	if radius == nil then
		-- Unknown/non-positional effects retain broadcast semantics.
		FX:FireAllClients(effectName, immutableCopy(payload))
		return #Players:GetPlayers()
	end

	local now = os.clock()
	local originPoint = point3(origin)
	local bucket = FxAudience.bucketFor(now)
	local identity = sourceDiscriminator(sourcePlayer) .. ":" .. payloadFingerprint(payload)
	local key = FxAudience.coalescingKey(effectName, originPoint, now, identity)
	if alreadySent(key, bucket) then
		return 0
	end

	local players = Players:GetPlayers()
	local positions = {}
	for _, player in players do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			positions[player] = point3(root.Position)
		end
	end

	local recipients =
		FxAudience.selectPlayers(players, positions, originPoint, radius, sourcePlayer)
	local snapshot = immutableCopy(payload)
	for _, player in recipients do
		FX:FireClient(player, effectName, snapshot)
	end
	return #recipients
end

return FxRouter
