-- Presentation cleanup only. Exact-name recipes; never infer gameplay from size.
local S = {}
local function cosmetic(p)
 return p:IsA('BasePart') and not p.CanCollide and not p.CanQuery and not p.CanTouch
  and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('LaneId')
  and not p:GetAttribute('RaidLane') and not p:GetAttribute('RaidVaultWall')
  and (not p:GetAttribute('SurfaceRole') or p:GetAttribute('SurfaceRole')=='Scenery')
  and #p:GetTags()==0
end
local function remove(p)
 local n=p.Name
 if n:match('^LookHillFlower') or n:match('^R5Flower') or n:match('^S1_Sunflower') then return true end
 if n:match('^S%d+_.*Bolt') then return true end
 -- Whole alternate fixtures, selected by their shared placement rather than
 -- deleting only their glass and leaving floating brackets.
 if n:match('^S2_Lamp') then local z=p.CFrame.Position.Z;return math.abs(z-78)<1 or math.abs(z-46)<1 end
 local rib=tonumber(n:match('^S3_RibSource(%d+)') or n:match('^S3_RibCage(%d+)'))
 if rib and rib%2==1 then return true end
 if n:match('^S6_RecoveryLamp2') then return true end
 return false
end
function S.apply(root)
 local removed=0
 for _,p in root:GetDescendants() do
  if cosmetic(p) then
   if remove(p) then p:Destroy();removed+=1
   elseif p:GetAttribute('Cosmetic') and p.Transparency<1 then
    -- Hero objects, native terrain/rock pass and route markings keep their hues.
    if p.Material==Enum.Material.Wood or p.Material==Enum.Material.WoodPlanks then
     p.Color=Color3.fromRGB(119,79,47)
    elseif p.Material==Enum.Material.Grass then p.Color=Color3.fromRGB(108,163,66) end
   end
  end
 end
 local limits={S1=2,S2=2,S3=4,S4=3,S6=3,S7=2,unowned=4}
 local used,positions={},{}
 for _,q in root:GetDescendants() do
  if q:IsA('PointLight') or q:IsA('SpotLight') or q:IsA('SurfaceLight') then
   local parent=q.Parent
   if cosmetic(parent) then
    local section=parent:GetAttribute('Section') or 'unowned'
    positions[section]=positions[section] or {}
    local crowded=false
    for _,v in positions[section] do if (v-parent.CFrame.Position).Magnitude<18 then crowded=true;break end end
    if crowded or (used[section] or 0)>=(limits[section] or 2) then q:Destroy()
    else
     used[section]=(used[section] or 0)+1;table.insert(positions[section],parent.CFrame.Position)
     q.Color=Color3.fromRGB(255,244,218)
     if section=='S3' then q.Range=28 end
    end
   end
  end
 end
 return removed
end
return S
