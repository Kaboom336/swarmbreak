local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local path='slice-v2/prototype/guardian-greybox.rbxl'
local bytes=fs.readFile(path)
local old=rb.deserializePlace(bytes)
local place=rb.deserializePlace(bytes)
local changed={}
for _,name in {'Section2','Section3'} do
 local node=place.ReplicatedStorage.MeadowV4[name]
 local source=fs.readFile('prototype/meadow-v4/'..name..'.luau')
 for opt=0,2 do luau.compile(source,{optimizationLevel=opt}) end
 if node.Source~=source then table.insert(changed,name) end
 node.Source=source
end
local function verify(a,b)
 assert(#a:GetDescendants()==#b:GetDescendants(),'instance count')
 for _,p in a:GetDescendants() do
  local q=b
  for _,n in string.split(p:GetFullName(),'.') do q=assert(q:FindFirstChild(n),n) end
  if p:IsA('LuaSourceContainer') and p.Name~='Section2' and p.Name~='Section3' then assert(p.Source==q.Source,p:GetFullName()) end
 end
 assert(rb.serializeModel({a.Workspace})==rb.serializeModel({b.Workspace}),'Workspace changed')
 -- Neutralize the two authorized properties and compare the complete place.
 local neutral=rb.deserializePlace(rb.serializePlace(b))
 for _,name in {'Section2','Section3'} do neutral.ReplicatedStorage.MeadowV4[name].Source=a.ReplicatedStorage.MeadowV4[name].Source end
 assert(rb.serializePlace(a)==rb.serializePlace(neutral),'other serialized property changed')
end
verify(old,place)
local backup='slice-v2/prototype/guardian-greybox.pre-s4r3-lightmount.rbxl'
assert(not fs.isFile(backup),'preserve existing lightmount backup')
fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
fs.writeFile(path,rb.serializePlace(place))
verify(old,rb.deserializePlace(fs.readFile(path)))
local start='slice-v2/prototype/guardian-greybox.pre-s4r3.rbxl'
assert(not fs.isFile(start),'preserve round-3 starting backup')
fs.writeFile(start,fs.readFile(path));assert(fs.readFile(start)==fs.readFile(path))
fs.writeFile('treasure/sections/S4/MOUNT-R3.json',serde.encode('json',{changed_sources=changed,only_two_source_properties_changed=true,workspace_exact=true,backup=start},true))
print('PASS canonical source-only S2/S3 mount; complete neutralized place parity; byte-verified R3 starting backup')
