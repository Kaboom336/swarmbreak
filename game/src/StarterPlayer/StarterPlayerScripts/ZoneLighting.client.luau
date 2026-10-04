--!strict
-- Lighting is client-local so players in different Outpost 9 zones can keep the
-- grade that belongs to the space they are currently standing in.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaLayout = require(Shared:WaitForChild("ArenaLayout"))
local LightingPresets = require(Shared:WaitForChild("LightingPresets"))
local Maps = require(Shared:WaitForChild("Maps"))

local function normalizedColor(values: { number }): Color3
	return Color3.new(values[1], values[2], values[3])
end

local function applyLightingPreset(preset: any)
	local properties = preset.Lighting
	Lighting.ColorShift_Bottom = normalizedColor(properties.ColorShift_Bottom or { 0, 0, 0 })
	Lighting.ColorShift_Top = normalizedColor(properties.ColorShift_Top or { 0, 0, 0 })
	Lighting.GeographicLatitude = properties.GeographicLatitude or 41.733
	for property, value in properties do
		if
			property == "Ambient"
			or property == "OutdoorAmbient"
			or property == "FogColor"
			or property == "ColorShift_Bottom"
			or property == "ColorShift_Top"
		then
			Lighting[property] = normalizedColor(value)
		elseif property ~= "Technology" then
			Lighting[property] = value
		end
	end

	local atmosphere = Lighting:FindFirstChild("Atmosphere") :: Atmosphere
	for property, value in preset.Atmosphere do
		atmosphere[property] = if property == "Color" or property == "Decay"
			then normalizedColor(value)
			else value
	end
	local bloom = Lighting:FindFirstChild("Bloom") :: BloomEffect
	for property, value in preset.Bloom do
		bloom[property] = value
	end
	local correction = Lighting:FindFirstChild("ColorCorrection") :: ColorCorrectionEffect
	correction.Brightness = preset.ColorCorrection.Brightness or 0
	for property, value in preset.ColorCorrection do
		correction[property] = if property == "TintColor" then normalizedColor(value) else value
	end
	local sky = Lighting:FindFirstChild("Sky") :: Sky
	sky.SkyboxBk = preset.Sky.SkyboxBk or "rbxasset://textures/sky/sky512_bk.tex"
	sky.SkyboxDn = preset.Sky.SkyboxDn or "rbxasset://textures/sky/sky512_dn.tex"
	sky.SkyboxFt = preset.Sky.SkyboxFt or "rbxasset://textures/sky/sky512_ft.tex"
	sky.SkyboxLf = preset.Sky.SkyboxLf or "rbxasset://textures/sky/sky512_lf.tex"
	sky.SkyboxRt = preset.Sky.SkyboxRt or "rbxasset://textures/sky/sky512_rt.tex"
	sky.SkyboxUp = preset.Sky.SkyboxUp or "rbxasset://textures/sky/sky512_up.tex"
	sky.MoonTextureId = preset.Sky.MoonTextureId or "rbxasset://sky/moon.jpg"
	sky.SunTextureId = preset.Sky.SunTextureId or "rbxasset://sky/sun.jpg"
	for property, value in preset.Sky do
		if property ~= "Tint" then
			sky[property] = value
		end
	end
end

local activePreset: any = nil

local function updateLighting()
	if player:GetAttribute("BossIntroInputLocked") then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local zone = if root and root:IsA("BasePart")
		then ArenaLayout.zoneAt({ x = root.Position.X, z = root.Position.Z })
		else nil
	local arena = workspace:FindFirstChild("Arena")
	local mapName = arena and arena:GetAttribute("MapName")
	local map = Maps.get(if type(mapName) == "string" then mapName else nil)
	local preset = if zone and zone.Id == "LandingPad"
		then LightingPresets.LandingPad
		else LightingPresets[map.LightingPreset]
	if preset ~= activePreset then
		activePreset = preset
		applyLightingPreset(preset)
	end
end

player:GetAttributeChangedSignal("BossIntroInputLocked"):Connect(function()
	activePreset = nil
	updateLighting()
end)

while true do
	updateLighting()
	task.wait(0.25)
end
