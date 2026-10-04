--!strict
-- Pure lighting data. Colors use normalized RGB values so Station can be copied
-- directly into default.project.json.

local LightingPresets = {
	DuskGradient = {
		Horizon = { 1, 0.7019607843, 0.4784313725 },
		Top = { 0.4784313725, 0.3098039216, 0.8392156863 },
		CloudSea = true,
	},
	Station = {
		Lighting = {
			Technology = "Future",
			ClockTime = 14.5,
			Brightness = 2.5,
			ExposureCompensation = 0,
			GlobalShadows = true,
			EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 0.5,
			ShadowSoftness = 0.35,
			Ambient = { 0.62, 0.55, 0.72 },
			OutdoorAmbient = { 0.55, 0.52, 0.5 },
			FogColor = { 1, 0.93, 0.85 },
			FogStart = 400,
			FogEnd = 1500,
		},
		Atmosphere = {
			Density = 0.3,
			Offset = 0.25,
			Color = { 1, 0.93, 0.85 },
			Decay = { 0.4784313725, 0.3098039216, 0.8392156863 },
			Glare = 0,
			Haze = 0.2,
		},
		Bloom = {
			Intensity = 0.4,
			Size = 16,
			Threshold = 1.8,
		},
		ColorCorrection = {
			Contrast = 0.15,
			Saturation = 0.15,
			TintColor = { 1, 0.96, 0.91 },
		},
		Sky = {
			Tint = { 1, 0.96, 0.91 },
			StarCount = 0,
			CelestialBodiesShown = true,
			SunAngularSize = 11,
		},
	},
	LandingPad = {
		Lighting = {
			Technology = "Future",
			ClockTime = 16.600000381469727,
			Brightness = 3.200000047683716,
			ExposureCompensation = 0,
			GlobalShadows = true,
			EnvironmentDiffuseScale = 0.6000000238418579,
			EnvironmentSpecularScale = 0.800000011920929,
			ShadowSoftness = 0.07999999821186066,
			Ambient = { 40 / 255, 34 / 255, 38 / 255 },
			OutdoorAmbient = { 118 / 255, 100 / 255, 100 / 255 },
			FogColor = { 1, 196 / 255, 160 / 255 },
			FogStart = 400,
			FogEnd = 1500,
			ColorShift_Bottom = { 40 / 255, 30 / 255, 50 / 255 },
			ColorShift_Top = { 1, 196 / 255, 140 / 255 },
			GeographicLatitude = 18,
		},
		Atmosphere = {
			Density = 0.2800000011920929,
			Offset = 0.15000000596046448,
			Color = { 1, 196 / 255, 160 / 255 },
			Decay = { 190 / 255, 120 / 255, 96 / 255 },
			Glare = 0.6000000238418579,
			Haze = 0.699999988079071,
		},
		Bloom = {
			Intensity = 0.3499999940395355,
			Size = 18,
			Threshold = 1.7999999523162842,
		},
		ColorCorrection = {
			Brightness = -0.019999999552965164,
			Contrast = 0.2199999988079071,
			Saturation = 0.07999999821186066,
			TintColor = { 1, 240 / 255, 222 / 255 },
		},
		Sky = {
			Tint = { 1, 240 / 255, 222 / 255 },
			StarCount = 0,
			CelestialBodiesShown = true,
			SunAngularSize = 11,
			SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex",
			SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex",
			SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex",
			SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex",
			SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex",
			SkyboxUp = "rbxasset://textures/sky/sky512_up.tex",
			MoonTextureId = "rbxasset://sky/moon.jpg",
			SunTextureId = "rbxasset://sky/sun.jpg",
		},
	},
	BossFight = {
		Lighting = {
			Technology = "Future",
			ClockTime = 17,
			Brightness = 2.3,
			ExposureCompensation = 0,
			GlobalShadows = true,
			EnvironmentDiffuseScale = 0.65,
			EnvironmentSpecularScale = 0.8,
			ShadowSoftness = 0.3,
			Ambient = { 0.42, 0.25, 0.3 },
			OutdoorAmbient = { 0.55, 0.32, 0.35 },
			FogColor = { 0.62, 0.3, 0.3 },
			FogStart = 140,
			FogEnd = 560,
		},
		Atmosphere = {
			Density = 0.32,
			Offset = 0.25,
			Color = { 0.92, 0.5, 0.45 },
			Decay = { 0.42, 0.15, 0.18 },
			Glare = 0.28,
			Haze = 1.7,
		},
		Bloom = {
			Intensity = 0.4,
			Size = 16,
			Threshold = 1.8,
		},
		ColorCorrection = {
			Contrast = 0.2,
			Saturation = 0.08,
			TintColor = { 1, 0.76, 0.72 },
		},
		Sky = {
			Tint = { 1, 0.76, 0.72 },
			StarCount = 0,
			CelestialBodiesShown = true,
			SunAngularSize = 11,
		},
	},
	NestInterior = {
		Lighting = {
			Technology = "Future",
			ClockTime = 0,
			Brightness = 1.4,
			ExposureCompensation = 0.05,
			GlobalShadows = true,
			EnvironmentDiffuseScale = 0.45,
			EnvironmentSpecularScale = 0.7,
			ShadowSoftness = 0.5,
			Ambient = { 0.2, 0.16, 0.28 },
			OutdoorAmbient = { 0.18, 0.28, 0.32 },
			FogColor = { 0.22, 0.18, 0.34 },
			FogStart = 70,
			FogEnd = 360,
		},
		Atmosphere = {
			Density = 0.38,
			Offset = 0.2,
			Color = { 0.48, 0.34, 0.68 },
			Decay = { 0.14, 0.28, 0.32 },
			Glare = 0.15,
			Haze = 2,
		},
		Bloom = {
			Intensity = 0.4,
			Size = 16,
			Threshold = 1.8,
		},
		ColorCorrection = {
			Contrast = 0.15,
			Saturation = 0.15,
			TintColor = { 0.82, 0.7, 1 },
		},
		Sky = {
			Tint = { 0.82, 0.7, 1 },
			StarCount = 0,
			CelestialBodiesShown = false,
			SunAngularSize = 11,
		},
		LightSources = {
			Crystal = {
				Kind = "PointLight",
				FixtureMaterial = "SmoothPlastic",
				Color = { 0.68, 0.2, 1 },
				Brightness = 1.5,
				Range = 12,
			},
			Fungus = {
				Kind = "PointLight",
				FixtureMaterial = "SmoothPlastic",
				Color = { 0.15, 1, 0.82 },
				Brightness = 1.5,
				Range = 12,
			},
		},
	},
	Base = {
		Lighting = {
			Technology = "Future",
			ClockTime = 14,
			Brightness = 2,
			ExposureCompensation = 0,
			GlobalShadows = true,
			EnvironmentDiffuseScale = 0.6,
			EnvironmentSpecularScale = 0.8,
			ShadowSoftness = 0.3,
			Ambient = { 0.35, 0.35, 0.4 },
			OutdoorAmbient = { 0.48, 0.5, 0.56 },
			FogColor = { 0.72, 0.78, 0.88 },
			FogStart = 200,
			FogEnd = 750,
		},
		Atmosphere = {
			Density = 0.25,
			Offset = 0.25,
			Color = { 0.72, 0.8, 0.92 },
			Decay = { 0.42, 0.42, 0.48 },
			Glare = 0.15,
			Haze = 1.2,
		},
		Bloom = {
			Intensity = 0.4,
			Size = 16,
			Threshold = 1.8,
		},
		ColorCorrection = {
			Contrast = 0.1,
			Saturation = 0,
			TintColor = { 0.95, 0.97, 1 },
		},
		Sky = {
			Tint = { 0.95, 0.97, 1 },
			StarCount = 0,
			CelestialBodiesShown = true,
			SunAngularSize = 11,
		},
	},
	LowQuality = {
		Lighting = {
			Technology = "Future",
			ClockTime = 17,
			Brightness = 2.5,
			ExposureCompensation = 0,
			GlobalShadows = false,
			EnvironmentDiffuseScale = 0.7,
			EnvironmentSpecularScale = 0.4,
			ShadowSoftness = 0,
			Ambient = { 0.4, 0.43, 0.52 },
			OutdoorAmbient = { 0.5, 0.53, 0.64 },
			FogColor = { 0.68, 0.76, 0.92 },
			FogStart = 200,
			FogEnd = 700,
		},
		Atmosphere = {
			Density = 0.2,
			Offset = 0.25,
			Color = { 0.68, 0.78, 0.95 },
			Decay = { 0.48, 0.4, 0.38 },
			Glare = 0,
			Haze = 1,
		},
		Bloom = {
			Intensity = 0.4,
			Size = 16,
			Threshold = 1.8,
		},
		ColorCorrection = {
			Contrast = 0.12,
			Saturation = 0.03,
			TintColor = { 0.93, 0.96, 1 },
		},
		Sky = {
			Tint = { 0.93, 0.96, 1 },
			StarCount = 0,
			CelestialBodiesShown = true,
			SunAngularSize = 11,
		},
	},
}

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in value do
		result[key] = copy(child)
	end
	return result
