-- Pure, engine-independent tunnel tuning. Rates are ESTIMATED targets, not telemetry.
local P={}
P.Tuning={Width=14,Ceiling=24,NormalSpeed=16,MudSpeed=8,MudLength=24,
 ShadowSeconds=0.7,FallSeconds=0.35,HazardLeadSeconds=1.05,ImpactRadius=3,KnockVelocity=18,
 FirstHazardSeconds=1.6,HazardInterval=2.4,RumbleAfter=8,RumbleInterval=0.9,
 ReentryGrace=3,ExitHoldSeconds=3,ExitWaitTimeout=14,ExitGuardRadius=12,PredictionProbability=0.60,KeeperSurfaceSpeed=32,
 ExpectedHitRate_ESTIMATED={0.20,0.35},ExpectedEscapeRate_ESTIMATED={0.45,0.60}}
P.Exits={{x=-76,y=0,z=78},{x=-61.8671875,y=0,z=98.953125}}
P.Surface={
 {x=-76,y=3,z=-27},{x=-90.375,y=3,z=-10.5625},{x=-100,y=3,z=8},
 {x=-100.1875,y=3,z=27.1875},{x=-95,y=3,z=46},{x=-86.4375,y=3,z=62.625},
 {x=-76,y=3,z=78},{x=-66.8125,y=3,z=92.125},{x=-61.8671875,y=3,z=98.953125}}
local function dist(x,z,ax,az,bx,bz)
 local dx,dz=bx-ax,bz-az
 local t=math.clamp(((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz),0,1)
 return math.sqrt((x-ax-dx*t)^2+(z-az-dz*t)^2)
end
function P.inside(x,y,z)
 if y<0 or y>24 then return false end
 return (math.abs(x+76)<=7.4 and z>=-27 and z<=78)
  or dist(x,z,-76,54,-60,82)<=7.4 or dist(x,z,-60,82,-61.8671875,98.953125)<=7.4
end
function P.inMud(x,y,z) return P.inside(x,y,z) and math.abs(x+76)<=7.4 and z>=-7 and z<=17 end
function P.hazardTarget(x,z,vx,vz)
 -- Lock the telegraph ahead of motion at expected impact; straight running must react.
 local tx,tz=x+vx*P.Tuning.HazardLeadSeconds,z+vz*P.Tuning.HazardLeadSeconds
 if P.inside(tx,3,tz) then return tx,tz end
 return x,z -- never telegraph outside the cave on a wall/roof or unreachable surface
end
function P.interval(age) return if age>=P.Tuning.RumbleAfter then P.Tuning.RumbleInterval else P.Tuning.HazardInterval end
function P.predict(x,z,randomUnit)
 local a,b=P.Exits[1],P.Exits[2]
 local nearest=if (x-a.x)^2+(z-a.z)^2<=(x-b.x)^2+(z-b.z)^2 then 1 else 2
 return if randomUnit<P.Tuning.PredictionProbability then nearest else 3-nearest
end
function P.path(exitId)
 local result={}
 for i,p in P.Surface do
  if exitId==2 or i<=7 then table.insert(result,p) end
 end
 return result
end
function P.shouldIntercept(activePlayer,activeExit,activeEpoch,player,exitId,epoch)
 return activePlayer~=player or activeExit~=exitId or activeEpoch~=epoch
end
return P
