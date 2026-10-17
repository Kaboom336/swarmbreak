local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local tag=require('@lune/process').args[1] or 'r1';local H='treasure/cave-sections/C8/'
local p=rb.deserializePlace(fs.readFile(H..tag..'-review.rbxl'));local root=p.Workspace.CaveEscapeC8
local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes=Plan.lanes(p.Workspace.CaveV2);local errors={};local count=0
local cameras=serde.decode('json',fs.readFile(H..'CAMERAS.json')).views
for _,q in root:GetChildren()do if q:IsA('BasePart')then
 count+=1
 local maxY=-math.huge
 for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
  local v=q.CFrame:PointToWorldSpace(q.Size*rb.Vector3.new(x,y,z)/2);maxY=math.max(maxY,v.Y)
  assert(v.X>=-479.001 and v.X<=559.001 and v.Y>=-251.832 and v.Y<=292.501 and v.Z>=-701.751 and v.Z<=239.001,'C8 bounds '..q.Name..' '..tostring(v))
 end end end
 local reserve={}
 for _,lane in lanes do
  local cf,s=lane.CFrame,lane.Size
  local bottom=cf.Y-(math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z)/2
  if maxY>=bottom-16 then table.insert(reserve,lane)end
 end
 local ok,why=Plan.laneClear({q},reserve);if not ok then table.insert(errors,{part=q.Name,lane=why})end
 assert(q.Anchored and not q.CanCollide and not q.CanQuery and not q.CanTouch,'flags')
 for _,v in cameras do local e=q.CFrame:PointToObjectSpace(rb.Vector3.new(unpack(v.eye)));local h=q.Size/2;assert(math.abs(e.X)>=h.X or math.abs(e.Y)>=h.Y or math.abs(e.Z)>=h.Z,'camera inside new art')end
 assert(#q:GetChildren()==0,'unexpected light/effect in static silhouette')
end end
local frozen=serde.decode('json',fs.readFile(H..'r1-plan.json'));local plan=serde.decode('json',fs.readFile(H..tag..'-plan.json'))
for i,g in frozen do assert(serde.encode('json',g)==serde.encode('json',plan[i]),'R1 changed')end
fs.writeFile(H..'AUDIT-'..tag..'.json',serde.encode('json',{state=#errors==0 and 'PASS' or 'FAIL',parts=count,lanes=#lanes,lane_errors=errors,bounds=true,flags=true,new_lights=0,player_eyes_clear_of_new_art=true,r1_frozen=#frozen,reserve='3D: full shell at least 16 below floor bottom, else unchanged horizontal Plan.laneClear'},true))
print('C8 audit',tag,'parts',count,'lane errors',#errors);assert(#errors==0)
