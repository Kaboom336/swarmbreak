local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local backup='slice-v2/prototype/guardian-greybox.pre-fix11.rbxl'
assert(fs.isFile(backup),'backup required before Rojo')
local before=rb.deserializePlace(fs.readFile(backup))
local place=rb.deserializePlace(fs.readFile(backup))
local built=rb.deserializePlace(fs.readFile('treasure/fix11-rojo.rbxl'))
local function at(root,path) for _,k in string.split(path,'.') do root=assert(root:FindFirstChild(k),path) end;return root end
local allowed={}
for _,path in {'ServerScriptService.OutsmartTestRunner','ServerScriptService.Greybox','ServerScriptService.GreyboxArena','ReplicatedStorage.MeadowV4.Outsmart','ReplicatedStorage.MeadowV4.Section1'} do
 at(place,path).Source=at(built,path).Source;allowed[path]=true
end
local count,preserved=0,0
for _,node in place:GetDescendants() do if node:IsA('LuaSourceContainer') then
 for opt=0,2 do luau.compile(node.Source,{optimizationLevel=opt}) end;count+=1
 if not allowed[node:GetFullName()] then assert(node.Source==at(before,node:GetFullName()).Source,'unrelated source changed');preserved+=1 end
end end
assert(rb.serializeModel({before.Workspace})==rb.serializeModel({place.Workspace}),'Workspace changed')
local bytes=rb.serializePlace(place);rb.deserializePlace(bytes);fs.writeFile('slice-v2/prototype/guardian-greybox.rbxl',bytes)
fs.writeFile('treasure/FIX11-BUILD.json',serde.encode('json',{compiled_O0_O1_O2=count,unrelated_sources_preserved=preserved,workspace_parity=true,live='UNKNOWN; restart Play and rerun suites'},true))
print('PASS fix11 build',count,'scripts O0/O1/O2;',preserved,'unrelated sources preserved; Workspace parity')
