-- Reuse the policy/domain/coordinator contracts and execute the real reset body
-- with an additional dirty arena, dummy, socket, timers and movement fixture.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local before=require('@lune/process').args[1]=='before'
local source=fs.readFile('prototype/s2r4-behavior.luau')
local underlying=fs.readFile('prototype/studio-pass-check.luau')
underlying=underlying:gsub('Config = {GuardianGuardOffset', 'Config = {WalkSpeed=16,JumpHeight=7.2,GuardianGuardOffset')
underlying=underlying:gsub('guardian = {}, tunnel =', 'guardian = {CFrame=rb.CFrame.new(1,2,3),Size=rb.Vector3.new(4,11,4)}, groundAction={Position=rb.Vector3.new(0,124,-456)}, tunnel =')
underlying=underlying:gsub('Health = 100, Move = function%(%) end','Health = 100, Move = function() end, MoveTo=function(self,p) self.WalkToPoint=p end')
underlying=underlying:gsub('fixture.prepare%(%)',[[
arena.mode,arena.untilTime,arena.throws,arena.computing='Guard',0,0,false
fixture.prepare()
arena.mode,arena.untilTime,arena.throws,arena.computing='Chase',9999,12,true
arena.guardCamp,arena.guardedVersion,arena.returnAfterAttack,arena.targetSince=rb.Vector3.new(20,5,20),7,true,999
arena.points,arena.occupants,arena.samplingDrops={{bad=true}},{bad=true},true
arena.lastDropResolution,arena.laneParams={bad=true},{bad=true}
arena.groundAction.Position=rb.Vector3.new(99,99,99)
arena.guardian.CFrame,arena.guardian.Size=rb.CFrame.new(90,90,90),rb.Vector3.new(4,6,4)
local dummy={Character={Destroy=function() end}}
states[dummy]={item={state='Carried'},phase='Run'}
]])
if before then underlying=underlying:gsub("states%[dummy%]={item={state='Carried'},phase='Run'}", "states[dummy]={phase='Run'}") end
underlying=underlying:gsub('local fixture =', "env.api={removeDummy=function(a) assert(states[a].item==nil,'retired cargo redropped');states[a]=nil end}\nlocal fixture =")
underlying=underlying:gsub('fixture.reset%(%)',[[fixture.reset()
assert(arena.mode=='Guard' and arena.untilTime==0 and arena.throws==0 and not arena.computing,'dirty Keeper restored')
assert(not arena.guardCamp and not arena.guardedVersion and not arena.returnAfterAttack and not arena.targetSince,'camp/target timers cleared')
assert(#arena.points==0 and next(arena.occupants)==nil and not arena.samplingDrops,'path/occupants/sampling restored')
assert(not arena.laneParams and not arena.lastDropResolution and not states[dummy],'caches/dummy cleared')
assert(arena.groundAction.Position==rb.Vector3.new(0,124,-456),'socket restored')
assert(arena.guardian.CFrame==rb.CFrame.new(1,2,3) and arena.guardian.Size==rb.Vector3.new(4,11,4),'Keeper physical restored')
assert(hum.WalkSpeed==16 and hum.JumpHeight==7.2 and hum.Jump==false and hum.UseJumpPower==false,'movement restored')
fixture.reset() -- Idempotence, including a second tunnel attachment.
]])
local env=table.clone(getfenv());local nativeRequire=require
env.require=function(path)
 if path=='@lune/fs' then
  local shim=table.clone(fs)
  shim.readFile=function(path)
   if path=='prototype/studio-pass-check.luau' then return underlying end
   if before and path=='slice-v2/prototype/Greybox.server.luau' then
    return require('@lune/roblox').deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-pvpflake.rbxl')).ServerScriptService.Greybox.Source
   end
   return fs.readFile(path)
  end
  return shim
 end
 if path:sub(1,2)=='./' then return nativeRequire('../prototype/'..path:sub(3)) end
 return nativeRequire(path)
end
local ok,why=pcall(luau.load(source,{environment=env,injectGlobals=true}))
if before then
 assert(not ok and tostring(why):find('dirty Keeper restored',1,true),'pre-fix must fail dirty Keeper regression: '..tostring(why))
 print('PASS negative control: pre-pvpflake reset FAILS dirty Keeper regression as expected')
 return
end
assert(ok,why)
print('PASS dirty suite reset: Keeper/counters/timers/path/dummy/socket/movement; repeat reset')
-- Execute production AI cancellation and its asynchronous completion, not a mock.
local ai=fs.readFile('slice-v2/prototype/Arena.luau')
local clear=ai:sub(assert(ai:find('local function clearPath(a)',1,true)),assert(ai:find('local function returnToCamp',1,true))-1)
local reset=ai:sub(assert(ai:find('function Arena.reset(a)',1,true)),assert(ai:find('-- Adapter called',1,true))-1)
local e={Arena={},Config={},Vector3=require('@lune/roblox').Vector3}
local funcs=luau.load(clear..reset..'\nreturn {reset=Arena.reset,clear=clearPath}',{environment=e})()
local archived=require('@lune/roblox').deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-pvpflake.rbxl')).ServerScriptService.GreyboxArena.Source
local oldClear=archived:sub(assert(archived:find('local function clearPath(a)',1,true)),assert(archived:find('local function returnToCamp',1,true))-1)
local oldReset=archived:sub(assert(archived:find('function Arena.reset(a)',1,true)),assert(archived:find('-- Adapter called',1,true))-1)
local oldFn=luau.load(oldClear..oldReset..'\nreturn Arena.reset',{environment={Arena={},Config={},Vector3=e.Vector3}})()
local leaked={computing=true,guardCamp={},untilTime=999,targetSince=99,returnAfterAttack=true}
oldFn(leaked)
assert(leaked.mode=='Guard' and leaked.computing and leaked.guardCamp and leaked.untilTime==999 and leaked.targetSince==99 and leaked.returnAfterAttack,'actual archived AI leakage reproduced')
print('PASS actual archived Arena.reset reproduces retained camp/timers/computing')
local a={pathVersion=4,tunnelGeneration=3,computing=true,points={1},guardCamp={},guardedVersion=7,
 returnAfterAttack=true,returnReason='old',untilTime=999,targetSince=99,chaseBegan=99}
funcs.reset(a)
assert(a.pathVersion==5 and a.tunnelGeneration==4 and not a.computing and #a.points==0)
assert(a.untilTime==0 and not a.guardCamp and not a.targetSince and not a.chaseBegan and not a.returnAfterAttack)
a.computing=true;funcs.clear(a);assert(not a.computing,'ordinary invalidation unlocks slot')
local requests={}
local worker=ai:sub(assert(ai:find('\tif now >= a.nextPath and not a.computing then',1,true)),assert(ai:find('\n\tlocal waypoint = a.points[a.index]',1,true))-1)
local V=require('@lune/roblox').Vector3
local q={pathVersion=1,nextPath=0,points={},model={Parent=true},guardian={Position=V.zero}}
local w={a=q,guard=q.guardian,now=10,destination=V.zero,Vector3=V,Config={GuardianPathRefreshSeconds=.7},
 Enum={PathStatus={Success='Success'}},task={spawn=function(fn)table.insert(requests,fn)end},
 Pathfinding={CreatePath=function() return {Status='Success',ComputeAsync=function()end,GetWaypoints=function()return {'new'}end,Destroy=function()end} end}}
local request=luau.load(worker,{environment=w})
request();assert(q.computing)
funcs.clear(q);q.nextPath=0
request();assert(q.computing and #requests==2)
requests[1]();assert(q.computing and #q.points==0,'stale completion cannot unlock/write newer request')
requests[2]();assert(not q.computing and q.points[1]=='new','current completion releases slot: '..tostring(q.computing)..' / '..tostring(q.points[1]))
print('PASS production Arena.reset and overlapping path completion epochs')
