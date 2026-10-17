-- Offline native-part builder. Reuses Meadow v4's manifest/CFrame/slab pattern;
-- source modules are mounted from prototype/core, never copied into source.
-- Section entrypoint: preserve the current six-suite place; never run the
-- historical baseline generator below for section work.
if (require('@lune/process').args[1] or ''):match('^c2%-') then
 require('../../treasure/cave-sections/C2/build')()
 return
end
if (require('@lune/process').args[1] or ''):match('^c1%-') then
 require('../../treasure/cave-sections/C1/build')()
 return
end
local fs, rb, serde, luau = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde'), require('@lune/luau')
local V, C = rb.Vector3, rb.CFrame
local stage=tonumber(require('@lune/process').args[1] or '4')
local routes = serde.decode('json',fs.readFile('treasure/cave-v2/ROUTES.json')).routeCenterlines
-- The approved illustrative centerline starts its cave descent inside the solid
-- camp. Exit the terrace first, then descend at <=25 degrees. This measured
-- greybox correction preserves the east/south cave choice and all destinations.
routes.cave={{160,120,48},{190,120,48},{214,98,48},{214,22,16},{190,-25,0},{140,-50,0},{80,-35,0},{40,-90,0},{-20,-70,0},{-70,-110,0},{-124,-120,0}}
routes.crosslinkNorth={{40,120,24},{45,65,24},{45,20,24},{105,20,24},{125,-35,0},{140,-50,0}}
routes.pitRecovery={{0,-25,-16},{-15,-25,-16},{-15,10,-16},{-25,10,-16},{-100,10,8},{-105,-35,8},{-70,-65,8}}
routes.crosslinkSouth={{-150,0,8},{-105,-35,8},{-70,-65,8},{-60,-65,8},{-35,-70,0},{-20,-70,0}}
routes.railWalkBypass={{130,90,48},{85,60,32},{45,20,24},{-30,20,24},{-55,-10,24},{-70,-45,8},{-70,-65,8},{-105,-100,0},{-126,-96,0}}
routes.cartRail={{130,90,48},{85,60,32},{45,20,24},{15,-10,24},{-15,-40,24},{-45,-54,24},{-70,-65,8},{-105,-100,0},{-126,-96,0}}
local place = rb.Instance.new('DataModel')
local ws=rb.Instance.new('Workspace'); ws.Parent=place
local model=rb.Instance.new('Model');model.Name='CaveV2';model.Parent=ws
local parts, routeData, lights = {}, {}, {}
local slate={69,78,100};local purple={97,83,122};local wood={104,68,43};local cyan={54,224,245};local violet={167,83,255}
local rock={{76,79,108},{88,92,122},{105,107,141},{145,140,170}}
local function xyz(a) return V.new(a[1],a[3],-a[2]) end
local function part(name,cat,cf,size,color,collide,mat,shape)
 local p=rb.Instance.new(shape=='Wedge' and 'WedgePart' or 'Part');p.Name=name;p.Anchored=true;p.CanCollide=collide==true;p.CanQuery=true;p.CanTouch=false;p.Size=size;p.CFrame=cf;p.Color=rb.Color3.fromRGB(unpack(color));p.Material=rb.Enum.Material[mat or 'Slate'];p.Parent=model
 p:SetAttribute('CaveCategory',cat)
 if shape=='Ball' then p.Shape=rb.Enum.PartType.Ball end
 -- Explicit basis vectors match the row-major manifest and avoid ambiguity
 -- in offline helper conventions. The native CFrame is exported unchanged.
 local right,up,back=cf.RightVector,cf.UpVector,-cf.LookVector
 local rot={right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z}
 table.insert(parts,{name=name,category=cat,position={cf.Position.X,cf.Position.Y,cf.Position.Z},size={size.X,size.Y,size.Z},rotation=rot,color=color,collidable=collide==true,material=mat or 'Slate',shape=shape or 'Block',transparency=0})
 return p
end
local function glow(p,brightness,range)
 local l=rb.Instance.new('PointLight');l.Color=p.Color;l.Brightness=brightness;l.Range=range;l.Shadows=true;l.Parent=p
 local q=p.CFrame.Position
 table.insert(lights,{position={q.X,q.Y,q.Z},color={p.Color.R*255,p.Color.G*255,p.Color.B*255},brightness=brightness,range=range})
end
local function box(name,cat,a,size,color,collide,mat,shape) return part(name,cat,C.new(xyz(a)),V.new(size[1],size[3],size[2]),color,collide,mat,shape) end
local function frame(position,target)
 -- Lune 0.10.5 lookAt incorrectly places pitch in the cross axis for this
 -- builder. Explicit orthonormal rows match Roblox and the Meadow slab pattern.
 local back=(position-target).Unit;local right=V.yAxis:Cross(back).Unit;local up=back:Cross(right)
 return C.new(position.X,position.Y,position.Z,right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z)
end
local function slab(name,cat,a,b,width,thickness,color,collide,mat)
 local aa,bb=xyz(a),xyz(b);local look=frame((aa+bb)/2,bb)
 return part(name,cat,look*C.new(0,-thickness/2,0),V.new(width,thickness,(bb-aa).Magnitude+.6),color,collide,mat)
