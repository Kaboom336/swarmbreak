-- Geometry-driven offline wall-bait regression. OBB casts model authored parts;
-- Roblox mesh/physics and the live rig still require Studio acceptance.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V,C=rb.Vector3,rb.CFrame
local world={}
local function scene(path,origin)
 local place=rb.deserializePlace(fs.readFile(path));local cache={}
 local function load(n)
  if cache[n] then return cache[n] end
  cache[n]=luau.load(n.Source,{environment={script=n,require=load,workspace=world,Vector3=V,Vector2=rb.Vector2,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,warn=warn}})();return cache[n]
 end
 local model=load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new('Folder'),origin)
 local parts,covers={},{}
 for _,p in model:GetDescendants() do if p:IsA('BasePart') and p.CanCollide and p.CanQuery then
  local category=p:GetAttribute('MeadowV4Category')
  if table.find({'cover','boulder','tunnel_rock','tunnel_roof','tunnel_hill'},category) then p:SetAttribute('SurfaceRole','Cover');table.insert(covers,p) end
  -- Cache transforms: Lune instance property access is costly.
  local cf,h=p.CFrame,p.Size/2
  local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
  local extent=V.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(l.X)*h.Z,
   math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(l.Y)*h.Z,
   math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(l.Z)*h.Z)
  local q=cf.Position-origin
  if q.X+extent.X>=-76 and q.X-extent.X<=-70 and q.Z+extent.Z>=87 and q.Z-extent.Z<=114
   and q.Y-extent.Y<=18 then table.insert(parts,{p=p,cf=cf,h=h,extent=extent}) end
 end end
 return place,model,load,parts,covers
end
local function cast(parts,from,delta,only,expand)
 local nearest
 for _,entry in parts do
  local p,cf,h=entry.p,entry.cf,entry.h
  if expand then
   local finish=from+delta;local center=cf.Position;local e=entry.extent
   if math.min(from.X,finish.X)-expand.X>center.X+e.X or math.max(from.X,finish.X)+expand.X<center.X-e.X
    or math.min(from.Y,finish.Y)-expand.Y>center.Y+e.Y or math.max(from.Y,finish.Y)+expand.Y<center.Y-e.Y
    or math.min(from.Z,finish.Z)-expand.Z>center.Z+e.Z or math.max(from.Z,finish.Z)+expand.Z<center.Z-e.Z then continue end
  end
  if not only or table.find(only,p) then
   local o,d=cf:PointToObjectSpace(from),cf:VectorToObjectSpace(delta)
   -- Dash is axis aligned; projected guardian extents make an OBB sweep.
  local eh=V.zero
  if expand then eh=V.new(math.abs(cf.RightVector.X)*expand.X+math.abs(cf.RightVector.Y)*expand.Y+math.abs(cf.RightVector.Z)*expand.Z,
    math.abs(cf.UpVector.X)*expand.X+math.abs(cf.UpVector.Y)*expand.Y+math.abs(cf.UpVector.Z)*expand.Z,
    math.abs(cf.LookVector.X)*expand.X+math.abs(cf.LookVector.Y)*expand.Y+math.abs(cf.LookVector.Z)*expand.Z);h+=eh end
   local lo,hi,normal=0,1,nil
   for _,axis in {'X','Y','Z'} do
    if math.abs(d[axis])<1e-7 then if math.abs(o[axis])>h[axis] then hi=-1;break end
    else
     local near,far=(-h[axis]-o[axis])/d[axis],(h[axis]-o[axis])/d[axis]
     local sign=-1
     if near>far then near,far=far,near;sign=1 end
     if near>lo then lo=near;normal=axis=='X' and V.new(sign,0,0) or axis=='Y' and V.new(0,sign,0) or V.new(0,0,sign) end
     hi=math.min(hi,far)
    end
   end
   if p:IsA('WedgePart') then
    local n=V.new(0,1,-entry.h.Y/entry.h.Z)
    local b=eh.Y+math.abs(n.Z)*eh.Z
    local nd,no=n:Dot(d),n:Dot(o)
    if math.abs(nd)<1e-7 then if no>b then hi=-1 end
    elseif nd<0 then
     local near=(b-no)/nd
     if near>lo then lo=near;normal=n.Unit end
    else hi=math.min(hi,(b-no)/nd) end
   end
   if normal and lo<=hi and lo>=0 and lo<=1 and (not nearest or lo<nearest.alpha) then
    local n=cf:VectorToWorldSpace(normal)
    local center=from+delta*lo
    nearest={alpha=lo,Instance=p,Normal=n,Position=center-(expand and V.new(n.X*expand.X,n.Y*expand.Y,n.Z*expand.Z) or V.zero)}
   end
  end
 end
 return nearest
