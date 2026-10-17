-- Home-local cosmetic yard architecture. Called by the existing MeadowV4 pcall
-- after Greybox has built HomePlot1..8. Never parent to the translated Meadow.
local Section9 = {}
local RS = game:GetService('ReplicatedStorage')
local Placement = require(RS.GreyboxPlacement)
local Style = require(RS.UIStyle)
local operations = 0
local function yieldBuild()
 operations += 1
 if operations % 300 == 0 then if task then task.wait() end end
end
function Section9.build(_meadow, _origin)
 local world = game:GetService('Workspace'):FindFirstChild('GREYBOX')
 -- Standalone Meadow test/builds have no home. This is deliberately a no-op.
 if not world or not world:FindFirstChild('HomePlot8') or world:FindFirstChild('HomeYardsS9') then return end
 local group=Instance.new('Model');group.Name='HomeYardsS9';group.Parent=world
 local wood=Color3.fromRGB(133,82,43)
 local stone=Color3.fromRGB(178,151,113)
 local function part(name,size,position,color,material,rotation)
  yieldBuild()
  local p=Instance.new('Part');p.Name='S9_'..name;p.Size=size
  p.CFrame=CFrame.new(position)*(rotation or CFrame.new())
  p.Color=color;p.Material=material or Enum.Material.Wood
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
  p:SetAttribute('Section','S9');p:SetAttribute('SurfaceRole','Scenery');p.Parent=group
  return p
 end
 for slot=1,8 do
  local x,z=Placement.center(slot);local y=Placement.height(slot);local side=x<0 and -1 or 1
  -- Foundation tops are tangent to the underside of the protected plot floor.
  -- All new inner faces stay >=1.1 studs outside the central path's x=+/-20 edge.
  if y>0 then
   for _,dz in {-15,15}do
    local length=18;local cz=z+dz
    if cz-length/2 < -110 then length=cz+length/2+110;cz=-110+length/2 end
    if length>0 then part('FoundationFront'..slot,Vector3.new(.5,y-.02,length),Vector3.new(side*21.35,y/2,z+(cz-z)),stone,Enum.Material.Sandstone)end
   end
   for _,dz in {-24,24}do
    if z+dz-.25>=-110 then part('FoundationSide'..slot,Vector3.new(62,y-.02,.5),Vector3.new(side*52.5,y/2,z+dz),stone,Enum.Material.Sandstone)end
   end
   local depth=math.min(48,z+24+110);local cz=z+24-depth/2
   part('FoundationBack'..slot,Vector3.new(.5,y-.02,depth),Vector3.new(side*83.5,y/2,cz),stone,Enum.Material.Sandstone)
  end
  -- Three joined pieces: post, projecting bracket, blank board facing the path.
  local gateX=side*22.5;local gateZ=z+14
  part('SignPost'..slot,Vector3.new(.8,11,.8),Vector3.new(gateX,y+.2+5.5,gateZ),wood)
  part('SignBracket'..slot,Vector3.new(.8,.65,7.5),Vector3.new(gateX,y+11.1,gateZ+2.8),wood)
  local board=part('PlotBoard'..slot,Vector3.new(8,3.6,.4),Vector3.new(gateX,y+8.8,gateZ+3),wood,Enum.Material.Wood,CFrame.Angles(0,side*math.pi/2,0))
  Style.sign(board,'PLOT '..slot)
  board:SetAttribute('RouteLabel','PLOT '..slot);board:SetAttribute('LabelFace','Front');board:SetAttribute('LabelSize',.85)
  for _,gui in board:GetChildren()do
   local text=gui:FindFirstChildOfClass('TextLabel')
   text.Text='PLOT '..slot;text.Size=UDim2.fromScale(1,.55)
  end
  local banner=part('NumberBanner'..slot,Vector3.new(1.8,2.3,.16),Vector3.new(gateX+side*.35,y+9.6,gateZ-1.1),wood,Enum.Material.Wood,CFrame.Angles(0,side*math.pi/2,0))
  Style.sign(banner,tostring(slot));banner.Color=Color3.fromRGB(50,105,74)
  banner:SetAttribute('RouteLabel',tostring(slot));banner:SetAttribute('LabelSize',.85)
  for _,gui in banner:GetChildren()do gui:FindFirstChildOfClass('TextLabel').Text=tostring(slot) end
  -- Open frame at the outer edge, beyond the usable +/-28 placement rectangle.
  local outerX=side*82.4
  for _,dz in {-10,10}do
   part('CollectionPost'..slot,Vector3.new(.8,8,.8),Vector3.new(outerX,y+4.2,z+dz),wood)
   part('CollectionBrace'..slot,Vector3.new(.8,2.4,.6),Vector3.new(outerX,y+7,z+dz*.85),wood,Enum.Material.Wood,CFrame.Angles(math.rad(dz<0 and -35 or 35),0,0))
  end
  local header=part('CollectionHeader'..slot,Vector3.new(21.5,1.5,.8),Vector3.new(outerX,y+8.2,z),wood,Enum.Material.Wood,CFrame.Angles(0,math.pi/2,0))
  Style.sign(header,'COLLECTION')
  header:SetAttribute('RouteLabel','COLLECTION');header:SetAttribute('LabelFace',side<0 and 'Back' or 'Front');header:SetAttribute('LabelSize',.85)
  -- A maintained welcome bed: three flowers, beyond legal placement and the gate.
  part('WelcomeBed'..slot,Vector3.new(1.2,.3,4.4),Vector3.new(side*23.2,y+.35,z+19),stone,Enum.Material.Sandstone)
  for flower=-1,1 do
   local fz=z+19+flower*1.25;local fx=side*23.2
   part('FlowerStem'..slot,Vector3.new(.12,.65,.12),Vector3.new(fx,y+.825,fz),Color3.fromRGB(74,119,50),Enum.Material.Grass)
   local tint=flower==0 and Color3.fromRGB(246,193,69)or Color3.fromRGB(249,235,191)
   for petal=0,2 do
    local angle=petal*math.pi*2/3
    local p=part('FlowerPetal'..slot,Vector3.new(.38,.18,.38),Vector3.new(fx+math.cos(angle)*.22,y+1.13,fz+math.sin(angle)*.22),tint,Enum.Material.SmoothPlastic);p.Shape=Enum.PartType.Ball
   end
   local center=part('FlowerCenter'..slot,Vector3.new(.23,.21,.23),Vector3.new(fx,y+1.21,fz),Color3.fromRGB(210,137,41),Enum.Material.SmoothPlastic);center.Shape=Enum.PartType.Ball
  end
  -- The border is outside every legal pet envelope. Lamps sit on the existing
  -- visual fence cap, above native/query geometry; never on the entry reserve.
  for _,dz in {-22,22}do
   if z+dz-1.1>=-110 then
    for _,dx in {-19,0,19}do
     local bx,bz=x+dx,z+dz
     part('BorderPlanter'..slot,Vector3.new(5,.5,1.8),Vector3.new(bx,y+.45,bz),stone,Enum.Material.Sandstone)
     part('PlanterLeaves'..slot,Vector3.new(4.5,.65,1.45),Vector3.new(bx,y+1.02,bz),Color3.fromRGB(70,128,55),Enum.Material.Grass)
     for f=-1,1 do
      local fx=bx+f*1.4
      part('BorderStem'..slot,Vector3.new(.16,.9,.16),Vector3.new(fx,y+1.7,bz),Color3.fromRGB(60,120,47),Enum.Material.Grass)
      local tint=f==0 and Color3.fromRGB(247,188,66)or(f<0 and Color3.fromRGB(255,239,196)or Color3.fromRGB(242,100,100))
      for petal=0,3 do
       local a=petal*math.pi/2
       local q=part('BorderPetal'..slot,Vector3.new(.48,.48,.25),Vector3.new(fx+math.cos(a)*.26,y+2.15+math.sin(a)*.26,bz),tint,Enum.Material.SmoothPlastic);q.Shape=Enum.PartType.Ball
      end
      part('BorderPollen'..slot,Vector3.new(.28,.28,.3),Vector3.new(fx,y+2.15,bz+.08),Color3.fromRGB(255,207,65),Enum.Material.SmoothPlastic)
     end
    end
    for _,dx in {-29.5,29.5}do
     local pos=Vector3.new(x+dx,y+5.875,z+dz+(dz<0 and -2 or 2))
     part('CornerLampBase'..slot,Vector3.new(2.1,.5,2.1),pos,wood)
     local pane=part('CornerLampGlow'..slot,Vector3.new(1.4,1.5,1.4),pos+Vector3.new(0,1,0),Color3.fromRGB(255,215,135),Enum.Material.Neon)
     part('CornerLampCap'..slot,Vector3.new(2.3,.4,2.3),pos+Vector3.new(0,1.95,0),wood)
     local light=Instance.new('PointLight');light.Color=pane.Color;light.Brightness=.35;light.Range=10;light.Shadows=false;light.Parent=pane
    end
   end
  end
 end
