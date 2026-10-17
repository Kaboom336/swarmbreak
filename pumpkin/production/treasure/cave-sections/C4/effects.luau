-- Presentation only: reads existing status/Transparency; never calls blast or
-- writes a gameplay property. No polling, physics, Explosion or extra lights.
return function(map,root,round)
 if root:GetAttribute('PresentationComplete')then return end
 local function mirror(board)
  local original=board:FindFirstChildWhichIsA('SurfaceGui')
  local source=original and original:FindFirstChildWhichIsA('TextLabel')
  if not source then return end
  local gui=original:Clone();gui.Name='C4ReadableReverse'
  gui.Face=original.Face==Enum.NormalId.Front and Enum.NormalId.Back or Enum.NormalId.Front
  local label=gui:FindFirstChildWhichIsA('TextLabel')
  label.Text=source.Text
  source:GetPropertyChangedSignal('Text'):Connect(function()label.Text=source.Text end)
  gui.Parent=board
 end
 for _,name in {'BailSign','JumpReady','RecoverySign'}do
  task.wait();local board=map:FindFirstChild(name);if board then mirror(board)end
 end
 local span=map:WaitForChild('BreakableSpan')
 local hook=map:WaitForChild('SupportBlastHook')
 if round=='r3'or round=='r4'then
  local focus={{hook,'SUPPORT BREAK'},{map.BroadLanding,'LAND HERE'}}
  if round=='r4'and map:FindFirstChild('pitRecovery4')then table.insert(focus,{map.pitRecovery4,'CLIMB OUT'})end
  for _,v in focus do
   local gui=Instance.new('BillboardGui');gui.Name='C4Focus';gui.Size=UDim2.fromOffset(150,40)
   gui.StudsOffset=Vector3.new(0,6,0);gui.MaxDistance=90;gui.AlwaysOnTop=false
   if round=='r4'then
    gui.Size=UDim2.fromOffset(180,44)
    if v[1]==hook then gui.StudsOffset=Vector3.new(-8,6,0)end
   end
   local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
   label.Text=v[2];label.TextScaled=true;label.FontFace=Font.new('rbxasset://fonts/families/FredokaOne.json')
   label.TextColor3=Color3.fromRGB(255,223,145);label.TextStrokeColor3=Color3.fromRGB(36,28,24);label.TextStrokeTransparency=0
   label.Parent=gui;gui.Parent=v[1]
  end
 end
 local attachment=Instance.new('Attachment');attachment.Name='C4CosmeticBurst';attachment.Parent=hook
 local dust=Instance.new('ParticleEmitter');dust.Name='Dust';dust.Texture='rbxasset://textures/particles/smoke_main.dds'
 dust.Enabled=false;dust.Rate=0;dust.Lifetime=NumberRange.new(.25,.6);dust.Speed=NumberRange.new(5,10)
 dust.SpreadAngle=Vector2.new(45,45);dust.Acceleration=Vector3.new(0,-8,0)
 dust.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.7),NumberSequenceKeypoint.new(1,2.4)})
 dust.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,1)})
 dust.Color=ColorSequence.new(Color3.fromRGB(139,120,101));dust.LightEmission=0;dust.Parent=attachment
 local chips=Instance.new('ParticleEmitter');chips.Name='Chips';chips.Texture='rbxasset://textures/particles/sparkles_main.dds'
 chips.Enabled=false;chips.Rate=0;chips.Lifetime=NumberRange.new(.18,.4);chips.Speed=NumberRange.new(9,15)
 chips.Size=NumberSequence.new(.22);chips.SpreadAngle=Vector2.new(65,65);chips.Acceleration=Vector3.new(0,-26,0)
 chips.Color=ColorSequence.new(Color3.fromRGB(223,157,73));chips.LightEmission=.25;chips.Parent=attachment
 local cracks={}
 for i,p in map:GetDescendants()do
  if i%120==0 then task.wait()end
  if p:IsA('BasePart')and p.Name=='ConnectSteelRail'and(p.Position-span.Position).Magnitude<14 then
   local gui=Instance.new('SurfaceGui');gui.Name='C4Cracks';gui.Face=Enum.NormalId.Top;gui.Enabled=false
   gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=40
   for j=1,3 do
    local line=Instance.new('Frame');line.Size=UDim2.fromScale(.9,.035);line.Position=UDim2.fromScale(.05,j*.2)
    line.Rotation=j%2==0 and 20 or -20;line.BorderSizePixel=0;line.BackgroundColor3=Color3.fromRGB(34,26,25);line.Parent=gui
   end
   gui.Parent=p;table.insert(cracks,gui)
  end
 end
 local status=map.JumpReady:FindFirstChildWhichIsA('SurfaceGui'):FindFirstChildWhichIsA('TextLabel')
 local function syncCracks()
  local enabled=status.Text=='2s CRACKS'or span.Transparency>.9
  for _,gui in cracks do gui.Enabled=enabled end
 end
 local wasOpen=span.Transparency>.9
 span:GetPropertyChangedSignal('Transparency'):Connect(function()
  local open=span.Transparency>.9
  if open and not wasOpen then dust:Emit(12);chips:Emit(8)end
  wasOpen=open;syncCracks()
 end)
 status:GetPropertyChangedSignal('Text'):Connect(syncCracks)
 syncCracks();root:SetAttribute('PresentationComplete',true)
end
