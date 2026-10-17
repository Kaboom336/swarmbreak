-- Summit camp R4: final reward grounding, door facing and cloth finish.
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
  -- Own both faces at construction; late RouteLabel replication must not leave
  -- the arrival (+X / Back) face blank or let UIWorld replace these captions.
  board:SetAttribute('S7Caption',text);board:SetAttribute('LabelFace','Back');board:SetAttribute('LabelSize',.35)
  require(game:GetService('ReplicatedStorage').UIStyle).sign(board,text)
  for _,gui in board:GetChildren() do
   if gui:IsA('SurfaceGui') then
    gui.AlwaysOnTop=true;gui.MaxDistance=70 -- Keep lettering clear of the overlapping post.
    local label=gui:FindFirstChildOfClass('TextLabel')
    label.Text=text;label.Size=UDim2.fromScale(.9,.84);label.Position=UDim2.fromScale(.05,.08)
   end
  end
  part('ExitBolt'..i,V(.12,.12,.12),frame*CFrame.new(-1.3,0,-.17),{159,149,116},'Metal')
 end
 -- Refinish only the existing nonphysical nest stones; preserve every field
 -- except appearance. Native terrain, lanes and the Keeper are untouched.
 for _,p in model:GetChildren() do tickWork()
  if p.Name=='AcornNest' and p:IsA('BasePart') then
   p.Material=Enum.Material.Slate;p.Color=Color3.fromRGB(106,115,104)
   local gui=Instance.new('SurfaceGui');gui.Name='StoneCarving';gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=64;gui.LightInfluence=.7;gui.Parent=p
   local mark=Instance.new('TextLabel');mark.Size=UDim2.fromScale(1,1);mark.BackgroundTransparency=1;mark.Text='◇';mark.Parent=gui
   require(game:GetService('ReplicatedStorage').UIStyle).lettering(mark,60,10)
   mark.TextColor3=Color3.fromRGB(55,66,61)
  end
 end
 -- Back wall and split entrance flaps use the same rotated tent frame.
 local tent=CFrame.new(-24,48,-103)*CFrame.Angles(0,math.pi/2,0)
 for _,side in {-1,1} do
  local flap=part('TentFlap'..side,V(1.15,3.7,.12),tent*CFrame.new(side*1.15,2,3.02)*CFrame.Angles(0,side*.25,side*.13),{77,96,51},'Fabric')
  beam('TentBackSeam'..side,V(-27,48.3,-103+side*2.5),V(-27,53.9,-103),.12,.12,wood)
  for _,edge in {-1,1} do
   part('TentPeg'..side..edge,V(.22,.5,.22),tent*CFrame.new(side*3.45,.25,edge*3.1),wood)
  end
 end
 part('TentBack',V(2.6,3.4,.12),tent*CFrame.new(0,1.7,-3),green,'Fabric')
 local roll=part('TentDoorRoll',V(3.35,.38,.38),tent*CFrame.new(0,3.95,3.03),{107,121,67},'Fabric');roll.Shape=Enum.PartType.Cylinder
 -- Fire ring, crossed charred logs, quiet embers and two seats in west pocket.
 for i=1,10 do local a=i*math.pi/5
  local rock=part('FireStone'..i,V(.65,.42,.65),CFrame.new(-22+math.cos(a)*1.45,48.21,-114+math.sin(a)*1.45),{103,109,101},'Slate');rock.Shape=Enum.PartType.Ball
 end
 for i=1,3 do
  part('FireLog'..i,V(2,.4,.48),CFrame.new(-22,48.2+(i-1)*.13,-114)*CFrame.Angles(0,i*1.1,0),{65,43,28},'Wood')
 end
 local ember=part('FireEmbers',V(.8,.35,.8),CFrame.new(-22,48.65,-114),{224,111,37},'Neon');ember.Shape=Enum.PartType.Ball
 local fire=Instance.new('PointLight');fire.Color=Color3.fromRGB(255,175,80);fire.Brightness=.7;fire.Range=9;fire.Shadows=false;fire.Parent=ember
 local run=game:GetService('RunService')
 if run.Heartbeat then
  local elapsed=0;local connection
  connection=run.Heartbeat:Connect(function(dt)
   if not ember.Parent then connection:Disconnect();return end
   elapsed+=dt;fire.Brightness=.65+.12*math.sin(elapsed*4)+.04*math.sin(elapsed*9)
  end)
 end
 for _,z in {-117,-110.5} do
  local seat=part('LogSeat'..z,V(3,.8,.8),CFrame.new(-22,48.4,z),wood,'Wood');seat.Shape=Enum.PartType.Cylinder
 end
 -- A single small pile: stolen cups stay exact; add coins and a blue charm.
 for i=1,5 do
  local coin=part('TrinketCoin'..i,V(.15,.55,.55),CFrame.new(-22.4+i*.38,48.09,-108.8)*CFrame.Angles(0,0,math.pi/2),{199,159,66},'Metal');coin.Shape=Enum.PartType.Cylinder
 end
 local charm=part('TrinketCharm',V(.65,.8,.55),CFrame.new(-20.6,48.4,-108.3),{63,132,143},'Glass');charm.Shape=Enum.PartType.Ball
 -- New cloth standard beside the existing fence; no protected panel is moved.
 part('FlagPole',V(.22,5.4,.22),CFrame.new(-26,50.7,-116.5),wood)
 for i=1,4 do
  local frame=CFrame.new(-26+math.sin(i*.8)*.16,52.25-i*.06,-116.82+i*.61)
  part('FlagCloth'..i,V(.12,1.5,.65),frame,{87,113,56},'Fabric')
  for _,side in {-1,1} do
   part('FlagHem'..i..side,V(.14,.1,.65),frame*CFrame.new(0,side*.73,0),{178,153,91},'Fabric')
  end
 end
 part('FlagSleeve',V(.3,1.8,.3),CFrame.new(-26,52.25,-116.5),{87,113,56},'Fabric')
 for _,y in {51.45,53.05} do part('FlagTie'..y,V(.34,.12,.34),CFrame.new(-26,y,-116.5),{178,153,91},'Fabric') end
 local finial=part('FlagFinial',V(.36,.36,.36),CFrame.new(-26,53.5,-116.5),{155,119,62},'Wood');finial.Shape=Enum.PartType.Ball
end
return S