end
local function nearest(x,z,pts)
 local best,yy=math.huge,0
 for i=1,#pts-1 do local a,b=pts[i],pts[i+1];local dx,dz=b[1]-a[1],b[2]-a[2];local t=math.clamp(((x-a[1])*dx+(z-a[2])*dz)/(dx*dx+dz*dz),0,1);local d=math.sqrt((x-a[1]-dx*t)^2+(z-a[2]-dz*t)^2);if d<best then best,yy=d,a[3]+(b[3]-a[3])*t end end
 return best,yy
end
-- Whole terrain is stacked rock volume, with four readable elevation districts.
-- Route clearance is carved before emitting each native collider; no audit exemptions.
for x=-240,240,10 do for z=-180,180,10 do
 local angle=math.atan2(z/195,x/255)
 local radius=stage>=2 and (1+.065*math.sin(angle*5)+.045*math.cos(angle*9)) or 1
 local outline=(x/255)^2+(z/195)^2<radius^2
 if stage>=3 then
  outline=((x+146)/75)^2+((z+111)/65)^2<1 or ((x+127)/99)^2+((z-52)/103)^2<1 or ((x-138)/104)^2+((z-116)/93)^2<1 or ((x-135)/107)^2+((z+56)/88)^2<1 or ((x+10)/142)^2+((z+54)/113)^2<1
 end
 if outline then
  local top=-2
  if z>36 or (x<-90 and z>12) then top=24 end
  if ((x-143)/89)^2+((z-125)/63)^2<1 then top=48 end
  if stage>=3 then
   -- The playable camp remains +48. High natural rock shoulders, not the
   -- crystal alone, establish the summit silhouette behind its terrace.
   local summit=math.sqrt(((x-140)/94)^2+((z-163)/60)^2)
   if summit<1 then top=math.max(top,48+math.floor((1-summit)*6)*16) end
   local west=math.sqrt(((x+156)/61)^2+((z-99)/65)^2)
   if west<1 then top=math.max(top,24+math.floor((1-west)*5)*14) end
   -- Crystal root pocket stays on the camp mesa and exposes the whole hero.
   if ((x-163)/25)^2+((z-153)/25)^2<1 then top=48 end
  end
  if x<-95 and z>-30 and z<36 then top=8 end
  if math.abs(x)<46 and z<32 and z>-70 then top=-19 end
  -- Broaden sloped shoulders while respecting every inherited lane and rail.
  for _,pts in routes do local d,y=nearest(x,z,pts);if d<33 and y>top and not (math.abs(x)<46 and z<32 and z>-70) then top=math.floor((y-2)/8)*8 end end
  for _,pts in routes do local d,y=nearest(x,z,pts);if d<20 then top=math.min(top,y-2.1) end end
  local bottom=-44;local n=math.ceil((top-bottom)/8);local h=(top-bottom)/n
  for k=1,n do
   local color=rock[1+(math.abs(math.floor(x/10)*7+math.floor(z/10)*3+k*5)%3)]
   if k==n then color=rock[4] end
   local inset=0
   box('StackedMesaRock','mass',{x,z,bottom+(k-.5)*h},{10.05-inset,10.05-inset,h+.06},color,true)
  end
 end
end end
-- Offset interlocking mountain tiers, with a narrow hanging keel rather than a disc.
for i=1,9 do
 local radius=({226,182,148,120,95,73,53,34,21})[i];local y=-42-i*16;local ox=stage>=2 and math.sin(i*.8)*13 or 0;local oz=stage>=2 and math.cos(i*.9)*9 or 0
 for x=-radius,radius,14 do for z=-radius*.78,radius*.78,14 do
  local angle=math.atan2(z,x);local edge=stage>=2 and (1+.09*math.sin(angle*5+i*.5)) or 1
  if (x/radius)^2+(z/(radius*.8))^2<edge^2 then box('InvertedMountainFacet','underside',{x+ox,z+oz,y},{14.1,14.1,33},rock[1+(math.abs(math.floor(x/14)+math.floor(z/14)+i)%3)],true) end
 end end
end
if stage>=2 then
 -- Authored lobes on the exterior, rooted into existing tier volumes. Each
 -- lobe has its own staggered taper so the outline is not concentric rings.
 for index,a in {{-205,-82,0,65},{-151,-148,0,86},{-74,-167,0,126},{21,-162,0,155},{124,-125,0,109},{204,-50,0,78},{221,67,0,71},{161,170,24,97},{-113,139,24,83},{-223,42,8,59}} do
  for k=0,math.floor(a[4]/12) do
   local radius=math.max(4,19-k*1.45);local y=-20-k*12
   for dx=-1,1 do for dz=-1,1 do
    if math.abs(dx)+math.abs(dz)<2 then
     box('HangingRockLobe','underside',{a[1]+dx*radius*.55+math.sin(index+k)*2,a[2]+dz*radius*.55,y},{radius*.9,radius*.9,15},rock[1+((index+k+dx+3)%3)],true)
    end
   end end
  end
 end
 -- Small deliberate floating satellites are noncollidable art, outside routes.
 for index,a in {{-292,-15,-58},{284,76,-89},{-241,-184,-128},{104,-230,-70},{258,-131,-151},{-92,219,-65}} do
  for k=0,3 do local s=18-k*3.5;box('FloatingRock','floating-rock',{a[1]+k*1.7,a[2]-k,a[3]-k*10},{s,s,12},rock[1+((index+k)%3)],false) end
 end
