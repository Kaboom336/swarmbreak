--!strict
-- Paste this file into the Studio command bar while the place is open.
-- Run it from the game directory so the captures land in assets/renders/ingame.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StudioService = game:GetService("StudioService")

local EnemyBuilder = require(ServerStorage:WaitForChild("EnemyBuilder"))
local LightingPresets = require(ReplicatedStorage.Shared.LightingPresets)
local Theme = require(ReplicatedStorage.Shared.Theme)

local OUTPUT_DIRECTORY = "../assets/renders/ingame"
local LIGHTING_SETTLE_SECONDS = 2
local CAMERA_SETTLE_SECONDS = 1
local FIELD_OF_VIEW = 70
local REVIEW_ENEMY_COUNT = 8
local REVIEW_FOLDER_NAME = "CaptureWaveOneEnemies"

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
		FileName = "02-gameplay-wave-1-eight-enemies.png",
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

local function normalizedColor(channels: { number }): Color3
	return Color3.new(channels[1], channels[2], channels[3])
end

local function getOrCreateAtmosphere(): Atmosphere
	local existing = Lighting:FindFirstChildOfClass("Atmosphere")
	if existing then
		return existing :: Atmosphere
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "Atmosphere"
	atmosphere.Parent = Lighting
	return atmosphere
end

local function getOrCreateBloom(): BloomEffect
	local existing = Lighting:FindFirstChildOfClass("BloomEffect")
	if existing then
		return existing :: BloomEffect
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "Bloom"
	bloom.Parent = Lighting
	return bloom
end

local function getOrCreateColorCorrection(): ColorCorrectionEffect
	local existing = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if existing then
		return existing :: ColorCorrectionEffect
	end

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ColorCorrection"
	colorCorrection.Parent = Lighting
	return colorCorrection
end

local function getOrCreateSky(): Sky
	local existing = Lighting:FindFirstChildOfClass("Sky")
	if existing then
		return existing :: Sky
	end

	local sky = Instance.new("Sky")
	sky.Name = "Sky"
	sky.Parent = Lighting
	return sky
end

local function applyStationPreset()
	local preset = LightingPresets.Station
	local properties = preset.Lighting
	Lighting.Technology = Enum.Technology.Future
	Lighting.ClockTime = properties.ClockTime
	Lighting.Brightness = properties.Brightness
	Lighting.ExposureCompensation = properties.ExposureCompensation
	Lighting.GlobalShadows = properties.GlobalShadows
	Lighting.EnvironmentDiffuseScale = properties.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = properties.EnvironmentSpecularScale
	Lighting.ShadowSoftness = properties.ShadowSoftness
	Lighting.Ambient = normalizedColor(properties.Ambient)
	Lighting.OutdoorAmbient = normalizedColor(properties.OutdoorAmbient)
	Lighting.FogColor = normalizedColor(properties.FogColor)
	Lighting.FogStart = properties.FogStart
	Lighting.FogEnd = properties.FogEnd

	local atmosphere = getOrCreateAtmosphere()
	atmosphere.Density = preset.Atmosphere.Density
	atmosphere.Offset = preset.Atmosphere.Offset
	atmosphere.Color = normalizedColor(preset.Atmosphere.Color)
	atmosphere.Decay = normalizedColor(preset.Atmosphere.Decay)
	atmosphere.Glare = preset.Atmosphere.Glare
	atmosphere.Haze = preset.Atmosphere.Haze

	local bloom = getOrCreateBloom()
	bloom.Intensity = preset.Bloom.Intensity
	bloom.Threshold = preset.Bloom.Threshold
	bloom.Size = preset.Bloom.Size

	local colorCorrection = getOrCreateColorCorrection()
	colorCorrection.Brightness = 0
	colorCorrection.Contrast = preset.ColorCorrection.Contrast
	colorCorrection.Saturation = preset.ColorCorrection.Saturation
	colorCorrection.TintColor = normalizedColor(preset.ColorCorrection.TintColor)

	local sky = getOrCreateSky()
	sky.StarCount = preset.Sky.StarCount
	sky.CelestialBodiesShown = preset.Sky.CelestialBodiesShown
	sky.SunAngularSize = preset.Sky.SunAngularSize
