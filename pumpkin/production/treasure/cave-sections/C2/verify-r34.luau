local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local H='treasure/cave-sections/C2/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local backup=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c2r3.rbxl'))
local map,S=p.Workspace.CaveV2,p.ServerScriptService
assert(S.CaveGeodeC2.Source==fs.readFile('prototype/cave-v2/GeodeC2.server.luau'),'runtime source drift')
assert(S.CaveGeodeC2.Dress.Source==fs.readFile(H..'dress.luau'),'dress source drift')
local function strip(q)
 q.Workspace.CaveGeodeC2:Destroy();q.ServerScriptService.CaveGeodeC2:Destroy()
 return rb.serializePlace(q)
end
assert(strip(rb.deserializePlace(bytes))==strip(backup),'original complete serialization changed')
local waits=0
local env={Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,task={wait=function()waits+=1 end}}
local old={};for _,n in map:GetDescendants()do
 if n:IsA('BasePart')then n.Transparency=n.Transparency;old[n]={n.Color,n.Material,n.Transparency}
 elseif n:IsA('Light')then n.Enabled=n.Enabled;old[n]={n.Enabled}end
end
local originalMap=rb.serializeModel({map});local loot=map.Geode;local lootBytes=rb.serializeModel({loot})
local dress=luau.load(S.CaveGeodeC2.Dress.Source,{environment=env})()
local report=dress(map,p.Workspace.CaveGeodeC2,S.CaveGeodeC2.Round.Value)
local once=rb.serializeModel({map,p.Workspace.CaveGeodeC2});dress(map,p.Workspace.CaveGeodeC2,S.CaveGeodeC2.Round.Value)
assert(once==rb.serializeModel({map,p.Workspace.CaveGeodeC2}),'dressing not idempotent')
local parts,lights=0,0
local cameras=serde.decode('json',fs.readFile(H..'CAMERAS.json')).views
for _,container in {loot.C2_GeodeArt,p.Workspace.CaveGeodeC2.CampDress}do
 for _,n in container:GetDescendants()do
  if n:IsA('BasePart')then
   parts+=1;assert(n.Anchored and n.Massless and not n.CanCollide and not n.CanQuery and not n.CanTouch,'flags')
   for _,view in cameras do if view.name~='overview'then
    local q=n.CFrame:PointToObjectSpace(rb.Vector3.new(unpack(view.eye)));local s=n.Size/2
    assert(math.abs(q.X)>=s.X or math.abs(q.Y)>=s.Y or math.abs(q.Z)>=s.Z,'player eye inside new cosmetic')
   end end
  elseif n:IsA('PointLight')then lights+=1;assert(n.Brightness<=1.5 and n.Range<=18 and not n.Shadows,'light cap')end
 end
end
loot.C2_GeodeArt:Destroy();p.Workspace.CaveGeodeC2.CampDress:Destroy()
assert(lootBytes==rb.serializeModel({loot}),'loot field, metadata or original child changed')
local appearance=0
for n,values in old do
 if n:IsA('BasePart')then
  if n.Transparency~=values[3]then
   appearance+=1;assert(not n.CanCollide and(n.Name=='R3DistantIsland'or n.Name:match('^Crystal')),'debris whitelist')
   assert(n.CFrame.X>470 and n.CFrame.X<540 and n.CFrame.Z> -150 and n.CFrame.Z< -90,'debris selection escaped')
  end
  n.Color,n.Material,n.Transparency=values[1],values[2],values[3]
 else n.Enabled=values[1]end
end
assert(originalMap==rb.serializeModel({map}),'nonvisual original field changed')
local sources=0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then sources+=1;for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end end end
fs.writeFile(H..'VERIFY-R34.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),original_serialization_exact=true,loot_root_exact=true,cart_physics_and_behaviour_exact=true,cosmetic_parts=parts,live_safe_lights=lights,debris_appearance_parts=appearance,idempotence=true,reversibility=true,yields=waits,compiled_O0_O1_O2=sources,dress=report,live='UNKNOWN; Studio not launched'},true))
print('PASS R34 exact originals, loot metadata, cosmetic flags/light caps, idempotence/reversibility, compiles',sources,'parts',parts,'debris',appearance)
