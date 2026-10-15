-- Readability pass: never mutate collision geometry, routes or hooks.
local rb=require('@lune/roblox')
return function(e)
 local V,C=e.V,e.C
 local native=e.model:GetChildren()
 local tan={224,199,151};local edge={159,137,99};local plank={166,99,49};local steel={36,42,51}
 local function color(i,col) e.parts[i].color=col;native[i].Color=rb.Color3.fromRGB(unpack(col)) end
 local function move(i,delta)
  local p=e.parts[i];native[i].CFrame=C.new(delta)*native[i].CFrame
  p.position={p.position[1]+delta.X,p.position[2]+delta.Y,p.position[3]+delta.Z}
 end
 local function resize(i,size) e.parts[i].size={size.X,size.Y,size.Z};native[i].Size=size end
 local remove={}
 local gemDelta=V.zero
 for i,p in e.parts do
  local x,y,z=p.position[1],p.position[2],-p.position[3]
  if p.name=='CrystalShaft' then
   gemDelta=V.zero
   local hero=x>120 and x<205 and z>130 and z<190 and y>48
   local distance=math.huge
   for _,pts in e.routes do distance=math.min(distance,e.nearest(x,z,pts)) end
   if not hero and y>-35 and (distance<55 or (x<-70 and z<-65)) then
    -- Move each complete gem as one rigid group into the exposed underside.
    gemDelta=V.new(0,-90,0)
   end
  end
  if p.category=='crystal' and p.name:match('^Crystal') then move(i,gemDelta) end
  if p.category=='lane' or p.name=='CobbleRoutePaving' then color(i,tan) end
  if p.name=='ChunkyPathEdge' then
   color(i,edge);resize(i,V.new(p.size[1],.5,p.size[3]));move(i,V.new(0,-.55,0))
  end
  if p.name=='RailSleeper' then color(i,plank);resize(i,V.new(9,.65,2.9)) end
  if p.name=='SteelRail' then color(i,steel);resize(i,V.new(.65,.8,p.size[3])) end
  -- Remove false routes and repeated, crossing silhouettes. Structural
  -- colliders, including the actual breakable span, are retained verbatim.
  local clutter=p.name:find('Scaffold') or p.name:find('Gantry') or p.name:find('RopeBridge') or p.name:find('Lantern') or p.name:find('PathTimber') or p.name:find('Trestle') or p.name:find('Banner') or p.name:find('TunnelInteriorCrystalLight') or p.name=='TimberBeam'
  if not p.collidable and p.category~='hook' and clutter then remove[i]=true end
  if not p.collidable and p.category=='prop' and x<-105 and z<-65 and y>-5 then remove[i]=true end
  if p.category=='portal' then
   local origin=V.new(-150,0,121);local old=V.new(unpack(p.position))
   move(i,origin+(old-origin)*.72-old+V.new(-10,0,3))
   resize(i,native[i].Size*.72)
   if p.material=='Neon' then color(i,{54,151,180}) end
  end
  -- Walkway palette belongs exclusively to playable surfaces and low edges.
  if p.category~='lane' and p.category~='paving' and p.category~='rail' and p.category~='hook' and (p.color[1]>150 and p.color[2]>95 and p.color[3]<155) then color(i,{101,78,74}) end
 end
 for i=#e.parts,1,-1 do if remove[i] then native[i]:Destroy();table.remove(e.parts,i) end end
 -- One aligned support frame every 34 studs; braces stay under the rails.
 for index=1,#e.rail-1 do
  local aa,bb=e.xyz(e.rail[index]),e.xyz(e.rail[index+1]);local len=(bb-aa).Magnitude
  local count=math.max(1,math.ceil(len/34))
  for j=0,count-1 do
   local t=(j+.5)/count
   if not (index==4 and math.abs(t-.5)<13/len) then
    local q=aa:Lerp(bb,t);local cf=e.frame(q,bb)
    e.part('ReadableRailCrosshead','prop',cf*C.new(0,-3,0),V.new(11,2,2),{101,69,47},false,'Wood')
    local base=-27;local h=q.Y-base-4
    for side=-1,1,2 do
     local pos=(cf*C.new(side*4,-4,0)).Position
     e.part('ReadableRailPier','prop',C.new(pos.X,base+h/2,pos.Z),V.new(1.8,h,1.8),{101,69,47},false,'Wood')
    end
    for side=-1,1,2 do e.part('ReadableRailStringer','prop',cf*C.new(side*4,-1.7,0),V.new(1,1.5,len/count+.5),{101,69,47},false,'Wood') end
   end
  end
 end
 local green={68,190,89};local yellow={255,211,65};local cyan={64,209,224}
 e.box('MainMouthBannerPole','landmark',{-139,-77,10},{1.3,1.3,20},{62,61,66},false,'Metal')
 e.box('MainMouthGreenBanner','landmark',{-136,-77,16},{5,.6,8},green,false,'Fabric')
 local function sign(name,a,text,col)
  local p=e.box(name,'landmark',a,name=='MainMouthLabel' and {17,1,7} or {12,1,4.5},col,false,'SmoothPlastic')
  for _,face in {rb.Enum.NormalId.Front,rb.Enum.NormalId.Back} do
   local gui=rb.Instance.new('SurfaceGui');gui.Face=face;gui.Parent=p
   local label=rb.Instance.new('TextLabel');label.Size=rb.UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=text;label.TextScaled=true;label.TextColor3=rb.Color3.fromRGB(22,30,35);label.Parent=gui
  end
 end
 sign('MainMouthLabel',{-136,-76,23},'MAIN / CAMP',green)
 e.box('CartMouthStationPost','landmark',{-138,-99,8},{1.2,1.2,16},{62,61,66},false,'Metal')
 sign('CartMouthYellowStation',{-132,-99,16},'CART STATION',yellow)
 -- The arch spans the eastbound cave mouth, not an invented route.
 for side=-1,1,2 do e.box('CyanMouthArchPier','landmark',{-81,-112+side*12,8},{3,3,16},{55,113,123},false) end
 e.box('CyanMouthArchCrown','landmark',{-81,-112,17},{3,27,1.5},cyan,false,'Neon')
 for side=-1,1,2 do e.box('CyanMouthArchGlow','landmark',{-81,-112+side*12,8},{3.1,.6,15},cyan,false,'Neon') end
 sign('CaveMouthLabel',{-91,-99,18},'CAVE',cyan)
 -- Route names at the original upper destinations reinforce the same code.
 -- Replace all lamp spam with spaced pools on walkways only.
 for name,pts in e.routes do if name=='main' or name=='cave' or name=='railWalkBypass' or name=='pitRecovery' then
  for k=1,#pts-1 do
   local aa,bb=e.xyz(pts[k]),e.xyz(pts[k+1]);local len=(bb-aa).Magnitude
   local n=math.max(1,math.ceil(len/65))
   for j=0,n-1 do
    local cf=e.frame(aa:Lerp(bb,(j+.5)/n),bb)*C.new(11.5,0,0)
    e.part('ReadableLanternPost','prop',cf*C.new(0,3.2,0),V.new(.9,6.4,.9),{63,57,61},false,'Metal')
    local lamp=e.part('ReadableLanternPool','light',cf*C.new(0,6.8,0),V.new(1.8,2.2,1.8),{255,179,75},false,'Neon')
    e.glow(lamp,1.4,18)
   end
  end
 end end
 -- Regenerate the light manifest from the actual saved native children,
 -- including moved crystal PointLights; deleted light owners cannot linger.
 table.clear(e.lights)
 for _,p in e.model:GetChildren() do
  for _,l in p:GetChildren() do if l:IsA('PointLight') then
   if p:GetAttribute('CaveCategory')=='crystal' then l.Brightness=.65;l.Range=math.min(l.Range,22) end
   local q=p.CFrame.Position;table.insert(e.lights,{position={q.X,q.Y,q.Z},color={l.Color.R*255,l.Color.G*255,l.Color.B*255},brightness=l.Brightness,range=l.Range})
  end end
 end
end
