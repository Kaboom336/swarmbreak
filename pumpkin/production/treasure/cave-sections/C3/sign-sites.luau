local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'));local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(8,4.6,1)
for _,g in {{134,55.8,-74,8,4.6,1,-45},{135.5,58.5,-71,.8,.8,6.71,26.565},{80,34,-35,5,20,3.5,0},{82,34,-35,5,20,3.5,0}}do
 q.Size=rb.Vector3.new(g[4],g[5],g[6]);q.CFrame=rb.CFrame.new(g[1],g[2],g[3])*rb.CFrame.Angles(0,math.rad(g[7]),0);print(g[1],g[3],Plan.laneClear({q},Plan.lanes(p.Workspace.CaveV2)))
end
