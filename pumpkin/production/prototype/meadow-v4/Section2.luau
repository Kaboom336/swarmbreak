-- S2 exterior dressing only; local coordinates until MeadowV4 translates once.
local S={kits={}}
local V=Vector3.new
local groundModule=require(script.Parent.Section1)
S.ground=groundModule.ground
local wood={132,82,40};local leaf={71,139,46}
local function safe(name,fn)
 local ok,err=pcall(fn);if not ok then warn('[Section2] '..name..' skipped: '..tostring(err)) end
end
local function part(root,name,pos,size,color,material)
 local p=Instance.new('Part');p.Name='S2_'..name;p.Size=size;p.CFrame=CFrame.new(pos)
 p.Color=Color3.fromRGB(unpack(color));p.Material=material or Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S2');p:SetAttribute('Cosmetic',true);p.Parent=root;return p
end
local function foot(root,name,x,z,size,color,material)
 local y=assert(S.ground(root,x,z,size.X,size.Z),'unsupported '..name)
 local p=part(root,name,V(x,y+size.Y/2,z),size,color,material);p:SetAttribute('SupportY',y);return p
end
local function rod(root,name,a,b,width,color)
 local p=part(root,name,(a+b)/2,V(width,width,(b-a).Magnitude),color)
 local up=if math.abs((b-a).Unit.Y)>.95 then V(1,0,0) else V(0,1,0)
 p.CFrame=CFrame.lookAt((a+b)/2,b,up);return p
end
local function lantern(root,pos,normal)
 local bracket=rod(root,'LampBracket',pos,pos+normal*1.1,.22,wood)
 local c=pos+normal*1.1-V(0,1.1,0)
 part(root,'LampBase',c-V(0,.75,0),V(1.3,.2,1.3),{53,47,37},Enum.Material.Metal)
 local core=part(root,'LampGlass',c,V(.85,1.3,.85),{255,193,91},Enum.Material.Neon)
 part(root,'LampRoof',c+V(0,.75,0),V(1.3,.2,1.3),{53,47,37},Enum.Material.Metal)
 for _,dx in {-.55,.55} do for _,dz in {-.55,.55} do part(root,'LampIron',c+V(dx,0,dz),V(.12,1.3,.12),{53,47,37},Enum.Material.Metal) end end
 rod(root,'LampHanger',pos+normal*1.1,c+V(0,.85,0),.16,{53,47,37})
 local l=Instance.new('PointLight');l.Color=core.Color;l.Brightness=2.5;l.Range=23;l.Shadows=true;l.Parent=core
end
local function mine(root)
 -- Face-mounted timbers: low grounded posts would overlap the authoritative bait lane.
 -- Skin backs touch exposed solid cliff sides; they do not enter earth or cap voids.
 local a,b=V(-75.86,14.5,99),V(-52.14,14.5,88)
 part(root,'MineWestTimber',a,V(.26,15,2.2),wood)
 part(root,'MineEastTimber',b,V(.26,15,2.2),wood)
 local topA,topB=V(a.X,22.5,a.Z),V(b.X,22.5,b.Z)
 local header=rod(root,'MineHeader',topA,topB,1.25,wood)
 -- Header meets both skins; steel bolt plates sit on their visible faces.
 for _,q in {{a,1},{b,-1}} do
  for _,y in {9,18.5,21.3} do
   part(root,'TimberBolt',V(q[1].X+q[2]*.16,y,q[1].Z),V(.06,.42,.42),{74,74,66},Enum.Material.Metal)
  end
  lantern(root,V(q[1].X+q[2]*.13,15.5,q[1].Z),V(q[2],0,0))
 end
 local mid=(topA+topB)/2
 local board=part(root,'ShortcutBoard',mid-V(0,1.25,0),V(9,1.25,.35),{157,102,50})
 board.CFrame=CFrame.lookAt(board.CFrame.Position,board.CFrame.Position+V(0,0,1))
 -- Two hangers connect physical board to header, no floating label.
 for _,dx in {-3,3} do rod(root,'SignHanger',board.CFrame.Position+V(dx,.625,0),mid+V(dx,-.4,dx*(b.Z-a.Z)/(b.X-a.X)),.12,{62,55,42}) end
 board:SetAttribute('RouteLabel','SHORTCUT')
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Back;gui.PixelsPerStud=64;gui.LightInfluence=.15;gui.Parent=board
 local label=Instance.new('TextLabel');label.Position=UDim2.fromScale(.05,.1);label.Size=UDim2.fromScale(.9,.8);label.BackgroundTransparency=1;label.Text='SHORTCUT';label.Parent=gui
 require(game:GetService('ReplicatedStorage').UIStyle).lettering(label,60,12)
 -- Three foliage chains on each actual side-wall face; all bases >=8 studs.
 for _,q in {{a,1},{b,-1}} do for j=-1,1 do
  local x=q[1].X+q[2]*.18;local z=q[1].Z+j*.7;local low=8.5+math.abs(j)*1.8
  rod(root,'CliffRoot',V(x,low,z),V(x,21.5,z),.18,{94,72,39})
  for i=0,5 do
   local p=part(root,'IvyLeaf',V(x+q[2]*.12,low+i*1.7,z),V(.3,1.5,.85),{59,115+(i%3)*9,39},Enum.Material.Grass);p.Shape=Enum.PartType.Ball
  end
 end end
 -- Runtime shafts: real Beam attachments; offline renderer labels its planar proxy.
 for j=0,1 do
  local base=part(root,'ShaftAnchor',V(-75.65,18+j,99+j*.7),V(.05,.05,.05),leaf);base.Transparency=1
  local a0=Instance.new('Attachment');a0.Parent=base
  local a1=Instance.new('Attachment');a1.Position=V(2, -9,4);a1.Parent=base
  local beam=Instance.new('Beam');beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.1;beam.Width1=2;beam.FaceCamera=true;beam.LightEmission=.5;beam.Parent=base
 end
