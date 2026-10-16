-- S1 presentation only. KitLibrary uses bottom-centre pivots; never alter physics.

-- Bound synchronous construction/scans; offline builders have no task.
local yieldWork = 0
local yieldDeadline = os.clock() + .01
local function yieldBuild()
 yieldWork += 1
 if yieldWork % 300 == 0 and os.clock() >= yieldDeadline then
  if task then task.wait() end
  yieldDeadline = os.clock() + .01
 end
end
local S = {}
local V = Vector3.new
S.bounds = {-58,58,98,156}
local floorCache=setmetatable({},{__mode="k"})
S.kits = {
 {id="WestTree",name="quaternius-nature__CommonTree_1",x=-50,z=138,size=V(10,17,10)},
 {id="EastTree",name="quaternius-nature__CommonTree_1",x=38,z=114,size=V(10,17,10)},
 {id="WestBush",name="quaternius-nature__Bush_Common",x=-47,z=146,size=V(4,3,4)},
 {id="EastBush",name="quaternius-nature__Bush_Common",x=36,z=110,size=V(4.5,5,3),lift=.14},
 {id="ArrivalFlowersA",name="quaternius-nature__Flower_3_Group",x=-17.5,z=121.7,size=V(1.5,2.5,1.5),frame=true,lift=.14},
 {id="ArrivalWaterBarrel",name="kenney_mini-dungeon__barrel",x=-17.8,z=124.5,size=V(2.4,3.4,2.4),frame=true,fit=true},
 {id="EastWaterBarrel",name="kenney_mini-dungeon__barrel",x=35,z=106,size=V(2.8,3.4,2.8),fit=true},
 {id="ArrivalCrate",name="kenney_survival-kit__box",x=-20.5,z=118,size=V(2,2,2),frame=true},
 {id="SupplyCrate",name="kenney_survival-kit__box-large",x=38,z=106,size=V(3,2.5,2.5)},
 {id="SeedChest",name="kenney_mini-dungeon__chest",x=42,z=117,size=V(3,2.4,2.5)},
 {id="EastRock",name="quaternius-nature__Rock_Medium_1",x=46,z=119,size=V(3,2.5,3)},
 {id="WestFence",name="kenney_nature-kit__fence_simple",x=-42,z=142,size=V(9,3,1)},
 {id="EastFence",name="kenney_nature-kit__fence_simple",x=37,z=103,size=V(8,3,1)},
 {id="EastFenceCorner",name="kenney_nature-kit__fence_corner",x=44,z=103,size=V(3,3,3)},
 {id="WestLog",name="kenney_nature-kit__log",x=-49,z=139,size=V(4,1.6,3)},
 {id="WestStump",name="kenney_nature-kit__stump_round",x=-52,z=139,size=V(2,1.8,2)},
 {id="CliffBaseRockA",name="quaternius-nature__Rock_Medium_1",x=-80,z=128,size=V(4,3,4),fit=true},
 {id="CliffBaseRockB",name="quaternius-nature__Rock_Medium_1",x=-75,z=128,size=V(3,2.5,3),fit=true},
}
for _,side in {-1,1} do
 for i=1,3 do table.insert(S.kits,{id="BedFlower"..side.."_"..i,name="quaternius-nature__Flower_3_Group",x=if side==-1 then -(38+i*1.6) else 29.5+i,z=if side==-1 then 145+(i%2)*2 else 109,size=if side==-1 then V(1.7,1.8,1.7) else V(.9,2.5,.9),lift=.14}) end
 for i=1,3 do table.insert(S.kits,{id="MouthFlower"..side.."_"..i,name="kenney_nature-kit__flower_yellowA",x=if side==-1 then -56+i*.7 else 45.5+i*.7,z=if side==-1 then 126.5+i*.7 else 112.5+i*.7,size=V(1.3,1.5,1.3)}) end
