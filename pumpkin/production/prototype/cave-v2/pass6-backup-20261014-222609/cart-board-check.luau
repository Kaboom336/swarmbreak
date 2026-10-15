-- Execute production boarding/departure helpers. Virtual engine; no physics claim.
local fs,luau,rb=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox')
local source=fs.readFile('prototype/cave-v2/Cart.server.luau')
local function section(a,b)
 local start=assert(source:find(a,1,true))
 return source:sub(start,assert(source:find(b,start,true))-1)
end
local V,C=rb.Vector3,rb.CFrame
local clock,attempts,readyAt,never,wrongWeld,missingWeld=0,0,3,false,false,false
local root={Position=V.zero,CFrame=C.identity,Anchored=true,IsA=function() return true end}
local character={Parent=true,Name='Carrier',GetAttribute=function() end,GetDescendants=function() return {root} end}
local hum={Health=100,Parent=character,PlatformStand=true,MoveTo=function() end,
 GetAttribute=function() end,GetState=function() return {Name='Running'} end,
 GetStateEnabled=function(self) return self.enabled end,
 SetStateEnabled=function(self,_,v) self.enabled=v end,ChangeState=function() end}
character.FindFirstChildOfClass=function() return hum end
character.FindFirstChild=function() return root end
local cargo,flag=nil,nil
local player={Name='Player',Character=character,GetAttribute=function(_,key)
 if key=='CaveItemID' then return cargo end
 if key==flag then return true end
end,SetAttribute=function() end}
local seat={Name='DriverSeat',CFrame=C.identity,Position=V.zero}
local weld={Part0=seat,Part1={IsDescendantOf=function(_,c) return c==character and not wrongWeld end},IsA=function(_,name) return name=='Weld' end}
seat.FindFirstChild=function() return seat.Occupant and not missingWeld and weld or nil end
seat.Sit=function(_,h)
 attempts+=1
 if clock>=readyAt and not never then seat.Occupant=h;h.SeatPart=seat end
end
local boarding,confirmed={},{}
local trace={ride=0}
local empty={FindFirstChild=function() end}
local env={state='Dock',index=1,base={Position=V.zero},seats={seat,empty},boarding=boarding,confirmed=confirmed,
 boardGeneration=0,waitTime=0,board={},trace=trace,diagnostic=function() end,
 Enum={HumanoidStateType={Seated='Seated',GettingUp='GettingUp'}},
 Vector3=V,CFrame=C,os={clock=function() return clock end},task={wait=function(dt) clock+=dt end}}
local api=luau.load(section('local function attached','local approachReserved')..
 section('local function boardPlayer','board.Triggered:Connect(boardPlayer)')..
 '\nreturn {board=boardPlayer,ready=departureReady,trace=function() return trace end}',{environment=env})()
assert(not api.ready(),'empty must remain Dock')
assert(api.board(player) and clock>=3 and attempts>1,'retry engine cooldown')
assert(api.ready() and api.trace().boarding.success and api.trace().boarding.reason=='confirmed','confirmed departure/evidence')
assert(not root.Anchored and not hum.PlatformStand and hum.enabled and not seat.Disabled,'avatar readiness')
assert(api.board(player),'idempotent confirmed boarding')
local function clear()
 seat.Occupant=nil;hum.SeatPart=nil;clock=0;attempts=0
 table.clear(confirmed);table.clear(boarding)
end
clear();never=true
assert(not api.board(player) and clock>=4.5 and not next(boarding) and not api.ready(),'timeout cannot arm departure')
assert(api.trace().boarding.reason=='SeatWeld/Occupant timeout' and api.trace().boarding.attempts>0,'failure diagnostic')
clear();never=false;readyAt=0;missingWeld=true
assert(not api.board(player) and not api.ready(),'Occupant without weld cannot arm departure')
clear();missingWeld=false;wrongWeld=true
assert(not api.board(player) and not api.ready(),'wrong rider weld cannot arm departure')
clear();wrongWeld=false;seat.Occupant=hum;hum.SeatPart=seat
assert(not api.ready(),'touch-seated rider is not confirmed by production path')
confirmed[seat]=hum;boarding[seat]=hum
assert(not api.ready(),'pending request cannot arm departure')
clear();root.Position=V.new(100,0,0)
assert(not api.board(player) and attempts==0,'range guard')
clear();root.Position=V.zero;boarding[seat]=hum
assert(not api.board(player) and attempts==0,'concurrency guard')
clear();hum.Health=0
assert(not api.board(player) and attempts==0,'dead guard')
hum.Health=100;flag='Stunned'
assert(not api.board(player) and api.trace().boarding.reason=='wait: Stunned','explicit effect refusal')
flag=nil;cargo='recovered-geode'
assert(api.board(player) and api.trace().boarding.cargo==cargo and api.ready(),'cargo permitted on exact path')
seat.Occupant=nil;hum.SeatPart=nil
assert(not api.ready(),'lost occupant cancels readiness')
print('PASS production boarding/departure: cooldown, cargo, readiness, Occupant-only, wrong weld, touch-only, pending, lost rider, timeout and refusal diagnostics (mock only)')
