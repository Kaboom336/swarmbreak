-- Deterministic replay of the runner's Steal/retry sequence, real Rules/check/hit/
-- driver/hold, built geometry. Movement is kinematic; this is not Studio physics.
local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
local V = rb.Vector3
local place = rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local cache = {}
local function load(n)
 if cache[n] then return cache[n] end
 local value = luau.load(n.Source, {environment={script=n,require=load,Vector3=V,Vector2=rb.Vector2,CFrame=rb.CFrame,
  Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,
  ColorSequence=rb.ColorSequence,warn=warn,workspace={GetAttribute=function(_,k) return k=='UseMeadowV4' end},
  game={GetService=function(_,name)
   if name=='HttpService' then return {JSONDecode=function(_,s)return serde.decode('json',s)end} end
   if name=='RunService' then return {Heartbeat={Connect=function()return {Disconnect=function()end}end}} end
   return place.ReplicatedStorage
  end}}})()
 cache[n]=value;return value
end
local Config=load(place.ReplicatedStorage.GreyboxConfig)
local Rules=require('../slice-v2/prototype/LootRules')
local model=load(place.ReplicatedStorage.MeadowV4.Builder).build(place.Workspace,V.new(0,76,-360))
local ray=require('../prototype/meadow-v4/OfflineRay').new(model,nil,2)
local fixed=require('@lune/process').args[1]=='fixed'
local archived='slice-v2/prototype/guardian-greybox.pre-pvp2.rbxl'
local baseline=fs.isFile(archived) and rb.deserializePlace(fs.readFile(archived)) or place
local runner=fixed and fs.readFile('slice-v2/prototype/LoopTest.luau') or baseline.ServerScriptService.GreyboxLoopTestRunner.Source
local gameplay=fs.readFile('slice-v2/prototype/Greybox.server.luau')
local function slice(s,a,b) return s:sub(assert(s:find(a,1,true)),assert(s:find(b,1,true))-1) end
local methods=slice(runner,'local function driver(', 'local function recoveryPoint(')..'\nreturn {driver=driver,hold=hold}'
local combat=slice(gameplay,'local function hit(', 'local function bumpTarget(')..'\nreturn {hit=hit,check=check}'
local reported=V.new(5.68,127.56,-466.67)
local nest=V.new(0,124,-456)
local camp=V.new(0,129.5,-456)
local direction=V.new(reported.X-camp.X,0,reported.Z-camp.Z).Unit
local start=reported-direction*Config.GuardianKnockback
local rows={}
local function replay(seed, keeperMode, timer, dummyOffset, rest, interrupt, keeperPosition, moveSocket)
 local now=100+seed*.001
 local rules=Rules.new(Config)
 local actor={Character={}}
 local state=Rules.actor(rules,actor);state.phase='Run';state.run={};state.mercy=now+timer
 local item=Rules.spawn(rules,nest)
 local r=rb.Instance.new('Part');r.CFrame=rb.CFrame.new(start+dummyOffset)
 local h={Health=100,WalkSpeed=16,FloorMaterial=rb.Enum.Material.Grass}
 local goal
 function h:Move() goal=nil end
 function h:MoveTo(p) goal=p end
 local root={}
 setmetatable(root,{__index=function(_,k) if k=='SetNetworkOwner' then return function()end end;if k=='Position' then return r.CFrame.Position end;return r[k] end,
  __newindex=function(_,k,v) if k=='Position' then r.CFrame=rb.CFrame.new(v) else r[k]=v end end})
 local keeper=keeperPosition or camp
 local arena={origin=V.new(0,76,-360),mode=keeperMode,guardian={Position=keeper}}
 state.run=arena
 local api={rules=rules,root=function()return root,h end,arena=function()return arena end,audit=function()Rules.audit(rules)end}
 local captured, hitDone, begins, navigations=nil,false,0,0
 local lastSocket=nest
 local env={Vector3=V,CFrame=rb.CFrame,Config=Config,Rules=Rules,rules=rules,states=rules.actors,arena=arena,
  root=api.root,V4=false,Arena={safe=function()return false end,sight=function()return true end},
  RaycastParams={new=function()return {} end},Enum=rb.Enum,os={clock=function()return now end},
  workspace={Blockcast=function()return nil end},dropPosition=function()return rest end,
  goal=function()end,publish=function()end,refreshLoot=function()end,
  game={GetService=function()return {SetAttribute=function()end,JSONEncode=function()return '{}'end}end}}
 local c=luau.load(combat,{environment=env})()
 api.holdAction=function(_,action,stage)
  lastSocket=item.position or lastSocket
  if stage=='begin' then begins+=1 end
  if stage=='begin' then return Rules.begin(rules,actor,action,nil,now,c.check) end
  return Rules.finish(rules,actor,action,now,c.check,function()return rest end)
 end
 local function advance(dt)
  now+=dt
  if goal then
   local d=goal-root.Position;local step=math.min(d.Magnitude,h.WalkSpeed*dt)
   if step>0 then root.Position+=d.Unit*step end
  end
 end
 env.task={wait=function(dt)
  if dt>1 and interrupt and not hitDone and keeperMode=='Chase' then
   advance(.2)
   hitDone=c.hit(actor,keeper,'Guardian')
   captured=root.Position
   advance(dt-.2)
  else advance(dt) end
 end}
 env.SSS={SetAttribute=function()end};env.updateDrop=function()end
 local m=luau.load(methods,{environment=env})()
 local Clearance=load(place.ReplicatedStorage.MeadowV4.Clearance)
 local function checked(p,edge,radius) return Clearance.resolve(p,edge,radius,ray,Config.MeadowV4,V) end
 local walk=m.driver(actor,rules.actors,api,function()end,checked)
 -- Real walk body; navmesh service is replaced only with direct court steering.
 local movedSocket=false
 local function navigate(p,name)
  navigations+=1
  local ok,why=walk(p,name)
  if moveSocket and not movedSocket then item.position+=V.new(6,0,0);movedSocket=true end
  return ok,why
 end
 api.floor=function(p)
  local hit=ray(p+V.new(0,9,0),V.new(0,-70,0));return hit and hit.Position
 end
 local ok,why=pcall(m.hold,api,actor,'Steal',navigate,checked)
 Rules.audit(rules)
 local result={seed=seed,keeper=keeperMode,mercy=timer,dummyOffset={dummyOffset.X,dummyOffset.Y,dummyOffset.Z},
  rest={rest.X,rest.Y,rest.Z},keeperPosition={keeper.X,keeper.Y,keeper.Z},movedSocket=movedSocket,
  interrupt=interrupt,hit=hitDone,ok=ok,why=not ok and tostring(why) or nil,
  begins=begins,navigations=navigations,position={root.Position.X,root.Position.Y,root.Position.Z},
  displaced=captured and {captured.X,captured.Y,captured.Z},distance=(root.Position-(lastSocket+V.new(0,1.5,0))).Magnitude}
 if ok then assert(state.item==item and item.state=='Carried' and item.firstPickup and math.abs(item.escapeDeadline-item.firstPickup-Config.EscapeSeconds)<.001,'pickup/conservation/deadline') end
 r:Destroy();return result
