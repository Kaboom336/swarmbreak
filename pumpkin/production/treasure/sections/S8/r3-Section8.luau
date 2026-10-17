-- Attached underside only: no collider, query, touch, light or gameplay hook.
local S={}
local V,C,RGB=Vector3.new,CFrame.new,Color3.fromRGB
function S.build(model,origin)
 local offset=origin or Vector3.zero
 local work=0
 local function tick() work+=1;if work%200==0 and task then task.wait() end end
 local rocks={R5MountainTier1=true,R5MountainTier2=true,R5MountainTier3=true,R5MountainTier4=true,R5IrregularRockFace=true,Round4TaperChunk=true,TaperedIslandStone=true}
 local tail={R5HangingApex=true,R5SecondaryHangingPoint=true,R5IntentionalFloatingRock=true,LookLightRockTop=true,LookRockFragment=true,LookRockMoss=true,MountainMossTop=true}
 local shades={RGB(211,164,108),RGB(194,140,87),RGB(177,122,77),RGB(161,109,73)}
 for _,p in model:GetDescendants() do
  tick()
  if not p:IsA('BasePart') then continue end
  local y=(p.CFrame.Position-offset).Y
  local free=not p.CanCollide and not p.CanQuery and not p.CanTouch and #p:GetTags()==0 and not p:GetAttribute('Section')
  if free and ((rocks[p.Name] and y < -58) or (tail[p.Name] and y < -58)) then p:Destroy()
  elseif free and rocks[p.Name] and y< -4 then
   p.Color=shades[math.clamp(math.floor(-y/44)+1,1,4)];p.Material=Enum.Material.Sandstone
  end
 end
 local group=Instance.new('Model');group.Name='S8_ErodedStrata';group.Parent=model
 local function part(name,kind,size,cf,color,material,alpha)
  tick()
  local p=Instance.new(kind);p.Name=name;p.Size=size;p.CFrame=C(offset)*cf
  p.Color=color;p.Material=material or Enum.Material.Sandstone;p.Transparency=alpha or 0
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
  p:SetAttribute('Section','S8');p:SetAttribute('Story','Attached exterior; never a landing');p.Parent=group
  return p
 end
 local function boulder(x,y,z,w,h,d,yaw,shade)
  return part('S8_Boulder','WedgePart',V(w,h,d),C(x,y,z)*CFrame.Angles(0,yaw,0)*CFrame.Angles(math.pi,0,0),shades[shade])
 end
 -- Broad full tops are buried in the retained shell or preceding stratum.
 boulder(0,-90,0,196,64,198,.03,1)
 boulder(-10,-120,9,137,70,146,-.18,2)
 boulder(-15,-159,8,88,72,98,.17,3)
 boulder(-22,-201,10,45,62,54,-.12,3)
 boulder(-26,-234,11,12,40,26,.1,4)
 for tier=1,3 do
  local count=if tier==1 then 9 elseif tier==2 then 7 else 5
  local radius=if tier==1 then 91 elseif tier==2 then 59 else 30
  local y=if tier==1 then -96 elseif tier==2 then -133 else -181
  for k=1,count do
   local a=k*math.pi*2/count+.29*tier
   local width=if tier==1 then 55 elseif tier==2 then 43 else 29
   boulder(-tier*6+math.cos(a)*radius,y+(k%3-1)*5,8+math.sin(a)*radius,width,if tier==1 then 64 elseif tier==2 then 68 else 56,width*.95,a+math.pi/2,tier)
  end
 end
 local function stem(a,b,width,name,color)
  local delta=b-a
  return part(name,'Part',V(width,delta.Magnitude,width),C((a+b)/2)*CFrame.lookAt(V(),delta)*CFrame.Angles(math.pi/2,0,0),color,Enum.Material.Wood)
 end
 local anchors={{-166.8,-29,-29.75},{160.67,-29,-42.56},{113,-61,78},{-105,-61,80},{81,-61,-95},{-70,-61,-106},{65,-112,40},{-58,-119,49},{15,-167,30}}
 for i,a in anchors do
  for strand=1,2 do
   local pos=V(a[1]+(strand-1)*2.1,a[2],a[3]);local len=9+(i%3)*2
   for j=1,4 do
    local nextPos=pos+V(math.sin(i+j)*1.8,-len,math.cos(i+j)*1.3)
    stem(pos,nextPos,1.1-j*.14,'S8_HangingRoot',RGB(118,80,43))
    if j%2==0 then for side=-1,1,2 do
     part('S8_VineLeaf','WedgePart',V(1.1,4,2.2),C(nextPos+V(side*.9,1,0))*CFrame.Angles(0,i,.3*side),RGB(92+8*(i%3),141,41),Enum.Material.Grass)
    end end
    pos=nextPos
   end
  end
  part('S8_Moss','WedgePart',V(8,11,2),C(a[1],a[2]-4,a[3])*CFrame.Angles(0,i*.7,math.pi),RGB(99,145,44),Enum.Material.Grass)
 end
 for i,a in {{-161,-24,-30},{157,-24,-44},{97,-61,104}} do
  local height=if i==3 then 133 else 180
  for ribbon=1,3 do
   part('S8_Waterfall','Part',V(if ribbon==2 then 1.3 else .65,height,.22),C(a[1]+(ribbon-2)*.8,a[2]-height/2,a[3]),RGB(173,221,229),Enum.Material.Glass,if ribbon==2 then .4 else .7)
  end
  for j=1,3 do
   local p=part('S8_Mist','Part',V(6+j*2,2+j,5+j*2),C(a[1]+j-2,a[2]-height+j*.7,a[3]),RGB(218,235,230),Enum.Material.SmoothPlastic,.88)
   p.Shape=Enum.PartType.Ball
  end
 end
end
return S
