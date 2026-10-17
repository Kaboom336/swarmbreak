-- Appearance only, complete ornamental groups only, full component bounds in C2.
-- Geode, guardian, carts, route labels, decks, colliders and all gameplay stay exact.
return function(map)
 local report={hidden_groups=0,quiet_groups=0,crystal_parts=0,rock_faces=0}
 local function inside(p)
  for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
   local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2)
   if v.X<100 or v.X>244 or v.Y<30 or v.Y>120 or v.Z< -170 or v.Z> -90 then return false end
  end end end
  return true
 end
 local groups,current={},nil
 for i,p in map:GetChildren()do
  if i%200==0 then task.wait()end
  if not p:IsA('BasePart')then continue end
  if p.Name=='CrystalShaft'then current={};table.insert(groups,current)
  elseif not p.Name:match('^Crystal')then current=nil end
  if current then table.insert(current,p)end
  if not p.CanCollide and inside(p)and (p.Name=='R3CliffVoxelSkin'or p.Name=='CliffInsetBlock'or p.Name=='CliffSteppedLedge')then
   local band=math.floor(p.CFrame.Y/8)%3
   p.Color=Color3.fromRGB(49+band*7,62+band*7,82+band*8)
   p.Material=Enum.Material.Slate
   report.rock_faces+=1
  end
 end
 for _,group in groups do
  task.wait()
  local shaft=group[1];local safe=shaft.Size.Y<25
  for _,p in group do if p.CanCollide or not inside(p)then safe=false end end
  if not safe then continue end
  local hide=shaft.Size.Y<8
  if hide then report.hidden_groups+=1 else report.quiet_groups+=1 end
  for _,p in group do
   if hide then p.Transparency=1 else p.Color=Color3.fromRGB(65,91,120);p.Material=Enum.Material.SmoothPlastic end
   for _,l in p:GetChildren()do if l:IsA('Light')then l.Enabled=false end end
   report.crystal_parts+=1
  end
 end
 return report
end
