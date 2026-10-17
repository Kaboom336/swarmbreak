local fs,rb=require('@lune/fs'),require('@lune/roblox')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c2r3.rbxl'))
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(p.Workspace.CaveV2,nil,4)
for _,x in {138,145,155,165,175,185,195,205,215}do
 local line={}
 for _,z in {-160,-150,-146,-140}do
  local hit=ray(rb.Vector3.new(x,140,z),rb.Vector3.new(0,-120,0))
  table.insert(line,z..':'..(hit and string.format('%.2f',hit.Position.Y)or'none'))
 end
 print(x,table.concat(line,' '));require('@lune/task').wait()
end
