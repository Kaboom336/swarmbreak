local fs,rb,luau,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/process')
local target='prototype/cave-v2.rbxl'
local backup='prototype/cave-v2.pre-studio-pass.rbxl'
if process.args[1]=='backup' then
 assert(not fs.isFile(backup),'refuse backup overwrite')
 local bytes=fs.readFile(target);rb.deserializePlace(bytes);fs.writeFile(backup,bytes)
 assert(fs.readFile(backup)==bytes);print('PASS byte-verified cave backup');return
end
assert(fs.isFile(backup),'backup required before Rojo')
local place=rb.deserializePlace(fs.readFile(backup))
local source=rb.deserializePlace(fs.readFile('prototype/cave-v2/studio-rojo.rbxl'))
local server=place.ServerScriptService
for _,n in source.ServerScriptService:GetChildren() do
 local old=server:FindFirstChild(n.Name);if old then old:Destroy() end
 n:Clone().Parent=server
end
-- Disable the old generic swap, whose cave path predates lane exclusion.
local old=server:FindFirstChild('KitSwap');if old then old:Destroy() end
local serde=require('@lune/serde')
local kit=serde.decode('json',fs.readFile('prototype/cave-v2/CONNECT-KIT.json'))
local bays={}
for _,contact in kit.contacts do if contact.kind=='fence' then
 local id=table.concat(contact.parts,',')
 bays[id]=bays[id] or {rails=contact.parts,posts={}}
 bays[id].posts[tostring(contact.target)]=contact.target
end end
local fenceData={}
for _,bay in bays do local posts={};for _,index in bay.posts do table.insert(posts,index) end;table.sort(posts)
 assert(#posts==2,'fence must have two joint posts');table.insert(fenceData,{rails=bay.rails,posts=posts})
end
table.sort(fenceData,function(a,b) return a.rails[1]<b.rails[1] end)
local fence=server:FindFirstChild('CaveFenceData') or rb.Instance.new('ModuleScript');fence.Name='CaveFenceData';fence.Parent=server
fence.Source='return '..serde.encode('json',fenceData):gsub('"(%w+)":','%1='):gsub('%[','{'):gsub('%]','}')
-- Deduplicate the two rail courses by their shared endpoint pair at runtime.
local routes=require('@lune/luau').load(place.ReplicatedStorage.CaveRouteData.Source)().routes
local count=0
for _,p in place.Workspace.CaveV2:GetChildren() do
 if not p:IsA('BasePart') then continue end
 local route=p.Name:match('^(.-)%d+$')
 local lane=p.CanCollide and p:GetAttribute('CaveCategory')=='lane'
  and (routes[route]~=nil or p.Name=='GeodeCamp' or p.Name=='SafetyApron' or p.Name=='PitFloor' or p.Name=='BroadLanding' or p.Name=='PaddedSidingFloor')
 p:SetAttribute('WalkableLaneFloor',lane);p:SetAttribute('Walkable',lane)
 if lane then p:AddTag('AuthoredLaneFloor');p:SetAttribute('LaneId',route or p.Name);count+=1 end
end
-- Axis-aligned buttresses were sampled at nine-stud intervals under sloping
-- decks; their downhill top corners can protrude through the lane. Trim only
-- those supports to the lowest neighboring deck underside, never tag rocks.
local Ray=require('../meadow-v4/OfflineRay')
local floors=Ray.new(place.Workspace.CaveV2,function(p) return p:GetAttribute('WalkableLaneFloor') end,4)
local trimmed=0
for _,p in place.Workspace.CaveV2:GetChildren() do
 if p:IsA('BasePart') and (p.Name=='RouteRockButtress' or p.Name=='StackedMesaRock') then
  local position=p.CFrame.Position
  local bottom=position.Y-p.Size.Y/2;local ceiling=position.Y+p.Size.Y/2
  local limit=ceiling
  for _,x in {-1,0,1} do for _,z in {-1,0,1} do
   local q=position+rb.Vector3.new(x*p.Size.X/2,0,z*p.Size.Z/2)
   local hit=floors(rb.Vector3.new(q.X,ceiling+5,q.Z),rb.Vector3.new(0,-16,0))
   if hit then limit=math.min(limit,hit.Position.Y-2.2) end
  end end
  if limit<ceiling-.01 then
   trimmed+=1
   if limit<=bottom+.05 then p.CanCollide=false;p.CanQuery=false
   else p.Size=rb.Vector3.new(p.Size.X,limit-bottom,p.Size.Z);p.CFrame=rb.CFrame.new(position.X,(bottom+limit)/2,position.Z) end
  end
 end
end
server:SetAttribute('CaveSupportTrims',trimmed)
for _,name in {'SelfTest','DropSampleTest','LoopTest','CartRideTest','BlastPolicyTest','StudioPassAll'} do
 server:SetAttribute(name,false);server:SetAttribute(name..'Result','NOT RUN');server:SetAttribute(name..'Failures','[]')
end
local compiled=0
for _,n in place:GetDescendants() do if n:IsA('LuaSourceContainer') then
 for level=0,2 do luau.compile(n.Source,{optimizationLevel=level}) end;compiled+=1
end end
local bytes=rb.serializePlace(place);rb.deserializePlace(bytes);fs.writeFile(target,bytes)
print('PASS cave mounts, strict floors',count,'support trims',trimmed,'compiled O0/O1/O2',compiled)