end
-- R3: arrival shoulder clusters, measured in the exact player frame.
for _,side in {-1,1} do
 for _,g in {
  {id="FrameTree",name="quaternius-nature__CommonTree_1",x=20.5,z=126,size=V(7,24,7)},
  {id="FrameBush",name="quaternius-nature__Bush_Common",x=19.5,z=120,size=V(7,7,7)},
  {id="FrameBarrel",name="kenney_mini-dungeon__barrel",x=18.2,z=128,size=V(3,4,3)},
  {id="FrameCrate",name="kenney_survival-kit__box",x=21.5,z=129,size=V(3.5,3.5,3.5)},
 } do
  g.id=g.id..side;g.x*=side;g.frame=true;g.fit=true;table.insert(S.kits,g)
 end
end
function S.inside(p)
 return p.X>=-58 and p.X<=58 and p.Z>=98 and p.Z<=156 and p.Y>=-3 and p.Y<=22
end
-- Horizontal floor support under all footprint corners. No visual moss/grass proxy.
function S.ground(root,x,z,w,d)
 -- Inputs and returned height are island-local, including late KitSwap calls.
 local localize=CFrame.new(-(root:GetAttribute("MeadowOrigin") or Vector3.zero))
 local floors={}
 if not floorCache[root] then
  local all={};for _,p in root:GetDescendants() do yieldBuild(); if p:IsA("BasePart") and p.CanCollide and math.abs(p.CFrame.UpVector.Y)>0.9999 then
   local top=(localize*p.CFrame).Position.Y+p.Size.Y/2;if top<=1 and top>=-3 then table.insert(all,p) end
  end end;floorCache[root]=all
 end
 for _,p in floorCache[root] do yieldBuild();
  local cf=localize*p.CFrame
  local q=cf:PointToObjectSpace(V(x,cf.Position.Y,z))
  local top=cf.Position.Y+p.Size.Y/2
  if top<=1 and top>=-3 and math.abs(q.X)<=p.Size.X/2+w/2 and math.abs(q.Z)<=p.Size.Z/2+d/2 then table.insert(floors,p) end
 end
 local lowest,highest=math.huge,-math.huge
 for ix=0,math.ceil(w) do yieldBuild(); for iz=0,math.ceil(d) do
  local px,pz=x-w/2+w*ix/math.max(1,math.ceil(w)),z-d/2+d*iz/math.max(1,math.ceil(d))
  local top=-math.huge
  for _,p in floors do
   local cf=localize*p.CFrame
   local q=cf:PointToObjectSpace(V(px,cf.Position.Y,pz))
   if math.abs(q.X)<=p.Size.X/2+.001 and math.abs(q.Z)<=p.Size.Z/2+.001 then top=math.max(top,cf.Position.Y+p.Size.Y/2) end
  end
  if top==-math.huge then return nil end
  lowest=math.min(lowest,top);highest=math.max(highest,top)
 end end
 if highest-lowest>.15 then return nil end
 return highest
end
local function part(root,name,x,z,size,color,base)
 yieldBuild()
 local y=base or S.ground(root,x,z,size.X,size.Z)
 local missing=y==nil
 assert(not missing,"S1 unsupported "..name.." at "..x..","..z)
 local p=Instance.new("Part");p.Name="S1_"..name;p.Size=size;p.CFrame=CFrame.new(x,y+size.Y/2,z)
 p.Color=Color3.fromRGB(unpack(color));p.Material=Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute("Section","S1");p:SetAttribute("SupportY",y);p.Parent=root
 p:SetAttribute("S1Coverage","Props");p:AddTag("S1FrameProp")
 if name:find("^Arrival") then p:SetAttribute("S1ApronBorder",true) end
 p:SetAttribute("MissingSupport",missing)
 return p