end
-- Broad supported route slabs; joins use overlap and full-width junction pads.
for name,pts in routes do
 local width=18
 routeData[name]={points=pts,width=width,category=name=='cartRail' and 'rail' or 'lane'}
 if name~='cartRail' then
  for i=1,#pts-1 do slab(name..i,'lane',pts[i],pts[i+1],width,2,stage>=3 and {136,124,139} or purple,true) end
  for i=1,#pts-1 do local a,b=pts[i],pts[i+1];local n=math.ceil((xyz(b)-xyz(a)).Magnitude/9);for j=0,n do local t=j/n;local x,z,y=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t
   -- Lower routes take precedence under crossings: no invisible support wall.
   local top=y-1.8;for other,otherPts in routes do if other~='cartRail' then local d,otherY=nearest(x,z,otherPts);if d<width*.5+21 then top=math.min(top,otherY-2) end end end
   local h=top+40;local count=math.ceil(h/8)
   -- The high cross-canyon lanes are carried by timber trestles, not a
   -- continuous stone wall that conceals the pit and the rail crossing.
   if not (stage>=3 and math.abs(x)<49 and z<35 and z>-66 and y>7) then
    for k=1,count do box('RouteRockButtress','support',{x,z,-40+(k-.5)*h/count},{width+5,10,h/count+.08},rock[1+((j+k)%3)],true) end
   end
  end end
 end
end
box('GeodeCamp','lane',{160,120,47},{48,48,2},purple,true)
-- Camp surface is +48; its giant crystal is rooted into the mesa itself.
box('SafetyApron','lane',{-150,-120,-1},{48,40,2},slate,true)
box('PitFloor','lane',{0,-25,-17},{56,56,2},slate,true)
-- Rail ties/steel use no passenger collision. Gap is exactly sixteen studs.
local rail=routes.cartRail
local distance=0;local gapStart,gapEnd
for i=1,#rail-1 do local a,b=rail[i],rail[i+1];local len=(xyz(b)-xyz(a)).Magnitude
 for j=0,math.floor(len/3) do local t=j*3/len;local q=xyz(a):Lerp(xyz(b),t);local at=distance+j*3
  local gap=i==4 and math.abs(t-.5)<8/len
  if not gap then local tie=part('RailSleeper','rail',frame(q,xyz(b))*C.new(0,.3,0),V.new(9,.6,1),wood,false,'Wood'); for off=-3,3,6 do part('SteelRail','rail',tie.CFrame*C.new(off,.5,0),V.new(.45,.6,3.3),{137,148,164},false,'Metal') end end
 end
 if i==4 then gapStart=distance+len/2-8;gapEnd=distance+len/2+8 end
 distance+=len
end
box('BreakableSpan','span',{0,-25,23},{16,16,2},wood,true,'Wood')
box('BroadLanding','lane',{-19,-44,23},{32,24,2},purple,true)
box('SpanBearingBeam','span',{0,-25,21},{62,4,2},wood,true,'Wood')
for x=-29,29,58 do box('SpanBearingPier','support',{x,-25,-10},{3,4,64},wood,true,'Wood') end
box('LandingRockBearing','support',{-19,-49,-10},{32,14,64},slate,true)
for _,a in {{85,60,32},{45,20,24},{15,-10,24},{-15,-40,24},{-70,-65,8}} do
 local h=a[3]+39;for off=-6,6,12 do box('TrestleTimberPier','prop',{a[1]+off,a[2],a[3]-h/2},{2.5,2.5,h},wood,false,'Wood') end
 slab('TrestleCrossBrace','prop',{a[1]-6,a[2],-30},{a[1]+6,a[2],a[3]-2},2,2,wood,false,'Wood')
