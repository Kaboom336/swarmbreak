-- Run the production prompt/API boarding function with a delayed seat engine.
-- This checks retries and truthfulness, not Roblox physics or replication.
local fs,luau,rb=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox')
local source=fs.readFile('prototype/cave-v2/Cart.server.luau')
local first=assert(source:find('local function boardPlayer',1,true))
local last=assert(source:find('board.Triggered:Connect(boardPlayer)',first,true))
local V,C=rb.Vector3,rb.CFrame
local clock,attempts,readyAt,never=0,0,3,false
local root={Position=V.zero,CFrame=C.identity}
local character={Parent=true}
local hum={Health=100,Parent=character,MoveTo=function() end}
character.FindFirstChildOfClass=function() return hum end
character.FindFirstChild=function() return root end
local player={Character=character}
local seat={CFrame=C.identity}
seat.FindFirstChild=function(_,name) return name=='SeatWeld' and seat.Occupant and {} or nil end
seat.Sit=function(_,h)
 attempts+=1
 if clock>=readyAt and not never then seat.Occupant=h;h.SeatPart=seat end
end
local boarding={}
local env={state='Dock',base={Position=V.zero},seats={seat,{}},boarding=boarding,
	trace={ride=0},diagnostic=function() end,
 Vector3=V,CFrame=C,os={clock=function() return clock end},task={wait=function(dt) clock+=dt end}}
local board=luau.load(source:sub(first,last-1)..'\nreturn boardPlayer',{environment=env})()
assert(board(player) and clock>=3 and attempts>1,'must retry cooldown until Occupant/SeatWeld')
assert(board(player),'already seated boarding must be idempotent')
seat.Occupant=nil;hum.SeatPart=nil;clock=0;attempts=0;never=true
assert(not board(player) and clock>=4.5 and next(boarding)==nil,'failed seat must time out false and release reservation')
clock=0;attempts=0;root.Position=V.new(100,0,0)
assert(not board(player) and attempts==0,'remote boarding must be refused')
root.Position=V.zero;boarding[seat]=hum
assert(not board(player) and attempts==0,'duplicate concurrent boarding must be refused')
boarding[seat]=nil;hum.Health=0
assert(not board(player) and attempts==0,'dead avatar boarding must be refused')
print('PASS production boarding cooldown retry, confirmed weld/occupant, idempotence, timeout cleanup, distance/concurrency/death guards (mock only)')