end
local function foreground(root)
 local wood={139,87,43}
 for _,side in {-1,1} do
  -- 8 x 3 x 1.5 planter, six large flowers; outer edge of the 32-stud lane.
  local x,z=side*20,122
  local y=assert(S.ground(root,x,z,8,3),"R3 bed support")
  local soil=part(root,"ArrivalR3Soil",x,z,V(7.4,1.2,2.4),{97,60,31},y)
  soil.Material=Enum.Material.Ground
  for _,dz in {-1.35,1.35} do part(root,"ArrivalR3BedRail",x,z+dz,V(8,1.5,.3),wood,y) end
  for _,dx in {-3.85,3.85} do part(root,"ArrivalR3BedEnd",x+dx,z,V(.3,1.5,2.4),wood,y) end
  for i=0,5 do
   local fx=x-3.1+i*1.24;local h=2.2+(i%2)*.5
   part(root,"ArrivalR3FlowerStem",fx,z,V(.18,h,.18),{51,123,35},y+1.2)
   local cy=y+1.2+h
   local seed=part(root,"ArrivalR3FlowerSeed",fx,z,V(.65,.65,.3),{110,59,22},cy-.325);seed.Shape=Enum.PartType.Ball
   for j=0,5 do
    local a=j*math.pi/3
    local petal=part(root,"ArrivalR3FlowerPetal",fx+math.sin(a)*.48,z,V(.6,.6,.25),{255,190+(i%2)*25,38},cy+math.cos(a)*.48-.3)
    petal.Shape=Enum.PartType.Ball
   end
  end
  local lx,lz=side*17,134
  local base=assert(S.ground(root,lx,lz,.6,.6))
  part(root,"ArrivalR3LanternPost",lx,lz,V(.6,6.5,.6),wood,base)
  part(root,"ArrivalR3LanternBase",lx,lz,V(1.2,.2,1.2),wood,base+6.5)
  local core=part(root,"ArrivalR3LanternGlow",lx,lz,V(.85,1.1,.85),{255,199,78},base+6.7);core.Material=Enum.Material.Neon
  part(root,"ArrivalR3LanternRoof",lx,lz,V(1.3,.2,1.3),wood,base+7.8)
 end
 -- Eight-stud handcart parallel to the corridor, recognizable from arrival.
 local x,z=18.5,122
 local y=assert(S.ground(root,x,z,4,8),"R3 cart support")
 for _,dx in {-1.7,1.7} do for _,dz in {-2.3,2.3} do
  local w=part(root,"ArrivalR3CartWheel",x+dx,z+dz,V(.4,1.5,1.5),{60,46,30},y);w.Shape=Enum.PartType.Cylinder
 end end
 part(root,"ArrivalR3CartDeck",x,z,V(3.8,.4,6),wood,y+1.5)
 for _,dx in {-1.7,1.7} do part(root,"ArrivalR3CartSide",x+dx,z,V(.4,1.4,6),wood,y+1.9) end
 for _,dz in {-2.8,2.8} do part(root,"ArrivalR3CartEnd",x,z+dz,V(3,1.4,.4),wood,y+1.9) end
 for _,dx in {-1.3,1.3} do part(root,"ArrivalR3CartHandle",x+dx,z+3.5,V(.25,.25,1),wood,y+1.6) end
 for _,dz in {-1.5,1.2} do
  local sack=part(root,"ArrivalR3CargoSack",x,z+dz,V(2.4,2.8,2.2),{202,177,121},y+1.9);sack.Shape=Enum.PartType.Ball
  part(root,"ArrivalR3CargoTie",x,z+dz,V(.6,.3,.6),wood,y+4.7)
 end
end
local function cliffGarden(root)
 -- Hang vines on exposed east faces of the left cliff, facing arrival.
 local faces={}
 for _,p in root:GetDescendants() do yieldBuild();
  if p:IsA("BasePart") and p.Name=="TunnelHillEarth" then
   local v=p.CFrame.Position
   if v.X>=-100 and v.X<=-25 and v.Z>=30 and v.Z<=87 and v.Y-p.Size.Y/2<1 and p.Size.Y>15 then
    local face=v.X+p.Size.X/2;local key=tostring(v.Z)
    if not faces[key] or face>faces[key].face then faces[key]={z=v.Z,face=face,top=v.Y+p.Size.Y/2} end
   end
  end
 end
 for _,f in faces do
  local base=10
  local h=math.min(18,f.top-base-.7)
  if h<2 then continue end
  local vine=part(root,"CliffVine",f.face+.06,f.z,V(.12,h,.22),{53,102,36},base)
  if base==10 then vine:SetAttribute("S1Overhead",true) end
  for i=1,math.floor(h/1.2) do
   local leaf=part(root,"CliffMossLeaf",f.face+.14,f.z+(if i%2==0 then .7 else -.7),V(.28,1.4,2),{65,126+(i%3)*9,39},base+i*1.2-.7)
   if base==10 then leaf:SetAttribute("S1Overhead",true) end
   leaf.Shape=Enum.PartType.Ball;leaf.Material=Enum.Material.Grass
  end
 end
