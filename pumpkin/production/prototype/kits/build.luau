-- Mount source into latest places, preserving Workspace byte-for-property.
-- No Rojo regeneration is needed. Existing pre-kits backups are never overwritten.
local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local catalog=serde.decode('json',fs.readFile('assets/kits/ROBLOX-ASSETS.json'))
local exports=serde.decode('json',fs.readFile('assets/kits/manifest.json')).exports
assert(#catalog>0,'empty manifest')
if #catalog~=72 then print('NOTICE owner reported 72; checked manifest contains '..#catalog..' entries') end
local seen={}
for _,e in catalog do
 local key=e.island..'__'..e.name;assert(not seen[key],'duplicate template');seen[key]=true
 for _,x in exports do if x.island==e.island and x.pack..'__'..x.name==e.name then
  e.triangles=0;for _,m in x.meshes do e.triangles+=m.triangles end
 end end
 assert(e.triangles,'missing triangle provenance '..key)
end
local rojoManifest=serde.decode('json',fs.readFile('prototype/kits/Manifest.model.json'))
local encoded=serde.decode('json',rojoManifest.Properties.Value)
assert(#encoded==#catalog,'Rojo manifest stale')
for i,e in catalog do assert(encoded[i].id==e.id and encoded[i].name==e.name and encoded[i].island==e.island and encoded[i].triangles==e.triangles,'Rojo manifest differs') end
local function ensure(parent,name,class)
 local n=parent:FindFirstChild(name)
 if not n then n=rb.Instance.new(class);n.Name=name;n.Parent=parent end
 return n
end
for _,path in {'prototype/guardian-greybox.rbxl','slice-v2/prototype/guardian-greybox.rbxl','prototype/meadow-v4.rbxl','prototype/cave-v2.rbxl'} do
 local bytes=fs.readFile(path);local place=rb.deserializePlace(bytes)
 local backup=path:gsub('%.rbxl$','.pre-kits.rbxl')
 if not fs.isFile(backup) then fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes) end
 -- This run's exact baseline also covers intervening source-only mounts.
 local baseline=path:gsub('%.rbxl$','.kit-runtime-baseline.rbxl')
 if not fs.isFile(baseline) then fs.writeFile(baseline,bytes) end
 local server=ensure(place,'ServerScriptService','ServerScriptService')
 for _,item in {{'KitLibrary','ModuleScript','KitLibrary.luau'},{'KitPlan','ModuleScript','Plan.luau'},{'KitSwap','Script','Swap.server.luau'}} do
  local n=ensure(server,item[1],item[2]);n.Source=fs.readFile('prototype/kits/'..item[3]);luau.compile(n.Source)
  if item[1]=='KitLibrary' then ensure(n,'Manifest','StringValue').Value=serde.encode('json',catalog) end
 end
 local out=rb.serializePlace(place);rb.deserializePlace(out);fs.writeFile(path,out)
 print('PASS kit source mounted '..path)
end
