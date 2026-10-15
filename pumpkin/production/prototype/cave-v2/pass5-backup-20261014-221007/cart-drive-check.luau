-- Execute the actual production integrator/Heartbeat/diagnostic/reservation bodies.
-- Virtual seats/time only: no claim about Roblox physics or replication.
local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
local source = fs.readFile('prototype/cave-v2/Cart.server.luau')
local place = rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local data = luau.load(place.ReplicatedStorage.CaveRouteData.Source)()
local policy = require('./Policy')
local function body(first, last, code)
 code = code or source
 local a = assert(code:find(first, 1, true))
 return code:sub(a, assert(code:find(last, a, true)) - 1)
end
local path = body('local function vec', 'local broken = false')
local reserve = body('local function reserve', '-- Defer ordinary seat jumping')
local drive = body('local function step', 'actions[index].snapshot')
local resetStart = assert(source:find('actions[index].snapshot', 1, true))
local reset = source:sub(resetStart, assert(source:find('\n\tlocal pos, dir = at(0)', resetStart, true)) - 1)
local diagnostics = body('local trace =', 'local function boardPlayer')
for _, scenario in {{24, 1/60, true}, {24, 0.5, true}, {12, 0.5, true}, {24, 0.5, false}, {24, 0.3, true, true}} do
 local speed, frame, broken, legacy = unpack(scenario)
 local clock, callback, traceJSON = 0, nil, nil
 local seen, times, attrs = {}, {}, {}
 local hum = {Parent = {Name = 'Carrier'}, Health = 100}
 local seat = {Occupant = hum, FindFirstChild = function(self) return self.Occupant and {} end}
 local empty = {FindFirstChild = function() return nil end}
 local env = {data = data, Vector3 = rb.Vector3, Color3 = rb.Color3, index = 1,
  Policy = policy, state = 'Dock', distance = 0, speed = speed, flightSpeed = speed,
  committed = false, approachReserved = false, busy = 0, elapsed = 0, waitTime = 0,
  boarding = {}, seats = {seat, empty}, board = {}, gaugeText = {}, diverted = false,
  broken = broken, traces = {}, actions = {[1] = {}}, os = {clock = function() return clock end},
  Http = {JSONEncode = function(_, v) return serde.encode('json', v) end},
  script = {Parent = {SetAttribute = function() end}},
  model = {GetAttribute = function(_, key) return attrs[key] end,
   SetAttribute = function(_, key, v) attrs[key] = v end},
  hook = {GetAttribute = function() return false end},
  map = {RailSwitchHook = {GetAttribute = function() return false end}},
  game = {Players = {GetPlayerFromCharacter = function() return nil end}},
  pivot = function() end, bypassPosition = function() return rb.Vector3.zero end,
  exitHumanoid = function(h) if h then seat.Occupant = nil end end,
  RunService = {Heartbeat = {Connect = function(_, f) callback = f end}},
 }
 -- Keep mutable integrator values in the load environment; helper captures
 -- retain the exact production locals and reservation behavior.
 local selectedReserve, selectedDrive, selectedReset = reserve, drive, reset
 if legacy then
  local old = fs.readFile('prototype/cave-v2/pass3-backup-20261014-214253/Cart.server.luau')
  selectedReserve = body('local function reserve', '-- Defer ordinary seat jumping', old)
  selectedDrive = body('RunService.Heartbeat:Connect(function(dt)', '\n\tlocal pos, dir = at(0)', old)
  selectedReset = ''
 end
 local bootstrap = path .. selectedReserve .. diagnostics .. selectedDrive .. selectedReset .. [[
 local originalPivot = pivot
 return {snapshot = function() return trace end,
  record = diagnostic,
  repair = function() if Policy.canRepair(busy, false, os.clock()) then broken = false end end,
  reset = actions[index].reset,
  error = function() pivot = function() error('injected drive failure') end end,
  restore = function() pivot = originalPivot end,
  values = function() return state, distance, busy, committed end}
 ]]
 local controller = luau.load(bootstrap, {environment = env})()
 for _ = 1, math.ceil(65/frame) do
  clock += frame
  controller.repair()
  callback(frame)
  if legacy then controller.record() end
  local trace = controller.snapshot()
  traceJSON = attrs.CartLastRide
  assert(trace.lastError == '', trace.lastError)
  for _, event in trace.transitions do
   seen[event.state] = true
   times[event.state] = times[event.state] or event.t
  end
  local state, distance, busy = controller.values()
  -- Real repair is wall-clock based. A passenger ride must reserve the span
  -- from launch, even before the original 22-stud gap commitment envelope.
  if not legacy and state == 'Track' and distance < data.gapStart then
   assert(busy == 1 and not policy.canRepair(busy, false, 30), 'approach repair race')
  end
  if seen.End and state == 'Dock' then break end
 end
 assert(seen.Track and seen.End and seen.Dock, 'ride never completed')
 if legacy then
  assert(not seen.Flight and not seen.Landing, 'pre-fix reproduction did not miss jump')
  print('REPRODUCED pre-fix production: 0.3s Heartbeats + real-time repair => End/Dock without Flight/Landing; End at', times.End)
  continue
 end
 if broken then
  assert(seen[speed == 24 and 'Flight' or 'Fall'], 'missing jump/fall')
  if speed == 24 then assert(seen.Landing, 'missing landing') end
 else
  assert(not seen.Flight and not seen.Fall, 'intact span jumped')
 end
 assert(times.End < 45, 'discarded Heartbeat time slowed ride')
 local state, distance, busy, committed = controller.values()
 assert(state == 'Dock' and distance == 0 and busy == 0 and not committed, 'reservation/dock cleanup')
 local persisted = serde.decode('json', traceJSON)
 assert(#persisted.samples <= 80 and #persisted.transitions <= 40 and #persisted.samples > 5, 'trace bounds/persistence')
 assert(persisted.current.segment and persisted.current.seatWeld and persisted.current.Occupant, 'missing diagnostics')
 controller.reset()
 controller.reset()
 state, distance, busy, committed = controller.values()
 assert(state == 'Dock' and distance == 0 and busy == 0 and not committed and attrs.Speed == 24, 'repeat reset')
 -- A failing production Heartbeat is retained after reset instead of lost in Output.
 seat.Occupant = hum
 controller.error()
 for _ = 1, math.ceil(4/frame) do clock += frame; callback(frame) end
 assert(controller.snapshot().lastError:find('injected drive failure', 1, true), 'drive error not retained')
 seat.Occupant = nil
 controller.restore()
 controller.reset()
 assert(serde.decode('json', attrs.CartLastRide).lastError:find('injected drive failure', 1, true), 'reset erased error')
 print('PASS production drive mock', speed, frame, broken, 'End at', times.End, 'trace bytes', #traceJSON)
end
