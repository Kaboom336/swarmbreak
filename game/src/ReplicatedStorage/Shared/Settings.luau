--!strict
-- Pure validation and application of player-controlled settings.
local Settings = {}

Settings.DefaultVolume = 0.5
Settings.DefaultMouseLock = true
Settings.DefaultQuality = "Auto"
Settings.QualityChoices = { "Auto", "Low", "High" }

function Settings.clamp(value: any): number
	if type(value) ~= "number" or value ~= value then
		return Settings.DefaultVolume
	end
	return math.clamp(value, 0, 1)
end

function Settings.quality(value: any): string
	if value == "Low" or value == "High" then
		return value
	end
	return Settings.DefaultQuality
end

function Settings.nextQuality(value: any): string
	local current = Settings.quality(value)
	local index = table.find(Settings.QualityChoices, current) or 1
	return Settings.QualityChoices[index % #Settings.QualityChoices + 1]
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
	if type(changes.MouseLockEnabled) == "boolean" then
		profile.MouseLockEnabled = changes.MouseLockEnabled
	end
	if changes.Quality ~= nil then
		profile.Quality = Settings.quality(changes.Quality)
	end
	return profile
end

return Settings