end
for seed=1,8 do
 for _,mode in {'Guard','Chase'} do
  for _,mercy in {0,3} do
   for _,offset in {V.zero,V.new(.2,0,0),V.new(-.2,0,.2)} do
    for _,rest in {nest,V.new(0,76,-402),V.new(6,124,-466.7)} do
     for _,keeper in {camp,V.new(-7,129.5,-470),V.new(10,129.5,-456)} do
      table.insert(rows,replay(seed,mode,mercy,offset,rest,true,keeper))
     end
    end
   end
  end
 end
end
local failures=0
for _,row in rows do if not row.ok then failures+=1 end end
local target=replay(1,'Chase',0,V.zero,nest,true)
local stale=fixed and replay(1,'Guard',0,V.zero,nest,false,nil,true) or nil
if stale then assert(stale.ok and stale.movedSocket and stale.navigations>=2,'live socket must be re-read after movement') end
-- Continue the production item sequence independently of the refusal fragment:
-- shield -> Bump -> legal settle -> actual runner recovery -> secure -> place.
local laneRay=require('../prototype/meadow-v4/OfflineRay').new(model,function(p)return p:GetAttribute('WalkableLaneFloor')==true end,2)
local Drops=load(place.ReplicatedStorage.MeadowV4.ReachableDrops)
local graph=Drops.graph(load(place.ReplicatedStorage.MeadowV4.Fix2Routes).waypoints(load(place.ReplicatedStorage.MeadowV4.RouteData)),V,V.new(0,76,-360))
local Clearance=load(place.ReplicatedStorage.MeadowV4.Clearance)
local sequenceMethods=slice(runner,'local function driver(', 'local function recover(api,')..'\nreturn {driver=driver,recover=recoverAttempt}'
local sequences={}
for seed=1,8 do
 for _,probe in {V.new(0,79,-402),V.new(-3,79,-402),V.new(3,79,-402),V.new(0,127,-456),reported} do
  local now=seed*.001+200
  local rules=Rules.new(Config)
  local carrier,player={Character={}},{Character={}}
  local cs,ps=Rules.actor(rules,carrier),Rules.actor(rules,player)
  local arena={}
  cs.phase,cs.run,ps.phase,ps.run='Run',arena,'Run',arena
  local roots={[carrier]={Position=nest+V.new(0,3,0)},[player]={Position=nest+V.new(1,3,0)}}
  local humanoids,goals={},{}
  for _,actor in {carrier,player} do
   roots[actor].SetNetworkOwner=function()end
   humanoids[actor]={Health=100,WalkSpeed=Config.CarrySpeed,FloorMaterial=rb.Enum.Material.Grass,
    Move=function()goals[actor]=nil end,MoveTo=function(_,p)goals[actor]=p end}
  end
  local api={rules=rules,root=function(a)return roots[a],humanoids[a] end,arena=function()return arena end,
   audit=function()Rules.audit(rules)end}
  local env={Vector3=V,Enum=rb.Enum,Config=Config,Rules=Rules,rules=rules,states=rules.actors,arena=arena,root=api.root,
   Arena={safe=function()return false end,sight=function()return true end},os={clock=function()return now end},
   SSS={SetAttribute=function()end},updateDrop=function()end,
   game={GetService=function()return {SetAttribute=function()end,JSONEncode=function()return '{}'end}end}}
  local check=luau.load(slice(gameplay,'local function check(', 'local function bumpTarget(')..'\nreturn check',{environment=env})()
  local item=Rules.spawn(rules,nest)
  assert(Rules.begin(rules,carrier,'Steal',nil,now,check));now+=Config.HoldSeconds.Steal+.05
  assert(Rules.finish(rules,carrier,'Steal',now,check))
  local timestamp,deadline=item.firstPickup,item.escapeDeadline
  now=cs.shield+.05
  local floor=assert(Drops.floor(probe,laneRay,V),'carrier lane')
  local socket=assert(Drops.settle(probe,floor.Y,{},laneRay,ray,V,graph,floor),'drop must stay reachable')
  -- Both actors arrive at the selected floor in the offline movement model.
  roots[carrier].Position=floor+V.new(0,3,0);roots[player].Position=floor+V.new(1,3,0)
  assert(Rules.begin(rules,player,'Bump',carrier,now,check));now+=Config.HoldSeconds.Bump+.05
  assert(Rules.finish(rules,player,'Bump',now,check,function()return socket end))
  assert(item.state=='Dropped' and not cs.item and not ps.item,'direct Bump award')
  assert(not Rules.begin(rules,player,'Grab',nil,now,check),'settle precharge')
  api.holdAction=function(actor,action,stage)
   if stage=='begin' then return Rules.begin(rules,actor,action,nil,now,check) end
   return Rules.finish(rules,actor,action,now,check)
  end
  env.task={wait=function(dt)
   now+=dt
   for actor,goal in goals do
    local root=roots[actor];local delta=goal-root.Position
    if delta.Magnitude>0 then root.Position+=delta.Unit*math.min(delta.Magnitude,humanoids[actor].WalkSpeed*dt) end
   end
  end}
  local m=luau.load(sequenceMethods,{environment=env})()
  local function checked(p,_,radius)return Clearance.resolve(p,false,radius,ray,Config.MeadowV4,V) end
  local walk=m.driver(player,rules.actors,api,function()end,checked)
  assert(m.recover(api,player,rules.actors,walk,item,function()end,checked),'actual recovery failed')
  assert(not api.holdAction(player,'Grab','finish'),'duplicate Grab')
  assert(item.firstPickup==timestamp and item.escapeDeadline==deadline,'handoff refreshed deadline')
  assert(Rules.secure(rules,player,now));assert(item.securedAt<deadline)
  assert(Rules.place(rules,player));assert(not Rules.place(rules,player),'duplicate Place')
  Rules.audit(rules)
  table.insert(sequences,{seed=seed,probe={probe.X,probe.Y,probe.Z},socket={socket.X,socket.Y,socket.Z},state=item.state,seconds=now-timestamp})
 end
end
local floor=assert(ray(reported+V.new(0,9,0),V.new(0,-70,0)))
local report={cases=#rows,failures=failures,target=target,stale_socket=stale,production_handoff_sequences=sequences,reported_floor={name=floor.Instance:GetFullName(),y=floor.Position.Y},
 limitation='Kinematic movement and injected real production hit; no engine physics/navmesh. Seeds vary clock phase, not physics.'}
fs.writeFile(fixed and 'treasure/PVP2-AFTER.json' or 'treasure/PVP2-BEFORE.json',serde.encode('json',report,true))
fs.writeFile(fixed and 'treasure/PVP2-AFTER-CASES.json' or 'treasure/PVP2-BEFORE-CASES.json',serde.encode('json',rows,true))
print(serde.encode('json',report,true))
if fixed then assert(failures==0,'fixed sweep failed')
else assert(not target.ok and target.hit and tostring(target.why):find('limit=9.0',1,true),'must reproduce exact Steal retry refusal') end