end
local report={origins={},live='UNKNOWN; Claude must rerun OutsmartTest'}
for _,origin in {V.zero,V.new(0,76,-360)} do
 local place,model,load,parts,covers=scene('slice-v2/prototype/guardian-greybox.rbxl',origin)
 world.Raycast=function(_,from,delta,params) return cast(parts,from,delta,params==covers and covers or nil) end
 world.Blockcast=function(_,cf,size,delta,params) assert(params==covers,'wrong wall query');return cast(parts,cf.Position,delta,covers,size/2) end
 local arenaSource=place.ServerScriptService.GreyboxArena.Source
 -- Extract only floor(), preserving its exact production ray origin/filter policy.
 local floorSource=assert(arenaSource:match('(function Arena.floor%(%a+, position%).-)\nfunction Arena.sight'))
 local floor=luau.load('local Arena={}\n'..floorSource..'\nreturn Arena.floor',{environment={workspace=world,Config={MeadowV4=true},Vector3=V}})()
 local O,Kit=load(place.ReplicatedStorage.MeadowV4.Outsmart),load(place.ReplicatedStorage.MeadowKeeper.Attacks)
 local a={origin=origin,params={},wallParams=covers,guardian=rb.Instance.new('Part'),model=rb.Instance.new('Model'),warning={},throws=0}
 a.guardian.Size=V.new(4,11,4)
 local ok,detail=O.levelApproach(a,floor);assert(ok,detail)
 -- Cover dimensions, runway width and all final 6+ studs use real rebuilt data.
 local lane=assert(model:FindFirstChild('OutsmartBaitFloor'));assert(lane.Size.Z>=22 and lane.Size.X>=6)
 for x=-2,2,.5 do for z=88,108.5,.5 do
  local p=floor(a,origin+V.new(-73+x,5.62,z));assert(p and math.abs(p.Y-origin.Y-.12)<.01,'body lane not level')
 end end
 local stars=0
 local api={floor=floor,safe=function() return false end,dashLegal=function() return true end,
  fx=function(_,name) if name=='WallStun' then stars+=1 end end}
 local function dash(now,dt)
  dt=dt or .05
  local start=assert(floor(a,origin+O.Start+V.new(0,3,0)))+V.new(0,5.5,0)
  a.guardian.CFrame=C.lookAt(start,start+V.zAxis);a.guardian.Position=start
  assert(Kit.begin(a,{},origin+O.Bait+V.new(0,3.12,0),now,'dash',api,{}))
  local direction=a.attack.direction
  for i=1,math.ceil(1.2/dt) do
   if not a.attack then break end
   assert(a.attack.direction==direction,'dash steered')
   Kit.step(a,now+i*dt,{},function() end,function() error('unexpected player hit') end,api,{})
   -- Lune keeps Position and CFrame properties independent.
   a.guardian.Position=a.guardian.CFrame.Position
  end
 end
 dash(10);assert(stars==1 and a.keeperStunUntil and a.model:GetAttribute('DashStopReason')=='collision','geometry dash failed: '..tostring(stars)..' / '..tostring(a.model:GetAttribute('DashStopReason'))..' / '..tostring(a.model:GetAttribute('DashStopCollider')))
 assert(a.model:GetAttribute('DashStopCollider'):match('R5BoulderFoot$'),'impact belongs to different cover')
 local stun=a.keeperStunUntil;dash(30);assert(stars==1 and a.keeperStunUntil==stun,'repeat stun refreshed')
 -- Removing the slab must expose the old 2-stud dip and fail the dense check.
 local without={};for _,e in parts do if e.p~=lane then table.insert(without,e) end end
 local with=parts;parts=without
 local oldOK,oldDetail=O.levelApproach(a,floor);assert(not oldOK,'level test missed pre-fix dip')
 a.wallBaitCorner=nil;dash(50);assert(stars==1 and a.model:GetAttribute('DashStopReason')=='floor height','old geometry did not reproduce reported stop: '..tostring(stars)..' / '..tostring(a.model:GetAttribute('DashStopReason')))
 parts=with
 -- Inject a narrow lip after bait: endpoints match, half-stud sampling catches it.
 local badFloor=function(ar,p) if p.Z-origin.Z>=105 and p.Z-origin.Z<105.5 then return V.new(p.X,origin.Y+2,p.Z) end;return floor(ar,p) end
 assert(not O.levelApproach(a,badFloor),'half-stud lip missed')
 -- Tagged cover within step tolerance: floor probe sees footing first.
 local tagged
 for _,p in covers do if p:GetAttribute('OutsmartBaitCover') then tagged=p end end
 assert(tagged,'cover tag missing')
 a.wallBaitCorner=nil
 local floorReal=api.floor
 api.floor=function(ar,p) if p.Z-origin.Z>105 then return V.new(p.X,origin.Y+2,p.Z) end;return floorReal(ar,p) end
 dash(70,.025);assert(stars==2 and a.model:GetAttribute('DashStopReason')=='collision','tagged close-cover tolerance failed')
 tagged:SetAttribute('OutsmartBaitCover',nil);a.wallBaitCorner=nil
 dash(90,.025);assert(stars==2 and a.model:GetAttribute('DashStopReason')=='floor height','untagged lip earned stun')
 tagged:SetAttribute('OutsmartBaitCover',true)
 api.safe=function(_,p) return p.Z-origin.Z>105 end;a.wallBaitCorner=nil
 dash(110);assert(stars==2,'safe zone earned stun')
 api.safe=function() return false end;api.dashLegal=function(_,p) return p.Z-origin.Z<=105 end;a.wallBaitCorner=nil
 dash(130);assert(stars==2,'leash exit earned stun')
 table.insert(report.origins,{origin={origin.X,origin.Y,origin.Z},level=detail,pre_fix_rejected=oldDetail,stars_once=true,repeat_refused=true,tolerance_tagged_only=true,safe_and_leash_preserved=true})
 print('PASS geometry-driven wall bait at',origin,'; old dip reproduced; exact .5 lane/lip; one stun/stars; tagged tolerance; safe/leash')
end
fs.writeFile('treasure/FIX8-CHECK.json',serde.encode('json',report,true))
