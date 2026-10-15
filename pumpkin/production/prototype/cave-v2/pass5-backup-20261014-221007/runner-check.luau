-- Execute real diagnostic/coordinator bodies with virtual scheduling. No physics
-- claims: Studio still owns Humanoid, seat weld, mesh and prompt acceptance.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local place=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local S=place.ServerScriptService
local source=S.CaveStudioPass.Source
local before=assert(source:find('local running = false',1,true))
local execute=assert(source:find('local function execute',before,true))
local clock,warnings,cancelled=0,0,false
local mode='pass'
local env={script={Parent=S},workspace={CaveV2=place.Workspace.CaveV2},Vector3=rb.Vector3,CFrame=rb.CFrame}
env.game={ReplicatedStorage=place.ReplicatedStorage,GetService=function(_,name)
 if name=='RunService' then return {IsStudio=function() return true end} end
 if name=='HttpService' then return {JSONEncode=function(_,v) return serde.encode('json',v) end} end
end}
env.require=function() return {} end
env.os={clock=function() return clock end}
env.warn=function() warnings+=1 end
env.print=function() end
env.task={wait=function(dt) clock+=dt or .1 end,spawn=function(f) if mode~='timeout' then f() end;return {} end,cancel=function() cancelled=true end}
local prefix=source:sub(1,before-1)
local diagnostics=luau.load(prefix..'\nreturn {fail=failure,snapshot=function() return failures,total,logged end}',{environment=env})()
for i=1,40 do diagnostics.fail('synthetic',{laneId='test:'..i}) end
local failures,total,logged=diagnostics.snapshot()
assert(#failures==30 and total==40 and logged==30 and warnings==30,'bounded failure evidence')
local suite='suites = {SelfTest = function() if TEST_FAIL then error("injected runner failure") end end}\n'
local tail=source:sub(before,execute-1)
for _,scenario in {'pass','fail','timeout'} do
 mode=scenario;clock=0;cancelled=false;env.TEST_FAIL=scenario=='fail'
 S:SetAttribute('SelfTestFailures','stale')
 local run=luau.load(prefix..suite..tail..'\nreturn run',{environment=env})()
 local ok=run('SelfTest')
 assert(ok==(scenario=='pass'),'coordinator verdict '..scenario)
 local evidence=serde.decode('json',S:GetAttribute('SelfTestFailures'))
 assert(#evidence==(scenario=='pass' and 0 or 1),'failure JSON '..scenario)
 if scenario=='timeout' then assert(cancelled and clock>=360,'watchdog did not cancel worker') end
end
print('PASS real runner PASS/FAIL/timeout, cancellation, stale evidence reset, 40 failures capped to 30 records/logs')
-- Both physical cart suites reset before/after, including failure/watchdog exits.
local resets,snapshots=0,0
local carts={Invoke=function(_,action)
 if action=='resetAll' then resets+=1;return true end
 if action=='snapshot' then snapshots+=1;S:SetAttribute('CartLastRide','{"retained":true}');return '{}' end
 error('unexpected cart action '..action)
end}
local facade=setmetatable({
 WaitForChild=function(_,name) if name=='CaveCartActions' then return carts end;return S:WaitForChild(name) end,
 FindFirstChild=function(_,name) if name=='CaveCartActions' then return carts end;return S:FindFirstChild(name) end,
 SetAttribute=function(_,...) S:SetAttribute(...) end,
 GetAttribute=function(_,...) return S:GetAttribute(...) end,
},{__index=function(_,name) return S[name] end})
env.script={Parent=facade}
local fixtureSuites='suites = {LoopTest = function() if TEST_FAIL then error("injected fixture failure") end end, CartRideTest = function() if TEST_FAIL then error("injected fixture failure") end end}\n'
for _,name in {'LoopTest','CartRideTest'} do
 for _,scenario in {'pass','fail','timeout'} do
  mode=scenario;clock=0;resets=0;snapshots=0;env.TEST_FAIL=scenario=='fail'
  local run=luau.load(prefix..fixtureSuites..tail..'\nreturn run',{environment=env})()
  assert(run(name)==(scenario=='pass'),'fixture verdict')
  assert(resets==(scenario=='timeout' and 1 or 2) and snapshots==2,'missing fixture cleanup '..name..scenario)
  assert(S:GetAttribute(name..'CartLastRide')=='{"retained":true}','missing suite cart evidence')
 end
end
print('PASS LoopTest/CartRideTest reset and trace retention on success, failure and watchdog (mock only)')
