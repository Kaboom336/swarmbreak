--!strict
-- Pure validation and application of player-controlled settings.
local Settings = {}

Settings.DefaultVolume = 0.5
Settings.DefaultMouseLock = true
Settings.DefaultAutoAim = true
Settings.DefaultAimAssistStrength = 1
Settings.DefaultUiScale = 1
Settings.DefaultLeftHanded = false
Settings.DefaultReduceMotion = false
Settings.DefaultMute = false

Settings.MinUiScale = 0.75
Settings.MaxUiScale = 1.25

Settings.Fields = {
	"MusicVolume",
	"SfxVolume",
	"MouseLockEnabled",
	"AutoAim",
	"AimAssistStrength",
	"UiScale",
	"LeftHanded",
	"ReduceMotion",
	"Mute",
}

function Settings.clamp(value: any): number
	if type(value) ~= "number" or value ~= value then
		return Settings.DefaultVolume
	end
	return math.clamp(value, 0, 1)
end

function Settings.clampAimAssistStrength(value: any): number
	if type(value) ~= "number" or value ~= value then
		return Settings.DefaultAimAssistStrength
	end
	return math.clamp(value, 0, 1)
end

function Settings.clampUiScale(value: any): number
	if type(value) ~= "number" or value ~= value then
		return Settings.DefaultUiScale
	end
	return math.clamp(value, Settings.MinUiScale, Settings.MaxUiScale)
end

local function booleanOr(value: any, fallback: boolean): boolean
	return if type(value) == "boolean" then value else fallback
end

function Settings.sanitize(raw: any): any
	local source = if type(raw) == "table" then raw else {}
	return {
		MusicVolume = Settings.clamp(source.MusicVolume),
		SfxVolume = Settings.clamp(source.SfxVolume),
		MouseLockEnabled = booleanOr(source.MouseLockEnabled, Settings.DefaultMouseLock),
		AutoAim = booleanOr(source.AutoAim, Settings.DefaultAutoAim),
		AimAssistStrength = Settings.clampAimAssistStrength(source.AimAssistStrength),
		UiScale = Settings.clampUiScale(source.UiScale),
		LeftHanded = booleanOr(source.LeftHanded, Settings.DefaultLeftHanded),
		ReduceMotion = booleanOr(source.ReduceMotion, Settings.DefaultReduceMotion),
		Mute = booleanOr(source.Mute, Settings.DefaultMute),
	}
end

function Settings.apply(profile: any, changes: any): any
	local nextProfile = if type(profile) == "table" then table.clone(profile) else {}
	if type(changes) ~= "table" then
		return nextProfile
	end
	if changes.MusicVolume ~= nil then
		nextProfile.MusicVolume = Settings.clamp(changes.MusicVolume)
	end
	if changes.SfxVolume ~= nil then
		nextProfile.SfxVolume = Settings.clamp(changes.SfxVolume)
	end
	if type(changes.MouseLockEnabled) == "boolean" then
		nextProfile.MouseLockEnabled = changes.MouseLockEnabled
	end
	if type(changes.AutoAim) == "boolean" then
		nextProfile.AutoAim = changes.AutoAim
	end
	if changes.AimAssistStrength ~= nil then
		nextProfile.AimAssistStrength = Settings.clampAimAssistStrength(changes.AimAssistStrength)
	end
	if changes.UiScale ~= nil then
		nextProfile.UiScale = Settings.clampUiScale(changes.UiScale)
	end
	if type(changes.LeftHanded) == "boolean" then
		nextProfile.LeftHanded = changes.LeftHanded
	end
	if type(changes.ReduceMotion) == "boolean" then
		nextProfile.ReduceMotion = changes.ReduceMotion
	end
	if type(changes.Mute) == "boolean" then
		nextProfile.Mute = changes.Mute
	end
	return nextProfile
end

return Settings
