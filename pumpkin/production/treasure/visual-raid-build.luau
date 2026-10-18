-- Canonical-place overlay and matched native manifests; never plain Rojo.
local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/visual-simplify/'
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-visual-raid2.rbxl'
local mode=process.args[1] or 'before'
if not fs.isDir(H) then fs.writeDir(H) end
if mode=='backup' then
 assert(not fs.isFile(backup),'backup already exists')
 local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
 print('PASS byte-verified pre-visual-raid2 backup');return
end
local baseline=fs.readFile(backup)
local p=rb.deserializePlace(baseline)
if mode~='before' then
 local old=p.ServerScriptService.Greybox.Source
 local mounted=fs.readFile('slice-v2/prototype/Greybox.server.luau')
 local new=[[  local wall=Raid.wallFor(arena,v.start)
  if not wall then stopVault(actor);continue end
  params.FilterDescendantsInstances={v.character,wall}]]
 local start,finish=assert(mounted:find(new,1,true))
 assert(mounted:sub(1,start-1)..'  params.FilterDescendantsInstances={v.character,arena.v4.RaidJunction.JumpVaultWall}'..mounted:sub(finish+1)==old,'server delta beyond selected vault wall')
end
local changes={}
if mode~='before' then
 local mounts={
  {p.ReplicatedStorage.MeadowV4,'VisualSimplify','prototype/meadow-v4/VisualSimplify.luau'},
  {p.ReplicatedStorage.MeadowV4,'Builder','prototype/meadow-v4/MeadowV4.luau'},
  {p.ReplicatedStorage.MeadowV4,'RaidSlice','prototype/meadow-v4/RaidSlice.luau'},
  {p.StarterPlayer.StarterPlayerScripts,'RaidSliceClient','prototype/meadow-v4/RaidSlice.client.luau'},
  {p.ServerScriptService,'RaidSliceTestRunner','slice-v2/prototype/RaidSliceTest.luau'},
  {p.ServerScriptService,'Greybox','slice-v2/prototype/Greybox.server.luau'},
  {p.ReplicatedStorage,'LightingPresets','slice-v2/prototype/LightingPresets.luau'},
  {p.ServerScriptService,'LightingPresets','slice-v2/prototype/LightingPresets.luau'},
 }
 for _,m in mounts do
  local q=m[1]:FindFirstChild(m[2]);local old=q and q.Source
  if not q then q=rb.Instance.new('ModuleScript');q.Name=m[2];q.Parent=m[1] end
  table.insert(changes,{q=q,old=old});q.Source=fs.readFile(m[3])
 end
end
local compiled=0
for _,q in p:GetDescendants() do if q:IsA('LuaSourceContainer') then
 for o=0,2 do luau.compile(q.Source,{optimizationLevel=o}) end;compiled+=1
end end
local bytes=rb.serializePlace(p)
for _,c in changes do if c.old then c.q.Source=c.old else c.q:Destroy() end end
assert(rb.serializePlace(p)==rb.serializePlace(rb.deserializePlace(baseline)),'overlay undo changed unrelated state')
p=rb.deserializePlace(bytes)
local cache,warnings={},{}
local conservation
local function load(q)
 if cache[q] then return cache[q] end
 cache[q]=luau.load(q.Source,{environment={script=q,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,warn=function(...) table.insert(warnings,{...}) end,
 game={GetService=function(_,name) if name=='ReplicatedStorage' then return p.ReplicatedStorage elseif name=='ServerStorage' then return p.ServerStorage elseif name=='RunService' then return {} elseif name=='Workspace' then return p.Workspace end;return {JSONDecode=function(_,s) return serde.decode('json',s) end} end}}})()
 if q.Name=='VisualSimplify' then
  local actual=cache[q].apply
  local function snapshot(root)
   local entries={}
   for _,n in root:GetDescendants() do if n:IsA('BasePart') and
    (n.CanCollide or n.CanQuery or n.CanTouch or n:GetAttribute('WalkableLaneFloor') or n:GetAttribute('LaneId') or n:GetAttribute('SurfaceRole')=='Cover' or #n:GetTags()>0) then
     -- Compare every BasePart property. Descendants are independently enumerated;
     -- inherited UIStyle fixtures use an offline FontFace proxy, not a Font.
     local copy=n:Clone();for _,child in copy:GetChildren() do child:Destroy() end
     table.insert(entries,rb.serializeModel({copy}))
   end end
   table.sort(entries);return table.concat(entries,'\0'),#entries
  end
  cache[q].apply=function(root)
   local before,n=snapshot(root)
   local count=actual(root)
   local after,m=snapshot(root)
   assert(before==after and n==m,'visual simplify touched protected geometry')
   local total=#root:GetDescendants();actual(root)
   assert(#root:GetDescendants()==total,'visual simplify is not idempotent')
   assert(snapshot(root)==before,'repeat cleanup changed protected geometry')
   conservation={status='PASS',protected_parts=n,serialization_exact=true,idempotent=true,removed_parts=count}
   return count
  end
 end
 return cache[q]
end
local model=load(p.ReplicatedStorage.MeadowV4.Builder).build(p.Workspace,rb.Vector3.zero)
assert(#warnings==0,serde.encode('json',warnings))
local parts,lights,inventory={},{},{}
for _,q in model:GetDescendants() do
 if q:IsA('BasePart') then
  local c={q.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i]) end
  local section=q:GetAttribute('Section') or 'unowned'
  table.insert(parts,{path=q:GetFullName(),name=q.Name,position={c[1],c[2],c[3]},rotation=r,size={q.Size.X,q.Size.Y,q.Size.Z},color={q.Color.R*255,q.Color.G*255,q.Color.B*255},material=q.Material.Name,shape=q:IsA('Part') and q.Shape.Name or (q:IsA('WedgePart') and 'Wedge' or 'Mesh'),transparency=q.Transparency,collidable=q.CanCollide,query=q.CanQuery,touch=q.CanTouch,collisionGroup=q.CollisionGroup,tags=q:GetTags(),attributes=q:GetAttributes(),lane=q:GetAttribute('WalkableLaneFloor'),laneId=q:GetAttribute('LaneId'),category=q:GetAttribute('MeadowV4Category'),section=section})
  local key=section..'/'..q.Name;inventory[key]=(inventory[key] or 0)+1
 elseif q:IsA('PointLight') or q:IsA('SpotLight') or q:IsA('SurfaceLight') then
  local v=q.Parent.CFrame.Position;table.insert(lights,{path=q:GetFullName(),section=q.Parent:GetAttribute('Section') or 'unowned',kind=q.ClassName,position={v.X,v.Y,v.Z},color={q.Color.R,q.Color.G,q.Color.B},brightness=q.Brightness,range=q.Range,shadows=q.Shadows})
 end
end
fs.writeFile(H..mode..'.json',serde.encode('json',{parts=parts,lights=lights,kits={},routes={},instances=#model:GetDescendants()}))
fs.writeFile(H..mode..'-inventory.json',serde.encode('json',inventory,true))
if conservation then fs.writeFile(H..'COLLIDABLE-CONTRACT.json',serde.encode('json',conservation,true)) end
if mode=='deliver' then fs.writeFile(main,bytes) end
fs.writeFile(H..'BUILD-'..mode..'.json',serde.encode('json',{status='PASS',compiled_O0_O1_O2=compiled,place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',baseline),undo_exact=true,Studio='NOT RUN'},true))
print('PASS',mode,'compiled',compiled,'parts',#parts,'lights',#lights,'instances',#model:GetDescendants())
