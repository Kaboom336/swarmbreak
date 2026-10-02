--!strict
-- Pure third-person camera tuning and platform decisions.
local CameraConfig = {}

CameraConfig.Distance = 9
CameraConfig.CrowdedDistance = 11
CameraConfig.CrowdEnemyCount = 12
CameraConfig.CrowdRadius = 30
CameraConfig.DistanceResponse = 4
CameraConfig.RightOffset = 2.5
CameraConfig.HeightOffset = 2.2
CameraConfig.StartPitchDegrees = 18
CameraConfig.MinPitchDegrees = 8
CameraConfig.MaxPitchDegrees = 40
CameraConfig.CrosshairSize = 18
CameraConfig.MouseLockDefault = true

function CameraConfig.distanceForEnemyCount(enemyCount: number): number
	return if enemyCount >= CameraConfig.CrowdEnemyCount
		then CameraConfig.CrowdedDistance
		else CameraConfig.Distance
end

function CameraConfig.isTouchOnly(touchEnabled: boolean, mouseEnabled: boolean): boolean
	return touchEnabled and not mouseEnabled
end

function CameraConfig.crosshairVisible(touchEnabled: boolean, mouseEnabled: boolean): boolean
	return not CameraConfig.isTouchOnly(touchEnabled, mouseEnabled)
end

return CameraConfig
