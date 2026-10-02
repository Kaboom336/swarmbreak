--!strict
-- Paste this file into the Studio command bar while the place is open.
-- Run it from the game directory so the captures land in assets/renders/ingame.

local Lighting = game:GetService("Lighting")
local StudioService = game:GetService("StudioService")

local OUTPUT_DIRECTORY = "../assets/renders/ingame"
local LIGHTING_SETTLE_SECONDS = 2
local CAMERA_SETTLE_SECONDS = 1
local FIELD_OF_VIEW = 70

type CameraShot = {
	FileName: string,
	Position: Vector3,
	LookAt: Vector3,
}

local cameraShots: { CameraShot } = {
	{
		FileName = "01-arena-overview.png",
		Position = Vector3.new(112, 96, 112),
		LookAt = Vector3.new(0, 3, 0),
	},
	{
		FileName = "02-gameplay-wave-3.png",
		Position = Vector3.new(0, 24, 42),
		LookAt = Vector3.new(0, 6, -8),
	},
	{
		FileName = "03-enemy-readability.png",
		Position = Vector3.new(-48, 28, 50),
		LookAt = Vector3.new(5, 5, -10),
	},
	{
		FileName = "04-glow-quality-1.png",
		Position = Vector3.new(57, 17, 50),
		LookAt = Vector3.new(0, 6, 0),
	},
	{
		FileName = "05-phone-1334x750.png",
		Position = Vector3.new(-9, 15, 26),
		LookAt = Vector3.new(0, 5, -10),
	},
	{
		FileName = "06-queen-boss-intro.png",
		Position = Vector3.new(26, 18, -42),
		LookAt = Vector3.new(0, 7, -70),
	},
}

local function getOrCreateAtmosphere(): Atmosphere
	local existing = Lighting:FindFirstChildOfClass("Atmosphere")
	if existing then
		return existing :: Atmosphere
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "StationAtmosphere"
	atmosphere.Parent = Lighting
	return atmosphere
end

local function getOrCreateBloom(): BloomEffect
	local existing = Lighting:FindFirstChildOfClass("BloomEffect")
	if existing then
		return existing :: BloomEffect
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "StationBloom"
	bloom.Parent = Lighting
	return bloom
end

local function getOrCreateColorCorrection(): ColorCorrectionEffect
	local existing = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if existing then
		return existing :: ColorCorrectionEffect
	end

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "StationColorCorrection"
	colorCorrection.Parent = Lighting
	return colorCorrection
end

local function applyStationPreset()
	Lighting.ClockTime = 17
	Lighting.Brightness = 2.5
	Lighting.ExposureCompensation = 0
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.ShadowSoftness = 0.3
	Lighting.Ambient = Color3.fromRGB(82, 88, 112)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 142, 176)
	Lighting.FogColor = Color3.fromRGB(120, 145, 184)
	Lighting.FogStart = 160
	Lighting.FogEnd = 600

	local atmosphere = getOrCreateAtmosphere()
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(164, 181, 216)
	atmosphere.Decay = Color3.fromRGB(104, 116, 154)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.5

	local bloom = getOrCreateBloom()
	bloom.Intensity = 1.2
	bloom.Threshold = 0.85
	bloom.Size = 24

	local colorCorrection = getOrCreateColorCorrection()
	colorCorrection.Brightness = 0
	colorCorrection.Contrast = 0.15
	colorCorrection.Saturation = 0.05
	colorCorrection.TintColor = Color3.fromRGB(255, 238, 218)
end

local camera = workspace.CurrentCamera
assert(camera, "Open the place in Studio before running the capture script")

local originalCameraType = camera.CameraType
local originalCameraSubject = camera.CameraSubject
local originalCFrame = camera.CFrame
local originalFieldOfView = camera.FieldOfView

applyStationPreset()
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = FIELD_OF_VIEW
task.wait(LIGHTING_SETTLE_SECONDS)

local ok, captureError = pcall(function()
	for _, shot in cameraShots do
		camera.CFrame = CFrame.lookAt(shot.Position, shot.LookAt)
		task.wait(CAMERA_SETTLE_SECONDS)
		StudioService:TakeScreenshot(OUTPUT_DIRECTORY .. "/" .. shot.FileName)
		task.wait()
	end
end)

camera.CameraType = originalCameraType
camera.CameraSubject = originalCameraSubject
camera.CFrame = originalCFrame
camera.FieldOfView = originalFieldOfView

assert(ok, captureError)
print(string.format("Saved %d review captures to %s", #cameraShots, OUTPUT_DIRECTORY))
