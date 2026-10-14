-- Fresh full-width manifest audit + actual production builder/adapter execution.
-- No Studio physics, visual judgement, device or fun claims.
local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local V,C=rb.Vector3,rb.CFrame
local base="prototype/meadow-v4/"
local scene=serde.decode("json",fs.readFile(base.."scene.json"))
local modules={}
local env={Instance=rb.Instance,Vector3=V,CFrame=C,Color3=rb.Color3,Enum=rb.Enum}
env.script={Parent={Data="Data",Builder="Builder",RouteData="RouteData",Gameplay="Gameplay"}}
env.require=function(n) return assert(modules[n],"module "..tostring(n)) end
for _,pair in {{"Data","MeadowV4Data"},{"RouteData","RouteData"},{"Builder","MeadowV4"},{"Gameplay","Gameplay"},{"Loader","Loader"}} do
    modules[pair[1]]=luau.load(fs.readFile(base..pair[2]..".luau"),{environment=env})()
end
assert(#modules.Data==#scene.parts,"Data/scene part count")
for i,p in scene.parts do
    local d=modules.Data[i]
    assert(d.name==p.name and d.collidable==p.collidable,"Data identity/collision")
    for k=1,3 do assert(math.abs(d.position[k]-p.position[k])<=.0001 and math.abs(d.size[k]-p.size[k])<=.0001,"Data geometry "..p.name) end
    for k=1,9 do assert(math.abs(d.rotation[k]-p.rotation[k])<=.0001,"Data rotation") end
end
for name,route in scene.routes do
    local actual=modules.RouteData[name]
    assert(#actual==#route.points,"route length "..name)
    for i,p in route.points do assert(math.abs(actual[i].x-p[1])<.0001 and math.abs(actual[i].z-p[2])<.0001 and math.abs(actual[i].y-p[3])<.0001,"route parity "..name) end
end
local ws=rb.Instance.new("Workspace");ws:SetAttribute("UseMeadowV4",true)
env.workspace=ws
local config=luau.load(fs.readFile("slice-v2/prototype/GreyboxConfig.luau"),{environment=env})()
local G=modules.Gameplay
assert(config.Nest.y==48 and config.Nest.z==96 and config.GuardianGuardOffset.y==48 and config.EntryZ==-136,"coordinate migration")
local layout={};G.install(layout);layout.validate(config,G.assemble(config,1))
local parent=rb.Instance.new("Model");parent.Parent=ws
local old=rb.Instance.new("Model");old.Name="I02";old.Parent=parent
local guard=rb.Instance.new("Part");guard.Name="Guardian";guard.Parent=old
local arm=rb.Instance.new("Part");arm.Name="ThrowArm";arm.Parent=old
local portal=rb.Instance.new("Part");portal.Name="ReturnPortal";portal.Parent=parent
local origin=V.new(config.MeadowX,config.MeadowHeight,config.MeadowZ)
local legacyCalled=false
local wrapenv=table.clone(env)
modules.Loader=luau.load(fs.readFile(base.."Loader.luau"),{environment=wrapenv})()
local switch=modules.Loader.wrap(function() legacyCalled=true end)
local map=switch(parent,origin,{},function() end)
assert(guard.Parent==parent and arm.Parent==parent and portal.Parent==parent,"live handle preservation")
assert(not map:FindFirstChild("KeeperCoat") and not map:FindFirstChild("GoldenAcorn"),"no duplicate objective/stand-in")
assert(parent:GetAttribute("MeadowV4CoordinateMigrationRequired")==false,"migration gate")
local counts=0
for _,p in map:GetChildren() do
    counts+=1
    assert(p.Anchored and not p.CanTouch,"native flags")
end
ws:SetAttribute("UseMeadowV4",false);switch(parent,origin,{},function() end)
assert(legacyCalled,"flag off fallback")
local acorn=rb.Instance.new("Part");acorn.Parent=parent
G.decorate(acorn)
assert(acorn:FindFirstChild("AcornCap") and acorn:FindFirstChild("AcornStem"),"authored acorn")
-- Spatially indexed exact vertical OBB interval audit (same math as audit.py).
local grid={}
for i,p in scene.parts do
    if p.collidable then
        local loX,hiX,loZ,hiZ=math.huge,-math.huge,math.huge,-math.huge
        local r,s,o=p.rotation,p.size,p.position
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            local px=o[1]+(r[1]*s[1]*x+r[2]*s[2]*y+r[3]*s[3]*z)/2
            local pz=o[3]+(r[7]*s[1]*x+r[8]*s[2]*y+r[9]*s[3]*z)/2
            loX=math.min(loX,px);hiX=math.max(hiX,px);loZ=math.min(loZ,pz);hiZ=math.max(hiZ,pz)
        end end end
        for x=math.floor(loX/16),math.floor(hiX/16) do for z=math.floor(loZ/16),math.floor(hiZ/16) do
            local key=string.format("%d:%d",x,z);grid[key]=grid[key] or {};table.insert(grid[key],i)
        end end
    end
end
local function vertical(p,x,z)
    local r,o,s=p.rotation,p.position,p.size
    local lo,hi=-1000,1000
    for j=1,3 do
        local a=r[j]*(x-o[1])+r[3+j]*(-o[2])+r[6+j]*(z-o[3])
        local d=r[3+j]
        if math.abs(d)<1e-9 then
            if math.abs(a)>s[j]/2+.001 then return end
        else
            local q,b=(-s[j]/2-a)/d,(s[j]/2-a)/d
            lo=math.max(lo,math.min(q,b));hi=math.min(hi,math.max(q,b))
            if hi<lo then return end
        end
    end
    return lo,hi
end
local samples,violations=0,{}
local function sample(name,x,z,y)
    samples+=1
    local support=false;local blocked=false
    for _,i in grid[string.format("%d:%d",math.floor(x/16),math.floor(-z/16))] or {} do
        local lo,hi=vertical(scene.parts[i],x,-z)
        if lo then
            if math.abs(hi-y)<=.75 then support=true end
            if hi>y+.75 and lo<y+20 and hi>y+.1 then blocked=true end
        end
    end
    if not support or blocked then table.insert(violations,{route=name,x=x,z=z,y=y,blocked=blocked}) end
end
local timing={};local maxGrade=0
-- Execute actual Arena floor/drop/safe/outside at the retained world origin.
local Arena
local world={}
function world:Raycast(position,direction)
    local localP=position-origin
    assert(direction.X==0 and direction.Z==0,"only vertical floor/body casts in this fixture")
    local best,distance=nil,math.huge
    for _,i in grid[string.format("%d:%d",math.floor(localP.X/16),math.floor(localP.Z/16))] or {} do
        local p=scene.parts[i];local lo,hi=vertical(p,localP.X,localP.Z)
        if lo then
            local y=direction.Y<0 and hi or lo
            local t=(y-localP.Y)/direction.Y
            if t>=0 and t<=1 and t<distance then
                local category=p.category
                local cover=category=="cover" or category=="boulder" or category=="tunnel_rock" or category=="tunnel_roof" or category=="tunnel_hill"
                best={Position=origin+V.new(localP.X,y,localP.Z),Normal=V.new(p.rotation[2],p.rotation[5],p.rotation[8]),
                    Instance={GetAttribute=function() return cover and "Cover" or "Floor" end}}
                distance=t
            end
        end
    end
    return best
end
local arenaEnv=table.clone(env)
arenaEnv.workspace=world
arenaEnv.game={GetService=function() return {WaitForChild=function(_,name) return name end} end}
arenaEnv.require=function(n) return ({GreyboxConfig=config,GreyboxLayout=layout,GreyboxScene={}})[n] end
Arena=luau.load(fs.readFile("slice-v2/prototype/Arena.luau"),{environment=arenaEnv})()
local a={origin=origin,layout=G.assemble(config,1),params={}}
local summit=assert(Arena.floor(a,origin+V.new(0,51,-96)))
assert(math.abs(summit.Y-origin.Y-48)<.75,"production summit floor")
local tunnel=assert(Arena.floor(a,origin+V.new(-76,3,40)))
assert(tunnel.Y-origin.Y<1,"production below-roof floor")
local socket=Arena.dropSocket(a,origin+V.new(-76,3,40))
assert(socket.Y-origin.Y<1 and (socket-tunnel).Magnitude<3,"production tunnel drop stays inside")
for _,p in {V.new(40,-4,24),V.new(-42,-4,24),V.new(40,-4,-24)} do
    local rim=Arena.dropSocket(a,origin+p)
    assert(math.abs(rim.Z-origin.Z-p.Z)<4 and math.abs(rim.X-origin.X-p.X)<4,"production rim projection")
end
assert(not Arena.outside(a,origin+V.new(-22,-29,0)),"ravine floor must not teleport")
assert(Arena.outside(a,origin+V.new(0,-46,0)),"outside fall recovery threshold")
assert(Arena.safe(a,origin+V.new(0,3,136)) and not Arena.safe(a,origin+V.new(-32,3,136)),"south safe rectangle")
local contactActor={}
local contacted=false
local guardFixture={origin=origin,guardian={Position=origin+V.new(-76,5.5,78)},
    tunnelGuard={waiting=true,exit=origin+V.new(-76,0,78)}}
Arena.tick(guardFixture,.05,10,{},function() return {Position=origin+V.new(-76,3,78)} end,
    function(actor,_,source) assert(actor==contactActor and source=="TunnelGuard","exit contact source");contacted=true;return true end,
    function() end,{holder=contactActor})
assert(contacted,"Keeper guards actual tunnel mouth even while inside policy")
for name,route in scene.routes do
    local length=0;assert(route.width>=12,"route width")
    for i=2,#route.points do
        local a,b=route.points[i-1],route.points[i]
        local dx,dz,dy=b[1]-a[1],b[2]-a[2],b[3]-a[3]
        local run=math.sqrt(dx*dx+dz*dz)
        if run<.01 then continue end
        local grade=math.deg(math.atan(math.abs(dy)/run));maxGrade=math.max(maxGrade,grade)
        assert(grade<=25.001,"route grade "..name)
        length+=math.sqrt(run*run+dy*dy)
        local n,across=math.ceil(run),math.ceil(route.width)
        for step=0,n do for j=0,across do
            local t,side=step/n,-route.width/2+route.width*j/across
            sample(name,a[1]+dx*t-dz/run*side,a[2]+dz*t+dx/run*side,a[3]+dy*t)
        end end
    end
    timing[name]={length=length,walk_ESTIMATED=length/16,carry_ESTIMATED=length/13.5,width=route.width}
end
for _,court in {{"camp",0,108,48},{"fork",0,42,0},{"ridge",110,-60,20}} do
    for x=-12,12 do for z=-12,12 do sample(court[1],court[2]+x,court[3]+z,court[4]) end end
end
-- The automated test paths are independently checked for supported segments.
local function routeAudit(name,points)
    for i,p in points do
        local a=points[i-1] or p
        local length=math.sqrt((p.x-a.x)^2+(p.z-a.z)^2)
        for n=0,math.max(1,math.ceil(length)) do
            local t=n/math.max(1,math.ceil(length))
            sample(name,a.x+(p.x-a.x)*t,a.z+(p.z-a.z)*t,a.y+(p.y-a.y)*t)
        end
    end
end
routeAudit("test approach",G.approach());routeAudit("test carry",G.carry())
for name,route in G.pvpRoutes() do routeAudit("test PvP "..name,route) end
local graph=serde.decode("json",fs.readFile("treasure/map-v4/routes-graph.json"))
local adjacency={}
for _,node in graph.nodes do adjacency[node.id]={} end
for _,edge in graph.edges do
    local a,b=edge.from,edge.to
    table.insert(adjacency[a],b);table.insert(adjacency[b],a)
end
local reached={PORTAL=true};local queue={"PORTAL"}
for _,id in queue do for _,neighbor in adjacency[id] do if not reached[neighbor] then reached[neighbor]=true;table.insert(queue,neighbor) end end end
local dead,unreachable=0,0
for id,links in adjacency do
    if not reached[id] then unreachable+=1 end
    if #links<=1 and id~="SUMMIT" and id~="PORTAL" then dead+=1 end
end
assert(dead==0 and unreachable==0,"route graph")
-- Compile and compare every shipped module with its current project source.
local place=rb.deserializePlace(fs.readFile("prototype/guardian-greybox.rbxl"))
local project=serde.decode("json",fs.readFile("slice-v2/prototype/greybox.project.json"))
local containers=0
local function parity(instance,node)
    if node["$path"] then
        local path="slice-v2/prototype/"..node["$path"]
        if instance:IsA("LuaSourceContainer") then
            assert(instance.Source:gsub("\r\n","\n")==fs.readFile(path):gsub("\r\n","\n"),"built source parity "..path)
            for optimization=0,2 do luau.compile(instance.Source,{optimizationLevel=optimization}) end
            containers+=1
        end
    end
    for name,child in node do if name:sub(1,1)~="$" and type(child)=="table" then parity(assert(instance:FindFirstChild(name),name),child) end end
end
parity(place,project.tree)
local backup=rb.deserializePlace(fs.readFile("prototype/guardian-greybox.pre-v4.rbxl"))
for _,child in backup.ReplicatedStorage.MeadowKeeper:GetChildren() do
    if child:IsA("LuaSourceContainer") then
        assert(child.Source==place.ReplicatedStorage.MeadowKeeper:FindFirstChild(child.Name).Source,"current Keeper preserved "..child.Name)
    end
end
assert(backup.StarterPlayer.StarterPlayerScripts.MeadowKeeper.Source==place.StarterPlayer.StarterPlayerScripts.MeadowKeeper.Source,"Keeper client preserved")
assert(backup.ReplicatedStorage.HomeArtGeometry.Source==place.ReplicatedStorage.HomeArtGeometry.Source,"Home art geometry preserved")
assert(backup.StarterPlayer.StarterPlayerScripts.HomeArt.Source==place.StarterPlayer.StarterPlayerScripts.HomeArt.Source,"Home art client preserved")
assert(backup.ReplicatedStorage.GreyboxLootRules.Source==place.ReplicatedStorage.GreyboxLootRules.Source,"ownership rules preserved")
assert(place.Workspace:GetAttribute("UseMeadowV4")==true,"shipped switch")
assert(not place.ServerScriptService:FindFirstChild("MeadowV4Links"),"standalone links excluded")
for _,mode in {"GreyboxLoopTest","GreyboxPvpTest","GreyboxTrapTest"} do
    assert(place.ServerScriptService:GetAttribute(mode.."Success")==false,"no fabricated Studio PASS")
end
local report={state=#violations==0 and "PASS" or "FAIL",parts=#scene.parts,merged_geometry_parts=counts,
    samples=samples,violations=violations,max_grade=maxGrade,routes=timing,
    graph_dead_ends=dead,graph_unreachable=unreachable,compiled_containers=containers,Studio_runtime="UNKNOWN"}
fs.writeFile("prototype/MERGE-V4-OFFLINE.json",serde.encode("json",report,true))
print("Fresh audit",report.state,"parts",#scene.parts,"samples",samples,"violations",#violations,"graph",dead,unreachable,"compiled",containers)
for i=1,math.min(12,#violations) do print(serde.encode("json",violations[i])) end
assert(#violations==0,"clearance/test route audit")
