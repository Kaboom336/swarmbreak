-- Balance only: protected geometry/gameplay never change.
local rb=require('@lune/roblox')
return function(e)
 local V,C=e.V,e.C;local native=e.model:GetChildren();local remove={}
 local tops={}
 for _,p in e.parts do if p.name=='StackedMesaRock' then
  local key=p.position[1]..':'..p.position[3];local y=p.position[2]+p.size[2]/2
  if not tops[key] or y>tops[key].y then tops[key]={x=p.position[1],z=-p.position[3],y=y} end
 end end
 for i,p in e.parts do
  if p.category=='landmark' then remove[i]=true end
  if p.category=='mass' or p.category=='underside' or p.category=='rock-detail' then
   local top=p.name=='StackedMesaRock' and math.abs(p.position[2]+p.size[2]/2-tops[p.position[1]..':'..p.position[3]].y)<.1
   local col=top and {103,112,137} or (i%3==0 and {68,64,88} or {47+i%3*7,59+i%3*6,82+i%3*7})
   p.color=col;native[i].Color=rb.Color3.fromRGB(unpack(col))
  end
 end
 for i=#e.parts,1,-1 do if remove[i] then native[i]:Destroy();table.remove(e.parts,i) end end
 local function safe(x,z,margin)
  for _,pts in e.routes do if e.nearest(x,z,pts)<margin then return false end end;return true
 end
 local newStart=#e.parts+1
 local cells={};for _,q in tops do table.insert(cells,q) end
 table.sort(cells,function(a,b)return a.x==b.x and a.z<b.z or a.x<b.x end)
 local n=0
 for _,q in cells do
  local face=false
  for _,d in {{10,0},{-10,0},{0,10},{0,-10}} do
   local p=tops[(q.x+d[1])..':'..(-q.z-d[2])];if not p or q.y-p.y>12 then face=true end
  end
  if face and safe(q.x,q.z,37) then
   n+=1
   if n%4==1 then
    for k=1,5 do
     local a=k*2.399;local x,z=q.x+math.cos(a)*5,q.z+math.sin(a)*5
     local scale=q.z<-80 and q.x<-40 and .65 or 1
     e.crystal(x,z,q.y-7,({12,18,27,16,10})[k]*scale,k%3==0 and {45,213,255} or {153,64,245},false,(k-3)*.06,k==3)
    end
   end
  end
 end
 local wood={92,58,35};local metal={34,40,52};local green={46,166,72};local cyan={42,205,242}
 local function box(name,a,size,col,mat) return e.box(name,'landmark',a,size,col,false,mat or 'Wood') end
 local function label(p,text,col)
  for _,face in {rb.Enum.NormalId.Front,rb.Enum.NormalId.Back} do
   local gui=rb.Instance.new('SurfaceGui');gui.Face=face;gui.Parent=p
   local t=rb.Instance.new('TextLabel');t.Size=rb.UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextScaled=true;t.TextColor3=rb.Color3.fromRGB(unpack(col));t.Parent=gui
  end
 end
 -- Green fabric gateway: a clear opening, timber braces and a hanging pennant.
 for side=-1,1,2 do
  box('MainGatewayTimber',{-150+side*16,-76,13},{2,2,26},wood)
  box('MainGatewayFoot',{-150+side*16,-76,1.5},{4,4,3},metal,'Metal')
 end
 box('MainGatewayLintel',{-150,-76,27},{35,3,3},wood)
 local banner=box('MainGatewayFabric',{-150,-76,23.5},{23,.5,5},green,'Fabric');label(banner,'MAIN / CAMP',{226,239,197})
 for side=-1,1,2 do box('MainGatewayPennant',{-150+side*13,-76,21},{3,.5,8},green,'Fabric') end
 -- Cart station beside the original lower mouth; hanging sign and a real ore tub.
 box('CartStationTimber',{-138,-99,10},{1.2,1.2,20},wood)
 box('CartStationBracket',{-134,-99,20},{9,1.3,1.3},wood)
 for x=-136,-128,8 do box('CartSignChain',{x,-99,18},{.25,.25,3},metal,'Metal') end
 local sign=box('CartStationHangingSign',{-132,-99,15.5},{12,.7,3.6},wood);label(sign,'CART STATION',{255,211,87})
 local lamp=box('CartStationLantern',{-128,-99,20},{1.8,1.8,2.4},{255,174,66},'Neon');e.glow(lamp,2.2,20)
 for dy=-1.5,1.5,3 do box('CartLanternCap',{-128,-99,20+dy},{2.3,2.3,.4},metal,'Metal') end
 local x,z,y=-118,-75,0
 box('StationOreCartChassis',{x,z,y+2},{8,10,1.5},metal,'Metal')
 for side=-1,1,2 do
  box('StationOreCartWall',{x+side*4,z,y+4.5},{.7,10,5},{75,91,111},'Metal')
  box('StationOreCartEnd',{x,z+side*5,y+4.5},{8,.7,5},{63,75,95},'Metal')
  for dz=-3.5,3.5,7 do e.box('StationOreCartWheel','landmark',{x+side*4.6,z+dz,y+1.5},{1.4,2.8,2.8},metal,false,'Metal','Ball') end
 end
 for k=1,4 do e.crystal(x+(k%2)*3-1.5,z+(k-2)*2,y+3,4+k,{58,210,247},false,0,false) end
 -- Stone arch with cyan crystal buttresses, an unobstructed stone crown.
 for side=-1,1,2 do
  for k=0,3 do box('CaveArchStone',{-81,-112+side*17,3+k*6},{5,5,6},{56+k*5,71+k*5,93+k*5},'Slate') end
  e.crystal(-81,-112+side*20,0,13,cyan,false,0,true)
  e.crystal(-85,-112+side*21,0,8,{136,78,235},false,0,false)
 end
 for k=0,8 do
  local angle=k/8*math.pi
  e.part('CaveArchVoussoir','landmark',C.new(e.xyz({-81,-112+17*math.cos(angle),23+8*math.sin(angle)}))*C.Angles(angle-math.pi/2,0,0),V.new(5,6,6),{74,88,112},false,'Slate')
 end
 local cave=box('CaveArchCarvedName',{-91,-99,18},{10,.6,3},{45,74,87},'Slate');label(cave,'CAVE',{92,226,250})
 -- Mine framing confined to roomy cliff shoulders, never new apparent routes.
 for _,a in {{-190,-63,0},{-190,85,24},{202,148,48},{190,-64,0},{75,160,24}} do
  if safe(a[1],a[2],28) then
   box('FramingCrate', {a[1],a[2],a[3]+3},{6,6,6},wood)
   for side=-1,1,2 do box('CrateIronBand',{a[1]+side*2,a[2],a[3]+3},{.5,6.2,6.2},metal,'Metal') end
   for k=0,3 do box('FramingTNT',{a[1]+8+k*1.5,a[2],a[3]+1},{1.3,4,1.3},{151,39,48}) end
   for side=-1,1,2 do box('CliffScaffoldPost',{a[1]+side*6,a[2]+8,a[3]+7},{1.5,1.5,14},wood) end
   box('CliffScaffoldShelf',{a[1],a[2]+8,a[3]+12},{14,4,1.2},wood)
   e.slab('CliffScaffoldBrace','landmark',{a[1]-6,a[2]+8,a[3]},{a[1]+6,a[2]+8,a[3]+12},1,1,wood,false,'Wood')
  end
 end
 -- Check whole gem footprints, including tilted tips, against every route.
 -- Move an entire new gem together so its facets and native light stay aligned.
 local children=e.model:GetChildren();local start=nil
 local function clearGem(first,last)
  local origin=e.parts[first].position;local radius=0;local highest=-math.huge
  for i=first,last do local p=e.parts[i];local r=p.rotation
   local bx,bz,by=0,0,0;for j=1,3 do bx+=math.abs(r[j])*p.size[j]/2;bz+=math.abs(r[6+j])*p.size[j]/2;by+=math.abs(r[3+j])*p.size[j]/2 end
   highest=math.max(highest,p.position[2]+by)
   radius=math.max(radius,math.sqrt((math.abs(p.position[1]-origin[1])+bx)^2+(math.abs(p.position[3]-origin[3])+bz)^2))
  end
  local below=true;for _,pts in e.routes do local _,y=e.nearest(origin[1],-origin[3],pts);if highest>y-4 then below=false end end
  if below or safe(origin[1],-origin[3],18+radius) then return end
  local best,bx,bz=math.huge,0,0
  for dx=-60,60,2 do for dz=-60,60,2 do local d=dx*dx+dz*dz
   if d<best and safe(origin[1]+dx,-origin[3]+dz,18+radius) then best,bx,bz=d,dx,dz end
  end end
  assert(best<math.huge,'no clear crystal pocket')
  for i=first,last do local p=e.parts[i];p.position[1]+=bx;p.position[3]-=bz;children[i].CFrame=C.new(bx,0,-bz)*children[i].CFrame end
 end
 for i=1,#e.parts+1 do local p=e.parts[i]
  if not p or p.category~='crystal' or p.name=='CrystalShaft' then
   if start then clearGem(start,i-1);start=nil end
   if p and p.name=='CrystalShaft' then start=i end
  end
 end
 -- Rich glass faces with luminous seams, rather than flat neon solids.
 children=e.model:GetChildren()
 local lamps={}
 for i,p in e.parts do
  if p.category=='crystal' and (p.name=='CrystalShaft' or p.name=='CrystalPoint' or p.name=='CrystalNeedle' or p.name=='CrystalInsetFacet') then
   local col={math.floor(p.color[1]*.67),math.floor(p.color[2]*.67),math.floor(p.color[3]*.8)}
   p.color=col;p.material=p.name=='CrystalInsetFacet' and 'Glass' or 'Neon';p.transparency=.12
   children[i].Color=rb.Color3.fromRGB(unpack(col));children[i].Material=rb.Enum.Material[p.material];children[i].Transparency=.12
  end
  if p.name=='ReadableLanternPool' then
   local best,bx,bz=math.huge,0,0
   if not safe(p.position[1],-p.position[3],13) then
    for dx=-40,40,2 do for dz=-40,40,2 do local d=dx*dx+dz*dz
     if d<best and safe(p.position[1]+dx,-p.position[3]+dz,13) then best,bx,bz=d,dx,dz end
    end end
    assert(best<math.huge,'no clear lantern pocket')
    for k=i-1,i do e.parts[k].position[1]+=bx;e.parts[k].position[3]-=bz;children[k].CFrame=C.new(bx,0,-bz)*children[k].CFrame end
   end
   p.color={255,154,47};children[i].Color=rb.Color3.fromRGB(255,154,47)
   table.insert(lamps,children[i].CFrame)
   for _,l in children[i]:GetChildren() do if l:IsA('PointLight') then l.Color=children[i].Color;l.Brightness=3;l.Range=27 end end
  end
 end
 for _,cf in lamps do
  for side=-1,1,2 do e.part('LanternIronCap','landmark',cf*C.new(0,side*1.35,0),V.new(2.6,.4,2.6),metal,false,'Metal') end
  for xside=-1,1,2 do for zside=-1,1,2 do e.part('LanternCornerFrame','landmark',cf*C.new(xside*1,0,zside*1),V.new(.18,2.8,.18),metal,false,'Metal') end end
  e.part('LanternHanger','landmark',cf*C.new(0,2,0),V.new(.25,1.5,.25),metal,false,'Metal')
 end
 -- Cantilevered timber station roof and camp shelter mark inhabited destinations.
 for side=-1,1,2 do e.slab('StationRoof','landmark',{-132+side*9,-99,22},{-132,-99,26},8,.8,wood,false,'Wood') end
 local function shelter(x,z,y,greenFlag)
  for side=-1,1,2 do box('CampShelterTimber',{x+side*10,z,y+9},{2,2,18},wood) end
  box('CampShelterBeam',{x,z,y+18},{24,3,2},wood)
  for side=-1,1,2 do e.slab('CampShelterRoof','landmark',{x+side*13,z,y+18},{x,z,y+23},17,1.2,{68,44,38},false,'Wood') end
  local flag=box('DestinationFabric',{x,z-1,y+15},{14,.5,5},greenFlag and green or {194,136,40},'Fabric')
  label(flag,greenFlag and 'CAMP' or 'CART',{248,224,166})
  for side=-1,1,2 do local lamp=box('ShelterLantern',{x+side*8,z-2,y+11},{1.4,1.4,2},{255,154,47},'Neon');e.glow(lamp,3,27) end
 end
 shelter(184,174,48,true);shelter(132,160,48,false)
 local frames=0
 for _,q in cells do
  local d=math.huge;for _,pts in e.routes do d=math.min(d,e.nearest(q.x,q.z,pts)) end
  if q.y>=0 and d>24 and d<42 then
   frames+=1
   if frames%18==1 then
    box('ShoulderCrate',{q.x,q.z,q.y+3},{6,6,6},wood)
    for side=-1,1,2 do box('ShoulderCrateBand',{q.x+side*2,q.z,q.y+3},{.5,6.2,6.2},{153,97,49}) end
    e.slab('ShoulderCrateDiagonal','landmark',{q.x-2.7,q.z-3.2,q.y+.4},{q.x+2.7,q.z-3.2,q.y+5.6},.7,.5,{153,97,49},false,'Wood')
   end
  end
 end
 table.clear(e.lights)
 for _,p in e.model:GetChildren() do for _,l in p:GetChildren() do if l:IsA('PointLight') then
  if p:GetAttribute('CaveCategory')=='crystal' then l.Brightness=2.6;l.Range=math.min(36,math.max(l.Range,24)) end
  local q=p.CFrame.Position;table.insert(e.lights,{position={q.X,q.Y,q.Z},color={l.Color.R*255,l.Color.G*255,l.Color.B*255},brightness=l.Brightness,range=l.Range})
 end end end
end
