-- Audited inward facets; retained continuous rear cores seal every wall.
local S={}
local plan=require(script.Parent.Rock3Plan)
local V,C=Vector3.new,CFrame.new
function S.build(root)
 if root:FindFirstChild('MeadowRock3')then return end
 local group=Instance.new('Model');group.Name='MeadowRock3'
 local originals={};local wanted,lookup={},{}
 local function key(n,v)return string.format('%s/%.3f/%.3f/%.3f',n,v.X,v.Y,v.Z)end
 for _,g in plan do wanted[g.name]=true end
 for _,p in root:GetDescendants()do
  if p:IsA('BasePart')and wanted[p.Name]then
   local k=key(p.Name,p.CFrame.Position);if lookup[k]then lookup[k]=false else lookup[k]=p end
  end
 end
 local ok,err=pcall(function()
  for _,g in plan do
   local target=assert(lookup[key(g.name,V(unpack(g.position)))],'missing rock3 target')
   assert((target.Size-V(unpack(g.size))).Magnitude<.003,'rock3 size changed')
   local expected=C(unpack(g.position))*C(0,0,0,unpack(g.rotation))
   assert((target.CFrame.RightVector-expected.RightVector).Magnitude<.0001 and (target.CFrame.UpVector-expected.UpVector).Magnitude<.0001,'rock3 rotation changed '..g.name)
   if g.replace then table.insert(originals,target)end
   for _,a in g.pieces do
    local q=Instance.new(if a.shape=='Wedge'then'WedgePart'else'Part')
    q.Name=if g.replace then target.Name else'Rock3FarRelief'
    q.Anchored=target.Anchored
    q.CanCollide=g.replace and target.CanCollide or false
    q.CanQuery=g.replace and target.CanQuery or false
    q.CanTouch=g.replace and target.CanTouch or false
    q.CollisionGroup=target.CollisionGroup
    for k,v in target:GetAttributes()do q:SetAttribute(k,v)end
    for _,tag in target:GetTags()do q:AddTag(tag)end
    if not g.replace then q:SetAttribute('Cosmetic',true)end
    q.Size=V(unpack(a.s));q.CFrame=C(unpack(a.c))*C(0,0,0,unpack(a.r))
    q.Color=Color3.fromRGB(unpack(a.color));q.Material=target.Material
    q.Transparency=target.Transparency;q.Parent=group
   end
  end
 end)
 if not ok then group:Destroy();error(err)end
 group.Parent=root
 for _,p in originals do p:Destroy()end
 group:SetAttribute('Complete',true)
end
return S
