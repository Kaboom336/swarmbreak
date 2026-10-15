local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V,C=rb.Vector3,rb.CFrame
local root='prototype/cave-v2/'
local place=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local baseline=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-studio-pass.rbxl'))
local map,S=place.Workspace.CaveV2,place.ServerScriptService
for _,entry in {{'CaveCart','Cart.server'},{'CaveLoop','Loop.server'},{'CaveStudioPass','StudioPass.server'},{'CaveKits','Kits.server'},{'CaveDrops','Drops'},{'CaveReachableDrops','ReachableDrops'},{'CavePolicy','Policy'},{'KitPlan','KitPlan'}} do
 assert(S[entry[1]].Source==fs.readFile(root..entry[2]..'.luau'),'mounted source differs: '..entry[1])
end
assert(S.KitLibrary.Source==fs.readFile('prototype/kits/KitLibrary.luau'),'mounted kit loader differs')
assert(S.CaveCart.CaveRiderControls.Source==fs.readFile(root..'RiderControls.client.luau'),'mounted rider controls differ')
local cache={}
local function load(n)
 if cache[n] then return cache[n] end
 cache[n]=luau.load(n.Source,{environment={Vector3=V,CFrame=C,Enum=rb.Enum}})();return cache[n]
end
local D,Plan,P=load(S.CaveReachableDrops),load(S.KitPlan),load(S.CavePolicy)
local valid,validCache=D.valid,{}
D.valid=function(p,y,...)
 local key=string.format('%.17g:%.17g:%.17g',p.X,p.Z,y)
 if validCache[key]~=nil then return validCache[key] or nil end
 local value=valid(p,y,...);validCache[key]=value or false;return value