end
local function story(root)
 local wood={134,85,43}
 local function lamp(x,z)
  local post=part(root,"ArrivalLampPost",x,z,V(.65,4,.65),wood)
  local y=post.CFrame.Position.Y+2
  part(root,"ArrivalLampBracket",x+.9875,z,V(1.325,.22,.3),wood,y-.22)
  local base=part(root,"ArrivalLampBase",x+1.15,z,V(1,.18,.8),{65,51,35},y)
  local core=part(root,"ArrivalLampGlow",x+1.15,z,V(.6,.9,.5),{255,198,72},base.CFrame.Position.Y+.09)
  core.Material=Enum.Material.Neon
  part(root,"ArrivalLampRoof",x+1.15,z,V(1,.2,.8),wood,core.CFrame.Position.Y+.45)
 end
 lamp(-18,118);lamp(18,147)
 local shrub=part(root,"ArrivalShrub",-20,122,V(3.1,3.6,2.5),{75,154,45},assert(S.ground(root,-20,122,3.1,2.5))+.14)
 shrub.Shape=Enum.PartType.Ball;shrub.Material=Enum.Material.Grass
 -- Pruned orchard trees occupy small clear shoulders; crowns frame arrival
 -- inside those same footprints instead of overhanging the routes.
 for _,t in {{-23,118,3.4,4,3,true},{31,107,4,5,3,false}} do
  local prefix=if t[6] then "ArrivalOrchard" else "Orchard"
  local base=assert(S.ground(root,t[1],t[2],.45,.45),"orchard foot")
  part(root,prefix.."Trunk",t[1],t[2],V(.45,3.2,.45),wood,base)
  local crown=part(root,prefix.."Crown",t[1],t[2],V(t[3],t[4],t[5]),{72,153,46},base+3.2)
  crown.Shape=Enum.PartType.Ball;crown.Material=Enum.Material.Grass
 end
 -- Five-petal sunflowers face arrival; stems start at the bed's soil top.
 for _,b in {{-17.2,121.1,3,true},{-17.6,122.7,2.7,true},{30,110.3,3.4,false},{31.5,110.5,4,false},{33,111,3.1,false}} do
  local x,z,h=b[1],b[2],b[3]
  local prefix=if b[4] then "ArrivalSunflower" else "Sunflower"
  local y=assert(S.ground(root,x,z,.9,.9),"sunflower "..x..","..z)+.14
  part(root,prefix.."Stem",x,z,V(.13,h,.13),{65,119,35},y)
  local head=y+h+.2
  local center=part(root,prefix.."Seed",x,z,V(.46,.46,.22),{105,63,24},head-.23);center.Shape=Enum.PartType.Ball
  for i=0,4 do
   local a=i*math.pi*2/5
   local p=part(root,prefix.."Petal",x+math.sin(a)*.46,z,V(.48,.48,.18),{255,197,45},head+math.cos(a)*.46-.24)
   p.Shape=Enum.PartType.Ball
  end
 end
 -- Tool station beside the watering barrel, all feet on the same apron shoulder.
 local x,z=-19,119.4
 local y=assert(S.ground(root,x,z,.7,.5))
 local blade=part(root,"ArrivalShovelBlade",x,z,V(.65,.85,.18),{155,165,164},y)
 part(root,"ArrivalShovelHandle",x,z,V(.16,2,.16),wood,y+.85)
 part(root,"ArrivalShovelGrip",x,z,V(.55,.2,.2),wood,y+2.85)
 local function sack(prefix,sx,sz,base)
  local body=part(root,prefix.."Sack",sx,sz,V(1.15,1.5,1),{198,177,127},base);body.Shape=Enum.PartType.Ball
  part(root,prefix.."SackTie",sx,sz,V(.35,.25,.35),{132,98,55},base+1.5)
 end
 sack("Arrival",-20,119.6,assert(S.ground(root,-20,119.6,1.15,1)))
 -- A four-wheel seed cart, with its cargo supported by the deck.
 x,z=31,114
 y=assert(S.ground(root,x,z,4,3),"cart footprint")
 for _,dx in {-1.75,1.75} do for _,dz in {-.65,.65} do
  local w=part(root,"CartWheel",x+dx,z+dz,V(.3,1.1,1.1),{65,52,38},y);w.Shape=Enum.PartType.Cylinder
 end end
 part(root,"CartDeck",x,z,V(3.8,.3,2.1),wood,y+1.1)
 for _,dz in {-.9,.9} do part(root,"CartSide",x,z+dz,V(3.8,.7,.3),wood,y+1.4) end
 for _,dx in {-1.75,1.75} do part(root,"CartEnd",x+dx,z,V(.3,.7,1.5),wood,y+1.4) end
 for _,dx in {-1.3,1.3} do part(root,"CartHandle",x+dx,z+1.7,V(.2,.25,1.3),wood,y+1.15) end
 sack("Cart",x+.7,z,y+1.4)
 part(root,"CartSeedBox",x-.8,z,V(1.2,1,1.3),{160,104,51},y+1.4)
 -- Timber frame at the existing south mine mouth; no new route or dark facade.
 local a,b=V(-75.87,0,98),V(-52.15,0,88)
 for _,v in {a,b} do
  local base=assert(S.ground(root,v.X,v.Z,.16,1),"mine foot")
  part(root,"MinePost",v.X,v.Z,V(.16,10-base,1),wood,base)
  local glow=part(root,"MineLanternGlow",v.X,v.Z,V(.16,1,1),{255,195,65},8);glow.Material=Enum.Material.Neon
  part(root,"MineLanternCap",v.X,v.Z,V(.16,.2,1),wood,9)
 end
 local mid=(a+b)/2
 local beam=part(root,"MineHeader",mid.X,mid.Z,V(1.4,1.4,(a-b).Magnitude+1),wood,10)
 beam.CFrame=CFrame.lookAt(V(mid.X,10.7,mid.Z),V(a.X,10.7,a.Z))
 beam:SetAttribute("S1Overhead",true)
