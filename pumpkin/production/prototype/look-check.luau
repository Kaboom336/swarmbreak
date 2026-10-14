local fs, rb, luau, serde = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/serde")
local before = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.pre-look.rbxl"))
local after = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.rbxl"))
local preserved = 0
local function sources(old, new)
	if old:IsA("Lighting") then return end
	for _, child in old:GetChildren() do
		local actual = assert(new:FindFirstChild(child.Name), "Missing " .. child.Name)
		if child:IsA("LuaSourceContainer") and child == before.ReplicatedStorage.GreyboxScene then
			local guard = "\t-- The server-selected look owns lighting while the Studio A/B switch is active.\n\tif lighting:GetAttribute(\"AppliedLightingPreset\") then\n\t\treturn\n\tend\n"
			local edited = actual.Source:gsub("\r\n", "\n")
			local offset = assert(edited:find(guard, 1, true), "Missing client legacy-lighting guard")
			edited = edited:sub(1, offset-1) .. edited:sub(offset+#guard)
			assert(edited == child.Source:gsub("\r\n", "\n"), "Scene changed outside lighting guard")
		elseif child:IsA("LuaSourceContainer") and child ~= before.ReplicatedStorage.MeadowV4.Data then
			assert(child.Source == actual.Source, "Source changed " .. child:GetFullName())
			preserved += 1
		end
		sources(child, actual)
	end
end
sources(before, after)
assert(fs.readFile("prototype/guardian-greybox.rbxl") == fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"))
assert(after.ServerScriptService:GetAttribute("LightingPreset") == "GardenWarm")
assert(after.Lighting.Technology == rb.Enum.Technology.Future)
local presets = luau.load(after.ServerScriptService.LightingPresets.Source, {environment={Color3=rb.Color3, Instance=rb.Instance}})()
local retainedAtmosphere = after.Lighting.LookAtmosphere
for _, name in {"GardenWarm", "EggClear", "PetPop", "GardenWarm", "invalid"} do
	local selected = presets.apply(after.Lighting, name)
	assert(selected == (name == "invalid" and "GardenWarm" or name))
	local count = 0
	for _, child in after.Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("ColorCorrectionEffect") or child:IsA("BloomEffect") or child:IsA("SunRaysEffect") then count += 1 end
	end
	assert(count == 4, "A/B stacked effects")
	assert(after.Lighting.LookAtmosphere == retainedAtmosphere, "A/B replaced serialized effect")
	assert(after.Lighting:GetAttribute("AppliedLightingPreset") == selected)
end
for _, name in {"GreyboxLoopTest", "GreyboxPvpTest", "GreyboxTrapTest"} do
	assert(after.ServerScriptService:GetAttribute(name .. "Success") == before.ServerScriptService:GetAttribute(name .. "Success"))
	assert(after.ServerScriptService:GetAttribute(name .. "Result") == "NOT RUN")
end
for _, item in after:GetDescendants() do
	if item:IsA("LuaSourceContainer") then
		for optimization = 0,2 do luau.compile(item.Source, {optimizationLevel=optimization}) end
	end
end
local report = {state="PASS", preserved_source_containers=preserved, all_three_test_sources_and_expectations_equal=true, lighting_preset_switches=5, stacked_effect_errors=0, future_serialized=true, runtime="UNKNOWN"}
fs.writeFile("treasure/map-v4/LOOK-PRESERVATION.json", serde.encode("json", report, true))
print("PASS look source preservation and all three unchanged tests; five lighting switches, zero stacked effects")
