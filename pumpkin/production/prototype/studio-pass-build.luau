-- Generated artifacts only; backup must complete before invoking Rojo.
local fs, rb, luau = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau")
local process = require("@lune/process")
local main, backup = "prototype/guardian-greybox.rbxl", "prototype/guardian-greybox.pre-studioprep.rbxl"
if process.args[1] == "backup" then
	assert(not fs.isFile(backup), "refusing to overwrite Studio-prep backup")
	local bytes = fs.readFile(main)
	rb.deserializePlace(bytes)
	fs.writeFile(backup, bytes)
	assert(fs.readFile(backup) == bytes, "backup byte mismatch")
	print("PASS backup verified; Rojo may now run")
	return
end
assert(fs.isFile(backup), "backup required before build")
local before = rb.deserializePlace(fs.readFile(backup))
local built = rb.deserializePlace(fs.readFile("prototype/studio-pass-rojo.rbxl"))
local mounts = {
	{ before.ServerScriptService, built.ServerScriptService, "Greybox" },
	{ before.ServerScriptService, built.ServerScriptService, "StudioPass" },
	{ before.ReplicatedStorage.MeadowV4, built.ReplicatedStorage.MeadowV4, "PolicyTests" },
	{ before.StarterPlayer.StarterPlayerScripts, built.StarterPlayer.StarterPlayerScripts, "StudioPass" },
}
for _, m in mounts do
	local old = m[1]:FindFirstChild(m[3])
	if old then
		old:Destroy()
	end
	m[2][m[3]]:Clone().Parent = m[1]
end
for _, name in { "StudioPassAll", "StudioPassSuccess", "StudioPassResult", "ShowDebug", "CaptureShots" } do
	before.ServerScriptService:SetAttribute(name, built.ServerScriptService:GetAttribute(name))
end
for _, node in before:GetDescendants() do
	if node:IsA("LuaSourceContainer") then
		for level = 0, 2 do
			luau.compile(node.Source, { optimizationLevel = level })
		end
	end
end
local bytes = rb.serializePlace(before)
rb.deserializePlace(bytes)
fs.writeFile(main, bytes)
fs.writeFile("slice-v2/prototype/guardian-greybox.rbxl", bytes)
print("PASS preserved scene, four reviewed mounts, every embedded script compiled O0/O1/O2")