end
-- Called only by the decor-loader's isolated cosmetic hook. Home-local; no state,
-- ownership, loot, placement, persistence, prompts, geometry or physics changes.
function Section9.finishDecor(decor)
 if decor:FindFirstChild('S9_PortalSwirl1_1')then return 0 end
 local changed=0
 for _,p in decor:GetDescendants()do
  yieldBuild()
  if p:IsA('BasePart') and not p.CanCollide and not p.CanQuery and not p.CanTouch then
   local c=p.CFrame.Position;local s=p.Size
   if p.Name=='Slate' and math.abs(s.X-66)<.01 and math.abs(s.Z-50)<.01 and s.Y>3
    and math.abs(math.abs(c.X)-52)<.01 and c.Z-s.Z/2>=-110 and c.Z+s.Z/2<=135 then
    p.Color=Color3.fromRGB(178,151,113);p.Material=Enum.Material.Sandstone;changed+=1
   end
   -- Existing placement-mat geometry, flags and metadata stay byte-for-byte.
   if c.Z-s.Z/2>=-110 and c.Z+s.Z/2<=135 then
    if p.Name=='Stone' and math.abs(s.X-12.5)<.01 and math.abs(s.Z-14)<.01 and s.Y<.2 then
     p.Color=Color3.fromRGB(213,188,146);p.Material=Enum.Material.Sandstone;changed+=1
    elseif p.Name=='Slate' and math.abs(s.X-11.5)<.01 and math.abs(s.Z-13)<.01 and s.Y<.1 then
     p.Color=Color3.fromRGB(154,164,161);p.Material=Enum.Material.SmoothPlastic;changed+=1
    elseif (p.Name=='Path' or p.Name=='PinkStone') and math.abs(c.X)+s.X/2<=20.01 and s.Y<.2 then
     p.Color=Color3.fromRGB(205,179,142);p.Material=Enum.Material.Sandstone;changed+=1
    end
   end
   -- The broad central paving crosses the seam; change only its finish.
   if p.Name=='PinkStone' and s.X==40 and s.Y<.1 then p.Color=Color3.fromRGB(205,179,142);p.Material=Enum.Material.Sandstone end
   if p.Name=='PortalLight' and math.abs(c.Z-1.8)<.01 then
    p.Transparency=.68;p.Color=Color3.fromRGB(75,224,210);p.Material=Enum.Material.Glass
    if task and not p:FindFirstChild('S9Swirl')then
     local socket=Instance.new('Attachment');socket.Name='S9Swirl';socket.Parent=p
     local emitter=Instance.new('ParticleEmitter');emitter.Texture='rbxasset://textures/particles/sparkles_main.dds'
     emitter.Rate=7;emitter.Lifetime=NumberRange.new(1.5,2.5);emitter.Speed=NumberRange.new(.4,1)
     emitter.Rotation=NumberRange.new(0,360);emitter.RotSpeed=NumberRange.new(30,65)
     emitter.SpreadAngle=Vector2.new(180,180);emitter.Size=NumberSequence.new(.35)
     emitter.Color=ColorSequence.new(p.Color);emitter.LightEmission=.6
     emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.35),NumberSequenceKeypoint.new(1,1)});emitter.Parent=socket
    end
   end
  end
 end
 local function finishPart(name,size,frame,color,material,alpha)
  yieldBuild()
  local q=Instance.new('Part');q.Name='S9_'..name;q.Size=size;q.CFrame=frame
  q.Color=color;q.Material=material;q.Transparency=alpha or 0
  q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
  q:SetAttribute('Section','S9Client');q.Parent=decor;return q
 end
 for slot=1,8 do
  local x,z=Placement.center(slot);local y=Placement.height(slot);local side=x<0 and -1 or 1
  -- Kerb outside the central path, split at the protected gate/stair reserve.
  for _,dz in {-15.5,15.5}do
   local cz=z+dz;local length=17
   if cz-length/2>=-110 then
    finishPart('Kerb'..slot,Vector3.new(.6,.45,length),CFrame.new(side*21.4,y+.425,cz),Color3.fromRGB(213,188,146),Enum.Material.Sandstone)
   end
  end
 end
 -- Two open spiral arms behind the glass. Their light and opacity are bounded;
 -- they have no touch/query/collision and do not replace the prompt anchor.
 for arm=1,2 do for segment=1,18 do
  local t=segment/18;local angle=t*math.pi*2+(arm-1)*math.pi
  local radius=1+7.8*t;local xx=1.54+math.cos(angle)*radius;local yy=17.446+math.sin(angle)*radius
  finishPart('PortalSwirl'..arm..'_'..segment,Vector3.new(.22,.75,.025),CFrame.new(xx,yy,1.76)*CFrame.Angles(0,0,angle),Color3.fromRGB(102,236,216),Enum.Material.Neon,.62)
 end end
 if task then Section9.bindOwners() end
 return changed
