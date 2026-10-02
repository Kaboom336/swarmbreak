--!strict
-- Pure validation and application of player-controlled settings.
local Settings = {}

Settings.DefaultVolume = 0.5
Settings.DefaultMouseLock = true
Settings.DefaultMute = false

function Settings.clamp(value: any): number
	if type(value) ~= "number" or value ~= value then
		return Settings.DefaultVolume
	end
	return math.clamp(value, 0, 1)
end

function Settings.apply(profile: any, changes: any): any
	if type(changes) ~= "table" then
		return profile
	end
	if changes.MusicVolume ~= nil then
		profile.MusicVolume = Settings.clamp(changes.MusicVolume)
	end
	if changes.SfxVolume ~= nil then
		profile.SfxVolume = Settings.clamp(changes.SfxVolume)
	end
	if type(changes.Mute) == "boolean" then
		profile.Mute = changes.Mute
	end
	if type(changes.MouseLockEnabled) == "boolean" then
		profile.MouseLockEnabled = changes.MouseLockEnabled
	end
	return profile
end

return Settings
