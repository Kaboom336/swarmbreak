local fs, rb, luau, process = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/process")
local main = "slice-v2/prototype/guardian-greybox.rbxl"
local backup = "slice-v2/prototype/guardian-greybox.pre-fix4.rbxl"
if process.args[1] == "backup" then
	assert(not fs.isFile(backup), "refusing to overwrite pre-fix4")
	local bytes = fs.readFile(main)
	rb.deserializePlace(bytes)
	fs.writeFile(backup, bytes)
	assert(fs.readFile(backup) == bytes, "backup byte mismatch")
	print("PASS pre-fix4 byte-verified backup")
	return
end
assert(fs.isFile(backup), "backup required before Rojo")
local old = rb.deserializePlace(fs.readFile(backup))
local current = rb.deserializePlace(fs.readFile(main))
local place = rb.deserializePlace(fs.readFile(backup))
local built = rb.deserializePlace(fs.readFile("prototype/fix4-rojo.rbxl"))
local mounts = {
	{ "ReplicatedStorage", "MeadowV4", "ReachableDrops" },
	{ "ServerScriptService", "GreyboxArena" },
	{ "ServerScriptService", "Greybox" },
}
local function at(root, path, last)
	for i = 1, last or #path do root = assert(root:FindFirstChild(path[i]), path[i]) end
	return root
end
local allowed = {}
for _, path in mounts do
	local parent = at(place, path, #path - 1)
	at(place, path):Destroy()
	at(built, path):Clone().Parent = parent
	allowed[table.concat(path, ".")] = true
end
assert(rb.serializeModel(old.Workspace:GetChildren()) == rb.serializeModel(place.Workspace:GetChildren()), "Workspace changed")
assert(rb.serializeModel({ old.Lighting }) == rb.serializeModel({ place.Lighting }), "Lighting changed")
assert(rb.serializeModel(old.Workspace:GetChildren()) == rb.serializeModel(current.Workspace:GetChildren()), "target scene changed since backup")
assert(rb.serializeModel({old.Lighting}) == rb.serializeModel({current.Lighting}), "target lighting changed since backup")
local preserved, compiled = 0, 0
for _, node in place:GetDescendants() do
	if node:IsA("LuaSourceContainer") then
		for level = 0, 2 do luau.compile(node.Source, { optimizationLevel = level }) end
		compiled += 1
		if not allowed[node:GetFullName()] then
			assert(at(old, string.split(node:GetFullName(), ".")).Source == node.Source, "unrelated source changed " .. node:GetFullName())
			assert(at(current, string.split(node:GetFullName(), ".")).Source == node.Source, "target unrelated source changed " .. node:GetFullName())
			preserved += 1
		end
	end
end
local bytes = rb.serializePlace(place)
rb.deserializePlace(bytes)
fs.writeFile(main, bytes)
print(string.format("PASS three mounts; %d preserved sources; %d compiled O0/O1/O2; scene parity", preserved, compiled))
