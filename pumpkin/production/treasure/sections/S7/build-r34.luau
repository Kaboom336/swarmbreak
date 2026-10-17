local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/sections/S7/'
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-s7r3.rbxl'
local tag=assert(process.args[1]);assert(tag=='r3' or tag=='r4')
local old=rb.deserializePlace(fs.readFile(backup));local p=rb.deserializePlace(fs.readFile(backup))
local function mount(parent,name,path)
 local n=parent:FindFirstChild(name)
 if n then n.Source=fs.readFile(path) else n=rb.Instance.new('ModuleScript');n.Name=name;n.Source=fs.readFile(path);n.Parent=parent end
end
mount(p.ReplicatedStorage.MeadowV4,'Section7','prototype/meadow-v4/Section7.luau')
mount(p.ReplicatedStorage.MeadowV4,'SummitAcorn','prototype/meadow-v4/SummitAcorn.luau')
mount(p.StarterPlayer.StarterPlayerScripts,'HomeArt','slice-v2/prototype/HomeArt.client.luau')
for _,n in {p.ReplicatedStorage.MeadowV4.Section7,p.ReplicatedStorage.MeadowV4.SummitAcorn,p.StarterPlayer.StarterPlayerScripts.HomeArt} do fs.writeFile(H..tag..'-'..n.Name..'.luau',n.Source) end
local neutral=rb.deserializePlace(rb.serializePlace(p));neutral.ReplicatedStorage.MeadowV4.SummitAcorn:Destroy()
neutral.ReplicatedStorage.MeadowV4.Section7.Source=old.ReplicatedStorage.MeadowV4.Section7.Source
neutral.StarterPlayer.StarterPlayerScripts.HomeArt.Source=old.StarterPlayer.StarterPlayerScripts.HomeArt.Source
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized place changed')
local compiled=0
for _,n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then for level=0,2 do luau.compile(n.Source,{optimizationLevel=level}) end;compiled+=1 end end
local bytes=rb.serializePlace(p) -- Freeze before offline proxy builders mutate Workspace.
local function export(root,name,visual)
 local cache={};local warnings={}
 local function load(n)
  if cache[n] then return cache[n] end
  local env={script=n,require=load,warn=function(...) table.insert(warnings,{...}) end,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,
   game={GetService=function(_,s) if s=='ReplicatedStorage' then return root.ReplicatedStorage elseif s=='RunService' then return {} end;assert(s=='HttpService',s);return {JSONDecode=function(_,v)return serde.decode('json',v)end} end}}
  cache[n]=luau.load(n.Source,{environment=env})();return cache[n]
 end
 local model=load(root.ReplicatedStorage.MeadowV4.Builder).build(root.Workspace,rb.Vector3.zero)
 assert(#warnings==0,serde.encode('json',warnings))
 local parts,lights={},{}
 local function collect(node)
 for _,q in node:GetDescendants() do if q:IsA('BasePart') then
  local c={q.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i]) end
  table.insert(parts,{name=q.Name,position={c[1],c[2],c[3]},rotation=r,size={q.Size.X,q.Size.Y,q.Size.Z},color={q.Color.R*255,q.Color.G*255,q.Color.B*255},material=q.Material.Name,shape=q:IsA('Part') and q.Shape.Name or 'Wedge',transparency=q.Transparency,collidable=q.CanCollide,query=q.CanQuery,touch=q.CanTouch,lane=q:GetAttribute('WalkableLaneFloor'),laneId=q:GetAttribute('LaneId'),role=q:GetAttribute('SurfaceRole'),tags=q:GetTags(),attributes=q:GetAttributes(),label=q:GetAttribute('RouteLabel'),labelFace=q:GetAttribute('LabelFace'),labelY=q:GetAttribute('LabelY'),labelSize=q:GetAttribute('LabelSize'),category=q:GetAttribute('MeadowV4Category'),section=q:GetAttribute('Section'),supportY=q:GetAttribute('SupportY')})
 elseif q:IsA('PointLight') then local v=q.Parent.CFrame.Position
  table.insert(lights,{kind='PointLight',position={v.X,v.Y,v.Z},color={q.Color.R,q.Color.G,q.Color.B},brightness=q.Brightness,range=q.Range,shadows=q.Shadows})
 end end
 end
 collect(model)
 local kits=serde.decode('json',fs.readFile(H..'r2.json')).kits
 fs.writeFile(H..name..'.json',serde.encode('json',{parts=parts,routes={},kits=kits,lights=lights},false))
 if visual then
  -- Explicit client proxy: exact same new model and scale, never serialized.
  for i=#parts,1,-1 do if parts[i].name=='GoldenAcorn' or parts[i].name=='AcornCap' or parts[i].name=='AcornStem' then table.remove(parts,i) end end
  local hero=load(root.ReplicatedStorage.MeadowV4.SummitAcorn).build()
  for _,q in hero:GetDescendants() do if q:IsA('BasePart') then
   q.Size*=1.8;q.CFrame=rb.CFrame.new(0,49.5,-96)*rb.CFrame.new(q.CFrame.Position*1.8)*q.CFrame.Rotation
  end end
  collect(hero)
  table.insert(lights,{kind='PointLight',position={0,53.1,-96},color={1,218/255,103/255},brightness=1.2,range=18,shadows=false})
  fs.writeFile(H..name..'-visual.json',serde.encode('json',{parts=parts,routes={},kits=kits,lights=lights},false))
 end
end
if not fs.isFile(H..'before-r34.json') then export(old,'before-r34',false) end
export(p,tag,true)
fs.writeFile(H..string.upper(tag)..'-review.rbxl',bytes);fs.writeFile(main,bytes)
fs.writeFile(H..'MOUNT-'..tag..'.json',serde.encode('json',{compiled_O0_O1_O2=compiled,unrelated_serialized_place_exact=true,workspace_exact=true,canonical_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',fs.readFile(backup)),changed_sources={'Section7','HomeArt'},new_source='SummitAcorn',live_Studio='UNKNOWN'},true))
print('PASS',tag,compiled,'sources compile O0/O1/O2; unrelated serialized place exact')
