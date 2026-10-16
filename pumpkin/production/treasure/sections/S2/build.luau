local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/sections/S2/'
local r3=string.find(process.args[1] or '', 'r3')~=nil
local r2=r3 or string.find(process.args[1] or '', 'r2')~=nil
local mode=(process.args[1] or ''):gsub('r[23]%-','')
if r3 then H..='r3-' elseif r2 then H..='r2-' end
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup=if r3 then 'slice-v2/prototype/guardian-greybox.pre-s2r3.rbxl' elseif r2 then 'slice-v2/prototype/guardian-greybox.pre-s2r2.rbxl' else 'slice-v2/prototype/guardian-greybox.pre-s2.rbxl'
if mode=='backup' then
 assert(not fs.isFile(backup),'preserve backup');local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes);print('PASS byte-verified backup before Rojo');return
end
assert(fs.isFile(backup),'backup first')
local old=rb.deserializePlace(fs.readFile(backup));local place=rb.deserializePlace(fs.readFile(backup))
local allowed={['ReplicatedStorage.MeadowV4.Section2']=true,['ServerScriptService.KitSwap']=true,['ReplicatedStorage.MeadowV4.Outsmart']=true}
if r2 then allowed={['ReplicatedStorage.MeadowV4.Section2']=true} end
if fs.isFile('prototype/meadow-v4/Section2.luau') then
 local s=place.ReplicatedStorage.MeadowV4:FindFirstChild('Section2') or rb.Instance.new('ModuleScript');s.Name='Section2';s.Source=fs.readFile('prototype/meadow-v4/Section2.luau');s.Parent=place.ReplicatedStorage.MeadowV4
 place.ServerScriptService.KitSwap.Source=fs.readFile('prototype/kits/Swap.server.luau')
 place.ReplicatedStorage.MeadowV4.Outsmart.Source=fs.readFile('prototype/meadow-v4/Outsmart.luau')
end
if mode=='deliver' then
 local rojo=rb.deserializePlace(fs.readFile(H..'rojo.rbxl'))
 assert(rojo.ReplicatedStorage.MeadowV4.Section2.Source==place.ReplicatedStorage.MeadowV4.Section2.Source,'Rojo Section2 differs')
 assert(rojo.ServerScriptService.KitSwap.Source==place.ServerScriptService.KitSwap.Source,'Rojo KitSwap differs')
 assert(rojo.ReplicatedStorage.MeadowV4.Outsmart.Source==place.ReplicatedStorage.MeadowV4.Outsmart.Source,'Rojo Outsmart differs')
end
local compiled,preserved=0,0
for _,p in place:GetDescendants() do if p:IsA('LuaSourceContainer') then
 for opt=0,2 do luau.compile(p.Source,{optimizationLevel=opt}) end;compiled+=1
 if not allowed[p:GetFullName()] then
  local q=old;for _,n in string.split(p:GetFullName(),'.') do q=assert(q:FindFirstChild(n),n) end
  assert(q.Source==p.Source,'unrelated source changed '..p:GetFullName());preserved+=1
 end
