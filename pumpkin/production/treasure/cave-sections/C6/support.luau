local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(p.Workspace.CaveV2,nil,4)
local errors={};local probes=0
for _,q in p.Workspace.CaveEscapeC6:GetChildren()do
 if q:IsA('BasePart')and(q:GetAttribute('C6Fallback')or q.Name:find('Foot'))then
  for _,x in {-1,-.5,0,.5,1}do for _,z in {-1,-.5,0,.5,1}do
   local foot=q.CFrame:PointToWorldSpace(rb.Vector3.new(x*q.Size.X/2,-q.Size.Y/2,z*q.Size.Z/2))
   local hit=ray(foot+rb.Vector3.new(0,.2,0),rb.Vector3.new(0,-2,0));probes+=1
   if not hit or math.abs(foot.Y-hit.Position.Y)>.035 then table.insert(errors,{part=q.Name,foot={foot.X,foot.Y,foot.Z},hit=hit and hit.Position.Y})end
  end;require('@lune/task').wait()end
 end
end
fs.writeFile('treasure/cave-sections/C6/SUPPORT.json',serde.encode('json',{probes=probes,errors=errors,state=#errors==0 and'PASS'or'FAIL'},true))
print('support probes',probes,'errors',#errors);assert(#errors==0)
