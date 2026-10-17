-- Residual exterior only. Never changes a gameplay solid or route producer.
local S = {}
local V, C = Vector3.new, CFrame.new
local warm = {Color3.fromRGB(133,108,84),Color3.fromRGB(117,94,74),Color3.fromRGB(98,81,68),Color3.fromRGB(85,75,66)}
function S.build(model, origin)
 local offset=origin or Vector3.zero
 local lanes, candidates, solids = {}, {}, {}
 local work=0
 local function yieldWork()
  work+=1
  if work%300==0 then if task then task.wait() end end
 end
 local function extent(p,margin)
  local cf=p.CFrame;local h=p.Size/2+V(margin or 0,0,margin or 0)
  local x,y,z=cf.RightVector,cf.UpVector,cf.LookVector
  return V(math.abs(x.X)*h.X+math.abs(y.X)*h.Y+math.abs(z.X)*h.Z,math.abs(x.Y)*h.X+math.abs(y.Y)*h.Y+math.abs(z.Y)*h.Z,math.abs(x.Z)*h.X+math.abs(y.Z)*h.Y+math.abs(z.Z)*h.Z)
 end
 local function safe(p)
  local e=extent(p);local c=p.CFrame.Position-offset
  if c.Y-e.Y < -160 or c.Y+e.Y > -24.1 or math.abs(c.X)+e.X>176 or math.abs(c.Z)+e.Z>176 then return false end
  for _,l in lanes do
   if math.abs(c.X-l.c.X)<e.X+l.e.X and math.abs(c.Z-l.c.Z)<e.Z+l.e.Z then return false end
  end
  for x=math.floor((c.X-e.X)/16),math.floor((c.X+e.X)/16) do
   for z=math.floor((c.Z-e.Z)/16),math.floor((c.Z+e.Z)/16) do
    for _,b in solids[x..':'..z] or {} do
     local d=c-b.c
     if math.abs(d.X)<e.X+b.e.X-.035 and math.abs(d.Y)<e.Y+b.e.Y-.035 and math.abs(d.Z)<e.Z+b.e.Z-.035 then return false end
    end
   end
  end
  return true
 end
 local paletteNames={R5MountainTier1=true,R5MountainTier2=true,Round4TaperChunk=true,TaperedIslandStone=true,R5IrregularRockFace=true}
 for _,p in model:GetDescendants() do
  yieldWork()
  if p:IsA('BasePart') and p:GetAttribute('WalkableLaneFloor') then table.insert(lanes,{c=p.CFrame.Position-offset,e=extent(p,1)}) end
  if p:IsA('BasePart') and (p.CanCollide or p.CanQuery) then
   local c,e=p.CFrame.Position-offset,extent(p)
   for x=math.floor((c.X-e.X)/16),math.floor((c.X+e.X)/16) do
    for z=math.floor((c.Z-e.Z)/16),math.floor((c.Z+e.Z)/16) do
     local key=x..':'..z;solids[key]=solids[key] or {};table.insert(solids[key],{c=c,e=e})
    end
   end
  end
 end
 for _,p in model:GetDescendants() do
  yieldWork()
  if p:IsA('BasePart') and paletteNames[p.Name] and not p.CanCollide and not p.CanQuery and not p.CanTouch and #p:GetTags()==0 and not p:GetAttribute('Section') then
   local c=p.CFrame.Position-offset;local e=extent(p)
   if c.Y-e.Y>=-160 and math.abs(c.X)+e.X<=176 and math.abs(c.Z)+e.Z<=176 and (p.Name~='R5IrregularRockFace' or c.Y+e.Y<=-4) then
    p.Color=warm[math.clamp(math.floor((-c.Y)/36)+1,1,4)];p.Material=Enum.Material.Rock
    if safe(p) then table.insert(candidates,p) end
   end
  end
 end
 -- Keep narrow tangent wedges inside each old cosmetic box. Their top is the
 -- old embedded joint; the exposed underside slopes down instead of ending flat.
 for i,p in candidates do
  yieldWork()
  local cf,size=p.CFrame,p.Size
  local group=Instance.new('Model');group.Name='S8_Stratum'..i;group.Parent=model
  for k=1,3 do
   yieldWork()
   local q=Instance.new('WedgePart');q.Name='S8_DownwardFacet'..k
   q.Size=V(size.X/3,size.Y,size.Z)
   q.CFrame=cf*C((k-2)*size.X/3,0,0)*CFrame.Angles(math.pi,0,0)
   q.Color=p.Color;q.Material=Enum.Material.Rock
   q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
   q:SetAttribute('Section','S8');q:SetAttribute('Story','Eroded underside stratum; downward break, never a landing')
   q:SetAttribute('S8Original',p.Name);q.Parent=group
  end
  p:Destroy()
 end
end
return S
