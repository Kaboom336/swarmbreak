local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c1.rbxl'))
local map=p.Workspace.CaveV2;local ray=require('../../../prototype/meadow-v4/OfflineRay').new(map,nil,4)
local plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes=plan.lanes(map)
for _,x in {-184,-179,-119,-113,-107}do for _,z in {112,124,134,144,151}do
 local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(9,10,9);q.CFrame=rb.CFrame.new(x,5,z)
 if plan.laneClear({q},lanes)then
  local hit=ray(rb.Vector3.new(x,40,z),rb.Vector3.new(0,-150,0))
  print('POCKET',x,z,hit and hit.Position.Y,hit and hit.Instance.Name)
 end
end end