end
local function orchard(root,x,z,w,h,index)
 local y=assert(S.ground(root,x,z,w,w),'orchard full footprint')
 part(root,'OrchardTrunk',V(x,y+h*.31,z),V(.65,h*.62,.65),wood)
 local cy=y+h*.7
 for _,q in {{0,0,0,w},{-.17,.1,.09,w*.72},{.18,-.12,-.1,w*.68}} do
  local crown=part(root,'OrchardCrown',V(x+q[1]*w,cy+q[2]*h,z+q[3]*w),V(q[4],h*.5,q[4]),{65+index*6,142+index*4,44},Enum.Material.Grass);crown.Shape=Enum.PartType.Ball
 end
 for i=0,3 do
  local theta=i*math.pi/2+.4;local fx=x+math.sin(theta)*w*.4;local fz=z+math.cos(theta)*w*.4;local fy=cy+(i%2-.5)*h*.12
  local fruit=part(root,'OrchardApple',V(fx,fy,fz),V(.65,.7,.65),{192+index*9,49,36},Enum.Material.SmoothPlastic);fruit.Shape=Enum.PartType.Ball
  part(root,'AppleStem',V(fx,fy+.4,fz),V(.09,.14,.09),wood)
 end
end
S.kits={
 {id='HarvestBarrel',name='kenney_mini-dungeon__barrel',x=-65,z=119,size=V(2.2,3.4,2.2),fit=true},
 {id='HarvestCrate',name='kenney_survival-kit__box',x=-62,z=122,size=V(2,2,2)},
 {id='OrchardRockA',name='quaternius-nature__Rock_Medium_1',x=-73,z=118,size=V(2,1.7,2)},
 {id='OrchardRockB',name='quaternius-nature__Rock_Medium_1',x=-71,z=117,size=V(1.3,1.1,1.3)},
 {id='OrchardRockC',name='quaternius-nature__Rock_Medium_1',x=-69,z=118,size=V(1.7,1.3,1.7)},
}
function S.build(root)
 safe('mine mouth',function() mine(root) end)
 for i,t in {{-71,122,5,17},{-64.5,123,4,13},{-60,124,2.5,10}} do safe('orchard '..i,function() orchard(root,t[1],t[2],t[3],t[4],i) end) end
 safe('harvest shovel',function()
  local p=foot(root,'ShovelBlade',-65,121,V(.7,.9,.2),{139,151,151},Enum.Material.Metal)
  local y=p.CFrame.Position.Y+.45
  part(root,'ShovelHandle',V(-65,y+1,121),V(.15,2,.15),wood)
  part(root,'ShovelGrip',V(-65,y+2.1,121),V(.6,.2,.2),wood)
 end)
end
function S.spawnKits(root,kit)
 local origin=root:GetAttribute('MeadowOrigin') or Vector3.zero
 for _,g in S.kits do safe(g.id,function()
  local y=assert(S.ground(root,g.x,g.z,g.size.X,g.size.Z),'unsupported kit')
  local frame=CFrame.new(origin+V(g.x,y,g.z));local m=kit.spawn(g.name,g.island or 'meadow',frame,g.size)
  if m then
   if g.fit then assert(kit.fit(m,g.size,frame)) end
   m.Name='S2_'..g.id;m:SetAttribute('Section','S2');m.Parent=root
   for _,p in m:GetDescendants() do if p:IsA('BasePart') then p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p:SetAttribute('Section','S2') end end
  end
 end) end
end
return S
