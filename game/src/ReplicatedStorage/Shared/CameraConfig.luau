--!strict
-- Pure third-person camera tuning and platform decisions.
local CameraConfig = {}

CameraConfig.Distance = 12
CameraConfig.RightOffset = 2
CameraConfig.HeightOffset = 1.5
CameraConfig.CrosshairSize = 18
CameraConfig.MouseLockDefault = true

function CameraConfig.isTouchOnly(touchEnabled: boolean, mouseEnabled: boolean): boolean
	return touchEnabled and not mouseEnabled
end

function CameraConfig.crosshairVisible(touchEnabled: boolean, mouseEnabled: boolean): boolean
	return not CameraConfig.isTouchOnly(touchEnabled, mouseEnabled)
end

return CameraConfig
