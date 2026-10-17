local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local tag=require('@lune/process').args[1]or'r1';local H='treasure/cave-sections/C6/'
local p=rb.deserializePlace(fs.readFile(H..tag..'-review.rbxl'));local root=p.Workspace.CaveEscapeC6
local Plan=luau.load(p.ServerScriptService.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lanes=Plan.lanes(p.Workspace.CaveV2);local errors={};local count=0
local cameras=serde.decode('json',fs.readFile(H..'CAMERAS.json')).views
for _,q in root:GetChildren()do if q:IsA('BasePart')then
 count+=1;local ok,why=Plan.laneClear({q},lanes);if not ok then table.insert(errors,{part=q.Name,lane=why})end
 assert(q.Anchored and not q.CanCollide and not q.CanQuery and not q.CanTouch,'flags')
 for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
  local v=q.CFrame:PointToWorldSpace(q.Size*rb.Vector3.new(x,y,z)/2)
  assert(v.X>=-205 and v.X<=145 and v.Y>=-20 and v.Y<=66 and v.Z>=-160 and v.Z<=100,'bounds '..q.Name)
 end end end
 for _,v in cameras do if v.name~='overview'then local e=q.CFrame:PointToObjectSpace(rb.Vector3.new(unpack(v.eye)));local h=q.Size/2;assert(math.abs(e.X)>=h.X or math.abs(e.Y)>=h.Y or math.abs(e.Z)>=h.Z,'eye inside new art')end end
 for _,l in q:GetChildren()do if l:IsA('PointLight')then assert(l.Brightness<=1.5 and l.Range<=18 and not l.Shadows)end end
end end
local frozen=serde.decode('json',fs.readFile(H..'r1-plan.json'));local plan=serde.decode('json',fs.readFile(H..tag..'-plan.json'))
for i,g in frozen do assert(serde.encode('json',g)==serde.encode('json',plan[i]),'R1 changed')end
fs.writeFile(H..'AUDIT-'..tag..'.json',serde.encode('json',{state=#errors==0 and'PASS'or'FAIL',parts=count,lanes=#lanes,lane_errors=errors,bounds=true,flags=true,light_caps=true,player_eyes_clear_of_new_art=true,r1_frozen=#frozen},true))
print('C6 audit',tag,'parts',count,'lane errors',#errors);assert(#errors==0)
