-- Production Swap with conservative kits2 bounding proxies, then the exact live
-- N=8 lattice and resolver. Mesh triangles/navmesh/Studio physics remain UNKNOWN.
local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local V,C=rb.Vector3,rb.CFrame
local Ray=require("./meadow-v4/OfflineRay")
local place=rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"))
local cache={}
local function load(node)
 if cache[node] then return cache[node] end
 cache[node]=luau.load(node.Source,{environment={script=node,require=load,Vector3=V,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance}})()
 return cache[node]
end
local rs=place.ReplicatedStorage
local D,R=load(rs.MeadowV4.ReachableDrops),load(rs.MeadowV4.RouteData)
local model=load(rs.MeadowV4.Builder).build(place.Workspace,V.zero)
print("built native geometry")
for _,p in model:GetChildren() do
 local cat=p:GetAttribute("MeadowV4Category")
 if cat=="keeper" or p.Name=="GoldenAcorn" or p.Name=="AcornCap" or p.Name=="AcornStem" then p:Destroy() end
end
local Plan=load(place.ServerScriptService.KitPlan)
local kit={templates={},init=function() end}
local entries=serde.decode("json",fs.readFile("assets/kits2/ROBLOX-ASSETS.json"))
local mounted=serde.decode("json",place.ServerScriptService.KitLibrary.Manifest.Value)
assert(#mounted==74 and #entries==74,"kits2 template count")
local byKey={}
for _,e in entries do
 local key=e.island.."__"..e.name;byKey[key]=e
 local t=rb.Instance.new("Model");t:SetAttribute("KitNativeSize",V.new(unpack(e.size)));kit.templates[key]=t
end
for _,e in mounted do
 local expected=assert(byKey[e.island.."__"..e.name]);assert(e.id==expected.id and e.meshParts==expected.meshParts,"stale kits manifest")
end
local spawned=0
function kit.spawn(name,island,base,scale)
 local e=assert(byKey[island.."__"..name],name)
 local native=V.new(unpack(e.size));local factor=scale or 1
 if typeof(factor)=="Vector3" then factor=math.min(factor.X/native.X,factor.Y/native.Y,factor.Z/native.Z) end
 local m=rb.Instance.new("Model");m.Name=name;m:SetAttribute("KitTriangles",e.triangles)
 -- Each material occupies the whole model box: conservative rather than
 -- inventing unavailable per-material imported bounds.
 for i=1,e.meshParts do
  local p=rb.Instance.new("Part");p.Name="kits2Bound"..i;p.Size=native*factor
  p.CFrame=base*C.new(0,p.Size.Y/2,0);p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.Parent=m
 end
 spawned+=1;return m
end
function kit.fit(m,size,frame)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Size=size;p.CFrame=frame*C.new(0,size.Y/2,0) end end
 return true
end
local scriptObject={Parent={KitLibrary={},KitPlan={}}}
local source=place.ServerScriptService.KitSwap.Source
source=source:sub(1,assert(source:find("local function watch",1,true))-1).."\nreturn apply"
local apply=luau.load(source,{environment={script=scriptObject,require=function(n) return if n==scriptObject.Parent.KitLibrary then kit else Plan end,
 game={GetService=function() return {GetTotalMemoryUsageMb=function() return 10 end} end},workspace=place.Workspace,
 Instance=rb.Instance,Vector3=V,CFrame=C,Enum=rb.Enum,warn=function() end}})()
apply(model,"meadow")
local lanes=Plan.lanes(model)
assert(Plan.laneClear(model.KitDressing:GetDescendants(),lanes),"kit footprint within lane margin")
for _,p in model.KitDressing:GetDescendants() do if p:IsA("BasePart") then assert(not p.CanCollide and not p.CanQuery,"kit query/collision") end end
local solid=Ray.new(model,nil,2)
local lane=Ray.new(model,function(p) return p:GetAttribute("WalkableLaneFloor")==true end,2)
-- Geometry is immutable throughout this offline run. Memoize exact float32
-- candidate coordinates so repeated edge/knock searches reuse identical tests.
local valid=D.valid
local validCache={}
local cacheHits=0
D.valid=function(p,y,...)
 local key=string.format("%.9g:%.9g:%.9g",p.X,p.Z,y)
 if validCache[key]~=nil then cacheHits+=1;return validCache[key] or nil end
 local result=valid(p,y,...);validCache[key]=result or false;return result
end
local cfg=luau.load(rs.GreyboxConfig.Source,{environment={workspace=place.Workspace}})()
local arenaModule=luau.load(place.ServerScriptService.GreyboxArena.Source,{environment={
 Vector3=V,Enum=rb.Enum,Color3=rb.Color3,RaycastParams={new=function() return {} end},
 game={GetService=function(_,name) return if name=="ReplicatedStorage" then setmetatable({WaitForChild=function(_,child) return rs[child] end},{__index=function(_,child) return rs[child] end}) else {} end},
 require=function(node) if node==rs.GreyboxConfig then return cfg end;if node==rs.GreyboxLayout or node==rs.GreyboxScene then return {} end;return load(node) end,
 workspace={Raycast=function(_,o,d,params) return (if params.FilterType==rb.Enum.RaycastFilterType.Include then lane else solid)(o,d) end},warn=function() end,
}})()
local arena={v4=model,origin=V.zero,params={},samplingDrops=true}
local failures,total,counts={},0,{}
local function fail(label,p,reason)
 table.insert(failures,{label=label,position={p.X,p.Y,p.Z},reason=reason})
 counts[reason]=(counts[reason] or 0)+1
end
for name,route in R do
 for i=2,#route do
  local u,v=route[i-1],route[i]
  local a,b=V.new(u.x,u.y,-u.z),V.new(v.x,v.y,-v.z)
  local forward=V.new(b.X-a.X,0,b.Z-a.Z).Unit;local side=V.new(-forward.Z,0,forward.X)
  for j=0,7 do for _,edge in {-5,0,5} do
   local pose=a:Lerp(b,(j+0.5)/8)+side*edge
   local floor=arenaModule.carrierFloor(arena,pose+V.new(0,3,0))
   for _,knock in {-20,0,20} do
    total+=1;local label=name.."/"..i.."/"..j.."/"..edge.."/"..knock
    if total%1000==0 then print("progress",total,"failures",#failures) end
    if not floor then fail(label,pose,"no lane floor at carrier") else
     local socket,why=arenaModule.dropSocket(arena,pose+side*knock+V.new(0,3,0),floor)
     if not socket then fail(label,pose,why) else
      local hit=solid(socket+V.new(0,8.25,0),V.new(0,-10.45,0))
      if not hit or not hit.Instance:HasTag("AuthoredLaneFloor") or math.abs(hit.Position.Y-socket.Y)>0.1
       or math.abs(socket.Y-floor.Y)>2 or not D.connected(D.segment(floor,arena.laneGraph),D.segment(socket,arena.laneGraph)) then
       fail(label,socket,"landing differs from carrier lane / blocked surface")
      end
     end
    end
   end
  end end
 end
 print("sampled",name,total,"failures",#failures)
end
local report={state=if #failures==0 then "PASS" else "FAIL",samples=total,failures=failures,categories=counts,
 validCacheHits=cacheHits,
 kits2Templates=#entries,spawnAttempts=spawned,droppedPlacements=model:GetAttribute("KitLanePlacementsDropped"),
 keptPlacements=model:GetAttribute("KitSwapped"),bounds="conservative whole-model boxes per material; actual imported geometry UNKNOWN",Studio="UNKNOWN"}
fs.writeFile("prototype/FIX6-DROPS.json",serde.encode("json",report,true))
print(report.state,total,"samples",#failures,"failures; dropped kit placements",report.droppedPlacements)
assert(#failures==0,"fix6 drop lattice")
