-- Compare shipped geometry to manifest and preserve all existing script Sources.
local fs=require('@lune/fs')
local rb=require('@lune/roblox')
local serde=require('@lune/serde')
local scene=serde.decode('json',fs.readFile('prototype/meadow-v4/scene.json'))
local current=rb.deserializePlace(fs.readFile('prototype/meadow-v4.rbxl'))
local baseline=rb.deserializePlace(fs.readFile('prototype/meadow-v4/round5-baseline.rbxl'))
local function sources(place)
 local result={};local count=0
 for _,item in place:GetDescendants() do
  if item:IsA('LuaSourceContainer') and item.Name~='Data' then result[item:GetFullName()]=item.Source;count+=1 end
 end
 return result,count
end
local a,n=sources(baseline);local b,m=sources(current)
assert(n==m,'script inventory changed')
for key,source in a do assert(b[key]==source,'changed script Source '..key) end
local model=current:FindFirstChildOfClass('Workspace'):FindFirstChild('MeadowV4')
local buckets={};local count=0
local function key(name,pos)
 return name..':'..math.floor(pos[1]/8+.00001)..':'..math.floor(pos[2]/8+.00001)..':'..math.floor(pos[3]/8+.00001)
end
for _,p in model:GetChildren() do
 if p:IsA('BasePart') then
  local components={p.CFrame:GetComponents()};local k=key(p.Name,components)
  buckets[k]=buckets[k] or {};table.insert(buckets[k],p);count+=1
 end
end
assert(count==#scene.parts,'native part count differs')
for _,p in scene.parts do
 local bucket=buckets[key(p.name,p.position)] or {};local matched=nil
 for i,q in bucket do
  local cf={q.CFrame:GetComponents()};local good=true
  for j=1,3 do if math.abs(cf[j]-p.position[j])>.0001 then good=false end end
  for j=1,9 do if math.abs(cf[j+3]-p.rotation[j])>.0001 then good=false end end
  for j,value in {q.Size.X,q.Size.Y,q.Size.Z} do if math.abs(value-p.size[j])>.0001 then good=false end end
  if good then
   assert(q.CanCollide==p.collidable,'collision mismatch '..p.name)
   assert(q.Anchored and not q.CanTouch,'part anchoring/touch mismatch')
   assert(q:IsA('WedgePart')==(p.shape=='Wedge'),'shape mismatch '..p.name)
   matched=i;break
  end
 end
 assert(matched,'manifest part not matched '..p.name..' '..serde.encode('json',p.position))
 table.remove(bucket,matched)
end
local report={state='PASS',matched_native_parts=count,geometry_tolerance_studs=.0001,non_generated_source_count=n,script_sources_byte_equal=true,Studio_runtime='UNKNOWN'}
fs.writeFile('treasure/map-v4/ROUND5-ARTIFACT.json',serde.encode('json',report,true))
print('PASS exact exported geometry within0.0001 stud: '..count..' native parts; '..n..' byte-equal non-generated scripts')