end
function S.build(root)
 -- The old opaque upright disc blocked the required arrival camera entirely.
 -- Only nonphysical artwork rotates; the existing return trigger stays put.
 local portalTurn=CFrame.Angles(math.pi/2,0,0)
 for _,p in root:GetDescendants() do yieldBuild(); if p:IsA("BasePart") and not p.CanCollide and (p.Name=="PortalStone" or p.Name=="CyanPortalField" or p.Name=="ContinuousCyanRim" or p.Name=="PortalSpiral") then
  if math.abs(p.CFrame.Position.X)<20 and math.abs(p.CFrame.Position.Z-136)<8 then
   local v=p.CFrame.Position
   local height=if p.Name=="PortalStone" then .12 elseif p.Name=="CyanPortalField" then .18 elseif p.Name=="ContinuousCyanRim" then .22 else .24
   if p.Name=="PortalStone" then p.Size=V(p.Size.X,p.Size.Y,.6) end
   p.CFrame=CFrame.new(v.X*.55,height,136+(v.Y-11)*.55)*portalTurn*p.CFrame.Rotation
   p.Size=V(p.Size.X*.55,p.Size.Y*.55,p.Size.Z)
   p:SetAttribute("S1PortalArt",true);p:SetAttribute("S1Coverage","Portal");p:AddTag("S1PortalVisual")
  end
 end end
 for _,p in root:GetDescendants() do yieldBuild(); if p:IsA("BasePart") and p.Name=="StonePathEdge" and not p.CanCollide and not p:GetAttribute("WalkableLaneFloor") then
  local v=p.CFrame.Position
  if v.X*v.X+(v.Z-136)^2<11^2 and v.Y<1.3 then p.Transparency=1;p:SetAttribute("S1Cleared",true) end
 end end
 for _,p in root:GetDescendants() do yieldBuild(); if p:IsA("BasePart") and S.inside(p.CFrame.Position) and not p.CanCollide and not p:GetAttribute("WalkableLaneFloor") then
  if p.Name:find("Flower") or p.Name:find("Bush") or p.Name:find("Mushroom") or p.Name:find("Pebble") or p.Name:find("GrassTuft") then
   p.Transparency=1;p:SetAttribute("MeadowPolishCleared",true);p:SetAttribute("S1Cleared",true)
  end
 end end
 for _,side in {-1,1} do
  local bz=if side==-1 then 146 else 110
  local bx=if side==-1 then -45 else 34
  local depth=if side==-1 then 3 else 2
  local width=if side==-1 then 14 else 10
  local fenceX=if side==-1 then -53 else 37
  -- Long borders and short end caps meet, not interpenetrate.
  local soil=part(root,"BedSoil",bx,bz,V(width-.5,.14,depth*2-.5),{102,66,36});soil.Material=Enum.Material.Ground
  for _,dz in {-depth,depth} do part(root,"BedRail",bx,bz+dz,V(width,.65,.5),{128,81,42}) end
  for _,dx in {-width/2+.25,width/2-.25} do part(root,"BedEnd",bx+dx,bz,V(.5,.65,depth*2-.5),{128,81,42}) end
  for _,z in {bz-depth,bz+depth} do part(root,"GardenPost",fenceX,z,V(.7,3,.7),{114,70,37}) end
  local fy=assert(S.ground(root,fenceX,bz,.35,depth*2-.7),"unsupported fence span")
  for _,y in {1.1,2.2} do part(root,"GardenRail",fenceX,bz,V(.35,.3,depth*2-.7),{156,105,53},fy+y) end
  local lx,lz=if side==-1 then -40 else 37,if side==-1 then 151 else 110
  local post=part(root,"LanternPost",lx,lz,V(.65,4,.65),{108,67,37})
  local cap=part(root,"LanternBase",lx,lz,V(1.3,.2,1.3),{87,59,35},post.CFrame.Position.Y+2)
  local core=part(root,"LanternGlass",lx,lz,V(.85,1,.85),{255,205,108},cap.CFrame.Position.Y+.1)
  core.Material=Enum.Material.Neon
  part(root,"LanternRoof",lx,lz,V(1.35,.25,1.35),{87,59,35},core.CFrame.Position.Y+.5)
  local light=Instance.new("PointLight");light.Color=core.Color;light.Range=9;light.Brightness=.8;light.Parent=core
 end
 -- Low garden border on the OUTER apron shoulder, outside a 32-stud central
 -- corridor. Apron floor/tags and every physical/query object remain intact.
 local soil=part(root,"ArrivalSoil",-19,122,V(5.5,.14,2.5),{102,66,36});soil.Material=Enum.Material.Ground
 for _,z in {120.5,123.5} do part(root,"ArrivalRail",-19,z,V(6,.55,.4),{142,92,45}) end
 for _,x in {-21.8,-16.2} do part(root,"ArrivalEnd",x,122,V(.4,.55,2.6),{142,92,45}) end
 story(root)
 foreground(root)
 cliffGarden(root)
 for _,sign in {{-49,134,"WEST",-1},{24,101,"BRIDGE",0},{36,118,"RIDGE",1}} do
  local post=part(root,"SignPost",sign[1],sign[2],V(.65,4,.25),{117,76,40})
  local board=part(root,"SignBoard",sign[1],sign[2],V(7,1.5,.4),{143,94,46},post.CFrame.Position.Y+1.25)
  board:SetAttribute("RouteLabel",sign[3])
  local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.PixelsPerStud=36;gui.Parent=board
  local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text=sign[3];text.TextScaled=true;text.Font=Enum.Font.GothamBold;text.TextColor3=Color3.fromRGB(255,239,185);text.Parent=gui
 end
