-- Generated binary delivery: preserve all pre-look content except map Data/lighting.
local fs, rb, luau = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau")
local place = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.pre-look.rbxl"))
place.ReplicatedStorage.MeadowV4.Data.Source = fs.readFile("prototype/meadow-v4/MeadowV4Data.luau")
place.ReplicatedStorage.GreyboxScene.Source = fs.readFile("slice-v2/prototype/Scene.luau")
local server = place.ServerScriptService
for _, pair in { {"LightingPresets", "ModuleScript", "LightingPresets.luau"}, {"LightingPresetController", "Script", "LightingPreset.server.luau"} } do
	local item = rb.Instance.new(pair[2])
	item.Name = pair[1]
	item.Source = fs.readFile("slice-v2/prototype/" .. pair[3])
	item.Parent = server
end
local replicated = rb.Instance.new("ModuleScript")
replicated.Name = "LightingPresets"
replicated.Source = fs.readFile("slice-v2/prototype/LightingPresets.luau")
replicated.Parent = place.ReplicatedStorage
local client = rb.Instance.new("LocalScript")
client.Name = "LightingPresetController"
client.Source = fs.readFile("slice-v2/prototype/LightingPreset.client.luau")
client.Parent = place.StarterPlayer.StarterPlayerScripts
server:SetAttribute("LightingPreset", "GardenWarm")
local env = {Color3=rb.Color3, Instance=rb.Instance}
local presets = luau.load(fs.readFile("slice-v2/prototype/LightingPresets.luau"), {environment=env})()
assert(place.Lighting.Technology == rb.Enum.Technology.Future, "Future lighting must already be serialized")
presets.apply(place.Lighting, "GardenWarm")
local bytes = rb.serializePlace(place)
fs.writeFile("prototype/guardian-greybox.rbxl", bytes)
fs.writeFile("slice-v2/prototype/guardian-greybox.rbxl", bytes)
rb.deserializePlace(bytes)
print("PASS generated guardian look place and canonical byte parity")
