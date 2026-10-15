-- Server-driven deterministic cart path. This prototype has no ram or blast damage.
local RunService=game:GetService('RunService')
local data=require(game.ReplicatedStorage.CaveRouteData)
local map=workspace.CaveV2
local function vec(a) return Vector3.new(a[1],a[3],-a[2]) end
local points=data.routes.cartRail
local function at(distance)
 local remaining=distance
 for i=1,#points-1 do local a,b=vec(points[i]),vec(points[i+1]);local length=(b-a).Magnitude
  if remaining<=length then local p=a:Lerp(b,math.clamp(remaining/length,0,1));return p,(b-a).Unit end
  remaining-=length
 end
 return vec(points[#points]),(vec(points[#points])-vec(points[#points-1])).Unit
end
local broken=false;local busy=0;local lastBreak=-100
local span=map.BreakableSpan
local hook=map.SupportBlastHook
local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Blast support (1s fuse + 2s cracks)';prompt.HoldDuration=.4;prompt.MaxActivationDistance=14;prompt.Parent=hook
local ready=map.JumpReady:FindFirstChildOfClass('SurfaceGui'):FindFirstChildOfClass('TextLabel')
local function occupiedRepairVolume()
 if busy>0 then return true end
 for _,player in game.Players:GetPlayers() do local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');if root and (root.Position-Vector3.new(0,4,25)).Magnitude<52 then return true end end
 return false
end
prompt.Triggered:Connect(function()
 if busy>0 or os.clock()-lastBreak<20 or hook:GetAttribute('Armed') then return end
 hook:SetAttribute('Armed',true);prompt.Enabled=false;ready.Text='1s FUSE';task.wait(1);ready.Text='2s CRACKS';task.wait(2)
 -- Do not change the gap beneath any cart in the reserved approach/flight envelope.
 if busy>0 then ready.Text='WAIT: CART COMMITTED';repeat task.wait(.1) until busy==0 end
 broken=true;lastBreak=os.clock();span.CanCollide=false;span.Transparency=1;map.SpanBearingBeam.CanCollide=false;map.SpanBearingBeam.Transparency=1;hook:SetAttribute('Armed',false);ready.Text='JUMP READY / 24';task.wait(20)
 repeat task.wait(.2) until not occupiedRepairVolume()
 broken=false;span.CanCollide=true;span.Transparency=0;map.SpanBearingBeam.CanCollide=true;map.SpanBearingBeam.Transparency=0;prompt.Enabled=true;ready.Text='JUMP READY'
end)
local function buildCart(index)
 local model=Instance.new('Model');model.Name='RideableCart'..index;model.Parent=map
 local function p(name,size,offset,color,class)
  local part=Instance.new(class or 'Part');part.Name=name;part.Size=size;part.Anchored=true;part.CanCollide=false;part.Color=color;part.CFrame=CFrame.new(vec(points[1])+offset);part.Parent=model;return part
 end
 local base=p('OreCart',Vector3.new(8,1,10),Vector3.new(0,2,0),Color3.fromRGB(71,79,92));model.PrimaryPart=base
 local seats={p('DriverSeat',Vector3.new(3,1,3),Vector3.new(-2,3,0),Color3.fromRGB(103,72,44),'Seat'),p('PassengerSeat',Vector3.new(3,1,3),Vector3.new(2,3,0),Color3.fromRGB(103,72,44),'Seat')}
 local gauge=Instance.new('BillboardGui');gauge.Size=UDim2.fromOffset(230,60);gauge.StudsOffset=Vector3.new(0,6,0);gauge.AlwaysOnTop=true;gauge.Parent=base
 local gaugeText=Instance.new('TextLabel');gaugeText.Size=UDim2.fromScale(1,1);gaugeText.BackgroundColor3=Color3.fromRGB(28,32,46);gaugeText.TextScaled=true;gaugeText.TextColor3=Color3.new(1,1,1);gaugeText.Parent=gauge
 for side=-1,1,2 do p('CartSide',Vector3.new(.7,3,10),Vector3.new(side*4,3,0),Color3.fromRGB(85,96,109));for z=-3,3,6 do local w=p('Wheel',Vector3.new(1.2,2,2),Vector3.new(side*4,1,z),Color3.fromRGB(39,42,53));w.Shape=Enum.PartType.Cylinder end end
 local board=Instance.new('ProximityPrompt');board.ActionText='Ride cart';board.HoldDuration=.3;board.MaxActivationDistance=12;board.Parent=base
 board.Triggered:Connect(function(player) local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if humanoid then for _,seat in seats do if not seat.Occupant then seat:Sit(humanoid);break end end end end)
 local speed=24;local brake=Instance.new('ProximityPrompt');brake.ActionText='Toggle speed 24 / 12 (red = pit if committed)';brake.MaxActivationDistance=9;brake.Parent=seats[1]
 local distance,state,elapsed,waitTime,committed,flightSpeed=0,'Dock',0,0,false,24
 local diverted=false
 local override=Instance.new('ProximityPrompt');override.ActionText='Override amber switch';override.MaxActivationDistance=9;override.Parent=seats[1]
 override.Triggered:Connect(function(player) if seats[1].Occupant and seats[1].Occupant.Parent==player.Character and not diverted then map.RailSwitchHook:SetAttribute('DivertNext',false);map.RailSwitchHook:SetAttribute('Warning',false) end end)
 local function bypassPosition(d)
  local pos=at(d);local nearest,best=nil,math.huge
  local pts=data.routes.railWalkBypass
  for i=1,#pts-1 do local a,b=vec(pts[i]),vec(pts[i+1]);local t=math.clamp((pos-a):Dot(b-a)/(b-a):Dot(b-a),0,1);local q=a:Lerp(b,t);local l=(q-pos).Magnitude;if l<best then nearest,best=q,l end end
  return nearest+Vector3.new(0,4,0)
 end
 brake.Triggered:Connect(function(player) if not committed and seats[1].Occupant and seats[1].Occupant.Parent==player.Character then speed=speed==24 and 12 or 24;ready.Text=speed>=24 and 'JUMP READY / 24' or 'RED: STOP / BAIL / 12' end end)
 local bail=Instance.new('ProximityPrompt');bail.ActionText='Emergency dismount to bypass';bail.MaxActivationDistance=9;bail.Parent=seats[2]
 local function exitHumanoid(h,pos) if h then h.Sit=false;local root=h.Parent:FindFirstChild('HumanoidRootPart');if root then task.defer(function() root.CFrame=CFrame.new(pos) end) end end end
 bail.Triggered:Connect(function(player)
  for _,seat in seats do if seat.Occupant and seat.Occupant.Parent==player.Character then if state=='Flight' or state=='Fall' then player:SetAttribute('CaveDismountDeferred',true) else exitHumanoid(seat.Occupant,bypassPosition(distance)) end end end
 end)
 local function reserve(on) if on and not committed then busy+=1;committed=true elseif not on and committed then busy-=1;committed=false end end
 -- Defer ordinary seat jumping as well as the explicit emergency-dismount
 -- prompt during a committed flight. Studio must verify replication behavior.
 for _,seat in seats do local previous=nil;seat:GetPropertyChangedSignal('Occupant'):Connect(function()
  local current=seat.Occupant
  if previous and not current and (state=='Flight' or state=='Fall' or state=='Landing') then local deferred=previous;task.defer(function() if deferred.Parent then seat:Sit(deferred) end end) end
  previous=current
 end) end
 local function pivot(pos,dir) model:PivotTo(CFrame.lookAt(pos+Vector3.new(0,2,0),pos+Vector3.new(0,2,0)+dir)) end
 RunService.Heartbeat:Connect(function(dt)
  dt=math.min(dt,.1);model:SetAttribute('State',state);model:SetAttribute('Speed',speed);model:SetAttribute('TrackDistance',distance);gaugeText.Text=string.format('CART %d | %d | %s',index,speed,(committed and flightSpeed or speed)>=24 and 'JUMP READY' or 'RED / BAIL');gaugeText.TextColor3=(committed and flightSpeed or speed)>=24 and Color3.fromRGB(128,255,150) or Color3.fromRGB(255,121,111)
  if state=='Dock' then
   if seats[1].Occupant or seats[2].Occupant then waitTime+=dt;if waitTime>=2+(index-1)*1 then state='Track';board.Enabled=false;waitTime=0 end end
  elseif state=='Track' then
   local nextDistance=distance+speed*dt
   if distance<data.gapStart-22 and nextDistance>=data.gapStart-22 then
    if hook:GetAttribute('Armed') then return end
    reserve(true);flightSpeed=speed
   end
   if broken and nextDistance>=data.gapStart and distance<data.gapStart then state=flightSpeed>=24 and 'Flight' or 'Fall';elapsed=0;distance=data.gapStart
   else distance=nextDistance
    local position,dir=at(distance);pivot(position,dir)
    if distance>data.gapEnd+24 then reserve(false) end
    if distance>=data.length then state='End';elapsed=0 end
    if distance>data.gapEnd+65 and map.RailSwitchHook:GetAttribute('DivertNext') and not diverted then diverted=true;map.RailSwitchHook:SetAttribute('DivertNext',false);state='Siding';elapsed=0 end
   end
  elseif state=='Flight' then
   elapsed+=dt;local t=math.clamp(elapsed/(16/flightSpeed),0,1);local a,dir=at(data.gapStart);local b=at(data.gapEnd);pivot(a:Lerp(b,t)+Vector3.new(0,12*4*t*(1-t),0),dir)
   if t>=1 then distance=data.gapEnd+.05;state='Landing';elapsed=0 end
  elseif state=='Landing' then
   distance+=flightSpeed*dt;local pos,dir=at(distance);pivot(pos,dir);elapsed+=dt
   if elapsed>=1 then reserve(false);state='Track';for _,s in seats do local h=s.Occupant;local pl=h and game.Players:GetPlayerFromCharacter(h.Parent);if pl and pl:GetAttribute('CaveDismountDeferred') then pl:SetAttribute('CaveDismountDeferred',false);exitHumanoid(h,bypassPosition(distance)) end end end
  elseif state=='Fall' then
   elapsed+=dt;local t=math.clamp(elapsed/1.2,0,1);local a,dir=at(data.gapStart);local pit=Vector3.new(0,-14,25);pivot(a:Lerp(pit,t),dir)
   if t>=1 then for _,s in seats do exitHumanoid(s.Occupant,pit+Vector3.new(0,4,0)) end;reserve(false);state='End';elapsed=0 end
  elseif state=='Siding' then
   elapsed+=dt;local pos,dir=at(distance);pivot(pos:Lerp(Vector3.new(-94,8,50),math.min(elapsed/3.5,1)),dir);if elapsed>=3.5 then for _,s in seats do exitHumanoid(s.Occupant,Vector3.new(-94,12,50)) end;state='End';elapsed=0 end
  elseif state=='End' then
   elapsed+=dt;if elapsed>.5 then for _,s in seats do exitHumanoid(s.Occupant,bypassPosition(distance)) end end
   if elapsed>4 then reserve(false);distance=0;state='Dock';diverted=false;speed=24;board.Enabled=true;local pos,dir=at(0);pivot(pos+Vector3.new(index==2 and 12 or 0,0,0),dir) end
  end
 end)
 local pos,dir=at(0);pivot(pos+Vector3.new(index==2 and 12 or 0,0,0),dir)
end
for i=1,2 do buildCart(i) end
-- Switch hook demonstrates its complete 2s warning, 12s lock and harmless siding.
local switch=map.RailSwitchHook;local sw=Instance.new('ProximityPrompt');sw.ActionText='Switch next cart';sw.HoldDuration=.4;sw.Parent=switch
sw.Triggered:Connect(function() if switch:GetAttribute('DivertNext') or not sw.Enabled then return end;sw.Enabled=false;switch:SetAttribute('Warning',true);switch.Color=Color3.fromRGB(255,190,34);task.wait(2);local active=switch:GetAttribute('Warning');switch:SetAttribute('Warning',false);switch:SetAttribute('DivertNext',active);task.wait(12);switch.Color=Color3.fromRGB(226,123,58);sw.Enabled=true end)
