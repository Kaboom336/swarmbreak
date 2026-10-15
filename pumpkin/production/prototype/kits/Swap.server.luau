local Kit = require(script.Parent.KitLibrary)
local Plan = require(script.Parent.KitPlan)
local Stats = game:GetService("Stats")
local applied = setmetatable({}, {__mode="k"})
local function apply(root,island)
 if applied[root] then return end
 applied[root]=true
 Kit.init()
 if not root:IsDescendantOf(workspace) then return end
 local memoryBefore=Stats:GetTotalMemoryUsageMb()
 local before=#root:GetDescendants()
 local primitiveProxy,curved=0,0
 for _,p in root:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
  if p:IsA("WedgePart") then primitiveProxy+=8
  elseif p:IsA("Part") and p.Shape==Enum.PartType.Block then primitiveProxy+=12
  else curved+=1 end
 end end
 local folder=Instance.new("Folder");folder.Name="KitDressing";folder.Parent=root
 local count,failed,meshParts,triangles=0,0,0,0
 local groups=Plan.groups(root,island)
 local lanes=Plan.lanes(root)
 local dropped=0
 local function clear(model, originals)
  if island~="meadow" then return true end
  local ok=Plan.laneClear(model:GetDescendants(),lanes)
  if originals then ok=ok and Plan.laneClear(originals,lanes) end
  if ok then return true end
  model:Destroy();dropped+=1
  -- Remove obsolete collision carriers with the rejected dressing placement.
  if originals then for _,p in originals do p:Destroy() end end
  return false
 end
 local function add(name,frame,size)
  local m=Kit.spawn(name,island,frame,size)
  if not m then failed+=1;return end
  if not clear(m) then return end
  for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false;p.CanQuery=false end end
  m.Parent=folder;count+=1;triangles+=m:GetAttribute("KitTriangles") or 0
  for _,p in m:GetDescendants() do if p:IsA("MeshPart") then meshParts+=1 end end
 end
 for index,g in groups do
  if g.keepReason then failed+=1;warn("[KitSwap] FALLBACK "..g.anchor.Name..": "..g.keepReason);continue end
  local scale=if g.fitted then 4 else g.size
  if g.tree then
   local template=Kit.templates[island.."__"..g.name]
   if template then
    local native=template:GetAttribute("KitNativeSize")
    scale=g.size.Y/native.Y
   end
  end
  local model,reason=Kit.spawn(g.name,island,g.base,scale)
  if not model then failed+=1;continue end
  if g.fitted then
   local ok,err=Kit.fit(model,g.size,g.base)
   if not ok then model:Destroy();failed+=1;warn("[KitSwap] FALLBACK "..g.anchor.Name..": "..err);continue end
  end
  if not clear(model,g.parts) then continue end
  -- Accepted placements retain original collision/query/touch carriers and names.
  -- Kit meshes cannot change lanes, reachable drops, cart contacts, or trunk hulls.
  for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false;p.CanQuery=false end end
  model.Name="Kit_"..g.anchor.Name.."_"..index
  model:SetAttribute("KitAssemblyId",island..":"..index)
  model:SetAttribute("KitOriginalBase",g.base)
  if g.tree then model:SetAttribute("KitTargetHeight",g.size.Y) end
  if g.fence then
   model:SetAttribute("KitJointStart",g.ends[1]);model:SetAttribute("KitJointEnd",g.ends[2])
   -- Existing shared posts close all bay ends, including failed adjacent bays.
  end
  model.Parent=folder
  for _,p in g.parts do
   p:SetAttribute("KitOriginalTransparency",p.Transparency)
   p:SetAttribute("KitAssemblyId",island..":"..index)
   p.Transparency=1 -- undo: restore this attribute, remove KitDressing
  end
  count+=1;triangles+=model:GetAttribute("KitTriangles") or 0
  for _,p in model:GetDescendants() do if p:IsA("MeshPart") then meshParts+=1 end end
  -- Three-piece accents stay inside existing bush/rock footprints, not on lanes.
  if island=="meadow" and g.anchor.Name:find("Bush") and index%4==0 then
   local w,d=math.min(g.size.X/4,2),math.min(g.size.Z/4,2)
   add("quaternius-nature__Pebble_Round_1",g.base*CFrame.new(w,0,d),Vector3.new(1.2,0.3,1))
   add("kenney_nature-kit__log",g.base*CFrame.new(-w,0,d),Vector3.new(2.5,1,2.5))
   add("kenney_nature-kit__stump_round",g.base*CFrame.new(w,0,-d),Vector3.new(1.4,1,1.4))
  end
 end
 if island=="cave" then
  local station=root:FindFirstChild("CartStationTimber",true)
  if station then
   local crates={}
   for _,g in groups do if g.anchor.Name:find("Crate") then table.insert(crates,g) end end
   table.sort(crates,function(a,b) return (a.base.Position-station.CFrame.Position).Magnitude<(b.base.Position-station.CFrame.Position).Magnitude end)
   -- Place station dressing on the existing crate cluster footprints.
   for i=1,math.min(3,#crates) do
    local g=crates[i]
    add("quaternius-nature__Mushroom_Common",g.base*CFrame.new(g.size.X/2,0,g.size.Z/2),Vector3.new(0.8,0.8,0.8))
   end
  end
 end
 if island=="meadow" then
  local bridge=Plan.bridgeCandidate(root)
  local template=Kit.templates[island.."__kenney_nature-kit__bridge_wood"]
  if bridge and template then
   local native=template:GetAttribute("KitNativeSize")
   local ratio=bridge.size/native
   if math.max(ratio.X,ratio.Y,ratio.Z)/math.min(ratio.X,ratio.Y,ratio.Z)<1.15 then
    -- A bridge deck is itself a lane; retain the native walking surface.
    root:SetAttribute("KitBridgeFit","kept: kit dressing excluded from lanes")
   else
    root:SetAttribute("KitBridgeFit","kept: uniform bridge asset does not fit thin ravine deck")
    warn("[KitSwap] bridge_wood does not fit ravine deck; original planks retained")
   end
  else root:SetAttribute("KitBridgeFit","kept: no deck or loaded bridge template") end
 end
 root:SetAttribute("KitSwapVersion",1)
 root:SetAttribute("KitLanePlacementsDropped",dropped)
 root:SetAttribute("KitSwapped",count);root:SetAttribute("KitFallbacks",failed)
 root:SetAttribute("KitInstancesBefore",before);root:SetAttribute("KitInstancesAfter",#root:GetDescendants())
 root:SetAttribute("KitMeshParts",meshParts);root:SetAttribute("KitSourceTriangles",triangles)
 root:SetAttribute("KitMemoryDeltaMb",Stats:GetTotalMemoryUsageMb()-memoryBefore)
 root:SetAttribute("KitPrimitiveTriangleProxyBefore",primitiveProxy)
 root:SetAttribute("KitUnknownCurvedPartsBefore",curved)
 root:SetAttribute("KitMemoryBeforeMb",memoryBefore)
 root:SetAttribute("KitMemoryAfterMb",Stats:GetTotalMemoryUsageMb())
 print(string.format("[KitSwap] %s: %d swaps, %d fallbacks; instances %d -> %d; meshes %d; source triangles %d; memory delta %.2f MB",island,count,failed,before,#root:GetDescendants(),meshParts,triangles,root:GetAttribute("KitMemoryDeltaMb")))
end
local function watch(node)
 if node:IsA("Model") and (node.Name=="MeadowV4" or node.Name=="CaveV2") then
  task.spawn(apply,node,node.Name=="MeadowV4" and "meadow" or "cave")
 end
end
workspace.DescendantAdded:Connect(watch)
for _,node in workspace:GetDescendants() do watch(node) end
task.spawn(Kit.init)
