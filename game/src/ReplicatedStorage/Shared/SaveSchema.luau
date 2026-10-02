--!strict
-- Versioned persistence boundary. This module is pure so old saves can be migrated and
-- sanitized without DataStore access.
local ProfileSchema = require(script.Parent.ProfileSchema)

export type Profile = ProfileSchema.Profile
export type SessionLock = {
	Owner: string,
	ExpiresAt: number,
}
export type Record = {
	Version: number,
	Profile: Profile,
	SessionLock: SessionLock?,
}

local SaveSchema = {
	Version = 2,
}

local function latestProfile(raw: any): Profile
	local profile = ProfileSchema.sanitize(raw)
	profile.Version = SaveSchema.Version
	return profile
end

-- Version 1 stored the profile directly. Version 2 wraps it with save metadata so a session
-- lock never leaks into gameplay data.
local migrations: { [number]: (any) -> any } = {
	[1] = function(raw: any): any
		return latestProfile(raw)
	end,
}
SaveSchema.Migrations = migrations

function SaveSchema.default(): Profile
	return latestProfile(nil)
end

-- Accepts both the old direct profile and the current record envelope. Sanitizing at the end
-- deliberately drops fields the current profile schema does not know about.
function SaveSchema.migrate(raw: any): Profile
	local source = raw
	if type(raw) == "table" and type(raw.Profile) == "table" then
		source = raw.Profile
	end
	if type(source) ~= "table" then
		return SaveSchema.default()
	end

	local version = if type(source.Version) == "number" then math.floor(source.Version) else 1
	local migrated: any = source
	while version < SaveSchema.Version do
		local migration = migrations[version]
		if not migration then
			return SaveSchema.default()
		end
		migrated = migration(migrated)
		version += 1
	end
	if version > SaveSchema.Version then
		return SaveSchema.default()
	end
	return latestProfile(migrated)
end

function SaveSchema.canClaim(raw: any, owner: string, now: number): boolean
	if type(raw) ~= "table" or type(raw.SessionLock) ~= "table" then
		return true
	end
	local lock = raw.SessionLock
	return lock.Owner == owner
		or type(lock.Owner) ~= "string"
		or type(lock.ExpiresAt) ~= "number"
		or lock.ExpiresAt <= now
end

function SaveSchema.canWrite(raw: any, owner: string): boolean
	return type(raw) == "table"
		and type(raw.SessionLock) == "table"
		and raw.SessionLock.Owner == owner
end

function SaveSchema.record(profile: Profile, owner: string?, expiresAt: number?): Record
	local record: Record = {
		Version = SaveSchema.Version,
		Profile = latestProfile(profile),
		SessionLock = nil,
	}
	if owner and expiresAt then
		record.SessionLock = {
			Owner = owner,
			ExpiresAt = expiresAt,
		}
	end
	return record
end

return SaveSchema
