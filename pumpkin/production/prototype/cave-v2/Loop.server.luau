-- Greybox steal / carry / escape slice. Shared economy domain is referenced,
-- saving deliberately stays absent from this separate prototype place.
local core=game.ReplicatedStorage.TreasureCore
local Domain,Config=require(core.Domain),require(core.Config)
local map=workspace.CaveV2
local states={};local carrier=nil;local cargo=nil;local started=0
local steal=Instance.new('ProximityPrompt');steal.ActionText='Steal geode';steal.HoldDuration=2;steal.MaxActivationDistance=10;steal.Parent=map.Geode
steal.Triggered:Connect(function(player)
 if carrier then return end
 carrier=player;started=os.clock();cargo={id=game.HttpService:GenerateGUID(false),tier=Domain.roll(Config,math.random())};player:SetAttribute('CaveItemID',cargo.id);steal.Enabled=false
end)
game.Players.PlayerAdded:Connect(function(player) states[player]=Domain.default();player:SetAttribute('CavePrototype','Volatile; no saving');end)
local function resetCargo()
 if carrier then carrier:SetAttribute('CaveItemID',nil) end
 carrier=nil;cargo=nil;steal.Enabled=true;map.Geode.CFrame=CFrame.new(160,51,-120)
end
game.Players.PlayerRemoving:Connect(function(player) states[player]=nil;if carrier==player then resetCargo() end end)
game:GetService('RunService').Heartbeat:Connect(function()
 if not carrier then return end
 local root=carrier.Character and carrier.Character:FindFirstChild('HumanoidRootPart')
 local humanoid=carrier.Character and carrier.Character:FindFirstChildOfClass('Humanoid')
 if not root or not humanoid or humanoid.Health<=0 then resetCargo();return end
 if root then
  carrier:SetAttribute('CaveSecondsLeft',math.max(0,60-(os.clock()-started)))
  map.Geode.CFrame=root.CFrame*CFrame.new(0,1,3)
  if math.abs(root.Position.X+150)<24 and math.abs(root.Position.Z-120)<20 and root.Position.Y<15 then
   local profile=states[carrier] or Domain.default();local ok,why=Domain.secure(profile,Config,cargo.id,cargo.tier,{shieldUsed=false,firstHitUsed=false})
   if ok then states[carrier]=profile;carrier:SetAttribute('CaveSecured',cargo.id);resetCargo() else carrier:SetAttribute('CaveSecureRefusal',why) end
  end
 end
 if carrier and os.clock()-started>=60 then resetCargo() end
end)
-- Core prototype progression uses the existing pure domain operations. Clear
-- secured pending cargo via place/open before another steal can be rewarded.
local open=Instance.new('ProximityPrompt');open.ActionText='Place / open secured geode (prototype)';open.HoldDuration=.6;open.Parent=map.PortalBeacon
open.Triggered:Connect(function(player)
 local profile=states[player];local pending=profile and profile.pending
 if pending then
  if not pending.placed then Domain.place(profile,pending.id,0,0,0) end
  local ok,why=Domain.open(profile,Config,pending.id);player:SetAttribute('CaveOpenResult',ok and 'Opened' or why)
 end
end)
-- Other feature hooks expose faithful timed, non-damaging telegraphs. Guardian
-- locomotion, blast force, mercy and pickup priority require a future combat pass.
for _,entry in {{'TNTHook',{1},15},{'DynamiteGuardianHook',{1.5,1},7},{'ShatterCavernHook',{1,.8,.8},20}} do
 local hook=map[entry[1]];local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Preview '..entry[1];prompt.HoldDuration=.4;prompt.Parent=hook
 prompt.Triggered:Connect(function()
  if not prompt.Enabled then return end;prompt.Enabled=false
  if entry[1]=='ShatterCavernHook' then
   -- Each cluster receives its own >=1s tell and bursts at 1/1.8/2.6s.
   for index=1,3 do task.delay((index-1)*.8,function()
    hook:SetAttribute('Cluster'..index..'Cracking',true);hook.Color=Color3.fromRGB(255,255,255);task.wait(1);hook:SetAttribute('Cluster'..index..'Cracking',false);hook:SetAttribute('Cluster'..index..'Burst',true);hook.Color=Color3.fromRGB(170,80,255);task.wait(.15);hook:SetAttribute('Cluster'..index..'Burst',false)
   end) end
   task.wait(2.75+entry[3]);hook.Color=Color3.fromRGB(226,123,58);prompt.Enabled=true;return
  end
  for stage,seconds in entry[2] do hook:SetAttribute('TelegraphStage',stage);hook.Color=Color3.fromRGB(255,210,110);task.wait(seconds) end
  hook:SetAttribute('TelegraphStage',0);hook:SetAttribute('PayoffPreview',true);hook.Color=Color3.fromRGB(170,80,255);task.wait(.3);hook:SetAttribute('PayoffPreview',false);task.wait(entry[3]);hook.Color=Color3.fromRGB(226,123,58);prompt.Enabled=true
 end)
end
