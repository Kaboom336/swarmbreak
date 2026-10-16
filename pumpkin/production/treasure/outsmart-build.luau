local fs,rb,luau,process,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/process"),require("@lune/serde")
local main="slice-v2/prototype/guardian-greybox.rbxl"
local backup="slice-v2/prototype/guardian-greybox.pre-outsmart.rbxl"
if process.args[1]=="backup" then
	assert(not fs.isFile(backup),"refusing to overwrite pre-outsmart backup")
	local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes)
	assert(fs.readFile(backup)==bytes,"backup byte mismatch")
	print("PASS byte-verified backup before Rojo");return
end
assert(fs.isFile(backup),"backup required BEFORE Rojo")
local before=rb.deserializePlace(fs.readFile(backup))
local place=rb.deserializePlace(fs.readFile(backup))
local built=rb.deserializePlace(fs.readFile("treasure/outsmart-rojo.rbxl"))
local function at(root,path,n) for i=1,n or #path do root=assert(root:FindFirstChild(path[i]),path[i]) end;return root end
local allowed={}
for _,path in {
	{"ReplicatedStorage","MeadowV4","Outsmart"},{"ReplicatedStorage","MeadowV4","Builder"},
	{"ReplicatedStorage","MeadowKeeper","Attacks"},{"ReplicatedStorage","MeadowKeeper","Effects"},
	{"ReplicatedStorage","GreyboxTraps"},{"ServerScriptService","GreyboxArena"},
	{"ServerScriptService","Greybox"},{"ServerScriptService","StudioPass"},{"ServerScriptService","OutsmartTestRunner"},
	{"StarterPlayer","StarterPlayerScripts","MeadowKeeper"},
} do
	local parent=at(place,path,#path-1);local old=parent:FindFirstChild(path[#path]);if old then old:Destroy() end
	at(built,path):Clone().Parent=parent;allowed[table.concat(path,".")]=true
end
for name,value in {OutsmartTest=false,OutsmartTestSuccess=false,OutsmartTestResult="NOT RUN",OutsmartTestFailureJSON="{}"} do place.ServerScriptService:SetAttribute(name,value) end
assert(rb.serializeModel({before.Workspace})==rb.serializeModel({place.Workspace}),"serialized Workspace changed")
local count,preserved=0,0
for _,p in place:GetDescendants() do if p:IsA("LuaSourceContainer") then
	for opt=0,2 do luau.compile(p.Source,{optimizationLevel=opt}) end;count+=1
	if not allowed[p:GetFullName()] then assert(p.Source==at(before,string.split(p:GetFullName(),".")).Source,"unrelated source changed: "..p:GetFullName());preserved+=1 end
end end
for _,name in {"GreyboxLoopTestRunner","DropSampleTestRunner","GreyboxTrapTestRunner","CoreLoopTestRunner"} do
	assert(place.ServerScriptService[name].Source==before.ServerScriptService[name].Source,"legacy suite changed")
end
local bytes=rb.serializePlace(place);rb.deserializePlace(bytes);fs.writeFile(main,bytes)
fs.writeFile("treasure/OUTSMART-OFFLINE.json",serde.encode("json",{compiled=count,preserved=preserved,workspaceParity=true,backupBytes=#fs.readFile(backup),placeBytes=#bytes,studio="UNKNOWN"},true))
print("PASS build: "..count.." scripts O0/O1/O2; "..preserved.." unrelated sources preserved; Workspace parity")