end
function S.laneClear(parts,lanes,plan,apronBorder)
 if #parts==1 and parts[1]:GetAttribute("S1Overhead")==true then
  return parts[1].CFrame.Position.Y-parts[1].Size.Y/2>=10,"mine header clearance"
 end
 if not apronBorder then return plan.laneClear(parts,lanes) end
 local filtered={}
 -- The R3 brief reserves the central 32 studs of the 48-stud apron.
 -- Art wholly inside that apron shares this same rule across route samples;
 -- all route buffers outside it (and elevated decks) remain protected.
 for _,lane in lanes do yieldBuild();
  local v=lane.CFrame.Position;local ext=V(0,0,0)
  for _,a in {lane.CFrame.RightVector*lane.Size.X/2,lane.CFrame.UpVector*lane.Size.Y/2,lane.CFrame.LookVector*lane.Size.Z/2} do
   ext+=V(math.abs(a.X),math.abs(a.Y),math.abs(a.Z))
  end
  local inApron=true
  for _,p in parts do
   local q=p.CFrame.Position;local half=p.Size/2
   if math.abs(q.X)+half.X>24.001 or q.Z-half.Z<115.999 or q.Z+half.Z>156.001 then inApron=false end
  end
  local apron=inApron and v.Y+ext.Y<=1
  if lane.Name~="PortalPad" and lane.Name~="ProtectedPortalApron" and not apron then table.insert(filtered,lane) end
 end
 for _,p in parts do if p:IsA("BasePart") then
  if math.abs(p.CFrame.Position.X)-p.Size.X/2<15.999 then return false,"32-stud plaza corridor" end
 end end
 return plan.laneClear(parts,filtered)
