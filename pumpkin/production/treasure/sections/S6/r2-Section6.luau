-- S6 R2: frozen R1 silhouette, then the three gaps in GAPS-R2.md only.
local S = {}
local V = Vector3.new
local work = 0
local function yieldBuild()
 work += 1
 if work % 300 == 0 then if task then task.wait() end end
end
local function part(root,name,frame,size,color,material)
 yieldBuild()
 local p=Instance.new('Part');p.Name='S6_'..name;p.CFrame=frame;p.Size=size
 p.Color=Color3.fromRGB(unpack(color));p.Material=material or Enum.Material.Slate
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S6');p:SetAttribute('Cosmetic',true);p.Parent=root
 return p
end
local function beam(root,name,a,b,width)
 local n=(b-a).Unit;local u=V(0,1,0)
 local x=u:Cross(n).Unit;local y=n:Cross(x).Unit;local c=(a+b)/2
 return part(root,name,CFrame.new(c.X,c.Y,c.Z,x.X,y.X,n.X,x.Y,y.Y,n.Y,x.Z,y.Z,n.Z),V(width,width,(b-a).Magnitude),{149,139,114})
end
local groups={
 {name='LowerSpiral',y=24,points={{-46,-142},{-42,-146},{-38,-150}}},
 {name='UpperSpiral',y=36,points={{26,-150},{30,-146},{34,-142}}},
 {name='RecoveryShelf',y=12,points={{86,-86},{94,-86},{102,-86}}},
}
local function lamp(root,name,point,normal,reach)
 local depth=reach or .9
 local n=normal;local x=V(0,1,0):Cross(n);local y=V(0,1,0)
 local frame=CFrame.new(point.X,point.Y,point.Z,x.X,y.X,n.X,x.Y,y.Y,n.Y,x.Z,y.Z,n.Z)
 part(root,name..'Bracket',frame*CFrame.new(0,0,(depth+.3)/2),V(.18,.18,depth+.3),{99,66,39},Enum.Material.Wood)
 local core=part(root,name..'Glass',frame*CFrame.new(0,-.45,depth),V(.7,1.1,.7),{255,194,87},Enum.Material.Neon)
 part(root,name..'Hood',frame*CFrame.new(0,.16,depth),V(.98,.16,.98),{90,65,40},Enum.Material.Metal)
 part(root,name..'Base',frame*CFrame.new(0,-1.08,depth),V(.94,.16,.94),{90,65,40},Enum.Material.Metal)
 local light=Instance.new('PointLight');light.Color=Color3.fromRGB(255,207,133)
 light.Brightness=1.25;light.Range=18;light.Shadows=false;light.Parent=core
end
local function sign(root)
 local frame=CFrame.new(86,15.9,-86)*CFrame.Angles(0,math.rad(-25),0)
 local board=part(root,'LowerPathBoard',frame,V(4,1.8,.18),{113,77,44},Enum.Material.Wood)
 board:SetAttribute('RouteLabel','LOWER PATH');board:SetAttribute('LabelFace','Front');board:SetAttribute('LabelSize',.5)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=96;gui.LightInfluence=.15;gui.Parent=board
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(.9,.8);label.Position=UDim2.fromScale(.05,.1)
 label.BackgroundTransparency=1;label.Text='LOWER PATH';label.Parent=gui
 require(game:GetService('ReplicatedStorage').UIStyle).lettering(label,80,12)
 for i,x in {-1.7,1.7} do
  part(root,'LowerPathBolt'..i,frame*CFrame.new(x,.55,-.13),V(.12,.12,.08),{186,162,108},Enum.Material.Metal)
 end
end
function S.build(root)
 -- Finish-only on explicit residual S6 cliff bodies. No lane, art, tag or flag edits.
 for _,p in root:GetDescendants() do
  yieldBuild()
  if p:IsA('BasePart') and p.Name=='SolidMountainStone' then
   local v=p.CFrame.Position
   local top=v.Y+p.Size.Y/2
   if top>=0 and top<=54 and v.X>=-65 and v.X<=125 and v.Z>=-158 and v.Z<=-35
    and not(v.X>=-32 and v.X<=32 and v.Z>=-132 and v.Z<=-72) then
    p.Color=if top>=36 then Color3.fromRGB(149,139,115) elseif top>=20 then Color3.fromRGB(128,124,101) else Color3.fromRGB(112,116,93)
    p.Material=Enum.Material.Rock
   end
  end
 end
 for _,g in groups do
  local points={}
  for i,q in g.points do
   part(root,g.name..'Pier'..i,CFrame.new(q[1],g.y+1.5,q[2]),V(.9,3,.9),{137,130,108})
   points[i]=V(q[1],g.y+2.5,q[2])
  end
  for i=1,2 do beam(root,g.name..'Sill'..i,points[i],points[i+1],.28) end
 end
 -- R2 finish-only on pre-existing nonphysical wall relief; retain every field.
 for _,p in root:GetDescendants() do
  yieldBuild()
  if p:IsA('BasePart') and (p.Name=='Round4ShelfRockRelief' or p.Name=='Round4ShelfLightFacet' or p.Name=='Round4StackedRock') then
   local v=p.CFrame.Position
   if v.X>=-65 and v.X<=125 and v.Y>=0 and v.Y<=54 and v.Z>=-158 and v.Z<=-35
    and not(v.Y>=44 and v.X>=-32 and v.X<=32 and v.Z>=-132 and v.Z<=-72)
    and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('LaneId') and #p:GetTags()==0 then
    local tint=(math.floor(v.X/8)+math.floor(v.Z/8))%3
    p.Color=Color3.fromRGB(132+tint*8,124+tint*6,100+tint*4);p.Material=Enum.Material.Rock
   end
  end
 end
 lamp(root,'EntryLamp1',V(-52,20.73,-83.34),V(1,0,0))
 lamp(root,'EntryLamp2',V(-56,21.03,-94.8),V(1,0,0))
 -- Rear face brackets touch the actual frozen piers at Z=-86.45.
 lamp(root,'RecoveryLamp1',V(94,14.65,-86.45),V(0,0,-1))
 lamp(root,'RecoveryLamp2',V(102,14.65,-86.45),V(0,0,-1))
 sign(root)
end
return S
