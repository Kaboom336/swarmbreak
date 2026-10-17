-- C2 R3/R4 visual children only. No authoritative loot or cart field is assigned.
return function(map,root,round)
 local final=round=='r4'
 local geode=assert(map:FindFirstChild('Geode'))
 if root:FindFirstChild('CampDress')then return {already_complete=true}end
 local camp=Instance.new('Folder');camp.Name='CampDress'
 local jewel=Instance.new('Model');jewel.Name='C2_GeodeArt'
 local count=0
 local function piece(parent,name,position,size,color,material,angles,shape)
  local p=Instance.new(shape=='Wedge'and'WedgePart'or'Part')
  p.Name='C2_'..name;p.Size=Vector3.new(unpack(size))
  p.CFrame=CFrame.new(unpack(position))*(angles and CFrame.Angles(unpack(angles))or CFrame.identity)
  p.Color=Color3.fromRGB(unpack(color));p.Material=Enum.Material[material or'Slate']
  if shape=='Cylinder'then p.Shape=Enum.PartType.Cylinder end
  p.Anchored=true;p.Massless=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
  p:SetAttribute('C2Cosmetic',true);p.Parent=parent;count+=1
  if count%20==0 then task.wait()end
  return p
 end
 local rock={66,68,87};local edge={133,116,151};local violet={180,65,240};local pink={245,146,255};local wood={111,75,48};local iron={62,72,88}
 local function shard(parent,name,x,y,z,h,w,col,lean)
  piece(parent,name..'Shaft',{x,y+h*.35,z},{w,h*.7,w},col,'Neon',{lean or 0,.65,.1})
  for i=0,3 do
   local a=i*math.pi/2
   local p=piece(parent,name..'Point',{x,y+h*.85,z},{w,h*.3,w/2},col,'Neon',nil,'Wedge')
   p.CFrame=CFrame.new(x,y+h*.85,z)*CFrame.Angles(0,a,0)*CFrame.new(0,0,-w/4)
  end
 end
 -- A low octagonal cut plinth. All bearings sit above the unchanged +48 floor.
 for i=0,(final and 1 or 3)do
  piece(jewel,'Pedestal',{160,48.24,-120},final and {5.8,.42,5.8}or{6.6,.42,4.4},rock,'Slate',{0,i*math.pi/4,0})
 end
 piece(jewel,'PedestalInset',{160,48.52,-120},{5.4,.14,5.4},edge,'Slate',{0,math.pi/4,0})
 -- Broken outer rind: staggered angular plates, open on the southwest face.
 for row=0,2 do for i=0,11 do
  local a=i*math.pi/6+row*.11
  local front=math.cos(a)<-.1 and math.sin(a)>.1
  if not front or row==0 then
   local r=final and (row==2 and 2.25 or 2.6)or(row==2 and 1.65 or 2.08)
   piece(jewel,'BrokenRockShell',{160+math.cos(a)*r,49.35+row*1.55,-120+math.sin(a)*r},final and {1.7,1.8,1.2}or{1.32,1.95,.85},i%3==0 and edge or rock,'Slate',{.12*(i%3-1),-a+.5,.22*(i%2==0 and 1 or -1)},'Wedge')
  end
 end;task.wait()end
 -- Front quartz facets cover the smooth loot surface without changing that part.
 local crystals=final and {{-1.8,.1,1.5,3.6,.85},{1,.1,1.9,3.4,.7}}or{{-1.25,.2,1.45,3.9,.9},{-.3,.05,1.95,4.8,1.1},{.9,.1,1.65,3.4,.85},{-1.8,.1,.45,3.2,.8},{.5,.2,-.3,5.4,1.0}}
 for i,g in crystals do
  shard(jewel,'TreasureCrystal'..i,160+g[1],48.8+g[2],-120+g[3],g[4],g[5],i%2==0 and pink or violet)
 end
 if final then
  -- An actual eight-sided prism assembled from two bars and four triangular
  -- corner sectors; no smooth egg silhouette or oversized square gem face.
  piece(jewel,'CavityCrystal',{160,51.2,-120},{4.2,5.5,2.1},{151,52,206},'Neon')
  piece(jewel,'CavityCrystal',{160,51.2,-120},{2.1,5.5,4.2},{169,63,219},'Neon')
  for i=0,3 do
   local a=i*math.pi/2
   local corner=piece(jewel,'CavityFacet',{160,51.2,-120},{5.5,1.05,1.05},i%2==0 and{137,47,192}or{188,82,227},'Neon',nil,'Wedge')
   corner.CFrame=CFrame.new(160,51.2,-120)*CFrame.Angles(0,a,0)*CFrame.new(-1.575,0,-1.575)*CFrame.Angles(0,0,math.pi/2)
  end
  for i=0,3 do
   local tip=piece(jewel,'CavityCrown',{160,54.15,-120},{4.1,.9,2.05},{194,89,235},'Neon',nil,'Wedge')
   tip.CFrame=CFrame.new(160,54.15,-120)*CFrame.Angles(0,.35+i*math.pi/2,0)*CFrame.new(0,0,-1.025)
  end
  for i=0,3 do
   piece(jewel,'CrystalFracture',{158.4+i*.65,50.2+i*.85,-117.7},{.07,.95,.08},{238,164,255},'Neon',{0,0,i%2==0 and .6 or -.6})
  end
 end
 local glow=piece(jewel,'GeodeGlow',{158.8,51,-117.6},{.12,.12,.12},pink,'Neon');glow.Transparency=1
 local l=Instance.new('PointLight');l.Name='C2_SoftGlow';l.Brightness=.85;l.Range=12;l.Shadows=false;l.Color=Color3.fromRGB(222,119,255);l.Parent=glow
 for i,g in {{-2.7,53,1.6},{1.5,54.6,.5},{-.8,55.1,1.2},{2.5,51.8,1.2}}do
  piece(jewel,'FloatingSparkle'..i,{160+g[1],g[2],-120+g[3]},{.14,.28,.14},pink,'Neon',{0,0,.7})
 end
 -- Stone/dirt edge, flush veneers rather than a new physical floor.
 for i=0,6 do
  piece(camp,'WorkedStone',{143+i*6,48.055,-142.5},{5.8,.05,2.5},{91+i%3*7,83+i%3*6,95},'Slate',{0,.03*(i%2),0})
 end
 for i=0,4 do
  piece(camp,'DirtPatch',{153+i*5,48.045,-137},{4.8,.03,6},{115+i%2*9,94+i%2*7,85},'Ground')
 end
 -- Pickaxes on an explicit timber rack, away from the objective/exit fan.
 for _,x in {177,183}do piece(camp,'ToolRackPost',{x,51,-143},{.55,5.9,.6},wood,'Wood')end
 piece(camp,'ToolRackRail',{180,52.5,-142.9},{7,.6,.6},wood,'Wood')
 for i=0,2 do
  piece(camp,'PickHandle',{178+i*2,51.5,-142.2},{.28,4.2,.28},wood,'Wood',{0,0,-.22})
  piece(camp,'PickHead',{178.4+i*2,53.1,-142.2},{2.1,.35,.42},{148,157,170},'Metal',{0,0,.15},'Wedge')
 end
 -- Group the existing supply crates with a sagging split tarp and rope ties.
 for i=0,2 do
  piece(camp,'Tarp',{168+i*4,52.25-math.sin(i*math.pi/2)*.45,-145},{4.2,.15,5},{70,109,118},'Fabric',{0,0,i==0 and -.12 or .12})
 end
 for _,x in {168,176}do piece(camp,'TarpTie',{x,50,-142.4},{.1,4,.1},{159,134,95},'Fabric')end
 for _,x in {174,178}do
  piece(camp,'LampPost',{x,51.7,-146.5},{.55,7.3,.55},wood,'Wood')
  piece(camp,'LampCap',{x,55.6,-146.5},{1.8,.25,1.8},iron,'Metal')
  local lamp=piece(camp,'LampGlass',{x,54.7,-146.5},{1.2,1.5,1.2},{255,183,76},'Neon')
  local light=Instance.new('PointLight');light.Brightness=.65;light.Range=10;light.Shadows=false;light.Color=lamp.Color;light.Parent=lamp
 end
 for i=0,3 do
  shard(camp,'RockVein'..i,138+i*1.2,49.5+i%2*2,-146.3,2+i%2,.42,{75,171,195})
 end
 if final then
  for i=0,2 do
   local x=170+i*3
   piece(camp,'SupplyCrate',{x,49.75,-138.5},{2.8,3.4,3.2},wood,'Wood')
   for _,dx in {-1.12,1.12}do piece(camp,'CrateStrap',{x+dx,49.75,-136.85},{.22,3.5,.12},{179,139,88},'Wood')end
   piece(camp,'VisibleTarp',{x,51.55,-139},{3.05,.12,3.8},{64,113,127},'Fabric',{0,0,(i-1)*.09})
  end
  for _,x in {170,176}do piece(camp,'VisibleRackPost',{x,52,-140.8},{.4,7.8,.4},wood,'Wood')end
  piece(camp,'VisibleRackRail',{173,54,-140.8},{6.5,.4,.4},wood,'Wood')
  for _,x in {172,174}do
   piece(camp,'VisiblePickHandle',{x,53,-140.3},{.22,3.8,.22},wood,'Wood',{0,0,.18})
   piece(camp,'VisiblePickHead',{x-.25,54.3,-140.3},{1.8,.3,.35},{159,168,180},'Metal',{0,0,-.14},'Wedge')
  end
  for _,x in {127.58,136.42}do
   piece(camp,'CartUpperBand',{x,52.65,-93},{.14,.35,9.9},{119,133,148},'Metal')
   for _,z in {-96.5,-93,-89.5}do
    piece(camp,'CartSteelRib',{x,51.4,z},{.18,2.6,.34},{99,113,129},'Metal')
    for _,y in {50.4,52.35}do piece(camp,'CartRivet',{x+(x<132 and -.12 or .12),y,z},{.12,.22,.22},{177,170,147},'Metal')end
   end
  end
 end
 -- The parked static cart keeps every original field; these are a rim and ore load.
 for _,x in {127.8,136.2}do piece(camp,'CartRim',{x,53.15,-93},{.32,.45,10.6},iron,'Metal')end
 for _,z in {-98.2,-87.8}do piece(camp,'CartRim',{132,53.15,z},{8.6,.45,.32},iron,'Metal')end
 for _,x in {127.6,136.4}do for _,z in {-96,-90}do
  piece(camp,'CartWheel',{x,49.25,z},{.7,2.4,2.4},iron,'Metal',nil,'Cylinder')
  piece(camp,'CartHub',{x+(x<132 and -.4 or .4),49.25,z},{.16,.8,.8},{140,145,153},'Metal',nil,'Cylinder')
 end end
 for i=0,5 do
  piece(camp,'CartOre',{130+i%3*2,53.4+math.floor(i/3)*.55,-95+math.floor(i/3)*3},{2.3,1.6,2.2},rock,'Slate',{.1,i*.6,.2},'Wedge')
 end
 shard(camp,'CartGem',132,53.4,-93,2.2,.65,{86,185,212})
 -- The distracting inverted block is the distant x500 island seen above the loot.
 -- Remove only its cosmetic rock stack and contiguous crystal recipes, not colliders.
 local hidden=0;local selected=false
 for i,p in map:GetChildren()do
  if i%200==0 then task.wait()end
  if p:IsA('BasePart')then
   if p.Name=='CrystalShaft'then selected=p.CFrame.X>475 and p.CFrame.X<535 and p.CFrame.Z< -90 and p.CFrame.Z> -150
   elseif not p.Name:match('^Crystal')then selected=false end
   if not p.CanCollide and (selected or(p.Name=='R3DistantIsland'and p.CFrame.X>=500 and p.CFrame.X<=504 and p.CFrame.Z== -120))then
    p.Transparency=1;hidden+=1
    for _,child in p:GetChildren()do if child:IsA('Light')then child.Enabled=false end end
   end
  end
 end
 jewel.Parent=geode;camp.Parent=root
 return {parts=count,hidden_distant_cosmetics=hidden,round=round}
end
