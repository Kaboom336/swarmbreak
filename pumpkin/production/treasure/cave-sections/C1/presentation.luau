-- Only appearance of explicit nonphysical art. Never changes transforms, sizes,
-- tags, gameplay props, collision/query/touch, routes or the giant crystal.
return function(map, round)
 local report={round=round,panel=0,rock_faces=0,hidden_crystal_parts=0,quiet_crystal_parts=0}
 local hide,quiet=false,false
 for i,p in map:GetChildren()do
  if i%200==0 then
   task.wait()
  end
  if not p:IsA('BasePart')then continue end
  local pos=p.CFrame.Position
  if p.Name=='CrystalShaft'then
   local foreground=pos.X>=-125 and pos.X<=-40 and pos.Z>=15 and pos.Z<=100 and pos.Y>=0 and pos.Y<=45
   hide=foreground and p.Size.Y<9
   quiet=foreground and not hide and p.Size.Y<15
  elseif not p.Name:match('^Crystal')then
   hide,quiet=false,false
  end
  if p.CanCollide then continue end
  if p.Name=='MainGatewayFabric'or(round=='r4'and p.Name=='MainGatewayPennant')then
   p.Color=Color3.fromRGB(49,62,80)
   p.Material=Enum.Material.Slate
   report.panel+=1
  elseif p.Name:match('^Crystal')and hide then
   p.Transparency=1
   for _,l in p:GetChildren()do
    if l:IsA('Light')then
     l.Enabled=false
    end
   end
   report.hidden_crystal_parts+=1
  elseif p.Name:match('^Crystal')and quiet then
   -- Keep larger intact groups; reduce their visual competition with the crown.
   p.Color=round=='r4'and Color3.fromRGB(65,174,206)or Color3.fromRGB(56,102,132)
   p.Material=round=='r4'and Enum.Material.Neon or Enum.Material.SmoothPlastic
   for _,l in p:GetChildren()do
    if l:IsA('Light')then
     l.Enabled=false
    end
   end
   report.quiet_crystal_parts+=1
  elseif (p.Name=='R3CliffVoxelSkin'or p.Name=='CliffInsetBlock'or p.Name=='CliffSteppedLedge')and pos.X>=-195 and pos.X<=-85 and pos.Z>=30 and pos.Z<=145 then
   local band=math.floor(pos.Y/8)%3
   p.Color=Color3.fromRGB(50+band*8,65+band*8,85+band*9)
   p.Material=Enum.Material.Slate
   report.rock_faces+=1
  end
 end
 return report
end
