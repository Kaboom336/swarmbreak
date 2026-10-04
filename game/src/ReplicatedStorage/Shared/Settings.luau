--!strict
-- Pure validation and application of player-controlled settings.
local Settings = {}

Settings.DefaultVolume = 0.5
Settings.DefaultMouseLock = true
Settings.AutoFire = true
Settings.DefaultCombatCamera = true
Settings.DefaultUltimateCinematics = "Full"

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
	if type(changes.MouseLockEnabled) == "boolean" then
		profile.MouseLockEnabled = changes.MouseLockEnabled
	end
	if type(changes.CombatCameraEnabled) == "boolean" then
		profile.CombatCameraEnabled = changes.CombatCameraEnabled
	end
	if
		changes.UltimateCinematics == "Full"
		or changes.UltimateCinematics == "Short"
		or changes.UltimateCinematics == "Off"
	then
		profile.UltimateCinematics = changes.UltimateCinematics
	end
	return profile
end

return Settings
