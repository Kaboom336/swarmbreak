local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c4.rbxl'))
local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes=Plan.lanes(p.Workspace.CaveV2)
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(p.Workspace.CaveV2,nil,4)
for _,c in {{25,17},{20,12},{20,25},{-40,38},{-40,48},{-43,50},{-25,65},{-5,60},{-27,0},{-40,0},{-60,0},{-85,0}}do
 local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(6,4,.6);q.CFrame=rb.CFrame.new(c[1],28,c[2])*rb.CFrame.Angles(0,math.rad(60),0)
 local ok,why=Plan.laneClear({q},lanes);local h=ray(rb.Vector3.new(c[1],60,c[2]),rb.Vector3.new(0,-100,0))
 print(c,ok,why,'ground',h and h.Position.Y)
 q:Destroy()
end
