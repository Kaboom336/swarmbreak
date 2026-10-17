local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c3.rbxl'));local map=p.Workspace.CaveV2
local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(map,nil,4)
local sites={};local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(8,12,8)
for x=26,144,6 do for z=-107,-11,6 do
 local hit=ray(rb.Vector3.new(x,90,z),rb.Vector3.new(0,-80,0))
 if hit and hit.Position.Y>12 and hit.Position.Y<60 then
 q.CFrame=rb.CFrame.new(x,hit.Position.Y+6.03,z)
 if Plan.laneClear({q},Plan.lanes(map))then table.insert(sites,{x,hit.Position.Y,z})end
 end
end;require('@lune/task').wait()end
fs.writeFile('treasure/cave-sections/C3/SITES.json',serde.encode('json',sites,true));print(serde.encode('json',sites))