end end
assert(rb.serializeModel({old.Workspace})==rb.serializeModel({place.Workspace}),'Workspace changed')
local bytes=rb.serializePlace(place)
local signatures={};local suiteSources={}
for _,pair in {{'before',old},{'after',place}} do
 local tag,root=pair[1],pair[2];local cache={}
 local function load(node)
  if cache[node] then return cache[node] end
  local env={script=node,require=load,warn=warn,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,
   game={GetService=function(_,name) if name=='ReplicatedStorage' then return root.ReplicatedStorage elseif name=='RunService' then return {} end;assert(name=='HttpService',name);return {JSONDecode=function(_,s) return serde.decode('json',s) end} end}}
  cache[node]=luau.load(node.Source,{environment=env})();return cache[node]
 end
 local rs=root.ReplicatedStorage;local model=load(rs.MeadowV4.Builder).build(root.Workspace,rb.Vector3.zero)
 local function encode(p)
  local c={p.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i]) end
  return {name=p.Name,position={c[1],c[2],c[3]},rotation=r,size={p.Size.X,p.Size.Y,p.Size.Z},color={p.Color.R*255,p.Color.G*255,p.Color.B*255},material=p.Material.Name,shape=p:IsA('Part') and p.Shape.Name or 'Wedge',transparency=p.Transparency,collidable=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,lane=p:GetAttribute('WalkableLaneFloor'),laneId=p:GetAttribute('LaneId'),role=p:GetAttribute('SurfaceRole'),tags=p:GetTags(),attributes=p:GetAttributes(),label=p:GetAttribute('RouteLabel'),category=p:GetAttribute('MeadowV4Category'),section=p:GetAttribute('Section'),supportY=p:GetAttribute('SupportY')}
 end
 local parts,physical,kits,lights={},{},{},{}
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then local r=encode(p);table.insert(parts,r);if p.CanCollide or p:GetAttribute('WalkableLaneFloor') then
  local signature=table.clone(r)
  if r2 and not p:GetAttribute('WalkableLaneFloor') and table.find({'TunnelHillEarth','TunnelRockCourse','TunnelInnerRockFacet','SolidMountainStone','R5BoulderFoot'},p.Name) then signature.color=nil;signature.material=nil end
  table.insert(physical,serde.encode('json',signature)) end end end
 table.sort(physical);signatures[tag]=table.concat(physical,'\n')
 for _,p in model:GetDescendants() do if p:IsA('PointLight') then
  local v=p.Parent.CFrame.Position;table.insert(lights,{position={v.X,v.Y,v.Z},color={p.Color.R,p.Color.G,p.Color.B},brightness=p.Brightness,range=p.Range})
 end end
 if tag=='after' and rs.MeadowV4:FindFirstChild('Section2') then
  local s=load(rs.MeadowV4.Section2);local keys={}
  for _,e in serde.decode('json',root.ServerScriptService.KitLibrary.Manifest.Value) do keys[e.island..'__'..e.name]=true end
  for _,g in s.kits do
   assert(keys[(g.island or 'meadow')..'__'..g.name],g.name)
   local y=assert(s.ground(model,g.x,g.z,g.size.X,g.size.Z),'kit ground '..g.id)
   table.insert(kits,{id=g.id,name=g.name,island=g.island or 'meadow',x=g.x,y=y,z=g.z,size={g.size.X,g.size.Y,g.size.Z},fit=g.fit,attachment=g.attachment,color=g.color})
  end
  for _,p in model:GetDescendants() do if p:IsA('BasePart') and p:GetAttribute('Section')=='S2' then assert(not p.CanCollide and not p.CanQuery and not p.CanTouch,'cosmetic physics') end end
 end
 fs.writeFile(H..tag..'.json',serde.encode('json',{parts=parts,routes={},kits=kits,lights=lights},false))
 if process.args[1]=='sites' and tag=='before' then
  local s=load(rs.MeadowV4.Section1);local plan=load(root.ServerScriptService.KitPlan);local lanes=plan.lanes(model);local sites={}
  for x=-116,-44,2 do for z=0,124,2 do
   if x>=-58 and z>=98 then continue end
   local y=s.ground(model,x,z,5,5)
   if y then local p=rb.Instance.new('Part');p.Size=rb.Vector3.new(5,22,5);p.CFrame=rb.CFrame.new(x,y+11,z)
    if plan.laneClear({p},lanes) then
     local blocked=false
     for _,q in model:GetDescendants() do if q:IsA('BasePart') and q.CanCollide and q.CFrame.Position.Y+q.Size.Y/2>y+.1 then
      local v=q.CFrame:PointToObjectSpace(p.CFrame.Position);if math.abs(v.X)<q.Size.X/2+2.5 and math.abs(v.Y)<q.Size.Y/2+11 and math.abs(v.Z)<q.Size.Z/2+2.5 then blocked=true end
     end end
     if not blocked then table.insert(sites,{x=x,z=z,y=y}) end
    end
   end
  end end
  fs.writeFile(H..'sites.json',serde.encode('json',sites,true))
 end
end
assert(signatures.before==signatures.after,'physics/floor/tags changed')
fs.writeFile(H..'AUDIT.json',serde.encode('json',{compiled_O0_O1_O2=compiled,unrelated_sources_preserved=preserved,workspace_equal=true,physics_floor_tags_equal=true,StudioPassAll='UNKNOWN; nine live suites not run'},true))
if mode=='deliver' then fs.writeFile(main,bytes);rb.deserializePlace(fs.readFile(main)) end
print('PASS',compiled,'scripts O0/O1/O2;',preserved,'unrelated sources; physical/floor/tag parity')
