-- Pure deterministic fall/drop policy, shared by the isolated server and Lune tests.
local Policy = {}
function Policy.isRavineFall(x:number, y:number, z:number, falling:boolean):boolean
    return falling and math.abs(x)<79 and math.abs(z)<18 and y<0
end
function Policy.rim(x:number, z:number, approachZ:number):(number,number)
    if math.abs(x)>65 then return if x<0 then -84 else 84, math.clamp(z,-12,12) end
    local side = if math.abs(z)>.5 then z else approachZ
    local rz = if side>=0 then 24 else -24
    local rx = math.clamp(x,-72,72)
    if rz>0 and rx>-36 and rx<-8 then rx=-42 end -- carve beside walkout: use upper bank
    return rx,rz
end
function Policy.canPickup(carrier:number?, player:number):boolean
    return carrier==nil
end
return Policy
