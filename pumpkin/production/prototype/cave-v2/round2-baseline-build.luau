-- Offline native-part builder. Reuses Meadow v4's manifest/CFrame/slab pattern;
-- source modules are mounted from prototype/core, never copied into source.
local fs, rb, serde, luau = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde'), require('@lune/luau')
local V, C = rb.Vector3, rb.CFrame
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
local parts, routeData = {}, {}
local slate={69,78,100};local purple={97,83,122};local wood={104,68,43};local cyan={54,224,245};local violet={167,83,255}
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
-- Full mountain mass comes first, not a thin platform. Lower strata taper to a point.
for x=-240,240,20 do for z=-180,180,20 do
 if (x/265)^2+(z/210)^2<1 then
  local top=-2
  for _,pts in routes do local d,y=nearest(x,z,pts);if d<31 then top=math.min(top,y-3) end end
  if math.abs(x)<35 and math.abs(z+25)<35 then top=-19 end
  box('ConnectedBedrock','mass',{x,z,(top-42)/2},{20,20,top+42},slate,true)
 end
end end
-- Faceted connected descending rings: circular stepped taper rather than boxes.
for i=1,10 do local radius=230-i*20;local y=-35-i*16
 for x=-radius,radius,22 do for z=-radius*.76,radius*.76,22 do
  if (x/radius)^2+(z/(radius*.79))^2<1 then box('InvertedMountainFacet','underside',{x,z,y},{23,23,23},(math.floor(x/22)+i)%3==0 and purple or slate,true) end
 end end
end
-- Broad supported route slabs; joins use overlap and full-width junction pads.
for name,pts in routes do
 local width=18
 routeData[name]={points=pts,width=width,category=name=='cartRail' and 'rail' or 'lane'}
 if name~='cartRail' then
  for i=1,#pts-1 do slab(name..i,'lane',pts[i],pts[i+1],width,2,purple,true) end
  for i=1,#pts-1 do local a,b=pts[i],pts[i+1];local n=math.ceil((xyz(b)-xyz(a)).Magnitude/9);for j=0,n do local t=j/n;local x,z,y=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t
   -- Lower routes take precedence under crossings: no invisible support wall.
   local top=y-1.8;for other,otherPts in routes do if other~='cartRail' then local d,otherY=nearest(x,z,otherPts);if d<width*.5+21 then top=math.min(top,otherY-2) end end end
   local h=top+40;box('RouteRockButtress','support',{x,z,top-h/2},{width+5,10,h},slate,true)
  end end
 end
end
box('GeodeCamp','lane',{160,120,47},{48,48,2},purple,true)
box('CampFullRockMass','mass',{164,132,3},{40,24,88},slate,true)
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
   if clear then box('CavernSidewall','wall',{x,z,14},{6,6,32},slate,true) end
  end
 end
end
local function crystal(x,z,y,s,col)
 box('CrystalShaft','crystal',{x,z,y+s*.5},{s*.35,s*.35,s},col,false,'Neon')
 box('CrystalPoint','crystal',{x,z,y+s*1.05},{s*.35,s*.35,s*.3},col,false,'Neon','Wedge')
end
-- The huge crown is behind the camp: clear portal silhouette and clear route fan.
box('CampRockCrown','mass',{169,159,42},{68,43,76},slate,true)
for i=1,7 do crystal(145+i*7,158+(i%2)*7,78,23+(i%3)*13,i%2==0 and cyan or violet) end
for i=1,36 do local a=i*2.399;local x,z=math.cos(a)*210,math.sin(a)*155;local safe=true;for _,pts in routes do if nearest(x,z,pts)<25 then safe=false end end;if safe then crystal(x,z,-1,10+(i%5)*3,i%2==0 and cyan or violet) end end
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
 box('LanternPost','prop',{a[1],a[2],a[3]+4},{1.5,1.5,8},wood,false,'Wood');local p=box('LanternGlow','light',{a[1],a[2],a[3]+8},{2.8,2.8,3},{255,177,64},false,'Neon');local l=rb.Instance.new('PointLight');l.Color=p.Color;l.Brightness=2;l.Range=25;l.Parent=p
