-- Patch source mounts into the LATEST binaries. Never regenerate CONNECT geometry.
local fs,rb,luau=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau")
local args=require("@lune/process").args
local files={"prototype/guardian-greybox.rbxl","slice-v2/prototype/guardian-greybox.rbxl",
	"prototype/meadow-v4.rbxl","prototype/cave-v2.rbxl","prototype/core-rojo.rbxl"}
if args[1]=="backup" then
	for _,path in files do
		local backup=path:gsub("%.rbxl$",".pre-kits.rbxl")
		assert(not fs.isFile(backup),"refusing to overwrite "..backup)
		local bytes=fs.readFile(path);rb.deserializePlace(bytes)
		fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
	end
	print("PASS backups byte-identical, deserialize OK")
	return
end
local built=rb.deserializePlace(fs.readFile("prototype/core-rojo.rbxl"))
local function ensure(parent,name,class)
	local node=parent:FindFirstChild(name)
	if not node then node=rb.Instance.new(class);node.Name=name;node.Parent=parent end
	return node
end
for _,path in files do
	if path=="prototype/core-rojo.rbxl" then continue end
	local place=rb.deserializePlace(fs.readFile(path))
	local rep=ensure(place,"ReplicatedStorage","ReplicatedStorage")
	local core=rep:FindFirstChild("TreasureCore")
	if core then core:Destroy() end
	built.ReplicatedStorage.TreasureCore:Clone().Parent=rep
	local sp=ensure(place,"StarterPlayer","StarterPlayer")
	local clients=ensure(sp,"StarterPlayerScripts","StarterPlayerScripts")
	local feel=clients:FindFirstChild("TreasureFeel")
	if feel then feel:Destroy() end
	built.StarterPlayer.StarterPlayerScripts.TreasureFeel:Clone().Parent=clients
	local hud=clients:FindFirstChild("TreasureCoreHud")
	if hud then hud.Source=fs.readFile("prototype/core/Hud.client.luau") end
	local runner=place.ServerScriptService:FindFirstChild("CoreLoopTestRunner")
	if runner then runner.Source=fs.readFile("prototype/core/Test.server.luau") end
	for _,node in place:GetDescendants() do if node:IsA("LuaSourceContainer") then luau.compile(node.Source) end end
	local bytes=rb.serializePlace(place);rb.deserializePlace(bytes);fs.writeFile(path,bytes)
	print("PASS compiled source mount: "..path)
end