end

local function mapGrade(
	tint: { number },
	atmosphere: { number },
	decay: { number },
	clockTime: number
)
	local preset = copy(LightingPresets.Station)
	preset.Lighting.ClockTime = clockTime
	preset.Lighting.FogColor = atmosphere
	preset.Atmosphere.Color = atmosphere
	preset.Atmosphere.Decay = decay
	preset.ColorCorrection.TintColor = tint
	preset.Sky.Tint = tint
	return preset
end

-- Each campaign entry owns a visibly different sky/grade while retaining the checked-in bloom.
LightingPresets.FrostRelay = mapGrade(
	{ 0.78, 0.9, 1 },
	{ 0.66, 0.82, 0.98 },
	{ 0.35, 0.5, 0.72 },
	10.5
)
LightingPresets.MagmaRefinery = mapGrade(
	{ 1, 0.72, 0.52 },
	{ 0.94, 0.48, 0.3 },
	{ 0.48, 0.16, 0.12 },
	18
)
LightingPresets.HiveHeart = copy(LightingPresets.NestInterior)
LightingPresets.HiveHeart.Atmosphere.Density = 0.32
LightingPresets.HiveHeart.ColorCorrection.Contrast = 0.15
LightingPresets.HiveHeart.ColorCorrection.Saturation = 0.15
LightingPresets.HiveHeart.ColorCorrection.TintColor = { 0.76, 0.62, 0.94 }
LightingPresets.HiveHeart.Sky.Tint = { 0.76, 0.62, 0.94 }

return LightingPresets
