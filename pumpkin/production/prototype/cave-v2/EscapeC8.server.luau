-- C8 exterior cosmetics. Existing gameplay, lights and suites remain exact.
local S = game:GetService('ServerScriptService')
local plan = game:GetService('HttpService'):JSONDecode(script.Plan.Value)
local root = workspace:WaitForChild('CaveEscapeC8')
for _, g in plan do
 task.wait()
 if g.sparkle then
  local q = root:FindFirstChild(g.name)
  if q and not q:FindFirstChild('C8FallingSparkles') then
   local e = Instance.new('ParticleEmitter')
   e.Name = 'C8FallingSparkles'
   e.Texture = 'rbxasset://textures/particles/sparkles_main.dds'
   e.EmissionDirection = g.flip and Enum.NormalId.Top or Enum.NormalId.Bottom
   e.Rate = 3
   e.Lifetime = NumberRange.new(1.2, 1.8)
   e.Speed = NumberRange.new(2, 3)
   e.Acceleration = Vector3.new(0, -4, 0)
   e.SpreadAngle = Vector2.new(3, 3)
   e.Size = NumberSequence.new(.12)
   e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .3), NumberSequenceKeypoint.new(1, 1)})
   e.Color = ColorSequence.new(q.Color)
   e.LightEmission = .4
   e.Parent = q
  end
 end
end
local Kit = require(S:WaitForChild('KitLibrary'))
local Lane = require(S:WaitForChild('KitPlan'))
local function build()
 local existing = root:FindFirstChild('Rocks')
 if existing and existing:GetAttribute('Complete') then
  return true
 end
 if existing then
  existing:Destroy()
 end
 local group = Instance.new('Model')
 group.Name = 'Rocks'
 local ok, why = pcall(function()
  local lanes = Lane.lanes(workspace:WaitForChild('CaveV2'))
  for _, g in plan do
   task.wait()
   if not g.kit then
    continue
   end
   local size = Vector3.new(unpack(g.s))
   local expected = CFrame.new(unpack(g.c)) * CFrame.Angles(0, math.rad(g.yaw or 0), 0) * CFrame.Angles(math.rad(g.flip and 180 or 0), 0, 0)
   local base = expected * CFrame.new(0, -size.Y / 2, 0)
   local m = assert(Kit.spawn(g.kitName or 'quaternius-nature__Rock_Medium_1', 'cave', base, size), 'C8 rock unavailable')
   m.Parent = group
   m.Name = g.name
   assert(Kit.fit(m, size, base), 'blast fit failed')
   local parts = {}
   for i, p in m:GetDescendants() do
    if i % 80 == 0 then
     task.wait()
    end
    if p:IsA('BasePart') then
     p.Anchored = true
     p.CanCollide = false
     p.CanQuery = false
     p.CanTouch = false
     p.Color = Color3.fromRGB(unpack(g.color))
     p.Material = Enum.Material.Slate
     if p:IsA('MeshPart') then
      p.TextureID = ''
     end
     for _, a in p:GetChildren() do
      if a:IsA('SurfaceAppearance') then
       a:Destroy()
      end
     end
     for _, x in {-1, 1} do
      for _, y in {-1, 1} do
       for _, z in {-1, 1} do
        local v = expected:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x, y, z) / 2))
        assert(math.abs(v.X) <= size.X / 2 + .01 and math.abs(v.Y) <= size.Y / 2 + .01 and math.abs(v.Z) <= size.Z / 2 + .01, 'blast envelope escaped')
       end
      end
     end
     table.insert(parts, p)
    end
   end
   local protected = lanes
   -- C8 owns the deep underside. Use full 3D reserves here: never filter a
   -- floor unless the entire cosmetic is at least 16 studs below its bottom.
   local separated = {}
   for _, lane in lanes do
    local cf, s = lane.CFrame, lane.Size
    local bottom = cf.Y - (math.abs(cf.RightVector.Y)*s.X + math.abs(cf.UpVector.Y)*s.Y + math.abs(cf.LookVector.Y)*s.Z)/2
    if expected.Y + size.Y / 2 >= bottom - 16 then
     table.insert(separated, lane)
    end
   end
   protected = separated
   assert(Lane.laneClear(parts, protected), 'blast lane margin')
  end
 end)
 if not ok then
  group:Destroy()
  return false, why
 end
 group:SetAttribute('Complete', true)
 group.Parent = root
 for _, p in root:GetChildren() do
  if p:IsA('BasePart') and p:GetAttribute('C8Fallback') then
   p.Transparency = 1
  end
 end
 return true
end
-- Bounded retry; native silhouettes stay visible on unavailable kits/fit failure.
for _attempt = 1, 3 do
 local ok, why = build()
 if ok then
  break
 end
 warn('[C8] rock fallback retained: ' .. tostring(why))
 task.wait(2)
end
-- Original CaveKits also replaces FloatingRock, regardless of Transparency.
-- Retire only those 24 nonphysical runtime duplicates after our full group fits.
-- Never change original producers or unrelated kit instances.
for _attempt = 1, 120 do
 task.wait(.5)
 local map = workspace:WaitForChild('CaveV2')
 local rocks = root:FindFirstChild('Rocks')
 if not rocks or not rocks:GetAttribute('Complete') then break end
 if map:GetAttribute('KitSwapVersion') == 2 then
  local ids = {}
  for index, q in map:GetChildren() do
   if index % 200 == 0 then task.wait() end
   if q:IsA('BasePart') and q.Name == 'FloatingRock' and not q.CanCollide then
    local id = q:GetAttribute('KitAssemblyId')
    if id then ids[id] = true end
   end
  end
  local dressing = map:FindFirstChild('CaveKitDressing')
  if dressing then
   for _, model in dressing:GetChildren() do
    task.wait()
    if ids[model:GetAttribute('KitAssemblyId')] then
     for _, q in model:GetDescendants() do
      if q:IsA('BasePart') then
       assert(not q.CanCollide and not q.CanQuery and not q.CanTouch, 'C8 duplicate unexpectedly physical')
       q.Transparency = 1
      end
     end
    end
   end
  end
  break
 end
end
