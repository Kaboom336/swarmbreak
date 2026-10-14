-- Isolated prototype system. Production Keeper merge uses documented adapter in TUNNEL.md.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local Policy=require(script.Parent:WaitForChild('TunnelPolicy'))
local Controller={}
function Controller.attach(adapter)
 assert(adapter.getCarrier and adapter.drop,'Tunnel requires existing treasure ownership/drop adapter')
 local map=workspace:WaitForChild('MeadowV4')
 local effects=Instance.new('Folder');effects.Name='TunnelTransientEffects';effects.Parent=workspace
 local keeper=Instance.new('Model');keeper.Name='TunnelPrototypeKeeper';keeper.Parent=map
 for _,p in map:GetChildren() do
  if p:IsA('BasePart') and p.Name:match('^Keeper') then p.Parent=keeper end
 end
 keeper.PrimaryPart=keeper:FindFirstChild('KeeperCoat')
 local home=keeper:GetPivot();local states={};local random=Random.new(1013)
 local generation=0;local active=true;local activeExit=nil;local pursuedEntrant=nil;local pursuedEpoch=nil;local externalCleanup=nil;local waiting=false;local guardUntil=0
 local function restore(player,state)
  local hum=state.hum
  if state.originalSpeed and hum and hum.Parent then hum.WalkSpeed=state.originalSpeed end
  state.originalSpeed=nil;state.hum=nil
  if player.Parent then player:SetAttribute('TunnelInside',false);player:SetAttribute('TunnelRumbling',false) end
 end
 local function intercept(exitId,entrant,epoch)
  -- Dropping/re-picking cannot cancel this player's already-running/waiting intercept.
  if not Policy.shouldIntercept(pursuedEntrant,activeExit,pursuedEpoch,entrant,exitId,epoch) then return end
  pursuedEntrant=entrant;activeExit=exitId;pursuedEpoch=epoch
  if externalCleanup then externalCleanup();externalCleanup=nil end
  if adapter.intercept then externalCleanup=adapter.intercept(exitId,Policy.path(exitId),Policy.Tuning.ExitHoldSeconds,entrant,epoch);return end
  if not keeper.PrimaryPart then return end
  generation+=1;local token=generation;activeExit=exitId;waiting=false
  task.spawn(function()
   local function travel(position,seconds,leap)
    local start=keeper:GetPivot();local elapsed=0
    while elapsed<seconds do
     elapsed+=RunService.Heartbeat:Wait()
     if token~=generation then return false end
     local t=math.min(elapsed/seconds,1);local p=start.Position:Lerp(position,t)
     if leap then p+=Vector3.new(0,math.sin(t*math.pi)*18,0) end
     keeper:PivotTo(CFrame.new(p)*start.Rotation)
    end
    return true
   end
   -- Visible long leap to the route entrance, then running along retained surface west lane.
   local path=Policy.path(exitId)
   for i,p in path do
    local target=Vector3.new(p.x,p.y+3,p.z)
    local seconds=if i==1 then 0.8 else (keeper:GetPivot().Position-target).Magnitude/Policy.Tuning.KeeperSurfaceSpeed
    if not travel(target,math.max(seconds,0.05),i==1) then return end
   end
   waiting=true;guardUntil=os.clock()+Policy.Tuning.ExitWaitTimeout
   workspace:SetAttribute('TunnelGuardWaiting',true)
   local waitedForExit=false
   while token==generation and os.clock()<guardUntil do
    task.wait(.1)
    if not waitedForExit and (not entrant.Parent or entrant:GetAttribute('TunnelInside')~=true) then
     waitedForExit=true;guardUntil=math.min(guardUntil,os.clock()+Policy.Tuning.ExitHoldSeconds)
    end
   end
   if token~=generation then return end
   waiting=false;activeExit=nil;pursuedEntrant=nil;workspace:SetAttribute('TunnelGuardWaiting',false)
   for i=#path-1,1,-1 do
    local p=path[i];local target=Vector3.new(p.x,p.y+3,p.z)
    if not travel(target,math.max((keeper:GetPivot().Position-target).Magnitude/32,.05),false) then return end
   end
   travel(home.Position,.8,true)
  end)
 end
 local function hazard(player,root)
  local originalCharacter=player.Character
  local velocity=root.AssemblyLinearVelocity
  local x,z=Policy.hazardTarget(root.Position.X,root.Position.Z,velocity.X,velocity.Z)
  local target=Vector3.new(x,.22,z)
  local shadow=Instance.new('Part');shadow.Name='TunnelRedShadow';shadow.Size=Vector3.new(6,.06,6)
  shadow.Anchored=true;shadow.CanCollide=false;shadow.CanTouch=false;shadow.CanQuery=false
  shadow.Color=Color3.fromRGB(250,48,44);shadow.Material=Enum.Material.Neon;shadow.Transparency=.18
  shadow.Position=target;shadow.Parent=effects;Debris:AddItem(shadow,2)
  task.delay(Policy.Tuning.ShadowSeconds,function()
   if not active or not shadow.Parent then return end
   local rock=Instance.new('WedgePart');rock.Name='TunnelFallingStalactite';rock.Size=Vector3.new(2.7,4,2.7)
   rock.Anchored=true;rock.CanCollide=false;rock.CanTouch=false;rock.CanQuery=false
   rock.Color=Color3.fromRGB(100,106,127);rock.Material=Enum.Material.Slate
   rock.CFrame=CFrame.new(target+Vector3.new(0,23,0))*CFrame.Angles(math.pi,0,0);rock.Parent=effects;Debris:AddItem(rock,.8)
   TweenService:Create(rock,TweenInfo.new(Policy.Tuning.FallSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=target+Vector3.new(0,2,0)}):Play()
   task.delay(Policy.Tuning.FallSeconds,function()
    if not active then return end
    shadow:Destroy()
    local character=player.Character;local currentRoot=character and character:FindFirstChild('HumanoidRootPart')
    local hum=character and character:FindFirstChildOfClass('Humanoid')
    if character~=originalCharacter or currentRoot~=root or not hum or hum.Health<=0 then return end
    local p=currentRoot.Position
    if Policy.inside(p.X,p.Y,p.Z) and Vector2.new(p.X-target.X,p.Z-target.Z).Magnitude<=Policy.Tuning.ImpactRadius then
     if adapter.getCarrier()==player then adapter.drop(Vector3.new(p.X,2.8,p.Z),'tunnel stalactite') end
     currentRoot.AssemblyLinearVelocity=Vector3.new(Policy.Tuning.KnockVelocity,8,0)
    end
   end)
  end)
 end
 local connection=RunService.Heartbeat:Connect(function()
  local now=os.clock();local carrier=adapter.getCarrier()
  for _,player in Players:GetPlayers() do
   local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
   local hum=character and character:FindFirstChildOfClass('Humanoid')
   local s=states[player]
   local inside=root and hum and hum.Health>0 and Policy.inside(root.Position.X,root.Position.Y,root.Position.Z)
   if inside then
    if not s then s={entered=now,nextHazard=now+Policy.Tuning.FirstHazardSeconds};states[player]=s end
    if s.hum and s.hum~=hum then restore(player,s) end
    if not s.inside then
     if s.left and now-s.left>Policy.Tuning.ReentryGrace then s.entered=now;s.prediction=nil;s.rumbleStarted=nil;s.wasCarrier=nil;s.nextHazard=now+Policy.Tuning.FirstHazardSeconds end
     s.inside=true
    end
    player:SetAttribute('TunnelInside',true)
    local age=now-s.entered;player:SetAttribute('TunnelRumbling',age>=Policy.Tuning.RumbleAfter)
    if Policy.inMud(root.Position.X,root.Position.Y,root.Position.Z) then
     if not s.originalSpeed then s.originalSpeed=hum.WalkSpeed;s.hum=hum end
     hum.WalkSpeed=math.min(s.originalSpeed,Policy.Tuning.MudSpeed)
    elseif s.originalSpeed then hum.WalkSpeed=s.originalSpeed;s.originalSpeed=nil;s.hum=nil end
    if carrier==player then
     s.wasCarrier=true
     player:SetAttribute('TunnelKeeperThrowsSuppressed',true)
     if not s.carrying then
      s.carrying=true
      if not s.prediction then s.prediction=Policy.predict(root.Position.X,root.Position.Z,random:NextNumber()) end
      workspace:SetAttribute('TunnelGuardedExit',s.prediction);intercept(s.prediction,player,s.entered)
     end
    else s.carrying=false;player:SetAttribute('TunnelKeeperThrowsSuppressed',false) end
    -- Former thieves still face rumble after dropping, so dropping cannot create a hide spot.
    if carrier==player or (s.wasCarrier and age>=Policy.Tuning.RumbleAfter) then
     if age>=Policy.Tuning.RumbleAfter and not s.rumbleStarted then s.rumbleStarted=true;s.nextHazard=math.min(s.nextHazard,now+Policy.Tuning.RumbleInterval) end
     if now>=s.nextHazard then hazard(player,root);s.nextHazard=now+Policy.interval(age) end
    end
   elseif s then
    s.carrying=false
    if s.inside then s.inside=false;s.left=now end
    restore(player,s);player:SetAttribute('TunnelKeeperThrowsSuppressed',false)
    if not hum or hum.Health<=0 then states[player]=nil end
   end
  end
  if waiting and activeExit and now<guardUntil and carrier then
   local root=carrier.Character and carrier.Character:FindFirstChild('HumanoidRootPart');local e=Policy.Exits[activeExit]
   if root and Vector2.new(root.Position.X-e.x,root.Position.Z-e.z).Magnitude<Policy.Tuning.ExitGuardRadius and root.Position.Y<10 then
    adapter.drop(Vector3.new(root.Position.X,2.8,root.Position.Z),'tunnel guarded exit')
   end
  end
  workspace:SetAttribute('TunnelRumbleActive',carrier~=nil and carrier:GetAttribute('TunnelRumbling')==true)
 end)
 local removing=Players.PlayerRemoving:Connect(function(player) if states[player] then restore(player,states[player]);states[player]=nil end end)
 workspace:SetAttribute('TunnelRuntime','Prototype hazards/slow/rumble and surface stand-in intercept; production Keeper hook pending')
 return {disconnect=function()
  active=false;connection:Disconnect();removing:Disconnect()
  for p,s in states do restore(p,s);if p.Parent then p:SetAttribute('TunnelKeeperThrowsSuppressed',false) end end
  generation+=1;if externalCleanup then externalCleanup();externalCleanup=nil end
  effects:Destroy();keeper:PivotTo(home)
  for _,p in keeper:GetChildren() do p.Parent=map end
  keeper:Destroy();workspace:SetAttribute('TunnelGuardWaiting',false)
  workspace:SetAttribute('TunnelRumbleActive',false);workspace:SetAttribute('TunnelGuardedExit',nil)
 end}
end
return Controller
