-- Protected structural sight blockers remain exact. Only audited nonphysical
-- underlays are carved, and all other relief is on their protected far sides.
local S={}
local plan=require(script.Parent.Rock2Plan)
local V,C=Vector3.new,CFrame.new
function S.build(root)
 if root:FindFirstChild('MeadowRock2')then return end
 local group=Instance.new('Model');group.Name='MeadowRock2'
 local originals={};local built=0
 local wanted,lookup={},{}
 local function key(name,v)return string.format('%s/%.3f/%.3f/%.3f',name,v.X,v.Y,v.Z)end
 for _,g in plan do wanted[g.name]=true end
 for _,p in root:GetDescendants()do
  if p:IsA('BasePart')and wanted[p.Name]then
   local k=key(p.Name,p.CFrame.Position)
   if lookup[k]then lookup[k]=false else lookup[k]=p end
  end
 end
 local ok,problem=pcall(function()
  for _,g in plan do
   local target=lookup[key(g.name,V(unpack(g.position)))]
   assert(target,'missing rock2 target '..g.name)
   assert((target.Size-V(unpack(g.size))).Magnitude<.003,'rock2 target size changed')
   if g.replace then
    assert(not target.CanCollide and not target.CanQuery and not target.CanTouch and not target:GetAttribute('WalkableLaneFloor')and not target:GetAttribute('LaneId')and #target:GetTags()==0,'protected replacement')
    table.insert(originals,target)
   end
   for _,a in g.pieces do
    local q
    if g.replace and a.shape=='Block'then q=target:Clone();q:ClearAllChildren()
    else
     q=Instance.new(if a.shape=='Wedge'then'WedgePart'else'Part')
     if g.replace then
      for k,v in target:GetAttributes()do q:SetAttribute(k,v)end
      for _,tag in target:GetTags()do q:AddTag(tag)end
      q.CollisionGroup=target.CollisionGroup
     end
    end
    q.Name=if g.replace then target.Name else'Rock2FarRelief'
    q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
    q.Size=V(unpack(a.s));q.CFrame=C(unpack(a.c))*C(0,0,0,unpack(a.r))
    q.Color=Color3.fromRGB(unpack(a.color));q.Material=if a.kind:find('moss')then Enum.Material.Grass else(if a.kind:find('root')then Enum.Material.Wood else Enum.Material.Slate)
    if not g.replace then q:SetAttribute('Cosmetic',true)end
    q.Parent=group;built+=1
    if task and built%120==0 then task.wait()end
   end
  end
 end)
 if not ok then group:Destroy();error(problem)end
 -- Publish only after every target and component exists; failure preserves all
 -- originals. Builder performs the single world-origin translation afterward.
 group.Parent=root
 for _,p in originals do p:Destroy()end
 group:SetAttribute('Complete',true)
end
return S
