-- Camera-scoped cosmetic replacements. Original solids are never mutated.
local S={}
local plan=require(script.Parent.Rock4Plan)
S.plan=plan.shells
local V,C=Vector3.new,CFrame.new
local work=0
local byName={}
for _,g in plan.retire do
 byName[g.name]=byName[g.name]or {};table.insert(byName[g.name],g)
end
local function tick()
 work+=1;if work%120==0 and task then task.wait()end
end
function S.hideReplaced(root)
 local origin=root:GetAttribute('MeadowOrigin')or V(0,0,0)
 local targets={}
 for _,p in root:GetDescendants()do
  tick()
  if not p:IsA('BasePart')then continue end
  for _,g in byName[p.Name]or {} do
   if g.hide and p.Name==g.name and (p.CFrame.Position-origin-V(unpack(g.c))).Magnitude<.01 then
    assert(not p.CanCollide and not p.CanQuery and not p.CanTouch,'protected replacement')
    table.insert(targets,p);break
   end
  end
 end
 local expected=0;for _,g in plan.retire do if g.hide then expected+=1 end end
 assert(#targets==expected,'replacement target drift')
 for _,p in targets do p.Transparency=1 end
end
function S.spawnKits(root,kit)
 if root:FindFirstChild('MeadowRock4')then return end
 local group=Instance.new('Model');group.Name='MeadowRock4'
 local origin=root:GetAttribute('MeadowOrigin')or V(0,0,0)
 local ok,err=pcall(function()
  for i,g in S.plan do
   tick()
   local size=V(unpack(g.s));local expected=C(origin+V(unpack(g.c)))*C(0,0,0,unpack(g.r))
   assert(math.min(size.X,size.Y,size.Z)>.05,'degenerate rock envelope')
   local frame=expected*C(0,-size.Y/2,0)
   local m=assert(kit.spawn('quaternius-nature__Rock_Medium_1','meadow',frame,size),'CC0 rock unavailable')
   m.Parent=group
   local fitted,why=kit.fit(m,size,frame);assert(fitted,why)
   m.Name=string.format('Rock4_%s_%04d',g.section,i)
   for _,p in m:GetDescendants()do
    tick()
    if p:IsA('BasePart')then
     for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
      local q=expected:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
      assert(math.abs(q.X)<=size.X/2+.01 and math.abs(q.Y)<=size.Y/2+.01 and math.abs(q.Z)<=size.Z/2+.01,'rock4 fit escaped envelope')
     end end end
     p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
     p.Color=Color3.fromRGB(unpack(g.color));p.Material=Enum.Material.Slate
     if p:IsA('MeshPart')then p.TextureID=''end
     for _,a in p:GetChildren()do if a:IsA('SurfaceAppearance')then a:Destroy()end end
     p:SetAttribute('Cosmetic',true);p:SetAttribute('RockSection',g.section);p:SetAttribute('Rock4',true)
    end
   end
  end
  S.hideReplaced(root)
 end)
 if not ok then group:Destroy();error(err)end
 group:SetAttribute('Complete',true);group.Parent=root
end
function S.build(root)
 if root:GetAttribute('Rock4Prepared')then return end
 local targets={}
 for _,p in root:GetDescendants()do
  tick()
  if not p:IsA('BasePart')then continue end
  for _,g in byName[p.Name]or {} do
   if p.Name==g.name and (p.CFrame.Position-V(unpack(g.c))).Magnitude<.01 then
    assert(not p.CanCollide and not p.CanQuery and not p.CanTouch,'protected rock4 target')
    assert(not p:GetAttribute('WalkableLaneFloor')and not p:GetAttribute('LaneId'),'lane target')
    table.insert(targets,{p,g});break
   end
  end
 end
 assert(#targets==#plan.retire,'rock4 target drift')
 for _,entry in targets do
  tick();local p,g=unpack(entry)
  if not g.hide then p:Destroy()end
 end
 root:SetAttribute('Rock4Prepared',true)
 if task then task.spawn(function()
  while root.Parent==nil and root:GetAttribute('MeadowOrigin')==nil do task.wait()end
  if not root.Parent then return end
  local ok,err=pcall(function()S.spawnKits(root,require(game:GetService('ServerScriptService'):WaitForChild('KitLibrary')))end)
  if not ok then warn('[MeadowV4] Rock4 skipped: '..tostring(err))end
 end)end
end
return S
