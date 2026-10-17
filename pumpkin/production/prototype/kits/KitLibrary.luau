-- CC0 Kenney/Quaternius models; server-only, one sanitized template per island/name.

-- Bound synchronous construction/scans; offline builders have no task.
local yieldWork = 0
local yieldDeadline = os.clock() + .01
local function yieldBuild()
 yieldWork += 1
 if yieldWork % 300 == 0 and os.clock() >= yieldDeadline then
  if task then task.wait() end
  yieldDeadline = os.clock() + .01
 end
end
local Insert = game:GetService("InsertService")
local Storage = game:GetService("ServerStorage")
local Tags = game:GetService("CollectionService")
local Http = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local manifest = Http:JSONDecode(script.Manifest.Value)
local Kit = { manifest = manifest, failures = {}, templates = {}, loaded = 0 }
local state = "new"
local folder = Storage:FindFirstChild("KitTemplates") or Instance.new("Folder")
folder.Name, folder.Parent = "KitTemplates", Storage
local function key(name, island) return island .. "__" .. name end
local function clearWalkable(node)
 node:SetAttribute("WalkableLaneFloor", false)
 node:SetAttribute("Walkable", false)
 node:SetAttribute("LaneId", nil)
 for _, tag in {"AuthoredLaneFloor", "WalkableLaneFloor", "Walkable"} do
  Tags:RemoveTag(node, tag)
 end
end
-- Interim palette until the kits are re-imported with per-material meshes and textures.
local MATERIAL_LOOK = {
 meadow_leaf = { Color3.fromRGB(86, 168, 62), Enum.Material.SmoothPlastic },
 cave_leaf = { Color3.fromRGB(92, 78, 120), Enum.Material.SmoothPlastic },
 meadow_flower = { Color3.fromRGB(236, 120, 170), Enum.Material.SmoothPlastic },
 cave_flower = { Color3.fromRGB(110, 210, 230), Enum.Material.Neon },
 wood = { Color3.fromRGB(132, 88, 52), Enum.Material.WoodPlanks },
 meadow_stone = { Color3.fromRGB(134, 136, 142), Enum.Material.Slate },
 cave_stone = { Color3.fromRGB(78, 80, 104), Enum.Material.Slate },
}
local function propType(name)
 if name:find("Tree") or name:find("Pine") or name:find("tree_") then return "tree" end
 if name:lower():find("flower") or name:lower():find("mushroom") or name:find("Pebble") then return "small" end
 if name:find("fence") or name:find("bridge") then return "infrastructure" end
 return "prop"
