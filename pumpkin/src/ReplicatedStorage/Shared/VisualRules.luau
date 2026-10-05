--!strict

local VisualRules = {}

VisualRules.PUMPKIN_HEIGHT_RATIO = 0.82
VisualRules.HERO_TEXT_MINIMUM = 28
VisualRules.MAX_ACTIVE_MAP_LIGHTS = 12
VisualRules.MAP_LIGHT_RANGE = 18
VisualRules.MAP_LIGHT_BRIGHTNESS = 1.35
VisualRules.REQUIRED_VALUE_BANDS = 3

VisualRules.FORBIDDEN_ASSET_CLASSES = {
	Script = true,
	LocalScript = true,
	ModuleScript = true,
	RemoteEvent = true,
	RemoteFunction = true,
	PackageLink = true,
}

function VisualRules.contactShadowDiameter(visualDiameter: number): number
	return math.clamp(math.max(0, visualDiameter) * 0.72, 3.2, 16)
end

function VisualRules.heroTextSize(_mobile: boolean): number
	return VisualRules.HERO_TEXT_MINIMUM
end

function VisualRules.groundContactOffset(visualDiameter: number): number
	return -math.max(0, visualDiameter) * VisualRules.PUMPKIN_HEIGHT_RATIO * 0.5
end

function VisualRules.cappedPumpkinLight(visualDiameter: number): (number, number)
	local diameter = math.max(0, visualDiameter)
	return math.clamp(0.45 + diameter * 0.045, 0.55, 1.2), math.clamp(6 + diameter * 0.45, 7, 16)
end

function VisualRules.assetClassAllowed(className: string): boolean
	return VisualRules.FORBIDDEN_ASSET_CLASSES[className] ~= true
end

function VisualRules.petModelNames(eggs: { any }): { string }
	local names = {}
	for _, egg in eggs do
		for _, pet in egg.Pets do
			table.insert(names, pet.Name)
		end
	end
	table.sort(names)
	return names
end

return VisualRules
