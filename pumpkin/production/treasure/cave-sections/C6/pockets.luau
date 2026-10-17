local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes=Plan.lanes(p.Workspace.CaveV2)
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(p.Workspace.CaveV2,nil,4)
local out={}
for x=-200,140,5 do for z=-155,95,5 do
 for _,width in {14,10,6}do
 local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(width,12,width);q.CFrame=rb.CFrame.new(x,0,z)
 if Plan.laneClear({q},lanes)then
  local hit=ray(rb.Vector3.new(x,64,z),rb.Vector3.new(0,-82,0))
  if hit then
   local y=hit.Position.Y;local supported=true
   for _,dx in {-width/2,0,width/2}do for _,dz in {-width/2,0,width/2}do
    local h=ray(rb.Vector3.new(x+dx,y+.2,z+dz),rb.Vector3.new(0,-.4,0))
    if not h or math.abs(h.Position.Y-y)>.035 then supported=false end
   end end
   if supported then table.insert(out,{x,y+.02,z,width})end
  end
 end
 q:Destroy()
 end
 end;require('@lune/task').wait()end
fs.writeFile('treasure/cave-sections/C6/POCKETS.json',serde.encode('json',out,true));print('supported pockets',#out)
