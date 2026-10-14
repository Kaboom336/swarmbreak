-- Reference-inspired values, not extracted settings from other games.
-- Technology=Future is serialized by Rojo; Roblox restricts runtime writes.
local Presets = {}
local rgb = Color3.fromRGB
Presets.Values = {
	GardenWarm = {
		ClockTime = 14,
		Brightness = 2.8,
		Ambient = rgb(138, 126, 107),
		OutdoorAmbient = rgb(175, 181, 153),
		EnvironmentDiffuseScale = 0.8,
		EnvironmentSpecularScale = 0.45,
		ShadowSoftness = 0.4,
		Atmosphere = {
			Density = 0.22,
			Offset = 0.15,
			Color = rgb(199, 224, 255),
			Decay = rgb(255, 226, 180),
			Glare = 0.12,
			Haze = 0.7,
		},
		ColorCorrection = { Brightness = 0.01, Contrast = 0.06, Saturation = 0.16, TintColor = rgb(255, 248, 231) },
		Bloom = { Intensity = 0.12, Size = 20, Threshold = 1.25 },
		SunRays = { Intensity = 0.035, Spread = 0.75 },
	},
	EggClear = {
		ClockTime = 13,
		Brightness = 3,
		Ambient = rgb(126, 139, 158),
		OutdoorAmbient = rgb(170, 188, 207),
		EnvironmentDiffuseScale = 0.85,
		EnvironmentSpecularScale = 0.5,
		ShadowSoftness = 0.3,
		Atmosphere = {
			Density = 0.16,
			Offset = 0.1,
			Color = rgb(181, 218, 255),
			Decay = rgb(210, 232, 255),
			Glare = 0.05,
			Haze = 0.35,
		},
		ColorCorrection = { Brightness = 0.015, Contrast = 0.09, Saturation = 0.12, TintColor = rgb(241, 250, 255) },
		Bloom = { Intensity = 0.08, Size = 16, Threshold = 1.4 },
		SunRays = { Intensity = 0.02, Spread = 0.8 },
	},
	PetPop = {
		ClockTime = 14.5,
		Brightness = 3.2,
		Ambient = rgb(151, 143, 172),
		OutdoorAmbient = rgb(192, 191, 221),
		EnvironmentDiffuseScale = 0.9,
		EnvironmentSpecularScale = 0.65,
		ShadowSoftness = 0.5,
		Atmosphere = {
			Density = 0.18,
			Offset = 0.2,
			Color = rgb(203, 214, 255),
			Decay = rgb(248, 216, 255),
			Glare = 0.16,
			Haze = 0.5,
		},
		ColorCorrection = { Brightness = 0.02, Contrast = 0.08, Saturation = 0.23, TintColor = rgb(255, 242, 255) },
		Bloom = { Intensity = 0.18, Size = 24, Threshold = 1.2 },
		SunRays = { Intensity = 0.025, Spread = 0.85 },
	},
}
function Presets.apply(lighting, name)
	local selected = Presets.Values[name] and name or "GardenWarm"
	local values = Presets.Values[selected]
	-- One owned effect per class, so A/B switches never stack post-processing.
	local owned = {
		LookAtmosphere = "Atmosphere",
		LookColorCorrection = "ColorCorrectionEffect",
		LookBloom = "BloomEffect",
		LookSunRays = "SunRaysEffect",
	}
	for _, child in lighting:GetChildren() do
		if
			child:IsA("Atmosphere")
			or child:IsA("ColorCorrectionEffect")
			or child:IsA("BloomEffect")
			or child:IsA("SunRaysEffect")
		then
			if not owned[child.Name] or not child:IsA(owned[child.Name]) then
				child:Destroy()
			end
		end
	end
	for key, value in values do
		if type(value) ~= "table" then
			lighting[key] = value
		end
	end
	lighting.GlobalShadows = true
	for _, pair in
		{
			{ "Atmosphere", "Atmosphere" },
			{ "ColorCorrection", "ColorCorrectionEffect" },
			{ "Bloom", "BloomEffect" },
			{ "SunRays", "SunRaysEffect" },
		}
	do
		-- Reuse serialized instances on server/client; avoid replication races.
		local effect = lighting:FindFirstChild("Look" .. pair[1])
		if not effect then
			effect = Instance.new(pair[2])
			effect.Name = "Look" .. pair[1]
			effect.Parent = lighting
		end
		for key, value in values[pair[1]] do
			effect[key] = value
		end
	end
	lighting:SetAttribute("AppliedLightingPreset", selected)
	return selected
end
return Presets
