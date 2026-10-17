-- Home-local cosmetic presentation; never a travel/unlock/state source.
local Section10={}
local RS=game:GetService('ReplicatedStorage')
local Style=require(RS.UIStyle)
local operations=0
local function yieldBuild()
 operations+=1
 if operations%300==0 and task then task.wait()end
end
local themes={
 {name='CRYSTAL CAVE',x=-66,color=Color3.fromRGB(111,80,147),accent=Color3.fromRGB(187,128,235)},
 {name='COMING SOON',x=-22,color=Color3.fromRGB(143,132,111),accent=Color3.fromRGB(185,166,130)},
 {name='COMING SOON',x=22,color=Color3.fromRGB(143,132,111),accent=Color3.fromRGB(185,166,130)},
 {name='COMING SOON',x=66,color=Color3.fromRGB(143,132,111),accent=Color3.fromRGB(185,166,130)},
}
local function part(parent,name,size,frame,color,material)
 yieldBuild()
 local q=Instance.new('Part');q.Name='S10_'..name;q.Size=size;q.CFrame=frame
 q.Color=color;q.Material=material or Enum.Material.Sandstone
 q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
 q:SetAttribute('Section','S10');q:SetAttribute('SurfaceRole','Scenery');q.Parent=parent
 return q
end
local function caption(board,text,size)
 Style.sign(board,text)
 board:SetAttribute('S10Caption',text);board:SetAttribute('LabelFace','Back');board:SetAttribute('LabelSize',size)
 for _,gui in board:GetChildren()do if gui:IsA('SurfaceGui')then
  gui.Adornee=board;gui.MaxDistance=200
  local label=gui:FindFirstChildOfClass('TextLabel')
  if label then label.Text=text;label.TypeBounds.MaxTextSize=180 end
 end end
end
function Section10.build(_meadow,_origin)
 local world=game:GetService('Workspace'):FindFirstChild('GREYBOX')
 if not world or not world:FindFirstChild('HomePlot8')or world:FindFirstChild('HomePortalsS10')then return end
 local group=Instance.new('Model');group.Name='HomePortalsS10';group.Parent=world
 for i,t in themes do
  local board=part(group,'NameBoard'..i,Vector3.new(30,5,3.5),CFrame.new(t.x,30.3,-143.3),Style.Colors.Panel,Enum.Material.Wood)
  caption(board,t.name,i==1 and 2.7 or 2.5)
  local badge=part(group,'LockedBadge'..i,Vector3.new(18,4.8,.5),CFrame.new(t.x,16,-142.2),Style.Colors.Panel,Enum.Material.Wood)
  -- Scene.home has no numeric requirement for these future arches.
  caption(badge,'LOCKED\nCOMING SOON',1.65)
  for j=-1,1 do
   local crown=part(group,'Crown'..i..'_'..j,Vector3.new(3.5,4+((j+2)%3),3),CFrame.new(t.x+j*8,31.6,-145),t.accent,i==1 and Enum.Material.Slate or Enum.Material.Sandstone)
   if i==1 then
    local wedge=Instance.new('WedgePart');wedge.Name=crown.Name
    wedge.Size=Vector3.new(4,j==0 and 8 or 6,3.5)
    wedge.CFrame=CFrame.new(t.x+j*8,j==0 and 35.6 or 34.6,-145)*CFrame.Angles(0,j*math.pi/2,0)
    wedge.Color=t.accent;wedge.Material=Enum.Material.Slate
    wedge.Anchored=true;wedge.CanCollide=false;wedge.CanQuery=false;wedge.CanTouch=false
    wedge:SetAttribute('Section','S10');wedge:SetAttribute('SurfaceRole','Scenery');wedge.Parent=group;crown:Destroy()
   end
  end
 end
 -- Exact two outer flights requested by the owner. These are tangent veneers;
 -- protected native tread size, flags, materials, colors and floor tags stay exact.
 for _,step in world:GetDescendants()do
  yieldBuild()
  if step:IsA('BasePart')and step.Name=='HomePlotStep'and math.abs(step.CFrame.Position.Z+96)<.01 then
   local c,s=step.CFrame.Position,step.Size;local side=c.X<0 and -1 or 1
   part(group,'StairTread',Vector3.new(s.X-.02,.018,s.Z-.02),CFrame.new(c.X,c.Y+s.Y/2+.009,c.Z),Color3.fromRGB(201,173,131),Enum.Material.Sandstone)
   part(group,'StairRiser',Vector3.new(.018,.48,s.Z-.02),CFrame.new(c.X-side*(s.X/2+.009),c.Y+s.Y/2-.24,c.Z),Color3.fromRGB(178,143,99),Enum.Material.Sandstone)
  end
 end