end
-- Client presentation observes the original replicated TextLabel. No ownership
-- writes and no HomeArt edits: the server keeps its existing live source.
function Section9.bindOwners()
 local world=game:GetService('Workspace'):FindFirstChild('GREYBOX')
 local group=world and world:FindFirstChild('HomeYardsS9');if not group then return end
 for slot=1,8 do
  yieldBuild()
  local plot=world:FindFirstChild('HomePlot'..slot)
  local marker=plot and plot:FindFirstChild('PenMarker'..slot)
  local gui=marker and marker:FindFirstChildOfClass('BillboardGui')
  local source=gui and gui:FindFirstChildWhichIsA('TextLabel',true)
  local board=group:FindFirstChild('S9_PlotBoard'..slot)
  if source and board and not board:GetAttribute('S9OwnerBound')then
   board:SetAttribute('S9OwnerBound',true);gui.Enabled=false
   local labels={}
   for _,face in board:GetChildren()do if face:IsA('SurfaceGui')then
    local text=Instance.new('TextLabel');text.Name='LiveOwner';text.BackgroundTransparency=1
    text.Size=UDim2.fromScale(.94,.4);text.Position=UDim2.fromScale(.03,.57)
    Style.lettering(text,42,1);text.Parent=face;table.insert(labels,text)
   end end
   local function refresh()
    local owner=source.Text:match(' / (.*)$')or source.Text
    for _,text in labels do text.Text=owner end
   end
   refresh();source:GetPropertyChangedSignal('Text'):Connect(refresh)
  end
 end
end
return Section9