end
local data=load(place.ReplicatedStorage.CaveRouteData)
-- Scene preservation: exact children, transforms, shapes, visuals and physics;
-- only explicit floor attributes/tags change in the built artifact.
assert(rb.serializeModel({baseline.Lighting})==rb.serializeModel({place.Lighting}),'Lighting changed')
local oldChildren=baseline.Workspace.CaveV2:GetChildren()
assert(#map:GetChildren()==#oldChildren,'scene children changed')
for i,p in map:GetChildren() do
 local old=oldChildren[i]
 assert(p.Name==old.Name and p.ClassName==old.ClassName,'scene order')
 if p:IsA('BasePart') then
  for _,key in {'CFrame','Size','CanCollide','CanQuery','Transparency','Color','Material'} do
   if p.Name~='RouteRockButtress' and p.Name~='StackedMesaRock' then assert(p[key]==old[key],'scene property '..p.Name..':'..key) end
  end
  if p.Name=='RouteRockButtress' or p.Name=='StackedMesaRock' then assert(p.Size.X==old.Size.X and p.Size.Z==old.Size.Z and p.Size.Y<=old.Size.Y+.001 and p.Color==old.Color and p.Material==old.Material,'support trim exceeded scope') end
 end
end
for _,n in place:GetDescendants() do if n:IsA('LuaSourceContainer') then
 for level=0,2 do luau.compile(n.Source,{optimizationLevel=level}) end
 assert(not n.Source:match('%.RenderFidelity%s*='),'plugin-only RenderFidelity write')
end end
local entries=serde.decode('json',S.KitLibrary.Manifest.Value)
local expected=serde.decode('json',fs.readFile('assets/kits2/ROBLOX-ASSETS.json'))
assert(#entries==74 and #expected==74)
local byKey={};local meshes=0
for _,e in expected do byKey[e.island..'__'..e.name]=e;meshes+=e.meshParts end
for _,e in entries do assert(byKey[e.island..'__'..e.name].id==e.id,'manifest mismatch') end
assert(meshes==117,'textured mesh provenance')
local templates=rb.Instance.new('Folder');templates.Name='KitTemplates';templates:SetAttribute('Loaded',74);templates.Parent=place:FindFirstChild('ServerStorage')
if not templates.Parent then local storage=rb.Instance.new('ServerStorage');storage.Parent=place;templates.Parent=storage end
local Kit={init=function() end}
function Kit.spawn(name,island,base,scale)
 local entry=assert(byKey[island..'__'..name],name)
 local native=V.new(unpack(entry.size));local factor=scale
 if typeof(scale)=='Vector3' then factor=math.min(scale.X/native.X,scale.Y/native.Y,scale.Z/native.Z) end
 -- Match KitLibrary's island-prefixed template/clone name in the offline proxy.
 local m=rb.Instance.new('Model');m.Name=island..'__'..name
 for i=1,entry.meshParts do
  local p=rb.Instance.new('Part');p.Size=native*factor;p.CFrame=base*C.new(0,p.Size.Y/2,0);p.Anchored=true;p.CanQuery=false;p.CanCollide=false;p.Parent=m
 end
 return m
end
function Kit.fit(m,size,base)
 for _,p in m:GetChildren() do p.Size=size;p.CFrame=base*C.new(0,size.Y/2,0) end
 return true
end
local Ray=require('../meadow-v4/OfflineRay')
local solid=Ray.new(map,nil,4)
print('CHECKED native solid ray grid')
local lane=Ray.new(map,function(p) return p:GetAttribute('WalkableLaneFloor')==true end,4)
local groundRay=Ray.new(map,function(p) return not p:GetAttribute('WalkableLaneFloor') end,4)
local floorCount=#Plan.lanes(map);local rayCache={}
local function cast(_,o,d,params)
 local list=params and params.FilterDescendantsInstances
 local ray=solid
 if list and #list==0 then return nil end
 if list and list[1]~=map then
  if list[1]:GetAttribute('WalkableLaneFloor') then
   ray=lane
   if #list~=floorCount then
    local names,allowed={},{};for _,p in list do table.insert(names,p.Name);allowed[p]=true end
    table.sort(names);local key=table.concat(names,'|')
    if not rayCache[key] then rayCache[key]=Ray.new(map,function(p) return allowed[p] end,4) end
    ray=rayCache[key]
   end
  else ray=groundRay end
 end
 local hit=ray(o,d)
 if hit and hit.Instance:GetAttribute('WalkableLaneFloor') then hit.Instance=map:FindFirstChild(hit.Instance.Name) end
 return hit
end
local world={CaveV2=map,Raycast=cast}
local noopTask={wait=function() end}
local environment={Vector3=V,CFrame=C,Enum=rb.Enum,Instance=rb.Instance,Color3=rb.Color3,workspace=world,task=noopTask,
 RaycastParams={new=function() return {} end},print=print,warn=print}
local scriptObject={Parent=S}
local clear=Plan.laneClear;local traced=0
Plan.laneClear=function(parts,lanes)
 local ok,why=clear(parts,lanes)
 if not ok and parts[1] and parts[1].Parent.Name:find('kenney_nature-kit__fence_simple',1,true) and traced<3 then
  traced+=1;print('FENCE REJECT',parts[1].CFrame.Position,parts[1].Size,why)
 end
 return ok,why
end
environment.script=scriptObject
environment.require=function(n) return n==S.KitLibrary and Kit or n==S.KitPlan and Plan or load(n) end
luau.load(S.CaveKits.Source,{environment=environment})()
print('CHECKED kit swap source executed')
local lanes=Plan.lanes(map)
assert(Plan.laneClear(map.CaveKitDressing:GetDescendants(),lanes),'kits invade lane margin')
local actual,assetNames=0,{}
for _,m in map.CaveKitDressing:GetChildren() do actual+=1;assetNames[m.Name]=true end
for _,p in map.CaveKitDressing:GetDescendants() do if p:IsA('BasePart') then assert(not p.CanQuery and not p.CanCollide,'kit query/collision') end end
assert(actual>0,'no kits retained')
solid=Ray.new(map,nil,4);lane=Ray.new(map,function(p) return p:GetAttribute('WalkableLaneFloor')==true end,4)
-- Execute actual production Drops and live sampler, including independent solid
-- landings. Proxies bound whole material boxes; they do not invent mesh triangles.
local game={ReplicatedStorage=place.ReplicatedStorage,ServerStorage=place.ServerStorage}
game.GetService=function(_,name)
 if name=='RunService' then return {IsStudio=function() return true end} end
 if name=='HttpService' then return {JSONEncode=function(_,v) return serde.encode('json',v) end} end
end
environment.game=game;environment.script={Parent=S}
environment.require=function(n) if n==S.CaveReachableDrops then return D else return load(n) end end
local Drops=luau.load(S.CaveDrops.Source,{environment=environment})()
environment.require=function(n) return n==S.CaveDrops and Drops or load(n) end
local source=S.CaveStudioPass.Source
local cut=assert(source:find('local running = false',1,true))
local suites=luau.load(source:sub(1,cut-1)..'\nreturn suites',{environment=environment})()
suites.SelfTest()
assert(P.flight(24)=='Flight' and P.flight(12)=='Fall','flight threshold')
assert(P.canBlast(0,0,20,false) and not P.canBlast(1,0,20,false) and not P.canBlast(0,0,19,false) and not P.canBlast(0,0,20,true),'blast policy')
assert(P.canRepair(0,false,20) and not P.canRepair(1,false,20) and not P.canRepair(0,true,20) and not P.canRepair(0,false,19),'repair policy')
assert(Drops.floor(V.new(-100.3125,11,-7.1875)),'nearly coplanar ramp-end face hides flat lane')
local joint=V.new(150.625,51,-115)
local jointFloor=assert(Drops.floor(joint),'pass-2 main joint floor')
for _,knock in {-20,0,20} do
 local socket=assert(Drops.socket(joint+V.new(0,0,knock),jointFloor,joint),'pass-2 joint socket')
 assert(D.valid(socket,jointFloor.Y,Drops.laneRay,Drops.solidRay,V),'pass-2 joint repeated footprint')
end
if require('@lune/process').args[1]=='artifact-only' then
 print('PASS final mounted source parity, scene scope, kits2 bounds/query/fence joints, SelfTest, strict floor seam, policy')
 return
end
local routes={};for name,pts in data.routes do if name~='cartRail' then routes[name]={};for _,p in pts do table.insert(routes[name],{x=p[1],y=p[3],z=p[2]}) end end end
local total,failures=0,{}
local N=tonumber(require('@lune/process').args[1]) or 8
local function vec(p) return V.new(p[1],p[3],-p[2]) end
local reasons={}
for name,points in data.routes do if name~='cartRail' then
 for i=2,#points do
  local a,b=vec(points[i-1]),vec(points[i]);local side=V.new(-(b-a).Z,0,(b-a).X).Unit
  for j=0,N-1 do for _,edge in {-5,0,5} do
   local carrier=a:Lerp(b,(j+.5)/N)+side*edge+V.new(0,3,0);local floor=Drops.floor(carrier)
   for _,knock in {-20,0,20} do
    total+=1;local socket,why
    if floor then socket,why=Drops.socket(carrier+side*knock,floor,carrier) end
    if not socket or not D.valid(socket,floor.Y,Drops.laneRay,Drops.solidRay,V) then
     local reason=why or 'missing carrier floor';reasons[reason]=(reasons[reason] or 0)+1
     if #failures<30 then table.insert(failures,{lane=name,index=i,edge=edge,knock=knock,carrier={carrier.X,carrier.Y,carrier.Z},reason=reason}) end
    end
   end
  end end
 end
end end
local names={};for name in assetNames do table.insert(names,name) end;table.sort(names)
fs.writeFile(root..'STUDIO-OFFLINE.json',serde.encode('json',{N=N,samples=total,failures=failures,reasons=reasons,kitsRetained=actual,kitsRejected=map:GetAttribute('KitLanePlacementsDropped'),kitNames=names,floors=#lanes,templates=#entries,texturedMeshes=meshes},true))
print('CHECKED cave native+kit bounds samples',total,'failures',serde.encode('json',reasons),'kits',actual,'types',#names)
assert(next(reasons)==nil,'drop lattice failures: see STUDIO-OFFLINE.json')
print('PASS scene preservation, O0/O1/O2, manifest, kit clearance/query, stacked floor, policy, reachable drops')
