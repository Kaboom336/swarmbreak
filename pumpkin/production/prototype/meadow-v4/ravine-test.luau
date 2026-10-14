local Policy = require("./RavinePolicy")
assert(Policy.isRavineFall(0,-2,0,true))
assert(not Policy.isRavineFall(0,4,0,true))
assert(not Policy.isRavineFall(0,-2,0,false))
assert(not Policy.isRavineFall(90,-2,0,true))
assert(not Policy.isRavineFall(-22,-12,10,false))
assert(Policy.canPickup(nil,17))
assert(not Policy.canPickup(17,18))
assert(not Policy.canPickup(17,17))
for _, case in {{0,0,30,0,24},{0,0,-30,0,-24},{30,-3,30,30,-24},{-22,3,30,-42,24},{70,0,30,84,0},{-70,0,30,-84,0}} do
    local x,z=Policy.rim(case[1],case[2],case[3])
    assert(x==case[4] and z==case[5], "Rim policy")
end
print("PASS 14 isolated policy assertions: fall threshold, ramp walk versus fall, exclusive carrier, reachable rim sides")
