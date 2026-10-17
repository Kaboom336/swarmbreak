-- Summit encounter: cosmetic silhouette only (R1). All gameplay remains exact.
local S={}
local V=Vector3.new
function S.build(model,origin)
 origin=origin or V(0,0,0)
 local work=0
 local function tickWork() work+=1;if work%300==0 then if task then task.wait() end end end
 local function part(name,size,frame,color,material)
  tickWork()
  local p=Instance.new('Part');p.Name='S7_'..name;p.Size=size;p.CFrame=CFrame.new(origin)*frame
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
  p.Color=Color3.fromRGB(unpack(color));p.Material=Enum.Material[material or 'Wood']
  p:SetAttribute('Section','S7');p:SetAttribute('MeadowV4Category','S7Cosmetic');p.Parent=model
  return p
 end
 local wood={100,66,39};local green={64,92,49}
 local function beam(name,a,b,width,depth,color,mat)
  local up=(b-a).Unit;local right=V(up.Y,-up.X,0).Unit;local back=right:Cross(up)
  return part(name,V(width,(b-a).Magnitude,depth),CFrame.fromMatrix((a+b)/2,right,up,back),color,mat)
 end
 -- Seven-piece A-frame; runners sit on existing flat west mountain top at Y48.
 for _,side in {-1,1} do
  part('TentRunner'..side,V(.55,.25,6.4),CFrame.new(-24+side*3.2,48.125,-103),wood)
  beam('TentCanvas'..side,V(-24+side*3.2,48.34,-103),V(-24,54.34,-103),.2,6,green,'Fabric')
  beam('TentStrut'..side,V(-24+side*3.2,48.34,-99.86),V(-24,54.34,-99.86),.25,.25,wood)
 end
 part('TentRidge',V(.4,.4,6.6),CFrame.new(-24,54.34,-103),wood)
 -- Each bay is a four-piece assembly; routes remain broad, genuine open gaps.
 local function bay(id,x,z,length,west)
  for _,side in {-1,1} do
   local p=part('FencePost'..id..side,V(.5,2.8,.5),CFrame.new(x+(west and 0 or side*length/2),49.4,z+(west and side*length/2 or 0)),wood)
   if id=='south' and side==1 then
    -- Silhouette light study; no ornamental lamp or fake treasure geometry.
    local light=Instance.new('PointLight');light.Color=Color3.fromRGB(255,222,142)
    light.Brightness=1.5;light.Range=18;light.Shadows=false;light.Parent=p
   end
  end
  for _,y in {49,50} do
   part('FenceRail'..id..y,west and V(.26,.24,length) or V(length,.24,.26),CFrame.new(x,y,z),wood)
  end
 end
 bay('south',-2,-86,8,false)
 bay('north',-6,-130,8,false)
 bay('west',-26,-114,6,true)
end
return S
