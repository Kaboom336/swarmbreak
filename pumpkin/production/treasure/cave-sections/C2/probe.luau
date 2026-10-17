local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c2.rbxl'))
local map=p.Workspace.CaveV2
print('ROUTES',p.ReplicatedStorage.CaveRouteData.Source)
for _,n in map:GetChildren()do
 if n:IsA('BasePart')and n.CFrame.X>=100 and n.CFrame.X<=244 and n.CFrame.Z>=-170 and n.CFrame.Z<=-90 and (n.Name:match('Geode')or n.Name:match('Giant')or n.Name:match('Camp')or n.Name:match('Guardian')or n.Name:match('Sign'))then print(n.Name,n.CFrame.Position,n.Size,n.CanCollide)end
end
local P=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes=P.lanes(map);local ray=require('../../../prototype/meadow-v4/OfflineRay').new(map,nil,4)
for _,x in {110,125,140,155,170,185,200,220,235}do for _,z in {-162,-150,-138,-126,-110,-98}do
 local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(10,14,10);q.CFrame=rb.CFrame.new(x,60,z)
 if P.laneClear({q},lanes)then local hit=ray(rb.Vector3.new(x,140,z),rb.Vector3.new(0,-150,0));print('POCKET',x,z,hit and hit.Position.Y,hit and hit.Instance.Name)end
end end
