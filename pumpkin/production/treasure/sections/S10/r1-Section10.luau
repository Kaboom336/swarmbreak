-- Home-local presentation only. The MeadowV4 guard calls build before origin
-- translation; this module deliberately parents to the unshifted home world.
local Section10={}
local RS=game:GetService('ReplicatedStorage')
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
  end
 end
end
return Section10
