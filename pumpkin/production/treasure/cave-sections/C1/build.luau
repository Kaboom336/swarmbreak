return function()
local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local tag=require('@lune/process').args[1]:sub(4)
assert(tag=='before'or tag=='r1'or tag=='r2'or tag=='r3'or tag=='r4','C1 rounds 1-4 only')
local H='treasure/cave-sections/C1/'
local target,backup='prototype/cave-v2.rbxl','prototype/cave-v2.pre-c1.rbxl'
if tag=='r3'or tag=='r4'then
 assert(fs.isFile('prototype/cave-v2.pre-c1r3.rbxl'),'R3 backup required before edits')
end
if not fs.isFile(backup)then
 local bytes=fs.readFile(target);rb.deserializePlace(bytes);fs.writeFile(backup,bytes)
 assert(fs.readFile(backup)==bytes,'backup mismatch')
end
local original=fs.readFile(backup);local p=rb.deserializePlace(original)
local plan={}
if tag~='before'then
 plan=require('./plan')(tag)
 local group=rb.Instance.new('Folder');group.Name='CaveArrivalC1';group.Parent=p.Workspace
 for i,g in plan do
  local q=rb.Instance.new(g.shape=='Wedge'and'WedgePart'or'Part');q.Name=g.name
  q.Size=rb.Vector3.new(unpack(g.s));q.CFrame=rb.CFrame.new(unpack(g.c))*rb.CFrame.Angles(0,math.rad(g.yaw or 0),0)
  q.Color=rb.Color3.fromRGB(unpack(g.color));q.Material=rb.Enum.Material[g.material or 'Slate']
  q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q:SetAttribute('C1Cosmetic',true)
  if g.kit then q:SetAttribute('C1Fallback',true)end
  if g.apronShoulder then q:SetAttribute('C1ApronShoulder',true)end
  q.Parent=group
  if g.light then local l=rb.Instance.new('PointLight');l.Brightness=1;l.Range=14;l.Shadows=false;l.Color=q.Color;l.Parent=q end
  if i%16==0 then require('@lune/task').wait()end
 end
 local script=rb.Instance.new('Script');script.Name='CaveArrivalC1';script.Source=fs.readFile('prototype/cave-v2/ArrivalC1.server.luau');script.Parent=p.ServerScriptService
 local data=rb.Instance.new('StringValue');data.Name='Plan';data.Value=serde.encode('json',plan);data.Parent=script
 if tag=='r3'or tag=='r4'then
  local presentation=rb.Instance.new('ModuleScript');presentation.Name='Presentation';presentation.Source=fs.readFile(H..'presentation.luau');presentation.Parent=script
  local round=rb.Instance.new('StringValue');round.Name='Round';round.Value=tag;round.Parent=script
 end
end
local compiled=0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end;compiled+=1 end end
local bytes=rb.serializePlace(p);local neutral=rb.deserializePlace(bytes)
if tag~='before'then neutral.Workspace.CaveArrivalC1:Destroy();neutral.ServerScriptService.CaveArrivalC1:Destroy()end
assert(rb.serializePlace(neutral)==rb.serializePlace(rb.deserializePlace(original)),'unrelated state changed')
-- Export the same cosmetic-only presentation executed by the mounted script.
-- Serialized original visuals remain reversible and stock offline checks stay exact.
if tag=='r3'or tag=='r4'then
 local apply=luau.load(fs.readFile(H..'presentation.luau'),{environment={Color3=rb.Color3,Enum=rb.Enum,task=require('@lune/task')}})()
 local report=apply(p.Workspace.CaveV2,tag)
 fs.writeFile(H..'PRESENTATION-'..tag..'.json',serde.encode('json',report,true))
end
local parts,lights,labels={},{},{}
for i,n in p.Workspace:GetDescendants()do
 if n:IsA('BasePart')then
  local cf,s=n.CFrame,n.Size;local a,b,c=cf.RightVector,cf.UpVector,-cf.LookVector
  local shape=n:IsA('WedgePart')and'Wedge'or'Block'
  if n.ClassName=='Part'and n.Shape==rb.Enum.PartType.Ball then shape='Ball'end
  local col=n.Color
  table.insert(parts,{name=n.Name,position={cf.X,cf.Y,cf.Z},size={s.X,s.Y,s.Z},rotation={a.X,b.X,c.X,a.Y,b.Y,c.Y,a.Z,b.Z,c.Z},color={col.R*255,col.G*255,col.B*255},material=n.Material.Name,shape=shape,transparency=n.Transparency,c1fallback=n:GetAttribute('C1Fallback')==true,collidable=n.CanCollide})
  for _,l in n:GetChildren()do if l:IsA('PointLight')and l.Enabled then table.insert(lights,{position={cf.X,cf.Y,cf.Z},brightness=l.Brightness,range=l.Range,color={l.Color.R,l.Color.G,l.Color.B}})end end
 end
 if i%300==0 then require('@lune/task').wait()end
end
fs.writeFile(H..tag..'.json',serde.encode('json',{parts=parts,lights=lights,labels=labels},true))
fs.writeFile(H..tag..'-plan.json',serde.encode('json',plan,true))
fs.writeFile(H..'MOUNT-'..tag..'.json',serde.encode('json',{compiled=compiled,backup_sha256=serde.hash('sha256',original),place_sha256=serde.hash('sha256',bytes),unrelated_serialized_state_exact=true,cosmetics=#plan},true))
if tag~='before'then fs.writeFile(H..tag..'-review.rbxl',bytes);fs.writeFile(target,bytes)end
print('PASS C1',tag,'exact unrelated state; compiled O0/O1/O2',compiled,'cosmetics',#plan)
end