end

local function setReviewState(): { () -> () }
	local restorers: { () -> () } = {}
	local state = ReplicatedStorage:FindFirstChild("State")
	if not state then
		return restorers
	end

	local function setInt(name: string, value: number)
		local object = state:FindFirstChild(name)
		if object and object:IsA("IntValue") then
			local original = object.Value
			table.insert(restorers, function()
				object.Value = original
			end)
			object.Value = value
		end
	end

	local function setNumber(name: string, value: number)
		local object = state:FindFirstChild(name)
		if object and object:IsA("NumberValue") then
			local original = object.Value
			table.insert(restorers, function()
				object.Value = original
			end)
			object.Value = value
		end
	end

	local function setString(name: string, value: string)
		local object = state:FindFirstChild(name)
		if object and object:IsA("StringValue") then
			local original = object.Value
			table.insert(restorers, function()
				object.Value = original
			end)
			object.Value = value
		end
	end

	setInt("Wave", 1)
	setString("Phase", "wave")
	setInt("Alive", REVIEW_ENEMY_COUNT)
	setNumber("TimeLeft", 0)
	return restorers
end

local function restoreReviewState(restorers: { () -> () })
	for _, restore in restorers do
		restore()
	end
end

local function addReviewHighlight(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.Name = "EnemyOutline"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 1
	highlight.OutlineColor =
		Color3.fromRGB(Theme.NeonAmber[1], Theme.NeonAmber[2], Theme.NeonAmber[3])
	highlight.OutlineTransparency = 0.2
	highlight.Parent = model
end

local function stageWaveOne(): Folder
	local oldReviewFolder = workspace:FindFirstChild(REVIEW_FOLDER_NAME)
	if oldReviewFolder then
		oldReviewFolder:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = REVIEW_FOLDER_NAME
	folder.Parent = workspace

	local positions = {
		Vector3.new(-18, 4, 5),
		Vector3.new(-10, 4, -3),
		Vector3.new(-3, 4, 7),
		Vector3.new(5, 4, -7),
		Vector3.new(12, 4, 4),
		Vector3.new(19, 4, -5),
		Vector3.new(-14, 4, -16),
		Vector3.new(15, 4, -18),
	}

	for index, position in positions do
		local facing = CFrame.lookAt(position, Vector3.new(0, position.Y, 28))
		local rig = EnemyBuilder.build("Walker", Vector3.new(3, 6, 2.4), facing)
		local model = rig.Model :: Model
		model.Name = string.format("WaveOneWalker%02d", index)
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end
		addReviewHighlight(model)
		model.Parent = folder
	end

	return folder
end

local camera = workspace.CurrentCamera
assert(camera, "Open the place in Studio before running the capture script")
assert(#cameraShots == 6, "The review set must contain exactly six fixed cameras")

local originalCameraType = camera.CameraType
local originalCameraSubject = camera.CameraSubject
local originalCFrame = camera.CFrame
local originalFieldOfView = camera.FieldOfView

applyStationPreset()
local originalState = setReviewState()
local reviewFolder: Folder? = nil

local ok, captureError = pcall(function()
	reviewFolder = stageWaveOne()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FIELD_OF_VIEW
	task.wait(LIGHTING_SETTLE_SECONDS)

	for _, shot in cameraShots do
		camera.CFrame = CFrame.lookAt(shot.Position, shot.LookAt)
		task.wait(CAMERA_SETTLE_SECONDS)
		StudioService:TakeScreenshot(OUTPUT_DIRECTORY .. "/" .. shot.FileName)
		task.wait()
	end
end)

if reviewFolder then
	reviewFolder:Destroy()
end
restoreReviewState(originalState)
camera.CameraType = originalCameraType
camera.CameraSubject = originalCameraSubject
camera.CFrame = originalCFrame
camera.FieldOfView = originalFieldOfView

assert(ok, captureError)
print(string.format("Saved %d review captures to %s", #cameraShots, OUTPUT_DIRECTORY))
