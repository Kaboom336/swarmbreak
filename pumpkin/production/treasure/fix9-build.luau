local fs,rb,luau,process,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/process'),require('@lune/serde')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-fix9.rbxl'
if process.args[1]=='backup' then
 assert(not fs.isFile(backup),'preserve existing backup')
 local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes)
 assert(fs.readFile(backup)==bytes);print('PASS byte-verified pre-fix9 backup before Rojo');return
end
assert(fs.isFile(backup),'backup required before Rojo')
local before=rb.deserializePlace(fs.readFile(backup))
local place=rb.deserializePlace(fs.readFile(backup))
local built=rb.deserializePlace(fs.readFile('treasure/fix9-rojo.rbxl'))
local function at(root,path) for _,k in string.split(path,'.') do root=assert(root:FindFirstChild(k),path) end;return root end
local allowed={}
for _,path in {'ServerScriptService.GreyboxLoopTestRunner','ReplicatedStorage.MeadowV4.Section1','ReplicatedStorage.MeadowV4.Builder','ServerScriptService.KitSwap'} do
 at(place,path).Source=at(built,path).Source;allowed[path]=true
end
local count,preserved=0,0
for _,node in place:GetDescendants() do if node:IsA('LuaSourceContainer') then
 for opt=0,2 do luau.compile(node.Source,{optimizationLevel=opt}) end;count+=1
 if not allowed[node:GetFullName()] then assert(node.Source==at(before,node:GetFullName()).Source,'unrelated source changed');preserved+=1 end
end end
assert(rb.serializeModel({before.Workspace})==rb.serializeModel({place.Workspace}),'Workspace changed')
local bytes=rb.serializePlace(place);rb.deserializePlace(bytes);fs.writeFile(main,bytes)
fs.writeFile('treasure/FIX9-BUILD.json',serde.encode('json',{compiled_O0_O1_O2=count,unrelated_sources_preserved=preserved,workspace_parity=true,StudioPassAll='UNKNOWN; rerun live'},true))
print('PASS fix9 build',count,'scripts O0/O1/O2;',preserved,'unrelated sources preserved; Workspace parity')
