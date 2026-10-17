-- Observe original preview attributes; write only new C5 artwork.
return function(map,root,round)
 if root:GetAttribute('C5FXBound')then return end
 local hook=map:FindFirstChild('ShatterCavernHook');if not hook then return end
 root:SetAttribute('C5FXBound',true)
 for i=1,3 do
  task.wait()
  local crystal=root:FindFirstChild('C5_Crystal3Shaft'..i)
  if not crystal then continue end
  local base=crystal.Color
  local em=Instance.new('ParticleEmitter');em.Name='C5Shards'
  em.Enabled=false;em.Rate=0;em.Lifetime=NumberRange.new(.25,.45)
  em.Speed=NumberRange.new(3,7);em.SpreadAngle=Vector2.new(45,45)
  em.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,0)})
  em.Color=ColorSequence.new(base);em.LightEmission=.35;em.Parent=crystal
  local last=false
  local function sync()
   local crack=hook:GetAttribute('Cluster'..i..'Cracking')==true
   local burst=hook:GetAttribute('Cluster'..i..'Burst')==true
   crystal.Color=crack and Color3.fromRGB(225,221,255)or base
   if burst and not last then em:Emit(12)end
   last=burst
  end
  hook:GetAttributeChangedSignal('Cluster'..i..'Cracking'):Connect(sync)
  hook:GetAttributeChangedSignal('Cluster'..i..'Burst'):Connect(sync)
  sync()
 end
end
