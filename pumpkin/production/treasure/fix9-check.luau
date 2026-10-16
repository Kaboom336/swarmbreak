local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V=rb.Vector3
local path=require('@lune/process').args[1] or 'slice-v2/prototype/guardian-greybox.rbxl'
local place=rb.deserializePlace(fs.readFile(path));local cache={}
local function load(n)
 if cache[n] then return cache[n] end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Vector3=V,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,warn=warn}})();return cache[n]
end
local model=load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new('Folder'),V.zero)
local routes=load(place.ReplicatedStorage.MeadowV4.Gameplay).pvpRoutes()
local parts={}
for _,p in model:GetDescendants() do if p:IsA('BasePart') and p.CanCollide and not p:GetAttribute('WalkableLaneFloor') then
 local cf,h=p.CFrame,p.Size/2
 table.insert(parts,{p=p,cf=cf,h=h,x=cf.Position.X,y=cf.Position.Y,z=cf.Position.Z,radius=h.Magnitude+5})
end end
local hits,length={},0
for i=2,#routes.Dummy do
 local a,b=routes.Dummy[i-1],routes.Dummy[i]
 local from,to=V.new(a.x,a.y,-a.z),V.new(b.x,b.y,-b.z)
 length+=(to-from).Magnitude
 for step=0,math.ceil((to-from).Magnitude) do
  local foot=from:Lerp(to,step/math.max(1,math.ceil((to-from).Magnitude)))
  for _,e in parts do
   if math.abs(foot.X-e.x)>e.radius or math.abs(foot.Y-e.y)>e.radius or math.abs(foot.Z-e.z)>e.radius then continue end
   local q=e.cf:PointToObjectSpace(foot+V.new(0,2.8,0))
   if math.abs(q.X)<e.h.X+1.5 and math.abs(q.Z)<e.h.Z+1.5 and math.abs(q.Y)<e.h.Y+2.4 then
    local key=e.p:GetFullName()
    if not hits[key] then hits[key]={name=e.p.Name,segment=i,position={foot.X,foot.Y,foot.Z},part={e.cf.Position.X,e.cf.Position.Y,e.cf.Position.Z},size={e.p.Size.X,e.p.Size.Y,e.p.Size.Z},category=e.p:GetAttribute('MeadowV4Category')} end
   end
  end
 end
end
local section=load(place.ReplicatedStorage.MeadowV4.Section1)
local cleared=model:GetAttribute('PvpMapClearedProps')
if section.clearProps then
 assert(not model:GetAttribute('PvpMapClearanceFailure'),'map audit failed')
 assert(#section.clearProps(model)==0,'clearance must be idempotent')
 local live=load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new('Folder'),V.new(0,76,-360))
 assert(not live:GetAttribute('PvpMapClearanceFailure') and #section.clearProps(live)==0,'live origin map clearance')
 assert(live:GetAttribute('PvpMapClearedProps')==cleared,'origin-dependent dressing removal')
 local fixture=rb.Instance.new('Model')
 local lane=rb.Instance.new('Part');lane.Size=V.new(10,1,10);lane.CFrame=rb.CFrame.new(0,-.5,0);lane:SetAttribute('WalkableLaneFloor',true);lane.Parent=fixture
 local function prop(x,z)
  local p=rb.Instance.new('Part');p.Size=V.one;p.CFrame=rb.CFrame.new(x,1,z);p:SetAttribute('Section','S1');p.Parent=fixture;return p
 end
 local onLane,tooClose,edge=prop(0,0),prop(6.49,0),prop(6.5,0)
 local court=prop(-63,97)
 local kit=rb.Instance.new('Model');kit.Name='LateKit';kit.Parent=fixture
 local mesh=prop(0,0);mesh.Parent=kit
 local keep=rb.Instance.new('Part');keep.Name='GameplayCover';keep.Parent=fixture
 local removed=section.clearProps(fixture)
 assert(#removed==4 and edge.Parent==fixture and keep.Parent==fixture,'lane/court/one-stud boundary/assembly policy')
 print('PASS map clearance: lane intrusions, <1 margin, complete late kit and PvP court removed; exact 1 margin and gameplay cover preserved')
end
local source=place.ServerScriptService.GreyboxLoopTestRunner.Source
local first=source:find('local function approachRecorder',1,true)
if first then
 local last=assert(source:find('local function driver',first,true))
 local attributes,worldAttributes={},{}
 local root={Position=V.new(0,3,0),CFrame=rb.CFrame.new(0,3,0)}
 local obstacle=rb.Instance.new('Part');obstacle.Name='BlockingFence';obstacle.Position=V.new(4,3,0)
 local time=10
 local recorder=luau.load(source:sub(first,last-1)..'\nreturn approachRecorder',{environment={
  game={GetService=function() return {JSONEncode=function(_,d) return serde.encode('json',d) end} end},
  SSS={SetAttribute=function(_,key,value) attributes[key]=value end},
  Vector3=V,Enum=rb.Enum,RaycastParams={new=function() return {} end},OverlapParams={new=function() return {} end},
  workspace={Raycast=function() return {Instance=obstacle} end,GetPartBoundsInBox=function() return {obstacle} end},
  os={clock=function() return time end},
 }})()
 local record=recorder({Character={}},{root=function() return root,{WalkSpeed=13.5,FloorMaterial='Grass'} end},
  {SetAttribute=function(_,key,value) worldAttributes[key]=value end},{id='original',state='Carried',escapeDeadline=70})
 record('waypoint',V.new(10,3,0),'approach 2')
 record('path',V.new(10,3,0),'recovery',{{position={1,2,3},action='Walk'}})
 time=14;record('stuck',V.new(10,3,0),'approach 2','no progress')
 time=70;record('failed',nil,'dummy approach','expiry')
 local d=serde.decode('json',attributes.PvpTestLastApproach)
 assert(d.status=='failed' and d.remaining==0 and d.itemId=='original' and #d.waypoints==1 and #d.paths==1 and #d.stuck==1,'diagnostic fields')
 assert(d.blockingInstances.BlockingFence.collidable and attributes.PvpTestLastApproach==worldAttributes.PvpTestLastApproach,'persistent blocking instances')
 print('PASS actual approach recorder: path/waypoint/stuck/blocker/time/failure survive on service and world attributes')
end
print('length',length,'minimum carry seconds',length/13.5,'cleared props',cleared and #string.split(cleared,',')-1)
local obstacles={}
for key,h in hits do if h.category~='lane' then obstacles[key]=h end end
assert(next(obstacles)==nil,'non-lane physical obstruction on approach')
fs.writeFile('treasure/FIX9-APPROACH-AUDIT.json',serde.encode('json',{source=path,length=length,minimumSeconds=length/13.5,nonLaneObstacles=obstacles,cleared=cleared,live='UNKNOWN; rerun GreyboxPvpTest and StudioPassAll'},true))
