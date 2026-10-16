local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V,C=rb.Vector3,rb.CFrame
-- Reuse the geometry-driven wall/dash harness, after the real late-swap code.
local lateCount=0
local function late(model,place,load)
 local plan=load(place.ServerScriptService.KitPlan)
 local cover,group
 for _,p in model:GetDescendants() do if p:GetAttribute('OutsmartBaitCover') then cover=p end end
 assert(cover and cover.CanCollide and cover.CanQuery and cover:HasTag('OutsmartBaitCover'))
 for _,g in plan.groups(model,'meadow') do if table.find(g.parts,cover) then group=g;break end end
 assert(group,'bait wall not covered by real KitPlan regression')
 local workspace=rb.Instance.new('Folder');model.Parent=workspace
 local kit={templates={},init=function() end,spawn=function() error('gameplay cover reached cosmetic replacement') end}
 local service=place.ServerScriptService
 local section=load(place.ReplicatedStorage.MeadowV4.Section1)
 local code=service.KitSwap.Source
 code=code:sub(1,assert(code:find('local function watch',1,true))-1)..'\nreturn apply'
 local apply=luau.load(code,{environment={script=service.KitSwap,workspace=workspace,
  require=function(n)
   if n==service.KitLibrary then return kit end
   if n==service.KitPlan then return {groups=function() return {group} end,lanes=plan.lanes,laneClear=plan.laneClear,bridgeCandidate=function() end} end
   if n==place.ReplicatedStorage.MeadowV4.Section1 then return {spawnKits=function() end,clearProps=section.clearProps} end
   error('unexpected module')
  end,
  game={GetService=function(_,name) if name=='Stats' then return {GetTotalMemoryUsageMb=function() return 0 end} end;return place.ReplicatedStorage end},
  Instance=rb.Instance,Vector3=V,CFrame=C,Enum=rb.Enum,warn=warn,print=function() end,
 }})()
 apply(model,'meadow')
 assert(cover.Parent and cover.CanCollide and cover.CanQuery and cover:GetAttribute('GameplayCover'),'late swap deleted cover')
 for _,lane in plan.lanes(model) do
  if (lane.CFrame.Position-cover.CFrame.Position).Magnitude>lane.Size.Magnitude/2+cover.Size.Magnitude/2+1 then continue end
  local lo,hi=V.new(math.huge,math.huge,math.huge),V.new(-math.huge,-math.huge,-math.huge)
  for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
   local q=lane.CFrame:PointToObjectSpace(cover.CFrame:PointToWorldSpace(cover.Size*V.new(x,y,z)/2))
   lo=V.new(math.min(lo.X,q.X),math.min(lo.Y,q.Y),math.min(lo.Z,q.Z))
   hi=V.new(math.max(hi.X,q.X),math.max(hi.Y,q.Y),math.max(hi.Z,q.Z))
  end end end
  assert(not (hi.X>-lane.Size.X/2+.001 and lo.X<lane.Size.X/2-.001 and hi.Z>-lane.Size.Z/2+.001 and lo.Z<lane.Size.Z/2-.001),'cover overlaps lane '..lane.Name)
 end
 -- Cover is a wall adjoining the bait runway, outside the through lanes/court.
 local position=cover.CFrame.Position-(model:GetAttribute('MeadowOrigin') or V.zero)
 print('retained cover',position,cover.Size)
 local court=model:FindFirstChild('PvpCourtFloor');assert(court and court:GetAttribute('WalkableLaneFloor'))
 assert((court.CFrame.Position-(model:GetAttribute('MeadowOrigin') or V.zero)-V.new(0,-.48,-42)).Magnitude<.001)
 local routes=load(place.ReplicatedStorage.MeadowV4.Gameplay).pvpRoutes()
 local length=0
 for i=2,#routes.Dummy do local a,b=routes.Dummy[i-1],routes.Dummy[i];length+=V.new(a.x-b.x,a.y-b.y,a.z-b.z).Magnitude end
 print('dummy route distance',length)
 assert(length<300,'long west detour restored')
 assert(routes.Dummy[#routes.Dummy].z==42 and routes.Tester[#routes.Tester].z==42,'court station mismatch')
 lateCount+=1
 fs.writeFile('treasure/FIX10-ROUTE.json',serde.encode('json',{oldDistance=485.8753756284714,newDistance=length,carrySpeed=13.5,estimatedMovingSeconds=length/13.5,measuredLiveSeconds='UNKNOWN',court={0,0,42},lateSwapCoverPreserved=true},true))
end
local source=fs.readFile('treasure/fix8-check.luau')
source=source:gsub('local parts,covers=%{%},%{%}','late(model,place,load)\n local parts,covers={},{}',1)
source=source:gsub('treasure/FIX8%-CHECK.json','treasure/FIX10-WALL.json')
source=source:gsub('lane.Size.Z>=22','lane.Size.Z>=21.9')
luau.load(source,{environment={require=require,late=late,print=print,warn=warn}})()
assert(lateCount==2,'both origins required')
-- Reuse the existing clearance and blocker probes against the new court.
source=fs.readFile('treasure/fix9-check.luau')
source=source:gsub('prop%(%-63,97%)','prop(0,-42)')
source=source:gsub('treasure/FIX9%-APPROACH%-AUDIT.json','treasure/FIX10-APPROACH-AUDIT.json')
-- Check the added timing records with a deterministic clock, including failure.
source=source:gsub("record%('waypoint',V.new%(10,3,0%),'approach 2'%)",[[record('phase',nil,'dummy approach')
 record('waypoint',V.new(10,3,0),'approach 2')
 time=12;record('arrived',V.new(10,3,0),'approach 2')
 record('phase',nil,'handoff')]])
source=source:gsub("local d=serde.decode%('json',attributes.PvpTestLastApproach%)",[[local d=serde.decode('json',attributes.PvpTestLastApproach)
 assert(#d.legs==1 and d.legs[1].seconds==2 and d.legs[1].status=='arrived','per-leg timing')
 assert(#d.phases==2 and d.phases[1].seconds==2 and d.phases[2].seconds==58 and d.phases[2].status=='failed','phase timing after failure')]])
luau.load(source,{environment={require=require,print=print,warn=warn}})()
print('PASS fix10: real late KitSwap guard; dense wall approach and dash; shorter physical court; persisted leg/phase failure timings')
