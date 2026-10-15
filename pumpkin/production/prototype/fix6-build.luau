-- Source edits use apply_patch; backups and compiled places are generated outputs.
local fs, rb, luau, process = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/process")
local main = "slice-v2/prototype/guardian-greybox.rbxl"
local backup = "slice-v2/prototype/guardian-greybox.pre-fix6.rbxl"
if process.args[1] == "backup" then
 assert(not fs.isFile(backup), "refusing to overwrite pre-fix6")
 local bytes=fs.readFile(main); rb.deserializePlace(bytes); fs.writeFile(backup,bytes)
 assert(fs.readFile(backup)==bytes,"backup mismatch"); print("PASS pre-fix6 byte-verified backup"); return
end
assert(fs.isFile(backup),"backup required before Rojo")
local old=rb.deserializePlace(fs.readFile(backup))
local place=rb.deserializePlace(fs.readFile(backup))
local built=rb.deserializePlace(fs.readFile("prototype/fix6-rojo.rbxl"))
local mounts={
 {"ReplicatedStorage","MeadowV4","ReachableDrops"},
 {"ServerScriptService","GreyboxArena"}, {"ServerScriptService","Greybox"},
 {"ServerScriptService","GreyboxLoopTestRunner"}, {"ServerScriptService","DropSampleTestRunner"},
 {"ServerScriptService","KitLibrary"}, {"ServerScriptService","KitPlan"}, {"ServerScriptService","KitSwap"},
}
local function at(root,path,last)
 for i=1,last or #path do root=assert(root:FindFirstChild(path[i]),path[i]) end
 return root
end
local allowed={}
for _,path in mounts do
 local parent=at(place,path,#path-1);local existing=parent:FindFirstChild(path[#path])
 if existing then existing:Destroy() end
 at(built,path):Clone().Parent=parent;allowed[table.concat(path,".")]=true
end
for _,name in {"Workspace","Lighting"} do
 assert(rb.serializeModel({old[name]})==rb.serializeModel({place[name]}),name.." changed")
end
local preserved,compiled=0,0
for _,node in place:GetDescendants() do if node:IsA("LuaSourceContainer") then
 for level=0,2 do luau.compile(node.Source,{optimizationLevel=level}) end
 compiled+=1
 if not allowed[node:GetFullName()] then
  assert(at(old,string.split(node:GetFullName(),".")).Source==node.Source,"unrelated source changed")
  preserved+=1
 end
end end
place.ServerScriptService:SetAttribute("DropSampleTest",false)
place.ServerScriptService:SetAttribute("DropSampleTestSuccess",false)
place.ServerScriptService:SetAttribute("DropSampleTestResult","NOT RUN")
place.ServerScriptService:SetAttribute("DropSampleTestFailures","[]")
place.ServerScriptService:SetAttribute("DropSampleTestFailureCount",0)
place.ServerScriptService:SetAttribute("GreyboxLoopTestLastDrop","{}")
local bytes=rb.serializePlace(place);rb.deserializePlace(bytes);fs.writeFile(main,bytes)
print("PASS eight mounts (including kits2 Manifest); preserved",preserved,"compiled O0/O1/O2",compiled,"scene parity")
