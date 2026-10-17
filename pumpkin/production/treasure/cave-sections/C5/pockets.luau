local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c5.rbxl'))
local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes=Plan.lanes(p.Workspace.CaveV2)
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(p.Workspace.CaveV2,nil,4)
local out={}
for x=45,230,5 do for z=-100,100,5 do
 local q=rb.Instance.new('Part');q.Size=rb.Vector3.new(6,12,6);q.CFrame=rb.CFrame.new(x,0,z)
 if Plan.laneClear({q},lanes)then
  -- Search from inside roof height, not above the protected roof.
  local hit=ray(rb.Vector3.new(x,22,z),rb.Vector3.new(0,-38,0))
  if hit and hit.Position.Y<12 then
   local y=hit.Position.Y;local supported=true
   for _,dx in {-3,0,3}do for _,dz in {-3,0,3}do
    local h=ray(rb.Vector3.new(x+dx,y+.2,z+dz),rb.Vector3.new(0,-.4,0))
    if not h or math.abs(h.Position.Y-y)>.035 then supported=false end
   end end
   if supported then table.insert(out,{x,y+.02,z})end
  end
 end
 q:Destroy()
 end;require('@lune/task').wait()end
fs.writeFile('treasure/cave-sections/C5/POCKETS.json',serde.encode('json',out,true));print('supported pockets',#out)
fs.writeFile('treasure/cave-sections/C5/mounted-kitplan.txt',p.ServerScriptService.KitPlan.Source)