end
function Section10.finishDecor(decor)
 if decor:GetAttribute('S10Finished')then return end
 decor:SetAttribute('S10Finished',true)
 for _,p in decor:GetDescendants()do
  yieldBuild()
  if not p:IsA('BasePart')or p.CanCollide or p.CanQuery or p.CanTouch then continue end
  local c,s=p.CFrame.Position,p.Size
  if math.abs(c.X)<=21 and math.abs(c.Z)<=3 and c.Y>4 and c.Y<40 and (p.Name=='Slate'or p.Name=='Stone')then
   p.Color=Color3.fromRGB(182,164,123);p.Material=Enum.Material.Sandstone
  end
  -- Exact inherited terrace railing members, including their short seam crossing.
  if (p.Name=='Wood'or p.Name=='DarkWood')and c.Z>=-120.01 and c.Z<=-101.99 and c.Y>11 and c.Y<16 and math.abs(c.X)<=86 then
   if s.Y>4 then
    p.Size=Vector3.new(1.4,2.5,1.4);p.CFrame=CFrame.new(c.X,11.97,c.Z)
   elseif s.Y<2 then
    local y=p.Name=='DarkWood'and 13.1 or(c.Y>13 and 12.55 or 11.5)
    p.Size=Vector3.new(s.X>10 and s.X or 1,.5,s.Z>10 and s.Z or 1)
    p.CFrame=CFrame.new(c.X,y,c.Z)
   end
   p.Color=Color3.fromRGB(133,82,43);p.Material=Enum.Material.Wood
  end
  -- Warm existing cosmetic stair blocks, never their native colliders.
  if p.Name=='Stone'and c.Z<=-119 and c.Z>=-137 and s.X>27 and s.X<29 and s.Z<4 then
   p.Color=Color3.fromRGB(195,161,113);p.Material=Enum.Material.Sandstone
  end
  if c.Z-s.Z/2 < -176 or c.Z+s.Z/2 > -110 or c.Y+s.Y/2>45 then continue end
  for i,t in themes do
   if math.abs(c.X-t.x)>17 or c.Z < -148 or c.Z > -141 then continue end
   if p.Name=='Slate'and c.Y>10 then p.Color=t.color;p.Material=i==1 and Enum.Material.Slate or Enum.Material.Sandstone end
   if (p.Name=='Stone'or p.Name=='Snow')and c.Y>15 and s.X<9 and s.Y<9 then
    p.Color=Style.Colors.Gold;p.Material=Enum.Material.Metal
   end
   if (p.Name=='Stone'or p.Name=='Snow'or p.Name=='Ink')and math.abs(c.X-t.x)<5 and c.Y>16 and c.Y<26 and s.X<9 and s.Y<9 then
    local pivot=Vector3.new(t.x,19,-143)
    p.Size=s*1.35;p.CFrame=CFrame.new(pivot+(c-pivot)*1.35+Vector3.new(0,2,0))*p.CFrame.Rotation
   end
   if p.Name=='Ink'and s.Y>19 and s.Z<.03 then
    p.Color=i==1 and Color3.fromRGB(82,42,136)or Color3.fromRGB(71,67,64)
    p.Material=Enum.Material.Glass;p.Transparency=.42
   end
   if p.Name=='Ink'and s.X==32 and s.Y==4.5 then
    for _,gui in p:GetChildren()do if gui:IsA('SurfaceGui')then gui:Destroy()end end
    p:SetAttribute('S10Caption',nil)
   end
   if p.Name=='Ink'and (c.Y>25 or math.abs(c.X-t.x)>9)then
    p.Color=t.color;p.Material=i==1 and Enum.Material.Slate or Enum.Material.Sandstone
   end
  end
 end
 -- Shallow, attached glowing spiral behind the Crystal lock; zero new lights.
 for arm=1,2 do for segment=1,12 do
  local u=segment/12;local angle=u*math.pi*2+(arm-1)*math.pi;local radius=1.2+7*u
  local facet=part(decor,'CrystalSwirl'..arm..'_'..segment,Vector3.new(.22,.45+radius*.28,.06),CFrame.new(-66+math.cos(angle)*radius,20+math.sin(angle)*radius,-144.975)*CFrame.Angles(0,0,angle),Color3.fromRGB(176,107,235),Enum.Material.Neon)
  facet.Transparency=.52
 end end
 local meadow=part(decor,'MeadowNameBoard',Vector3.new(28,4,.5),CFrame.new(0,34,1.65),Style.Colors.Panel,Enum.Material.Wood)
 caption(meadow,'MEADOW',2.8)
 if task then
  local function hide(node)if node:IsA('BillboardGui')and node.Name=='DestinationCaption'then node.Enabled=false end end
  for _,node in decor:GetDescendants()do yieldBuild();hide(node)end
  decor.DescendantAdded:Connect(hide)
 end
end
return Section10
