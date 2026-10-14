-- Generated rbxl: keep the exact main-place hierarchy/properties; mount reviewed scripts only.
local fs, rb, luau = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau")
local before = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.pre-core.rbxl"))
local built = rb.deserializePlace(fs.readFile("prototype/core-rojo.rbxl"))
local edits = {
	{ "ReplicatedStorage", "GreyboxLootRules" },
	{ "ServerScriptService", "Greybox" },
	{ "StarterPlayer.StarterPlayerScripts", "HomeArt" },
}
local function find(place, path)
	local node = place
	for name in path:gmatch("[^.]+") do
		node = node[name]
	end
	return node
end
for _, pair in edits do
	local target = find(before, pair[1])[pair[2]]
	target.Source = find(built, pair[1])[pair[2]].Source
end
for _, pair in
	{
		{ "ReplicatedStorage", "TreasureCore" },
		{ "ServerScriptService", "CoreLoopTestRunner" },
		{ "StarterPlayer.StarterPlayerScripts", "TreasureCoreHud" },
	}
do
	assert(not find(before, pair[1]):FindFirstChild(pair[2]), "duplicate core mount")
	find(built, pair[1])[pair[2]]:Clone().Parent = find(before, pair[1])
end
for _, name in
	{
		"CoreLoopTest",
		"CoreLoopTestSuccess",
		"CoreLoopTestResult",
		"CoreUseDataStore",
		"CoreRequireLegacyGates",
	}
do
	before.ServerScriptService:SetAttribute(name, built.ServerScriptService:GetAttribute(name))
end
for _, node in before:GetDescendants() do
	if node:IsA("LuaSourceContainer") then
		luau.compile(node.Source)
	end
end
local bytes = rb.serializePlace(before)
fs.writeFile("prototype/guardian-greybox.rbxl", bytes)
fs.writeFile("slice-v2/prototype/guardian-greybox.rbxl", bytes)
rb.deserializePlace(bytes)
print(
	"PASS source mounts, preserved main hierarchy, compiled every embedded script, binary deserialize"
)
