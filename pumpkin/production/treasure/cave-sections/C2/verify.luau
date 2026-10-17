local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local H='treasure/cave-sections/C2/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local backup=fs.readFile('prototype/cave-v2.pre-c2.rbxl')
local neutral=rb.deserializePlace(bytes)
neutral.Workspace.CaveGeodeC2:Destroy();neutral.ServerScriptService.CaveGeodeC2:Destroy()
assert(rb.serializePlace(neutral)==rb.serializePlace(rb.deserializePlace(backup)),'unrelated serialization changed')
local S=p.ServerScriptService;local map=p.Workspace.CaveV2;local saved={}
assert(S.CaveGeodeC2.Source==fs.readFile('prototype/cave-v2/GeodeC2.server.luau'),'runtime source drift')
assert(S.CaveGeodeC2.Presentation.Source==fs.readFile(H..'presentation.luau'),'presentation source drift')
for i,n in map:GetDescendants()do
 if n:IsA('BasePart')then n.Color,n.Material,n.Transparency=n.Color,n.Material,n.Transparency;table.insert(saved,{n,n.Color,n.Material,n.Transparency})
 elseif n:IsA('Light')then n.Enabled=n.Enabled;table.insert(saved,{n,n.Enabled})end
 if i%200==0 then require('@lune/task').wait()end
end
local before=rb.serializeModel({map});local yields=0
local apply=luau.load(S.CaveGeodeC2.Presentation.Source,{environment={Vector3=rb.Vector3,Color3=rb.Color3,Enum=rb.Enum,task={wait=function()yields+=1 end}}})()
local report=apply(map);local once=rb.serializeModel({map});apply(map)
assert(once==rb.serializeModel({map}),'presentation not idempotent')
local changed=0
for _,e in saved do
 local n=e[1]
 if n:IsA('BasePart')then
  if n.Color~=e[2]or n.Material~=e[3]or n.Transparency~=e[4]then
   changed+=1;assert(not n.CanCollide,'physical appearance changed')
   assert(n.Name:match('^Crystal')or n.Name=='R3CliffVoxelSkin'or n.Name=='CliffInsetBlock'or n.Name=='CliffSteppedLedge','whitelist violation')
   for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
    local v=n.CFrame:PointToWorldSpace(n.Size*rb.Vector3.new(x,y,z)/2)
    assert(v.X>=100 and v.X<=244 and v.Y>=30 and v.Y<=120 and v.Z>=-170 and v.Z<=-90,'appearance escaped C2 bounds')
   end end end
  end
  n.Color,n.Material,n.Transparency=e[2],e[3],e[4]
 else n.Enabled=e[2]end
end
assert(before==rb.serializeModel({map}),'nonappearance field changed')
-- Disjoint C1/C2 appearance passes must produce the same result in either order.
local c1=luau.load(S.CaveArrivalC1.Presentation.Source,{environment={Color3=rb.Color3,Enum=rb.Enum,task={wait=function()end}}})()
local first,second=map:Clone(),map:Clone()
c1(first,S.CaveArrivalC1.Round.Value);apply(first)
apply(second);c1(second,S.CaveArrivalC1.Round.Value)
assert(rb.serializeModel({first})==rb.serializeModel({second}),'C1/C2 presentation order differs')
first:Destroy();second:Destroy()
-- Exact camera eyes must clear the actual authored solid and added art envelopes.
local cameras=serde.decode('json',fs.readFile(H..'CAMERAS.json'));local errors={}
for _,v in cameras.views do if v.name~='overview'then
 local eye=rb.Vector3.new(unpack(v.eye))
 for _,n in p.Workspace:GetDescendants()do if n:IsA('BasePart')and(n.CanCollide or n:GetAttribute('C2Cosmetic'))then
  local q=n.CFrame:PointToObjectSpace(eye);local s=n.Size/2
  if math.abs(q.X)<s.X and math.abs(q.Y)<s.Y and math.abs(q.Z)<s.Z then table.insert(errors,{camera=v.name,part=n.Name})end
 end end
end end
assert(#errors==0,'camera contained in geometry')
local sources={};local count=0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then
 count+=1;for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end
 sources[n:GetFullName()]=serde.hash('sha256',n.Source)
end end
fs.writeFile(H..'VERIFY.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',backup),unrelated_complete_serialization_exact=true,original_physical_query_lane_state_exact=true,presentation_only_whitelisted_appearance=true,c1_c2_order_equal=true,mounted_sources_match_worktree=true,presentation=report,changed_parts=changed,presentation_yields=yields,camera_errors=errors,compiled_O0_O1_O2=count,sources=sources,live_six_suites='UNKNOWN; not launched'},true))
print('PASS full preservation, presentation whitelist/reversibility/idempotence, five clear player cameras, O0/O1/O2',count)
