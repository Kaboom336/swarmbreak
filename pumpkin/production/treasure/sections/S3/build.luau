local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/sections/S3/'
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-s3.rbxl'
local mode=process.args[1] or 'before'
if mode=='backup' then
 assert(not fs.isFile(backup),'preserve backup');local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes);print('PASS byte-verified pre-s3 backup before Rojo');return
end
local old=rb.deserializePlace(fs.readFile(backup))
local place=rb.deserializePlace(fs.readFile(backup))
if mode~='before' then
 local s=rb.Instance.new('ModuleScript');s.Name='Section3';s.Source=fs.readFile('prototype/meadow-v4/Section3.luau');s.Parent=place.ReplicatedStorage.MeadowV4
 fs.writeFile(H..mode..'-Section3.luau',s.Source)
end
local compiled,preserved=0,0
for _,p in place:GetDescendants() do if p:IsA('LuaSourceContainer') then
 for opt=0,2 do luau.compile(p.Source,{optimizationLevel=opt}) end;compiled+=1
 if p.Name~='Section3' then local q=old;for _,n in string.split(p:GetFullName(),'.') do q=assert(q:FindFirstChild(n),n) end;assert(q.Source==p.Source,p:GetFullName());preserved+=1 end
end end
assert(rb.serializeModel({old.Workspace})==rb.serializeModel({place.Workspace}),'Workspace changed')
-- Serialize the pristine mounted place BEFORE proof builders create temporary islands.
-- Offline text properties are render/test proxies and must never enter the delivered Workspace.
local bytes=rb.serializePlace(place)
local signatures={}
local function export(root,tag)
 local cache={};local warnings={}
 local function load(node)
  if cache[node] then return cache[node] end
  local env={script=node,require=load,warn=function(...) table.insert(warnings,{...}) end,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,
   game={GetService=function(_,name) if name=='ReplicatedStorage' then return root.ReplicatedStorage elseif name=='RunService' then return {} end;assert(name=='HttpService',name);return {JSONDecode=function(_,s) return serde.decode('json',s) end} end}}
  cache[node]=luau.load(node.Source,{environment=env})();return cache[node]
 end
 local model=load(root.ReplicatedStorage.MeadowV4.Builder).build(root.Workspace,rb.Vector3.zero)
 assert(#warnings==0,serde.encode('json',warnings))
 local parts,physical,lights={},{},{}
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then
  local c={p.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i]) end
  local q={name=p.Name,position={c[1],c[2],c[3]},rotation=r,size={p.Size.X,p.Size.Y,p.Size.Z},color={p.Color.R*255,p.Color.G*255,p.Color.B*255},material=p.Material.Name,shape=p:IsA('Part') and p.Shape.Name or 'Wedge',transparency=p.Transparency,collidable=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,lane=p:GetAttribute('WalkableLaneFloor'),laneId=p:GetAttribute('LaneId'),role=p:GetAttribute('SurfaceRole'),tags=p:GetTags(),attributes=p:GetAttributes(),label=p:GetAttribute('RouteLabel'),labelFace=p:GetAttribute('LabelFace'),labelY=p:GetAttribute('LabelY'),labelSize=p:GetAttribute('LabelSize'),category=p:GetAttribute('MeadowV4Category'),section=p:GetAttribute('Section'),supportY=p:GetAttribute('SupportY')}
  table.insert(parts,q)
  if p.CanCollide or p.CanQuery or p.CanTouch or q.lane or #q.tags>0 then table.insert(physical,serde.encode('json',q)) end
  if q.section=='S3' then assert(not p.CanCollide and not p.CanQuery and not p.CanTouch,'cosmetic physics') end
 elseif p:IsA('PointLight') or p:IsA('SpotLight') then
  local v=p.Parent.CFrame.Position;local spot=p:IsA('SpotLight');local direction=nil
  if spot then assert(p.Face==rb.Enum.NormalId.Bottom,'only exported bottom-face spots');local d=-p.Parent.CFrame.UpVector;direction={d.X,d.Y,d.Z};v+=d*p.Parent.Size.Y/2 end
  table.insert(lights,{kind=p.ClassName,position={v.X,v.Y,v.Z},direction=direction,angle=if spot then p.Angle else nil,color={p.Color.R,p.Color.G,p.Color.B},brightness=p.Brightness,range=p.Range})
 end end
 table.sort(physical);signatures[tag]=table.concat(physical,'\n')
 local kits=serde.decode('json',fs.readFile('treasure/sections/S2/close-after.json')).kits
 fs.writeFile(H..tag..'.json',serde.encode('json',{parts=parts,routes={},kits=kits,lights=lights},false))
 return model,load
end
export(old,'before')
local model,load=export(place,mode)
assert(signatures.before==signatures[mode],'protected geometry/palette/query/touch/floor/lane/tags changed')
fs.writeFile(H..'AUDIT-'..mode..'.json',serde.encode('json',{compiled_O0_O1_O2=compiled,unrelated_sources_preserved=preserved,workspace_exact=true,all_protected_signatures_exact=true,live_Studio='UNKNOWN'},true))
if mode=='deliver' then
 local rojo=rb.deserializePlace(fs.readFile(H..'rojo.rbxl'))
 assert(rojo.ReplicatedStorage.MeadowV4.Section3.Source==place.ReplicatedStorage.MeadowV4.Section3.Source,'Rojo source parity')
 fs.writeFile(main,bytes);local delivered=rb.deserializePlace(fs.readFile(main))
 assert(rb.serializeModel({delivered.Workspace})==rb.serializeModel({rb.deserializePlace(fs.readFile(backup)).Workspace}),'delivered Workspace changed')
end
print('PASS',mode,compiled,'compiled O0/O1/O2;',preserved,'preserved; exact protected signatures')
