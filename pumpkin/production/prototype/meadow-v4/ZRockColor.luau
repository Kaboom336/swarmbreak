-- Appearance only: keep S6's existing cosmetic cap geometry and metadata exact.
local S={}
function S.build(root)
 for _,p in root:GetDescendants()do
  if p:IsA('BasePart') and (p.Name=='LookLightRockTop' or p.Name=='Round4PaleRockTop')
   and not p.CanCollide and not p.CanQuery and not p.CanTouch
   and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('LaneId')then
   local v=p.CFrame.Position
   if v.X>=-65 and v.X<=125 and v.Z>=-158 and v.Z<=-35 and v.Y>=0 and v.Y<=54 then
    local band=(math.floor(v.X/7)+math.floor(v.Z/7))%4
    p.Color=Color3.fromRGB(128+band*8,117+band*7,99+band*5)
    p.Material=Enum.Material.Slate
   end
  end
 end
end
return S
