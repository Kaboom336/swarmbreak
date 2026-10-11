-- Independent check of packaged source and the retained imported art.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local place = roblox.deserializePlace(fs.readFile("garden-test.rbxl"))
local required = {
	Garden = { server = false, client = false },
	GardenScene = false,
	GardenRules = false,
	GardenLayout = false,
	Data = false,
	SessionRules = false,
}
local count = 0
for _, instance in place:GetDescendants() do
	if instance:IsA("LuaSourceContainer") then
		count += 1
		if instance.Name == "Garden" then
			local category = if instance:IsA("LocalScript") then "client" else "server"
			local path = if category == "client"
				then "src/StarterPlayer/StarterPlayerScripts/Garden.client.luau"
				else "src/ServerScriptService/Garden.server.luau"
			assert(instance.Source:gsub("\r\n", "\n") == fs.readFile(path):gsub("\r\n", "\n"), path)
			required.Garden[category] = true
		elseif instance:IsA("ModuleScript") and required[instance.Name] ~= nil then
			local path = if instance.Name == "GardenScene" or instance.Name == "Data"
				then "src/ServerStorage/" .. instance.Name .. ".luau"
				else "src/ReplicatedStorage/Shared/" .. instance.Name .. ".luau"
			assert(instance.Source:gsub("\r\n", "\n") == fs.readFile(path):gsub("\r\n", "\n"), path)
			required[instance.Name] = true
		end
	end
end
assert(required.Garden.server and required.Garden.client and required.GardenScene and required.GardenRules and required.GardenLayout and required.Data and required.SessionRules)
local workspace = place:GetService("Workspace")
local map = place:GetService("ServerStorage"):FindFirstChild("GardenArtSource")
if map then
	assert(not workspace:FindFirstChild("PumpkinMap"), "Historical map exposed in garden Workspace")
	for _, item in workspace:GetDescendants() do
		assert(not item:IsA("SpawnLocation"), "Historical spawn exposed in editor")
	end
	print("Garden editor Workspace contains no historical map or spawns; reusable art is private in ServerStorage.")
else
	map = workspace:FindFirstChild("PumpkinMap")
end
assert(map, "Bundled map missing")
for _, instance in map:GetDescendants() do
	assert(not instance:IsA("LuaSourceContainer"), "Executable map art")
end
print("Packaged Garden server/client/Scene/Rules/Layout/Data/SessionRules source matches disk; total executable source files:", count)
print("Bundled map contains no LuaSourceContainers; runtime scene is created only when Studio runs.")
