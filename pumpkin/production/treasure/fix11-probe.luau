local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local V=rb.Vector3
local place=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local cache={}
local function load(n)
 if cache[n] then return cache[n] end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Vector3=V,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,warn=warn}})();return cache[n]
end
local model=load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new('Folder'),V.zero)
local ray=require('../prototype/meadow-v4/OfflineRay').new(model)
local parts={}
for _,p in model:GetDescendants() do if p:IsA('BasePart') and p.CanCollide and p.CanQuery then table.insert(parts,{p=p,cf=p.CFrame,h=p.Size/2}) end end
local function sight(_,from,to)
 local delta=to-from
 if delta.X==0 and delta.Z==0 then local h=ray(from,delta);return h==nil,h and h.Instance.Name end
 for _,e in parts do
  local o,d=e.cf:PointToObjectSpace(from),e.cf:VectorToObjectSpace(delta)
  local lo,hi=0,1
  for _,axis in {'X','Y','Z'} do
   if math.abs(d[axis])<1e-8 then if math.abs(o[axis])>e.h[axis] then hi=-1;break end
   else local a,b=(-e.h[axis]-o[axis])/d[axis],(e.h[axis]-o[axis])/d[axis];lo=math.max(lo,math.min(a,b));hi=math.min(hi,math.max(a,b)) end
  end
  if hi>=lo and lo>=0 and lo<=1 then return false,e.p.Name end
 end
 return true
end
local api={}
function api.floor(_,p)
 local hit=ray(V.new(p.X,p.Y+12,p.Z),V.new(0,-90,0))
 if hit and hit.Instance:GetAttribute('SurfaceRole')=='Floor' then return hit.Position,hit.Normal end
end
api.sight=sight;api.safe=function() return false end
local config=load(place.ReplicatedStorage.GreyboxConfig)
local traps=load(place.ReplicatedStorage.GreyboxTraps)
local a={origin=V.zero,layout=load(place.ReplicatedStorage.MeadowV4.Gameplay).assemble(config,1)}
local manager=traps.new(config,api)
local O=load(place.ReplicatedStorage.MeadowV4.Outsmart)
local p=assert(api.floor(a,O.Bell+V.new(0,3,0)))
local ok,why=traps.spot(manager,a,p,p+V.new(0,3,0));assert(ok,tostring(why))
for _,part in model:GetDescendants() do if part:IsA('BasePart') and part:GetAttribute('WalkableLaneFloor') then
 local q=part.CFrame:PointToObjectSpace(p)
 assert(math.abs(q.X)>part.Size.X/2+9 or math.abs(q.Z)>part.Size.Z/2+9 or math.abs(q.Y)>8,'bell bypass overlaps lane '..part.Name)
end end
print('PASS fixed bell full bypass, off all lane footprints',p)
-- Both normal construction and the real late audit reserve this clearing.
local section=load(place.ReplicatedStorage.MeadowV4.Section1)
local function prop(name,position)
 local q=rb.Instance.new('Part');q.Name=name;q.Size=V.new(1,2,1);q.CFrame=rb.CFrame.new(position)
 q.Anchored,q.CanCollide,q.CanQuery=true,true,true;q:SetAttribute('Section','S1');q.Parent=model;return q
end
local overlap=prop('BellIntruder',O.Bell+V.new(0,1,0))
local outside=prop('CosmeticOutside',V.new(150,1,150))
local cover=model:FindFirstChild('R5BoulderFoot')
section.clearProps(model)
assert(overlap.Parent==nil,'bell clearing lost to late dressing')
assert(outside.Parent and not outside.CanQuery and not outside.CanCollide and outside:GetAttribute('Cosmetic'),'cosmetic query flags')
print('PASS late clearing reservation and nonqueryable cosmetic policy')
local source=place.ServerScriptService.GreyboxArena.Source
local initStart=assert(source:find('local sightParts = {}',1,true))
local init=source:sub(initStart,assert(source:find('\n\treturn a',initStart,true))-1)
local aSight={}
luau.load(init,{environment={a=aSight,model=model,RaycastParams={new=function() return {} end},Enum=rb.Enum}})()
assert(table.find(aSight.sightParams.FilterDescendantsInstances,outside)==nil,'cosmetic in sight filter')
local wall
for _,part in model:GetDescendants() do if part:GetAttribute('GameplayCover') then wall=part;break end end
assert(wall and table.find(aSight.sightParams.FilterDescendantsInstances,wall),'wall excluded from sight')
local late=prop('LateKit',V.new(0,2,-42))
assert(table.find(aSight.sightParams.FilterDescendantsInstances,late)==nil,'late art entered sight filter')
late:Destroy()
local socket=V.new(-.12,.12,-42.59)
local root={Position=V.new(0,3.12,-42)}
local item={id='fix11',version=1,position=socket}
local sightSource=source:sub(assert(source:find('function Arena.sight(',1,true)),assert(source:find('function Arena.safe(',1,true))-1)
local forcedHit
local Arena={safe=function() return false end}
luau.load(sightSource,{environment={Arena=Arena,workspace={Raycast=function(_,from,delta,params)
 assert(params==aSight.sightParams,'sight used floor query')
 if forcedHit then return forcedHit end
 local clear,blocker=sight(nil,from,from+delta)
 assert(clear,'reported drop blocked by native geometry '..tostring(blocker))
end}}})()
local actor={};local diagnostic,logged
local serverSource=place.ServerScriptService.Greybox.Source
local checkSource=serverSource:sub(assert(serverSource:find('local function check(',1,true)),assert(serverSource:find('local function bumpTarget(',1,true))-1)..'\nreturn check'
local check=luau.load(checkSource,{environment={root=function() return root end,states={[actor]={run=aSight}},arena=aSight,Arena=Arena,Vector3=V,
 game={GetService=function(_,service)
  if service=='ServerScriptService' then return {SetAttribute=function(_,key,value) assert(key=='LootHoldLastRefusal');diagnostic=value end} end
  return {JSONEncode=function(_,value) return value end}
 end},testLog=function(value) logged=value end}})()
for _,z in {-42,-41,-40} do root.Position=V.new(0,3.12,z);assert(check(actor,'Grab',nil,item),'nearby Grab refused') end
root.Position=V.new(0,3.12,-38)
local accepted,reason=check(actor,'Grab',nil,item)
assert(not accepted and diagnostic.distance>4 and diagnostic.blocker=='NONE' and reason:find('range',1,true),'range diagnostic')
root.Position=V.new(0,3.12,-42)
forcedHit={Instance=wall,Position=wall.CFrame.Position}
accepted,reason=check(actor,'Grab',nil,item)
assert(not accepted and diagnostic.blocker==wall:GetFullName() and reason:find('sight',1,true) and logged==reason,'blocker diagnostic')
print('PASS production Grab: reported drop geometry; unchanged 4-stud limit; actual sight filter; wall blocker/refusal telemetry')
-- Execute the stationary presentation branch with a rotated, oversized root.
local stationary=serverSource:sub(assert(serverSource:find('-- Reset carried rotation',1,true)),assert(serverSource:find('\n\telseif item.state == "Placed"',1,true))-1)
local visual={Size=V.new(3,6,3)}
item.recoverAt=nil
luau.load(stationary,{environment={p=visual,item=item,CFrame=rb.CFrame,Vector3=V}})()
assert(math.abs(visual.CFrame.Position.Y-visual.Size.Y/2-socket.Y-.05)<.001,'loot sinks into floor')
assert(visual.CFrame.UpVector==V.yAxis,'carried rotation survived drop')
print('PASS dropped root rests above floor after carried rotation')
