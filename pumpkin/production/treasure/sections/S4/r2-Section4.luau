-- S4 R2: frozen R1 silhouettes plus only sign, recovery light and bank roots/moss.
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
  local light=Instance.new('PointLight');light.Color=Color3.fromRGB(255,202,132);light.Brightness=8;light.Range=30;light.Shadows=true;light.Parent=glow
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
end
return S
