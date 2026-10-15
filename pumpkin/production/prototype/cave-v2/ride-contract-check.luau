-- Execute the shipped ride harness with virtual time/seats. No Studio physics claim.
local fs, rb, luau = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau')
local source = fs.readFile('prototype/cave-v2/StudioPass.server.luau')
local place = rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local data = luau.load(place.ReplicatedStorage.CaveRouteData.Source)()
local function section(first, last, code)
 code = code or source
 local a = assert(code:find(first, 1, true))
 return code:sub(a, assert(code:find(last, a, true)) - 1)
end
local helpers = section('local function vec', 'local function ready')
local rideSource = section('local function ride', 'function suites.CartRideTest')
local V, C = rb.Vector3, rb.CFrame
local last = data.routes.railWalkBypass[#data.routes.railWalkBypass]
local exit = V.new(last[1], last[3] + 4, -last[2])
local function run(name, path, fault, code, lateEnd)
 local clock, boarded, snapshots, recovery = 0, nil, 0, 0
 local root = {Position = V.zero, AssemblyLinearVelocity = V.zero}
 local hum = {Health = 100}
 local seat = {Position = V.zero, FindFirstChild = function() return {} end}
 local pl = {GetAttribute = function(_, key)
  if key == 'CaveItemID' then return fault == 'cargo' and clock > 6 and 'wrong' or 'geode1' end
 end}
 local cart = {OreCart = {CFrame = C.identity}, DriverSeat = seat}
 local attrs = {State = 'Dock', TrackDistance = 0}
 cart.GetAttribute = function(_, key) return attrs[key] end
 local function advance(dt)
  clock += dt or .05
  if not boarded then return end
  local t = clock - boarded
  if lateEnd == true and t >= 16 and t < 16.6 then clock += .7; t += .7 end
  local state = t < 2 and 'Dock' or t < 16 and 'Track' or t < 20 and 'End' or 'Dock'
  if fault == 'no end' then state = 'Track' end
  if path and fault ~= 'no flight' and t >= 7 and t < 8 then state = path end
  if path == 'Flight' and fault ~= 'no flight' and t >= 8 and t < 9 then state = 'Landing' end
  attrs.State = state
  attrs.TrackDistance = state == 'End' and data.length or 0
  local dismounted = fault ~= 'no end' and (t >= 16.6 or (path == 'Fall' and t >= 16))
  hum.SeatPart = not dismounted and seat or nil
  seat.Occupant = not dismounted and hum or nil
  if lateEnd == 'partial seat' and state == 'End' and t < 16.6 then hum.SeatPart=nil end
  if lateEnd == 'partial occupant' and state == 'End' and t < 16.6 then seat.Occupant=nil end
  root.Position = dismounted and (path == 'Fall' and V.new(0,-10,25) or exit) or V.new(0, state == 'Flight' and 42 or 24, 0)
  seat.Position = root.Position
  if fault == 'rider' and t > 6 then seat.Occupant = {} end
  if fault == 'end rider' and state == 'End' then seat.Occupant = {} end
  if fault == 'end seat' and state == 'End' then hum.SeatPart = {} end
  if fault == 'exit' and dismounted then root.Position = V.zero end
 end
 local actions = {Invoke = function(_, action)
  if action == 'board' then
   boarded = clock; hum.SeatPart = seat; seat.Occupant = hum
   return true
  elseif action == 'toggle' then return 12
  elseif action == 'snapshot' then snapshots += 1; return '{}' end
  error('unexpected action ' .. action)
 end}
 local env = {Vector3 = V, CFrame = C, data = data,
  map = {RideableCart1 = cart, RideableCart2 = cart, BreakableSpan = {CanCollide = path == nil}},
  S = {WaitForChild = function() return actions end},
  boardCart = function()
   actions:Invoke('board')
   return pl, root, hum, seat
  end,
  player = function() return pl, root, hum end,
  os = {clock = function() return clock end}, task = {wait = advance},
  move = function() recovery += 1 end, walk = function() recovery += 1 end}
 local ride = luau.load(helpers .. (code or rideSource) .. '\nreturn ride', {environment = env})()
 local ok, err = pcall(ride, path == 'Fall' and 12 or 24, 'geode1', 1, path)
 if fault then
  assert(not ok, name .. ' incorrectly accepted')
  local expected = ({cargo = 'original cargo', rider = 'rider left seat', ['end rider']='wrong rider at End', ['end seat']='wrong rider at End', exit = path == 'Fall' and 'missed pit' or 'exit platform', ['no end'] = 'ride timeout', legacy = 'ride timeout', ['no flight'] = 'no big-air landing'})[fault]
  assert(tostring(err):find(expected, 1, true), name .. ': ' .. tostring(err))
 else
  assert(ok, name .. ': ' .. tostring(err))
  assert(clock < 20 and hum.SeatPart == nil, name .. ' waited past arrival or returned seated')
  assert(recovery == (path == 'Fall' and 2 or 0), name .. ' wrong recovery path')
 end
 print('PASS harness contract mock', name)
 return snapshots
end
run('intact span End/dismount/cargo', nil)
run('End first observed after production dismount', nil, nil, nil, true)
run('End SeatPart clears first', nil, nil, nil, 'partial seat')
run('End Occupant clears first', nil, nil, nil, 'partial occupant')
run('armed big-air End/dismount', 'Flight')
run('jump test rejects intact ride', 'Flight', 'no flight')
run('slow fall/recovery', 'Fall')
run('reject failed jump on wrong floor', 'Fall', 'exit')
run('reject changed cargo', nil, 'cargo')
run('reject changed rider', nil, 'rider')
run('reject replacement occupant at End', nil, 'end rider')
run('reject foreign SeatPart at End', nil, 'end seat')
run('reject wrong exit', nil, 'exit')
assert(run('reject missing End', nil, 'no end') == 1, 'missing timeout diagnostic')
-- The same 14-second intact ride fails with the backed-up pass-3 harness.
local old = fs.readFile('prototype/cave-v2/pass4-backup-20261014-215829/StudioPass.server.luau')
run('reproduce pass-3 intact-ride timeout', nil, 'legacy',
 section('local function ride', 'function suites.CartRideTest', old))
-- Execute the actual CartRideTest fixture, including its real cargo deadline
-- acceptance, rather than testing only the ride helper with a synthetic ID.
for _,fault in {false,'id','clock','dropped'} do
 local id,started,dropped,completed=nil,0,false,false
 local calls={}
 local label={Text='JUMP READY'}
 local map={BreakableSpan={CanCollide=true},JumpReady={FindFirstChildOfClass=function()
  return {FindFirstChildOfClass=function() return label end}
 end}}
 local root={}
 local cargo={Invoke=function(_,action)
  if action=='reset' then id=nil;dropped=false;return true end
  if action=='take' then id='same-geode';started=42;return id end
  if action=='status' then return completed and fault=='id' and 'replacement' or id,
   completed and fault=='dropped' or dropped,started+(completed and fault=='clock' and 1 or 0) end
 end}
 local env={suites={},ready=function() end,map=map,CFrame=C,
  player=function() return {},root,{} end,task={wait=function() end},
  await=function(f) assert(f(),'fixture predicate') end,
  S={CaveLoopActions=cargo,CaveCartActions={Invoke=function()
   map.BreakableSpan.CanCollide=false;label.Text='JUMP READY / 24'
  end}},ride=function(speed,carry,index,path)
   table.insert(calls,{speed,carry,index,path})
   if path=='Flight' then map.BreakableSpan.CanCollide=true
   else assert(carry=='same-geode','slow fail path omitted cargo');completed=true end
  end}
 local suite=luau.load(section('function suites.CartRideTest','-- Override the cart branch')..
  '\nreturn suites.CartRideTest',{environment=env})()
 local ok,err=pcall(suite)
 assert(ok==(fault==false),'cargo fixture verdict: '..tostring(fault)..' '..tostring(err))
 assert(#calls==2 and calls[1][4]=='Flight' and calls[2][4]=='Fall','missing jump/fall suite coverage')
end
print('PASS actual CartRideTest cargo fixture rejects replaced ID, reset deadline and dropped cargo (mock)')
