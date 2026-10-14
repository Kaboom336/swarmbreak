local fs=require('@lune/fs')
local rb=require('@lune/roblox')
local serde=require('@lune/serde')
local scene=serde.decode('json',fs.readFile('prototype/meadow-v4/scene.json'))
local current=rb.deserializePlace(fs.readFile('prototype/meadow-v4.rbxl'))
local baseline=rb.deserializePlace(fs.readFile('prototype/meadow-v4/round6-baseline.rbxl'))
local function sources(place)
 local result={}
 for _,p in place:GetDescendants() do
  if p:IsA('LuaSourceContainer') and p.Name~='Data' then result[p:GetFullName()]=p.Source end
 end
 return result
end
local a,b=sources(baseline),sources(current)
for key,source in a do assert(b[key]==source,'changed Source '..key) end
for key in b do assert(a[key],'added Source '..key) end
local model=current:FindFirstChildOfClass('Workspace'):FindFirstChild('MeadowV4')
local parts=model:GetChildren();assert(#parts==#scene.parts,'part inventory')
for i,p in scene.parts do
 local q=parts[i];assert(q.Name==p.name,'native ordering/name')
 local cf={q.CFrame:GetComponents()}
 for j=1,3 do assert(math.abs(cf[j]-p.position[j])<.0001,'position') end
 for j=1,9 do assert(math.abs(cf[j+3]-p.rotation[j])<.0001,'rotation') end
 for j,v in {q.Size.X,q.Size.Y,q.Size.Z} do assert(math.abs(v-p.size[j])<.0001,'size') end
 assert(q.CanCollide==p.collidable and q.Anchored,'physics flags')
 assert(q:IsA('WedgePart')==(p.shape=='Wedge'),'shape')
end
local report={state='PASS',matched_native_parts=#parts,non_generated_sources_byte_equal=true,Studio_runtime='UNKNOWN'}
fs.writeFile('treasure/map-v4/ROUND6-ARTIFACT.json',serde.encode('json',report,true))
print('PASS '..#parts..' exact native parts; non-generated scripts byte-equal')
