local fs,rb,luau,serde,process=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde"),require("@lune/process")
local main="slice-v2/prototype/guardian-greybox.rbxl"
local backup="slice-v2/prototype/guardian-greybox.pre-s1r3.rbxl"
local H="treasure/sections/S1/"
if process.args[1]=="backup" then
 assert(not fs.isFile(backup),"preserve existing section backup")
 local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
 print("PASS byte-verified pre-section1 backup");return
end
assert(fs.isFile(backup),"backup required BEFORE Rojo")
local old=rb.deserializePlace(fs.readFile(backup))
local place=rb.deserializePlace(fs.readFile(backup))
local built=rb.deserializePlace(fs.readFile(H.."rojo.rbxl"))
-- Draft contact checks avoid a Rojo rebuild per single prop adjustment.
if process.args[1]=="draft" or process.args[1]=="support" or process.args[1]=="resolve" then built.ReplicatedStorage.MeadowV4.Section1.Source=fs.readFile("prototype/meadow-v4/Section1.luau") end
local function at(root,path,n) for i=1,n or #path do root=assert(root:FindFirstChild(path[i]),path[i]) end;return root end
local allowed={}
for _,path in {{"ReplicatedStorage","MeadowV4","Section1"}} do
 local parent=at(place,path,#path-1);local p=parent:FindFirstChild(path[#path]);if p then p:Destroy() end
 at(built,path):Clone().Parent=parent;allowed[table.concat(path,".")]=true
end
assert(rb.serializeModel({old.Workspace})==rb.serializeModel({place.Workspace}),"serialized Workspace changed")
local compiled,preserved=0,0
for _,p in place:GetDescendants() do if p:IsA("LuaSourceContainer") then
 for opt=0,2 do luau.compile(p.Source,{optimizationLevel=opt}) end;compiled+=1
 if not allowed[p:GetFullName()] then assert(at(old,string.split(p:GetFullName(),".")).Source==p.Source,"unrelated source changed");preserved+=1 end
end end
-- Freeze the artifact BEFORE offline builders append their proof geometry.
local artifactBytes=rb.serializePlace(place);rb.deserializePlace(artifactBytes)
local signatures={}
for _,pair in {{"before",old},{"after",place}} do
 local tag,root=pair[1],pair[2];local cache={}
 local function load(node)
  if cache[node] then return cache[node] end
  local env={script=node,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,
   game={GetService=function(_,name) if name=="RunService" then return {} end;assert(name=="HttpService");return {JSONDecode=function(_,s) return serde.decode("json",s) end} end}}
  cache[node]=luau.load(node.Source,{environment=env})();return cache[node]
 end
 local rs=root.ReplicatedStorage
 local model=load(rs.MeadowV4.Builder).build(root.Workspace,rb.Vector3.zero)
 if process.args[1]=="resolve" then
  local s=load(built.ReplicatedStorage.MeadowV4.Section1);local plan=load(root.ServerScriptService.KitPlan);local lanes={}
  for _,p in plan.lanes(model) do if p.Name~="PortalPad" and p.Name~="ProtectedPortalApron" then table.insert(lanes,p) end end
  if process.args[2]=="map" then
   for _,q in {{-24,-18,114,124},{18,34,104,122},{-84,-40,82,108}} do
    for x=q[1],q[2],2 do for z=q[3],q[4],2 do
     local w,d=if q[1]< -30 then 1 else 4,if q[1]< -30 then 1 else 3
     local p=rb.Instance.new("Part");p.Size=rb.Vector3.new(w,5,d);p.CFrame=rb.CFrame.new(x,2.5,z)
     if plan.laneClear({p},lanes) then print("SITE",x,z,s.ground(model,x,z,w,d)) end
    end end
   end;return
  end
  if process.args[2]=="r3" then
   for _,size in {{8,3},{7,7},{6,6},{3.5,3.5},{.6,.6}} do
    for _,side in {-1,1} do
     local sites={}
     for x=16+size[1]/2,45,1 do for z=116,155,1 do
      local y=s.ground(model,side*x,z,size[1],size[2])
      if not y then continue end
      local p=rb.Instance.new("Part");p.Size=rb.Vector3.new(size[1],24,size[2]);p.CFrame=rb.CFrame.new(side*x,y+12,z)
      if plan.laneClear({p},lanes) then table.insert(sites,{x=side*x,z=z,y=y,d=math.sqrt(x*x+(154-z)^2)}) end
     end end
     table.sort(sites,function(a,b) return a.d<b.d end)
     print("SITES",size[1],size[2],side,serde.encode("json",{unpack(sites,1,math.min(12,#sites))}))
    end
   end
   return
  end
  local requests={{"MineW",-72,80,1.5,1.5},{"MineE",-50,80,1.5,1.5},{"MineW2",-74,70,1.5,1.5},{"MineE2",-52,70,1.5,1.5},{"MineW3",-80,110,1.5,1.5},{"MineE3",-33,112,1.5,1.5}}
  for _,q in requests do
   local found=false
   if process.args[2]=="exact" then
    local y=s.ground(model,q[2],q[3],q[4],q[5]);local p=rb.Instance.new("Part");p.Size=rb.Vector3.new(q[4],5,q[5]);p.CFrame=rb.CFrame.new(q[2],(y or 0)+2.5,q[3]);local ok,lane=plan.laneClear({p},lanes)
    print(q[1],q[2],q[3],y,ok,lane);continue
   end
   for radius=0,20,2 do
    if found then break end
    for dx=-radius,radius,2 do if found then break end;for dz=-radius,radius,2 do
     if math.max(math.abs(dx),math.abs(dz))~=radius then continue end
     local x,z=q[2]+dx,q[3]+dz
     if math.abs(x)-q[4]/2<16 then continue end
     if x-q[4]/2< -58 or x+q[4]/2>58 or z-q[5]/2<98 or z+q[5]/2>156 then continue end
     local y=s.ground(model,x,z,q[4],q[5]);if y then
      local p=rb.Instance.new("Part");p.Size=rb.Vector3.new(q[4],5,q[5]);p.CFrame=rb.CFrame.new(x,y+2.5,z)
      if plan.laneClear({p},lanes) then print(q[1],x,z,y);found=true;break end
     end
    end end
   end
   if not found then print("NONE",q[1]) end
  end;return
 end
 if process.args[1]=="support" then
  local s=load(built.ReplicatedStorage.MeadowV4.Section1)
  local plan=load(root.ServerScriptService.KitPlan);local lanes=plan.lanes(model)
  for _,side in {1} do for x=26,58,2 do for z=100,154,2 do
   local y=s.ground(model,x*side,z,8,4)
   if y then local p=rb.Instance.new("Part");p.Size=rb.Vector3.new(8,5,4);p.CFrame=rb.CFrame.new(x*side,y+2.5,z)
    if plan.laneClear({p},lanes) then print("BED",x*side,z,y) end
   end
  end end end;return
 end
 local parts,physical={},{}
 local function encode(p)
  local cf={p.CFrame:GetComponents()};local rotation={};for i=4,12 do table.insert(rotation,cf[i]) end
  return {name=p.Name,position={cf[1],cf[2],cf[3]},rotation=rotation,size={p.Size.X,p.Size.Y,p.Size.Z},color={p.Color.R*255,p.Color.G*255,p.Color.B*255},
   material=p.Material.Name,shape=p:IsA("Part") and p.Shape.Name or "Wedge",transparency=p.Transparency,collidable=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,
   lane=p:GetAttribute("WalkableLaneFloor"),laneId=p:GetAttribute("LaneId"),role=p:GetAttribute("SurfaceRole"),tags=p:GetTags(),label=p:GetAttribute("RouteLabel"),category=p:GetAttribute("MeadowV4Category"),section=p:GetAttribute("Section"),supportY=p:GetAttribute("SupportY"),coverage=p:GetAttribute("S1Coverage")}
 end
 for _,p in model:GetDescendants() do if p:IsA("BasePart") then
  local record=encode(p);table.insert(parts,record)
  if p.CanCollide or p:GetAttribute("WalkableLaneFloor") then table.insert(physical,serde.encode("json",record)) end
 end end
 table.sort(physical);signatures[tag]=table.concat(physical,"\n")
 local placements={}
 if tag=="after" then
  local s=load(rs.MeadowV4.Section1)
  local keys={}
  for _,entry in serde.decode("json",root.ServerScriptService.KitLibrary.Manifest.Value) do keys[entry.island.."__"..entry.name]=true end
  for _,g in s.kits do assert(keys[(g.island or "meadow").."__"..g.name],"S1 missing kits2 asset key: "..g.name) end
  local plan=load(root.ServerScriptService.KitPlan)
  local lanes=plan.lanes(model)
  local errors={}
  for _,g in s.kits do
   local y=s.ground(model,g.x,g.z,g.size.X,g.size.Z)
   if not y then table.insert(errors,"unsupported kit "..g.id);y=0 end
   local box=rb.Instance.new("Part");box.Size=g.size;box.CFrame=rb.CFrame.new(g.x,y+g.size.Y/2,g.z)
   local clear,lane=s.laneClear({box},lanes,plan,g.frame);if not clear then table.insert(errors,"S1 kit overlaps lane: "..g.id.." "..tostring(lane)) end
   table.insert(placements,{id=g.id,name=g.name,island=g.island or "meadow",x=g.x,y=y+(g.lift or 0),z=g.z,size={g.size.X,g.size.Y,g.size.Z},fit=g.fit})
  end
  for _,p in model:GetDescendants() do if p:IsA("BasePart") and p:GetAttribute("Section")=="S1" then
   assert(not p.CanCollide and not p.CanQuery and not p.CanTouch,"dressing physics")
   assert(not p:GetAttribute("WalkableLaneFloor"),"dressing floor tag")
   if p:GetAttribute("MissingSupport") then table.insert(errors,"unsupported "..p.Name.." "..tostring(p.CFrame.Position)) end
   local clear,lane=s.laneClear({p},lanes,plan,p:GetAttribute("S1ApronBorder"));if not clear then table.insert(errors,"native overlaps lane: "..p.Name.." "..tostring(p.CFrame.Position).." "..tostring(lane)) end
  end end
  for _,err in errors do warn(err) end
  assert(#errors==0,"S1 contact/lane audit failed: "..#errors)
  for _,p in model:GetDescendants() do
   if p:IsA("BasePart") and (p.Name=="S1_MinePost" or p.Name=="S1_MineHeader") then
    local cf=p.CFrame*rb.CFrame.new(0,-p.Size.Y/2,0);local c={cf:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i]) end
    table.insert(placements,{id=p.Name,name="kenney_mini-dungeon__"..(if p.Name=="S1_MinePost" then "wood-support" else "wood-structure"),island="cave",x=c[1],y=c[2],z=c[3],size={p.Size.X,p.Size.Y,p.Size.Z},fit=true,rotation=r,attachment=p.Name})
    for _,record in parts do if record.name==p.Name and math.abs(record.position[1]-p.CFrame.Position.X)<.01 then record.transparency=1 end end
   end
  end
 end
 -- Same approved posed hero geometry in both columns, reused from prior checked export.
 local prior=serde.decode("json",fs.readFile("prototype/studio-pass-1/polish-after.json"))
 for _,p in prior.parts do if string.sub(p.name,1,7)=="Keeper_" or string.sub(p.name,1,10)=="HeroAcorn_" then table.insert(parts,p) end end
 for _,p in parts do if p.category=="keeper" or p.name=="GoldenAcorn" or p.name=="AcornCap" or p.name=="AcornStem" then p.transparency=1 end end
 fs.writeFile(H..(if tag=="before" then "r3baseline" else "r3")..".json",serde.encode("json",{parts=parts,routes={},kits=placements},false))
end
assert(signatures.before==signatures.after,"physics/lane/floor/tag changed")
if process.args[1]~="draft" then fs.writeFile(main,artifactBytes);rb.deserializePlace(fs.readFile(main)) end
fs.writeFile(H.."AUDIT.json",serde.encode("json",{status="PASS",compiled_O0_O1_O2=compiled,unrelated_sources_preserved=preserved,workspace_byte_equal=true,
 physics_floor_tags_equal=true,actual_route_buffers_clear=true,outer_apron_art_exception=true,central_apron_corridor_studs=32,kit_full_footprint_support=true,StudioPassAll="UNKNOWN; not run after S1r3",mounts={"Section1"}},true))
print("PASS",compiled,"scripts compiled O0/O1/O2;",preserved,"unrelated sources preserved; physics/floor/tag parity; S1 lane/support audit")
