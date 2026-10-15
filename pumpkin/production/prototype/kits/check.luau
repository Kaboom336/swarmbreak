local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V,C=rb.Vector3,rb.CFrame
local Plan=luau.load(fs.readFile('prototype/kits/Plan.luau'),{environment={Vector3=V,CFrame=C}})()
local report={status='PASS',catalogEntries=71,ownerReportedEntries=72,runtime='UNKNOWN: Studio not run',memoryMb='UNKNOWN: emitted by runtime Stats after load/swap',places={}}
local function buildMeadow(place)
 local cache={}
 local function load(n)
  if cache[n] then return cache[n] end
  cache[n]=luau.load(n.Source,{environment={script=n,require=load,Vector3=V,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance}})();return cache[n]
 end
 return load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new('Folder'),V.zero)
end
for _,path in {'prototype/guardian-greybox.rbxl','prototype/meadow-v4.rbxl','prototype/cave-v2.rbxl'} do
 local before=rb.deserializePlace(fs.readFile(path:gsub('%.rbxl$','.kit-runtime-baseline.rbxl')))
 local after=rb.deserializePlace(fs.readFile(path))
 local a,b=before.Workspace:GetDescendants(),after.Workspace:GetDescendants()
 assert(#a==#b,'saved workspace count changed')
 for i,n in a do
  assert(n.Name==b[i].Name and n.ClassName==b[i].ClassName,'saved hierarchy changed')
  if n:IsA('BasePart') then for _,prop in {'CFrame','Size','CanCollide','CanQuery','CanTouch','Transparency','Anchored'} do assert(n[prop]==b[i][prop],'saved collision/geometry changed') end end
 end
 for _,n in before:GetDescendants() do if n:IsA('LuaSourceContainer') then
  local function walk(old,new)
   local buckets,seen={},{}
   for _,v in new:GetChildren() do buckets[v.Name]=buckets[v.Name] or {};table.insert(buckets[v.Name],v) end
   for _,child in old:GetChildren() do
    local candidates=buckets[child.Name] or {}
    seen[child.Name]=(seen[child.Name] or 0)+1
    assert(#candidates>0,'missing source parent')
    local target=assert(candidates[seen[child.Name]])
    if child:IsA('LuaSourceContainer') then assert(child.Source==target.Source,'unrelated script changed') end
    if not child:IsA('BasePart') then walk(child,target) end
   end
  end
  walk(before,after);break
 end end
 for _,n in after:GetDescendants() do if n:IsA('LuaSourceContainer') then luau.compile(n.Source) end end
 local island=if path:find('cave') then 'cave' else 'meadow'
 local root=if island=='meadow' and path:find('guardian') then buildMeadow(after) else after.Workspace:FindFirstChild(if island=='cave' then 'CaveV2' else 'MeadowV4',true)
 assert(root,'missing kit target')
 local manifest=serde.decode('json',after.ServerScriptService.KitLibrary.Manifest.Value)
 local catalog={};for _,m in manifest do catalog[m.island..'__'..m.name]=m end
 local groups=Plan.groups(root,island)
 local claimed,types={},{}
 local triangles,meshes,hidden,projectedInstances,extraTriangles,extras,treeFallbacks=0,0,0,0,0,0,0
 local function predict(name)
  local m=assert(catalog[island..'__'..name]);extras+=1;extraTriangles+=m.triangles;projectedInstances+=1+m.meshParts
 end
 local fenceEnds={}
 for index,g in groups do
  local m=assert(catalog[island..'__'..g.name],'bad assignment '..g.name)
  assert(g.size.X>0 and g.size.Y>0 and g.size.Z>0,'bad bounds')
  assert(not g.anchor.Name:find('Connect'),'CONNECT infrastructure selected')
  for _,p in g.parts do assert(not claimed[p],'assembly member used twice');claimed[p]=true;hidden+=1 end
  types[g.name]=(types[g.name] or 0)+1;triangles+=m.triangles;meshes+=m.meshParts
  local fits=g.keepReason==nil
  if g.tree then
   local scale=g.size.Y/m.size[2]
   assert(scale>0,'tree target height')
   projectedInstances+=1 -- merged trunk proxy; disabled in the swap
  end
  if fits then projectedInstances+=1+m.meshParts else triangles-=m.triangles;meshes-=m.meshParts end
  if island=='meadow' and g.anchor.Name:find('Bush') and index%4==0 then
   for _,name in {'quaternius-nature__Pebble_Round_1','kenney_nature-kit__log','kenney_nature-kit__stump_round'} do predict(name) end
  end
  if g.fence then
   assert(#g.parts==2,'not a whole fence bay')
   for _,v in g.ends do local k=string.format('%.3f:%.3f:%.3f',v.X,v.Y,v.Z);fenceEnds[k]=(fenceEnds[k] or 0)+1 end
   assert((g.base:PointToWorldSpace(V.new(-(g.size.X+g.posts[1].Size.X)/2,0,0))-g.ends[1]).Magnitude<0.001,'fence start mismatch')
   assert((g.base:PointToWorldSpace(V.new((g.size.X+g.posts[1].Size.X)/2,0,0))-g.ends[2]).Magnitude<0.001,'fence end mismatch')
  end
 end
 local unmatched=0
 for _,count in fenceEnds do if count~=1 and count~=2 then unmatched+=1 end end
 assert(unmatched==0,'fence topology mismatch')
 if island=='cave' then for _=1,3 do predict('quaternius-nature__Mushroom_Common') end end
 local nativeProxy,curved=0,0
 for _,p in root:GetDescendants() do if p:IsA('BasePart') and p.Transparency<1 then
  if p:IsA('WedgePart') then nativeProxy+=8
  elseif p:IsA('Part') and p.Shape==rb.Enum.PartType.Block then nativeProxy+=12
  else curved+=1 end
 end end
 local instances=#root:GetDescendants()
 table.insert(report.places,{path=path,island=island,savedWorkspaceInstancesBefore=#a,savedWorkspaceInstancesAfter=#b,
  propGroups=#groups,hiddenOriginalParts=hidden,assignedMeshes=meshes,assignedSourceTriangles=triangles,
  runtimeInstancesBefore=instances,runtimeInstancesAfterProjectedMinimum=instances+1+projectedInstances,
  projectedExtras=extras,treeFootprintFallbacksProjected=treeFallbacks,projectedKitSourceTriangles=triangles+extraTriangles,
  nativePrimitiveTriangleProxyBefore=nativeProxy,unknownCurvedOrMeshPartsBefore=curved,
  trianglesBefore='UNKNOWN: native primitive tessellation is engine-dependent',trianglesAfter='source triangle count only; retained terrain not included',
  fenceEndpointMismatches=unmatched,assignments=types})
end
local mirror=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local main=rb.deserializePlace(fs.readFile('prototype/guardian-greybox.rbxl'))
for _,name in {'KitLibrary','KitPlan','KitSwap'} do assert(mirror.ServerScriptService[name].Source==main.ServerScriptService[name].Source,'kit mount parity') end
local rojo=rb.deserializePlace(fs.readFile('prototype/kit-source-rojo.rbxl'))
for _,name in {'KitLibrary','KitPlan','KitSwap'} do assert(rojo.ServerScriptService[name].Source==main.ServerScriptService[name].Source,'stale Rojo kit source') end
assert(#serde.decode('json',rojo.ServerScriptService.KitLibrary.Manifest.Value)==71,'Rojo manifest child missing')
fs.writeFile('prototype/KIT-RUNTIME-OFFLINE.json',serde.encode('json',report,true))
print('PASS compiled mounts, preserved geometry/scripts, assembly uniqueness, catalog coverage, fence endpoints, kit mount parity')