end
box('PaddedSidingFloor','lane',{-94,-50,7},{24,24,2},purple,true)
box('PaddedBumper','prop',{-104,-50,10},{3,22,5},{190,131,70},false,'Wood')
box('ParkedMineOreCart','prop',{132,93,51},{8,10,4},{72,81,96},false,'Metal')
for off=-4,4,8 do box('ParkedOreCartWheel','prop',{132+off,96,49},{1.5,2,2},{38,42,52},false,'Metal','Ball') end
-- A roofed two-ended cavern with thirty studs clearance and three open skylights.
for i=5,8 do local a,b=routes.cave[i],routes.cave[i+1]
  -- Two roof pieces leave a genuine eight-stud skylight at each interior joint.
 local gap=8/(xyz(b)-xyz(a)).Magnitude
 for _,range in {{0,.45-gap/2},{.45+gap/2,1}} do local aa,bb={},{};for axis=1,3 do aa[axis]=a[axis]+(b[axis]-a[axis])*range[1];bb[axis]=a[axis]+(b[axis]-a[axis])*range[2] end;aa[3]+=33;bb[3]+=33;slab('CaveThickRoof','roof',aa,bb,46,5,slate,true) end
 local dx,dz=b[1]-a[1],b[2]-a[2];local l=math.sqrt(dx*dx+dz*dz)
 for side=-1,1,2 do local ox,oz=-dz/l*22*side,dx/l*22*side
  -- Short wall sections are omitted beside junction and cross-link envelopes.
  local n=math.ceil(l/7);for j=1,n-1 do local t=j/n;local x,z=a[1]+dx*t+ox,a[2]+dz*t+oz;local clear=true
   for _,pts in routes do if nearest(x,z,pts)<20 then clear=false end end
   if clear then for k=0,3 do box('CavernSidewall','wall',{x,z,2+k*8},{6,6,8.1},rock[1+((j+k)%3)],true) end end
  end
 end
end
local function crystal(x,z,y,s,col,down,lean,lit)
 -- Four WedgeParts form a real four-sided point; tilted companion crystals
 -- use this same native recipe, not renderer-only geometry.
 local cf=C.new(xyz({x,z,y}))*C.Angles(down and math.pi or (lean or 0),(x+z)*.13,lean or 0)
 local width=s*.27
 local p=part('CrystalShaft','crystal',cf*C.new(0,s*.4,0),V.new(width,s*.8,width),col,false,'Neon')
 -- Native inset facets and thin edges give the gem a readable internal shape.
 if stage>=3 and s>8 then
  local dark={math.floor(col[1]*.44),math.floor(col[2]*.38),math.floor(col[3]*.64)}
  part('CrystalInsetFacet','crystal',cf*C.new(0,s*.42,0)*C.Angles(0,math.pi/4,0),V.new(width*.82,s*.79,width*.82),dark,false,'Neon')
  -- Exposed darker faces give the native gem depth; the emissive body and
  -- edge lines remain visible. These facets are included in the saved place.
  part('CrystalDarkFace','crystal',cf*C.new(-width*.506,s*.4,0),V.new(width*.025,s*.79,width*.98),dark,false,'SmoothPlastic')
  local mid={math.floor(col[1]*.65),math.floor(col[2]*.58),math.floor(col[3]*.83)}
  part('CrystalPrismFace','crystal',cf*C.new(0,s*.4,-width*.506),V.new(width*.98,s*.79,width*.025),mid,false,'SmoothPlastic')
  local edge={math.min(255,col[1]+70),math.min(255,col[2]+60),255}
  for xside=-1,1,2 do for zside=-1,1,2 do
   local x,z=xside*width*.5,zside*width*.5
   part('CrystalFacetEdge','crystal',cf*C.new(x,s*.4,z),V.new(math.max(.12,s*.005),s*.8,math.max(.12,s*.005)),edge,false,'Neon')
   local aa,bb=cf:PointToWorldSpace(V.new(x,s*.8,z)),cf:PointToWorldSpace(V.new(0,s*1.22,0))
   part('CrystalTipEdge','crystal',frame((aa+bb)/2,bb),V.new(math.max(.12,s*.005),math.max(.12,s*.005),(bb-aa).Magnitude),edge,false,'Neon')
  end end
 end
 for turn=0,3 do part('CrystalPoint','crystal',cf*C.new(0,s*.95,0)*C.Angles(0,turn*math.pi/2,0)*C.new(0,0,-width/4),V.new(width,s*.3,width/2),col,false,'Neon','Wedge') end
 for turn=0,1 do part('CrystalNeedle','crystal',cf*C.new(0,s*1.13,0)*C.Angles(0,turn*math.pi,0)*C.new(0,0,-width*.08),V.new(width*.32,s*.18,width*.16),col,false,'Neon','Wedge') end
 if stage>=3 and lit~=false then glow(p,1.8,math.min(40,s*1.3)) end
end
if stage>=2 then
 for index,a in {{-211,-88,-70},{-153,-155,-98},{-74,-171,-137},{21,-169,-165},{124,-130,-122},{210,-53,-94},{224,66,-83},{163,174,-110},{-113,144,-95},{-227,42,-71},{6,3,-192}} do
  for i=1,5 do crystal(a[1]+(i-3)*5,a[2]+(i%2)*5,a[3],({22,33,49,29,18})[i],(i+index)%2==0 and cyan or violet,true,.05*(i-3)) end
 end
end
-- The huge crown is behind the camp: clear portal silhouette and clear route fan.
for _,a in {{163,153,48,122},{146,151,48,57},{182,152,48,63},{158,170,48,38},{183,173,48,31},{132,157,48,29},{175,135,48,25}} do crystal(a[1],a[2],a[3],a[4],a[1]%2==0 and cyan or violet,false,(a[1]-163)*.004) end
if stage>=3 then
 for group,a in {{-183,-91,0},{-183,40,24},{-167,112,64},{82,152,48},{185,-28,0},{114,-98,0},{-66,21,24}} do
  for i=1,7 do local dx=(i-4)*3;local dz=(i%3)*4;local x,z=a[1]+dx,a[2]+dz;local safe=true;for _,pts in routes do if nearest(x,z,pts)<21 then safe=false end end
   if safe then crystal(x,z,a[3]-3,({7,13,22,31,17,12,6})[i]*(.7+group*.075),i%3==0 and cyan or violet,false,(i-4)*.1) end
  end
 end
