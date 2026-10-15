-- Execute production retention, bulk movement, release and client controls.
-- Virtual engine only: weld solving/replication still require fresh Studio.
local fs, rb, luau = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau')
local source = fs.readFile('prototype/cave-v2/Cart.server.luau')
local function body(a,b)
 local start=assert(source:find(a,1,true))
 return source:sub(start,assert(source:find(b,start,true))-1)
end
local V,C=rb.Vector3,rb.CFrame
local clock,bulk,logs,clones=0,0,{},0
local root={CFrame=C.new(0,4,0),IsA=function(_,n) return n=='BasePart' end}
local limb={CFrame=C.new(1,4,0),IsA=root.IsA}
local character={Name='Boarded',Parent=true,FindFirstChild=function(_,n) if n=='HumanoidRootPart' then return root end end,
 GetDescendants=function() return {root,limb} end}
root.Parent=character
local player={Character=character}
local stateEnabled={Jumping=true}
local attrs={}
local h={Parent=character,Health=100,Sit=true,
 GetStateEnabled=function(_,s) return stateEnabled[s] end,
 SetStateEnabled=function(_,s,v) stateEnabled[s]=v end,
 SetAttribute=function(_,k,v) attrs[k]=v end}
local seat={CFrame=C.new(0,2,0),IsA=root.IsA,Occupant=h}
h.SeatPart=seat
local weld={Part0=seat,Part1={IsDescendantOf=function(_,c) return c==character end},IsA=function() return true end}
seat.FindFirstChild=function(_,n) if n=='SeatWeld' then return weld end end
seat.Sit=function(_,rider) seat.Occupant=rider;rider.SeatPart=seat end
weld.Destroy=function() weld=nil;seat.Occupant=nil;h.SeatPart=nil end
local base={CFrame=C.identity,IsA=root.IsA}
local model={GetPivot=function() return base.CFrame end,GetDescendants=function() return {base,seat} end}
local confirmed={[seat]=h}
local env={Enum={HumanoidStateType={Jumping='Jumping'},BulkMoveMode={FireCFrameChanged='bulk'}},
 CFrame=C,Vector3=V,confirmed=confirmed,model=model,exiting={},seats={seat},state='Flight',index=1,
 os={clock=function() return clock end},task={defer=function(f) f() end},
 game={Players={GetPlayerFromCharacter=function(_,c) return c==player.Character and player end}},
 script={CaveRiderControls={Clone=function() clones+=1;return {} end}},
 diagnostic=function(event) table.insert(logs,event) end,print=function() end,
 workspace={BulkMoveTo=function(_,parts,frames)
  bulk+=1;assert(#parts==4,'bulk must include cart and both avatar parts')
  for i,p in parts do p.CFrame=frames[i] end
 end}}
local api=luau.load(body('local riding = {}','local boardGeneration')..
 body('local function attached','local approachReserved')..
 body('local function exitHumanoid','bail.Triggered:Connect')..
 body('local function retainRiders','local function step')..
 '\nreturn {lock=lockRider,unlock=unlockRider,retain=retainRiders,pivot=pivot,exit=exitHumanoid}',{environment=env})()
api.lock(h)
assert(not stateEnabled.Jumping and attrs.CaveCartRiding and clones==1,'server lock/client installation')
local original=weld
for _,state in {'Track','Flight','Landing','Track'} do
 env.state=state;api.retain()
 local before=seat.CFrame:ToObjectSpace(root.CFrame)
 api.pivot(V.new(clock*24,15,9),V.new(1,0,0));clock+=.1
 assert(weld==original and seat.Occupant==h and h.SeatPart==seat,'intact weld replaced')
 assert((seat.CFrame:ToObjectSpace(root.CFrame).Position-before.Position).Magnitude<.001,'cart/rider moved separately')
end
-- Force the reported fault; retained identity must recover even after Occupant clears.
env.state='Flight';seat.Occupant=nil;h.SeatPart=nil;weld=nil
api.retain()
assert(seat.Occupant==h and h.SeatPart==seat and #logs==1 and logs[1]:find('re%-sit'),'missing re-seat/log')
weld=original
api.exit(h,V.new(0,-10,25))
assert(not next(confirmed) and stateEnabled.Jumping and not attrs.CaveCartRiding,'release did not restore controls')
assert(root.CFrame.Position==V.new(0,-10,25) and seat.Occupant==nil,'failed jump did not eject into pit')
-- A replacement Character never inherits the old Humanoid's reservation.
confirmed[seat]=h;api.lock(h);player.Character={};api.retain()
assert(not next(confirmed) and not attrs.CaveCartRiding and stateEnabled.Jumping,'stale respawn reference retained')
-- Client lock/release preserves an initially disabled jump state too.
for _,initial in {true,false} do
 local enabled=initial;local active=true;local changed
 local hum={GetAttribute=function() return active end,GetStateEnabled=function() return enabled end,
  SetStateEnabled=function(_,_,v) enabled=v end,
  GetAttributeChangedSignal=function() return {Connect=function(_,f) changed=f end} end}
 luau.load(fs.readFile('prototype/cave-v2/RiderControls.client.luau'),{environment={
  script={Parent={WaitForChild=function() return hum end}},Enum=env.Enum}})()
 assert(not enabled,'client jumping still enabled')
 active=false;changed();assert(enabled==initial,'client prior state not restored')
end
print('PASS actual rider retention/re-seat/log, atomic cart+rider transform/weld identity, pit release, respawn and server/client jump restoration (mock)')
