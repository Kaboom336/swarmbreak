-- Actual KitLibrary.init on explicit offline import/bounds/scale adapters.
-- Import latency and actual Roblox mesh hierarchy remain UNKNOWN.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local pre=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-yield.rbxl'))
local place=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local entries=serde.decode('json',place.ServerScriptService.KitLibrary.Manifest.Value)
local byId={};local meshCount=0
for _,e in entries do byId[e.id]=e;meshCount+=e.meshParts end
local function run(source,enabled)
 local storage=rb.Instance.new('Folder');local loads,yields=0,0;local importTimes={}
 local services={ServerStorage=storage,Stats={GetTotalMemoryUsageMb=function()return 0 end},HttpService={JSONDecode=function(_,s)return serde.decode('json',s)end},CollectionService={RemoveTag=function(_,n,t)n:RemoveTag(t)end,AddTag=function(_,n,t)n:AddTag(t)end}}
 services.InsertService={LoadAsset=function(_,id)
  local start=os.clock();loads+=1;local e=assert(byId[id]);local m=rb.Instance.new('Model');local size=rb.Vector3.new(unpack(e.size));m:SetAttribute('OfflineBounds',size)
  for i=1,e.meshParts do local p=rb.Instance.new('MeshPart');p.TextureID='';p.Name=e.name..'__'..e.island..'_wood';p.Size=size;p.CFrame=rb.CFrame.new(0,size.Y/2,0);p.Parent=m end
  -- Exercise the production script sanitization branch too.
  local s=rb.Instance.new('Script');s.Parent=m
  table.insert(importTimes,os.clock()-start);return m
 end}
 source=source:gsub('model:GetBoundingBox%(%)','mockBounds(model)'):gsub('model:GetScale%(%)','1'):gsub('model.PrimaryPart = nil','-- Proxy starts without a PrimaryPart; Lune cannot assign nil Ref.')
 local env={script=place.ServerScriptService.KitLibrary,Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,warn=function(...)error('unexpected KitLibrary warning '..tostring(...))end,print=function()end,
  task=if enabled then {wait=function()yields+=1 end} else nil,
  mockBounds=function(m)local size=m:GetAttribute('OfflineBounds');return rb.CFrame.new(0,size.Y/2,0),size end,
  game={GetService=function(_,name)return assert(services[name],name)end}}
 local kit=luau.load(source,{environment=env})();local start=os.clock();kit.init();local elapsed=os.clock()-start
 assert(kit.loaded==74 and loads==74 and next(kit.failures)==nil,'kit import/sanitize contract')
 for _,m in kit.templates do for _,n in m:GetDescendants() do assert(not n:IsA('LuaSourceContainer'),'script survived');if n:IsA('BasePart') then assert(n.Anchored and not n.CanCollide and not n.CanQuery and not n.CanTouch,'unsafe kit flags') end end end
 local longest=0;for _,t in importTimes do longest=math.max(longest,t)end
 return rb.serializeModel({storage}),{init_seconds=elapsed,proxy_import_max_seconds=longest,assets=loads,mesh_parts=meshCount,retained_proxy_instances=#storage:GetDescendants()+1,yield_calls=yields,import_latency='UNKNOWN; local manifest-sized proxy',bounds_and_scale='offline adapters; production code otherwise unchanged'}
end
local before=run(pre.ServerScriptService.KitLibrary.Source,false)
local after,report=run(place.ServerScriptService.KitLibrary.Source,true)
assert(before==after,'KitLibrary template instance/attribute/transform/sanitization signature changed')
report.template_signature_exact=true
fs.writeFile('prototype/yield-evidence/KIT.json',serde.encode('json',report,true));print('PASS actual KitLibrary.init; 74 proxy assets / 117 mesh parts; exact sanitized templates; network import UNKNOWN')
