-- Pure shared-domain contracts; this does not simulate Roblox seats or network.
local Domain=require('../core/Domain');local Config=require('../core/Config')
local profile=Domain.default()
assert(Domain.secure(profile,Config,'same-geode',1,{}))
assert(Domain.secure(profile,Config,'same-geode',1,{}));assert(profile.escapes==1,'idempotent award')
local ok=Domain.secure(profile,Config,'new-geode',1,{});assert(not ok,'pending cargo blocks second award')
assert(Domain.place(profile,'same-geode',0,0,0));assert(Domain.open(profile,Config,'same-geode'))
assert(Domain.secure(profile,Config,'new-geode',1,{}));assert(profile.escapes==2)
local rb=require('@lune/roblox');local V,C=rb.Vector3,rb.CFrame
local a,b=V.new(110,48,-120),V.new(40,24,-120);local forward=(b-a).Unit;local back=-forward;local right=V.yAxis:Cross(back).Unit;local up=back:Cross(right);local mid=(a+b)/2
local cf=C.new(mid.X,mid.Y,mid.Z,right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z)
assert((cf:PointToWorldSpace(V.new(0,0,-(b-a).Magnitude/2))-b).Magnitude<.001,'sloped native slab endpoint')
print('PASS shared core same-item idempotence, refusal, place/open/repeat; native sloped slab endpoint')
local D=require('./ReachableDrops')
local lane={GetAttribute=function() return true end}
-- Engine ray positions may differ by a float ULP at a connected lane joint.
-- A returned socket must retain its requested X/Z for stable repeat queries.
local function ray(o,d)
 if d.Y>0 then return nil end
 return {Position=V.new(o.X+0.000015,48,o.Z-0.000015),Normal=V.yAxis,Instance=lane}
end
local point=V.new(150.625,48,-115)
local socket=assert(D.valid(point,48,ray,ray,V))
assert(socket.X==point.X and socket.Z==point.Z,'joint ray drift changed socket footprint')
assert(D.valid(socket,48,ray,ray,V),'joint socket not repeatable')
local a1={route='main',index=2,a=V.new(160,48,-120),b=V.new(110,48,-120)}
local a2={route='main',index=3,a=a1.b,b=V.new(40,24,-120)}
assert(D.connected(a1,a2),'adjacent main joints must share reachable lane')
assert(not D.connected(a1,{route='other',index=2,a=V.new(160,24,-120),b=V.new(110,24,-120)}),'stacked crossing is not connected')
print('PASS stable joint socket X/Z, repeated footprint validation, connected main joint and stacked-lane rejection')
