local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local sss=rb.Instance.new("Folder");sss:SetAttribute("DropSampleTestN",4)
local http={JSONEncode=function(_,v) return serde.encode("json",v) end,JSONDecode=function(_,v) return serde.decode("json",v) end}
local routes={test={{x=0,y=0,z=0},{x=20,y=0,z=0}}}
local drops={connected=function() return true end,segment=function() return {} end}
local rs={MeadowV4={ReachableDrops={},RouteData={}}}
local messages={}
local p=rb.Instance.new("Part");p.Name="Landing";p:AddTag("AuthoredLaneFloor")
local sample=luau.load(fs.readFile("slice-v2/prototype/DropSampleTest.luau"),{environment={
 game={GetService=function(_,name) return if name=="ServerScriptService" then sss elseif name=="HttpService" then http else rs end},
 require=function(node) return if node==rs.MeadowV4.RouteData then routes else drops end,
 workspace={Raycast=function(_,o) return {Instance=p,Position=rb.Vector3.new(o.X,0,o.Z)} end},
 RaycastParams={new=function() return {} end},Enum=rb.Enum,Vector3=rb.Vector3,task={wait=function() end},
 warn=function(message) table.insert(messages,message) end,
}})()
local arena={origin=rb.Vector3.zero,v4={GetAttribute=function() return 1 end,GetDescendants=function() return {} end}}
local ok=pcall(sample.run,arena,{carrierFloor=function() return nil end})
assert(not ok and #messages==30,"failure log cap")
assert(sss:GetAttribute("DropSampleTestFailureCount")==36,"failure total")
local rows=serde.decode("json",sss:GetAttribute("DropSampleTestFailures"))
assert(#rows==1 and rows[1].count==36 and #rows[1].samples==3 and rows[1].laneId=="test" and rows[1].landingInstance:find("Landing"),"grouped failure JSON")
messages={}
assert(sample.run(arena,{carrierFloor=function(_,v) return rb.Vector3.new(v.X,0,v.Z) end,dropSocket=function(_,v) return rb.Vector3.new(v.X,0,v.Z) end}))
assert(#messages==0 and sss:GetAttribute("DropSampleTestFailureCount")==0,"success must be silent and reset stale failures")
local source=fs.readFile("slice-v2/prototype/LoopTest.luau")
local first=assert(source:find("local function updateDrop",1,true));local last=assert(source:find("local Config",first,true))
local update=luau.load(source:sub(first,last-1).."\nreturn updateDrop",{environment={SSS=sss,game={GetService=function() return http end}}})()
local snapshot={carrierPos={1,3,2},carrierFloorY=0,laneId="spiral/21",landingInstance="Floor",landingY=0,lootPos={2,0,2},recoverPath={},reason="drop"}
sss:SetAttribute("GreyboxLoopTestLastDrop",http:JSONEncode(snapshot))
update({recoverPath={{position={1,0,2}}},reason="path recovery >30s"})
local result=http:JSONDecode(sss:GetAttribute("GreyboxLoopTestLastDrop"))
assert(result.carrierFloorY==0 and result.carrierPos[2]==3 and #result.recoverPath==1 and result.reason=="path recovery >30s","snapshot survives watchdog update")
print("PASS failure cap=30, grouped JSON=36 failures/3 positions, silent success/reset, persisted drop/path/watchdog fields")
local Plan=luau.load(fs.readFile("prototype/kits/Plan.luau"),{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local lane=rb.Instance.new("Part");lane.Size=rb.Vector3.new(18,1,40);lane.CFrame=rb.CFrame.identity
local safe=rb.Instance.new("Part");safe.Size=rb.Vector3.new(2,2,2);safe.CFrame=rb.CFrame.new(12,1,0)
local extra=rb.Instance.new("Part");extra.Size=safe.Size;extra.CFrame=rb.CFrame.new(10.5,20,0)
assert(Plan.laneClear({safe},{lane}),"clear placement rejected")
assert(not Plan.laneClear({safe,extra},{lane}),"extra kits2 material component / stacked footprint escaped margin")
extra.CFrame=rb.CFrame.new(11,1,0)
assert(not Plan.laneClear({extra},{lane}),"one-stud lane-edge margin must be clear")
print("PASS every-component kit footprint, stacked lane footprint and one-stud edge margin")
