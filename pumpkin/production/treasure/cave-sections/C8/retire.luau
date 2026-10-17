-- Residual C8 cosmetics only. No routes, geode, colliders or suite exceptions.
return function(q,tag)
 if not q:IsA('BasePart')then return false end
 if q.Name=='FloatingRock' or q.Name=='R3DistantIsland'then return true end
 if tag=='r4' and q.Name:match('^Crystal') then
  local v=q.CFrame.Position
  return math.abs(v.X)>275 or v.Z< -270
 end
 return false
end
