--!strict
-- Pure validation and application of player-controlled settings.
local Settings = {}

Settings.DefaultVolume = 0.5

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
	return profile
end

return Settings
