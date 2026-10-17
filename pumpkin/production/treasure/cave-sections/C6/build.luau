return function()
local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local tag=require('@lune/process').args[1]:sub(4)
assert(table.find({'before','r1','r2','r3','r4'},tag),'C6 rounds only')
local H='treasure/cave-sections/C6/'
local target,backup='prototype/cave-v2.rbxl','prototype/cave-v2.pre-c6.rbxl'
assert(fs.isFile(backup),'run C6/probe.luau to byte-verify backup first')
local original=fs.readFile(backup);local p=rb.deserializePlace(original)
local plan={}
if tag~='before'then
 plan=require('./plan')(tag)
 local group=rb.Instance.new('Folder');group.Name='CaveEscapeC6';group.Parent=p.Workspace
 for i,g in plan do
  local q=rb.Instance.new(g.shape=='Wedge'and'WedgePart'or'Part');q.Name=g.name
  q.Size=rb.Vector3.new(unpack(g.s))
  if g.r then local cf=table.clone(g.c);for _,n in g.r do table.insert(cf,n)end;q.CFrame=rb.CFrame.new(unpack(cf))
  else q.CFrame=rb.CFrame.new(unpack(g.c))*rb.CFrame.Angles(0,math.rad(g.yaw or 0),0)end
  q.Color=rb.Color3.fromRGB(unpack(g.color));q.Material=rb.Enum.Material[g.material or 'Slate']
  q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
  q:SetAttribute('C6Cosmetic',true);if g.kit then q:SetAttribute('C6Fallback',true)end;q.Parent=group
  if g.light then local l=rb.Instance.new('PointLight');l.Brightness=1;l.Range=14;l.Shadows=false;l.Color=q.Color;l.Parent=q end
  -- GUI is created by the mounted runtime to avoid Lune materializing default
  -- FontFace fields on every original TextLabel during binary serialization.
  if i%16==0 then require('@lune/task').wait()end
 end
 local node=rb.Instance.new('Script');node.Name='CaveEscapeC6';node.Source=fs.readFile('prototype/cave-v2/EscapeC6.server.luau');node.Parent=p.ServerScriptService
 local data=rb.Instance.new('StringValue');data.Name='Plan';data.Value=serde.encode('json',plan);data.Parent=node
 local round=rb.Instance.new('StringValue');round.Name='Round';round.Value=tag;round.Parent=node


end
local compiled=0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end;compiled+=1 end end
local bytes=rb.serializePlace(p);local neutral=rb.deserializePlace(bytes)
if tag~='before'then neutral.Workspace.CaveEscapeC6:Destroy();neutral.ServerScriptService.CaveEscapeC6:Destroy()end

assert(rb.serializePlace(neutral)==rb.serializePlace(rb.deserializePlace(original)),'unrelated serialized state changed')
-- Evaluate prior mounted cosmetic producers only in the offline export.
local env={Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,task={wait=function()end}}
for _,name in {'CaveArrivalC1','CaveGeodeC2','CaveDockC3'}do
 local n=p.ServerScriptService:FindFirstChild(name)
 if n then
  if n:FindFirstChild('Presentation')then luau.load(n.Presentation.Source,{environment=env})()(p.Workspace.CaveV2,n.Round.Value)end
  if n:FindFirstChild('Dress')then luau.load(n.Dress.Source,{environment=env})()(p.Workspace.CaveV2,p.Workspace.CaveGeodeC2,n.Round.Value)end
 end
end
local parts,lights={},{ }
for i,n in p.Workspace:GetDescendants()do if n:IsA('BasePart')then
 local cf,s,col=n.CFrame,n.Size,n.Color;local a,b,c=cf.RightVector,cf.UpVector,-cf.LookVector
 local shape=n:IsA('WedgePart')and'Wedge'or'Block'
 if n.ClassName=='Part'and n.Shape==rb.Enum.PartType.Ball then shape='Ball'end
 if n.ClassName=='Part'and n.Shape==rb.Enum.PartType.Cylinder then shape='Cylinder'end
 local textFaces={}
 for _,gui in n:GetChildren()do if gui:IsA('SurfaceGui')then
  local label=gui:FindFirstChildWhichIsA('TextLabel')
  if label then
   table.insert(textFaces,{face=gui.Face.Name,text=label.Text})
  end
 end end
 table.insert(parts,{name=n.Name,position={cf.X,cf.Y,cf.Z},size={s.X,s.Y,s.Z},rotation={a.X,b.X,c.X,a.Y,b.Y,c.Y,a.Z,b.Z,c.Z},color={col.R*255,col.G*255,col.B*255},material=n.Material.Name,shape=shape,transparency=n.Transparency,c6fallback=n:GetAttribute('C6Fallback')==true,c3fallback=n:GetAttribute('C3Fallback')==true,collidable=n.CanCollide,textFaces=textFaces})
 for _,l in n:GetChildren()do if l:IsA('PointLight')and l.Enabled then table.insert(lights,{position={cf.X,cf.Y,cf.Z},brightness=l.Brightness,range=l.Range,color={l.Color.R,l.Color.G,l.Color.B}})end end
 end;if i%300==0 then require('@lune/task').wait()end end
fs.writeFile(H..tag..'.json',serde.encode('json',{parts=parts,lights=lights,labels={}},true))
fs.writeFile(H..tag..'-plan.json',serde.encode('json',plan,true))
fs.writeFile(H..'MOUNT-'..tag..'.json',serde.encode('json',{compiled=compiled,backup_sha256=serde.hash('sha256',original),place_sha256=serde.hash('sha256',bytes),unrelated_serialized_state_exact=true,cosmetics=#plan},true))
if tag~='before'then fs.writeFile(H..tag..'-review.rbxl',bytes);fs.writeFile(target,bytes)end
print('PASS C6',tag,'exact unrelated state; O0/O1/O2',compiled,'cosmetics',#plan)
end
