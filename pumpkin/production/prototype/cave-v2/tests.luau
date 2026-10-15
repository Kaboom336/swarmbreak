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