end
for _,a in {{169,145,48},{115,109,44},{68,65,30},{-77,-44,8},{150,-66,0}} do for i=0,2 do box('MineCrate','prop',{a[1]+i*5,a[2],a[3]+2},{4,4,4},wood,false,'Wood') end end
for _,a in {{155,148,48},{96,79,32},{-61,16,24}} do for off=-9,9,18 do box('TimberScaffold','prop',{a[1]+off,a[2],a[3]+10},{2,2,20},wood,false,'Wood') end;box('TimberBeam','prop',{a[1],a[2],a[3]+20},{22,3,3},wood,false,'Wood') end
-- Amber hook markers are deliberately non-damaging placeholders.
for _,h in {{'TNT',{74,54,31},1,15},{'SupportBlast',{0,-25,24},3,20},{'DynamiteGuardian',{140,142,48},2.5,7},{'ShatterCavern',{80,-35,0},1,20},{'RailSwitch',{-70,-65,8},2,12}} do local p=box(h[1]..'Hook','hook',{h[2][1]+16,h[2][2],h[2][3]+2},{4,4,4},{226,123,58},false);p:SetAttribute('TelegraphSeconds',h[3]);p:SetAttribute('CooldownSeconds',h[4]);p:SetAttribute('Placeholder',true) end
box('Geode','treasure',{160,120,51},{4,4,6},violet,false,'Neon','Ball')
box('PortalBeacon','portal',{-150,-120,14},{16,3,28},cyan,false,'Neon')
-- Native portal shell and ring remain visible from the camp; camera faces +Z.
for _,a in {{-160,-121,13},{-140,-121,13}} do box('PortalSlatePillar','portal',a,{5,7,26},slate,false) end
box('PortalSlateLintel','portal',{-150,-121,28},{25,7,5},purple,false)
for i=1,18 do local a=i/18*math.pi*2;box('PortalCyanRing','portal',{-150+8*math.cos(a),-124,14+11*math.sin(a)},{2,1.2,2},cyan,false,'Neon') end
for off=-1,1,2 do box('CaveMouthTimber','prop',{190+off*18,-25,13},{3,4,26},wood,false,'Wood') end
box('CaveMouthLintel','prop',{190,-25,28},{39,4,4},wood,false,'Wood')
local spawn=rb.Instance.new('SpawnLocation');spawn.Name='PortalSpawn';spawn.Size=V.new(10,1,10);spawn.CFrame=C.new(-150,.5,120);spawn.Anchored=true;spawn.Neutral=true;spawn.Parent=ws
local rep=rb.Instance.new('ReplicatedStorage');rep.Parent=place;local core=rb.Instance.new('Folder');core.Name='TreasureCore';core.Parent=rep
for _,name in {'Config','Domain','Profiles','Runtime','Service','Tests'} do local m=rb.Instance.new('ModuleScript');m.Name=name;m.Source=fs.readFile('prototype/core/'..name..'.luau');m.Parent=core end
local function lua(value)
 if type(value)=='table' then local fields={};for key,child in value do table.insert(fields,'['..lua(key)..']='..lua(child)) end;return '{'..table.concat(fields,',')..'}' end
 if type(value)=='string' then return string.format('%q',value) end
 return tostring(value)
end
local data=rb.Instance.new('ModuleScript');data.Name='CaveRouteData';data.Source='return '..lua({routes=routes,gapStart=gapStart,gapEnd=gapEnd,length=distance});data.Parent=rep
local sss=rb.Instance.new('ServerScriptService');sss.Parent=place;sss:SetAttribute('CoreUseDataStore',false)
for _,name in {'Cart','Loop'} do local s=rb.Instance.new('Script');s.Name='Cave'..name;s.Source=fs.readFile('prototype/cave-v2/'..name..'.server.luau');s.Parent=sss end
local lighting=rb.Instance.new('Lighting');lighting.ClockTime=18;lighting.Brightness=2;lighting.Ambient=rb.Color3.fromRGB(78,82,122);lighting.OutdoorAmbient=rb.Color3.fromRGB(104,112,144);lighting.Parent=place
for _,node in place:GetDescendants() do if node:IsA('LuaSourceContainer') then luau.compile(node.Source) end end
fs.writeFile('prototype/cave-v2/scene.json',serde.encode('json',{parts=parts,routes=routeData},true))
fs.writeFile('prototype/cave-v2.rbxl',rb.serializePlace(place))
rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
print('PASS compiled scripts and binary roundtrip; '..#parts..' native parts; route source referenced from ROUTES.json; core source referenced from prototype/core')
