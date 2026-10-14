local server = game:GetService("ServerScriptService")
local lighting = game:GetService("Lighting")
local presets = require(server:WaitForChild("LightingPresets"))
local function apply()
	local requested = server:GetAttribute("LightingPreset")
	presets.apply(lighting, requested)
end
server:GetAttributeChangedSignal("LightingPreset"):Connect(apply)
apply()
