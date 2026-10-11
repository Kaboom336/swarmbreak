--!strict
-- Small ProfileStore-style wrapper: UpdateAsync session locks, retries, autosave support,
-- and a Studio in-memory fallback when DataStore API access is unavailable.
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ProfileSchema = require(Shared:WaitForChild("ProfileSchema"))

type Profile = ProfileSchema.Profile
type StoredRecord = {
	Data: Profile,
	SessionId: string?,
	SessionExpiresAt: number?,
	UpdatedAt: number,
}

local sessionId = if game.JobId ~= "" then game.JobId else "studio-" .. tostring(os.clock())
local profiles: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}

local function retry(operation: () -> any): (boolean, any)
	local delaySeconds = Config.FirstRetryDelay
	local lastError = nil
	for attempt = 1, Config.DataRetries do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < Config.DataRetries then
			task.wait(delaySeconds)
			delaySeconds *= 2
		end
	end
	return false, lastError
end

local function openStore(): any
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if not ok then
		return nil
	end

	if RunService:IsStudio() then
		local probeOk = pcall(function()
			result:GetAsync("__api_probe")
		end)
		if not probeOk then
			return nil
		end
	end
	return result
end

local store = openStore()
local Data = {}

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function makeRecord(profile: Profile, releaseLock: boolean): StoredRecord
	return {
		Data = profile,
		SessionId = if releaseLock then nil else sessionId,
		SessionExpiresAt = if releaseLock then nil else os.time() + Config.SessionLockSeconds,
		UpdatedAt = os.time(),
	}
end

local function canClaim(record: any, now: number): boolean
	if type(record) ~= "table" or record.SessionId == nil then
		return true
	end
	return record.SessionId == sessionId or (tonumber(record.SessionExpiresAt) or 0) <= now
end

function Data.load(player: Player): (Profile?, string?)
	if profiles[player] then
		return profiles[player], nil
	end
	if not store then
		local profile = ProfileSchema.default()
		profiles[player] = profile
		return profile, nil
	end

	local now = os.time()
	local ok, result = retry(function()
		return store:UpdateAsync(keyFor(player), function(oldRecord: any)
			if not canClaim(oldRecord, now) then
				return nil
			end
			local oldData = if type(oldRecord) == "table" and oldRecord.Data ~= nil
				then oldRecord.Data
				else oldRecord
			return makeRecord(ProfileSchema.fromStored(oldData), false)
		end)
	end)
	if not ok then
		return nil, "Your data could not be loaded. Please rejoin."
	end
	if result == nil then
		return nil, "Your data is open in another server. Please try again shortly."
	end

	local profile = ProfileSchema.fromStored(result.Data)
	profiles[player] = profile
	return profile, nil
end

function Data.get(player: Player): Profile?
	return profiles[player]
end

function Data.markDirty(player: Player)
	if profiles[player] then
		dirty[player] = true
	end
end

function Data.save(player: Player, releaseLock: boolean?): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	if not store then
		dirty[player] = nil
		return true
	end
	-- Always write: a clean autosave still refreshes the session lock (T1 review).
	-- Clear dirty before the write so changes made while it is in flight are kept.
	dirty[player] = nil
	local shouldRelease = releaseLock == true
	local ok, result = retry(function()
		return store:UpdateAsync(keyFor(player), function(oldRecord: any)
			if not canClaim(oldRecord, os.time()) then
				return nil
			end
			return makeRecord(profile, shouldRelease)
		end)
	end)
	if not ok or result == nil then
		warn("Profile save failed for", player.Name, result)
		if profiles[player] then
			dirty[player] = true
		end
		return false
	end
	return true
end

function Data.release(player: Player)
	Data.save(player, true)
	profiles[player] = nil
	dirty[player] = nil
end

function Data.saveAll(releaseLocks: boolean?)
	for player in profiles do
		Data.save(player, releaseLocks)
	end
end

return Data
