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
  local gateX=side*22.5;local gateZ=z+11
  part('SignPost'..slot,Vector3.new(.8,8,.8),Vector3.new(gateX,y+.2+4,gateZ),wood)
  part('SignBracket'..slot,Vector3.new(.8,.65,7.5),Vector3.new(gateX,y+8.1,gateZ+2.8),wood)
  local board=part('PlotBoard'..slot,Vector3.new(6.5,2.6,.4),Vector3.new(gateX,y+6.5,gateZ+3),wood,Enum.Material.Wood,CFrame.Angles(0,side*math.pi/2,0))
  Style.sign(board,'PLOT '..slot)
  board:SetAttribute('RouteLabel','PLOT '..slot);board:SetAttribute('LabelFace','Front');board:SetAttribute('LabelSize',.85)
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
 end
end
-- Called only by the decor-loader's isolated cosmetic hook. Home-local; no state,
-- ownership, loot, placement, persistence, prompts, geometry or physics changes.
function Section9.finishDecor(decor)
 local changed=0
 for _,p in decor:GetDescendants()do
  yieldBuild()
  if p:IsA('BasePart') and not p.CanCollide and not p.CanQuery and not p.CanTouch then
   local c=p.CFrame.Position;local s=p.Size
   if p.Name=='Slate' and math.abs(s.X-66)<.01 and math.abs(s.Z-50)<.01 and s.Y>3
    and math.abs(math.abs(c.X)-52)<.01 and c.Z-s.Z/2>=-110 and c.Z+s.Z/2<=135 then
    p.Color=Color3.fromRGB(178,151,113);p.Material=Enum.Material.Sandstone;changed+=1
   end
  end
 end
 return changed
end
return Section9
