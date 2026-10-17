-- Owner rock pass: cosmetics only. Builder's existing MeadowDressing pcall
-- invokes build in local coordinates; deferred meshes receive MeadowOrigin once.
local S={}
local plan=require(script.Parent.RockShellPlan)
S.plan=plan
local V,C=Vector3.new,CFrame.new
local work=0
local function yieldBuild()
 work+=1;if work%120==0 and task then task.wait()end
end
local stone={SolidMountainStone=true,TunnelHillEarth=true,TunnelClosedVault=true,
 TunnelRoughRockCore=true,TunnelRockCourse=true,TunnelInnerRockFacet=true,
 TunnelArchedRockRib=true,TunnelValleyRetainedJoin=true,R5IrregularRockFace=true,
 Round4StackedRock=true,Round4ShelfRockRelief=true,Round4ShelfLightFacet=true}
function S.spawnKits(root,kit)
 if root:FindFirstChild('MeadowRockShells')then return end
 local group=Instance.new('Model');group.Name='MeadowRockShells'
 local origin=root:GetAttribute('MeadowOrigin')or V(0,0,0)
 local ok,problem=pcall(function()
  for i,g in plan do
   yieldBuild()
   local size=V(unpack(g.s));local rotation=C(0,0,0,unpack(g.r))
   local frame=C(origin+V(unpack(g.c)))*rotation*C(0,-size.Y/2,0)
   local m=assert(kit.spawn('quaternius-nature__Rock_Medium_1','meadow',frame,size),'CC0 rock unavailable')
   local fitted,why=kit.fit(m,size,frame)
   if not fitted then m:Destroy();error(why)end
   -- Verify actual cloned component bounds, rather than trusting requested fit.
   local expected=C(origin+V(unpack(g.c)))*rotation
   for _,p in m:GetDescendants()do
    yieldBuild()
    if p:IsA('BasePart')then
     for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
      local q=expected:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2))
      if math.abs(q.X)>size.X/2+.01 or math.abs(q.Y)>size.Y/2+.01 or math.abs(q.Z)>size.Z/2+.01 then
       m:Destroy();error('rock component escaped audited envelope')
      end
     end end end
    end
   end
   m.Name=string.format('RockShell_%s_%04d',g.section,i)
   for _,p in m:GetDescendants()do
    yieldBuild()
    if p:IsA('BasePart')then
     p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
     p.Color=Color3.fromRGB(unpack(g.color));p.Material=Enum.Material.Slate
     -- Atlas pixels override the intended stone tint in Studio.
     if p:IsA('MeshPart')then p.TextureID='' end
     for _,a in p:GetChildren()do if a:IsA('SurfaceAppearance')then a:Destroy()end end
     p:SetAttribute('Cosmetic',true);p:SetAttribute('RockShell',true);p:SetAttribute('RockSection',g.section)
     p.CastShadow=true
    end
   end
   m.Parent=group
  end
 end)
 if not ok then group:Destroy();error(problem)end
 group:SetAttribute('Complete',true);group:SetAttribute('RockCount',#plan);group.Parent=root
end
function S.build(root)
 -- Only Color changes on retained geometry. No original metadata is written.
 for _,p in root:GetDescendants()do
  yieldBuild()
  if p:IsA('BasePart')and stone[p.Name]and not p:GetAttribute('WalkableLaneFloor')and not p:GetAttribute('LaneId')then
   p.Color=Color3.fromRGB(124,116,99)
  end
 end
 -- KitLibrary belongs to the existing server pipeline. Wait until Builder's
 -- one translation is complete; never import assets or write restricted lights.
 if task then task.spawn(function()
  while root.Parent==nil and root:GetAttribute('MeadowOrigin')==nil do task.wait()end
  if not root.Parent then return end
  local ok,err=pcall(function()
   S.spawnKits(root,require(game:GetService('ServerScriptService'):WaitForChild('KitLibrary')))
  end)
  if not ok then warn('[MeadowV4] Rock shells skipped: '..tostring(err))end
 end)end
end
return S
