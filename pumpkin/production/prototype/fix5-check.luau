local fs, rb, luau = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau")
local place = rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"))
local cache = {}
local function load(node)
	if cache[node] then return cache[node] end
	cache[node] = luau.load(node.Source, {environment = {
		script = node, require = load, Vector3 = rb.Vector3, CFrame = rb.CFrame,
		Color3 = rb.Color3, Enum = rb.Enum, Instance = rb.Instance,
	}})()
	return cache[node]
end
local folder = place.ReplicatedStorage.MeadowV4
local D, routes = load(folder.ReachableDrops), load(folder.RouteData)
for _, prefix in {"Fix2Lane_", "Fix2Junction_"} do
	for _, category in {"rock", "fence", "edging", "prop", "bridge_structure"} do
		assert(not D.isLane({name=prefix .. "spiral_21", category=category, collidable=true}, routes), "forged prop accepted")
	end
	assert(not D.isLane({name=prefix .. "spiral_21_Edging", category="lane", collidable=true}, routes), "edging suffix accepted")
end
local model = load(folder.Builder).build(rb.Instance.new("Folder"), rb.Vector3.zero)
local count = 0
for _, p in model:GetDescendants() do
	if p:HasTag("AuthoredLaneFloor") then
		assert(p.Parent == model and p:GetAttribute("WalkableLaneFloor") == true and p:GetAttribute("LaneId"), "builder tag contract")
		count += 1
	end
end
assert(count > 0, "no authored lane floors")
for path, file in {
	["ReplicatedStorage.MeadowV4.Builder"]="prototype/meadow-v4/MeadowV4.luau",
	["ReplicatedStorage.MeadowV4.ReachableDrops"]="prototype/meadow-v4/ReachableDrops.luau",
	["ServerScriptService.GreyboxArena"]="slice-v2/prototype/Arena.luau",
	["ServerScriptService.Greybox"]="slice-v2/prototype/Greybox.server.luau",
	["ServerScriptService.GreyboxLoopTestRunner"]="slice-v2/prototype/LoopTest.luau",
	["ServerScriptService.StudioPass"]="slice-v2/prototype/StudioPass.luau",
	["ServerScriptService.KitLibrary"]="prototype/kits/KitLibrary.luau",
	["ServerScriptService.DropSampleTestRunner"]="slice-v2/prototype/DropSampleTest.luau",
} do
	local node = place
	for _, name in string.split(path, ".") do node = assert(node:FindFirstChild(name)) end
	assert(node.Source:gsub("\r\n", "\n") == fs.readFile(file):gsub("\r\n", "\n"), "source parity " .. path)
end
print("PASS builder floor tags/IDs", count, "forged props rejected; eight mounted sources match; live drops NOT RUN")
