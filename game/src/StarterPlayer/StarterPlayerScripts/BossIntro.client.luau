--!strict
-- Cinematic boss intro: letterbox bars, camera sweep on the boss spawn, name card.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local BossIntro = ReplicatedStorage:WaitForChild("Remotes").BossIntro :: RemoteEvent
local LightingPresets = require(ReplicatedStorage.Shared.LightingPresets)
local Maps = require(ReplicatedStorage.Shared.Maps)
local Theme = require(ReplicatedStorage.Shared.Theme)
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local function normalizedColor(t: { number }): Color3
	return Color3.new(t[1], t[2], t[3])
end

local function applyLightingPreset(preset: any)
	local properties = preset.Lighting
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

	local atmosphere = Lighting:FindFirstChild("Atmosphere") :: Atmosphere
	atmosphere.Density = preset.Atmosphere.Density
	atmosphere.Offset = preset.Atmosphere.Offset
	atmosphere.Color = normalizedColor(preset.Atmosphere.Color)
	atmosphere.Decay = normalizedColor(preset.Atmosphere.Decay)
	atmosphere.Glare = preset.Atmosphere.Glare
	atmosphere.Haze = preset.Atmosphere.Haze

	local bloom = Lighting:FindFirstChild("Bloom") :: BloomEffect
	bloom.Intensity = preset.Bloom.Intensity
	bloom.Size = preset.Bloom.Size
	bloom.Threshold = preset.Bloom.Threshold

	local correction = Lighting:FindFirstChild("ColorCorrection") :: ColorCorrectionEffect
	correction.Contrast = preset.ColorCorrection.Contrast
	correction.Saturation = preset.ColorCorrection.Saturation
	correction.TintColor = normalizedColor(preset.ColorCorrection.TintColor)

	local sky = Lighting:FindFirstChild("Sky") :: Sky
	sky.StarCount = preset.Sky.StarCount
	sky.CelestialBodiesShown = preset.Sky.CelestialBodiesShown
	sky.SunAngularSize = preset.Sky.SunAngularSize
end

BossIntro.OnClientEvent:Connect(function(bossName: string, seconds: number)
	applyLightingPreset(LightingPresets.BossFight)
	local arena = workspace:FindFirstChild("Arena")
	local bossSpawn = arena and arena:FindFirstChild("BossSpawn") :: BasePart?
	local gui = player:WaitForChild("PlayerGui")

	local card = Instance.new("ScreenGui")
	card.Name = "BossCard"
	card.IgnoreGuiInset = true
	card.DisplayOrder = 50
	card.Parent = gui
	UiKit.ScreenScale(card)
	for _, y in { 0, 0.85 } do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, 0, 0.15, 0)
		bar.Position = UDim2.new(0, 0, y, 0)
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Parent = card
	end
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 80)
	name.Position = UDim2.new(0, 0, 0.62, 0)
	name.BackgroundTransparency = 1
	name.Text = string.upper(bossName)
	name.Font = UiKit.Fonts.Banner
	name.TextSize = 64
	name.TextColor3 = Color3.fromRGB(Theme.Telegraph[1], Theme.Telegraph[2], Theme.Telegraph[3])
	name.TextStrokeTransparency = 0
	name.TextTransparency = 1
	name.Parent = card
	TweenService:Create(name, TweenInfo.new(0.8), { TextTransparency = 0 }):Play()

	if bossSpawn then
		camera.CameraType = Enum.CameraType.Scriptable
		local from = bossSpawn.Position + Vector3.new(30, 25, 30)
		local to = bossSpawn.Position + Vector3.new(14, 10, 14)
		camera.CFrame = CFrame.lookAt(from, bossSpawn.Position)
		TweenService:Create(camera, TweenInfo.new(seconds, Enum.EasingStyle.Sine), {
			CFrame = CFrame.lookAt(to, bossSpawn.Position + Vector3.new(0, 6, 0)),
		}):Play()
	end
	task.wait(seconds)
	camera.CameraType = Enum.CameraType.Custom
	card:Destroy()
	local mapName = if arena then arena:GetAttribute("MapName") else nil
	local map = Maps.get(if type(mapName) == "string" then mapName else nil)
	applyLightingPreset(LightingPresets[map.LightingPreset])
end)
