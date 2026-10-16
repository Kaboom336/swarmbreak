-- S4 R4 final: R3 bridge/ravine/approach plus three render-driven finish gaps.
local S={}
local V=Vector3.new
local function part(root,name,frame,size,color,material)
 local p=Instance.new('Part');p.Name='S4_'..name;p.CFrame=frame;p.Size=size
 p.Color=Color3.fromRGB(unpack(color));p.Material=material or Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S4');p:SetAttribute('Cosmetic',true);p.Parent=root;return p
end
local function rod(root,name,a,b,width,color)
 -- Explicit basis avoids offline lookAt/engine disagreement. Long axis local Z.
 local n=(b-a).Unit;local u=V(1,0,0)
 if math.abs(n:Dot(u))>.9 then u=V(0,1,0) end
 local x=u:Cross(n).Unit;local y=n:Cross(x).Unit;local c=(a+b)/2
 return part(root,name,CFrame.new(c.X,c.Y,c.Z,x.X,y.X,n.X,x.Y,y.Y,n.Y,x.Z,y.Z,n.Z),V(width,width,(b-a).Magnitude),color,Enum.Material.Fabric)
end
function S.build(root)
 -- Remove only bridge-owned cosmetic fence; preserve all planks, guard beams and floors.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') then
  local v=p.CFrame.Position
  if (p.Name=='R5FencePost' or p.Name=='R5FenceRail') and math.abs(math.abs(v.X)-11.6)<.02 then
   if math.abs(v.Z)<=24.01 and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then p:Destroy() end
  end
 end end
 -- Four three-piece anchor groups: footing carries post; cap protects its end grain.
 for _,x in {-11.6,11.6} do
  for _,z in {-16,16} do
   local key=x..'_'..z
   part(root,'Footing'..key,CFrame.new(x,4.65,z),V(2.6,.7,2.6),{104,108,89},Enum.Material.Slate)
   part(root,'Anchor'..key,CFrame.new(x,7.5,z),V(1.15,5,1.15),{108,69,39})
   part(root,'Cap'..key,CFrame.new(x,10.12,z),V(1.4,.24,1.4),{78,50,31})
  end
  -- Seven cable segments form one load-bearing silhouette, each end touches an anchor.
  for i=0,6 do
   local function point(t)return V(x,9.5-2.6*math.sin(math.pi*t),-16+32*t) end
   rod(root,'Cable'..x..'_'..i,point(i/7),point((i+1)/7),.22,{161,135,85})
  end
 end
 -- Recovery rail follows the actual straight ramp. Feet sit on existing stone columns,
 -- outside the complete lane margin; no new walking surface or switchback.
 local tops={}
 for i=0,5 do
  local z=20+i*10;local top=-math.huge
  for _,p in root:GetDescendants() do if p:IsA('BasePart') and p.Name=='SolidMountainStone' then
   local v=p.CFrame.Position
   if math.abs(v.X+34)<=p.Size.X/2 and math.abs(v.Z-z)<=p.Size.Z/2 then top=math.max(top,v.Y+p.Size.Y/2) end
  end end
  assert(top>-36 and top<4,'recovery support missing')
  tops[i+1]=V(-34,top+6,z)
  part(root,'RecoveryFoot'..i,CFrame.new(-34,top+.25,z),V(1,.5,1),{95,101,84},Enum.Material.Slate)
  part(root,'RecoveryPost'..i,CFrame.new(-34,top+3.25,z),V(.55,5.5,.55),{103,69,42})
  part(root,'RecoveryCap'..i,CFrame.new(-34,top+6.1,z),V(.8,.2,.8),{78,50,31})
 end
 for i=1,5 do rod(root,'RecoveryCable'..i,tops[i],tops[i+1],.16,{161,135,85}) end
 -- Three purposeful cliff groups, three offset faces each; tangent to retained wall.
 for i,g in {{-46,-1},{32,-1},{57,1}} do
  for j=0,2 do
   local x=g[1]+(j-1)*3.6;local h=10+j*3;local z=g[2]*15.7
   part(root,'CliffFace'..i..'_'..j,CFrame.new(x,-5-h/2,z),V(3.6,h,.6),{88+j*6,98+j*5,89+j*3},Enum.Material.Rock)
  end
 end
 -- R2 gap 1: retire only the owner-identified old clipped BRIDGE cue at the S1 seam.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') then
  local v=p.CFrame.Position
  if p:GetAttribute('Section')=='S1' and (p.Name=='S1_SignBoard' or p.Name=='S1_SignPost') and
   math.abs(v.X-24)<.01 and math.abs(v.Z-101)<.01 and not p.CanCollide and not p.CanQuery and not p.CanTouch then p:Destroy() end
 end end
 local board=part(root,'WarningBoard',CFrame.new(12.5,8.35,16.68),V(4.6,2.2,.2),{104,65,34})
 board:SetAttribute('RouteLabel','BRIDGE\nWATCH STEP');board:SetAttribute('LabelFace','Back');board:SetAttribute('LabelSize',.6)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Back;gui.PixelsPerStud=96;gui.LightInfluence=.15;gui.Parent=board
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(.92,.88);label.Position=UDim2.fromScale(.04,.06)
 label.BackgroundTransparency=1;label.Text='BRIDGE\nWATCH STEP';label.Parent=gui
 require(game:GetService('ReplicatedStorage').UIStyle).lettering(label,80,12)
 for _,x in {10.6,14.4} do
  local bolt=part(root,'WarningBolt'..x,CFrame.new(x,9.25,16.82),V(.12,.12,.08),{176,158,105},Enum.Material.Metal);bolt.Shape=Enum.PartType.Ball
 end
 -- R2 gap 2: three five-piece rescue lamps; each bracket touches its rail post.
 for _,i in {0,2,4} do
  local v=tops[i+1];local y=v.Y-1.2;local z=v.Z
  part(root,'RescueBracket'..i,CFrame.new(-33.55,y+.2,z),V(.35,.18,.3),{66,51,36})
  part(root,'RescueBase'..i,CFrame.new(-33.1,y-.4,z),V(.7,.18,.7),{63,53,39},Enum.Material.Metal)
  local glow=part(root,'RescueGlow'..i,CFrame.new(-33.1,y,z),V(.45,.62,.45),{255,207,128},Enum.Material.Neon)
  part(root,'RescueRoof'..i,CFrame.new(-33.1,y+.4,z),V(.7,.18,.7),{63,53,39},Enum.Material.Metal)
  part(root,'RescueHandle'..i,CFrame.new(-33.1,y+.25,z),V(.12,.5,.12),{63,53,39},Enum.Material.Metal)
  local light=Instance.new('PointLight');light.Color=Color3.fromRGB(255,202,132);light.Brightness=1.2;light.Range=16;light.Shadows=false;light.Parent=glow
 end
 -- R2 gap 3: roots hold the exposed bank; moss follows those damp seams.
 for i,g in {{-46,-1},{32,-1},{57,1}} do
  local x,side=g[1],g[2];local z=side*15.25
  local a=rod(root,'RootStem'..i,V(x,-5,z),V(x-.4,-12,z),.26,{91,63,41});a.Material=Enum.Material.Wood
  local b=rod(root,'RootForkA'..i,V(x-.4,-10,z),V(x-2.8,-15,z),.20,{91,63,41});b.Material=Enum.Material.Wood
  local c=rod(root,'RootForkB'..i,V(x-.3,-9,z),V(x+2.5,-13,z),.18,{91,63,41});c.Material=Enum.Material.Wood
  for j=-1,1 do
   local moss=part(root,'BankMoss'..i..'_'..j,CFrame.new(x+j*3,-5.5,side*15.2),V(2.6,.65,.4),{65,107+j*7,46},Enum.Material.Grass);moss.Shape=Enum.PartType.Ball
  end
 end
 -- R3 gap 1. Restyle existing cosmetic deck and tells; transforms/physics of tells stay exact.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') then
  local v=p.CFrame.Position
  if p.Name=='BridgeTimberPlank' then
   local shade=math.floor((v.Z+18)/3)%4
   p.Color=Color3.fromRGB(111+shade*11,76+shade*7,44+shade*5)
   p.Size=V(p.Size.X,p.Size.Y,2.7);p.Material=Enum.Material.WoodPlanks
  elseif p.Name=='BridgeThrowTell' then
   p.Color=Color3.fromRGB(221,208,167);p.Material=Enum.Material.Wood
  elseif (p.Name=='LanternPost' or p.Name=='LanternAmber' or p.Name=='LanternCap') and
   ((math.abs(v.X-16)<.01 and math.abs(v.Z-30)<.01) or (math.abs(v.X-20)<.01 and math.abs(v.Z-42)<.01)) then
   assert(not p.CanCollide and not p.CanQuery and not p.CanTouch);p:Destroy()
  end
 end end
 for _,z in {-13.5,-4.5,4.5,13.5} do
  part(root,'CrossBeam'..z,CFrame.new(0,2.35,z),V(23,1.2,1),{79,52,32})
 end
 for _,x in {-11.6,11.6} do
  for _,z in {-8,0,8} do
   part(root,'RailPost'..x..'_'..z,CFrame.new(x,6.1,z),V(.65,3.4,.65),{95,65,40})
  end
  for i=0,7 do
   local z=-16+i*4
   rod(root,'HandRope'..x..'_'..i,V(x,7.5,z),V(x,7.5,z+4),.15,{164,143,99})
  end
 end
 -- R3 gap 2. Facings sit on exposed wall faces; lower bands grow darker.
 -- All dressing remains cosmetic, including stream overlays and splash rocks.
 for _,side in {-1,1} do
  for i,x in {-50,-38,28,40,52,64} do
   for tier=0,2 do
    local y=-9-tier*8;local depth=.5+tier*.18
    part(root,'Strata'..side..'_'..i..'_'..tier,CFrame.new(x,y,side*(16-depth/2)),V(9+(i%2),6,depth),{91-tier*14,103-tier*15,94-tier*13},Enum.Material.Rock)
   end
   local z=side*15.2
   local width=4.5+(i%3)*1.25
   part(root,'Ledge'..side..'_'..i,CFrame.new(x,-8.8,z),V(width,.65,1.6),{91,102,84},Enum.Material.Slate)
   part(root,'LedgeMoss'..side..'_'..i,CFrame.new(x,-8.4,z),V(width-.5,.15,1.4),{61,92,49},Enum.Material.Grass)
   for j=0,2 do
    local len=4+(i+j)%4
    rod(root,'Vine'..side..'_'..i..'_'..j,V(x-2+j*1.7,-8.3,side*14.3),V(x-1.6+j*1.7,-8.3-len,side*14.3),.14,{57,83,43})
    for leaf=1,3 do
     local t=leaf/4
     local p=part(root,'VineLeaf'..side..'_'..i..'_'..j..'_'..leaf,CFrame.new(x-2+j*1.7+.4*t,-8.3-len*t,side*14.3),V(.45,.65,.16),{57+leaf*3,89+(i%3)*7,42},Enum.Material.Grass);p.Shape=Enum.PartType.Ball
    end
   end
  end
 end
 for i,x in {73,76,79} do
  local rock=part(root,'StreamRock'..i,CFrame.new(x,-31.45,3),V(2,1.1,1.5),{63,77,74},Enum.Material.Slate);rock.Shape=Enum.PartType.Ball
 end
 part(root,'SpringRock',CFrame.new(78,-28.5,0),V(3.84,7,3.8),{67,82,77},Enum.Material.Rock)
 local pool=part(root,'SpringPool',CFrame.new(78,-24.97,0),V(3.84,.06,2.4),{78,153,161},Enum.Material.Glass);pool.Transparency=.18
 local fall=part(root,'Waterfall',CFrame.new(76,-28.5,0),V(.16,7,2.4),{83,157,163},Enum.Material.Glass);fall.Transparency=.2
 for i=-1,1 do
  local ribbon=part(root,'FallRibbon'..i,CFrame.new(75.9,-28.5+i*.3,i*.65),V(.04,5.8,.12),{170,207,202},Enum.Material.Glass);ribbon.Transparency=.35
 end
 for i=0,2 do part(root,'FallFoam'..i,CFrame.new(75-i*.5,-31.96,0),V(.3,.08,1.6+i*.3),{186,216,204},Enum.Material.SmoothPlastic) end
 -- R3 gap 3. Stone landing threshold on the retained deck; two player-scale S3 cages.
 for _,p in root:GetDescendants() do if p.Name=='Fix2Lane_bridge_2' or p.Name=='Fix2Lane_bridge_4' then
  local sign=if p.CFrame.Position.Z<0 then 1 else -1
  for i=-2,2 do
   local cap=part(root,'Threshold'..p.Name..'_'..i,p.CFrame*CFrame.new(i*3.4,p.Size.Y/2+.06,sign*6),V(3.25,.12,.8),{132+i%2*8,127+i%2*7,107},Enum.Material.Slate)
   cap:SetAttribute('FloorFinish',p.Name)
  end
 end end
 for _,z in {-17,17} do
  for _,x in {-12.8,12.8} do part(root,'Abutment'..x..'_'..z,CFrame.new(x,4.65,z),V(1.5,.7,1.5),{104,110,94},Enum.Material.Rock) end
 end
 for i,v in {V(16,.4,30),V(20,.4,42)} do
  part(root,'ApproachFoot'..i,CFrame.new(v+V(0,.18,0)),V(1.4,.36,1.4),{99,104,88},Enum.Material.Slate)
  part(root,'ApproachPost'..i,CFrame.new(v+V(0,2.3,0)),V(.45,4.25,.45),{91,62,39})
  local center=v+V(0,4.7,0);local iron={48,44,39}
  local glow=part(root,'ApproachGlow'..i,CFrame.new(center),V(.55,.75,.55),{240,201,137},Enum.Material.Neon)
  for _,s in {-1,1} do part(root,'ApproachCap'..i..'_'..s,CFrame.new(center+V(0,s*.5,0)),V(1.1,.2,1.1),iron,Enum.Material.Metal) end
  for _,sx in {-1,1} do for _,sz in {-1,1} do part(root,'ApproachBar'..i..'_'..sx..'_'..sz,CFrame.new(center+V(sx*.5,0,sz*.5)),V(.1,.8,.1),iron,Enum.Material.Metal) end end
  local light=Instance.new('PointLight');light.Color=Color3.fromRGB(255,202,132);light.Brightness=1.1;light.Range=16;light.Shadows=false;light.Parent=glow
 end
 -- R4 joint inlays touch the retained collision deck and sit below the planks.
 local floor=assert(root:FindFirstChild('Fix2Lane_bridge_3'))
 for i=-5,5 do
  local joint=part(root,'DeckJoint'..i,floor.CFrame*CFrame.new(0,floor.Size.Y/2+.02,i*3),V(17.2,.04,.28),{49,36,25},Enum.Material.Wood)
  joint:SetAttribute('FloorFinish',floor.Name)
 end
 -- Owner's live-safe ceiling applies to retained lights too. Keep S2/S3 sources verbatim.
 for _,light in root:GetDescendants() do
  if light:IsA('PointLight') then light.Brightness=math.min(light.Brightness,1.5);light.Range=math.min(light.Range,18);light.Shadows=false
  elseif light:IsA('SpotLight') then light.Shadows=false end
 end
end
return S
