-- S5 R4 final: R3 owner gaps plus three render-recorded finish gaps.
local S={kits={}}
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
-- Reuse sanitized CC0 kits2 rock templates, fitted to tangent wall envelopes.
for i,g in {{97.2,4.9,-2},{97.2,9.9,-2},{97.2,14.9,-2},{122.8,4.9,-2},{122.8,9.9,-2},
 {97.2,4.9,10},{97.2,9.9,10},{97.2,14.9,10},{122.8,4.9,10},{122.8,9.9,10},{97.2,14.9,22},{97.2,14.9,34}} do
 table.insert(S.kits,{id='RidgeRock'..i,name='quaternius-nature__Rock_Medium_1',x=g[1],y=g[2],z=g[3],size=V(2.4,4.2,3.4),color={133+i%3*10,119+i%3*8,99+i%3*6}})
end
function S.spawnKits(root,kit)
 if root:GetAttribute('S5KitsLoaded') then return end
 local origin=root:GetAttribute('MeadowOrigin') or V(0,0,0)
 for _,g in S.kits do
  yieldBuild();local frame=CFrame.new(origin+V(g.x,g.y,g.z))
  local m=assert(kit.spawn(g.name,'meadow',frame,g.size),'S5 kit missing '..g.id)
  assert(kit.fit(m,g.size,frame),'S5 fit failed')
  m.Name='S5_'..g.id;m:SetAttribute('Section','S5')
  for _,p in m:GetDescendants() do yieldBuild();if p:IsA('BasePart') then
   p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
   p.Color=Color3.fromRGB(unpack(g.color));p.Material=Enum.Material.Rock;p:SetAttribute('Section','S5');p:SetAttribute('Cosmetic',true)
  end end
  m.Parent=root
 end
 root:SetAttribute('S5KitsLoaded',#S.kits)
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
 -- R3 gap 1: finish only on ridge solids; never change a collision property.
 for _,p in root:GetDescendants() do yieldBuild();if p:IsA('BasePart') then
  local v=p.CFrame.Position;local inRidge=v.X>=80 and v.X<=144 and v.Z>=-12 and v.Z<=64
  if inRidge and (p.Name=='SolidMountainStone' or p.Name=='SolidRampBody' or p.Name=='SolidRampWedge' or p.Name=='Round4ShelfRockRelief' or p.Name=='Round4ShelfLightFacet') then
   local t=(math.floor(v.X/4)+math.floor(v.Z/4))%4
   p.Color=Color3.fromRGB(127+t*9,114+t*8,96+t*6);p.Material=Enum.Material.Rock
  elseif p.Name:match('^OptionalJumpLanding%d+$') then
   p.Color=Color3.fromRGB(137,132,108);p.Material=Enum.Material.Rock
  elseif v.X>140 and v.X<156 and p.Name=='Round4JumpPalePad' then
   p.Color=Color3.fromRGB(218,214,179);p.Material=Enum.Material.Limestone
  elseif v.X>140 and v.X<156 and p.Name=='Round4JumpAmberEdge' then
   p.Color=Color3.fromRGB(218,214,179);p.Material=Enum.Material.Limestone
  end
  -- R3 gap 3: only thin, untagged nonphysical rock-detail caps in this ridge.
  if inRidge and v.Y>4 and p.Size.Y<.5 and
   (p.Name=='LookLightRockTop' or p.Name=='Round4ShelfLightFacet') and
   not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then p:Destroy();continue end
  -- R4 gap 1: these foreground cosmetic boxes hide the new tangent rock faces.
  if v.X>=116 and v.X<=124 and v.Z>=-12 and v.Z<=40 and
   (p.Name=='Round4ShelfRockRelief' or p.Name=='Round4ShelfMossLedge' or p.Name=='Round4ShelfMossDrop') and
   not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then p:Destroy() end
 end end
 for i,g in S.kits do
  local anchor=part(root,'RockAnchor'..i,CFrame.new(g.x,g.y+g.size.Y/2,g.z),g.size,g.color)
  anchor.Material=Enum.Material.Rock;anchor.Transparency=1
 end
 -- Three bent rim pines: vertical rooted feet, leaning trunk, stepped crowns.
 for i,g in {{92,20,28},{88,20.000008,12},{90,20,48}} do
  local x,y,z=unpack(g)
  part(root,'PineRoot'..i,CFrame.new(x,y+1,z),V(.6,2,.6),{101,72,43})
  beam(root,'PineTrunk'..i,V(x,y+1.8,z),V(x+1.2,y+9,z),.45,{112,78,43})
  for j=0,2 do
   -- R4 gap 2: paired tapering wedges keep the rooted, leaning conifer silhouette.
   local w=4.4-j*.95
   for _,side in {-1,1} do
    yieldBuild();local crown=Instance.new('WedgePart');crown.Name='S5_PineCrown'..i..'_'..j..'_'..side
    crown.Size=V(w,2.7,w/2);crown.CFrame=CFrame.new(x+.3+j*.35,y+4.2+j*2.3,z+side*w/4)*CFrame.Angles(0,if side==1 then math.pi else 0,0)
    crown.Color=Color3.fromRGB(73+j*12,119+j*13,55+j*7);crown.Material=Enum.Material.Grass
    crown.Anchored=true;crown.CanCollide=false;crown.CanQuery=false;crown.CanTouch=false
    crown:SetAttribute('Section','S5');crown:SetAttribute('Cosmetic',true);crown.Parent=root
   end
  end
  for j=0,2 do
   local tuft=part(root,'RimTuft'..i..'_'..j,CFrame.new(x-1+j*.7,y+.45,z+1.5),V(.3,.9,.3),{118,157,65})
   tuft.Material=Enum.Material.Grass
  end
 end
 -- Deferred kits wait for the builder's one origin translation. No KitSwap edits.
 if task then task.defer(function()
  while not root:GetAttribute('MeadowOrigin') do task.wait() end
  local ok,err=pcall(function() S.spawnKits(root,require(game:GetService('ServerScriptService').KitLibrary)) end)
  if not ok then warn('[S5] ridge kits skipped: '..tostring(err)) end
 end) end
end
return S