end
function S.spawnKits(root,kit)
 local count=0
 local origin=root:GetAttribute("MeadowOrigin") or Vector3.zero
 for _,g in S.kits do
  local y=assert(S.ground(root,g.x,g.z,g.size.X,g.size.Z),"S1 kit lacks support: "..g.id)+(g.lift or 0)
  local frame=CFrame.new(origin+V(g.x,y,g.z))
  local m=kit.spawn(g.name,g.island or "meadow",frame,g.size)
  if m and g.fit then
   local ok,reason=kit.fit(m,g.size,frame);assert(ok,"S1 fitted barrel: "..tostring(reason))
  end
  if m then
   m.Name="S1_"..g.id;m:SetAttribute("Section","S1");m:SetAttribute("SupportY",y);m.Parent=root;count+=1
   for _,p in m:GetDescendants() do yieldBuild(); if p:IsA("BasePart") then p:SetAttribute("S1Coverage","Props");p:AddTag("S1FrameProp") end end
  end
 end
 -- Use the licensed mine timber assets as fitted skins on supported carriers.
 for _,p in root:GetDescendants() do yieldBuild();
  if p:IsA("BasePart") and (p.Name=="S1_MinePost" or p.Name=="S1_MineHeader") then
   local name=if p.Name=="S1_MinePost" then "wood-support" else "wood-structure"
   local cf=p.CFrame*CFrame.new(0,-p.Size.Y/2,0)
   local m=kit.spawn("kenney_mini-dungeon__"..name,"cave",cf,p.Size)
   if m then
    assert(kit.fit(m,p.Size,cf));m.Name="S1_MineKit_"..name;m.Parent=root;p.Transparency=1
    for _,q in m:GetDescendants() do yieldBuild(); if q:IsA("BasePart") then q:SetAttribute("S1Coverage","Props");q:AddTag("S1FrameProp") end end
   end
  end
 end
 root:SetAttribute("S1KitsLoaded",count);root:SetAttribute("S1KitsExpected",#S.kits)
end
-- Shared map dressing audit, including the late KitSwap pass. The old apron
-- exception allowed art right up to (and inside) the authored lane footprint.
function S.clearProps(root)
 local lanes={}
 local origin=root:GetAttribute("MeadowOrigin") or Vector3.zero
 local court=require(script.Parent.Gameplay).PvpCourt
 local outsmart=require(script.Parent.Outsmart)
 for _,p in root:GetDescendants() do yieldBuild();
  if p:IsA("BasePart") and p:GetAttribute("WalkableLaneFloor")==true then
   local cf,h=p.CFrame,p.Size/2
   local e=Vector3.zero
   for _,a in {cf.RightVector*h.X,cf.UpVector*h.Y,cf.LookVector*h.Z} do e+=V(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
   local v=cf.Position
   table.insert(lanes,{cf=cf,w=p.Size.X,d=p.Size.Z,minX=v.X-e.X-1,maxX=v.X+e.X+1,minZ=v.Z-e.Z-1,maxZ=v.Z+e.Z+1,minY=v.Y-e.Y,maxY=v.Y+e.Y+7})
  end
 end
 local removed={}
 for _,p in root:GetDescendants() do yieldBuild();
  if not p:IsA("BasePart") or p:GetAttribute("WalkableLaneFloor") or p:GetAttribute("S1PortalArt") or p:GetAttribute("GameplayCover") then continue end
  local category=p:GetAttribute("MeadowV4Category") or ""
  local dressing=p:GetAttribute("Section")=="S1" or p:HasTag("S1FrameProp")
   or p:FindFirstAncestor("KitDressing")~=nil
   or table.find({"tree","bush","flower","fence","lantern","light","grass","pebble","mushroom"},category)~=nil
  if not dressing then continue end
    p.CanCollide,p.CanQuery,p.CanTouch=false,false,false
    p:SetAttribute("Cosmetic",true)
  local cf,h=p.CFrame,p.Size/2
  local e=Vector3.zero
  for _,a in {cf.RightVector*h.X,cf.UpVector*h.Y,cf.LookVector*h.Z} do e+=V(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
  local v=cf.Position
  local minX,maxX,minZ,maxZ=v.X-e.X,v.X+e.X,v.Z-e.Z,v.Z+e.Z
  local function overlaps(frame,width,depth)
   local loX,hiX,loZ,hiZ=math.huge,-math.huge,math.huge,-math.huge
   for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
    local q=frame:PointToObjectSpace(cf:PointToWorldSpace(h*V(x,y,z)))
    loX=math.min(loX,q.X);hiX=math.max(hiX,q.X);loZ=math.min(loZ,q.Z);hiZ=math.max(hiZ,q.Z)
   end end end
   return hiX>-width/2-1 and loX<width/2+1 and hiZ>-depth/2-1 and loZ<depth/2+1
  end
  local blocked=v.Y+e.Y>origin.Y+court.y-.1 and v.Y-e.Y<origin.Y+court.y+8 and overlaps(CFrame.new(origin+V(court.x,court.y,-court.z)),18,18)
  if v.Y+e.Y>origin.Y+outsmart.Bell.Y-.1 and v.Y-e.Y<origin.Y+outsmart.Bell.Y+8
   and overlaps(CFrame.new(origin+outsmart.Bell),outsmart.BellClearSize,outsmart.BellClearSize) then blocked=true end
  if not blocked then
   for _,lane in lanes do yieldBuild();
    if v.Y+e.Y>lane.minY and v.Y-e.Y<lane.maxY
     and maxX>lane.minX and minX<lane.maxX and maxZ>lane.minZ and minZ<lane.maxZ
     and overlaps(lane.cf,lane.w,lane.d) then blocked=true;break end
   end
  end
  if blocked then
   local target=p
   -- Remove a complete late kit assembly, not isolated mesh sections.
   local parent=p.Parent
   while parent and parent~=root do
    if parent:IsA("Model") then target=parent end
    parent=parent.Parent
   end
   removed[target]=true
  end
 end
 local names={}
 for p in removed do table.insert(names,p.Name);p:Destroy() end
 table.sort(names)
 local previous=root:GetAttribute("PvpMapClearedProps") or ""
 root:SetAttribute("PvpMapClearedProps",previous..(#names>0 and table.concat(names,",").."," or ""))
 root:SetAttribute("PvpMapLaneMargin",1)
 return names
end
return S
