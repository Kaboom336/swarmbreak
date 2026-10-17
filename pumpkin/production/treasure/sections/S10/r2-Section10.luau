-- Home-local presentation only. The MeadowV4 guard calls build before origin
-- translation; this module deliberately parents to the unshifted home world.
local Section10={}
local RS=game:GetService('ReplicatedStorage')
local Style=require(RS.UIStyle)
local operations=0
local function yieldBuild()
 operations+=1
 if operations%300==0 then if task then task.wait()end end
end
local themes={
 {name='CRYSTAL CAVE',x=-66,color=Color3.fromRGB(111,80,147),crown=Color3.fromRGB(187,128,235),material=Enum.Material.Slate},
 {name='FROST PEAK',x=-22,color=Color3.fromRGB(160,190,207),crown=Color3.fromRGB(229,240,239),material=Enum.Material.Glacier},
 {name='VOLCANO',x=22,color=Color3.fromRGB(93,76,70),crown=Color3.fromRGB(174,114,67),material=Enum.Material.Basalt},
 {name='OCEAN',x=66,color=Color3.fromRGB(179,156,113),crown=Color3.fromRGB(75,173,174),material=Enum.Material.Sandstone},
}
local function part(parent,name,size,frame,color,material)
 yieldBuild()
 local q=Instance.new('Part');q.Name='S10_'..name;q.Size=size;q.CFrame=frame
 q.Color=color;q.Material=material or Enum.Material.Slate
 q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
 q:SetAttribute('Section','S10');q:SetAttribute('SurfaceRole','Scenery');q.Parent=parent
 return q
end
function Section10.build(_meadow,_origin)
 local world=game:GetService('Workspace'):FindFirstChild('GREYBOX')
 if not world or not world:FindFirstChild('HomePlot8')or world:FindFirstChild('HomePortalsS10')then return end
 local group=Instance.new('Model');group.Name='HomePortalsS10';group.Parent=world
 -- Three large attached crown facets per destination: world identity silhouettes.
 -- All feet land in the existing cosmetic arch envelope, outside route reserve.
 for i,t in themes do
  for j=-1,1 do
   local q=part(group,'Crown'..i..'_'..j,Vector3.new(4,6+((i+j)%3),3),
    CFrame.new(t.x+j*8,31+(j==0 and 1 or -1),-145)*CFrame.Angles(0,0,math.rad(-j*12)),t.crown,t.material)
   if i==1 then q.Shape=Enum.PartType.Block end
  end
  -- Three attached accents give the arch material a recognizable world story.
  for j=-1,1 do
   local accent=part(group,'Identity'..i..'_'..j,Vector3.new(1.1,3.4+((j+2)%3),1.2),
    CFrame.new(t.x-10.7+j*.9,25.4+j*.9,-143.6)*CFrame.Angles(0,0,math.rad(-j*18)),t.crown,t.material)
   if i==1 or i==2 then
    -- Wedges create attached tapered crystal/ice tips, with no effect lights.
    local wedge=Instance.new('WedgePart')
    for _,key in {'Name','Size','CFrame','Color','Material','Anchored','CanCollide','CanQuery','CanTouch'}do wedge[key]=accent[key]end
    wedge:SetAttribute('Section','S10');wedge:SetAttribute('SurfaceRole','Scenery');wedge.Parent=group;accent:Destroy()
   elseif i==3 then accent.Color=Color3.fromRGB(197,139,78);accent.Material=Enum.Material.Slate
   else accent.Shape=Enum.PartType.Ball end
  end
  -- In-world availability information, never an interaction or a state source.
  local badge=part(group,'LockedBadge'..i,Vector3.new(18,3.2,.45),CFrame.new(t.x,15.8,-142.15),Style.Colors.Panel,Enum.Material.Wood)
  Style.sign(badge,'LOCKED\nCOMING SOON')
  badge:SetAttribute('S10Caption','LOCKED\nCOMING SOON');badge:SetAttribute('LabelFace','Back');badge:SetAttribute('LabelSize',1.2)
  for _,gui in badge:GetChildren()do if gui:IsA('SurfaceGui')then
   gui.Adornee=badge;gui.MaxDistance=180
   local text=gui:FindFirstChildOfClass('TextLabel');text.Text='LOCKED\nCOMING SOON';text.TextColor3=Style.Colors.Gold
  end end
 end
end
function Section10.finishDecor(decor)
 if decor:GetAttribute('S10Finished')then return end
 decor:SetAttribute('S10Finished',true)
 for _,p in decor:GetDescendants()do
  yieldBuild()
  if not p:IsA('BasePart')or p.CanCollide or p.CanQuery or p.CanTouch then continue end
  local c,s=p.CFrame.Position,p.Size
  if c.Z-s.Z/2 < -176 or c.Z+s.Z/2 > -110 or c.Y+s.Y/2>45 then continue end
  for _,t in themes do
   if math.abs(c.X-t.x)>17 or c.Z < -148 or c.Z > -141 then continue end
   -- Only existing scenery finishes; geometry, flags and metadata are exact.
   if p.Name=='Slate' and c.Y>10 then p.Color=t.color;p.Material=t.material end
   if (p.Name=='Stone' or p.Name=='Snow')and c.Y>15 and s.X<9 and s.Y<9 then
    p.Color=Color3.fromRGB(223,181,77);p.Material=Enum.Material.Metal
   end
   if p.Name=='Ink' and s.Y>19 and s.Z<.03 then
    p.Color=Color3.fromRGB(math.floor(t.color.R*70),math.floor(t.color.G*70),math.floor(t.color.B*70))
   end
   if p.Name=='Ink'and s.X==32 and s.Y==4.5 then
    Style.sign(p,t.name);p:SetAttribute('S10Caption',t.name)
    p:SetAttribute('LabelFace','Back');p:SetAttribute('LabelSize',1.7);p:SetAttribute('S10LabelLift',1.24)
    for _,gui in p:GetChildren()do if gui:IsA('SurfaceGui')then
     gui.Adornee=p;gui.MaxDistance=180
     local text=gui:FindFirstChildOfClass('TextLabel');text.Text=t.name;text.TypeBounds.MaxTextSize=100
     -- Keep the name in the exposed upper strip above the frozen R1 crowns.
     text.Size=UDim2.fromScale(1,.45);text.Position=UDim2.fromScale(0,0)
    end end
   end
  end
 end
 if task then
  -- HomeArt creates its redundant caption anchors after this finish hook.
  -- Observe only those cosmetic captions; no travel/prompt/ownership listeners.
  decor.DescendantAdded:Connect(function(node)
   if node:IsA('BillboardGui')and node.Name=='DestinationCaption'then node.Enabled=false end
  end)
 end
end
return Section10
