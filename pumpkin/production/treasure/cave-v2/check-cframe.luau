-- Independent exporter-axis probe, no place writes.
local rb=require('@lune/roblox')
local V,C=rb.Vector3,rb.CFrame
local a,b=V.new(110,48,-120),V.new(40,24,-120)
local cf=C.lookAt((a+b)/2,b)
local c={cf:GetComponents()}
print('components',c)
print('right',cf.RightVector,'up',cf.UpVector,'look',cf.LookVector)
print('localZ world',cf:VectorToWorldSpace(V.new(0,0,1)))
print('expected forward',(b-a).Unit)
local forward=(b-a).Unit
local right=forward:Cross(V.yAxis).Unit
local fixed=C.fromMatrix((a+b)/2,right,right:Cross(forward).Unit,-forward)
print('matrix components',{fixed:GetComponents()})
print('matrix look',fixed.LookVector,'expected',forward)
print('matrix localZ',fixed:VectorToWorldSpace(V.zAxis))
