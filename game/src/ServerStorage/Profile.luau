--!strict
-- Persistent player profiles with migration, retries, session ownership, and autosaving.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SaveSchema = require(ReplicatedStorage.Shared.SaveSchema)

type Profile = SaveSchema.Profile

local STORE_NAME = "SwarmBreak_profile_v1"
local RETRY_COUNT = 4
local FIRST_RETRY_DELAY = 1
local AUTOSAVE_SECONDS = 30
local LOCK_SECONDS = 120
local sessionId = if game.JobId ~= "" then game.JobId else "studio"

local function openStore(): DataStore
	return DataStoreService:GetDataStore(STORE_NAME)
end

local store: DataStore? = nil
local storeOk, storeResult = pcall(openStore)
if storeOk then
	store = storeResult
end
if store and RunService:IsStudio() then
	local studioStore = store
	local probeOk = pcall(function()
		studioStore:GetAsync("__probe")
	end)
	if not probeOk then
		store = nil
	end
end

local Profile = {}
local cache: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}
local loaded: { [Player]: boolean } = {}
Profile.OnLoaded = nil :: ((Player, Profile) -> ())?

local function key(plr: Player): string
	return "p_" .. plr.UserId
end

local function retry(operation: () -> any): (boolean, any)
	local delaySeconds = FIRST_RETRY_DELAY
	local lastError: any = nil
	for attempt = 1, RETRY_COUNT do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < RETRY_COUNT then
			task.wait(delaySeconds)
			delaySeconds *= 2
		end
	end
	return false, lastError
end

function Profile.get(plr: Player): Profile
	local profile = cache[plr]
	if not profile then
		profile = SaveSchema.default()
		cache[plr] = profile
	end
	return profile
end

function Profile.isLoaded(plr: Player): boolean
	return loaded[plr] == true
end

function Profile.markDirty(plr: Player)
	dirty[plr] = true
end

local function save(plr: Player, releaseLock: boolean?): boolean
	local profile = cache[plr]
	local activeStore = store
	if not profile or not loaded[plr] or not activeStore then
		return false
	end

	dirty[plr] = false
	local ok, result = retry(function()
		return activeStore:UpdateAsync(key(plr), function(old)
			if not SaveSchema.canWrite(old, sessionId) then
				return nil
			end
			if releaseLock then
				return SaveSchema.record(profile, nil, nil)
			end
			return SaveSchema.record(profile, sessionId, os.time() + LOCK_SECONDS)
		end)
	end)
	if not ok or result == nil then
		warn("Profile save failed for", plr.Name, result)
		dirty[plr] = true
		return false
	end
	return true
end
Profile.save = save

local function finishLoad(plr: Player, profile: Profile)
	cache[plr] = profile
	loaded[plr] = true
	if Profile.OnLoaded then
		Profile.OnLoaded(plr, profile)
	end
end

local function load(plr: Player)
	local activeStore = store
	if not activeStore then
		finishLoad(plr, SaveSchema.default())
		return
	end

	local now = os.time()
	local ok, result = retry(function()
		return activeStore:UpdateAsync(key(plr), function(old)
			if not SaveSchema.canClaim(old, sessionId, now) then
				return nil
			end
			return SaveSchema.record(SaveSchema.migrate(old), sessionId, now + LOCK_SECONDS)
		end)
	end)
	if not ok then
		warn("Profile load failed for", plr.Name, result)
		plr:Kick("Your save could not be loaded. Please try again.")
		return
	end
	if result == nil then
		plr:Kick("Your save is already open in another server. Please try again shortly.")
		return
	end
	finishLoad(plr, SaveSchema.migrate(result))
end

Players.PlayerAdded:Connect(load)
for _, plr in Players:GetPlayers() do
	task.spawn(load, plr)
end
Players.PlayerRemoving:Connect(function(plr)
	save(plr, true)
	cache[plr] = nil
	dirty[plr] = nil
	loaded[plr] = nil
end)
game:BindToClose(function()
	for plr in cache do
		save(plr, true)
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for plr in cache do
			save(plr)
		end
	end
end)

return Profile
