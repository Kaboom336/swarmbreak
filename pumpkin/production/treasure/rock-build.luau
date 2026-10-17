-- Source-only mount: canonical serialized kits/Workspace must survive unchanged.
local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/rock/'
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-rock.rbxl'
local mode=process.args[1] or 'before'
local previousMount=fs.isFile(H..'MOUNT-deliver.json')and serde.decode('json',fs.readFile(H..'MOUNT-deliver.json'))or nil
if not fs.isDir(H) then fs.writeDir(H) end
if mode=='backup' then
 assert(not fs.isFile(backup),'pre-rock backup already exists; do not overwrite')
 local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
 fs.writeFile(H..'BACKUP.json',serde.encode('json',{sha256=serde.hash('sha256',bytes),byte_verified=true},true));print('PASS backup');return
end
local baseline=fs.readFile(backup);local p=rb.deserializePlace(baseline)
if mode~='before' then
 local s=rb.Instance.new('ModuleScript');s.Name='ZRockShells';s.Source=fs.readFile('prototype/meadow-v4/ZRockShells.luau');s:SetAttribute('MeadowDressing',true);s.Parent=p.ReplicatedStorage.MeadowV4
 local data=rb.Instance.new('ModuleScript');data.Name='RockShellPlan';data.Source=fs.readFile('prototype/meadow-v4/RockShellPlan.luau');data.Parent=p.ReplicatedStorage.MeadowV4
end
local compiled=0
for _,s in p:GetDescendants() do if s:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(s.Source,{optimizationLevel=o})end;compiled+=1 end end
local bytes=rb.serializePlace(p);local neutral=rb.deserializePlace(bytes)
if mode~='before' then neutral.ReplicatedStorage.MeadowV4.ZRockShells:Destroy();neutral.ReplicatedStorage.MeadowV4.RockShellPlan:Destroy()end
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
for _,q in model:GetDescendants()do
 if q:IsA('BasePart')then
  local c={q.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i])end
  table.insert(parts,{name=q.Name,position={c[1],c[2],c[3]},rotation=r,size={q.Size.X,q.Size.Y,q.Size.Z},color={q.Color.R*255,q.Color.G*255,q.Color.B*255},material=q.Material.Name,shape=q:IsA('Part')and q.Shape.Name or (q:IsA('WedgePart')and'Wedge'or'Mesh'),transparency=q.Transparency,collidable=q.CanCollide,query=q.CanQuery,touch=q.CanTouch,collisionGroup=q.CollisionGroup,tags=q:GetTags(),attributes=q:GetAttributes(),lane=q:GetAttribute('WalkableLaneFloor'),laneId=q:GetAttribute('LaneId'),category=q:GetAttribute('MeadowV4Category'),section=q:GetAttribute('Section'),label=q:GetAttribute('RouteLabel'),labelFace=q:GetAttribute('LabelFace'),labelSize=q:GetAttribute('LabelSize')})
 elseif q:IsA('PointLight')or q:IsA('SpotLight')then
  local v=q.Parent.CFrame.Position;table.insert(lights,{kind=q.ClassName,position={v.X,v.Y,v.Z},color={q.Color.R,q.Color.G,q.Color.B},brightness=q.Brightness,range=q.Range,shadows=q.Shadows})
 end
end
fs.writeFile(H..mode..'.json',serde.encode('json',{parts=parts,lights=lights,kits={},routes={}},false))
fs.writeFile(H..'MOUNT-'..mode..'.json',serde.encode('json',{compiled_O0_O1_O2=compiled,unrelated_serialized_state_exact=true,canonical_sha256=serde.hash('sha256',bytes)},true))
if mode=='deliver'then
 local current=fs.readFile(main)
 assert(current==baseline or(previousMount and serde.hash('sha256',current)==previousMount.canonical_sha256),'canonical changed outside this pass; preserve newer owner work')
 fs.writeFile(main,bytes)
else if mode~='before'then fs.writeFile(H..mode..'.rbxl',bytes)end end
print('PASS',mode,'compiled',compiled,'native parts',#parts,'serialized state exact')
