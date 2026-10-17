local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/rock2/'
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-rock2.rbxl'
local mode=process.args[1]or'before'
if not fs.isDir(H)then fs.writeDir(H)end
if mode=='backup'then
 assert(not fs.isFile(backup),'backup already exists')
 local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(bytes==fs.readFile(backup))
 fs.writeFile(H..'BACKUP.json',serde.encode('json',{sha256=serde.hash('sha256',bytes),byte_verified=true},true));print('PASS byte-verified rock2 backup');return
end
local baseline=fs.readFile(backup);local p=rb.deserializePlace(baseline)
if mode~='before'then
 for _,name in{'ZRock2','Rock2Plan'}do
  local m=rb.Instance.new('ModuleScript');m.Name=name;m.Source=fs.readFile('prototype/meadow-v4/'..name..'.luau')
  if name=='ZRock2'then m:SetAttribute('MeadowDressing',true)end
  m.Parent=p.ReplicatedStorage.MeadowV4
 end
end
local sources={};local compiled=0
for _,s in p:GetDescendants()do if s:IsA('LuaSourceContainer')then
 for o=0,2 do luau.compile(s.Source,{optimizationLevel=o})end;compiled+=1
 sources[s:GetFullName()]=s.Source
end end
fs.writeFile(H..mode..'-sources.json',serde.encode('json',sources))
local bytes=rb.serializePlace(p);local neutral=rb.deserializePlace(bytes)
if mode~='before'then neutral.ReplicatedStorage.MeadowV4.ZRock2:Destroy();neutral.ReplicatedStorage.MeadowV4.Rock2Plan:Destroy()end
assert(rb.serializePlace(neutral)==rb.serializePlace(rb.deserializePlace(baseline)),'unrelated serialized state changed')
local cache,warnings={},{}
local function load(node)
 if cache[node]then return cache[node]end
 cache[node]=luau.load(node.Source,{environment={script=node,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,warn=function(...)table.insert(warnings,{...})end,
 game={GetService=function(_,name)if name=='ReplicatedStorage'then return p.ReplicatedStorage elseif name=='ServerStorage'then return p.ServerStorage elseif name=='RunService'then return {} elseif name=='Workspace'then return p.Workspace end;assert(name=='HttpService',name);return {JSONDecode=function(_,s)return serde.decode('json',s)end}end}}})()
 return cache[node]
end
local model=load(p.ReplicatedStorage.MeadowV4.Builder).build(p.Workspace,rb.Vector3.zero)
assert(#warnings==0,serde.encode('json',warnings))
local parts,lights={},{}
local keeperExcludedKitColliders=0
for _,q in model:GetDescendants()do
 if q:IsA('BasePart')then
  if q.CanCollide and q:FindFirstAncestor('KitDressing')then keeperExcludedKitColliders+=1 end
  local c={q.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i])end
  table.insert(parts,{name=q.Name,position={c[1],c[2],c[3]},rotation=r,size={q.Size.X,q.Size.Y,q.Size.Z},color={q.Color.R*255,q.Color.G*255,q.Color.B*255},material=q.Material.Name,shape=q:IsA('Part')and q.Shape.Name or(q:IsA('WedgePart')and'Wedge'or'Mesh'),transparency=q.Transparency,collidable=q.CanCollide,query=q.CanQuery,touch=q.CanTouch,collisionGroup=q.CollisionGroup,tags=q:GetTags(),attributes=q:GetAttributes(),lane=q:GetAttribute('WalkableLaneFloor'),laneId=q:GetAttribute('LaneId'),category=q:GetAttribute('MeadowV4Category'),section=q:GetAttribute('Section'),label=q:GetAttribute('RouteLabel'),labelFace=q:GetAttribute('LabelFace'),labelSize=q:GetAttribute('LabelSize')})
 elseif q:IsA('PointLight')or q:IsA('SpotLight')then
  local v=q.Parent.CFrame.Position;table.insert(lights,{kind=q.ClassName,position={v.X,v.Y,v.Z},color={q.Color.R,q.Color.G,q.Color.B},brightness=q.Brightness,range=q.Range,shadows=q.Shadows})
 end
end
fs.writeFile(H..mode..'.json',serde.encode('json',{parts=parts,lights=lights,kits={},routes={}}))
local report={compiled_O0_O1_O2=compiled,unrelated_serialized_state_exact=true,canonical_sha256=serde.hash('sha256',bytes),keeper_excluded_KitDressing_colliders=keeperExcludedKitColliders}
if mode=='deliver'then
 local current=fs.readFile(main);local old=fs.isFile(H..'MOUNT-deliver.json')and serde.decode('json',fs.readFile(H..'MOUNT-deliver.json'))or nil
 assert(current==baseline or(old and serde.hash('sha256',current)==old.canonical_sha256),'canonical changed outside pass')
 fs.writeFile(main,bytes)
elseif mode~='before'then fs.writeFile(H..mode..'.rbxl',bytes)end
fs.writeFile(H..'MOUNT-'..mode..'.json',serde.encode('json',report,true))
print('PASS',mode,'compiled',compiled,'parts',#parts,'serialized state exact')
