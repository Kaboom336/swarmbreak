-- Local reversible travel stubs only; no currency, ownership, combat or Keeper code.
local Players = game:GetService("Players")
local releaseAcornForTravel: ((Player)->())? = nil
local function marker(name, position, size, color)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position = name, size, position
    p.Color, p.Anchored, p.CanCollide, p.Parent = color, true, false, workspace
    p.Material = Enum.Material.Neon
    return p
end
local home = Instance.new("Part")
home.Name, home.Size, home.Position = "HomeLinkStubIsland", Vector3.new(48,8,48), Vector3.new(0,-4,246)
home.Anchored, home.Material, home.Color, home.Parent = true, Enum.Material.Grass, Color3.fromRGB(106,162,56), workspace
local entry = marker("HomeToMeadowStub",Vector3.new(0,4,232),Vector3.new(12,8,1),Color3.fromRGB(20,232,255))
local back = marker("MeadowToHomeStub",Vector3.new(0,5,144),Vector3.new(12,10,1),Color3.fromRGB(20,232,255))
local function link(part, text, target)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText, prompt.HoldDuration = text, "TEST LINK / no treasure scoring", 0
    prompt.RequiresLineOfSight, prompt.MaxActivationDistance, prompt.Parent = false, 14, part
    prompt.Triggered:Connect(function(player)
        if releaseAcornForTravel then releaseAcornForTravel(player) end
        if player.Character then player.Character:PivotTo(CFrame.new(target)) end
    end)
end
link(entry,"Enter Meadow v4",Vector3.new(0,4,130))
link(back,"Return Home stub",Vector3.new(0,4,246))
-- Physical stand-in and acorn are authored geometry. Deliberately no NPC controller.
workspace:SetAttribute("MeadowVersion",4)
workspace:SetAttribute("StudioChecks","PENDING: timings, jumps, Keeper pathing and throw sweep")
-- Standalone acorn carry/fall behavior. Never reads guardian or Keeper systems.
local RunService = game:GetService("RunService")
local Policy = require(game:GetService("ReplicatedStorage"):WaitForChild("MeadowV4"):WaitForChild("RavinePolicy"))
local map = workspace:WaitForChild("MeadowV4")
local TunnelPolicy = require(game:GetService("ReplicatedStorage"):WaitForChild("MeadowV4"):WaitForChild("TunnelPolicy"))
local acorn = Instance.new("Model")
acorn.Name = "Round3TestAcorn"
local seed = map:WaitForChild("GoldenAcorn")
for _, name in {"GoldenAcorn","AcornCap","AcornStem"} do
    local part = map:FindFirstChild(name)
    assert(part and part:IsA("BasePart"), "Missing isolated treasure geometry")
    part.CanCollide, part.CanTouch, part.CanQuery = false,false,false
    part.Parent = acorn
end
acorn.PrimaryPart = seed
acorn.Parent = map
local pickup = Instance.new("ProximityPrompt")
pickup.Name, pickup.ActionText, pickup.ObjectText = "AcornPickup", "Carry acorn", "Prototype acorn"
pickup.RequiresLineOfSight, pickup.MaxActivationDistance, pickup.HoldDuration = false,10,0
pickup.Parent = seed
local carrier: Player? = nil
local lastSafe = seed.Position
local approachZ = -24
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {map}
params.RespectCanCollide = true
local function supportedPosition(x:number,z:number):Vector3
    -- Tunnel drop rays start below its roof, so manual/lifecycle drops remain rival-grabbable.
    local rayHeight=if TunnelPolicy.inside(x,3,z) then 10 else 70
    local hit=workspace:Raycast(Vector3.new(x,rayHeight,z),Vector3.new(0,-130,0),params)
    if not hit then return Vector3.new(0,51,-108) end -- lifecycle outside map returns to the summit nest
    return hit.Position + Vector3.new(0,2.8,0)
end
local function drop(position:Vector3, reason:string)
    if carrier then carrier:SetAttribute("Round3CarryingAcorn",false) end
    carrier=nil
    acorn:PivotTo(CFrame.new(position))
    acorn:SetAttribute("DropReason",reason)
    pickup.ActionText="Carry acorn"
end
releaseAcornForTravel=function(player)
    if player==carrier then drop(supportedPosition(lastSafe.X,lastSafe.Z),"test link") end
end
pickup.Triggered:Connect(function(player)
    if carrier==player then
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then drop(supportedPosition(root.Position.X,root.Position.Z),"manual") end
        return
    end
    if not Policy.canPickup(if carrier then carrier.UserId else nil,player.UserId) then return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local hum=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 or (root.Position-seed.Position).Magnitude>12 then return end
    carrier=player
    lastSafe=root.Position
    approachZ=root.Position.Z
    player:SetAttribute("Round3CarryingAcorn",true)
    pickup.ActionText="Drop acorn"
    acorn:SetAttribute("DropReason","carried")
end)
RunService.Heartbeat:Connect(function()
    if not carrier then return end
    local character=carrier.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local hum=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then
        drop(supportedPosition(lastSafe.X,lastSafe.Z),"character lost")
        return
    end
    local p=root.Position
    if Policy.isRavineFall(p.X,p.Y,p.Z,hum:GetState()==Enum.HumanoidStateType.Freefall) then
        local x,z=Policy.rim(p.X,p.Z,approachZ)
        drop(supportedPosition(x,z),"ravine rim")
        -- No teleport, damage, respawn or scoring. Walk the physical ramp out.
        return
    end
    if p.Y>=2 and workspace:Raycast(p,Vector3.new(0,-12,0),params) then
        lastSafe=p
        if math.abs(p.Z)>22 then approachZ=p.Z end
    end
    acorn:PivotTo(root.CFrame*CFrame.new(2,1,-1))
end)
Players.PlayerRemoving:Connect(function(player)
    if player==carrier then drop(supportedPosition(lastSafe.X,lastSafe.Z),"player left") end
end)
workspace:SetAttribute("Round3FallRule","Drop at reachable rim; physical long walkout; no fall damage")
-- Isolated tunnel prototype bridge. Guardian/Keeper code is untouched; merge hook: TUNNEL.md.
require(game:GetService("ReplicatedStorage"):WaitForChild("MeadowV4"):WaitForChild("TunnelController")).attach({
    getCarrier=function() return carrier end,
    drop=drop,
})
