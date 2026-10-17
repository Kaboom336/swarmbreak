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
  local badge=part(group,'LockedBadge'..i,Vector3.new(18,5,.5),CFrame.new(t.x,16,-142.2),Style.Colors.Panel,Enum.Material.Wood)
  -- Scene.home has no numeric requirement for these future arches.
  caption(badge,'LOCKED\nCOMING SOON',1.65)
  for j=-1,1 do
   part(group,'Crown'..i..'_'..j,Vector3.new(3.5,4+((j+2)%3),3),CFrame.new(t.x+j*8,31.6,-145),t.accent,i==1 and Enum.Material.Slate or Enum.Material.Sandstone)
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
   if p.Name=='Ink'and s.Y>19 and s.Z<.03 then
    p.Color=i==1 and Color3.fromRGB(82,42,136)or Color3.fromRGB(71,67,64)
    p.Material=Enum.Material.Neon;p.Transparency=.38
   end
   if p.Name=='Ink'and s.X==32 and s.Y==4.5 then
    for _,gui in p:GetChildren()do if gui:IsA('SurfaceGui')then gui:Destroy()end end
    p:SetAttribute('S10Caption',nil)
   end
  end
 end
 if task then
  local function hide(node)if node:IsA('BillboardGui')and node.Name=='DestinationCaption'then node.Enabled=false end end
  for _,node in decor:GetDescendants()do yieldBuild();hide(node)end
  decor.DescendantAdded:Connect(hide)
 end
end
return Section10