end
function Kit.init()
 if state == "ready" then return end
 if state == "loading" then repeat task.wait() until state == "ready"; return end
 state = "loading"
 local memoryBefore = Stats:GetTotalMemoryUsageMb()
 for _, entry in manifest do
  -- Cached asset loads may return without yielding.
  if task then task.wait() end
  local id = key(entry.name, entry.island)
  local loaded, lastError
  for attempt = 1, 3 do
   local ok, result = pcall(function()
    local model = Insert:LoadAsset(entry.id)
    clearWalkable(model)
    local valid, err = pcall(function()
     local count = 0
     for _, node in model:GetDescendants() do yieldBuild();
      clearWalkable(node)
      if node:IsA("LuaSourceContainer") then node:Destroy()
      elseif node:IsA("BasePart") then
       count += 1
       node.Anchored, node.CanCollide, node.CanTouch, node.CanQuery = true, false, false, false
       -- RenderFidelity is plugin-only at runtime; imported meshes already default to Automatic.
       -- Bulk import dropped the kit colours; the mesh name carries its material (__<island>_<mat>).
       local mat = node.Name:match("__%a+_(%a+)$") or node.Name:match("__%a+_[%w_]+_(%a+)$")
       local look = MATERIAL_LOOK[(entry.island or "") .. "_" .. (mat or "")] or MATERIAL_LOOK[mat or ""]
       if look and node:IsA("MeshPart") and node.TextureID == "" then
        node.Color, node.Material = look[1], look[2]
       end
      end
     end
     assert(count > 0, "empty model")
     assert(count == entry.meshParts, "manifest MeshPart count differs")
     model.PrimaryPart = nil
     local box, size = model:GetBoundingBox()
     local shift = CFrame.new(-box.X, -box.Y + size.Y / 2, -box.Z)
     for _, part in model:GetDescendants() do yieldBuild();
      if part:IsA("BasePart") then part.CFrame = shift * part.CFrame end
     end
     model.WorldPivot = CFrame.identity
     model:SetAttribute("KitNativeSize", size)
     model:SetAttribute("KitNativeScale", model:GetScale())
     model:SetAttribute("KitAssetId", entry.id)
     model:SetAttribute("KitIsland", entry.island)
     model:SetAttribute("KitName", entry.name)
     model:SetAttribute("KitTriangles", entry.triangles)
     model.Name = id
    end)
    if not valid then model:Destroy(); error(err) end
    return model
   end)
   if ok then loaded = result; break end
   lastError = tostring(result)
   warn(string.format("[KitLibrary] %s asset %s attempt %d/3 failed: %s", id, entry.id, attempt, lastError))
   if attempt < 3 then task.wait(attempt) end
  end
  if loaded then loaded.Parent = folder; Kit.templates[id] = loaded; Kit.loaded += 1
  else Kit.failures[id] = lastError; warn("[KitLibrary] FALLBACK original code-built prop: " .. id) end
 end
 state = "ready"
 folder:SetAttribute("Loaded", Kit.loaded)
 folder:SetAttribute("Expected", #manifest)
 folder:SetAttribute("MemoryBeforeMb",memoryBefore)
 folder:SetAttribute("MemoryAfterMb",Stats:GetTotalMemoryUsageMb())
 folder:SetAttribute("LoadMemoryDeltaMb", folder:GetAttribute("MemoryAfterMb") - memoryBefore)
 folder:SetAttribute("TemplateInstances",#folder:GetDescendants())
 local triangles=0
 for _,t in Kit.templates do triangles+=t:GetAttribute("KitTriangles") or 0 end
 folder:SetAttribute("TemplateSourceTriangles",triangles)
 print(string.format("[KitLibrary] %d/%d templates; memory delta %.2f MB (whole server, not asset-exclusive)", Kit.loaded, #manifest, folder:GetAttribute("LoadMemoryDeltaMb")))
end
-- number = native-size multiplier; Vector3 = target bounding dimensions (uniform fit).
-- cframe is the bottom-centre base frame. Caller parents the returned model.
-- Missing model returns nil + reason; callers MUST retain/create their original prop.
function Kit.spawn(name, island, cframe, scale)
 Kit.init()
 local template = Kit.templates[key(name, island)]
 if not template then
  local reason = Kit.failures[key(name, island)] or "unknown manifest key"
  warn("[KitLibrary] FALLBACK " .. key(name, island) .. ": " .. reason)
  return nil, reason
 end
 local model = template:Clone()
 clearWalkable(model)
 local size = template:GetAttribute("KitNativeSize")
 local factor = scale or 1
 if typeof(factor) == "Vector3" then factor = math.min(factor.X / size.X, factor.Y / size.Y, factor.Z / size.Z) end
 assert(type(factor) == "number" and factor > 0 and factor < math.huge, "invalid kit scale")
 model:ScaleTo(template:GetAttribute("KitNativeScale") * factor)
 model:PivotTo(cframe)
 local kind = propType(name)
 -- Meadow geology uses material and tint, never the imported palette atlas.
 -- Other islands and wood/foliage/infrastructure retain their authored look.
 local rockName = name:lower()
 local warmStone = island == 'meadow' and (rockName:find('rock',1,true)
  or rockName:find('cliff',1,true) or rockName:find('stone_large',1,true)
  or rockName:find('pebble',1,true))
 local hasTrunk=false
 for _, p in model:GetDescendants() do yieldBuild();
  clearWalkable(p)
  if p:IsA("BasePart") then
   p.Anchored, p.CanTouch, p.CanQuery = true, false, false
   -- Decorative material components never participate in collision or landing rays.
   p.CanCollide = false
   if p.CanCollide then hasTrunk=true end
   p.CastShadow = kind ~= "small"
   if warmStone then
    if p:IsA('MeshPart') then p.TextureID = '' end
    for _,a in p:GetChildren() do if a:IsA('SurfaceAppearance') then a:Destroy() end end
    -- Stable world-space strata; section/shell palettes can refine this tint.
    local band = (math.floor(cframe.X/7)+math.floor(cframe.Z/7))%5
    p.Color = if band == 4 then Color3.fromRGB(157,143,119)
     else Color3.fromRGB(120+band*7,111+band*6,95+band*5)
    p.Material = Enum.Material.Slate
   end
   -- RenderFidelity left at its imported default (plugin-only property).
  end
 end
 if kind=="tree" and not hasTrunk then
  local trunk=Instance.new("Part");trunk.Name="KitTrunkCollider"
  clearWalkable(trunk)
  trunk.Size=Vector3.new(math.min(size.X,size.Z)*0.08*factor,size.Y*0.35*factor,math.min(size.X,size.Z)*0.08*factor)
  trunk.CFrame=cframe*CFrame.new(0,trunk.Size.Y/2,0)
  trunk.Anchored,trunk.CanCollide,trunk.CanTouch,trunk.CanQuery=true,false,false,false
  trunk.Transparency=1;trunk.CastShadow=false;trunk.Parent=model
 end
 Tags:AddTag(model, "KitProp"); Tags:AddTag(model, island); Tags:AddTag(model, "KitType_" .. kind)
 model:SetAttribute("KitScale", factor)
 return model
end
-- Explicit fitted infrastructure only; foliage/rocks always use uniform ScaleTo.
-- Reject rotated component bases that would require mesh shearing.
function Kit.fit(model, target, frame)
 model:PivotTo(CFrame.identity)
 local pivot=CFrame.identity
 local _,size=model:GetBoundingBox()
 local ratio=target/size
 local edits={}
 for _,p in model:GetDescendants() do yieldBuild(); if p:IsA("BasePart") then
  local cf=pivot:ToObjectSpace(p.CFrame)
  local axes={cf.RightVector,cf.UpVector,-cf.LookVector}
  for _,a in axes do
   local v=math.max(math.abs(a.X),math.abs(a.Y),math.abs(a.Z))
   if v<0.9999 then return false,"non-axis-aligned component requires shear" end
  end
  local function axisScale(a) return math.abs(a.X)*ratio.X+math.abs(a.Y)*ratio.Y+math.abs(a.Z)*ratio.Z end
  table.insert(edits,{part=p,cf=CFrame.new(cf.Position*ratio)*cf.Rotation,
   size=p.Size*Vector3.new(axisScale(axes[1]),axisScale(axes[2]),axisScale(axes[3]))})
 end end
 for _,e in edits do yieldBuild(); e.part.Size=e.size;e.part.CFrame=frame*e.cf end
 model.WorldPivot=frame
 model:SetAttribute("KitFittedSize",target)
 return true
end
return Kit
