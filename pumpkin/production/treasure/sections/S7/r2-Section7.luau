-- Summit encounter R2; R1 fence frozen, all original gameplay/art exact.
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
 -- R2 gap 1: lift the second reward source above the low rail. Four attached pieces.
 part('RewardLampStem',V(.32,3,.32),CFrame.new(2,52.3,-86),wood)
 part('RewardLampFoot',V(.85,.2,.85),CFrame.new(2,53.9,-86),{53,49,40},'Metal')
 local glass=part('RewardLampGlass',V(.55,.8,.55),CFrame.new(2,54.4,-86),{222,183,98},'Glass')
 glass.Transparency=.35
 part('RewardLampCap',V(.85,.2,.85),CFrame.new(2,54.9,-86),{53,49,40},'Metal')
 local light=Instance.new('PointLight');light.Color=Color3.fromRGB(255,224,148)
 light.Brightness=1.5;light.Range=18;light.Shadows=false;light.Parent=glass
 -- R2 gap 2: the seven original tent pieces rotate together, entrance toward +X.
 local pivot=CFrame.new(origin+V(-24,48,-103))
 for _,p in model:GetChildren() do tickWork()
  if p:IsA('BasePart') and p:GetAttribute('Section')=='S7' and p.Name:match('^S7_Tent') then
   p.CFrame=pivot*CFrame.Angles(0,math.pi/2,0)*pivot:Inverse()*p.CFrame
  end
 end
 -- Three stolen cups, each a body and lip: a single six-piece story group.
 for i,g in {{-25,-108.2,1.0,{64,105,114}},{-23,-108.2,1.3,{123,80,52}},{-21,-108.2,.8,{83,113,68}}} do
  local x,z,h,color=g[1],g[2],g[3],g[4]
  part('StolenCupBody'..i,V(.7,h,.7),CFrame.new(x,48+h/2,z),color,'SmoothPlastic')
  part('StolenCupLip'..i,V(.85,.15,.85),CFrame.new(x,48+h+.075,z),{139,131,103},'SmoothPlastic')
 end
 -- R2 gap 3: one post, two route boards, two bolts; attached and off every lane.
 part('ExitPost',V(.5,4,.5),CFrame.new(22,50,-94),wood)
 for i,text in {'SHELF  >','SPIRAL  >'} do
  local frame=CFrame.new(21.64,52.2-(i-1)*1.4,-94)*CFrame.Angles(0,math.pi/2,0)
  local board=part('ExitBoard'..i,V(3.1,1.2,.22),frame,wood)
  board:SetAttribute('RouteLabel',text);board:SetAttribute('LabelFace','Front');board:SetAttribute('LabelSize',.35)
  local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=96;gui.LightInfluence=.15;gui.Parent=board
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(.9,.84);label.Position=UDim2.fromScale(.05,.08)
  label.BackgroundTransparency=1;label.Text=text;label.Parent=gui
  require(game:GetService('ReplicatedStorage').UIStyle).lettering(label,80,12)
  part('ExitBolt'..i,V(.12,.12,.12),frame*CFrame.new(-1.3,0,-.17),{159,149,116},'Metal')
 end
end
return S
