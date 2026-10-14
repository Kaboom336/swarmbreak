-- Deterministic execution of production callbacks; services/physics explicitly mocked.
local fs,luau,rb=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox")
local P=require("./meadow-v4/TunnelPolicy")
local V=rb.Vector3
local origin=V.new(0,76,-360)
local now=0;local deferred={};local heartbeat;local removing
local ws=rb.Instance.new("Workspace")
local map=rb.Instance.new("Model");map.Parent=ws
local attributes={}
local root={Position=origin+V.new(-76,3,-20),AssemblyLinearVelocity=V.zero}
local hum={Health=100,WalkSpeed=13.5,Parent=true}
local character={}
function character:FindFirstChild(name) return name=="HumanoidRootPart" and root or nil end
function character:FindFirstChildOfClass() return hum end
local player={Parent=true,Character=character}
function player:SetAttribute(k,v) attributes[k]=v end
function player:GetAttribute(k) return attributes[k] end
local carrier=player;local intercepts=0;local cleanups=0;local drops={}
local services={
    Players={GetPlayers=function() return {player} end,
        PlayerRemoving={Connect=function(_,fn) removing=fn;return {Disconnect=function() removing=nil end} end}},
    RunService={Heartbeat={Connect=function(_,fn) heartbeat=fn;return {Disconnect=function() heartbeat=nil end} end}},
    TweenService={Create=function() return {Play=function() end} end},
    Debris={AddItem=function() end}
}
local Controller=luau.load(fs.readFile("prototype/meadow-v4/ProductionTunnelController.luau"),{environment={
    game={GetService=function(_,name) return services[name] end},
    script={Parent={WaitForChild=function() return "Policy" end}},require=function() return P end,
    workspace=ws,Instance=rb.Instance,Vector3=V,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,TweenInfo={new=function() return {} end},
    Random={new=function() return {NextNumber=function() return .3 end} end},
    os={clock=function() return now end},
    task={delay=function(seconds,fn) table.insert(deferred,{time=now+seconds,fn=fn}) end}
}})()
local connection=Controller.attach({map=map,origin=origin,managedSpeed=true,
    getCarrier=function() return carrier end,
    drop=function(position,reason) table.insert(drops,{position=position,reason=reason});carrier=nil end,
    intercept=function(exit,path,seconds,entrant,epoch)
        intercepts+=1
        assert(exit==1 and #path==7 and seconds==3 and entrant==player and epoch==now,"captured external Keeper hook")
        return function() cleanups+=1 end
    end
})
local function step(time)
    now=time
    if heartbeat then heartbeat() end
    local repeatWork=true
    while repeatWork do
        repeatWork=false
        for i,item in deferred do if item.time<=now then table.remove(deferred,i);item.fn();repeatWork=true;break end end
    end
end
step(0)
assert(attributes.TunnelInside and attributes.TunnelKeeperThrowsSuppressed and intercepts==1,"origin-aware entry")
carrier=nil;step(.1);carrier=player;step(.2)
assert(intercepts==1,"same visit re-pickup must retain guard")
root.Position=origin+V.new(-76,3,0);hum.WalkSpeed=8;step(.3)
assert(hum.WalkSpeed==8,"production mud speed owner is server")
step(1.6)
local effects=map:FindFirstChild("TunnelTransientEffects")
local shadow=assert(effects:FindFirstChild("TunnelRedShadow"))
assert((shadow.Position-(origin+V.new(-76,.22,0))).Magnitude<.0001,"world-origin hazard shadow")
step(2.3);step(2.65)
assert(#drops==1 and math.abs(drops[1].position.Y-(origin.Y+2.8))<.0001,"same carrier forced floor drop")
step(8.01)
assert(attributes.TunnelRumbling,"former thief retains rumble age")
root.Position=origin+V.new(-100,3,40);step(8.1)
assert(not attributes.TunnelInside and not attributes.TunnelKeeperThrowsSuppressed,"exit suppression cleanup")
root.Position=origin+V.new(-76,3,0);step(9)
assert(attributes.TunnelRumbling,"rapid doorway does not reset rumble")
root.Position=origin+V.new(-100,3,40);step(9.1)
root.Position=origin+V.new(-76,3,0);carrier=player;step(13)
assert(intercepts==2 and cleanups==1 and not attributes.TunnelRumbling,"full visit resets occupancy and intercept")
local dropsBeforeDetach=#drops
connection.disconnect()
assert(not heartbeat and not removing and cleanups==2 and not map:FindFirstChild("TunnelTransientEffects"),"detach callbacks/effects/Keeper cleanup")
step(20)
assert(#drops==dropsBeforeDetach,"detach cancels delayed hazard impacts")
print("PASS production tunnel: retained origin, shared drop, warning/impact callbacks, mud ownership, former-thief rumble, grace/dedupe/full visit, detach")
