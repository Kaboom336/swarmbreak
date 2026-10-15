-- Source edits use apply_patch; this script writes only verified binary build artifacts.
local fs, rb, luau, process = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/process")
local main = "slice-v2/prototype/guardian-greybox.rbxl"
local backup = "slice-v2/prototype/guardian-greybox.pre-fix1.rbxl"
if process.args[1] == "backup" then
	assert(not fs.isFile(backup), "refusing to overwrite pre-fix1 backup")
	local bytes = fs.readFile(main)
	rb.deserializePlace(bytes)
	fs.writeFile(backup, bytes)
	assert(fs.readFile(backup) == bytes, "backup byte mismatch")
	print("PASS pre-fix1 backup byte verification")
	return
end
assert(fs.isFile(backup), "backup must exist before Rojo")
local place = rb.deserializePlace(fs.readFile(backup))
local built = rb.deserializePlace(fs.readFile("prototype/fix1-rojo.rbxl"))
local mounts = {
	{"ReplicatedStorage", "NativeBlocks"},
	{"ReplicatedStorage", "GreyboxConfig"},
	{"ReplicatedStorage", "MeadowKeeper", "Rig"},
	{"ReplicatedStorage", "MeadowV4", "Builder"},
	{"ReplicatedStorage", "MeadowV4", "Fix1Art"},
	{"StarterPlayer", "StarterPlayerScripts", "HomeArt"},
	{"StarterPlayer", "StarterPlayerScripts", "MeadowKeeper"},
}
local function at(root, path, last)
	for i = 1, last or #path do root = assert(root:FindFirstChild(path[i]), path[i]) end
	return root
end
for _, path in mounts do
	local parent = at(place,path,#path-1)
	local old = parent:FindFirstChild(path[#path])
	if old then old:Destroy() end
	at(built,path):Clone().Parent = parent
end
local old = rb.deserializePlace(fs.readFile(backup))
assert(rb.serializeModel(old.Workspace:GetChildren()) == rb.serializeModel(place.Workspace:GetChildren()), "Workspace changed")
assert(rb.serializeModel({old.Lighting}) == rb.serializeModel({place.Lighting}), "Lighting changed")
local allowed = {}
for _, path in mounts do allowed[table.concat(path,".")] = true end
local preserved, compiled = 0, 0
for _, node in place:GetDescendants() do
	if node:IsA("LuaSourceContainer") then
		for level = 0, 2 do luau.compile(node.Source,{optimizationLevel=level}) end
		compiled += 1
		if not allowed[node:GetFullName()] then
			local path = string.split(node:GetFullName(),".")
			assert(at(old,path).Source == node.Source,"unrelated source changed: " .. node:GetFullName())
			preserved += 1
		end
	end
end
local bytes = rb.serializePlace(place)
rb.deserializePlace(bytes)
fs.writeFile(main,bytes)
print(string.format("PASS seven mounts; %d unrelated sources preserved; %d Sources O0/O1/O2; Workspace/Lighting parity",preserved,compiled))
