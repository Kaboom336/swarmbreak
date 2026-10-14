local lighting = game:GetService("Lighting")
local presets = require(game:GetService("ReplicatedStorage"):WaitForChild("LightingPresets"))
local function apply()
	local selected = lighting:GetAttribute("AppliedLightingPreset")
	if selected then
		presets.apply(lighting, selected)
	end
end
lighting:GetAttributeChangedSignal("AppliedLightingPreset"):Connect(apply)
apply()