end
for i=1,14 do local angle=i/14*math.pi*2;local x,z=159*math.cos(angle),126*math.sin(angle)
 box('SideUndersideCrystal','crystal',{x,z,-106},{7,7,30},i%2==0 and cyan or violet,false,'Neon')
 local point=box('SideUndersideCrystalTip','crystal',{x,z,-126},{7,7,10},violet,false,'Neon','Wedge');point.CFrame=point.CFrame*C.Angles(math.pi,0,0)
 local item=parts[#parts];local r,u,b=point.CFrame.RightVector,point.CFrame.UpVector,-point.CFrame.LookVector;item.rotation={r.X,u.X,b.X,r.Y,u.Y,b.Y,r.Z,u.Z,b.Z}
end
for _,a in {{8,0,-195,34},{35,12,-163,31},{-92,95,-99,28},{120,80,-82,29}} do
 box('UndersideCrystalShaft','crystal',{a[1],a[2],a[3]-a[4]*.5},{a[4]*.3,a[4]*.3,a[4]},violet,false,'Neon')
 local point=box('UndersideCrystalTip','crystal',{a[1],a[2],a[3]-a[4]*1.1},{a[4]*.3,a[4]*.3,a[4]*.3},cyan,false,'Neon','Wedge');point.CFrame=point.CFrame*C.Angles(math.pi,0,0)
 local last=parts[#parts];local right,up,back=point.CFrame.RightVector,point.CFrame.UpVector,-point.CFrame.LookVector;last.rotation={right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z}
end
local function sign(name,a,text,color)
 local p=box(name,'sign',a,{17,1,7},color,false,'Wood');local gui=rb.Instance.new('SurfaceGui');gui.Face=rb.Enum.NormalId.Front;gui.Parent=p;local label=rb.Instance.new('TextLabel');label.Size=rb.UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=text;label.TextScaled=true;label.TextColor3=rb.Color3.new(1,1,1);label.Parent=gui
end
for _,item in {{'MainSign',{135,134,54},'MAIN',slate},{'CartSign',{129,101,54},'CART',wood},{'CaveSign',{187,98,45},'CAVE',purple},{'JumpReady',{16,-9,32},'JUMP READY', {31,159,74}},{'BailSign',{28,6,31},'RED: STOP / BAIL',{177,51,60}},{'RecoverySign',{-11,-28,-9},'CLIMB OUT',cyan}} do sign(unpack(item)) end
for _,a in {{147,143,48},{120,100,48},{95,74,34},{57,29,24},{-38,29,24},{-84,-62,8},{-169,-105,0},{185,-2,4},{114,-45,0},{20,-78,0}} do
 box('LanternPost','prop',{a[1],a[2],a[3]+4},{1.5,1.5,8},wood,false,'Wood');local p=box('LanternGlow','light',{a[1],a[2],a[3]+8},{2.8,2.8,3},{255,177,64},false,'Neon');glow(p,2,25)
end
for _,a in {{169,145,48},{115,109,44},{68,65,30},{-77,-44,8},{150,-66,0}} do for i=0,2 do box('MineCrate','prop',{a[1]+i*5,a[2],a[3]+2},{4,4,4},wood,false,'Wood') end end
for _,a in {{155,148,48},{96,79,32},{-61,16,24}} do for off=-9,9,18 do box('TimberScaffold','prop',{a[1]+off,a[2],a[3]+10},{2,2,20},wood,false,'Wood') end;box('TimberBeam','prop',{a[1],a[2],a[3]+20},{22,3,3},wood,false,'Wood') end
-- Amber hook markers are deliberately non-damaging placeholders.
for _,h in {{'TNT',{74,54,31},1,15},{'SupportBlast',{0,-25,24},3,20},{'DynamiteGuardian',{140,142,48},2.5,7},{'ShatterCavern',{80,-35,0},1,20},{'RailSwitch',{-70,-65,8},2,12}} do local p=box(h[1]..'Hook','hook',{h[2][1]+16,h[2][2],h[2][3]+2},{4,4,4},{226,123,58},false);p:SetAttribute('TelegraphSeconds',h[3]);p:SetAttribute('CooldownSeconds',h[4]);p:SetAttribute('Placeholder',true) end
box('Geode','treasure',{160,120,51},{4,4,6},violet,false,'Neon','Ball')
local portalPane=box('PortalBeacon','portal',{-150,-120,14},{16,3,28},cyan,false,'Neon')
if stage>=3 then portalPane.Transparency=1;parts[#parts].transparency=1 end
-- Native portal shell and ring remain visible from the camp; camera faces +Z.
for _,a in {{-160,-121,13},{-140,-121,13}} do box('PortalSlatePillar','portal',a,{5,7,26},slate,false) end
box('PortalSlateLintel','portal',{-150,-121,28},{25,7,5},purple,false)
for i=1,18 do local a=i/18*math.pi*2;box('PortalCyanRing','portal',{-150+8*math.cos(a),-124,14+11*math.sin(a)},{2,1.2,2},cyan,false,'Neon') end
if stage>=3 then
 for i=1,36 do local a=i/36*math.pi*4;local radius=1+i/36*6
  local p=box('PortalSpiral','portal',{-150+radius*math.cos(a),-124.5,14+radius*math.sin(a)},{1.4,1,1.4},cyan,false,'Neon')
  if i==18 then glow(p,4,35) end
 end
end
for off=-1,1,2 do box('CaveMouthTimber','prop',{190+off*18,-25,13},{3,4,26},wood,false,'Wood') end
box('CaveMouthLintel','prop',{190,-25,28},{39,4,4},wood,false,'Wood')
if stage>=3 then
 local paving={{211,179,133},{190,157,113},{225,195,151}}
 local function lantern(cf)
  part('PairedLanternFoot','prop',cf*C.new(0,-1.4,0),V.new(3,3,3),rock[3],false)
  part('PairedLanternPost','prop',cf*C.new(0,3,0),V.new(1.2,9,1.2),wood,false,'Wood')
  local p=part('PairedLanternGlow','light',cf*C.new(0,8,0),V.new(2.3,3,2.3),{255,157,45},false,'Neon');glow(p,4,30)
  for y=6.3,9.7,3.4 do part('LanternIronCap','prop',cf*C.new(0,y,0),V.new(3.2,.7,3.2),{41,39,52},false,'Metal') end
  for x=-1.35,1.35,2.7 do for z=-1.35,1.35,2.7 do part('LanternIronCorner','prop',cf*C.new(x,8,z),V.new(.25,3,.25),{41,39,52},false,'Metal') end end
 end
 for name,pts in routes do if name~='cartRail' then
  for index=1,#pts-1 do
   local aa,bb=xyz(pts[index]),xyz(pts[index+1]);local len=(bb-aa).Magnitude;local n=math.ceil(len/4)
   for j=0,n-1 do
    local q=aa:Lerp(bb,(j+.5)/n);local cf=frame(q,bb)
    for column=-1,1 do part('CobbleRoutePaving','paving',cf*C.new(column*5.65,.03,0),V.new(5.4,.22,len/n-.15),paving[1+((j+column+3)%3)],false) end
    for side=-1,1,2 do
     part('ChunkyPathEdge','paving',cf*C.new(side*10.2,.7,0),V.new(2.2,1.9,len/n-.1),rock[3+(j%2)],false)
     if j%4==0 and name~='pitRecovery' then
      part('PathTimberPost','prop',cf*C.new(side*10.4,1.3,0),V.new(1.1,7,1.1),wood,false,'Wood')
     end
     part('PathTimberRail','prop',cf*C.new(side*10.4,3.8,0),V.new(.8,.8,len/n+.2),wood,false,'Wood')
    end
    if j%11==3 and (name=='main' or name=='cave') then for side=-1,1,2 do lantern(cf*C.new(side*11.5,0,0)) end end
   end
  end
 end end
 -- Substantial timber decks and paired diagonal braces along the same cart line.
 for index=1,#rail-1 do
  local aa,bb=xyz(rail[index]),xyz(rail[index+1]);local len=(bb-aa).Magnitude;local n=math.ceil(len/12)
  for j=0,n-1 do
   local t=(j+.5)/n
   if not (index==4 and math.abs(t-.5)<12/len) then
    local q=aa:Lerp(bb,t);local cf=frame(q,bb)
    for side=-1,1,2 do part('TrestleLongBeam','prop',cf*C.new(side*5,-3.5,0),V.new(2.5,4,len/n+.25),wood,false,'Wood') end
    part('TrestleCrossHead','prop',cf*C.new(0,-5,0),V.new(17,3,3),wood,false,'Wood')
    local ground=math.abs(q.X)<50 and q.Z<75 and q.Z>-35 and -18 or -30
    for side=-1,1,2 do
     local x,z=q.X+side*7,-q.Z;local h=q.Y-ground-5
     box('HeavyTimberTrestleLeg','prop',{x,z,ground+h/2},{3,3,h},wood,false,'Wood')
    end
    slab('TrestleDiagonalBrace','prop',{q.X-7,-q.Z,ground+3},{q.X+7,-q.Z,q.Y-6},2,2,wood,false,'Wood')
   end
  end
 end
 local function crate(x,z,y)
  box('DressedCrate','prop',{x,z,y+3},{6,6,6},wood,false,'Wood')
  for off=-2.6,2.6,5.2 do for dz=-3.1,3.1,6.2 do box('CrateBinding','prop',{x+off,z+dz,y+3},{.65,.4,6.3},{163,108,63},false,'Wood') end end
  slab('CrateDiagonal','prop',{x-2.8,z-3.2,y+.3},{x+2.8,z-3.2,y+5.7},.8,.5,{163,108,63},false,'Wood')
 end
 for _,a in {{-177,73,24},{-161,-93,0},{65,145,24},{145,139,48},{205,7,0}} do crate(a[1],a[2],a[3]);crate(a[1]+7,a[2]+2,a[3]) end
 -- Three concentrated mining destinations; keep the route fan physically open.
 for _,a in {{-176,-108,0},{180,139,48},{171,-20,0}} do
  crate(a[1],a[2],a[3]);crate(a[1]-7,a[2]+4,a[3]);crate(a[1]-3,a[2]+2,a[3]+6)
  for side=-1,1,2 do
   box('DestinationScaffoldPost','prop',{a[1]+side*12,a[2]+11,a[3]+9},{3,3,22},wood,false,'Wood')
   slab('DestinationScaffoldBrace','prop',{a[1]+side*12,a[2]+11,a[3]-2},{a[1],a[2]+11,a[3]+18},2,2,wood,false,'Wood')
  end
  box('DestinationScaffoldDeck','prop',{a[1],a[2]+11,a[3]+18},{29,8,3},wood,false,'Wood')
  for side=-1,1,2 do lantern(C.new(xyz({a[1]+side*12,a[2]-5,a[3]}))) end
 end
 for _,a in {{149,136,48},{-180,47,24},{156,-18,0}} do
  box('OreCartChassis','prop',{a[1],a[2],a[3]+2},{9,12,2},{42,48,68},false,'Metal')
  for side=-1,1,2 do
   box('OreCartSide','prop',{a[1]+side*4,a[2],a[3]+5},{1,12,6},{101,116,140},false,'Metal')
   box('OreCartEnd','prop',{a[1],a[2]+side*5.5,a[3]+5},{8,1,6},{85,94,118},false,'Metal')
   for dz=-4,4,8 do box('OreCartWheel','prop',{a[1]+side*5,a[2]+dz,a[3]+1.5},{2,3,3},{36,35,46},false,'Metal','Ball') end
  end
  for i=1,5 do crystal(a[1]+(i%3-1)*2,a[2]+(i-3)*1.4,a[3]+4,3+i%3,i%2==0 and cyan or violet) end
 end
 for _,a in {{150,143,48},{-184,68,24},{71,151,24}} do
  for layer=0,1 do for i=0,3 do box('DynamiteBundle','prop',{a[1]+i*1.6,a[2]+layer*2,a[3]+1+layer*1.8},{1.4,5,1.4},{181,46,57},false,'Wood') end end
  for dz=-1.7,1.7,3.4 do box('TNTBinding','prop',{a[1]+2.4,a[2]+dz,a[3]+2},{7,.6,4},{49,39,52},false,'Metal') end
 end
 for _,a in {{136,146,48},{191,132,48},{-182,74,24}} do
  box('CampBannerPole','prop',{a[1],a[2],a[3]+11},{1.3,1.3,26},wood,false,'Wood')
  box('CampBanner','prop',{a[1]+5,a[2],a[3]+15},{9,.6,14},a[1]==191 and cyan or {112,49,163},false,'Fabric')
  crystal(a[1]+5,a[2]-.6,a[3]+11,5,{225,194,255})
 end
 -- Semicircular masonry arches are outside the inherited 18-wide tunnel mouth.
 for _,a in {{190,-25,0},{-20,-70,0},{80,-35,0}} do
  for side=-1,1,2 do for k=0,3 do box('TunnelArchPier','prop',{a[1]+side*16,a[2],a[3]+3+k*6},{7,8,6},rock[1+(k%3)],false) end end
  for k=0,8 do local angle=k/8*math.pi;local cf=C.new(xyz({a[1]+16*math.cos(angle),a[2],a[3]+22+10*math.sin(angle)}))*C.Angles(0,0,angle-math.pi/2)
   part('TunnelArchVoussoir','prop',cf,V.new(6,7,8),rock[3+(k%2)],false)
  end
  for side=-1,1,2 do crystal(a[1]+side*19,a[2]-5,a[3],12,side==1 and violet or cyan) end
  local p=box('TunnelInteriorCrystalLight','light',{a[1],a[2]+7,a[3]+15},{3,3,3},violet,false,'Neon');glow(p,5,45)
 end
 -- Tiny moss confined to six rock shoulders.
 for _,a in {{-194,38,8},{-169,100,24},{72,168,24},{220,-86,0},{130,-134,0},{-33,-158,0}} do box('TinyMoss','prop',a,{3,2,.3},{68,97,91},false,'Grass') end
end
require('./round3-art')({parts=parts,routes=routes,rail=rail,part=part,box=box,slab=slab,frame=frame,xyz=xyz,nearest=nearest,crystal=crystal,glow=glow,rock=rock,wood=wood,cyan=cyan,violet=violet,V=V,C=C})
require('./readability-art')({model=model,parts=parts,lights=lights,routes=routes,rail=rail,part=part,box=box,slab=slab,frame=frame,xyz=xyz,nearest=nearest,glow=glow,V=V,C=C})
require('./balance-art')({model=model,parts=parts,lights=lights,routes=routes,part=part,box=box,slab=slab,frame=frame,xyz=xyz,nearest=nearest,crystal=crystal,glow=glow,V=V,C=C})
require('./connect-art')({model=model,parts=parts,part=part,V=V,C=C})
local spawn=rb.Instance.new('SpawnLocation');spawn.Name='PortalSpawn';spawn.Size=V.new(10,1,10);spawn.CFrame=C.new(-150,.5,120);spawn.Anchored=true;spawn.Neutral=true;spawn.Parent=ws
local rep=rb.Instance.new('ReplicatedStorage');rep.Parent=place;local core=rb.Instance.new('Folder');core.Name='TreasureCore';core.Parent=rep
for _,name in {'Config','Domain','Profiles','Runtime','Service','Tests','MockStore','StudioStoreTest','Feel'} do local m=rb.Instance.new('ModuleScript');m.Name=name;m.Source=fs.readFile('prototype/core/'..name..'.luau');m.Parent=core end
local packages=rb.Instance.new('Folder');packages.Name='Packages';packages.Parent=core
for _,name in {'ProfileStore','Shake','Spring','Signal','Trove'} do local m=rb.Instance.new('ModuleScript');m.Name=name;m.Source=fs.readFile('prototype/core/Packages/'..name..'.luau');m.Parent=packages end
local sp=rb.Instance.new('StarterPlayer');sp.Parent=place
local clients=rb.Instance.new('StarterPlayerScripts');clients.Parent=sp
local feel=rb.Instance.new('LocalScript');feel.Name='TreasureFeel';feel.Source=fs.readFile('prototype/core/Feel.client.luau');feel.Parent=clients
local function lua(value)
 if type(value)=='table' then local fields={};for key,child in value do table.insert(fields,'['..lua(key)..']='..lua(child)) end;return '{'..table.concat(fields,',')..'}' end
 if type(value)=='string' then return string.format('%q',value) end
 return tostring(value)
end
local data=rb.Instance.new('ModuleScript');data.Name='CaveRouteData';data.Source='return '..lua({routes=routes,gapStart=gapStart,gapEnd=gapEnd,length=distance});data.Parent=rep
local sss=rb.Instance.new('ServerScriptService');sss.Parent=place;sss:SetAttribute('CoreUseDataStore',false)
for _,name in {'Cart','Loop','ConnectArt'} do local s=rb.Instance.new('Script');s.Name='Cave'..name;s.Source=fs.readFile('prototype/cave-v2/'..name..'.server.luau');s.Parent=sss end
local lighting=rb.Instance.new('Lighting');lighting.ClockTime=18;lighting.Brightness=2;lighting.Ambient=rb.Color3.fromRGB(78,82,122);lighting.OutdoorAmbient=rb.Color3.fromRGB(104,112,144);lighting.Parent=place
if stage>=4 then
 lighting.ClockTime=0.2;lighting.Brightness=1.6;lighting.ExposureCompensation=.15;lighting.Ambient=rb.Color3.fromRGB(39,48,76);lighting.OutdoorAmbient=rb.Color3.fromRGB(54,66,97)
 lighting.GeographicLatitude=35
 lighting.ColorShift_Top=rb.Color3.fromRGB(39,51,82)
 local sky=rb.Instance.new('Sky');sky.Name='NightBlueSky';sky.StarCount=1600;sky.CelestialBodiesShown=true;sky.Parent=lighting
 local bloom=rb.Instance.new('BloomEffect');bloom.Name='CrystalBloom';bloom.Intensity=.65;bloom.Size=32;bloom.Threshold=.9;bloom.Parent=lighting
 local atmosphere=rb.Instance.new('Atmosphere');atmosphere.Density=.22;atmosphere.Offset=.12;atmosphere.Color=rb.Color3.fromRGB(90,117,170);atmosphere.Decay=rb.Color3.fromRGB(31,43,79);atmosphere.Haze=1.1;atmosphere.Parent=lighting
end
for _,node in place:GetDescendants() do if node:IsA('LuaSourceContainer') then luau.compile(node.Source) end end
local labels={}
for i,p in model:GetChildren() do
 if p:GetAttribute('CaveCategory')=='landmark' then
  for _,gui in p:GetChildren() do if gui:IsA('SurfaceGui') then
   local label=gui:FindFirstChildWhichIsA('TextLabel')
   if label then table.insert(labels,{partIndex=i,text=label.Text,face=gui.Face.Name,color={label.TextColor3.R*255,label.TextColor3.G*255,label.TextColor3.B*255}}) end
  end end
 end
end
fs.writeFile('prototype/cave-v2/scene.json',serde.encode('json',{parts=parts,routes=routeData,lights=lights,labels=labels,stage=stage},true))
fs.writeFile('prototype/cave-v2.rbxl',rb.serializePlace(place))
rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
print('PASS compiled scripts and binary roundtrip; '..#parts..' native parts; route source referenced from ROUTES.json; core source referenced from prototype/core')
