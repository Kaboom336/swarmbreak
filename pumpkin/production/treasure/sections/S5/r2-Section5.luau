-- S5 R2: three recorded gaps only; R1 silhouette parts remain exact.
local S={}
local V=Vector3.new
local work=0
local function yieldBuild()
 work+=1;if work%300==0 then if task then task.wait() end end
end
local function part(root,name,frame,size,color)
 yieldBuild();local p=Instance.new('Part');p.Name='S5_'..name;p.CFrame=frame;p.Size=size
 p.Color=Color3.fromRGB(unpack(color));p.Material=Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S5');p:SetAttribute('Cosmetic',true);p.Parent=root;return p
end
local function beam(root,name,a,b,width,color)
 local n=(b-a).Unit;local u=V(1,0,0);if math.abs(n:Dot(u))>.9 then u=V(0,1,0) end
 local x=u:Cross(n).Unit;local y=n:Cross(x).Unit;local c=(a+b)/2
 return part(root,name,CFrame.new(c.X,c.Y,c.Z,x.X,y.X,n.X,x.Y,y.Y,n.Y,x.Z,y.Z,n.Z),V(width,width,(b-a).Magnitude),color)
end
local function sign(root,name,frame,text)
 local board=part(root,name..'Board',frame,V(3.0,1.8,.18),{119,79,43})
 board:SetAttribute('RouteLabel',text);board:SetAttribute('LabelFace','Front');board:SetAttribute('LabelSize',.55)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=96;gui.LightInfluence=.15;gui.Parent=board
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(.88,.82);label.Position=UDim2.fromScale(.06,.09)
 label.BackgroundTransparency=1;label.Text=text;label.Parent=gui
 require(game:GetService('ReplicatedStorage').UIStyle).lettering(label,80,12)
 for _,x in {-1.28,1.28} do
  local p=part(root,name..'Bolt'..x,frame*CFrame.new(x,.65,-.13),V(.12,.12,.08),{190,169,111})
  p.Material=Enum.Material.Metal;p.Shape=Enum.PartType.Ball
 end
end
function S.build(root)
 for _,p in root:GetDescendants() do yieldBuild();if p:IsA('BasePart') then
  local v=p.CFrame.Position
  local owned=v.X>90 and v.X<130 and v.Z>-8 and v.Z<45
  if owned and (p.Name=='Round4StackedRock' or p.Name=='Round4PaleRockTop')
   and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then p:Destroy()
  elseif p.Name=='Round4JumpPalePad' and v.X>140 and v.X<156 then
   assert(not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('LaneId') and #p:GetTags()==0)
   p.Color=Color3.fromRGB(205,207,181);p.Material=Enum.Material.Slate
  end
 end end
 local points={}
 for i=0,4 do
  local z=2+i*8;local top=-math.huge
  for _,p in root:GetDescendants() do yieldBuild();if p:IsA('BasePart') and p.Name=='SolidMountainStone' then
   local v=p.CFrame.Position;if math.abs(v.X-98)<p.Size.X/2 and math.abs(v.Z-z)<p.Size.Z/2 then top=math.max(top,v.Y+p.Size.Y/2) end
  end end
  assert(top>-3 and top<30,'ridge rail support missing')
  part(root,'RailFoot'..i,CFrame.new(98,top+.15,z),V(.8,.3,.8),{95,100,79}).Material=Enum.Material.Slate
  part(root,'RailPost'..i,CFrame.new(98,top+1.7,z),V(.5,2.8,.5),{116,78,45})
  part(root,'RailCap'..i,CFrame.new(98,top+3.2,z),V(.75,.2,.75),{89,59,37})
  points[i+1]=V(98,top+2.8,z)
 end
 for i=1,4 do beam(root,'SafeRail'..i,points[i],points[i+1],.24,{139,101,62}) end
 -- R2 gap 1: board sits directly on the first retained cap (top Y5.3).
 sign(root,'Walk',CFrame.new(98,6.2,2),'WALK')
 -- R2 gap 2: the 2.2-stud shoulder between two lane margins supports a rail.
 -- Its full width stays X139.6..140.4; no attachment crosses a lane edge.
 local bypass={}
 for i=0,2 do
  local z=34+i*4
  part(root,'BypassFoot'..i,CFrame.new(140,20.15,z),V(.8,.3,.8),{95,100,79}).Material=Enum.Material.Slate
  part(root,'BypassPost'..i,CFrame.new(140,21.7,z),V(.5,2.8,.5),{116,78,45})
  part(root,'BypassCap'..i,CFrame.new(140,23.2,z),V(.75,.2,.75),{89,59,37})
  bypass[i+1]=V(140,22.8,z)
 end
 for i=1,2 do beam(root,'BypassRail'..i,bypass[i],bypass[i+1],.24,{139,101,62}) end
 sign(root,'JumpChoice',CFrame.new(140,24.2,38)*CFrame.Angles(0,-math.pi/2,0),'JUMPS')
 -- R2 gap 3: surface finish only on this owned nonphysical front cladding.
 for _,p in root:GetDescendants() do yieldBuild();if p:IsA('BasePart') then
  local v=p.CFrame.Position
  if v.X>=124 and v.X<=144 and v.Z>-15 and v.Z<15 and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then
   if p.Name=='Round4ShelfRockRelief' or p.Name=='Round4ShelfLightFacet' then
    local tone=math.floor(v.Y/5)%3
    p.Color=Color3.fromRGB(139+tone*9,141+tone*8,115+tone*7);p.Material=Enum.Material.Slate
   elseif p.Name=='Round4ShelfMossDrop' or p.Name=='Round4ShelfMossLedge' then
    p.Color=Color3.fromRGB(100,137,64);p.Material=Enum.Material.Grass
   end
  end
 end end
end
return S
