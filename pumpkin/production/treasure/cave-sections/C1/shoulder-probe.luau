local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c1.rbxl'));local plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes={};for _,l in plan.lanes(p.Workspace.CaveV2)do if l.Name~='SafetyApron'then table.insert(lanes,l)end end
for _,z in {114,118,122,126,130,134}do
 local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(6,10,6);q.CFrame=rb.CFrame.new(-130,5,z)
 print(z,plan.laneClear({q},lanes))
end
