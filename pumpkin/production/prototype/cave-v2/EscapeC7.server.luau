-- Cosmetic-only tunnel; existing CaveV2 and its gameplay are never edited.
local S = game:GetService('ServerScriptService')
local plan = game:GetService('HttpService'):JSONDecode(script.Plan.Value)
local root = workspace:WaitForChild('CaveEscapeC7')
for _, g in plan do
 task.wait()
 if g.text then
  local board = root:FindFirstChild(g.name)
  if board and not board:FindFirstChild('C7Front') then
   for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
    local gui = Instance.new('SurfaceGui')
    gui.Name = face == Enum.NormalId.Front and 'C7Front' or 'C7Back'
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    local label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = g.text
    label.FontFace = Font.new('rbxasset://fonts/families/FredokaOne.json')
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255, 236, 180)
    label.TextStrokeColor3 = Color3.fromRGB(45, 28, 21)
    label.TextStrokeTransparency = 0
    label.Parent = gui
    gui.Parent = board
   end
  end
 end
end
local presentation = script:FindFirstChild('Presentation')
if presentation then
 require(presentation)(workspace:WaitForChild('CaveV2'), root, script.Round.Value)
end
local dress = script:FindFirstChild('Dress')
if dress then
 require(dress)(workspace:WaitForChild('CaveV2'), root, script.Round.Value)
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
   local expected = CFrame.new(unpack(g.c)) * CFrame.Angles(0, math.rad(g.yaw or 0), 0)
   local base = expected * CFrame.new(0, -size.Y / 2, 0)
   local m = assert(Kit.spawn('quaternius-nature__Rock_Medium_1', 'cave', base, size), 'blast rock unavailable')
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
   if g.apronShoulder then
    -- Exact cosmetic shoulder exception; central 32-wide apron stays empty.
    assert(expected.X - size.X / 2 >= -133 and expected.X + size.X / 2 <= -126 and expected.Z - size.Z / 2 >= 105 and expected.Z + size.Z / 2 <= 139, 'apron shoulder exceeded')
    protected = {}
    for _, lane in lanes do
     if lane.Name ~= 'SafetyApron' then
      table.insert(protected, lane)
     end
    end
   end
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
  if p:IsA('BasePart') and p:GetAttribute('C7Fallback') then
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
 warn('[C7] rock fallback retained: ' .. tostring(why))
 task.wait(2)
end
