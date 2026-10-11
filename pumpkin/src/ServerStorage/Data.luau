--!strict
-- Small ProfileStore-style wrapper: UpdateAsync session locks, retries, autosave support,
-- and a Studio in-memory fallback when DataStore API access is unavailable.
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ProfileSchema = require(Shared:WaitForChild("ProfileSchema"))
local SessionRules = require(Shared:WaitForChild("SessionRules"))

type Profile = ProfileSchema.Profile
type StoredRecord = {
	Data: Profile,
	SessionId: string?,
	SessionExpiresAt: number?,
	UpdatedAt: number,
}

local sessions: { [Player]: string } = {}
local leases: { [Player]: number } = {}
local profiles: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}
local fenced: { [Player]: boolean } = {}

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

local function makeRecord(profile: Profile, releaseLock: boolean, token: string): StoredRecord
	return {
		Data = profile,
		SessionId = if releaseLock then nil else token,
		SessionExpiresAt = if releaseLock then nil else os.time() + Config.SessionLockSeconds,
		UpdatedAt = os.time(),
	}
end

local function canClaim(record: any, now: number, token: string): boolean
	if type(record) ~= "table" or record.SessionId == nil then
		return true
	end
	return record.SessionId == token or (tonumber(record.SessionExpiresAt) or 0) <= now
end
local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in value do
		copy[key] = deepCopy(item)
	end
	return copy
end

function Data.load(player: Player): (Profile?, string?)
	if fenced[player] then
		return nil, "Your data session changed. Please rejoin."
	end
	if profiles[player] then
		if store and os.time() >= (leases[player] or 0) then
			return nil, "Your data lease expired. Please rejoin."
		end
		return profiles[player], nil
	end
	if not store then
		if not RunService:IsStudio() then
			return nil, "Saving is unavailable. Please rejoin shortly."
		end
		local profile = ProfileSchema.default()
		profiles[player] = profile
		return profile, nil
	end

	local token = sessions[player] or HttpService:GenerateGUID(false)
	sessions[player] = token
	local ok, result = retry(function()
		return store:UpdateAsync(keyFor(player), function(oldRecord: any)
			if not canClaim(oldRecord, os.time(), token) then
				return nil
			end
			local oldData = if type(oldRecord) == "table" and oldRecord.Data ~= nil
				then oldRecord.Data
				else oldRecord
			return makeRecord(ProfileSchema.fromStored(oldData), false, token)
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
	leases[player] = tonumber(result.SessionExpiresAt) or 0
	return profile, nil
end

function Data.get(player: Player): Profile?
	return if fenced[player] or (store and os.time() >= (leases[player] or 0))
		then nil
		else profiles[player]
end

function Data.markDirty(player: Player)
	if profiles[player] then
		dirty[player] = true
	end
end

function Data.save(player: Player, releaseLock: boolean?): boolean
	local profile = profiles[player]
	if not profile or fenced[player] then
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
	local token = sessions[player]
	if not token then
		return false
	end
	local snapshot = deepCopy(ProfileSchema.fromStored(profile))
	local ok, result = retry(function()
		return store:UpdateAsync(keyFor(player), function(oldRecord: any)
			if not SessionRules.canWrite(oldRecord, token) then
				fenced[player] = true
				return nil
			end
			return makeRecord(snapshot, shouldRelease, token)
		end)
	end)
	if not ok or result == nil then
		warn("Profile save failed for", player.Name, result)
		if profiles[player] then
			dirty[player] = true
		end
		return false
	end
	leases[player] = tonumber(result.SessionExpiresAt) or 0
	return true
end

function Data.release(player: Player): boolean
	if not profiles[player] then
		sessions[player], leases[player] = nil, nil
		return true
	end
	local saved = Data.save(player, true)
	if saved then
		profiles[player] = nil
		dirty[player] = nil
		fenced[player] = nil
		sessions[player], leases[player] = nil, nil
	end
	return saved
end

function Data.saveAll(releaseLocks: boolean?)
	for player in profiles do
		Data.save(player, releaseLocks)
	end
end

return Data
