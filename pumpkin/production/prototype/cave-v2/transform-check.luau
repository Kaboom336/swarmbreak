local rb=require('@lune/roblox');local V,C=rb.Vector3,rb.CFrame
local cf=C.lookAt(V.zero,V.new(-70,-24,0));print('lookAt',cf.LookVector,cf.UpVector,cf.RightVector,cf:GetComponents())
local explicit=C.new(0,0,0,0,-.324324,.945946,0,.945946,.324324,-1,0,0);print('explicit',explicit.LookVector,explicit.UpVector,explicit.RightVector,explicit:GetComponents())
print('ends',explicit:PointToWorldSpace(V.new(0,0,-37)))
