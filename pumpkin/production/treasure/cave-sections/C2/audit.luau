local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local tag=require('@lune/process').args[1]or'r1'
local p=rb.deserializePlace(fs.readFile('treasure/cave-sections/C2/'..tag..'-review.rbxl'))
local map=p.Workspace.CaveV2
local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(map,nil,4)
local lanes=Plan.lanes(map);local errors,support={},{};local count=0
for _,q in p.Workspace.CaveGeodeC2:GetChildren()do if q:IsA('BasePart')then
 count+=1
 local protected=lanes
 if q:GetAttribute('C2ApronShoulder')then
  local c,s=q.CFrame.Position,q.Size
  assert(c.X-s.X/2>=-133 and c.X+s.X/2<=-126 and c.Z-s.Z/2>=105 and c.Z+s.Z/2<=139,'apron shoulder exception')
  protected={};for _,lane in lanes do if lane.Name~='SafetyApron'then table.insert(protected,lane)end end
 end
 local clear,why=Plan.laneClear({q},protected);if not clear then table.insert(errors,{part=q.Name,lane=why})end
 assert(not q.CanCollide and not q.CanQuery and not q.CanTouch and q.Anchored)
 local c,s=q.CFrame.Position,q.Size
 assert(c.X-s.X/2>=100 and c.X+s.X/2<=244 and c.Y-s.Y/2>=30 and c.Y+s.Y/2<=120 and c.Z-s.Z/2>=-170 and c.Z+s.Z/2<=-90,'section bounds')
 if q:GetAttribute('C2Fallback')then
  for _,x in {-1,-.5,0,.5,1}do for _,z in {-1,-.5,0,.5,1}do
   local foot=q.CFrame:PointToWorldSpace(rb.Vector3.new(x*s.X/2,-s.Y/2,z*s.Z/2))
   local hit=ray(foot+rb.Vector3.new(0,.2,0),rb.Vector3.new(0,-2,0))
   if not hit or math.abs(foot.Y-hit.Position.Y)>.035 then table.insert(support,{part=q.Name,x=foot.X,z=foot.Z,bottom=foot.Y,hit=hit and hit.Position.Y})end
  end end
 end
 for _,l in q:GetChildren()do if l:IsA('PointLight')then assert(l.Brightness<=1.5 and l.Range<=18 and not l.Shadows)end end
end end
fs.writeFile('treasure/cave-sections/C2/AUDIT-'..tag..'.json',serde.encode('json',{parts=count,lanes=#lanes,lane_errors=errors,support_errors=support,flags=true},true))
print('C2 audit',tag,count,'lanes',#lanes,'lane failures',#errors,'support failures',#support)
assert(#errors==0 and #support==0,'see AUDIT JSON')
