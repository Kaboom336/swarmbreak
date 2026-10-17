-- Adds only new GUIs to unchanged, existing approach fence posts.
return function(map,_root,round)
 local specs={
  {name='C7FootExit',text='FOOT EXIT',at=Vector3.new(-144,1.7250061,93.3333435)},
  {name='C7CaveExit',text='CAVE EXIT',at=Vector3.new(-89.7587891,1.7250061,107.5570221)},
 }
 for _,s in specs do
  task.wait()
  local post
  for i,p in map:GetDescendants()do
   if p:IsA('BasePart')and p.Name=='ConnectFencePost'and(p.CFrame.Position-s.at).Magnitude<.01 then post=p;break end
   if i%200==0 then task.wait()end
  end
  if not post or post:FindFirstChild(s.name)then continue end
  local gui=Instance.new('BillboardGui');gui.Name=s.name;gui.Adornee=post
  gui.Size=UDim2.fromOffset(round=='r4'and 104 or 112,28)
  gui.StudsOffsetWorldSpace=Vector3.new(0,round=='r4'and 2.5 or 4,0)
  gui.AlwaysOnTop=false;gui.MaxDistance=round=='r4'and(s.name=='C7FootExit'and 32 or 45)or 70;gui.LightInfluence=0
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1)
  label.BackgroundColor3=Color3.fromRGB(55,42,34);label.BackgroundTransparency=.12
  label.Text=s.text;label.TextScaled=true
  label.FontFace=Font.new('rbxasset://fonts/families/FredokaOne.json')
  label.TextColor3=Color3.fromRGB(255,236,180);label.TextStrokeTransparency=.5
  label.Parent=gui;gui.Parent=post
 end
end
