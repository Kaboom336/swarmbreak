--!strict
-- Persistent player profile: load once per session, save on change (debounced) and on leave.
-- Shared by the lobby place and the arena place (same DataStore name).
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileSchema = require(ReplicatedStorage.Shared.ProfileSchema)

type Profile = ProfileSchema.Profile

local STORE_NAME = "SwarmBreak_profile_v1"
local store = if RunService:IsStudio()
		and not pcall(function()
			return DataStoreService:GetDataStore(STORE_NAME):GetAsync("__probe")
		end)
	then nil
	else DataStoreService:GetDataStore(STORE_NAME)

local Profile = {}
local cache: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}
local loaded: { [Player]: boolean } = {}
Profile.OnLoaded = nil :: ((Player, Profile) -> ())?

local function key(plr: Player): string
	return "p_" .. plr.UserId
end

function Profile.get(plr: Player): Profile
	local p = cache[plr]
	if not p then
		p = ProfileSchema.default()
		cache[plr] = p
	end
	return p
end

function Profile.isLoaded(plr: Player): boolean
	return loaded[plr] == true
end

function Profile.markDirty(plr: Player)
	dirty[plr] = true
end

local function save(plr: Player)
	local p = cache[plr]
	if not p or not loaded[plr] or not store then
		return
	end
	dirty[plr] = false
	local ok, err = pcall(function()
		store:UpdateAsync(key(plr), function()
			return p
		end)
	end)
	if not ok then
		warn("Profile save failed for", plr.Name, err)
		dirty[plr] = true
	end
end
Profile.save = save

local function load(plr: Player)
	local raw = nil
	if store then
		local ok, val = pcall(function()
			return store:GetAsync(key(plr))
		end)
		if ok then
			raw = val
		else
			warn("Profile load failed for", plr.Name, val)
		end
	end
	local p = ProfileSchema.sanitize(raw)
	cache[plr] = p
	loaded[plr] = store == nil or raw ~= nil or true
	if Profile.OnLoaded then
		Profile.OnLoaded(plr, p)
	end
end

Players.PlayerAdded:Connect(load)
for _, plr in Players:GetPlayers() do
	task.spawn(load, plr)
end
Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	cache[plr] = nil
	dirty[plr] = nil
	loaded[plr] = nil
end)
game:BindToClose(function()
	for plr in cache do
		save(plr)
	end
end)

-- Debounced autosave every 30 s for dirty profiles.
task.spawn(function()
	while true do
		task.wait(30)
		for plr, d in dirty do
			if d then
				save(plr)
			end
		end
	end
end)

return Profile
